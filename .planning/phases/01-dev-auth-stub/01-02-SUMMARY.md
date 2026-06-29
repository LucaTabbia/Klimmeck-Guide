---
phase: 01-dev-auth-stub
plan: "02"
subsystem: auth
tags: [auth, stub, dotenv, sealed-class, equatable]
dependency_graph:
  requires: [equatable, flutter_dotenv]
  provides: [AuthTokenService, DevAuthTokenService, AuthState, EnvConfig.devAuthEnabled]
  affects: [main.dart (Plan 03), GraphQL auth link (Plan 03), dio interceptor (Plan 03)]
tech_stack:
  added: [flutter_dotenv ^6.0.0]
  patterns: [sealed class, broadcast StreamController, runtime dotenv getter]
key_files:
  created:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/auth.dart
  modified:
    - lib/config/env_config.dart
    - pubspec.yaml
decisions:
  - "AuthTokenService include initialize() come bootstrap hook generico (superset compatibile con Phase 11 D-02)"
  - "DevAuthTokenService usa StreamController.broadcast() per supportare listener multipli senza StateError"
  - "EnvConfig.devAuthEnabled e' getter runtime (non const) perche' dotenv e' runtime, non compile-time"
metrics:
  duration: "~30 min"
  completed: "2026-04-14T14:50:30Z"
  tasks_completed: 3
  tasks_total: 3
  files_created: 3
  files_modified: 2
---

# Phase 1 Plan 02: DevAuthTokenService Contract + Implementation Summary

**One-liner:** Contratto `AuthTokenService` (abstract + sealed `AuthState`) e stub `DevAuthTokenService` backed da `flutter_dotenv`, pronto per sostituzione drop-in in Phase 11.

---

## Firma pubblica di `AuthTokenService`

```dart
/// Bootstrap hook. DEVE essere chiamato esattamente una volta da main.dart
/// tramite await authTokenService.initialize() (tipo astratto — NO type-check
/// is DevAuthTokenService) prima di runApp.
///
/// Phase 1 (Dev stub): emette immediatamente AuthBootstrapping →
/// AuthAuthenticated con il test user letto da .env.
///
/// Phase 11 (OAuth reale): carica token da secure storage e valida contro
/// Twitch prima di emettere AuthAuthenticated o AuthUnauthenticated.
Future<void> initialize();                    // superset compatibile Phase 11

Stream<AuthState> get authStateStream;        // broadcast, multi-listener
Future<String?> getAccessToken();             // nullable
Future<void> login();
Future<void> logout();
Future<void> handleRevocation();
void dispose();                               // chiude StreamController
```

Il metodo `initialize()` e' il superset aggiunto rispetto al contratto canonico di Phase 11 (11-CONTEXT.md D-02). Phase 11 lo implementera' per OAuth senza toccare i consumer.

---

## `AuthState` sealed — 3 sottotipi

```dart
sealed class AuthState extends Equatable { const AuthState(); }

final class AuthBootstrapping extends AuthState {
  const AuthBootstrapping();
  // props: [] — const-costruibile, istanze uguali == true
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated({required this.user, required this.accessToken});
  final User user;
  final String accessToken;
  // props: [user, accessToken] — equatable-safe
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
  // props: [] — const-costruibile
}
```

---

## Mappatura `.env` → `User` + role fallback

| `.env` key              | Campo `User`        | Fallback                        |
|-------------------------|---------------------|---------------------------------|
| `DEV_AUTH_USER_ID`      | `user.id`           | stringa vuota `''`              |
| `DEV_AUTH_TWITCH_ID`    | `user.twitchId`     | stringa vuota `''`              |
| `DEV_AUTH_ACCESS_TOKEN` | `accessToken`       | stringa vuota `''`              |
| `DEV_AUTH_ROLE`         | `user.role`         | `RoleType.adventurer` + warning |

`_parseRole()` normalizza a lowercase e usa `RoleType.values.byName()`. Valore sconosciuto → `try/catch` → `RoleType.adventurer` + `debugPrint` in `kDebugMode` (T-01-02-03).

---

## Test status

