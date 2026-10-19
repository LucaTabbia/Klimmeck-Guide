# Phase 5: Notifications Infrastructure - Research

**Researched:** 2026-10-19
**Domain:** Flutter 3.35.5 / Dart 3.9.2 push client on Android: `firebase_core` 3.15.1 + `firebase_messaging` 15.2.9 (data-only FCM), `flutter_local_notifications` 19.3.0, `permission_handler` 12.0.1, `url_launcher` 6.3.2, `shared_preferences` 2.5.3 (`SharedPreferencesAsync`), `uuid` 4.5.1; Google Services Gradle plugin 4.5.0 on AGP 8.9.1 / Gradle 8.12 / Kotlin 2.1.0; GraphQL `registerPushDevice` / `unregisterPushDevice`
**Confidence:** HIGH for the build/dependency facts (proved this session with a real `pub get` and three scratch Android builds), the GraphQL contract (documents validated against BE `origin/develop` `0828719` with the BE `graphql` 16.11.0) and every plugin behaviour quoted from the plugin source in the local pub cache. MEDIUM for on-device runtime behaviour that can only be observed on the phone (background-isolate delivery when killed on the Samsung, `SharedPreferencesAsync` cross-engine reads): source and docs agree, the UAT confirms.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Firebase bootstrap & push stack (NOTIF-01, NOTIF-03..05)
- **D-01:** Stack confirmed: `firebase_core` + `firebase_messaging` (already in `pubspec.yaml`, `^3.15.1` / `^15.2.9`) for token, permission status and message streams; `flutter_local_notifications` (`^19.3.0`, present) to display the system notification built from the data-only payload (the backend never sends a `notification` block, BE Phase 5 D-10); `permission_handler` (present) only for `openAppSettings()` (D-10); `url_launcher` (present) for the Twitch link (D-16). The only new runtime dependency is `uuid` (D-05). The researcher pins versions against the Flutter 3.35.5 / Dart 3.9.2 baseline (Phase 2 D-30/D-31).
- **D-02 (user decision):** `android/app/google-services.json` (and, for the future iOS phase, `GoogleService-Info.plist`) stay **out of the VCS**: `.gitignore` entries plus a comment in `.env.example`/README on where the file comes from. `Firebase.initializeApp()` runs in `main()` before `runApp` inside a guard: if it fails (file missing in a dev checkout, CI) push is **disabled with a `debugPrint` warning and the game runs unchanged** — the composition root wires a no-op messaging port. Mirror of the backend's `NoopPushTransport`. Tests never touch Firebase (D-19).
- **D-03 (user decision — Android only):** native wiring is explicit Wave 0 work (Phase 11 D-34 / Phase 2 D-31 pattern), verified with a scratch build: `com.google.gms.google-services` Gradle plugin, `POST_NOTIFICATIONS` permission in `AndroidManifest.xml`, a notification channel `klimmeck_events` (high importance, default sound) created at startup. **Nothing under `ios/` changes** in this phase; iOS (Info.plist background modes, entitlements, APNs key, iOS UAT) is a deferred item for a later phase. `platform: android` is what the app registers; the code stays platform-agnostic behind the ports (D-19).
- **D-04:** Delivery semantics follow the backend contract verbatim (`BACKEND-NOTES.md` §2): `data.type` maps 1:1 onto `NotificationCategory` (`travelEnd`, `streamerLive`, `questEnd`); `id` is present only for personal types; an unknown `type` (the future `combatResult`) is dropped with a debug log and never crashes. The FE never subscribes to FCM topics — the backend does it server-side at registration.
- **D-05 (Boy Scout, user decision):** `firebase_auth` is removed from `pubspec.yaml` (login is backend-mediated since Phase 11; the researcher confirms no import) and the legacy `lib/utils/notification.dart` (`NotificationsBloc` importing `rxdart`, not a dependency) is deleted.

#### Device identity & registration lifecycle (NOTIF-01)
- **D-06:** `deviceId` = **UUID v4 generated once and persisted device-wide** in `shared_preferences` (a key not scoped by user, e.g. `klimmeck.push.deviceId`), never rotated: it survives logout and account switch and dies only with a reinstall (the backend row then expires by TTL). Package `uuid`. A `DeviceIdentityStore` in `lib/repository/storage/` follows the `SharedPreferencesAsync` + injectable-factory pattern of `NotificationPreferencesStore`.
- **D-07:** Registration is owned by a Flutter-free **`PushRegistrationCoordinator`** (`lib/repository/services/push/`) that observes `AuthTokenService.authStateStream` and the messaging port's token stream: `AuthAuthenticated` (login **and** cold-start bootstrap) with a token available → `registerPushDevice({ deviceId, token, platform: android })`; `onTokenRefresh` while authenticated → re-register; a token arriving after login → register then. Silent and non-blocking (rule 2): bounded exponential retry with `lib/utils/backoff.dart` on transient failures, no UI ever; `PUSH_INVALID_DEVICE_ID` / `PUSH_INVALID_TOKEN` / `UNAUTHENTICATED` → log, no retry (FE bug or ended session). Registration does **not** wait for the OS permission (Android tokens exist without it). GraphQL documents `RegisterPushDevice` / `UnregisterPushDevice` in `lib/graphql/mutations/push_mutations.dart`; a `PushDeviceRepository` maps `extensions.code` (pattern `CharacterDeletionRepository`).
- **D-08 (user decision):** `unregisterPushDevice(deviceId)` is orchestrated by **`AuthCubit.logout()`**: it first awaits the coordinator's `unregister()` (best-effort, **2 s timeout**, failures logged only), then calls `_authTokenService.logout()` as today. `confirmLogout` and the creation page "Esci" already go through `AuthCubit.logout()`, so the order "unregister → backend `logout`" holds for every user-initiated logout. The auth services and the `AuthTokenService` contract (Phase 1 D-02) are untouched. Revocation and sync-lost terminations do **not** unregister (no usable bearer); the backend's token claim at the next login covers them (BE §5 point 6).
- **D-09:** The active account is mirrored on the device for the background isolate: an **`ActiveUserStore`** (shared_preferences, e.g. `klimmeck.push.activeUserId`) written on `AuthAuthenticated` and cleared when the session ends (logout, revocation, sync lost). The background handler reads it to resolve the per-user toggles (Phase 4 D-11 keys); no active user → the message is dropped silently.

