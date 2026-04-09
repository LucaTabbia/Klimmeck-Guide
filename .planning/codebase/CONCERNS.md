# Codebase Concerns

**Analysis Date:** 2026-04-09

## Tech Debt

**Hardcoded Development Server URLs:**
- Issue: Default server URLs use hardcoded local network IP (192.168.0.20:3000) instead of environment-appropriate defaults
- Files: `lib/config/env_config.dart` (lines 17, 22, 27)
- Impact: Developers must manually override these values for production builds. Production URL will not be safely configured without explicit dart-define flags. Easy to accidentally deploy with development server URL.
- Fix approach: Move defaults to empty/placeholder values that require explicit configuration, or use a config file loaded at runtime. Consider separating development defaults from production requirements.

**Inconsistent Error Handling and Logging:**
- Issue: Mix of `print()`, `debugPrint()`, and silent failures across codebase. No centralized logging system.
- Files: 
  - `lib/repository/services/rest/rest.dart` line 55 (uses `print()`)
  - `lib/screens/splash/cubit/splash_cubit.dart` line 40 (uses `print()`)
  - `lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart` lines 22, 31 (uses `print()`)
  - `lib/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart` line 24 (uses `print()`)
  - `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart` line 22 (uses `print()`)
- Impact: In production builds, important error information via `print()` is dropped. Inconsistent approach makes debugging harder. No way to aggregate errors or send to monitoring services.
- Fix approach: Implement centralized logger (e.g., use `kDebugMode` conditionally, or integrate proper logging package). Replace all bare `print()` with consistent logging calls.

**GlobalKey Navigator Access Pattern:**
- Issue: GraphQL operations access `navigatorKey.currentContext!` at runtime with force unwrap (`!`)
- Files: `lib/repository/services/graphql/graphql.dart` lines 53, 67, 81
- Impact: If context is null (e.g., during app startup, after hot reload), app will crash. Hard to test. Tight coupling to root navigator. This is an anti-pattern for accessing context.
- Fix approach: Use dependency injection to pass BuildContext or GraphQL client down through providers. Consider making GraphQL client initialization not depend on current context. Use BlocProvider.of() safer patterns.

**Missing Null Safety in Type Casts:**
- Issue: Several unsafe type casts without null checks or try-catch
- Files:
  - `lib/repository/services/rest/rest.dart` lines 16, 31 (cast to `List<String>`)
  - `lib/repository/services/rest/rest.dart` line 50 (cast to `String`)
- Impact: If API response format changes or is unexpected, app crashes with uncaught exception. No graceful degradation.
- Fix approach: Wrap casts in try-catch, validate response structure before casting, use JSON validation layer.

**Uncontrolled In-Memory SVG Cache:**
- Issue: `SvgCache` stores unlimited File objects in memory without eviction policy
- Files: `lib/repository/cache/svg_cache.dart`
- Impact: Long-running app sessions will accumulate SVG files in memory, causing memory pressure and potential OOM crashes, especially with many different SVGs loaded (e.g., Cloudinary assets).
- Fix approach: Implement bounded cache with LRU eviction, or rely solely on disk-based `SvgCacheManager` which has `maxNrOfCacheObjects: 300` limit. Remove in-memory layer or add size cap.

**Fire-and-Forget Delayed Emissions:**
- Issue: Cubits emit state changes after delays without checking if stream is closed or widget is mounted
- Files:
  - `lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart` lines 18-20, 24-26
  - `lib/shared/components/cards/equipment_item_card.dart` line 62-64
- Impact: Potential emissions after Cubit/widget is disposed, memory leaks, unexpected state changes. The `isClosed` check in TransactionCubit is good but not comprehensive.
- Fix approach: Use `Timer` with proper cleanup in dispose, or emit state directly without delay. Consider using `Timer.periodic` with cancellation, or use Dart's `Timer` class with proper lifecycle management.

**Lint Rule Disabled in Analysis:**
- Issue: `avoid_print` rule commented out in `analysis_options.yaml`
- Files: `analysis_options.yaml` line 24
- Impact: Allows production of debug `print()` statements that won't work in release builds, contributing to above logging issues.
- Fix approach: Enable `avoid_print: true`, migrate all print statements to centralized logger, use `debugPrint()` only where appropriate.

## Known Bugs

**Test Widget Test Broken:**
- Symptoms: Test file references non-existent '+' button and counter widget that don't exist in actual app
- Files: `test/widget_test.dart`
- Trigger: Run `flutter test`
- Workaround: Skip/ignore this test for now. Replace with real test or remove.
- Root cause: Boilerplate test file was not updated when app was created; it's testing a default Flutter counter app template that doesn't exist in this project.

**Missing Firebase Configuration:**
- Symptoms: Firebase imports and initialization are commented out in main.dart
- Files: `lib/main.dart` lines 28-29
- Trigger: Attempting to use Firebase messaging or auth features
- Workaround: Firebase features are currently non-functional
- Root cause: Firebase setup incomplete or intentionally disabled, but dependencies remain in pubspec.yaml

## Security Considerations

