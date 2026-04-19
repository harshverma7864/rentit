try { require('dotenv').config(); } catch (e) { /* no .env file */ }
const express = require('express');
const path = require('path');
const cors = require('cors');
const cookieParser = require('cookie-parser');
// Force bundler to include pg (Sequelize loads it dynamically)
require('pg');

const app = express();

// EJS view engine
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Middleware
app.use(cors());
app.use(cookieParser());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Global rate limiter
const { globalLimiter } = require('./middleware/rateLimiter');
app.use('/api', globalLimiter);

// Admin panel static assets
app.use('/admin/public', express.static(path.join(__dirname, 'public')));

// Health check — always responds, no dependencies
app.get('/api/health', (req, res) => res.json({ status: 'ok', timestamp: new Date() }));

// Lazy-load heavy modules only when needed (avoids cold-start crash)
let dbReady = false;
let sequelize, routes, adminPanel;

const loadRoutes = () => {
  if (routes) return routes;
  const { sequelize: sq } = require('./models');
  sequelize = sq;
  adminPanel = require('./routes/adminPanel');
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
    favorites: require('./routes/favorites'),
    admin: require('./routes/admin'),
  };
  return routes;
};

const connectDB = async () => {
  if (dbReady) return;
  try {
    loadRoutes();
    await sequelize.authenticate();
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
      app.use('/api/favorites', r.favorites);
      app.use('/api/admin', r.admin);
      app.use('/admin', adminPanel);
      app._routesMounted = true;
    }
    next();
  } catch (err) {
    res.status(500).json({ error: 'Database connection failed', detail: err.message });
  }
});

// Local development server (skip on Vercel)
if (!process.env.VERCEL) {
  const http = require('http');
  const { Server } = require('socket.io');
  const jwt = require('jsonwebtoken');
  const PORT = process.env.PORT || 3000;
  const server = http.createServer(app);
  const io = new Server(server, { cors: { origin: '*' } });

  io.use((socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) return next(new Error('Authentication required'));
    try {
      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      socket.userId = decoded.userId;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    socket.join(socket.userId);
    socket.on('disconnect', () => {});
  });

  app.set('io', io);
  server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
  });
} else {
  app.set('io', null);
}

module.exports = app;
