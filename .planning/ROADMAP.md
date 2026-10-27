# Roadmap: Klimmeck Guide — v1.0 Core Loop

**Created:** 2026-04-10
**Last updated:** 2026-04-14 — split Auth into a Phase 1 dev stub + a full OAuth phase deferred to Phase 11 (pre-hardening); Hardening shifted to Phase 12.
**Milestone:** v1.0 Core Loop
**Granularity:** Standard (12 phases)
**Coverage:** 79/79 v1 requirements mapped

## Phase Ordering Rationale

L'ordine originale del brief è adottato con due deviazioni:

1. **Settings + Notifications sono split** in due fasi adiacenti (erano fuse). Notifications ha preoccupazioni cross-cutting (FCM init, tap routing via `NotificationRouter`, tre app states) la cui scope è molto maggiore di Settings (schermata + `PreferencesCubit`). Mantenere separate permette a Settings di shippare veloce come quick win, mentre Notifications possiede il wiring Firebase non banale. Entrambe precedono Quest/Travel perché queste fasi consumano permission prompts, FCM tokens e tap-routing.
2. **Auth è split in due fasi**: una stub iniziale (Phase 1, "Dev Auth Stub") che fornisce `AuthTokenService` con token e identità hardcoded da `.env` — così le fasi gameplay 2–10 possono essere sviluppate e testate manualmente senza attrito OAuth — e una fase di auth reale (Phase 11, "Auth & Session Bootstrap") che sostituisce l'implementazione concreta dello stub con OAuth PKCE, secure storage, refresh mutex, logout atomico e detection della revoca esterna. La sostituzione è per costruzione trasparente: Phase 11 cambia solo l'implementazione di `AuthTokenService`, non il contratto pubblico né i consumer. Auth reale atterra prima di Hardening (che diventa Phase 12) così Phase 12 può auditare l'auth reale insieme al resto.

Dependency shape:

```
Phase 1 (Dev Auth Stub)       ← foundational; fornisce AuthTokenService stub + identità di test
   |
Phase 2 (Character Creation)  ← needs identity token
   |
Phase 3 (Real-Time Sync)      ← needs identity token; foundation for all reactive features
   |
   +-- Phase 4 (Settings)     ← parallel quick win
   +-- Phase 5 (Notifications)← needs identity + Sync for FCM token sync + in-app banner model
   |
   +-- Phase 6 (Quest Accept) ← needs Sync; needs BE prereq QUEST-04
   +-- Phase 7 (Travel)       ← needs Sync + Notifications; needs BE prereq TRAVEL-01
   +-- Phase 8 (Spells)       ← needs Sync; self-contained, parallelizable with 6/7
   |
Phase 9 (Combat Result)       ← needs Sync + Notifications + Spells
   |
Phase 10 (Admin Panel)        ← needs Sync; built after quests/travel flowing
   |
Phase 11 (Auth & Session)     ← sostituisce l'implementazione di AuthTokenService con OAuth reale
   |
Phase 12 (Hardening)          ← always last; auditing include auth reale
```

## UX Principles (non-phase, cross-cutting)

- **Klimmeck Guide is a videogame.** Phases touching gameplay screens (Sync, Quest, Travel, Spells, Combat) must not introduce app-style chrome: no reconnection banners, no "loading" scaffolding, no status indicators outside Login, Character Creation, Settings, Admin.
- **Accessibility is out of scope for v1.0.** Do not add a11y work to any phase.
- **Brownfield discipline.** The app already has BLoC, GraphQL client, Cloudinary SVG caching, board/journal/library/map/shop/profile tabs, and a partial Spells section. Phases only add what's missing; they verify existing coverage before writing new code.

## Backend Prerequisites

Two v1.0 requirements require a backend schema change **before** the corresponding frontend phase can start:

- **QUEST-04** — `activeStoryQuest` / `activeWorldMissionQuest` fields on `Character` (or `CharacterQuests`). Blocks Phase 6 (Quest Accept).
- **TRAVEL-01** — `status.activeTravel { road, startTime, endTime, duration }` on `Character`. Blocks Phase 7 (Travel).
- **SPELL-05** — `status.spellStates { spell usages recoveries }` on `Character` (BE Phase 9.1, added 2026-10-27). Blocks only the schema-gated final plan of Phase 8 (Spells Section).

Both are tracked inside their respective frontend phases (QUEST-04 in Phase 6, TRAVEL-01 in Phase 7) as **prerequisite callouts**, not as a separate "Phase 0". The frontend phases cannot start until the BE schema, resolvers, and subscription payloads are shipped and visible in the staging environment.

## Phases

- [x] **Phase 1: Dev Auth Stub** — `AuthTokenService` stub con contratto invariante; token, user id, role letti da `.env`. Sblocca tutte le fasi downstream per sviluppo e test manuali senza OAuth reale.
- [x] **Phase 2: Character Creation** — New users reach a creation flow when `currentCharacter == null` and complete it end-to-end into the main tab shell. (completed 2026-10-09)
- [x] **Phase 3: Real-Time Sync Foundation** — Live `User` and `Character` GraphQL subscriptions with silent auto-reconnect and clean teardown on logout. (completed 2026-10-14)
- [x] **Phase 4: Settings Screen** — Settings surface with logout, notification category toggles, persistence, and explicit character deletion (SET-05, added 2026-10-15; BE companion Phase 03.1). (completed 2026-10-18)
- [x] **Phase 5: Notifications Infrastructure** — FCM registration, permission gate (prompt call site wired by Phase 7), three-state push handling, in-app banner dedup, taps → Map tab / Twitch (Android only; iOS deferred). (completed 2026-10-20)
- [x] **Phase 6: Quest Accept & Info Sheets** — Per-type quest info layouts, swipe-left accept gesture with tear-paper artifact, server-driven state label on the standard-lane paper (no countdown, D-15), parallel story/worldMission lanes torn-for-owner. (completed 2026-10-22) (completed 2026-10-22)
- [x] **Phase 7: Travel** — Confirmation surface with server-provided ETA, live position interpolation along `road.coordinates`, restart-safe reconstruction from `activeTravel`. (completed 2026-10-26)
- [ ] **Phase 8: Spells Section (Journal Tab)** — Complete the partial Spells section: owned list, tap equip/disequip into backend-driven slots, usages + recovery display with optimistic rollback.
- [ ] **Phase 9: Combat Result Sheet** — Full-screen combat outcome with HP delta animation, consumables/spells used, injuries, rewards, XP; queued if a flow is active.
- [ ] **Phase 10: Admin Panel (innkeeper)** — Role-gated admin surface: pending story/worldMission queue (filtered by `activeTravel`), teleport, monster/grade/reward selection, injury application.
- [x] **Phase 11: Auth & Session Bootstrap** — Login Twitch mediato dal backend, secure token storage, refresh/logout, `AuthTokenService` reale affiancato allo stub di Phase 1 dietro lo stesso contratto (bypass dev mantenuto finché non arrivano le chiavi Twitch). Plan di aprile superati: ripianificata il 2026-10-06. (completed 2026-10-06)
- [ ] **Phase 12: Hardening** — Intensive bug-fix + security + concurrency audit: token hygiene, logout atomicity, refresh mutex, subscription lifetimes, multi-device identity transitions.

