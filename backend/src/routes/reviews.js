const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { createReview, getReviewsForUser, getMyReviews } = require('../controllers/reviewController');

router.post('/', auth, createReview);
router.get('/mine', auth, getMyReviews);
router.get('/user/:userId', getReviewsForUser);

module.exports = router;