#### Notification permission (NOTIF-02)
- **D-10 (user decisions):** Phase 5 ships one idempotent entry point, **`NotificationPermissionGate.ensureRequested()`** (Flutter-free service over `requestPermission()` / `getNotificationSettings()` of the messaging port): prompts only when the OS status is `notDetermined`, otherwise returns the current status; nothing is persisted (the OS is the source of truth). **Phase 5 never calls it**: the only trigger is the **first travel confirmation, wired by Phase 7** (call site documented in this phase's handoff for Phase 7). A test guards that `main.dart`/`AuthGate`/`SplashScreen`/Settings never reach the prompt. In Settings, under the three toggles, a **hint row appears only when the OS permission is `denied`** ("Le notifiche di sistema sono disattivate" + "Attiva" → `openAppSettings()`); nothing is shown while the status is `notDetermined`. No nagging anywhere else.
- **D-11 (user decision):** The Phase 5 UAT grants the permission **manually from the Android system settings** (Settings › Apps › Notifications): no dev-only trigger, nothing to strip in Phase 12.

#### Receiving & displaying in the three app states (NOTIF-03, NOTIF-04, NOTIF-05)
- **D-12:** A top-level `@pragma('vm:entry-point')` background handler registered with `FirebaseMessaging.onBackgroundMessage` in `main()` before `runApp` covers background and terminated states. Its logic is a **pure function** `handleDataMessage(data, {activeUser, preferences, notifier})` testable with fakes: parse → map type → read `ActiveUserStore` + `NotificationPreferencesStore` → if enabled, show a local notification (title/body from `data`, payload = JSON of `data`, channel `klimmeck_events`); otherwise nothing. The isolate initialises Firebase and `flutter_local_notifications` itself.
- **D-13:** Foreground (`onMessage`): **never a system notification**; the same filter feeds the in-app banner (D-17). This *is* the NOTIF-08 rule "foreground suppresses the duplicate push".
- **D-14:** Toggles apply in all three states before anything is shown (banner included). `getNotificationAppLaunchDetails()` / `getInitialMessage()` are consulted once at startup for a tap that launched the app (D-15).

#### Tap routing (NOTIF-06 — amended 2026-10-19)
- **D-15:** Every tap becomes a **`NotificationIntent { type, id?, sentAt }`** model (`lib/models/`). Sources: the `flutter_local_notifications` response callback + launch details (the system notification is always the FE-built one for data-only messages) and, belt and braces, FCM `onMessageOpenedApp` / `getInitialMessage`. Intents for personal types are buffered in a **`PendingNotificationIntent`** holder provided above `AuthGate` and **consumed declaratively by `MainScreen`** once the authenticated shell with a character is mounted: `pageController.jumpToPage(0)` (WorldMap is index 0 in `_buildPages`). **No popup in this phase** for `travelEnd`/`questEnd` (user decision): Phases 7 and 9 add their context popups behind a per-type hook (`NotificationPopupRegistry` or equivalent) that Phase 5 leaves empty. The intent survives splash and sign-in (killed state → login → consumed), is cleared on consumption or at logout, and is dropped when the session lands on the creation page (no character). No imperative global router: the ROADMAP's "NavigationService GlobalKey" is not needed; the existing `navigatorKey` stays for future popups.
- **D-16 (user decision):** A **`streamerLive` tap opens the Twitch channel directly** — `https://www.twitch.tv/lordreavor`, a constant in `lib/config/` (e.g. `TwitchChannel.url`; not a secret) — through `url_launcher` (`LaunchMode.externalApplication`), without passing through the Map tab or a popup. The same action applies to the banner tap (D-17). The earlier idea of a streamer-live popup with a "Guarda la live" button is superseded by this direct action. NOTIF-06 and ROADMAP success criterion 4 carry a dated amendment (done in this discuss).

#### In-app banner & dedup (NOTIF-07, NOTIF-08)
- **D-17 (user decision):** Foreground events render as an **in-app banner** built on **`KGNotification(title, description)`** (existing model in `lib/models/notification.dart`; Boy Scout: `Equatable`, `const` constructor, `fromJson` kept): a **thin strip at the top** of the screen in the parchment/ink language from `kg_theme.dart` (no `SnackBar`, no `MaterialBanner`), **auto-dismiss ≈ 5 s**, one banner at a time via a queue in an **`InAppNotificationsCubit`**. **Tap behaviour is per type and identical to the system notification**: `travelEnd`/`questEnd` → Map tab (D-15), `streamerLive` → Twitch (D-16); a type with no action (none today) is purely informative. The cubit is provided in `AuthenticatedShell` (banners need a character; the creation page shows none).
- **D-18:** `InAppNotificationsCubit.publish(event)` is the **single publication path** for every producer (FCM foreground now; the subscription-driven producers of Phases 7/9 later) and **dedups by `(type, id)`** — `(type, sentAt minute)` for the id-less `streamerLive` — within a sliding in-memory window (≈ 2 min; 15 min for `streamerLive`). Together with D-13 this guarantees one surface per event in foreground; background/killed states only ever have the system notification.

#### Architecture, tests, tooling, branch
- **D-19:** **Ports & adapters, no plugin in tests:** `PushMessagingPort` (token, token stream, request permission, settings, message streams, initial message) over `firebase_messaging`; `LocalNotificationsPort` (init, show, tap stream, launch details) over `flutter_local_notifications`; a `LinkOpener` port over `url_launcher`; fakes under `test/`. Layering per `docs/rules/architecture.md`: ports/adapters/coordinator/gate in `lib/repository/services/push/`, repository in `lib/repository/`, models in `lib/models/`, documents in `lib/graphql/mutations/`, cubits in the consuming feature, shared widgets in `lib/shared/components/` with the `Kg` prefix. UI → Cubit → Repository → Service; nothing the background isolate touches depends on `BuildContext` or `flutter_bloc` (Phase 4 D-14).
- **D-20:** **TDD red → green → refactor:** unit tests for parsing/mapping, filters, the coordinator state machine (register on auth, re-register on refresh, no retry on FE-bug codes), `AuthCubit.logout()` ordering and timeout, permission-gate idempotency and the "never called by Phase 5 surfaces" guard, dedup window, intent buffering/consumption, per-type tap actions; widget tests for banner and the Settings hint row; `bloc_test` for the cubits. `flutter test` green, `flutter analyze` with no new issues; formatting only on touched files (Phase 11 D-38 / Phase 2 D-25).
- **D-21:** **Contract check and E2E:** the two documents are verified with `tool/schema_check` against `Klimmeck-Guide-BE/src/schema.gql` at `origin/develop` ≥ `0828719` (BE PR #8 merged 2026-10-18 — fetch the ref, never touch the BE working tree). Manual UAT on the Android device with the backend `sendTestPush` recipe (BE `BACKEND-NOTES.md` §6: dev bypass with `DEV_AUTH_ROLE=innkeeper`, `FIREBASE_SERVICE_ACCOUNT` set, permission granted by hand per D-11): foreground/background/killed × three types, toggles off → nothing shown, tap → Map tab / Twitch, unregister before logout (row gone in `push_devices`). It also closes the backend's `05-HUMAN-UAT.md` item for Android.
- **D-22:** Branch **`feat/05-notifications-infrastructure`** from `develop`, PR to `develop`; the BE dependency is already merged, so this PR has no lockstep wait. Planning docs travel with the code.

### Claude's Discretion
- Names and folders within `docs/rules/naming.md` (`PushRegistrationCoordinator`, `NotificationPermissionGate`, `InAppNotificationsCubit`, `PendingNotificationIntent`, `TwitchChannel` are suggestions); whether `DeviceIdentityStore` and `ActiveUserStore` are one `PushLocalStore`.
- Exact channel id/name/importance, banner animation, dedup windows, retry caps, the `uuid` version, how `PendingNotificationIntent` is provided (`RepositoryProvider` vs Cubit), where `AuthenticatedShell` mounts the banner overlay, whether the Settings hint row re-checks the OS status on app resume (`AppLifecycleEvents` exists) or only on tab open.
- Copy of the Settings hint row (Italian, game voice; theme tokens only).
- Shape of the per-type popup hook left for Phases 7/9 (registry vs sealed handler), as long as adding a popup later is a single registration.
- Test layout mirroring `lib/` (`docs/rules/testing.md`).

### Deferred Ideas (OUT OF SCOPE)
- **iOS support** (user decision 2026-10-19): `Info.plist` `UIBackgroundModes: remote-notification`, Push Notifications entitlement, APNs key in Firebase, `GoogleService-Info.plist`, iOS background-push caveats (BE §3), iOS UAT — a later phase; the ports of D-19 keep it a wiring change.
- **Context popups** for `travelEnd` (Phase 7) and `questEnd`/death (Phase 9) — registered behind the per-type hook left empty by D-15.
- **Streamer-live popup with "Guarda la live"** — superseded by the direct Twitch link (D-16); revisit only if the direct jump proves confusing.
- **Server-side notification preferences** (multi-device coherence, backend suppression) — only if a real need appears (Phase 4 deferred, BE Phase 5 §3).
- **Dedup across isolates / persisted ledger of shown notifications** — in-memory window is enough while the subscription-driven producers do not exist (D-18).
- **Notification inbox/history, badge counts, pre-permission explainer dialog** — not in NOTIF-01..08.
- **`combatResult` push type** — Phase 9 (BE catalog is exhaustive; FE drops unknown types until then, D-04).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| NOTIF-01 | Register with FCM after login and sync the token to the backend per device | Dependency probe (no version bump, `uuid ^4.5.1`), Google Services plugin 4.5.0 + `missingGoogleServicesStrategy = WARN` (proved), `Firebase.initializeApp()` failure mode (async `PlatformException`), validated `RegisterPushDevice`/`UnregisterPushDevice` documents, `PushRegistrationCoordinator` state machine (register once per user per process, re-register on `onTokenRefresh`, suspend during logout), `PushDeviceFailure` mapping, `AuthCubit.logout()` unregister-then-logout with a 2 s timeout (Patterns 2, 4, 5; Pitfalls 1, 4, 5, 6, 7) |
| NOTIF-02 | Permission requested in context at the first travel confirmation, never at cold launch | `NotificationPermissionGate` + **Conflict C1** (FCM on Android never reports `notDetermined`; classification via `permission_handler` status + `shouldShowRequestRationale`), channel creation does not prompt on target 36, architectural test that `ensureRequested(` has no call site in `lib/` (Pattern 7, Pitfall 2) |
| NOTIF-03 | Travel-end push in killed, background, foreground | Data-only delivery path proved from plugin source: background + killed → background isolate (`isApplicationForeground` false), foreground → `onMessage`; pure `handleDataMessage`; channel `klimmeck_events` high importance; stable notification id (Patterns 3, 6; Pitfalls 3, 8, 9, 10) |
| NOTIF-04 | Streamer-live push | Same path; id-less event keyed by `sentAt` minute; topic subscription is server-side only (D-04) (Patterns 3, 6) |
| NOTIF-05 | Quest-end push | Same path; `id` = `pendingQuestId` (BE §2) (Patterns 3, 6) |
| NOTIF-06 (amended) | Tap → Map tab for personal types, Twitch for `streamerLive`, uniform across states | Tap sources: `onDidReceiveNotificationResponse` (alive) + `getNotificationAppLaunchDetails()` (killed); FCM `getInitialMessage`/`onMessageOpenedApp` never fire for FE-built notifications (source-proved, Conflict C3); `NotificationTapRouter` single action path; `NotificationIntentCubit` above `AuthGate` with clear-on-session-end only; `MainScreen` consumption with `hasClients` guard; `launchUrl(..., mode: LaunchMode.externalApplication)` without `canLaunchUrl` (no `<queries>` needed) (Pattern 8; Pitfalls 11, 12, 13) |
| NOTIF-07 | Foreground → in-app banner on `KGNotification` with tap-to-navigate | `InAppNotificationsCubit` (queue, 5 s timer, dedup) in `AuthenticatedShell`, `KgNotificationBanner` mounted with a `Stack` over the shell body (no `Scaffold`/`SnackBar`), tap delegated to the router (Pattern 9; Pitfall 14) |
| NOTIF-08 | One surface per event | Foreground never calls `show()` (D-13); dedup window in the cubit (D-18); same `(type,id)` → same Android notification id so a duplicate FCM delivery in background replaces instead of stacking (Pattern 6, 9) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Treated with the same authority as locked decisions.

- **Principles always applied:** Clean Code (no dead code, early return, small single-purpose functions), SoC (UI does no networking; Cubit builds no widgets; repositories/services know no `BuildContext`; models Flutter-free), **TDD red → green → refactor with the test written first**, Boy Scout Rule (touched files cleaned in the same commit; massive refactors out of scope).
- **Inviolable rules:** (1) no app UI chrome outside utility screens — the banner is a gameplay surface, so no `SnackBar`/`MaterialBanner`/`AppBar` (D-17); (2) **no blocking loading in an active session** — registration, retries, token refresh, unregister are invisible; (3) branch `feat/05-notifications-infrastructure` + PR to `develop`, never push to `develop`/`main`; (4) **backend is the source of truth** — the payload carries no state, the FE re-queries; (5) **no secret in repo** — `google-services.json` stays ignored (already in `.gitignore` lines "Firebase config files", commit `8893510`), never print its keys, never log FCM tokens.
- **Commands:** `flutter pub get` (needed once: removal of `firebase_auth`, addition of `uuid`), `flutter analyze` (no new issues), `flutter test`, `dart format` **only on single touched files** (`dart format --output=none --set-exit-if-changed <file>`; never a directory — rewrites ~77 files).
- **Rule files read:** `architecture.md`, `naming.md`, `state-management.md`, `graphql.md`, `ui-ux.md`, `testing.md`, `workflow.md`, `assets.md`. Relevant points folded into the patterns: documents only in `lib/graphql/`, error mapping by `extensions.code` only, `StreamSubscription` cancelled in `close()`, cubit suffix + Equatable states, theme tokens only, `Kg` prefix for design-system widgets, mocks only in `test/helpers/mocks.dart`, no `await Future.delayed` in tests.
- **Project memory:** commit scope `phase-5` (not `05`); **no `Co-Authored-By` trailer**; PRs with `GH_TOKEN=$(gh auth token --user LucaTabbia)`; keep a `.planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md` handoff (UAT result for BE `05-HUMAN-UAT.md`, Phase 7 call-site note for `ensureRequested()`); the BE working tree is on another branch (`feat/06-eventsub-punti-canale-streamer-live`) — always read the schema with `git show origin/develop:src/schema.gql`.

## Summary

The phase is mostly wiring and state, but four findings change the plan. **First, the "build without `google-services.json`" requirement is solvable without any conditional Gradle logic:** the Google Services plugin 4.4.x/4.5.0 has an official extension property `googleServices { missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN }` (enum `IGNORE`/`WARN`/`ERROR`, read from the plugin jar). Proved this session: with the file present the build generates `google_app_id`/`gcm_defaultSenderId`/`project_id` resources; with the file absent and the default strategy the build **fails** (`File google-services.json is missing. The Google Services Plugin cannot function without it.`); with `WARN` it **succeeds**, prints the same text as a warning, and the APK contains no `google_app_id`. At runtime `Firebase.initializeApp()` then fails **asynchronously** with a `PlatformException` ("Failed to load FirebaseOptions from resource…") — it does not hang and does not throw synchronously — which is exactly what the D-02 guard catches.

**Second, desugaring and SDK levels are already in place:** `android/app/build.gradle.kts:16,44` already enables `isCoreLibraryDesugaringEnabled` with `desugar_jdk_libs:2.1.4` (the exact version the `flutter_local_notifications` 19.3.0 README asks for), Flutter 3.35.5 sets `compileSdk = 36`, `targetSdk = 36`, `minSdk = 24` (plugin needs compile ≥ 35). `POST_NOTIFICATIONS` is already merged into the final manifest by both `firebase_messaging` and `flutter_local_notifications`; adding it explicitly (D-03) is harmless. **No version bump is needed:** removing `firebase_auth` and adding `uuid: ^4.5.1` changes only the lock (3 `firebase_auth*` packages removed, `uuid` transitive → direct) and nothing under `android/` or `ios/`; resolved versions stay `firebase_core 3.15.1`, `firebase_messaging 15.2.9`, `flutter_local_notifications 19.3.0`, `permission_handler 12.0.1`, `url_launcher 6.3.2`, `shared_preferences 2.5.3`, `uuid 4.5.1`. The notification small icon cannot be the launcher icon: `mipmap/launcher_icon.png` is 100 % opaque and would render as a white square; a dedicated white-on-transparent `drawable/ic_stat_klimmeck` plus `res/raw/keep.xml` (release builds shrink resources) are Wave 0 work.

**Third, D-10 cannot be implemented on Android with `firebase_messaging` alone:** its Android `getNotificationSettings()`/`requestPermission()` only ever return `authorized` (1) or `denied` (0) — never `notDetermined` — so a fresh Android 13+ install reads `denied` before any prompt (the hint row would nag immediately and `ensureRequested()` would never prompt). `permission_handler` can tell "never asked" from "denied" (`denied` + `shouldShowRequestRationale == false` vs `true`, plus `permanentlyDenied`). This is recorded as **Conflict C1** with a recommended remedy. **Fourth, FCM's `getInitialMessage()`/`onMessageOpenedApp` never fire for this app** (they key on `google.message_id` in the launch intent, which only FCM-built notifications carry): taps come exclusively from `flutter_local_notifications`.

**Primary recommendation:** Wave 0 = Gradle (`com.google.gms.google-services` 4.5.0 + `WARN` strategy), manifest, small icon + keep.xml, pubspec (`-firebase_auth`, `+uuid ^4.5.1`), delete the legacy util, extend the test fakes; then build bottom-up and test-first: models → documents + repository → stores → ports + pure handler → coordinator + `AuthCubit.logout()` → gate (permission_handler-backed) → intent cubit + router + `MainScreen` consumption → banner cubit + widget → Settings hint row → composition root → schema check + device UAT.

## Standard Stack

### Core
| Library | Version (locked, verified) | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `firebase_core` | `^3.15.1` → **3.15.1** | `Firebase.initializeApp()` behind the D-02 guard | Already declared; FlutterFire is the official Flutter FCM client [VERIFIED: pubspec.lock after probe] |
| `firebase_messaging` | `^15.2.9` → **15.2.9** (platform_interface 4.6.9) | token, `onTokenRefresh`, `onMessage`, `onBackgroundMessage` | Already declared; data-only handling in 3 states [VERIFIED: probe; CITED: plugin source in pub cache] |
| `flutter_local_notifications` | `^19.3.0` → **19.3.0** (platform_interface 9.1.0) | channel, `show()`, tap callback, launch details | Already declared; the only way to show data-only messages [VERIFIED: probe; CITED: README 19.3.0] |
| `permission_handler` | `^12.0.1` → **12.0.1** (android 13.0.1) | `openAppSettings()` (D-10) **and** (Conflict C1) notification status classification + request | Only plugin that distinguishes never-asked / denied / permanently-denied on Android [CITED: `PermissionUtils.java:420-545`] |
| `url_launcher` | `^6.1.7` → **6.3.2** | `launchUrl(TwitchChannel.url, mode: LaunchMode.externalApplication)` | Already declared [VERIFIED: pubspec.lock] |
| `shared_preferences` | `^2.0.12` → **2.5.3** | `SharedPreferencesAsync` for `DeviceIdentityStore`, `ActiveUserStore` (and Phase 4 store) | No per-isolate cache: "should always provide the latest data stored on the native platform regardless of what process was used to store it" [CITED: shared_preferences 2.5.3 README] |
| `uuid` | **add `^4.5.1`** → 4.5.1 (already transitive via `graphql` `^4.0.0` and `flutter_cache_manager` `^4.4.2`) | `const Uuid().v4()` for `deviceId` | The only new dependency (D-05); `^4.5.1` leaves the lock untouched except the dependency kind [VERIFIED: probe; 4.6.0 exists but would bump the lock for no gain] |

### Native (Android)
| Item | Version / value | Status |
|------|-----------------|--------|
| `com.google.gms.google-services` Gradle plugin | **4.5.0** (latest on Google Maven, `maven-metadata.xml`; 4.4.4 also works, FlutterFire CLI default is 4.3.15) | **Add** in `android/settings.gradle.kts` (`apply false`) and `android/app/build.gradle.kts`; proved with AGP 8.9.1, Gradle 8.12, Kotlin 2.1.0 [VERIFIED: scratch builds] |
| `missingGoogleServicesStrategy` | `WARN` | **Add** — makes the build pass without the JSON [VERIFIED: plugin jar `GoogleServicesPlugin$MissingGoogleServicesStrategy {IGNORE, WARN, ERROR}` + scratch builds] |
| Core library desugaring | `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4` | **Already present** (`android/app/build.gradle.kts:16,44`) |
| compileSdk / targetSdk / minSdk | 36 / 36 / 24 (`flutter.*` defaults of 3.35.5, `FlutterExtension.kt:23,26,34`) | OK (fln needs compile ≥ 35) [VERIFIED: merged manifest `minSdkVersion=24`, `targetSdkVersion=36`] |
| `POST_NOTIFICATIONS` | already merged from both plugins' manifests | Add explicitly per D-03 (harmless, documents intent) |
| Small icon | new `res/drawable/ic_stat_klimmeck.xml` (white vector) + `res/raw/keep.xml` | **Add** (launcher icon is opaque) |

### Supporting (tests)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bloc_test` | 10.0.0 | `NotificationIntentCubit`, `InAppNotificationsCubit`, `NotificationPermissionCubit`, `AuthCubit.logout` | every cubit |
| `mocktail` | 1.0.5 | `MockPushDeviceRepository`, `MockKlimmeckGraphQl`, mock cubits | repository/widget tests |
| `fake_async` | 1.3.3 | 2 s unregister timeout, 5 s banner auto-dismiss, backoff retries, dedup window | timer-driven tests |
| `gql` (`parseString`) | locked | document unit tests | `push_mutations` test |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `missingGoogleServicesStrategy = WARN` | apply the plugin only `if (file("google-services.json").exists())` in Kotlin DSL | Works too, but needs the legacy `apply(plugin = ...)` form with a buildscript classpath or `plugins { id(...) apply false }` + conditional `apply`; more code, same result. The plugin's own switch is official and declarative. **Recommended: WARN.** |
| `WARN` | `IGNORE` | `IGNORE` hides the cause in CI/dev logs; `WARN` prints the plugin's own message once per build. |
| Google Services plugin | `flutterfire configure` → `firebase_options.dart` + `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` | Generates a Dart file with the API key that must then be kept out of VCS too, and would make the build always "configured"; D-02 chose the JSON file. Not recommended. |
| Bump to `firebase_core` 4.x/5.x + `firebase_messaging` 16.x/17.x | — | Major lines (Firebase Android BoM jumps, new minimums); 17.0.0 is 4 days old. Nothing in this phase needs them. Re-evaluate with the iOS phase. |
| `flutter_local_notifications` 20.x | — | 21+/22+ need Dart 3.10 / Flutter 3.38 (incompatible with the baseline); 20.x adds risk without need. Stay on 19.3.0. |
| `getNotificationSettings()` of FCM for the gate | `permission_handler` `Permission.notification` | FCM on Android cannot report `notDetermined` (Conflict C1). |
| FCM `requestPermission()` for the prompt | `Permission.notification.request()` | Same system dialog on Android 13+; using permission_handler for both status and request keeps its "denied before" bookkeeping consistent. Either is acceptable; recommend permission_handler (one plugin, one port). |
| `String.hashCode` for the notification id | explicit FNV-1a 31-bit hash | `hashCode` is not specified to be stable across isolates/VM builds; the id must match across the background isolate and future runs (replacement semantics). |

**Installation (exact pubspec diff, proved):**
```yaml
  #Firebase
  firebase_messaging: ^15.2.9
-  firebase_auth: ^5.6.2
  firebase_core: ^3.15.1
...
  shared_preferences: ^2.0.12
+  uuid: ^4.5.1
```
then `flutter pub get`. Expected lock diff: −3 packages (`firebase_auth 5.6.2`, `firebase_auth_platform_interface 7.7.2`, `firebase_auth_web 5.15.2`), `uuid` `dependency: transitive` → `"direct main"`. No file under `android/` or `ios/` changes (`ios/Podfile.lock` does not exist/untracked; generated plugin registrants are ignored) [VERIFIED: probe `git diff --stat` = `pubspec.lock | 26 +-, pubspec.yaml | 2 +-`].

**Version verification:** pub.dev API queried 2026-10-19: latest `firebase_core` 5.0.0 / `firebase_messaging` 17.0.0 (2026-10-15), `flutter_local_notifications` 22.3.2 (needs Flutter ≥ 3.38.1), `permission_handler` 13.0.2, `url_launcher` 6.3.3 (needs Dart ≥ 3.11), `uuid` 4.6.0. All locked versions above resolve on Flutter 3.35.5 / Dart 3.9.2 [VERIFIED: `flutter --version`, probe].

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── config/
│   ├── twitch_channel.dart                 # TwitchChannel.url = 'https://www.twitch.tv/lordreavor' (D-16)
│   └── push_channel.dart                   # channel id 'klimmeck_events', name, description, small icon name (constants only)
├── graphql/mutations/push_mutations.dart   # RegisterPushDevice, UnregisterPushDevice (validated)
├── models/
│   ├── notification.dart                   # KGNotification: const + Equatable (Boy Scout, D-17)
│   ├── notification_category.dart          # + explicit wireType ('travelEnd'...) + fromWireType()
│   ├── push_event.dart                     # PushEvent {category, id?, title, body, sentAt} + tryParse(Map)
│   └── notification_intent.dart            # NotificationIntent {category, id?, sentAt} + toPayload()/tryFromPayload()
├── repository/
│   ├── push_device_repository.dart         # register/unregister, maps codes → PushDeviceException
│   ├── push_device_failure.dart            # PushDeviceFailure {invalidDeviceId, invalidToken, unauthenticated, connection, unknown} + isRetryable
│   ├── services/graphql/graphql.dart       # + registerPushDevice(...), unregisterPushDevice(deviceId)
│   ├── storage/
│   │   ├── device_identity_store.dart      # klimmeck.push.deviceId (SharedPreferencesAsync, uuid v4, never rotated)
│   │   └── active_user_store.dart          # klimmeck.push.activeUserId (write on auth, clear on session end)
│   └── services/push/
│       ├── push_messaging_port.dart        # abstract: token(), tokenRefreshes, foregroundMessages (Map<String,String>)
│       ├── firebase_push_messaging.dart    # adapter (only file importing firebase_messaging besides the bg handler)
│       ├── noop_push_messaging.dart        # push disabled (D-02)
│       ├── local_notifications_port.dart   # abstract: initialize(), show(...), taps, launchTap(), cancelAll()
│       ├── flutter_local_notifications_adapter.dart
│       ├── notification_permission_port.dart  # abstract: status() → NotificationPermissionStatus, request(), openSettings()
│       ├── permission_handler_notification_permission.dart
│       ├── link_opener.dart + url_launcher_link_opener.dart
│       ├── data_message_handler.dart       # pure handleDataMessage(...) (D-12)
│       ├── push_background_handler.dart    # top-level @pragma('vm:entry-point') entry (bg isolate)
│       ├── push_registration_coordinator.dart
│       ├── notification_permission_gate.dart  # ensureRequested() (Phase 7 caller only)
│       ├── notification_tap_router.dart    # one action path: personal → intent sink, streamerLive → LinkOpener
│       ├── foreground_push_events.dart     # onMessage → parse → active-user toggle filter → Stream<PushEvent>
│       └── push_bootstrap.dart             # guarded Firebase init + adapters → PushServices (enabled/disabled)
├── utils/stable_notification_id.dart       # FNV-1a 31-bit of "type|id" (or "type|sentAt-minute")
├── screens/auth/
│   ├── notificationIntentCubit/            # NotificationIntentCubit (above AuthGate; D-15 holder)
│   ├── inAppNotificationsCubit/            # InAppNotificationsCubit (provided in AuthenticatedShell)
│   └── authenticated_shell.dart            # + cubit + Stack(banner)
├── screens/mainScreen/
│   ├── main_screen.dart                    # BlocListener<NotificationIntentCubit> → jumpToPage(0) + popup hook
│   ├── components/notification_popup_registry.dart  # empty per-type hook for Phases 7/9
│   └── tabs/settings/
│       ├── permissionCubit/notification_permission_cubit.dart (+ state)
│       └── components/notification_permission_hint.dart   # "Le notifiche di sistema sono disattivate" + "Attiva"
├── shared/components/kg_notification_banner.dart
└── main.dart                               # composition root (see Pattern 10)
android/app/src/main/res/drawable/ic_stat_klimmeck.xml, android/app/src/main/res/raw/keep.xml
```
Deleted: `lib/utils/notification.dart` (no importer anywhere: `grep -rn "NotificationsBloc|utils/notification.dart" lib test tool` → only the file itself) [VERIFIED].

### Pattern 1: Android native wiring (Wave 0, proved by scratch build)
**What:** plugin + strategy + permission + icon. **When:** first plan, before any Dart code that calls Firebase.
```kotlin
// android/settings.gradle.kts — plugins { ... }
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.5.0" apply false

// android/app/build.gradle.kts
import com.google.gms.googleservices.GoogleServicesPlugin.MissingGoogleServicesStrategy

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}
...
// D-02: the JSON is local-only; without it the build passes and push stays disabled at runtime.
googleServices {
    missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN
}
```
```xml
<!-- AndroidManifest.xml, next to INTERNET -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
```
```xml
<!-- android/app/src/main/res/raw/keep.xml: release builds shrink resources (FlutterPlugin.kt:268-273) -->
<?xml version="1.0" encoding="utf-8"?>
<resources xmlns:tools="http://schemas.android.com/tools"
    tools:keep="@drawable/ic_stat_klimmeck" />
```
Proof recorded this session (then reverted): (A) JSON present → `✓ Built build/app/outputs/flutter-apk/app-debug.apk` in 89 s, generated `values.xml` with `gcm_defaultSenderId, google_api_key, google_app_id, google_crash_reporting_api_key, google_storage_bucket, project_id`; (B) JSON absent, default strategy → `> Task :app:processDebugGoogleServices FAILED … File google-services.json is missing.`; (C) JSON absent + `WARN` → warning text, `BUILD SUCCESSFUL`, APK `resources.arsc` contains no `google_app_id`. The local JSON's `project_id` is `klimmeck-guide-app` and its client `package_name` is `it.lordreavor.klimmeckguide.klimmeck_guide` (matches `applicationId`) — compare with the BE boot log `Push notifications enabled for Firebase project <project_id>` in the UAT.

### Pattern 2: guarded bootstrap in `main()` (D-02)
```dart
// lib/repository/services/push/push_bootstrap.dart
Future<PushServices> bootstrapPush() async {
  if (!Platform.isAndroid) return PushServices.disabled(); // iOS deferred (D-03)
  try {
    await Firebase.initializeApp().timeout(const Duration(seconds: 3));
  } on Object catch (error) {   // PlatformException when the JSON is missing; TimeoutException belt-and-braces
    debugPrint('Push disabled: Firebase unavailable (${error.runtimeType})');
    return PushServices.disabled();
  }
  FirebaseMessaging.onBackgroundMessage(firebaseBackgroundMessageHandler);
  final local = FlutterLocalNotificationsAdapter();
  await local.initialize();                    // channel klimmeck_events + tap callback (main isolate)
  return PushServices.enabled(
    messaging: FirebasePushMessaging(FirebaseMessaging.instance),
    localNotifications: local,
    launchTap: await local.launchTap(),        // getNotificationAppLaunchDetails(), once (D-14)
  );
}
```
Failure mode (source-read): with no default app and no options, `MethodChannelFirebase.initializeApp` calls `api.optionsFromResource()` (`method_channel_firebase.dart:86`), the Android side completes the task exceptionally with `"Failed to load FirebaseOptions from resource. Check that you have defined values.xml correctly."` (`FlutterFirebaseCorePlugin.java:220-226`), pigeon rethrows it as `PlatformException(code: 'java.lang.Exception: …', message: 'Exception')` (`messages.pigeon.dart:334`). It is an **async** error on a thread-pool task: no hang, no synchronous throw. All plugin calls are local (no network): D-33 ("no network before `runApp`") holds. Never touch `FirebaseMessaging.instance` when disabled — it calls `Firebase.app()` and throws `[core/no-app]`.

### Pattern 3: background handler = thin entry + pure function (D-12)
```dart
// lib/repository/services/push/push_background_handler.dart
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized(); // shared_preferences_android & fln have dartPluginClass
  final local = FlutterLocalNotificationsAdapter();
  await local.initialize(withTapCallback: false);   // no callbacks in the bg isolate
  await handleDataMessage(
    message.data,
    activeUser: ActiveUserStore(),
    preferences: SharedPreferencesNotificationPreferencesStore(),
    notifier: local,
  );
}

