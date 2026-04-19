const { z } = require('zod');

const createItemSchema = z.object({
  body: z.object({}).passthrough(),
});

const boostItemSchema = z.object({
  body: z.object({
    tier: z.enum(['30min', '1hour', '3hours']),
  }),
});

const itemQuerySchema = z.object({
  query: z.object({
    search: z.string().optional(),
    category: z.string().optional(),
    minPrice: z.string().optional(),
    maxPrice: z.string().optional(),
    latitude: z.string().optional(),
    longitude: z.string().optional(),
    radius: z.string().optional(),
    sort: z.string().optional(),
    page: z.string().optional(),
    limit: z.string().optional(),
  }).passthrough(),
});

module.exports = {
  createItemSchema,
  boostItemSchema,
  itemQuerySchema,
};
