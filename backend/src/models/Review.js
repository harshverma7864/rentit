const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Review = sequelize.define('Review', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  reviewerId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  revieweeId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  itemId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  rating: {
    type: DataTypes.INTEGER,
    allowNull: false,
    validate: { min: 1, max: 5 },
  },
  comment: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
}, {
  tableName: 'reviews',
  underscored: true,
  timestamps: true,
  indexes: [
    { fields: ['reviewee_id', 'created_at'] },
    { fields: ['booking_id', 'reviewer_id'], unique: true },
    { fields: ['item_id', 'created_at'] },
  ],
});

Review.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = Review;
