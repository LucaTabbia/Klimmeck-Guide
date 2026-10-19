# Phase 5: Notifications Infrastructure - Context

**Gathered:** 2026-10-19 (interactive discuss: the user answered every gray area; technical defaults below are marked as such)
**Status:** Ready for planning
**Amended:** 2026-10-19 after research — D-01, D-10, D-12, D-15 carry a "revised after research" note (05-RESEARCH.md §"Conflicts with CONTEXT", C1/C3/C4); the user can veto at PR review.

<domain>
## Phase Boundary

The app becomes a **push client of the backend's FCM infrastructure** (BE Phase 5, merged in BE PR #8 on 2026-10-18) and owns every notification surface of the game, **on Android** (user decision: iOS wiring is deferred to a later phase):

- **Registration** (NOTIF-01): after login the FCM token is registered per device with `registerPushDevice`, kept fresh on token refresh and on every start with a valid session, and removed with `unregisterPushDevice` **before** logout.
- **Permission** (NOTIF-02): the phase ships the permission gate API; the **only prompt trigger is the first travel confirmation, wired by Phase 7**. Phase 5 adds no prompt; a Settings hint appears only when the OS permission is denied.
- **Delivery in the three app states** (NOTIF-03/04/05): the backend sends **data-only** messages (`type`, `title`, `body`, `sentAt`, optional `id`); the app applies the per-category toggles of Phase 4 and shows the system notification itself (background/killed) or an in-app banner (foreground) for `travelEnd`, `streamerLive`, `questEnd`.
- **Tap routing** (NOTIF-06, amended 2026-10-19): `travelEnd`/`questEnd` taps land on the **Map tab** (their context popups arrive with Phases 7/9); a `streamerLive` tap **opens the Twitch channel directly**. Behaviour is uniform across killed, background and foreground and identical for system notifications and in-app banners.
- **In-app banner + dedup** (NOTIF-07/08): foreground events render as banners built on the existing `KGNotification` model; a single event never produces both a banner and a system notification.

The backend contract is **fixed** (`Klimmeck-Guide-BE/src/schema.gql` wins): mutations `registerPushDevice`, `unregisterPushDevice`, `sendTestPush`; enums `PushPlatform`/`PushEventType`; codes `PUSH_INVALID_DEVICE_ID`, `PUSH_INVALID_TOKEN`, `PUSH_DISABLED`. The FE calls only the first two; `sendTestPush` (innkeeper-only) is the E2E trigger.

Out of scope: iOS (`ios/` untouched, APNs, iOS UAT), the rich context popups (travel-end in Phase 7, quest-end/death in Phase 9), any permission prompt (Phase 7), syncing preferences to the backend, notification history/inbox, badges, the Firebase project itself (user prerequisite), the real BE triggers (BE Phases 6/8/9).

**Platform prerequisites (user deliverables, outside the repo):** a Firebase project shared with the backend; Android app `it.lordreavor.klimmeckguide.klimmeck_guide` → `google-services.json` placed locally (not committed, D-02); backend `.env` with `FIREBASE_SERVICE_ACCOUNT` of the same project. The app must build and run without the file.

</domain>

<decisions>
## Implementation Decisions

