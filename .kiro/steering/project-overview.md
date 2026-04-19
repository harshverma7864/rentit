---
inclusion: always
---

# RentPe (RentIt) — Project Overview

RentPe is a peer-to-peer rental marketplace where users can list items for rent and book items from others. The app supports categories like clothing, electronics, vehicles, furniture, sports equipment, tools, books, cameras, and party supplies.

## Tech Stack

### Backend (`backend/`)
- Runtime: Node.js 20 (Alpine Docker image)
- Framework: Express 4.21
- ORM: Sequelize 6.37 with PostgreSQL 16
- Auth: JWT (jsonwebtoken) + Firebase Admin SDK for phone OTP
- Real-time: Socket.io 4.8
- File uploads: Multer (memory storage) → custom PHP upload server at rentpe.store
- Deployment: Vercel (serverless) for production, Docker Compose for local dev

### Frontend (`frontend/`)
- Framework: Flutter (Dart SDK ^3.11.3)
- State management: Provider pattern (ChangeNotifier)
- HTTP: `http` package with custom `ApiService` wrapper
- Real-time: `socket_io_client` for notifications
- Auth: Firebase Auth (phone OTP) + email/password via backend JWT
- Theme: Airbnb-inspired glassmorphic dark/light theme using Google Fonts (Poppins)
- Local storage: SharedPreferences

### Infrastructure
- Database: PostgreSQL 16 (Neon/Supabase in production, Docker locally)
- Image hosting: Custom PHP server (rentpe.store/uploads/)
- CI/CD: Vercel auto-deploy for backend

## Project Structure

```
rentit/
├── backend/
│   ├── src/
│   │   ├── config/          # database.js, categorySpecs.js
│   │   ├── controllers/     # Route handlers (auth, booking, chat, dispute, item, notification, review, subscription, wallet)
│   │   ├── middleware/       # auth.js (JWT verify), upload.js (Multer)
│   │   ├── models/           # Sequelize models + index.js (associations)
│   │   ├── routes/           # Express routers (9 modules)
│   │   ├── services/         # firebase.js, imageUpload.js
│   │   └── index.js          # App entry point with lazy-loading for Vercel
│   ├── hosting/upload.php    # PHP image upload endpoint
│   ├── docker-compose.yml    # Local dev: PostgreSQL + API
│   ├── Dockerfile            # Node 20 Alpine production image
│   └── vercel.json           # Vercel serverless config
├── frontend/
│   └── lib/
│       ├── models/           # Dart data models (user, item, booking, chat, dispute, notification, review, wallet)
│       ├── providers/        # ChangeNotifier providers (10 providers)
│       ├── screens/          # UI screens organized by feature (auth, bookings, chat, disputes, home, items, notifications, profile, subscription, wallet)
│       ├── services/         # api_service.dart, socket_service.dart
│       ├── theme/            # app_theme.dart (dark/light glassmorphic theme)
│       ├── widgets/          # Shared widgets (glass_widgets.dart)
│       └── main.dart         # App entry point, provider setup, splash screen
└── detailed_marketplace_plan.docx
```

## Data Models (Backend)

Core entities and their relationships:
- User → has many: Address, Item, Subscription (1:1), Wallet (1:1)
- Item → belongs to User (owner), has many Bookings
- Booking → belongs to Item, User (renter), User (owner); has many NegotiationEntry
- Chat → belongs to Item, Booking; many-to-many with User via ChatParticipant; has many Messages
- Review → belongs to User (reviewer), User (reviewee), Booking
- Wallet → has many WalletTransaction
- Dispute → belongs to Booking, User (raisedBy), User (againstUser)
- Subscription → has many ContactView
- Notification → belongs to User

All models use UUID primary keys, `underscored: true` column naming, and timestamps.

## API Routes

All routes are prefixed with `/api/`:
- `/api/auth` — register, login, firebase-auth, profile, location, addresses, become-seller
- `/api/items` — CRUD, categories, recommended, boost, availability
- `/api/bookings` — create, respond, complete, cancel, negotiate, delivery/alteration/return status
- `/api/chats` — chat management and messaging
- `/api/notifications` — user notifications
- `/api/wallet` — wallet and transactions
- `/api/reviews` — review management
- `/api/subscription` — subscription plans
- `/api/disputes` — dispute management
