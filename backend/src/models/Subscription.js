const mongoose = require('mongoose');

const subscriptionSchema = new mongoose.Schema({
  user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  plan: {
    type: String,
    enum: ['free', 'basic', 'premium'],
    default: 'free',
  },
  freeListingsRemaining: { type: Number, default: 3 },
  freeContactViewsRemaining: { type: Number, default: 5 },
  contactViewsUsed: [{ type: mongoose.Schema.Types.ObjectId, ref: 'User' }],
  expiresAt: { type: Date },
  autoRenew: { type: Boolean, default: false },
}, { timestamps: true });

module.exports = mongoose.model('Subscription', subscriptionSchema);
