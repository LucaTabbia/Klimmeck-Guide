---
phase: 11-auth-session-bootstrap
verified: 2026-10-06T00:00:00Z
status: human_needed
score: 7/7 must-haves verified (automaticamente, con fake)
overrides_applied: 0
gaps: []
human_verification:
  - test: "Login Twitch reale su device fisico Android e iOS (browser di sistema, deep link klimmeck://, shell autenticata con utente reale da `me`)"
    expected: "Il login si completa e l'app atterra autenticata"
    why_human: "Le chiavi Twitch non esistono ancora (D-28); verificato solo con fake"
  - test: "Annullamento (back / chiusura browser) e consenso negato (`access_denied`)"
    expected: "Sign-in invariato, nessun messaggio di errore"
    why_human: "Richiede browser reale e Twitch"
  - test: "Cambio account con SSO Twitch (`force_verify=true`)"
    expected: "Dopo logout si puo scegliere un altro account; se Twitch riusa l'account A, passare `preferEphemeral: true`"
    why_human: "Comportamento del browser/SSO non simulabile"
  - test: "Kill e riavvio app, poi attesa >15 min con una subscription attiva"
    expected: "Sessione ripresa senza prompt; chiusura WS 4401 e riconnessione silenziosa col token nuovo"
    why_human: "Richiede BE reale con JWT a scadenza reale"
  - test: "Revoca server-side della sessione"
    expected: "Sign-in con 'La sessione è scaduta, accedi di nuovo.'"
    why_human: "Richiede BE reale"
  - test: "Reinstall iOS (Keychain) e restore backup Android"
    expected: "Nessuna sessione residua su iOS; nessun crash su Android"
    why_human: "Comportamento di piattaforma"
  - test: "Conformita visiva di SignIn, Splash (hint 10 s) e dialog di logout alla UI-SPEC su schermo reale (landscape)"
    expected: "Layout, copy e stati come da 11-UI-SPEC.md"
    why_human: "Giudizio visivo"
  - test: "BE senza chiavi Twitch e backend http:// in dev (cleartext solo in debug)"
    expected: "'Login con Twitch non ancora disponibile.'; connessione dev funzionante con `adb reverse`"
    why_human: "Richiede BE e device"
---

# Phase 11: Auth & Session Bootstrap — Report di verifica

**Obiettivo della fase:** affiancare al `DevAuthTokenService` un'implementazione reale basata sulla sessione del backend (login Twitch via browser di sistema mediato dal BE, secure storage, refresh mutex, logout atomico, detection revoca), contratto `AuthTokenService` invariato, stub selezionabile con `DEV_AUTH_ENABLED=true`.
**Verificato:** 2026-10-06
**Stato:** human_needed
**Ri-verifica:** No (verifica iniziale)

## Esecuzione automatica

| Controllo | Risultato |
| --- | --- |
| `flutter test` | 247 test, tutti verdi |
| `flutter analyze lib test` | 11 issue (baseline pre-fase 14), nessuna nei file nuovi della fase (board.dart, journal_cubit, world_map_cubit, profile_cubit, shop_cubit, transaction_cubit, spell_info, notification.dart: tutti preesistenti) |
| `flutter build` | NON rieseguito (build debug Android gia provata dai summary 11-01, 11-10, 11-11) |
| `dart format` | non eseguito (vietato; `routes.dart` noto non conforme, D-38) |

## Verita osservabili (Success Criteria ROADMAP)

| # | Verita | Stato | Evidenza |
| --- | --- | --- | --- |
| 1 | Login Twitch via browser di sistema mediato dal BE | VERIFICATO (fake) / device reale PENDING | `SessionAuthTokenService.login` -> `auth/twitch/start?challenge=<S256>` via `BrowserAuthenticator` (flutter_web_auth_2) -> `parseLoginCallback` -> `exchangeLoginTicket(ticket, codeVerifier)` -> `AuthAuthenticated`. Nessuna WebView. Mutation allineate a `schema.gql` BE. |
| 2 | Sessione ripresa dopo kill/relaunch | VERIFICATO (fake) | `initialize()` legge il refresh token da `SecureSessionStore`, `_attemptBootstrap` -> `refreshSession`; nuovo refresh token persistito prima dell'aggiornamento in memoria; errori transitori = retry con backoff senza perdere la sessione. |
| 3 | Logout: nessun token/cache/subscription sopravvive | VERIFICATO | `logout`: backend best-effort con timeout 4 s -> `_endSession`: epoch++ / forget -> `onSessionTeardown` (reset `GraphQLClientHolder`) -> `store.clear()` -> emit `AuthUnauthenticated`. Cubit gameplay vivono in `AuthenticatedShell` (keyed su `user.id`, chiusi allo scollegamento). |
| 4 | Cambio account senza bleed-through | VERIFICATO (fake) | `KeyedSubtree(ValueKey(user.id))` nell'`AuthGate`; shell ricreata con Cubit nuovi; teardown del client GraphQL a ogni fine sessione; `_announceIdentityChange` sul refresh. Con browser/SSO reale: PENDING. |
| 5 | Revoca/scadenza -> sign-in con messaggio chiaro | VERIFICATO | Solo `SESSION_EXPIRED`/`SESSION_REVOKED` producono `SessionRejected` (`auth_api_exception.dart`); gli altri codici/errori di rete sono `TransientAuthFailure` non distruttivi. `AuthUnauthenticated(reason: sessionExpired)` -> `SignInScreen` con "La sessione è scaduta, accedi di nuovo.". |
| 6 | Switch stub/reale senza modifiche ai consumer | VERIFICATO | Contratto astratto con 7 firme invariate (`initialize`, `authStateStream`, `getAccessToken`, `login`, `logout`, `handleRevocation`, `dispose`); solo aggiunta additiva `AuthUnauthenticated.reason`. Selezione unica in `main.dart::_buildAuth` su `EnvConfig.devAuthEnabled`. Nessun type-check del servizio concreto fuori da `lib/repository/services/auth/` (grep vuoto; `is UnauthorizedRecovery` non presente fuori). I consumer (link GraphQL, interceptor dio) sono stati modificati una volta dalla fase per il retry-once, con `UnauthorizedRecovery?` opzionale; passare da stub a reale richiede solo il flag. |
| 7 | `DEV_AUTH_ENABLED=true` -> app interamente utilizzabile | VERIFICATO | `auth_gate_dev_bypass_test.dart` (3 test verdi): cold start dritto nella shell; logout -> SignInScreen e "Login con Twitch" rientra con identita dev; `DEV_AUTH_START_SIGNED_OUT=true` parte dal sign-in. Stub con `meSource` per allineare l'utente via `me`; `.env.example` documenta `DEV_AUTH_START_SIGNED_OUT`. |

