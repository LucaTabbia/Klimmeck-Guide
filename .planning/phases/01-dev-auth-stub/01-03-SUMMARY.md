---
phase: 01-dev-auth-stub
plan: "03"
subsystem: auth
tags: [auth, wiring, dio, graphql, repository-provider, dependency-injection]
dependency_graph:
  requires: [AuthTokenService, DevAuthTokenService, EnvConfig.devAuthEnabled, flutter_dotenv]
  provides: [AuthInterceptor, AuthAuthLink, initGraphQLClient(AuthTokenService), RepositoryProvider<AuthTokenService>]
  affects: [main.dart, RestClient, KlimmeckRest, GraphQLClient, WebSocketLink]
tech_stack:
  added: [gql_exec, gql_link, gql_http_link, gql]
  patterns: [RepositoryProvider DI, Dio Interceptor, gql_link Link extension, async GraphQL client init]
key_files:
  created:
    - lib/repository/services/rest/auth_interceptor.dart
    - lib/repository/services/graphql/auth_link.dart
  modified:
    - lib/main.dart
    - lib/repository/services/rest/rest_client_provider.dart
    - lib/repository/services/rest/rest.dart
    - lib/repository/services/graphql/graphql_client_provider.dart
    - test/widget_test.dart
    - pubspec.yaml
decisions:
  - "AuthAuthLink è una classe (estende Link) non una funzione factory — allineato al contratto del test scaffoldato"
  - "gql_exec/gql_link/gql_http_link/gql aggiunti come dependencies esplicite (transitivi di graphql_flutter ma referenziati direttamente nel codice prod)"
  - "RepositoryProvider.dispose ha firma void Function(T) in flutter_bloc 9.1.1 (non void Function(BuildContext, T))"
  - "widget_test.dart aggiornato: il test counter del template è incompatibile con l'app reale, sostituito con placeholder"
  - "KlimmeckRest istanziato in initState() di _KlimmeckGuideAppState per accedere a widget.restClient"
metrics:
  duration: "~90 min"
  completed: "2026-04-14T16:12:12Z"
  tasks_completed: 4
  tasks_total: 4
  files_created: 2
  files_modified: 6
---

# Phase 1 Plan 03: Wiring AuthTokenService — dio + GraphQL + main.dart Summary

**One-liner:** Wiring completo di `AuthTokenService` nell'albero app: `RepositoryProvider`, `AuthInterceptor` su Dio, `AuthAuthLink` su GraphQL, `initGraphQLClient` async con token bootstrap.

---

## Cosa è stato implementato

### `AuthInterceptor` (Task 1)

`lib/repository/services/rest/auth_interceptor.dart` — Dio `Interceptor` che legge `AuthTokenService.getAccessToken()` in `onRequest` e aggiunge `Authorization: Bearer <token>` se il token è non-null/non-empty. Fail-open: eccezione nel fetch → request procede senza header, `debugPrint` in `kDebugMode`.

### `RestClient` refactor (Task 1)

Singleton `_instance` e `factory RestClient()` rimossi. Il client è ora costruito con `RestClient({required AuthTokenService authTokenService})` e aggiunge `AuthInterceptor` alla catena Dio. `KlimmeckRest` riceve `RestClient` via costruttore DI.

### `AuthAuthLink` (Task 2)

`lib/repository/services/graphql/auth_link.dart` — estende `Link` di `gql_link`. Aggiunge `Authorization: Bearer <token>` al context `HttpLinkHeaders` di ogni request HTTP GraphQL. Fail-open su eccezione `getAccessToken()`.

### `initGraphQLClient` refactor (Task 2)

Firma cambiata da `ValueNotifier<GraphQLClient>` a `Future<ValueNotifier<GraphQLClient>>` con parametro `AuthTokenService`. Il `WebSocketLink.initialPayload` porta il token letto una volta al boot (Phase 1 static — Phase 11 ricrea il link on-demand per il refresh, D-07 CONTEXT.md).

### `main.dart` wiring (Task 3)

```dart
await dotenv.load(fileName: '.env');
final AuthTokenService authTokenService = _buildAuthTokenService();
await authTokenService.initialize(); // polimorfico, no type-check
final restClient = RestClient(authTokenService: authTokenService);
final graphQlClient = await initGraphQLClient(authTokenService);
runApp(KlimmeckGuideApp(authTokenService: authTokenService, ...));
```

`RepositoryProvider<AuthTokenService>` è l'antenato più esterno del tree, con `dispose: (svc) => svc.dispose()`.

---

## Firma pubblica delle nuove API

```dart
// Dio interceptor
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required AuthTokenService authService});
}

// GraphQL link
class AuthAuthLink extends Link {
  AuthAuthLink({required AuthTokenService authService});
}

// GraphQL client builder
Future<ValueNotifier<GraphQLClient>> initGraphQLClient(
  AuthTokenService authTokenService,
);
```

---

## Test status

