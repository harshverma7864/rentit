const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Dispute = sequelize.define('Dispute', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  raisedById: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  againstUserId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  reason: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  images: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    defaultValue: [],
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'open',
    validate: {
      isIn: [['open', 'under_review', 'resolved', 'dismissed']],
    },
  },
  resolution: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
}, {
  tableName: 'disputes',
  underscored: true,
  timestamps: true,
  indexes: [
    { fields: ['booking_id'] },
    { fields: ['raised_by_id'] },
  ],
});

Dispute.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = Dispute;
