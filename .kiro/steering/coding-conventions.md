---
inclusion: always
---

# Coding Conventions

## Backend (Node.js / Express)

### File & Naming
- Controllers: `camelCase` function names, exported as `exports.functionName`
- Models: PascalCase file names matching the Sequelize model name (e.g., `User.js`, `WalletTransaction.js`)
- Routes: lowercase plural file names (e.g., `bookings.js`, `items.js`)
- All Sequelize models use `underscored: true` — JS fields are camelCase, DB columns are snake_case

### Model Patterns
- UUID v4 primary keys on all models
- Every model defines a custom `toJSON()` that adds `_id = id` for frontend compatibility
- Location fields are stored as flat columns (`latitude`, `longitude`, `locationAddress`, `locationCity`) and assembled into a GeoJSON-like `location` object in `toJSON()`
- Flexible attributes use JSONB columns (e.g., `Item.specs`)
- Associations are defined centrally in `models/index.js`, not in individual model files
- Validation uses Sequelize's built-in `validate` with `isIn` for enum-like fields

### Controller Patterns
- Every controller function is an async `(req, res) => {}` wrapped in try/catch
- Errors return `res.status(4xx).json({ error: error.message })`
- Success responses return the resource as `{ resourceName: data }` (e.g., `{ booking: result }`)
- Auth-protected routes access the user via `req.user` (set by auth middleware)
- Socket.io notifications are emitted via `req.app.get('io')` when available
- Notifications are created in-DB alongside socket emissions

### Route Patterns
- All routes are prefixed with `/api/` (mounted in index.js)
- Auth middleware is applied per-route, not globally
- File uploads use `upload.array('images', 5)` or `upload.single('avatar')`
- Route files only define routes — no business logic

### Error Handling
- No centralized error middleware — each controller handles its own errors
- Standard pattern: `try { ... } catch (error) { res.status(400).json({ error: error.message }); }`

### Environment Variables
- `DATABASE_URL` — PostgreSQL connection string
- `JWT_SECRET` — JWT signing secret
- `IMAGE_UPLOAD_URL` — PHP upload endpoint URL
- `IMAGE_UPLOAD_SECRET` — Upload auth secret
- `FIREBASE_SERVICE_ACCOUNT` — JSON string of Firebase service account
- `PORT` — Server port (default 3000)

## Frontend (Flutter / Dart)

### File & Naming
- Files: snake_case (e.g., `auth_provider.dart`, `item_model.dart`)
- Classes: PascalCase (e.g., `AuthProvider`, `ItemModel`)
- Providers: `{Feature}Provider` extending `ChangeNotifier`
- Models: `{Feature}Model` with `fromJson` factory and `toJson` method
- Screens: `{Feature}Screen` as StatefulWidget or StatelessWidget

### State Management
- Provider pattern with `ChangeNotifier` — one provider per domain
- Providers are registered in `main.dart` via `MultiProvider`
- Private state fields with public getters (e.g., `List<ItemModel> _items = []; List<ItemModel> get items => _items;`)
- Loading/error state: `_isLoading` bool + `_error` nullable string on every provider
- Always call `notifyListeners()` after state changes
- API calls wrapped in try/catch, setting `_error` on failure

### API Service
- Centralized `ApiService` class in `services/api_service.dart`
- Base URL configured as static const
- Token management via SharedPreferences
- Methods: `get`, `post`, `patch`, `delete`, `multipartPost`, `multipartPatch`
- All responses parsed as `Map<String, dynamic>`
- Custom `ApiException` class with message and statusCode

### Model Patterns
- All models have `fromJson` factory constructor and `toJson` method
- IDs accept both `json['id']` and `json['_id']` for backend compatibility
- Nullable fields use `??` with sensible defaults
- Numeric fields use `.toDouble()` for type safety
- Image URLs are computed via getters using `ApiService.imageBaseUrl`

### Theme & UI
- `AppTheme` class with static getters that react to `isDark` toggle
- Airbnb-inspired color palette with Rausch red (#FF385C) as primary
- Google Fonts Poppins as the default text theme
- Glassmorphic design using `BackdropFilter` and semi-transparent surfaces
- Shared widgets in `widgets/` directory (GlassCard, GlassButton, GlassTextField, StatusBadge)
- Border radius: 16px for inputs/buttons, 20px for cards, 24px for elevated containers
- Use `withValues(alpha: x)` for opacity (not `withOpacity`)

### Navigation
- `MaterialApp` with `home:` property (no named routes)
- Navigation via `Navigator.push` / `Navigator.pushReplacement` with `MaterialPageRoute`
- `SplashScreen` checks auth state and redirects to `WelcomeScreen` or `MainNavScreen`

### Widget Conventions
- Use `const` constructors wherever possible
- Use `super.key` in widget constructors
- Prefer `StatelessWidget` unless local state is needed
- Use `context.read<Provider>()` for one-time reads, `context.watch<Provider>()` for reactive rebuilds
