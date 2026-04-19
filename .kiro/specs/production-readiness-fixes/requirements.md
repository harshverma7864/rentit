# Requirements Document

## Introduction

This document captures the production-readiness requirements for the RentPe backend, addressing 14 issues identified during an architecture review plus 6 new feature requirements (Razorpay payment gateway, enhanced delivery flow, dispute image evidence, admin panel, seller KYC verification, and role-based access control). The issues span data integrity, security, performance, operational safety, infrastructure gaps, and new feature additions. Each requirement maps to one or more findings and is written to be independently testable.

## Glossary

- **Wallet_Service**: The backend module responsible for reading and updating wallet balances and creating wallet transaction records (walletController.js and wallet-related logic in bookingController.js).
- **Booking_Service**: The backend module responsible for creating, accepting, completing, cancelling, and managing the lifecycle of bookings (bookingController.js).
- **Item_Service**: The backend module responsible for item CRUD, boost management, category specs, and browse/search queries (itemController.js).
- **Chat_Service**: The backend module responsible for chat creation, messaging, and content filtering (chatController.js).
- **Auth_Middleware**: The Express middleware that verifies JWT tokens and attaches the authenticated user to the request (middleware/auth.js).
- **Validation_Layer**: A request validation middleware (e.g., Zod or Joi) that validates and sanitizes incoming request bodies, query parameters, and route parameters before they reach controllers.
- **Rate_Limiter**: An Express middleware that enforces per-IP or per-user request rate limits on API endpoints.
- **Migration_System**: The Sequelize CLI migration framework used to version and apply database schema changes safely.
- **Sequelize_Transaction**: A Sequelize managed transaction that wraps multiple database operations so they either all commit or all roll back.
- **DECIMAL_Type**: The PostgreSQL DECIMAL(10, 2) column type used for exact monetary arithmetic, replacing DOUBLE.
- **Soft_Delete**: Sequelize paranoid mode where `destroy()` sets a `deletedAt` timestamp instead of physically removing the row.
- **Boost_Expiry_Filter**: A WHERE clause condition that excludes items with expired boosts from query results, replacing the inline UPDATE approach.
- **Category_Specs_Schema**: The per-category field definitions in `config/categorySpecs.js` that describe required and optional spec fields for each item category.
- **Contact_Blocking**: The regex-based system in Chat_Service that attempts to prevent users from sharing phone numbers, emails, and addresses in chat messages.
- **Socket_Initialization**: The setup of Socket.io on the HTTP server instance so that `req.app.get('io')` returns a valid Socket.io server object.
- **Razorpay_Service**: The backend module responsible for creating Razorpay orders, verifying payment signatures, and handling webhook callbacks for wallet top-ups and direct booking payments.
- **Razorpay_Order**: A server-side order created via the Razorpay Orders API that the frontend uses to initiate a payment flow. Contains order_id, amount, currency, and receipt.
- **Razorpay_Signature**: The HMAC-SHA256 signature returned by Razorpay after a successful payment, verified server-side using the Razorpay key_secret to confirm payment authenticity.
- **Delivery_Flow**: The end-to-end process where an owner marks an item as out-for-delivery, the renter confirms receipt by uploading a photo, and the booking transitions to the delivered state.
- **Delivery_Proof_Image**: A photo uploaded by the renter upon receiving a delivered item, stored as evidence that the item was received and documenting its condition at arrival.
- **Dispute_Evidence**: One or more images uploaded by a user when raising a dispute, documenting damage or issues with a rented item as proof for dispute resolution.
- **Admin_Panel**: A web-based dashboard (separate from the Flutter app) used by admins and superadmins to manage the platform — approve/reject items, seller applications, disputes, and user accounts.
- **Admin_Service**: The backend module responsible for admin-specific operations: item approval, seller KYC review, user management, and platform analytics (adminController.js).
- **Role**: A field on the User model that determines access level. Values: `user` (default), `seller` (KYC-approved), `admin` (platform moderator), `superadmin` (full platform control).
- **Superadmin**: The highest-privilege role that can create admin accounts, manage all platform entities, and cannot be created through normal registration — only via a CLI seed command or direct DB insert.
- **KYC_Verification**: The Know Your Customer process where a user submitting a seller application uploads Aadhaar card (front + back) and PAN card (front + back) images for identity verification.
- **Seller_Application**: A record created when a user requests to become a seller, containing KYC documents and a status (pending, approved, rejected). Approval grants the `seller` role.
- **Item_Approval**: The process where a newly listed item enters a `pending_approval` state and must be approved by an admin before it becomes visible in browse/search results.
- **Admin_Middleware**: An Express middleware that checks the authenticated user's role is `admin` or `superadmin` before allowing access to admin-only endpoints.

