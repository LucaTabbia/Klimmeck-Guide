# Requirements: Klimmeck Guide — v1.0 Core Loop

**Defined:** 2026-04-10
**Core Value:** I viewer trasformano il tempo speso a guardare lo stream in progressione di un personaggio RPG persistente, con un loop di gioco che funziona sia durante che fuori dalle live.

## Domain Model Reference

Questi requirements si riferiscono ai modelli esistenti in `lib/models/`:

- **`User`** = identità (`id`, `twitchId`, `twitchPoints: int`, `role: RoleType`, `currentCharacter: Character?`). `User.twitchPoints` è il saldo punti canale Twitch, aggiornato lato backend via Twitch API. `role == innkeeper` identifica l'admin/streamer.
- **`Character`** = entità giocabile (`id`, `infos`, `status`, `quests`, `assets`). Può essere `null` su User finché non viene creato.
- **`CharacterInfos`** = aspetto + narrativa (`sex`, `name`, `pronoun`, `race`, `classType`, `age`, `background`, `imagePath`).
- **`CharacterStatus`** = `location: PointOfInterest`, `xp`, `level`, `title: TitleType`, `injuries: List<InjuryType>`, `spells: List<Spell>` (posseduti), `coins: Coins` (gold/silver/copper), `currentLifePoints`, `maxLifePoints`, `maxActiveSpells`.
- **`CharacterQuests`** = `completedQuests: List<Quest>`, `pendingQuest: PendingQuest?` (singolo). `PendingQuest` ha `startDate + waitingTime + quest`. V1.0 richiede anche di aggiungere sul Character (o su `CharacterQuests`) due campi opzionali indipendenti — ad es. `activeStoryQuest: PendingQuest?` e `activeWorldMissionQuest: PendingQuest?` — perché le quest `story` e `worldMission` possono girare in parallelo al `pendingQuest` normale.
- **`CharacterAssets`** = `wearedEquipment`, `ownedEquipments`, `ownedItems`, `activeSpells: List<ActiveSpell>`, `pet`. `ActiveSpell { spell, usages }` rappresenta uno slot magia equipaggiato con i suoi utilizzi residui.
- **`QuestType`** enum 12 valori: `hunt`, `aid`, `enemy`, `worldMission`, `boss`, `dungeon`, `story`, `study`, `heal`, `job`, `crime`, `guard`.
- **`RoleType`** enum = `{guard, adventurer, innkeeper}`. L'`innkeeper` è lo streamer/admin.
- **`TitleType`** enum = `{rookie, adventurer, paladin, mage, hero, legend}`.
- **`Road`** (backend, `{id, coordinates: [[lat,lng]], length, speedFactor}`) rappresenta una strada percorribile. V1.0 richiede l'aggiunta di un nuovo campo opzionale su Character — ad es. `status.activeTravel { road, startTime, endTime, duration }` — che tracci un viaggio in corso. Il frontend calcola la posizione lungo `road.coordinates` in funzione di `(now - startTime) / duration`; ETA, durata e validazione temporale sono interamente responsabilità del backend.

## UX Principles

- **Klimmeck Guide è un videogioco, non un'app utility.** Niente indicatori di stato app-style, niente banner "reconnecting", niente pulsanti di sistema nei gameplay screens. Gli unici surface dove è ammesso UI chrome convenzionale sono: Login/OAuth, Character Creation, Settings, Admin (innkeeper).
- **Accessibilità:** esplicitamente fuori scope per v1.0. Sarà rivalutata in una milestone successiva.

## v1 Requirements

### Dev Auth Stub (Phase 1 — sostituita da Phase 11)

Scopo: sbloccare test manuali di tutte le fasi gameplay senza attrito OAuth. Phase 11 sostituisce l'implementazione concreta mantenendo invariato il contratto.

