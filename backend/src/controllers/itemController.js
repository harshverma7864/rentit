const { Item, Subscription, Wallet, WalletTransaction, User, Booking } = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');
const { v4: uuidv4 } = require('uuid');
const { uploadToHosting } = require('../services/imageUpload');
const { CATEGORY_SPECS, resolveParentCategory } = require('../config/categorySpecs');

exports.createItem = async (req, res) => {
  try {
    // Only sellers can list items
    if (!req.user.role || !['seller', 'admin', 'superadmin'].includes(req.user.role)) {
      return res.status(403).json({ error: 'You must be a verified seller to list items. Please complete KYC verification first.' });
    }

    let sub = await Subscription.findOne({ where: { userId: req.user.id } });
    if (!sub) {
      sub = await Subscription.create({ userId: req.user.id });
    }
    if (sub.plan !== 'free' && sub.expiresAt && sub.expiresAt < new Date()) {
      await sub.update({ plan: 'free', freeListingsRemaining: 3, freeContactViewsRemaining: 5, expiresAt: null });
    }
    const isPremium = sub.plan === 'premium' && (!sub.expiresAt || sub.expiresAt > new Date());
    if (!isPremium && sub.freeListingsRemaining <= 0) {
      return res.status(403).json({ error: 'Free listing limit reached. Please upgrade your plan to list more items.' });
    }

    const body = { ...req.body };
    if (typeof body.location === 'string') body.location = JSON.parse(body.location);
    if (typeof body.tags === 'string') body.tags = JSON.parse(body.tags);
    if (typeof body.deliveryOptions === 'string') body.deliveryOptions = JSON.parse(body.deliveryOptions);

    for (const key of ['pricePerDay', 'pricePerHour', 'pricePerWeek', 'securityDeposit', 'deliveryFee', 'maxRentalDays', 'quantity', 'price']) {
      if (body[key] !== undefined) body[key] = Number(body[key]);
    }
    if (body.deliveryAvailable !== undefined) body.deliveryAvailable = body.deliveryAvailable === 'true' || body.deliveryAvailable === true;
    if (body.isAvailable !== undefined) body.isAvailable = body.isAvailable === 'true' || body.isAvailable === true;
    if (body.specs && typeof body.specs === 'string') {
      try { body.specs = JSON.parse(body.specs); } catch (_) { body.specs = {}; }
    }

    // Validate specs against category schema
    if (body.specs && body.category) {
      const parentCat = resolveParentCategory(body.category);
      const schema = parentCat ? CATEGORY_SPECS[parentCat] : null;
      if (schema) {
        const validKeys = new Set(schema.fields.map(f => f.key));
        const validatedSpecs = {};
        for (const [key, value] of Object.entries(body.specs)) {
          if (!validKeys.has(key)) continue; // strip unknown keys
          const field = schema.fields.find(f => f.key === key);
          if (field.type === 'select' && field.options && !field.options.includes(value)) continue;
          if (field.type === 'number' && typeof value !== 'number' && isNaN(Number(value))) continue;
          if (field.type === 'boolean' && typeof value !== 'boolean') continue;
          validatedSpecs[key] = value;
        }
        body.specs = validatedSpecs;
      }
    }

    const itemId = uuidv4();

    const images = [];
    if (req.files && req.files.length > 0) {
      for (const file of req.files) {
        const filename = await uploadToHosting(file.buffer, file.originalname, file.mimetype, `items/${itemId}`);
        images.push(filename);
      }
    }
    if (body.images) {
      const bodyImages = Array.isArray(body.images) ? body.images : [body.images];
      images.push(...bodyImages);
    }

    // Extract location fields
    const loc = body.location || {};

    const item = await Item.create({
      id: itemId,
      ownerId: req.user.id,
      title: body.title,
      description: body.description,
      category: body.category,
      images,
      pricePerHour: body.pricePerHour || 0,
      pricePerDay: body.pricePerDay,
      pricePerWeek: body.pricePerWeek || 0,
      price: body.price || 0,
      securityDeposit: body.securityDeposit,
      condition: body.condition || 'good',
      latitude: loc.coordinates ? loc.coordinates[1] : (body.latitude || 0),
      longitude: loc.coordinates ? loc.coordinates[0] : (body.longitude || 0),
      locationAddress: loc.address || body.locationAddress || '',
      locationAddressLine1: loc.addressLine1 || body.locationAddressLine1 || '',
      locationAddressLine2: loc.addressLine2 || body.locationAddressLine2 || '',
      locationStreet: loc.street || body.locationStreet || '',
      locationCity: loc.city || body.locationCity || '',
      locationState: loc.state || body.locationState || '',
      locationPincode: loc.pincode || body.locationPincode || '',
      locationLandmark: loc.landmark || body.locationLandmark || '',
      quantity: body.quantity || 1,
      isAvailable: body.isAvailable !== false,
      tags: body.tags || [],
      rules: body.rules || '',
      maxRentalDays: body.maxRentalDays || 30,
      deliveryAvailable: body.deliveryAvailable || false,
      deliveryFee: body.deliveryFee || 0,
      deliveryOptions: body.deliveryOptions || [],
      specs: body.specs || {},
      approvalStatus: 'pending_approval',
    });

    if (!isPremium) {
      await sub.update({ freeListingsRemaining: sub.freeListingsRemaining - 1 });
    }

    const result = await Item.findByPk(itemId, {
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating'] }],
    });
    res.status(201).json({ item: result });
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
      ...specFilters // all remaining query params are treated as spec filters
    } = req.query;

    const where = { isAvailable: true, approvalStatus: 'approved' };

    if (search) {
      where[Op.or] = [
        { title: { [Op.iLike]: `%${search}%` } },
        { description: { [Op.iLike]: `%${search}%` } },
      ];
    }
    if (category) where.category = category;
    if (minPrice || maxPrice) {
      where.pricePerDay = {};
      if (minPrice) where.pricePerDay[Op.gte] = Number(minPrice);
      if (maxPrice) where.pricePerDay[Op.lte] = Number(maxPrice);
    }

    // Dynamic spec filters via JSONB
    // Look up which category's schema the filter keys belong to
    const parentCat = resolveParentCategory(category);
    const schema = parentCat ? CATEGORY_SPECS[parentCat] : null;
    if (schema) {
      const validKeys = new Set(schema.fields.filter(f => f.filterable).map(f => f.key));
      for (const [key, value] of Object.entries(specFilters)) {
        if (!validKeys.has(key) || !value) continue;
        const field = schema.fields.find(f => f.key === key);
        if (field && field.type === 'select') {
          // Exact match for select fields
          where[`specs.${key}`] = value;
        } else {
          // Case-insensitive partial match for text fields
          where[Op.and] = [
            ...(where[Op.and] || []),
            sequelize.where(
              sequelize.cast(sequelize.json(`specs.${key}`), 'TEXT'),
              { [Op.iLike]: `%${value}%` }
            ),
          ];
        }
      }
    }

    // Bounding box geo filter
    if (latitude && longitude && radius) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      const radiusKm = parseFloat(radius);
      if (!isNaN(lat) && !isNaN(lng) && !isNaN(radiusKm)) {
        const latDelta = radiusKm / 111;
        const lngDelta = radiusKm / (111 * Math.cos(lat * Math.PI / 180));
        where.latitude = { [Op.between]: [lat - latDelta, lat + latDelta] };
        where.longitude = { [Op.between]: [lng - lngDelta, lng + lngDelta] };
      }
    }

    let order = [
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN 1 ELSE 0 END`), 'DESC'],
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN boost_priority ELSE 0 END`), 'DESC'],
      ['createdAt', 'DESC'],
    ];
    if (sort === 'price_asc') order = [
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN 1 ELSE 0 END`), 'DESC'],
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN boost_priority ELSE 0 END`), 'DESC'],
      ['pricePerDay', 'ASC'],
    ];
    else if (sort === 'price_desc') order = [
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN 1 ELSE 0 END`), 'DESC'],
      [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN boost_priority ELSE 0 END`), 'DESC'],
      ['pricePerDay', 'DESC'],
    ];

    const offset = (Number(page) - 1) * Number(limit);

    const { rows: items, count: total } = await Item.findAndCountAll({
      where,
      order,
      offset,
      limit: Number(limit),
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating', 'latitude', 'longitude', 'locationAddress', 'locationCity'] }],
    });

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
    const item = await Item.findByPk(req.params.id, {
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating', 'phone', 'latitude', 'longitude', 'locationAddress', 'locationCity'] }],
    });
    if (!item) return res.status(404).json({ error: 'Item not found' });
    res.json({ item });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateItem = async (req, res) => {
  try {
    const item = await Item.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });

    const body = { ...req.body };
    if (typeof body.location === 'string') body.location = JSON.parse(body.location);
    if (typeof body.tags === 'string') body.tags = JSON.parse(body.tags);
    if (typeof body.deliveryOptions === 'string') body.deliveryOptions = JSON.parse(body.deliveryOptions);

    for (const key of ['pricePerDay', 'pricePerHour', 'pricePerWeek', 'securityDeposit', 'deliveryFee', 'maxRentalDays', 'quantity', 'price']) {
      if (body[key] !== undefined) body[key] = Number(body[key]);
    }
    if (body.deliveryAvailable !== undefined) body.deliveryAvailable = body.deliveryAvailable === 'true' || body.deliveryAvailable === true;
    if (body.isAvailable !== undefined) body.isAvailable = body.isAvailable === 'true' || body.isAvailable === true;

    if (body.specs && typeof body.specs === 'string') {
      try { body.specs = JSON.parse(body.specs); } catch (_) { body.specs = {}; }
    }

    // Validate specs against category schema
    if (body.specs && (body.category || item.category)) {
      const catToValidate = body.category || item.category;
      const parentCat = resolveParentCategory(catToValidate);
      const schema = parentCat ? CATEGORY_SPECS[parentCat] : null;
      if (schema) {
        const validKeys = new Set(schema.fields.map(f => f.key));
        const validatedSpecs = {};
        for (const [key, value] of Object.entries(body.specs)) {
          if (!validKeys.has(key)) continue; // strip unknown keys
          const field = schema.fields.find(f => f.key === key);
          if (field.type === 'select' && field.options && !field.options.includes(value)) continue;
          if (field.type === 'number' && typeof value !== 'number' && isNaN(Number(value))) continue;
          if (field.type === 'boolean' && typeof value !== 'boolean') continue;
          validatedSpecs[key] = value;
        }
        body.specs = validatedSpecs;
      }
    }

    if (req.files && req.files.length > 0) {
      const newImages = [];
      for (const file of req.files) {
        const filename = await uploadToHosting(file.buffer, file.originalname, file.mimetype, `items/${item.id}`);
        newImages.push(filename);
      }
      const existingImages = body.images
        ? (Array.isArray(body.images) ? body.images : [body.images])
        : item.images;
      body.images = [...existingImages, ...newImages];
    }

    // Extract location
    if (body.location) {
      const loc = body.location;
      body.latitude = loc.coordinates ? loc.coordinates[1] : body.latitude;
      body.longitude = loc.coordinates ? loc.coordinates[0] : body.longitude;
      body.locationAddress = loc.address || '';
      body.locationAddressLine1 = loc.addressLine1 || '';
      body.locationAddressLine2 = loc.addressLine2 || '';
      body.locationStreet = loc.street || '';
      body.locationCity = loc.city || '';
      body.locationState = loc.state || '';
      body.locationPincode = loc.pincode || '';
      body.locationLandmark = loc.landmark || '';
    }

    const allowedUpdates = [
      'title', 'description', 'category', 'images', 'price',
      'pricePerHour', 'pricePerDay', 'pricePerWeek',
      'securityDeposit', 'condition',
      'latitude', 'longitude', 'locationAddress', 'locationAddressLine1',
      'locationAddressLine2', 'locationStreet', 'locationCity',
      'locationState', 'locationPincode', 'locationLandmark',
      'isAvailable', 'tags', 'rules', 'maxRentalDays',
      'deliveryAvailable', 'deliveryFee', 'quantity', 'deliveryOptions',
      'specs',
    ];
    const updates = {};
    for (const key of allowedUpdates) {
      if (body[key] !== undefined) updates[key] = body[key];
    }

    await item.update(updates);
    const result = await Item.findByPk(item.id, {
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating'] }],
    });
    res.json({ item: result });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteItem = async (req, res) => {
  try {
    const item = await Item.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });

    const activeBookings = await Booking.count({
      where: {
        itemId: item.id,
        status: { [Op.in]: ['pending', 'accepted', 'active'] },
      },
    });
    if (activeBookings > 0) {
      return res.status(400).json({ error: 'Cannot delete item with active bookings' });
    }

    await item.destroy(); // soft delete (paranoid mode)
    res.json({ message: 'Item deleted' });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getMyItems = async (req, res) => {
  try {
    const items = await Item.findAll({
      where: { ownerId: req.user.id },
      order: [['createdAt', 'DESC']],
    });
    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getCategories = async (req, res) => {
  const categories = Object.entries(CATEGORY_SPECS).map(([id, spec]) => ({
    id,
    name: spec.name,
    icon: spec.icon,
    subcategories: spec.subcategories || [],
    fields: spec.fields || [],
  }));
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
    const { tier } = req.body;
    if (!BOOST_TIERS[tier]) {
      return res.status(400).json({ error: 'Invalid boost tier. Choose 30min, 1hour, or 3hours.' });
    }

    const item = await Item.findOne({ where: { id: req.params.id, ownerId: req.user.id } });
    if (!item) return res.status(404).json({ error: 'Item not found or unauthorized' });

    const boostInfo = BOOST_TIERS[tier];

    let wallet = await Wallet.findOne({ where: { userId: req.user.id } });
    if (!wallet) {
      wallet = await Wallet.create({ userId: req.user.id, balance: 0 });
    }
    if (wallet.balance < boostInfo.price) {
      return res.status(400).json({ error: `Insufficient balance. Need ₹${boostInfo.price}` });
    }

    await wallet.update({ balance: wallet.balance - boostInfo.price });
    await WalletTransaction.create({
      walletId: wallet.id,
      type: 'debit',
      amount: boostInfo.price,
      description: `Boost "${item.title}" for ${tier}`,
    });

    await item.update({
      isBoosted: true,
      boostExpiresAt: new Date(Date.now() + boostInfo.duration),
      boostPriority: boostInfo.priority,
    });

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

    const where = { isAvailable: true, approvalStatus: 'approved' };

    if (latitude && longitude) {
      const lat = parseFloat(latitude);
      const lng = parseFloat(longitude);
      if (!isNaN(lat) && !isNaN(lng)) {
        const latDelta = 50 / 111; // ~50km
        const lngDelta = 50 / (111 * Math.cos(lat * Math.PI / 180));
        where.latitude = { [Op.between]: [lat - latDelta, lat + latDelta] };
        where.longitude = { [Op.between]: [lng - lngDelta, lng + lngDelta] };
      }
    }

    const items = await Item.findAll({
      where,
      order: [
        [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN 1 ELSE 0 END`), 'DESC'],
        [sequelize.literal(`CASE WHEN is_boosted = true AND boost_expires_at > NOW() THEN boost_priority ELSE 0 END`), 'DESC'],
        ['createdAt', 'DESC'],
      ],
      limit: 20,
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating'] }],
    });

    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Item Availability Calendar ----

exports.getItemAvailability = async (req, res) => {
  try {
    const bookings = await Booking.findAll({
      where: {
        itemId: req.params.id,
        status: { [Op.in]: ['pending', 'accepted', 'active'] },
      },
      attributes: ['id', 'startDate', 'endDate', 'status'],
      order: [['startDate', 'ASC']],
    });
    res.json({ bookings });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
