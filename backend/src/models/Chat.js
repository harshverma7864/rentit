const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Chat = sequelize.define('Chat', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  itemId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  lastMessage: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  lastMessageAt: {
    type: DataTypes.DATE,
    defaultValue: DataTypes.NOW,
  },
}, {
  tableName: 'chats',
  underscored: true,
  timestamps: true,
  indexes: [
    { fields: ['last_message_at'] },
  ],
});

Chat.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = Chat;
