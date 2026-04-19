const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const { validate } = require('../middleware/validate');
const { authLimiter } = require('../middleware/rateLimiter');
const { registerSchema, loginSchema, firebaseAuthSchema, updateLocationSchema, addAddressSchema } = require('../schemas/auth');
const {
  register, login, getProfile, updateProfile, updateLocation, getPublicProfile,
  addAddress, updateAddress, deleteAddress, setDefaultAddress,
  getUserItems, getUserReviews, submitSellerApplication, getSellerApplication, firebaseAuth,
} = require('../controllers/authController');

router.post('/register', authLimiter, validate(registerSchema), register);
router.post('/login', authLimiter, validate(loginSchema), login);
router.post('/firebase-auth', authLimiter, validate(firebaseAuthSchema), firebaseAuth);
router.get('/profile', auth, getProfile);
router.patch('/profile', auth, upload.single('avatar'), updateProfile);
router.patch('/location', auth, validate(updateLocationSchema), updateLocation);

// Address routes
router.post('/address', auth, validate(addAddressSchema), addAddress);
router.patch('/address/:addressId', auth, updateAddress);
router.delete('/address/:addressId', auth, deleteAddress);
router.patch('/address/:addressId/default', auth, setDefaultAddress);

// Seller application
router.post('/seller-application', auth, upload.array('images', 4), submitSellerApplication);
router.get('/seller-application', auth, getSellerApplication);

// Seller profile routes
router.get('/user/:id', auth, getPublicProfile);
router.get('/user/:id/items', getUserItems);
router.get('/user/:id/reviews', getUserReviews);

module.exports = router;
