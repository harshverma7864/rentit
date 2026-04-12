const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getNotifications, markAsRead, markAllRead, getUnreadCount,
} = require('../controllers/notificationController');

router.get('/', auth, getNotifications);
router.get('/unread-count', auth, getUnreadCount);
router.patch('/read-all', auth, markAllRead);
router.patch('/:id/read', auth, markAsRead);

module.exports = router;
