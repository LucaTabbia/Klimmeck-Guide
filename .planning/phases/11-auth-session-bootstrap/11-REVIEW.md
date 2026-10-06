---
phase: 11-auth-session-bootstrap
reviewed: 2026-10-06T18:50:42Z
depth: standard
files_reviewed: 44
files_reviewed_list:
  - lib/main.dart
  - lib/config/env_config.dart
  - lib/graphql/fragments/auth_session_fragment.dart
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/mutations/auth_mutations.dart
  - lib/graphql/queries/auth_queries.dart
  - lib/models/auth/auth_session.dart
  - lib/models/auth/login_challenge.dart
  - lib/repository/services/auth/access_token_lifetime.dart
  - lib/repository/services/auth/auth.dart
  - lib/repository/services/auth/auth_api_exception.dart
  - lib/repository/services/auth/auth_state_channel.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/backend_auth_api.dart
  - lib/repository/services/auth/browser_authenticator.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/graphql_backend_auth_api.dart
  - lib/repository/services/auth/login_callback.dart
  - lib/repository/services/auth/login_exception.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/services/auth/unauthorized_recovery.dart
  - lib/repository/services/graphql/auth_link.dart
  - lib/repository/services/graphql/graphql_client_holder.dart
  - lib/repository/services/graphql/graphql_client_provider.dart
  - lib/repository/services/graphql/ws_reconnect_policy.dart
  - lib/repository/services/rest/auth_interceptor.dart
  - lib/repository/services/rest/rest_client_provider.dart
  - lib/repository/storage/session_store.dart
  - lib/routes/routes.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/auth/cubit/auth_cubit.dart
  - lib/screens/signIn/cubit/sign_in_cubit.dart
  - lib/screens/signIn/cubit/sign_in_state.dart
  - lib/screens/signIn/sign_in_screen.dart
  - lib/screens/splash/cubit/splash_cubit.dart
  - lib/screens/splash/cubit/splash_state.dart
  - lib/screens/splash/splash_screen.dart
  - lib/shared/components/modal/logout_confirmation_dialog.dart
  - lib/utils/backoff.dart
  - android/app/src/main/AndroidManifest.xml
  - android/settings.gradle.kts
  - pubspec.yaml
  - .env.example
findings:
  critical: 0
  warning: 5
  info: 9
  total: 14
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-10-06T18:50:42Z
**Depth:** standard
**Files Reviewed:** 44
**Status:** issues_found

## Summary

Review statica (nessun test eseguito; `flutter analyze lib` = baseline di 11 issue pre-esistenti, nessuna nuova) del substrato auth di Phase 11 contro `11-CONTEXT.md` (D-01..D-38), il contratto BE Phase 2 (`BACKEND-NOTES.md` BE) e le regole di progetto.

Valutazione complessiva: buona. Il single-flight del refresh, l'epoch guard su storage/memoria, il persist-before-apply della rotazione, il retry-once di link GraphQL e interceptor dio (marcatori `AuthRetried` / `klimmeck.authRetried`), il backoff limitato del WebSocket con `initialPayload` che non lancia mai, la mappatura terminale solo su `SESSION_EXPIRED`/`SESSION_REVOKED`, l'igiene dei segreti (`toString()` di `AuthSession`, `LoginChallenge`, `LoginTicketReceived`, `AuthAuthenticated` non espongono token; i log riportano solo `runtimeType`) e il binding S256 sono corretti e conformi al contratto. Il cablaggio dev bypass / `UnauthorizedRecovery` via record nel composition root è pulito: lo stub non ha recovery e non può entrare nei percorsi di refresh.

Le criticità trovate sono soprattutto **fughe tra epoche di sessione**: l'epoch guard protegge storage e memoria, ma non i *chiamanti* di `getAccessToken()` / `recoverFromUnauthorized()`, che dopo un logout→login possono ricevere il token della sessione NUOVA (WR-01, con un percorso concreto che revoca lato server la sessione appena creata). Seguono il caso noto del doppio teardown al logout (WR-02), la cancellazione della sessione su errori di lettura transitori dello storage cifrato (WR-03), un `initialize()` che può lanciare e lasciare il cold start bloccato (WR-04) e i Cubit gameplay che ora vengono chiusi al logout ma emettono ancora dopo `close()` (WR-05).

