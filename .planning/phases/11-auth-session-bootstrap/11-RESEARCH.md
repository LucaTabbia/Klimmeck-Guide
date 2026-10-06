# Phase 11: Auth & Session Bootstrap — Research (rev. 2, 2026-10-06)

**Researched:** 2026-10-06
**Domain:** Flutter — sessione first-party mediata dal backend (system browser login + ticket exchange, secure storage, refresh single-flight, WS re-auth, logout atomico, dev bypass)
**Confidence:** HIGH sullo stack/versioni/setup nativo (verificati su sorgenti dei package e con una build Android reale in una copia scratch), MEDIUM sul contratto BE (BACKEND-NOTES.md non esiste ancora: si pianifica contro 02-CONTEXT/02-RESEARCH del BE)

> **Questo file SOSTITUISCE la research di aprile 2026** (PKCE/Twitch diretto, Twitch token, `/oauth2/validate`, `TWITCH_CLIENT_ID`): tutto quel materiale è obsoleto e non va riusato. Dell'aprile restano valide (e sono state **ri-verificate**) solo le note su `flutter_web_auth_2` / `flutter_secure_storage` — con **correzioni importanti** (versioni, AGP, opzioni Android) elencate sotto.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**AuthTokenService — shape & placement**
- **D-01:** `AuthTokenService` is a singleton exposed via `RepositoryProvider` placed above the `BlocProvider` tree (already wired in Phase 1 — keep).
- **D-02:** Public surface is the Phase 1 contract, unchanged: `initialize()`, `Stream<AuthState> authStateStream`, `Future<String?> getAccessToken()`, `login()`, `logout()`, `handleRevocation()`, `dispose()`. `getAccessToken()` returns the current valid **backend session JWT**, refreshing first if it knows the token is near/past expiry.
- **D-03:** `dio` interceptor and `graphql_flutter` link consume the service through the same provider — no service locator, no static globals.

**Token refresh strategy (AUTH-06)**
- **D-04:** **Refresh must never block UI in an active session** (project-wide rule). No spinners, no overlays during in-session refresh.
- **D-05 (amended):** **Proactive scheduled refresh** based on the session's `accessTokenExpiresAt` returned by the backend (refresh ~60s before expiry, recomputed on each successful refresh), with a **reactive fallback** when a request comes back unauthenticated (GraphQL `extensions.code == UNAUTHENTICATED`, or HTTP 401 on REST) for missed firings (background app, clock skew). Refresh = backend mutation `refreshSession(refreshToken)`; the refresh token **rotates on every call** and the new one must be persisted before the old one is forgotten.
- **D-06:** Concurrent in-flight requests during a refresh are serialized via a **single-flight mutex** (a shared `Completer<String>`): exactly one network refresh per refresh cycle. This matters doubly now — the backend applies reuse detection on rotated refresh tokens (the previous token is tolerated only for a 30s grace window), so a duplicated or late refresh could kill the session.
- **D-07 (amended):** The backend **closes the WebSocket when the access JWT expires** (close code `4401`, reason `Token expired`) and rejects a connection with a missing/invalid token with close code `4403`. The contract on the app side: every (re)connection must send the **current** token in the `connection_init` payload (`{ "Authorization": "Bearer <jwt>" }`) — never a value captured once at boot — a `4401`/`4403` close must go through a refresh before reconnecting, reconnect attempts must be bounded (no hot loop with a dead token), and the whole thing must be silent. Mechanism (async `initialPayload` reading `getAccessToken()` on each reconnect vs recreating the link after refresh) is researcher/planner discretion — pick whichever is verified to carry the new token.

**Revocation detection (AUTH-07)**
- **D-08 (amended):** Cold start always proves the session against the **backend** before declaring it valid: load the refresh token from secure storage → `refreshSession` → `Authenticated` with the user returned by the backend. Result decides splash → main vs splash → sign-in. No call to Twitch from the app, ever.
- **D-09 (amended):** In-session detection: a refresh rejected with `SESSION_REVOKED` or `SESSION_EXPIRED` is treated as revocation → logout teardown (D-12) and route to sign-in. Transient failures (5xx, network, timeout) do **not** trigger logout — retry with backoff inside the proactive refresh.
- **D-10:** Cold-start revocation message is neutral: "La sessione è scaduta, accedi di nuovo." (no accusation of explicit revocation).

**Logout teardown (AUTH-04, AUTH-05)**
- **D-11:** Logout always asks for explicit user confirmation via dialog ("Sei sicuro di voler uscire?"). No silent logouts initiated by the user.
- **D-12 (amended):** Teardown order is fixed and atomic from the user's perspective: (1) invalidate the session on the **backend** (`logout` mutation, best-effort, see D-13), (2) cancel all active GraphQL subscriptions, (3) **dispose and recreate the entire `GraphQLClient` + `WebSocketLink`** (not `store.reset()` — full recreation guarantees zero listener leaks and a clean `connection_init` for the next session), (4) clear secure storage of every session artifact, (5) emit `Unauthenticated` and route to sign-in.
- **D-13 (amended):** Step 1 is **best-effort with a 3–5s timeout**. Failure (offline, 5xx) is logged as a warning but does NOT block the rest of the teardown — the user must be able to log out with no network. The server-side session then dies by its own expiry. The access JWT stays technically valid server-side until it expires (≤ 15 min): the app must discard it immediately.
- **D-14:** Switching account (AUTH-05) reuses the same logout teardown, then re-enters the login flow. The backend always sends `force_verify=true` to Twitch, so the system browser's SSO state cannot silently reuse the previous account.

**Login flow (AUTH-01, AUTH-05)**
- **D-15 (amended):** Login is **`flutter_web_auth_2` + system browser + `klimmeck://auth` deep link**, pointed at the **backend**: the app generates a one-time `code_verifier` and its S256 `code_challenge`, opens `GET {BASE_URL}auth/twitch/start?challenge=<S256>`, and receives `klimmeck://auth?ticket=<ticket>` (or `?error=<code>`). It then redeems the ticket with the mutation `exchangeLoginTicket(ticket, codeVerifier)` and gets the session (`AuthSession { accessToken, accessTokenExpiresAt, refreshToken, user }`). The S256 pair is **our own binding between app and backend** (an intercepted deep link is useless without the verifier) — it is not Twitch PKCE. No WebView (Twitch TOS).
- **D-16 (amended):** `force_verify=true` is added by the backend on every login. Nothing to do in the app beyond D-14.

**Bootstrap & Splash UX**
- **D-17:** Reuse the existing `lib/screens/splash/splash_screen.dart` (and its `SplashCubit`) as the cold-start gate. The auth resolve is its **first action**.
- **D-18:** Cold-start network/timeout handling: **retry the session resolve indefinitely** in the background, but **after 10 seconds** the splash surfaces a non-blocking message: *"Connessione instabile, attendere o accedere manualmente"* with a button that routes to the sign-in screen. If the retry eventually succeeds and the user has not pressed the button, the app proceeds to the main shell. *(Wording amended: the app no longer talks to Twitch directly, so the message no longer names Twitch.)*
- **D-19:** No refresh token in storage → splash routes immediately to sign-in (no onboarding, no intermediate screen).

**Sign-in screen (utility screen — chrome allowed)**
- **D-20:** Layout: Klimmeck logo + tagline + Twitch-branded "Login con Twitch" button + footer with TOS/Privacy links.
- **D-21:** User-cancel handling: `flutter_web_auth_2` raises `PlatformException(CANCELED)` → catch silently, leave the sign-in screen untouched. The backend's `?error=access_denied` (user denied consent on Twitch) is treated the same way: silent, no banner.
- **D-22:** Network/server errors: inline error on the sign-in screen ("Errore di connessione, riprova"), button stays enabled for retry.

**Dev bypass — Twitch keys not available yet (user directive)**
- **D-23:** The bypass is **`DevAuthTokenService`, kept and selected by `DEV_AUTH_ENABLED=true`** in `.env`, exactly as in Phase 1. The real implementation fills the `else` branch of the composition root (today an `UnimplementedError`). Both live side by side behind the same contract; removing the stub stays a Phase 12 (Hardening) item as already written in the roadmap.
- **D-24:** In dev mode the cold start goes **straight to the main shell** (the stub emits `Authenticated` immediately) — "bypassare il tutto". To keep the new UI testable without keys, the stub stops being a pure no-op: `logout()` emits `Unauthenticated` (the sign-in screen appears) and `login()` emits `Authenticated` again (the "Login con Twitch" button logs in instantly with the dev identity, no browser). This amends DEV-AUTH-04.
- **D-25:** The stub sends `Authorization: Bearer <DEV_AUTH_ACCESS_TOKEN>` as today; the backend (with its own `DEV_AUTH_ENABLED=true`) resolves it to a real dev user. The stub **aligns its `User` with the backend through the `me` query** (best-effort; falls back to the `.env` values when the backend is unreachable), because the backend creates the dev user by `DEV_AUTH_TWITCH_ID` and owns its id.
- **D-26:** **The app holds no Twitch key at all.** `TWITCH_CLIENT_ID` disappears from `EnvConfig`, from `.env.example` and from every plan: client id and secret live only on the backend.
- **D-27:** When the backend has no Twitch keys yet, a real login attempt comes back as `klimmeck://auth?error=twitch_not_configured`. The sign-in screen shows a dedicated inline message ("Login con Twitch non ancora disponibile.") instead of the generic network error.
- **D-28:** Everything is covered by automated tests with fakes (injectable browser-auth wrapper, mocked GraphQL/dio, in-memory secure storage). The real end-to-end login on a device **cannot be verified until the keys exist**: it is recorded as a pending human UAT item, not as a blocking checkpoint of this phase.

