const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const {
  register, login, getProfile, updateProfile, updateLocation, getPublicProfile,
  addAddress, updateAddress, deleteAddress, setDefaultAddress,
  getUserItems, getUserReviews, becomeSeller, firebaseAuth,
} = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.post('/firebase-auth', firebaseAuth);
router.get('/profile', auth, getProfile);
router.patch('/profile', auth, upload.single('avatar'), updateProfile);
router.patch('/location', auth, updateLocation);

// Address routes
router.post('/address', auth, addAddress);
router.patch('/address/:addressId', auth, updateAddress);
router.delete('/address/:addressId', auth, deleteAddress);
router.patch('/address/:addressId/default', auth, setDefaultAddress);

// Become seller
router.patch('/become-seller', auth, becomeSeller);

// Seller profile routes
router.get('/user/:id', auth, getPublicProfile);
router.get('/user/:id/items', getUserItems);
router.get('/user/:id/reviews', getUserReviews);

module.exports = router;
