# RentIt - Peer-to-Peer Rental Marketplace

A full-stack mobile application where users can rent and list items for short-term use.

## Architecture

- **Backend**: Node.js + Express + MongoDB + Socket.IO
- **Frontend**: Flutter (Hybrid - Android/iOS/Web)
- **Database**: MongoDB
- **Real-time**: Socket.IO for notifications
- **Containerization**: Docker + Docker Compose

## Getting Started

### Backend (Docker)

```bash
cd backend
docker-compose up --build
```

The API will be available at `http://localhost:3000`

### Backend (Local - without Docker)

```bash
cd backend
# Make sure MongoDB is running locally
# Update .env with MONGODB_URI=mongodb://localhost:27017/rentit
npm install
npm run dev
```

### Frontend (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

> **Note**: Update the API base URL in `frontend/lib/services/api_service.dart`:
> - Android Emulator: `http://10.0.2.2:3000/api`
> - iOS Simulator: `http://localhost:3000/api`
> - Physical device: `http://<YOUR_LOCAL_IP>:3000/api`

## API Endpoints

### Auth
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `GET /api/auth/profile` - Get profile
- `PATCH /api/auth/profile` - Update profile
- `PATCH /api/auth/location` - Update location

### Items
- `GET /api/items` - Browse items (search, filter, sort, paginate)
- `GET /api/items/:id` - Get item details
- `POST /api/items` - List new item
- `PATCH /api/items/:id` - Update item
- `DELETE /api/items/:id` - Delete item
- `GET /api/items/mine` - Get my listings
- `GET /api/items/categories` - Get categories

### Bookings
- `POST /api/bookings` - Create rental request
- `GET /api/bookings` - Get my bookings (query: role=renter|owner)
- `GET /api/bookings/:id` - Get booking details
- `PATCH /api/bookings/:id/respond` - Accept/reject (owner)
- `PATCH /api/bookings/:id/complete` - Complete rental
- `PATCH /api/bookings/:id/cancel` - Cancel booking

### Notifications
- `GET /api/notifications` - Get notifications
- `GET /api/notifications/unread-count` - Get unread count
- `PATCH /api/notifications/:id/read` - Mark as read
- `PATCH /api/notifications/read-all` - Mark all as read

## Features

- **Two Roles**: Giver (list items) & Taker (rent items) - switchable
- **Location-based Search**: Find items near you
- **Full Rental Flow**: Request → Accept/Reject → Deliver → Complete
- **Real-time Notifications**: via Socket.IO
- **Scheduling**: Pick delivery time slots
- **Booking Management**: Track all rentals and requests
- **Glassmorphic UI**: Modern dark theme with blue accent
