---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-10-27T22:26:19.237Z"
last_activity: "2026-10-27 -- Phase 9 execution started: waves 1–5 (plans 09-01..09-11) on feat/09-combat-result-sheet; 09-12/09-13 gated on the BE Phase 9.2 PR merge"
progress:
  total_phases: 12
  completed_phases: 9
  total_plans: 100
  completed_plans: 87
  percent: 87
---

# Project State

## Current Position

Phase: 9 (Combat Result Sheet) — EXECUTING (started 2026-10-27): 13 plans in 7 waves on `feat/09-combat-result-sheet` off `develop`; waves 6–7 (09-12, 09-13) gated on the BE Phase 9.2 PR merge
Plan: 6 of 13
Completed phases: 9 (1, 2, 3, 4, 5, 6, 7, 8, 11)
Next Phase: execute FE Phase 9 waves 1–5 (`/gsd-execute-phase 9`, plans 09-01..09-11); 09-12/09-13 run after the BE Phase 9.2 PR (`feat/09.2-quest-result-delivery-contract`, 7 plans, planned 2026-10-27) is merged on BE `develop`; then BE Phase 10 (`feat/10-hardening`, stacked on 9.2)
Status: Executing Phase 9 — waves 1–5 (plans 09-01..09-11) in progress, one executor at a time; 09-12/09-13 wait for the BE 9.2 merge on BE `develop`
Last activity: 2026-10-28 -- Plan 09-07 complete (QuestResultSheet for the five outcomes, animated HpDeltaBar with tap-to-skip, healGreen token); 09-12/09-13 gated on the BE Phase 9.2 PR merge

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
- **BE Phase 9.2 (Quest Result Delivery Contract):** inserted 2026-10-27 from the Phase 9 discuss (`unacknowledgedQuestResults`, `acknowledgeQuestResult`, `QuestResult.acknowledgedAt`, seats of started quests kept by the archive); the FE plans that select `acknowledgedAt`, register the two new documents and run the device E2E wait for the BE PR merge on BE `develop` (09-CONTEXT D-09/D-18/D-21).
- **BE Phase 10 (hardening) FE follow-ups:** map `BAD_USER_INPUT` in every classifier and `IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE` in character creation once the BE PR lands (quick task or Phase 12).

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