- [ ] **DEV-AUTH-01**: `AuthTokenService` stub espone la stessa public surface del servizio finale — `Stream<AuthState>`, `Future<String?> getAccessToken()`, `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()`
- [ ] **DEV-AUTH-02**: Lo stub legge identità e token da `.env` (`DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`); niente secure storage, niente OAuth
- [ ] **DEV-AUTH-03**: Lo stub supporta role switching via `DEV_AUTH_ROLE` (`guard | adventurer | innkeeper`) per abilitare test di fasi role-gated (Admin Panel)
- [ ] **DEV-AUTH-04**: `login()` e `logout()` sono no-op (warning log in debug builds only); nessun sign-in screen viene costruito in questa fase
- [ ] **DEV-AUTH-05**: `AuthTokenService` è esposto via `RepositoryProvider` sopra il `BlocProvider` tree, stesso wiring previsto per l'implementazione finale di Phase 11 (nessun consumer downstream cambia quando Phase 11 atterra)

### Authentication

- [ ] **AUTH-01**: User can log in with Twitch OAuth via system browser using PKCE flow (WebView is prohibited by Twitch TOS)
- [ ] **AUTH-02**: The app stores the Twitch access token and refresh token in encrypted platform storage (never in shared_preferences)
- [ ] **AUTH-03**: User session persists across app restarts via refresh token rotation
- [ ] **AUTH-04**: User can log out, which revokes the Twitch token, clears secure storage, resets the GraphQL cache, cancels all subscriptions, and returns to sign-in
- [ ] **AUTH-05**: User can switch Twitch account by logging out and logging back in with a different account
- [ ] **AUTH-06**: On token expiry, the access token is refreshed transparently; concurrent 401 responses are serialized via mutex so a single refresh is issued
- [ ] **AUTH-07**: On Twitch token revocation (user revoked the app externally), the app detects the invalidation and returns the user to sign-in with a clear message

### Character Creation

- [ ] **CHAR-01**: When a logged-in User has `currentCharacter == null`, the app routes to a character creation onboarding flow instead of the main tab shell
- [ ] **CHAR-02**: User can pick a name for the character (required, validated client + server)
- [ ] **CHAR-03**: User can pick `sex`, `pronoun`, `race` (RaceType), `classType` (ClassType), `age` from the corresponding enums
- [ ] **CHAR-04**: User can enter a free-text `background` (narrative bio, bounded length)
- [ ] **CHAR-05**: User can set a character portrait (`imagePath`) either by picking from a curated set or by uploading a photo from the device gallery/camera
- [ ] **CHAR-06**: Before upload, the app runs a client-side NSFW/explicit-content pre-screen on the selected image (on-device ML model such as Google ML Kit Image Labeling or TensorFlow Lite NSFW classifier). Images flagged as explicit are rejected client-side with a clear message; the backend performs the authoritative check and may still reject what the client allowed.
- [ ] **CHAR-07**: On submission, the mutation creates the character server-side and updates `User.currentCharacter`; the app transitions to the main tab shell
- [ ] **CHAR-08**: The creation flow supports back navigation between steps without losing data
- [ ] **CHAR-09**: If character creation fails (server error, validation, backend NSFW rejection), the UI shows the error using the project's existing error-display pattern (see shop flow) and preserves entered data

### Settings

- [ ] **SET-01**: User can access a Settings screen from the main menu of the app
- [ ] **SET-02**: User can toggle individual notification categories (travel end, streamer live, quest end) in Settings
- [ ] **SET-03**: User can trigger logout from Settings
- [ ] **SET-04**: Notification preferences persist across app restarts

### Real-Time Sync (User + Character subscriptions)

