# Technology Stack

**Analysis Date:** 2026-04-09

## Languages

**Primary:**
- Dart ^3.8.1 - Flutter application language for cross-platform mobile development

**Secondary:**
- Swift/Objective-C - iOS platform-specific code (minimal, managed by Flutter)
- Kotlin/Java - Android platform-specific code (minimal, managed by Flutter)

## Runtime

**Environment:**
- Flutter framework (cross-platform runtime for iOS and Android)
- Dart VM

**Package Manager:**
- pub (Dart/Flutter package manager)
- Lockfile: `pubspec.lock` - Present and committed

## Frameworks

**Core:**
- flutter ^3.x - Cross-platform mobile UI framework
- flutter_bloc ^9.1.1 - State management (BLoC pattern implementation)

**Testing:**
- flutter_test (SDK test framework) - Built into Flutter
- No dedicated testing runner package detected (tests run via `flutter test`)

**Build/Dev:**
- build_runner ^2.4.6 - Code generation for JSON serialization and build processes
- flutter_launcher_icons ^0.14.4 - App icon generation for iOS and Android

## Key Dependencies

**State Management & Architecture:**
- flutter_bloc ^9.1.1 - BLoC pattern for state management
- equatable ^2.0.0 - Value equality helper for state objects and models

**API & Communication:**
- graphql_flutter ^5.2.1 - GraphQL client with HTTP and WebSocket (subscription) support
- dio ^5.4.0 - HTTP client for REST API calls (used for Cloudinary and custom endpoints)

**Authentication & Services:**
- firebase_auth ^5.6.2 - Firebase Authentication (dependency present but not initialized in main.dart)
- firebase_core ^3.15.1 - Firebase core services (dependency present but not initialized)
- firebase_messaging ^15.2.9 - Firebase Cloud Messaging (dependency present but not enabled)

**UI & Rendering:**
- flutter_svg ^2.2.0 - SVG asset loading and caching
- cached_network_image ^3.2.3 - Network image caching with placeholder support
- google_fonts ^6.2.1 - Google Fonts integration
- auto_size_text ^3.0.0 - Responsive text sizing
- cupertino_icons ^1.0.8 - iOS-style icon pack

**Asset & Media:**
- flutter_cache_manager ^3.3.1 - Configurable cache manager for network and local assets
- url_launcher ^6.1.7 - Launch URLs and handle deep linking
- permission_handler ^12.0.1 - Cross-platform permission management

**Data Persistence:**
- shared_preferences ^2.0.12 - Local key-value storage for simple data (not encrypted)
- flutter_local_notifications ^19.3.0 - Local push notifications (dependency present, not actively used)

**Maps & Location:**
- flutter_map ^8.2.1 - OpenStreetMap-based mapping
- latlong2 ^0.9.1 - Latitude/longitude coordinate handling

**Internationalization & Time:**
- intl ^0.20.2 - i18n and localization (date/time formatting)
- collection ^1.19.1 - Utility collection functions

**Code Generation:**
- json_serializable ^6.7.0 - JSON serialization code generation for models

## Configuration

**Environment:**
- Configured via `lib/config/env_config.dart` using `String.fromEnvironment()` and `int.fromEnvironment()`
- Supports compile-time configuration with `flutter run --dart-define=KEY=VALUE`
- Key configs:
  - `GRAPHQL_HTTP_URL` - GraphQL endpoint (default: `http://192.168.0.20:3000/api/graphql`)
  - `GRAPHQL_WS_URL` - GraphQL WebSocket endpoint (default: `ws://192.168.0.20:3000/api/graphql`)
  - `BASE_URL` - REST API base URL (default: `http://192.168.0.20:3000/`)
  - `CLOUDINARY_BASE_URL` - Cloudinary asset delivery URL (default: `https://res.cloudinary.com/dzuhywp53/image/upload`)
  - `QUERY_TIMEOUT_SECONDS` - GraphQL query timeout (default: 30s)
  - `WS_INACTIVITY_TIMEOUT_SECONDS` - WebSocket inactivity timeout (default: 30s)
  - `DEBUG` - Debug mode flag (default: true)
  - `ENABLE_LOGGING` - Logging toggle (default: true)

**Build:**
- `pubspec.yaml` - Dart package manifest with Flutter configuration
- `build.yaml` - (implied, managed by build_runner)
- App icon configuration in pubspec.yaml with flutter_launcher_icons

**Platform Config:**
- iOS: `ios/Podfile` (CocoaPods dependency management)
- Android: `android/build.gradle`, `android/app/build.gradle` (Gradle build system)

## Platform Requirements

**Development:**
- Dart SDK ^3.8.1
- Flutter SDK (recent stable)
- iOS: Xcode 12+ with iOS 12+ deployment target
- Android: Android SDK with minSdkVersion 21+ (implied by dependencies)
- Device or emulator for testing

**Production:**
- iOS: Deployed via App Store or TestFlight
- Android: Deployed via Google Play Store or direct APK distribution
- Minimum OS: iOS 12.0+, Android 5.1+ (API 21+)

---

*Stack analysis: 2026-04-09*