// lib/repository/services/push/data_message_handler.dart  (pure, unit-tested with fakes)
Future<void> handleDataMessage(
  Map<String, dynamic> data, {
  required ActiveUserStore activeUser,
  required NotificationPreferencesStore preferences,
  required LocalNotificationsPort notifier,
}) async {
  final event = PushEvent.tryParse(data);
  if (event == null) return debugPrint('Push dropped: unknown or malformed type'); // D-04
  final userId = await activeUser.read();
  if (userId == null) return;                                                   // D-09
  if (!await preferences.isEnabled(userId, event.category)) return;              // D-14
  await notifier.show(event);  // id = stableNotificationId(event), payload = intent JSON
}
```
Facts behind it: the dispatcher already calls `WidgetsFlutterBinding.ensureInitialized()` (`method_channel_messaging.dart:26`) and swallows handler exceptions with a `print` (`:48-54`); the handler must be top-level and non-anonymous (`messaging.dart:69-72`) with `@pragma('vm:entry-point')`; work over ~30 s may get the process killed [CITED: firebase.google.com/docs/cloud-messaging/flutter/receive]. `Firebase.initializeApp()` inside the isolate is only needed to use other Firebase services; this handler uses none, so it can be omitted (see Conflict C4; if kept, wrap in try). No `dotenv`/`EnvConfig`/theme in this code path. The background isolate also serves the **background-but-alive** state: `FlutterFirebaseMessagingReceiver` routes to the background service whenever `isApplicationForeground` is false (`FlutterFirebaseMessagingReceiver.java:49-67`); `onMessage` fires only in foreground.

### Pattern 4: `PushRegistrationCoordinator` state machine (D-07, D-09)
- Inputs: `authStateStream` (replays the last state to new listeners — `AuthStateChannel.stream`, `auth_state_channel.dart:14-25`, so start order is not critical), `messaging.tokenRefreshes`, `messaging.token()`.
- On `AuthAuthenticated(user)`: if `user.id != _registeredUserId` → write `ActiveUserStore`, then `register(user.id)`; **ignore re-emissions for the same id** (`adoptUser`, `userUpdated` re-emit `AuthAuthenticated` on every character change — Pitfall 4).
- `register`: `deviceId = await deviceIdentity.readOrCreate()`, `token = await messaging.token()` (null/throws → retry), `repository.register(deviceId, token, platform: android)`; on `PushDeviceException` with `isRetryable` (connection/unknown) → `exponentialBackoff(attempt)` (1 s → 30 s cap, `lib/utils/backoff.dart`) up to **5 attempts**; `invalidDeviceId`/`invalidToken`/`unauthenticated` → `debugPrint` code only, stop.
- On `tokenRefreshes` while authenticated and not suspended → register again with the new token.
- `unregister()` (called by `AuthCubit.logout()`): set `_suspended = true` (no re-register can race between unregister and the backend logout), cancel pending retry timer, `repository.unregister(deviceId)` best-effort.
- On `AuthUnauthenticated` after an authenticated state (any reason): clear `ActiveUserStore`, `_registeredUserId = null`, cancel retries, `localNotifications.cancelAll()` (stale tray entries of the ended session, Pitfall 13), `_suspended = false`.
- `dispose()` cancels both subscriptions and the timer. Lives for the app process (created in `_KlimmeckGuideAppState`, like `notificationPreferencesStore`).

### Pattern 5: `AuthCubit.logout()` ordering + 2 s timeout (D-08)
```dart
// lib/screens/auth/cubit/auth_cubit.dart
AuthCubit(this._authTokenService, {PushSessionCleanup? pushCleanup})
    : _pushCleanup = pushCleanup ?? const NoPushSessionCleanup(), super(const AuthBootstrapping());

