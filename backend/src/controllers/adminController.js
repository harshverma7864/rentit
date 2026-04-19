const { User, Item, Booking, SellerApplication, Dispute, Notification, Wallet, WalletTransaction, Subscription } = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');
const bcrypt = require('bcryptjs');

// ---- Dashboard ----
exports.getDashboard = async (req, res) => {
  try {
    const [totalUsers, totalSellers, totalItems, pendingItems, pendingApps, activeBookings, revenueResult] = await Promise.all([
      User.count(),
      User.count({ where: { role: 'seller' } }),
      Item.count(),
      Item.count({ where: { approvalStatus: 'pending_approval' } }),
      SellerApplication.count({ where: { status: 'pending' } }),
      Booking.count({ where: { status: 'active' } }),
      WalletTransaction.sum('amount', { where: { type: 'payment' } }),
    ]);
    res.json({
      stats: {
        totalUsers,
        totalSellers,
        totalItems,
        pendingItems,
        pendingSellerApplications: pendingApps,
        activeBookings,
        totalRevenue: revenueResult || 0,
      },
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Items ----
exports.getItems = async (req, res) => {
  try {
    const { status = 'pending_approval', page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const { rows: items, count: total } = await Item.findAndCountAll({
      where: { approvalStatus: status },
      order: [['createdAt', 'DESC']],
      offset,
      limit: Number(limit),
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'email', 'phone'] }],
      paranoid: false,
    });
    res.json({ items, pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.approveItem = async (req, res) => {
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (!item) return res.status(404).json({ error: 'Item not found' });
    if (item.approvalStatus !== 'pending_approval') {
      return res.status(400).json({ error: 'Item is not in pending approval state' });
    }
    await item.update({ approvalStatus: 'approved' });
    await Notification.create({
      userId: item.ownerId,
      type: 'general',
      title: 'Item Approved',
      message: `Your item "${item.title}" has been approved and is now live.`,
      data: { itemId: item.id },
    });
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.rejectItem = async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (!item) return res.status(404).json({ error: 'Item not found' });
    if (item.approvalStatus !== 'pending_approval') {
      return res.status(400).json({ error: 'Item is not in pending approval state' });
    }
    await item.update({ approvalStatus: 'rejected', rejectionReason: rejectionReason || '' });
    await Notification.create({
      userId: item.ownerId,
      type: 'general',
      title: 'Item Rejected',
      message: `Your item "${item.title}" was rejected. Reason: ${rejectionReason || 'Not specified'}`,
      data: { itemId: item.id },
    });
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Seller Applications ----
exports.getSellerApplications = async (req, res) => {
  try {
    const { status = 'pending', page = 1, limit = 20 } = req.query;
    const offset = (Number(page) - 1) * Number(limit);
    const { rows: applications, count: total } = await SellerApplication.findAndCountAll({
      where: { status },
      order: [['createdAt', 'DESC']],
      offset,
      limit: Number(limit),
      include: [{ model: User, as: 'applicant', attributes: ['id', 'name', 'avatar', 'email', 'phone'] }],
    });
    res.json({ applications, pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.approveSellerApplication = async (req, res) => {
  try {
    const app = await SellerApplication.findByPk(req.params.id);
    if (!app) return res.status(404).json({ error: 'Application not found' });
    if (app.status !== 'pending') {
      return res.status(400).json({ error: 'Application is not pending' });
    }
    await app.update({ status: 'approved', reviewedBy: req.user.id, reviewedAt: new Date() });
    await User.update({ role: 'seller', isSeller: true }, { where: { id: app.userId } });
    await Notification.create({
      userId: app.userId,
      type: 'general',
      title: 'Seller Application Approved',
      message: 'Your seller application has been approved! You can now list items.',
      data: { applicationId: app.id },
    });
    res.json({ application: app });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.rejectSellerApplication = async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const app = await SellerApplication.findByPk(req.params.id);
    if (!app) return res.status(404).json({ error: 'Application not found' });
    if (app.status !== 'pending') {
      return res.status(400).json({ error: 'Application is not pending' });
    }
    await app.update({ status: 'rejected', rejectionReason: rejectionReason || '', reviewedBy: req.user.id, reviewedAt: new Date() });
    await Notification.create({
      userId: app.userId,
      type: 'general',
      title: 'Seller Application Rejected',
      message: `Your seller application was rejected. Reason: ${rejectionReason || 'Not specified'}`,
      data: { applicationId: app.id },
    });
    res.json({ application: app });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Users ----
exports.getUsers = async (req, res) => {
  try {
    const { role, page = 1, limit = 20, search } = req.query;
    const where = {};
    if (role) where.role = role;
    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
      ];
    }
    const offset = (Number(page) - 1) * Number(limit);
    const { rows: users, count: total } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      offset,
      limit: Number(limit),
      attributes: { exclude: ['password'] },
    });
    res.json({ users, pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Bookings ----
exports.getBookings = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const where = {};
    if (status) where.status = status;
    const offset = (Number(page) - 1) * Number(limit);
    const { rows: bookings, count: total } = await Booking.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      offset,
      limit: Number(limit),
      include: [
        { model: Item, as: 'item', attributes: ['id', 'title', 'images'] },
        { model: User, as: 'renter', attributes: ['id', 'name', 'avatar'] },
        { model: User, as: 'owner', attributes: ['id', 'name', 'avatar'] },
      ],
    });
    res.json({ bookings, pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Disputes ----
exports.getDisputes = async (req, res) => {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const where = {};
    if (status) where.status = status;
    const offset = (Number(page) - 1) * Number(limit);
    const { rows: disputes, count: total } = await Dispute.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      offset,
      limit: Number(limit),
      include: [
        { model: User, as: 'raisedBy', attributes: ['id', 'name', 'avatar'] },
        { model: User, as: 'againstUser', attributes: ['id', 'name', 'avatar'] },
        { model: Booking, as: 'booking', attributes: ['id', 'status', 'totalPrice'] },
      ],
    });
    res.json({ disputes, pagination: { page: Number(page), limit: Number(limit), total, pages: Math.ceil(total / Number(limit)) } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateDisputeStatus = async (req, res) => {
  try {
    const { status, resolution } = req.body;
    const dispute = await Dispute.findByPk(req.params.id);
    if (!dispute) return res.status(404).json({ error: 'Dispute not found' });
    const updates = { status };
    if (resolution) updates.resolution = resolution;
    await dispute.update(updates);
    res.json({ dispute });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Superadmin: Admin Management ----
exports.createAdmin = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;
    const existing = await User.findOne({
      where: { [Op.or]: [{ email: email.toLowerCase().trim() }, { phone }] },
    });
    if (existing) {
      return res.status(400).json({ error: 'Email or phone already exists' });
    }
    const user = await User.create({
      name,
      email: email.toLowerCase().trim(),
      password,
      phone,
      role: 'admin',
      isVerified: true,
    });
    res.status(201).json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getAdmins = async (req, res) => {
  try {
    const admins = await User.findAll({
      where: { role: 'admin' },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']],
    });
    res.json({ admins });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.changeUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.role === 'superadmin') {
      return res.status(400).json({ error: 'Cannot change superadmin role' });
    }
    await user.update({ role, isSeller: role === 'seller' || role === 'admin' || role === 'superadmin' });
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Superadmin: Full Access Endpoints ----

// Get single item with all details
exports.getItemDetail = async (req, res) => {
  try {
    const item = await Item.findByPk(req.params.id, {
      paranoid: false,
      include: [{ model: User, as: 'owner', attributes: { exclude: ['password'] } }],
    });
    if (!item) return res.status(404).json({ error: 'Item not found' });
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Edit any item (superadmin)
exports.editItem = async (req, res) => {
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (!item) return res.status(404).json({ error: 'Item not found' });

    const allowedFields = [
      'title', 'description', 'category', 'pricePerDay', 'pricePerHour', 'pricePerWeek',
      'price', 'securityDeposit', 'condition', 'isAvailable', 'quantity', 'tags', 'rules',
      'maxRentalDays', 'deliveryAvailable', 'deliveryFee', 'deliveryOptions', 'specs',
      'approvalStatus', 'rejectionReason',
    ];
    const updates = {};
    for (const key of allowedFields) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    await item.update(updates);
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Delete any item (superadmin, force delete)
exports.deleteItem = async (req, res) => {
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (!item) return res.status(404).json({ error: 'Item not found' });
    await item.destroy({ force: true });
    res.json({ message: 'Item permanently deleted' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Get single user with full details
exports.getUserDetail = async (req, res) => {
  try {
    const { Address, SellerApplication: SellerApp } = require('../models');
    const user = await User.findByPk(req.params.id, {
      attributes: { exclude: ['password'] },
      include: [
        { model: Address, as: 'addresses' },
        { model: SellerApp, as: 'sellerApplication' },
        { model: Wallet, as: 'wallet' },
        { model: Subscription, as: 'subscription' },
      ],
    });
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Get user's items, bookings counts
    const [itemCount, bookingCount, disputeCount] = await Promise.all([
      Item.count({ where: { ownerId: req.params.id }, paranoid: false }),
      Booking.count({ where: { [Op.or]: [{ renterId: req.params.id }, { ownerId: req.params.id }] } }),
      Dispute.count({ where: { [Op.or]: [{ raisedById: req.params.id }, { againstUserId: req.params.id }] } }),
    ]);

    const userJson = user.toJSON();
    userJson.itemCount = itemCount;
    userJson.bookingCount = bookingCount;
    userJson.disputeCount = disputeCount;
    res.json({ user: userJson });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Edit any user (superadmin)
exports.editUser = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    if (user.role === 'superadmin' && req.user.id !== user.id) {
      return res.status(400).json({ error: 'Cannot edit another superadmin' });
    }

    const allowedFields = ['name', 'email', 'phone', 'role', 'isSeller', 'isVerified', 'rating'];
    const updates = {};
    for (const key of allowedFields) {
      if (req.body[key] !== undefined) updates[key] = req.body[key];
    }
    if (updates.role) {
      updates.isSeller = ['seller', 'admin', 'superadmin'].includes(updates.role);
    }
    await user.update(updates);
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Get single booking with full details
exports.getBookingDetail = async (req, res) => {
  try {
    const { NegotiationEntry } = require('../models');
    const booking = await Booking.findByPk(req.params.id, {
      include: [
        { model: Item, as: 'item' },
        { model: User, as: 'renter', attributes: { exclude: ['password'] } },
        { model: User, as: 'owner', attributes: { exclude: ['password'] } },
        { model: NegotiationEntry, as: 'negotiationHistory', order: [['createdAt', 'ASC']] },
      ],
    });
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Update any booking status (superadmin)
exports.updateBookingStatus = async (req, res) => {
  try {
    const { status, deliveryStatus, returnStatus, paymentStatus } = req.body;
    const booking = await Booking.findByPk(req.params.id);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });

    const updates = {};
    if (status) updates.status = status;
    if (deliveryStatus) updates.deliveryStatus = deliveryStatus;
    if (returnStatus) updates.returnStatus = returnStatus;
    if (paymentStatus) updates.paymentStatus = paymentStatus;
    await booking.update(updates);
    res.json({ booking });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// Credit/debit any user's wallet (superadmin)
exports.adjustWallet = async (req, res) => {
  try {
    const { userId, amount, type, description } = req.body;
    if (!userId || !amount || !type) {
      return res.status(400).json({ error: 'userId, amount, and type are required' });
    }

    let wallet = await Wallet.findOne({ where: { userId } });
    if (!wallet) {
      wallet = await Wallet.create({ userId, balance: 0 });
    }

    const currentBalance = parseFloat(wallet.balance);
    const adjustAmount = parseFloat(amount);
    const newBalance = type === 'credit' ? currentBalance + adjustAmount : currentBalance - adjustAmount;

    await wallet.update({ balance: newBalance });
    await WalletTransaction.create({
      walletId: wallet.id,
      type,
      amount: adjustAmount,
      description: description || `Admin ${type} adjustment`,
    });

    res.json({ wallet, newBalance });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
