const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { getMySubscription, purchasePlan, getPlans } = require('../controllers/subscriptionController');

router.get('/plans', getPlans);
router.get('/', auth, getMySubscription);
router.post('/purchase', auth, purchasePlan);

module.exports = router;
