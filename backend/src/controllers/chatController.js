const { Chat, ChatParticipant, Message, User, Item } = require('../models');
const { Op, QueryTypes } = require('sequelize');
const sequelize = require('../config/database');

// Regex patterns to block contact info and addresses in chat
const BLOCKED_PATTERNS = [
  /(\+?\d[\d\s\-]{7,14}\d)/,
  /[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}/,
  /\b\d+\s*(,\s*)?(street|st|road|rd|avenue|ave|lane|ln|drive|dr|flat|house|floor|block|sector|colony|nagar|plot|gali|mohalla|chowk|marg|path|way)\b/i,
];

/**
 * Best-effort contact information blocking.
 *
 * LIMITATIONS: This regex-based approach is a deterrent, not a security boundary.
 * Determined users can bypass it by:
 * - Spelling out numbers ("nine eight seven six five...")
 * - Using Unicode lookalike characters
 * - Inserting zero-width characters between digits
 * - Using creative formatting ("9-8-7-6-5-4-3-2-1-0")
 * - Sharing contact info via images (not scanned)
 *
 * FUTURE: For stronger enforcement, consider server-side ML-based content
 * moderation (e.g., Google Cloud Natural Language API) or human review queues.
 */
function containsBlockedContent(text) {
  return BLOCKED_PATTERNS.some(pattern => pattern.test(text));
}

exports.getOrCreateChat = async (req, res) => {
  try {
    const { userId, itemId, bookingId } = req.body;
    if (!userId) return res.status(400).json({ error: 'userId is required' });

    const participantIds = [req.user.id, userId].sort();

    // Find existing chat between these two users (optionally for a specific item)
    const existingChats = await sequelize.query(`
      SELECT cp1.chat_id FROM chat_participants cp1
      JOIN chat_participants cp2 ON cp1.chat_id = cp2.chat_id
      WHERE cp1.user_id = $1 AND cp2.user_id = $2
    `, {
      bind: participantIds,
      type: QueryTypes.SELECT,
    });

    let chat = null;

    if (existingChats.length > 0) {
      const chatIds = existingChats.map(r => r.chat_id);
      const where = { id: { [Op.in]: chatIds } };
      if (itemId) where.itemId = itemId;

      chat = await Chat.findOne({
        where,
        include: [
          { model: User, as: 'participants', attributes: ['id', 'name', 'avatar'], through: { attributes: [] } },
          { model: Item, as: 'item', attributes: ['id', 'title', 'images'] },
        ],
      });
    }

    if (!chat) {
      chat = await Chat.create({
        itemId: itemId || null,
        bookingId: bookingId || null,
      });

      await ChatParticipant.bulkCreate([
        { chatId: chat.id, userId: participantIds[0] },
        { chatId: chat.id, userId: participantIds[1] },
      ]);

      chat = await Chat.findByPk(chat.id, {
        include: [
          { model: User, as: 'participants', attributes: ['id', 'name', 'avatar'], through: { attributes: [] } },
          { model: Item, as: 'item', attributes: ['id', 'title', 'images'] },
        ],
      });
    }

    res.json({ chat });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyChats = async (req, res) => {
  try {
    const participantRows = await ChatParticipant.findAll({
      where: { userId: req.user.id },
      attributes: ['chatId'],
    });
    const chatIds = participantRows.map(p => p.chatId);

    const chats = await Chat.findAll({
      where: { id: { [Op.in]: chatIds } },
      order: [['lastMessageAt', 'DESC']],
      include: [
        { model: User, as: 'participants', attributes: ['id', 'name', 'avatar'], through: { attributes: [] } },
        { model: Item, as: 'item', attributes: ['id', 'title', 'images'] },
      ],
    });

    res.json({ chats });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getChatMessages = async (req, res) => {
  try {
    // Verify the user is a participant
    const participant = await ChatParticipant.findOne({
      where: { chatId: req.params.id, userId: req.user.id },
    });
    if (!participant) return res.status(404).json({ error: 'Chat not found' });

    const messages = await Message.findAll({
      where: { chatId: req.params.id },
      order: [['createdAt', 'ASC']],
      include: [{ model: User, as: 'sender', attributes: ['id', 'name', 'avatar'] }],
    });

    // Compute readBy from ChatParticipant.lastReadAt for frontend compat
    const allParticipants = await ChatParticipant.findAll({
      where: { chatId: req.params.id },
    });

    const formattedMessages = messages.map(msg => {
      const m = msg.toJSON();
      m.readBy = allParticipants
        .filter(p => p.lastReadAt && p.lastReadAt >= msg.createdAt)
        .map(p => p.userId);
      return m;
    });

    res.json({ messages: formattedMessages });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.sendMessage = async (req, res) => {
  try {
    const { text } = req.body;
    if (!text || !text.trim()) return res.status(400).json({ error: 'Message text is required' });

    if (containsBlockedContent(text.trim())) {
      return res.status(400).json({ error: 'Cannot share contact details or addresses in chat. This is to protect both parties.' });
    }

    const participant = await ChatParticipant.findOne({
      where: { chatId: req.params.id, userId: req.user.id },
    });
    if (!participant) return res.status(404).json({ error: 'Chat not found' });

    const message = await Message.create({
      chatId: req.params.id,
      senderId: req.user.id,
      text: text.trim(),
    });

    await Chat.update(
      { lastMessage: text.trim(), lastMessageAt: new Date() },
      { where: { id: req.params.id } }
    );

    // Mark sender as having read up to now
    await participant.update({ lastReadAt: new Date() });

    res.status(201).json({
      message: {
        _id: message.id,
        sender: { _id: req.user.id, id: req.user.id, name: req.user.name, avatar: req.user.avatar },
        text: message.text,
        readBy: [req.user.id],
        createdAt: message.createdAt,
      },
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.markChatRead = async (req, res) => {
  try {
    const participant = await ChatParticipant.findOne({
      where: { chatId: req.params.id, userId: req.user.id },
    });
    if (!participant) return res.status(404).json({ error: 'Chat not found' });

    await participant.update({ lastReadAt: new Date() });

    res.json({ message: 'Chat marked as read' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getUnreadCount = async (req, res) => {
  try {
    const participantRows = await ChatParticipant.findAll({
      where: { userId: req.user.id },
    });

    let unreadCount = 0;
    for (const p of participantRows) {
      const count = await Message.count({
        where: {
          chatId: p.chatId,
          senderId: { [Op.ne]: req.user.id },
          createdAt: { [Op.gt]: p.lastReadAt || new Date(0) },
        },
      });
      unreadCount += count;
    }

    res.json({ unreadCount });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