## Phase Details

### Phase 1: Dev Auth Stub
**Goal**: Fornire un `AuthTokenService` stub con la stessa public surface del servizio finale (vedi Phase 11), backed da `.env`. Ogni fase downstream consuma l'auth service reale-per-contratto; Phase 11 atterrerà sostituendo solo l'implementazione.
**Depends on**: Nothing (foundational)
**Scope**: S
**Requirements**: DEV-AUTH-01, DEV-AUTH-02, DEV-AUTH-03, DEV-AUTH-04, DEV-AUTH-05
**Success Criteria** (what must be TRUE):
  1. `AuthTokenService` espone `Stream<AuthState>`, `getAccessToken()`, `login()`, `logout()`, `handleRevocation()` identici al contratto finale di Phase 11.
  2. Al cold start lo stub legge `.env` e emette immediatamente `Authenticated` con il test user; `getAccessToken()` ritorna il token hardcoded.
  3. Cambiare `DEV_AUTH_ROLE` in `.env` (tra `guard`, `adventurer`, `innkeeper`) e rilanciare l'app produce un User con quel role, permettendo il test di fasi role-gated (Admin Panel).
  4. `login()` e `logout()` sono no-op (log di warning in debug builds solamente); nessun sign-in screen viene mostrato in questa fase.
  5. `AuthTokenService` è wire-ato via `RepositoryProvider` sopra il `BlocProvider` tree; il GraphQL client e il `dio` interceptor consumano il token tramite `getAccessToken()` — stesso pattern di Phase 11.
**Decisions to make during discuss step**:
  - Scelta package `.env` (dotenv / flutter_dotenv) — probabilmente `flutter_dotenv`, già uso comune.
  - Naming finale del service class (`AuthTokenService` è il contratto; la concrete stub class può chiamarsi `DevAuthTokenService` e essere la sola registrata quando `DEV_AUTH_ENABLED=true`).
**Plans**: 3 plans
  - [x] 01-01-PLAN.md — Wave 0: install flutter_dotenv + bloc_test + mocktail, register .env asset, scaffold RED test stubs
  - [x] 01-02-PLAN.md — AuthTokenService contract + AuthState sealed + DevAuthTokenService (.env-backed stub) + EnvConfig.devAuthEnabled flag
  - [x] 01-03-PLAN.md — Wiring: RepositoryProvider + dio AuthInterceptor + graphql AuthLink + main.dart dotenv.load
**Replacement**: Phase 11 sostituisce `DevAuthTokenService` con una concrete class OAuth-backed senza cambiare il contratto né i consumer.

### Phase 2: Character Creation
**Goal**: A logged-in user with no character is routed to a single-page character sheet and exits into the main tab shell with a valid `currentCharacter`.
**Depends on**: Phase 1 (requires an authenticated User, stub or real)
**Scope**: M
**Requirements**: CHAR-01, CHAR-02, CHAR-03, CHAR-04, CHAR-05, CHAR-06 (DEFERRED — D-17), CHAR-07, CHAR-08, CHAR-09
**Success Criteria** (what must be TRUE):
  1. When a logged-in user has `currentCharacter == null`, the app routes to the creation flow instead of the main shell.
  2. The user can enter name/sex/pronoun/race/class/age/background and either pick a curated portrait or upload one from gallery/camera. (curated portrait set deferred — D-15; gallery/camera upload ships).
  3. ~~Uploaded images are pre-screened on-device for explicit content and rejected client-side when flagged, with a clear message.~~ **DEFERRED (D-17)** — no NSFW pre-screen in this phase.
  4. On successful submission, `User.currentCharacter` is populated via mutation and the app transitions into the main tab shell.
  5. Server/validation/NSFW rejection errors surface using the existing error-display pattern (shop flow) without losing entered data; back navigation between steps preserves data. (NSFW rejection deferred with CHAR-06; "back navigation" is satisfied by the single page, D-04).
**Decisions to make during discuss step**:
  - Choice of on-device NSFW classifier (Google ML Kit Image Labeling vs TensorFlow Lite NSFW model) and its integration footprint.
  - Onboarding layout is a utility surface (UI chrome allowed).
**Plans**: 11 plans
  - [x] 02-01-PLAN.md — Wave 0: CHAR-06 deferral in docs, image_picker 1.2.2 + native targets (D-31), shared test helpers
  - [x] 02-02-PLAN.md — Session handover: AuthTokenService/AuthCubit.adoptUser + AuthGate rebuild on character gain (D-26)
  - [x] 02-03-PLAN.md — Models (RaceTraits, CreateCharacterRequest, SexType.label) + pure CharacterDraft validation
  - [x] 02-04-PLAN.md — Theme tokens for fields/chips/spacing + CharacterPortrait silhouette resolver (D-14)
  - [x] 02-05-PLAN.md — Fixed Cloudinary upload (D-28) + injectable PortraitPicker (D-30)
  - [x] 02-06-PLAN.md — CreateCharacter/GetRaceTraits documents, error-code mapper, KlimmeckGraphQl methods (D-29)
  - [x] 02-07-PLAN.md — CharacterCreationRepository + cubit editing (traits, fields, portrait)
  - [x] 02-08-PLAN.md — Cubit submit: upload-then-mutation, URL reuse, CHARACTER_ALREADY_EXISTS recovery
  - [x] 02-09-PLAN.md — CharacterCreationScreen: parchment sheet, inline errors, Crea progress, Esci
  - [x] 02-10-PLAN.md — SessionHome branch, real character id into shell/MainScreen (D-27), main.dart wiring
  - [x] 02-11-PLAN.md — Schema check vs BE 02.1 (D-33), validation sign-off, manual E2E checkpoint