- [ ] **SYNC-01**: After login, the app opens a GraphQL subscription on the current `User` that delivers live updates to `twitchPoints`, `role`, and the `currentCharacter` reference
- [ ] **SYNC-02**: After the current `Character` is known, the app opens a GraphQL subscription on that Character that delivers live updates to `infos`, `status` (location, coins, HP, XP, spells, injuries, `activeTravel`, …), `quests` (including `pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest`), and `assets` (including `activeSpells`, `wearedEquipment`)
- [ ] **SYNC-03**: Both subscriptions auto-reconnect silently after network drop or app resume, and each re-queries its full payload to recover any missed events. No reconnection indicator is shown to the user — the experience stays immersive; transient staleness is resolved as soon as the subscription reopens.
- [ ] **SYNC-04**: Both subscriptions are closed cleanly on logout; no user or character data leaks into a subsequent session
- [ ] **SYNC-05**: When the current character changes (admin-swap, creation, or deletion), the Character subscription is rebuilt against the new `currentCharacter.id` without leaking the previous stream
- [ ] **SYNC-06**: The WebSocket `connection_init` payload carries the current auth token and is updated after token refresh for both subscriptions
- [ ] **SYNC-07**: `User.twitchPoints` and `Character.status` values displayed in the UI update live as the backend emits subscription events (no manual polling)

### Notifications

- [ ] **NOTIF-01**: The app registers with Firebase Cloud Messaging after login and syncs the FCM token to the backend (per-device)
- [ ] **NOTIF-02**: The app requests notification permission in-context at the first travel confirmation (never at cold launch)
- [ ] **NOTIF-03**: User receives a push notification when a travel completes (handled in all three app states: killed, background, foreground)
- [ ] **NOTIF-04**: User receives a push notification when the streamer goes live
- [ ] **NOTIF-05**: User receives a push notification when a quest they have accepted resolves (success, failure, death)
- [ ] **NOTIF-06**: Tapping a notification always routes the app to the Map tab (regardless of notification type) and then surfaces the correct context popup for that event (travel-end, streamer-live, quest-end, death). No type-specific tab routing. Behavior is uniform across all three app states (killed, background, foreground).
- [ ] **NOTIF-07**: In-foreground notifications render as in-app banners using the existing `KGNotification` model (title + description) with tap-to-navigate
- [ ] **NOTIF-08**: When a single event would generate both an FCM push and an in-app banner simultaneously, only one is shown to the user (foreground suppresses duplicate push)

### Quest Accept & Info

- [ ] **QUEST-01**: The existing `QuestInfoSheet` above the board tab gets per-`QuestType` layout variants **only where the content differs** — e.g. combat types (`hunt`, `enemy`, `boss`, `dungeon`) surface enemy/grade info; `story` and `worldMission` surface narrative context; `heal`, `aid`, `job`, `study` surface their own relevant fields. `crime` and `guard` are out of scope for v1.0 layouts.
- [ ] **QUEST-02**: User can accept a quest by swiping left on the `QuestInfoSheet` (the sheet presented above the board — **not** directly on the board list) with a "tear paper" animation and haptic feedback
- [ ] **QUEST-03**: On successful swipe-accept, the app navigates to the Map tab and presents the torn quest paper image on top of the stack as a confirmation artifact. Further details of the confirmation flow (dialog? cost preview? undo window?) are deferred — see Open Questions in `STATE.md`.
- [ ] **QUEST-04**: Backend prerequisite — Character carries independent fields for active `story` and `worldMission` quests (e.g. `activeStoryQuest: PendingQuest?`, `activeWorldMissionQuest: PendingQuest?`) so these run in parallel to the standard `pendingQuest`. The board hides a quest from the list as soon as the corresponding field is populated, without blocking acceptance of other quest types.
- [ ] **QUEST-05**: Quest cost model — `story` and `worldMission` quests spend `User.twitchPoints`. All other quest types spend `Character.coins` and/or display a list of **recommended** consumables/equipment (display-only hint, not enforced client-side — the backend is the source of truth for eligibility and debit).
- [ ] **QUEST-06**: If quest acceptance fails (insufficient balance, quest already taken, server error), the UI rolls back the optimistic state and surfaces the error using the project's existing error-display pattern (already implemented in the shop flow — reuse, do not reinvent)
- [ ] **QUEST-07**: While `Character.quests.pendingQuest` is populated, the UI shows a live countdown driven by `startDate + waitingTime`; the countdown is anchored to server timestamps, not device clock

