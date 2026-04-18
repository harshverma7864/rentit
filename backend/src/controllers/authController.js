const jwt = require('jsonwebtoken');
const { User, Address, Item, Review, Subscription, Booking, ContactView } = require('../models');
const { Op } = require('sequelize');
const sequelize = require('../config/database');
const { uploadToHosting } = require('../services/imageUpload');
const firebaseAdmin = require('../services/firebase');

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

exports.register = async (req, res) => {
  try {
    const { name, email, password, phone } = req.body;

    const existingUser = await User.findOne({ where: { email: email.toLowerCase().trim() } });
    if (existingUser) {
      return res.status(400).json({ error: 'Email already registered' });
    }

    const user = await User.create({ name, email: email.toLowerCase().trim(), password, phone });

    const token = generateToken(user.id);
    res.status(201).json({ user, token });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    const user = await User.findOne({ where: { email: email.toLowerCase().trim() } });
    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    const token = generateToken(user.id);
    res.json({ user, token });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getProfile = async (req, res) => {
  const user = await User.findByPk(req.user.id, {
    include: [{ model: Address, as: 'addresses', order: [['isDefault', 'DESC']] }],
  });
  res.json({ user });
};

exports.updateProfile = async (req, res) => {
  try {
    const allowedUpdates = ['name', 'email', 'phone'];
    const updates = {};
    for (const key of allowedUpdates) {
      if (req.body[key] !== undefined) {
        updates[key] = req.body[key];
      }
    }

    if (req.file) {
      const filename = await uploadToHosting(req.file.buffer, req.file.originalname, req.file.mimetype, `avatars/${req.user.id}`);
      updates.avatar = filename;
    }

    await User.update(updates, { where: { id: req.user.id } });
    const user = await User.findByPk(req.user.id, {
      include: [{ model: Address, as: 'addresses' }],
    });
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateLocation = async (req, res) => {
  try {
    const { latitude, longitude, address, city } = req.body;
    await User.update(
      {
        latitude: latitude || 0,
        longitude: longitude || 0,
        locationAddress: address || '',
        locationCity: city || '',
      },
      { where: { id: req.user.id } }
    );
    const user = await User.findByPk(req.user.id);
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getPublicProfile = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id, {
      include: [{ model: Address, as: 'addresses' }],
    });
    if (!user) return res.status(404).json({ error: 'User not found' });

    let contactLocked = false;
    if (req.user && req.user.id !== req.params.id) {
      let sub = await Subscription.findOne({ where: { userId: req.user.id } });
      if (!sub) {
        sub = await Subscription.create({ userId: req.user.id });
      }
      const isPremium = sub.plan === 'premium' && (!sub.expiresAt || sub.expiresAt > new Date());
      const isBasic = sub.plan === 'basic' && (!sub.expiresAt || sub.expiresAt > new Date());
      const alreadyViewed = await ContactView.findOne({
        where: { subscriptionId: sub.id, viewedUserId: req.params.id },
      });

      if (!alreadyViewed && !isPremium) {
        if (sub.freeContactViewsRemaining > 0 || isBasic) {
          if (sub.plan === 'free') {
            await sub.update({ freeContactViewsRemaining: sub.freeContactViewsRemaining - 1 });
          }
          await ContactView.create({ subscriptionId: sub.id, viewedUserId: req.params.id });
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

    const [itemCount, completedBookings] = await Promise.all([
      Item.count({ where: { ownerId: req.params.id } }),
      Booking.count({ where: { ownerId: req.params.id, status: 'completed' } }),
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

    if (isDefault) {
      await Address.update({ isDefault: false }, { where: { userId: req.user.id } });
    }

    const existingCount = await Address.count({ where: { userId: req.user.id } });
    const shouldBeDefault = isDefault || existingCount === 0;

    await Address.create({
      userId: req.user.id,
      label: label || 'Home',
      addressLine1,
      addressLine2: addressLine2 || '',
      street: street || '',
      city,
      state: state || '',
      pincode: pincode || '',
      landmark: landmark || '',
      latitude: latitude || 0,
      longitude: longitude || 0,
      isDefault: shouldBeDefault,
    });

    const addresses = await Address.findAll({ where: { userId: req.user.id } });
    res.status(201).json({ addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.updateAddress = async (req, res) => {
  try {
    const address = await Address.findOne({ where: { id: req.params.addressId, userId: req.user.id } });
    if (!address) return res.status(404).json({ error: 'Address not found' });

    const fields = ['label', 'addressLine1', 'addressLine2', 'street', 'city', 'state', 'pincode', 'landmark'];
    const updates = {};
    for (const f of fields) {
      if (req.body[f] !== undefined) updates[f] = req.body[f];
    }
    if (req.body.latitude !== undefined) updates.latitude = req.body.latitude;
    if (req.body.longitude !== undefined) updates.longitude = req.body.longitude;

    if (req.body.isDefault) {
      await Address.update({ isDefault: false }, { where: { userId: req.user.id } });
      updates.isDefault = true;
    }

    await address.update(updates);
    const addresses = await Address.findAll({ where: { userId: req.user.id } });
    res.json({ addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteAddress = async (req, res) => {
  try {
    const address = await Address.findOne({ where: { id: req.params.addressId, userId: req.user.id } });
    if (!address) return res.status(404).json({ error: 'Address not found' });

    const wasDefault = address.isDefault;
    await address.destroy();

    if (wasDefault) {
      const first = await Address.findOne({ where: { userId: req.user.id }, order: [['createdAt', 'ASC']] });
      if (first) await first.update({ isDefault: true });
    }

    const addresses = await Address.findAll({ where: { userId: req.user.id } });
    res.json({ addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.setDefaultAddress = async (req, res) => {
  try {
    const address = await Address.findOne({ where: { id: req.params.addressId, userId: req.user.id } });
    if (!address) return res.status(404).json({ error: 'Address not found' });

    await Address.update({ isDefault: false }, { where: { userId: req.user.id } });
    await address.update({ isDefault: true });

    const addresses = await Address.findAll({ where: { userId: req.user.id } });
    res.json({ addresses });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Seller Profile ----

exports.becomeSeller = async (req, res) => {
  try {
    await User.update({ isSeller: true }, { where: { id: req.user.id } });
    const user = await User.findByPk(req.user.id);
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getUserItems = async (req, res) => {
  try {
    const items = await Item.findAll({
      where: { ownerId: req.params.id, isAvailable: true },
      order: [['isBoosted', 'DESC'], ['createdAt', 'DESC']],
      include: [{ model: User, as: 'owner', attributes: ['id', 'name', 'avatar', 'rating'] }],
    });
    res.json({ items });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getUserReviews = async (req, res) => {
  try {
    const reviews = await Review.findAll({
      where: { revieweeId: req.params.id },
      order: [['createdAt', 'DESC']],
      include: [{ model: User, as: 'reviewer', attributes: ['id', 'name', 'avatar'] }],
    });
    res.json({ reviews });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

// ---- Firebase OTP Auth ----

exports.firebaseAuth = async (req, res) => {
  try {
    const { firebaseToken, name } = req.body;
    if (!firebaseToken) {
      return res.status(400).json({ error: 'Firebase token is required' });
    }

    // Verify the Firebase ID token
    const decodedToken = await firebaseAdmin.auth().verifyIdToken(firebaseToken);
    const { uid, phone_number } = decodedToken;

    if (!phone_number) {
      return res.status(400).json({ error: 'Phone number not found in token' });
    }

    // Check if user exists by firebaseUid or phone
    let user = await User.findOne({
      where: {
        [Op.or]: [
          { firebaseUid: uid },
          { phone: phone_number },
        ],
      },
      include: [{ model: Address, as: 'addresses' }],
    });

    let isNewUser = false;

    if (user) {
      // Existing user — update firebaseUid if not set
      if (!user.firebaseUid) {
        await user.update({ firebaseUid: uid, isVerified: true });
      }
    } else {
      // New user — create account
      user = await User.create({
        name: name || '',
        phone: phone_number,
        firebaseUid: uid,
        isVerified: true,
      });
      isNewUser = true;
    }

    const token = generateToken(user.id);
    res.json({ user, token, isNewUser });
  } catch (error) {
    if (error.code === 'auth/id-token-expired') {
      return res.status(401).json({ error: 'Firebase token expired' });
    }
    if (error.code === 'auth/argument-error') {
      return res.status(400).json({ error: 'Invalid Firebase token' });
    }
    res.status(400).json({ error: error.message });
  }
};