**UI hint**: yes

### Phase 3: Real-Time Sync Foundation
**Goal**: Live `User` and `Character` GraphQL subscriptions are established session-wide so that every downstream feature consumes authoritative state reactively, with silent reconnect and clean teardown.
**Depends on**: Phase 1 (needs an auth token for `connection_init`, stub or real), Phase 2 (needs a real `currentCharacter.id` for the Character subscription)
**Scope**: M
**Requirements**: SYNC-01, SYNC-02, SYNC-03, SYNC-04, SYNC-05, SYNC-06, SYNC-07
**Success Criteria** (what must be TRUE):
  1. After login, the User subscription is open and `twitchPoints`/`role`/`currentCharacter` changes emitted by the backend appear live in the UI with no polling.
  2. After the character is known, the Character subscription delivers live updates to `infos`, `status` (including `activeTravel`), `quests` (including `activeStoryQuest` / `activeWorldMissionQuest`), and `assets` (including `activeSpells`).
  3. Network drop or app resume silently reopens both subscriptions and each re-queries its full payload; no reconnection UI is shown to the user.
  4. On logout, on character swap, and on character deletion, both subscriptions are closed cleanly with no leaked streams into the next session/identity.
  5. The WebSocket `connection_init` payload carries the current auth token and is updated after token refresh.
**Decisions to make during discuss step**:
  - GraphQL subscription client choice (`graphql_flutter` already in use vs `ferry`) — open question from STATE.md.
  - Backend contract for `connection_init` auth header (confirm with BE before implementation).
**Notes (Phase 3 decisions)**: SC#2 fields `activeTravel` / `activeStoryQuest` / `activeWorldMissionQuest` are not in the backend schema yet — they join `CharacterFragment` in Phases 6/7 (D-05, fragment-only change). SC#4 "character swap": the admin never reassigns characters (D-08) — the shell is nevertheless keyed by character id. SC#3 re-query happens on resume; on reconnect the backend snapshot-on-subscribe recovers the payload (D-03/D-12). FE PR waits for the BE Phase 3 PR (D-04).
**Plans**: 9 plans

Plans:
- [x] 03-01-PLAN.md — Wave 0: fake graphql-ws server, sync fixtures, schema-check tooling, SYNC-05 wording (D-08)
- [x] 03-02-PLAN.md — Flutter-free sync primitives: SyncHealth/SyncWatchdog (degraded-time clock), lifecycle + user-refresh buses, silentRetry
- [x] 03-03-PLAN.md — GraphQL boundary: OnUserChanged, FORBIDDEN/NOT_FOUND codes, subscribeToUser, typed stream failures
- [x] 03-04-PLAN.md — Session end: UnauthenticatedReason.syncLost, SessionTerminator, "Connessione persa" notice, AuthGate pop on character change (D-10)
- [x] 03-05-PLAN.md — Transport: keep-alive connect, socket monitor, real-socket tests for resubscribe/token rotation/reset
- [x] 03-06-PLAN.md — SessionSyncCubit: single userUpdated consumer, resume/request me refetch, watchdog feeding
- [x] 03-07-PLAN.md — CharacterCubit hardening (silent resubscribe, terminal FORBIDDEN, resume refetch) + shell wiring
- [x] 03-08-PLAN.md — Wiring: SessionSyncScope, shell keyed by character id, AppLifecycleBridge, main.dart
- [x] 03-09-PLAN.md — Cross-repo gate: schema check vs BE schema, validation sign-off, manual E2E, BACKEND-NOTES (checkpoint)

### Phase 4: Settings Screen
**Goal**: User has a settings surface from which to log out and control per-category notification toggles, and those preferences persist across app restarts.
**Depends on**: Phase 1 (logout wiring — in Phase 1 è no-op; Phase 11 sostituirà con logout reale), Phase 3 (not strictly required, but SET shares infra with NOTIF), **BE Phase 03.1 Character Deletion Contract** (`deleteCharacter`; BE PR merges before the FE PR — added 2026-10-15)
**Scope**: S
**Requirements**: SET-01, SET-02, SET-03, SET-04, SET-05
**Success Criteria** (what must be TRUE):
  1. User can reach a Settings screen from the main menu.
  2. User can individually toggle travel-end, streamer-live, and quest-end notification categories.
  3. User can log out from Settings and is returned to sign-in (in Phase 1 stub: no-op + log; con Phase 11 atterrato: logout atomico reale).
  4. Notification preferences survive app kill/restart.
  5. User can delete the current character from Settings after confirming; the app returns to character creation (backend `deleteCharacter`, soft delete, BE Phase 03.1). *(added 2026-10-15, SET-05)*
**Decisions to make during discuss step**:
  - Storage backend for preferences (shared_preferences is acceptable here — these are non-sensitive).
  - Settings is a utility surface (UI chrome allowed).
**Plans**: 7 plans

