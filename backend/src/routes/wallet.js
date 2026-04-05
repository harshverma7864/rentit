const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getWallet, addMoney, payForBooking, requestRefund,
} = require('../controllers/walletController');

router.get('/', auth, getWallet);
router.post('/add', auth, addMoney);
router.post('/pay', auth, payForBooking);
router.post('/refund', auth, requestRefund);

module.exports = router;
