const Item = require('../models/Item');

exports.createItem = async (req, res) => {
  try {
    const item = new Item({ ...req.body, owner: req.user._id });
    await item.save();
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

    let sortOption = { createdAt: -1 };
    if (sort === 'price_asc') sortOption = { pricePerDay: 1 };
    else if (sort === 'price_desc') sortOption = { pricePerDay: -1 };
    else if (sort === 'nearest' && latitude && longitude) sortOption = {};

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

    const allowedUpdates = [
      'title', 'description', 'category', 'images',
      'pricePerHour', 'pricePerDay', 'pricePerWeek',
      'securityDeposit', 'condition', 'location',
      'isAvailable', 'tags', 'rules', 'maxRentalDays',
      'deliveryAvailable', 'deliveryFee',
    ];
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) item[key] = req.body[key];
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