Plans:
- [x] 04-01-PLAN.md — Satchel menu rework: SatchelLayout table (Mappa 1x2, 2x3 grid, Impostazioni = page 6), MenuBackground/MenuItem/SatchelMenu driven by the table, CloudinaryAssets.settings (real asset)
- [x] 04-02-PLAN.md — Theme tokens (switchTheme, destructive button styles) + shared DestructiveConfirmationDialog extracted from the logout dialog
- [x] 04-03-PLAN.md — Notification preferences: NotificationCategory enum, Flutter-free store on SharedPreferencesAsync keyed per user, NotificationPreferencesCubit (optimistic toggle, revert on failed write)
- [x] 04-04-PLAN.md — Character deletion data path: DeleteCharacter document (+ schema-check listing), KlimmeckGraphQl.deleteCharacter, CharacterDeletionFailure/Repository, CharacterDeletionCubit
- [x] 04-05-PLAN.md — Session wiring: adoptUser accepts currentCharacter null (both services), AuthenticatedShell provides both cubits + hand-over listener, main.dart composition root
- [x] 04-06-PLAN.md — Settings tab UI: Notifiche section (3 themed switches), Account section (Elimina personaggio + Esci via confirmLogout), parchment tab, MainScreen page 6
- [x] 04-07-PLAN.md — Cross-repo gate: schema check vs BE develop schema, phase gates, validation sign-off, manual E2E on device (checkpoint), BACKEND-NOTES, REQUIREMENTS traceability
**UI hint**: yes

### Phase 5: Notifications Infrastructure
**Goal**: The app receives and displays push + in-app notifications for travel end, streamer live, and quest end across all three app states, with permission requested contextually and taps routed uniformly to the Map tab.
**Depends on**: Phase 1 (auth token for FCM token sync), Phase 3 (backend identifies the device/user; in-app banner feeds off the Character subscription where applicable), Phase 4 (respects per-category toggles)
**Scope**: M
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08
**Success Criteria** (what must be TRUE):
  1. After login, the FCM token is registered and synced to the backend per-device; token refresh is handled.
  2. Notification permission is requested in-context at the first travel confirmation, not at cold launch.
  3. Travel-end, streamer-live, and quest-end push notifications are delivered and handled in killed, background, and foreground app states.
  4. Tapping any notification routes the app to the Map tab and surfaces the correct context popup (travel-end, streamer-live, quest-end, death), uniformly across the three app states. _(Amended 2026-10-19 in the Phase 5 discuss: a `streamerLive` tap opens the Twitch channel directly; personal types land on the Map tab and their context popups arrive with Phases 7/9.)_
  5. When an event would trigger both an FCM push and an in-app banner, only one is shown (foreground suppresses the duplicate push); foreground banners use the existing `KGNotification` model.
**Decisions to make during discuss step**:
  - Push library confirmation (`firebase_messaging` + `flutter_local_notifications` — open question from STATE.md).
  - `NotificationRouter` / `NavigationService` GlobalKey pattern.
**Backend/platform prerequisites**:
  - Firebase project configured, `google-services.json` in place locally (not committed). _(Platform note 2026-10-19, user decision: Phase 5 is **Android only**; `GoogleService-Info.plist`, APNs Auth Key and the iOS wiring are deferred to a later phase.)_
  - BE Phase 5 (FCM) merged in BE PR #8 on 2026-10-18.
**Plans**: TBD

### Phase 6: Quest Accept & Info Sheets
**Goal**: Users can view per-type quest details in the info sheet and accept a quest via the swipe-left tear-paper gesture; the accepted standard-lane quest stays on the Map as a paper with a server-driven state label (no countdown, CONTEXT D-15), and story/worldMission quests run in parallel to the standard pendingQuest.
**Depends on**: Phase 3 (live `pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest`, coins, twitchPoints), Phase 1 (authenticated mutation)
**Scope**: L
**Backend prerequisite**: **QUEST-04 is a backend prerequisite.** Character must expose `activeStoryQuest` and `activeWorldMissionQuest` (or equivalent) on the GraphQL schema and emit them via the Character subscription before this phase can start. Frontend work in this phase is blocked until that ships to staging.
**Requirements**: QUEST-01, QUEST-02, QUEST-03, QUEST-04, QUEST-05, QUEST-06, QUEST-07
**Success Criteria** (what must be TRUE):
  1. The `QuestInfoSheet` above the board shows per-type layout variants for `hunt`, `enemy`, `boss`, `dungeon`, `story`, `worldMission`, `heal`, `aid`, `job`, `study` — surfacing the fields relevant to each type.
  2. Swiping left on the `QuestInfoSheet` (not on the board list) with the tear-paper animation + haptic feedback triggers accept; on success the app navigates to the Map tab with the torn quest paper shown on top of the stack.
  3. ~~A quest of type `story` or `worldMission` is hidden from the board as soon as its corresponding active field is populated, without blocking acceptance of other quest types.~~ **Superseded (CONTEXT D-08/D-12):** an accepted `story`/`worldMission` stays on the board torn for its owner; the other lanes stay acceptable.
  4. ~~While `pendingQuest` is populated, the board shows a live countdown driven by `startDate + waitingTime`, anchored to server timestamps (not device clock).~~ **Superseded (CONTEXT D-15):** no countdown; the standard-lane paper on the Map carries a server-driven state label ("In viaggio" while `startDate` is null, a per-type label afterwards).
  5. On acceptance failure (insufficient balance, quest already taken, server error), optimistic state rolls back and the error surfaces via the existing shop-flow error pattern. **Amended (CONTEXT D-04, C3):** the error surface is the Phase 5 in-app banner with copy chosen by `extensions.code`.
**Decisions to make during discuss step**:
  - **QUEST-03 confirmation flow** (open question from STATE.md): dialog with cost preview before swipe? undo window after swipe? cost surface location? Must be resolved during this phase's discuss step.
  - Gesture arena disambiguation (custom `GestureDetector` with drag threshold — NOT `Dismissible`).
  - _Resolved in the Phase 6 discuss (2026-10-21): swipe = confirmation, no dialog, no undo (D-01); cost line for story/worldMission only (D-02); custom `GestureDetector` (D-01/D-06)._
