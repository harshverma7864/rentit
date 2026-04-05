const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createBooking, respondToBooking, completeBooking,
  cancelBooking, getMyBookings, getBookingById, getItemBookings,
  updateDeliveryStatus, negotiatePrice, acceptNegotiation,
} = require('../controllers/bookingController');

router.post('/', auth, createBooking);
router.get('/', auth, getMyBookings);
router.get('/:id', auth, getBookingById);
router.patch('/:id/respond', auth, respondToBooking);
router.patch('/:id/complete', auth, completeBooking);
router.patch('/:id/cancel', auth, cancelBooking);
router.patch('/:id/delivery-status', auth, updateDeliveryStatus);
router.patch('/:id/negotiate', auth, negotiatePrice);
router.patch('/:id/accept-negotiation', auth, acceptNegotiation);
router.get('/item/:itemId', auth, getItemBookings);

module.exports = router;
