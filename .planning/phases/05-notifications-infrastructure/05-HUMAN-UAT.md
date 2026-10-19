---
status: partial
phase: 05-notifications-infrastructure
source: [05-09-PLAN.md]
started: 2026-10-19T19:17:20Z
updated: 2026-10-19T19:17:20Z
---

## Current Test

[awaiting human testing — device UAT di 05-09 Task 2 con `sendTestPush` del BE]

> Prerequisiti: BE `.env` con `FIREBASE_SERVICE_ACCOUNT` dello stesso progetto Firebase (`klimmeck-guide-app`), `DEV_AUTH_ENABLED=true`, `DEV_AUTH_ROLE=innkeeper`; FE `.env` con `DEV_AUTH_ENABLED=true` e lo stesso `DEV_AUTH_ACCESS_TOKEN`; `android/app/google-services.json` locale; l'utente dev HA un personaggio (annotare il suo id e, per questEnd, un `pendingQuestId` o un id qualsiasi); telefono `RZCY92B5BWW` (Samsung SM-S938B, Android 16) via USB, `adb reverse tcp:3000 tcp:3000`; batteria dell'app su "Senza restrizioni". Il permesso si concede a mano dalle impostazioni di sistema (D-11), mai da un prompt in-app.

## Tests

### 1. Boot BE con push abilitato

expected: BE up on :3000: the boot log shows `Push notifications enabled for Firebase project <id>` and `<id>` equals `jq -r '.project_info.project_id' android/app/google-services.json` (expected `klimmeck-guide-app`).
result: [pending]

### 2. Nessun prompt del permesso

expected: Fresh install (`flutter run -d RZCY92B5BWW`, or `adb shell pm clear it.lordreavor.klimmeckguide.klimmeck_guide` first): NO permission prompt at cold launch, splash, sign-in or Settings. Settings shows the three toggles and NO hint row (never asked).
result: [pending]

### 3. Registrazione del device

expected: `db.push_devices.find({}, {deviceId:1, platform:1, lastSeenAt:1, _id:0})` (never print `token`) → one row, `platform: "android"`; kill and relaunch → same `deviceId`, `lastSeenAt` updated.
result: [pending]

### 4. Permesso concesso / revocato a mano e riga di suggerimento

expected: Grant by hand (Settings › Apps › Guida di Klimmeck › Notifications › On, or `adb shell pm grant it.lordreavor.klimmeckguide.klimmeck_guide android.permission.POST_NOTIFICATIONS`) → back in the app: NO hint row (status `granted`). Then revoke it (same page, or `adb shell pm revoke … android.permission.POST_NOTIFICATIONS`) and return to the app. If classified `denied` → Settings shows "Le notifiche di sistema sono disattivate" + "Attiva"; "Attiva" opens the app's system settings; turn it ON and come back → the row disappears without reopening the tab → `pass`. FALLBACK: the row does NOT appear after the revoke = known C1 limitation (`shouldShowRequestRationale == false` → `notDetermined`) → `pass (C1 limitation observed)`, with device/Android version/observation noted here and in BACKEND-NOTES §2/§5. In both cases leave the permission GRANTED before step 5.
result: [pending]

### 5. Foreground: banner, tap, dedup

expected: App on the Map or another tab: `sendTestPush` for `travelEnd` (`id: "<characterId>"`), `questEnd` (`id: "<pendingQuestId>"`), `streamerLive` (no id), each `sent: 1` → a parchment banner at the top for ~5 s, NO tray entry; tap a travelEnd/questEnd banner from another tab (e.g. Settings) → Map tab; tap the streamerLive banner → Twitch app/browser opens `twitch.tv/lordreavor`. Same travelEnd sent twice within 2 min → one banner.
result: [pending]

### 6. Background: notifica di sistema e tap

expected: App in background (Home button): each of the three sends → one tray notification with the shield icon and the BE title/body; tap travelEnd/questEnd → the app resumes on the Map tab; tap streamerLive → Twitch opens.
result: [pending]

### 7. Killed: notifica di sistema e tap a freddo

expected: App killed (swipe away from Recents, NOT Force stop): each of the three sends → tray notification; tap travelEnd/questEnd → cold start → (sign-in if needed) → Map tab; tap streamerLive → Twitch opens.
result: [pending]

### 8. Toggle spenti

expected: Turn "Fine viaggio" off → travelEnd shows nothing in foreground, background and killed; same check for "Streamer in live" and "Fine quest"; turn them back on.
result: [pending]

### 9. Unregister prima del logout

expected: Logout from Settings (confirm "Esci") → the `push_devices` row for that `deviceId` is gone; a `sendTestPush` now → `targeted: 0` (or nothing delivered) and no tray entry; log in again → the row is back with the SAME `deviceId`.
result: [pending]

### 10. Smoke senza google-services.json

expected: Move the JSON to a scratch dir, `flutter clean`, `flutter run` → app boots, log `Push disabled: Firebase unavailable (PlatformException)`, the game works unchanged; restore the JSON. Optional: uninstall the app, `sendTestPush` → `pruned: 1` (closes the BE sub-item).
result: [pending]

## Summary

total: 10
passed: 0
issues: 0
pending: 10
skipped: 0
blocked: 0

## Gaps
