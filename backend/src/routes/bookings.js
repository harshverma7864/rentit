const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const { validate } = require('../middleware/validate');
const { bookingLimiter } = require('../middleware/rateLimiter');
const { createBookingSchema, respondBookingSchema, negotiateSchema, deliveryStatusSchema, returnStatusSchema, confirmReceiptSchema, requestReturnSchema } = require('../schemas/bookings');
const {
  createBooking, respondToBooking, completeBooking,
  cancelBooking, getMyBookings, getBookingById, getItemBookings,
  updateDeliveryStatus, negotiatePrice, acceptNegotiation,
  updateAlterationStatus, updateReturnStatus,
  confirmReceipt, requestReturn,
} = require('../controllers/bookingController');

router.post('/', auth, bookingLimiter, validate(createBookingSchema), createBooking);
router.get('/', auth, getMyBookings);
router.get('/:id', auth, getBookingById);
router.patch('/:id/respond', auth, validate(respondBookingSchema), respondToBooking);
router.patch('/:id/complete', auth, completeBooking);
router.patch('/:id/cancel', auth, cancelBooking);
router.patch('/:id/delivery-status', auth, validate(deliveryStatusSchema), updateDeliveryStatus);
router.patch('/:id/negotiate', auth, validate(negotiateSchema), negotiatePrice);
router.patch('/:id/accept-negotiation', auth, acceptNegotiation);
router.patch('/:id/alteration-status', auth, updateAlterationStatus);
router.patch('/:id/return-status', auth, validate(returnStatusSchema), updateReturnStatus);
router.patch('/:id/confirm-receipt', auth, upload.single('image'), validate(confirmReceiptSchema), confirmReceipt);
router.patch('/:id/request-return', auth, validate(requestReturnSchema), requestReturn);
router.get('/item/:itemId', auth, getItemBookings);

module.exports = router;
