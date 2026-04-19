const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const { validate } = require('../middleware/validate');
const { chatLimiter } = require('../middleware/rateLimiter');
const { createChatSchema, sendMessageSchema } = require('../schemas/chats');
const {
  getOrCreateChat, getMyChats, getChatMessages,
  sendMessage, markChatRead, getUnreadCount,
} = require('../controllers/chatController');

router.post('/', auth, validate(createChatSchema), getOrCreateChat);
router.get('/', auth, getMyChats);
router.get('/unread-count', auth, getUnreadCount);
router.get('/:id/messages', auth, getChatMessages);
router.post('/:id/messages', auth, chatLimiter, validate(sendMessageSchema), sendMessage);
router.patch('/:id/read', auth, markChatRead);

module.exports = router;
