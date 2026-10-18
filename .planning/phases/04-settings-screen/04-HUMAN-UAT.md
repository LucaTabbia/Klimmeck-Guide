---
status: complete
phase: 04-settings-screen
source: [04-07-PLAN.md]
started: 2026-10-16T00:00:00Z
updated: 2026-10-18T00:00:00Z
---

## Current Test

[complete]

> Prerequisiti: BE su `develop` (con 03.1) su :3000 con Mongo replica set; log di boot con la migrazione dell'indice nome (`Dropped legacy index character_name_ci_unique...` oppure indice gia' assente); `.env` app con `DEV_AUTH_ENABLED=true` e `DEV_AUTH_ACCESS_TOKEN` uguale a quello BE; l'utente dev HA un personaggio (annotare il nome); device via USB con `adb reverse tcp:3000`.

## Tests

### 1. Satchel con sette icone

expected: Open the satchel: seven icons fly out; Mappa lands in a cell spanning both rows on the left; Profilo/Diario/Libreria on top, Bacheca/Negozio/Impostazioni below; the Impostazioni icon is the new Settings SVG; no overflow stripe.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 2. Tab Impostazioni

expected: Tap Impostazioni: parchment sheet, title "Impostazioni", the character's name, sections Notifiche and Account; no AppBar; satchel still usable; 'Esci' reachable by scrolling and not covered by the satchel.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 3. Toggle persistenti al riavvio

expected: Toggle "Streamer in live" off and "Fine quest" off; kill the app; relaunch: both still off, "Fine viaggio" on.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 4. Logout e nuovo login

expected: Esci -> confirmation -> Esci: sign-in screen. Log in again (dev stub): toggles unchanged.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 5. Annulla eliminazione

expected: Elimina personaggio -> dialog names the character; Annulla: nothing happens.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 6. Eliminazione offline

expected: Airplane mode ON -> Elimina personaggio -> Elimina: inline "Errore di connessione, riprova", button usable again; airplane mode OFF.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 7. Eliminazione riuscita

expected: Elimina personaggio -> Elimina: brief in-button progress, then the character creation page with no flash of the game shell and no error.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 8. Archivio in Mongo

expected: In Mongo: the old Character has `deletedAt` set and `deletionReason: "user_request"`, `infos.name` unchanged; the User has `currentCharacter: null` and the same `twitchPoints`.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 9. Ricreazione con lo stesso nome

expected: Create a new character with the SAME name: accepted -> game shell; Settings shows the new character's name; toggles still as set in step 3 (per user, not per character).
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 10. Percorso di backup userUpdated

expected: With the app on Settings, run `deleteCharacter` from a GraphQL client with the same bearer (or unset `currentCharacter` in Mongo): the app moves to the creation page by itself (userUpdated); recreate a character afterwards.
result: pass
note: confermato dall'utente (esito complessivo: ok)

### 11. Opzionale: secondo account

expected: A second account (different `DEV_AUTH_TWITCH_ID`) on the same device sees all three toggles on.
result: skipped
note: non riportato dall'utente

### 12. Opzionale: landscape ~667 px

expected: On a ~667 px wide landscape device/emulator the satchel overlay fits without overflow.
result: skipped
note: non riportato dall'utente

## Esito

Approvazione complessiva dell'utente il 2026-10-18 ("Ho eseguito il check della fase 4 ed è ok"): passi 1-10 pass, passi opzionali 11-12 non riportati. Le note per passo riflettono solo l'esito complessivo, non osservazioni dettagliate. Device: Android fisico (Samsung via USB, `adb reverse tcp:3000`), app in dev auth bypass (`DEV_AUTH_ENABLED=true`). Backend: BE `develop` @ `d578ad2` (Merge PR #6 feat/03.1-character-deletion-contract, `deleteCharacter: User!`).
