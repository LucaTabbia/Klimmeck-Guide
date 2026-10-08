---
phase: 11-auth-session-bootstrap
plan: 06
subsystem: auth
tags: [session, logout, revocation, unauthorized-recovery, epoch-guard, fake_async]
requires: [11-05]
provides:
  - SessionAuthTokenService.recoverFromUnauthorized (reactive retry entry point, single-flight)
  - SessionAuthTokenService.handleRevocation (local teardown, sessionExpired)
  - SessionAuthTokenService.logout (atomic 5-step logout, best-effort backend with 4 s timeout)
  - MockSessionTeardownHook (test/helpers/mocks.dart)
affects: [11-07, 11-08, 11-10, 11-11]
tech-stack:
  added: []
  patterns: [best-effort step bounded by Future.timeout, epoch guard against zombie sessions]
key-files:
  created:
    - test/repository/services/auth/session_auth_token_service_revocation_test.dart
    - test/repository/services/auth/session_auth_token_service_logout_test.dart
  modified:
    - lib/repository/services/auth/session_auth_token_service.dart
    - test/helpers/mocks.dart
key-decisions:
  - "logout() runs its backend step and then calls _endSession(signedOut); _endSession keeps no notifyBackend flag"
  - "The 4 s timeout covers the whole backend step, including the D-36 refresh of an expired access token"
  - "recoverFromUnauthorized maps every refresh failure to null; only SessionRejected ends the session (inside the single-flight)"
requirements-completed: []
duration: ~15min
completed: 2026-10-06
---

# Phase 11 Plan 06: Session service logout, revocation and unauthorized recovery Summary

`SessionAuthTokenService` is now complete: `recoverFromUnauthorized` (reuses the single-flight and skips the refresh when the rejected token already rotated), `handleRevocation` (local teardown, `sessionExpired`, no backend call) and an atomic `logout` (best-effort backend `logout` with a 4 s timeout → teardown hook → storage clear → `AuthUnauthenticated(signedOut)`) that works offline. The epoch guard prevents an in-flight refresh from bringing back a closed session. No `UnimplementedError` is left.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | bf01c78 | test(phase-11): add unauthorized recovery and revocation specs |
| T1 GREEN | 42111c4 | feat(phase-11): add unauthorized recovery and explicit revocation to session service |
| T2 RED | b0d4469 | test(phase-11): add atomic logout teardown specs |
| T2 GREEN | cc79d77 | feat(phase-11): implement atomic logout with best-effort backend invalidation |
| T2 REFACTOR | e70a684 | refactor(phase-11): name the backend logout timeout step in session service |

## Results

- `flutter test`: 153 tests, all passed (baseline 133; +8 revocation, +12 logout).
- `flutter analyze lib test`: 14 issues (baseline 14, no new ones). Every touched file: No issues found.
- The 5 service spec files (bootstrap, refresh, login, revocation, logout: 55 tests) ran 5 times in a row: 5/5 green, 55/55 each time. All timing uses `fakeAsync`, with no real sleeps.
- `grep -c UnimplementedError lib/repository/services/auth/session_auth_token_service.dart` → 0. `grep -n "timeout(_logoutTimeout"` → 1 line. No `resetStore`/`store.reset`.
- Mutation checks (made by hand, then restored from a backup):
  - Removing the epoch guards in `_rotateSession` breaks 2 logout specs.
  - Running the teardown before the backend call breaks 5 logout specs.
  - Dropping the `current != rejectedToken` check breaks the "already rotated" recovery spec.
- `dart format --output=none --set-exit-if-changed` on the 4 touched Dart files (explicit paths): exit 0.

## Backend contract

`BACKEND-NOTES.md` does not exist yet, and `src/schema.gql` does not have `logout` yet. Backend `02-07-PLAN.md` defines `logout: Boolean!` as an authenticated mutation with no arguments, based on `@CurrentUser()`. It revokes the current `sid`, so the next `refreshSession` returns `SESSION_REVOKED`. The access JWT stays valid for up to 15 min (BE D-27). This matches `BackendAuthApi.logout(accessToken)` from 11-03. The app drops the JWT immediately (`getAccessToken()` → null).

