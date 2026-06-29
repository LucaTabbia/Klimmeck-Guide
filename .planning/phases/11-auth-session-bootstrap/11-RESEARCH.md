# Phase 11: Auth & Session Bootstrap — Research

**Researched:** 2026-04-13
**Domain:** Twitch OAuth PKCE, secure token storage, AuthTokenService, Cubit/BLoC auth state, GraphQL + WebSocket auth injection, logout teardown
**Confidence:** HIGH (codebase letto direttamente + STACK/ARCHITECTURE/PITFALLS già prodotte per v1.0)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**D-01** — `AuthTokenService` è un singleton esposto via `RepositoryProvider` sopra il `BlocProvider` tree (pattern analogo a `KlimmeckGraphQl`). Vive in `lib/repository/services/auth/`.

**D-02** — Public surface di `AuthTokenService`: `Stream<AuthState>` (Authenticated / Unauthenticated / Bootstrapping), `Future<String?> getAccessToken()` (refresh proattivo se vicino a scadenza), `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()`.

**D-03** — `dio` interceptor e `graphql_flutter` link consumano il service tramite lo stesso provider. Nessun service locator, nessun static global.

**D-04** — Refresh mai bloccante in sessione attiva (regola invalicabile del progetto). Niente spinner, niente overlay.

**D-05** — Strategia refresh: **proactivo schedulato** basato su `expires_in` (refresh ~60s prima della scadenza), con **fallback reattivo on-401** per firing mancati.

**D-06** — Richieste concorrenti durante refresh serializzate via **single-flight mutex** (un `Completer<String>` condiviso). Una sola chiamata di refresh per ciclo.

**D-07** — Dopo refresh riuscito, il nuovo access token deve essere propagato al **WebSocket `connection_init` payload**. Dettaglio implementativo (aggiorna `initialPayload` o ricrea il link) lasciato al ricercatore/pianificatore.

**D-08** — Cold start: chiamare sempre `https://id.twitch.tv/oauth2/validate` prima di dichiarare la sessione valida.

**D-09** — In-session revocation: refresh fallisce con HTTP 400/401 + `error=invalid_grant` → trigger logout teardown. Fallimenti transitori (5xx, rete) non triggerano logout — retry con backoff.

**D-10** — Messaggio cold-start revocation: `"La sessione è scaduta, accedi di nuovo."` (neutro).

**D-11** — Logout sempre con conferma esplicita: `"Sei sicuro di voler uscire?"`.

**D-12** — Teardown order fisso e atomico: (1) revoca token Twitch (best-effort), (2) cancella subscriptions GraphQL attive, (3) **dispose + ricrea** `GraphQLClient` + `WebSocketLink` (non `store.reset()` — full client recreation), (4) cancella `flutter_secure_storage`, (5) emetti `Unauthenticated` e naviga a sign-in.

**D-13** — Step 1 (revoca Twitch) best-effort con timeout 3-5s. Fallimento non blocca il resto del teardown.

**D-14** — Switch account = stessa logout teardown + re-enters OAuth flow con `force_verify=true`.

**D-15** — OAuth flow: **`flutter_web_auth_2` + system browser + `klimmeck://auth` deep link + PKCE** (locked).

**D-16** — Auth URL include SEMPRE `force_verify=true`, anche al primo login.

**D-17** — Riusa `lib/screens/splash/splash_screen.dart` + `SplashCubit` come cold-start gate. Primo action: load token → validate Twitch → emit Authenticated/Unauthenticated.

**D-18** — Cold-start network timeout: retry indefinito in background, dopo 10s mostra messaggio non bloccante `"Connessione a Twitch instabile, attendere o accedere manualmente"` + pulsante verso sign-in.

**D-19** — Nessun token in storage → splash naviga immediatamente a sign-in.

**D-20** — Sign-in layout: Klimmeck logo + tagline + Twitch-branded "Login con Twitch" button + footer TOS/Privacy. Chrome ammesso (utility screen).

**D-21** — OAuth user-cancel (`PlatformException(CANCELED)`) → catch silenzioso, sign-in screen non toccato.

**D-22** — OAuth network/server error → errore inline su sign-in screen, button enabled per retry.

### Claude's Discretion

- Widget dialog logout (usa pattern esistente in `lib/shared/` se presente).
- URL TOS/Privacy (placeholder ok per v1).
- Styling del Twitch button (coerente con brand Twitch e theme app in `lib/theme/`).
- Scelta mutex primitive (Completer-based vs `synchronized` package) — preferire Completer se sufficiente, nessun nuovo package.
- Se ricreare `WebSocketLink` dopo refresh vs hot-update `initialPayload` — verificare quale porta davvero il nuovo token al `connection_init` del backend.
- Naming chiavi storage e `SecureStorage` wrapper shape se migliora testabilità.

### Deferred Ideas (OUT OF SCOPE)

