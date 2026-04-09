const mongoose = require('mongoose');

const bookingSchema = new mongoose.Schema({
  item: { type: mongoose.Schema.Types.ObjectId, ref: 'Item', required: true },
  renter: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  owner: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  startDate: { type: Date, required: true },
  endDate: { type: Date, required: true },
  quantity: { type: Number, default: 1, min: 1 },
  totalPrice: { type: Number, required: true },
  securityDeposit: { type: Number, required: true },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'rejected', 'active', 'completed', 'cancelled'],
    default: 'pending',
  },
  deliveryOption: {
    type: String,
    enum: ['pickup', 'delivery'],
    default: 'pickup',
  },
  deliveryStatus: {
    type: String,
    enum: ['none', 'pending', 'out_for_delivery', 'delivered'],
    default: 'none',
  },
  estimatedDeliveryTime: { type: String, default: '' },
  scheduledPickupTime: { type: Date },
  renterNote: { type: String, default: '' },
  ownerNote: { type: String, default: '' },
  renterRating: { type: Number, min: 1, max: 5 },
  ownerRating: { type: Number, min: 1, max: 5 },
  paymentStatus: {
    type: String,
    enum: ['unpaid', 'paid'],
    default: 'unpaid',
  },
  paymentDate: { type: Date },
  // Negotiation fields
  proposedPrice: { type: Number },
  negotiationStatus: {
    type: String,
    enum: ['none', 'proposed', 'counter', 'accepted', 'rejected'],
    default: 'none',
  },
  negotiationHistory: [{
    from: { type: String, enum: ['renter', 'owner'] },
    amount: { type: Number },
    message: { type: String, default: '' },
    timestamp: { type: Date, default: Date.now },
  }],
  finalPrice: { type: Number },
}, { timestamps: true });

module.exports = mongoose.model('Booking', bookingSchema);