static const Duration pushUnregisterTimeout = Duration(seconds: 2);

Future<void> logout() async {
  await _unregisterPushDevice();
  await _authTokenService.logout();
}

Future<void> _unregisterPushDevice() async {
  try {
    await _pushCleanup.unregister().timeout(pushUnregisterTimeout);
  } on Object catch (error) {
    debugPrint('Push unregister skipped (${error.runtimeType})'); // never blocks logout
  }
}
```
`PushSessionCleanup` is a one-method interface (`Future<void> unregister()`) implemented by the coordinator, so `AuthCubit` stays free of push internals and the optional named parameter keeps every existing `AuthCubit(service)` call site (`main.dart:214`, `auth_cubit_test.dart`, `logout_confirmation_dialog_test.dart:25`) compiling. `AuthCubit` already imports nothing from Flutter except `flutter_bloc`; use `debugPrint` from `package:flutter/foundation.dart` (already the project's logging style).

### Pattern 6: payload, id and display (NOTIF-03..05, NOTIF-08)
- `PushEvent.tryParse`: require `type` ∈ wire names, non-empty `title`/`body`, parseable `sentAt` (`DateTime.tryParse`); `id` optional and only kept for personal types. Wire mapping must be **explicit** (`NotificationCategory.travelEnd` → `'travelEnd'`), not `category.name` (Phase 4 Pitfall 8 analogue).
- Android id: `stableNotificationId('${wire}|${id ?? sentAtMinuteIso}')` = FNV-1a 32 → `& 0x7fffffff`. Same event delivered twice → same id → the tray entry is replaced, not duplicated.
- `show(id, title, body, NotificationDetails(android: AndroidNotificationDetails('klimmeck_events', 'Eventi di gioco', importance: Importance.high, priority: Priority.high)), payload: intent.toPayload())` — fln 19.3.0 signature `show(int id, String? title, String? body, NotificationDetails? details, {String? payload})` (`flutter_local_notifications_plugin.dart:233`). Passing the same channel details in the background isolate means `show()` creates the channel if the main isolate never did ("Showing/scheduling a notification will create a channel with the specified id if it doesn't exist already" — README).
- Channel at startup: `resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(const AndroidNotificationChannel('klimmeck_events', 'Eventi di gioco', importance: Importance.high))` (`platform_flutter_local_notifications.dart:475`; `playSound` defaults to `true` = default sound). On target 36, creating a channel does **not** show the permission dialog ("If your app targets Android 13 or higher, your app has complete control over when the permission dialog is displayed" — developer.android.com notification-permission), so D-10 "no prompt in Phase 5" holds.
- `initialize(InitializationSettings(android: AndroidInitializationSettings('ic_stat_klimmeck')), onDidReceiveNotificationResponse: _onTap)` — positional settings in 19.3.0 (`:113-118`). Do **not** pass `onDidReceiveBackgroundNotificationResponse`: it is only for notification *actions* without UI; plain taps open the activity and reach the main isolate.

### Pattern 7: permission gate (NOTIF-02, D-10 + Conflict C1)
```dart
enum NotificationPermissionStatus { notDetermined, denied, granted }

// permission_handler adapter (Android semantics from PermissionUtils/PermissionManager):
Future<NotificationPermissionStatus> status() async {
  final status = await Permission.notification.status;
  if (status.isGranted) return NotificationPermissionStatus.granted;
  if (status.isPermanentlyDenied) return NotificationPermissionStatus.denied;
  return await Permission.notification.shouldShowRequestRationale
      ? NotificationPermissionStatus.denied          // denied once (13+), or revoked from Settings
      : NotificationPermissionStatus.notDetermined;  // never asked (13+)
}

