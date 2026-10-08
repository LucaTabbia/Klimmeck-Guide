---
phase: 11-auth-session-bootstrap
plan: 04
subsystem: auth
tags: [dev-bypass, dev-auth-stub, me-alignment]
requires: [11-02, 11-03]
provides:
  - DevAuthTokenService with login/logout/revocation transitions (no browser)
  - DEV_AUTH_START_SIGNED_OUT start-signed-out flag
  - Best-effort `me` alignment (3 s timeout, .env fallback)
  - loadTestEnv(startSignedOut:) fixture parameter
affects: [11-05, 11-06, 11-07, 11-11]
key-files:
  created:
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
  modified:
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/config/env_config.dart
    - test/helpers/fixtures/dev_auth_env.dart
    - test/repository/services/auth/dev_auth_token_service_test.dart
  deleted:
    - test/repository/services/auth/dev_auth_token_service_noop_test.dart
key-decisions:
  - "Constructor: DevAuthTokenService({meSource, onSessionTeardown, meTimeout = 3s}); no-arg form still works"
  - "No kReleaseMode guard (D-30); loud debugPrint warning always emitted at initialize()"
  - "Logs never include the token; only error runtimeType"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 04: Dev auth bypass transitions Summary

The dev stub is no longer a no-op: it simulates cold start, logout, login and revocation, aligns the user with the backend `me` (best-effort, `.env` fallback) and can start signed out via `DEV_AUTH_START_SIGNED_OUT=true`.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | a2800fd | test(phase-11): replace dev stub no-op spec with login and logout transitions |
| T1 GREEN | afcd4e4 | feat(phase-11): simulate login and logout transitions in dev auth stub |
| T2 RED | 15df281 | test(phase-11): add dev stub me alignment specs |
| T2 GREEN | f044646 | feat(phase-11): align dev stub identity with backend me query |

## Results

- `flutter test`: 93 tests, all passed (baseline 81).
- `flutter analyze lib test`: 14 issues (baseline 14, no new).
- `dart format --output=none --set-exit-if-changed` on the 5 touched files: exit 0.
- Only the user's `auth_token_service_contract_test.dart` remains modified.

## Deviations from Plan

None. Notes:
- T1 RED failed at compile time (the `onSessionTeardown` constructor parameter does not exist yet), which is the plan's "needs a production type" case. T2 RED failed on real assertions (2 failing: me success, login re-align).
- The `me` timeout/fetch path is ready to be wired by passing a `GraphQlBackendAuthApi` as `meSource` in `main.dart` (later plan); this plan does not touch `main.dart`.

## Notes for next plans

- Wire `DevAuthTokenService(meSource: GraphQlBackendAuthApi.forEndpoint(...), onSessionTeardown: ...)` at composition time.
- The backend `me` contract was not re-verified here beyond the 11-03 `BackendMeSource` interface.

## Known Stubs

None.

## Self-Check: PASSED

- Files present: transitions test, modified lib files; noop test removed.
- Commits a2800fd, afcd4e4, 15df281, f044646 exist.
