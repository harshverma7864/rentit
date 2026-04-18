const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Address = sequelize.define('Address', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  label: {
    type: DataTypes.STRING,
    defaultValue: 'Home',
  },
  addressLine1: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  addressLine2: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  street: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  city: {
    type: DataTypes.STRING,
    allowNull: false,
  },
  state: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  pincode: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  landmark: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  latitude: {
    type: DataTypes.DOUBLE,
    defaultValue: 0,
  },
  longitude: {
    type: DataTypes.DOUBLE,
    defaultValue: 0,
  },
  isDefault: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
}, {
  tableName: 'addresses',
  underscored: true,
  timestamps: true,
});

Address.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  values.location = {
    type: 'Point',
    coordinates: [values.longitude || 0, values.latitude || 0],
  };
  return values;
};

module.exports = Address;
