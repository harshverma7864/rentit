---
inclusion: always
---

# Build, Run & Deploy

## Backend

### Local Development (Docker)
```bash
cd backend
docker compose up -d          # Starts PostgreSQL 16 + API on port 3000
docker compose logs -f api    # Tail API logs
docker compose down           # Stop everything
```

### Local Development (without Docker)
```bash
cd backend
npm install
# Ensure PostgreSQL is running and DATABASE_URL is set in .env
npm run dev                   # Uses nodemon for hot-reload
```

### Environment Setup
Copy `backend/.env.example` to `backend/.env` and fill in:
- `DATABASE_URL` — PostgreSQL connection string (local: `postgres://rentit:rentit_dev_pass@localhost:5432/rentit`)
- `JWT_SECRET` — any strong random string
- `IMAGE_UPLOAD_URL` — PHP upload endpoint (default: `https://rentpe.store/uploads/upload.php`)
- `IMAGE_UPLOAD_SECRET` — shared secret for image uploads
- `FIREBASE_SERVICE_ACCOUNT` — JSON string of Firebase service account credentials (optional for dev)

### Database
- Sequelize auto-syncs with `{ alter: true }` in development mode
- No migration files — schema changes are applied via model definitions on startup
- Docker Compose provisions a `rentit` database with user `rentit` / password `rentit_dev_pass`

### Production Deployment
- Backend deploys to Vercel as a serverless function via `vercel.json`
- Entry point: `src/index.js` using `@vercel/node` builder
- Routes are lazy-loaded to optimize cold starts
- `sequelize.sync()` is skipped on Vercel — schema must be managed separately in production
- Max function duration: 30 seconds

## Frontend

### Prerequisites
- Flutter SDK ^3.11.3
- Dart SDK ^3.11.3
- Android Studio or Xcode for platform builds

### Development
```bash
cd frontend
flutter pub get               # Install dependencies
flutter run                   # Run on connected device/emulator
flutter run -d chrome         # Run on web (if configured)
```

### Build
```bash
cd frontend
flutter build apk             # Android APK
flutter build appbundle        # Android App Bundle (for Play Store)
flutter build ios              # iOS (requires macOS + Xcode)
```

### Configuration
- API base URL is hardcoded in `lib/services/api_service.dart` as `ApiService.baseUrl`
- Image base URL: `ApiService.imageBaseUrl`
- Socket URL is hardcoded in `lib/services/socket_service.dart` as `SocketService.socketUrl`
- Firebase config: `android/app/google-services.json` (Android), `ios/Runner/GoogleService-Info.plist` (iOS)
- To switch between local and production API, toggle the commented `baseUrl` lines in `api_service.dart`

### App Icons
```bash
cd frontend
flutter pub run flutter_launcher_icons  # Regenerate app icons from assets/logo.jpeg
```

## Key URLs
- Production API: `https://rentit-indol.vercel.app/api`
- Production Socket: `https://rentit-kappa.vercel.app`
- Image CDN: `https://rentpe.store/uploads/images`
- Health check: `GET /api/health` (no auth required)
- DB health: `GET /api/health/db` (no auth required)
