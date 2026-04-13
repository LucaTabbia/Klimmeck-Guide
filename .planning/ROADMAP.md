# Roadmap: Klimmeck Guide — v1.0 Core Loop

**Created:** 2026-04-10
**Milestone:** v1.0 Core Loop
**Granularity:** Standard (10 phases)
**Coverage:** 74/74 v1 requirements mapped

## Phase Ordering Rationale

The suggested ordering from the project brief is adopted with one minor deviation: **Settings + Notifications infra are split into two adjacent phases** rather than fused into one. Notifications (NOTIF) have cross-cutting runtime concerns (FCM init, tap routing via `NotificationRouter`, three-app-states handling) whose scope is substantially larger than Settings (a simple screen + `PreferencesCubit`). Keeping them separate lets the Settings phase ship fast as a parallel QA unblocker, while the Notifications phase owns the non-trivial Firebase wiring. Both still precede Quest/Travel, since those phases consume permission prompts, FCM tokens, and tap-routing surfaces.

Dependency shape:

```
Phase 1 (Auth)
   |
Phase 2 (Character Creation)     ← needs Auth
   |
Phase 3 (Real-Time Sync)         ← needs Auth; foundation for all reactive features
   |
   +-- Phase 4 (Settings)        ← parallel quick win
   +-- Phase 5 (Notifications)   ← needs Auth + Sync for FCM token sync + in-app banner model
   |
   +-- Phase 6 (Quest Accept)    ← needs Sync; needs BE prereq QUEST-04
   +-- Phase 7 (Travel)          ← needs Sync + Notifications; needs BE prereq TRAVEL-01
   +-- Phase 8 (Spells)          ← needs Sync; self-contained, parallelizable with 6/7
   |
Phase 9 (Combat Result)          ← needs Sync + Notifications + Spells (for spell list in payload)
   |
Phase 10 (Admin Panel)           ← needs Sync; built after quests/travel are flowing
   |
Phase 11 (Hardening)             ← always last
```

## UX Principles (non-phase, cross-cutting)

- **Klimmeck Guide is a videogame.** Phases touching gameplay screens (Sync, Quest, Travel, Spells, Combat) must not introduce app-style chrome: no reconnection banners, no "loading" scaffolding, no status indicators outside Login, Character Creation, Settings, Admin.
- **Accessibility is out of scope for v1.0.** Do not add a11y work to any phase.
- **Brownfield discipline.** The app already has BLoC, GraphQL client, Cloudinary SVG caching, board/journal/library/map/shop/profile tabs, and a partial Spells section. Phases only add what's missing; they verify existing coverage before writing new code.

## Backend Prerequisites

Two v1.0 requirements require a backend schema change **before** the corresponding frontend phase can start:

- **QUEST-04** — `activeStoryQuest` / `activeWorldMissionQuest` fields on `Character` (or `CharacterQuests`). Blocks Phase 6 (Quest Accept).
- **TRAVEL-01** — `status.activeTravel { road, startTime, endTime, duration }` on `Character`. Blocks Phase 7 (Travel).

Both are tracked inside their respective frontend phases (QUEST-04 in Phase 6, TRAVEL-01 in Phase 7) as **prerequisite callouts**, not as a separate "Phase 0". The frontend phases cannot start until the BE schema, resolvers, and subscription payloads are shipped and visible in the staging environment.

## Phases