// gate (Flutter-free, idempotent, Phase 7 is the only caller)
Future<NotificationPermissionStatus> ensureRequested() async {
  final current = await _permission.status();
  if (current != NotificationPermissionStatus.notDetermined) return current;
  return _permission.request();   // Permission.notification.request() → mapped
}
```
Android facts: `firebase_messaging` returns only `1`/`0` (`FlutterFirebaseMessagingPlugin.java:358-410`) → `authorized`/`denied`, never `notDetermined` (`-1`) (`utils.dart:77-90`). permission_handler: never asked → `denied` with rationale `false`; denied once → `denied` with rationale `true`; denied twice → `permanentlyDenied` (scenario table `PermissionUtils.java:420-445`); a change from App info → `granted` or "denied once". On Android ≤ 12 (no runtime permission) a user-disabled app reads `denied` with rationale `false` → `notDetermined`: accepted limitation (no hint row on API 24-32 when the user disabled notifications manually; `request()` there shows nothing). Hint row = `status == denied`; re-check on tab build and on `AppLifecycleEvents.foregrounded` (the user comes back from `openAppSettings()`).

### Pattern 8: taps → intent → Map / Twitch (NOTIF-06, D-15, D-16)
- Sources: `LocalNotificationsPort.taps` (main-isolate `onDidReceiveNotificationResponse`, app alive) and `launchTap` (`getNotificationAppLaunchDetails()` → `didNotificationLaunchApp` + `notificationResponse.payload`, killed). README: the response callback "**cannot** be used to handle when a notification launched an app. Use the `getNotificationAppLaunchDetails` method when the app starts".
- `NotificationTapRouter.handle(intent)`: `streamerLive` → `linkOpener.open(TwitchChannel.url)`; personal → `intentSink.offer(intent)`. Banner taps call the same `handle` (D-17 identical behaviour). The router is Flutter-free; the intent sink is `NotificationIntentCubit`.
- `NotificationIntentCubit` (state `NotificationIntentState { NotificationIntent? pending }`), provided above `AuthGate` (sibling of `AuthCubit` in `KlimmeckGuideApp`): `offer`, `consume` (returns + clears), subscribes to `AuthTokenService.authStateStream` (a service, not another cubit) and clears **only on a transition `AuthAuthenticated → AuthUnauthenticated`** (so a killed-state tap survives cold-start sign-in, D-15) and when an `AuthAuthenticated` user has `currentCharacter == null` (creation page drop).
- `MainScreen`: `BlocListener<NotificationIntentCubit, NotificationIntentState>(listenWhen: pending changed to non-null)` + an initial check in the first `MainScreenLoadData` frame; consumption = `Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst)` (sheets would hide the map; same policy as Phase 3 D-10) → `if (pageController.hasClients) pageController.jumpToPage(0)` → `notificationPopupRegistry[intent.category]?.call(context, intent)` (empty in Phase 5). `PageView` exists only in `MainScreenLoadData` (`main_screen.dart:74-84`): consume only there.
- Twitch: `launchUrl(Uri.parse(TwitchChannel.url), mode: LaunchMode.externalApplication)` directly, **no `canLaunchUrl`** (which would need `<queries>` on Android 11+; the README recommends calling `launchUrl` and handling failure). Killed-state `streamerLive` launch tap: run the router after the first frame (needs an Activity).

### Pattern 9: banner (NOTIF-07, D-17, D-18)
- `InAppNotificationsCubit(ForegroundPushEvents feed, {Duration display = 5 s, DateTime Function() now})`: subscribes to the feed (already parsed + toggle-filtered for the active user), `publish(PushEvent)` = single path; dedup key `(category, id)` or `(category, sentAt minute)`; window 2 min (personal) / 15 min (`streamerLive`, = BE TTL); queue; `Timer` for auto-dismiss; `dismiss()` on tap; everything cancelled in `close()`. State: `InAppNotificationsState { KGNotification? current; PushEvent? currentEvent; }` (queue internal).
- `AuthenticatedShell`: wrap `_ShellBody` in `Stack(children: [body, Positioned(top: 0, left: 0, right: 0, child: SafeArea(bottom: false, child: BlocBuilder<…>(… KgNotificationBanner(...))))])`; the banner is a `Material(type: MaterialType.transparency)` strip with parchment background/ink text from `KlimmeckGuideTheme` tokens (`parchment`, `darkWood`, `darkBronze`), `AnimatedSwitcher`/`AnimatedSlide` for enter/exit, `Semantics(button: true)`, height ≥ 44 px. Root-navigator dialogs render above it (accepted: the banner is informative and auto-dismisses).
- Foreground while not in the shell (sign-in, creation): events are dropped (no cubit, D-13 forbids a system notification) — documented behaviour.

### Pattern 10: composition root (`main.dart`)
Before `runApp`: `dotenv.load` (as today) → `final push = await bootstrapPush();` (Pattern 2). In `KlimmeckGuideApp` (new required param `push`): `_KlimmeckGuideAppState` builds `PushDeviceRepository(graphQl)`, `DeviceIdentityStore()`, `ActiveUserStore()`, `PushRegistrationCoordinator(...)..start()` in `initState` (disabled → coordinator still clears `ActiveUserStore` but never registers — or a no-op coordinator), disposes it in `dispose`. Providers: `RepositoryProvider<NotificationPermissionGate>` (for Phase 7), `BlocProvider<NotificationIntentCubit>(lazy: false)` above `AuthGate`, `AuthCubit(widget.authTokenService, pushCleanup: coordinator)`, the router wired to the local-notification taps + `push.launchTap` after the first frame. `AuthenticatedShell` gains `InAppNotificationsCubit(ForegroundPushEvents(messaging, activeUser/userId, preferences))`. `NotificationPermissionCubit` (Settings) joins the shell providers next to `NotificationPreferencesCubit`.

### Anti-Patterns to Avoid
- **Calling `ensureRequested()` from anything in this phase** (main, AuthGate, Splash, Settings, coordinator): forbidden by D-10; an architectural test enforces it.
- **Reading permission state from `FirebaseMessaging.getNotificationSettings()` on Android** for UX decisions: it cannot express `notDetermined` (C1).
- **Opening any URL taken from the payload**: only the `TwitchChannel.url` constant is ever launched.
- **Showing a system notification from `onMessage`** (D-13) or a banner from the background isolate (impossible anyway).
- **Re-registering on every `AuthAuthenticated` emission** (character create/delete, `userUpdated`): one registration per user id per process, plus token refreshes.
- **Importing `firebase_messaging` / `flutter_local_notifications` / `url_launcher` / `permission_handler` outside the adapters, the background entry and `push_bootstrap.dart`** — tests would then need platform channels.
- **Logging the FCM token, the payload body or the user id** (graphql.md privacy rule).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Build without the Firebase JSON | conditional Gradle `apply` logic, copying a dummy JSON | `googleServices { missingGoogleServicesStrategy = WARN }` | Official switch in the plugin (4.4.x+), proved here |
| Never-asked vs denied on Android | own "already prompted" flag in shared_preferences | `permission_handler` status + `shouldShowRequestRationale` | OS truth (rationale) + plugin bookkeeping; D-10 forbids persisting our own state |
| UUID v4 | `Random`-based string | `const Uuid().v4()` | RFC 4122, already in the graph |
| Retry timing | ad-hoc doubling | `exponentialBackoff()` (`lib/utils/backoff.dart`) | Project standard, tested |
| Notification display / channels / launch details | platform channel code | `flutter_local_notifications` | Handles channel, PendingIntent, launch intent parsing |
| Cross-isolate preference reads | `SharedPreferences` + `reload()` | `SharedPreferencesAsync` | No cache by design (README) |
| Error-code extraction | parsing `message` text | `graphQlErrorCode()` (`graphql_error_code.dart`) | Project standard; messages are never used |
| Document validation | manual review | `tool/schema_check` (`dump_documents.dart` + `validate_documents.js`) | Validates against the real BE schema |

**Key insight:** every platform-specific edge in this phase (missing config, permission tri-state, launch-vs-resume taps, isolate caches) already has an owner in a plugin; the project code only needs thin adapters plus pure, testable decision functions.

## Runtime State Inventory

Not a rename/refactor phase; the one removal (`firebase_auth`, legacy util) was checked: **stored data** — none (firebase_auth was never initialised; no Firebase Auth user exists); **live service config** — none in the app repo (the Firebase project and the BE `FIREBASE_SERVICE_ACCOUNT` are user prerequisites, unchanged); **OS-registered state** — none (no FirebaseAuth native components were ever initialised; the merged manifest after removal is regenerated at build); **secrets/env vars** — none renamed; **build artifacts** — `pubspec.lock` changes as listed; `build/` may hold Google-Services resources from a build made *with* the JSON — run `flutter clean` (or delete `build/app/generated/res/processDebugGoogleServices`) before verifying the "file missing" path (Pitfall 15).

## Common Pitfalls

### Pitfall 1: the build breaks on every checkout without the JSON
**What goes wrong:** applying `com.google.gms.google-services` makes `processDebugGoogleServices` fail when `android/app/google-services.json` is absent (proved). **Avoid:** `missingGoogleServicesStrategy = MissingGoogleServicesStrategy.WARN` + the Kotlin import at the top of `app/build.gradle.kts`. **Warning sign:** `File google-services.json is missing` as a FAILURE instead of a warning.

### Pitfall 2: the permission gate never prompts, or the hint row nags on first install (Conflict C1)
**What goes wrong:** using FCM settings on Android → status is `denied` from day one. **Avoid:** permission_handler-based classification (Pattern 7); widget test with the fake port in each of the three states; manual UAT step resets the permission with `adb shell pm revoke … POST_NOTIFICATIONS` + `adb shell pm clear-permission-flags … POST_NOTIFICATIONS user-set user-fixed` to see "never asked" again.

### Pitfall 3: notification shows as a white square, or disappears in release
**What goes wrong:** `@mipmap/launcher_icon` is fully opaque (0 % transparent pixels, measured) → status-bar silhouette is a square; release `shrinkResources` drops an icon referenced only by name → "notifications might be broken … silently failing" (fln README). **Avoid:** white-on-transparent `drawable/ic_stat_klimmeck` + `res/raw/keep.xml`. **Warning sign:** a release build shows nothing while debug works.

### Pitfall 4: registration storm
**What goes wrong:** `AuthAuthenticated` is re-emitted by `adoptUser` and every `userUpdated` (Phase 3 D-07), each triggering a `registerPushDevice`. **Avoid:** register once per `user.id` per process + on token refresh; unit test "three `AuthAuthenticated` for the same user → one register".

### Pitfall 5: logout re-registers the device it just unregistered
**What goes wrong:** a token refresh or a pending retry fires between `unregister()` and the backend `logout`. **Avoid:** `_suspended` flag + cancel retry timer inside `unregister()`; reset on the following `AuthUnauthenticated`.

### Pitfall 6: unregister blocks or breaks logout
**What goes wrong:** offline → mutation hangs; exception propagates. **Avoid:** `.timeout(2 s)` + catch-all + log only (Pattern 5); `fake_async` test proves `service.logout()` is called after exactly 2 s when the unregister never completes, and immediately when it throws.

### Pitfall 7: `getToken()` throws or returns null offline / without Play services
**What goes wrong:** `SERVICE_NOT_AVAILABLE` IOException at cold start. **Avoid:** treat as transient in the coordinator (same backoff); a later `onTokenRefresh` also triggers registration.

### Pitfall 8: killed-state messages never arrive on the Samsung
**What goes wrong:** One UI "Sleeping/Deep sleeping apps" and battery restrictions; **Force stop** from Settings stops delivery until the user reopens the app ("if the user force-quits the app from device settings, it must be manually reopened" — FlutterFire docs); the app must have been opened once. **Avoid in UAT:** "killed" = swipe away from Recents, never Force stop; set battery to Unrestricted for the app; record the outcome honestly.

### Pitfall 9: high-priority messages get deprioritised
**What goes wrong:** FCM downgrades high-priority messages that produce no visible notification (7-day window, per app instance); disabled permission or toggles cause it [CITED: firebase message-priority docs; BE §3]. **Avoid:** nothing to code; note it in the handoff; UAT with permission granted and toggles on except the explicit "toggle off" checks.

### Pitfall 10: background isolate cannot reach plugins or env
**What goes wrong:** `MissingPluginException` for Dart-implemented plugin classes, or `dotenv`/`EnvConfig` not loaded. **Avoid:** `DartPluginRegistrant.ensureInitialized()` first line of the handler; handler code imports only stores, models and the fln adapter.

### Pitfall 11: relying on FCM "opened" callbacks
**What goes wrong:** `getInitialMessage()`/`onMessageOpenedApp` look for `google.message_id` in the launch intent (`FlutterFirebaseMessagingPlugin.java:302-308, 547-551`), present only on FCM-built notifications; for this app they always yield nothing. **Avoid:** treat fln as the tap source (Conflict C3).

### Pitfall 12: the intent is lost at cold start or leaks into the next session
**What goes wrong:** clearing on the first `AuthUnauthenticated` (cold start needing sign-in) loses a killed-state tap; never clearing lets a tap from user A route user B. **Avoid:** clear only on `Authenticated → Unauthenticated` and on creation-page landing; `bloc_test` for both.

### Pitfall 13: stale tray entries after logout
**What goes wrong:** notifications of the previous session remain tappable. **Avoid:** `cancelAll()` when the session ends (coordinator) — tap of an old entry after login only reaches the Map tab anyway.

### Pitfall 14: `jumpToPage` before the `PageView` exists
**What goes wrong:** `PageController` without clients asserts. **Avoid:** consume only in `MainScreenLoadData` frames with `pageController.hasClients`; cold start already lands on index 0 (`initialPage: 0`).

### Pitfall 15: verifying the "missing JSON" path on a stale build directory
**What goes wrong:** after a build with the JSON, `build/app/generated/res/processDebugGoogleServices/values/values.xml` survived a later build without it (observed in build B before deleting the folder), so Firebase would still initialise. **Avoid:** `flutter clean` before that check.

### Pitfall 16: schema-check test goes red
**What goes wrong:** `test/tool/schema_check_documents_test.dart` fails as soon as `RegisterPushDevice`/`UnregisterPushDevice` exist in `lib/graphql/mutations/` but not in `tool/schema_check/schema_check_documents.dart`. **Avoid:** add both entries in the same commit as the documents.

## Code Examples

### Documents (validated against BE `origin/develop` `0828719`)
```dart
// lib/graphql/mutations/push_mutations.dart
class PushMutations {
  /// Registra o aggiorna il device del chiamante (identità dal bearer, BE Phase 5 D-02).
  static const String registerPushDevice = r'''
    mutation RegisterPushDevice($input: RegisterPushDeviceInput!) {
      registerPushDevice(input: $input)
    }
  ''';

