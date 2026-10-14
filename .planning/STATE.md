---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-10-14T18:11:14.175Z"
last_activity: 2026-10-14 -- Phase 3 closed (verified, review fixed, security 46/46); FE PR waits for the BE Phase 3 PR merge (D-04)
progress:
  total_phases: 12
  completed_phases: 4
  total_plans: 34
  completed_plans: 34
  percent: 100
---

# Project State

## Current Position

Phase: 04 (settings-screen) — CONTEXT GATHERED 2026-10-15 (4 areas, D-01..D-21), branch feat/04-settings-screen
Plan: 0 of TBD
Completed phases: 01 (dev-auth-stub), 02 (character-creation — with BE companion phase 02.1), 03 (real-time-sync-foundation — PR #27 merged into develop 2026-10-14 after the BE Phase 3 PR #5), 11 (auth-session-bootstrap — executed ahead of phases 2–10 on user request, with the dev bypass kept)
Next Phase: 04 — /gsd-plan-phase 4 (BE companion Phase 03.1 "Character Deletion Contract" inserted 2026-10-15 with CONTEXT; its PR merges before the FE PR)
Status: Phase 04 context gathered — ready to plan; SET-05 (explicit character deletion from Settings) added to scope on user decision
Last activity: 2026-10-15 -- Phase 4 discuss closed: 7th satchel item + PageView tab, parchment sheet, local per-user notification toggles (default on), logout via confirmLogout, deleteCharacter proposed in BACKEND-NOTES and fixed in BE 03.1 CONTEXT; next /gsd-plan-phase 4

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
- **Entry point del logout:** arriva con Settings (Phase 4, in corso dal 2026-10-15); `confirmLogout` esiste ed è testato ma non è ancora raggiungibile dal gioco.
- **Cancellazione personaggio (SET-05):** contratto `deleteCharacter: User!` proposto in `phases/04-settings-screen/BACKEND-NOTES.md` e fissato nel CONTEXT della fase BE 03.1; il FE sviluppa con fake finché la PR BE non è merge-ata.
- **Formattazione:** il baseline non è allineato a `dart format`; mai lanciarlo su directory (Phase 11 CONTEXT D-38).
- **Eventi WS persi durante una riconnessione** (chiusura 4401 ogni ~15 min): refetch-on-reconnect da progettare in Phase 3.
- **QUEST-03 confirmation flow** — oltre al redirect su Map tab + immagine del foglio in cima allo stack, manca da definire: c'è un dialog di conferma con costo prima dello swipe? undo window dopo l'accept? anteprima del costo (twitchPoints / coins / consumabili consigliati) dove? — da definire in UI phase.
- **TRAVEL-02 confirmation dialog** — contenuto e stile del dialog di conferma viaggio (destination, ETA dal backend, eventuale costo, pulsanti) — da definire in UI phase. Requirement già marcato TBD.