- [ ] **Phase 1: Auth & Session Bootstrap** — Twitch OAuth identity, secure token storage, refresh/logout, and `AuthTokenService` wired above the BLoC tree.
- [ ] **Phase 2: Character Creation** — New users reach a creation flow when `currentCharacter == null` and complete it end-to-end into the main tab shell.
- [ ] **Phase 3: Real-Time Sync Foundation** — Live `User` and `Character` GraphQL subscriptions with silent auto-reconnect and clean teardown on logout.
- [ ] **Phase 4: Settings Screen** — Settings surface with logout, notification category toggles, and persistence.
- [ ] **Phase 5: Notifications Infrastructure** — FCM registration, permission gated at first travel confirm, three-state push handling, in-app banner dedup, uniform tap routing to Map.
- [ ] **Phase 6: Quest Accept & Info Sheets** — Per-type quest info layouts, swipe-left accept gesture with tear-paper artifact, live countdown on `pendingQuest`, parallel story/worldMission lanes.
- [ ] **Phase 7: Travel** — Confirmation surface with server-provided ETA, live position interpolation along `road.coordinates`, restart-safe reconstruction from `activeTravel`.
- [ ] **Phase 8: Spells Section (Journal Tab)** — Complete the partial Spells section: owned list, tap equip/disequip into backend-driven slots, usages + recovery display with optimistic rollback.
- [ ] **Phase 9: Combat Result Sheet** — Full-screen combat outcome with HP delta animation, consumables/spells used, injuries, rewards, XP; queued if a flow is active.
- [ ] **Phase 10: Admin Panel (innkeeper)** — Role-gated admin surface: pending story/worldMission queue (filtered by `activeTravel`), teleport, monster/grade/reward selection, injury application.
- [ ] **Phase 11: Hardening** — Intensive bug-fix + security + concurrency audit: token hygiene, logout atomicity, refresh mutex, subscription lifetimes, multi-device identity transitions.

## Phase Details

### Phase 1: Auth & Session Bootstrap
**Goal**: User can log in with their Twitch account, the session persists safely across restarts, and logout fully tears down state. Identity becomes available to every downstream phase.
**Depends on**: Nothing (foundational)
**Scope**: M
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06, AUTH-07
**Success Criteria** (what must be TRUE):
  1. A new user can complete Twitch OAuth via the system browser (PKCE, no WebView) and land in the app authenticated.
  2. After killing and relaunching the app, the previous session resumes without re-prompting for Twitch credentials.
  3. Logging out returns the user to sign-in, and no tokens, GraphQL cache entries, or subscriptions from the previous session survive.
  4. Logging in with a different Twitch account after logout cleanly swaps the identity with no bleed-through from the previous account.
  5. If the user revokes the app externally on Twitch, the next authenticated request detects the invalidation and returns the user to sign-in with a clear message.
**Decisions to make during discuss step**:
  - OAuth flow choice: `flutter_web_auth_2` + system browser + `klimmeck://auth` deep link vs alternative (open question from STATE.md).
  - Secure storage wrapper (`flutter_secure_storage` wrapper service shape).
**Plans**: 5 plans
  - [ ] 01-01-PLAN.md — Wave 0: dependencies + platform manifests + TDD scaffolding
  - [ ] 01-02-PLAN.md — AuthTokenService core (SecureStorage, PKCE, TwitchApi, refresh mutex, bootstrap/login/logout)
  - [ ] 01-03-PLAN.md — GraphqlClientProvider auth-aware + AuthDioInterceptor (401 refresh retry, client recreate)
  - [ ] 01-04-PLAN.md — AuthCubit + SignInCubit + LogoutConfirmationDialog
  - [ ] 01-05-PLAN.md — main.dart restructure + SplashCubit gate + SignInScreen + AuthGate + BACKEND-NOTES + manual E2E checkpoint

### Phase 2: Character Creation
**Goal**: A logged-in user with no character is routed into a multi-step creation flow and exits into the main tab shell with a valid `currentCharacter`.
**Depends on**: Phase 1 (requires an authenticated User)
**Scope**: M
**Requirements**: CHAR-01, CHAR-02, CHAR-03, CHAR-04, CHAR-05, CHAR-06, CHAR-07, CHAR-08, CHAR-09
**Success Criteria** (what must be TRUE):
  1. When a logged-in user has `currentCharacter == null`, the app routes to the creation flow instead of the main shell.
  2. The user can enter name/sex/pronoun/race/class/age/background and either pick a curated portrait or upload one from gallery/camera.
  3. Uploaded images are pre-screened on-device for explicit content and rejected client-side when flagged, with a clear message.
  4. On successful submission, `User.currentCharacter` is populated via mutation and the app transitions into the main tab shell.
  5. Server/validation/NSFW rejection errors surface using the existing error-display pattern (shop flow) without losing entered data; back navigation between steps preserves data.
