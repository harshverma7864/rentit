const { Booking, Item, Notification, NegotiationEntry, User, Wallet, WalletTransaction } = require('../models');
const { Op, Sequelize } = require('sequelize');
const sequelize = require('../config/database');
const { uploadToHosting } = require('../services/imageUpload');

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

    const booking = await sequelize.transaction({
      isolationLevel: Sequelize.Transaction.ISOLATION_LEVELS.SERIALIZABLE,
    }, async (t) => {
      const conflict = await Booking.findOne({
        where: {
          itemId,
          status: { [Op.in]: ['pending', 'accepted', 'active'] },
          startDate: { [Op.lte]: new Date(endDate) },
          endDate: { [Op.gte]: new Date(startDate) },
        },
        transaction: t,
      });
      if (conflict) throw new Error('Item is already booked for these dates');

      const start = new Date(startDate);
      const end = new Date(endDate);
      const days = Math.max(1, Math.ceil((end - start) / (1000 * 60 * 60 * 24)));
      const pricePerDay = parseFloat(item.pricePerDay);
      const deliveryFee = parseFloat(item.deliveryFee);
      const secDeposit = parseFloat(item.securityDeposit);
      const totalPrice = (days * pricePerDay + (deliveryOption === 'delivery' ? deliveryFee : 0)) * requestedQty;

      const newBooking = await Booking.create({
        itemId,
        renterId: req.user.id,
        ownerId: item.ownerId,
        startDate: start,
        endDate: end,
        quantity: requestedQty,
        totalPrice,
        securityDeposit: secDeposit * requestedQty,
        deliveryOption: deliveryOption || 'pickup',
        renterNote: renterNote || '',
        scheduledPickupTime: scheduledPickupTime ? new Date(scheduledPickupTime) : null,
        eventDate: eventDate ? new Date(eventDate) : null,
        renterSize: renterSize || '',
        sizeDetails: sizeDetails || {},
        alterationRequests: alterationRequests || '',
        alterationStatus: alterationRequests ? 'requested' : 'none',
        securityDepositStatus: 'unpaid',
      }, { transaction: t });

      await Notification.create({
        userId: item.ownerId,
        type: 'booking_request',
        title: 'New Rental Request',
        message: `${req.user.name} wants to rent your "${item.title}"`,
        data: { bookingId: newBooking.id, itemId: item.id },
      }, { transaction: t });

      return newBooking;
    });

    const io = req.app.get('io');
    if (io) {
      io.to(item.ownerId).emit('notification', { type: 'booking_request' });
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

    await sequelize.transaction(async (t) => {
      await booking.update({ status: 'completed' }, { transaction: t });

      const completedItem = await Item.findByPk(booking.itemId, { transaction: t });
      if (completedItem) {
        const newQty = completedItem.quantity + (booking.quantity || 1);
        await completedItem.update({ quantity: newQty, isAvailable: true }, { transaction: t });
      }

      if (booking.paymentStatus === 'paid' && parseFloat(booking.securityDeposit) > 0) {
        const renterWallet = await Wallet.findOne({
          where: { userId: booking.renterId },
          transaction: t,
          lock: t.LOCK.UPDATE,
        });
        if (renterWallet) {
          const currentBalance = parseFloat(renterWallet.balance);
          const deposit = parseFloat(booking.securityDeposit);
          await renterWallet.update({ balance: currentBalance + deposit }, { transaction: t });
          await WalletTransaction.create({
            walletId: renterWallet.id,
            type: 'refund',
            amount: deposit,
            description: 'Security deposit returned on rental completion',
            bookingId: booking.id,
          }, { transaction: t });
        }
      }

      const notifyUser = booking.ownerId === req.user.id ? booking.renterId : booking.ownerId;
      await Notification.create({
        userId: notifyUser,
        type: 'booking_completed',
        title: 'Rental Completed',
        message: 'The rental has been marked as completed.',
        data: { bookingId: booking.id },
      }, { transaction: t });
    });

    const notifyUser = booking.ownerId === req.user.id ? booking.renterId : booking.ownerId;
    const io = req.app.get('io');
    if (io) {
      io.to(notifyUser).emit('notification', { type: 'booking_completed' });
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
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

    if (booking.deliveryStatus === 'delivered') {
      return res.status(400).json({ error: 'Cannot cancel after delivery' });
    }

    const originalStatus = booking.status;

    await sequelize.transaction(async (t) => {
      if (booking.deliveryStatus === 'out_for_delivery') {
        const item = await Item.findByPk(booking.itemId, { transaction: t });
        const deliveryFee = item ? parseFloat(item.deliveryFee) : 0;

        if (booking.paymentStatus === 'paid') {
          const renterWallet = await Wallet.findOne({
            where: { userId: req.user.id },
            transaction: t,
            lock: t.LOCK.UPDATE,
          });
          if (renterWallet) {
            const currentBalance = parseFloat(renterWallet.balance);
            const refund = parseFloat(booking.totalPrice) + parseFloat(booking.securityDeposit) - deliveryFee;
            await renterWallet.update({ balance: currentBalance + refund }, { transaction: t });
            await WalletTransaction.create({
              walletId: renterWallet.id,
              type: 'refund',
              amount: refund,
              description: `Cancellation refund (delivery fee ₹${deliveryFee} deducted)`,
              bookingId: booking.id,
            }, { transaction: t });
          }
        }
        await booking.update({ status: 'cancelled', deliveryStatus: 'none' }, { transaction: t });
      } else {
        if (booking.paymentStatus === 'paid') {
          const renterWallet = await Wallet.findOne({
            where: { userId: req.user.id },
            transaction: t,
            lock: t.LOCK.UPDATE,
          });
          if (renterWallet) {
            const currentBalance = parseFloat(renterWallet.balance);
            const refund = parseFloat(booking.totalPrice) + parseFloat(booking.securityDeposit);
            await renterWallet.update({ balance: currentBalance + refund }, { transaction: t });
            await WalletTransaction.create({
              walletId: renterWallet.id,
              type: 'refund',
              amount: refund,
              description: 'Full cancellation refund',
              bookingId: booking.id,
            }, { transaction: t });
          }
        }
        await booking.update({ status: 'cancelled' }, { transaction: t });
      }

      if (['accepted', 'active'].includes(originalStatus)) {
        const cancelledItem = await Item.findByPk(booking.itemId, { transaction: t });
        if (cancelledItem) {
          const newQty = cancelledItem.quantity + (booking.quantity || 1);
          await cancelledItem.update({ quantity: newQty, isAvailable: true }, { transaction: t });
        }
      }

      await Notification.create({
        userId: booking.ownerId,
        type: 'booking_cancelled',
        title: 'Booking Cancelled',
        message: 'A rental request has been cancelled by the renter.',
        data: { bookingId: booking.id },
      }, { transaction: t });
    });

    const io = req.app.get('io');
    if (io) {
      io.to(booking.ownerId).emit('notification', { type: 'booking_cancelled' });
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
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
      include: [
        ...bookingIncludes,
        { model: NegotiationEntry, as: 'negotiationHistory', order: [['createdAt', 'ASC']] },
      ],
    });

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
        { model: NegotiationEntry, as: 'negotiationHistory', order: [['createdAt', 'ASC']] },
      ],
    });

    if (!booking) return res.status(404).json({ error: 'Booking not found' });

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

    const proposedPrice = parseFloat(booking.proposedPrice);
    await booking.update({
      negotiationStatus: 'accepted',
      finalPrice: proposedPrice,
      totalPrice: proposedPrice,
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

// ---- Return Status Update ----
exports.updateReturnStatus = async (req, res) => {
  try {
    const { returnStatus, returnNote, depositAction } = req.body;
    if (!['pending', 'returned', 'damaged'].includes(returnStatus)) {
      return res.status(400).json({ error: 'Invalid return status' });
    }

    // Renter can set to 'pending' (initiate return), owner handles 'returned'/'damaged'
    const booking = await Booking.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [{ ownerId: req.user.id }, { renterId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (!['accepted', 'active', 'completed'].includes(booking.status)) {
      return res.status(400).json({ error: 'Booking is not in a returnable state' });
    }

    const isOwner = booking.ownerId === req.user.id;
    const isRenter = booking.renterId === req.user.id;

    // Renter can only set to 'pending'
    if (isRenter && returnStatus !== 'pending') {
      return res.status(400).json({ error: 'Renter can only initiate return (set to pending)' });
    }
    // Owner handles 'returned' and 'damaged'
    if (isOwner && returnStatus === 'pending') {
      return res.status(400).json({ error: 'Owner cannot set return to pending — renter initiates return' });
    }

    await sequelize.transaction(async (t) => {
      const updates = { returnStatus, returnNote: returnNote || '' };

      // Handle security deposit based on return condition
      if (returnStatus === 'returned' && depositAction === 'refund' && booking.securityDepositStatus === 'paid') {
        updates.securityDepositStatus = 'refunded';
        const renterWallet = await Wallet.findOne({
          where: { userId: booking.renterId },
          transaction: t,
          lock: t.LOCK.UPDATE,
        });
        if (renterWallet) {
          const currentBalance = parseFloat(renterWallet.balance);
          const deposit = parseFloat(booking.securityDeposit);
          await renterWallet.update({ balance: currentBalance + deposit }, { transaction: t });
          await WalletTransaction.create({
            walletId: renterWallet.id,
            type: 'refund',
            amount: deposit,
            description: 'Security deposit refunded - item returned in good condition',
            bookingId: booking.id,
          }, { transaction: t });
        }
      } else if (returnStatus === 'damaged' && booking.securityDepositStatus === 'paid') {
        const deduction = req.body.deductionAmount ? Math.min(Number(req.body.deductionAmount), parseFloat(booking.securityDeposit)) : parseFloat(booking.securityDeposit);
        const refundAmount = parseFloat(booking.securityDeposit) - deduction;
        updates.securityDepositStatus = 'deducted';

        if (refundAmount > 0) {
          const renterWallet = await Wallet.findOne({
            where: { userId: booking.renterId },
            transaction: t,
            lock: t.LOCK.UPDATE,
          });
          if (renterWallet) {
            const currentBalance = parseFloat(renterWallet.balance);
            await renterWallet.update({ balance: currentBalance + refundAmount }, { transaction: t });
            await WalletTransaction.create({
              walletId: renterWallet.id,
              type: 'refund',
              amount: refundAmount,
              description: `Partial security deposit refund (₹${deduction} deducted for damage)`,
              bookingId: booking.id,
            }, { transaction: t });
          }
        }

        // Credit deduction to owner
        let ownerWallet = await Wallet.findOne({
          where: { userId: booking.ownerId },
          transaction: t,
          lock: t.LOCK.UPDATE,
        });
        if (!ownerWallet) {
          ownerWallet = await Wallet.create({ userId: booking.ownerId, balance: 0 }, { transaction: t });
        }
        const ownerBalance = parseFloat(ownerWallet.balance);
        await ownerWallet.update({ balance: ownerBalance + deduction }, { transaction: t });
        await WalletTransaction.create({
          walletId: ownerWallet.id,
          type: 'credit',
          amount: deduction,
          description: `Damage deduction from security deposit`,
          bookingId: booking.id,
        }, { transaction: t });
      }

      await booking.update(updates, { transaction: t });

      // Restore item quantity on successful return
      if (returnStatus === 'returned') {
        const item = await Item.findByPk(booking.itemId, { transaction: t });
        if (item) {
          const newQty = item.quantity + (booking.quantity || 1);
          await item.update({ quantity: newQty, isAvailable: true }, { transaction: t });
        }
        await booking.update({ status: 'completed' }, { transaction: t });
      }

      // Notification: renter initiates → notify owner. Owner processes → notify renter.
      if (returnStatus === 'pending') {
        await Notification.create({
          userId: booking.ownerId,
          type: 'general',
          title: 'Return Initiated',
          message: 'The renter wants to return the item. Please arrange pickup.',
          data: { bookingId: booking.id },
        }, { transaction: t });
      } else {
        await Notification.create({
          userId: booking.renterId,
          type: 'general',
          title: returnStatus === 'damaged' ? 'Return - Damage Reported' : 'Return Processed',
          message: returnStatus === 'damaged'
            ? `Damage was reported on your returned item. ${returnNote || ''}`.trim()
            : 'Your return has been processed successfully. Security deposit will be refunded.',
          data: { bookingId: booking.id },
        }, { transaction: t });
      }
    });

    // Socket notification
    const io = req.app.get('io');
    if (io) {
      const notifyUserId = returnStatus === 'pending' ? booking.ownerId : booking.renterId;
      io.to(notifyUserId).emit('notification', { type: 'return_update' });
    }

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Confirm Receipt (Renter uploads delivery proof image) ----
exports.confirmReceipt = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: { id: req.params.id, renterId: req.user.id },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.deliveryStatus !== 'out_for_delivery') {
      return res.status(400).json({ error: 'Booking is not out for delivery' });
    }
    if (!req.file) {
      return res.status(400).json({ error: 'Receipt image is required' });
    }

    const filename = await uploadToHosting(req.file.buffer, req.file.originalname, req.file.mimetype, `receipts/${booking.id}`);
    await booking.update({ deliveryStatus: 'delivered', receiptImage: filename });

    await Notification.create({
      userId: booking.ownerId,
      type: 'general',
      title: 'Item Received',
      message: 'The renter has confirmed receipt of your item.',
      data: { bookingId: booking.id },
    });

    const io = req.app.get('io');
    if (io) io.to(booking.ownerId).emit('notification', { type: 'receipt_confirmed' });

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Request Return (Owner requests renter to return overdue item) ----
exports.requestReturn = async (req, res) => {
  try {
    const booking = await Booking.findOne({
      where: { id: req.params.id, ownerId: req.user.id },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'active') {
      return res.status(400).json({ error: 'Booking is not active' });
    }
    if (new Date(booking.endDate) > new Date()) {
      return res.status(400).json({ error: 'Booking is not overdue' });
    }
    if (booking.returnRequested) {
      return res.status(400).json({ error: 'Return already requested' });
    }

    await booking.update({ returnRequested: true });

    await Notification.create({
      userId: booking.renterId,
      type: 'general',
      title: 'Return Requested',
      message: 'The owner has requested you return the item.',
      data: { bookingId: booking.id },
    });

    const io = req.app.get('io');
    if (io) io.to(booking.renterId).emit('notification', { type: 'return_requested' });

    const result = await Booking.findByPk(booking.id, { include: bookingIncludes });
    res.json({ booking: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
