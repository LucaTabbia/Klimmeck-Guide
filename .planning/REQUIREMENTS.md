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

- [x] **DEV-AUTH-01**: `AuthTokenService` stub espone la stessa public surface del servizio finale — `Stream<AuthState>`, `Future<String?> getAccessToken()`, `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()`
- [x] **DEV-AUTH-02**: Lo stub legge identità e token da `.env` (`DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`); niente secure storage, niente OAuth
- [x] **DEV-AUTH-03**: Lo stub supporta role switching via `DEV_AUTH_ROLE` (`guard | adventurer | innkeeper`) per abilitare test di fasi role-gated (Admin Panel)
- [x] **DEV-AUTH-04**: `login()` e `logout()` sono no-op (warning log in debug builds only); nessun sign-in screen viene costruito in questa fase _(da Phase 11 lo stub simula le transizioni login/logout per rendere testabile la UI di auth senza chiavi Twitch — vedi 11-CONTEXT.md D-24)_
- [x] **DEV-AUTH-05**: `AuthTokenService` è esposto via `RepositoryProvider` sopra il `BlocProvider` tree, stesso wiring previsto per l'implementazione finale di Phase 11 (nessun consumer downstream cambia quando Phase 11 atterra)

### Authentication

- [x] **AUTH-01**: User can log in with Twitch via the system browser (WebView is prohibited by Twitch TOS); the backend mediates the Twitch OAuth exchange and the app redeems a one-time login ticket bound to an app-generated S256 challenge _(amended 2026-10-06: Twitch has no PKCE and requires a client secret — see 11-CONTEXT.md)_
- [x] **AUTH-02**: The app stores the session refresh token in encrypted platform storage (never in shared_preferences); it never holds a Twitch token _(amended 2026-10-06)_
- [x] **AUTH-03**: User session persists across app restarts via refresh token rotation
- [x] **AUTH-04**: User can log out, which invalidates the session on the backend, clears secure storage, resets the GraphQL cache, cancels all subscriptions, and returns to sign-in _(amended 2026-10-06)_
- [x] **AUTH-05**: User can switch Twitch account by logging out and logging back in with a different account
- [x] **AUTH-06**: On token expiry, the access token is refreshed transparently; concurrent 401 responses are serialized via mutex so a single refresh is issued
- [x] **AUTH-07**: When the backend revokes or expires the session (including after an external revocation on Twitch, once the backend detects it), the app detects the invalidation and returns the user to sign-in with a clear message _(amended 2026-10-06)_

### Character Creation

- [x] **CHAR-01**: When a logged-in User has `currentCharacter == null`, the app routes to a character creation onboarding flow instead of the main tab shell
- [x] **CHAR-02**: User can pick a name for the character (required, validated client + server)
- [x] **CHAR-03**: User can pick `sex`, `pronoun`, `race` (RaceType), `classType` (ClassType), `age` from the corresponding enums
- [x] **CHAR-04**: User can enter a free-text `background` (narrative bio, bounded length)
- [x] **CHAR-05**: User can set a character portrait (`imagePath`) either by picking from a curated set or by uploading a photo from the device gallery/camera — Phase 2 ships the gallery/camera upload only; the curated-set half is deferred (D-15).
- [ ] **CHAR-06**: Before upload, the app runs a client-side NSFW/explicit-content pre-screen on the selected image (on-device ML model such as Google ML Kit Image Labeling or TensorFlow Lite NSFW classifier). Images flagged as explicit are rejected client-side with a clear message; the backend performs the authoritative check and may still reject what the client allowed. — **DEFERRED** (Phase 2 CONTEXT D-17, user decision 2026-10-08: "Nessun filtro per ora"; candidates: BE Phase 10 hardening with Cloudinary AI moderation, FE Phase 12 Hardening). Not counted against Phase 2.
- [x] **CHAR-07**: On submission, the mutation creates the character server-side and updates `User.currentCharacter`; the app transitions to the main tab shell
- [x] **CHAR-08**: The creation flow supports back navigation between steps without losing data — Phase 2 uses a single page (D-04): there are no steps, and entered data is never discarded, which satisfies this requirement.
- [x] **CHAR-09**: If character creation fails (server error, validation, backend NSFW rejection), the UI shows the error using the project's existing error-display pattern (see shop flow) and preserves entered data

### Settings

