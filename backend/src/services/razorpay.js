const Razorpay = require('razorpay');
const crypto = require('crypto');

let instance = null;

function getInstance() {
  if (!instance) {
    if (!process.env.RAZORPAY_KEY_ID || !process.env.RAZORPAY_KEY_SECRET) {
      console.warn('RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET not set — Razorpay features disabled');
      return null;
    }
    instance = new Razorpay({
      key_id: process.env.RAZORPAY_KEY_ID,
      key_secret: process.env.RAZORPAY_KEY_SECRET,
    });
  }
  return instance;
}

async function createOrder(amountInPaise, receipt) {
  const razorpay = getInstance();
  if (!razorpay) throw new Error('Razorpay not configured');
  return razorpay.orders.create({
    amount: amountInPaise,
    currency: 'INR',
    receipt,
  });
}

function verifySignature(orderId, paymentId, signature) {
  const body = `${orderId}|${paymentId}`;
  const expectedSignature = crypto
    .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
    .update(body)
    .digest('hex');
  return expectedSignature === signature;
}

function verifyWebhookSignature(rawBody, signature) {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET || process.env.RAZORPAY_KEY_SECRET;
  const expectedSignature = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');
  return expectedSignature === signature;
}

module.exports = { getInstance, createOrder, verifySignature, verifyWebhookSignature };
