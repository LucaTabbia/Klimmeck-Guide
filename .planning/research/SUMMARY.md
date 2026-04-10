# Project Research Summary

**Project:** Klimmeck Guide — v1.0 Core Loop
**Domain:** Brownfield Flutter mobile RPG with Twitch integration — adding auth, real-time sync, gesture UI, travel timers, push notifications, and admin panel to an existing BLoC app
**Researched:** 2026-04-10
**Confidence:** HIGH (direct codebase analysis + established patterns; MEDIUM on Twitch API specifics)

---

## Executive Summary

Klimmeck Guide v1.0 is a focused brownfield integration milestone. The existing app is structurally sound — BLoC architecture, GraphQL client, map, inventory, and shop are already in place. What v1.0 adds is identity (Twitch OAuth), real-time character state (GraphQL subscription), the core RPG interaction loop (swipe-to-accept quest, travel, combat outcome), push notifications, spell management, and an admin panel for the streamer. The research confirms this is achievable with only two new pubspec packages (`flutter_web_auth_2`, `flutter_secure_storage`); everything else — Firebase, WebSocket, gesture handling — is already present or handled by Flutter's built-in widgets.

The single most important architectural constraint is the build order: Auth must be fully wired before anything else can run. `AuthBloc` (with `AuthTokenService`) sits above the entire `MultiBlocProvider` subtree and gates every authenticated feature. `UserBloc` (the session-wide GraphQL subscription for character state) must be added immediately after Auth and feeds every downstream feature with live data. Every other feature in v1.0 is either in Tier 4 (parallel after those two), Tier 5 (event-driven, needs subscription infrastructure), or Tier 6 (hardening). Following the tier order is not optional — skipping it creates integration debt that is hard to unwind.

The top risks are security (unencrypted token storage is one line of bad code away from the existing pattern), concurrency (coin deduction race, duplicate subscription, stale logout), and correctness (travel timer must be server-authoritative, admin mutations must be server-enforced). These are all preventable with clear conventions established before each phase begins. The hardening phase at the end must be treated as a full phase, not a sprint epilogue.

---

## Key Findings

### Recommended Stack

The codebase already contains the correct packages. Only two additions are needed for v1.0. Three Firebase packages (`firebase_core`, `firebase_messaging`, `flutter_local_notifications`) are present in `pubspec.yaml` but not initialised — they need wiring work, not package additions. The GraphQL WebSocket/subscription transport is fully configured in `graphql_client_provider.dart` with `autoReconnect: true`.

**Package additions:**
- `flutter_web_auth_2: ^4.0.0` — Twitch PKCE OAuth flow via ASWebAuthenticationSession (iOS) / Chrome Custom Tab (Android); correct successor to deprecated `flutter_web_auth`. Verify version on pub.dev before adding.
- `flutter_secure_storage: ^9.2.2` — Encrypted token storage via Android Keystore / iOS Keychain. No viable alternative for this use case. Verify version on pub.dev.

**Packages explicitly rejected:**
- `firebase_auth` — already in pubspec but wrong tool for Twitch OAuth; routes tokens through Firebase unnecessarily. Keep disabled.
- `flutter_appauth` — heavier AppAuth native SDK; not needed for Twitch's PKCE flow.
- `flutter_slidable` / any swipe package — Flutter's `Dismissible` is sufficient; third-party swipe packages address a different UX pattern (action buttons, not accept).

**Platform setup required (non-trivial):**
- Android `AndroidManifest.xml`: add `CallbackActivity` for `flutter_web_auth_2` with `klimmeck://auth` scheme.
- iOS `Info.plist`: add `CFBundleURLSchemes: [klimmeck]`.
- Firebase: `google-services.json` (Android) + `GoogleService-Info.plist` (iOS), Gradle plugin wiring, APNs Auth Key uploaded to Firebase Console, `flutterfire configure` to generate `firebase_options.dart`.

**WebSocket auth token gap:** The current `initialPayload` on `WebSocketLink` is an empty map. When auth is added, the backend must clarify whether `connection_init` should carry `Authorization: Bearer <token>`. Confirm with backend before implementing `UserBloc`.

