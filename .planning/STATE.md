---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: executing
last_updated: "2026-04-14T00:00:00.000Z"
last_activity: 2026-04-14 -- Auth split: Phase 1 diventa Dev Auth Stub; il planning OAuth originale migra a Phase 11; Hardening shift a Phase 12
progress:
  total_phases: 12
  completed_phases: 0
  total_plans: 5
  completed_plans: 0
  percent: 0
---

# Project State

## Current Position

Phase: Not started (defining requirements)
Plan: —
Status: Ready to execute
Last activity: 2026-04-14 -- Auth split: Phase 1 diventa Dev Auth Stub; Phase 11 = full OAuth; Hardening = Phase 12

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
- Scelta client GraphQL subscription (ferry / graphql_flutter già in uso?)
- Flusso OAuth Twitch: webview in-app vs deep link / universal link
- **QUEST-03 confirmation flow** — oltre al redirect su Map tab + immagine del foglio in cima allo stack, manca da definire: c'è un dialog di conferma con costo prima dello swipe? undo window dopo l'accept? anteprima del costo (twitchPoints / coins / consumabili consigliati) dove? — da definire in UI phase.
- **TRAVEL-02 confirmation dialog** — contenuto e stile del dialog di conferma viaggio (destination, ETA dal backend, eventuale costo, pulsanti) — da definire in UI phase. Requirement già marcato TBD.
