const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const upload = require('../middleware/upload');
const { validate } = require('../middleware/validate');
const { createDisputeSchema } = require('../schemas/disputes');
const {
  createDispute, getMyDisputes, getDisputeById,
} = require('../controllers/disputeController');

router.post('/', auth, upload.array('images', 5), validate(createDisputeSchema), createDispute);
router.get('/', auth, getMyDisputes);
router.get('/:id', auth, getDisputeById);

module.exports = router;