Nessun finding contraddice le scelte documentate e accettate (assenza di guardia `kReleaseMode` — D-30; entry point del logout in Phase 4; placeholder TOS/Privacy; eventi WS persi nel gap — Phase 3; UAT su device in sospeso).

## Warnings

### WR-01: `getAccessToken()` / `recoverFromUnauthorized()` restituiscono il token di una sessione successiva a chiamanti della sessione precedente — un logout lento può revocare la sessione appena creata

**File:** `lib/repository/services/auth/session_auth_token_service.dart:109-118`, `:160-162`, `:387-395`
**Issue:** L'epoch guard di `_rotateSession` completa il completer con `_superseded` quando la sessione è cambiata, ma `getAccessToken()` intercetta ogni errore non-`SessionRejected` con `catch (_) { return _accessToken; }` e rilegge `_accessToken` **al momento del ritorno**, non dell'invocazione. Analogamente `recoverFromUnauthorized()` ritorna `_accessToken` corrente se diverso dal token rifiutato, senza sapere a quale sessione appartiene la richiesta.

Scenario concreto (rete mobile lenta, D-13/D-36):
1. t=0 l'utente conferma il logout; l'access JWT è scaduto, quindi `_invalidateBackendSession()` → `getAccessToken()` → `refreshSession` (timeout client 15 s) resta appeso.
2. t=4 s scatta `_logoutTimeout`: `_endSession` (epoch++), sign-in. `_invalidateBackendSession` **continua in background**.
3. L'utente rifà subito il login (dev bypass reale o Twitch): `_startSession` imposta `_accessToken = <token sessione B>`.
4. t≈15 s il refresh vecchio fallisce (o riesce tardi → `_superseded`): `getAccessToken()` cade nel `catch (_)` e ritorna `_accessToken`, cioè il token di B.
5. `_api.logout(<token B>)` revoca **la sessione B appena creata**; al primo refresh successivo arriva `SESSION_REVOKED` e l'utente viene sbattuto fuori con "La sessione è scaduta".

Lo stesso difetto fa sì che una query/mutation della shell precedente, in attesa su `getAccessToken()` o su `recoverFromUnauthorized()` a cavallo di un logout→login (cambio account, D-14), venga inviata con l'identità del NUOVO utente.
**Fix:** catturare l'epoca all'ingresso e scartare l'esito se è cambiata; idem nel percorso di recovery e nel logout best-effort:
```dart
@override
Future<String?> getAccessToken() async {
  final epoch = _epoch;
  if (_hasFreshAccessToken || _refreshToken == null) return _accessToken;
  try {
    final token = await _refreshSingleFlight();
    return epoch == _epoch ? token : null;
  } on SessionRejected {
    return null;
  } catch (_) {
    return epoch == _epoch ? _accessToken : null;
  }
}

Future<String?> recoverFromUnauthorized({String? rejectedToken}) async {
  final epoch = _epoch;
  // ... come oggi, ma ogni `return` diventa `epoch == _epoch ? x : null`
}

Future<void> _invalidateBackendSession() async {
  final epoch = _epoch;
  final accessToken = await getAccessToken();
  if (accessToken == null || epoch != _epoch) return;
  await _api.logout(accessToken);
}
```
Aggiungere un test con `fake_async`: logout con refresh appeso > `logoutTimeout`, login riuscito, poi completamento del refresh → `api.logout` non deve mai ricevere il token della nuova sessione.

### WR-02: il logout può emettere `sessionExpired` e poi `signedOut` ed eseguire il teardown due volte