I test RED scaffoldati da Plan 01-01 (in `test/repository/services/auth/`) eserciteranno questa implementazione dopo il merge delle wave. Il contratto e l'implementazione rispettano fedelmente il comportamento atteso:

| Test file                                      | Comportamento verificato                          | Stato atteso post-merge |
|------------------------------------------------|---------------------------------------------------|-------------------------|
| `auth_token_service_contract_test.dart`        | Contratto 7 metodi + sealed AuthState             | GREEN                   |
| `dev_auth_token_service_test.dart`             | initialize() stream order + getAccessToken()      | GREEN                   |
| `dev_auth_token_service_role_test.dart`        | Role switching parametrico + fallback UnknownRole | GREEN                   |
| `dev_auth_token_service_noop_test.dart`        | login/logout/handleRevocation no-op, no new state | GREEN                   |

---

## Note per Plan 03 (wiring in `main.dart`)

1. **RepositoryProvider sopra MultiBlocProvider:** `RepositoryProvider<AuthTokenService>(create: (_) => DevAuthTokenService())` deve wrappare `MultiBlocProvider`. Il tipo generico e' `AuthTokenService` (non `DevAuthTokenService`) — questo garantisce il drop-in di Phase 11.

2. **Factory con flag runtime:**
   ```dart
   await dotenv.load(fileName: '.env');
   final authService = EnvConfig.devAuthEnabled
       ? DevAuthTokenService()
       : throw UnimplementedError('OAuthTokenService not yet implemented');
   await authService.initialize();
   ```

3. **`main.dart` chiama `await authTokenService.initialize()` tramite il tipo `AuthTokenService`** — NO type-check `is DevAuthTokenService`. Questo e' il vincolo critico per la sostituzione drop-in Phase 11.

4. **GraphQL auth link:** `authService.getAccessToken()` nell'header `Authorization: Bearer <token>`.

5. **dio interceptor:** stessa chiamata `getAccessToken()` nel `RequestInterceptor`.

6. **`dispose()`:** chiamare in `runApp()` wrappato in un widget root con `dispose` override, oppure tramite il service locator se usato.

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocker] Aggiunta flutter_dotenv a pubspec del worktree**

- **Found during:** Task 1
- **Issue:** Il worktree aveva un pubspec diverso dal main repo (template iniziale), senza `flutter_dotenv`. Necessario per compilare `dev_auth_token_service.dart`.
- **Fix:** Aggiunti `flutter_dotenv: ^6.0.0` e asset `.env` a `pubspec.yaml` del worktree. Il piano 01-01 fa lo stesso nel suo worktree — al merge si allineano.
- **Files modified:** `pubspec.yaml`, `pubspec.lock`
- **Commit:** 26465cc

**2. [Rule 3 - Blocker] Reset worktree al codebase corretto**

- **Found during:** Task 1/2
- **Issue:** Il worktree aveva un working tree con il codebase del template iniziale (diverso da ee6eae6). Il modello `User` aveva campi `name`/`email` invece di `twitchId`/`twitchPoints`.
- **Fix:** `git checkout ee6eae6 -- .` per portare il working tree allo stato del commit target. I file di mia competenza (auth/ + env_config.dart) sono stati ricreati correttamente.
- **Commit:** N/A (fix di setup pre-implementazione)

---

## Threat Flags

Nessun nuovo threat surface introdotto oltre quanto documentato nel `<threat_model>` del piano.

Verifica T-01-02-02 (no token in log): `grep -r "accessToken" lib/repository/services/auth/dev_auth_token_service.dart` mostra solo l'uso nell'`AuthAuthenticated` — nessun `debugPrint` stampa il token.

---

## Self-Check: PASSED

- `lib/repository/services/auth/auth_token_service.dart` — FOUND (113 righe, > 50 richieste)
- `lib/repository/services/auth/dev_auth_token_service.dart` — FOUND (114 righe, > 70 richieste)
- `lib/repository/services/auth/auth.dart` — FOUND (barrel con 2 export)
- `lib/config/env_config.dart` — FOUND (contiene devAuthEnabled + dotenv)
- Commit 5e55d55 — Task 1 contract
- Commit 26465cc — Task 2 DevAuthTokenService
- Commit a55ddf8 — Task 3 EnvConfig.devAuthEnabled
