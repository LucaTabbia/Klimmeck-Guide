---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-10-14T13:10:11.774Z"
last_activity: 2026-10-14 -- Phase 3 plan 03-05 complete (keep-alive socket, watchConnection and real-socket resubscribe/token/teardown tests)
progress:
  total_phases: 12
  completed_phases: 3
  total_plans: 34
  completed_plans: 30
  percent: 88
---

# Project State

## Current Position

Phase: 03 (real-time-sync-foundation) — EXECUTING
Plan: 1 of 9
Completed phases: 01 (dev-auth-stub), 02 (character-creation — with BE companion phase 02.1), 11 (auth-session-bootstrap — executed ahead of phases 2–10 on user request, with the dev bypass kept)
Next Phase: 03 (Real-Time Sync Foundation) — /gsd-execute-phase 3 (sequential executors, no worktrees; plan 03-09 waits for the BE Phase 3 schema)
Status: Executing Phase 03
Last activity: 2026-10-14 -- Phase 3 plan 03-05 complete (keep-alive socket, watchConnection and real-socket resubscribe/token/teardown tests)

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

- Scelta libreria push notification Flutter (firebase_messaging è standard)
- ~~Scelta client GraphQL subscription~~ — risolta in Phase 3 discuss (2026-10-14): resta `graphql_flutter` 5.2.1 (WebSocketLink + WsReconnectPolicy di Phase 11)
- ~~Flusso OAuth Twitch: webview in-app vs deep link / universal link~~ — **risolto in Phase 11:** login mediato dal backend via browser di sistema + deep link `klimmeck://auth` (Twitch non supporta PKCE né redirect con custom scheme; l'app non possiede chiavi Twitch).
- **Chiavi Twitch non ancora disponibili:** il login reale su device non è mai stato esercitato (UAT pendenti in `phases/11-auth-session-bootstrap/11-HUMAN-UAT.md`). Fino ad allora si lavora con il dev bypass (`DEV_AUTH_ENABLED=true`; `DEV_AUTH_START_SIGNED_OUT=true` per vedere il sign-in).
- **Backend:** dalla sua Phase 2 richiede un'identità su ogni chiamata; `DEV_AUTH_ACCESS_TOKEN` deve coincidere con quello del BE (≥ 16 caratteri). Contratto in `Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md`. Decisione BE D-26 (finestra di grazia del refresh) in attesa dell'utente.
- **Entry point del logout:** arriva con Settings (Phase 4); `AuthCubit.logout()` e `LogoutConfirmationDialog` esistono e sono testati ma non sono raggiungibili dal gioco.
- **Formattazione:** il baseline non è allineato a `dart format`; mai lanciarlo su directory (Phase 11 CONTEXT D-38).
- **Eventi WS persi durante una riconnessione** (chiusura 4401 ogni ~15 min): refetch-on-reconnect da progettare in Phase 3.
- **QUEST-03 confirmation flow** — oltre al redirect su Map tab + immagine del foglio in cima allo stack, manca da definire: c'è un dialog di conferma con costo prima dello swipe? undo window dopo l'accept? anteprima del costo (twitchPoints / coins / consumabili consigliati) dove? — da definire in UI phase.
- **TRAVEL-02 confirmation dialog** — contenuto e stile del dialog di conferma viaggio (destination, ETA dal backend, eventuale costo, pulsanti) — da definire in UI phase. Requirement già marcato TBD.