**Decisions to make during discuss step**:
  - Choice of on-device NSFW classifier (Google ML Kit Image Labeling vs TensorFlow Lite NSFW model) and its integration footprint.
  - Onboarding layout is a utility surface (UI chrome allowed).
**Plans**: TBD
**UI hint**: yes

### Phase 3: Real-Time Sync Foundation
**Goal**: Live `User` and `Character` GraphQL subscriptions are established session-wide so that every downstream feature consumes authoritative state reactively, with silent reconnect and clean teardown.
**Depends on**: Phase 1 (needs authenticated token for `connection_init`), Phase 2 (needs a real `currentCharacter.id` for the Character subscription)
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
**Plans**: TBD

### Phase 4: Settings Screen
**Goal**: User has a settings surface from which to log out and control per-category notification toggles, and those preferences persist across app restarts.
**Depends on**: Phase 1 (logout wiring), Phase 3 (not strictly required, but SET shares infra with NOTIF)
**Scope**: S
**Requirements**: SET-01, SET-02, SET-03, SET-04
**Success Criteria** (what must be TRUE):
  1. User can reach a Settings screen from the main menu.
  2. User can individually toggle travel-end, streamer-live, and quest-end notification categories.
  3. User can log out from Settings and is returned to sign-in (delegates to the Phase 1 atomic logout path).
  4. Notification preferences survive app kill/restart.
**Decisions to make during discuss step**:
  - Storage backend for preferences (shared_preferences is acceptable here — these are non-sensitive).
  - Settings is a utility surface (UI chrome allowed).
**Plans**: TBD
**UI hint**: yes

### Phase 5: Notifications Infrastructure
**Goal**: The app receives and displays push + in-app notifications for travel end, streamer live, and quest end across all three app states, with permission requested contextually and taps routed uniformly to the Map tab.
**Depends on**: Phase 1 (auth for FCM token sync), Phase 3 (backend identifies the device/user; in-app banner feeds off the Character subscription where applicable), Phase 4 (respects per-category toggles)
**Scope**: M
**Requirements**: NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08
**Success Criteria** (what must be TRUE):
  1. After login, the FCM token is registered and synced to the backend per-device; token refresh is handled.
  2. Notification permission is requested in-context at the first travel confirmation, not at cold launch.
  3. Travel-end, streamer-live, and quest-end push notifications are delivered and handled in killed, background, and foreground app states.
  4. Tapping any notification routes the app to the Map tab and surfaces the correct context popup (travel-end, streamer-live, quest-end, death), uniformly across the three app states.
  5. When an event would trigger both an FCM push and an in-app banner, only one is shown (foreground suppresses the duplicate push); foreground banners use the existing `KGNotification` model.
**Decisions to make during discuss step**:
  - Push library confirmation (`firebase_messaging` + `flutter_local_notifications` — open question from STATE.md).
  - `NotificationRouter` / `NavigationService` GlobalKey pattern.
**Backend/platform prerequisites**:
  - Firebase project configured, `google-services.json` / `GoogleService-Info.plist` in place, APNs Auth Key uploaded.
**Plans**: TBD

### Phase 6: Quest Accept & Info Sheets
**Goal**: Users can view per-type quest details in the info sheet and accept a quest via the swipe-left tear-paper gesture; accepted quests show a live server-anchored countdown, and story/worldMission quests run in parallel to the standard pendingQuest.
**Depends on**: Phase 3 (live `pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest`, coins, twitchPoints), Phase 1 (authenticated mutation)
**Scope**: L
**Backend prerequisite**: **QUEST-04 is a backend prerequisite.** Character must expose `activeStoryQuest` and `activeWorldMissionQuest` (or equivalent) on the GraphQL schema and emit them via the Character subscription before this phase can start. Frontend work in this phase is blocked until that ships to staging.
**Requirements**: QUEST-01, QUEST-02, QUEST-03, QUEST-04, QUEST-05, QUEST-06, QUEST-07
**Success Criteria** (what must be TRUE):
  1. The `QuestInfoSheet` above the board shows per-type layout variants for `hunt`, `enemy`, `boss`, `dungeon`, `story`, `worldMission`, `heal`, `aid`, `job`, `study` — surfacing the fields relevant to each type.
  2. Swiping left on the `QuestInfoSheet` (not on the board list) with the tear-paper animation + haptic feedback triggers accept; on success the app navigates to the Map tab with the torn quest paper shown on top of the stack.
  3. A quest of type `story` or `worldMission` is hidden from the board as soon as its corresponding active field is populated, without blocking acceptance of other quest types.
  4. While `pendingQuest` is populated, the board shows a live countdown driven by `startDate + waitingTime`, anchored to server timestamps (not device clock).
  5. On acceptance failure (insufficient balance, quest already taken, server error), optimistic state rolls back and the error surfaces via the existing shop-flow error pattern.