### Travel

- [ ] **TRAVEL-01**: Backend exposes a new optional field on Character (e.g. `status.activeTravel { road: Road, startTime, endTime, duration }`) that represents a travel in progress. ETA, duration and validation are computed server-side. This field is a prerequisite for the frontend travel UI.
- [ ] **TRAVEL-02**: User can initiate travel to a destination POI and must explicitly confirm before the mutation fires. The confirmation surface shows destination + ETA **as received from the backend** (no client-side calculation). Exact dialog content/style is deferred — see Open Questions in `STATE.md`.
- [ ] **TRAVEL-03**: Once `activeTravel` is populated, the UI shows the character moving along `road.coordinates` in real time. Current position is computed by interpolating along the coordinate list based on `(now - startTime) / duration`, anchored to server timestamps. When the backend clears `activeTravel` and updates `location`, the UI snaps to the new location via the subscription stream — no frontend-side completion logic.
- [ ] **TRAVEL-04**: If the app is killed mid-travel, on relaunch the travel state is reconstructed from `activeTravel` via the subscription and the position on the road is recomputed accurately

### Spells (Journal Tab)

> **Note:** Una sezione Magie esiste già nel tab Journal in forma parziale. I requirement sotto definiscono la scope per v1.0; durante l'implementazione si verificherà puntualmente cosa è già presente e cosa manca davvero.

- [ ] **SPELL-01**: User can view owned spells in the Journal tab, sourced from `Character.status.spells`
- [ ] **SPELL-02**: For each owned spell, the UI shows: `name`, `description`, `maxUsages`, `recoveryTime`, and `energyDamage` summary
- [ ] **SPELL-03**: User can equip a spell to one of the available active slots (slot count = `Character.status.maxActiveSpells`, dynamic and backend-driven) by tapping it
- [ ] **SPELL-04**: User can disequip an `ActiveSpell` from a slot by tapping it
- [ ] **SPELL-05**: For each `ActiveSpell`, the UI displays the remaining `usages` and (where applicable) a recovery indicator derived from `spell.recoveryTime`
- [ ] **SPELL-06**: Slot assignment updates optimistically and rolls back on backend failure
- [ ] **SPELL-07**: The UI respects backend-determined slot availability — slot unlocks (e.g. after gaining `mage` title) are driven by changes in `maxActiveSpells`, not frontend logic

### Combat Result Sheet

- [ ] **COMBAT-01**: When a combat resolves, the user sees a full-screen result sheet (not a bottom sheet), triggered by a subscription event in foreground or by an FCM push when backgrounded
- [ ] **COMBAT-02**: The sheet shows HP before vs HP after (`currentLifePoints` delta against `maxLifePoints`) with an animated transition
- [ ] **COMBAT-03**: The sheet lists consumables and `activeSpells` used during the combat (derived from the combat result payload)
- [ ] **COMBAT-04**: The sheet lists `InjuryType` values received during the combat, rendered with human-readable labels
- [ ] **COMBAT-05**: The sheet lists rewards obtained (equipment, items, coins) and XP earned
- [ ] **COMBAT-06**: User must tap to dismiss the result sheet; it cannot be accidentally swiped away
- [ ] **COMBAT-07**: If the result arrives while the user is navigating or in a modal, it is queued and shown at a safe moment (not interrupting critical flows)

### Admin Panel (innkeeper role)