**File:** `lib/repository/services/auth/session_auth_token_service.dart:141-145`, `:297-300`
**Issue:** (caso noto, confermato) `logout()` → `_invalidateBackendSession()` → `getAccessToken()` → refresh → `SessionRejected` → `_rotateSession` esegue già `_endSession(sessionExpired)` (teardown #1, clear #1, emit `AuthUnauthenticated(sessionExpired)`); poi `logout()` prosegue con `_endSession(signedOut)` (teardown #2, clear #2, emit `signedOut`). Effetti: (a) `AuthGate._shouldRebuild` ricostruisce perché `reason` cambia → l'utente che ha *scelto* di uscire vede per un frame "La sessione è scaduta, accedi di nuovo." (contraddice la semantica di D-10/D-31: il notice è per la sessione rifiutata, non per il logout volontario); (b) `GraphQLClientHolder.reset()` gira due volte (idempotente oggi, ma ogni ricreazione apre un nuovo client e la seconda è inutile); (c) `onSessionTeardown` non è "atomico" come chiede D-12.
**Fix:** rendere `_endSession` idempotente per epoca e far vincere il motivo del logout esplicito, ad esempio marcando il logout prima di toccare la rete:
```dart
bool _loggingOut = false;

Future<void> logout() async {
  _loggingOut = true;
  try {
    await _invalidateBackendSession().timeout(_logoutTimeout, onTimeout: _logLogoutTimeout);
    await _endSession(UnauthenticatedReason.signedOut);
  } finally {
    _loggingOut = false;
  }
}

// in _rotateSession, ramo SessionRejected:
if (!_loggingOut) await _endSession(UnauthenticatedReason.sessionExpired);
completer.completeError(error);
```
oppure saltare `_endSession` in `logout()` se `_channel.current is AuthUnauthenticated` ed emettere solo il motivo `signedOut` senza rifare teardown/clear. Coprire con un test che asserisca un solo `AuthUnauthenticated(signedOut)` e una sola invocazione di `onSessionTeardown`.

### WR-03: un errore *transitorio* di lettura dello storage cifrato cancella la sessione valida

**File:** `lib/repository/storage/session_store.dart:42-50`, `:68-74`
**Issue:** `readRefreshToken()` tratta qualunque eccezione di `_storage.read` come "storage irrecuperabile" ed esegue `deleteAll()`. Tra queste ci sono errori transitori: su iOS `errSecInteractionNotAllowed` (-25308) se il processo legge il Keychain prima del primo sblocco dopo un riavvio (avvio in background da push/background fetch: proprio lo scenario che `first_unlock_this_device` intende supportare), su Android eccezioni momentanee del Keystore. In quei casi il refresh token ancora valido viene distrutto e al prossimo avvio l'utente si ritrova sul sign-in senza motivo — contraddice D-09 ("transient failures do not trigger logout") e il principio "mai wipe su errore transitorio". Inoltre `deleteAll()` cancella ogni chiave del secure storage, non solo gli artefatti di sessione (oggi coincide, ma è un effetto collaterale latente se un'altra feature userà lo storage cifrato).
**Fix:** cancellare solo su errori di decrittazione permanenti (chiave Keystore invalidata / restore da backup) e solo la chiave di sessione; per gli altri, restituire `null` *senza* cancellare (o propagare un errore transitorio che `initialize()` ritenta):
```dart
} on PlatformException catch (error) {
  if (_isUnrecoverable(error)) await _deleteSessionQuietly(); // delete(key: refreshTokenKey)
  return null;
}
```
Documentare quali codici `flutter_secure_storage` 10.x considera irrecuperabili e testare entrambi i rami con un fake.

### WR-04: `initialize()` può lanciare e lasciare il cold start bloccato su `AuthBootstrapping` con un errore asincrono non gestito

