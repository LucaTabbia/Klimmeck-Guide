---
phase: 11-auth-session-bootstrap
reviewed: 2026-10-06T20:10:00Z
depth: deep
scope: re-review dei fix 88aaeda..HEAD (WR-01..WR-05, IN-04, IN-06, IN-09)
files_reviewed: 10
files_reviewed_list:
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/storage/session_store.dart
  - lib/screens/auth/cubit/auth_cubit.dart
  - lib/screens/auth/auth_gate.dart
  - lib/shared/bloc/safe_emit.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/repository/services/auth/login_callback.dart
  - lib/repository/services/graphql/graphql_client_holder.dart
  - lib/config/env_config.dart
  - android/app/src/main/AndroidManifest.xml
findings:
  critical: 0
  warning: 1
  info: 7
  total: 8
status: issues_found
---

# Phase 11: Code Review Report, iterazione 2 (re-review dei fix)

**Reviewed:** 2026-10-06T20:10:00Z
**Depth:** deep (call chain verso `AuthAuthLink`, `AuthInterceptor`, `WsReconnectPolicy`, `graphql_client_provider`, plugin `flutter_web_auth_2` 5.1.0 e `bloc` 9.0.0 nella pub cache)
**Files Reviewed:** 10 (più i test della diff)
**Status:** issues_found

## Summary

