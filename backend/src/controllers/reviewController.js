const Review = require('../models/Review');
const Booking = require('../models/Booking');
const User = require('../models/User');

exports.createReview = async (req, res) => {
  try {
    const { bookingId, rating, comment } = req.body;
    if (!bookingId || !rating) {
      return res.status(400).json({ error: 'bookingId and rating are required' });
    }
    if (rating < 1 || rating > 5) {
      return res.status(400).json({ error: 'Rating must be between 1 and 5' });
    }

    const booking = await Booking.findById(bookingId);
    if (!booking) return res.status(404).json({ error: 'Booking not found' });
    if (booking.status !== 'completed') {
      return res.status(400).json({ error: 'Can only review completed bookings' });
    }

    const isRenter = booking.renter.toString() === req.user._id.toString();
    const isOwner = booking.owner.toString() === req.user._id.toString();
    if (!isRenter && !isOwner) {
      return res.status(403).json({ error: 'Not authorized to review this booking' });
    }

    // Renter reviews owner (seller), owner reviews renter
    const reviewee = isRenter ? booking.owner : booking.renter;

    // Check if already reviewed
    const existing = await Review.findOne({ booking: bookingId, reviewer: req.user._id });
    if (existing) {
      return res.status(400).json({ error: 'You have already reviewed this booking' });
    }

    const review = new Review({
      reviewer: req.user._id,
      reviewee,
      booking: bookingId,
      rating,
      comment: comment || '',
    });
    await review.save();

    // Update the reviewee's average rating
    const allReviews = await Review.find({ reviewee });
    const avgRating = allReviews.reduce((sum, r) => sum + r.rating, 0) / allReviews.length;
    await User.findByIdAndUpdate(reviewee, {
      rating: Math.round(avgRating * 10) / 10,
      totalRatings: allReviews.length,
    });

    await review.populate('reviewer', 'name avatar');
    res.status(201).json({ review });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getReviewsForUser = async (req, res) => {
  try {
    const reviews = await Review.find({ reviewee: req.params.userId })
      .sort({ createdAt: -1 })
      .populate('reviewer', 'name avatar');
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ reviewee: req.user._id })
      .sort({ createdAt: -1 })
      .populate('reviewer', 'name avatar');
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