**File:** `lib/repository/storage/session_store.dart:59-66`, `lib/repository/services/auth/session_auth_token_service.dart:93-104`, `lib/screens/auth/cubit/auth_cubit.dart:16-22`, `lib/main.dart:183`
**Issue:** `_wipeIfFirstLaunch()` chiama `SharedPreferences.getInstance()` / `prefs.setBool()` **fuori** da qualunque try; se lancia (prefs corrotte, I/O), l'eccezione risale da `readRefreshToken()` → `initialize()` → `AuthCubit.start()`, che è invocato come `..start()` dentro `create:` e quindi non è atteso da nessuno: errore di zona non gestito e servizio che non emette mai né `AuthAuthenticated` né `AuthUnauthenticated`. L'utente resta sullo splash (il bootstrap non viene ritentato: `_attemptBootstrap` non è mai partito) finché, dopo 10 s, non preme "Accedi manualmente" — e la sessione salvata non verrà mai ripresa in quel processo. Inoltre `_firstLaunchChecked = true` viene impostato prima dell'await, quindi un secondo tentativo salterebbe comunque il wipe del primo avvio.
**Fix:** rendere `readRefreshToken()` totale (try attorno a `_wipeIfFirstLaunch`, impostando `_firstLaunchChecked` solo a esito positivo) e difendere anche `initialize()`:
```dart
Future<void> initialize() async {
  final epoch = _epoch;
  _channel.emit(const AuthBootstrapping());
  final String? stored;
  try {
    stored = await _store.readRefreshToken();
  } catch (error) {
    debugPrint('[SessionAuth] session read failed: ${error.runtimeType}');
    if (epoch == _epoch) _channel.emit(const AuthUnauthenticated());
    return;
  }
  ...
}
```
e in `AuthCubit.start()` avvolgere `initialize()` in try/catch che, in caso di errore, emette `AuthUnauthenticated()` se lo stato è ancora `AuthBootstrapping`.

### WR-05: i Cubit gameplay ora vengono chiusi al logout ma emettono ancora dopo `close()`; il teardown gira con la shell ancora montata

**File:** `lib/screens/auth/authenticated_shell.dart:41-56` (esposizione), `lib/repository/services/auth/session_auth_token_service.dart:402-408` (ordine); codice colpito pre-esistente es. `lib/screens/mainScreen/characterCubit/character_cubit.dart:19-27`, `:40-42`
**Issue:** Phase 11 sposta correttamente i Cubit gameplay sotto `AuthenticatedShell` così che il logout li chiuda (focus 6). Però quasi tutti (eccetto `TransactionCubit`) fanno `emit` dopo un `await` senza `if (isClosed) return;`. Esempio: `CharacterCubit.loadCharacter` ha una query in volo quando l'utente esce → la shell viene smontata → la query ritorna → `emit(CharacterLoaded)` lancia `StateError: Cannot emit new states after calling close`, il `catch (e)` del cubit prova `emit(CharacterError)` e rilancia: errore asincrono non gestito a ogni logout/cambio account con richieste in volo. Inoltre `_endSession` esegue `_forgetSession()` e `_runTeardown()` (che sostituisce `client.value`) **prima** di emettere `AuthUnauthenticated`: in quella finestra la shell è ancora montata e qualunque richiesta partita dai cubit va al backend senza bearer e riceve `UNAUTHENTICATED`, che i cubit possono mostrare come errore a schermo un attimo prima del sign-in.
**Fix:** (a) aggiungere la guardia `isClosed` agli `emit` post-`await` dei Cubit montati in `AuthenticatedShell` (Boy Scout, in scope perché il ciclo di vita è cambiato in questa fase) e un test `bloc_test` "close durante una richiesta in volo non lancia"; (b) valutare di emettere lo stato `AuthUnauthenticated` *prima* di sostituire il client (D-12 ordina "cancel subscriptions → recreate client → clear storage → emit"; il passo 2 si può fare chiudendo i Cubit, cioè smontando la shell) oppure documentare la finestra come accettata.

## Info

### IN-01: la pianificazione del refresh decodifica il JWT (`exp - iat`), contro la lettera del contratto BE

