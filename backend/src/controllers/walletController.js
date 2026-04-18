const { Wallet, WalletTransaction, Booking } = require('../models');

const getOrCreateWallet = async (userId) => {
  let wallet = await Wallet.findOne({ where: { userId } });
  if (!wallet) {
    wallet = await Wallet.create({ userId, balance: 0 });
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

    const wallet = await getOrCreateWallet(req.user.id);
    await wallet.update({ balance: wallet.balance + amount });
    await WalletTransaction.create({
      walletId: wallet.id,
      type: 'credit',
      amount,
      description: 'Added money to wallet',
    });

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

    const wallet = await getOrCreateWallet(req.user.id);

    const rentalAmount = booking.finalPrice || booking.totalPrice;
    const totalAmount = rentalAmount + booking.securityDeposit;

    if (wallet.balance < totalAmount) {
      return res.status(400).json({ error: 'Insufficient wallet balance', required: totalAmount, available: wallet.balance });
    }

    await wallet.update({ balance: wallet.balance - totalAmount });
    await WalletTransaction.create({
      walletId: wallet.id,
      type: 'payment',
      amount: totalAmount,
      description: `Payment for booking (Rental: ₹${rentalAmount}, Deposit: ₹${booking.securityDeposit})`,
      bookingId,
    });

    await booking.update({
      paymentStatus: 'paid',
      paymentDate: new Date(),
      status: 'active',
      deliveryStatus: booking.deliveryOption === 'delivery' ? 'pending' : 'none',
    });

    // Credit rental to owner
    const ownerWallet = await getOrCreateWallet(booking.ownerId);
    await ownerWallet.update({ balance: ownerWallet.balance + rentalAmount });
    await WalletTransaction.create({
      walletId: ownerWallet.id,
      type: 'credit',
      amount: rentalAmount,
      description: `Received rental payment (Security deposit ₹${booking.securityDeposit} held in escrow)`,
      bookingId,
    });

    const transactions = await WalletTransaction.findAll({
      where: { walletId: wallet.id },
      order: [['createdAt', 'DESC']],
    });
    const walletJson = wallet.toJSON();
    walletJson.transactions = transactions;
    res.json({ wallet: walletJson, booking });
  } catch (error) {
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

    const wallet = await getOrCreateWallet(req.user.id);
    const refundAmount = booking.securityDeposit;

    await wallet.update({ balance: wallet.balance + refundAmount });
    await WalletTransaction.create({
      walletId: wallet.id,
      type: 'refund',
      amount: refundAmount,
      description: reason || 'Security deposit refund',
      bookingId,
    });

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
