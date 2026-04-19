const { z } = require('zod');

const rejectItemSchema = z.object({
  body: z.object({
    rejectionReason: z.string().min(1).max(1000),
  }),
});

const rejectSellerAppSchema = z.object({
  body: z.object({
    rejectionReason: z.string().min(1).max(1000),
  }),
});

const createAdminSchema = z.object({
  body: z.object({
    name: z.string(),
    email: z.string().email(),
    password: z.string().min(6).max(100),
    phone: z.string().min(10).max(15),
  }),
});

const changeRoleSchema = z.object({
  body: z.object({
    role: z.enum(['user', 'seller', 'admin']),
  }),
});

const updateDisputeStatusSchema = z.object({
  body: z.object({
    status: z.enum(['under_review', 'resolved', 'dismissed']),
    resolution: z.string().optional(),
  }),
});

module.exports = {
  rejectItemSchema,
  rejectSellerAppSchema,
  createAdminSchema,
  changeRoleSchema,
  updateDisputeStatusSchema,
};
