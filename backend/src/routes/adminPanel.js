const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Op } = require('sequelize');
const {
  User, Item, Booking, SellerApplication, Dispute,
  Notification, WalletTransaction,
} = require('../models');

// ---------- Helpers ----------

// Verify JWT from cookie, attach user to req
const panelAuth = async (req, res, next) => {
  try {
    const token = req.cookies && req.cookies.admin_token;
    if (!token) return res.redirect('/admin/login');
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findByPk(decoded.userId, {
      attributes: ['id', 'name', 'email', 'role'],
    });
    if (!user || !['admin', 'superadmin'].includes(user.role)) {
      res.clearCookie('admin_token');
      return res.redirect('/admin/login');
    }
    req.adminUser = user;
    next();
  } catch (err) {
    res.clearCookie('admin_token');
    return res.redirect('/admin/login');
  }
};

// ---------- Login ----------

router.get('/login', (req, res) => {
  res.render('admin/login', { error: null });
});

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.render('admin/login', { error: 'Email and password are required.' });
    }
    const user = await User.findOne({ where: { email: email.toLowerCase().trim() } });
    if (!user || !['admin', 'superadmin'].includes(user.role)) {
      return res.render('admin/login', { error: 'Invalid credentials or insufficient privileges.' });
    }
    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      return res.render('admin/login', { error: 'Invalid credentials or insufficient privileges.' });
    }
    const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '24h' });
    res.cookie('admin_token', token, { httpOnly: true, maxAge: 24 * 60 * 60 * 1000, sameSite: 'lax' });
    return res.redirect('/admin');
  } catch (err) {
    return res.render('admin/login', { error: 'Something went wrong. Please try again.' });
  }
});

// ---------- Logout ----------

router.get('/logout', (req, res) => {
  res.clearCookie('admin_token');
  res.redirect('/admin/login');
});

// ---------- All panel routes below require auth ----------
router.use(panelAuth);

// ---------- Dashboard ----------

router.get('/', async (req, res) => {
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
    res.render('admin/dashboard', {
      adminUser: req.adminUser,
      stats: { totalUsers, totalSellers, totalItems, pendingItems, pendingSellerApplications: pendingApps, activeBookings, totalRevenue: revenueResult || 0 },
    });
  } catch (err) {
    res.render('admin/dashboard', { adminUser: req.adminUser, stats: { totalUsers: 0, totalSellers: 0, totalItems: 0, pendingItems: 0, pendingSellerApplications: 0, activeBookings: 0, totalRevenue: 0 } });
  }
});

// ---------- Items ----------

router.get('/items', async (req, res) => {
  try {
    const { status = 'pending_approval', page = 1 } = req.query;
    const limit = 20;
    const offset = (Number(page) - 1) * limit;
    const { rows: items, count: total } = await Item.findAndCountAll({
      where: { approvalStatus: status },
      order: [['createdAt', 'DESC']],
      offset,
      limit,
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'email', 'phone'] }],
      paranoid: false,
    });
    res.render('admin/items', {
      adminUser: req.adminUser,
      items,
      status,
      pagination: { page: Number(page), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.render('admin/items', { adminUser: req.adminUser, items: [], status: 'pending_approval', pagination: { page: 1, total: 0, pages: 0 } });
  }
});

// ---------- Seller Applications ----------