- [x] **SET-01**: User can access a Settings screen from the main menu of the app
- [x] **SET-02**: User can toggle individual notification categories (travel end, streamer live, quest end) in Settings
- [x] **SET-03**: User can trigger logout from Settings
- [x] **SET-04**: Notification preferences persist across app restarts
- [x] **SET-05**: User can delete the current character from Settings after an explicit confirmation; the app returns to character creation (added 2026-10-15 in the Phase 4 discuss — backend contract `deleteCharacter` in BE Phase 03.1)

### Real-Time Sync (User + Character subscriptions)

- [x] **SYNC-01**: After login, the app opens a GraphQL subscription on the current `User` that delivers live updates to `twitchPoints`, `role`, and the `currentCharacter` reference
- [x] **SYNC-02**: After the current `Character` is known, the app opens a GraphQL subscription on that Character that delivers live updates to `infos`, `status` (location, coins, HP, XP, spells, injuries, `activeTravel`, …), `quests` (including `pendingQuest`, `activeStoryQuest`, `activeWorldMissionQuest`), and `assets` (including `activeSpells`, `wearedEquipment`) — _Phase 3 note (D-05): `activeTravel`, `activeStoryQuest`, `activeWorldMissionQuest` are not in the backend schema yet; they join `CharacterFragment` in Phases 6/7 (fragment-only change on the plumbing built in Phase 3)._
- [x] **SYNC-03**: Both subscriptions auto-reconnect silently after network drop or app resume, and each re-queries its full payload to recover any missed events. No reconnection indicator is shown to the user — the experience stays immersive; transient staleness is resolved as soon as the subscription reopens.
- [x] **SYNC-04**: Both subscriptions are closed cleanly on logout; no user or character data leaks into a subsequent session
- [x] **SYNC-05**: When the current character changes (creation or deletion — the admin never reassigns characters, Phase 3 D-08), the Character subscription is rebuilt against the new `currentCharacter.id` (or closed when it becomes `null`) without leaking the previous stream
- [x] **SYNC-06**: The WebSocket `connection_init` payload carries the current auth token and is updated after token refresh for both subscriptions
- [x] **SYNC-07**: `User.twitchPoints` and `Character.status` values displayed in the UI update live as the backend emits subscription events (no manual polling)

### Notifications

- [x] **NOTIF-01**: The app registers with Firebase Cloud Messaging after login and syncs the FCM token to the backend (per-device)
- [x] **NOTIF-02**: The app requests notification permission in-context at the first travel confirmation (never at cold launch) _(Phase 5: gate + no cold-launch prompt; call site wired by Phase 7)_
- [x] **NOTIF-03**: User receives a push notification when a travel completes (handled in all three app states: killed, background, foreground)
- [x] **NOTIF-04**: User receives a push notification when the streamer goes live
- [x] **NOTIF-05**: User receives a push notification when a quest they have accepted resolves (success, failure, death)
- [x] **NOTIF-06**: Tapping a notification always routes the app to the Map tab (regardless of notification type) and then surfaces the correct context popup for that event (travel-end, streamer-live, quest-end, death). No type-specific tab routing. Behavior is uniform across all three app states (killed, background, foreground).
  - _Emendato il 2026-10-19 (Phase 5 discuss, decisione utente): il tap su `streamerLive` apre direttamente il canale Twitch (`https://www.twitch.tv/lordreavor`), senza passare dalla mappa né da un popup; i tipi personali (`travelEnd`, `questEnd`) vanno sulla Map tab e i loro popup di contesto arrivano con le Phase 7/9. Il comportamento resta uniforme nei tre app state e identico tra notifica di sistema e banner in-app. Phase 5 è solo Android: iOS è rinviato a una fase successiva._
- [x] **NOTIF-07**: In-foreground notifications render as in-app banners using the existing `KGNotification` model (title + description) with tap-to-navigate
- [x] **NOTIF-08**: When a single event would generate both an FCM push and an in-app banner simultaneously, only one is shown to the user (foreground suppresses duplicate push)

### Quest Accept & Info