  /// Idempotente: true anche se il device non era registrato (BE D-03).
  static const String unregisterPushDevice = r'''
    mutation UnregisterPushDevice($deviceId: String!) {
      unregisterPushDevice(deviceId: $deviceId)
    }
  ''';
}
// variables: {'input': {'deviceId': uuid, 'token': fcmToken, 'platform': 'android'}} / {'deviceId': uuid}
// tool/schema_check/schema_check_documents.dart: + 'RegisterPushDevice': PushMutations.registerPushDevice,
//                                                + 'UnregisterPushDevice': PushMutations.unregisterPushDevice,
```
SDL (BE `src/schema.gql` lines 296-299, 381-390, 476-480): `registerPushDevice(input: RegisterPushDeviceInput!): Boolean!`, `unregisterPushDevice(deviceId: String!): Boolean!`, `input RegisterPushDeviceInput { deviceId: String! platform: PushPlatform! token: String! }`, `enum PushPlatform { android ios }`, `enum PushEventType { questEnd streamerLive travelEnd }`. Codes: `PUSH_INVALID_DEVICE_ID`, `PUSH_INVALID_TOKEN` (register only), `UNAUTHENTICATED` (`unauthenticatedCode`, `auth_api_exception.dart:7`); `PUSH_DISABLED`/`FORBIDDEN`/`NOT_FOUND` belong to `sendTestPush` only. Validation run this session: `OK RegisterPushDevice.graphql`, `OK UnregisterPushDevice.graphql`, `OK SendTestPush_scratch.graphql`, and a negative control with a selection on `Boolean!` correctly `FAIL`ed.

### Repository failure mapping (pattern `character_deletion_failure.dart`)
```dart
const String pushInvalidDeviceIdCode = 'PUSH_INVALID_DEVICE_ID';
const String pushInvalidTokenCode = 'PUSH_INVALID_TOKEN';

enum PushDeviceFailure {
  invalidDeviceId, invalidToken, unauthenticated, connection, unknown;
  bool get isRetryable => this == connection || this == unknown;
}

PushDeviceFailure pushDeviceFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) return PushDeviceFailure.connection;
  return switch (code) {
    pushInvalidDeviceIdCode => PushDeviceFailure.invalidDeviceId,
    pushInvalidTokenCode => PushDeviceFailure.invalidToken,
    unauthenticatedCode => PushDeviceFailure.unauthenticated,
    _ => PushDeviceFailure.unknown,
  };
}
```

### Test fakes (no plugin import in `test/`)
```dart
// test/helpers/fakes/fake_push_messaging_port.dart
class FakePushMessagingPort implements PushMessagingPort {
  String? currentToken = 'token-1';
  Object? tokenFailure;
  final StreamController<String> refreshes = StreamController<String>.broadcast();
  final StreamController<Map<String, String>> foreground = StreamController.broadcast();
  @override
  Future<String?> token() async {
    final failure = tokenFailure;
    if (failure != null) throw failure;
    return currentToken;
  }
  @override
  Stream<String> get tokenRefreshes => refreshes.stream;
  @override
  Stream<Map<String, String>> get foregroundMessages => foreground.stream;
}
// Same style: RecordingLocalNotificationsPort (records show()/cancelAll(), exposes a taps controller),
// RecordingLinkOpener, FakeNotificationPermissionPort (scripted status/request results).
// Extend FakeSharedPreferencesAsync with getString/setString/remove for the two new stores.
```

### `AuthCubit.logout()` timeout test (fake_async)
```dart
test('logout waits at most 2 s for the push unregister', () {
  fakeAsync((async) {
    final cleanup = NeverCompletingPushCleanup();
    final cubit = AuthCubit(service, pushCleanup: cleanup);
    cubit.logout();
    async.elapse(const Duration(milliseconds: 1999));
    verifyNever(() => service.logout());
    async.elapse(const Duration(milliseconds: 1));
    verify(() => service.logout()).called(1);
  });
});
```

### Architectural guard (pattern `schema_check_documents_test.dart`)
```dart
// test/repository/services/push/push_boundaries_test.dart
test('ensureRequested has no call site in lib/ (Phase 7 wires it)', () {
  final callers = Directory('lib').listSync(recursive: true).whereType<File>()
      .where((f) => f.path.endsWith('.dart') && !f.path.endsWith('notification_permission_gate.dart'))
      .where((f) => f.readAsStringSync().contains('ensureRequested('));
  expect(callers, isEmpty);
});
test('push plugins are imported only by the adapters', () { /* allow-list of files */ });
```

### Schema check (exact commands for the last plan)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
SCRATCH=$(mktemp -d)
git -C /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs"
```
Expected: 27 lines `OK …` (25 today + 2), exit 0. Use `git show origin/develop:` because the BE working tree is on `feat/06-…` (its `src/schema.gql` currently equals `origin/develop`, but that is not guaranteed).

## E2E / UAT recipe (manual-only, D-11, D-21)

Prerequisites: BE `.env` with `FIREBASE_SERVICE_ACCOUNT` (same project `klimmeck-guide-app`), `DEV_AUTH_ENABLED=true`, `DEV_AUTH_ROLE=innkeeper`; FE `.env` with `DEV_AUTH_ENABLED=true` and the same `DEV_AUTH_ACCESS_TOKEN`; local `android/app/google-services.json`.
1. BE up on :3000; check the boot log `Push notifications enabled for Firebase project klimmeck-guide-app`.
2. Phone (Samsung SM-S938B, Android 16, adb id `RZCY92B5BWW`): `~/Library/Android/sdk/platform-tools/adb reverse tcp:3000 tcp:3000`; `flutter run -d RZCY92B5BWW 2>&1 | tee <log>` (the run loses the device when the app is backgrounded; keep reading with `adb logcat -d --pid=$(adb shell pidof it.lordreavor.klimmeckguide.klimmeck_guide)`).
3. Permission: verify Settings shows **no** hint row (never asked); then grant by hand: Settings › Apps › Guida di Klimmeck › Notifications › On (or `adb shell pm grant it.lordreavor.klimmeckguide.klimmeck_guide android.permission.POST_NOTIFICATIONS`). Revoke from Settings once to see the hint row appear and "Attiva" open the app settings; grant again and confirm the row disappears on return (foreground re-check).
4. Registration: `mongosh "$MONGO_URI/$DB_NAME" --eval 'db.push_devices.find({}, {deviceId:1, platform:1, lastSeenAt:1, _id:0})'` (never print `token`): one row, `platform: "android"`, `lastSeenAt` updated on each cold start.
5. Sends (bearer = dev token): `curl -s localhost:3000/api/graphql -H 'content-type: application/json' -H "authorization: Bearer $DEV_AUTH_ACCESS_TOKEN" --data '{"query":"mutation { sendTestPush(input: { type: travelEnd, id: \"<characterId>\" }) { targeted sent pruned failed } }"}'` — repeat with `questEnd` (`id: "<pendingQuestId>"`) and `streamerLive` (no id). Expect `sent: 1`.
6. Matrix 3 states × 3 types: foreground → banner only (no tray entry), ~5 s, tap → Map / Twitch; background (Home button) → tray notification, tap → app resumes on Map / Twitch opens; killed (swipe from Recents, **not** Force stop; battery Unrestricted) → tray notification, tap → cold start → (sign-in if needed) → Map / Twitch. Send the same event twice within 2 min in foreground → one banner.
7. Toggles: turn each category off in Settings → that type shows nothing in all three states.
8. Logout from Settings (confirm) → `push_devices` row gone (step 4 query returns nothing for the `deviceId`); log in again → row back with the same `deviceId`.
9. No-JSON smoke: move the JSON out, `flutter clean`, `flutter run` → app boots, log `Push disabled: Firebase unavailable (PlatformException)`, game unchanged; restore the JSON.
10. Record results in `05-HUMAN-UAT.md` (FE) and the BE item in this phase's `BACKEND-NOTES.md` (closes BE `05-HUMAN-UAT.md` test 1 for Android; the "uninstall → `pruned: 1`" sub-item can be done at the end: uninstall, `sendTestPush` → `pruned: 1`).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Google Services plugin always fails without JSON | `missingGoogleServicesStrategy` (`IGNORE`/`WARN`/`ERROR`) | 4.4.x line (present in 4.4.4 and 4.5.0 jars) | Optional config without Gradle hacks |
| Notifications allowed by default | `POST_NOTIFICATIONS` runtime permission, off by default for new installs on Android 13+ | Android 13 (API 33) | Prompt is the app's choice (Phase 7) |
| `SharedPreferences` + `reload()` across isolates | `SharedPreferencesAsync` | shared_preferences 2.3.0 | Background isolate reads fresh values |
| fln `onSelectNotification` | `onDidReceiveNotificationResponse` + `getNotificationAppLaunchDetails()` | fln 10+ | Two tap paths: alive vs launched |

**Deprecated/outdated:** `lib/utils/notification.dart` (`rxdart` singleton, unused; `depend_on_referenced_packages` info) — delete; `firebase_auth` (never imported) — remove.

## Conflicts with CONTEXT