router.get('/seller-applications', async (req, res) => {
  try {
    const { status = 'pending', page = 1 } = req.query;
    const limit = 20;
    const offset = (Number(page) - 1) * limit;
    const { rows: applications, count: total } = await SellerApplication.findAndCountAll({
      where: { status },
      order: [['createdAt', 'DESC']],
      offset,
      limit,
      include: [{ model: User, as: 'applicant', attributes: ['id', 'name', 'email', 'phone'] }],
    });
    res.render('admin/seller-applications', {
      adminUser: req.adminUser,
      applications,
      status,
      pagination: { page: Number(page), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.render('admin/seller-applications', { adminUser: req.adminUser, applications: [], status: 'pending', pagination: { page: 1, total: 0, pages: 0 } });
  }
});

// ---------- Users ----------

router.get('/users', async (req, res) => {
  try {
    const { role = '', search = '', page = 1 } = req.query;
    const limit = 20;
    const offset = (Number(page) - 1) * limit;
    const where = {};
    if (role) where.role = role;
    if (search) {
      where[Op.or] = [
        { name: { [Op.iLike]: `%${search}%` } },
        { email: { [Op.iLike]: `%${search}%` } },
        { phone: { [Op.iLike]: `%${search}%` } },
      ];
    }
    const { rows: users, count: total } = await User.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      offset,
      limit,
      attributes: { exclude: ['password'] },
    });
    res.render('admin/users', {
      adminUser: req.adminUser,
      users,
      role,
      search,
      pagination: { page: Number(page), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.render('admin/users', { adminUser: req.adminUser, users: [], role: '', search: '', pagination: { page: 1, total: 0, pages: 0 } });
  }
});

// ---------- Disputes ----------

router.get('/disputes', async (req, res) => {
  try {
    const { status = 'open', page = 1 } = req.query;
    const limit = 20;
    const offset = (Number(page) - 1) * limit;
    const { rows: disputes, count: total } = await Dispute.findAndCountAll({
      where: { status },
      order: [['createdAt', 'DESC']],
      offset,
      limit,
      include: [
        { model: User, as: 'raisedBy', attributes: ['id', 'name'] },
        { model: User, as: 'againstUser', attributes: ['id', 'name'] },
        { model: Booking, as: 'booking', attributes: ['id', 'status', 'totalPrice'] },
      ],
    });
    res.render('admin/disputes', {
      adminUser: req.adminUser,
      disputes,
      status,
      pagination: { page: Number(page), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.render('admin/disputes', { adminUser: req.adminUser, disputes: [], status: 'open', pagination: { page: 1, total: 0, pages: 0 } });
  }
});

// ---------- Bookings ----------

router.get('/bookings', async (req, res) => {
  try {
    const { status, page = 1 } = req.query;
    const limit = 20;
    const offset = (Number(page) - 1) * limit;
    const where = {};
    if (status) where.status = status;
    const { rows: bookings, count: total } = await Booking.findAndCountAll({
      where,
      order: [['createdAt', 'DESC']],
      offset,
      limit,
      include: [
        { model: Item, as: 'item', attributes: ['id', 'title', 'images'] },
        { model: User, as: 'renter', attributes: ['id', 'name'] },
        { model: User, as: 'owner', attributes: ['id', 'name'] },
      ],
    });
    res.render('admin/bookings', {
      adminUser: req.adminUser,
      bookings,
      status: status || '',
      pagination: { page: Number(page), total, pages: Math.ceil(total / limit) },
    });
  } catch (err) {
    res.render('admin/bookings', { adminUser: req.adminUser, bookings: [], status: '', pagination: { page: 1, total: 0, pages: 0 } });
  }
});

// ---------- Admins (superadmin only) ----------

router.get('/admins', async (req, res) => {
  if (req.adminUser.role !== 'superadmin') return res.redirect('/admin');
  try {
    const admins = await User.findAll({
      where: { role: 'admin' },
      attributes: { exclude: ['password'] },
      order: [['createdAt', 'DESC']],
    });
    res.render('admin/admins', { adminUser: req.adminUser, admins, error: null, success: null });
  } catch (err) {
    res.render('admin/admins', { adminUser: req.adminUser, admins: [], error: 'Failed to load admins.', success: null });
  }
});

router.post('/admins/create', async (req, res) => {
  if (req.adminUser.role !== 'superadmin') return res.redirect('/admin');
  try {
    const { name, email, password, phone } = req.body;
    const existing = await User.findOne({
      where: { [Op.or]: [{ email: email.toLowerCase().trim() }, { phone }] },
    });
    if (existing) {
      const admins = await User.findAll({ where: { role: 'admin' }, attributes: { exclude: ['password'] } });
      return res.render('admin/admins', { adminUser: req.adminUser, admins, error: 'Email or phone already exists.', success: null });
    }
    await User.create({ name, email: email.toLowerCase().trim(), password, phone, role: 'admin', isVerified: true });
    const admins = await User.findAll({ where: { role: 'admin' }, attributes: { exclude: ['password'] }, order: [['createdAt', 'DESC']] });
    res.render('admin/admins', { adminUser: req.adminUser, admins, error: null, success: 'Admin created successfully.' });
  } catch (err) {
    const admins = await User.findAll({ where: { role: 'admin' }, attributes: { exclude: ['password'] } }).catch(() => []);
    res.render('admin/admins', { adminUser: req.adminUser, admins, error: err.message, success: null });
  }
});

// ---------- Action routes (approve/reject via POST forms) ----------

router.post('/action/items/:id/approve', async (req, res) => {
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (item && item.approvalStatus === 'pending_approval') {
      await item.update({ approvalStatus: 'approved' });
      await Notification.create({
        userId: item.ownerId, type: 'general', title: 'Item Approved',
        message: `Your item "${item.title}" has been approved and is now live.`,
        data: { itemId: item.id },
      });
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/items?status=pending_approval');
});

router.post('/action/items/:id/reject', async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (item && item.approvalStatus === 'pending_approval') {
      await item.update({ approvalStatus: 'rejected', rejectionReason: rejectionReason || '' });
      await Notification.create({
        userId: item.ownerId, type: 'general', title: 'Item Rejected',
        message: `Your item "${item.title}" was rejected. Reason: ${rejectionReason || 'Not specified'}`,
        data: { itemId: item.id },
      });
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/items?status=pending_approval');
});

router.post('/action/seller-applications/:id/approve', async (req, res) => {
  try {
    const app = await SellerApplication.findByPk(req.params.id);
    if (app && app.status === 'pending') {
      await app.update({ status: 'approved', reviewedBy: req.adminUser.id, reviewedAt: new Date() });
      await User.update({ role: 'seller', isSeller: true }, { where: { id: app.userId } });
      await Notification.create({
        userId: app.userId, type: 'general', title: 'Seller Application Approved',
        message: 'Your seller application has been approved! You can now list items.',
        data: { applicationId: app.id },
      });
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/seller-applications?status=pending');
});

router.post('/action/seller-applications/:id/reject', async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    const app = await SellerApplication.findByPk(req.params.id);
    if (app && app.status === 'pending') {
      await app.update({ status: 'rejected', rejectionReason: rejectionReason || '', reviewedBy: req.adminUser.id, reviewedAt: new Date() });
      await Notification.create({
        userId: app.userId, type: 'general', title: 'Seller Application Rejected',
        message: `Your seller application was rejected. Reason: ${rejectionReason || 'Not specified'}`,
        data: { applicationId: app.id },
      });
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/seller-applications?status=pending');
});

router.post('/action/disputes/:id/status', async (req, res) => {
  try {
    const { status, resolution } = req.body;
    const dispute = await Dispute.findByPk(req.params.id);
    if (dispute) {
      const updates = { status };
      if (resolution) updates.resolution = resolution;
      await dispute.update(updates);
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/disputes?status=open');
});

// ---------- Superadmin: Item Detail & Edit ----------

router.get('/items/:id', async (req, res) => {
  if (req.adminUser.role !== 'superadmin') return res.redirect('/admin/items');
  try {
    const item = await Item.findByPk(req.params.id, {
      paranoid: false,
      include: [{ model: User, as: 'owner', attributes: { exclude: ['password'] } }],
    });
    if (!item) return res.redirect('/admin/items');
    res.render('admin/item-detail', { adminUser: req.adminUser, item });
  } catch (err) {
    res.redirect('/admin/items');
  }
});

router.post('/action/items/:id/edit', async (req, res) => {
  if (req.adminUser.role !== 'superadmin') return res.redirect('/admin/items');
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (item) {
      const updates = {};
      const fields = ['title', 'description', 'category', 'condition', 'approvalStatus'];
      for (const f of fields) {
        if (req.body[f] !== undefined) updates[f] = req.body[f];
      }
      if (req.body.pricePerDay) updates.pricePerDay = Number(req.body.pricePerDay);
      if (req.body.securityDeposit) updates.securityDeposit = Number(req.body.securityDeposit);
      if (req.body.quantity) updates.quantity = Number(req.body.quantity);
      if (req.body.isAvailable !== undefined) updates.isAvailable = req.body.isAvailable === 'true';
      await item.update(updates);
    }
  } catch (err) { /* ignore */ }
  res.redirect('/admin/items/' + req.params.id);
});

router.post('/action/items/:id/delete', async (req, res) => {
  if (req.adminUser.role !== 'superadmin') return res.redirect('/admin/items');
  try {
    const item = await Item.findByPk(req.params.id, { paranoid: false });
    if (item) await item.destroy({ force: true });
  } catch (err) { /* ignore */ }
  res.redirect('/admin/items?status=approved');
});

module.exports = router;