Review dei soli commit `9581226..0a24e44` (12 commit) contro `11-REVIEW.md`, `11-REVIEW-FIX.md`, `11-CONTEXT.md` (D-05, D-06, D-09, D-12, D-13, D-36 emendata, D-37) e il contratto BE aggiornato oggi (rotazione a ogni refresh, grace 30 s solo per il token immediatamente precedente, riuso di qualunque token ritirato, compreso l'orfano di una rotazione in grace = `SESSION_REVOKED`).

Gate verificati in locale: `flutter analyze lib test` = 11 issue (baseline, nessuna nuova); `flutter test` sui file auth/storage/graphql/auth-screens/shared/mainScreen/config = 210 test, tutti verdi (incluso `auth_gate_dev_bypass_test.dart`: cold start → shell, logout → sign-in, login → di nuovo dentro).

Esito: i difetti originali sono chiusi. Le garanzie di fase reggono: single-flight intatto (l'unico refresh fuori dal single-flight è quello dedicato del logout, ammesso da D-36 emendata e compatibile con la grace BE), persist-before-forget invariato, solo `SESSION_EXPIRED`/`SESSION_REVOKED` chiudono la sessione, nessun loading bloccante introdotto, dev bypass funzionante. Ho trovato **un nuovo Warning**: `logout()` non è rientrante, quindi un secondo logout sovrapposto (doppio tap sull'entry point di Phase 4) annulla la chiamata backend del primo e riesegue teardown, pulizia e `signedOut`. Nel caso peggiore il `_endSession` tardivo del primo logout chiude una sessione nuova. Il resto sono Info: crescita del set dei token, guardia d'epoca più restrittiva del necessario sul logout backend, casi residui pre-esistenti e l'interazione con la nuova regola BE.

## Verdetti per finding originale

### WR-01: fix confermato

- **Difetto chiuso.** `getAccessToken()` cattura l'epoca dopo il controllo sincrono (`:116-117`) e ogni uscita asincrona passa da `_tokenFor` (`:120`, `:124`). `SessionRejected` restituisce `null`. `recoverFromUnauthorized()` rifiuta i token non emessi alla sessione corrente (`:177`) e applica l'epoca al refresh forzato (`:181-184`). Il logout backend non passa più da `getAccessToken()` (WR-02), quindi il percorso originale "logout lento → token di B → revoca di B" non esiste più per costruzione: `_backendLogoutToken` deriva il bearer solo dalle credenziali della sessione che si chiude.
- **Uscite.** Successo, `catch`, `_superseded`, timeout e `dispose` (che passa da `_supersedeSession`) rispettano tutti l'epoca. Nessun percorso restituisce il token di una sessione successiva.
- **Retry legittimi.** Tutti i token in circolazione nascono da `_applySession` (`:350`): login (`_startSession`), bootstrap (`_rotateSession`), rotazioni proattive e reattive. Quindi:
  - la prima richiesta dopo il bootstrap porta un token presente nel set;
  - una richiesta partita con `a1` e rifiutata dopo una rotazione proattiva (set `{a1, a2}`) riceve `a2` senza refresh;
  - al resume, `_hasFreshAccessToken` usa l'orologio, quindi la prima richiesta forza il refresh single-flight e il token ottenuto è nel set.
  - `AuthAuthLink` passa il token che ha effettivamente inviato. `AuthInterceptor` lo rilegge dall'header della richiesta fallita. Nessun retry legittimo viene rifiutato.
- **WebSocket.** Con il normale 4401 a 15 minuti, `_lastSentToken = a1` è nel set: si ottiene il token corrente (o un refresh forzato se non è ancora ruotato) e il retry rapido di 500 ms resta. `rejectedToken: null` capita solo per un connect partito senza token (bootstrap transitorio, sessione già chiusa) e ora ricade nel backoff (1 s al primo tentativo). Il connect successivo rilegge il token corrente: il socket non resta bloccato.
- **Test.** Bloccano davvero il comportamento:
  - "a token read suspended across a new login yields null" fallisce senza `_tokenFor`;
  - "recovery for a token of a previous session yields null" e "returns null for a token never issued" falliscono senza il set;
  - i due test "hung logout refresh … never revokes the new session" falliscono sul codice originale.
  - Nota: oggi non fallirebbero più se si togliesse solo la guardia `closing.epoch != _epoch` (vedi IN-N2), perché il bearer di B è escluso strutturalmente.
- Residui: IN-N1 (crescita del set), IN-N3 (rotazione con cambio utente).

### WR-02: fix confermato per il logout singolo; nuovo difetto con logout sovrapposti (WR-N1)

- **Difetto chiuso.** `_detachSession()` porta l'epoca avanti e sgancia il refresh in volo. L'eventuale `SessionRejected` di quel refresh termina in `_superseded` (`:328`). Nessun nuovo refresh può partire, perché `_refreshToken` è `null` e `_issuedAccessTokens` è vuoto. Dopo il detach l'unico chiamante di `_endSession(sessionExpired)` sarebbe `handleRevocation()`, che oggi non ha chiamanti in `lib/`. I test "a rejected refresh ends the session once" e "a proactive refresh rejected during logout" verificano `[signedOut]`, un solo teardown e `clears == 1`, e fallirebbero sul codice originale.
- **Contratto BE (nuova regola).** Il refresh dedicato parte solo da `logout()`, quindi mai senza un logout reale. Se un refresh normale con `r0` è in volo (al massimo 15 s, `queryRequestTimeout`), il secondo invio di `r0` cade nella grace: `r0→r2`, `r1` resta orfano. `r1` non viene mai persistito né applicato (epoca cambiata) e lo storage viene poi svuotato, quindi nessuno ripresenta l'orfano. Se `r0` fosse già fuori grace, la risposta è `SESSION_REVOKED`: la sessione è revocata comunque, che a un logout va bene.
- **Sessione lasciata viva lato server.** Non succede solo offline o su rifiuto. Succede anche se il refresh dedicato riesce dopo i 4 s, perché la chiamata `logout` viene saltata dalla guardia d'epoca (IN-N2), e con due logout sovrapposti (WR-N1).
- **Percorsi verificati:**
  - logout durante il bootstrap: non raggiungibile dalla UI (splash e sign-in non hanno logout); anche se lo fosse, il risultato del bootstrap viene scartato;
  - logout seguito da un login immediato: il login è possibile solo dopo `signedOut`, che arriva dopo `_endSession`;
  - `dispose` durante il logout: `emit` su canale chiuso è un no-op, ma teardown e clear girano comunque (innocuo).
- **Doppio tap:** vedi WR-N1.

### WR-03: fix confermato (wipe rimosso); residuo documentato (IN-N5)

- Una lettura fallita restituisce `null` e non cancella nulla (`session_store.dart:55-64`). Il test usa `-25308` e verifica né `deleteAll` né `delete`.
- `resetOnError: true` è esplicito e bloccato da un test sul `toMap()`. Il plugin Android continua a cancellare solo su una chiave o un valore non più decifrabili, come documentato.
- Resta il caso dichiarato in BACKEND-NOTES §3: con uno storage transitoriamente illeggibile si va al sign-in per tutta la vita del processo, senza un nuovo tentativo di lettura. Se l'utente rifà il login, il refresh token salvato viene sovrascritto e la sessione server precedente resta orfana fino alla scadenza. È accettabile come trade-off documentato. Il suggerimento è in IN-N5.

### WR-04: fix confermato

- `_markFirstLaunchDone()` non lancia mai e `_readStoredRefreshToken()` intercetta tutto, quindi `initialize()` non lancia più nel servizio reale.
- `AuthCubit.start()` riporta l'errore con `addError` (in bloc 9.0.0 chiama `onError`/observer senza rilanciare) e chiama `showSignIn()`, che agisce solo in `AuthBootstrapping`.
- Nessun loop di retry e nessuno stato incoerente: una lettura fallita porta a un solo `AuthUnauthenticated()`.
- Marker salvato prima del wipe: il wipe salta per sempre solo se il processo muore tra `setBool` e `deleteAll`, oppure se `deleteAll` fallisce. Il secondo caso c'era anche prima. Il primo è una finestra nuova ma di pochi millisecondi (IN-N6). Il compromesso è giusto: l'ordine inverso con un marker non salvabile faceva logout a ogni avvio.
- I test della store e del cubit fallirebbero senza il fix.

### WR-05: fix confermato; follow-up D-12 valutato

- **Il mixin è corretto per bloc 9.0.0.** `BlocBase.emit(State)` è `@protected` e lancia `StateError` dopo `close()`. L'override in `SafeEmit<S> on BlocBase<S>` ha la stessa firma, scarta solo a cubit chiuso e da aperto delega a `super.emit`, che continua a chiamare `onError` e a rilanciare. Nessun errore viene inghiottito a cubit aperto.
- Gli 8 Cubit hanno solo `with SafeEmit<…>` più l'import: nessun comportamento perso.
- La guardia in `CharacterCubit.loadCharacter` (`:25`) chiude la subscription fantasma. Il test fallisce senza la guardia anche con `SafeEmit` attivo, quindi blocca proprio quella riga.
- **Follow-up 1 (finestra D-12).** Lo considero davvero solo cosmetico. `KlimmeckGraphQl` risolve il client per chiamata e nella shell non ci sono widget `Query`/`Subscription`, quindi nella finestra parte solo il lavoro già avviato dai Cubit.
  - Una richiesta che parte in quel momento va sul client nuovo senza bearer e riceve `UNAUTHENTICATED`. Nessun retry (`token == null`) e nessun dato della vecchia sessione: al massimo uno stato d'errore per un frame.
  - Unico effetto non visivo: se `getCharacter` risolve proprio nella finestra, `subscribeToCharacter` apre una subscription sul link nuovo con un `connection_init` senza token. La subscription viene cancellata alla chiusura del Cubit e il socket si chiude per `inactivityTimeout`.
  - Nessuno stato sbagliato e nessuna fuga d'identità. Va bene tenerlo come follow-up per Phase 12.

### IN-04: fix confermato

- In `flutter_web_auth_2` 5.1.0, `CallbackActivity` prende `intent.data`, ne legge solo lo `scheme` e risolve `callbacks[scheme]`. Con `<data android:scheme="klimmeck" android:host="auth" />` il callback `klimmeck://auth?…` arriva ancora: l'intent-filter restringe solo cosa Android instrada verso l'activity. Il ramo Auth Tab con scheme custom riceve il risultato via launcher e non dipende dal filtro. `android:taskAffinity=""` resta come raccomandato dal README.
- Il parser rifiuta host diversi da `auth`, `klimmeck:?…` compreso. `Uri` normalizza l'host in minuscolo.
- Resta possibile iniettare `klimmeck://auth?error=…` (DoS, già accettato perché il binding S256 evita la fixation).

### IN-06: fix confermato

- `_resetInFlight ??= _recreate().whenComplete(...)`: `_recreate` è `async`, quindi l'assegnazione avviene sempre prima del `whenComplete`.
- Le chiamate sovrapposte condividono un solo dispose e una sola connessione. Ogni chiamante riprende dopo `client.value = nuovo`, e il client nuovo nasce dopo la sua chiamata. Nessun link sostituito resta senza dispose e nessun client già disposto viene restituito.
- Se `_connect()` lanciasse, entrambi i chiamanti ricevono l'errore e il teardown lo intercetta. Era così anche prima.
- I due test falliscono sul codice originale (3 connessioni, link 1 mai disposto).

### IN-09 (parti selezionate): fix confermato

- `devAuthEnabled` usa `trim().toLowerCase()`, con test.
- `lib/routes/routes.dart` è rimosso senza riferimenti pendenti in `lib/`, `test/` e `integration_test/`.
- `AuthGate._leavesSession` chiude le route radice solo se `user.id` cambia o all'ingresso in `AuthUnauthenticated`. Una rotazione dello stesso utente non chiude nulla (di norma `_announceIdentityChange` non emette nemmeno). Entrambi i casi hanno test widget.

## Warnings

### WR-N1: `logout()` non è rientrante: un secondo logout sovrapposto annulla la chiamata backend del primo e ripete teardown, clear e `signedOut`

**File:** `lib/repository/services/auth/session_auth_token_service.dart:154-159`, `:419-431`, `:439`, `:471-477`; entry point `lib/shared/components/modal/logout_confirmation_dialog.dart:56-58`
**Issue:** D-36 emendata e la dartdoc di `logout()` promettono "un solo `signedOut`, teardown e clear una sola volta". Vale solo per un logout alla volta. `confirmLogout` aspetta `authCubit.logout()` fino a 4 s con la shell ancora montata, e né `AuthCubit` né il servizio deduplicano.

Scenario (access JWT scaduto, ad esempio subito dopo un resume):
1. Logout #1: `_detachSession()` cattura `{a1, fresh: false, r1}` e porta l'epoca a E1. Il refresh dedicato `refreshSession(r1)` è in volo.
2. Logout #2 (secondo tap su Esci prima che compaia il sign-in): `_detachSession()` cattura `{a1, fresh: false, refreshToken: null}`, perché #1 ha già messo `_refreshToken` a `null`, e porta l'epoca a E2. `_backendLogoutToken` restituisce `a1`, che è scaduto. `api.logout(a1)` riceve `UNAUTHENTICATED`.
3. Il refresh di #1 restituisce `a2`, ma `closing.epoch (E1) != _epoch (E2)` e la chiamata `logout` viene saltata (`:439`). La sessione server resta viva con `r2`, che nessuno possiede, mentre l'utente crede di essere uscito.
4. Entrambi chiamano `_endSession(signedOut)`: due `onSessionTeardown` (due `holder.reset()` sequenziali), due `clear()`, due emissioni `signedOut`.
5. Caso peggiore: #2 finisce subito, compare il sign-in e l'utente completa un nuovo login B prima che scada il timeout di #1. Il `_endSession(signedOut)` tardivo di #1 chiama `_supersedeSession()` e `_forgetSession()`, esegue il teardown, svuota lo storage di B ed emette `signedOut`: la sessione nuova viene chiusa, cioè proprio la classe di difetto che WR-01 doveva eliminare. È improbabile (login Twitch con `force_verify` in meno di 4 s), ma il percorso esiste.

Lo stesso schema vale se l'utente fa logout mentre un `_endSession(sessionExpired)` da refresh rifiutato è già in corso (`:329`, durante il teardown): il logout ripete teardown e clear ed emette un secondo stato terminale.
**Fix:** condividere il logout in corso e rendere `_endSession` idempotente per sessione:
```dart
Future<void>? _logoutInFlight;

@override
Future<void> logout() =>
    _logoutInFlight ??= _performLogout().whenComplete(() => _logoutInFlight = null);

Future<void> _performLogout() async {
  final closing = _detachSession();
  await _invalidateBackendSession(closing)
      .timeout(_logoutTimeout, onTimeout: _logLogoutTimeout);
  if (closing.epoch != _epoch) return; // un login (o un'altra chiusura) è già subentrato
  await _endSession(UnauthenticatedReason.signedOut);
}
```
(Con il controllo d'epoca prima di `_endSession`, un login completato nel frattempo non viene mai chiuso da un logout vecchio.) Aggiungere i test con `fake_async`:
- due `logout()` sovrapposti con access scaduto: una sola `api.refreshSession`, una sola `api.logout(a2)`, `clears == 1`, teardown una volta, stati `[signedOut]`;
- un logout bloccato fino al timeout seguito da un login riuscito prima del timeout: B resta `Authenticated` e lo storage di B resta intatto.

## Info

### IN-N1: `_issuedAccessTokens` cresce senza limite per tutta la durata della sessione

**File:** `lib/repository/services/auth/session_auth_token_service.dart:78`, `:350`, `:404`
**Issue:** viene svuotato solo da `_supersedeSession()` (login, logout, revoca, dispose). Una sessione lunga accumula un JWT ogni ~14 minuti: circa 100 al giorno, migliaia in un'app che resta viva per settimane. Non è un problema di correttezza (sono tutti token della stessa sessione), ma tiene in memoria segreti scaduti più a lungo del necessario.
**Fix:** tenere solo gli ultimi N token (ad esempio 4) con una coda limitata: una richiesta o un socket non portano mai un token più vecchio di una o due rotazioni. Un token più vecchio ricade nel backoff, che è innocuo.

### IN-N2: la guardia d'epoca del logout backend salta una revoca valida della sessione che si chiude

**File:** `lib/repository/services/auth/session_auth_token_service.dart:436-444`
**Issue:** il bearer di `_backendLogoutToken` deriva sempre e solo dalle credenziali di `closing`, quindi non può mai essere il token di una sessione successiva (il `logout` BE revoca il `sid` di quel token). La guardia `closing.epoch != _epoch` non protegge nulla. Fa però saltare la revoca ogni volta che il refresh dedicato riesce dopo i 4 s (rete lenta, non offline): la sessione resta viva lato server con un refresh token appena ruotato e scartato. BACKEND-NOTES §2 lo descrive come voluto, ma il motivo dichiarato ("mai il bearer di una sessione nata dopo") è già garantito altrove.
**Fix:** rimuovere la guardia e lasciare che la chiamata `logout` tardiva parta in background (idempotente lato BE). In alternativa documentare in D-36 che una rete lenta più del timeout lascia la sessione viva fino a scadenza.

### IN-N3: una rotazione che cambia utente non svuota il set dei token emessi

**File:** `lib/repository/services/auth/session_auth_token_service.dart:323-325`, `:365-369`
**Issue:** se un `refreshSession` restituisse un `user.id` diverso, `_announceIdentityChange` emette `AuthAuthenticated(B)`, ma epoca e `_issuedAccessTokens` non cambiano. Una richiesta della shell di A rifiutata con `a1` ottiene da `recoverFromUnauthorized` il token di B e viene ritentata con l'identità di B: è lo stesso scenario cross-identity che WR-01 chiude per login e logout. Per il contratto BE (una sessione = un utente) è praticamente irraggiungibile.
**Fix:** se `previousUserId != null && previousUserId != _user?.id`, svuotare il set lasciando solo il token nuovo (o portare avanti l'epoca), oppure documentare l'invariante "il refresh non cambia mai utente".

### IN-N4 (pre-esistente, non introdotto dai fix): `_startSession` lascia le credenziali della sessione precedente in memoria durante la persistenza

**File:** `lib/repository/services/auth/session_auth_token_service.dart:246-253`
**Issue:** dopo `_supersedeSession()` l'epoca è già quella nuova, ma `_refreshToken` e `_accessToken` della sessione precedente restano in memoria finché `writeRefreshToken` non completa. Un `getAccessToken()` in quella finestra con un access non fresco avvierebbe un refresh della sessione vecchia sotto l'epoca nuova. Il suo esito supererebbe la guardia e sovrascriverebbe storage e memoria di B. Oggi nessun chiamante è attivo in quella finestra: l'unico caso reale è D-18 con bootstrap in retry, quando la shell non è montata.
**Fix:** chiamare `_forgetSession()` subito dopo `_supersedeSession()` in `_startSession`.

### IN-N5: uno storage illeggibile per errore transitorio porta al sign-in per tutta la vita del processo

**File:** `lib/repository/storage/session_store.dart:55-64`; `lib/repository/services/auth/session_auth_token_service.dart:97-108`
**Issue:** è il trade-off documentato in BACKEND-NOTES §3 ("l'avvio successivo lo riprova"). Su iOS però il processo può vivere giorni, e quando arriveranno le push in background (Phase 3+) l'avvio prima del primo sblocco sarà frequente. L'utente vede il sign-in pur avendo una sessione valida salvata. Se fa login, il token salvato viene sovrascritto e la sessione server precedente resta orfana.
**Fix (follow-up):** ritentare la lettura al primo `AppLifecycleState.resumed` (o con un breve backoff) finché lo stato è ancora quello del bootstrap fallito, prima di mostrare il sign-in come esito definitivo.

### IN-N6: marker salvato prima del wipe: se il processo muore in mezzo, il wipe del primo avvio non avviene più

**File:** `lib/repository/storage/session_store.dart:72-97`
**Issue:** se il processo viene ucciso tra `setBool` (`:85`) e `deleteAll` (`:96`) al primo avvio dopo una reinstallazione iOS, oppure se `deleteAll` fallisce (come già prima), il Keychain sopravvissuto non viene mai pulito: all'avvio successivo la sessione della vecchia installazione viene ripresa. La finestra è di pochi millisecondi e l'ordine scelto evita il problema più grave (logout a ogni avvio).
**Fix:** accettabile così. Per chiuderla del tutto: salvare un marker `wipe_pending` prima del wipe e cancellarlo dopo, ripetendo il wipe finché il marker è presente.

### IN-N7 (contratto BE di oggi, non introdotto dai fix): un retry transitorio fuori dalla grace di 30 s ora revoca la sessione

**File:** `lib/repository/services/auth/session_auth_token_service.dart:376-391` (retry proattivo), `:268-289` (bootstrap)
**Issue:** se una `refreshSession` raggiunge il BE (`r0→r1`) ma la risposta si perde, il client continua a ritentare con `r0`, con backoff 1, 2, 4, 8, 16, … s (cap 60 s). Un retry oltre 30 s dalla prima rotazione presenta un token ritirato e riceve `SESSION_REVOKED`, cioè un logout per un errore che era di rete. Lo stesso vale al cold start quando il processo muore tra la risposta e `writeRefreshToken` (IN-02). Con la nuova regola BE, D-09 ("transient failures do not trigger logout") vale solo per disservizi di rete sotto i ~30 s. Il FE non può fare meglio senza conoscere `r1`.
**Fix:** registrare il limite in `11-CONTEXT.md` (D-09) e in BACKEND-NOTES §6, e valutare con il BE una grace più lunga o un'idempotenza per `r0` che restituisca lo stesso `r1` invece di ruotare di nuovo.

## Copertura dei test (osservazioni, nessun finding)

- Mancano test per logout sovrapposti e per un login completato dentro il timeout di un logout (vedi WR-N1).
- I test di `AuthAuthLink`, `AuthInterceptor` e `WsReconnectPolicy` usano una recovery mockata. Nessun test combina il servizio reale e il set `_issuedAccessTokens` con un chiamante reale, ad esempio: rotazione proattiva → 401 con il token precedente → retry con il corrente; oppure 4401 sul WS dopo la rotazione → retry rapido. La logica è corretta a lettura, ma una regressione sul set non verrebbe intercettata.

---

_Reviewed: 2026-10-06T20:10:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
