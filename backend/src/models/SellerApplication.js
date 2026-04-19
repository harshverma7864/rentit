const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const SellerApplication = sequelize.define('SellerApplication', {
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
  aadhaarFront: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  aadhaarBack: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  panFront: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  panBack: {
    type: DataTypes.TEXT,
    allowNull: false,
  },
  status: {
    type: DataTypes.STRING,
    defaultValue: 'pending',
    validate: {
      isIn: [['pending', 'approved', 'rejected']],
    },
  },
  rejectionReason: {
    type: DataTypes.TEXT,
    defaultValue: '',
  },
  reviewedBy: {
    type: DataTypes.UUID,
    allowNull: true,
  },
  reviewedAt: {
    type: DataTypes.DATE,
    allowNull: true,
  },
}, {
  tableName: 'seller_applications',
  underscored: true,
  timestamps: true,
});

SellerApplication.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = SellerApplication;