## Deviations from Plan

**1. [Adapted to 11-05] `_endSession` has no `notifyBackend` flag**
- The plan's snippet passed `notifyBackend:` to `_endSession`. 11-05 removed that flag on purpose (CLAUDE.md does not allow behaviour-switching booleans). So `handleRevocation()` is `_endSession(sessionExpired)`. `logout()` is `_invalidateBackendSession().timeout(_logoutTimeout, …)` followed by `_endSession(signedOut)`. The behaviour and the D-12 order are the same.
- The plan put the backend step behind `_refreshToken != null`. I left that guard out: `getAccessToken()` already returns `null` when there is no session, so the call is skipped (there is a spec for this).

**2. [Rule 3 - Blocking] `MockSessionTeardownHook` added to `test/helpers/mocks.dart`**
- `verifyInOrder` needs a mock for the teardown hook. The suite's convention is that mocks live only in `mocks.dart`, so I added a small `SessionTeardownHook` interface and its mock there. This file is outside the plan's `files_modified`.

**3. `dispose()` needed no change**
- 11-05 already made `dispose()` set `_isDisposed`, run `_supersedeSession()` (epoch++, both timers cancelled, in-flight detached) and `_channel.close()`. The two dispose specs passed during RED as characterization tests.
- The "stream closes" spec runs in real async (`emitsInOrder([signedOut, emitsDone])`). Inside `fakeAsync`, the done event that `AuthStateChannel`'s `Stream.multi` forwards is not delivered by `flushMicrotasks`. I checked this in isolation: it works in real async. This is a quirk of the test harness, not of the product.

**4. Refactor step**
- `dart format` split the `.timeout(...)` call over several lines. I moved the timeout log into `_logLogoutTimeout()`, so the backend step is one readable line. This also matches the plan's `.timeout(_logoutTimeout` acceptance grep.

## Notes for 11-07 / 11-08 / 11-10

- **11-07 (link/interceptor/WS retry):** call `recoverFromUnauthorized(rejectedToken: <the token sent with the failed request>)`, retry once with the returned token, and give up on `null`. `null` covers both a transient failure (session kept; the next request tries again) and a rejected session (already torn down; `AuthUnauthenticated(sessionExpired)` already emitted). The caller must NOT call `handleRevocation()` after a `null`. Use `handleRevocation()` only for an explicit revocation signal.
- If `logout()` runs while a refresh is pending (cold start in retry, or an expired access token), it joins that refresh, which is bounded by the 4 s timeout. The late result is then dropped by the epoch guard (there is a spec for this).
- If the refresh inside `logout()` returns `SessionRejected`, `_endSession(sessionExpired)` runs inside the refresh, and then `logout()` runs `_endSession(signedOut)`. The teardown hook is called twice, and the stream emits `sessionExpired` and then `signedOut`. The final state is correct (`signedOut`). In 11-10, `GraphQLClientHolder.reset()` must therefore be idempotent. This edge case has no spec.
- `onSessionTeardown` is where 11-08/11-10 plug in `GraphQLClientHolder.reset()` (closes the WS and all subscriptions, recreates client and link). Gameplay Cubits close their own subscriptions when the authenticated shell is removed.

## Known Stubs

None. The service has no `UnimplementedError` left.

## Threat Flags

None. No new surface beyond the plan's threat model (T-11-26..T-11-30 mitigated and covered by specs).

## Self-Check: PASSED

- Files found: `session_auth_token_service.dart`, `session_auth_token_service_revocation_test.dart`, `session_auth_token_service_logout_test.dart`, `test/helpers/mocks.dart`.
- Commits found: bf01c78, 42111c4, b0d4469, cc79d77, e70a684.
