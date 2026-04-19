const { Subscription, Wallet, WalletTransaction, User, ContactView } = require('../models');
const sequelize = require('../config/database');

const PLANS = {
  free: { price: 0, listings: 3, contactViews: 5, durationDays: null },
  basic: { price: 99, listings: 15, contactViews: 30, durationDays: 30 },
  premium: { price: 299, listings: -1, contactViews: -1, durationDays: 30 },
};

exports.getPlans = async (req, res) => {
  res.json({ plans: PLANS });
};

exports.getMySubscription = async (req, res) => {
  try {
    let sub = await Subscription.findOne({ where: { userId: req.user.id } });
    if (!sub) {
      sub = await Subscription.create({ userId: req.user.id });
    }

    if (sub.plan !== 'free' && sub.expiresAt && sub.expiresAt < new Date()) {
      await sub.update({
        plan: 'free',
        freeListingsRemaining: PLANS.free.listings,
        freeContactViewsRemaining: PLANS.free.contactViews,
        expiresAt: null,
      });
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

    await sequelize.transaction(async (t) => {
      let wallet = await Wallet.findOne({
        where: { userId: req.user.id },
        transaction: t,
        lock: t.LOCK.UPDATE,
      });
      if (!wallet) {
        wallet = await Wallet.create({ userId: req.user.id, balance: 0 }, { transaction: t });
      }
      const currentBalance = parseFloat(wallet.balance);
      if (currentBalance < planInfo.price) {
        throw Object.assign(new Error(`Insufficient wallet balance. Need ₹${planInfo.price}, have ₹${currentBalance}`), { statusCode: 400 });
      }

      await wallet.update({ balance: currentBalance - planInfo.price }, { transaction: t });
      await WalletTransaction.create({
        walletId: wallet.id,
        type: 'debit',
        amount: planInfo.price,
        description: `${plan.charAt(0).toUpperCase() + plan.slice(1)} plan subscription`,
      }, { transaction: t });

      let sub = await Subscription.findOne({ where: { userId: req.user.id }, transaction: t });
      if (!sub) {
        sub = await Subscription.create({ userId: req.user.id }, { transaction: t });
      }

      await sub.update({
        plan,
        freeListingsRemaining: planInfo.listings,
        freeContactViewsRemaining: planInfo.contactViews,
        expiresAt: new Date(Date.now() + planInfo.durationDays * 24 * 60 * 60 * 1000),
      }, { transaction: t });

      await ContactView.destroy({ where: { subscriptionId: sub.id }, transaction: t });
    });

    // Re-fetch after transaction for response
    const sub = await Subscription.findOne({ where: { userId: req.user.id } });
    const wallet = await Wallet.findOne({ where: { userId: req.user.id } });

    res.json({ subscription: sub, wallet: { balance: wallet.balance } });
  } catch (error) {
    const status = error.statusCode || 400;
    res.status(status).json({ error: error.message });
  }
};