- [x] **QUEST-01**: The existing `QuestInfoSheet` above the board tab gets per-`QuestType` layout variants **only where the content differs** — e.g. combat types (`hunt`, `enemy`, `boss`, `dungeon`) surface enemy/grade info; `story` and `worldMission` surface narrative context; `heal`, `aid`, `job`, `study` surface their own relevant fields. `crime` and `guard` are out of scope for v1.0 layouts.
- [x] **QUEST-02**: User can accept a quest by swiping left on the `QuestInfoSheet` (the sheet presented above the board — **not** directly on the board list) with a "tear paper" animation and haptic feedback
- [x] **QUEST-03**: On successful swipe-accept, the app navigates to the Map tab and presents the torn quest paper image on top of the stack as a confirmation artifact. Further details of the confirmation flow (dialog? cost preview? undo window?) are deferred — see Open Questions in `STATE.md`.
  - _Emendato il 2026-10-21 (Phase 6 discuss, D-01/D-03/D-07/D-08): lo swipe è la conferma — nessun dialog e nessuna undo window (il backend non ha cancel). Il foglio si strappa subito (ottimistico), la mutation parte alla soglia e l'app passa alla Map tab solo quando il backend risponde `successful: true`. Per la corsia standard il foglio intero della quest resta visibile sulla mappa finché la quest è attiva; il tap apre lo stesso QuestInfoSheet in sola lettura con lo stato (QUEST-07). Story e worldMission non mostrano mai un foglio sulla mappa._
- [x] **QUEST-04**: Backend prerequisite — Character carries independent fields for active `story` and `worldMission` quests (e.g. `activeStoryQuest: PendingQuest?`, `activeWorldMissionQuest: PendingQuest?`) so these run in parallel to the standard `pendingQuest`. The board hides a quest from the list as soon as the corresponding field is populated, without blocking acceptance of other quest types.
  - _Emendato il 2026-10-21 (D-08/D-11/D-12): le tre corsie sono servite dal BE Phase 7 (merged). Una story/worldMission accettata resta sulla board **strappata per il proprietario** (non nascosta). La board è raggiungibile solo da un marker di città e mostra le quest della città, le worldMission della città e la sola story del titolo del personaggio; le non ripetibili già completate sono nascoste; worldMission/boss/enemy/aid piene (totale o rango del giocatore, regola BE Phase 8 D-32) appaiono strappate per tutti._
- [x] **QUEST-05**: Quest cost model — `story` and `worldMission` quests spend `User.twitchPoints`. All other quest types spend `Character.coins` and/or display a list of **recommended** consumables/equipment (display-only hint, not enforced client-side — the backend is the source of truth for eligibility and debit).
  - _Emendato il 2026-10-21 (D-02, handoff BE Phase 7 §7): nessuna quest costa monete. Solo story e worldMission costano `requirements.requiredPoints` punti canale (`User.twitchPoints`), mostrati come `Punti canale: saldo / costo` ed evidenziati se il saldo è insufficiente; `recommendedLoot` resta un suggerimento display. Il backend decide (`INSUFFICIENT_POINTS`)._
- [x] **QUEST-06**: If quest acceptance fails (insufficient balance, quest already taken, server error), the UI rolls back the optimistic state and surfaces the error using the project's existing error-display pattern (already implemented in the shop flow — reuse, do not reinvent)
  - _Emendato il 2026-10-21 (D-04, D-20 C3): il rollback ricompone il foglio strappato e l'errore appare nel banner in-app di Phase 5 con copy di dominio scelta da `extensions.code`, mai dal testo del messaggio. La nuvoletta del negoziante dello shop è specifica dello shop e non viene riusata._
- [x] **QUEST-07**: While `Character.quests.pendingQuest` is populated, the UI shows a live countdown driven by `startDate + waitingTime`; the countdown is anchored to server timestamps, not device clock
  - _Emendato il 2026-10-21 (D-15): nessun countdown a schermo. Il foglio della corsia standard mostra un'etichetta di stato guidata dal server: `startDate` nullo → «In viaggio», poi un'etichetta per tipo («In combattimento…», «Cacciando…», «Esplorando…», «Lavorando…», «Guarendo…», «Aiutando…», «Studiando…») finché l'esito (Phase 9) svuota la corsia. Niente `serverTime` né offset in questa fase (FE Phase 7)._

### Travel