## Requirements

### Requirement 1: Atomic Wallet Balance Updates

**User Story:** As a platform operator, I want wallet balance updates to be atomic, so that concurrent payments cannot cause negative balances or lost updates.

#### Acceptance Criteria

1. WHEN a wallet balance update is requested, THE Wallet_Service SHALL acquire a row-level lock on the wallet row (SELECT ... FOR UPDATE) within a Sequelize_Transaction before reading the balance.
2. WHEN the Wallet_Service reads a wallet balance inside a transaction, THE Wallet_Service SHALL use the locked row value to compute the new balance and persist it in a single atomic operation.
3. IF a concurrent transaction attempts to update the same wallet row, THEN THE database SHALL block the second transaction until the first transaction commits or rolls back.
4. IF the computed new balance would be negative, THEN THE Wallet_Service SHALL reject the operation and return an insufficient balance error without modifying the wallet.
5. WHEN a wallet credit or debit completes, THE Wallet_Service SHALL create the corresponding WalletTransaction record within the same Sequelize_Transaction.
6. THE Wallet_Service SHALL apply atomic locking to all wallet-modifying operations: addMoney, payForBooking, boostItem, purchasePlan, cancelBooking refund, completeBooking deposit return, and updateReturnStatus deposit handling.

### Requirement 2: Database Transactions for Multi-Table Operations

**User Story:** As a platform operator, I want all multi-table operations wrapped in database transactions, so that partial failures do not leave the database in an inconsistent state.

#### Acceptance Criteria

1. WHEN the Booking_Service creates a booking, THE Booking_Service SHALL wrap the booking creation, item availability check, and notification creation in a single Sequelize_Transaction.
2. WHEN the Wallet_Service processes a payment (payForBooking), THE Wallet_Service SHALL wrap the wallet debit, wallet transaction creation, booking status update, and owner wallet credit in a single Sequelize_Transaction.
3. WHEN the Booking_Service cancels a booking, THE Booking_Service SHALL wrap the booking status update, wallet refund, wallet transaction creation, and item quantity restoration in a single Sequelize_Transaction.
4. WHEN the Booking_Service completes a booking, THE Booking_Service SHALL wrap the booking status update, item quantity restoration, and security deposit refund in a single Sequelize_Transaction.
5. WHEN the Booking_Service updates return status, THE Booking_Service SHALL wrap the return status update, deposit refund or deduction, wallet transactions, and item quantity restoration in a single Sequelize_Transaction.
6. IF any operation within a Sequelize_Transaction fails, THEN THE Sequelize_Transaction SHALL roll back all changes made within that transaction.

### Requirement 3: Booking Conflict Detection with Row-Level Locking

**User Story:** As a renter, I want the system to prevent double-bookings, so that two users cannot book the same item for overlapping dates simultaneously.

#### Acceptance Criteria

1. WHEN the Booking_Service checks for date conflicts during booking creation, THE Booking_Service SHALL acquire a row-level advisory lock or use a serializable isolation level scoped to the item being booked.
2. WHEN two concurrent booking requests target the same item with overlapping dates, THE Booking_Service SHALL allow only one to succeed and reject the other with a conflict error.
3. THE Booking_Service SHALL perform the conflict check and booking insertion within the same Sequelize_Transaction to eliminate the check-then-create race window.

### Requirement 4: Request Input Validation Layer

**User Story:** As a developer, I want all API endpoints to validate incoming request data against schemas, so that malformed or malicious input is rejected before reaching business logic.

#### Acceptance Criteria

1. THE Validation_Layer SHALL validate request bodies, query parameters, and route parameters using a schema validation library (Zod, Joi, or express-validator) before the request reaches the controller.
2. WHEN a request fails validation, THE Validation_Layer SHALL return a 400 status code with a descriptive error message listing the invalid fields.
3. THE Validation_Layer SHALL enforce type checking, required field presence, string length limits, and numeric range constraints on all endpoints that accept user input.
4. THE Validation_Layer SHALL sanitize string inputs to prevent XSS by stripping or escaping HTML tags and script content.
5. THE Validation_Layer SHALL validate UUID format for all ID parameters (route params and body fields referencing foreign keys).
6. THE Validation_Layer SHALL validate date fields to ensure they are valid ISO 8601 date strings and that startDate is before endDate where applicable.
7. THE Validation_Layer SHALL validate numeric monetary fields to ensure they are positive numbers.

### Requirement 5: DECIMAL Type for All Monetary Fields

