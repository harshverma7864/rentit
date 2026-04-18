const { Sequelize } = require('sequelize');

let databaseUrl = process.env.DATABASE_URL || 'postgres://localhost:5432/rentit';

// Strip params not supported by node-postgres (e.g. channel_binding from Neon)
try {
  const url = new URL(databaseUrl);
  url.searchParams.delete('channel_binding');
  url.searchParams.delete('sslmode');
  databaseUrl = url.toString();
} catch (e) {
  // URL parsing failed — use as-is
}

// Enable SSL for any hosted DB (Neon, Supabase, etc.)
const needsSSL = databaseUrl.includes('neon.tech')
  || databaseUrl.includes('supabase')
  || !!process.env.DATABASE_SSL
  || process.env.NODE_ENV === 'production';

const sequelize = new Sequelize(databaseUrl, {
  dialect: 'postgres',
  logging: false,
  pool: {
    max: 3,
    min: 0,
    acquire: 8000,
    idle: 0,
    evict: 1000,
  },
  dialectOptions: needsSSL
    ? { ssl: { require: true, rejectUnauthorized: false } }
    : {},
});

module.exports = sequelize;