**Exposed Development IP in Source:**
- Risk: Hardcoded local network IP (192.168.0.20) in version control makes it trivial to infer internal network structure
- Files: `lib/config/env_config.dart`
- Current mitigation: Can be overridden with dart-define at build time
- Recommendations: Remove from source entirely, use environment-specific build config. Use CI/CD secrets for production URLs. Consider build-time assertion to ensure production builds have correct URL configured.

**No Input Validation on Network Responses:**
- Risk: App assumes API responses match expected schema without validation. Malformed responses or MITM attacks could cause crashes or unexpected behavior.
- Files: `lib/repository/services/rest/rest.dart`, `lib/repository/services/graphql/graphql.dart`
- Current mitigation: Basic null checks on some fields
- Recommendations: Implement schema validation, use strongly-typed models with proper error handling, validate critical fields before casting.

**Dart Define Secrets Risk:**
- Risk: Sensitive values can be passed via `--dart-define` flags which appear in build logs
- Files: `lib/config/env_config.dart`
- Current mitigation: None
- Recommendations: For sensitive tokens/keys, use secure storage or file-based config loaded at runtime, never via command-line flags.

## Performance Bottlenecks

**Heavy SVG Loading in App Initialization:**
- Problem: `main.dart` preloads all SVG assets from AssetManifest at startup (lines 65-89)
- Files: `lib/main.dart` lines 66-89, 91-114
- Cause: Synchronous JSON parsing of manifest + async SVG cache population blocks startup
- Impact: App startup is delayed, no progress indication to user
- Improvement path: Defer non-critical SVG preloading to background after app is visible. Show splash screen during preload. Profile to identify critical vs. nice-to-have SVGs.

**Cloudinary SVG Download on Every App Run:**
- Problem: SVGs from Cloudinary are fetched on every component render if not cached
- Files: `lib/shared/components/cached_svg.dart`
- Cause: Two-layer cache (in-memory + disk) but no pre-warming of frequently-used SVGs
- Impact: Network requests for each asset on first view, visible loading delays
- Improvement path: Pre-fetch critical Cloudinary SVGs during splash screen. Cache invalidation strategy needed for asset updates.

**Unbounded MapController State:**
- Problem: WorldMap maintains many animation controllers and scroll state variables
- Files: `lib/screens/mainScreen/tabs/map/world_map.dart` lines 33-51
- Cause: Multiple AnimationControllers, ValueNotifiers, Timers without documented lifecycle
- Impact: Complex state management, potential memory leaks if not properly disposed
- Improvement path: Document lifecycle clearly, ensure all controllers are disposed in dispose method, consider refactoring to use BLoC pattern.

**Transaction Modal Rendering Complexity:**
- Problem: Large complex widget (324 lines) with nested layouts, animations, multiple setState calls
- Files: `lib/screens/mainScreen/tabs/shop/components/transaction_modal.dart`
- Cause: UI logic mixed with business logic, heavy use of setState
- Impact: Slow rebuilds when items are added/removed, difficult to optimize
- Improvement path: Refactor to smaller composable widgets, extract state to dedicated Cubit, use ValueNotifier or BlocBuilder for specific field updates instead of full setState.

**Manual Animation Duration Management:**
- Problem: Magic numbers for durations scattered throughout (300ms, 400ms, 4s)
- Files: Multiple files using `Duration(milliseconds: 300)`, `Duration(seconds: 4)` inline
- Cause: No centralized animation constants
- Impact: Inconsistent UX, hard to maintain, easy to introduce timing bugs
- Improvement path: Create AnimationConstants class with predefined durations, use consistently across app.

## Fragile Areas

**Null Coalescing in Equipment Widgets:**
- Files: `lib/shared/components/popup/equipment_info_sheet.dart`, `lib/shared/components/cards/equipment_item_card.dart`
- Why fragile: Heavy reliance on `widget.equipmentItem.equipType!.imagePath` and `widget.equipmentItem.name!` with force unwraps
- Safe modification: Add null checks before force unwrap, provide fallback images/names
- Test coverage: No unit tests visible; only integration tests via widget_test.dart which is broken

**Character Status Assumptions:**
- Files: `lib/screens/mainScreen/characterCubit/character_cubit.dart`, multiple widgets accessing `character.status?.currentLifePoints`, etc.
- Why fragile: Multiple Optional chaining but some paths use force unwrap (e.g., `character.status!.coins!` in transaction_modal.dart line 71)
- Safe modification: Ensure all character status access uses optional chaining with fallback values, never force unwrap
- Test coverage: None visible

**GraphQL Response Parsing:**
- Files: `lib/repository/services/graphql/graphql.dart` lines 85-100+ (all query methods)
- Why fragile: Pattern assumes exact data structure: `result.data?['keyName']` then direct `.fromJson()`. If any key changes, silent null returns or crashes.
- Safe modification: Implement response type guard function, validate structure before parsing
- Test coverage: Only widget_test smoke test exists

**Equipment Equip/Unequip Logic:**
- Files: `lib/screens/mainScreen/tabs/journal/journal.dart`, `lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart`
- Why fragile: Complex animation state management tied to UI logic, selectedEquipment state scattered across parent/child widgets
- Safe modification: Extract all equip logic to dedicated Cubit, use BlocBuilder instead of setState callbacks
- Test coverage: None