- Onboarding screens prima di sign-in.
- Persistent retry queue per failed Twitch revoke offline.
- Multi-device / multi-session identity policies (→ Phase 11 Hardening).
- Biometric gate (FaceID / fingerprint).
- Refresh on resume da `AppLifecycleState`.
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| AUTH-01 | Login con Twitch OAuth via system browser con PKCE (WebView vietato da Twitch TOS) | Stack: `flutter_web_auth_2` v5.0.2 + PKCE flow documentato; pattern PKCE in Code Examples |
| AUTH-02 | Access token + refresh token in encrypted platform storage (mai in shared_preferences) | Stack: `flutter_secure_storage` v10.0.0; Android Keystore / iOS Keychain; SecureStorageService pattern |
| AUTH-03 | Sessione persiste tra restart via refresh token rotation | D-08 (validate on cold start) + D-05 (proactive scheduled refresh) + SecureStorageService |
| AUTH-04 | Logout: revoca token, clear storage, reset GraphQL cache, cancella subscriptions, torna a sign-in | D-12 teardown order; pitfall #3 stale data; full GraphQLClient recreation (D-12 step 3) |
| AUTH-05 | Switch Twitch account: logout + re-login con account diverso | D-14 (stessa teardown + `force_verify=true`) + D-16 |
| AUTH-06 | Token expiry: refresh trasparente; 401 concorrenti serializzati via mutex | D-05/D-06: proactive + Completer single-flight; pitfall #2 race condition |
| AUTH-07 | Revocation detection: app rileva invalidazione e ritorna a sign-in con messaggio chiaro | D-08 (cold start validate) + D-09 (in-session invalid_grant) + D-10 (messaggio neutro) |
</phase_requirements>

---

## Summary

La fase costruisce il substrato di identità di tutta l'app. Il codebase è **brownfield** con `KlimmeckGraphQl` (classe singleton + `ValueNotifier<GraphQLClient>`) già wired in `main.dart`. Non esiste autenticazione: `SignInCubit` è uno stub vuoto, `SplashCubit` gestisce solo preload SVG. La struttura `MultiBlocProvider` attuale mette tutti i Cubit al livello root senza gate di auth — va ristrutturata per wrappare il subtree autenticato.

Il design deciso in CONTEXT.md richiede: (1) `AuthTokenService` singleton esposto via `RepositoryProvider`, (2) un `AuthCubit` (o ristrutturazione di `SignInCubit`) che consuma il service, (3) injection del token nel `GraphQLClient` tramite `AuthLink` + `WebSocketLink.initialPayload`, (4) `flutter_web_auth_2` + `flutter_secure_storage` come nuovi package. La logica di refresh è composta da timer proattivo + fallback on-401 + Completer mutex — tre meccanismi distinti che devono coordinarsi.

**Primary recommendation:** Costruire `AuthTokenService` prima di tutto il resto. Tutti gli altri componenti della fase (cubit, interceptor, splash gate) lo consumano. Il service è testabile in isolamento, non ha dipendenze Flutter, e la sua `Stream<AuthState>` è l'unico segnale che il widget tree deve osservare.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_web_auth_2` | **5.0.2** | Twitch OAuth — apre system browser, cattura callback `klimmeck://auth` | Successore ufficiale di `flutter_web_auth` (deprecated); ASWebAuthenticationSession iOS, Chrome Custom Tab Android; nessuna dipendenza native SDK pesante |
| `flutter_secure_storage` | **10.0.0** | Encrypted storage per access + refresh token | Android Keystore / iOS Keychain; unico wrapper unificato in Flutter; nessuna alternativa valida per token storage |
| `flutter_bloc` | 9.1.1 (già presente) | BLoC/Cubit per `AuthCubit` e stati | Stack di progetto |
| `graphql_flutter` | 5.2.1 (già presente) | GraphQL client + `AuthLink` per injection token HTTP; `WebSocketLink` per WS | Stack di progetto |
| `dio` | 5.4.0 (già presente) | Token exchange POST (`/oauth2/token`), validate (`/oauth2/validate`), revoke (`/oauth2/revoke`) | Stack di progetto |

[VERIFIED: pub.dev registry] — `flutter_secure_storage` 10.0.0, `flutter_web_auth_2` 5.0.2 verificati al 2026-04-13.

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `equatable` | 2.0.0 (già presente) | `AuthState` immutabile con `props` | Obbligatorio per tutti i Cubit state del progetto |
| `shared_preferences` | 2.0.12 (già presente) | `user_id` Twitch (non sensibile) | Solo dati non sensibili; mai token |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Completer single-flight mutex | Package `synchronized` | `synchronized` è più robusto per contesti complessi ma aggiunge una dipendenza; per un singolo lock su refresh il Completer è sufficiente e non richiede nuovo package |
| `flutter_web_auth_2` | `flutter_appauth` | AppAuth più robusto per OIDC completo, ma richiede `.well-known/openid-configuration` + CocoaPods pod pesante; per Twitch PKCE plain il `flutter_web_auth_2` è più leggero |

**Installation:**
```bash
flutter pub add flutter_web_auth_2 flutter_secure_storage
```

---

## Architecture Patterns

### Recommended Project Structure (nuovi file di questa fase)

