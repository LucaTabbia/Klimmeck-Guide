---
status: partial
phase: 04-settings-screen
source: [04-07-PLAN.md]
started: 2026-10-16T00:00:00Z
updated: 2026-10-16T00:00:00Z
---

## Current Test

[awaiting human testing]

> Prerequisiti: BE su `develop` (con 03.1) su :3000 con Mongo replica set; log di boot con la migrazione dell'indice nome (`Dropped legacy index character_name_ci_unique...` oppure indice gia' assente); `.env` app con `DEV_AUTH_ENABLED=true` e `DEV_AUTH_ACCESS_TOKEN` uguale a quello BE; l'utente dev HA un personaggio (annotare il nome); device via USB con `adb reverse tcp:3000`.

## Tests

### 1. Satchel con sette icone

expected: Open the satchel: seven icons fly out; Mappa lands in a cell spanning both rows on the left; Profilo/Diario/Libreria on top, Bacheca/Negozio/Impostazioni below; the Impostazioni icon is the new Settings SVG; no overflow stripe.
result: [pending]

### 2. Tab Impostazioni

expected: Tap Impostazioni: parchment sheet, title "Impostazioni", the character's name, sections Notifiche and Account; no AppBar; satchel still usable; 'Esci' reachable by scrolling and not covered by the satchel.
result: [pending]

### 3. Toggle persistenti al riavvio

expected: Toggle "Streamer in live" off and "Fine quest" off; kill the app; relaunch: both still off, "Fine viaggio" on.
result: [pending]

### 4. Logout e nuovo login

expected: Esci -> confirmation -> Esci: sign-in screen. Log in again (dev stub): toggles unchanged.
result: [pending]

### 5. Annulla eliminazione

expected: Elimina personaggio -> dialog names the character; Annulla: nothing happens.
result: [pending]

### 6. Eliminazione offline

expected: Airplane mode ON -> Elimina personaggio -> Elimina: inline "Errore di connessione, riprova", button usable again; airplane mode OFF.
result: [pending]

### 7. Eliminazione riuscita

expected: Elimina personaggio -> Elimina: brief in-button progress, then the character creation page with no flash of the game shell and no error.
result: [pending]

### 8. Archivio in Mongo

expected: In Mongo: the old Character has `deletedAt` set and `deletionReason: "user_request"`, `infos.name` unchanged; the User has `currentCharacter: null` and the same `twitchPoints`.
result: [pending]

### 9. Ricreazione con lo stesso nome

expected: Create a new character with the SAME name: accepted -> game shell; Settings shows the new character's name; toggles still as set in step 3 (per user, not per character).
result: [pending]

### 10. Percorso di backup userUpdated

expected: With the app on Settings, run `deleteCharacter` from a GraphQL client with the same bearer (or unset `currentCharacter` in Mongo): the app moves to the creation page by itself (userUpdated); recreate a character afterwards.
result: [pending]

### 11. Opzionale: secondo account

expected: A second account (different `DEV_AUTH_TWITCH_ID`) on the same device sees all three toggles on.
result: [pending]

### 12. Opzionale: landscape ~667 px

expected: On a ~667 px wide landscape device/emulator the satchel overlay fits without overflow.
result: [pending]
