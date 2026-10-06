---
phase: 11-auth-session-bootstrap
plan: 07
subsystem: auth
tags: [graphql, dio, retry-once, unauthorized-recovery]
requires: [11-06]
provides:
  - AuthAuthLink retry-once on UNAUTHENTICATED / ServerException 401
  - AuthInterceptor retry-once on REST 401 (FormData cloned)
  - RestClient forwards recovery and its own Dio to the interceptor
  - MockUnauthorizedRecovery, FakeHttpClientAdapter test helpers
affects: [11-08, 11-10]
tech-stack:
  added: []
  patterns: [context-entry marker (AuthRetried), dio extra flag, optional-recovery additive params]
key-files:
  created:
    - test/helpers/fakes/fake_http_client_adapter.dart
  modified:
    - lib/repository/services/graphql/auth_link.dart
    - lib/repository/services/rest/auth_interceptor.dart
    - lib/repository/services/rest/rest_client_provider.dart
    - test/helpers/mocks.dart
    - test/network/graphql_auth_link_test.dart
    - test/network/auth_interceptor_test.dart
key-decisions:
  - "Requests sent without a token are never retried (link and interceptor)"
  - "AuthInterceptor stays a plain Interceptor (not Queued) to avoid deadlock on dio.fetch"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 07: Reactive retry in link and interceptor Summary

`AuthAuthLink` and `AuthInterceptor` now retry exactly once after an auth rejection through `UnauthorizedRecovery.recoverFromUnauthorized(rejectedToken:)`, invisibly to the caller; both stay additive (optional `recovery`) and keep Phase 1 behaviour without it.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | 9e34f8d | test(phase-11): add graphql auth link retry-once specs |
| T1 GREEN | 716d157 | feat(phase-11): retry graphql requests once after unauthenticated response |
| T2 RED | d40de46 | test(phase-11): add rest auth interceptor retry-once specs |
| T2 GREEN | 0ffb7af | feat(phase-11): retry rest requests once after 401 through unauthorized recovery |

## Results

- `flutter test`: 168 tests, all passed (baseline 153, +10 link specs net of 1 old, +6 interceptor specs net).
- `flutter analyze lib test`: 14 issues (baseline 14, no new). Touched files: No issues found.
- `dart format --output=none --set-exit-if-changed` on explicit touched files: exit 0.

## Deviations from Plan

**1. Interceptor skips retry when the failed request carried no Bearer token** (`rejectedToken == null`). Plan snippet did not check it; it enforces the "requests sent without a token are never retried" rule.

**2. Link: `canRetry` also requires a non-null token**, same reason. The link reuses a local `recovery`/`next` variable for null-promotion.

**3. RED of both tasks is a compile failure** (the new `recovery:`/`dio:` parameters did not exist yet), not an assertion failure.

**4. Minor:** the interceptor's debugPrint now prints only `runtimeType` (T-11-33); `_unauthenticatedCode`, `_retriedKey` etc. extracted as constants.

## Notes for 11-08 and later

- `lib/main.dart` and `graphql_client_provider.dart` still construct `RestClient(authTokenService:)` / `AuthAuthLink(authService:)` WITHOUT `recovery`: the retry is dormant until the composition root passes the real `SessionAuthTokenService` (it implements `UnauthorizedRecovery`). That wiring is outside this plan's `files_modified`; whoever wires the session service in `main.dart` must pass `recovery:` in both places (a dev stub must be passed as null).
- WS subscriptions are not covered here (11-08).

## Known Stubs

None.

## Self-Check: PASSED

All created/modified files exist; commits 9e34f8d, 716d157, 0ffb7af found in git log; `git status` shows only the user's pre-existing edit.
