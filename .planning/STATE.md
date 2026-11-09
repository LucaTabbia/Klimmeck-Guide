---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-11-09T16:40:09.057Z"
last_activity: 2026-11-09 -- Phase 12 execution started
progress:
  total_phases: 17
  completed_phases: 16
  total_plans: 180
  completed_plans: 163
  percent: 91
---

# Project State

## Current Position

Phase: 12 (Hardening) — EXECUTING since 2026-11-09 on `refactor/12-hardening` (from `develop` `ac75702`): 17 plans in 17 sequential waves (12-01..12-15 on fakes with the contract names of the BE `17-REPO-RULES.md`; 12-16 gate and 12-17 device UAT + handoff gated by the BE Phase 17 merge on BE `develop`)
Plan: 11 of 17
Completed phases: 16 (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17)
Next Phase: `/gsd-execute-phase 12` (12-01..12-15 now on fakes with the contract names of the BE `17-REPO-RULES.md`; review by area, then 12-16/12-17 after the BE Phase 17 PR merges on BE `develop`), then the FE PR to `develop` and the v1.0 close (Hardening is the last phase)
Status: Executing Phase 12 — 12-01..12-15 run now; 12-16/12-17 wait for the BE Phase 17 merge; BE Phase 17 executing in the same session on `feat/17-autorizzazione-e-sessioni`; the BE runs from `develop` `31dba96` on port 3001; the user generates the release keystore and `android/key.properties` before the UAT (handoff steps)
Last activity: 2026-11-09 -- Phase 12 execution started
Quick task 261109-inj (2026-11-09): `LootItem.canHeal` (campo già a DB, riusato su correzione dell'utente) letto dalla FE e mostrato come riga «Cura: …» sugli oggetti heal (negozio e Diario); gemello BE sullo stesso nome di branch; contenuto dei 25 oggetti heal a DB dopo la revisione dell'utente.
Quick task 261109-inj2 (2026-11-09): nove `InjuryType` nuovi (37) con etichette, gravità ed effetti; lettura tollerante delle ferite del personaggio; gemello BE con gli effetti provvisori.

## Current Milestone

**v1.0 Core Loop** — Chiudere il loop di gioco base: auth Twitch, sync utente real-time, quest accept gesture, viaggio con notifiche, esiti combattimento, magie (tab diario), admin panel, hardening finale.

## Accumulated Context

- Codebase brownfield già mappato in `.planning/codebase/`
- Stack: Flutter (mobile) + NestJS + MongoDB + GraphQL (HTTP + WS) + REST
- Asset su Cloudinary, mappa POI manuale, single channel Twitch
- Titoli personaggio: adventurer → paladin → mage → hero
- Progressione livelli, apprendimento magie, sblocco slot magie: gestiti lato backend (frontend reattivo)
- Shop e sezione lore già esistenti e funzionanti
- Lista quest nel tab board quasi definitiva; mancano layout info sheet per tipo

### Roadmap Evolution

- Phases 13–17 added 2026-10-29 (user request, before closing v1.0): 13 City Shops ↔ BE 12, 14 Quest Generation companion ↔ BE 13 (`infos.enemies` replaces `infos.enemy`), 15 Travel Food ↔ BE 14, 16 Travel Ambushes ↔ BE 15, 17 Unlockable Lore ↔ BE 16; BE Phase 11 World Content (data-only, from `World building.docx`) is the data prerequisite of every device UAT. Execution order 13 → 14 → 15 → 16 → 17 → 12 (Hardening last). Each FE phase waits for the BE companion merge on BE `develop` (gate pattern 08-12/09-12). Contracts decided in the discuss of 2026-10-29 are recorded in the ROADMAP phase details; the BE roadmap carries the server rules.
- 2026-11-07: Phase 17 discussed while Phase 16 waits for its device UAT (phone unavailable); the two phases run on separate branches from `develop` as two separate features (user decision); both device UATs (16-08 and the Phase 17 one) run at the end of Phase 17, then the two PRs land in sequence.

## Open Questions / Blockers

- ~~Scelta libreria push notification Flutter (firebase_messaging è standard)~~ — risolta nel discuss di Phase 5 (2026-10-19): `firebase_core` + `firebase_messaging` + `flutter_local_notifications` già in pubspec; `firebase_auth` rimosso; iOS rinviato.
- ~~Scelta client GraphQL subscription~~ — risolta in Phase 3 discuss (2026-10-14): resta `graphql_flutter` 5.2.1 (WebSocketLink + WsReconnectPolicy di Phase 11)
- ~~Flusso OAuth Twitch: webview in-app vs deep link / universal link~~ — **risolto in Phase 11:** login mediato dal backend via browser di sistema + deep link `klimmeck://auth` (Twitch non supporta PKCE né redirect con custom scheme; l'app non possiede chiavi Twitch).
- ~~Chiavi Twitch non ancora disponibili~~ — **risolto:** chiavi presenti nel `.env` del BE; il login Twitch reale su device (browser di sistema + deep link `klimmeck://auth`) è stato esercitato con successo il 2026-10-20 nella UAT di Phase 5. Il dev bypass resta disponibile per i test (`DEV_AUTH_ENABLED=true`).
- **Backend:** dalla sua Phase 2 richiede un'identità su ogni chiamata; `DEV_AUTH_ACCESS_TOKEN` deve coincidere con quello del BE (≥ 16 caratteri). Contratto in `Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md`. Decisione BE D-26 (finestra di grazia del refresh) in attesa dell'utente.
- ~~Entry point del logout~~ — **risolto in Phase 4** (Settings → Esci; PR #28). Dalla Phase 5 `AuthCubit.logout()` fa prima `unregisterPushDevice` (tetto 2 s) e poi il logout del servizio.
- ~~Cancellazione personaggio (SET-05)~~ — **risolto:** `deleteCharacter` consegnato dal BE (Phase 03.1, BE PR #6) e consumato dalla Phase 4 FE (PR #28).
- ~~BE/ops — topic FCM `streamer-live`~~ — **risolto il 2026-10-20:** `firebase-admin` 14.5 iscrive ai topic con l'API FCM v1 (permesso `cloudmessaging.topicSubscriptions.create`); il ruolo **Firebase Cloud Messaging API Admin** (`roles/firebasecloudmessaging.admin`) è stato aggiunto al service account e la subscribe v1 sul token reale riesce. Dettagli in `phases/05-notifications-infrastructure/BACKEND-NOTES.md` §5.1.
- **Formattazione:** il baseline non è allineato a `dart format`; mai lanciarlo su directory (Phase 11 CONTEXT D-38).
- **Eventi WS persi durante una riconnessione** (chiusura 4401 ogni ~15 min): refetch-on-reconnect da progettare in Phase 3.
- ~~**QUEST-03 confirmation flow** — oltre al redirect su Map tab + immagine del foglio in cima allo stack, manca da definire: c'è un dialog di conferma con costo prima dello swipe? undo window dopo l'accept? anteprima del costo (twitchPoints / coins / consumabili consigliati) dove? — da definire in UI phase.~~ — **risolto nel discuss di Phase 6 (2026-10-21):** lo swipe è la conferma, nessun dialog né undo, costo solo per story/worldMission (CONTEXT D-01/D-02/D-03).
- ~~**TRAVEL-02 confirmation dialog**~~ — **risolto nel discuss di Phase 7 (2026-10-24):** drag della pedina sulla città → foglio di pergamena con distanza, durata ed ETA da `travelPreview`, rotta disegnata dietro, "Parti"/"Resta", nessun costo (CONTEXT D-01..D-05).
- ~~**feat/party-waiting**~~ — merged (PR #32, 2026-10-26).
- ~~**BE Phase 9.1 (Spell State and Recovery Contract):** inserted 2026-10-27 from the Phase 8 discuss; the FE plan that selects `status.spellStates { spell usages recoveries }` runs only after the BE PR is merged on BE `develop`.~~ — **resolved 2026-10-27:** merged on BE `develop` (PR #14, `10e5f43`), consumed by plan 08-12 and proven by the device E2E (outcome in `phases/08-spells-section-journal-tab/BACKEND-NOTES.md` §7).
- ~~**BE Phase 9.2 (Quest Result Delivery Contract):** inserted 2026-10-27 from the Phase 9 discuss (`unacknowledgedQuestResults`, `acknowledgeQuestResult`, `QuestResult.acknowledgedAt`, seats of started quests kept by the archive); the FE plans that select `acknowledgedAt`, register the two new documents and run the device E2E wait for the BE PR merge on BE `develop` (09-CONTEXT D-09/D-18/D-21). — **BE PR #15 open (2026-10-28, `feat/09.2-quest-result-delivery-contract` → `develop`, 7/7 plans, handoff `BACKEND-NOTES.md` of the BE phase)**: the gated FE plans 09-12/09-13 run after its merge. **Note for 09-12 (review fix IN-04, 2026-10-28):** the real `PendingQuestResults` adapter must parse the unacknowledged list item by item (`QuestResult.tryFromJson` per element, skip malformed entries and orphan items), mapping only a list-level shape error to `malformed`, because `malformed` is no longer retried by the cubit; RED adapter test: one malformed + one valid item → the valid one. Also stub `getUnacknowledgedQuestResults` in `authenticated_shell_test.dart` (the cubit refetches at `start()`).~~ — **resolved 2026-10-29:** merged on BE `develop` (PR #15, `8f30d1d`), consumed by plan 09-12 and proven by the device E2E (outcome in `phases/09-combat-result-sheet/BACKEND-NOTES.md` §5).
- **F2 — BE rule change from the Phase 9 UAT (2026-10-29):** a started quest whose participant is archived should be fought as if the seat were still occupied (user: «Per quello lasciamo il posto pieno»); today the BE fights with the remaining members (BE 9.2 D-07). Routed in `phases/09-combat-result-sheet/BACKEND-NOTES.md` §5.2; BE Phase 10 or a 9.3 companion — decision pending.
- **F1 / F3 — FE items from the Phase 9 UAT:** F1 party counter / torn state of the own quest not live during the own travel (fix on `feat/09-combat-result-sheet` before the PR); F3 «In attesa del gruppo» on a due solo quest (minor, to check).
- ~~**BE Phase 10 (hardening) — BE-HARD-08 for the FE Phase 10 (2026-10-29):** **FE parked at 10/11 (2026-10-29): plans 10-01..10-10 done, reviewed, fixed, verified and audited on `feat/10-admin-panel`; 10-11 starts after the BE PR merge.** **BE PR #16 (`feat/10-hardening` → `develop`) opened as DRAFT on 2026-10-30: `pendingQuest: ID` + `QUEST_IN_PROGRESS` are in; ready after the user runs the ref migration in production (BE runbook).** additive `PendingRequestCharacter.pendingQuest` and `QUEST_IN_PROGRESS` on `completePendingRequest` while a participant's standard lane is occupied; the FE Phase 10 plan that selects the field and the device E2E run after the BE Phase 10 PR merges (proposal in `phases/10-admin-panel-innkeeper/BACKEND-NOTES.md` §2).~~ — **resolved 2026-11-01:** merged on BE `develop` (`4dc7e89`), consumed by plan 10-11 and proven by the device E2E (outcome in `phases/10-admin-panel-innkeeper/BACKEND-NOTES.md` §6).
- **FE Phase 10 UAT (2026-11-01) — to clarify with the user:** the app logged «Failed host lookup: 'localhost'» (WebSocket closed) a few times with the adb tunnel and the BE up (Wi-Fi / airplane mode?); no step failed. BE-side observations (audit target of `teleportCharacter`, list queries on unpopulated ids, rookie vs 100 HP enemy) routed in `phases/10-admin-panel-innkeeper/BACKEND-NOTES.md` §6.4. — **explained (2026-11-03/09):** the screen-off Doze and the adb tunnel lost on every USB reconnection drop `localhost`; a device-setup effect, not an app defect; not a Phase 12 item (12-CONTEXT §Deferred).
- ~~**BE Phase 10 (hardening) FE follow-ups:** map `BAD_USER_INPUT` in every classifier and `IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE` in character creation once the BE PR lands (quick task or Phase 12).~~ — **routed to Phase 12 on 2026-11-09 (HARDEN-10, CONTEXT D-13)** together with the `CityType.cityClass` → `City.size` item of the Phase 13 discuss.
- ~~FE Phase 13: from plan 13-02 the branch `feat/13-city-shops` needs BE Phase 12 on the device (cities select size/hasShop, character fragment selects pet/ownedPets); no device run before 13-11 (D-16).~~ — **resolved 2026-11-03:** BE Phase 12 merged on BE `develop` (`0585b2e`, PR #18), consumed by 13-10 and proven by the device E2E of 13-11 (outcome in `phases/13-city-shops/BACKEND-NOTES.md` §4; the latent BE defect on unpopulated nested refs under `me.currentCharacter` is routed in §5.1, no app impact).

- ~~**FE Phase 16 / BE Phase 15 (2026-11-06):** the plans that select `QuestResult.kind`, the nullable `quest`, `ambush { at, nearCity, reachedCity }` and the defeat push category, and the device E2E, run after the BE Phase 15 PR merges on BE `develop` (gate pattern 15-08); names fixed in the BE `15-REPO-RULES.md`; the BE holds the ambush reports until the arrival, so the carousel never opens mid-travel. **Update 2026-11-06 evening:** BE Phase 15 executed 12/12 and PR #24 opened towards BE `develop`; FE 16-07/16-08 run after its merge.~~ — **resolved 2026-11-09:** merged on BE `develop` (`9103440`, PR #24), consumed by plan 16-07 and proven by the device E2E of 16-08 against BE `develop` `6be50d2` (outcome in `phases/16-travel-ambushes/BACKEND-NOTES.md` §4; questions §5, among them the user's detour-safety rule already honoured by BE D-03).

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 261022-f0n | worldMission listed and acceptable only in its own city (D-11/D-16 amended, user correction) | 2026-10-22 | 10d6298 | [261022-f0n-worldmission-listed-and-acceptable-only-](./quick/261022-f0n-worldmission-listed-and-acceptable-only-/) |
| fast-261022 | quest parsing tolerant to catalog items without description and prizeItem as AssetQuantity (board empty with the live catalog) | 2026-10-22 | e4211cc | — (gsd-fast, inline) |
| fast-261022b | prize loot crash in the quest sheet (effect/power selected for prizeItem, LootItemCard null-safe) | 2026-10-22 | c663be2 | — (gsd-fast, inline) |
| 261022-qkx | tear geometry: horizontal tear at 10% height, lower piece slides off-screen unclipped, seeded jaggedness (D-06 amended after the device UAT) | 2026-10-22 | f8e08ef | [261022-qkx-tear-geometry-horizontal-tear-near-the-t](./quick/261022-qkx-tear-geometry-horizontal-tear-near-the-t/) |
| 261025-grp | waiting-for-party label (k/N), abandonQuest with parchment confirmation, questCancelled push category (BE 09-19 contract; branch feat/party-waiting from feat/07-travel) | 2026-10-25 | 4633b3f | [261025-grp-party-waiting-abandon](./quick/261025-grp-party-waiting-abandon/) |
| 261026-gld | dashed route (preview and remaining part) in primaryGold after the device UAT (D-06 amended, user feedback on step 3) | 2026-10-26 | 8ba1154 | [261026-gld-gold-route-dash](./quick/261026-gld-gold-route-dash/) |
| 261026-prt | live party counter: questUpdated subscription watched while the lane waits for the party (BE 09-20) | 2026-10-26 | 073c39f | [261026-prt-party-counter-live](./quick/261026-prt-party-counter-live/) |
| 261102-lor | drop Lore.unlocked from the lore documents and model (BE Phase 11 D-25, BE PR #17; branch fix/lore-unlocked-field from develop, to merge with the end of that phase) | 2026-11-02 | d6346a9 | [261102-lor-lore-unlocked-field](./quick/261102-lor-lore-unlocked-field/) |
| 261105-hea | `heal` as ninth spell use type («Cura», provisional icon) and tolerant parsing of unknown use types (BE quick task twin on the same branch name; branch fix/spell-heal-use-type from develop) | 2026-11-05 | 250c9f0 | [261105-hea-spell-heal-use-type](./quick/261105-hea-spell-heal-use-type/) |
| 261105-lgd | legends take the hero seats after the legend seats, before the wildcards (BE 13.1 D-08 mirror in `canRegisterWithTitle`; branch feat/quests-per-area-follow-ups stacked on fix/spell-heal-use-type) | 2026-11-05 | 6508fed | [261105-lgd-legend-hero-seat](./quick/261105-lgd-legend-hero-seat/) |
| 261105-scp | `QuestScopeListener`: reread `quests` when `characterUpdated` changes location, title or a lane's quest (BE 13.1 D-05 `quests` per area; same branch) | 2026-11-05 | d677a24 | [261105-scp-quest-scope-reread](./quick/261105-scp-quest-scope-reread/) |