```
lib/
├── repository/
│   └── services/
│       └── auth/
│           ├── auth_token_service.dart       # Singleton service — D-01, D-02
│           └── secure_storage_service.dart   # Wrapper flutter_secure_storage — AUTH-02
├── screens/
│   ├── splash/
│   │   ├── splash_screen.dart               # Esistente — esteso come cold-start gate (D-17)
│   │   └── cubit/
│   │       ├── splash_cubit.dart            # Esistente — esteso per auth resolve
│   │       └── splash_state.dart            # Esistente — aggiunge stati auth
│   ├── signIn/
│   │   ├── sign_in_screen.dart              # Esistente — esteso con UX D-20..D-22
│   │   └── cubit/
│   │       ├── sign_in_cubit.dart           # Stub esistente — sostituito/esteso per OAuth flow
│   │       └── sign_in_state.dart
│   └── auth/                                # Nuovo: AuthCubit globale
│       └── cubit/
│           ├── auth_cubit.dart
│           └── auth_state.dart
├── graphql/
│   └── mutations/
│       └── auth_mutations.dart              # Nessuna — auth è via REST; file non necessario
└── main.dart                                # Ristrutturato: AuthCubit sopra MultiBlocProvider
```

### Pattern 1: AuthTokenService Singleton via RepositoryProvider

**What:** `AuthTokenService` esposto come singleton tramite `RepositoryProvider` sopra il BLoC tree. Tutti i consumer (interceptor `dio`, `AuthLink` per GraphQL, `WebSocketLink.initialPayload`) lo leggono senza accedere al widget tree.

**When to use:** Ogni volta che un componente non-UI (link, interceptor) deve accedere al token corrente senza `BuildContext`.

```dart
// lib/repository/services/auth/auth_token_service.dart
// [ASSUMED] — pattern derivato da ARCHITECTURE.md e CONTEXT.md D-01/D-02
class AuthTokenService {
  // Stream per il widget tree
  final _authStateController = StreamController<AuthState>.broadcast();
  Stream<AuthState> get authStateStream => _authStateController.stream;

  // Token in memoria (breve durata)
  String? _accessToken;
  DateTime? _accessTokenExpiry;

  // Proactive refresh: Completer per single-flight mutex (D-06)
  Completer<String>? _refreshCompleter;

  Future<String?> getAccessToken() async {
    if (_accessToken != null && _isTokenFresh()) return _accessToken;
    return _refreshCompleter?.future ?? _performRefresh();
  }

  bool _isTokenFresh() =>
      _accessTokenExpiry != null &&
      _accessTokenExpiry!.isAfter(DateTime.now().add(const Duration(seconds: 60)));

  // Chiamato internamente dopo login/refresh riuscito
  void _setAccessToken(String token, Duration expiresIn) {
    _accessToken = token;
    _accessTokenExpiry = DateTime.now().add(expiresIn);
  }

  void clear() {
    _accessToken = null;
    _accessTokenExpiry = null;
    _refreshCompleter = null;
  }
  // ...
}
```

### Pattern 2: AuthLink + WebSocketLink con token da AuthTokenService

**What:** `graphql_client_provider.dart` inietta l'`AuthLink` che legge il token da `AuthTokenService` a ogni richiesta (non a initialization time). Risolve il bug `navigatorKey.currentContext!` esistente.

**When to use:** All'inizializzazione del `GraphQLClient` in `main.dart` o nel provider.

```dart
// lib/repository/services/graphql/graphql_client_provider.dart — modificato
// [ASSUMED] — pattern da ARCHITECTURE.md §1
ValueNotifier<GraphQLClient> initGraphQLClient(AuthTokenService authService) {
  final httpLink = HttpLink(EnvConfig.graphqlHttpUrl);

  final authLink = AuthLink(
    getToken: () async {
      final token = await authService.getAccessToken();
      return token != null ? 'Bearer $token' : '';
    },
  );

  final wsLink = WebSocketLink(
    EnvConfig.graphqlWsUrl,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: Duration(seconds: EnvConfig.wsInactivityTimeoutSeconds),
      initialPayload: () async {
        final token = await authService.getAccessToken();
        return token != null ? {'Authorization': 'Bearer $token'} : <String, dynamic>{};
      },
    ),
    subProtocol: GraphQLProtocol.graphqlTransportWs,
  );

  final link = Link.split(
    (request) => request.isSubscription,
    wsLink,
    authLink.concat(httpLink),
  );

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      queryRequestTimeout: Duration(seconds: EnvConfig.queryTimeoutSeconds),
    ),
  );
}
```

**Nota su D-07 (WebSocket post-refresh):** il `WebSocketLink.initialPayload` è una `Future<Map>` eseguita a ogni nuova connessione WebSocket. Ricreando il client post-refresh (oppure disconnettendo/riconnettendo il WS), il prossimo `connection_init` userà il token fresco. La scelta tra ricreazione del client o `wsLink.disconnect()` + reconnect è lasciata all'implementatore ma deve essere verificata con il backend (confermare che NestJS `graphql-transport-ws` accetti il nuovo token su reconnect senza richiedere re-subscribe).

### Pattern 3: Dio Interceptor per 401 — single-flight mutex

**What:** Un `Interceptor` registrato sul client `dio` intercetta risposte 401. Il primo interceptor a ricevere 401 esegue il refresh e aggiorna il `Completer`; i concorrenti attendono lo stesso `Completer`.

```dart
// [ASSUMED] — pattern standard Dio interceptor
class AuthInterceptor extends Interceptor {
  final AuthTokenService _authService;
  AuthInterceptor(this._authService);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      try {
        // getAccessToken() internamente usa il Completer mutex (D-06)
        final newToken = await _authService.getAccessToken();
        if (newToken != null) {
          final opts = err.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          final response = await Dio().fetch(opts);
          return handler.resolve(response);
        }
      } catch (_) {
        // refresh fallito → handleRevocation() viene chiamato da AuthTokenService
      }
    }
    handler.next(err);
  }
}
```

