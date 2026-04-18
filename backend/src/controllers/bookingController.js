const { Booking, Item, Notification, NegotiationEntry, User, Wallet, WalletTransaction } = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');

const bookingIncludes = [
  { model: Item, as: 'item', attributes: ['id', 'title', 'images', 'pricePerDay', 'category'] },
  { model: User, as: 'renter', attributes: ['id', 'name', 'avatar', 'phone'] },
  { model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'phone'] },
];

exports.createBooking = async (req, res) => {
  try {
    const { itemId, startDate, endDate, deliveryOption, renterNote, scheduledPickupTime, quantity,
      eventDate, renterSize, sizeDetails, alterationRequests } = req.body;

    const item = await Item.findByPk(itemId);
    if (!item) return res.status(404).json({ error: 'Item not found' });
    if (!item.isAvailable) return res.status(400).json({ error: 'Item is not available' });
    if (item.ownerId === req.user.id) {
      return res.status(400).json({ error: 'Cannot rent your own item' });
    }

    const requestedQty = quantity && quantity > 0 ? quantity : 1;
    if (requestedQty > item.quantity) {
      return res.status(400).json({ error: `Only ${item.quantity} available` });
    }

    const conflict = await Booking.findOne({
      where: {
        itemId,
        status: { [Op.in]: ['pending', 'accepted', 'active'] },
        startDate: { [Op.lte]: new Date(endDate) },
        endDate: { [Op.gte]: new Date(startDate) },
      },
    });
    if (conflict) return res.status(400).json({ error: 'Item is already booked for these dates' });

    const start = new Date(startDate);
    const end = new Date(endDate);
    const days = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
    const totalPrice = (days * item.pricePerDay + (deliveryOption === 'delivery' ? item.deliveryFee : 0)) * requestedQty;

    const booking = await Booking.create({
      itemId,
      renterId: req.user.id,
      ownerId: item.ownerId,
      startDate: start,
      endDate: end,
      quantity: requestedQty,
      totalPrice,
      securityDeposit: item.securityDeposit * requestedQty,
      deliveryOption: deliveryOption || 'pickup',
      renterNote: renterNote || '',
      scheduledPickupTime: scheduledPickupTime ? new Date(scheduledPickupTime) : null,
      eventDate: eventDate ? new Date(eventDate) : null,
      renterSize: renterSize || '',
      sizeDetails: sizeDetails || {},
      alterationRequests: alterationRequests || '',
      alterationStatus: alterationRequests ? 'requested' : 'none',
      securityDepositStatus: 'unpaid',
    });

    const notification = await Notification.create({
      userId: item.ownerId,
      type: 'booking_request',
      title: 'New Rental Request',
      message: `${req.user.name} wants to rent your "${item.title}"`,
      data: { bookingId: booking.id, itemId: item.id },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(item.ownerId).emit('notification', notification);
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.status(201).json({ booking: result });
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

    const booking = await Booking.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'pending') return res.status(400).json({ error: 'Booking already responded to' });

    const updates = { status };
    if (ownerNote) updates.ownerNote = ownerNote;
    if (estimatedDeliveryTime) updates.estimatedDeliveryTime = estimatedDeliveryTime;
    await booking.update(updates);

    if (status === 'accepted') {
      const item = await Item.findByPk(booking.itemId);
      if (item) {
        const newQty = Math.max(0, item.quantity - (booking.quantity || 1));
        await item.update({ quantity: newQty, isAvailable: newQty > 0 });
      }
    }

    const item = await Item.findByPk(booking.itemId);
    const notifType = status === 'accepted' ? 'booking_accepted' : 'booking_rejected';
    const notifMsg = status === 'accepted'
      ? `Your rental request for "${item.title}" has been accepted!${estimatedDeliveryTime ? ` Estimated delivery: ${estimatedDeliveryTime}` : ''}`
      : `Your rental request for "${item.title}" was declined.`;

    const notification = await Notification.create({
      userId: booking.renterId,
      type: notifType,
      title: status === 'accepted' ? 'Request Accepted!' : 'Request Declined',
      message: notifMsg,
      data: { bookingId: booking.id, itemId: item.id },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(booking.renterId).emit('notification', notification);
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.completeBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [{ ownerId: req.user.id }, { renterId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'accepted' && booking.status !== 'active') {
      return res.status(400).json({ error: 'Booking cannot be completed' });
    }

    await booking.update({ status: 'completed' });

    const completedItem = await Item.findByPk(booking.itemId);
    if (completedItem) {
      const newQty = completedItem.quantity + (booking.quantity || 1);
      await completedItem.update({ quantity: newQty, isAvailable: true });
    }

    if (booking.paymentStatus === 'paid' && booking.securityDeposit > 0) {
      const renterWallet = await Wallet.findOne({ where: { userId: booking.renterId } });
      if (renterWallet) {
        await renterWallet.update({ balance: renterWallet.balance + booking.securityDeposit });
        await WalletTransaction.create({
          walletId: renterWallet.id,
          type: 'refund',
          amount: booking.securityDeposit,
          description: 'Security deposit returned on rental completion',
          bookingId: booking.id,
        });
      }
    }

    const notifyUser = booking.ownerId === req.user.id ? booking.renterId : booking.ownerId;
    const notification = await Notification.create({
      userId: notifyUser,
      type: 'booking_completed',
      title: 'Rental Completed',
      message: 'The rental has been marked as completed.',
      data: { bookingId: booking.id },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(notifyUser).emit('notification', notification);
    }

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.cancelBooking = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        renterId: req.user.id,
        status: { [Op.in]: ['pending', 'accepted', 'active'] },
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found or cannot cancel' });

    const originalStatus = booking.status;

    if (booking.deliveryStatus === 'out_for_delivery') {
      const item = await Item.findByPk(booking.itemId);
      const deliveryFee = item ? item.deliveryFee : 0;

      if (booking.paymentStatus === 'paid') {
        const renterWallet = await Wallet.findOne({ where: { userId: req.user.id } });
        if (renterWallet) {
          const refund = booking.totalPrice + booking.securityDeposit - deliveryFee;
          await renterWallet.update({ balance: renterWallet.balance + refund });
          await WalletTransaction.create({
            walletId: renterWallet.id,
            type: 'refund',
            amount: refund,
            description: `Cancellation refund (delivery fee ₹${deliveryFee} deducted)`,
            bookingId: booking.id,
          });
        }
      }
      await booking.update({ status: 'cancelled', deliveryStatus: 'none' });
    } else if (booking.deliveryStatus === 'delivered') {
      return res.status(400).json({ error: 'Cannot cancel after delivery' });
    } else {
      if (booking.paymentStatus === 'paid') {
        const renterWallet = await Wallet.findOne({ where: { userId: req.user.id } });
        if (renterWallet) {
          const refund = booking.totalPrice + booking.securityDeposit;
          await renterWallet.update({ balance: renterWallet.balance + refund });
          await WalletTransaction.create({
            walletId: renterWallet.id,
            type: 'refund',
            amount: refund,
            description: 'Full cancellation refund',
            bookingId: booking.id,
          });
        }
      }
      await booking.update({ status: 'cancelled' });
    }

    if (['accepted', 'active'].includes(originalStatus)) {
      const cancelledItem = await Item.findByPk(booking.itemId);
      if (cancelledItem) {
        const newQty = cancelledItem.quantity + (booking.quantity || 1);
        await cancelledItem.update({ quantity: newQty, isAvailable: true });
      }
    }

    const notification = await Notification.create({
      userId: booking.ownerId,
      type: 'booking_cancelled',
      title: 'Booking Cancelled',
      message: 'A rental request has been cancelled by the renter.',
      data: { bookingId: booking.id },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(booking.ownerId).emit('notification', notification);
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

    const booking = await Booking.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    if (booking.paymentStatus !== 'paid') {
      return res.status(400).json({ error: 'Payment must be completed before updating delivery status' });
    }

    await booking.update({ deliveryStatus });

    await Notification.create({
      userId: booking.renterId,
      type: 'general',
      title: 'Delivery Update',
      message: deliveryStatus === 'out_for_delivery'
        ? 'Your item is out for delivery!'
        : deliveryStatus === 'delivered'
          ? 'Your item has been delivered!'
          : 'Delivery is being prepared.',
      data: { bookingId: booking.id },
    });

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyBookings = async (req, res) => {
  try {
    const { role = 'renter', status } = req.query;
    const where = {};

    if (role === 'renter') where.renterId = req.user.id;
    else where.ownerId = req.user.id;

    if (status) where.status = status;

    const bookings = await Booking.findAll({
      where,
      order: [['createdAt', 'DESC']],
      include: bookingIncludes,
    });

    // Attach negotiation history
    for (const booking of bookings) {
      const history = await NegotiationEntry.findAll({
        where: { bookingId: booking.id },
        order: [['createdAt', 'ASC']],
      });
      booking.dataValues.negotiationHistory = history;
    }

    res.json({ bookings });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [{ ownerId: req.user.id }, { renterId: req.user.id }],
      },
      include: [
        { model: Item, as: 'item' },
        { model: User, as: 'renter', attributes: ['id', 'name', 'avatar', 'phone', 'latitude', 'longitude', 'locationAddress', 'locationCity'] },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'phone', 'latitude', 'longitude', 'locationAddress', 'locationCity'] },
      ],
    });

    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    const history = await NegotiationEntry.findAll({
      where: { bookingId: booking.id },
      order: [['createdAt', 'ASC']],
    });
    booking.dataValues.negotiationHistory = history;

    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getItemBookings = async (req, res) => {
  try {
    const item = await Item.findOne({ where: { id: req.params.itemId, ownerId: req.user.id } });
    if (!item) return res.status(404).json({ error: 'Item not found' });

    const bookings = await Booking.findAll({
      where: { itemId: req.params.itemId },
      order: [['startDate', 'DESC']],
      include: [{ model: User, as: 'renter', attributes: ['id', 'name', 'avatar', 'phone'] }],
    });

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
      where: {
        id: req.params.id,
        [Op.or]: [{ ownerId: req.user.id }, { renterId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'pending') {
      return res.status(400).json({ error: 'Can only negotiate pending bookings' });
    }

    const isOwner = booking.ownerId === req.user.id;
    const fromRole = isOwner ? 'owner' : 'renter';

    await booking.update({
      proposedPrice,
      negotiationStatus: isOwner ? 'counter' : 'proposed',
    });

    await NegotiationEntry.create({
      bookingId: booking.id,
      fromRole,
      amount: proposedPrice,
      message: message || '',
    });

    const notifyUser = isOwner ? booking.renterId : booking.ownerId;
    await Notification.create({
      userId: notifyUser,
      type: 'general',
      title: 'Price Negotiation',
      message: `${isOwner ? 'The owner' : 'The renter'} proposed ₹${proposedPrice} for this booking.`,
      data: { bookingId: booking.id },
    });

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    const history = await NegotiationEntry.findAll({
      where: { bookingId: booking.id },
      order: [['createdAt', 'ASC']],
    });
    result.dataValues.negotiationHistory = history;

    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.acceptNegotiation = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [{ ownerId: req.user.id }, { renterId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (!booking.proposedPrice) {
      return res.status(400).json({ error: 'No price proposal to accept' });
    }

    await booking.update({
      negotiationStatus: 'accepted',
      finalPrice: booking.proposedPrice,
      totalPrice: booking.proposedPrice,
    });

    const isOwner = booking.ownerId === req.user.id;
    const notifyUser = isOwner ? booking.renterId : booking.ownerId;
    await Notification.create({
      userId: notifyUser,
      type: 'general',
      title: 'Price Accepted',
      message: `The negotiated price of ₹${booking.proposedPrice} has been accepted!`,
      data: { bookingId: booking.id },
    });

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Alteration Status Update (Owner/Admin) ----
exports.updateAlterationStatus = async (req, res) => {
  try {
    const { alterationStatus } = req.body;
    if (!['none', 'requested', 'in_progress', 'completed'].includes(alterationStatus)) {
      return res.status(400).json({ error: 'Invalid alteration status' });
    }

    const booking = await Booking.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    await booking.update({ alterationStatus });

    await Notification.create({
      userId: booking.renterId,
      type: 'general',
      title: 'Alteration Update',
      message: alterationStatus === 'in_progress'
        ? 'Your alteration is in progress with the tailor!'
        : alterationStatus === 'completed'
          ? 'Your alteration is complete! Ready for pickup/delivery.'
          : `Alteration status updated to: ${alterationStatus}`,
      data: { bookingId: booking.id },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(booking.renterId).emit('notification', { type: 'alteration_update' });
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Return Status Update (Owner inspects returned item) ----
exports.updateReturnStatus = async (req, res) => {
  try {
    const { returnStatus, returnNote, depositAction } = req.body;
    if (!['pending', 'returned', 'damaged'].includes(returnStatus)) {
      return res.status(400).json({ error: 'Invalid return status' });
    }

    const booking = await Booking.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (!['accepted', 'active', 'completed'].includes(booking.status)) {
      return res.status(400).json({ error: 'Booking is not in a returnable state' });
    }

    const updates = { returnStatus, returnNote: returnNote || '' };

    // Handle security deposit based on return condition
    if (returnStatus === 'returned' && depositAction === 'refund' && booking.securityDepositStatus === 'paid') {
      updates.securityDepositStatus = 'refunded';
      const renterWallet = await Wallet.findOne({ where: { userId: booking.renterId } });
      if (renterWallet) {
        await renterWallet.update({ balance: renterWallet.balance + booking.securityDeposit });
        await WalletTransaction.create({
          walletId: renterWallet.id,
          type: 'refund',
          amount: booking.securityDeposit,
          description: 'Security deposit refunded - item returned in good condition',
          bookingId: booking.id,
        });
      }
    } else if (returnStatus === 'damaged' && booking.securityDepositStatus === 'paid') {
      const deduction = req.body.deductionAmount ? Math.min(Number(req.body.deductionAmount), booking.securityDeposit) : booking.securityDeposit;
      const refundAmount = booking.securityDeposit - deduction;
      updates.securityDepositStatus = 'deducted';

      if (refundAmount > 0) {
        const renterWallet = await Wallet.findOne({ where: { userId: booking.renterId } });
        if (renterWallet) {
          await renterWallet.update({ balance: renterWallet.balance + refundAmount });
          await WalletTransaction.create({
            walletId: renterWallet.id,
            type: 'refund',
            amount: refundAmount,
            description: `Partial security deposit refund (₹${deduction} deducted for damage)`,
            bookingId: booking.id,
          });
        }
      }

      // Credit deduction to owner
      let ownerWallet = await Wallet.findOne({ where: { userId: booking.ownerId } });
      if (!ownerWallet) ownerWallet = await Wallet.create({ userId: booking.ownerId, balance: 0 });
      await ownerWallet.update({ balance: ownerWallet.balance + deduction });
      await WalletTransaction.create({
        walletId: ownerWallet.id,
        type: 'credit',
        amount: deduction,
        description: `Damage deduction from security deposit`,
        bookingId: booking.id,
      });
    }

    await booking.update(updates);

    // Restore item quantity on successful return
    if (returnStatus === 'returned') {
      const item = await Item.findByPk(booking.itemId);
      if (item) {
        const newQty = item.quantity + (booking.quantity || 1);
        await item.update({ quantity: newQty, isAvailable: true });
      }
      await booking.update({ status: 'completed' });
    }

    await Notification.create({
      userId: booking.renterId,
      type: 'general',
      title: returnStatus === 'damaged' ? 'Return - Damage Reported' : 'Return Processed',
      message: returnStatus === 'damaged'
        ? `Damage was reported on your returned item. ${returnNote || ''}`.trim()
        : 'Your return has been processed successfully. Security deposit will be refunded.',
      data: { bookingId: booking.id },
    });

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
