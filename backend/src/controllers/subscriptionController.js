const Subscription = require('../models/Subscription');
const Wallet = require('../models/Wallet');
const User = require('../models/User');

const PLANS = {
  free: { price: 0, listings: 3, contactViews: 5, durationDays: null },
  basic: { price: 99, listings: 15, contactViews: 30, durationDays: 30 },
  premium: { price: 299, listings: -1, contactViews: -1, durationDays: 30 }, // -1 = unlimited
};

exports.getPlans = async (req, res) => {
  res.json({ plans: PLANS });
};

exports.getMySubscription = async (req, res) => {
  try {
    let sub = await Subscription.findOne({ user: req.user._id });
    if (!sub) {
      sub = new Subscription({ user: req.user._id });
      await sub.save();
      await User.findByIdAndUpdate(req.user._id, { subscription: sub._id });
    }

    // Check expiry
    if (sub.plan !== 'free' && sub.expiresAt && sub.expiresAt < new Date()) {
      sub.plan = 'free';
      sub.freeListingsRemaining = PLANS.free.listings;
      sub.freeContactViewsRemaining = PLANS.free.contactViews;
      sub.expiresAt = null;
      await sub.save();
    }

    res.json({ subscription: sub, plans: PLANS });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.purchasePlan = async (req, res) => {
  try {
    const { plan } = req.body;
    if (!['basic', 'premium'].includes(plan)) {
      return res.status(400).json({ error: 'Invalid plan. Choose basic or premium.' });
    }

    const planInfo = PLANS[plan];

    // Deduct from wallet
    let wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet) {
      wallet = new Wallet({ user: req.user._id, balance: 0 });
      await wallet.save();
    }
    if (wallet.balance < planInfo.price) {
      return res.status(400).json({ error: `Insufficient wallet balance. Need ₹${planInfo.price}, have ₹${wallet.balance}` });
    }

    wallet.balance -= planInfo.price;
    wallet.transactions.push({
      type: 'debit',
      amount: planInfo.price,
      description: `${plan.charAt(0).toUpperCase() + plan.slice(1)} plan subscription`,
    });
    await wallet.save();

    // Update subscription
    let sub = await Subscription.findOne({ user: req.user._id });
    if (!sub) {
      sub = new Subscription({ user: req.user._id });
    }

    sub.plan = plan;
    sub.freeListingsRemaining = planInfo.listings;
    sub.freeContactViewsRemaining = planInfo.contactViews;
    sub.contactViewsUsed = [];
    sub.expiresAt = new Date(Date.now() + planInfo.durationDays * 24 * 60 * 60 * 1000);
    await sub.save();

    await User.findByIdAndUpdate(req.user._id, { subscription: sub._id });

    res.json({ subscription: sub, wallet: { balance: wallet.balance } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
