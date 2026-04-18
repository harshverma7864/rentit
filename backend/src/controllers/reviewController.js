const { Review, Booking, User } = require('../models');

exports.createReview = async (req, res) => {
  try {
    const { bookingId, rating, comment } = req.body;
    if (!bookingId || !rating) {
      return res.status(400).json({ error: 'bookingId and rating are required' });
    }
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const booking = await Booking.findByPk(bookingId);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'completed') {
      return res.status(400).json({ error: 'Can only review completed bookings' });
    }

    const isRenter = booking.renterId === req.user.id;
    const isOwner = booking.ownerId === req.user.id;
    if (!isRenter && !isOwner) {
      return res.status(403).json({ error: 'Not authorized to review this booking' });
    }

    const revieweeId = isRenter ? booking.ownerId : booking.renterId;

    const existing = await Review.findOne({ where: { bookingId, reviewerId: req.user.id } });
    if (existing) {
      return res.status(400).json({ error: 'You have already reviewed this booking' });
    }

    const review = await Review.create({
      reviewerId: req.user.id,
      revieweeId,
      bookingId,
      rating,
      comment: comment || '',
    });

    // Update average rating
    const allReviews = await Review.findAll({ where: { revieweeId } });
    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
    await User.update(
      { rating: Math.round(avgRating * 10) / 10, totalRatings: allReviews.length },
      { where: { id: revieweeId } }
    );

    const result = await Review.findByPk(review.id, {
      include: [{ model: User, as: 'reviewer', attributes: ['id', 'name', 'avatar'] }],
    });
    res.status(201).json({ review: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getReviewsForUser = async (req, res) => {
  try {
    const reviews = await Review.findAll({
      where: { revieweeId: req.params.userId },
      order: [['createdAt', 'DESC']],
      include: [{ model: User, as: 'reviewer', attributes: ['id', 'name', 'avatar'] }],
    });
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyReviews = async (req, res) => {
  try {
    const reviews = await Review.findAll({
      where: { revieweeId: req.user.id },
      order: [['createdAt', 'DESC']],
      include: [{ model: User, as: 'reviewer', attributes: ['id', 'name', 'avatar'] }],
    });
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