**Plans**: 12 plans
  - [x] 06-01-PLAN.md — Wave 1: REQUIREMENTS/ROADMAP amendments; rank slots, registrations with rank, D-32 capacity, tolerant quest parsing; three lanes in models + fragment; fixtures
  - [x] 06-02-PLAN.md — Wave 2: pure availability layer (lanes, classifier in BE order, board policy, cost line, state label, blocked reasons, title labels)
  - [x] 06-03-PLAN.md — Wave 2: AcceptQuest slice (document, service, failures by extensions.code, repository, QuestAcceptanceCubit, banner copy, shell provider)
  - [x] 06-04-PLAN.md — Wave 1: in-app banner publishNotice for local domain notices (D-20 C1)
  - [x] 06-05-PLAN.md — Wave 1: TearablePaper (pure gesture model, jagged clipper, haptics, spring back, recompose)
  - [x] 06-06-PLAN.md — Wave 3: QuestInfoSheet families (combat/narrative/service) + indicators + cost line via a pure view-model
  - [x] 06-07-PLAN.md — Wave 3: board data (GetCity, interim quest requirements, tolerant getQuests, silent refreshQuests)
  - [x] 06-08-PLAN.md — Wave 3: satchel Board entry disabled outside a city marker
  - [x] 06-09-PLAN.md — Wave 4: Board listing by city/lane/title with deterministic torn papers
  - [x] 06-10-PLAN.md — Wave 5: swipe-to-accept on the Board sheet, Map on success, rollback + banner + refresh on failure
  - [x] 06-11-PLAN.md — Wave 5: Map quest paper with the state label, read-only overlay
  - [x] 06-12-PLAN.md — Wave 6 (BE Phase 8 gated): quests document flip + schema_check vs BE origin/develop + device E2E (checkpoint)
**UI hint**: no (CONTEXT D-19: no UI phase, every visual is provisional and reworked by the user)

### Phase 7: Travel
**Goal**: Users can initiate travel to a POI with an explicit confirmation showing backend-provided ETA, then watch their character move along the road in real time, with accurate reconstruction after an app kill mid-travel.
**Depends on**: Phase 3 (live `activeTravel` in the Character subscription), Phase 5 (travel-end push + in-context permission prompt), Phase 6 (some quests trigger travel)
**Scope**: M
**Backend prerequisite**: **TRAVEL-01 is a backend prerequisite.** Character must expose `status.activeTravel { road, startTime, endTime, duration }` on the GraphQL schema and emit it via the Character subscription before this phase can start. Frontend work in this phase is blocked until that ships to staging.
**Requirements**: TRAVEL-01, TRAVEL-02, TRAVEL-03, TRAVEL-04
**Success Criteria** (what must be TRUE):
  1. Initiating travel to a POI opens an explicit confirmation surface showing destination + ETA exactly as received from the backend (no client-side ETA math) before the mutation fires. **Amended (07-CONTEXT D-01..D-03, C4):** the free travel targets a city marker chosen by dragging the pawn; the parchment sheet shows backend distance, duration and ETA (`serverNow + preview.duration`: arithmetic on server values, no client ETA from distance or speed), no cost.
  2. Once `activeTravel` is populated, the character visibly moves along `road.coordinates`, interpolated from `(now - startTime) / duration` anchored to server timestamps.
  3. When the backend clears `activeTravel` and updates `location`, the UI snaps to the new location via the subscription stream with no frontend-side completion logic.
  4. If the app is killed mid-travel, relaunching reconstructs the travel state from `activeTravel` and the character resumes at the correct interpolated position on the road.
**Decisions to make during discuss step**:
  - **TRAVEL-02 confirmation dialog** (open question from STATE.md): exact dialog content/style, button copy, cost display. Must be resolved during this phase's discuss step.
  - Gameplay surface — NO app-style chrome in the map/travel UI.
  - _Resolved in the Phase 7 discuss (2026-10-24): pawn-drag trigger, parchment sheet with backend distance/duration/ETA, "Parti"/"Resta", no cost (D-01..D-05)._
**Plans**: 11 plans
  - [x] 07-01-PLAN.md — Wave 1: doc amendments (no cost, C3); shared wire→LatLng helper (C1); ActiveTravel/TravelPath/TravelPreview models; `activeTravel` on CharacterStatus and in the fragment; travel fixtures
  - [x] 07-02-PLAN.md — Wave 1: pure route geometry (cumulative length, interpolation, split), server-time progress, Italian duration/distance/ETA strings, drag destination rule (D-02)
  - [x] 07-03-PLAN.md — Wave 1: ServerClockService (serverTime offset, RTT, resync on resume) + fake; TravelFailure by `extensions.code` + banner catalogue (D-14)
  - [x] 07-04-PLAN.md — Wave 2: Board and Shop only on a city marker and never while travelling (D-12); MapFocusCubit + `travelEnd` popup entry (D-15)
  - [x] 07-05-PLAN.md — Wave 2: GetServerTime/GetTravelPreview/StartTravel documents + registry (29 → 32), cities lore image, KlimmeckGraphQl methods, TravelRepository with the permission gate after success (D-05)
  - [x] 07-06-PLAN.md — Wave 2: TravelProgressCubit (route memoised per startTime, 1 s tick on server time, arrival hold, silent refetch requests)
  - [x] 07-07-PLAN.md — Wave 3: TravelCubit (preview → confirm → start), TravelOutcomeListener (banner, settle on activeTravel), shell providers
  - [x] 07-08-PLAN.md — Wave 4: TravelRouteLayer (dashed preview, two-tone live route) + TravelConfirmationSheet (parchment, Parti/Resta) + map test harness
  - [x] 07-09-PLAN.md — Wave 5: WorldMap wiring (progress cubit, route layer, one-shot framing, travelEnd focus, refetch, drag end → preview sheet + camera fit); drop the teleport stub
  - [x] 07-10-PLAN.md — Wave 6: pawn modes (drag only when free, spring back, travelling pawn with the floating remaining-time label, reconstruction after kill)
  - [x] 07-11-PLAN.md — Wave 7: schema_check vs BE origin/develop, phase gates, device E2E (BE handoff §11 d + C1 probe, checkpoint), traceability and BACKEND-NOTES
**UI hint**: no (07-CONTEXT: no UI phase, every visual is provisional and reworked by the user)

