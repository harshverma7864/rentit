const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Booking = sequelize.define('Booking', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  itemId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  renterId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  ownerId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  startDate: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  endDate: {
    type: DataTypes.DATE,
    allowNull: false,
  },
  quantity: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  totalPrice: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  securityDeposit: {
    type: DataTypes.DOUBLE,
    allowNull: false,
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'pending',
    validate: {
      isIn: [['pending', 'accepted', 'rejected', 'active', 'completed', 'cancelled']],
    },
  },
  deliveryOption: {
    type: DataTypes.STRING,
    defaultValue: 'pickup',
    validate: {
      isIn: [['pickup', 'delivery', 'in_app_delivery']],
    },
  },
  deliveryStatus: {
    type: DataTypes.STRING,
    defaultValue: 'none',
    validate: {
      isIn: [['none', 'pending', 'out_for_delivery', 'delivered']],
    },
  },
  estimatedDeliveryTime: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  scheduledPickupTime: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  renterNote: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  ownerNote: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  // Clothing rental fields
  eventDate: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  renterSize: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  sizeDetails: {
    type: DataTypes.JSONB,
    defaultValue: {},
  },
  alterationRequests: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  alterationStatus: {
    type: DataTypes.STRING,
    defaultValue: 'none',
    validate: {
      isIn: [['none', 'requested', 'in_progress', 'completed']],
    },
  },
  securityDepositStatus: {
    type: DataTypes.STRING,
    defaultValue: 'unpaid',
    validate: {
      isIn: [['unpaid', 'paid', 'refunded', 'deducted']],
    },
  },
  returnStatus: {
    type: DataTypes.STRING,
    defaultValue: 'none',
    validate: {
      isIn: [['none', 'pending', 'returned', 'damaged']],
    },
  },
  returnNote: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  renterRating: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: { min: 1, max: 5 },
  },
  ownerRating: {
    type: DataTypes.INTEGER,
    allowNull: true,
    validate: { min: 1, max: 5 },
  },
  paymentStatus: {
    type: DataTypes.STRING,
    defaultValue: 'unpaid',
    validate: {
      isIn: [['unpaid', 'paid']],
    },
  },
  paymentDate: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  proposedPrice: {
    type: DataTypes.DOUBLE,
    allowNull: true,
  },
  negotiationStatus: {
    type: DataTypes.STRING,
    defaultValue: 'none',
    validate: {
      isIn: [['none', 'proposed', 'counter', 'accepted', 'rejected']],
    },
  },
  finalPrice: {
    type: DataTypes.DOUBLE,
    allowNull: true,
  },
}, {
  tableName: 'bookings',
  underscored: true,
  timestamps: true,
  indexes: [
    { fields: ['renter_id'] },
    { fields: ['owner_id'] },
    { fields: ['item_id'] },
    { fields: ['status'] },
    { fields: ['renter_id', 'status'] },
    { fields: ['owner_id', 'status'] },
  ],
});

Booking.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  // Map FK fields to nested objects if includes aren't populated
  if (typeof values.item === 'undefined' && values.itemId) values.item = values.itemId;
  if (typeof values.renter === 'undefined' && values.renterId) values.renter = values.renterId;
  if (typeof values.owner === 'undefined' && values.ownerId) values.owner = values.ownerId;
  return values;
};

module.exports = Booking;