**User Story:** As a platform operator, I want all monetary values stored with exact decimal precision, so that floating-point rounding errors do not cause incorrect balances or prices.

#### Acceptance Criteria

1. THE Migration_System SHALL change the column type of Wallet.balance from DOUBLE to DECIMAL_Type (DECIMAL(10, 2)).
2. THE Migration_System SHALL change the column type of WalletTransaction.amount from DOUBLE to DECIMAL_Type.
3. THE Migration_System SHALL change the column types of Booking.totalPrice, Booking.securityDeposit, Booking.proposedPrice, and Booking.finalPrice from DOUBLE to DECIMAL_Type.
4. THE Migration_System SHALL change the column types of Item.pricePerDay, Item.pricePerHour, Item.pricePerWeek, Item.price, Item.securityDeposit, and Item.deliveryFee from DOUBLE to DECIMAL_Type.
5. WHEN the Sequelize model definitions are updated, THE model definitions SHALL use DataTypes.DECIMAL(10, 2) for all monetary fields listed above.
6. THE Wallet_Service SHALL perform arithmetic on monetary values using string-based or integer-based calculations to avoid floating-point errors in JavaScript (e.g., parseFloat on Sequelize DECIMAL string returns).

### Requirement 6: Sequelize CLI Migration Strategy

**User Story:** As a developer, I want a proper migration system in place, so that database schema changes can be applied safely and reproducibly across environments.

#### Acceptance Criteria

1. THE Migration_System SHALL use Sequelize CLI with a `.sequelizerc` configuration file pointing to the correct config, models, migrations, and seeders directories.
2. THE Migration_System SHALL include a baseline migration that captures the current schema of all existing tables.
3. WHEN a schema change is needed, THE developer SHALL create a new migration file using `npx sequelize-cli migration:generate` rather than modifying model definitions and relying on `sync({ alter: true })`.
4. THE application entry point (index.js) SHALL remove the `sequelize.sync({ alter: true })` call in development mode and rely on migrations for schema changes.
5. THE Migration_System SHALL include a migration for the DOUBLE-to-DECIMAL type change (Requirement 5) as the first post-baseline migration.

### Requirement 7: Lightweight Auth Middleware

**User Story:** As a developer, I want the auth middleware to load only the data needed for authentication, so that every API request does not incur an unnecessary database JOIN.

#### Acceptance Criteria

1. THE Auth_Middleware SHALL query only the User table (without including Address associations) when verifying a JWT token.
2. WHEN a specific endpoint requires address data, THE controller for that endpoint SHALL load addresses explicitly via a separate query or include.
3. THE Auth_Middleware SHALL select only the user fields needed for authentication and authorization (id, name, avatar, phone, email, role, rating) rather than loading the full user row.

### Requirement 8: Boost Expiry as Background Filter

**User Story:** As a developer, I want boost expiry handled efficiently, so that browse requests do not trigger UPDATE queries on every page load.

#### Acceptance Criteria

1. THE Item_Service SHALL remove the inline `Item.update()` call that expires old boosts from the `getItems` and `getRecommended` controller functions.
2. WHEN the Item_Service queries items for browse or recommendations, THE Item_Service SHALL include a WHERE clause condition that treats items with `boostExpiresAt < NOW()` as non-boosted (e.g., using a CASE expression or computed column in the ORDER BY).
3. WHERE a scheduled job runner is available, THE application SHALL run a periodic cron job (e.g., every 5 minutes) to batch-expire old boosts by setting `isBoosted = false` and `boostPriority = 0` on expired items.

### Requirement 9: Eager Loading for Booking Negotiation History

**User Story:** As a developer, I want booking queries to load negotiation history in a single query, so that the N+1 query pattern in getMyBookings is eliminated.

#### Acceptance Criteria

1. WHEN the Booking_Service fetches bookings in `getMyBookings`, THE Booking_Service SHALL include NegotiationEntry in the Sequelize `include` array (using the `negotiationHistory` association) instead of looping through bookings and querying one by one.
2. WHEN the Booking_Service fetches a single booking in `getBookingById`, THE Booking_Service SHALL include NegotiationEntry in the Sequelize `include` array.
3. THE Booking_Service SHALL order the included NegotiationEntry records by `createdAt ASC` within the include definition.

### Requirement 10: API Rate Limiting

**User Story:** As a platform operator, I want rate limiting on API endpoints, so that the system is protected from brute-force attacks, booking spam, and chat flooding.

#### Acceptance Criteria

