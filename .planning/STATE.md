---
gsd_state_version: 1.0
milestone: v1.0
milestone_name: milestone
status: completed
last_updated: "2026-10-20T20:30:00Z"
last_activity: 2026-10-20 -- Phase 5 complete; FE PR #29 opened to develop
progress:
  total_phases: 12
  completed_phases: 6
  total_plans: 50
  completed_plans: 50
  percent: 100
---

# Project State

## Current Position

Phase: 5 (notifications-infrastructure) — COMPLETE 2026-10-20 (9/9 plans; device UAT approved; code review 0 critical / 3 warnings fixed; verification passed 5/5; security audit filed)
Plan: 9 of 9
Completed phases: 01 (dev-auth-stub), 02 (character-creation — with BE companion phase 02.1), 03 (real-time-sync-foundation — PR #27 merged 2026-10-14), 04 (settings-screen — PR #28 merged 2026-10-18; BE companion Phase 03.1 merged as BE PR #6 on 2026-10-16), 05 (notifications-infrastructure — Android only, UAT 2026-10-20; FE PR #29 to develop opened 2026-10-20; BE Phase 5 FCM merged in BE PR #8), 11 (auth-session-bootstrap — executed ahead of phases 2–10 on user request, with the dev bypass kept)
Next Phase: 06 (quest-accept-info-sheets) — blocked by BE Phase 7 (QUEST-04: `activeStoryQuest`/`activeWorldMissionQuest` on schema + subscription); discuss can start meanwhile. BE Phase 6 (EventSub) is at its human-verify checkpoint (Twitch CLI UAT pending).
Status: Phase 5 complete — PR #29 open, awaiting review/merge
Last activity: 2026-10-20 -- Phase 5 closed: ROADMAP/STATE/PROJECT updated; stale blockers (Twitch keys, logout entry point, character deletion) resolved; new BE/ops item: FCM topic subscription needs `roles/firebasecloudmessaging.admin` on the service account

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
- **BE/ops — topic FCM `streamer-live`:** `firebase-admin` 14.5 iscrive ai topic con l'API FCM v1, che richiede il permesso IAM `cloudmessaging.topicSubscriptions.create`; il service account del progetto non lo ha e `registerPushDevice` logga `subscribeToTopic(streamer-live) … messaging/authentication-error`. Rimedio: ruolo `roles/firebasecloudmessaging.admin` al service account (o fallback legacy nel BE). Dettagli in `phases/05-notifications-infrastructure/BACKEND-NOTES.md` §5.1.
- **Formattazione:** il baseline non è allineato a `dart format`; mai lanciarlo su directory (Phase 11 CONTEXT D-38).
- **Eventi WS persi durante una riconnessione** (chiusura 4401 ogni ~15 min): refetch-on-reconnect da progettare in Phase 3.
- **QUEST-03 confirmation flow** — oltre al redirect su Map tab + immagine del foglio in cima allo stack, manca da definire: c'è un dialog di conferma con costo prima dello swipe? undo window dopo l'accept? anteprima del costo (twitchPoints / coins / consumabili consigliati) dove? — da definire in UI phase.
- **TRAVEL-02 confirmation dialog** — contenuto e stile del dialog di conferma viaggio (destination, ETA dal backend, eventuale costo, pulsanti) — da definire in UI phase. Requirement già marcato TBD.
