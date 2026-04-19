const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Item = sequelize.define('Item', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  ownerId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  title: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  description: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  category: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  // Category-specific attributes stored as JSONB.
  // Schema for each category is defined in config/categorySpecs.js
  specs: {
    type: DataTypes.JSONB,
    defaultValue: {},
  },
  images: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    defaultValue: [],
  },
  pricePerHour: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  pricePerDay: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  pricePerWeek: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  price: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  securityDeposit: {
    type: DataTypes.DECIMAL(10, 2),
    allowNull: false,
  },
  condition: {
    type: DataTypes.STRING,
    defaultValue: 'good',
    validate: {
      isIn: [['new', 'like_new', 'good', 'fair']],
    },
  },
  // Location fields
  latitude: {
    type: DataTypes.DOUBLE,
    defaultValue: 0,
  },
  longitude: {
    type: DataTypes.DOUBLE,
    defaultValue: 0,
  },
  locationAddress: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationAddressLine1: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationAddressLine2: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationStreet: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationCity: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationState: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationPincode: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  locationLandmark: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  quantity: {
    type: DataTypes.INTEGER,
    defaultValue: 1,
  },
  isAvailable: {
    type: DataTypes.BOOLEAN,
    defaultValue: true,
  },
  tags: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    defaultValue: [],
  },
  rules: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  maxRentalDays: {
    type: DataTypes.INTEGER,
    defaultValue: 30,
  },
  deliveryAvailable: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  deliveryFee: {
    type: DataTypes.DECIMAL(10, 2),
    defaultValue: 0,
  },
  deliveryOptions: {
    type: DataTypes.ARRAY(DataTypes.TEXT),
    defaultValue: [],
  },
  isBoosted: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  boostExpiresAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
  boostPriority: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  approvalStatus: {
    type: DataTypes.STRING,
    defaultValue: 'pending_approval',
    validate: {
      isIn: [['pending_approval', 'approved', 'rejected']],
    },
  },
  rejectionReason: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
}, {
  tableName: 'items',
  underscored: true,
  timestamps: true,
  paranoid: true,
  indexes: [
    { fields: ['owner_id'] },
    { fields: ['category'] },
    { fields: ['is_available'] },
    { fields: ['is_boosted'] },
    { fields: ['latitude', 'longitude'] },
    { fields: ['specs'], using: 'gin' },
  ],
});

Item.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  values.owner = values.owner || values.ownerId;
  values.location = {
    type: 'Point',
    coordinates: [values.longitude || 0, values.latitude || 0],
    address: values.locationAddress || '',
    addressLine1: values.locationAddressLine1 || '',
    addressLine2: values.locationAddressLine2 || '',
    street: values.locationStreet || '',
    city: values.locationCity || '',
    state: values.locationState || '',
    pincode: values.locationPincode || '',
    landmark: values.locationLandmark || '',
  };
  return values;
};

module.exports = Item;
