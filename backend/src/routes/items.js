const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const {
  createItem, getItems, getItemById,
  updateItem, deleteItem, getMyItems, getCategories,
  boostItem, getBoostTiers, getRecommended,
} = require('../controllers/itemController');

router.get('/categories', getCategories);
router.get('/recommended', getRecommended);
router.get('/boost-tiers', getBoostTiers);
router.get('/', getItems);
router.get('/mine', auth, getMyItems);
router.get('/:id', getItemById);
router.post('/', auth, upload.array('images', 5), createItem);
router.post('/:id/boost', auth, boostItem);
router.patch('/:id', auth, upload.array('images', 5), updateItem);
router.delete('/:id', auth, deleteItem);

module.exports = router;