1. THE Rate_Limiter SHALL enforce a global default rate limit on all API endpoints (e.g., 100 requests per minute per IP).
2. THE Rate_Limiter SHALL enforce a stricter rate limit on authentication endpoints (`/api/auth/login`, `/api/auth/register`, `/api/auth/firebase-auth`) to prevent brute-force attacks (e.g., 10 requests per minute per IP).
3. THE Rate_Limiter SHALL enforce a stricter rate limit on booking creation (`POST /api/bookings`) to prevent booking spam (e.g., 20 requests per minute per user).
4. THE Rate_Limiter SHALL enforce a stricter rate limit on message sending (`POST /api/chats/:id/messages`) to prevent chat flooding (e.g., 30 requests per minute per user).
5. WHEN a client exceeds the rate limit, THE Rate_Limiter SHALL return a 429 status code with a `Retry-After` header indicating when the client can retry.
6. THE Rate_Limiter SHALL use a store compatible with serverless deployment (e.g., in-memory with fallback, or an external store like Redis if available).

### Requirement 11: Backend Category Specs Validation

**User Story:** As a platform operator, I want the backend to validate item specs against the category schema, so that items cannot be created with invalid or missing spec fields.

#### Acceptance Criteria

1. WHEN an item is created or updated with a `specs` object, THE Item_Service SHALL validate the specs against the Category_Specs_Schema for the item's category.
2. WHEN a `select`-type spec field is provided, THE Item_Service SHALL verify the value is one of the allowed options defined in the Category_Specs_Schema.
3. WHEN a `number`-type spec field is provided, THE Item_Service SHALL verify the value is a valid number.
4. WHEN a `boolean`-type spec field is provided, THE Item_Service SHALL verify the value is a boolean.
5. IF the specs object contains keys not defined in the Category_Specs_Schema for the given category, THEN THE Item_Service SHALL strip the unknown keys or return a validation error.
6. IF the category is a clothing subcategory (e.g., `lehenga`, `saree`), THEN THE Item_Service SHALL resolve the parent category to `clothing` and validate specs against the clothing schema.

### Requirement 12: Document Chat Contact-Blocking Limitations

**User Story:** As a developer, I want the chat contact-blocking limitations documented and acknowledged, so that the team understands this is a best-effort filter and not a security boundary.

#### Acceptance Criteria

1. THE Chat_Service source code SHALL include a documentation comment on the `containsBlockedContent` function stating that regex-based contact blocking is a best-effort deterrent and can be circumvented by determined users.
2. THE Chat_Service source code SHALL include a documentation comment listing known bypass techniques (e.g., spelling out numbers, using Unicode lookalikes, inserting zero-width characters).
3. WHERE a future improvement is planned, THE documentation SHALL note that server-side ML-based content moderation or human review would be needed for stronger enforcement.

### Requirement 13: Soft Deletes for Items

**User Story:** As a platform operator, I want item deletions to be soft deletes, so that items with active bookings retain their data and historical records are preserved.

#### Acceptance Criteria

1. THE Item model SHALL enable Sequelize paranoid mode (`paranoid: true`) so that `destroy()` sets a `deletedAt` timestamp instead of physically removing the row.
2. WHEN an item is soft-deleted, THE Item_Service SHALL verify that the item has no active bookings (status in `pending`, `accepted`, `active`) before allowing the deletion.
3. IF an item has active bookings, THEN THE Item_Service SHALL reject the delete request with an error message indicating the item has active bookings.
4. WHEN querying items for browse or search, THE Item_Service SHALL exclude soft-deleted items by default (Sequelize paranoid mode handles this automatically).
5. THE Migration_System SHALL include a migration that adds a `deleted_at` TIMESTAMP column to the `items` table.

### Requirement 14: Socket.io Initialization and Serverless Fallback

**User Story:** As a developer, I want Socket.io properly initialized for local development and gracefully degraded on Vercel, so that real-time notifications work locally and the app does not error on serverless.

#### Acceptance Criteria

1. WHEN the application starts in non-Vercel mode (local development), THE application entry point SHALL create an HTTP server, attach Socket.io to the server, and store the io instance via `app.set('io', io)`.
2. WHEN the application runs on Vercel (serverless), THE application entry point SHALL skip Socket.io initialization and set `app.set('io', null)`.
3. WHEN a controller attempts to emit a socket event via `req.app.get('io')`, THE controller SHALL check that the io instance is not null before calling `.to().emit()` (this guard already exists in most controllers but must be verified for all emit sites).
4. THE Socket.io server SHALL authenticate connections using the same JWT token mechanism as the Auth_Middleware.
5. WHEN a socket client connects with a valid JWT, THE Socket.io server SHALL join the client to a room identified by the user's UUID so that targeted notifications can be emitted to `io.to(userId)`.