| Test file | Comportamento verificato | Stato |
|-----------|--------------------------|-------|
| `test/app/app_wiring_test.dart` | `context.read<AuthTokenService>()` risolve senza ProviderNotFoundException | GREEN |
| `test/network/auth_interceptor_test.dart` | Header Authorization presente/assente correttamente | GREEN |
| `test/network/graphql_auth_link_test.dart` | HttpLinkHeaders porta Bearer token | GREEN |
| `test/repository/services/auth/*` (15 test) | Contract + DevAuth behavior (Wave 1) | GREEN |
| `test/widget_test.dart` | Placeholder (template counter rimosso) | GREEN |

**Totale: 20/20 GREEN**

---

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Import mancanti nel test scaffoldato `graphql_auth_link_test.dart`**

- **Found during:** Task 2 (GREEN phase)
- **Issue:** Il test RED scaffoldato in Wave 0 usava `Request`, `Operation`, `Response` da `gql_exec` senza importarlo. Anche `Response(data: {}, errors: null)` usava l'API vecchia — la versione `gql_exec 1.1.1-alpha` richiede `Response(response: {...})`.
- **Fix:** Aggiunto `import 'package:gql_exec/gql_exec.dart'`; rimosso `gql_http_link` (unnecessary); corretta chiamata `Response(response: {'data': null})`.
- **Files modified:** `test/network/graphql_auth_link_test.dart`
- **Commit:** `37507b4`

**2. [Rule 3 - Blocker] `AuthAuthLink` deve essere classe, non funzione factory**

- **Found during:** Task 2
- **Issue:** Il piano descriveva una funzione `buildAuthLink(AuthTokenService)` ma il test usa `AuthAuthLink(authService: mockService)` come classe. Il piano conteneva questa nota: "verificare il nome preciso del factory". Il test scaffoldato è la fonte di verità.
- **Fix:** Implementato come `class AuthAuthLink extends Link` con constructor named parameter `authService`.
- **Files modified:** `lib/repository/services/graphql/auth_link.dart`
- **Commit:** `37507b4`

**3. [Rule 1 - Bug] `RepositoryProvider.dispose` firma errata**

- **Found during:** Task 3 (flutter analyze)
- **Issue:** Il piano indicava `dispose: (_, svc) => svc.dispose()` (firma `BuildContext, T`) ma in flutter_bloc 9.1.1 la firma è `void Function(T)?` (solo il service, no context).
- **Fix:** Cambiato in `dispose: (svc) => svc.dispose()`.
- **Files modified:** `lib/main.dart`
- **Commit:** `85e414b`

**4. [Rule 1 - Bug] `widget_test.dart` usa API pre-refactor**

- **Found during:** Task 4 (full-suite test)
- **Issue:** Il test di default del template Flutter chiamava `initGraphQLClient()` senza argomenti e `KlimmeckGuideApp(client: client)` con il vecchio costruttore — entrambi incompatibili con il refactor DI.
- **Fix:** Sostituito con placeholder test (il template counter non era mai stato rilevante per l'app reale).
- **Files modified:** `test/widget_test.dart`
- **Commit:** `bde8093`

**5. [Rule 3 - Blocker] gql_exec/gql_link/gql_http_link/gql come dependencies esplicite**

- **Found during:** Task 2 (flutter analyze `depend_on_referenced_packages`)
- **Issue:** `auth_link.dart` importa direttamente `gql_exec` e `gql_link` che sono transitivi ma non dichiarati. `flutter analyze` segnala `depend_on_referenced_packages`.
- **Fix:** Aggiunti a `dependencies:` in `pubspec.yaml` con version `any` (pin alla transitiva di `graphql_flutter`).
- **Files modified:** `pubspec.yaml`
- **Commit:** `bde8093`

**6. [Rule 3 - Blocker] File `.env` mancante nel worktree**

- **Found during:** Task 1 (primo `flutter test`)
- **Issue:** Il worktree non aveva il `.env` dichiarato in `pubspec.yaml` come asset. Flutter build falliva con `No file or variants found for asset: .env`.
- **Fix:** Creato `.env` locale con valori placeholder (non committato — correttamente in `.gitignore`).
- **Commit:** N/A (file locale non versionato)

---

## Threat Flags

Verifica T-01-03-01 (token non leakato in log):
- `AuthInterceptor`: nessun `debugPrint` interpola il token — solo `$e` sull'eccezione, non il token stesso.
- `AuthAuthLink`: nessun log del token.

Nessun nuovo threat surface introdotto oltre al `<threat_model>` del piano.

---

## Self-Check: PASSED

- `lib/repository/services/rest/auth_interceptor.dart` — FOUND
- `lib/repository/services/graphql/auth_link.dart` — FOUND
- `lib/main.dart` — contiene `RepositoryProvider<AuthTokenService>`, `dotenv.load`, `authTokenService.initialize()`, `EnvConfig.devAuthEnabled`, NO `is DevAuthTokenService`
- `lib/repository/services/rest/rest_client_provider.dart` — singleton RIMOSSO (grep negativo verificato)
- Commit `eca5a70` — Task 1 AuthInterceptor + RestClient DI
- Commit `37507b4` — Task 2 AuthAuthLink + GraphQL client
- Commit `85e414b` — Task 3 main.dart wiring
- Commit `bde8093` — Task 4 full-suite + format
- `flutter test`: 20/20 GREEN
- `flutter analyze lib/ test/`: 0 nuovi issue introdotti