- [ ] **ADMIN-01**: When `User.role == RoleType.innkeeper`, the app exposes an admin tab (or admin menu) hidden to other roles
- [ ] **ADMIN-02**: Innkeeper can view a live list of pending quest requests for `story` and `worldMission` quest types. Characters whose `activeTravel` is populated are filtered out of this queue: the innkeeper only sees characters that are currently present at a POI and can therefore be acted upon.
- [ ] **ADMIN-03**: Innkeeper can approve or reject each pending request; approval/rejection requires explicit confirmation
- [ ] **ADMIN-04**: Innkeeper can teleport any user's character instantly to any POI on the map. The backend atomically overrides `location` and, if the character has an `activeTravel`, clears it as part of the same operation. Frontend is reactive only — no client-side teleport logic beyond the mutation.
- [ ] **ADMIN-05**: Innkeeper can select enemies/monsters for a POI combat quest, set the quest grade, and assign rewards
- [ ] **ADMIN-06**: Innkeeper can apply `InjuryType` values to a character as an outcome of admin-mediated combat
- [ ] **ADMIN-07**: Every admin mutation is enforced server-side with a role guard checking `role == innkeeper`; the client-side visibility check is UX only
- [ ] **ADMIN-08**: Every admin action is audit-logged on the backend (who, what, when)

### Hardening

- [ ] **HARDEN-01**: No token is ever written to shared_preferences, logs, or unencrypted disk (verified by code review and automated grep in CI)
- [ ] **HARDEN-02**: All admin endpoints return 403 when called by a non-innkeeper (verified by integration test with a non-innkeeper JWT)
- [ ] **HARDEN-03**: Logout is atomic: revoke token, clear secure storage, reset GraphQL cache, cancel subscriptions, reset cubits, navigate to sign-in. All steps covered by automated test.
- [ ] **HARDEN-04**: Token refresh is mutex-guarded so concurrent 401 responses do not cause double-refresh or silent logout
- [ ] **HARDEN-05**: Subscriptions are closed on logout and on disposal of the owning bloc (verified by memory profiler: no retained subscriptions after logout)
- [ ] **HARDEN-06**: A second device logging into the same Twitch account does not cause state corruption on the client (client handles subscription conflicts and identity transitions gracefully)

> **Backend concerns (out of scope for frontend hardening, tracked by BE team):** atomic balance debit / optimistic locking on `twitchPoints`, `Character.coins` and accepted quests, server-timestamp validation of travel completion, atomic clearing of `activeTravel` on admin teleport. These are fully server-side responsibilities; the frontend only reacts to authoritative state changes.

## Future Requirements

Deferred to post-v1.0. Tracked but not in current roadmap.

- **FUT-01**: Round-by-round combat log with replay
- **FUT-02**: Pet/mount speed modifiers affecting travel ETA (`Character.assets.pet` already modeled; backend would factor the modifier into `activeTravel.duration`)
- **FUT-03**: Village visual with clickable buildings showing available quests
- **FUT-04**: Full accessibility pass (screen reader support, large text, motor-impairment affordances)

## Out of Scope

Explicitly excluded from v1.0. Documented to prevent scope creep.

