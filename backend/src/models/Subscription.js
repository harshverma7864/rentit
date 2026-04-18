const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Subscription = sequelize.define('Subscription', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
    unique: true,
  },
  plan: {
    type: DataTypes.STRING,
    defaultValue: 'free',
    validate: {
      isIn: [['free', 'basic', 'premium']],
    },
  },
  freeListingsRemaining: {
    type: DataTypes.INTEGER,
    defaultValue: 3,
  },
  freeContactViewsRemaining: {
    type: DataTypes.INTEGER,
    defaultValue: 5,
  },
  expiresAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  autoRenew: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'subscriptions',
  underscored: true,
  timestamps: true,
});

Subscription.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = Subscription;
