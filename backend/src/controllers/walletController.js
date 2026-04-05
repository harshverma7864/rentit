const Wallet = require('../models/Wallet');
const Booking = require('../models/Booking');

const getOrCreateWallet = async (userId) => {
  let wallet = await Wallet.findOne({ user: userId });
  if (!wallet) {
    wallet = new Wallet({ user: userId, balance: 0, transactions: [] });
    await wallet.save();
  }
  return wallet;
};

exports.getWallet = async (req, res) => {
  try {
    const wallet = await getOrCreateWallet(req.user._id);
    res.json({ wallet });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.addMoney = async (req, res) => {
  try {
    const { amount } = req.body;
    if (!amount || amount <= 0) return res.status(400).json({ error: 'Invalid amount' });

    const wallet = await getOrCreateWallet(req.user._id);
    wallet.balance += amount;
    wallet.transactions.push({
      type: 'credit',
      amount,
      description: 'Added money to wallet',
    });
    await wallet.save();

    res.json({ wallet });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.payForBooking = async (req, res) => {
  try {
    const { bookingId } = req.body;
    const booking = await Booking.findOne({ _id: bookingId, renter: req.user._id });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.paymentStatus === 'paid') return res.status(400).json({ error: 'Already paid' });
    if (booking.status !== 'accepted') return res.status(400).json({ error: 'Booking must be accepted first' });

    const wallet = await getOrCreateWallet(req.user._id);

    // Use finalPrice if negotiation was accepted, otherwise totalPrice
    const rentalAmount = booking.finalPrice || booking.totalPrice;
    const totalAmount = rentalAmount + booking.securityDeposit;

    if (wallet.balance < totalAmount) {
      return res.status(400).json({ error: 'Insufficient wallet balance', required: totalAmount, available: wallet.balance });
    }

    wallet.balance -= totalAmount;
    wallet.transactions.push({
      type: 'payment',
      amount: totalAmount,
      description: `Payment for booking (Rental: ₹${rentalAmount}, Deposit: ₹${booking.securityDeposit})`,
      booking: bookingId,
    });
    await wallet.save();

    booking.paymentStatus = 'paid';
    booking.paymentDate = new Date();
    booking.status = 'active';
    if (booking.deliveryOption === 'delivery') {
      booking.deliveryStatus = 'pending';
    }
    await booking.save();

    // Credit ONLY rental amount to owner (security deposit held in escrow)
    const ownerWallet = await getOrCreateWallet(booking.owner);
    ownerWallet.balance += rentalAmount;
    ownerWallet.transactions.push({
      type: 'credit',
      amount: rentalAmount,
      description: `Received rental payment (Security deposit ₹${booking.securityDeposit} held in escrow)`,
      booking: bookingId,
    });
    await ownerWallet.save();

    res.json({ wallet, booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.requestRefund = async (req, res) => {
  try {
    const { bookingId, reason } = req.body;
    const booking = await Booking.findOne({
      _id: bookingId,
      $or: [{ renter: req.user._id }, { owner: req.user._id }],
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.paymentStatus !== 'paid') return res.status(400).json({ error: 'No payment to refund' });

    const wallet = await getOrCreateWallet(req.user._id);
    const refundAmount = booking.securityDeposit;

    wallet.balance += refundAmount;
    wallet.transactions.push({
      type: 'refund',
      amount: refundAmount,
      description: reason || 'Security deposit refund',
      booking: bookingId,
    });
    await wallet.save();

    res.json({ wallet });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