### Requirement 15: Razorpay Payment Gateway Integration

**User Story:** As a renter, I want to add money to my wallet and pay for bookings using Razorpay (UPI, cards, net banking), so that I can make real payments instead of relying on a simulated wallet balance.

#### Acceptance Criteria

1. THE backend SHALL integrate the `razorpay` npm package and configure it with `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET` environment variables.
2. WHEN a user requests to add money to their wallet, THE Razorpay_Service SHALL create a Razorpay_Order via the Razorpay Orders API with the requested amount (in paise), currency `INR`, and a receipt identifier.
3. THE Razorpay_Service SHALL expose a `POST /api/wallet/create-order` endpoint that returns the Razorpay order_id, amount, currency, and the Razorpay key_id to the frontend.
4. WHEN the frontend completes a Razorpay payment and sends back `razorpay_order_id`, `razorpay_payment_id`, and `razorpay_signature`, THE Razorpay_Service SHALL verify the Razorpay_Signature using HMAC-SHA256 with the key_secret.
5. IF the signature verification succeeds, THE Razorpay_Service SHALL credit the wallet balance and create a WalletTransaction with type `credit` and description referencing the Razorpay payment_id, all within a Sequelize_Transaction.
6. IF the signature verification fails, THE Razorpay_Service SHALL return a 400 error and NOT modify the wallet balance.
7. THE Razorpay_Service SHALL expose a `POST /api/wallet/verify-payment` endpoint for signature verification and wallet crediting.
8. THE Razorpay_Service SHALL support a webhook endpoint `POST /api/wallet/razorpay-webhook` that listens for `payment.captured` events as a fallback for cases where the frontend callback fails, verifying the webhook signature using the Razorpay webhook secret.
9. THE Razorpay_Service SHALL be idempotent — if a payment_id has already been processed (duplicate webhook or retry), it SHALL not credit the wallet again.
10. THE frontend Flutter app SHALL integrate the `razorpay_flutter` package to open the Razorpay checkout with the order_id received from the backend.
11. THE frontend SHALL handle Razorpay payment success, failure, and external wallet callbacks, sending the payment details to the verify endpoint on success.
12. THE frontend wallet screen SHALL show a "Add Money" button that triggers the Razorpay flow instead of (or in addition to) the current simulated wallet top-up.

### Requirement 16: Enhanced Delivery Flow with Proof of Receipt

**User Story:** As an owner, I want a button to mark my item as out-for-delivery, and as a renter, I want to confirm receipt by uploading a photo of the item, so that both parties have documented proof of the handoff.

#### Acceptance Criteria

1. WHEN an owner views an accepted/active booking with delivery option `delivery` or `in_app_delivery`, THE frontend SHALL display a "Mark Out for Delivery" button that calls `PATCH /api/bookings/:id/delivery-status` with `deliveryStatus: 'out_for_delivery'`.
2. WHEN the delivery status is `out_for_delivery`, THE frontend SHALL display the booking as "Out for Delivery" to both owner and renter.
3. WHEN the renter receives the item and the delivery status is `out_for_delivery`, THE frontend SHALL display a "Confirm Receipt" button that opens a camera/gallery picker to upload a Delivery_Proof_Image.
4. THE Booking_Service SHALL expose a `PATCH /api/bookings/:id/confirm-receipt` endpoint that accepts a multipart image upload, stores the image via the image upload service, saves the image filename in a new `receiptImage` field on the Booking model, and updates `deliveryStatus` to `delivered`.
5. THE Migration_System SHALL add a `receipt_image` TEXT column to the `bookings` table.
6. WHEN the renter confirms receipt, THE Booking_Service SHALL create a notification to the owner indicating the item has been received.
7. THE frontend booking detail screen SHALL display the receipt image (if present) to both owner and renter as proof of delivery.
8. IF the renter attempts to confirm receipt without uploading an image, THE frontend SHALL show a validation error requiring the image.

### Requirement 17: Dispute Image Evidence Upload

**User Story:** As a renter, I want to upload photos when raising a dispute about a damaged item, so that I have documented evidence to support my claim.

#### Acceptance Criteria