### Pattern 4: Cold-start gate in SplashCubit

**What:** `SplashCubit` esteso per diventare il cold-start auth gate (D-17). Il flusso è: carica token da SecureStorage → chiama `validate` su Twitch → emetti stato. La logica SVG preload esistente convive ma non blocca il gate auth.

```dart
// Estensione di SplashCubit — [ASSUMED]
Future<void> bootstrap() async {
  emit(SplashBootstrapping());
  final hasToken = await _authTokenService.hasStoredRefreshToken();
  if (!hasToken) {
    emit(SplashUnauthenticated());
    return;
  }
  // Avvia timeout 10s (D-18)
  _startInstabilityTimer();
  try {
    await _authTokenService.validateAndRefreshOnColdStart(); // chiama /oauth2/validate
    emit(SplashAuthenticated());
  } catch (e) {
    if (e is RevocationException) {
      emit(SplashRevoked(message: "La sessione è scaduta, accedi di nuovo."));
    } else {
      // Transient — continua retry in background, timer gestisce il messaggio
    }
  }
}
```

### Anti-Patterns to Avoid

- **Non riconstruire MultiBlocProvider prima di AuthCubit:** tutti i Cubit di feature (CharacterCubit, QuestCubit, ecc.) devono essere istanziati SOLO dopo che l'auth è confermata. Nel `main.dart` attuale sono tutti al root — devono essere spostati nel subtree autenticato.
- **Non leggere il token direttamente da SecureStorage nei Cubit feature:** usare sempre `AuthTokenService.getAccessToken()` che gestisce refresh + mutex.
- **Non usare `firebase_auth` per Twitch OAuth:** già presente in pubspec ma è l'approccio sbagliato (routing inutile attraverso Firebase, extra latenza, config Firebase OAuth Twitch richiede setup aggiuntivo).
- **Non fare `store.reset()` al logout:** CONTEXT.md D-12 richiede full `GraphQLClient` + `WebSocketLink` recreation per garantire zero listener leak.
- **Non usare `SharedPreferences` per access o refresh token:** vietato da AUTH-02 e da HARDEN-01.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| System browser OAuth + callback | Custom `url_launcher` + deep link listener manuale | `flutter_web_auth_2` | Gestisce ASWebAuthenticationSession (iOS) e Chrome Custom Tab (Android), intercetta callback, cancella flow su dismiss. Manuale richiede 3+ package e gestione edge case OS-specifici. |
| Encrypted token storage | Encrypted SharedPreferences custom | `flutter_secure_storage` | Wrappa Android Keystore + iOS Keychain in API unica. Implementare manualmente richiederebbe JNI (Android) e SecItem (iOS). |
| PKCE code_verifier generation | Stringa random manuale | `dart:math` Random.secure() già sufficiente | Tuttavia la derivazione `BASE64URL(SHA256(verifier))` richiede `dart:convert` + `crypto` (già transitive dep di graphql_flutter) — usare `Hmac`/`sha256` dal package `crypto`. |