## Scaling Limits

**SVG Cache Disk Space:**
- Current capacity: `maxNrOfCacheObjects: 300` in `SvgCacheManager` (lib/repository/cache/svg_cache_manager.dart line 7)
- Limit: With large SVGs (50KB+ each), 300 * 50KB = ~15MB. If SVGs grow or cache period extends (stalePeriod: 30 days), disk usage becomes significant on low-storage devices
- Scaling path: Profile actual SVG sizes, adjust maxNrOfCacheObjects based on typical app usage patterns. Consider LRU replacement instead of FIFO.

**In-Memory GraphQL Cache:**
- Current capacity: `InMemoryStore()` with no size limits
- Limit: As user plays longer, queries accumulate. Character subscriptions + equipment queries + loot data will grow
- Scaling path: Implement bounded cache or persistent disk cache via `HiveStore` from graphql_flutter

**Animation Controller Proliferation:**
- Current capacity: Multiple AnimationControllers per screen (Journal, Shop, Map, etc.) each holding Ticker from TickerProviderStateMixin
- Limit: Each screen adds more controllers. No documented cleanup strategy
- Scaling path: Reuse AnimationControllers where possible, centralize animation logic, ensure proper disposal

## Dependencies at Risk

**Firebase Integration Incomplete:**
- Risk: Firebase dependencies declared but configuration commented out
- Files: `pubspec.yaml` lines 25-28, `lib/main.dart` lines 28-29
- Impact: Dead code, increases bundle size, may cause runtime crashes if any unreviewed code tries to use Firebase
- Migration plan: Either fully implement Firebase (auth, messaging) or remove entirely from pubspec.yaml. Make decision explicit.

**Cloudinary Hardcoded Base URL:**
- Risk: `dzuhywp53` account ID hardcoded throughout app
- Files: `lib/config/cloudinary_assets.dart`
- Impact: If account is compromised or URL structure changes, all assets break. SVGs cached offline won't update
- Migration plan: Consider using custom CNAME for Cloudinary, implement asset manifest with fallbacks

**GraphQL Client Initialization Fragility:**
- Risk: `initGraphQLClient()` in `graphql_client_provider.dart` depends on hardcoded URLs from env_config
- Files: Referenced from `lib/main.dart` line 30
- Impact: If URL loading fails, entire app fails to start. No fallback or retry logic
- Migration plan: Add initialization error handling, implement retry with exponential backoff, show error screen if client init fails

## Missing Critical Features

**No Error Recovery or Retry Logic:**
- Problem: Network failures (GraphQL queries, REST calls) fail silently or with generic error message
- Blocks: Users cannot recover from transient network errors, must restart app
- Files: Throughout `lib/repository/services/` - no retry mechanism, no offline fallback
- Recommendation: Implement retry decorator for queries, queue mutations for offline execution, show error with retry button

**No User-Facing Error Messages:**
- Problem: Errors are caught and converted to strings, but never shown to user in meaningful way
- Blocks: Users don't know why actions failed (network vs. validation vs. server error)
- Files: Cubits emit error states to string, UI doesn't display these meaningfully
- Recommendation: Implement proper error state model (code + localized message), show toast/snackbar on errors

**No Analytics or Crash Reporting:**
- Problem: App has no visibility into what users are doing or where crashes occur
- Blocks: Can't identify performance issues, can't debug production problems
- Files: No Firebase Analytics integration (Firebase is disabled), no Sentry-like error tracking
- Recommendation: Integrate Firebase Crash Reporting or Sentry, add basic analytics events

**No Offline Support:**
- Problem: All data is fetched live from GraphQL, no local caching strategy for viewing offline
- Blocks: Users cannot play if network is unavailable
- Files: No SQLite, Hive, or persistent storage of game data
- Recommendation: Implement Hive or SQLite for local cache, sync strategy for mutations

## Test Coverage Gaps

**No Unit Tests:**
- What's not tested: Cubits, models, utility functions, GraphQL parsing logic
- Files: Only `test/widget_test.dart` exists and it's broken
- Risk: Refactoring is dangerous, business logic has no safety net
- Priority: High - should add unit tests for Cubit logic and models before major changes

**No Integration Tests:**
- What's not tested: Flows like "load character -> equip item -> save", authentication, transactions
- Files: No integration test files
- Risk: End-to-end user flows can break without detection
- Priority: Medium - integration tests help catch state management bugs

**No Widget Tests Beyond Smoke Test:**
- What's not tested: Equipment info sheets, transaction modals, shop UI, map interactions
- Files: Only broken counter test exists
- Risk: UI bugs slip through, especially animation/transition issues
- Priority: Medium - widget tests for complex UI components (transaction_modal, equipment_info_sheet)

**No Performance Tests:**
- What's not tested: Startup time, SVG loading performance, map rendering performance with many markers
- Files: None
- Risk: Can't detect performance regressions
- Priority: Low - can add later once performance becomes concern

---

*Concerns audit: 2026-04-09*
