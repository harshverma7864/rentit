const jwt = require('jsonwebtoken');
const User = require('../models/User');
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
    res.json({ user });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
