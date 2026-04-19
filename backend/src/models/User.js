const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');
const bcrypt = require('bcryptjs');

const User = sequelize.define('User', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  name: {
    type: DataTypes.STRING,
    allowNull: true,
    defaultValue: '',
  },
  email: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
  },
  password: {
    type: DataTypes.STRING,
    allowNull: true,
  },
  phone: {
    type: DataTypes.STRING,
    allowNull: false,
    unique: true,
  },
  firebaseUid: {
    type: DataTypes.STRING,
    allowNull: true,
    unique: true,
  },
  avatar: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  // Primary location
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
  locationCity: {
    type: DataTypes.STRING,
    defaultValue: '',
  },
  rating: {
    type: DataTypes.DOUBLE,
    defaultValue: 0,
  },
  totalRatings: {
    type: DataTypes.INTEGER,
    defaultValue: 0,
  },
  isSeller: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  isVerified: {
    type: DataTypes.BOOLEAN,
    defaultValue: false,
  },
  role: {
    type: DataTypes.STRING,
    defaultValue: 'user',
    validate: {
      isIn: [['user', 'seller', 'admin', 'superadmin']],
    },
  },
}, {
  tableName: 'users',
  underscored: true,
  timestamps: true,
  hooks: {
    beforeCreate: async (user) => {
      if (user.password) {
        user.password = await bcrypt.hash(user.password, 12);
      }
    },
    beforeUpdate: async (user) => {
      if (user.changed('password')) {
        user.password = await bcrypt.hash(user.password, 12);
      }
    },
  },
});

User.prototype.comparePassword = async function (candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

User.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  delete values.password;
  // Build location object for frontend compat
  values.location = {
    type: 'Point',
    coordinates: [values.longitude || 0, values.latitude || 0],
    address: values.locationAddress || '',
    city: values.locationCity || '',
  };
  return values;
};

module.exports = User;