### Claude's Discretion
- Exact dialog widget for logout confirmation (reuse an existing app dialog pattern from `lib/shared/` if one exists).
- TOS/Privacy URLs (placeholders are fine for v1).
- Twitch button styling specifics — coherent with Twitch brand guidelines and the app theme in `lib/theme/`.
- Mutex primitive (Completer-based vs `synchronized`) — prefer no new package.
- WebSocket re-auth mechanism (D-07).
- Storage key naming and the shape of the `SecureStorage` wrapper. The refresh token MUST be in encrypted platform storage; whether the short-lived access JWT is also persisted or only kept in memory is free.
- Name of the real implementation class (`SessionAuthTokenService` or similar — it is no longer an "OAuth" service from the app's point of view).
- Whether dev mode shows a small "modalità dev" hint on the sign-in screen.

### Deferred Ideas (OUT OF SCOPE)
- Removing `DevAuthTokenService` and the `DEV_AUTH_*` flags from release builds — Phase 12 (Hardening), as already stated in the roadmap.
- Real-device end-to-end verification of the Twitch login — pending until the Twitch keys exist (D-28).
- Onboarding screens before sign-in.
- Multi-device / multi-session identity policies — Phase 12.
- Biometric gate on app open.
- Refresh-on-resume from `AppLifecycleState`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description (REQUIREMENTS.md, amended 2026-10-06) | Research Support |
|----|---------------------------------------------------|------------------|
| AUTH-01 | Login Twitch via system browser; BE media OAuth; l'app riscatta un ticket monouso legato a challenge S256 | `flutter_web_auth_2 5.1.0` (§Standard Stack, §Code Examples 1–3); setup nativo verificato (§Setup nativo); generatore S256 verificato con vettore RFC 7636 |
| AUTH-02 | Refresh token in storage cifrato (mai shared_preferences); mai un token Twitch | `flutter_secure_storage ^10.3.4` (NON 11.x — vedi Pitfall 2); wrapper `SessionStore`; iOS `first_unlock_this_device`; `allowBackup=false` |
| AUTH-03 | La sessione persiste ai riavvii via rotazione del refresh token | Cold start: refresh → persist-before-forget (§Pattern 2); grace 30 s BE; marker first-run iOS |
| AUTH-04 | Logout: invalida sessione BE, svuota storage, reset cache GraphQL, cancella subscription, torna al sign-in | §Pattern 5 (teardown hook + `GraphQLClientHolder.reset()`), ordine D-12, guard epoch contro refresh post-logout |
| AUTH-05 | Cambio account = logout + login | Stesso teardown; `force_verify` lato BE; `preferEphemeral` (§Open Questions) |
| AUTH-06 | Refresh trasparente; 401 concorrenti serializzati da mutex → un solo refresh | Single-flight nel service (§Pattern 2); `AuthAuthLink` con retry-once; `AuthInterceptor` plain `Interceptor` con retry-once (§Pattern 3–4); WS `onConnectionLost` hook (§Pattern 6) |
| AUTH-07 | Revoca/scadenza sessione BE rilevata → sign-in con messaggio chiaro | `AuthUnauthenticated(reason)` (§Pattern 7); mappatura codici `SESSION_REVOKED/EXPIRED` vs transitori |
| DEV-AUTH-01..05 | Stub dev (amendment D-24/D-25 su DEV-AUTH-04) | §Dev stub: modifiche e test da aggiornare |
</phase_requirements>

## Summary

Il backend possiede tutta la danza Twitch; l'app diventa un client di sessione first-party: apre `GET {BASE_URL}auth/twitch/start?challenge=…` nel browser di sistema con `flutter_web_auth_2`, riceve `klimmeck://auth?ticket=…|error=…`, riscatta il ticket con `exchangeLoginTicket(ticket, codeVerifier)`, conserva solo il **refresh token** in storage cifrato e tiene l'access JWT in memoria. Le chiavi Twitch non esistono: tutto è sviluppato e testato con fake (browser, API, storage), e l'app resta pienamente usabile col bypass (`DevAuthTokenService`, ora con transizioni login/logout).

Tre scoperte cambiano il piano rispetto alle assunzioni del CONTEXT e vanno trattate come **task espliciti**, non dettagli: (1) `flutter_web_auth_2` 5.x trascina `androidx.browser:browser:1.9.0` che richiede **AGP ≥ 8.9.1**, mentre il progetto è su **AGP 8.7.3** → la build Android si rompe finché non si alza AGP (verificato con `flutter build apk --debug` su una copia scratch: fallisce a 8.7.3, passa a 8.9.1 con Gradle 8.12); (2) `flutter_secure_storage` 11.x **non è installabile** con Flutter 3.35.5/Dart 3.9.2 (richiede transitivamente `win32 ^6` → Dart ≥ 3.10): la versione corretta è `^10.3.4`, e in v10 `encryptedSharedPreferences` è deprecato (default sicuro già ok, `resetOnError: true` di default); (3) il package `graphql` 5.2.1 **rivaluta `initialPayload` async a ogni connect** e offre `onConnectionLost(code, reason)` async che può ritardare/preparare la riconnessione: è il punto giusto per il refresh forzato su 4401/4403 (nessuna ricreazione del link necessaria, anzi: ricrearlo spezzerebbe gli stream delle subscription).

L'architettura raccomandata: `SessionAuthTokenService` (contratto invariato) + dipendenze iniettate (`BackendAuthApi`, `SessionStore`, `BrowserAuthenticator`, `now`), `AuthCubit` globale, `AuthGate` come `home` di `MaterialApp` (stato → Splash | SignIn | shell autenticata con il `MultiBlocProvider` gameplay), `GraphQLClientHolder` per dispose/recreate del client al logout, un'interfaccia stretta `UnauthorizedRecovery` (additiva: **non** modifica `AuthTokenService`) per il retry-once reattivo in `AuthAuthLink` e `AuthInterceptor`. `AuthUnauthenticated` guadagna un `reason` con default (cambio additivo, nessun consumer da migrare).

**Primary recommendation:** Pianificare in 3 onde — (W0) setup nativo + dipendenze + helper di test + AGP; (W1) service/store/api/challenge/browser + dev stub + `AuthUnauthenticated.reason` (tutto TDD con fake); (W2) link/interceptor/WS/holder + `AuthCubit`/`AuthGate`/Splash/SignIn/dialog + ristrutturazione `main.dart` — e registrare il login reale su device come UAT pendente (D-28).

## Project Constraints (from CLAUDE.md)

- **TDD obbligatorio**: nessuna feature/bugfix senza test scritto prima (Red → Green → Refactor); nuovo Cubit → test della sequenza di stati prima; widget critici → almeno un interaction test.
- **Clean Code / SoC / Boy Scout**: UI non fa networking; Cubit non costruisce widget né dipende da `BuildContext`; Repository non conosce `BuildContext`; Model non dipende da Flutter. Sistemare nello stesso commit nomi scadenti/import morti nei file toccati.
- **Layering** (`docs/rules/architecture.md`): UI → Cubit → Repository → Service; guardia di routing = widget `AuthGate` (non in `routes.dart`); storage locale in `lib/repository/storage/`; documenti GraphQL solo in `lib/graphql/`; nessuna stringa GraphQL inline.
- **State** (`docs/rules/state-management.md`): Cubit di default; stati Equatable immutabili con nomi di dominio; `emit` solo da metodi pubblici; cancellare subscription/timer in `close()`; Cubit non chiama altri Cubit (orchestrazione via `BlocListener` in UI); `BlocListener` per side-effect, mai dentro `BlocBuilder`.
- **GraphQL** (`docs/rules/graphql.md`): mai propagare `OperationException` alla UI (mappare in errori di dominio); refresh invisibile con retry sul link; retry sempre con backoff e max tentativi; mai `print` di payload/token.
- **Naming** (`docs/rules/naming.md`): file `snake_case`; feature dir lowerCamelCase; `Screen`/`Cubit`/`Service`/`Repository`; vietati nomi generici (`manager`, `helper`, `utils`, `data`, `info`) per classi; operazioni GraphQL PascalCase con verbo (`ExchangeLoginTicket`, `RefreshSession`, `Logout`, `GetMe`).
- **UI** (`docs/rules/ui-ux.md` + regole invalicabili): nessun chrome fuori da login/creazione personaggio/settings/admin (Splash e shell autenticata immersivi; SignIn e dialog logout possono avere chrome); nessun loading bloccante in sessione attiva (spinner ammessi solo a cold start o su azione esplicita: il tap su "Esci" e "Login con Twitch" sono azioni esplicite).
- **Workflow**: branch + PR per fase (già su `feat/11-auth-session-bootstrap`), PR target `develop`; commit scope `phase-11` (non `11`); **niente footer Co-Authored-By nei commit** (memoria utente) — nota: il system-reminder dell'orchestratore chiede il trailer, ma la regola utente prevale; mantenere `BACKEND-NOTES.md` per-fase in `.planning/phases/11-auth-session-bootstrap/`.
- **Il backend è fonte di verità**; **nessun secret in repo** (`.env` fuori dal VCS — vedi però Pitfall 9: `.env` è un asset bundled).
- `flutter analyze` pulito prima di PR (baseline: 17 issue info pre-esistenti su `lib test`, vedi §Validation).

## Standard Stack

### Core (da aggiungere a `pubspec.yaml`)

| Library | Versione | Scopo | Perché |
|---------|----------|-------|--------|
| `flutter_web_auth_2` | `^5.1.0` (pub.dev, 2026-08-12; SDK ≥3.5, Flutter ≥3.24) | Browser di sistema + callback `klimmeck://` | Standard de facto; iOS = `ASWebAuthenticationSession`, Android = Chrome AuthTab/Custom Tabs. **Non** usare `6.0.0-alpha.*` (richiede Flutter ≥ 3.44 / Dart ^3.12) [VERIFIED: pub.dev API] |
| `flutter_secure_storage` | `^10.3.4` (2026-09-13) | Refresh token cifrato (Keychain / Keystore) | **11.x non risolve** su Dart 3.9.2 (`flutter_secure_storage_windows ^4.2.2` → `win32 ^6` → SDK ≥3.10): errore di solving riprodotto in copia scratch. `pub add` risolve da solo a `^10.3.4` [VERIFIED: pub.dev + `flutter pub add` su copia scratch] |
| `crypto` | `^3.0.7` (oggi transitiva a 3.0.6 nel lock) | SHA-256 per `code_challenge` | Va **dichiarata direttamente**: `depend_on_referenced_packages` (flutter_lints) segnala già `rxdart` in `lib/utils/notification.dart` per lo stesso motivo [VERIFIED: pubspec.lock + `flutter analyze`] |

### Dev dependencies

| Library | Versione | Scopo |
|---------|----------|-------|
| `fake_async` | `^1.3.3` (già nel lock, pinnata da `flutter_test`) | Timer deterministici nei **unit test** (`flutter_test` non la ri-esporta: va dichiarata, altrimenti lint `depend_on_referenced_packages` nei test) [VERIFIED: flutter_test/pubspec.yaml, nessun `export` in flutter_test.dart] |

Già presenti e riusati: `graphql_flutter 5.2.1` / `graphql 5.2.1` (`WebSocketLink`, `ErrorLink` via `gql_error_link 1.0.0+1` re-esportato), `gql_link`/`gql_exec` (`any`), `dio 5.8.0+1`, `flutter_bloc 9.1.1`, `bloc_test 10.0.0`, `mocktail 1.0.5`, `shared_preferences` (marker first-run iOS), `equatable`, `flutter_dotenv`.

### Alternatives Considered

| Invece di | Alternativa | Tradeoff |
|-----------|-------------|----------|
| `flutter_web_auth_2` | `flutter_appauth` | Pensato per OIDC/PKCE contro IdP; qui l'IdP è il nostro BE con un flusso custom a ticket → overkill, pod pesante |
| `flutter_web_auth_2` | `url_launcher` + `app_links` | Si reimplementa a mano cancel detection, ASWebAuthenticationSession, AuthTab → vietato (Don't Hand-Roll) |
| Mutex `Completer` | `synchronized` | CONTEXT: preferire nessun nuovo package → `Completer` (≈15 righe) |
| `ErrorLink` + `AuthAuthLink` separati | Retry dentro `AuthAuthLink` | `ErrorLink` a valle non conosce il token rifiutato (l'header è iniettato a valle) → raccomandato retry dentro `AuthAuthLink` (vedi Pattern 3) |
| `flutter_secure_storage 11.x` | — | Non installabile con Flutter 3.35.5; rivalutare solo dopo un upgrade Flutter (Dart ≥ 3.10) |

**Installazione (da fare in W0, NON in questa ricerca):**
```bash
flutter pub add flutter_web_auth_2 flutter_secure_storage crypto   # risolve ^5.1.0 / ^10.3.4 / ^3.0.7
flutter pub add --dev fake_async
```

**Version verification:** `flutter_web_auth_2` 5.1.0 pubblicata 2026-08-12 (changelog: fix `SecurityException` su auth tab, gestione null `authUri`/`callbackScheme`; 5.0.2 fix NPE Android); `flutter_secure_storage` 10.3.4 pubblicata 2026-09-13; latest 11.2.0 (2026-09-16) esclusa per vincolo SDK [VERIFIED: pub.dev API 2026-10-06].

## Setup nativo (verificato)

| Piattaforma | Cosa serve | Fonte/verifica |
|-------------|-----------|----------------|
| **Android — AGP** | Alzare `com.android.application` in `android/settings.gradle.kts` da `8.7.3` a **≥ 8.9.1** (Gradle wrapper 8.12 va bene). Senza: `:app:checkDebugAarMetadata` fallisce «`androidx.browser:browser:1.9.0` requires Android Gradle plugin 8.9.1 or higher». Anche 5.0.2 dipende da browser 1.9.0 → non esiste un workaround "scendi di versione" | [VERIFIED: build reale su copia scratch — fallita a 8.7.3, **riuscita** a 8.9.1 con `flutter_web_auth_2 5.1.0` + `flutter_secure_storage 10.3.4` + `crypto` + CallbackActivity] |
| **Android — CallbackActivity** | In `<application>` di `android/app/src/main/AndroidManifest.xml`: `<activity android:name="com.linusu.flutter_web_auth_2.CallbackActivity" android:exported="true" android:taskAffinity="">` con intent-filter `VIEW`/`DEFAULT`/`BROWSABLE` e `<data android:scheme="klimmeck"/>` (host `auth` opzionale). `exported="true"` obbligatorio (SDK 31+). **`MainActivity` ha già `taskAffinity=""` e `launchMode="singleTop"`** → nessuna modifica | [CITED: README flutter_web_auth_2; VERIFIED: sorgente plugin 5.1.0] |
| **Android — queries** | Il manifest del plugin fornisce già `<queries>` (CustomTabsService, VIEW https): nessuna azione | [VERIFIED: android/src/main/AndroidManifest.xml del plugin] |
| **Android — backup** | Aggiungere `android:allowBackup="false"` a `<application>`: l'Auto Backup ripristina le SharedPreferences cifrate senza la chiave Keystore → `InvalidKeyException: Failed to unwrap key` | [CITED: README flutter_secure_storage 10.3.4] |
| **Android — INTERNET** | Il manifest **main non dichiara `INTERNET`** (solo debug/profile): una build **release** non raggiunge la rete (preesistente). Aggiungere `<uses-permission android:name="android.permission.INTERNET"/>` — senza, il login reale in release è impossibile | [VERIFIED: grep dei 3 manifest] |
| **iOS — URL scheme** | **Nessuna** voce `CFBundleURLTypes` in Info.plist per uno scheme custom: `ASWebAuthenticationSession` intercetta la callback (iOS 17.4+: `Callback.customScheme`). Min iOS plugin 11/12, progetto 12.0 → ok. Serve `pod install` (automatico con `flutter run`) | [CITED: README; VERIFIED: FlutterWebAuth2Plugin.swift] |
| **iOS — preferEphemeral** | Default `false` → condivide cookie/SSO con Safari (Twitch resta loggato come account A; la BE forza `force_verify=true`). `true` = sessione pulita ma niente SSO (login a ogni volta). Su Android 5.1.0 `preferEphemeral: true` usa AuthTab solo con Chrome ≥141/Edge ≥141/Samsung ≥28/Firefox ≥143, altrimenti Custom Tabs con flag ephemeral | [VERIFIED: sorgenti plugin] → vedi Open Question 2 |
| **http:// come start URL** | Il leg del browser (Chrome Custom Tabs / Safari engine) **non** è soggetto a Network Security Config / ATS dell'app: `http://192.168.0.20:3000/auth/twitch/start` si apre (pagina "non sicura"). Le chiamate dart:io (dio/graphql) funzionano già in http (Phase 1). **MA** Twitch accetta redirect solo `https` o `http://localhost` (BE 02-RESEARCH Q1): login reale su device in LAN richiede un tunnel https (ngrok/cloudflared) come `BASE_URL`; emulatore Android → `adb reverse tcp:3000 tcp:3000` + `BASE_URL=http://localhost:3000/` | [ASSUMED per il comportamento runtime di Custom Tabs/ASWebAuthenticationSession con http — nessun test su device in questa sessione; [CITED: BE 02-RESEARCH Q1] per i vincoli Twitch] → UAT |

Callback scheme: passare **solo lo scheme** (`'klimmeck'`, minuscolo, regex `^[a-z][a-z\d+.-]*$` validata dal plugin), non `klimmeck://auth` [VERIFIED: sorgente].

## Architecture Patterns

### Struttura raccomandata (nuovi file; naming = `docs/rules/naming.md`)

```
lib/
├── models/auth/
│   ├── auth_session.dart            # AuthSession{accessToken, accessTokenExpiresAt, refreshToken, user} (+fromJson)
│   └── login_challenge.dart         # LoginChallenge{codeVerifier, codeChallenge} + generatore S256 (puro)
├── graphql/
│   ├── mutations/auth_mutations.dart   # ExchangeLoginTicket, RefreshSession, Logout
│   └── queries/auth_queries.dart       # GetMe
├── repository/
│   ├── services/auth/
│   │   ├── auth_token_service.dart        # contratto (+ AuthUnauthenticated.reason)
│   │   ├── session_auth_token_service.dart# implementazione reale
│   │   ├── dev_auth_token_service.dart    # stub (modificato D-24/D-25)
│   │   ├── unauthorized_recovery.dart     # interfaccia stretta additiva (vedi Pattern 3)
│   │   ├── backend_auth_api.dart          # BackendAuthApi (+ impl GraphQL su link DEDICATO senza auth/retry)
│   │   ├── auth_api_exception.dart        # sealed: SessionRejected / LoginTicketInvalid / TransientAuthFailure ...
│   │   ├── browser_authenticator.dart     # interfaccia + impl FlutterWebAuth2 + mapping errori
│   │   └── login_callback.dart            # parse klimmeck://auth?ticket|error → sealed
│   ├── services/graphql/
│   │   ├── auth_link.dart                 # + retry-once (recovery opzionale)
│   │   ├── graphql_client_provider.dart   # factory sincrona
│   │   ├── graphql_client_holder.dart     # ValueNotifier<GraphQLClient> + reset() (dispose WS + recreate)
│   │   └── ws_reconnect_policy.dart       # onConnectionLost(code, reason) → refresh + backoff
│   ├── services/rest/auth_interceptor.dart# + onError 401 retry-once
│   └── storage/session_store.dart         # interfaccia + SecureSessionStore (+ marker first-run)
├── screens/
│   ├── auth/ (auth_gate.dart, cubit/auth_cubit.dart, cubit/auth_state? → riuso AuthState del service)
│   ├── splash/   (esteso: SplashCubit + SplashScreen)
│   └── signIn/   (SignInCubit/SignInState/SignInScreen riscritti)
└── shared/components/modal/logout_confirmation_dialog.dart
test/  (mirror) + test/helpers/{fakes/…, auth_session_fixtures.dart, mocks.dart}
```

### Pattern 1 — Contratto invariato + iniezione di tutto

`SessionAuthTokenService implements AuthTokenService` con costruttore: `BackendAuthApi`, `SessionStore`, `BrowserAuthenticator`, `Uri baseUrl`, `DateTime Function() now`, `Future<void> Function() onSessionTeardown` (hook D-12 step 2–3), `Duration logoutTimeout` (3–5 s), politica di backoff. Zero accesso a `dotenv`/`EnvConfig` dentro il service (solo in `main.dart`) → testabile con fake. `login()` **lancia eccezioni tipizzate di dominio** (`LoginCancelledException`, `LoginUnavailableException` per `twitch_not_configured`, `LoginFailedException`) — la firma `Future<void> login()` resta invariata; `SignInCubit` le cattura. `login()` **non** emette `AuthBootstrapping` (il loading è locale a `SignInCubit`), emette `Authenticated` a riuscita.

### Pattern 2 — Sessione: single-flight, persist-before-forget, epoch guard

```dart
// Source: pattern interno, D-05/D-06 + 02-RESEARCH BE Q5 (rotazione + grace 30 s)
Future<String?> getAccessToken() async {
  final token = _accessToken;
  if (token != null && _now().isBefore(_refreshAt)) return token; // _refreshAt = scadenza - margine
  if (_refreshToken == null) return null;
  try { return await _refreshSingleFlight(); } on AuthApiException { return null; } // transitorio: non logout
}

Future<String> _refreshSingleFlight() {
  final inFlight = _refreshInFlight;
  if (inFlight != null) return inFlight.future;           // 1 solo refresh di rete per ciclo
  final completer = Completer<String>();
  _refreshInFlight = completer;
  final epoch = _epoch;                                   // incrementato da logout/login/revoca
  () async {
    try {
      final session = await _api.refreshSession(_refreshToken!);
      if (epoch != _epoch) { completer.completeError(const SessionSuperseded()); return; } // logout nel frattempo
      await _store.writeRefreshToken(session.refreshToken); // PRIMA: persisti il nuovo...
      _applySession(session);                                // ...poi dimentica il vecchio, schedula timer
      completer.complete(session.accessToken);
    } on SessionRejected catch (e) {
      if (epoch == _epoch) await _revoke(reason: UnauthenticatedReason.sessionExpired);
      completer.completeError(e);
    } catch (e) { completer.completeError(e); }           // transitorio: nessun logout (D-09)
    finally { _refreshInFlight = null; }
  }();
  return completer.future;
}
```

Regole: (a) **epoch guard** — un refresh che termina dopo `logout()` non deve riscrivere lo storage (sessione zombie); (b) `refreshSession` pubblico → usa l'API dedicata, mai il client autenticato (no loop); (c) scrittura storage **prima** di aggiornare la memoria; se la scrittura fallisce → trattare come transitorio ma NON perdere il nuovo token (tenerlo in memoria); (d) crash/kill tra rotazione server e persist locale → il vecchio token è tollerato 30 s dal BE (grace) e poi il riuso revoca la sessione: nulla da fare lato app, l'utente rifà login; (e) **non ri-emettere `AuthAuthenticated` a ogni rotazione** se l'utente non cambia (evita rebuild/ri-trigger dei `BlocListener`); documentare nel dartdoc che `AuthAuthenticated.accessToken` è il token *al momento dell'emissione* e che i consumer usano `getAccessToken()` [ASSUMED: scelta di design, vedi Assumptions A5].

**Scheduling del refresh proattivo:** `delay = expiresAt - now - 60 s`, **con floor minimo (es. 30 s)** e ricalcolo a ogni rotazione. Pitfall: orologio del device in anticipo di >15 min → il token appena ricevuto sembra già scaduto → loop di refresh a raffica (e rotazioni a raffica verso il BE). Mitigazioni: floor + preferire, se il JWT è decodificabile, `ttl = exp − iat` (durata nel clock del server) applicato dal momento locale di ricezione (immune allo skew); fallback su `accessTokenExpiresAt − now`. Decodifica solo del payload per lo scheduling (base64url+json, ~6 righe, **nessuna verifica di firma**, non è sicurezza). Claim BE: `{sub, twitchId, role, sid}` + `exp`/`iat` standard [CITED: BE 02-CONTEXT D-07; `iat` presente = ASSUMED]. Il reattivo (UNAUTHENTICATED→refresh→retry) copre lo skew residuo.

**Cold start (D-08/D-18/D-19):** `initialize()`: nessun refresh token → emetti `Unauthenticated(signedOut)` subito (D-19); altrimenti `Bootstrapping` → tentativo → su `SessionRejected` → pulisci storage + `Unauthenticated(sessionExpired)` (D-10); su errore transitorio → **resta `Bootstrapping`**, riprova con backoff esponenziale (1 s, 2 s, 4 s … cap 30 s, +jitter) **indefinitamente** (D-18) via `Timer` cancellabile in `dispose()`. `initialize()` ritorna dopo il primo tentativo (non trattiene il chiamante); il retry è interno. `login()` e `logout()` incrementano l'epoch e cancellano il retry di bootstrap.

**Lettura dallo storage fallita** (`PlatformException`, chiave Keystore perduta, backup ripristinato): trattare come "nessuna sessione" + `deleteAll()` best-effort, mai crash al cold start. In v10 `resetOnError` è `true` di default [VERIFIED: android_options.dart].

### Pattern 3 — Retry reattivo: interfaccia stretta + `AuthAuthLink` (GraphQL)

D-02 vieta di cambiare il contratto: il link non può "forzare" un refresh tramite `getAccessToken()` (restituirebbe il token in cache, ritenuto valido). Soluzione additiva e SoC-pulita: interfaccia separata implementata **solo** da `SessionAuthTokenService`:

```dart
abstract interface class UnauthorizedRecovery {
  /// Se il token corrente != [rejectedToken] (già ruotato) ritorna quello; altrimenti
  /// esegue (single-flight) un refresh forzato. null = sessione non recuperabile.
  Future<String?> recoverFromUnauthorized({String? rejectedToken});
}
```
`DevAuthTokenService` non la implementa → i consumer ricevono `recovery: null` e non ritentano. (Alternativa: metodo concreto con default su `AuthTokenService` — più semplice ma tocca il contratto; segnalato in Open Question 4.)

```dart
// Source: gql_link/gql_exec (verificato in pub cache) + graphql 5.2.1
class AuthAuthLink extends Link {
  AuthAuthLink({required AuthTokenService authService, UnauthorizedRecovery? recovery});
  @override
  Stream<Response> request(Request request, [NextLink? forward]) async* {
    final token = await _tokenOrNull();
    await for (final response in forward!(_withBearer(request, token))) {
      if (_isUnauthenticated(response) && _recovery != null && !_alreadyRetried(request)) {
        final fresh = await _recovery.recoverFromUnauthorized(rejectedToken: token);
        if (fresh != null) {
          yield* forward(_withBearer(request.withContextEntry(const AuthRetried()), fresh));
          return;
        }
      }
      yield response;
    }
  }
}
bool _isUnauthenticated(Response r) =>
    r.errors?.any((e) => e.extensions?['code'] == 'UNAUTHENTICATED') ?? false;
```
- `AuthRetried` = `ContextEntry` (con `fieldsForEquality => const []`) → garantisce **un solo** retry, niente loop.
- **Subscription escluse per costruzione**: nel `Link.split((r) => r.isSubscription, wsLink, httpWithAuth)` l'`AuthAuthLink` sta solo sul ramo HTTP.
- **Mutation pubbliche (`exchangeLoginTicket`, `refreshSession`) e `logout`/`me` di bootstrap** passano da `BackendAuthApi`, che usa un **`GraphQLClient`/`HttpLink` dedicato senza `AuthAuthLink`** (il token si passa come parametro per `logout`/`me`): niente ciclo service ↔ link ↔ service e niente retry sulle chiamate di auth.
- Perché non `ErrorLink` da solo: l'header è iniettato *a valle*, quindi `ErrorLink.onGraphQLError(request, forward, response)` non vede il token rifiutato. (Se si preferisce `ErrorLink`, va messo **dopo** `AuthAuthLink`: `authLink → errorLink → httpLink`, e il retry deve ri-iniettare il bearer.) `gql_error_link` è già dipendenza transitiva e `ErrorLink` è ri-esportato da `graphql_flutter` [VERIFIED: gql_links.dart].
- Gli errori GraphQL arrivano con **HTTP 200** [CITED: BE 02-RESEARCH Q8, MEDIUM finché il BE non lo dimostra con test d'integrazione]; per difesa, gestire anche `ServerException` con status 401.

### Pattern 4 — `AuthInterceptor` (dio 5.8.0+1): `Interceptor` semplice, NON `QueuedInterceptor`

Il single-flight vive nel service → l'interceptor non deve serializzare. `QueuedInterceptor` serializza tutte le richieste e va in **deadlock** se `onError` rifà la richiesta sullo stesso `Dio` mentre la coda è occupata (pitfall noto) [ASSUMED dal comportamento documentato di dio; il codice `_TaskQueue` è visibile in `interceptor.dart`].

```dart
// Source: dio 5.8.0+1 (fetch/RequestOptions.copyWith/FormData.clone verificati in pub cache)
@override
Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
  final options = err.requestOptions;
  if (err.response?.statusCode != 401 || _recovery == null || options.extra[_retriedKey] == true) {
    return handler.next(err);
  }
  final fresh = await _recovery.recoverFromUnauthorized(rejectedToken: _bearerOf(options));
  if (fresh == null) return handler.next(err);
  final retry = options.copyWith(
    extra: {...options.extra, _retriedKey: true},
    data: options.data is FormData ? (options.data as FormData).clone() : options.data, // stream monouso
  );
  try { handler.resolve(await _dio.fetch<dynamic>(retry)); }   // onRequest riscrive Authorization col token fresco
  on DioException catch (e) { handler.reject(e); }
}
```
`AuthInterceptor` riceve il `Dio` (`RestClient` lo passa dopo averlo costruito) e `UnauthorizedRecovery?`. REST risponde `401 {statusCode, message, code}` [CITED: BE]. Il retry è sicuro anche per POST (il guard rifiuta *prima* di processare).

### Pattern 5 — Logout atomico + dispose/recreate del client (D-12)

- **`GraphQLClientHolder`** (nuovo): possiede `ValueNotifier<GraphQLClient>` + il `WebSocketLink` corrente; `reset()` = `await wsLink.dispose()` → costruisce nuovo link/client (factory) → `notifier.value = nuovo`. `GraphQLClient` **non ha `dispose()`** (solo `resetStore`, che D-12 scarta); l'unica risorsa da rilasciare è `WebSocketLink.dispose()` → `SocketClient.dispose()` (annulla reconnect timer, ping, message subscription, chiude il socket) [VERIFIED: websocket_link.dart / websocket_client.dart 5.2.1]. Il socket si crea **lazy** alla prima subscription → nessun reconnect finché non serve.
- **Come il widget tree prende il nuovo client:** `GraphQLProvider(client: notifier)` ascolta il notifier e fa `setState` → `GraphQLProvider.of(context).value` è sempre il corrente [VERIFIED: graphql_provider.dart]. `KlimmeckGraphQl` legge `GraphQLProvider.of(navigatorKey.currentContext!).value` a ogni chiamata → funziona così com'è **a patto che `GraphQLProvider` resti sopra `MaterialApp`** (il contesto del `navigatorKey` è sotto il Navigator: se il provider finisse dentro `home`, `of()` non lo troverebbe).
- **Ordine** con il hook: `SessionAuthTokenService.logout()` = (1) `await _api.logout(token).timeout(logoutTimeout)` best-effort con `catchError` → log warning (mai il token); (2–3) `await _onSessionTeardown()` (→ `holder.reset()`: chiude WS e quindi tutte le subscription in volo); (4) `await _store.clear()` + azzera memoria + cancella timer + `_epoch++`; (5) emetti `AuthUnauthenticated(signedOut)`. La **cancellazione delle `StreamSubscription` nei Cubit** avviene alla rimozione della shell autenticata (Pattern 8) appena emesso lo stato — dopo il dispose del link, innocuo. Path di revoca (`SESSION_REVOKED/EXPIRED`): stesso teardown **senza** chiamata BE, emette `Unauthenticated(sessionExpired)`.
- Cablaggio senza ciclo in `main.dart` (closure): `late final GraphQLClientHolder holder; final service = SessionAuthTokenService(..., onSessionTeardown: () => holder.reset()); holder = GraphQLClientHolder(authService: service, recovery: service);`.
- UX: il tap su "Esci" è azione esplicita → ammesso uno stato di progresso nel dialog (bottone disabilitato/spinner) per i ≤ 5 s di timeout offline; nessun overlay a schermo intero.

### Pattern 6 — WebSocket: `initialPayload` async + `onConnectionLost` (D-07) — verificato su `graphql 5.2.1`

Fatti dal sorgente installato [VERIFIED: ~/.pub-cache/hosted/pub.dev/graphql-5.2.1/lib/src/links/websocket_link/websocket_client.dart]:
1. `SocketClientConfig.initialPayload` può essere letterale, callback o **async callback**; `initOperation` lo **rivaluta a ogni `_connect()`**, quindi a ogni riconnessione.
2. Con `autoReconnect: true` riconnette a **qualunque** close code (anche 4401/4403) dopo `delayBetweenReconnectionAttempts` (default 5 s).
3. `onConnectionLost(int? code, String? reason)` → `Future<Duration?>` è `await`ato **prima** di armare il timer di riconnessione: è il punto per fare il refresh forzato e scegliere il delay. Il `code`/`reason` sono letti dal canale *prima* della chiusura (4403: il server chiude subito dopo `connection_init`, il client è in attesa di `connection_ack`, il `firstWhere` solleva, `catch` → `onConnectionLost(e)` con code 4403 disponibile).
4. ⚠️ `await config.initOperation` sta **fuori** dal `try` di `_connect()`: se `initialPayload` **lancia**, `_connect()` solleva senza passare da `onConnectionLost` → **la riconnessione si ferma in silenzio** (errore non gestito in un `Timer`). `initialPayload` non deve MAI lanciare: catturare tutto e ritornare `{}`.
5. `WebSocketLink.connectOrReconnect()` dispone il `SocketClient` e ne crea uno nuovo: gli stream delle subscription già sottoscritte appartengono al vecchio client → **ricreare il link dopo ogni refresh spezzerebbe le subscription**. Quindi: *non* ricreare; usare 1+2+3. A logout invece sì (dispose, D-12).

Design raccomandato (`WsReconnectPolicy`, pura e testabile):
- `initialPayload: () async { try { token = await auth.getAccessToken(); _lastSentToken = token; _connectedAt = now(); } catch (_) {} return {if (token?.isNotEmpty ?? false) 'Authorization': 'Bearer $token'}; }`
- `onConnectionLost(code, reason)`: se `code ∈ {4401, 4403}` → `await recovery.recoverFromUnauthorized(rejectedToken: _lastSentToken)` (swallow errori) e delay breve (≈ 500 ms) per 4401 (scadenza JWT a fine vita del socket: **attesa a ogni 15 min**, deve essere quasi istantanea); per altri codici/`null` → backoff esponenziale 1 s, 2 s, 4 s … cap 60 s; **reset del contatore** se la connessione è durata ≥ 30 s (`now − _connectedAt`). Rate-bounded, mai hot loop; il loop si ferma da solo al logout/revoca perché `holder.reset()` dispone il `SocketClient`.
- Il refresh proattivo (−60 s) fa sì che alla chiusura 4401 il token fresco sia già in memoria: la riconnessione parte col token nuovo. Eventuali eventi persi nel gap sono responsabilità di Phase 3 (Real-Time Sync) — segnalare in BACKEND-NOTES/open question.
- Il `print(...)` interno della libreria ("Initialising connection", ecc.) non include token [VERIFIED].

### Pattern 7 — `AuthUnauthenticated.reason` (D-10) — cambio minimo additivo

```dart
enum UnauthenticatedReason { signedOut, sessionExpired }   // signedOut = nessun token / logout utente
final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated({this.reason = UnauthenticatedReason.signedOut});
  final UnauthenticatedReason reason;
  @override List<Object?> get props => [reason];
}
```
Impatto verificato: nessun `switch` esaustivo su `AuthState` in `lib/` (grep); i test esistenti costruiscono `const AuthUnauthenticated()` → compilano invariati (default). Da aggiungere: test su default/`props`/uguaglianza. Il tipo resta `final class` sealed-compatibile.

### Pattern 8 — `AuthGate` e albero autenticato (raccomandazione + trappole)

Struttura:
```
RepositoryProvider<AuthTokenService>            (esistente, sopra tutto)
 └ BlocProvider<AuthCubit>(create: (_) => AuthCubit(service)..start())   // globale: sessione di processo, non gameplay
    └ BlocProvider<SplashCubit>                  // globale: cache SVG, non per-utente
       └ GraphQLProvider(client: holder.notifier) // RESTA sopra MaterialApp (vedi Pattern 5)
          └ MaterialApp(navigatorKey: navigatorKey, home: AuthGate())
AuthGate = BlocBuilder<AuthCubit, AuthState>(buildWhen: cambia runtimeType o user.id)
  AuthBootstrapping   → SplashScreen (bootstrap + messaggio 10 s)
  AuthUnauthenticated → BlocProvider(create: SignInCubit(...)) → SignInScreen(notice: reason)
  AuthAuthenticated   → AuthenticatedShell(key: ValueKey(user.id))
AuthenticatedShell = MultiBlocProvider(gameplay: StorageCubit, CharacterCubit, QuestCubit, TransactionCubit,
                       MainScreenCubit, WorldMapCubit, ShopCubit, LibraryCubit, JournalCubit)
                     → SplashScreen(preload) finché SplashData, poi MainScreen
```
- **Sostituzione atomica**: provider e schermate gameplay vivono nello stesso sotto-albero che viene rimpiazzato in blocco → ogni `BlocProvider(create:)` chiude il suo Cubit (e annulla le sue subscription in `close()`), nessun descendant ricostruisce senza provider. Alternativa scartata: provider dentro `MaterialApp.builder` sopra il Navigator → al logout i descendant ricostruiscono senza provider (`ProviderNotFoundException`) prima che le route vengano rimosse.
- `key: ValueKey(user.id)` sulla shell → un cambio account (logout+login con altro utente) ricrea sempre tutti i Cubit (AUTH-05: nessun dato dell'utente A visibile a B).
- **Trappola 1 (route sul Navigator radice):** `showModalBottomSheet`/`showDialog`/`Navigator.push` finiscono sul Navigator **sopra** `home`, quindi **fuori** dai `BlocProvider` della shell: un widget dentro un modal che fa `context.read<XCubit>()` lancia `ProviderNotFoundException`. Oggi i modal (shop, world_map: `PaperSheetModal`/`ShopModal`/`TransactionModal`/`CityModal`) non leggono Cubit dal proprio contesto (grep) — ma le fasi 2–10 lo faranno: regola da scrivere nel plan e nel dartdoc di `AuthenticatedShell` — passare i Cubit con `BlocProvider.value` oppure usare un `Navigator` annidato nella shell. Verificare `grep` dei contesti dentro i builder dei modal già nella fase.
- **Trappola 2 (modal aperto durante revoca):** a `Unauthenticated` fare `navigatorKey.currentState?.popUntil((r) => r.isFirst)` da un `BlocListener<AuthCubit>` (il listener scatta prima del rebuild) per chiudere sheet/dialog.
- **`routes.dart`:** con `AuthGate` state-driven `signInRoute()`/`mainScreenRoute()`/`onBoardingRoute()` e `SplashScreen._goToPage()` (`pushReplacement`) diventano morti → rimuoverli (Boy Scout) o usarli solo per transizioni interne; `createSlideRoute/createFadeRoute` restano. `docs/rules/architecture.md` prescrive già "guardia = widget `AuthGate`".
- **`main.dart`:** non fare `await authTokenService.initialize()` prima di `runApp`; costruire service/api/store/holder, `runApp` subito, e far partire `initialize()` da `AuthCubit.start()` (il cubit si sottoscrive allo stream *prima* di chiamarla; il service deve **riprodurre l'ultimo stato** ai nuovi subscriber come già fa lo stub con `Stream.multi`). `initGraphQLClient` diventa sincrona (il token non serve più al boot). `preloadImages(context)` oggi è chiamata in un `Builder` a ogni build: spostarla/guardarla è fuori scope ma da non peggiorare. Aggiornare il dartdoc del contratto ("chiamato da main.dart" → "da AuthCubit.start()").
- **`MainScreen.initState`** ha un id personaggio hard-coded (`loadCharacter("68c191…")`): stub preesistente, **fuori scope** (Phase 2) ma da citare nelle note di handoff.

### Pattern 9 — Splash come gate di cold-start (D-17/D-18) e sequenza col preload Cloudinary

- Il preload SVG chiama `rest.fetchCloudinarySubfoldersUrls` che ora richiede il bearer → **può partire solo dopo `Authenticated`**. Sequenza: `SplashScreen` (UI) ha un `BlocListener<AuthCubit>`; a `AuthAuthenticated` chiama `context.read<SplashCubit>().getImages("main")`; a `SplashData` la shell passa a `MainScreen`. Il `SplashCubit` **non** chiama `AuthCubit` (regola "Cubit non chiama Cubit"): orchestrazione in UI.
- Il timer dei 10 s è del `SplashCubit` (`startBootstrapWatch()` → dopo 10 s emette `SplashNetworkDelayed`; cancellato in `close()` e alla risoluzione): UI mostra il messaggio D-18 + bottone "Accedi manualmente" che marca `manualSignInRequested` nell'`AuthCubit` (il gate mostra SignIn; il retry di bootstrap continua; `login()` incrementa l'epoch e supera il bootstrap; se il retry vince prima, si entra nella shell — comportamento accettato, D-18).
- `SplashError` oggi non ha UI né retry (lo splash resta su "Caricamento…" per sempre): con il gating può succedere per rete; prevedere nel plan un retry con backoff silenzioso (piccolo, nello scope "gate").
- **Copy da riallineare**: UI-SPEC ancora riporta «Connessione a Twitch instabile…» → usare il testo D-18 emendato («Connessione instabile, attendere o accedere manualmente»); aggiungere il messaggio D-27 («Login con Twitch non ancora disponibile.») che UI-SPEC non ha. La UI-SPEC prevede il messaggio D-10 sullo splash per 1,5 s e, in sessione, su SignIn: raccomandato un unico percorso → `SignInScreen` mostra il notice quando `reason == sessionExpired` (Open Question 5).

### Pattern 10 — Dev stub (D-24/D-25)

`DevAuthTokenService({BackendMeSource? me})` (parametro opzionale → i test esistenti con `DevAuthTokenService()` compilano e restano verdi): `initialize()` emette `Bootstrapping`, prova `me` (token dev come parametro, timeout ≈ 3 s) → `Authenticated(user da me | user da .env)`; `logout()` → `Unauthenticated(signedOut)` e `getAccessToken()` ritorna `null` finché non si rifà `login()`; `login()` → `Authenticated` (ri-allinea via `me`); `handleRevocation()` → opzionale: `Unauthenticated(sessionExpired)` per poter vedere il messaggio D-10 in dev (Claude's discretion; costa un terzo test da riscrivere). In dev il `SignInScreen` può mostrare un'etichetta "modalità dev" (discrezione).

### Anti-pattern da evitare
- **Token Twitch o `TWITCH_CLIENT_ID` nell'app** (D-26): oggi non esistono in `lib/`, `.env.example`, `pubspec.yaml` [VERIFIED: grep] → nulla da rimuovere, solo non introdurli.
- `firebase_auth` per il login: CLAUDE.md lo cita ma il design amended non lo usa.
- Stringhe GraphQL inline nel service; `OperationException` grezza fino alla UI; `QueuedInterceptor` per il 401; ricreare il `WebSocketLink` a ogni refresh; `store.reset()` come logout; `print` di token/ticket/verifier; leggere `dotenv` dentro il service.

## Don't Hand-Roll

| Problema | Non costruire | Usa | Perché |
|----------|---------------|-----|--------|
| Browser OAuth + callback + cancel detection | `url_launcher` + listener deep link | `flutter_web_auth_2` | ASWebAuthenticationSession, AuthTab/Custom Tabs, `CANCELED` su resume/dismiss |
| Storage cifrato | SharedPreferences "offuscate", AES a mano | `flutter_secure_storage ^10.3.4` | Keychain/Keystore; migrazioni cifrari |
| SHA-256 / base64url | implementazione manuale | `crypto` + `dart:convert` (`base64Url`) | Verificato col vettore RFC 7636 |
| Random per il verifier | `Random()` | `Random.secure()` | CSPRNG |
| Single-flight | lock custom con flag booleani | `Completer<String>` condiviso | CONTEXT: niente nuovi package |
| Retry GraphQL | loop in ogni repository | `AuthAuthLink` (un posto) | un solo retry, niente loop |
| Retry REST | wrapper per ogni chiamata dio | `AuthInterceptor.onError` | idem |
| Verifica firma JWT lato app | qualunque cosa | niente (il BE verifica) | decodificare solo il payload per lo scheduling |

**Key insight:** la complessità sta nella *coordinazione* (single-flight + rotazione + epoch + WS), non nelle primitive: concentrarla in `SessionAuthTokenService` e in due adapter sottili (link, interceptor).

## Common Pitfalls

1. **Build Android rotta da AGP 8.7.3** — `flutter_web_auth_2` ≥ 5.0.x → `androidx.browser 1.9.0` richiede AGP ≥ 8.9.1 (+compileSdk 36, già ok con Flutter 3.35.5). *Evitare:* task W0 "alza AGP a ≥8.9.1 e verifica `flutter build apk --debug`". *Segnale:* `checkDebugAarMetadata` fallisce [VERIFIED].
2. **`flutter_secure_storage 11.x` non risolve** su Dart 3.9.2 → `flutter pub add` da solo seleziona `^10.3.4`; non forzare `^11`. Rivalutare dopo upgrade Flutter. In v10: `AndroidOptions()` default (RSA-OAEP + AES-GCM) — **non** usare `encryptedSharedPreferences` (deprecato); `migrateOnAlgorithmChange` default true.
3. **iOS: keychain sopravvive alla disinstallazione** → su reinstall l'app trova un refresh token "vecchio". *Evitare:* marker `has_launched_before` in `shared_preferences` (che invece viene cancellato alla disinstallazione): al primo avvio senza marker → `store.clear()` prima di leggere, poi scrivi il marker. Accessibilità iOS: `KeychainAccessibility.first_unlock_this_device` (il default `unlocked` fallisce se l'app parte in background a dispositivo bloccato, p.es. da push; `_this_device` evita la migrazione su nuovo device). [CITED: README/enum flutter_secure_storage per le opzioni; la persistenza keychain post-uninstall = comportamento Apple noto, ASSUMED/MEDIUM]
4. **Android Auto Backup** ripristina i dati cifrati senza chiave → eccezioni di lettura. *Evitare:* `allowBackup="false"` **e** wrapper che cattura eccezioni in lettura → "nessuna sessione" + clear.
5. **Refresh doppio/tardivo uccide la sessione** (reuse detection BE, grace 30 s): un solo refresh in volo; il reattivo deve confrontare il token rifiutato col corrente (`recoverFromUnauthorized(rejectedToken)`) prima di forzare; mai refresh da due punti diversi (timer, link, interceptor, WS) senza passare dal single-flight.
6. **Refresh che completa dopo il logout** riscrive lo storage → sessione zombie. *Evitare:* epoch/generation check prima di persistere (Pattern 2) + test dedicato.
7. **Loop di refresh con orologio sballato** (device avanti > TTL): floor minimo sullo scheduling; preferire `exp−iat` (Pattern 2).
8. **`initialPayload` che lancia ferma la riconnessione WS** (sorgente 5.2.1, Pattern 6 punto 4) → catch-all e `{}`.
9. **`.env` è un asset bundled** (`pubspec.yaml`: `- .env`): `DEV_AUTH_ACCESS_TOKEN` finisce nel binario e, se `DEV_AUTH_ENABLED=true` in una build release, il bypass è attivo lato app (il BE, in produzione, rifiuta di avviarsi col flag dev: fail-closed [CITED: BE D-17]). Raccomandato (basso costo, difesa in profondità): nel composition root `EnvConfig.devAuthEnabled && !kReleaseMode`; rimozione completa resta Phase 12. Richiede conferma (Assumption A6/Open Question 6).
10. **Modal sulla route radice fuori dai provider** (Pattern 8, trappola 1).
11. **`dart format --set-exit-if-changed lib test` SCRIVE i file** (senza `--output=none` formatta in-place) e il **baseline del repo non è formattato** (76 file su 183 verrebbero riscritti). *Evitare:* nei task/verify usare `dart format --output=none --set-exit-if-changed <solo i file toccati dalla fase>`. (Questa ricerca ha involontariamente riformattato 76 file eseguendo il comando alla lettera: vedi nota nel report finale all'orchestratore.)
12. **FormData non riutilizzabile** nel retry dio (stream monouso) → `clone()`.
13. **Il ticket/verifier/refresh token nei log**: niente `print`/`debugPrint` dei valori; loggare solo il codice errore.
14. **Callback `?error=` arriva come URL di successo** al plugin (nessuna eccezione): va parsato (`LoginCallback`). `access_denied` = silenzioso come CANCELED (D-21); `twitch_not_configured` → messaggio D-27; `invalid_state|invalid_request|twitch_client_mismatch|twitch_exchange_failed` e callback malformata → errore generico D-22.
15. **`INTERNET` mancante nel manifest main** (preesistente): in release nessuna rete. Task di setup.

## Code Examples

### 1. Challenge S256 (verificato: vettore RFC 7636 App. B ✔, verifier 43 char ✔, regex `[A-Za-z0-9\-._~]{43,128}` ✔)
```dart
// Source: eseguito con `dart run` su copia scratch con crypto 3.0.7
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

String _base64UrlNoPadding(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');

LoginChallenge generateLoginChallenge({Random? random}) {           // random iniettabile → test deterministici
  final rng = random ?? Random.secure();
  final verifier = _base64UrlNoPadding(List<int>.generate(32, (_) => rng.nextInt(256))); // 32 byte → 43 char
  return LoginChallenge(codeVerifier: verifier, codeChallenge: challengeFor(verifier));
}
String challengeFor(String verifier) =>
    _base64UrlNoPadding(sha256.convert(ascii.encode(verifier)).bytes);
// test: challengeFor('dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk') == 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM'
```

### 2. Wrapper del browser (iniettabile) — API verificata sul sorgente 5.1.0
```dart
abstract interface class BrowserAuthenticator {
  /// Ritorna l'URL di callback completo. Lancia [BrowserAuthCancelled] / [BrowserAuthFailure].
  Future<String> authenticate({required Uri startUrl, required String callbackScheme});
}
class FlutterWebAuth2BrowserAuthenticator implements BrowserAuthenticator {
  const FlutterWebAuth2BrowserAuthenticator({this.preferEphemeral = false});
  final bool preferEphemeral;
  @override
  Future<String> authenticate({required Uri startUrl, required String callbackScheme}) async {
    try {
      return await FlutterWebAuth2.authenticate(            // static Future<String>
        url: startUrl.toString(),
        callbackUrlScheme: callbackScheme,                   // 'klimmeck' (solo scheme)
        options: FlutterWebAuth2Options(preferEphemeral: preferEphemeral),
      );
    } on PlatformException catch (e) {
      throw mapBrowserAuthError(e);                          // funzione pura testabile
    }
  }
}
BrowserAuthException mapBrowserAuthError(PlatformException e) => e.code == 'CANCELED'
    ? const BrowserAuthCancelled()
    : BrowserAuthFailure(e.code);   // EUNKNOWN, FAILED, NO_BROWSER, SECURITY_EXCEPTION, ACQUIRE_ROOT_VIEW_CONTROLLER_FAILED
```
`CANCELED` è il codice sia iOS (`canceledLogin`) sia Android (`RESULT_CANCELED` AuthTab e `cleanUpDanglingCalls` al resume) [VERIFIED: Swift + Kotlin]. Il plugin NON ha un timeout su mobile (`timeout` solo web/desktop) [ASSUMED].

### 3. Parse della callback
```dart
sealed class LoginCallback { const LoginCallback(); }
final class LoginTicketReceived extends LoginCallback { const LoginTicketReceived(this.ticket); final String ticket; }
final class LoginDeniedByUser extends LoginCallback { const LoginDeniedByUser(); }          // error=access_denied
final class LoginRejectedByBackend extends LoginCallback { const LoginRejectedByBackend(this.code); final String code; }
LoginCallback parseLoginCallback(String url) {
  final q = Uri.parse(url).queryParameters;
  final ticket = q['ticket'];
  if (ticket != null && ticket.isNotEmpty) return LoginTicketReceived(ticket);
  return switch (q['error']) {
    'access_denied' => const LoginDeniedByUser(),
    final String code => LoginRejectedByBackend(code),    // include twitch_not_configured
    null => const LoginRejectedByBackend('invalid_callback'),
  };
}
```
URL di start: `Uri.parse(EnvConfig.baseUrl).resolve('auth/twitch/start').replace(queryParameters: {'challenge': challenge})` (base con `/` finale come nel default).

### 4. Documenti GraphQL (nomi di campo = contratto BE; **shape/argomenti ASSUMED** finché non esiste `BACKEND-NOTES.md`/`schema.gql` con `AuthSession`)
```dart
// lib/graphql/mutations/auth_mutations.dart
class AuthMutations {
  static const String exchangeLoginTicket = r'''
    mutation ExchangeLoginTicket($ticket: String!, $codeVerifier: String!) {
      exchangeLoginTicket(ticket: $ticket, codeVerifier: $codeVerifier) { ...}   # AuthSession
    }''';
  // refreshSession(refreshToken), logout, GetMe → idem; selezione user: id twitchId twitchPoints role currentCharacter { id }
}
```
Selezionare **`currentCharacter { id }`** nell'user: `User.fromJson`/`Character.fromJson` tollerano il parziale (tutti i campi tranne `id` sono opzionali) e Phase 2 deciderà il routing su `currentCharacter == null` — omettere il campo darebbe un falso "nessun personaggio". `User` BE: `id: ID!, role: RoleType!, twitchId: String!, twitchPoints: Int!, currentCharacter` [VERIFIED: BE src/schema.gql]; `accessTokenExpiresAt` = scalar `DateTime` (stringa ISO) [VERIFIED: `scalar DateTime`; uso nel tipo AuthSession = ASSUMED]. Mappatura errori in `BackendAuthApi`: `extensions.code ∈ {SESSION_REVOKED, SESSION_EXPIRED}` → `SessionRejected`; `LOGIN_TICKET_INVALID` → `LoginTicketInvalid`; `UNAUTHENTICATED` su chiamata pubblica = rifiuto; `LinkException`/5xx/timeout/codice ignoto → `TransientAuthFailure`.

### 5. Wiring Link (HTTP con retry, WS con policy)
```dart
final httpWithAuth = AuthAuthLink(authService: auth, recovery: recovery).concat(HttpLink(EnvConfig.graphqlHttpUrl));
final link = Link.split((r) => r.isSubscription, wsLink, httpWithAuth);   // il retry NON tocca le subscription
```

## State of the Art

| Vecchio | Corrente | Quando | Impatto |
|---------|----------|--------|---------|
| App fa PKCE verso Twitch (research aprile) | BE media il flusso; l'app lega app↔BE con S256 e riscatta un ticket | 2026-10-06 | Nessun token Twitch, nessun client id nell'app |
| Android Custom Tabs + CallbackActivity | `flutter_web_auth_2` 5.x usa **AuthTab** (androidx.browser 1.9.0) quando supportato, Custom Tabs come fallback | 5.0.x (2025–26) | Richiede AGP ≥ 8.9.1; CallbackActivity resta per il fallback |
| `encryptedSharedPreferences` (Jetpack Security) | Cifrari custom (RSA-OAEP + AES-GCM) in `flutter_secure_storage` 10 | 10.0.0 | Opzione deprecata; default già sicuro |
| `flutter_secure_storage` 9.x | 10.3.x (11.x esiste ma richiede Dart ≥3.10) | 2026 | Restare su `^10.3.4` |

**Deprecato/obsoleto:** `flutter_web_auth` (sostituito da `_2`); `ephemeralIntentFlags` (usare `preferEphemeral`); `SocketSubProtocol` nel package graphql (usare `GraphQLProtocol`); tutta la research di aprile su PKCE/Twitch.

## Dev stub — cosa cambia e quali test lo codificano (D-24/D-25)

Modifiche a `DevAuthTokenService`: costruttore con `BackendMeSource? me` opzionale; `initialize()` con allineamento `me` best-effort; `logout()` → `Unauthenticated(signedOut)` + token null; `login()` → `Authenticated`; (opz.) `handleRevocation()` → `Unauthenticated(sessionExpired)`; aggiornare dartdoc/commenti "no-op"/"Phase 11 sostituirà".

| Test Phase 1 | Stato dopo D-24 | Azione |
|--------------|-----------------|--------|
| `test/repository/services/auth/dev_auth_token_service_noop_test.dart` | **`logout()` test FALLISCE** (ora emette `Unauthenticated`). **`login()` test è tautologico** (`expect(statesAfterLogin, equals(states.length))` è sempre vero → coprirebbe nulla). `handleRevocation()` resta verde se rimane no-op | Riscrivere e rinominare (es. `dev_auth_token_service_transitions_test.dart`): initialize→Authenticated; logout→`Unauthenticated(signedOut)` + `getAccessToken()==null`; login→`Authenticated`; (opz.) handleRevocation |
| `dev_auth_token_service_test.dart` | invariato (senza `me` iniettato → user da env) | Aggiungere casi: `me` ok → user allineato; `me` che fallisce/timeout → fallback env |
| `dev_auth_token_service_role_test.dart` | invariato | — |
| `auth_token_service_contract_test.dart` | invariato; ⚠️ **ha una modifica non committata dell'utente** (1 riga: `(state as AuthAuthenticated).accessToken` → `(state).accessToken`) | Aggiungere test su `AuthUnauthenticated` default reason/props; coordinarsi per non sovrascrivere la modifica |
| `test/network/auth_interceptor_test.dart`, `graphql_auth_link_test.dart` | compilano (parametri nuovi opzionali) | Estendere con i casi retry; rimuovere commenti "RED/Diventerà GREEN" (stantii); estrarre il `MockAuthTokenService` duplicato in `test/helpers/mocks.dart` |
| `test/app/app_wiring_test.dart`, `widget_test.dart` | invariati | Aggiungere test `AuthGate` |

## Assumptions Log

| # | Claim | Sezione | Rischio se errato |
|---|-------|---------|-------------------|
| A1 | Forma esatta di `AuthSession`/argomenti delle mutation (`exchangeLoginTicket(ticket, codeVerifier)`, `refreshSession(refreshToken)`, `logout`, `me`) e `accessTokenExpiresAt` come `DateTime` ISO | Code Examples 4 | Medio: i documenti GraphQL vanno riallineati a `BACKEND-NOTES.md`/`schema.gql` quando atterrano (wave dedicata/verifica) |
| A2 | Il JWT contiene `iat` (oltre a `exp`) | Pattern 2 | Basso: fallback su `accessTokenExpiresAt − now` + floor |
| A3 | Custom Tabs/ASWebAuthenticationSession aprono start URL `http://` senza ATS/NSC dell'app; dart:io non soggetto a cleartext policy | Setup nativo | Basso/dev-only: serve tunnel https comunque per Twitch; verificare in UAT |
| A4 | Il keychain iOS sopravvive alla disinstallazione (marker first-run necessario) | Pitfall 3 | Basso: il marker è innocuo anche se non servisse |
| A5 | Non ri-emettere `AuthAuthenticated` a ogni rotazione se l'utente non cambia | Pattern 2 | Basso: se si preferisce ri-emettere, filtrare con `buildWhen`/`listenWhen` su `user.id` |
| A6 | Ignorare `DEV_AUTH_ENABLED` quando `kReleaseMode` (difesa in profondità) è gradito | Pitfall 9 | Basso: leggermente oltre D-23 — **confermare con l'utente** |
| A7 | `QueuedInterceptor` + `dio.fetch` nello stesso `Dio` può andare in deadlock | Pattern 4 | Basso: la scelta `Interceptor` semplice è comunque corretta |
| A8 | Errori GraphQL di auth arrivano con HTTP 200 e `extensions.code` stabile su HTTP (BE MEDIUM finché non provato dall'integration test) | Pattern 3 | Medio: gestire anche `ServerException` 401 |
| A9 | `preferEphemeral=false` + `force_verify=true` BE basta per l'account switch su Twitch | Setup nativo | Medio: se la pagina Twitch non permette di cambiare account, passare a `true` |
| A10 | Il plugin non applica timeout su mobile | Code Examples 2 | Basso |

## Open Questions

1. **`BACKEND-NOTES.md` BE non esiste ancora** — *Noto:* contratto riassunto in 02-CONTEXT/02-RESEARCH (D-01..D-34, §Q1 Q2 Q8, "Contenuto minimo"). *Incerto:* nomi/tipi esatti dei campi, codice per refresh token malformato, se `logout` accetta anche solo il refresh token (utile quando l'access è scaduto). *Raccomandazione:* pianificare contro il riassunto; includere nel plan una task di riallineamento ai documenti GraphQL quando il file/`schema.gql` atterra (**se esiste, vince**, come da CONTEXT); loggare le richieste al BE in `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` (memoria utente): eventi WS persi nel gap 4401, `logout` con access scaduto, codice per refresh malformato.
2. **`preferEphemeral` (D-14/AUTH-05)** — default `false` (SSO, meno attrito) vs `true` (account switch garantito, login a ogni volta). *Raccomandazione:* parametro del wrapper, default `false`; item UAT "cambio account su device"; fallback `true` se necessario.
3. **Chi chiama `initialize()`** — oggi il dartdoc dice `main.dart`. *Raccomandazione:* `AuthCubit.start()` dopo `runApp` (primo frame immediato, cubit testabile); aggiornare il dartdoc. D-02 invariata (firma identica).
4. **`UnauthorizedRecovery` separata vs metodo concreto sul contratto** — interpretazione di D-02 "invariato". *Raccomandazione:* interfaccia separata (nessuna modifica a `AuthTokenService` oltre a `AuthUnauthenticated.reason`); confermare.
5. **Messaggio D-10 sulla UI** — UI-SPEC: splash 1,5 s (cold start) e dialog/snackbar su SignIn (in sessione). *Raccomandazione:* un solo percorso: notice inline in `SignInScreen` quando `reason == sessionExpired` (meno stati nello splash); aggiornare UI-SPEC se accettato.
6. **Guardia `kReleaseMode` sul bypass dev** (Pitfall 9, A6) — confermare.
7. **Entry point del logout fino a Phase 4** — *Raccomandazione:* nessuna UI di produzione; esercitare `AuthCubit.logout()` + `LogoutConfirmationDialog` via test (bloc_test + widget test con un host minimale) e, per QA manuale, un trigger **solo `kDebugMode`** opzionale e non committato (decidere nel plan; non aggiungere chrome nel gameplay). Il dialog espone `Future<bool> showLogoutConfirmationDialog(BuildContext)`.
8. **Eventi persi durante il gap di riconnessione WS** (4401 ogni 15 min) — responsabilità Phase 3; segnalarlo al BE/Phase 3 come refetch-on-reconnect.

## Environment Availability

| Dipendenza | Richiesta da | Disponibile | Versione | Fallback |
|------------|--------------|-------------|----------|----------|
| Flutter / Dart | tutto | ✓ | 3.35.5 / 3.9.2 (`flutter doctor` OK) | — |
| Android SDK / JDK | build Android, verifica AGP | ✓ | SDK 36.1.0, JDK 21 (Android Studio) | — |
| Gradle wrapper | build Android | ✓ | 8.12 (basta per AGP 8.9.1; verificato) | — |
| AGP | `flutter_web_auth_2` | ✗ (8.7.3) | richiesto ≥ 8.9.1 | **nessun fallback**: task W0 obbligatorio |
| Xcode / CocoaPods | build iOS | ✓ | Xcode 26.3 / Pods 1.16.2 | — |
| `pub.dev` | dipendenze | ✓ | — | — |
| Backend locale con Twitch keys | login reale end-to-end | ✗ | — | UAT pendente (D-28); bypass dev + fake nei test |
| Backend locale (dev bypass) | `me` dev, GraphQL reale | non verificato | — | stub usa fallback `.env` |

**Bloccante senza fallback:** AGP ≥ 8.9.1. **Con fallback:** chiavi Twitch (UAT pendente).

## Validation Architecture

> `.planning/config.json` non disattiva `nyquist_validation` → sezione attiva.

### Test Framework
| Proprietà | Valore |
|-----------|--------|
| Framework | `flutter_test` + `bloc_test 10.0.0` + `mocktail 1.0.5` + `fake_async 1.3.3` (da dichiarare dev) |
| Config | nessuna (`analysis_options.yaml` = `flutter_lints`) |
| Quick run | `flutter test test/repository/services/auth test/network test/screens` (< 30 s) |
| Full suite | `flutter test` (baseline: 20 test verdi) |
| Lint | `flutter analyze lib test` (baseline: **17 issue info preesistenti**; gate = nessuna issue *nuova*; `flutter analyze` senza path include `tools/` con 40+ `avoid_print` irrilevanti) |
| Format | `dart format --output=none --set-exit-if-changed <file toccati>` — **mai** `dart format --set-exit-if-changed lib test` (scrive in-place; baseline non formattato, Pitfall 11) |

### Phase Requirements → Test Map
| Req | Comportamento | Tipo | Comando | File |
|-----|---------------|------|---------|------|
| AUTH-01 | S256: vettore RFC, 43 char, charset, unicità | unit | `flutter test test/models/auth/login_challenge_test.dart` | ❌ W0 |
| AUTH-01 | parse callback (`ticket`, `access_denied`, `twitch_not_configured`, malformata) | unit | `.../login_callback_test.dart` | ❌ W0 |
| AUTH-01 | `mapBrowserAuthError` (`CANCELED` → cancelled) | unit | `.../browser_authenticator_test.dart` | ❌ W0 |
| AUTH-01 | `login()`: start URL col challenge, exchange col verifier, persist refresh, `Authenticated`; cancel/denied silenziosi; `twitch_not_configured`; errori rete | unit (fake browser/api/store) | `.../session_auth_token_service_login_test.dart` | ❌ W0 |
| AUTH-01/D-21/22/27 | `SignInCubit` sequenze di stati | bloc_test | `test/screens/signIn/cubit/sign_in_cubit_test.dart` | ❌ W0 |
| AUTH-01 | `SignInScreen`: bottone, errore inline, messaggio D-27, notice sessione scaduta, hint dev | widget | `test/screens/signIn/sign_in_screen_test.dart` | ❌ W0 |
| AUTH-02 | refresh token solo in `SessionStore`; lettura che lancia → "nessuna sessione" + clear; marker first-run | unit (in-memory fake + wrapper con storage fittizio) | `test/repository/storage/session_store_test.dart` | ❌ W0 |
| AUTH-03 | cold start: token → refresh → persist-before-forget (`verifyInOrder`) → `Authenticated`; senza token → `Unauthenticated(signedOut)` | unit | `.../session_auth_token_service_bootstrap_test.dart` | ❌ W0 |
| AUTH-03/D-18 | errore transitorio → resta `Bootstrapping`, backoff 1/2/4… cap 30 s, indefinito (`fakeAsync`) | unit | idem | ❌ W0 |
| AUTH-04 | ordine teardown (`verifyInOrder`: api.logout → onTeardown → store.clear → emit), timeout BE non blocca, offline ok, `getAccessToken()==null`, refresh post-logout non riscrive lo storage (epoch) | unit | `.../session_auth_token_service_logout_test.dart` | ❌ W0 |
| AUTH-04 | `GraphQLClientHolder.reset()`: dispone WS, nuovo client, notifier aggiornato | unit | `test/repository/services/graphql/graphql_client_holder_test.dart` | ❌ W0 |
| AUTH-04/D-11 | `LogoutConfirmationDialog` (annulla/conferma, non dismissibile) + `AuthCubit.logout()` | widget + bloc_test | `test/shared/components/modal/logout_confirmation_dialog_test.dart`, `test/screens/auth/cubit/auth_cubit_test.dart` | ❌ W0 |
| AUTH-05 | logout poi login altro utente → stati `Unauthenticated`→`Authenticated(B)`; la shell è ricreata (Cubit nuovi, vecchi chiusi) | unit + widget (`AuthGate`) | `test/screens/auth/auth_gate_test.dart` | ❌ W0 |
| AUTH-06 | N `getAccessToken()` concorrenti vicino a scadenza → 1 sola `refreshSession`; timer proattivo a `exp−60 s` (`fakeAsync`); floor anti-loop; rotazione persistita | unit | `.../session_auth_token_service_refresh_test.dart` | ❌ W0 |
| AUTH-06 | `AuthAuthLink`: UNAUTHENTICATED → recovery → retry **una** volta col token nuovo; secondo UNAUTHENTICATED non ritenta; senza recovery non ritenta; subscription non toccate | unit | estendere `test/network/graphql_auth_link_test.dart` | ✅ esteso |
| AUTH-06 | `AuthInterceptor`: 401 → recovery → `fetch` una volta (adapter fake), `FormData.clone`, no loop | unit | estendere `test/network/auth_interceptor_test.dart` | ✅ esteso |
| AUTH-06/D-07 | `WsReconnectPolicy`: `initialPayload` legge token corrente e non lancia; 4401/4403 → recovery con token rifiutato; backoff capped; reset dopo connessione lunga | unit (`fakeAsync`) | `test/repository/services/graphql/ws_reconnect_policy_test.dart` | ❌ W0 |
| AUTH-07 | refresh `SESSION_REVOKED`/`SESSION_EXPIRED` → teardown + `Unauthenticated(sessionExpired)`; 5xx/rete NON fanno logout | unit | `.../session_auth_token_service_revocation_test.dart` | ❌ W0 |
| AUTH-07/D-10/D-18 | Splash: messaggio dopo 10 s, bottone → sign-in, preload SVG **dopo** `Authenticated` | bloc_test + widget (`pump`) | `test/screens/splash/…` | ❌ W0 |
| AUTH-07 | `AuthUnauthenticated.reason` default/props | unit | estendere `auth_token_service_contract_test.dart` | ✅ esteso |
| DEV-AUTH-04 (amend.) | stub: logout/login/`me` allineato/fallback | unit | `.../dev_auth_token_service_transitions_test.dart` | riscrivere noop test |

**Solo manuale (UAT pendente, D-28):** login reale col browser su iOS e Android (intent `klimmeck://`, AuthTab/Custom Tabs, cancel con back/chiusura), `twitch_not_configured` reale dal BE, account switch con SSO Twitch, rotazione refresh e chiusura WS 4401 contro un BE reale, keychain dopo reinstall iOS, restore backup Android, start URL `http://`/tunnel https su device.

### Sampling Rate
- **Per commit task:** `flutter test <file/dir del task>` + `flutter analyze <file toccati>`
- **Per onda:** `flutter test` completo
- **Gate di fase:** `flutter test` verde + `flutter analyze lib test` senza nuove issue + `flutter build apk --debug` OK (AGP) prima di `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `pubspec.yaml`: `flutter_web_auth_2 ^5.1.0`, `flutter_secure_storage ^10.3.4`, `crypto`, dev `fake_async`
- [ ] AGP ≥ 8.9.1 (`android/settings.gradle.kts`) + manifest (CallbackActivity, `allowBackup=false`, `INTERNET`) → verificare `flutter build apk --debug`
- [ ] `test/helpers/`: `mocks.dart` (MockAuthTokenService unico, MockBackendAuthApi, MockBrowserAuthenticator), `fakes/in_memory_session_store.dart`, `auth_session_fixtures.dart` (`buildAuthSession`, JWT fittizi con `exp/iat`), fake `HttpClientAdapter` per dio, `registerFallbackValue` dove serve
- [ ] File di test elencati sopra (❌ W0)
- [ ] Riscrittura `dev_auth_token_service_noop_test.dart`

## Security Domain

> `security_enforcement` non disabilitato → incluso.

### Applicable ASVS Categories
| ASVS | Si applica | Controllo standard |
|------|-----------|--------------------|
| V2 Authentication | sì | Login mediato dal BE, ticket monouso legato a S256, nessun credential nell'app |
| V3 Session Management | sì | Access JWT 15 min in memoria; refresh token rotante in storage cifrato; single-flight; revoca rilevata; logout che invalida sul BE |
| V4 Access Control | no (server-side) | il BE è fonte di verità; `role` nel JWT è snapshot |
| V5 Input Validation | sì | parse rigoroso di `klimmeck://auth?…`; ticket mai loggato; codici errore whitelisted |
| V6 Cryptography | sì | `crypto` SHA-256 + `Random.secure()`; niente crypto a mano; storage via Keychain/Keystore |
| V8 Data Protection | sì | token solo in `flutter_secure_storage`/memoria; mai in `shared_preferences`, log, stato Cubit in chiaro |
| V9 Communications | parziale | prod: solo https/wss; dev: http su LAN (Phase 12 per l'hardening) |

### Known Threat Patterns
| Pattern | STRIDE | Mitigazione |
|---------|--------|-------------|
| Hijack dello scheme custom `klimmeck://` (app ostile) | Spoofing / Info Disclosure | ticket inutilizzabile senza `code_verifier` (S256, verifier solo in memoria dell'app); ticket monouso ≤ 60 s [CITED: BE D-02/D-03] |
| Furto del refresh token da backup/storage | Info Disclosure | Keychain `first_unlock_this_device`, Keystore cifrari v10, `allowBackup=false`, mai nei log |
| Riuso del refresh token (race/doppio refresh) | Tampering / DoS (sessione revocata) | single-flight + epoch + persist-before-forget; il BE rileva il riuso |
| Sessione zombie dopo logout | Elevation of Privilege | epoch guard, `store.clear()`, `holder.reset()`, scarto immediato dell'access JWT |
| Sessione stale dopo reinstall iOS | Spoofing | marker first-run in `shared_preferences` |
| Token/ticket nei log o nei crash report | Info Disclosure | nessun `print`; log solo di codici |
| Bypass dev nel binario release | Elevation of Privilege | BE fail-closed in prod; (raccomandato) guardia `kReleaseMode`; `.env` asset va ripulito dai `DEV_AUTH_*` in CI; rimozione in Phase 12 |
| Account bleed tra utenti | Info Disclosure | shell keyed su `user.id`, client GraphQL ricreato, cubit chiusi al logout |
| Loop di riconnessione con token morto | DoS | backoff capped, refresh forzato su 4401/4403, dispose al logout |

## Sources

### Primary (HIGH)
- Sorgenti installati/scaricati e letti: `graphql-5.2.1` (`websocket_client.dart`, `websocket_link.dart`, `graphql_client.dart`, `query_manager.dart`), `graphql_flutter-5.2.1` (`graphql_provider.dart`), `gql_error_link-1.0.0+1`, `gql_link`/`gql_exec` (ContextEntry, `Link.split`), `dio-5.8.0+1` (`interceptor.dart`, `form_data.dart`, `dio_mixin.dart`), `flutter_web_auth_2-5.1.0` (Dart, Swift, Kotlin, manifest, build.gradle), `flutter_web_auth_2_platform_interface-5.0.0`, `flutter_secure_storage-10.3.4` e `-11.2.0` (README, CHANGELOG, `lib/options/*`), `flutter_test` pubspec
- pub.dev API (`/api/packages/<pkg>`) 2026-10-06: versioni, date, vincoli SDK
- **Build reale** in copia scratch del progetto: `flutter pub add flutter_web_auth_2 flutter_secure_storage crypto` → risoluzione `^5.1.0/^10.3.4/^3.0.7`; `flutter pub add flutter_secure_storage:^11.2.0` → fallita (win32 ^6/Dart ≥3.10); `flutter build apk --debug` → fallita con AGP 8.7.3 («browser:1.9.0 requires AGP 8.9.1»), riuscita con 8.9.1 + CallbackActivity
- `dart run` (scratch) del generatore S256: vettore RFC 7636 App. B ✔
- BE (read-only): `02-CONTEXT.md` (D-01..D-34), `02-RESEARCH.md` (§Q1, §Q2, §Q8, "Contenuto minimo BACKEND-NOTES.md"), `src/schema.gql` (`User`, `DateTime`)
- Codice e doc di progetto: `lib/**`, `test/**`, `CLAUDE.md`, `docs/rules/*`, `.planning/**`

### Secondary (MEDIUM)
- WebFetch README/CHANGELOG flutter_web_auth_2 (pub.dev, GitHub raw) — coerenti con i sorgenti
- Ricerca web: AuthTab/androidx.browser 1.9.0 richiede compileSdk 36 e AGP 8.9.1 (conferma indipendente della build)

### Tertiary (LOW)
- Comportamento runtime di http:// negli start URL, persistenza keychain post-uninstall, nessun timeout del plugin su mobile (A3, A4, A10) — non verificati su device in questa sessione

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versioni da pub.dev + risoluzione e build reali
- Setup nativo: HIGH (AGP/manifest verificati con build), MEDIUM (runtime su device non provato)
- Architettura/pattern WS-link-dio: HIGH sul comportamento delle librerie (sorgenti letti), MEDIUM sul design complessivo (non ancora implementato)
- Contratto BE: MEDIUM — riassunto, `BACKEND-NOTES.md` assente
- Pitfall: HIGH (la maggior parte derivata da sorgente/build)

**Research date:** 2026-10-06
**Valid until:** ~30 giorni (stack stabile); rivalutare subito se atterra `BACKEND-NOTES.md` o se si aggiorna Flutter (sblocca `flutter_secure_storage 11.x`)