| Feature                                             | Reason                                                                                                                                                            |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Level progression UI logic                          | Backend is the source of truth for `level`, `xp`, `currentLifePoints`, `maxLifePoints`, `title`, `maxActiveSpells`; frontend purely displays                      |
| Spell learning at Valantar                          | Backend-only: resolved as outcome of a `study` quest server-side; frontend shows the updated `spells` list via subscription                                       |
| Spell slot unlock logic                             | Backend determines `maxActiveSpells`; frontend reactive only                                                                                                      |
| Live casting of `activeSpells` during combat        | Not planned, ever — combat resolution is backend-algorithmic; spells are view-only in the journal                                                                 |
| Multi-hop travel logic on frontend                  | Travel is handled entirely by the backend; frontend only renders the `activeTravel` payload. No FE-side route stitching.                                          |
| Post-creation character editing                     | Character info is final at creation time; no edit flow                                                                                                            |
| `twitchPoints → coins` conversion logic on frontend | Backend applies Twitch redemption events; frontend displays the resulting `twitchPoints` value only                                                               |
| Travel ETA calculation on frontend                  | Backend computes ETA and duration; frontend only displays the values it receives                                                                                  |
| Travel completion logic on frontend                 | Backend owns the travel lifecycle: clears `activeTravel` and updates `location`; frontend reacts via subscription only                                            |
| Frontend accessibility pass                         | Deferred to a later milestone — v1.0 does not optimize for screen reader, large text, or motor-impairment affordances                                             |
| Guilds and arena                                    | V2; requires complex social system                                                                                                                                |
| Guild blogs                                         | V2; depends on guild system                                                                                                                                       |
| Category-specific shops                             | V2; v1 has a single generic shop (already exists)                                                                                                                 |
| Village visual with clickable houses                | V2; significant UI refactor                                                                                                                                       |
| LLM-generated quests                                | V2; requires AI integration                                                                                                                                       |
| Audio upload/playback for story/worldMission        | V2; requires media storage                                                                                                                                        |
| Speech-to-text for quest audio                      | V2; depends on audio upload                                                                                                                                       |
| Good/evil alignment system (crime/guard)            | V2; complex mechanic (note: `crime` and `guard` QuestType enum values exist but are not surfaced in v1.0 layouts)                                                 |
| Lore with navigable hyperlinks between entries      | V2                                                                                                                                                                |
| Completed quest summary with details                | V2                                                                                                                                                                |
| go_router deep link routing overhaul                | V2; manual `NavigationService` sufficient for v1                                                                                                                  |
| Drag-and-drop spell slot assignment                 | V2; tap-based is sufficient                                                                                                                                       |
| Pet UI beyond current assets model                  | V2; `Character.assets.pet` is already modeled but not used by v1.0 features                                                                                       |
| firebase_auth for Twitch                            | Anti-feature: routes tokens through Firebase unnecessarily; direct Twitch PKCE is correct                                                                         |
| WebView-based OAuth                                 | Anti-feature: prohibited by Twitch TOS; system browser only                                                                                                       |
| `Dismissible` widget for swipe-accept               | Anti-feature: removes item from list; custom `GestureDetector` with drag threshold is correct                                                                     |
| Monolithic `QuestInfoSheet` with 12 nested branches | Anti-feature: per-type layout variants applied only where content differs                                                                                         |
| Client-side-only admin role enforcement             | Anti-feature: server must enforce `role == innkeeper` on every admin mutation                                                                                     |
| Cold-launch notification permission prompt          | Anti-feature: ~60% iOS dismissal rate; must be contextual                                                                                                         |
| App-style UI chrome in gameplay screens             | Anti-feature: Klimmeck Guide is a videogame — no status indicators, reconnection banners, or conventional buttons outside login/character-creation/settings/admin |

## Traceability

Which phases cover which requirements. Populated during roadmap creation.

| Requirement                 | Phase | Status  |
| --------------------------- | ----- | ------- |
| DEV-AUTH-01 through DEV-AUTH-05 | Phase 1 | Pending |
| AUTH-01 through AUTH-07     | Phase 11 | Pending |
| CHAR-01 through CHAR-09     | TBD   | Pending |
| SET-01 through SET-04       | TBD   | Pending |
| SYNC-01 through SYNC-07     | TBD   | Pending |
| NOTIF-01 through NOTIF-08   | TBD   | Pending |
| QUEST-01 through QUEST-07   | TBD   | Pending |
| TRAVEL-01 through TRAVEL-04 | TBD   | Pending |
| SPELL-01 through SPELL-07   | TBD   | Pending |
| COMBAT-01 through COMBAT-07 | TBD   | Pending |
| ADMIN-01 through ADMIN-08   | TBD   | Pending |
| HARDEN-01 through HARDEN-06 | TBD   | Pending |

**Coverage:**

- v1 requirements: 79 total (74 original + 5 DEV-AUTH)
- Mapped to phases: 12 (DEV-AUTH → Phase 1, AUTH → Phase 11); rest still TBD
- Unmapped: 67 (pending roadmap)

---

_Requirements defined: 2026-04-10_
_Last updated: 2026-04-14 — split Auth phase: introduced DEV-AUTH-01..05 (Phase 1, stub) and moved full OAuth (AUTH-01..07) to Phase 11 per decision to defer OAuth friction during manual QA_
