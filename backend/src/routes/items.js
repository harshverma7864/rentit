const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  createItem, getItems, getItemById,
  updateItem, deleteItem, getMyItems, getCategories,
} = require('../controllers/itemController');

router.get('/categories', getCategories);
router.get('/', getItems);
router.get('/mine', auth, getMyItems);
router.get('/:id', getItemById);
router.post('/', auth, createItem);
router.patch('/:id', auth, updateItem);
router.delete('/:id', auth, deleteItem);

module.exports = router;
