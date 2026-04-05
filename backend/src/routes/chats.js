const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getOrCreateChat, getMyChats, getChatMessages,
  sendMessage, markChatRead, getUnreadCount,
} = require('../controllers/chatController');

router.post('/', auth, getOrCreateChat);
router.get('/', auth, getMyChats);
router.get('/unread-count', auth, getUnreadCount);
router.get('/:id/messages', auth, getChatMessages);
router.post('/:id/messages', auth, sendMessage);
router.patch('/:id/read', auth, markChatRead);

module.exports = router;