### Phase 8: Spells Section (Journal Tab)
**Goal**: The partial Spells section in the Journal tab is completed: users can view owned spells, tap to equip/disequip into backend-driven active slots, and see remaining usages and recovery per active spell, all with optimistic UI and rollback.
**Depends on**: Phase 3 (live `Character.status.spells`, `Character.assets.activeSpells`, `Character.status.maxActiveSpells`), **BE Phase 9.1 Spell State and Recovery Contract** (`CharacterStatus.spellStates { spell usages recoveries }`, additive; the BE PR merges before the FE plan that selects it — added 2026-10-27)
**Scope**: M
**Requirements**: SPELL-01, SPELL-02, SPELL-03, SPELL-04, SPELL-05, SPELL-06, SPELL-07
**Success Criteria** (what must be TRUE):
  1. The Journal tab shows the list of owned spells with `name`, `description`, `maxUsages`, `recoveryTime`, and `energyDamage` summary.
  2. Tapping a spell assigns it to an available active slot (slot count = `maxActiveSpells`, backend-driven); tapping an active slot disequips it; UI updates optimistically and rolls back on backend failure.
  3. Every known spell below its maximum shows the remaining `usages` and a live «prossimo tra X» countdown from `status.spellStates[].recoveries` against server time (static «in recupero» without an instant); the slot card shows the usages only. _(Amended 2026-10-27 after the Phase 8 research, per the SPELL-05 amendment.)_
  4. Slot availability reflects `maxActiveSpells` changes from the subscription (e.g. new slot appearing after a title change) with no frontend slot logic.
**Decisions to make during discuss step**:
  - Audit what the existing partial Spells section already provides vs what must be built.
  - Gameplay surface — NO app-style chrome.
**Backend prerequisite**: BE Phase 9.1 — per-spell state `spellStates { spell usages recoveries }` that outlives equip/disequip (user rule 2026-10-27); proposed in `.planning/phases/08-spells-section-journal-tab/BACKEND-NOTES.md`, fixed in the BE `09.1-CONTEXT.md`. Only the schema-gated final plan waits for it.
**Plans**: 12 plans
  - [x] 08-01-PLAN.md — Wave 1: SpellState + optional spellStates, spell fixtures, shared formatGameDuration
  - [ ] 08-02-PLAN.md — Wave 1: EquipSpell/UnequipSpell (no usages), service, SpellEquipFailure, SpellsRepository
  - [ ] 08-03-PLAN.md — Wave 2: shared BookmarkRibbon + pencil counter, SpellCard bookmark, pending-ink tokens
  - [ ] 08-04-PLAN.md — Wave 2: recovery status on server time + Italian spell lines
  - [ ] 08-05-PLAN.md — Wave 2: pure Spellbook view (slots, fallback, optimistic overlay, intents)
  - [ ] 08-06-PLAN.md — Wave 3: SpellsCubit pending overlay (15 s settle, tokens)
  - [ ] 08-07-PLAN.md — Wave 3: SpellRecoveryCubit countdown ticker
  - [ ] 08-08-PLAN.md — Wave 3: SpellInfo extended + SpellInfoSheet (bookmark toggle)
  - [ ] 08-09-PLAN.md — Wave 3: slot row, known-spell rows, shake, SpellbookContent
  - [ ] 08-10-PLAN.md — Wave 4: spell notices, SpellOutcomeListener, shell provider + MainScreen mount
  - [ ] 08-11-PLAN.md — Wave 5: SpellsSection + Journal wiring + spell sheet, SpellRow removed
  - [ ] 08-12-PLAN.md — Wave 6 (BE 9.1 gated): spellStates fragment, schema_check vs BE origin/develop, device E2E (checkpoint), closure
**UI hint**: yes

### Phase 9: Combat Result Sheet
**Goal**: When a combat resolves, the user sees a full-screen result sheet with HP delta, consumables and spells used, injuries received, rewards, and XP — triggered by subscription in foreground or FCM push in background, and queued safely if a critical flow is active.
**Depends on**: Phase 3 (subscription delivers the result), Phase 5 (FCM fallback for background), Phase 8 (spells must be in place so "spells used" lines resolve correctly)
**Scope**: M
**Requirements**: COMBAT-01, COMBAT-02, COMBAT-03, COMBAT-04, COMBAT-05, COMBAT-06, COMBAT-07
**Success Criteria** (what must be TRUE):
  1. When a combat resolves in foreground, a full-screen result sheet (not a bottom sheet) appears; when in background, an FCM push brings the user into the same result view on tap.
  2. The sheet shows `currentLifePoints` before vs after against `maxLifePoints` with an animated transition.
  3. The sheet lists consumables used, `activeSpells` used, `InjuryType` values received (with human-readable labels), rewards obtained, and XP earned.
  4. The sheet requires an explicit tap to dismiss; swipe-dismiss is disabled.
  5. If a result arrives while the user is navigating or inside a modal, it is queued and presented at a safe moment without interrupting the active flow.
**Decisions to make during discuss step**:
  - Subscription contract: does `combatResult` carry the full payload or a result ID requiring follow-up query? Confirm with backend before implementation.
**Plans**: TBD
**UI hint**: yes

### Phase 10: Admin Panel (innkeeper)
**Goal**: When `User.role == innkeeper`, the streamer has a dedicated admin surface to review and approve/reject pending story/worldMission requests, teleport characters, and assign monsters/grade/rewards/injuries as combat outcomes — with every mutation enforced server-side and audit-logged.
**Depends on**: Phase 1 (auth, stub o reale), Phase 3 (`role` and real-time pending request data), Phase 6 (real quest data flowing), Phase 7 (`activeTravel` filtering)
**Scope**: L
**Requirements**: ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-08
**Success Criteria** (what must be TRUE):
  1. An admin tab/menu is visible only when `role == innkeeper` and is hidden to all other roles.
  2. The innkeeper sees a live queue of pending `story` and `worldMission` requests, filtered to exclude characters whose `activeTravel` is populated (they must be at a POI to be acted on).
  3. The innkeeper can approve or reject each pending request with an explicit confirmation step.
  4. The innkeeper can teleport any character to any POI; the backend atomically overrides `location` and clears any `activeTravel` as part of the same operation, and the frontend reacts via subscription only.
  5. The innkeeper can select enemies/monsters for a POI combat quest, set grade, assign rewards, and apply `InjuryType` values; every admin mutation is confirmed to be rejected server-side when called without `innkeeper` role and every action is audit-logged on the backend.
