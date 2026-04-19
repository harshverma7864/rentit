const { Wallet, WalletTransaction, Booking } = require('../models');
const sequelize = require('../config/database');
const razorpayService = require('../services/razorpay');

const getOrCreateWallet = async (userId, transaction = null) => {
  const opts = transaction ? { where: { userId }, transaction, lock: transaction.LOCK.UPDATE } : { where: { userId } };
  let wallet = await Wallet.findOne(opts);
  if (!wallet) {
    wallet = await Wallet.create({ userId, balance: 0 }, transaction ? { transaction } : {});
    // Re-fetch with lock if in transaction
    if (transaction) {
      wallet = await Wallet.findOne({ where: { userId }, transaction, lock: transaction.LOCK.UPDATE });
    }
  }
  return wallet;
};

exports.getWallet = async (req, res) => {
  try {
    const wallet = await getOrCreateWallet(req.user.id);
    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.addMoney = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ error: 'Invalid amount' });

    await sequelize.transaction(async (t) => {
      const wallet = await getOrCreateWallet(req.user.id, t);
      const newBalance = parseFloat(wallet.balance) + amount;
      await wallet.update({ balance: newBalance }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'credit',
        amount,
        description: 'Added money to wallet',
      }, { transaction: t });
    });

    const wallet = await getOrCreateWallet(req.user.id);
    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.payForBooking = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const booking = await Booking.findOne({ where: { id: bookingId, renterId: req.user.id } });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.paymentStatus === 'paid') return res.status(400).json({ error: 'Already paid' });
    if (booking.status !== 'accepted') return res.status(400).json({ error: 'Booking must be accepted first' });

    await sequelize.transaction(async (t) => {
      const wallet = await getOrCreateWallet(req.user.id, t);

      const rentalAmount = parseFloat(booking.finalPrice || booking.totalPrice);
      const securityDeposit = parseFloat(booking.securityDeposit);
      const totalAmount = rentalAmount + securityDeposit;
      const currentBalance = parseFloat(wallet.balance);

      if (currentBalance < totalAmount) {
        throw Object.assign(new Error('Insufficient wallet balance'), { statusCode: 400, required: totalAmount, available: currentBalance });
      }

      await wallet.update({ balance: currentBalance - totalAmount }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'payment',
        amount: totalAmount,
        description: `Payment for booking (Rental: ₹${rentalAmount}, Deposit: ₹${securityDeposit})`,
        bookingId,
      }, { transaction: t });

      await booking.update({
        paymentStatus: 'paid',
        paymentDate: new Date(),
        status: 'active',
        deliveryStatus: booking.deliveryOption === 'delivery' ? 'pending' : 'none',
      }, { transaction: t });

      // Credit rental to owner
      const ownerWallet = await getOrCreateWallet(booking.ownerId, t);
      const ownerBalance = parseFloat(ownerWallet.balance);
      await ownerWallet.update({ balance: ownerBalance + rentalAmount }, { transaction: t });
      await WalletTransaction.create({
        walletId: ownerWallet.id,
        type: 'credit',
        amount: rentalAmount,
        description: `Received rental payment (Security deposit ₹${securityDeposit} held in escrow)`,
        bookingId,
      }, { transaction: t });
    });

    const wallet = await getOrCreateWallet(req.user.id);
    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson, booking });
  } catch (error) {
    if (error.statusCode === 400) {
      return res.status(400).json({ error: error.message, required: error.required, available: error.available });
    }
    res.status(400).json({ error: error.message });
  }
};

