const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const { register, login, getProfile, updateProfile, updateLocation, getPublicProfile } = require('../controllers/authController');

router.post('/register', register);
router.post('/login', login);
router.get('/profile', auth, getProfile);
router.patch('/profile', auth, upload.single('avatar'), updateProfile);
router.patch('/location', auth, updateLocation);
router.get('/user/:id', auth, getPublicProfile);

module.exports = router;
