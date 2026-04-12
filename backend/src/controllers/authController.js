const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Item = require('../models/Item');
const Review = require('../models/Review');
const Subscription = require('../models/Subscription');
const Booking = require('../models/Booking');
const { uploadToHosting } = require('../services/imageUpload');

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.register = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const user = new User({ name, email, password, phone });
    await user.save();

    const token = generateToken(user._id);
    res.status(201).json({ user, token });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ email });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateToken(user._id);
    res.json({ user, token });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getProfile = async (req, res) => {
  res.json({ user: req.user });
};

exports.updateProfile = async (req, res) => {
  try {
    const allowedUpdates = ['name', 'phone', 'avatar', 'location'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    // Handle avatar file upload to hosting under images/avatars/{userId}/
    if (req.file) {
      const filename = await uploadToHosting(req.file.buffer, req.file.originalname, req.file.mimetype, `avatars/${req.user._id}`);
      updates.avatar = filename;
    }

    const user = await User.findByIdAndUpdate(req.user._id, updates, { new: true, runValidators: true });
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, address, city } = req.body;
    const user = await User.findByIdAndUpdate(
      req.user._id,
      {
        location: {
          type: 'Point',
          coordinates: [longitude, latitude],
          address: address || '',
          city: city || '',
        },
      },
      { new: true }
    );
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getPublicProfile = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    if (!user) return res.status(404).json({ error: 'User not found' });

    // Contact view limit check
    let contactLocked = false;
    if (req.user && req.user._id.toString() !== req.params.id) {
      let sub = await Subscription.findOne({ user: req.user._id });
      if (!sub) {
        sub = new Subscription({ user: req.user._id });
        await sub.save();
      }
      const isPremium = sub.plan === 'premium' && (!sub.expiresAt || sub.expiresAt > new Date());
      const isBasic = sub.plan === 'basic' && (!sub.expiresAt || sub.expiresAt > new Date());
      const alreadyViewed = sub.contactViewsUsed.some(id => id.toString() === req.params.id);

      if (!alreadyViewed && !isPremium) {
        if (sub.freeContactViewsRemaining > 0 || isBasic) {
          if (sub.plan === 'free') {
            sub.freeContactViewsRemaining -= 1;
          }
          sub.contactViewsUsed.push(req.params.id);
          await sub.save();
        } else {
          contactLocked = true;
        }
      } else if (!alreadyViewed && !isPremium && sub.freeContactViewsRemaining <= 0) {
        contactLocked = true;
      }
    }

    const userObj = user.toJSON();
    if (contactLocked) {
      delete userObj.phone;
      userObj.contactLocked = true;
    } else {
      userObj.contactLocked = false;
    }

    // Add item count and completed bookings count
    const [itemCount, completedBookings] = await Promise.all([
      Item.countDocuments({ owner: req.params.id }),
      Booking.countDocuments({ owner: req.params.id, status: 'completed' }),
    ]);
    userObj.itemCount = itemCount;
    userObj.completedBookings = completedBookings;

    res.json({ user: userObj });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Address CRUD ----

exports.addAddress = async (req, res) => {
  try {
    const { label, addressLine1, addressLine2, street, city, state, pincode, landmark, latitude, longitude, isDefault } = req.body;
    if (!addressLine1 || !city) {
      return res.status(400).json({ error: 'addressLine1 and city are required' });
    }

    const address = {
      label: label || 'Home',
      addressLine1,
      addressLine2: addressLine2 || '',
      street: street || '',
      city,
      state: state || '',
      pincode: pincode || '',
      landmark: landmark || '',
      location: {
        type: 'Point',
        coordinates: [longitude || 0, latitude || 0],
      },
      isDefault: isDefault || false,
    };

    const user = await User.findById(req.user._id);
    if (address.isDefault) {
      user.addresses.forEach(a => { a.isDefault = false; });
    }
    if (user.addresses.length === 0) {
      address.isDefault = true;
    }
    user.addresses.push(address);
    await user.save();
    res.status(201).json({ addresses: user.addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateAddress = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const address = user.addresses.id(req.params.addressId);
    if (!address) return res.status(404).json({ error: 'Address not found' });

    const fields = ['label', 'addressLine1', 'addressLine2', 'street', 'city', 'state', 'pincode', 'landmark'];
    for (const f of fields) {
      if (req.body[f] !== undefined) address[f] = req.body[f];
    }
    if (req.body.latitude !== undefined && req.body.longitude !== undefined) {
      address.location = { type: 'Point', coordinates: [req.body.longitude, req.body.latitude] };
    }
    if (req.body.isDefault) {
      user.addresses.forEach(a => { a.isDefault = false; });
      address.isDefault = true;
    }

    await user.save();
    res.json({ addresses: user.addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteAddress = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const address = user.addresses.id(req.params.addressId);
    if (!address) return res.status(404).json({ error: 'Address not found' });

    const wasDefault = address.isDefault;
    user.addresses.pull(req.params.addressId);
    if (wasDefault && user.addresses.length > 0) {
      user.addresses[0].isDefault = true;
    }
    await user.save();
    res.json({ addresses: user.addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.setDefaultAddress = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    const address = user.addresses.id(req.params.addressId);
    if (!address) return res.status(404).json({ error: 'Address not found' });

    user.addresses.forEach(a => { a.isDefault = false; });
    address.isDefault = true;
    await user.save();
    res.json({ addresses: user.addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Seller Profile ----

exports.getUserItems = async (req, res) => {
  try {
    const items = await Item.find({ owner: req.params.id, isAvailable: true })
      .sort({ isBoosted: -1, createdAt: -1 })
      .populate('owner', 'name avatar rating');
    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getUserReviews = async (req, res) => {
  try {
    const reviews = await Review.find({ reviewee: req.params.id })
      .sort({ createdAt: -1 })
      .populate('reviewer', 'name avatar');
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