**C1 — D-10 (and D-01 "permission_handler only for `openAppSettings()`") vs Android reality.** D-10 builds the gate over `requestPermission()`/`getNotificationSettings()` of the messaging port and distinguishes `notDetermined` from `denied`. On Android, `firebase_messaging` 15.2.9 only returns `authorized` or `denied` (`FlutterFirebaseMessagingPlugin.java:358-410`): before any prompt the status is already `denied`, so (a) `ensureRequested()` would never prompt in Phase 7 and (b) the Settings hint row would appear on every fresh Android 13+ install — the "nagging" the user rejected. **Recommended remedy (keeps every intent of D-10):** implement `NotificationPermissionPort` over `permission_handler` (`Permission.notification.status`, `.shouldShowRequestRationale`, `.request()`, `openAppSettings()`) as in Pattern 7; nothing is persisted by the app (the plugin's own internal flag and the OS rationale are the source of truth). This widens D-01's use of `permission_handler`. Accepted limitation: on Android 7-12 a user who disabled notifications manually sees no hint row (the OS gives no way to tell without an SDK-version probe or a new dependency). Planner: adopt the remedy and record it in the PR description; the user can veto at review.

**C2 — D-03 "`POST_NOTIFICATIONS` in `AndroidManifest.xml`".** Not a conflict: both plugins already merge it (`firebase_messaging` manifest line 7, fln manifest line 3; merged manifest line 16). Adding it explicitly is redundant but harmless; keep it for readability.

**C3 — D-15 "belt and braces, FCM `onMessageOpenedApp`/`getInitialMessage`".** For data-only messages these never fire on Android (Pitfall 11). Recommended: keep them out of the port (dead code under Clean Code) and state in the port dartdoc that the FE-built notification is the only tap source; if the planner prefers to honour the wording literally, expose them in the port and feed the same router — harmless, untestable on device.

**C4 — D-12 "the isolate initialises Firebase".** Not needed for this handler (no Firebase service is used there; FlutterFire docs require `initializeApp` only "before using other Firebase services"). Recommended: omit it (one fewer failure point); if kept, wrap it in try/catch like the main guard.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Android returns an FCM token without `POST_NOTIFICATIONS` (D-07): the plugin's `getToken` has no permission check (`FlutterFirebaseMessagingPlugin.java:151`) and Firebase docs tie token generation to "initial startup", not to the permission; not exercised on the device yet | Pattern 4 | Low: if wrong, registration waits for the grant; UAT step 4 runs before the grant and will show it |
| A2 | Data-only high-priority messages wake the background isolate when the app is swiped away on One UI 8 / Android 16 (receiver + background service path read in source; OEM behaviour not testable here) | Pattern 3, Pitfall 8 | Medium: killed-state UAT may need "Unrestricted" battery; documented, no code change |
| A3 | `SharedPreferencesAsync` reads from the FCM background engine see the main engine's writes (README: "regardless of what process was used to store it"; same process, DataStore singleton) | Pattern 3 | Low-medium: UAT step 7 (toggle off, kill, send) verifies; fallback = legacy API + `reload()` |
| A4 | `DartPluginRegistrant.ensureInitialized()` is needed (or at least harmless) in the background handler for `shared_preferences_android`/fln Dart plugin classes | Pitfall 10 | Low: idempotent call |
| A5 | A simple white vector drawable is acceptable as the interim small icon (design asset not supplied yet) | Pattern 1 | Low: swap the drawable later, keep the name |
| A6 | Dedup windows 2 min / 15 min and 5 retry attempts are good defaults (discretion) | Patterns 4, 9 | Low: constants |
| A7 | Popping root routes before jumping to the Map (Pattern 8) matches the user's "land on the Map tab" intent | Pattern 8 | Low: one line; the user can ask to keep sheets open |

## Open Questions (RESOLVED)

1. **Does removing `firebase_auth` change anything native?** RESOLVED: no — probe diff limited to `pubspec.yaml`/`pubspec.lock`; no Dart import exists (`grep -rn firebase_auth lib test tool` → none); `ios/Podfile.lock` absent.
2. **Which `uuid` version?** RESOLVED: `^4.5.1` (already locked transitively; zero version churn).
3. **Do we need to bump Firebase/fln?** RESOLVED: no; locked versions build and run on the baseline; newer majors are out of scope.
4. **How does the app build without `google-services.json`?** RESOLVED: `missingGoogleServicesStrategy = WARN` (proved A/B/C builds).
5. **What exactly fails at runtime without the JSON, and is it synchronous?** RESOLVED: async `PlatformException` from `optionsFromResource`; guard with try/catch (+3 s timeout).
6. **Is desugaring / compileSdk work needed?** RESOLVED: already configured (`build.gradle.kts:16,44`; compileSdk 36).
7. **Which notification icon?** RESOLVED: new `drawable/ic_stat_klimmeck` + `raw/keep.xml` (launcher icon opaque).
8. **Can the gate tell `notDetermined` on Android?** RESOLVED: not via FCM; via permission_handler (Conflict C1, Pattern 7).
9. **Does creating the channel at startup prompt?** RESOLVED: no on target 36 (Android docs).
10. **Do FCM opened-callbacks fire for data-only?** RESOLVED: no (Pitfall 11, Conflict C3).
11. **Where does background-but-alive delivery go?** RESOLVED: background isolate (receiver checks foreground), never `onMessage`.
12. **Tap while alive vs killed?** RESOLVED: `onDidReceiveNotificationResponse` vs `getNotificationAppLaunchDetails()` (README).
13. **How is the pending intent provided?** RESOLVED: `NotificationIntentCubit` above `AuthGate` (needs `BlocListener` in `MainScreen`; clears on Authenticated→Unauthenticated and creation landing).
14. **Where is the banner mounted?** RESOLVED: `Stack` in `AuthenticatedShell` over `_ShellBody`, `SafeArea`, theme tokens; root dialogs above it accepted.
15. **Does Twitch launch need `<queries>`?** RESOLVED: no, `launchUrl` without `canLaunchUrl`.
16. **Hint row re-check?** RESOLVED: on tab build + `AppLifecycleEvents.foregrounded`.
17. **Should `Firebase.initializeApp()` run in the background isolate?** RESOLVED: not required (Conflict C4).
18. **iOS at runtime?** RESOLVED: `bootstrapPush` returns disabled when `!Platform.isAndroid` (no iOS device ever registers before the iOS phase).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK (fvm default) | build/tests | ✓ | 3.35.5 / Dart 3.9.2 | — |
| Android SDK + Gradle wrapper | scratch builds | ✓ (gradlew present, ignored) | AGP 8.9.1, Gradle 8.12 | — |
| JDK | `./gradlew` outside Flutter | ✓ only as Android Studio JBR (`/Applications/Android Studio.app/Contents/jbr/Contents/Home`; no system Java on PATH) | — | `flutter build apk` uses it automatically; for `./gradlew` export `JAVA_HOME` to the JBR |
| `android/app/google-services.json` | real push | ✓ local, gitignored | project `klimmeck-guide-app` | WARN strategy → push disabled |
| Node.js + BE `node_modules/graphql` | schema check | ✓ | 22.12.0 / 16.11.0 | — |
| BE `origin/develop` ≥ `0828719` | contract | ✓ (fetched) | — | — |
| Physical device | UAT | not probed this session (memory: Samsung SM-S938B Android 16 via USB) | — | emulator with Play services (killed-state behaviour differs from One UI) |
| BE `FIREBASE_SERVICE_ACCOUNT` | real sends | user prerequisite (not inspected) | — | without it `sendTestPush` → `PUSH_DISABLED` |
| `mongosh` | UAT row check | not probed | — | any Mongo client / Compass |

**Missing dependencies with no fallback:** none for development. **With fallback:** system JDK (use the JBR).

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false`, so this section is required.)

### Baseline (recorded 2026-10-19, branch `feat/05-notifications-infrastructure` at `8893510`, clean tree)
- `flutter test` → **762 tests, All tests passed, ~27 s** (`00:27 +762: All tests passed!`).
- `flutter analyze` → **57 issues (0 errors, 4 warnings, 53 infos)**, all pre-existing: warnings `dead_null_aware_expression` at `lib/screens/mainScreen/tabs/board/board.dart:54,65`, `lib/shared/components/spell_info.dart:52`, `unnecessary_cast` at `test/repository/services/auth/auth_token_service_contract_test.dart:40`; infos mostly `avoid_print` in `tools/svg_tool.dart`, plus `depend_on_referenced_packages` at `lib/utils/notification.dart:1`. **Deleting the legacy util drops the total to 56**: gate = `flutter analyze` total ≤ 56 with 0 errors after that commit, never higher.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 |
| Config file | none (defaults); shared mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/` |
| Quick run command | `flutter test test/models test/graphql test/repository/push_device_repository_test.dart test/repository/storage test/repository/services/push test/screens/auth test/screens/mainScreen/main_screen_notification_intent_test.dart test/screens/mainScreen/tabs/settings test/shared/components/kg_notification_banner_test.dart test/tool test/utils` |
| Full suite command | `flutter test` (baseline 762) + `flutter analyze` (≤ 56) + `dart format --output=none --set-exit-if-changed <each touched file>` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| NOTIF-01 | Documents: one named mutation each, variables `$input: RegisterPushDeviceInput!` / `$deviceId: String!`, no selection on `Boolean!` | unit | `flutter test test/graphql/push_mutations_test.dart` | Wave 0 |
| NOTIF-01 | Schema-check listing includes both | unit | `flutter test test/tool/schema_check_documents_test.dart` | exists (auto-enforces) |
| NOTIF-01 | `KlimmeckGraphQl.registerPushDevice/unregisterPushDevice` send the right operation + variables (`platform: 'android'`), surface `OperationException` | unit | `flutter test test/repository/services/graphql/graphql_push_test.dart` | Wave 0 |
| NOTIF-01 | Repository maps `PUSH_INVALID_DEVICE_ID`/`PUSH_INVALID_TOKEN`/`UNAUTHENTICATED`/link error/other → failures; `isRetryable` only connection/unknown | unit | `flutter test test/repository/push_device_repository_test.dart` | Wave 0 |
| NOTIF-01 | `DeviceIdentityStore`: creates a UUID v4 once, returns the same value from a new store instance, key `klimmeck.push.deviceId`, matches `[A-Za-z0-9._-]{1,128}` | unit | `flutter test test/repository/storage/device_identity_store_test.dart` | Wave 0 |
| NOTIF-01 | `ActiveUserStore` write/read/clear, key `klimmeck.push.activeUserId` | unit | `flutter test test/repository/storage/active_user_store_test.dart` | Wave 0 |
| NOTIF-01 | Coordinator: register on first `AuthAuthenticated`; no duplicate for same user re-emissions; register on token refresh; token arriving later; retry with backoff on connection (fake_async) capped at 5; no retry on invalid/unauthenticated; `unregister()` suspends + cancels retries; session end clears active user + `cancelAll()`; dispose cancels | unit (fake_async) | `flutter test test/repository/services/push/push_registration_coordinator_test.dart` | Wave 0 |
| NOTIF-01 | `AuthCubit.logout()`: unregister then service logout (order); 2 s timeout; unregister throwing still logs out; default no-op cleanup keeps old behaviour | cubit (fake_async/bloc_test) | `flutter test test/screens/auth/cubit/auth_cubit_test.dart` | exists, extend |
| NOTIF-02 | Gate: prompts only on `notDetermined`; returns current otherwise; idempotent on repeated calls | unit | `flutter test test/repository/services/push/notification_permission_gate_test.dart` | Wave 0 |
| NOTIF-02 | No call site of `ensureRequested(` in `lib/`; push plugin imports only in the allow-listed files | unit (static) | `flutter test test/repository/services/push/push_boundaries_test.dart` | Wave 0 |
| NOTIF-02 | Settings hint row: shown only for `denied`, hidden for `notDetermined`/`granted`, "Attiva" calls `openSettings()`, re-checks on `foregrounded`; cubit sequence | widget + cubit | `flutter test test/screens/mainScreen/tabs/settings` | Wave 0 / extend `settings_test.dart` |
| NOTIF-03/04/05 | `PushEvent.tryParse`: three types, `id` only for personal, missing title/body/sentAt → null, unknown `combatResult` → null; `NotificationCategory` wire mapping pinned | unit | `flutter test test/models/push_event_test.dart test/models/notification_category_test.dart` | Wave 0 / extend |
| NOTIF-03/04/05 | `handleDataMessage`: shows when active user + toggle on; nothing when no active user, toggle off, unknown type; payload round-trips to `NotificationIntent`; id stable for same event | unit | `flutter test test/repository/services/push/data_message_handler_test.dart` | Wave 0 |
| NOTIF-03/04/05 | `stableNotificationId`: deterministic, non-negative 31-bit, differs across types/ids | unit | `flutter test test/utils/stable_notification_id_test.dart` | Wave 0 |
| NOTIF-03/04/05 | `ForegroundPushEvents`: parse + toggle filter for the shell user; never calls `show()` | unit | `flutter test test/repository/services/push/foreground_push_events_test.dart` | Wave 0 |
| NOTIF-03/04/05 | Real delivery in killed/background/foreground on the device | manual | UAT recipe steps 5-7 | manual-only (needs FCM + device) |
| NOTIF-06 | `NotificationIntent` payload JSON round-trip, malformed payload → null | unit | `flutter test test/models/notification_intent_test.dart` | Wave 0 |
| NOTIF-06 | Router: personal → cubit offer; `streamerLive` → `LinkOpener.open(TwitchChannel.url)`; launch tap handled once | unit | `flutter test test/repository/services/push/notification_tap_router_test.dart` | Wave 0 |
| NOTIF-06 | `NotificationIntentCubit`: offer/consume; survives cold-start `Unauthenticated → Authenticated`; cleared on `Authenticated → Unauthenticated`; dropped when user has no character | cubit | `flutter test test/screens/auth/notificationIntentCubit/notification_intent_cubit_test.dart` | Wave 0 |
| NOTIF-06 | `MainScreen` consumes a pending intent: jumps to page 0 from another tab, pops root sheets, clears the intent, calls the (empty) popup hook | widget | `flutter test test/screens/mainScreen/main_screen_notification_intent_test.dart` | Wave 0 |
| NOTIF-07 | `KGNotification` `const` + Equatable + `fromJson`/`toJson` | unit | `flutter test test/models/notification_test.dart` | Wave 0 |
| NOTIF-07/08 | `InAppNotificationsCubit`: shows, auto-dismiss after 5 s, queue order, dedup by `(type,id)` within 2 min and `(type, minute)` within 15 min for `streamerLive`, after window shows again, `close()` cancels timer | cubit (fake_async) | `flutter test test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart` | Wave 0 |
| NOTIF-07 | Banner widget: renders title/description with theme tokens, no `SnackBar`/`MaterialBanner`/`Scaffold`, tap delegates to the router per type, ≥ 44 px, semantics | widget | `flutter test test/shared/components/kg_notification_banner_test.dart` | Wave 0 |
| NOTIF-07 | Shell provides the cubit and mounts the banner; creation page shows none | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | exists, extend |
| D-02 | App builds and runs without the JSON | manual + scripted | `flutter clean && flutter build apk --debug` with the JSON moved out (UAT step 9) | manual |

### Sampling Rate
- **Per task commit:** the task's test file(s) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>`.
- **Per wave merge:** quick run command above.
- **Phase gate:** full `flutter test` green (≥ 762 + new tests), `flutter analyze` ≤ 56 issues and 0 errors, schema check 27 × OK, scratch build with and without the JSON, UAT recipe done — before opening the PR.

### Wave 0 Gaps
- [ ] Gradle + manifest + `ic_stat_klimmeck` + `keep.xml`; scratch builds A (JSON present) and C (JSON absent + `flutter clean`).
- [ ] `pubspec.yaml`: `-firebase_auth`, `+uuid: ^4.5.1`, `flutter pub get`; delete `lib/utils/notification.dart` (analyzer → 56).
- [ ] `test/helpers/fakes/fake_shared_preferences_async.dart`: add `getString`/`setString`/`remove` (with the same failure queues).
- [ ] `test/helpers/fakes/`: `fake_push_messaging_port.dart`, `recording_local_notifications_port.dart`, `recording_link_opener.dart`, `fake_notification_permission_port.dart`, `never_completing_push_cleanup.dart` (or a scripted cleanup).
- [ ] `test/helpers/mocks.dart`: `MockPushDeviceRepository`, `MockInAppNotificationsCubit`, `MockNotificationIntentCubit`, `MockNotificationPermissionCubit`, `MockPushSessionCleanup`.
- [ ] Failing-first tests for every row of the map before its implementation.
- [ ] `tool/schema_check/schema_check_documents.dart` updated in the same commit as `push_mutations.dart`.
- [ ] `.planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md` (UAT outcome for BE, Phase 7 call-site note for `ensureRequested()`, Conflict C1 decision), `05-HUMAN-UAT.md`, REQUIREMENTS traceability NOTIF-01..08 → Phase 5.

## Security Domain

(`security_enforcement` absent in `.planning/config.json` → enabled.)

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherited) | Mutations go through the existing `AuthLink` bearer; no identity in input (BE D-02) |
| V3 Session Management | yes | Unregister before backend logout (D-08); active-user mirror cleared at session end (D-09); tray cleared; intent cleared on session end |
| V4 Access Control | yes | The FE cannot target another user's device (bearer-derived); `sendTestPush` is never called by the app |
| V5 Input Validation | yes | `PushEvent.tryParse` / `NotificationIntent.tryFromPayload` at the boundary; unknown types dropped; only the constant Twitch URL is ever launched |
| V6 Cryptography | no | No crypto; `deviceId` is a random opaque UUID |
| V7 Error handling & logging | yes | Log `runtimeType`/codes only; never the FCM token, payload body, user id or `google-services.json` content |
| V14 Configuration | yes | Firebase files gitignored (already); WARN strategy keeps CI green without secrets |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Notification for a logged-out user shown on a shared phone | Info disclosure | Unregister before logout; `ActiveUserStore` cleared → background handler drops; `cancelAll()` |
| Spoofed/malformed data message (only FCM with the server key can send, but treat as untrusted) | Tampering | Strict parsing, no URL or state from payload, unknown type dropped |
| Token leakage via logs | Info disclosure | No token logging; BE logs at most a 6-char suffix |
| Firebase API key committed | Info disclosure | `.gitignore` entries (D-02), research never prints it |
| Device re-assigned to another account without unregister | Spoofing | BE token-uniqueness invariant moves the row (BE §5.6) |
| Permission nagging / dark pattern | (UX abuse) | Single prompt site in Phase 7; hint row only when denied |