**Decisions to make during discuss step**:
  - **QUEST-03 confirmation flow** (open question from STATE.md): dialog with cost preview before swipe? undo window after swipe? cost surface location? Must be resolved during this phase's discuss step.
  - Gesture arena disambiguation (custom `GestureDetector` with drag threshold — NOT `Dismissible`).
**Plans**: TBD
**UI hint**: yes

### Phase 7: Travel
**Goal**: Users can initiate travel to a POI with an explicit confirmation showing backend-provided ETA, then watch their character move along the road in real time, with accurate reconstruction after an app kill mid-travel.
**Depends on**: Phase 3 (live `activeTravel` in the Character subscription), Phase 5 (travel-end push + in-context permission prompt), Phase 6 (some quests trigger travel)
**Scope**: M
**Backend prerequisite**: **TRAVEL-01 is a backend prerequisite.** Character must expose `status.activeTravel { road, startTime, endTime, duration }` on the GraphQL schema and emit it via the Character subscription before this phase can start. Frontend work in this phase is blocked until that ships to staging.
**Requirements**: TRAVEL-01, TRAVEL-02, TRAVEL-03, TRAVEL-04
**Success Criteria** (what must be TRUE):
  1. Initiating travel to a POI opens an explicit confirmation surface showing destination + ETA exactly as received from the backend (no client-side ETA math) before the mutation fires.
  2. Once `activeTravel` is populated, the character visibly moves along `road.coordinates`, interpolated from `(now - startTime) / duration` anchored to server timestamps.
  3. When the backend clears `activeTravel` and updates `location`, the UI snaps to the new location via the subscription stream with no frontend-side completion logic.
  4. If the app is killed mid-travel, relaunching reconstructs the travel state from `activeTravel` and the character resumes at the correct interpolated position on the road.
**Decisions to make during discuss step**:
  - **TRAVEL-02 confirmation dialog** (open question from STATE.md): exact dialog content/style, button copy, cost display. Must be resolved during this phase's discuss step.
  - Gameplay surface — NO app-style chrome in the map/travel UI.
**Plans**: TBD
**UI hint**: yes

### Phase 8: Spells Section (Journal Tab)
**Goal**: The partial Spells section in the Journal tab is completed: users can view owned spells, tap to equip/disequip into backend-driven active slots, and see remaining usages and recovery per active spell, all with optimistic UI and rollback.
**Depends on**: Phase 3 (live `Character.status.spells`, `Character.assets.activeSpells`, `Character.status.maxActiveSpells`)
**Scope**: M
**Requirements**: SPELL-01, SPELL-02, SPELL-03, SPELL-04, SPELL-05, SPELL-06, SPELL-07
**Success Criteria** (what must be TRUE):
  1. The Journal tab shows the list of owned spells with `name`, `description`, `maxUsages`, `recoveryTime`, and `energyDamage` summary.
  2. Tapping a spell assigns it to an available active slot (slot count = `maxActiveSpells`, backend-driven); tapping an active slot disequips it; UI updates optimistically and rolls back on backend failure.
  3. Each `ActiveSpell` shows remaining `usages` and, where applicable, a recovery indicator derived from `spell.recoveryTime`.
  4. Slot availability reflects `maxActiveSpells` changes from the subscription (e.g. new slot appearing after a title change) with no frontend slot logic.
