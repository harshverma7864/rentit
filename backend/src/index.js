try { require('dotenv').config(); } catch (e) { /* no .env file */ }
const express = require('express');
const cors = require('cors');
// Force bundler to include pg (Sequelize loads it dynamically)
require('pg');

const app = express();

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Health check — always responds, no dependencies
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date() }));

// Lazy-load heavy modules only when needed (avoids cold-start crash)
let dbReady = false;
let sequelize, routes;

const loadRoutes = () => {
  if (routes) return routes;
  const { sequelize: sq } = require('./models');
  sequelize = sq;
  routes = {
    auth: require('./routes/auth'),
    items: require('./routes/items'),
    bookings: require('./routes/bookings'),
    notifications: require('./routes/notifications'),
    chats: require('./routes/chats'),
    wallet: require('./routes/wallet'),
    reviews: require('./routes/reviews'),
    subscription: require('./routes/subscription'),
    disputes: require('./routes/disputes'),
  };
  return routes;
};

const connectDB = async () => {
  if (dbReady) return;
  try {
    loadRoutes();
    await sequelize.authenticate();
    if (!process.env.VERCEL) {
      await sequelize.sync({ alter: process.env.NODE_ENV === 'development' });
    }
    dbReady = true;
    console.log('Connected to PostgreSQL');
  } catch (err) {
    console.error('PostgreSQL connection error:', err.message || err);
    throw err;
  }
};

// DB diagnostic
app.get('/api/health/db', async (req, res) => {
  try {
    loadRoutes();
    await sequelize.authenticate();
    res.json({ status: 'connected' });
  } catch (err) {
    res.status(500).json({ status: 'failed', error: err.message });
  }
});

// Connect to DB and mount routes
app.use(async (req, res, next) => {
  try {
    await connectDB();
    const r = loadRoutes();
    // Mount routes on first request
    if (!app._routesMounted) {
      app.use('/api/auth', r.auth);
      app.use('/api/items', r.items);
      app.use('/api/bookings', r.bookings);
      app.use('/api/notifications', r.notifications);
      app.use('/api/chats', r.chats);
      app.use('/api/wallet', r.wallet);
      app.use('/api/reviews', r.reviews);
      app.use('/api/subscription', r.subscription);
      app.use('/api/disputes', r.disputes);
      app._routesMounted = true;
    }
    next();
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed', detail: err.message });
  }
});

// Local development server (skip on Vercel)
if (!process.env.VERCEL) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });
}

module.exports = app;