1. WHEN a renter views a booking where the item has been delivered (deliveryStatus is `delivered`), THE frontend SHALL display a "Raise Dispute" button on the booking detail screen.
2. WHEN the user taps "Raise Dispute", THE frontend SHALL open a dispute form that includes fields for reason, description, and an image picker allowing up to 5 images.
3. THE Dispute_Service (disputeController.js) `POST /api/disputes` endpoint SHALL accept multipart image uploads via `upload.array('images', 5)` in addition to the text fields (this partially exists but the route must include the upload middleware).
4. THE dispute route SHALL be updated to include `upload.array('images', 5)` middleware on the `POST /` route.
5. WHEN dispute images are uploaded, THE Dispute_Service SHALL store them via the image upload service in the `disputes/{bookingId}` folder and save the filenames in the Dispute.images array.
6. THE frontend dispute detail screen SHALL display all uploaded dispute images as scrollable evidence.
7. THE frontend SHALL show the dispute images on both the raiser's and the accused's dispute detail view so both parties can see the evidence.
8. THE Dispute model already has an `images` ARRAY(TEXT) field — no migration is needed for the images column itself.
9. WHEN a dispute is created with images, THE notification sent to the accused user SHALL mention that evidence images have been attached.


### Requirement 18: Role-Based Access Control (RBAC)

**User Story:** As a platform operator, I want a role system with user, seller, admin, and superadmin levels, so that different users have appropriate access to platform features.

#### Acceptance Criteria

1. THE Migration_System SHALL add a `role` column (STRING, default `'user'`) to the `users` table with allowed values: `user`, `seller`, `admin`, `superadmin`.
2. THE User model SHALL include a `role` field with validation `isIn: [['user', 'seller', 'admin', 'superadmin']]` and default value `'user'`.
3. THE Admin_Middleware SHALL be a new Express middleware that checks `req.user.role` is `admin` or `superadmin` and returns 403 if not.
4. THE application SHALL include a `superadminOnly` middleware that checks `req.user.role === 'superadmin'` and returns 403 if not.
5. THE existing `becomeSeller` endpoint SHALL be replaced by the KYC-based seller application flow (Requirement 19) — users can no longer self-promote to seller.
6. THE `toJSON()` method on User SHALL include the `role` field in the response.
7. THE frontend AuthProvider SHALL expose the user's role so that UI elements can be conditionally shown based on role.

### Requirement 19: Seller KYC Verification Flow

**User Story:** As a user who wants to become a seller, I want to submit my Aadhaar card and PAN card for verification, so that the platform can verify my identity before granting seller privileges.

#### Acceptance Criteria

1. THE Migration_System SHALL create a `seller_applications` table with columns: `id` (UUID PK), `user_id` (UUID FK to users, unique), `aadhaar_front` (TEXT), `aadhaar_back` (TEXT), `pan_front` (TEXT), `pan_back` (TEXT), `status` (STRING, default `'pending'`, values: `pending`, `approved`, `rejected`), `rejection_reason` (TEXT, default `''`), `reviewed_by` (UUID FK to users, nullable), `reviewed_at` (DATE, nullable), `created_at`, `updated_at`.
2. THE backend SHALL include a SellerApplication Sequelize model with the above schema and associations: `belongsTo User (userId)`, `belongsTo User (reviewedBy)`.
3. THE backend SHALL expose `POST /api/auth/seller-application` (auth required) that accepts multipart uploads for `aadhaar_front`, `aadhaar_back`, `pan_front`, `pan_back` images, stores them via the image upload service in `kyc/{userId}` folder, and creates a SellerApplication with status `pending`.
4. IF the user already has a pending or approved seller application, THE endpoint SHALL return a 400 error.
5. IF the user's previous application was rejected, THE endpoint SHALL allow resubmission by creating a new application (or updating the existing one).
6. THE frontend SHALL include a "Become a Seller" screen that shows 4 image upload slots (Aadhaar front, Aadhaar back, PAN front, PAN back) and a submit button.
7. WHEN the application is submitted, THE frontend SHALL show a "Pending Approval" status on the profile screen.
8. WHEN an admin approves the application (Requirement 20), THE Admin_Service SHALL update the user's role to `seller` and the application status to `approved`.
9. WHEN an admin rejects the application, THE Admin_Service SHALL set the application status to `rejected` with a reason, and send a notification to the user.
10. THE frontend profile screen SHALL show the current KYC status: not applied, pending, approved, or rejected (with reason).

### Requirement 20: Admin Panel — Item and Seller Approval

**User Story:** As an admin, I want a dashboard to review and approve/reject item listings and seller applications, so that only verified sellers and quality items appear on the platform.

#### Acceptance Criteria

