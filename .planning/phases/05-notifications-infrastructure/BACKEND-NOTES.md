# BACKEND-NOTES — Phase 5 Notifications Infrastructure (handoff FE → BE)

- **Fase FE:** `05-notifications-infrastructure` (requisiti NOTIF-01..NOTIF-08; decisioni D-01..D-22 in `05-CONTEXT.md`, con D-01, D-10, D-12, D-15 riviste dopo `05-RESEARCH.md` §"Conflicts with CONTEXT")
- **Data:** 2026-10-19
- **Stato:** contratto BE Phase 5 (PR #8, `origin/develop` `0828719`) consumato dal FE; UAT Android: approvato il 2026-10-20, vedi §5
- **Consumatori:** BE (chiusura del test Android di `Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/05-HUMAN-UAT.md`), FE Phase 7 (prompt del permesso alla prima conferma di viaggio, popup `travelEnd`), FE Phase 9 (popup `questEnd`/morte, `combatResult`)
- **Fonte BE:** `Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/BACKEND-NOTES.md` (§1 contratto, §2 payload, §6 ricetta `sendTestPush`). **Lo schema vince su questo documento.**

---

## 0. TL;DR per il BE

1. **Il FE chiama solo due mutation.** `registerPushDevice` dopo il login, a ogni cold start con sessione valida e a ogni `onTokenRefresh`; `unregisterPushDevice` in `AuthCubit.logout()` **PRIMA** del logout backend (serve il bearer), best-effort con tetto di **2 s**: un fallimento o un timeout non bloccano mai il logout. `sendTestPush` non è mai chiamata dall'app (solo strumento UAT).
2. **`deviceId` = UUID v4 device-wide** generato una volta e persistito in `shared_preferences` (`klimmeck.push.deviceId`); sopravvive a logout e cambio account, si perde solo con la reinstallazione. `platform: android` (iOS rinviato).
3. **Nessun `subscribeToTopic` lato client:** l'iscrizione a `streamer-live` resta del BE (BE §2).
4. **I toggle sono applicati solo sul device** (Phase 4 D-11), nei tre app state, prima di mostrare qualsiasi cosa (notifica di sistema o banner). Il BE continua a inviare a tutti i device registrati.
5. **Tipi sconosciuti scartati in silenzio:** il parsing del payload accetta solo `travelEnd` / `questEnd` / `streamerLive`; un futuro `combatResult` non rompe l'app installata (verrà mostrato solo quando Phase 9 lo aggiunge al FE).
6. **Revoca della sessione / sync persa non fanno unregister:** l'app pulisce l'utente attivo e la tray locale, ma non chiama il BE (non ha più un bearer valido). Il FE si affida al claim del token del BE (BE §5.6): il prossimo `registerPushDevice` di qualunque utente su quel device sposta la riga.
7. **Unregister saltato se il token FCM non è mai stato visto** in questa sessione (`_hasSeenToken` del coordinator): nessuna chiamata di rete e nessuna attesa nel logout quando il device non si è mai registrato (es. Firebase non disponibile).

---

## 1. Contratto usato

Documenti FE (`lib/graphql/mutations/push_mutations.dart`), verbatim:

```graphql
mutation RegisterPushDevice($input: RegisterPushDeviceInput!) {
  registerPushDevice(input: $input)
}
```

```graphql
mutation UnregisterPushDevice($deviceId: String!) {
  unregisterPushDevice(deviceId: $deviceId)
}
```

`input` = `{ deviceId, token, platform: android }`. Nessuna identità in input: il device è sempre dell'utente del bearer.

Mappatura degli errori (`lib/repository/push_device_failure.dart`, solo `errors[0].extensions.code`, mai il messaggio):

| Codice / caso | `PushDeviceFailure` | Comportamento FE |
| ------------- | ------------------- | ---------------- |
| `PUSH_INVALID_DEVICE_ID` | `invalidDeviceId` | nessun retry (bug FE) |
| `PUSH_INVALID_TOKEN` | `invalidToken` | nessun retry (bug FE) |
| `UNAUTHENTICATED` | `unauthenticated` | nessun retry (sessione finita) |
| errore di link senza codice | `connection` | retry: max 5 tentativi, backoff 1 → 30 s |
| ogni altro codice | `unknown` | retry: max 5 tentativi, backoff 1 → 30 s |

Il testo di `PushDeviceException` riporta solo il nome del caso, mai il token.

**Schema check (D-21), 2026-10-19:** `tool/schema_check` (dump dei documenti + `validate_documents.js` con `graphql-js` del BE) contro `git show origin/develop:src/schema.gql`, `origin/develop` = `0828719` (Merge PR #8): **27 documenti, 27 × OK, exit 0**, inclusi `OK RegisterPushDevice.graphql` e `OK UnregisterPushDevice.graphql`. Nessun drift sui 25 documenti preesistenti.

---

## 2. Decisioni prese dopo la ricerca (C1, C3, C4)

Registrate in `05-CONTEXT.md` come revisioni di D-01, D-10, D-12, D-15. L'utente può porre il veto in review della PR.

- **C1 — permesso via `permission_handler`.** Su Android `firebase_messaging` riporta solo `authorized`/`denied`, mai `notDetermined`: con il port di messaging il prompt di Phase 7 non partirebbe mai e la riga "notifiche disattivate" apparirebbe a ogni installazione nuova. Il port del permesso usa quindi `Permission.notification.status` + `shouldShowRequestRationale` + `request()` + `openAppSettings()`. L'app non persiste nulla (la verità è l'OS). **Limite accettato:** su Android 7–12 un utente che ha disattivato le notifiche a mano non vede la riga di suggerimento; anche su Android 13+ un permesso revocato dalle impostazioni di sistema può lasciare `shouldShowRequestRationale == false` ed essere classificato `notDetermined` (osservazione UAT in §5).
- **C2 — `POST_NOTIFICATIONS` esplicito nel manifest.** Ridondante (i plugin lo fondono già), innocuo, tenuto per leggibilità.
- **C3 — niente callback FCM "opened".** `onMessageOpenedApp` / `getInitialMessage` non scattano mai per i data message su Android: l'unica sorgente dei tap è la notifica locale costruita dal FE (`flutter_local_notifications`: callback di risposta + launch details).
- **C4 — nessun `Firebase.initializeApp()` nell'isolate in background.** L'handler non usa servizi Firebase (legge solo `data`, `shared_preferences` e mostra la notifica locale): un punto di fallimento in meno.

---

## 3. Per Phase 7 e Phase 9 (FE)

- **Call site UNICO del prompt del permesso = prima conferma di viaggio (Phase 7):** `NotificationPermissionGate.ensureRequested()` (idempotente: chiede solo se lo stato OS è `notDetermined`, altrimenti restituisce lo stato corrente; il risultato **non** blocca il viaggio), raggiunto **tramite il cubit del viaggio**: il gate si inietta nel cubit alla `create` del provider, es. `TravelConfirmationCubit(gate: context.read<NotificationPermissionGate>())`, e un'azione del cubit chiama `ensureRequested()`. **Mai** `context.read<NotificationPermissionGate>().ensureRequested()` dentro un widget (UI → Cubit → Service, D-19 / `docs/rules/architecture.md`; stesso schema di `InAppNotificationsCubit.open()`).
- **Guard da aggiornare:** `test/repository/services/push/push_boundaries_test.dart` vieta oggi ogni chiamata a `ensureRequested(` fuori dal gate; Phase 7 deve ammettere esplicitamente il file del cubit del viaggio (e solo quello) nello stesso commit che aggiunge il call site.
- **Popup di contesto:** una voce in `defaultNotificationPopups` (`lib/screens/mainScreen/components/notification_popup_registry.dart`, vuota in Phase 5): `travelEnd` (Phase 7), `questEnd`/morte (Phase 9). Il tap porta già alla Map tab e consuma l'intent; il popup si aggancia lì e ri-interroga GraphQL (`character(id)` / `pendingQuest(id)`), mai dati dal payload.
- **Banner dalle subscription:** un produttore (cubit o servizio) chiama `InAppNotificationsCubit.publish(event)`; la dedup `(type, id)` (2 min; `streamerLive` per tipo, qualunque `sentAt`, 15 min dall'ultimo banner mostrato) è già garantita, quindi push foreground e subscription possono coesistere senza doppioni. Il tap del banner passa già da `InAppNotificationsCubit.open(event)` → `NotificationTapRouter`.
- **`combatResult` (Phase 9):** aggiungere il valore a `NotificationCategory` / al parsing di `PushEvent`, la categoria dei toggle e la voce del popup; fino ad allora è scartato.

---

## 4. Note di consegna

- **Samsung / One UI, stato killed:** "killed" = swipe via da Recenti, **mai** Forza arresto (con force stop FCM non consegna finché l'utente non riapre l'app); batteria dell'app su "Senza restrizioni" per evitare "app in sospensione".
- **Deprioritizzazione FCM:** i data message high-priority che non producono una notifica visibile (permesso negato, toggle spento) possono essere declassati a priorità normale da Firebase (finestra di 7 giorni per istanza). Nessuna azione di codice: è il prezzo dei toggle lato device (BE §3).
- **Foreground fuori dalla shell di gioco** (sign-in, creazione personaggio): nessuna superficie per l'evento (né banner né notifica di sistema). Comportamento voluto e documentato: il banner richiede un personaggio.
- **Senza `google-services.json`:** l'app builda (plugin Google Services con `missingGoogleServicesStrategy = WARN`) e gira con il push disabilitato (`Push disabled: Firebase unavailable (PlatformException)`); il gioco resta invariato.

---

## 5. Esito UAT Android

UAT su device del 2026-10-20 (17:50–19:21): **approvato**, passi 1–10 pass (dettaglio in `05-HUMAN-UAT.md`). Device Samsung SM-S938B, Android 16 (API 36); BE locale su :3000 (branch `feat/06-eventsub-punti-canale-streamer-live`, con il codice push di Phase 5), progetto Firebase `klimmeck-guide-app`; login Twitch reale nell'app, `sendTestPush` chiamata tramite il dev bypass del BE con `targetUserId` dell'account reale (tipi personali) e senza target per `streamerLive` (topic).

| Stato app | `travelEnd` | `questEnd` | `streamerLive` |
|-----------|-------------|------------|----------------|
| Foreground | banner pergamena, nessuna voce in tray; tap → Map tab | banner | banner; tap → Twitch `lordreavor` |
| Background | notifica in tray (icona scudo, titolo/testo BE); tap → Map tab | notifica in tray; tap → Map tab | notifica in tray; tap → Twitch |
| Killed (swipe da Recenti) | isolate in background avviato, notifica sul canale `klimmeck_events`; tap → cold start, sessione ripristinata, Map tab | notifica in tray; tap → Map tab | notifica in tray; tap → Twitch |

- **Dedup foreground:** due `travelEnd` identici a 5 s di distanza → un solo banner.
- **Toggle spenti (tutti e tre):** messaggi ricevuti dal device in foreground, background e killed, ma nulla mostrato (tray 0, nessun banner).
- **Registrazione:** 1 riga in `push_devices` (`platform android`); dopo kill + rilancio stesso `deviceId`, `lastSeenAt` aggiornato.
- **Logout:** dopo "Esci" righe `push_devices` 0, `sendTestPush` → `targeted 0`, nulla consegnato; dopo il nuovo login la riga torna con lo **stesso** `deviceId`.
- **Prune:** app disinstallata → `sendTestPush` → `{ targeted 1, sent 0, pruned 1, failed 1 }`, righe `push_devices` 0.
- **Permesso (C1):** la revoca dalle impostazioni di sistema è stata classificata `denied` e la riga di suggerimento è apparsa: il limite C1 **non** si è presentato su Samsung SM-S938B / Android 16. Resta il limite documentato in §2 per Android 7–12 e per altri OEM.
- **Senza `google-services.json`:** l'app parte con `Push disabled: Firebase unavailable (PlatformException)`, gioco invariato.

Chiude il test Android di `Klimmeck-Guide-BE/.planning/phases/05-infrastruttura-push-fcm/05-HUMAN-UAT.md` (passi 5–7 pass, più la voce di pruning Android).

### 5.1 Action item per il BE / ops — iscrizione al topic negata dall'IAM

Non è un difetto del FE di Phase 5. `firebase-admin` 14.5.0 implementa `subscribeToTopic` tramite l'endpoint FCM v1 `projects/*/registrations/*/topicSubscriptions`, che richiede il permesso IAM `cloudmessaging.topicSubscriptions.create`. Il service account `…@klimmeck-guide-app.iam.gserviceaccount.com` non lo ha: `registerPushDevice` logga `subscribeToTopic(streamer-live): 1 token failed (messaging/authentication-error)` (errore per token: `Permission 'cloudmessaging.topicSubscriptions.create' denied on resource '//googlecloudmessaging.googleapis.com/projects/klimmeck-guide-app/registrations/…'`) e i device non ricevono mai `streamerLive`. Nell'UAT i primi due invii `streamerLive` non sono arrivati per questo motivo; dopo l'iscrizione manuale del token con l'API legacy (`subscribeToTopicLegacy`, Instance ID API, disponibile fino al 2027-09-29) la consegna è riuscita in tutti gli stati.

- **Rimedio (ops):** concedere al service account il ruolo **Firebase Cloud Messaging Admin** (`roles/firebasecloudmessaging.admin`) in Google Cloud IAM, poi ri-registrare i device (kill + rilancio dell'app).
- **Hardening BE opzionale:** fallback alla chiamata legacy quando v1 risponde `authentication-error`.

Osservazioni d'ambiente (non dell'app): un conflitto sulla porta 3000 con un dev server locale non correlato ha ritardato il primo login Twitch; riga di log preesistente `CachedSvg: failed to load Invalid argument(s): No host specified in URI` (URL di un asset senza host, fuori scope Phase 5).
