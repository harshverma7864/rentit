const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ChatParticipant = sequelize.define('ChatParticipant', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  chatId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  lastReadAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'chat_participants',
  underscored: true,
  timestamps: false,
  indexes: [
    { fields: ['chat_id', 'user_id'], unique: true },
    { fields: ['user_id'] },
  ],
});

module.exports = ChatParticipant;
