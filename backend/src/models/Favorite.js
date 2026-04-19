const { DataTypes } = require('sequelize');
const sequelize = require('../config/database');

const Favorite = sequelize.define('Favorite', {
  id: {
    type: DataTypes.UUID,
    defaultValue: DataTypes.UUIDV4,
    primaryKey: true,
  },
  userId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
  itemId: {
    type: DataTypes.UUID,
    allowNull: false,
  },
}, {
  tableName: 'favorites',
  underscored: true,
  timestamps: true,
  indexes: [
    { fields: ['user_id', 'item_id'], unique: true },
    { fields: ['user_id', 'created_at'] },
  ],
});

Favorite.prototype.toJSON = function () {
  const values = Object.assign({}, this.get());
  values._id = values.id;
  return values;
};

module.exports = Favorite;
