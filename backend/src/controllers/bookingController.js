const Booking = require('../models/Booking');
const Item = require('../models/Item');
const Notification = require('../models/Notification');
const Wallet = require('../models/Wallet');

exports.createBooking = async (req, res) => {
  try {
    const { itemId, startDate, endDate, deliveryOption, renterNote, scheduledPickupTime } = req.body;

    const item = await Item.findById(itemId);
    if (!item) return res.status(404).json({ error: 'Item not found' });
    if (!item.isAvailable) return res.status(400).json({ error: 'Item is not available' });
    if (item.owner.toString() === req.user._id.toString()) {
      return res.status(400).json({ error: 'Cannot rent your own item' });
    }

    // Check for conflicting bookings
    const conflict = await Booking.findOne({
      item: itemId,
      status: { $in: ['pending', 'accepted', 'active'] },
      $or: [
        { startDate: { $lte: new Date(endDate) }, endDate: { $gte: new Date(startDate) } },
      ],
    });
    if (conflict) return res.status(400).json({ error: 'Item is already booked for these dates' });

    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
    const totalPrice = days * item.pricePerDay + (deliveryOption === 'delivery' ? item.deliveryFee : 0);

    const booking = new Booking({
      item: itemId,
      renter: req.user._id,
      owner: item.owner,
      startDate: start,
      endDate: end,
      totalPrice,
      securityDeposit: item.securityDeposit,
      deliveryOption: deliveryOption || 'pickup',
      renterNote: renterNote || '',
      scheduledPickupTime: scheduledPickupTime ? new Date(scheduledPickupTime) : undefined,
    });

    await booking.save();

    // Notify the owner
    const notification = new Notification({
      user: item.owner,
      type: 'booking_request',
      title: 'New Rental Request',
      message: `${req.user.name} wants to rent your "${item.title}"`,
      data: { bookingId: booking._id, itemId: item._id },
    });
    await notification.save();

    // Emit socket event
    if (req.app.get('io')) {
      req.app.get('io').to(item.owner.toString()).emit('notification', notification);
    }

    await booking.populate([
      { path: 'item', select: 'title images pricePerDay' },
      { path: 'renter', select: 'name avatar' },
      { path: 'owner', select: 'name avatar' },
    ]);

    res.status(201).json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.respondToBooking = async (req, res) => {
  try {
    const { status, ownerNote, estimatedDeliveryTime } = req.body;
    if (!['accepted', 'rejected'].includes(status)) {
      return res.status(400).json({ error: 'Status must be accepted or rejected' });
    }

    const booking = await Booking.findOne({ _id: req.params.id, owner: req.user._id });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'pending') return res.status(400).json({ error: 'Booking already responded to' });

    booking.status = status;
    if (ownerNote) booking.ownerNote = ownerNote;
    if (estimatedDeliveryTime) booking.estimatedDeliveryTime = estimatedDeliveryTime;
    await booking.save();

    const item = await Item.findById(booking.item);
    const notifType = status === 'accepted' ? 'booking_accepted' : 'booking_rejected';
    const notifMsg = status === 'accepted'
      ? `Your rental request for "${item.title}" has been accepted!${estimatedDeliveryTime ? ` Estimated delivery: ${estimatedDeliveryTime}` : ''}`
      : `Your rental request for "${item.title}" was declined.`;

    const notification = new Notification({
      user: booking.renter,
      type: notifType,
      title: status === 'accepted' ? 'Request Accepted!' : 'Request Declined',
      message: notifMsg,
      data: { bookingId: booking._id, itemId: item._id },
    });
    await notification.save();

    if (req.app.get('io')) {
      req.app.get('io').to(booking.renter.toString()).emit('notification', notification);
    }

    await booking.populate([
      { path: 'item', select: 'title images pricePerDay' },
      { path: 'renter', select: 'name avatar' },
      { path: 'owner', select: 'name avatar' },
    ]);

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.completeBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      $or: [{ owner: req.user._id }, { renter: req.user._id }],
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'accepted' && booking.status !== 'active') {
      return res.status(400).json({ error: 'Booking cannot be completed' });
    }

    booking.status = 'completed';
    await booking.save();

    // Refund security deposit to renter on completion
    if (booking.paymentStatus === 'paid' && booking.securityDeposit > 0) {
      const renterWallet = await Wallet.findOne({ user: booking.renter });
      if (renterWallet) {
        renterWallet.balance += booking.securityDeposit;
        renterWallet.transactions.push({
          type: 'refund',
          amount: booking.securityDeposit,
          description: 'Security deposit returned on rental completion',
          booking: booking._id,
        });
        await renterWallet.save();
      }
    }

    const notifyUser = booking.owner.toString() === req.user._id.toString()
      ? booking.renter : booking.owner;

    const notification = new Notification({
      user: notifyUser,
      type: 'booking_completed',
      title: 'Rental Completed',
      message: 'The rental has been marked as completed.',
      data: { bookingId: booking._id },
    });
    await notification.save();

    if (req.app.get('io')) {
      req.app.get('io').to(notifyUser.toString()).emit('notification', notification);
    }

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      renter: req.user._id,
      status: { $in: ['pending', 'accepted', 'active'] },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found or cannot cancel' });

    // If out for delivery, renter must pay delivery fee only
    if (booking.deliveryStatus === 'out_for_delivery') {
      const item = await Item.findById(booking.item);
      const deliveryFee = item ? item.deliveryFee : 0;

      // Check if paid, refund minus delivery fee
      if (booking.paymentStatus === 'paid') {
        const renterWallet = await Wallet.findOne({ user: req.user._id });
        if (renterWallet) {
          const refund = booking.totalPrice + booking.securityDeposit - deliveryFee;
          renterWallet.balance += refund;
          renterWallet.transactions.push({
            type: 'refund',
            amount: refund,
            description: `Cancellation refund (delivery fee ₹${deliveryFee} deducted)`,
            booking: booking._id,
          });
          await renterWallet.save();
        }
      }

      booking.status = 'cancelled';
      booking.deliveryStatus = 'none';
      await booking.save();
    } else if (booking.deliveryStatus === 'delivered') {
      return res.status(400).json({ error: 'Cannot cancel after delivery' });
    } else {
      // Pending or no delivery — full cancel
      if (booking.paymentStatus === 'paid') {
        const renterWallet = await Wallet.findOne({ user: req.user._id });
        if (renterWallet) {
          const refund = booking.totalPrice + booking.securityDeposit;
          renterWallet.balance += refund;
          renterWallet.transactions.push({
            type: 'refund',
            amount: refund,
            description: 'Full cancellation refund',
            booking: booking._id,
          });
          await renterWallet.save();
        }
      }
      booking.status = 'cancelled';
      await booking.save();
    }

    const notification = new Notification({
      user: booking.owner,
      type: 'booking_cancelled',
      title: 'Booking Cancelled',
      message: `A rental request has been cancelled by the renter.`,
      data: { bookingId: booking._id },
    });
    await notification.save();

    if (req.app.get('io')) {
      req.app.get('io').to(booking.owner.toString()).emit('notification', notification);
    }

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateDeliveryStatus = async (req, res) => {
  try {
    const { deliveryStatus } = req.body;
    if (!['pending', 'out_for_delivery', 'delivered'].includes(deliveryStatus)) {
      return res.status(400).json({ error: 'Invalid delivery status' });
    }

    const booking = await Booking.findOne({ _id: req.params.id, owner: req.user._id });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    // Only allow delivery status change after payment is completed
    if (booking.paymentStatus !== 'paid') {
      return res.status(400).json({ error: 'Payment must be completed before updating delivery status' });
    }

    booking.deliveryStatus = deliveryStatus;
    await booking.save();

    const notification = new Notification({
      user: booking.renter,
      type: 'general',
      title: 'Delivery Update',
      message: deliveryStatus === 'out_for_delivery'
        ? 'Your item is out for delivery!'
        : deliveryStatus === 'delivered'
          ? 'Your item has been delivered!'
          : 'Delivery is being prepared.',
      data: { bookingId: booking._id },
    });
    await notification.save();

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyBookings = async (req, res) => {
  try {
    const { role = 'renter', status } = req.query;
    const filter = {};

    if (role === 'renter') filter.renter = req.user._id;
    else filter.owner = req.user._id;

    if (status) filter.status = status;

    const bookings = await Booking.find(filter)
      .sort({ createdAt: -1 })
      .populate('item', 'title images pricePerDay category')
      .populate('renter', 'name avatar phone')
      .populate('owner', 'name avatar phone');

    res.json({ bookings });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      $or: [{ owner: req.user._id }, { renter: req.user._id }],
    })
      .populate('item')
      .populate('renter', 'name avatar phone location')
      .populate('owner', 'name avatar phone location');

    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getItemBookings = async (req, res) => {
  try {
    const item = await Item.findOne({ _id: req.params.itemId, owner: req.user._id });
    if (!item) return res.status(404).json({ error: 'Item not found' });

    const bookings = await Booking.find({ item: req.params.itemId })
      .sort({ startDate: -1 })
      .populate('renter', 'name avatar phone');

    res.json({ bookings });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.negotiatePrice = async (req, res) => {
  try {
    const { proposedPrice, message } = req.body;
    if (!proposedPrice || proposedPrice <= 0) {
      return res.status(400).json({ error: 'Valid proposed price is required' });
    }

    const booking = await Booking.findOne({
      _id: req.params.id,
      $or: [{ owner: req.user._id }, { renter: req.user._id }],
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    if (booking.status !== 'pending') {
      return res.status(400).json({ error: 'Can only negotiate pending bookings' });
    }

    const isOwner = booking.owner.toString() === req.user._id.toString();
    const from = isOwner ? 'owner' : 'renter';

    booking.proposedPrice = proposedPrice;
    booking.negotiationStatus = isOwner ? 'counter' : 'proposed';
    booking.negotiationHistory.push({
      from,
      amount: proposedPrice,
      message: message || '',
      timestamp: new Date(),
    });
    await booking.save();

    // Notify the other party
    const notifyUser = isOwner ? booking.renter : booking.owner;
    const notification = new Notification({
      user: notifyUser,
      type: 'general',
      title: 'Price Negotiation',
      message: `${isOwner ? 'The owner' : 'The renter'} proposed ₹${proposedPrice} for this booking.`,
      data: { bookingId: booking._id },
    });
    await notification.save();

    await booking.populate([
      { path: 'item', select: 'title images pricePerDay' },
      { path: 'renter', select: 'name avatar' },
      { path: 'owner', select: 'name avatar' },
    ]);

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.acceptNegotiation = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      _id: req.params.id,
      $or: [{ owner: req.user._id }, { renter: req.user._id }],
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    if (!booking.proposedPrice) {
      return res.status(400).json({ error: 'No price proposal to accept' });
    }

    booking.negotiationStatus = 'accepted';
    booking.finalPrice = booking.proposedPrice;
    booking.totalPrice = booking.proposedPrice;
    await booking.save();

    const isOwner = booking.owner.toString() === req.user._id.toString();
    const notifyUser = isOwner ? booking.renter : booking.owner;
    const notification = new Notification({
      user: notifyUser,
      type: 'general',
      title: 'Price Accepted',
      message: `The negotiated price of ₹${booking.finalPrice} has been accepted!`,
      data: { bookingId: booking._id },
    });
    await notification.save();

    await booking.populate([
      { path: 'item', select: 'title images pricePerDay' },
      { path: 'renter', select: 'name avatar' },
      { path: 'owner', select: 'name avatar' },
    ]);

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
