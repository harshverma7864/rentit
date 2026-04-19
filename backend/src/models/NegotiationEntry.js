const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const NegotiationEntry = sequelize.define('NegotiationEntry', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  bookingId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  fromRole: {
    type: DataTypes.STRING,
    allowNull: false,
    validate: {
      isIn: [['renter', 'owner']],
    },
  },
  amount: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  message: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
}, {
  tableName: 'negotiation_entries',
  underscored: true,
  timestamps: true,
  updatedAt: false,
});

NegotiationEntry.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  values.from = values.fromRole;
  values.timestamp = values.createdAt;
  return values;
};

module.exports = NegotiationEntry;