**Key insight:** La complessità di OAuth mobile su iOS/Android (session handling, cancellation, redirect interception, keychain access) è interamente nascosta da questi due package. Qualsiasi implementazione custom introduce buchi di sicurezza (pitfall #4: deep link hijacking).

---

## Common Pitfalls

### Pitfall 1: Token in SharedPreferences (HARDEN-01)
**What goes wrong:** `StorageManager` esistente usa `SharedPreferences`; tentazione di riusarlo per i token.
**Why it happens:** Path of least resistance — il pattern è già nel codebase.
**How to avoid:** `SecureStorageService` separato, non estendere `StorageManager`. Grep CI: cerca `SharedPreferences` + `token` come signal.
**Warning signs:** Qualsiasi `KGStorageManager.save(key: '...token...', ...)`.

### Pitfall 2: Refresh race condition — doppio refresh / silent logout
**What goes wrong:** Due richieste concorrenti ricevono 401, entrambe chiamano refresh → la seconda usa il refresh token già invalidato → logout silenzioso.
**Why it happens:** Nessuna sincronizzazione sul refresh path.
**How to avoid:** `Completer<String>` come single-flight mutex in `AuthTokenService.getAccessToken()`. Il primo chiamante inizia il refresh e salva il Completer; i successivi awaittano lo stesso Completer.
**Warning signs:** Logout casuale in condizioni di rete instabile.

### Pitfall 3: Stale data on logout — account bleed
**What goes wrong:** Logout senza reset dei Cubit → `CharacterCubit` mostra il personaggio del profilo precedente al prossimo login.
**Why it happens:** Logout implementato come "pulisci token + naviga" senza teardown BLoC.
**How to avoid:** Il subtree `MultiBlocProvider` (CharacterCubit, QuestCubit, ecc.) deve essere dentro un widget condizionato allo stato `Authenticated` di `AuthCubit`. Quando `AuthCubit` emette `Unauthenticated`, il subtree viene smontato e tutti i Cubit vengono disposti automaticamente.
**Warning signs:** Dopo logout+login, `CharacterCubit.state` contiene dati del profilo precedente.

### Pitfall 4: WebSocket non aggiornato dopo refresh
**What goes wrong:** Token HTTP aggiornato, ma il `WebSocketLink` continua a usare il vecchio token nel `connection_init`. Le subscription rimangono su una connessione non autorizzata o ottengono dati sbagliati.
**Why it happens:** `WebSocketLink.initialPayload` viene eseguito solo alla connessione iniziale, non ad ogni messaggio.
**How to avoid:** Dopo un refresh riuscito, forzare un disconnect + reconnect del WebSocket (oppure ricreare il client, D-12 lo fa già al logout). Per il refresh in-session (non logout), verificare con il backend se basta la reconnessione del socket o se serve un `connection_init` fresco.
**Warning signs:** Subscription GraphQL smette di ricevere eventi dopo un refresh silenzioso.

### Pitfall 5: `PlatformException(CANCELED)` non gestita
**What goes wrong:** L'utente chiude il browser OAuth → `flutter_web_auth_2` lancia `PlatformException` con codice `CANCELED` → se non catchata, crash o error state visibile.
**Why it happens:** Mancanza di handler specifico per la cancellazione.
**How to avoid:** In `SignInCubit.login()`, catturare `PlatformException` e distinguere `CANCELED` (silenzioso, D-21) da errori reali (D-22).
**Warning signs:** Chiudere il browser di login mostra una schermata di errore.

### Pitfall 6: Firebase inizializzato accidentalmente durante bootstrap
**What goes wrong:** `firebase_core` e `firebase_messaging` sono presenti in pubspec. Se il bootstrap auth tocca accidentalmente Firebase, l'app crasha perché non è configurata.
**Why it happens:** I package sono importati ma non inizializzati (nessun `google-services.json`/`GoogleService-Info.plist`).
**How to avoid:** Non inizializzare Firebase in questa fase. Lasciare i commenti in `main.dart`. Firebase init appartiene a Phase 5 (Notifications).
**Warning signs:** Import di `firebase_messaging` o `firebase_auth` nel codice auth.

### Pitfall 7: `MultiBlocProvider` root non ristrutturato
**What goes wrong:** `CharacterCubit`, `QuestCubit`, `MainScreenCubit` ecc. rimangono al root anche dopo l'introduzione di `AuthCubit`. Questi Cubit eseguono query GraphQL all'inizializzazione senza token → errori 401 al cold start.
**Why it happens:** Il `main.dart` attuale ha tutti i Cubit al root — è la prima cosa da ristrutturare.
**How to avoid:** Spostare tutti i Cubit di feature dentro il subtree autenticato (BlocBuilder su `AuthCubit` state). Solo `AuthCubit` (e `SplashCubit` per il gate) restano al root.

---

## Code Examples

### PKCE code_verifier + code_challenge generation

```dart
// [ASSUMED] — pattern PKCE standard (RFC 7636)
// Usa dart:math, dart:convert, package:crypto (già transitiva da graphql_flutter)
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String _generateCodeVerifier() {
  const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
  final random = Random.secure();
  return List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
}

String _generateCodeChallenge(String verifier) {
  final bytes = utf8.encode(verifier);
  final digest = sha256.convert(bytes);
  return base64UrlEncode(digest.bytes).replaceAll('=', '');
}
```

### Twitch OAuth URL construction

```dart
// [CITED: https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#authorization-code-grant-flow]
String buildTwitchAuthUrl({
  required String clientId,
  required String codeChallenge,
  required String state,
}) {
  final params = {
    'client_id': clientId,
    'redirect_uri': 'klimmeck://auth',
    'response_type': 'code',
    'scope': 'user:read:email',             // adattare agli scope necessari
    'code_challenge': codeChallenge,
    'code_challenge_method': 'S256',
    'state': state,
    'force_verify': 'true',                 // D-16 — sempre presente
  };
  final uri = Uri.https('id.twitch.tv', '/oauth2/authorize', params);
  return uri.toString();
}
```

### flutter_web_auth_2 authenticate call

```dart
// [ASSUMED] — API da pub.dev flutter_web_auth_2 5.0.2
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

Future<String> performOAuthLogin(String authUrl) async {
  // Lancia il browser — su iOS: ASWebAuthenticationSession, Android: Chrome Custom Tab
  final result = await FlutterWebAuth2.authenticate(
    url: authUrl,
    callbackUrlScheme: 'klimmeck',
  );
  // result = 'klimmeck://auth?code=XXXX&state=YYYY'
  final uri = Uri.parse(result);
  final code = uri.queryParameters['code']!;
  return code;
}
```

### Twitch token exchange (POST /oauth2/token)

```dart
// [CITED: https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/]
// Usa il dio client esistente (KlimmeckRest o Dio diretto per Twitch endpoint)
Future<TwitchTokenResponse> exchangeCodeForTokens({
  required String code,
  required String codeVerifier,
  required String clientId,
}) async {
  final response = await _dio.post(
    'https://id.twitch.tv/oauth2/token',
    data: {
      'client_id': clientId,
      'code': code,
      'code_verifier': codeVerifier,
      'grant_type': 'authorization_code',
      'redirect_uri': 'klimmeck://auth',
    },
    options: Options(contentType: Headers.formUrlEncodedContentType),
  );
  return TwitchTokenResponse.fromJson(response.data);
}
```

### flutter_secure_storage — SecureStorageService wrapper

```dart
// lib/repository/services/auth/secure_storage_service.dart
// [ASSUMED] — wrapper minimo per testabilità
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _accessTokenKey = 'twitch_access_token';
  static const _refreshTokenKey = 'twitch_refresh_token';

  final _storage = const FlutterSecureStorage();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
  }

  Future<String?> getRefreshToken() => _storage.read(key: _refreshTokenKey);
  Future<String?> getAccessToken() => _storage.read(key: _accessTokenKey);

  Future<void> clearAll() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
  }
}
```

### Single-flight mutex con Completer (D-06)

```dart
// [ASSUMED] — pattern standard Dart per single-flight async
Completer<String>? _refreshCompleter;

Future<String> _refreshAccessToken() async {
  // Se un refresh è già in corso, attendi il suo risultato
  if (_refreshCompleter != null) {
    return _refreshCompleter!.future;
  }

  _refreshCompleter = Completer<String>();
  try {
    final newToken = await _doRefresh();           // chiama Twitch /oauth2/token
    _refreshCompleter!.complete(newToken);
    return newToken;
  } catch (e) {
    _refreshCompleter!.completeError(e);
    rethrow;
  } finally {
    _refreshCompleter = null;
  }
}
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `flutter_web_auth` (deprecated) | `flutter_web_auth_2` v5.x | 2023 | Usa API native OS più stabili; nessun breaking change nell'API pubblica |
| `flutter_secure_storage` v8/v9 | v10.0.0 (2025) | 2025 | API identica, supporto Android API 28+ migliorato; richiede Kotlin 1.8+ |
| `firebase_auth` per Twitch OAuth | Direct Twitch PKCE (no Firebase) | Best practice 2024+ | Elimina latenza e dipendenza da Firebase per il critical path di login |

**Deprecated/outdated:**
- `flutter_web_auth`: rimosso da pub.dev, usa `flutter_web_auth_2`.
- `firebase_auth` per Twitch: anti-feature esplicita in REQUIREMENTS.md.
- `WebView` per OAuth: vietato da Twitch TOS.

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Il `crypto` package (per sha256 PKCE) è già disponibile come dipendenza transitiva di `graphql_flutter` | Code Examples — PKCE | Se non disponibile, aggiungere `crypto: ^3.x` a pubspec (basso rischio, package stabile) |
| A2 | `flutter_web_auth_2` API: `FlutterWebAuth2.authenticate(url:, callbackUrlScheme:)` è il metodo pubblico corretto in v5.x | Code Examples | Se rinominato in v5 (possibile minor breaking change rispetto a v4), verificare pub.dev changelog prima di usare |
| A3 | NestJS `graphql-transport-ws` accetta un nuovo token su WebSocket reconnect senza richiedere re-subscribe esplicito | Pattern 2 (WebSocket post-refresh) | Se richiede logica aggiuntiva di re-subscribe, D-07 ha un costo implementativo maggiore — verificare con backend team |
| A4 | Il `Completer`-based single-flight è sufficiente senza package `synchronized` | Pattern 3 + D-06 | Se emergono casi di contention complessa, aggiungere `synchronized` ma questo non è previsto dal CONTEXT.md |
| A5 | `flutter_secure_storage` v10 mantiene API backward-compatible con v9 (`FlutterSecureStorage`, `.write`, `.read`, `.delete`) | Standard Stack | In caso di breaking change: leggere il changelog su pub.dev prima di aggiungere il package |

---

## Open Questions

1. **Backend `connection_init` auth contract (D-07)**
   - What we know: NestJS usa `graphql-transport-ws`; `initialPayload` invia il token al connect.
   - What's unclear: Il backend si aspetta `{'Authorization': 'Bearer <token>'}` o `{'token': '<token>'}` nel `connection_init`? Dopo un token refresh, il backend chiede un nuovo `connection_init` o accetta il token aggiornato solo sulla prossima connessione?
   - Recommendation: Verificare con il backend team prima di implementare D-07. Se serve reconnect esplicito post-refresh, questo è un task separato nel piano.

2. **Scope OAuth Twitch necessari**
   - What we know: Phase 11 richiede solo identità (login). Phase 3 (sync) potrebbe richiedere scope aggiuntivi.
   - What's unclear: Quali scope Twitch sono necessari per il game backend? `user:read:email`? Scope canale?
   - Recommendation: Definire gli scope nella `EnvConfig` come costante, non hardcoded nell'URL. Chiedere al backend team quali scope sono richiesti per il server a convalidare l'identità del viewer.

3. **`EnvConfig` — Twitch Client ID**
   - What we know: `EnvConfig` usa `dart-define` per URL backend.
   - What's unclear: Come viene passato il `TWITCH_CLIENT_ID` al build? Già gestito fuori VCS?
   - Recommendation: Aggiungere `TWITCH_CLIENT_ID` alle variabili `dart-define` in `EnvConfig`, documentare il valore in `.env.example` (non in repo).

---

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `flutter_web_auth_2` | AUTH-01 OAuth flow | ✗ (da aggiungere) | 5.0.2 su pub.dev | — (bloccante) |
| `flutter_secure_storage` | AUTH-02 encrypted storage | ✗ (da aggiungere) | 10.0.0 su pub.dev | — (bloccante) |
| `dio` | Token exchange REST calls | ✓ | 5.4.0 in pubspec | — |
| `graphql_flutter` | AuthLink, WebSocketLink | ✓ | 5.2.1 in pubspec | — |
| `flutter_bloc` + `equatable` | AuthCubit | ✓ | 9.1.1 / 2.0.0 in pubspec | — |
| Android minSdkVersion 21+ | flutter_secure_storage | ✓ | Già configurato | — |
| iOS Keychain | flutter_secure_storage | ✓ | Disponibile iOS 12+ | — |
| Twitch OAuth endpoint | AUTH-01..07 | ✓ (live) | API v2 stabile | — |

**Missing dependencies with no fallback:**
- `flutter_web_auth_2`: necessario per AUTH-01, nessuna alternativa accettabile senza WebView.
- `flutter_secure_storage`: necessario per AUTH-02 (HARDEN-01), SharedPreferences non è alternativa valida.

**Platform setup richiesta (Wave 0 o Task 1):**

Android — `android/app/src/main/AndroidManifest.xml`:
```xml
<activity
  android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
  android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="klimmeck" android:host="auth" />
  </intent-filter>
</activity>
```

iOS — `ios/Runner/Info.plist`:
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key><string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array><string>klimmeck</string></array>
  </dict>
</array>
```

[VERIFIED: STACK.md §1 + §2] — setup confermato dalla ricerca stack già prodotta.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` (da aggiungere a dev_dependencies) + `mocktail` (da aggiungere) |
| Config file | `analysis_options.yaml` (esiste) — abilitare `avoid_print: true` in questa fase |
| Quick run command | `flutter test test/repository/services/auth/ test/screens/auth/` |
| Full suite command | `flutter test` |

**Nota:** `bloc_test` e `mocktail` non sono in `pubspec.yaml`. Sono obbligatori per TDD (docs/rules/testing.md). Aggiungere a `dev_dependencies`:
```yaml
dev_dependencies:
  bloc_test: ^9.1.7
  mocktail: ^1.0.4
```
[ASSUMED] — versioni da verificare su pub.dev prima di aggiungere.

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| AUTH-01 | OAuth flow: URL corretto con PKCE + `force_verify=true`; cancellazione silente | unit (AuthTokenService) | `flutter test test/repository/services/auth/auth_token_service_test.dart` | ❌ Wave 0 |
| AUTH-01 | `SignInCubit` emette stati corretti su login success/cancel/error | bloc_test | `flutter test test/screens/signIn/cubit/sign_in_cubit_test.dart` | ❌ Wave 0 |
| AUTH-02 | Token salvati in SecureStorage, mai in SharedPreferences | unit (SecureStorageService) | `flutter test test/repository/services/auth/secure_storage_service_test.dart` | ❌ Wave 0 |
| AUTH-03 | Cold start con refresh token valido → sessione ripristinata senza re-prompt | bloc_test (SplashCubit) | `flutter test test/screens/splash/cubit/splash_cubit_test.dart` | ❌ Wave 0 |
| AUTH-04 | Logout: teardown order completo (D-12), storage cleared | unit (AuthTokenService.logout) | incluso in `auth_token_service_test.dart` | ❌ Wave 0 |
| AUTH-05 | Switch account: logout + re-login con `force_verify=true` | bloc_test (AuthCubit) | `flutter test test/screens/auth/cubit/auth_cubit_test.dart` | ❌ Wave 0 |
| AUTH-06 | Refresh mutex: due 401 concorrenti → una sola chiamata refresh | unit concurrency test | incluso in `auth_token_service_test.dart` | ❌ Wave 0 |
| AUTH-07 | Revocation detection: `invalid_grant` → logout teardown + messaggio corretto | unit (AuthTokenService) | incluso in `auth_token_service_test.dart` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `flutter test test/repository/services/auth/ test/screens/auth/ test/screens/signIn/ test/screens/splash/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green + `flutter analyze` pulito prima di `/gsd-verify-work`

### Wave 0 Gaps

- [ ] `test/repository/services/auth/auth_token_service_test.dart` — copre AUTH-01, AUTH-04, AUTH-06, AUTH-07
- [ ] `test/repository/services/auth/secure_storage_service_test.dart` — copre AUTH-02
- [ ] `test/screens/splash/cubit/splash_cubit_test.dart` — copre AUTH-03 (esteso)
- [ ] `test/screens/signIn/cubit/sign_in_cubit_test.dart` — copre AUTH-01 (UX flow)
- [ ] `test/screens/auth/cubit/auth_cubit_test.dart` — copre AUTH-05
- [ ] `test/helpers/` — mock fixtures (mock `SecureStorageService`, `Dio`, `FlutterWebAuth2`)
- [ ] `flutter pub add --dev bloc_test mocktail` — se non già in pubspec

---

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | PKCE + system browser (no WebView); `force_verify=true`; `state` parameter validation |
| V3 Session Management | yes | Refresh token rotation; proactive expiry; full teardown on logout |
| V4 Access Control | no | Phase 11 scope solo auth; gating BLoC tree è conseguenza, non enforcement ASVS |
| V5 Input Validation | yes | Validare `state` parameter nel callback OAuth; non fidarsi del `code` senza verifica `code_verifier` |
| V6 Cryptography | yes | `Random.secure()` per `code_verifier`; SHA-256 per `code_challenge`; mai `plain` method |
| V8 Data Protection | yes | Token solo in `flutter_secure_storage`; access token solo in memoria; mai in log |

### Known Threat Patterns for Twitch OAuth PKCE Mobile

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Deep link hijacking (intercetta callback `klimmeck://auth`) | Spoofing | PKCE S256 elimina l'utilità del codice rubato (code_verifier non è nel redirect) |
| `state` parameter forgery | Tampering | Generare `state` casuale per ogni login; validare nella risposta callback |
| Token in logs / crash reports | Information Disclosure | Mai loggare token; non passare token come argomento di route/navigazione |
| Refresh token esfiltrazione | Information Disclosure | `flutter_secure_storage` Keychain/Keystore; mai `SharedPreferences` |
| Double refresh (401 race) | Denial of Service | Completer single-flight mutex (D-06) |
| Logout incompleto (stale subscription) | Information Disclosure | Full `GraphQLClient` recreation (D-12 step 3) + subtree BLoC disposal |

---

## Project Constraints (from CLAUDE.md)

| Constraint | Impact su questa fase |
|------------|----------------------|
| **No UI chrome fuori utility screens** | Sign-in è utility screen → AppBar ammessa. SplashScreen è già immersiva — il messaggio di instabilità (D-18) deve essere overlay non-intrusivo, non AppBar. |
| **No loading bloccanti in sessione** | Refresh silenzioso obbligatorio (D-04). Spinner ammesso SOLO al cold start (SplashScreen). |
| **Branch + PR per ogni fase GSD** | Creare `feat/auth-session-bootstrap` da `develop` prima di qualsiasi commit di codice. |
| **Backend è fonte di verità** | `AuthTokenService` riceve `expires_in` dal backend Twitch, non calcola scadenze autonomamente. |
| **Nessun secret in repo** | `TWITCH_CLIENT_ID` via `dart-define`; nessun `.env` committato. |
| **TDD obbligatorio** | Test scritti PRIMA dell'implementazione. Wave 0 crea tutti i file test vuoti con i test case fallenti. |
| **BLoC/Cubit senza dipendenze Flutter** | `AuthTokenService` e `AuthCubit` non dipendono da `BuildContext`. |
| **No service locator / GetIt** | `AuthTokenService` esposto via `RepositoryProvider`, non come singleton statico. |
| **`flutter analyze` pulito a ogni commit** | Abilitare `avoid_print: true` in `analysis_options.yaml` in questa fase (fix del lint debt esistente). |

---

## Sources

### Primary (HIGH confidence)

- `.planning/codebase/STRUCTURE.md`, `INTEGRATIONS.md`, `CONCERNS.md` — codebase audit diretto
- `.planning/research/STACK.md` §1 (flutter_web_auth_2), §2 (flutter_secure_storage) — ricerca stack v1.0
- `.planning/research/ARCHITECTURE.md` §1 (Auth), §10 (existing components) — pattern architetturali verificati sul codebase
- `lib/main.dart`, `lib/repository/services/graphql/graphql_client_provider.dart`, `lib/screens/signIn/cubit/sign_in_cubit.dart`, `lib/screens/splash/cubit/splash_cubit.dart` — lettura diretta file esistenti
- `pubspec.yaml` — versioni package effettive
- pub.dev registry — `flutter_secure_storage` 10.0.0, `flutter_web_auth_2` 5.0.2 verificati al 2026-04-13

### Secondary (MEDIUM confidence)

- [CITED: https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/] — Authorization Code Flow + PKCE
- [CITED: https://dev.twitch.tv/docs/authentication/validate-tokens/] — validate endpoint cold start (D-08)
- [CITED: https://dev.twitch.tv/docs/authentication/revoke-tokens/] — revoke endpoint (D-13)
- `.planning/research/PITFALLS.md` #1..#4 (token storage, race condition, stale data, deep link hijacking)
- `docs/rules/architecture.md`, `state-management.md`, `testing.md`, `naming.md`, `graphql.md`, `workflow.md` — regole di progetto lette direttamente

### Tertiary (LOW confidence)

- Versioni `bloc_test` e `mocktail` per `dev_dependencies` — da verificare su pub.dev prima di aggiungere.
- Scope OAuth Twitch esatti richiesti dal backend — non verificabile in questa fase; richiedono conferma con il backend team (Open Question #2).

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — package verificati su pub.dev + conferma codebase audit
- Architecture patterns: HIGH — derivati direttamente da CONTEXT.md (decisions bloccate) + ARCHITECTURE.md sul codebase reale
- Pitfalls: HIGH — basati su PITFALLS.md (ricerca esistente) + analisi diretta del codice (main.dart, graphql_client_provider.dart, sign_in_cubit.dart)
- Test map: MEDIUM — blocchi test identificati dai requisiti, ma comandi esatti dipendono dalla struttura directory finale

**Research date:** 2026-04-13
**Valid until:** 2026-05-13 (30 giorni — stack stabile; Twitch OAuth API non ha breaking change frequenti)