**Score:** 7/7

## Controlli specifici

| Punto | Esito |
| --- | --- |
| `main()` non attende `initialize()` prima di `runApp` (bootstrap da `AuthCubit.start()` dopo il primo frame, D-33) | OK |
| Refresh token solo in `flutter_secure_storage`; `shared_preferences` usato solo per il marker non segreto di primo avvio (wipe Keychain iOS) | OK |
| Nessuna chiave Twitch nell'app: `grep TWITCH_CLIENT lib .env.example` = 0 righe | OK |
| Refresh single-flight (`_refreshInFlight` Completer) + proattivo con timer + epoch anti-race | OK |
| WS policy: token corrente a ogni connect, 4401/4403 -> recovery e retry a 500 ms, backoff esponenziale max 60 s, `buildInitialPayload` non lancia mai | OK |
| Retry-once in `AuthAuthLink` (UNAUTHENTICATED / ServerException 401) e `AuthInterceptor` (401) | OK |
| Copy UI-SPEC: tutte le 7 stringhe presenti in lib (sign_in_screen, splash_screen, auth_cubit, logout_confirmation_dialog) | OK |
| Nessun bottone logout nelle schermate di gameplay (Phase 4 ne e proprietaria; assenza NON e un gap) | OK |
| Android: `INTERNET`, `allowBackup="false"`, `CallbackActivity` con scheme `klimmeck`, AGP 8.9.1 | OK |
| Contratto 11-11 vs `schema.gql` BE (`exchangeLoginTicket`, `refreshSession`, `logout`, `me`, `AuthSession`, campi `User`) | Nessun mismatch rilevato |
| Git: branch `feat/11-auth-session-bootstrap`; 56 commit da e1d7118, tutti con scope `phase-11`; 0 trailer Co-Authored-By; nessun branch remoto per la fase (nulla pushato) | OK |
| Modifica utente non committata su `auth_token_service_contract_test.dart`: presente in working tree, mai committata/ripristinata dalla fase (`git log` sul file vuoto) | OK |

## Copertura requisiti

| Requisito | Piani | Stato | Evidenza |
| --- | --- | --- | --- |
| AUTH-01 | 11-02/05/09/10/11 | SODDISFATTO (fake); device PENDING | login via browser + ticket S256 |
| AUTH-02 | 11-03/05/11 | SODDISFATTO | `SecureSessionStore`, nessun token Twitch |
| AUTH-03 | 11-05/10/11 | SODDISFATTO (fake) | bootstrap con rotazione refresh token |
| AUTH-04 | 11-06/08/09/10/11 | SODDISFATTO | logout atomico + reset client + shell keyed |
| AUTH-05 | 11-04/05/10/11 | SODDISFATTO (fake) | cambio utente senza bleed-through |
| AUTH-06 | 11-05/06/07/08/11 | SODDISFATTO | single-flight + retry-once REST/GraphQL/WS |
| AUTH-07 | 11-02/05/06/09/11 | SODDISFATTO | solo SESSION_EXPIRED/REVOKED -> sign-in con messaggio |
| DEV-AUTH-04 (emendato) | 11-04 | SODDISFATTO | stub simula login/logout |

Tutti i 7 ID AUTH sono dichiarati nei PLAN e presenti in REQUIREMENTS.md; nessun requisito orfano.
Nota: la tabella di tracciabilita in REQUIREMENTS.md (righe 201-202) riporta ancora "Pending" e le checkbox sono `[ ]`; aggiornamento di bookkeeping per l'orchestratore (non un gap di codice).

## Anti-pattern

Nessun blocker. Nessun TODO/stub nei file nuovi; i `catch (_)` sono best-effort intenzionali con log (`debugPrint`) e senza valori segreti.

## Gap

Nessuno.

## Riepilogo

Obiettivo raggiunto per quanto verificabile senza chiavi Twitch: implementazione reale completa e testata con fake, bypass dev interamente funzionante (criterio 7 coperto da test end-to-end), contratto pubblico invariato. Restano solo le verifiche umane su device reale (UAT D-28, checklist in BACKEND-NOTES.md §7) e la conformita visiva alla UI-SPEC; per questo lo stato e `human_needed`, non `gaps_found`.

---

_Verificato: 2026-10-06_
_Verificatore: Claude (gsd-verifier)_