**Decisions to make during discuss step**:
  - Admin tab placement (7th tab vs menu).
  - Admin is a utility surface (UI chrome allowed).
**Backend prerequisite**:
  - Server-side `@Roles(innkeeper)` guard + audit logging must land in lockstep with the frontend admin panel; this is not deferred to hardening.
**Plans**: TBD
**UI hint**: yes

### Phase 11: Auth & Session Bootstrap
**Goal**: Affiancare al `DevAuthTokenService` di Phase 1 un'implementazione reale basata sulla sessione del backend: login Twitch via system browser mediato dal BE, secure token storage, refresh mutex, logout atomico, detection della revoca di sessione. Il contratto pubblico di `AuthTokenService` è invariato: nessun consumer downstream cambia. Lo stub resta selezionabile (`DEV_AUTH_ENABLED=true`) finché le chiavi Twitch non sono disponibili. _(Emendato 2026-10-06: Twitch non supporta PKCE; vedi 11-CONTEXT.md.)_
**Depends on**: Phase 1 (fornisce il contratto che questa fase soddisfa con l'implementazione reale). Tutte le fasi 2–10 si devono essere integrate con `AuthTokenService` via lo stub, in modo che la sostituzione sia drop-in.
**Scope**: M
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07
**Success Criteria** (what must be TRUE):
  1. A new user can complete the Twitch login via the system browser (backend-mediated, no WebView) and land in the app authenticated. _(Real-device verification pending until the Twitch keys exist; covered by automated tests with fakes meanwhile.)_
  2. After killing and relaunching the app, the previous session resumes without re-prompting for Twitch credentials.
  3. Logging out returns the user to sign-in, and no tokens, GraphQL cache entries, or subscriptions from the previous session survive.
  4. Logging in with a different Twitch account after logout cleanly swaps the identity with no bleed-through from the previous account.
  5. When the backend rejects the session as revoked or expired, the app detects the invalidation and returns the user to sign-in with a clear message.
  6. Passare da `DevAuthTokenService` all'`AuthTokenService` reale (flag `DEV_AUTH_ENABLED`) non richiede modifiche ai consumer (GraphQL client, dio interceptor, AuthCubit, SignInScreen nuovo, AuthGate). Verificato da diff di codice sui file consumer.
  7. Con `DEV_AUTH_ENABLED=true` l'app è interamente utilizzabile senza chiavi Twitch: cold start diretto nel main shell, e dopo un logout il pulsante di login rientra con l'identità dev.
**Decisions to make during discuss step**:
  - OAuth flow choice: `flutter_web_auth_2` + system browser + `klimmeck://auth` deep link vs alternative (open question from STATE.md) — già pre-deciso nei plan esistenti, da confermare.
  - Secure storage wrapper (`flutter_secure_storage` wrapper service shape) — già pre-deciso nei plan esistenti, da confermare.
**Plans**: 11 plans (ripianificati il 2026-10-06 sul login mediato dal backend; esecuzione sequenziale, una wave per plan)
  - [x] 11-01-PLAN.md — Wave 0: dipendenze (flutter_web_auth_2, flutter_secure_storage 10, crypto, fake_async), AGP 8.9.1, manifest Android, .env.example, helper di test
  - [x] 11-02-PLAN.md — Primitive di dominio: AuthSession, LoginChallenge S256, durata JWT, parser callback, browser authenticator, AuthUnauthenticated.reason, UnauthorizedRecovery, AuthStateChannel
  - [x] 11-03-PLAN.md — SessionStore cifrato + documenti GraphQL auth + BackendAuthApi su client dedicato con mapping errori
  - [x] 11-04-PLAN.md — Dev stub: transizioni login/logout/revoca, DEV_AUTH_START_SIGNED_OUT, allineamento via `me`
  - [x] 11-05-PLAN.md — SessionAuthTokenService: bootstrap cold start, refresh single-flight + proattivo, revoca sul refresh, login via browser + ticket
  - [x] 11-06-PLAN.md — SessionAuthTokenService: recoverFromUnauthorized, handleRevocation, logout atomico best-effort
  - [x] 11-07-PLAN.md — AuthAuthLink e AuthInterceptor con retry-once dopo UNAUTHENTICATED/401
  - [x] 11-08-PLAN.md — WsReconnectPolicy (token corrente, 4401/4403) + GraphQLClientHolder + buildGraphQLConnection
  - [x] 11-09-PLAN.md — AuthCubit + SignInCubit/SignInScreen + LogoutConfirmationDialog
  - [x] 11-10-PLAN.md — Splash gate (hint 10 s) + AuthGate + AuthenticatedShell + composition root in main.dart
  - [x] 11-11-PLAN.md — Riallineamento al contratto BE, gate di fase, BACKEND-NOTES.md e UAT pendente

### Phase 12: Hardening
**Goal**: Close v1.0 with an intensive pass on bugs, security, and concurrency so the shipped app survives real users and real streams without leaking state, double-refreshing, or breaking under multi-device pressure.
**Depends on**: All prior phases feature-complete (incluso Phase 11 che rimpiazza lo stub con auth reale)
**Scope**: L
**Requirements**: HARDEN-01, HARDEN-02, HARDEN-03, HARDEN-04, HARDEN-05, HARDEN-06
**Success Criteria** (what must be TRUE):
  1. An audit (code review + automated grep in CI) confirms no access or refresh token is ever written to shared_preferences, logs, or any unencrypted disk path.
  2. Integration tests confirm every admin endpoint returns 403 when called with a non-innkeeper JWT.
  3. An automated test demonstrates that logout is atomic end-to-end: Twitch token revoked, secure storage cleared, GraphQL cache reset, subscriptions cancelled, cubits reset, navigation to sign-in — all verified in a single flow.
  4. A concurrency test confirms that two simultaneous 401 responses produce exactly one refresh call (mutex-guarded), with no silent logout.
  5. A memory profiler run after logout shows no retained subscriptions or owning blocs; a dual-device test (same Twitch account on two devices) shows graceful identity/subscription conflict handling with no state corruption on the client.
  6. Audit aggiuntivo: nessun riferimento residuo a `DevAuthTokenService` / `DEV_AUTH_*` nel codice di produzione; il flag `DEV_AUTH_ENABLED` in `.env` è rimosso dai build release.
**Decisions to make during discuss step**:
  - Concrete test harness(es) for memory profiling and dual-device simulation.
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Dev Auth Stub | 3/3 | Complete | 2026-04-15 |
| 2. Character Creation | 11/11 | Complete    | 2026-10-09 |
| 3. Real-Time Sync Foundation | 9/9 | Complete    | 2026-10-14 |
| 4. Settings Screen | 7/7 | Complete    | 2026-10-18 |
| 5. Notifications Infrastructure | 9/9 | Complete    | 2026-10-20 |
| 6. Quest Accept & Info Sheets | 12/12 | Complete    | 2026-10-22 |
| 7. Travel | 11/11 | Complete | 2026-10-26 |
| 8. Spells Section (Journal Tab) | 1/12 | In Progress | - |
| 9. Combat Result Sheet | 0/0 | Not started | - |
| 10. Admin Panel (innkeeper) | 0/0 | Not started | - |
| 11. Auth & Session Bootstrap | 11/11 | Complete    | 2026-10-06 |
| 12. Hardening | 0/0 | Not started | - |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| DEV-AUTH-01 | Phase 1 | Pending |
| DEV-AUTH-02 | Phase 1 | Pending |
| DEV-AUTH-03 | Phase 1 | Pending |
| DEV-AUTH-04 | Phase 1 | Pending |
| DEV-AUTH-05 | Phase 1 | Pending |
| CHAR-01 | Phase 2 | Pending |
| CHAR-02 | Phase 2 | Pending |
| CHAR-03 | Phase 2 | Pending |
| CHAR-04 | Phase 2 | Pending |
| CHAR-05 | Phase 2 | Pending |
| CHAR-06 | Phase 2 | Deferred (D-17) |
| CHAR-07 | Phase 2 | Pending |
| CHAR-08 | Phase 2 | Pending |
| CHAR-09 | Phase 2 | Pending |
| SYNC-01 | Phase 3 | Pending |
| SYNC-02 | Phase 3 | Pending |
| SYNC-03 | Phase 3 | Pending |
| SYNC-04 | Phase 3 | Pending |
| SYNC-05 | Phase 3 | Pending |
| SYNC-06 | Phase 3 | Pending |
| SYNC-07 | Phase 3 | Pending |
| SET-01 | Phase 4 | Complete |
| SET-02 | Phase 4 | Complete |
| SET-03 | Phase 4 | Complete |
| SET-04 | Phase 4 | Complete |
| SET-05 | Phase 4 | Complete |
| NOTIF-01 | Phase 5 | Pending |
| NOTIF-02 | Phase 5 | Pending |
| NOTIF-03 | Phase 5 | Pending |
| NOTIF-04 | Phase 5 | Pending |
| NOTIF-05 | Phase 5 | Pending |
| NOTIF-06 | Phase 5 | Pending |
| NOTIF-07 | Phase 5 | Pending |
| NOTIF-08 | Phase 5 | Pending |
| QUEST-01 | Phase 6 | Pending |
| QUEST-02 | Phase 6 | Pending |
| QUEST-03 | Phase 6 | Pending |
| QUEST-04 | Phase 6 (BE prereq) | Pending |
| QUEST-05 | Phase 6 | Pending |
| QUEST-06 | Phase 6 | Pending |
| QUEST-07 | Phase 6 | Pending |
| TRAVEL-01 | Phase 7 (BE prereq) | Complete |
| TRAVEL-02 | Phase 7 | Complete |
| TRAVEL-03 | Phase 7 | Complete |
| TRAVEL-04 | Phase 7 | Complete |
| SPELL-01 | Phase 8 | Pending |
| SPELL-02 | Phase 8 | Pending |
| SPELL-03 | Phase 8 | Pending |
| SPELL-04 | Phase 8 | Pending |
| SPELL-05 | Phase 8 | Pending |
| SPELL-06 | Phase 8 | Pending |
| SPELL-07 | Phase 8 | Pending |
| COMBAT-01 | Phase 9 | Pending |
| COMBAT-02 | Phase 9 | Pending |
| COMBAT-03 | Phase 9 | Pending |
| COMBAT-04 | Phase 9 | Pending |
| COMBAT-05 | Phase 9 | Pending |
| COMBAT-06 | Phase 9 | Pending |
| COMBAT-07 | Phase 9 | Pending |
| ADMIN-01 | Phase 10 | Pending |
| ADMIN-02 | Phase 10 | Pending |
| ADMIN-03 | Phase 10 | Pending |
| ADMIN-04 | Phase 10 | Pending |
| ADMIN-05 | Phase 10 | Pending |
| ADMIN-06 | Phase 10 | Pending |
| ADMIN-07 | Phase 10 | Pending |
| ADMIN-08 | Phase 10 | Pending |
| AUTH-01 | Phase 11 | Pending |
| AUTH-02 | Phase 11 | Pending |
| AUTH-03 | Phase 11 | Pending |
| AUTH-04 | Phase 11 | Pending |
| AUTH-05 | Phase 11 | Pending |
| AUTH-06 | Phase 11 | Pending |
| AUTH-07 | Phase 11 | Pending |
| HARDEN-01 | Phase 12 | Pending |
| HARDEN-02 | Phase 12 | Pending |
| HARDEN-03 | Phase 12 | Pending |
| HARDEN-04 | Phase 12 | Pending |
| HARDEN-05 | Phase 12 | Pending |
| HARDEN-06 | Phase 12 | Pending |

**Coverage:** 79 / 79 v1 requirements mapped. No orphans. No duplicates.

---

_Roadmap created: 2026-04-10_
_Last restructured: 2026-04-14 — Auth split in Phase 1 (Dev Auth Stub) + Phase 11 (full OAuth); Hardening shifted to Phase 12_
