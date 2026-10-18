---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
last_updated: "2026-10-18T14:00:00.000Z"
last_activity: 2026-10-18 -- Phase 4 closed (verified 5/5, review fixed, security 29/29); FE PR #28 open to develop
progress:
  total_phases: 12
  completed_phases: 5
  total_plans: 41
  completed_plans: 41
  percent: 100
---

# Project State

## Current Position

Phase: 04 (settings-screen) — COMPLETE (verified 2026-10-18, 5/5 success criteria; review 2 warnings fixed in TDD; E2E approved on device 2026-10-18)
Plan: 7 of 7
Completed phases: 01 (dev-auth-stub), 02 (character-creation — with BE companion phase 02.1), 03 (real-time-sync-foundation — PR #27 merged 2026-10-14), 04 (settings-screen — branch feat/04-settings-screen; BE companion Phase 03.1 merged as BE PR #6 on 2026-10-16), 11 (auth-session-bootstrap — executed ahead of phases 2–10 on user request, with the dev bypass kept)
Next Phase: 05 (Notifications Infrastructure) — depends on BE Phase 5 (FCM) — /gsd-discuss-phase 5 then /gsd-plan-phase 5
Status: Phase 04 complete — security 29/29 closed; FE PR #28 open on LucaTabbia/Klimmeck-Guide (feat/04-settings-screen → develop), ready for review and merge (no BE dependency pending)
Last activity: 2026-10-18 -- Phase 4 closed: E2E approved, verification 5/5, review WR-01/WR-02 fixed in TDD (762 tests), security 29/29, PR #28 opened to develop; next: merge PR #28, then /gsd-discuss-phase 5 (needs BE Phase 5 FCM)

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
