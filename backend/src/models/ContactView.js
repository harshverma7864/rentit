const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const ContactView = sequelize.define('ContactView', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  subscriptionId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  viewedUserId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
}, {
  tableName: 'contact_views',
  underscored: true,
  timestamps: true,
  updatedAt: false,
  indexes: [
    { fields: ['subscription_id', 'viewed_user_id'], unique: true },
  ],
});

module.exports = ContactView;