**File:** `lib/repository/services/auth/access_token_lifetime.dart:7-38`, `lib/repository/services/auth/session_auth_token_service.dart:322-327`
**Issue:** Il contratto BE (§2) dice "Il FE **non deve** decodificarlo per decidere quando rinnovare: usa `accessTokenExpiresAt`" e D-05 parla di schedule "based on the session's `accessTokenExpiresAt`". Il codice usa la durata ricavata dal payload del JWT e ricade su `accessTokenExpiresAt` solo se la decodifica fallisce. La scelta è motivata (robustezza allo skew) e documentata nel BACKEND-NOTES FE §3, ma accoppia l'app al formato interno del token (un futuro token opaco o un cambio di claim degrada silenziosamente sul fallback skew-sensibile).
**Fix:** allineare il contratto: o chiedere al BE di accettare formalmente la lettura di `exp/iat`, o calcolare la durata come `accessTokenExpiresAt - Date header della risposta` (indipendente dall'orologio del device) senza decodificare il JWT. In ogni caso registrare la deviazione in `11-CONTEXT.md` come decisione.

### IN-02: persistenza della rotazione fallita → lo storage conserva un refresh token che al prossimo avvio innesca la reuse detection (o riprende un altro account)

**File:** `lib/repository/services/auth/session_auth_token_service.dart:227-234`, `:291-296`, `:308-316`
**Issue:** Se `writeRefreshToken` fallisce, il token nuovo vive solo in memoria e lo storage tiene quello vecchio. Al cold start successivo (> 30 s dopo) il vecchio token produce `SESSION_REVOKED` per reuse detection: l'intera sessione viene revocata lato server. Nel percorso "Accedi manualmente durante un bootstrap lento" lo storage può contenere il refresh token dell'account A mentre in memoria c'è l'account B: un fallimento di scrittura al login di B fa riprendere A al riavvio.
**Fix:** se la scrittura fallisce, tentare `_store.clear()` (meglio il sign-in pulito al prossimo avvio che una revoca per reuse o una sessione dell'account sbagliato) e loggare l'evento.

### IN-03: il login che sostituisce un bootstrap in corso non chiude la sessione precedente lato server

**File:** `lib/repository/services/auth/session_auth_token_service.dart:120-133`, `:225-234`; `lib/screens/auth/cubit/auth_cubit.dart:25-27`
**Issue:** Dopo "Accedi manualmente" (D-18) il bootstrap continua a ritentare in background; se l'utente completa un login, `_supersedeSession()` scarta il vecchio refresh token senza `logout` lato server (la sessione resta viva fino a 30 gg sliding). Inoltre, se il bootstrap riesce mentre l'utente è nel browser, l'`AuthGate` passa alla shell sotto il browser e poi il login la sostituisce. D-18 descrive solo il caso "the user has not pressed the button".
**Fix:** fermare il bootstrap (`_supersedeSession` + `_store.clear()`) quando l'utente preme "Accedi manualmente", oppure documentare esplicitamente in `11-CONTEXT.md` che il bootstrap prosegue anche dopo il tap e che la sessione scartata muore per scadenza.

### IN-04: il parser del callback non valida l'host `auth`

**File:** `lib/repository/services/auth/login_callback.dart:47-60`; `android/app/src/main/AndroidManifest.xml:30-40`
**Issue:** `parseLoginCallback` controlla solo lo scheme. La `CallbackActivity` è (necessariamente) `exported="true"` con un intent-filter su tutto lo scheme `klimmeck`, e `flutter_web_auth_2` risolve il `authenticate()` pendente con il **primo** `klimmeck://…` ricevuto: qualunque app o pagina può iniettare `klimmeck://qualcosa?error=twitch_not_configured` (o un ticket proprio) durante un login. Il binding S256 impedisce la session fixation (ticket altrui → `LOGIN_TICKET_INVALID`), quindi l'impatto è solo un DoS/messaggio fuorviante, ma la validazione dell'host è economica.
**Fix:** `if (uri == null || uri.scheme != loginCallbackScheme || uri.host != 'auth') return const LoginRejectedByBackend(_invalidCallbackError);` e, nel manifest, restringere il filtro con `<data android:scheme="klimmeck" android:host="auth" />`.

### IN-05: misura della "connessione stabile" del WebSocket presa al momento del payload, non dell'ack

**File:** `lib/repository/services/graphql/ws_reconnect_policy.dart:45-56`, `:63-79`
**Issue:** `_connectedAt` viene impostato in `buildInitialPayload()`, cioè prima di aprire il socket e prima del `connection_ack`. Un tentativo che resta appeso ≥ 30 s (TCP lento, ack mai arrivato) viene considerato "stabile" e azzera il backoff; inoltre `_recoverSession()` viene valutato a ogni 4401/4403 prima del controllo `_attempt == 0`, quindi con un token rifiutato ripetutamente si fa un refresh di rete (con rotazione) a ogni riconnessione. Entrambi restano limitati dal backoff (nessun hot loop), ma consumano rotazioni inutilmente.
**Fix:** valutare `_attempt == 0` prima di chiamare la recovery quando il token inviato è già diverso dal corrente, e misurare la stabilità dalla prima ricezione di un messaggio (o accettare il limite documentandolo).

### IN-06: `GraphQLClientHolder.reset()` non è serializzato

**File:** `lib/repository/services/graphql/graphql_client_holder.dart:28-39`
**Issue:** Due `reset()` concorrenti (es. teardown da `SessionRejected` su WS + logout, vedi WR-02) dispongono entrambi il link vecchio e creano due connessioni; la prima (`L2`) viene pubblicata in `client.value` e subito sostituita senza essere mai disposta: se nel frattempo una subscription l'ha usata, il suo socket resta in riconnessione automatica per sempre.
**Fix:** serializzare con un `Future<void>? _resetInFlight` (riuso del future in corso) oppure disporre anche il link sostituito.

### IN-07: dev stub senza guardia d'epoca tra `_signIn` e `_endSession`

**File:** `lib/repository/services/auth/dev_auth_token_service.dart:108-126`
**Issue:** `_signIn()` imposta `_isSignedIn = true` e poi attende `me` (fino a 3 s) prima di emettere; un `logout()` in quella finestra emette `AuthUnauthenticated` e poi viene "resuscitato" da `AuthAuthenticated`. Solo dev, non raggiungibile finché l'entry point del logout non esiste (Phase 4), ma lo stub è il percorso usato da tutte le fasi 2-10.
**Fix:** contatore di generazione come nel servizio reale: `final gen = ++_generation; final user = await _resolveUser(); if (gen != _generation) return;` e `_generation++` in `_endSession`.

### IN-08: `allowBackup="false"` non copre il trasferimento device-to-device da Android 12

**File:** `android/app/src/main/AndroidManifest.xml:4`
**Issue:** Per app con `targetSdk` ≥ 31, `allowBackup="false"` disattiva il backup cloud ma non il trasferimento D2D: `shared_preferences` (con il marker `first_launch_done`) e il blob cifrato migrano su un device nuovo dove la chiave Keystore non esiste. Oggi l'esito è gestito (lettura fallita → wipe, vedi però WR-03), ma il marker migrato fa saltare il wipe del primo avvio.
**Fix:** aggiungere `android:dataExtractionRules="@xml/data_extraction_rules"` che escluda `sharedpref` e il file del secure storage sia da `cloud-backup` sia da `device-transfer`.

### IN-09: piccole pulizie (Boy Scout)

**File:** `lib/routes/routes.dart:5-43`, `lib/config/env_config.dart:66-74`, `lib/screens/auth/auth_gate.dart:27-31`
**Issue:**
- `createSlideRoute` / `createFadeRoute` non hanno più chiamanti in `lib/` dopo la rimozione delle route: codice morto (o tabella route da ripopolare secondo `docs/rules/ui-ux.md`).
- `EnvConfig.devAuthEnabled` non fa `trim()` mentre `DEV_AUTH_START_SIGNED_OUT` sì: `DEV_AUTH_ENABLED=true ` (spazio finale) seleziona silenziosamente il servizio reale. Direzione sicura, ma incoerente e fonte di confusione.
- `AuthGate` chiude dialog/route del Navigator radice solo al passaggio a `AuthUnauthenticated`; un cambio d'identità `AuthAuthenticated(A) → AuthAuthenticated(B)` (rotazione con utente diverso, `_announceIdentityChange`) ricostruisce la shell ma lascia aperte le route dell'utente A con `BlocProvider.value` su Cubit già chiusi.
**Fix:** rimuovere o riusare gli helper di route; uniformare il parsing dei flag `.env` (`trim().toLowerCase()`); estendere `listenWhen` anche al cambio di `user.id`.

---

_Reviewed: 2026-10-06T18:50:42Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
