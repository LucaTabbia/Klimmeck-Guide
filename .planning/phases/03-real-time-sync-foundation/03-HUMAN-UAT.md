---
status: complete
phase: 03-real-time-sync-foundation
source: [03-09-PLAN.md]
started: 2026-10-14T00:00:00Z
updated: 2026-10-14T23:00:00Z
---

## Current Test

[complete]

Contesto sessione: device fisico Samsung SM S938B, Android 16 (API 36), via USB con `adb reverse tcp:3000 tcp:3000` (il `localhost:3000` del `.env` raggiunge il BE sul Mac). Login Twitch reale (`DEV_AUTH_ENABLED=false`), non lo stub dev. BE sul branch `feat/03-autorizzazione-ownership-ruoli-audit` al commit `62890b6`, locale su :3000. Segnale dell'utente: `approved`. Data: 2026-10-14.

> Prerequisiti: BE sul branch `feat/03-autorizzazione-ownership-ruoli-audit` in locale su :3000 con Mongo (replica set, change stream) e contratto wave 1; `.env` dell'app con `DEV_AUTH_ENABLED=true` e `DEV_AUTH_ACCESS_TOKEN` uguale a quello del BE (nella sessione effettiva: login Twitch reale, vedi Contesto sessione); l'utente dev HA un personaggio. Tenere visibili i log di `flutter run` (righe `[Sync]`).
> Registrare solo esiti e codici: nessun token, valore di `.env` o payload utente.

## Tests

### 1. Cold start con snapshot

expected: Il main shell mostra il personaggio; i log BE mostrano un solo `connection_init` e due subscription (`userUpdated`, `characterUpdated`), ciascuna con uno snapshot.
result: pass

### 2. twitchPoints e role live

expected: Cambiando `twitchPoints` dell'utente in Mongo nessuna UI cambia (D-18), ma log/BlocObserver/debugger mostrano `AuthAuthenticated.user.twitchPoints` aggiornato; idem per `role` (`innkeeper` e ritorno).
result: pass

### 3. Status e monete del personaggio live

expected: Cambiando `status.currentLifePoints` / monete in Mongo, Diario (Punti vita / Monete) e monete dello Shop si aggiornano in tempo reale senza spinner.
result: pass

### 4. Modalità aereo 30 s

expected: Modalità aereo ON ~30 s, cambio monete in Mongo, modalità aereo OFF: entro pochi secondi le nuove monete compaiono, nessun banner/spinner (snapshot alla ri-sottoscrizione).
result: pass

### 5. Ciclo 4401 (scadenza JWT)

expected: Alla scadenza del JWT (~15 min, o forzata dal BE) la riconnessione è invisibile; la modifica Mongo successiva arriva ancora live; il secondo `connection_init` porta un token fresco (log BE).
result: pass

### 6. Resume da background

expected: App in background > 1 min, cambio monete in Mongo, ritorno in foreground: valore aggiornato (refetch al resume). Abbassare solo la tendina notifiche non scatena refetch (nessuna richiesta `getMe`/`character` nel log BE).
result: pass

### 7. Wifi -> cellulare / perdita di rete < 3 min

expected: Cambio wifi->cellulare (device) o Network Link Conditioner "100% loss" (simulatore) per < 3 min, poi ripristino: recupero senza UI; il socket viene ristabilito (il ping keep-alive chiude il socket morto).
result: pass

### 8. BE spento > 3 minuti

expected: BE fermo > 3 minuti con app in foreground: schermata SignIn con "Connessione persa, accedi di nuovo."; riavviato il BE, il login (dev stub) riporta nello shell.
result: pass
note: nota orchestratore, dai log flutter: con il BE spento l'app ha loggato `Disconnected from websocket` e ha ritentato con backoff 1, 2, 4, 8, 16, 32 poi 60 s, senza crash e senza UI mostrata.

### 9. Forma di FORBIDDEN su id altrui

expected: Con `currentCharacter` dell'utente dev impostato in Mongo su un id di un altro utente e app riavviata (o client GraphQL sul WS): il rifiuto è `next{errors[FORBIDDEN]}` + `complete`; l'app NON ri-sottoscrive in loop (`[Sync] characterUpdated rejected: FORBIDDEN` compare una volta) e segue una sola richiesta `GetMe`. Ripristinare il vero `currentCharacter`. Forma osservata da registrare in BACKEND-NOTES §5.
result: pass

### 10. Percorso di cancellazione personaggio

expected: Togliendo `currentCharacter` dell'utente in Mongo l'app passa in silenzio alla creazione personaggio (D-09), gli eventuali dialog aperti si chiudono; rimettendolo, torna lo shell.
result: pass

### 11. Teardown (via sync-lost)

expected: Il logout non è raggiungibile dalla UI (Phase 4): dopo la schermata SignIn del passo 8 il BE mostra il socket chiuso e nessun ulteriore traffico di subscription.
result: pass

### 12. Opzionale: ripetere 6 e 8 su iOS fisico

expected: Passi 6 e 8 ripetuti su un device iOS fisico con lo stesso esito.
result: skipped
note: opzionale, nessun device iOS riportato
