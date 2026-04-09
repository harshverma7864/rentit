const mongoose = require('mongoose');

const itemSchema = new mongoose.Schema({
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true, trim: true },
  description: { type: String, required: true },
  category: {
    type: String,
    required: true,
    enum: ['clothing', 'electronics', 'vehicles', 'furniture', 'sports', 'tools', 'party', 'books', 'music', 'other'],
  },
  images: [{ type: String }],
  pricePerHour: { type: Number, default: 0 },
  pricePerDay: { type: Number, required: true },
  pricePerWeek: { type: Number, default: 0 },
  securityDeposit: { type: Number, required: true },
  condition: {
    type: String,
    enum: ['new', 'like_new', 'good', 'fair'],
    default: 'good',
  },
  location: {
    type: { type: String, enum: ['Point'], default: 'Point' },
    coordinates: { type: [Number], default: [0, 0] },
    address: { type: String, default: '' },
    city: { type: String, default: '' },
  },
  quantity: { type: Number, default: 1, min: 1 },
  isAvailable: { type: Boolean, default: true },
  tags: [{ type: String }],
  rules: { type: String, default: '' },
  maxRentalDays: { type: Number, default: 30 },
  deliveryAvailable: { type: Boolean, default: false },
  deliveryFee: { type: Number, default: 0 },
}, { timestamps: true });

itemSchema.index({ location: '2dsphere' });
itemSchema.index({ title: 'text', description: 'text', tags: 'text' });

module.exports = mongoose.model('Item', itemSchema);
