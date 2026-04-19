const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { addMoneySchema, payForBookingSchema, createOrderSchema, verifyPaymentSchema, requestRefundSchema } = require('../schemas/wallet');
const {
  getWallet, addMoney, payForBooking, requestRefund,
  createOrder, verifyPayment, razorpayWebhook,
} = require('../controllers/walletController');

router.get('/', auth, getWallet);
router.post('/add', auth, validate(addMoneySchema), addMoney);
router.post('/pay', auth, validate(payForBookingSchema), payForBooking);
router.post('/refund', auth, validate(requestRefundSchema), requestRefund);
router.post('/create-order', auth, validate(createOrderSchema), createOrder);
router.post('/verify-payment', auth, validate(verifyPaymentSchema), verifyPayment);
router.post('/razorpay-webhook', express.raw({ type: 'application/json' }), razorpayWebhook);

module.exports = router;
