const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const WalletTransaction = sequelize.define('WalletTransaction', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  walletId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  type: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      isIn: [['credit', 'debit', 'refund', 'payment']],
    },
  },
  amount: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: true,
  },
}, {
  tableName: 'wallet_transactions',
  underscored: true,
  timestamps: true,
  updatedAt: false,
  indexes: [
    { fields: ['wallet_id', 'created_at'] },
  ],
});

WalletTransaction.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  values.booking = values.bookingId;
  return values;
};

module.exports = WalletTransaction;
