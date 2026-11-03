---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-11-03T18:41:46.000Z"
last_activity: 2026-11-03 -- Phase 13 complete (11/11): device E2E approved against BE develop 0585b2e, SHOP-02/03/04 ticked, D-17 fixed during the UAT; FE PR #37 feat/13-city-shops -> develop open
progress:
  total_phases: 17
  completed_phases: 12
  total_plans: 122
  completed_plans: 112
  percent: 92
---

# Project State

## Current Position

Phase: 13 (City Shops) — complete, 11/11 (2026-11-03) on `feat/13-city-shops` (from `develop` `b6eb4d4`): plans 13-01..13-09 executed, reviewed, fixed, verified and audited; 13-10 (schema gate) green against the merged BE Phase 12 (`origin/develop` `0585b2e`, PR #18; A1/A2/A3 confirmed, 43/43 documents OK); 13-11 device E2E run on the Android phone (`13-HUMAN-UAT.md`: steps 1–10 pass, 11 skipped; D-17 companion dropdown fixed in TDD during the UAT), SHOP-02/03/04 ticked, handoff `phases/13-city-shops/BACKEND-NOTES.md` written; FE PR not yet opened
Plan: 11 of 11
Completed phases: 12 (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13)
Next Phase: merge the FE PR #37 `feat/13-city-shops` → `develop` (opened 2026-11-03; the BE Phase 12 PR #18 is already merged); then FE 14 → 15 → 16 → 17 (each after its BE companion merge), FE 12 (Hardening) last
Status: Phase 13 complete (2026-11-03) — BE Phase 12 merged on BE `develop` (`0585b2e`, PR #18 `feat/12-negozi-per-citta`); 13-10 schema gate green (A1/A2/A3 confirmed, 43/43 OK); 13-11 device E2E approved by the user (steps 1–9 pass, optional 10 pass with a live `ITEM_NOT_IN_SHOP` curation, optional 11 skipped: Redis not running locally). Step 4 failed on the first build and the user's rule became D-17 (companion section as a dropdown like «Magie imparate»), fixed in TDD on the branch during the UAT (`8ac0ede`, `e26c72a`, `6cda912`); gates after the fix: full suite 3031 green in 72 s, analyzer 50 info / 0 error / 0 warning, trailers 0 over 79 commits. Of the review-fix notes for the UAT (13-REVIEW-FIX.md WR-01, WR-02, IN-04) only IN-04 is covered by the D-17 tests; WR-02 (a pet bought or sold while still in a selection) was not reported in the run. Latent BE defect (nested refs not populated under `me.currentCharacter`, no app impact) routed in `phases/13-city-shops/BACKEND-NOTES.md` §5.1. Awaiting the FE PR by the user.
Last activity: 2026-11-03 -- Phase 13 plan 13-11 (device E2E + handoff) executed: UAT recorded, SHOP-02/03/04 complete, BACKEND-NOTES.md written; phase closed, FE PR #37 → develop opened

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
- **FE Phase 10 UAT (2026-11-01) — to clarify with the user:** the app logged «Failed host lookup: 'localhost'» (WebSocket closed) a few times with the adb tunnel and the BE up (Wi-Fi / airplane mode?); no step failed. BE-side observations (audit target of `teleportCharacter`, list queries on unpopulated ids, rookie vs 100 HP enemy) routed in `phases/10-admin-panel-innkeeper/BACKEND-NOTES.md` §6.4.
- **BE Phase 10 (hardening) FE follow-ups:** map `BAD_USER_INPUT` in every classifier and `IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE` in character creation once the BE PR lands (quick task or Phase 12).
- ~~FE Phase 13: from plan 13-02 the branch `feat/13-city-shops` needs BE Phase 12 on the device (cities select size/hasShop, character fragment selects pet/ownedPets); no device run before 13-11 (D-16).~~ — **resolved 2026-11-03:** BE Phase 12 merged on BE `develop` (`0585b2e`, PR #18), consumed by 13-10 and proven by the device E2E of 13-11 (outcome in `phases/13-city-shops/BACKEND-NOTES.md` §4; the latent BE defect on unpopulated nested refs under `me.currentCharacter` is routed in §5.1, no app impact).

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