1. THE backend SHALL expose admin-only routes under `/api/admin/` protected by the Admin_Middleware.
2. THE Admin_Service SHALL expose `GET /api/admin/items?status=pending_approval` to list all items awaiting approval, with pagination.
3. THE Admin_Service SHALL expose `PATCH /api/admin/items/:id/approve` to set an item's `approvalStatus` to `approved`, making it visible in browse/search.
4. THE Admin_Service SHALL expose `PATCH /api/admin/items/:id/reject` accepting a `rejectionReason` body field, setting the item's `approvalStatus` to `rejected`, and notifying the owner.
5. THE Migration_System SHALL add an `approval_status` column (STRING, default `'pending_approval'`, values: `pending_approval`, `approved`, `rejected`) and a `rejection_reason` (TEXT, default `''`) column to the `items` table.
6. THE Item model SHALL include `approvalStatus` and `rejectionReason` fields.
7. WHEN the Item_Service queries items for browse/search (`getItems`, `getRecommended`), THE WHERE clause SHALL include `approvalStatus = 'approved'` in addition to `isAvailable = true`.
8. THE Admin_Service SHALL expose `GET /api/admin/seller-applications?status=pending` to list all pending KYC applications with user details and document image URLs.
9. THE Admin_Service SHALL expose `PATCH /api/admin/seller-applications/:id/approve` to approve a seller application, update the user's role to `seller`, and notify the user.
10. THE Admin_Service SHALL expose `PATCH /api/admin/seller-applications/:id/reject` accepting a `rejectionReason`, update the application status, and notify the user.
11. THE Admin_Service SHALL expose `GET /api/admin/users` to list all users with filtering by role, with pagination.
12. THE Admin_Service SHALL expose `GET /api/admin/dashboard` returning platform stats: total users, total sellers, total items, pending items, pending seller applications, active bookings, total revenue.
13. WHEN an item is created by a seller, THE Item_Service SHALL set `approvalStatus` to `'pending_approval'` instead of making it immediately available.
14. THE frontend seller flow SHALL show items in `pending_approval` state with a "Pending Admin Approval" badge, and rejected items with the rejection reason.

### Requirement 21: Superadmin — Admin Account Management

**User Story:** As a superadmin, I want to create and manage admin accounts, so that I can delegate platform moderation to trusted team members.

#### Acceptance Criteria

1. THE backend SHALL expose `POST /api/admin/create-admin` (superadmin-only) that accepts `name`, `email`, `password`, `phone` and creates a new User with role `admin`.
2. IF the email or phone already exists, THE endpoint SHALL return a 400 error.
3. THE backend SHALL expose `GET /api/admin/admins` (superadmin-only) to list all users with role `admin`.
4. THE backend SHALL expose `PATCH /api/admin/users/:id/role` (superadmin-only) to change a user's role (e.g., demote an admin back to `user`, or promote a user to `admin`).
5. THE superadmin SHALL NOT be able to demote themselves or other superadmins via the API.
6. THE backend SHALL include a CLI seed script or a one-time setup endpoint (disabled in production) to create the initial superadmin account.
7. THE Admin_Panel (web dashboard) SHALL show an "Admin Management" section visible only to superadmins, listing all admins with options to create new admins or revoke admin access.

### Requirement 22: Admin Panel Web Dashboard

**User Story:** As an admin, I want a web-based dashboard to manage the platform, so that I can review items, seller applications, disputes, and users from a browser.

#### Acceptance Criteria

1. THE Admin_Panel SHALL be a server-rendered web portal hosted inside the backend project (e.g., using EJS, Handlebars, or a static SPA build served by Express) and accessible at a URL path like `/admin` (e.g., `https://rentit-indol.vercel.app/admin`).
2. THE Admin_Panel SHALL require login with admin or superadmin credentials using the same JWT auth system as the main API, with the JWT stored in an HTTP-only cookie or localStorage for the web session.
3. THE Admin_Panel dashboard page SHALL display platform stats: total users, sellers, items, pending approvals, active bookings, open disputes, and total revenue.
4. THE Admin_Panel SHALL include an "Items" page showing items filtered by approval status (pending, approved, rejected) with approve/reject action buttons.
5. THE Admin_Panel SHALL include a "Seller Applications" page showing KYC applications with document image previews and approve/reject buttons with a reason field for rejections.
6. THE Admin_Panel SHALL include a "Users" page with search and filter by role, showing user details and the ability to view their items, bookings, and reviews.
7. THE Admin_Panel SHALL include a "Disputes" page listing all disputes with status filters, showing evidence images, and allowing admins to update dispute status (under_review, resolved, dismissed) with a resolution note.
8. THE Admin_Panel SHALL include a "Bookings" page showing all bookings with status filters for platform-wide visibility.
9. THE Admin_Panel navigation SHALL conditionally show "Admin Management" only to superadmin users.
10. THE Admin_Panel SHALL be responsive and usable on both desktop and tablet screens.