## Sources

### Primary (HIGH confidence)
- Repo files read at the cited lines: `lib/main.dart`, `lib/screens/auth/{cubit/auth_cubit.dart, authenticated_shell.dart, session_home.dart}`, `lib/screens/mainScreen/main_screen.dart`, `lib/repository/storage/notification_preferences_store.dart`, `lib/models/{notification.dart, notification_category.dart}`, `lib/utils/{notification.dart, backoff.dart}`, `lib/repository/{character_deletion_repository.dart, character_deletion_failure.dart}`, `lib/repository/services/graphql/{graphql.dart, graphql_error_code.dart}`, `lib/repository/services/auth/{auth_token_service.dart, auth_state_channel.dart}`, `lib/repository/services/sync/app_lifecycle_events.dart`, `lib/config/*.dart`, `lib/graphql/mutations/character_mutations.dart`, `tool/schema_check/*`, `test/tool/schema_check_documents_test.dart`, `test/helpers/*`, `android/{settings.gradle.kts, build.gradle.kts, app/build.gradle.kts, app/src/main/AndroidManifest.xml, gradle/wrapper/gradle-wrapper.properties}`, `pubspec.yaml`, `pubspec.lock`, `.gitignore`.
- BE (read-only): `.planning/phases/05-infrastruttura-push-fcm/{BACKEND-NOTES.md, 05-CONTEXT.md, 05-HUMAN-UAT.md}`, `git show origin/develop:src/schema.gql` (`0828719`), `.env.example` (names only).
- Plugin sources in `~/.pub-cache/hosted/pub.dev/`: `firebase_core-3.15.1` (`FlutterFirebaseCorePlugin.java`, `GeneratedAndroidFirebaseCore.java`), `firebase_core_platform_interface-6.0.0` (`method_channel_firebase.dart`, `messages.pigeon.dart`), `firebase_messaging-15.2.9` (`FlutterFirebaseMessagingPlugin.java`, `FlutterFirebaseMessagingReceiver.java`, `AndroidManifest.xml`, `lib/src/messaging.dart`), `firebase_messaging_platform_interface-4.6.9/4.7.9` (dispatcher, `utils.dart`), `flutter_local_notifications-19.3.0` (README, `flutter_local_notifications_plugin.dart`, `platform_flutter_local_notifications.dart`, manifest, `build.gradle`), `flutter_local_notifications_platform_interface-9.1.0` (`types.dart`), `permission_handler-12.0.1`, `permission_handler_android-13.0.1` (`PermissionUtils.java`, `PermissionManager.java`), `shared_preferences-2.5.3` README, `url_launcher-6.3.2` README, `uuid-4.5.1`.
- Google Services Gradle plugin jars 4.4.4 and 4.5.0 from `dl.google.com` (disassembled `GoogleServicesPlugin$MissingGoogleServicesStrategy`, `GoogleServicesPluginConfig`), Google Maven `maven-metadata.xml`.
- Flutter tools `FlutterExtension.kt` (SDK defaults), `FlutterPlugin.kt:258-285` (release shrink).
- Executed this session: `flutter --version`, `flutter test` (762 passed), `flutter analyze` (57), dependency probe `flutter pub get` (reverted), three scratch Android builds + `./gradlew :app:processDebugGoogleServices` with WARN and with the default strategy (reverted), `validate_documents.js` on scratch documents (OK ×3, negative control FAIL), PNG alpha measurement of `launcher_icon.png`, pub.dev API version listing.

### Secondary (MEDIUM confidence)
- https://firebase.google.com/docs/cloud-messaging/flutter/receive — background handler rules, force-stop note, 30 s limit.
- https://firebase.google.com/docs/cloud-messaging/android/message-priority — deprioritisation of high-priority messages without visible notifications.
- https://firebase.google.com/docs/cloud-messaging/android/client — runtime permission on Android 13, token generated at startup.
- https://developer.android.com/develop/ui/views/notifications/notification-permission — default off on 13+, no auto prompt on target 13+, swipe-away keeps state.
- https://firebase.google.com/docs/android/google-services-plugin-and-file — missing-file error text, plugin 4.5.0 snippet.

### Tertiary (LOW confidence)
- WebSearch on `missingGoogleServicesStrategy` returned nothing authoritative; the property was verified directly from the plugin jar and by build, so no claim rests on search results.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — locked versions re-resolved after the real pubspec change; build proved with the plugin.
- Architecture: HIGH for layering and contract (rules + validated documents); MEDIUM for discretionary shapes (cubit placements, banner overlay) which follow project practice.
- Pitfalls: HIGH for build/permission/tap-source items (source + builds); MEDIUM for OEM killed-state delivery and cross-engine prefs (device-only, covered by UAT).

**Research date:** 2026-10-19
**Valid until:** 2026-11-18 (30 days; re-check if `firebase_*`/fln are bumped, if BE `src/schema.gql` changes the push types, or if the Android target SDK moves past 36)