### Expected Features

**Must have (table stakes):**
- Twitch PKCE OAuth via system browser (not WebView — Twitch TOS prohibits it)
- Refresh token persistence in encrypted storage across sessions
- Logout + token revocation, account switch
- GraphQL subscription auto-start after login with reconnect on resume
- Loading / stale-data indicators when subscription is disconnected
- Quest swipe gesture with haptic feedback + accessibility fallback (long-press)
- Swipe confirmation step before mutation fires (channel points have real value)
- Type-specific quest info sheet layouts (hunt/boss/dungeon/heal/story/worldMission each differ structurally)
- Travel ETA + cost confirmation before committing
- Server-authoritative travel timer (cosmetic display only on client)
- FCM token registration post-login; iOS permission prompt in-context (first travel confirm), never at cold launch
- All three notification tap paths handled: killed, background, foreground
- Spell list with slot assignment (tap-based, not drag-and-drop) + optimistic UI with rollback
- Combat result full-screen overlay (not bottom sheet) with explicit dismiss
- Admin panel: role-gated tab visible only when `isAdmin == true` from server
- Admin mutations server-enforced with `@Roles('admin')` — client-side gating is UX only

**Should have (differentiators):**
- Animated currency counter on subscription update
- "Reconnecting..." stale indicator when WebSocket drops
- Haptic + paper-tear visual on swipe-accept
- Themed quest info sheet headers per type (color / icon)
- Animated HP bar (old to new value) on combat result
- Sequential combat result reveal (wounds, consumables, rewards, XP)
- Admin panel: badge count for pending requests + auto-refresh via subscription or 30s poll

**Defer to v2+:**
- Round-by-round combat log (summary only for v1)
- Pet/mount speed modifiers
- Drag-and-drop spell slot assignment
- Custom deep link routing via go_router (current manual `NavigationService` is sufficient for v1)

### Architecture Approach

The integration follows the existing BLoC/repository layer contract without restructuring it. Two structural changes affect the whole app: (1) `AuthBloc` moves above `MultiBlocProvider` in `main.dart` so that logout tears down all feature BLoCs simultaneously; (2) `AuthTokenService` (a simple singleton) replaces the existing fragile `navigatorKey.currentContext!` pattern for injecting auth headers into GraphQL requests. Everything else is additive — new Blocs, repositories, and widgets slotted into the existing structure.

**Major components to create:**

| Component | Type | Role |
|-----------|------|------|
| `AuthBloc` + `AuthRepository` + `AuthTokenService` | Bloc + Repo + Service | Owns OAuth flow, token refresh, logout, token injection |
| `SecureStorageService` | Service | Encrypts refresh token via `flutter_secure_storage` |
| `UserBloc` + `UserRepository` | Bloc + Repo | Session-wide GraphQL subscription for character state; source of truth for all tabs |
| `AppLifecycleObserver` | Observer | Fires reconnect events on app resume for subscriptions and travel timer |
| `NavigationService` | Service singleton | `GlobalKey<NavigatorState>`-based navigation for push notification routing |
| `NotificationService` | Service | Firebase message routing: killed / background / foreground to tab switch + BLoC event |
| `TravelBloc` + widget-level timer | Bloc + Widget | Server timestamps only in BLoC; `Timer.periodic` in widget for display tick |
| `QuestInfoSheetFactory` + per-type sheets | Widget factory | One file per quest type; shared `BaseCombatQuestInfoSheet` for combat types |
| `CombatResultBloc` + `CombatResultSheet` | Bloc + Widget | Subscription-triggered result; FCM fallback when backgrounded |
| `SpellsBloc` + `SpellsRepository` | Bloc + Repo | Spell list, equip/disequip mutations, optimistic UI with rollback |
| `AdminBloc` + `AdminRepository` | Bloc + Repo | Pending requests, teleport, monster/wound assignment |
| `PreferencesCubit` + `PreferencesRepository` | Cubit + Repo | Notification toggles in shared_preferences; settings screen |

