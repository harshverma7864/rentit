const { z } = require('zod');

const createDisputeSchema = z.object({
  body: z.object({
    bookingId: z.string().uuid(),
    reason: z.string().min(1).max(500),
    description: z.string().min(1).max(5000),
  }),
});

module.exports = {
  createDisputeSchema,
};