### Firebase bootstrap & push stack (NOTIF-01, NOTIF-03..05)
- **D-01:** Stack confirmed: `firebase_core` + `firebase_messaging` (already in `pubspec.yaml`, `^3.15.1` / `^15.2.9`) for token, permission status and message streams; `flutter_local_notifications` (`^19.3.0`, present) to display the system notification built from the data-only payload (the backend never sends a `notification` block, BE Phase 5 D-10); `permission_handler` (present) for the notification-permission port — `Permission.notification.status`, `shouldShowRequestRationale`, `request()`, `openAppSettings()` (D-10; _revised after research C1: originally "only for `openAppSettings()`"_); `url_launcher` (present) for the Twitch link (D-16). The only new runtime dependency is `uuid` (D-05). The researcher pins versions against the Flutter 3.35.5 / Dart 3.9.2 baseline (Phase 2 D-30/D-31).
- **D-02 (user decision):** `android/app/google-services.json` (and, for the future iOS phase, `GoogleService-Info.plist`) stay **out of the VCS**: `.gitignore` entries plus a comment in `.env.example`/README on where the file comes from. `Firebase.initializeApp()` runs in `main()` before `runApp` inside a guard: if it fails (file missing in a dev checkout, CI) push is **disabled with a `debugPrint` warning and the game runs unchanged** — the composition root wires a no-op messaging port. Mirror of the backend's `NoopPushTransport`. Tests never touch Firebase (D-19).
- **D-03 (user decision — Android only):** native wiring is explicit Wave 0 work (Phase 11 D-34 / Phase 2 D-31 pattern), verified with a scratch build: `com.google.gms.google-services` Gradle plugin, `POST_NOTIFICATIONS` permission in `AndroidManifest.xml`, a notification channel `klimmeck_events` (high importance, default sound) created at startup. **Nothing under `ios/` changes** in this phase; iOS (Info.plist background modes, entitlements, APNs key, iOS UAT) is a deferred item for a later phase. `platform: android` is what the app registers; the code stays platform-agnostic behind the ports (D-19).
- **D-04:** Delivery semantics follow the backend contract verbatim (`BACKEND-NOTES.md` §2): `data.type` maps 1:1 onto `NotificationCategory` (`travelEnd`, `streamerLive`, `questEnd`); `id` is present only for personal types; an unknown `type` (the future `combatResult`) is dropped with a debug log and never crashes. The FE never subscribes to FCM topics — the backend does it server-side at registration.
- **D-05 (Boy Scout, user decision):** `firebase_auth` is removed from `pubspec.yaml` (login is backend-mediated since Phase 11; the researcher confirms no import) and the legacy `lib/utils/notification.dart` (`NotificationsBloc` importing `rxdart`, not a dependency) is deleted.

### Device identity & registration lifecycle (NOTIF-01)
- **D-06:** `deviceId` = **UUID v4 generated once and persisted device-wide** in `shared_preferences` (a key not scoped by user, e.g. `klimmeck.push.deviceId`), never rotated: it survives logout and account switch and dies only with a reinstall (the backend row then expires by TTL). Package `uuid`. A `DeviceIdentityStore` in `lib/repository/storage/` follows the `SharedPreferencesAsync` + injectable-factory pattern of `NotificationPreferencesStore`.
- **D-07:** Registration is owned by a Flutter-free **`PushRegistrationCoordinator`** (`lib/repository/services/push/`) that observes `AuthTokenService.authStateStream` and the messaging port's token stream: `AuthAuthenticated` (login **and** cold-start bootstrap) with a token available → `registerPushDevice({ deviceId, token, platform: android })`; `onTokenRefresh` while authenticated → re-register; a token arriving after login → register then. Silent and non-blocking (rule 2): bounded exponential retry with `lib/utils/backoff.dart` on transient failures, no UI ever; `PUSH_INVALID_DEVICE_ID` / `PUSH_INVALID_TOKEN` / `UNAUTHENTICATED` → log, no retry (FE bug or ended session). Registration does **not** wait for the OS permission (Android tokens exist without it). GraphQL documents `RegisterPushDevice` / `UnregisterPushDevice` in `lib/graphql/mutations/push_mutations.dart`; a `PushDeviceRepository` maps `extensions.code` (pattern `CharacterDeletionRepository`).
- **D-08 (user decision):** `unregisterPushDevice(deviceId)` is orchestrated by **`AuthCubit.logout()`**: it first awaits the coordinator's `unregister()` (best-effort, **2 s timeout**, failures logged only), then calls `_authTokenService.logout()` as today. `confirmLogout` and the creation page "Esci" already go through `AuthCubit.logout()`, so the order "unregister → backend `logout`" holds for every user-initiated logout. The auth services and the `AuthTokenService` contract (Phase 1 D-02) are untouched. Revocation and sync-lost terminations do **not** unregister (no usable bearer); the backend's token claim at the next login covers them (BE §5 point 6).
- **D-09:** The active account is mirrored on the device for the background isolate: an **`ActiveUserStore`** (shared_preferences, e.g. `klimmeck.push.activeUserId`) written on `AuthAuthenticated` and cleared when the session ends (logout, revocation, sync lost). The background handler reads it to resolve the per-user toggles (Phase 4 D-11 keys); no active user → the message is dropped silently.