**Decisions to make during discuss step**:
  - Audit what the existing partial Spells section already provides vs what must be built.
  - Gameplay surface — NO app-style chrome.
**Plans**: TBD
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
**Depends on**: Phase 1 (auth), Phase 3 (`role` and real-time pending request data), Phase 6 (real quest data flowing), Phase 7 (`activeTravel` filtering)
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

### Phase 11: Hardening
**Goal**: Close v1.0 with an intensive pass on bugs, security, and concurrency so the shipped app survives real users and real streams without leaking state, double-refreshing, or breaking under multi-device pressure.
**Depends on**: All prior phases feature-complete
**Scope**: L
**Requirements**: HARDEN-01, HARDEN-02, HARDEN-03, HARDEN-04, HARDEN-05, HARDEN-06
**Success Criteria** (what must be TRUE):
  1. An audit (code review + automated grep in CI) confirms no access or refresh token is ever written to shared_preferences, logs, or any unencrypted disk path.
  2. Integration tests confirm every admin endpoint returns 403 when called with a non-innkeeper JWT.
  3. An automated test demonstrates that logout is atomic end-to-end: Twitch token revoked, secure storage cleared, GraphQL cache reset, subscriptions cancelled, cubits reset, navigation to sign-in — all verified in a single flow.
  4. A concurrency test confirms that two simultaneous 401 responses produce exactly one refresh call (mutex-guarded), with no silent logout.
  5. A memory profiler run after logout shows no retained subscriptions or owning blocs; a dual-device test (same Twitch account on two devices) shows graceful identity/subscription conflict handling with no state corruption on the client.
**Decisions to make during discuss step**:
  - Concrete test harness(es) for memory profiling and dual-device simulation.
**Plans**: TBD

## Progress Table

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Auth & Session Bootstrap | 0/5 | Planned | - |
| 2. Character Creation | 0/0 | Not started | - |
| 3. Real-Time Sync Foundation | 0/0 | Not started | - |
| 4. Settings Screen | 0/0 | Not started | - |
| 5. Notifications Infrastructure | 0/0 | Not started | - |
| 6. Quest Accept & Info Sheets | 0/0 | Not started | - |
| 7. Travel | 0/0 | Not started | - |
| 8. Spells Section (Journal Tab) | 0/0 | Not started | - |
| 9. Combat Result Sheet | 0/0 | Not started | - |
| 10. Admin Panel (innkeeper) | 0/0 | Not started | - |
| 11. Hardening | 0/0 | Not started | - |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 1 | Pending |
| AUTH-04 | Phase 1 | Pending |
| AUTH-05 | Phase 1 | Pending |
| AUTH-06 | Phase 1 | Pending |
| AUTH-07 | Phase 1 | Pending |
| CHAR-01 | Phase 2 | Pending |
| CHAR-02 | Phase 2 | Pending |
| CHAR-03 | Phase 2 | Pending |
| CHAR-04 | Phase 2 | Pending |
| CHAR-05 | Phase 2 | Pending |
| CHAR-06 | Phase 2 | Pending |
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
| SET-01 | Phase 4 | Pending |
| SET-02 | Phase 4 | Pending |
| SET-03 | Phase 4 | Pending |
| SET-04 | Phase 4 | Pending |
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
| TRAVEL-01 | Phase 7 (BE prereq) | Pending |
| TRAVEL-02 | Phase 7 | Pending |
| TRAVEL-03 | Phase 7 | Pending |
| TRAVEL-04 | Phase 7 | Pending |
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
| HARDEN-01 | Phase 11 | Pending |
| HARDEN-02 | Phase 11 | Pending |
| HARDEN-03 | Phase 11 | Pending |
| HARDEN-04 | Phase 11 | Pending |
| HARDEN-05 | Phase 11 | Pending |
| HARDEN-06 | Phase 11 | Pending |

**Coverage:** 74 / 74 v1 requirements mapped. No orphans. No duplicates.

---

_Roadmap created: 2026-04-10_
