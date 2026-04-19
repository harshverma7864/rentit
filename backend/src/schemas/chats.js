const { z } = require('zod');

const createChatSchema = z.object({
  body: z.object({
    userId: z.string().uuid(),
    itemId: z.string().uuid().optional(),
    bookingId: z.string().uuid().optional(),
  }),
});

const sendMessageSchema = z.object({
  body: z.object({
    text: z.string().min(1).max(5000),
  }),
});

module.exports = {
  createChatSchema,
  sendMessageSchema,
};
