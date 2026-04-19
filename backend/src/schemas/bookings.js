const { z } = require('zod');

const createBookingSchema = z.object({
  body: z.object({
    itemId: z.string().uuid(),
    startDate: z.string(),
    endDate: z.string(),
    deliveryOption: z.string().optional(),
    renterNote: z.string().optional(),
    quantity: z.number().int().positive().optional(),
    scheduledPickupTime: z.string().optional(),
    eventDate: z.string().optional(),
    renterSize: z.string().optional(),
    sizeDetails: z.record(z.any()).optional(),
    alterationRequests: z.string().optional(),
  }),
});

const respondBookingSchema = z.object({
  body: z.object({
    status: z.enum(['accepted', 'rejected']),
    ownerNote: z.string().optional(),
    estimatedDeliveryTime: z.string().optional(),
  }),
});

const negotiateSchema = z.object({
  body: z.object({
    proposedPrice: z.number().positive(),
    message: z.string().optional(),
  }),
});

const deliveryStatusSchema = z.object({
  body: z.object({
    deliveryStatus: z.enum(['pending', 'out_for_delivery', 'delivered']),
  }),
});

const returnStatusSchema = z.object({
  body: z.object({
    returnStatus: z.enum(['pending', 'returned', 'damaged']),
    returnNote: z.string().optional(),
    depositAction: z.string().optional(),
    deductionAmount: z.number().optional(),
  }),
});

const confirmReceiptSchema = z.object({
  body: z.object({}).passthrough(),
});

const requestReturnSchema = z.object({
  body: z.object({}).passthrough(),
});

module.exports = {
  createBookingSchema,
  respondBookingSchema,
  negotiateSchema,
  deliveryStatusSchema,
  returnStatusSchema,
  confirmReceiptSchema,
  requestReturnSchema,
};
