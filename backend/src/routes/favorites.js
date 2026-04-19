const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { toggleFavorite, getMyFavorites, checkFavorite } = require('../controllers/favoriteController');

router.get('/', auth, getMyFavorites);
router.get('/:itemId/check', auth, checkFavorite);
router.post('/:itemId/toggle', auth, toggleFavorite);

module.exports = router;
