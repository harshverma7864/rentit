const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { adminOnly, superadminOnly } = require('../middleware/admin');
const {
  getDashboard, getItems, approveItem, rejectItem,
  getSellerApplications, approveSellerApplication, rejectSellerApplication,
  getUsers, getBookings, getDisputes, updateDisputeStatus,
  createAdmin, getAdmins, changeUserRole,
  getItemDetail, editItem, deleteItem,
  getUserDetail, editUser,
  getBookingDetail, updateBookingStatus,
  adjustWallet,
} = require('../controllers/adminController');

// All routes require auth + admin
router.use(auth, adminOnly);

router.get('/dashboard', getDashboard);
router.get('/items', getItems);
router.patch('/items/:id/approve', approveItem);
router.patch('/items/:id/reject', rejectItem);
router.get('/seller-applications', getSellerApplications);
router.patch('/seller-applications/:id/approve', approveSellerApplication);
router.patch('/seller-applications/:id/reject', rejectSellerApplication);
router.get('/users', getUsers);
router.get('/bookings', getBookings);
router.get('/disputes', getDisputes);
router.patch('/disputes/:id/status', updateDisputeStatus);

// Superadmin only — full access
router.post('/create-admin', superadminOnly, createAdmin);
router.get('/admins', superadminOnly, getAdmins);
router.patch('/users/:id/role', superadminOnly, changeUserRole);
router.get('/items/:id', superadminOnly, getItemDetail);
router.patch('/items/:id/edit', superadminOnly, editItem);
router.delete('/items/:id', superadminOnly, deleteItem);
router.get('/users/:id', superadminOnly, getUserDetail);
router.patch('/users/:id/edit', superadminOnly, editUser);
router.get('/bookings/:id', superadminOnly, getBookingDetail);
router.patch('/bookings/:id/status', superadminOnly, updateBookingStatus);
router.post('/wallet/adjust', superadminOnly, adjustWallet);

module.exports = router;