exports.requestRefund = async (req, res) => {
  try {
    const { bookingId, reason } = req.body;
    const booking = await Booking.findOne({
      where: {
        id: bookingId,
        [require('sequelize').Op.or]: [{ renterId: req.user.id }, { ownerId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.paymentStatus !== 'paid') return res.status(400).json({ error: 'No payment to refund' });

    await sequelize.transaction(async (t) => {
      const wallet = await getOrCreateWallet(req.user.id, t);
      const refundAmount = parseFloat(booking.securityDeposit);
      const currentBalance = parseFloat(wallet.balance);
      await wallet.update({ balance: currentBalance + refundAmount }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'refund',
        amount: refundAmount,
        description: reason || 'Security deposit refund',
        bookingId,
      }, { transaction: t });
    });

    const wallet = await getOrCreateWallet(req.user.id);
    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.createOrder = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ error: 'Invalid amount' });

    const amountInPaise = Math.round(amount * 100);
    const receipt = `wallet_${req.user.id}_${Date.now()}`;
    const order = await razorpayService.createOrder(amountInPaise, receipt);

    res.json({
      orderId: order.id,
      amount: order.amount,
      currency: order.currency,
      keyId: process.env.RAZORPAY_KEY_ID,
    });
  } catch (error) {
    res.status(500).json({ error: error.message || 'Payment gateway error' });
  }
};

exports.verifyPayment = async (req, res) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

    const isValid = razorpayService.verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature);
    if (!isValid) {
      return res.status(400).json({ error: 'Payment verification failed' });
    }

    // Idempotency check — see if this payment was already processed
    const existing = await WalletTransaction.findOne({
      where: { description: { [require('sequelize').Op.like]: `%${razorpay_payment_id}%` } },
    });
    if (existing) {
      const wallet = await getOrCreateWallet(req.user.id);
      return res.json({ message: 'Payment already processed', wallet: wallet.toJSON() });
    }

    // Credit wallet in transaction
    await sequelize.transaction(async (t) => {
      const wallet = await getOrCreateWallet(req.user.id, t);
      const currentBalance = parseFloat(wallet.balance);
      const amount = req.body.amount || 0; // amount in rupees, passed from frontend or derived from order

      // Fetch order to get amount if not passed
      let creditAmount = amount;
      if (!creditAmount) {
        const razorpay = razorpayService.getInstance();
        if (razorpay) {
          const order = await razorpay.orders.fetch(razorpay_order_id);
          creditAmount = order.amount / 100; // paise to rupees
        }
      }

      await wallet.update({ balance: currentBalance + creditAmount }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'credit',
        amount: creditAmount,
        description: `Razorpay payment ${razorpay_payment_id}`,
      }, { transaction: t });
    });

    const wallet = await getOrCreateWallet(req.user.id);
    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.razorpayWebhook = async (req, res) => {
  try {
    const signature = req.headers['x-razorpay-signature'];
    const rawBody = typeof req.body === 'string' ? req.body : JSON.stringify(req.body);

    if (!razorpayService.verifyWebhookSignature(rawBody, signature)) {
      return res.status(400).send('Invalid signature');
    }

    const event = typeof req.body === 'string' ? JSON.parse(req.body) : req.body;
    if (event.event !== 'payment.captured') {
      return res.json({ status: 'ignored' });
    }

    const payment = event.payload.payment.entity;
    const paymentId = payment.id;
    const amountInRupees = payment.amount / 100;

    // Idempotency check
    const existing = await WalletTransaction.findOne({
      where: { description: { [require('sequelize').Op.like]: `%${paymentId}%` } },
    });
    if (existing) {
      return res.json({ status: 'already_processed' });
    }

    // Extract userId from receipt (format: wallet_{userId}_{timestamp})
    const receipt = payment.notes?.receipt || '';
    const userIdMatch = receipt.match(/^wallet_(.+?)_\d+$/);
    if (!userIdMatch) {
      return res.json({ status: 'no_user_id' });
    }
    const userId = userIdMatch[1];

    await sequelize.transaction(async (t) => {
      const wallet = await getOrCreateWallet(userId, t);
      const currentBalance = parseFloat(wallet.balance);
      await wallet.update({ balance: currentBalance + amountInRupees }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'credit',
        amount: amountInRupees,
        description: `Razorpay webhook payment ${paymentId}`,
      }, { transaction: t });
    });

    res.json({ status: 'ok' });
  } catch (error) {
    console.error('[Razorpay Webhook] Error:', error.message);
    res.status(500).json({ error: 'Webhook processing failed' });
  }
};
