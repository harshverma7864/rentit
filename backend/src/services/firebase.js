const admin = require('firebase-admin');

if (!admin.apps.length) {
  try {
    const serviceAccount = process.env.FIREBASE_SERVICE_ACCOUNT
      ? JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT)
      : undefined;

    if (serviceAccount) {
      admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    } else {
      // Skip Firebase init if no credentials — endpoints that need it will fail gracefully
      console.warn('FIREBASE_SERVICE_ACCOUNT not set — Firebase features disabled');
    }
  } catch (err) {
    console.error('Firebase init error:', err.message);
  }
}

module.exports = admin;
