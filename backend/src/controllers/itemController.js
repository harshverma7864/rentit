const mongoose = require('mongoose');
const Item = require('../models/Item');
const Subscription = require('../models/Subscription');
const Wallet = require('../models/Wallet');
const User = require('../models/User');
const { uploadToHosting } = require('../services/imageUpload');

exports.createItem = async (req, res) => {
  try {
    // Check subscription listing limits
    let sub = await Subscription.findOne({ user: req.user._id });
    if (!sub) {
      sub = new Subscription({ user: req.user._id });
      await sub.save();
      await User.findByIdAndUpdate(req.user._id, { subscription: sub._id });
    }
    // Check expiry
    if (sub.plan !== 'free' && sub.expiresAt && sub.expiresAt < new Date()) {
      sub.plan = 'free';
      sub.freeListingsRemaining = 3;
      sub.freeContactViewsRemaining = 5;
      sub.expiresAt = null;
      await sub.save();
    }
    const isPremium = sub.plan === 'premium' && (!sub.expiresAt || sub.expiresAt > new Date());
    if (!isPremium && sub.freeListingsRemaining <= 0) {
      return res.status(403).json({ error: 'Free listing limit reached. Please upgrade your plan to list more items.' });
    }

    // Parse JSON fields sent as strings in multipart form data
    const body = { ...req.body };
    if (typeof body.location === 'string') {
      body.location = JSON.parse(body.location);
    }
    if (typeof body.tags === 'string') {
      body.tags = JSON.parse(body.tags);
    }
    if (typeof body.deliveryOptions === 'string') {
      body.deliveryOptions = JSON.parse(body.deliveryOptions);
    }
    // Convert numeric strings
    for (const key of ['pricePerDay', 'pricePerHour', 'pricePerWeek', 'securityDeposit', 'deliveryFee', 'maxRentalDays', 'quantity']) {
      if (body[key] !== undefined) body[key] = Number(body[key]);
    }
    // Convert boolean strings
    if (body.deliveryAvailable !== undefined) {
      body.deliveryAvailable = body.deliveryAvailable === 'true' || body.deliveryAvailable === true;
    }
    if (body.isAvailable !== undefined) {
      body.isAvailable = body.isAvailable === 'true' || body.isAvailable === true;
    }

    // Generate item ID upfront so we can use it as the folder name
    const itemId = new mongoose.Types.ObjectId();

    // Upload images to hosting under images/items/{itemId}/
    const images = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const filename = await uploadToHosting(file.buffer, file.originalname, file.mimetype, `items/${itemId}`);
        images.push(filename);
      }
    }
    // Also accept filenames sent directly in body
    if (body.images) {
      const bodyImages = Array.isArray(body.images) ? body.images : [body.images];
      images.push(...bodyImages);
    }

    body.images = images;
    const item = new Item({ _id: itemId, ...body, owner: req.user._id });
    await item.save();

    // Decrement listing count
    if (!isPremium) {
      sub.freeListingsRemaining -= 1;
      await sub.save();
    }

    await item.populate('owner', 'name avatar rating');
    res.status(201).json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getItems = async (req, res) => {
  try {
    const {
      search, category, minPrice, maxPrice,
      latitude, longitude, radius,
      sort, page = 1, limit = 20,
    } = req.query;

    const filter = { isAvailable: true };

    if (search) {
      filter.$text = { $search: search };
    }
    if (category) {
      filter.category = category;
    }
    if (minPrice || maxPrice) {
      filter.pricePerDay = {};
      if (minPrice) filter.pricePerDay.$gte = Number(minPrice);
      if (maxPrice) filter.pricePerDay.$lte = Number(maxPrice);
    }
    if (latitude && longitude && radius) {
      filter.location = {
        $near: {
          $geometry: { type: 'Point', coordinates: [Number(longitude), Number(latitude)] },
          $maxDistance: Number(radius) * 1000,
        },
      };
    }

    // Expire old boosts
    await Item.updateMany(
      { isBoosted: true, boostExpiresAt: { $lt: new Date() } },
      { isBoosted: false, boostPriority: 0 }
    );

    let sortOption = { isBoosted: -1, boostPriority: -1, createdAt: -1 };
    if (sort === 'price_asc') sortOption = { isBoosted: -1, pricePerDay: 1 };
    else if (sort === 'price_desc') sortOption = { isBoosted: -1, pricePerDay: -1 };
    else if (sort === 'nearest' && latitude && longitude) sortOption = { isBoosted: -1 };

    const skip = (Number(page) - 1) * Number(limit);

    const [items, total] = await Promise.all([
      Item.find(filter)
        .sort(sortOption)
        .skip(skip)
        .limit(Number(limit))
        .populate('owner', 'name avatar rating location'),
      Item.countDocuments(filter),
    ]);

    res.json({
      items,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit)),
      },
    });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getItemById = async (req, res) => {
  try {
    const item = await Item.findById(req.params.id).populate('owner', 'name avatar rating phone location');
    if (!item) return res.status(404).json({ error: 'Item not found' });
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateItem = async (req, res) => {
  try {
    const item = await Item.findOne({ _id: req.params.id, owner: req.user._id });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });

    const body = { ...req.body };
    if (typeof body.location === 'string') {
      body.location = JSON.parse(body.location);
    }
    if (typeof body.tags === 'string') {
      body.tags = JSON.parse(body.tags);
    }
    if (typeof body.deliveryOptions === 'string') {
      body.deliveryOptions = JSON.parse(body.deliveryOptions);
    }
    for (const key of ['pricePerDay', 'pricePerHour', 'pricePerWeek', 'securityDeposit', 'deliveryFee', 'maxRentalDays', 'quantity']) {
      if (body[key] !== undefined) body[key] = Number(body[key]);
    }
    if (body.deliveryAvailable !== undefined) {
      body.deliveryAvailable = body.deliveryAvailable === 'true' || body.deliveryAvailable === true;
    }
    if (body.isAvailable !== undefined) {
      body.isAvailable = body.isAvailable === 'true' || body.isAvailable === true;
    }

    // Upload new images to hosting under images/items/{itemId}/
    if (req.files && req.files.length > 0) {
      const newImages = [];
      for (const file of req.files) {
        const filename = await uploadToHosting(file.buffer, file.originalname, file.mimetype, `items/${item._id}`);
        newImages.push(filename);
      }
      // Keep existing image filenames passed in body, add new uploaded ones
      const existingImages = body.images
        ? (Array.isArray(body.images) ? body.images : [body.images])
        : item.images;
      body.images = [...existingImages, ...newImages];
    }

    const allowedUpdates = [
      'title', 'description', 'category', 'images',
      'pricePerHour', 'pricePerDay', 'pricePerWeek',
      'securityDeposit', 'condition', 'location',
      'isAvailable', 'tags', 'rules', 'maxRentalDays',
      'deliveryAvailable', 'deliveryFee', 'quantity', 'deliveryOptions',
    ];
    for (const key of allowedUpdates) {
      if (body[key] !== undefined) item[key] = body[key];
    }

    await item.save();
    await item.populate('owner', 'name avatar rating');
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteItem = async (req, res) => {
  try {
    const item = await Item.findOneAndDelete({ _id: req.params.id, owner: req.user._id });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });
    res.json({ message: 'Item deleted' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyItems = async (req, res) => {
  try {
    const items = await Item.find({ owner: req.user._id }).sort({ createdAt: -1 });
    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getCategories = async (req, res) => {
  const categories = [
    { id: 'clothing', name: 'Clothing & Fashion', icon: '👔' },
    { id: 'electronics', name: 'Electronics', icon: '📱' },
    { id: 'vehicles', name: 'Vehicles', icon: '🚗' },
    { id: 'furniture', name: 'Furniture', icon: '🪑' },
    { id: 'sports', name: 'Sports & Outdoors', icon: '⚽' },
    { id: 'tools', name: 'Tools & Equipment', icon: '🔧' },
    { id: 'party', name: 'Party & Events', icon: '🎉' },
    { id: 'books', name: 'Books & Media', icon: '📚' },
    { id: 'music', name: 'Musical Instruments', icon: '🎸' },
    { id: 'other', name: 'Other', icon: '📦' },
  ];
  res.json({ categories });
};

// ---- Boost/Promotion ----

const BOOST_TIERS = {
  '30min': { duration: 30 * 60 * 1000, price: 10, priority: 1 },
  '1hour': { duration: 60 * 60 * 1000, price: 20, priority: 2 },
  '3hours': { duration: 3 * 60 * 60 * 1000, price: 50, priority: 3 },
};

exports.boostItem = async (req, res) => {
  try {
    const { tier } = req.body; // '30min', '1hour', '3hours'
    if (!BOOST_TIERS[tier]) {
      return res.status(400).json({ error: 'Invalid boost tier. Choose 30min, 1hour, or 3hours.' });
    }

    const item = await Item.findOne({ _id: req.params.id, owner: req.user._id });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });

    const boostInfo = BOOST_TIERS[tier];

    // Deduct from wallet
    let wallet = await Wallet.findOne({ user: req.user._id });
    if (!wallet) {
      wallet = new Wallet({ user: req.user._id, balance: 0 });
      await wallet.save();
    }
    if (wallet.balance < boostInfo.price) {
      return res.status(400).json({ error: `Insufficient balance. Need ₹${boostInfo.price}` });
    }

    wallet.balance -= boostInfo.price;
    wallet.transactions.push({
      type: 'debit',
      amount: boostInfo.price,
      description: `Boost "${item.title}" for ${tier}`,
    });
    await wallet.save();

    item.isBoosted = true;
    item.boostExpiresAt = new Date(Date.now() + boostInfo.duration);
    item.boostPriority = boostInfo.priority;
    await item.save();

    res.json({ item, wallet: { balance: wallet.balance } });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getBoostTiers = async (req, res) => {
  res.json({ tiers: BOOST_TIERS });
};

// ---- Recommendations ----

exports.getRecommended = async (req, res) => {
  try {
    const { latitude, longitude } = req.query;

    // Expire old boosts at query time
    await Item.updateMany(
      { isBoosted: true, boostExpiresAt: { $lt: new Date() } },
      { isBoosted: false, boostPriority: 0 }
    );

    const filter = { isAvailable: true };

    if (latitude && longitude) {
      filter.location = {
        $near: {
          $geometry: { type: 'Point', coordinates: [Number(longitude), Number(latitude)] },
          $maxDistance: 50000, // 50km
        },
      };
    }

    const items = await Item.find(filter)
      .sort({ isBoosted: -1, boostPriority: -1, createdAt: -1 })
      .limit(20)
      .populate('owner', 'name avatar rating');

    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
