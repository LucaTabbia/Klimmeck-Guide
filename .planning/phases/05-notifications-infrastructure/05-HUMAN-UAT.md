---
status: complete
phase: 05-notifications-infrastructure
source: [05-09-PLAN.md]
started: 2026-10-19T19:17:20Z
updated: 2026-10-20T19:21:00+02:00
---

## Current Test

[complete — UAT su device del 2026-10-20 (17:50–19:21), approvato dall'utente]

> Prerequisiti: BE `.env` con `FIREBASE_SERVICE_ACCOUNT` dello stesso progetto Firebase (`klimmeck-guide-app`), `DEV_AUTH_ENABLED=true`, `DEV_AUTH_ROLE=innkeeper`; FE `.env` con `DEV_AUTH_ENABLED=true` e lo stesso `DEV_AUTH_ACCESS_TOKEN`; `android/app/google-services.json` locale; l'utente dev HA un personaggio (annotare il suo id e, per questEnd, un `pendingQuestId` o un id qualsiasi); telefono `RZCY92B5BWW` (Samsung SM-S938B, Android 16) via USB, `adb reverse tcp:3000 tcp:3000`; batteria dell'app su "Senza restrizioni". Il permesso si concede a mano dalle impostazioni di sistema (D-11), mai da un prompt in-app.

> Sessione effettiva (2026-10-20, 17:50–19:21): eseguita dall'utente (Luca) con l'orchestratore che pilotava `sendTestPush` e `adb`. Device Samsung SM-S938B (`RZCY92B5BWW`), Android 16 (API 36). BE locale su :3000 dal branch `feat/06-eventsub-punti-canale-streamer-live` (contiene il codice push di Phase 5), `FIREBASE_SERVICE_ACCOUNT` del progetto `klimmeck-guide-app`. **Login Twitch reale nell'app** (FE `DEV_AUTH_ENABLED=false`); il dev bypass del BE (`DEV_AUTH_ENABLED=true`, `DEV_AUTH_ROLE=innkeeper`, identità dev `dev-twitch-id`, un User separato) è stato usato solo per chiamare `sendTestPush` con `targetUserId: 6ac61251c703dc50b8544865` (l'account reale dell'utente) per i tipi personali, e senza target per `streamerLive` (topic).

## Tests

### 1. Boot BE con push abilitato

expected: BE up on :3000: the boot log shows `Push notifications enabled for Firebase project <id>` and `<id>` equals `jq -r '.project_info.project_id' android/app/google-services.json` (expected `klimmeck-guide-app`).
result: pass (indirect)
note: l'orchestratore non ha letto la riga di boot del BE; il progetto Firebase del service account è `klimmeck-guide-app` (letto via firebase-admin in una diagnostica) e ogni push è arrivato al device, quindi FE e BE condividono il progetto.

### 2. Nessun prompt del permesso

expected: Fresh install (`flutter run -d RZCY92B5BWW`, or `adb shell pm clear it.lordreavor.klimmeckguide.klimmeck_guide` first): NO permission prompt at cold launch, splash, sign-in or Settings. Settings shows the three toggles and NO hint row (never asked).
result: pass
note: a cold launch, splash, sign-in Twitch e Settings nessun prompt (l'utente non ne ha riportati; `dumpsys package` mostrava `POST_NOTIFICATIONS granted=false` senza `USER_SET` fino al grant dell'orchestratore alle 18:13:58, quindi nessun prompt è mai stato mostrato). Settings mostrava i 3 toggle senza riga di suggerimento.

### 3. Registrazione del device

expected: `db.push_devices.find({}, {deviceId:1, platform:1, lastSeenAt:1, _id:0})` (never print `token`) → one row, `platform: "android"`; kill and relaunch → same `deviceId`, `lastSeenAt` updated.
result: pass
note: `push_devices` con 1 riga per l'utente (`deviceId c3badace-7496-48cd-a59d-8847d0c2c990`, `platform android`); dopo `am force-stop` + rilancio alle 18:07 la riga ha mantenuto lo stesso `deviceId` con `lastSeenAt` aggiornato (16:07:09Z); il datastore conteneva `klimmeck.push.deviceId` e `klimmeck.push.activeUserId = 6ac61251c703dc50b8544865`; la sessione salvata è stata ripristinata al rilancio senza nuovo login.

### 4. Permesso concesso / revocato a mano e riga di suggerimento

expected: Grant by hand (Settings › Apps › Guida di Klimmeck › Notifications › On, or `adb shell pm grant it.lordreavor.klimmeckguide.klimmeck_guide android.permission.POST_NOTIFICATIONS`) → back in the app: NO hint row (status `granted`). Then revoke it (same page, or `adb shell pm revoke … android.permission.POST_NOTIFICATIONS`) and return to the app. If classified `denied` → Settings shows "Le notifiche di sistema sono disattivate" + "Attiva"; "Attiva" opens the app's system settings; turn it ON and come back → the row disappears without reopening the tab → `pass`. FALLBACK: the row does NOT appear after the revoke = known C1 limitation (`shouldShowRequestRationale == false` → `notDetermined`) → `pass (C1 limitation observed)`, with device/Android version/observation noted here and in BACKEND-NOTES §2/§5. In both cases leave the permission GRANTED before step 5.
result: pass (no C1 limitation observed)
note: permesso concesso via `adb shell pm grant` → nessuna riga di suggerimento; l'utente lo ha poi revocato dalle impostazioni di sistema Android → al ritorno è apparsa la riga "Le notifiche di sistema sono disattivate" + "Attiva"; "Attiva" ha aperto la pagina di sistema dell'app; l'utente ha riattivato le notifiche (flag `USER_SET` confermato) e la riga è scomparsa. Parole dell'utente: "La riga attiva era presente". Il limite C1 NON si è presentato su questo device (Samsung SM-S938B, Android 16). Permesso lasciato concesso prima del passo 5.

### 5. Foreground: banner, tap, dedup

expected: App on the Map or another tab: `sendTestPush` for `travelEnd` (`id: "<characterId>"`), `questEnd` (`id: "<pendingQuestId>"`), `streamerLive` (no id), each `sent: 1` → a parchment banner at the top for ~5 s, NO tray entry; tap a travelEnd/questEnd banner from another tab (e.g. Settings) → Map tab; tap the streamerLive banner → Twitch app/browser opens `twitch.tv/lordreavor`. Same travelEnd sent twice within 2 min → one banner.
result: pass
note: travelEnd (18:02:38) → banner pergamena, nessuna voce in tray; secondo travelEnd toccato da Settings → Map tab ("Ha funzionato"); banner questEnd mostrato; banner streamerLive mostrato e il tap ha aperto Twitch lordreavor ("Ha funzionato"); dedup: due travelEnd identici (`dedup-1`) alle 18:13:01 e 18:13:06 → un solo banner ("Confermo"). I primi due invii streamerLive (18:04, 18:05) non sono arrivati al device perché il token **non era iscritto al topic** (finding BE/ops in Gaps); dopo che l'orchestratore ha iscritto il token con l'API legacy, streamerLive è stato consegnato in tutti gli stati.

### 6. Background: notifica di sistema e tap

expected: App in background (Home button): each of the three sends → one tray notification with the shield icon and the BE title/body; tap travelEnd/questEnd → the app resumes on the Map tab; tap streamerLive → Twitch opens.
result: pass
note: tre notifiche in tray (travelEnd/questEnd/streamerLive) con l'icona dello scudo e titolo/testo del BE, ricevute alle 18:17:31/34/38; il tap su travelEnd/questEnd ha ripreso l'app sulla Map tab; il tap su streamerLive ha aperto Twitch ("Funzionano").

### 7. Killed: notifica di sistema e tap a freddo

expected: App killed (swipe away from Recents, NOT Force stop): each of the three sends → tray notification; tap travelEnd/questEnd → cold start → (sign-in if needed) → Map tab; tap streamerLive → Twitch opens.
result: pass
note: processo terminato alle 18:18:55 (swipe da Recenti); FCM ha avviato l'isolate in background (`FLTFireBGExecutor: Creating background FlutterEngine instance`, `FlutterFirebaseMessagingBackgroundService started!`), messaggi ricevuti alle 18:18:58/19:02/19:06, notifiche pubblicate sul canale `klimmeck_events` (importance 4, titolo "Viaggio completato", testo "Il tuo personaggio è arrivato a destinazione."); tap → cold start, sessione ripristinata, Map tab; tap sul live → Twitch ("le notifiche sono arrivate e mi hanno reindirizzato correttamente").

### 8. Toggle spenti

expected: Turn "Fine viaggio" off → travelEnd shows nothing in foreground, background and killed; same check for "Streamer in live" and "Fine quest"; turn them back on.
result: pass
note: tutti e tre i toggle spenti. Foreground: 3 messaggi ricevuti (18:21:01/03/06), tray 0, nessun banner riportato dall'utente (nessuna frase esplicita dell'utente su questo sotto-passo); background: 3 ricevuti, tray 0; killed: isolate in background avviato, 3 ricevuti, tray 0. Toggle riattivati dopo il passo.