### Notification permission (NOTIF-02)
- **D-10 (user decisions):** Phase 5 ships one idempotent entry point, **`NotificationPermissionGate.ensureRequested()`** (Flutter-free service over `requestPermission()` / `getNotificationSettings()` of the messaging port): prompts only when the OS status is `notDetermined`, otherwise returns the current status; nothing is persisted (the OS is the source of truth). **Phase 5 never calls it**: the only trigger is the **first travel confirmation, wired by Phase 7** (call site documented in this phase's handoff for Phase 7). A test guards that `main.dart`/`AuthGate`/`SplashScreen`/Settings never reach the prompt. In Settings, under the three toggles, a **hint row appears only when the OS permission is `denied`** ("Le notifiche di sistema sono disattivate" + "Attiva" → `openAppSettings()`); nothing is shown while the status is `notDetermined`. No nagging anywhere else. _(Revised after research 2026-10-19, Conflict C1: on Android `firebase_messaging` reports only `authorized`/`denied`, never `notDetermined`, so the gate and the hint row are implemented over `permission_handler` (`Permission.notification.status` + `shouldShowRequestRationale` + `request()` + `openAppSettings()`), not over the messaging port. Every behaviour above is preserved: prompt only where Phase 7 calls it, hint only when the OS permission is really denied, nothing persisted by the app. Accepted limitation: on Android 7–12 a user who disabled notifications by hand sees no hint row.)_
- **D-11 (user decision):** The Phase 5 UAT grants the permission **manually from the Android system settings** (Settings › Apps › Notifications): no dev-only trigger, nothing to strip in Phase 12.

### Receiving & displaying in the three app states (NOTIF-03, NOTIF-04, NOTIF-05)
- **D-12:** A top-level `@pragma('vm:entry-point')` background handler registered with `FirebaseMessaging.onBackgroundMessage` in `main()` before `runApp` covers background and terminated states. Its logic is a **pure function** `handleDataMessage(data, {activeUser, preferences, notifier})` testable with fakes: parse → map type → read `ActiveUserStore` + `NotificationPreferencesStore` → if enabled, show a local notification (title/body from `data`, payload = JSON of `data`, channel `klimmeck_events`); otherwise nothing. The isolate initialises `flutter_local_notifications` itself after `DartPluginRegistrant.ensureInitialized()`; `Firebase.initializeApp()` inside the isolate is not required for this handler and is omitted (or guarded in try/catch if kept) — _revised after research C4_.
- **D-13:** Foreground (`onMessage`): **never a system notification**; the same filter feeds the in-app banner (D-17). This *is* the NOTIF-08 rule "foreground suppresses the duplicate push".
- **D-14:** Toggles apply in all three states before anything is shown (banner included). `getNotificationAppLaunchDetails()` / `getInitialMessage()` are consulted once at startup for a tap that launched the app (D-15).

### Tap routing (NOTIF-06 — amended 2026-10-19)
- **D-15:** Every tap becomes a **`NotificationIntent { type, id?, sentAt }`** model (`lib/models/`). Sources: the `flutter_local_notifications` response callback + launch details (the system notification is always the FE-built one for data-only messages) FCM `onMessageOpenedApp` / `getInitialMessage` are **not** used: for data-only messages they never fire on Android, so the FE-built local notification is the only tap source and the port does not expose them — _revised after research C3 (originally "belt and braces")_. Intents for personal types are buffered in a **`PendingNotificationIntent`** holder provided above `AuthGate` and **consumed declaratively by `MainScreen`** once the authenticated shell with a character is mounted: `pageController.jumpToPage(0)` (WorldMap is index 0 in `_buildPages`). **No popup in this phase** for `travelEnd`/`questEnd` (user decision): Phases 7 and 9 add their context popups behind a per-type hook (`NotificationPopupRegistry` or equivalent) that Phase 5 leaves empty. The intent survives splash and sign-in (killed state → login → consumed), is cleared on consumption or at logout, and is dropped when the session lands on the creation page (no character). No imperative global router: the ROADMAP's "NavigationService GlobalKey" is not needed; the existing `navigatorKey` stays for future popups.
- **D-16 (user decision):** A **`streamerLive` tap opens the Twitch channel directly** — `https://www.twitch.tv/lordreavor`, a constant in `lib/config/` (e.g. `TwitchChannel.url`; not a secret) — through `url_launcher` (`LaunchMode.externalApplication`), without passing through the Map tab or a popup. The same action applies to the banner tap (D-17). The earlier idea of a streamer-live popup with a "Guarda la live" button is superseded by this direct action. NOTIF-06 and ROADMAP success criterion 4 carry a dated amendment (done in this discuss).

### In-app banner & dedup (NOTIF-07, NOTIF-08)
- **D-17 (user decision):** Foreground events render as an **in-app banner** built on **`KGNotification(title, description)`** (existing model in `lib/models/notification.dart`; Boy Scout: `Equatable`, `const` constructor, `fromJson` kept): a **thin strip at the top** of the screen in the parchment/ink language from `kg_theme.dart` (no `SnackBar`, no `MaterialBanner`), **auto-dismiss ≈ 5 s**, one banner at a time via a queue in an **`InAppNotificationsCubit`**. **Tap behaviour is per type and identical to the system notification**: `travelEnd`/`questEnd` → Map tab (D-15), `streamerLive` → Twitch (D-16); a type with no action (none today) is purely informative. The cubit is provided in `AuthenticatedShell` (banners need a character; the creation page shows none).
- **D-18:** `InAppNotificationsCubit.publish(event)` is the **single publication path** for every producer (FCM foreground now; the subscription-driven producers of Phases 7/9 later) and **dedups by `(type, id)`** — `(type, sentAt minute)` for the id-less `streamerLive` — within a sliding in-memory window (≈ 2 min; 15 min for `streamerLive`). Together with D-13 this guarantees one surface per event in foreground; background/killed states only ever have the system notification.

### Architecture, tests, tooling, branch
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 5: Notifications Infrastructure" — goal, success criteria 1–5 (SC 4 amended 2026-10-19), platform note (Android only).
- `.planning/REQUIREMENTS.md` — NOTIF-01..NOTIF-08 (NOTIF-06 amended 2026-10-19); anti-feature "Cold-launch notification permission prompt"; SET-02/SET-04 (the toggles this phase consumes).
- `.planning/PROJECT.md` §"Key Decisions" — "Notifiche Firebase (FCM + APNs)" (pending → validated on Android by this phase), "Impostazioni… preferenze notifiche solo sul device".

### Backend contract (separate repo — source of truth for every name, payload and code)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/BACKEND-NOTES.md` — TL;DR §0, SDL §1, payload §2, Android/iOS caveats §3, Firebase checklist §4, recommended FE flow §5, `sendTestPush` E2E recipe §6, codes §7, manual verification §10.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/05-CONTEXT.md` — BE decisions D-01..D-18 (registry, data-only payload, pruning, topic `streamer-live`).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/05-HUMAN-UAT.md` — the real-device delivery item this phase's UAT closes (Android).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` (at `origin/develop` ≥ `0828719`) — **wins over every document**.

### Prior phase decisions this phase builds on
- `.planning/phases/04-settings-screen/04-CONTEXT.md` — D-09..D-14 (categories, device-only store keyed per user, defaults, Flutter-free store for the background isolate, "Phase 5 may add a note under the toggles"), D-07 (`confirmLogout` unchanged).
- `.planning/phases/04-settings-screen/BACKEND-NOTES.md` §4 — client-side filtering agreed with the backend.
- `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md` — D-02 (frozen `AuthTokenService` contract), D-04 (refresh never blocks), D-11..D-13 (logout confirmation, teardown order, best-effort backend logout), D-23..D-25 (dev bypass), D-33 (nothing blocks `runApp`), D-34 (native prerequisites as Wave 0), D-36 (logout single-flight), D-38 (no `dart format` on directories).
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-07 (`adoptUser` single entry for `User`), D-10 (root routes popped on character change), D-13 (resume re-queries), D-14 (transient failures silent), D-17 (no QA tooling).
- `.planning/phases/02-character-creation/02-CONTEXT.md` — D-25 (formatting discipline), D-30/D-31 (toolchain baseline: Flutter 3.35.5, minSdk 24), D-33 (schema check before PR).
- `.planning/phases/01-dev-auth-stub/01-CONTEXT.md` — D-02 (implementation swap, never an interface change).

### Project rules
- `docs/rules/ui-ux.md` — chrome rule (the banner is a gameplay surface, Settings is utility), no blocking loading, theme-only styles, "deep link e notification tap handler convergono", error copy.
- `docs/rules/architecture.md` — layers; `lib/repository/services/`, `lib/repository/storage/`, `lib/shared/components/`, `lib/config/` (constants, no logic).
- `docs/rules/state-management.md`, `docs/rules/graphql.md` (documents in `lib/graphql/`, error mapping by code, cleanup in `close()`), `docs/rules/naming.md`, `docs/rules/testing.md`, `docs/rules/workflow.md` (branch `feat/05-notifications-infrastructure`, PR to `develop`, planning docs with the code), `docs/rules/assets.md`.

### Codebase maps
- `.planning/codebase/INTEGRATIONS.md` — Firebase dependencies present but disabled; config files not committed; `flutter_local_notifications` present.
- `.planning/codebase/STRUCTURE.md`, `.planning/codebase/CONVENTIONS.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `pubspec.yaml` — `firebase_core ^3.15.1`, `firebase_messaging ^15.2.9`, `flutter_local_notifications ^19.3.0`, `permission_handler ^12.0.1`, `url_launcher ^6.1.7`, `shared_preferences ^2.0.12` already declared; `firebase_auth ^5.6.2` declared and unused (D-05).
- `lib/models/notification.dart` — `KGNotification(title, description)` with `fromJson`/`toJson`: the NOTIF-07 banner model (D-17).
- `lib/models/notification_category.dart` — `NotificationCategory { travelEnd, streamerLive, questEnd }` with `storageKey` and `defaultEnabled`: the FE mirror of `PushEventType` (D-04).
- `lib/repository/storage/notification_preferences_store.dart` — `NotificationPreferencesStore` (abstract) + `SharedPreferencesNotificationPreferencesStore` on `SharedPreferencesAsync` (no isolate cache): readable from the background isolate (Phase 4 D-14), and the pattern for `DeviceIdentityStore` / `ActiveUserStore` (D-06, D-09).
- `lib/main.dart` — composition root: `Firebase.initializeApp()` goes before `runApp` next to `dotenv.load`; `_buildAuth` shows how services are composed; the `navigatorKey` global; `AuthGate` → `SessionSyncScope` → `SessionHome` → `AuthenticatedShell`.
- `lib/screens/auth/cubit/auth_cubit.dart` — `logout()` delegates to the service: the single place that gains the unregister step (D-08).
- `lib/screens/auth/authenticated_shell.dart` — `MultiBlocProvider` of the session cubits (where `InAppNotificationsCubit` joins), `NotificationPreferencesCubit` wiring with `userId`.
- `lib/screens/mainScreen/main_screen.dart` — `_buildPages` (WorldMap index 0), `pageController.jumpToPage(index)` in `onItemTap`, `SatchelLayout.entries` assertion: the consumption point of `NotificationIntent` (D-15).
- `lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart` + `notificationCubit/` — the toggles section that hosts the denied-permission hint row (D-10).
- `lib/repository/services/auth/auth_token_service.dart` — `AuthState` sealed classes (`AuthAuthenticated.user`, `AuthUnauthenticated.reason`) the coordinator observes (D-07, D-09).
- `lib/repository/character_deletion_repository.dart` / `character_deletion_failure.dart` — repository + typed failure + `extensions.code` mapping pattern for `PushDeviceRepository`.
- `lib/graphql/mutations/character_mutations.dart` — document style for `push_mutations.dart`.
- `lib/utils/backoff.dart`, `lib/repository/services/sync/app_lifecycle_events.dart` — bounded retry and lifecycle bus (resume) for the coordinator and the hint row.
- `lib/config/env_config.dart`, `lib/config/cloudinary_assets.dart` — where the `TwitchChannel.url` constant belongs (D-16).
- `tool/schema_check/` — document-vs-schema verification (D-21).
- `lib/utils/notification.dart` — legacy `NotificationsBloc` (`rxdart`, unused): delete (D-05).

### Established Patterns
- Services are Flutter-free and injected by constructor; `BuildContext` never reaches cubits/services; dialogs open on the root `Navigator`.
- The frozen auth contract is extended only by additive capabilities or by orchestration in `AuthCubit` (D-08), never by interface changes.
- Silent failure in session (Phase 3 D-14): no indicator, bounded backoff, `debugPrint` only.
- Phase docs verify GraphQL documents against the regenerated BE schema before the PR; BE PR first (already merged here).
- Native prerequisites are explicit Wave 0 tasks with a scratch build (Phase 11 D-34, Phase 2 D-31).

### Integration Points
- `main.dart`: Firebase init guard, background handler registration, messaging/local-notification/link adapters, `PushRegistrationCoordinator` lifetime, `PendingNotificationIntent` provider above `AuthGate`.
- `AuthCubit.logout()`: unregister (2 s) → service logout (D-08).
- `AuthenticatedShell`: `InAppNotificationsCubit` + banner overlay; `MainScreen`: intent consumer (Map tab).
- Settings `NotificationPreferencesSection`: denied-permission hint row (D-10).
- Android: `android/settings.gradle.kts` / `android/app/build.gradle.kts` (google-services plugin), `AndroidManifest.xml` (`POST_NOTIFICATIONS`), `.gitignore`.
- Phase 7 (travel confirmation) calls `NotificationPermissionGate.ensureRequested()` and registers the travel-end popup; Phase 9 registers the quest-end/death popup; both publish banners through `InAppNotificationsCubit`.

### Gaps found during scouting
- No Firebase initialisation anywhere in `lib/` (dependencies present, never wired); no `google-services.json`; `.gitignore` does not list it.
- `AndroidManifest.xml` lacks `POST_NOTIFICATIONS`; Gradle lacks the google-services plugin.
- `lib/utils/notification.dart` imports `rxdart` (not a dependency).
- The background isolate has no way to know the current user: hence `ActiveUserStore` (D-09).

</code_context>

<specifics>
## Specific Ideas

- User (2026-10-19): the permission prompt belongs **only** to the first travel confirmation (Phase 7); Phase 5 adds no prompt and the UAT grants the permission by hand from the Android settings.
- User (2026-10-19): `travelEnd`/`questEnd` taps go to the Map tab **without a popup** in this phase; a `streamerLive` tap opens the channel **`https://www.twitch.tv/lordreavor`** directly.
- User (2026-10-19): banner = thin strip at the top, ~5 s, with navigation on tap only where the type needs it ("lo decideremo sulla base del tipo di notifica").
- User (2026-10-19): unregister orchestrated in `AuthCubit.logout()`; Firebase config files out of the VCS; **Android only**; remove `firebase_auth` and the legacy notification util.
- Backend handoff TL;DR items 1–7 (`BACKEND-NOTES.md` §0) are binding: register after login and on `onTokenRefresh`, re-register at every start, unregister **before** logout, `deviceId` = persisted UUID (`[A-Za-z0-9._-]`, ≤ 128), toggles stay on the device, E2E via `sendTestPush`.
- The backend logs `Push notifications enabled for Firebase project <project_id>` at boot: the UAT compares it with the `project_id` in `google-services.json` (BE §4 point 1).

</specifics>

<deferred>
## Deferred Ideas

- **iOS support** (user decision 2026-10-19): `Info.plist` `UIBackgroundModes: remote-notification`, Push Notifications entitlement, APNs key in Firebase, `GoogleService-Info.plist`, iOS background-push caveats (BE §3), iOS UAT — a later phase; the ports of D-19 keep it a wiring change.
- **Context popups** for `travelEnd` (Phase 7) and `questEnd`/death (Phase 9) — registered behind the per-type hook left empty by D-15.
- **Streamer-live popup with "Guarda la live"** — superseded by the direct Twitch link (D-16); revisit only if the direct jump proves confusing.
- **Server-side notification preferences** (multi-device coherence, backend suppression) — only if a real need appears (Phase 4 deferred, BE Phase 5 §3).
- **Dedup across isolates / persisted ledger of shown notifications** — in-memory window is enough while the subscription-driven producers do not exist (D-18).
- **Notification inbox/history, badge counts, pre-permission explainer dialog** — not in NOTIF-01..08.
- **`combatResult` push type** — Phase 9 (BE catalog is exhaustive; FE drops unknown types until then, D-04).

</deferred>

---

*Phase: 05-notifications-infrastructure*
*Context gathered: 2026-10-19*
