# External Integrations

**Analysis Date:** 2026-04-09

## APIs & External Services

**GraphQL Backend:**
- Backend server providing game data (characters, quests, equipment, lore, cities)
  - SDK/Client: `graphql_flutter` ^5.2.1
  - HTTP Endpoint: Configured in `EnvConfig.graphqlHttpUrl` (default: `http://192.168.0.20:3000/api/graphql`)
  - WebSocket Endpoint: Configured in `EnvConfig.graphqlWsUrl` (default: `ws://192.168.0.20:3000/api/graphql`)
  - Client implementation: `lib/repository/services/graphql/graphql_client_provider.dart`
  - Queries/Mutations/Subscriptions: Located in `lib/graphql/` directory

**REST API:**
- Custom REST endpoints for Cloudinary integration and image uploads
  - SDK/Client: `dio` ^5.4.0
  - Base URL: Configured in `EnvConfig.baseUrl` (default: `http://192.168.0.20:3000/`)
  - Client singleton: `lib/repository/services/rest/rest_client_provider.dart`
  - Timeouts: 10 seconds for both connect and receive
  - Endpoints (in `lib/repository/services/rest/rest.dart`):
    - `POST /cloudinary/getUrls` - Fetch Cloudinary folder URLs
    - `POST /cloudinary/getSubfoldersUrls` - Fetch Cloudinary subfolder URLs
    - `POST /uploadImage` - Upload image files to backend

**Cloudinary:**
- CDN for serving game assets (SVGs, images, icons)
  - Service: Cloudinary image hosting and delivery
  - Base URL: `https://res.cloudinary.com/dzuhywp53/image/upload` (configured in `EnvConfig`)
  - Account ID: `dzuhywp53`
  - Assets: All paths defined in `lib/config/cloudinary_assets.dart`
  - Usage: CachedNetworkImage and custom SVG loaders
  - Caching: Handled by `flutter_cache_manager` and local HTTP cache

## Data Storage

**Databases:**
- Remote: GraphQL backend database (managed by server, not directly accessed)
  - Connection: HTTP/WebSocket via GraphQL endpoints
  - Client: `graphql_flutter`
  - Models: Located in `lib/models/` directory

**File Storage:**
- Local filesystem only (device-specific)
- Cloudinary CDN for remote image/asset storage
- No direct cloud storage SDK (S3, Firebase Storage, etc.)

**Caching:**
- **HTTP Cache Manager**: `flutter_cache_manager` ^3.3.1
  - Custom SVG cache in `lib/repository/cache/svg_cache_manager.dart`
  - Cache expiry logic in `lib/repository/cache/cache_expiry.dart`
  - Used for SVG and image assets from Cloudinary
- **Shared Preferences**: `shared_preferences` ^2.0.12
  - Purpose: Local key-value storage for app state
  - Manager: `lib/repository/storage/storage_manager.dart`
  - Stores: Cached Cloudinary URLs (`cachedUrls` key)
  - Note: Unencrypted, suitable only for non-sensitive data

## Authentication & Identity

**Auth Provider:**
- Firebase Authentication (dependency present, currently disabled)
  - SDK: `firebase_auth` ^5.6.2
  - Status: Imported but not initialized (see `main.dart` line 28, commented out)
  - Implementation path: `lib/screens/signIn/cubit/sign_in_cubit.dart`
  - Could support email/password, OAuth, etc. when enabled

**Custom Auth (Current):**
- GraphQL-based authentication (implied by backend integration)
- Sign-in flow managed via `SignInCubit` in `lib/screens/signIn/cubit/sign_in_cubit.dart`
- No visible JWT or token storage implementation (may be handled by GraphQL client)

## Monitoring & Observability

**Error Tracking:**
- None detected (no Sentry, Crashlytics, etc.)
- Generic error handling via `KlimmeckGraphQl.getGenericErrorMessage()` in `lib/repository/services/graphql/graphql.dart`

**Logs:**
- Console/debugPrint approach
  - Debug logs controlled by `EnvConfig.enableLogging` and `EnvConfig.isDebug`
  - Logs emitted in: asset loading (`main.dart`), error handling
  - No persistent logging infrastructure

## CI/CD & Deployment

**Hosting:**
- iOS: Apple App Store or TestFlight (deployment target)
- Android: Google Play Store or direct APK distribution
- Backend: Custom server at `192.168.0.20:3000` (development) or configurable via `dart-define`

**CI Pipeline:**
- None detected in codebase (no .github/workflows, .gitlab-ci.yml, etc.)
- Build managed locally or via IDE

## Environment Configuration

**Required env vars (compile-time via dart-define):**
- `GRAPHQL_HTTP_URL` - GraphQL HTTP endpoint
- `GRAPHQL_WS_URL` - GraphQL WebSocket endpoint
- `BASE_URL` - REST API base URL
- `CLOUDINARY_BASE_URL` - Cloudinary CDN URL
- `QUERY_TIMEOUT_SECONDS` - GraphQL timeout (optional, defaults to 30)
- `WS_INACTIVITY_TIMEOUT_SECONDS` - WebSocket timeout (optional, defaults to 30)
- `DEBUG` - Debug mode (optional, defaults to true)
- `ENABLE_LOGGING` - Enable logs (optional, defaults to true)

**Secrets location:**
- No .env file detected or needed (uses compile-time Dart constants)
- Sensitive data (if any) would need Firebase config for iOS (`GoogleService-Info.plist`) and Android (`google-services.json`)
- Currently not committed to repo (Firebase features disabled)

## Webhooks & Callbacks

**Incoming:**
- None explicitly configured
- Push notifications supported via `flutter_local_notifications` ^19.3.0 (Firebase Cloud Messaging disabled)

**Outgoing:**
- No external webhooks detected
- All communication is request-response (REST POST, GraphQL query/mutation/subscription)

## Integration Flow Summary

```
┌──────────────────────────────────────────┐
│      Klimmeck Guide Mobile App           │
│         (Flutter/Dart)                   │
└──────────────────────────────────────────┘
              │                │
              │                │
     ┌────────▼────────┐  ┌────▼──────────┐
     │  GraphQL Client │  │   REST Client │
     │  (graphql_flutter)   (dio)        │
     └────────┬────────┘  └────┬──────────┘
              │                │
     ┌────────┴────────────────┴──────────┐
     │   Backend API Server               │
     │  (192.168.0.20:3000)               │
     │                                    │
     │  HTTP: /api/graphql                │
     │  WebSocket: /api/graphql           │
     │  REST: /cloudinary/*, /uploadImage │
     └────────┬───────────────────────────┘
              │
     ┌────────▼──────────────────────────┐
     │   Cloudinary CDN                   │
     │ (res.cloudinary.com/dzuhywp53)     │
     │   - SVG assets                     │
     │   - Images                         │
     └────────────────────────────────────┘

Local Storage:
├── Shared Preferences (shared_preferences)
│   └── Cached URLs, simple KV data
├── Flutter Cache Manager (flutter_cache_manager)
│   └── SVG and image cache
└── Device Filesystem
    └── App documents and temp files
```

---

*Integration audit: 2026-04-09*
