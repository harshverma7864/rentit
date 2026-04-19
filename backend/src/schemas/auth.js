const { z } = require('zod');

const registerSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(100),
    email: z.string().email(),
    password: z.string().min(6).max(100),
    phone: z.string().min(10).max(15),
  }),
});

const loginSchema = z.object({
  body: z.object({
    email: z.string().email(),
    password: z.string(),
  }),
});

const firebaseAuthSchema = z.object({
  body: z.object({
    firebaseToken: z.string(),
    name: z.string().optional(),
  }),
});

const updateProfileSchema = z.object({
  body: z.object({
    name: z.string().optional(),
    email: z.string().email().optional(),
    phone: z.string().optional(),
  }).passthrough(),
});

const updateLocationSchema = z.object({
  body: z.object({
    latitude: z.number(),
    longitude: z.number(),
    address: z.string(),
    city: z.string(),
  }),
});

const addAddressSchema = z.object({
  body: z.object({
    addressLine1: z.string(),
    city: z.string(),
    label: z.string().optional(),
    addressLine2: z.string().optional(),
    street: z.string().optional(),
    state: z.string().optional(),
    pincode: z.string().optional(),
    landmark: z.string().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    isDefault: z.boolean().optional(),
  }),
});

const sellerApplicationSchema = z.object({
  body: z.object({}).passthrough(),
});

module.exports = {
  registerSchema,
  loginSchema,
  firebaseAuthSchema,
  updateProfileSchema,
  updateLocationSchema,
  addAddressSchema,
  sellerApplicationSchema,
};