**Anti-patterns that must be avoided:**
- Feature BLoCs opening their own user subscriptions — one `UserBloc` owns the subscription
- `AuthBloc` at feature level — must be at root, above `MultiBlocProvider`
- `Timer.periodic` inside `TravelBloc` — widget owns display tick, BLoC holds server timestamps only
- Passing `BuildContext` into repositories — use `AuthTokenService` and `NavigationService` singletons
- Monolith `QuestInfoSheet` with 10 nested if/switch branches — use factory pattern

### Critical Pitfalls

The full PITFALLS.md documents 35 pitfalls. The five that can cause rewrites, data loss, or game-breaking exploits:

1. **Token storage in SharedPreferences** — The existing `StorageManager` uses `shared_preferences`; the new auth flow must use `SecureStorageService` for all tokens. Grep for `StorageManager.save` calls with token-like keys. Do not accept auth PR without this.

2. **Admin mutations enforced client-side only** — `isAdmin` check in Flutter is UX gating only. Every admin resolver in NestJS must carry `@Roles('admin')` with JWT role verification. A non-admin calling `teleportCharacter` via curl must get 403. Enforce during admin panel phase, not deferred to hardening.

3. **Coin deduction race condition** — User fires shop purchase + quest accept simultaneously with the same balance. Without a MongoDB atomic `findOneAndUpdate` with conditional balance check, both pass and balance goes negative. Backend must implement atomic deduction from day one.

4. **Token refresh race condition** — Two concurrent 401 responses both trigger token refresh independently; the second call uses an invalidated refresh token, causing silent logout. Prevention: `AuthRepository.getValidAccessToken()` must hold a `Mutex` around the refresh call.

5. **Stale data on logout / account switch** — A `LogoutUseCase` must execute in order: revoke Twitch token, clear secure storage, reset GraphQL `InMemoryStore` cache, cancel all subscriptions, close all user-specific Cubits, navigate to sign-in. Missing any step risks data leakage between accounts.

**Additional critical pitfalls per phase:**
- Travel timer device-clock manipulation: client timer is cosmetic only; `confirmArrival` validated server-side against server clock
- Push notification cold-launch permission: never call `requestPermission()` at startup; defer to first travel confirmation dialog
- `NavigationService` GlobalKey crash: defensive null-check + `addPostFrameCallback` guard before any navigation from notification handlers
- Three-way notification tap handling: killed, background, and foreground paths must all route through a single `NotificationRouter`

---

## Implications for Roadmap

### Phase 1: Auth Foundation
**Rationale:** Nothing works without identity. `AuthBloc`-above-`MultiBlocProvider` must be wired in `main.dart` before any feature BLoC can run. `AuthTokenService` must exist before GraphQL headers can carry tokens.
**Delivers:** Twitch PKCE login, refresh token persistence, logout/account-switch, `AuthTokenService` singleton, `AuthLink` injected into `KlimmeckGraphQl`, platform OAuth redirect setup (Android manifest + iOS plist).
**Avoids:** Pitfall 1 (secure storage), Pitfall 2 (refresh race/mutex), Pitfall 3 (logout cleanup), Pitfall 4 (PKCE/code hijacking), Pitfall 30 (no client secrets in app).
**Research flag:** Standard patterns — skip research phase.

### Phase 2: Real-Time User Sync
**Rationale:** `UserBloc` is the session-wide data bus. Quest accept needs live coin balance. Admin panel needs `isAdmin`. Travel needs live travel state. Build before any consumer.
**Delivers:** `UserBloc` + `UserRepository`, character state subscription, `AppLifecycleObserver` for reconnect, full-state refresh query on reconnect.
**Avoids:** Pitfall 5 (subscription not closed on logout), Pitfall 6 (duplicate subscriptions), Pitfall 7 (WebSocket stale after token refresh), Pitfall 8 (missed events on reconnect), Pitfall 27 (rebuild loops), Pitfall 28 (backgrounding kills subscription silently).
**Research flag:** Verify WebSocket `connection_init` auth token contract with NestJS backend before starting.

