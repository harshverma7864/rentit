const { Dispute, Booking, Notification, User } = require('../models');
const { Op } = require('sequelize');
const { uploadToHosting } = require('../services/imageUpload');

exports.createDispute = async (req, res) => {
  try {
    const { bookingId, reason, description } = req.body;
    if (!bookingId || !reason || !description) {
      return res.status(400).json({ error: 'bookingId, reason, and description are required' });
    }

    const booking = await Booking.findOne({
      where: {
        id: bookingId,
        [Op.or]: [{ renterId: req.user.id }, { ownerId: req.user.id }],
      },
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    if (!['accepted', 'active', 'completed'].includes(booking.status)) {
      return res.status(400).json({ error: 'Can only raise disputes on accepted, active, or completed bookings' });
    }

    const existing = await Dispute.findOne({ where: { bookingId, raisedById: req.user.id } });
    if (existing) {
      return res.status(400).json({ error: 'You have already raised a dispute for this booking' });
    }

    const isRenter = booking.renterId === req.user.id;
    const againstUserId = isRenter ? booking.ownerId : booking.renterId;

    const images = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const filename = await uploadToHosting(file.buffer, file.originalname, file.mimetype, `disputes/${bookingId}`);
        images.push(filename);
      }
    }

    const dispute = await Dispute.create({
      bookingId,
      raisedById: req.user.id,
      againstUserId,
      reason,
      description,
      images,
    });

    await Notification.create({
      userId: againstUserId,
      type: 'dispute_raised',
      title: 'Dispute Raised',
      message: `A dispute has been raised against you for a booking. Reason: ${reason}`,
      data: { disputeId: dispute.id, bookingId },
    });

    if (req.app.get('io')) {
      req.app.get('io').to(againstUserId).emit('notification', { type: 'dispute_raised' });
    }

    const result = await Dispute.findByPk(dispute.id, {
      include: [
        { model: User, as: 'raisedBy', attributes: ['id', 'name', 'avatar'] },
        { model: User, as: 'againstUser', attributes: ['id', 'name', 'avatar'] },
        { model: Booking, as: 'booking', attributes: ['id', 'status', 'totalPrice'] },
      ],
    });

    res.status(201).json({ dispute: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyDisputes = async (req, res) => {
  try {
    const disputes = await Dispute.findAll({
      where: {
        [Op.or]: [{ raisedById: req.user.id }, { againstUserId: req.user.id }],
      },
      order: [['createdAt', 'DESC']],
      include: [
        { model: User, as: 'raisedBy', attributes: ['id', 'name', 'avatar'] },
        { model: User, as: 'againstUser', attributes: ['id', 'name', 'avatar'] },
        { model: Booking, as: 'booking', attributes: ['id', 'status', 'totalPrice'] },
      ],
    });

    res.json({ disputes });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getDisputeById = async (req, res) => {
  try {
    const dispute = await Dispute.findOne({
      where: {
        id: req.params.id,
        [Op.or]: [{ raisedById: req.user.id }, { againstUserId: req.user.id }],
      },
      include: [
        { model: User, as: 'raisedBy', attributes: ['id', 'name', 'avatar'] },
        { model: User, as: 'againstUser', attributes: ['id', 'name', 'avatar'] },
        { model: Booking, as: 'booking' },
      ],
    });

    if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
    res.json({ dispute });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
