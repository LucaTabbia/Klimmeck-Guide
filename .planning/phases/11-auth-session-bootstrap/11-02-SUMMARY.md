---
phase: 11-auth-session-bootstrap
plan: 02
subsystem: auth
tags: [s256, deep-link, jwt-lifetime, flutter_web_auth_2, auth-state]
requires: [11-01]
provides:
  - AuthSession model, LoginChallenge (S256), accessTokenLifetime/refreshDelayFor
  - parseLoginCallback (sealed LoginCallback), LoginException, BrowserAuthenticator wrapper
  - AuthUnauthenticated.reason (additive), UnauthorizedRecovery, AuthStateChannel
affects: [11-03, 11-04, 11-05, 11-06, 11-07, 11-08, 11-09, 11-10]
key-files:
  created:
    - lib/models/auth/auth_session.dart
    - lib/models/auth/login_challenge.dart
    - lib/repository/services/auth/access_token_lifetime.dart
    - lib/repository/services/auth/login_callback.dart
    - lib/repository/services/auth/login_exception.dart
    - lib/repository/services/auth/browser_authenticator.dart
    - lib/repository/services/auth/unauthorized_recovery.dart
    - lib/repository/services/auth/auth_state_channel.dart
    - test/helpers/auth_session_fixtures.dart
  modified:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/auth.dart
    - test/helpers/mocks.dart
key-decisions:
  - "Contract change is additive only: AuthUnauthenticated(reason) defaults to signedOut; the 7 AuthTokenService signatures are untouched"
  - "DevAuthTokenService now composes AuthStateChannel; behavior unchanged"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 02: Auth domain primitives Summary

Pure, TDD-built auth primitives: S256 login challenge (RFC 7636 vector verified), JWT lifetime based refresh delay with 30 s floor, total deep link parser, injectable system-browser wrapper, additive `AuthUnauthenticated.reason`, `UnauthorizedRecovery` and a shared replaying `AuthStateChannel`.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | afd8fb8 | test(phase-11): add auth session, s256 challenge and jwt lifetime specs |
| T1 GREEN | 9297917 | feat(phase-11): add auth session model, s256 login challenge and jwt lifetime |
| T2 RED | 489be30 | test(phase-11): add login callback parsing and browser error mapping specs |
| T2 GREEN | 6187be4 | feat(phase-11): add login callback parser, login exceptions and browser authenticator |
| T3 RED | 10e39f2 | test(phase-11): add unauthenticated reason and auth state channel specs |
| T3 GREEN | af7fb7e | feat(phase-11): add unauthenticated reason, unauthorized recovery and shared auth state channel |

## Results

- `flutter test`: 57 tests, all passed (baseline 21).
- `flutter analyze lib test`: 14 issues (baseline 14, no new); all touched files "No issues found".
- `dart format --output=none --set-exit-if-changed` on explicit touched files: exit 0.
- `git status`: only the user's own modification of `auth_token_service_contract_test.dart` remains outside the plan.

## Deviations from Plan

- Backend `BACKEND-NOTES.md` for phase 02 does not exist yet and `src/schema.gql` has no `AuthSession` type yet: shape (`accessToken`, `accessTokenExpiresAt`, `refreshToken`, `user`) and deep link params (`ticket`, `error`) follow the plan and 02-RESEARCH.md. Re-check against BACKEND-NOTES.md/schema.gql when the backend lands (11-03+).
- RED commit for Task 2/3 included only the test files; mocks.dart change went in the GREEN commit (needs the production type to compile).
- Minor: `LoginTicketReceived.toString()` returns a fixed string (T-11-07).
- No other deviations.

## Notes for next plans

- `lib/repository/services/auth/auth.dart` barrel now exports all new services/primitives (not the models).
- Test fixtures: `buildTestJwt`, `buildAuthSession`, `authSessionJson`, `testNow` in `test/helpers/auth_session_fixtures.dart`; `MockBrowserAuthenticator` in `test/helpers/mocks.dart`.
- Constant `twitchNotConfiguredError` exported from `login_callback.dart` for mapping to `LoginUnavailableException`.
- `FlutterWebAuth2BrowserAuthenticator` has no unit test (platform channel; covered by pending UAT D-28).

## Known Stubs

None.

## Self-Check: PASSED

- All created files FOUND; commits afd8fb8, 9297917, 489be30, 6187be4, 10e39f2, af7fb7e FOUND.
