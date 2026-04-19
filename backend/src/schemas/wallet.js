const { z } = require('zod');

const addMoneySchema = z.object({
  body: z.object({
    amount: z.number().positive(),
  }),
});

const payForBookingSchema = z.object({
  body: z.object({
    bookingId: z.string().uuid(),
  }),
});

const createOrderSchema = z.object({
  body: z.object({
    amount: z.number().positive(),
  }),
});

const verifyPaymentSchema = z.object({
  body: z.object({
    razorpay_order_id: z.string(),
    razorpay_payment_id: z.string(),
    razorpay_signature: z.string(),
  }),
});

const requestRefundSchema = z.object({
  body: z.object({
    bookingId: z.string().uuid(),
    reason: z.string().optional(),
  }),
});

module.exports = {
  addMoneySchema,
  payForBookingSchema,
  createOrderSchema,
  verifyPaymentSchema,
  requestRefundSchema,
};