### Phase 3: Push Notification Infrastructure
**Rationale:** Travel and quest completion are incomplete without background notifications. Can be developed in parallel with Phase 2 since it only depends on Phase 1. Requires Firebase credentials outside the Flutter codebase.
**Delivers:** Firebase init, `NavigationService`, `NotificationService` with killed/background/foreground handlers, Android channels, iOS APNs setup, FCM token registration and refresh.
**Avoids:** Pitfall 11 (cold-launch permission), Pitfall 12 (stale FCM token), Pitfall 13 (three-way tap handling), Pitfall 14 (stale deep link target), Pitfall 33 (duplicate FCM + in-app banner), Pitfall 35 (payload size limit).
**Research flag:** Platform setup is procedural but requires Apple Developer + Firebase Console access. Sequence around credentials availability.

### Phase 4: Settings Screen
**Rationale:** Quick win; closes the auth loop for users and unblocks QA testing of Phase 1. Parallel to Phase 3.
**Delivers:** Settings screen, `PreferencesCubit`, `PreferencesRepository`, logout action via `AuthBloc`.
**Research flag:** Skip — standard patterns.

### Phase 5: Quest Accept Loop
**Rationale:** Core engagement mechanic. Depends on Phase 2 (live coin balance) and Phase 1 (auth for mutation).
**Delivers:** Swipe-left gesture with confirmation bottom sheet, `QuestInfoSheetFactory` with per-type sheets (10 types), `QuestBloc.QuestAccepted` event, haptic feedback, accessibility long-press fallback.
**Avoids:** Pitfall 9 (optimistic divergence — use pessimistic confirm), Pitfall 18 (gesture arena conflict), Pitfall 19 (no undo — confirmation dialog), Pitfall 20 (swipe inaccessible to screen readers).
**Research flag:** Gesture arena disambiguation needs physical device testing before finalising approach.

### Phase 6: Travel System
**Rationale:** Depends on Phase 2 (live travel state), Phase 3 (travel-end push), Phase 5 (quests triggering travel).
**Delivers:** Travel confirmation dialog, `TravelBloc` with server timestamps, countdown widget with widget-level `Timer.periodic`, travel-end notification to map tab, "viaggio annullato" detection when admin teleports mid-travel.
**Avoids:** Pitfall 15 (device-clock manipulation), Pitfall 16 (app killed mid-travel), Pitfall 17 (double-tap confirm), Pitfall 23 (admin teleport vs active travel).
**Research flag:** Confirm `confirmArrival` idempotency contract and `travelId` implementation in NestJS before starting.

### Phase 7: Spells Section
**Rationale:** Self-contained; can be built in parallel with Phase 6. Depends on Phase 2 (live spell ownership and slot state).
**Delivers:** Spells tab in Journal, `SpellsBloc` + `SpellsRepository`, 3-slot tap-based assignment, optimistic UI with rollback, cooldown and uses-remaining display.
**Research flag:** Skip — slot assignment UX is well-established.

### Phase 8: Combat Result Sheet
**Rationale:** Depends on Phase 7 (spells in result), Phase 2 (subscription infrastructure), Phase 3 (FCM for background).
**Delivers:** `CombatResultBloc`, `combatResult` GraphQL subscription, `CombatResultSheet` full-screen overlay with sequential reveal, FCM-triggered fetch for background case, unacknowledged result queue on resume.
**Avoids:** Pitfall 10 (mutation vs subscription race — subscription is source of truth), Pitfall 31 (result arriving during navigation).
**Research flag:** Confirm `combatResult` subscription event contract — full result payload or result ID requiring follow-up query.

### Phase 9: Admin Panel
**Rationale:** Depends on Phase 2 (`isAdmin` flag) and Phase 1 (auth). Built last among features so the streamer has a complete app to administer. Server-side role enforcement is part of this phase, not deferred.
**Delivers:** Conditional 7th admin tab, pending request list with approve/reject, character teleport, monster/grade/wounds assignment, NestJS `@Roles('admin')` enforcement confirmation.
**Avoids:** Pitfall 21 (client-only role check), Pitfall 22 (no audit log), Pitfall 23 (admin action on mid-travel character), Pitfall 34 (bulk actions without confirmation).
**Research flag:** Backend work (role guard + audit log + atomic teleport transaction) must land in the same sprint as Flutter admin panel.