- [x] **TRAVEL-01**: Backend exposes a new optional field on Character (e.g. `status.activeTravel { road: Road, startTime, endTime, duration }`) that represents a travel in progress. ETA, duration and validation are computed server-side. This field is a prerequisite for the frontend travel UI.
  - _Nota 2026-10-24: consegnato dal BE Phase 8 su `develop` (PR #11 e #12): `activeTravel { road { coordinates distance } startTime endTime duration to }`, `travelPreview`, `startTravel`, `serverTime`. La spunta arriva con il piano finale della FE Phase 7 (07-11)._
- [x] **TRAVEL-02**: User can initiate travel to a destination POI and must explicitly confirm before the mutation fires. The confirmation surface shows destination + ETA **as received from the backend** (no client-side calculation). Exact dialog content/style is deferred — see Open Questions in `STATE.md`.
  - _Emendato il 2026-10-24 (Phase 7 discuss, D-01..D-05): il viaggio parte trascinando la pedina su una città (la più vicina al punto di rilascio); la conferma è un foglio di pergamena con nome e immagine della città, distanza, durata ed ETA forniti dal backend (`travelPreview`; l'ETA mostrata è l'ora del server stimata più `duration`), rotta tratteggiata dietro il foglio e azioni «Parti» / «Resta». Nessun costo: il backend non ne prevede. Il permesso notifiche si chiede solo dopo un `startTravel` riuscito. La domanda aperta in STATE.md è risolta._
- [x] **TRAVEL-03**: Once `activeTravel` is populated, the UI shows the character moving along `road.coordinates` in real time. Current position is computed by interpolating along the coordinate list based on `(now - startTime) / duration`, anchored to server timestamps. When the backend clears `activeTravel` and updates `location`, the UI snaps to the new location via the subscription stream — no frontend-side completion logic.
  - _Emendato il 2026-10-24 (D-06..D-10, D-12, D-13): la rotta intera resta visibile con il tratto percorso in un altro tono, sopra la pedina fluttua solo il tempo rimanente («In arrivo…» a fine percorso) e la pedina scatta sulla nuova posizione solo all'evento del backend. Durante qualsiasi viaggio (anche quello automatico verso una quest) e fuori da un marker di città Bacheca e Negozio sono disabilitati._
- [x] **TRAVEL-04**: If the app is killed mid-travel, on relaunch the travel state is reconstructed from `activeTravel` via the subscription and the position on the road is recomputed accurately

### Spells (Journal Tab)

> **Note:** Una sezione Magie esiste già nel tab Journal in forma parziale. I requirement sotto definiscono la scope per v1.0; durante l'implementazione si verificherà puntualmente cosa è già presente e cosa manca davvero.

- [x] **SPELL-01**: User can view owned spells in the Journal tab, sourced from `Character.status.spells`
- [x] **SPELL-02**: For each owned spell, the UI shows: `name`, `description`, `maxUsages`, `recoveryTime`, and `energyDamage` summary
- [x] **SPELL-03**: User can equip a spell to one of the available active slots (slot count = `Character.status.maxActiveSpells`, dynamic and backend-driven) by tapping it
  - _Emendato il 2026-10-27 (Phase 8 discuss, D-06/D-07): il tap sulla riga è un toggle (equip se inattiva, disequip se attiva); con slot pieni o `maxActiveSpells == 0` il client non chiama il BE e mostra il banner; il BE resta il giudice (`MAX_ACTIVE_SPELLS_REACHED`). Il campo deprecato `EquipSpellRequest.usages` non viene inviato._
- [x] **SPELL-04**: User can disequip an `ActiveSpell` from a slot by tapping it
  - _Emendato il 2026-10-27 (D-06, D-09): anche il tap sulla carta nello slot disequipaggia; il long-press su riga o carta apre il foglio di dettaglio (`SpellInfo` esteso, pattern `EquipmentInfoSheet`)._
- [x] **SPELL-05**: For each `ActiveSpell`, the UI displays the remaining `usages` and (where applicable) a recovery indicator derived from `spell.recoveryTime`
  - _Emendato il 2026-10-27 (D-01..D-05): countdown reale «prossimo tra X» nella riga della lista, calcolato dal tempo server sul primo istante di `CharacterStatus.spellStates[].recoveries` (BE Phase 9.1, contratto additivo proposto in `phases/08-spells-section-journal-tab/BACKEND-NOTES.md`). Usi e recuperi sono per magia conosciuta e sopravvivono a equip/disequip (regola dell'utente: «Il timer di recupero non si interrompe mai»); senza `recoveries` il FE mostra «in recupero» senza tempo; la carta nello slot mostra solo gli usi._
- [x] **SPELL-06**: Slot assignment updates optimistically and rolls back on backend failure
- [x] **SPELL-07**: The UI respects backend-determined slot availability — slot unlocks (e.g. after gaining `mage` title) are driven by changes in `maxActiveSpells`, not frontend logic
  - _Nota 2026-10-27 (D-10..D-12): la riga degli slot ha esattamente `maxActiveSpells` box; con `maxActiveSpells == 0` nessuna riga di slot e una riga di copy neutro senza numeri; senza magie conosciute la sezione non viene costruita._

- [x] **SPELL-08**: The known-spell list can be filtered by `useType` with the shop's icon chips («Tutti» + one chip per use type present in the list); the slot row never changes _(added 2026-10-27 after the Phase 8 device UAT, D-22/D-23)_
- [x] **SPELL-09**: The compact spell line and the detail sheet show the use-type label in place of «Danno» («Attacco: Fuoco 12»; «Danno: …» only when `useType` is missing); the sheet keeps its «Uso: …» line _(added 2026-10-27, D-24)_

### Journal Items and Shop (Phase 8 extension, added 2026-10-27)

- [x] **ITEM-01**: `EffectType` has an Italian label (Cura, Sazietà, Danno, Esplorazione, Nessun effetto) and every loot item row (Journal and shop, shared `ItemRow`) shows «<label>: <power>» under the description (D-25/D-26)
- [x] **ITEM-02**: The Journal «Oggetti» section can be filtered by `effect` with the same icon chips, limited to the effect types present among the owned items (D-27/D-23)
- [x] **SHOP-01**: The shop filters show only the equip/effect types present in the lists on sale or owned (D-23)

### Combat Result Sheet

- [x] **COMBAT-01**: When a combat resolves, the user sees a full-screen result sheet (not a bottom sheet), triggered by a subscription event in foreground or by an FCM push when backgrounded _(amended 2026-10-27, D-06/D-07/D-13: the sheet is presented only on the Map tab; from any other tab the in-app banner leads there; the death sheet opens on any tab)_
- [x] **COMBAT-02**: The sheet shows HP before vs HP after (`currentLifePoints` delta against `maxLifePoints`) with an animated transition
- [x] **COMBAT-03**: The sheet lists consumables and `activeSpells` used during the combat (derived from the combat result payload)
- [x] **COMBAT-04**: The sheet lists `InjuryType` values received during the combat, rendered with human-readable labels
- [x] **COMBAT-05**: The sheet lists rewards obtained (equipment, items, coins) and XP earned
- [x] **COMBAT-06**: User must tap to dismiss the result sheet; it cannot be accidentally swiped away _(2026-10-27, D-05: one explicit button at the bottom; scrim, Android back and swipe ignored)_
- [x] **COMBAT-07**: If the result arrives while the user is navigating or in a modal, it is queued and shown at a safe moment (not interrupting critical flows) _(amended 2026-10-27, D-06..D-08: queued until the Map tab is visible and free — no sheet or dialog open, no pawn drag — then shown FIFO by `resolvedAt`, one sheet at a time)_
- [x] **COMBAT-08**: After a lost fight the Map shows the wounded state (`status.awaitingAid`): «In attesa di soccorso» over the pawn, pawn drag, Board and Shop disabled as during a travel, `AWAITING_AID` / `SHOP_NOT_IN_CITY` mapped to the banner _(added 2026-10-27, D-16; Phase 7 deferred item)_
- [x] **COMBAT-09**: No result sheet is ever lost: the app reads the unacknowledged results of the user at cold start, resume and reconnection (BE Phase 9.2 `unacknowledgedQuestResults`) and acknowledges each sheet when the player closes it (`acknowledgeQuestResult`); every source (subscription, push, query) is deduplicated by result id; a `death` result keeps `User.currentCharacter` on the dead character until it is acknowledged (BE 9.2, user decision 2026-10-27), so the death sheet always precedes the creation page, cold start included _(added 2026-10-27, D-09/D-10/D-13; BE prerequisite)_
- [x] **COMBAT-10**: The `aid` quest («Soccorso: …») uses the combat sheet family on the Board (enemy, time, rank slots, party counter); a started quest stays torn until it concludes because the BE keeps its seats after the start (BE Phase 9.2, user rule) _(added 2026-10-27, D-17/D-18)_

### Admin Panel (innkeeper role)

- [ ] **ADMIN-01**: When `User.role == RoleType.innkeeper`, Settings shows a «Locanda» section (hidden to every other role, live with `userUpdated`) that opens the admin panel as a full-screen utility route on the root Navigator; the innkeeper always has a character (no special boot path) _(amended 2026-10-29, Phase 10 discuss D-01/D-02)_
- [ ] **ADMIN-02**: Innkeeper can view a live list of pending quest requests for `story` and `worldMission` quest types (`pendingRequestsUpdated`), one card per quest with its registered participants and seats. A character whose standard lane is occupied (`character.pendingQuest`, BE Phase 10 BE-HARD-08) is not shown: user rule «chi ha accettato una quest, in viaggio o in combattimento, non compare nella lista». A character on a free travel stays visible, greyed with the remaining time, and the card cannot be completed until every listed participant has arrived (story and worldMission never start a travel). _(amended 2026-10-29, D-05..D-10)_
- [ ] **ADMIN-03**: Innkeeper can complete each pending request (there is no reject: BE Phase 9 user decision, a story/worldMission can only end well) through the completion form, with an explicit confirmation dialog that recaps the overrides; the returned results are shown per character; errors are mapped per code inline (`NOT_FOUND`, `QUEST_IN_PROGRESS`, `OUTCOME_OVERRIDE_INVALID`, `OUTCOME_NOT_PARTICIPANT`, `FORBIDDEN`) _(amended 2026-10-29, D-11/D-13/D-14)_
- [ ] **ADMIN-04**: Innkeeper can teleport a queued character (a row of the queue: the panel is only the queue, user decision) by opening the Map in teleport mode, where the selected character's pawn replaces the innkeeper's own, and dragging it onto a city marker: `teleportCharacter` is called at once, with no confirmation; on success the panel reopens. The backend atomically overrides `location` and, if the character has an `activeTravel`, clears it as part of the same operation. Frontend is reactive only — no client-side teleport logic beyond the mutation. _(amended 2026-10-29, D-03, D-15..D-20)_
- [ ] **ADMIN-05**: Innkeeper tells what happened in the live session per participant: HP left (slider `1..maxLifePoints`), consumables used (owned loot with quantity) and spells used (active spells within the remaining usages); monsters, grade and rewards are not chosen at runtime (catalogue data, BE Phase 9 user decision) _(amended 2026-10-29, D-11/D-12)_
- [ ] **ADMIN-06**: Innkeeper can apply `InjuryType` values to a participant as an outcome of the admin-mediated combat, as multi-select chips of the 28 injuries with the Italian labels in the same completion form (existing injuries shown as inactive) _(amended 2026-10-29, D-12)_
- [ ] **ADMIN-07**: Every admin mutation is enforced server-side with a role guard checking `role == innkeeper` (delivered by BE Phase 3 `@Roles(innkeeper)`, Phases 8/9 `teleportCharacter`/`completePendingRequest`); the client-side visibility check is UX only — the FE pins the hidden Settings section for a non-innkeeper and the device UAT calls `pendingRequests` as an adventurer expecting `FORBIDDEN` _(amended 2026-10-29, D-21)_
- [ ] **ADMIN-08**: Every admin action is audit-logged on the backend (who, what, when) — delivered by the BE Phase 3 audit interceptor on every `@Roles(innkeeper)` mutation; the FE adds nothing _(amended 2026-10-29, D-21)_

### Hardening

- [ ] **HARDEN-01**: No token is ever written to shared_preferences, logs, or unencrypted disk (verified by code review and automated grep in CI)
- [ ] **HARDEN-02**: All admin endpoints return 403 when called by a non-innkeeper (verified by integration test with a non-innkeeper JWT)
- [ ] **HARDEN-03**: Logout is atomic: revoke token, clear secure storage, reset GraphQL cache, cancel subscriptions, reset cubits, navigate to sign-in. All steps covered by automated test.
- [ ] **HARDEN-04**: Token refresh is mutex-guarded so concurrent 401 responses do not cause double-refresh or silent logout
- [ ] **HARDEN-05**: Subscriptions are closed on logout and on disposal of the owning bloc (verified by memory profiler: no retained subscriptions after logout)
- [ ] **HARDEN-06**: A second device logging into the same Twitch account does not cause state corruption on the client (client handles subscription conflicts and identity transitions gracefully)

> **Backend concerns (out of scope for frontend hardening, tracked by BE team):** atomic balance debit / optimistic locking on `twitchPoints`, `Character.coins` and accepted quests, server-timestamp validation of travel completion, atomic clearing of `activeTravel` on admin teleport. These are fully server-side responsibilities; the frontend only reacts to authoritative state changes.

### City Shops (Phase 13, added 2026-10-29)

- [ ] **SHOP-02**: On a city marker the shop lists only that city's pool of items (equipment and loot) as served by the backend; the city size (village / city / capital) and the pool live on the backend (BE Phase 12, seeded by BE Phase 11); the frontend never filters by rarity itself and the shop sheet names the city
- [ ] **SHOP-03**: Buying an item outside the current pool is refused by the backend with a stable code mapped on the in-app banner like the other transaction codes; selling works in every city; stock is infinite; legendary items are never on sale

### Quest Generation companion (Phase 14, added 2026-10-29)

- [ ] **QGEN-01**: Quest sheets list every enemy of the quest with its quantity from `infos.enemies: [{ enemy, quantity }]`; the single `infos.enemy` is removed from every document and model (BE Phase 13 replaces it)
- [ ] **QGEN-02**: The result sheet lists the enemies fought, for standard-lane and ambush outcomes
- [ ] **QGEN-03**: From the Locanda the innkeeper can trigger the quest generator («Genera missioni», BE `generateQuests`) with an explicit confirmation and sees how many quests were generated; `FORBIDDEN` and the other codes are mapped inline
- [ ] **QGEN-04**: Fixed `crime` and `guard` quests render with the service family layout and `dungeon` with the combat family; no alignment mechanic (still out of scope)

### Travel Food (Phase 15, added 2026-10-29)

- [ ] **FOOD-01**: The travel confirmation sheet shows the food the backend will consume (items and quantities) and the HP lost on the uncovered kilometres, from `travelPreview`, before «Parti»
- [ ] **FOOD-02**: Combat and service quest sheets show the food cost of the automatic travel to the marker next to the channel-points line, from a backend acceptance preview
- [ ] **FOOD-03**: A departure or an acceptance refused for lack of food (backend starvation code) is explained on the in-app banner and the sheet recomposes
- [ ] **FOOD-04**: Inventory and HP after a departure update only through `characterUpdated`; the frontend computes nothing (1 power = 3 minutes of march, minimum-waste selection, km n costs n HP: all server rules)

### Travel Ambushes (Phase 16, added 2026-10-29)

- [ ] **AMBUSH-01**: When the backend reroutes an `activeTravel` after a lost ambush, the pawn, the dashed route and the remaining time follow the new polyline live
- [ ] **AMBUSH-02**: The ambush report is a variant of the result sheet (won: XP and coins; lost: HP delta, injuries, city reached), queued and acknowledged like the quest results and shown on the free Map
- [ ] **AMBUSH-03**: The confirmation sheet never reveals an ambush; the arrival banner/push leads to the Map where the report appears

### Unlockable Lore (Phase 17, added 2026-10-29)

- [ ] **LORE-01**: The Library shows only the lore unlocked by the current character (backend-filtered), live after each unlock; locked lore is hidden; a book with nothing unlocked shows an empty state
- [ ] **LORE-02**: Unknown enemies (never defeated by the character) show a darkened portrait and the name only on quest and result sheets; the knowledge flag comes from the backend
- [ ] **LORE-03**: A new character starts with the home-city lore and its region only; deleting and recreating the character resets the Library

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
| Shops by item category                              | V2; superseded in part on 2026-10-29: pools per city and size are Phase 13 (BE Phase 12); a shop per category (smith, alchemist…) remains V2                        |
| Village visual with clickable houses                | V2; significant UI refactor                                                                                                                                       |
| LLM-generated quest descriptions                    | V2; the server-side generation and placement of consumable `enemy`/`boss` quests is BE Phase 13 (Phase 14 companion) with templated titles; prose by LLM stays V2    |
| Audio upload/playback for story/worldMission        | V2; requires media storage                                                                                                                                        |
| Speech-to-text for quest audio                      | V2; depends on audio upload                                                                                                                                       |
| Good/evil alignment system (crime/guard)            | V2; complex mechanic (fixed `crime`/`guard` quests seeded by BE Phase 11 render with the service layout, QGEN-04, without any alignment logic)                     |
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
| DEV-AUTH-01 through DEV-AUTH-05 | Phase 1 | Complete |
| AUTH-01 through AUTH-07     | Phase 11 | Complete (real-device Twitch login pending UAT) |
| CHAR-01 through CHAR-05, CHAR-07 through CHAR-09 | Phase 2 | Complete (CHAR-05: upload only, curated set deferred) |
| CHAR-06                     | Deferred (Phase 2 D-17 → Phase 12 / BE hardening) | Deferred |
| SET-01 through SET-05       | Phase 4 | Complete |
| SYNC-01 through SYNC-07     | Phase 3 | Complete (activeTravel/activeStoryQuest/activeWorldMissionQuest join the fragment in Phases 6/7, D-05; FE PR after the BE Phase 3 PR, D-04) |
| NOTIF-01 through NOTIF-08   | Phase 5 | Complete (Android only; NOTIF-02 prompt call site in Phase 7; context popups in Phases 7/9) |
| QUEST-01 through QUEST-07   | Phase 6 | Complete (QUEST-03/04/05/06/07 as amended 2026-10-21; Android device E2E 2026-10-22) |
| TRAVEL-01 through TRAVEL-04 | Phase 7 | Complete (TRAVEL-01 shipped by BE Phase 8; TRAVEL-02/03 amended 2026-10-24; Android device E2E 2026-10-26) |
| SPELL-01 through SPELL-07   | Phase 8 | Complete |
| SPELL-08, SPELL-09          | Phase 8 | Complete |
| ITEM-01, ITEM-02, SHOP-01   | Phase 8 | Complete |
| COMBAT-01 through COMBAT-10 | Phase 9 | Complete (COMBAT-01/06/07 amended, COMBAT-08/09/10 added 2026-10-27; BE Phase 9.2 merged; Android device E2E 2026-10-29) |
| ADMIN-01 through ADMIN-08   | Phase 10 | Pending (context gathered 2026-10-29; BE-HARD-08 companion in BE Phase 10) |
| HARDEN-01 through HARDEN-06 | Phase 12 (executes last) | Pending |
| SHOP-02, SHOP-03            | Phase 13 | Pending (added 2026-10-29; BE Phase 12) |
| QGEN-01 through QGEN-04     | Phase 14 | Pending (added 2026-10-29; BE Phase 13, `enemies` replaces `enemy`) |
| FOOD-01 through FOOD-04     | Phase 15 | Pending (added 2026-10-29; BE Phase 14) |
| AMBUSH-01 through AMBUSH-03 | Phase 16 | Pending (added 2026-10-29; BE Phase 15) |
| LORE-01 through LORE-03     | Phase 17 | Pending (added 2026-10-29; BE Phase 16) |

**Coverage:**

- v1 requirements: 103 total (74 original + 5 DEV-AUTH + 5 Phase 8 extension + 3 COMBAT-08..10 added 2026-10-27 + 16 added 2026-10-29: SHOP-02/03, QGEN-01..04, FOOD-01..04, AMBUSH-01..03, LORE-01..03)
- Mapped to phases: all (Phases 1–17; HARDEN → Phase 12, executed last)
- Unmapped: 0

---

_Requirements defined: 2026-04-10_
_Last updated: 2026-10-09 — CHAR-06 deferred by user decision (Phase 2 D-17); CHAR-05 curated half deferred; CHAR-08 satisfied by the single-page flow (D-04)_ · _Last updated: 2026-04-14 — split Auth phase: introduced DEV-AUTH-01..05 (Phase 1, stub) and moved full OAuth (AUTH-01..07) to Phase 11 per decision to defer OAuth friction during manual QA_ · _Last updated: 2026-10-21 — Phase 6 discuss: QUEST-03/04/05/06/07 amended (CONTEXT D-01..D-20)_ · _Last updated: 2026-10-24 — Phase 7 discuss: TRAVEL-02/03 amended, no travel cost (CONTEXT D-01..D-20)_ · _Last updated: 2026-10-26 — Phase 7 complete: TRAVEL-01..04 ticked after the Android device E2E (07-HUMAN-UAT.md, steps 1-11 pass)_ · _Last updated: 2026-10-27 — Phase 9 discuss: COMBAT-01/06/07 amended, COMBAT-08/09/10 added (CONTEXT D-01..D-22); BE Phase 9.2 inserted_ · _Last updated: 2026-10-29 — Phase 9 complete: COMBAT-01..10 ticked after the Android device E2E (09-HUMAN-UAT.md, 12/12 pass); party counter during the own travel (F1) is a Phase 7 behaviour fixed on the branch, not a COMBAT gap_ · _Last updated: 2026-10-29 — Phase 10 discuss: ADMIN-01..08 amended (no reject, no grade/monsters/rewards, completion form with overrides, teleport from the queue on the Map, busy standard lane hidden); BE-HARD-08 added to the BE Phase 10_ · _Last updated: 2026-10-29 — v1.0 extended: SHOP-02/03 (Phase 13), QGEN-01..04 (Phase 14), FOOD-01..04 (Phase 15), AMBUSH-01..03 (Phase 16), LORE-01..03 (Phase 17); Out of Scope amended for shops, LLM quests and crime/guard_
