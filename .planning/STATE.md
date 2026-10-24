---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: planning
last_updated: "2026-10-24T14:30:00.000Z"
last_activity: 2026-10-24
progress:
  total_phases: 12
  completed_phases: 7
  total_plans: 62
  completed_plans: 62
  percent: 100
---

# Project State

## Current Position

Phase: 7 (travel) — CONTEXT GATHERED 2026-10-24 (interactive discuss, 07-CONTEXT D-01..D-20; BE Phase 8 contract merged on BE develop with PR #11 and PR #12, no lockstep)
Plan: 0 of TBD
Completed phases: 7 (1, 2, 3, 4, 5, 6, 11)
Next Phase: 07 (travel) — /gsd-plan-phase 7 on branch feat/07-travel; BE Phase 9 (Combat Result & Admin Outcomes) discussed in the same session (BE 09-CONTEXT), it unblocks FE Phases 9 and 10
Status: Phase 7 context gathered — ready to plan (/gsd-plan-phase 7); FE PR #30 (Phase 6) merged 2026-10-24
Last activity: 2026-10-24 -- Phase 7 discuss: pawn-drag trigger, parchment confirmation with travelPreview and drawn route, floating remaining-time label, Board and Shop only on a city marker, error catalogue by code, camera-only travelEnd popup; BE Phase 9 discussed the same day (resolver port with placeholder rules, aid/death chain, XP/level/HP tables, result contract, GM queue, shop guard)

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
- **TRAVEL-02 confirmation dialog** — contenuto e stile del dialog di conferma viaggio (destination, ETA dal backend, eventuale costo, pulsanti) — da definire in UI phase. Requirement già marcato TBD.

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 261022-f0n | worldMission listed and acceptable only in its own city (D-11/D-16 amended, user correction) | 2026-10-22 | 10d6298 | [261022-f0n-worldmission-listed-and-acceptable-only-](./quick/261022-f0n-worldmission-listed-and-acceptable-only-/) |
| fast-261022 | quest parsing tolerant to catalog items without description and prizeItem as AssetQuantity (board empty with the live catalog) | 2026-10-22 | e4211cc | — (gsd-fast, inline) |
| fast-261022b | prize loot crash in the quest sheet (effect/power selected for prizeItem, LootItemCard null-safe) | 2026-10-22 | c663be2 | — (gsd-fast, inline) |
| 261022-qkx | tear geometry: horizontal tear at 10% height, lower piece slides off-screen unclipped, seeded jaggedness (D-06 amended after the device UAT) | 2026-10-22 | f8e08ef | [261022-qkx-tear-geometry-horizontal-tear-near-the-t](./quick/261022-qkx-tear-geometry-horizontal-tear-near-the-t/) |
