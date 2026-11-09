---
phase: 12-hardening
plan: 02
subsystem: bootstrap, auth composition
tags: [hardening, entry-points, dev-bypass, release]
requires: ["12-01"]
provides:
  - "lib/bootstrap/auth_composition.dart: typedef AuthComposition, typedef AuthCompositionFactory"
  - "lib/bootstrap/session_auth_composition.dart: AuthComposition buildSessionAuthComposition({required BackendAuthApi api, required Future<void> Function() onSessionTeardown})"
  - "lib/bootstrap/dev_auth_composition.dart: AuthComposition buildDevAuthComposition({...same params}) with fallback to the session factory"
  - "lib/bootstrap/app_bootstrap.dart: Future<void> bootstrapApp({required AuthCompositionFactory buildAuth})"
  - "lib/bootstrap/klimmeck_guide_app.dart: KlimmeckGuideApp + navigatorKey (moved from main.dart)"
  - "lib/main.dart production entry, lib/main_dev.dart dev entry (appFlavor assert)"
affects: [12-03, 12-04, 12-05, 12-06, 12-07, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "entry point = one line choosing the auth factory; shared composition module in lib/bootstrap/"
    - "source-purity tests reading lib files to pin the production graph"
key-files:
  created:
    - lib/bootstrap/auth_composition.dart
    - lib/bootstrap/session_auth_composition.dart
    - lib/bootstrap/dev_auth_composition.dart
    - lib/bootstrap/app_bootstrap.dart
    - lib/bootstrap/klimmeck_guide_app.dart
    - lib/main_dev.dart
    - test/bootstrap/auth_composition_test.dart
    - test/bootstrap/entry_points_test.dart
  modified:
    - lib/main.dart
    - lib/repository/services/auth/auth.dart
    - lib/config/env_config.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/services/graphql/graphql_client_holder.dart
    - lib/repository/services/rest/rest.dart
    - lib/repository/services/rest/rest_client_provider.dart
    - test/repository/services/push/push_boundaries_test.dart
decisions:
  - "lib/main.dart composes only buildSessionAuthComposition; the dev bypass is reachable only from lib/main_dev.dart through buildDevAuthComposition (D-01)"
  - "lib/main_dev.dart asserts appFlavor == 'dev' before loading .env (D-16); from now on it needs --flavor dev (flavors land in plan 03)"
  - "the auth barrel no longer re-exports dev_auth_token_service.dart, removed in the split commit (D-01, Pitfall 4)"
metrics:
  duration: "~20 min"
  completed: 2026-11-09
  tasks: 2
  files: 16
---

# Phase 12 Plan 02: Production and dev entry points over one bootstrap module Summary

`lib/main.dart` is now a five-line production entry point that boots `bootstrapApp(buildAuth: buildSessionAuthComposition)`; `lib/main_dev.dart` asserts the `dev` flavor, loads `.env`, installs it as runtime overrides and boots with `buildDevAuthComposition` (dev bypass only when `DEV_AUTH_ENABLED=true`, otherwise the real session); the shared composition, the auth typedefs/factories and the app widget live in `lib/bootstrap/`, and the auth barrel no longer re-exports the dev service.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Auth composition module (typedefs, session factory, dev factory with fallback) | 3142784 (test), 424423e (feat) |
| 2 | bootstrapApp, app widget moved, production main.dart, main_dev.dart, barrel cleaned, purity tests | 010293a (test), 2d27d75 (refactor) |

## Names and signatures created

- `lib/bootstrap/auth_composition.dart`: `typedef AuthComposition = ({AuthTokenService service, UnauthorizedRecovery? recovery, SessionTerminator terminator});` / `typedef AuthCompositionFactory = AuthComposition Function({required BackendAuthApi api, required Future<void> Function() onSessionTeardown});`
- `lib/bootstrap/session_auth_composition.dart`: `AuthComposition buildSessionAuthComposition({required BackendAuthApi api, required Future<void> Function() onSessionTeardown})` → `SessionAuthTokenService(api, SecureSessionStore(), const FlutterWebAuth2BrowserAuthenticator(), Uri.parse(EnvConfig.baseUrl), onSessionTeardown)` as service, recovery and terminator
- `lib/bootstrap/dev_auth_composition.dart`: `AuthComposition buildDevAuthComposition({...})` → `buildSessionAuthComposition(...)` when `!EnvConfig.devAuthEnabled`, else `(service: dev, recovery: null, terminator: dev)` with `DevAuthTokenService(meSource: api, onSessionTeardown: ...)`
- `lib/bootstrap/app_bootstrap.dart`: `Future<void> bootstrapApp({required AuthCompositionFactory buildAuth})` — `WidgetsFlutterBinding.ensureInitialized()`, `bootstrapPush()`, `GraphQlBackendAuthApi.forEndpoint(EnvConfig.graphqlHttpUrl)`, `buildAuth(api:, onSessionTeardown: () => graphQlHolder.reset())`, `GraphQLClientHolder`, `RestClient`, `SystemChrome` block, `runApp(KlimmeckGuideApp(...))`
- `lib/bootstrap/klimmeck_guide_app.dart`: `final GlobalKey<NavigatorState> navigatorKey`, `class KlimmeckGuideApp` + `_KlimmeckGuideAppState` verbatim except the three logs → `appLog('Error during Svg loading: ${e.runtimeType}')`, `appLog('Precached ${imagePaths.length} images')`, `appLog('Error during image preloading: ${e.runtimeType}')` (`catch (e)`, no stack)
- `lib/main.dart`: imports `bootstrap/app_bootstrap.dart` + `bootstrap/session_auth_composition.dart`; `Future<void> main() => bootstrapApp(buildAuth: buildSessionAuthComposition);`
- `lib/main_dev.dart`: `assert(appFlavor == 'dev', 'Run with --flavor dev'); WidgetsFlutterBinding.ensureInitialized(); await dotenv.load(fileName: '.env'); EnvConfig.installRuntimeOverrides(dotenv.env); await bootstrapApp(buildAuth: buildDevAuthComposition);`

## RED failures observed

- Task 1: `flutter test test/bootstrap/auth_composition_test.dart` failed to compile: `Undefined name 'buildSessionAuthComposition'` / `'buildDevAuthComposition'`, missing `lib/bootstrap/*.dart`.
- Task 2: `entry_points_test.dart` 4 of 5 red (`PathNotFoundException` on `lib/bootstrap/app_bootstrap.dart` and `lib/main_dev.dart`; barrel still exported the dev service; main.dart without `bootstrapApp`); `push_boundaries_test.dart` «Phase 5 surfaces never reach the prompt» red (`PathNotFoundException` on the new prompt-free files).
- Green at first run (guard, as the plan expected): «env_config no longer imports flutter_dotenv (D-01)» — plan 01 already removed the import.
- `SecureSessionStore()` constructs fine in the test VM (no platform channel at construction); no deviation needed.

## Verification

- `flutter test test/bootstrap/auth_composition_test.dart` → 4 tests, All tests passed
- `flutter test test/bootstrap test/repository/services test/screens/auth test/app test/config` → 656 tests, All tests passed (superset of the plan's `<verify>` and `<verification>`)
- Full `flutter test` → 3580 tests, All tests passed (01:26)
- `flutter analyze` → `50 issues found.` (all info, 0 error, 0 warning), gate OK after each code task; the first GREEN pass had 4 `unused_import` warnings in the moved widget file (push_bootstrap, graphql_client_holder, graphql_client_provider, session_store), removed before committing
- Acceptance greps: dev markers in `lib/main.dart`, `app_bootstrap.dart`, `klimmeck_guide_app.dart`, `session_auth_composition.dart`, `auth_composition.dart` = 0; `wc -l < lib/main.dart` = 5; `assert(appFlavor == 'dev'` = 1; `installRuntimeOverrides(dotenv.env)` in main_dev = 1; `buildAuth: buildDevAuthComposition` = 1; barrel `dev_auth_token_service.dart` = 0; `appLog(` in the widget file = 3, `debugPrint(` = 0; `D-01)` in auth_composition_test = 4, in entry_points_test = 4; `D-16)` = 1
- Direct log call sites outside `lib/utils/app_log.dart`: 57 → 54
- Formatted one by one: every created/touched Dart file; only `test/bootstrap/entry_points_test.dart` changed (fresh file), the rest were already clean.

## Deviations from Plan

- [Boy Scout, docs only] `lib/config/env_config.dart` doc of `devAuthEnabled` now says it is used by `buildDevAuthComposition` (entry `main_dev.dart`) instead of `main.dart` (mandated by the orchestrator brief; file outside `files_modified`).
- [Boy Scout, docs only] four doc comments that named `main.dart` as composition root now point to the bootstrap: `lib/repository/services/graphql/graphql.dart`, `graphql_client_holder.dart`, `lib/repository/services/rest/rest.dart`, `rest_client_provider.dart`.
- `klimmeck_guide_app.dart` imports `auth_token_service.dart` + `session_terminator.dart` directly instead of the barrel.
- Bookkeeping uses the orchestrator's `2/17` / `Plan: 2 of 17` instead of the plan's `02/17`.
- `requirements mark-complete` not run (forbidden by the brief: traceability belongs to 12-17).

## Notes

- From this plan on `lib/main_dev.dart` needs `--flavor dev` (the assert fires in debug otherwise); plan 03 adds the Android flavors. Nobody runs the app before the device UAT.

## Known Stubs

None.

## Threat surface

T-12-04 (production entry composes only the session factory; purity test), T-12-05 (barrel export removed in the split commit; barrel test), T-12-06 (`${e.runtimeType}` through `appLog` in the moved widget) mitigated as planned; T-12-07 accepted (flavor assert). No new surface.

## Self-Check: PASSED
