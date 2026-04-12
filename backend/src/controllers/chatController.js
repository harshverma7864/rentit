const Chat = require('../models/Chat');

// Regex patterns to block contact info and addresses in chat
const BLOCKED_PATTERNS = [
  /(\+?\d[\d\s\-]{7,14}\d)/,                                      // Phone numbers
  /[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/,            // Email addresses
  /\b\d+\s*(,\s*)?(street|st|road|rd|avenue|ave|lane|ln|drive|dr|flat|house|floor|block|sector|colony|nagar|plot|gali|mohalla|chowk|marg|path|way)\b/i, // Address patterns
];

function containsBlockedContent(text) {
  return BLOCKED_PATTERNS.some(pattern => pattern.test(text));
}

exports.getOrCreateChat = async (req, res) => {
  try {
    const { userId, itemId, bookingId } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const participants = [req.user._id, userId].sort();

    let filter = { participants: { $all: participants } };
    if (itemId) filter.item = itemId;

    let chat = await Chat.findOne(filter)
      .populate('participants', 'name avatar')
      .populate('item', 'title images');

    if (!chat) {
      chat = new Chat({
        participants,
        item: itemId || undefined,
        booking: bookingId || undefined,
      });
      await chat.save();
      await chat.populate('participants', 'name avatar');
      if (itemId) await chat.populate('item', 'title images');
    }

    res.json({ chat });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyChats = async (req, res) => {
  try {
    const chats = await Chat.find({ participants: req.user._id })
      .sort({ lastMessageAt: -1 })
      .populate('participants', 'name avatar')
      .populate('item', 'title images');

    res.json({ chats });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getChatMessages = async (req, res) => {
  try {
    const chat = await Chat.findOne({
      _id: req.params.id,
      participants: req.user._id,
    }).populate('messages.sender', 'name avatar');

    if (!chat) return res.status(404).json({ error: 'Chat not found' });

    res.json({ messages: chat.messages });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ error: 'Message text is required' });

    // Block contact details and addresses
    if (containsBlockedContent(text.trim())) {
      return res.status(400).json({ error: 'Cannot share contact details or addresses in chat. This is to protect both parties.' });
    }

    const chat = await Chat.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!chat) return res.status(404).json({ error: 'Chat not found' });

    const message = {
      sender: req.user._id,
      text: text.trim(),
      readBy: [req.user._id],
    };

    chat.messages.push(message);
    chat.lastMessage = text.trim();
    chat.lastMessageAt = new Date();
    await chat.save();

    const savedMessage = chat.messages[chat.messages.length - 1];

    res.status(201).json({
      message: {
        _id: savedMessage._id,
        sender: { _id: req.user._id, name: req.user.name, avatar: req.user.avatar },
        text: savedMessage.text,
        readBy: savedMessage.readBy,
        createdAt: savedMessage.createdAt,
      },
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.markChatRead = async (req, res) => {
  try {
    const chat = await Chat.findOne({
      _id: req.params.id,
      participants: req.user._id,
    });

    if (!chat) return res.status(404).json({ error: 'Chat not found' });

    chat.messages.forEach((msg) => {
      if (!msg.readBy.includes(req.user._id)) {
        msg.readBy.push(req.user._id);
      }
    });
    await chat.save();

    res.json({ message: 'Chat marked as read' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const chats = await Chat.find({ participants: req.user._id });
    let unreadCount = 0;
    chats.forEach((chat) => {
      chat.messages.forEach((msg) => {
        if (msg.sender.toString() !== req.user._id.toString() && !msg.readBy.includes(req.user._id)) {
          unreadCount++;
        }
      });
    });
    res.json({ unreadCount });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