### 9. Unregister prima del logout

expected: Logout from Settings (confirm "Esci") → the `push_devices` row for that `deviceId` is gone; a `sendTestPush` now → `targeted: 0` (or nothing delivered) and no tray entry; log in again → the row is back with the SAME `deviceId`.
result: pass
note: dopo "Esci": righe `push_devices` 0, `sendTestPush` → `targeted 0`, tray 0, `activeUserId` cancellato sul device; dopo il nuovo login: 1 riga con lo **stesso** `deviceId c3badace-…`, `lastSeenAt` 16:24:06Z, `activeUserId` ripristinato.

### 10. Smoke senza google-services.json

expected: Move the JSON to a scratch dir, `flutter clean`, `flutter run` → app boots, log `Push disabled: Firebase unavailable (PlatformException)`, the game works unchanged; restore the JSON. Optional: uninstall the app, `sendTestPush` → `pruned: 1` (closes the BE sub-item).
result: pass
note: build debug senza JSON (JSON spostato fuori, `flutter clean`) installata e avviata: log `Push disabled: Firebase unavailable (PlatformException)` poi `Initialising connection` (gioco invariato, sessione mantenuta); JSON ripristinato (708 byte, non tracciato). Una disconnessione del device ha interrotto il passo una volta; la ripetizione è riuscita. Prune opzionale: `adb uninstall` → `sendTestPush` → `{ targeted 1, sent 0, pruned 1, failed 1 }` e righe `push_devices` 0 → chiude la voce di pruning Android della HUMAN-UAT BE Phase 5. Build normale ricostruita e reinstallata (l'utente rifà il login: installazione nuova → nuovo deviceId, atteso per D-06).

## Summary

total: 10
passed: 10
issues: 0
pending: 0
skipped: 0
blocked: 0

## Gaps

Nessun gap di Phase 5. Le voci seguenti sono **BE/ops finding, not a Phase 5 gap** e osservazioni d'ambiente.

- **BE/ops finding, not a Phase 5 gap — iscrizione al topic `streamer-live` negata dall'IAM.** `firebase-admin` 14.5.0 implementa `subscribeToTopic` tramite l'endpoint FCM v1 `projects/*/registrations/*/topicSubscriptions`, che richiede il permesso IAM `cloudmessaging.topicSubscriptions.create`. Il service account `…@klimmeck-guide-app.iam.gserviceaccount.com` non lo ha: `registerPushDevice` del BE logga `subscribeToTopic(streamer-live): 1 token failed (messaging/authentication-error)` (errore per token: `Permission 'cloudmessaging.topicSubscriptions.create' denied on resource '//googlecloudmessaging.googleapis.com/projects/klimmeck-guide-app/registrations/…'`) e i device non ricevono mai `streamerLive`. Il percorso legacy (`subscribeToTopicLegacy`, Instance ID API, disponibile fino al 2027-09-29) riesce. Rimedio: concedere al service account il ruolo **Firebase Cloud Messaging API Admin** (`roles/firebasecloudmessaging.admin`) in Google Cloud IAM, poi ri-registrare (kill + rilancio dell'app); hardening BE opzionale: fallback alla chiamata legacy quando v1 risponde `authentication-error`. Riportato in `BACKEND-NOTES.md` §5 come action item per il BE.
- **Osservazione d'ambiente:** un conflitto sulla porta 3000 con un dev server locale non correlato ha ritardato il primo login Twitch (problema d'ambiente, non dell'app).
- **Osservazione (fuori scope Phase 5):** riga di log preesistente `CachedSvg: failed to load Invalid argument(s): No host specified in URI` (URL di un asset senza host). Solo annotata.