### Requirement 23: Return Flow — Renter Initiates Return & Owner Pickup

**User Story:** As a renter, I want to initiate a return when I'm done with the item, so that the owner is notified to pick it up and the booking can be closed.

#### Acceptance Criteria

1. WHEN a booking is in `active` status and `deliveryStatus` is `delivered`, THE frontend SHALL display a "Return Item" button on the renter's booking detail screen.
2. WHEN the renter taps "Return Item", THE frontend SHALL call `PATCH /api/bookings/:id/return-status` with `returnStatus: 'pending'` to signal the renter is ready to return.
3. WHEN the return status changes to `pending`, THE Booking_Service SHALL create a notification to the owner saying the renter has initiated a return and the item is ready for pickup.
4. WHEN the owner picks up the item and inspects it, THE owner SHALL use the existing return status flow to mark it as `returned` (good condition) or `damaged` (with deduction), which completes the booking.
5. THE frontend renter booking detail SHALL show the current return status: "Not Returned", "Return Initiated — Waiting for Pickup", "Returned", or "Damaged".
6. THE frontend owner booking detail SHALL show a "Pick Up Item" prompt when return status is `pending`, with buttons to mark as "Returned" or "Damaged".

### Requirement 24: Owner Dashboard — Active Rentals with Due Dates

**User Story:** As an owner, I want to see all my rented-out items with their return due dates in one place, so that I can track which items are overdue and take action.

#### Acceptance Criteria

1. THE frontend SHALL include an "Active Rentals" section (tab or screen) in the owner's bookings view that shows all bookings where the owner is the item owner and status is `active` or `accepted`.
2. EACH booking card in the Active Rentals view SHALL display: item title, item image, renter name, renter avatar, start date, end date (due date), days remaining or days overdue (computed from `endDate` vs current date), and return status.
3. BOOKINGS where `endDate < today` and status is still `active` SHALL be visually highlighted as "Overdue" with a red badge or indicator.
4. THE Active Rentals list SHALL be sorted with overdue items first, then by nearest due date ascending.
5. THE backend `GET /api/bookings?role=owner` endpoint already supports this — no backend changes needed, only frontend presentation.

### Requirement 25: Owner Overdue Dispute & Return Request

**User Story:** As an owner, I want to request a return from an overdue renter or raise a dispute if they're unresponsive, so that I can recover my item or escalate the situation.

#### Acceptance Criteria

1. WHEN a booking is overdue (endDate has passed, status is `active`, returnStatus is `none`), THE frontend owner booking detail SHALL display a "Request Return" button.
2. WHEN the owner taps "Request Return", THE Booking_Service SHALL expose a `PATCH /api/bookings/:id/request-return` endpoint that sets a new `returnRequested` boolean field to `true` on the booking and sends a notification to the renter saying the owner has requested the item back.
3. THE Migration_System SHALL add a `return_requested` BOOLEAN column (default `false`) to the `bookings` table.
4. WHEN the renter receives the return request notification, THE frontend renter booking detail SHALL prominently display "Owner has requested return — please return the item" with the "Return Item" button.
5. WHEN a booking is overdue AND the owner has already requested return, THE frontend owner booking detail SHALL display a "Raise Overdue Dispute" button that pre-fills the dispute form with reason "Item overdue — renter unresponsive" and links to the booking.
6. THE Dispute model's `reason` validation (if any) SHALL accept `'overdue'` as a valid reason type.

### Requirement 26: In-App Calling — Owner Can Call Renter from Booking

**User Story:** As an owner, I want to call the renter directly from the booking detail screen, so that I can quickly check on the item status without leaving the app.

#### Acceptance Criteria

1. WHEN an owner views a booking detail for an active or overdue booking, THE frontend SHALL display the renter's name, avatar, and a "Call" button next to the renter info.
2. WHEN the owner taps the "Call" button, THE frontend SHALL use Flutter's `url_launcher` package to initiate a phone call to the renter's phone number via `tel:` URI scheme.
3. THE renter's phone number SHALL only be visible/callable if the owner has an active subscription that allows contact views (existing subscription/contact view logic), OR if the booking is in `active` status (since both parties are in an active transaction, contact should be allowed regardless of subscription).
4. THE backend `GET /api/bookings/:id` endpoint already returns renter phone in the include — THE frontend SHALL use this phone number for the call action.
5. THE "Call" button SHALL be disabled with a tooltip "Calling not available" if the renter's phone number is not available (e.g., contact locked due to subscription limits on non-active bookings).
6. THE frontend SHALL also show a "Call" button for the renter to call the owner on the renter's booking detail screen, using the same logic.