### Phase 10: Hardening
**Rationale:** All features are functionally complete. Full phase for concurrency, security, memory, and accessibility audit. Not a sprint epilogue.
**Delivers:** Concurrent mutation tests (coin race, duplicate travel, dual-device), security audit (secrets in build logs, server admin enforcement verify), memory profiler run, widget rebuild audit, subscription cleanup audit, accessibility review.
**Avoids:** Pitfall 24 (two devices same account), Pitfall 25 (coin race — verify atomic backend), Pitfall 26 (subscription event mid-mutation), Pitfall 29 (memory leaks).
**Research flag:** No new research — audit and test work only.

### Phase Ordering Rationale

- Phases 1–3 form the foundation tier: no feature is completable without all three.
- Phase 4 (Settings) is a fast parallel win that closes the auth loop for QA.
- Phases 5–9 are the feature tier; Phases 6 and 7 can run in parallel after Phases 2 and 3 complete.
- Phase 9 (Admin) goes last among features because it needs real quest and travel data flowing to be meaningful.
- Phase 10 (Hardening) is non-negotiable as a full phase — the concurrency and security issues affect every session and are not edge cases.

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Codebase audit is direct and HIGH; package versions need pub.dev verification before adding |
| Features | HIGH | Derived from existing app requirements; Twitch API specifics MEDIUM from training data |
| Architecture | HIGH | Direct codebase analysis + established BLoC patterns; build order validated through dependency graph |
| Pitfalls | HIGH | All critical pitfalls derive from existing codebase debt (CONCERNS.md) or well-established Flutter/mobile security patterns |

**Overall confidence:** HIGH

### Gaps to Address

- **WebSocket `connection_init` auth contract:** Whether `connection_init` must carry `Authorization: Bearer` is a NestJS backend protocol question. Must be resolved before Phase 2 begins.
- **Package versions:** `flutter_web_auth_2: ^4.0.0` and `flutter_secure_storage: ^9.2.2` are training-data versions (cutoff Aug 2025). Run `flutter pub add flutter_web_auth_2 flutter_secure_storage` to resolve current stable versions.
- **`combatResult` subscription contract:** Whether the event carries the full result or just a result ID requiring a follow-up query affects `CombatResultBloc` design. Confirm with backend before Phase 8.
- **`confirmArrival` idempotency:** Whether the NestJS travel resolver already has `travelId`-based idempotency. Confirm before Phase 6.
- **Firebase credentials:** `google-services.json`, `GoogleService-Info.plist`, and the APNs Auth Key require Apple Developer + Firebase Console access outside the Flutter codebase. Sequence Phase 3 around their availability.

---

## Sources

### Primary (HIGH confidence)
- Direct codebase analysis: `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`, `INTEGRATIONS.md`, `STACK.md`, `CONCERNS.md`, `pubspec.yaml`, `graphql_client_provider.dart`
- Flutter BLoC library documentation — top-level auth pattern, `BlocSelector`, `buildWhen`
- RFC 7636 (PKCE) + RFC 8252 (OAuth 2.0 for Native Apps) — PKCE mobile auth requirements
- Apple Human Interface Guidelines — notification permission timing
- Firebase Cloud Messaging Flutter docs — three-way message handling

### Secondary (MEDIUM confidence)
- Twitch OAuth 2.0 documentation (training data, Aug 2025) — PKCE support, refresh token rotation, 30-day inactivity expiry
- `graphql_flutter` GitHub + community issues — subscription reconnect behaviour, `onDone` callback semantics
- Mobile RPG UX patterns (Fire Emblem Heroes, Fate/GO, Roll20) — combat result full-screen, swipe gesture conventions

### Tertiary (LOW confidence)
- `flutter_web_auth_2` version `^4.0.0` — training data; verify on pub.dev before adding
- `flutter_secure_storage` version `^9.2.2` — training data; verify on pub.dev before adding

---

*Research completed: 2026-04-10*
*Ready for roadmap: yes*
