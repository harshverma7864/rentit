const express = require('express');
const router = express.Router();
const auth = require('../middleware/auth');
const {
  getNotifications, markAsRead, markAllRead, getUnreadCount,
} = require('../controllers/notificationController');

router.get('/', auth, getNotifications);
router.get('/unread-count', auth, getUnreadCount);
router.patch('/:id/read', auth, markAsRead);
router.patch('/read-all', auth, markAllRead);

module.exports = router;
