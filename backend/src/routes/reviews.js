const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createReview, getReviewsForUser, getMyReviews,
  createItemReview, getItemReviews,
} = require('../controllers/reviewController');

router.post('/', auth, createReview);
router.get('/mine', auth, getMyReviews);
router.get('/user/:userId', getReviewsForUser);
router.post('/item/:itemId', auth, createItemReview);
router.get('/item/:itemId', getItemReviews);

module.exports = router;
