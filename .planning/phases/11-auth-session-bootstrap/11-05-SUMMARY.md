---
phase: 11-auth-session-bootstrap
plan: 05
subsystem: auth
tags: [session, single-flight, refresh-rotation, backoff, login, s256, fake_async]
requires: [11-02, 11-03, 11-04]
provides:
  - exponentialBackoff pure helper (lib/utils/backoff.dart)
  - SessionAuthTokenService (cold start, single-flight refresh, proactive scheduling, revocation on refresh, backend-mediated login)
affects: [11-06, 11-07, 11-10, 11-11]
tech-stack:
  added: []
  patterns: [single-flight Completer<String>, epoch guard, persist-before-forget, background bootstrap retry]
key-files:
  created:
    - lib/utils/backoff.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - test/utils/backoff_test.dart
    - test/repository/services/auth/session_auth_token_service_bootstrap_test.dart
    - test/repository/services/auth/session_auth_token_service_refresh_test.dart
    - test/repository/services/auth/session_auth_token_service_login_test.dart
  modified:
    - lib/repository/services/auth/auth.dart
key-decisions:
  - "initialize() returns after the local storage read; the backend resolve and its retries run in the background (never waits on the network)"
  - "Only SessionRejected ends the session; every other refresh failure keeps storage and retries with capped backoff"
  - "login() replaces the previous session only after a successful ticket exchange"
  - "A stale (superseded) refresh outcome, including a stale SessionRejected, never touches storage, memory or state"
  - "_endSession has no notifyBackend flag: logout() in 11-06 adds its own best-effort backend step"
requirements-completed: []
duration: ~12min
completed: 2026-10-06
---

# Phase 11 Plan 05: Session auth token service (bootstrap, refresh, login) Summary

Real `SessionAuthTokenService`: background cold-start resolve with capped retries, single-flight refresh with persist-before-forget rotation and epoch guard, skew-robust proactive refresh, revocation only on `SessionRejected`, and backend-mediated Twitch login via `auth/twitch/start?challenge=<S256>` with ticket redemption. All built TDD with fakes.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | a1e3ded | test(phase-11): add session bootstrap and single-flight refresh specs |
| T1 GREEN | ef6e6e6 | feat(phase-11): add session auth token service bootstrap and single-flight refresh |
| T2 RED | c5aaed7 | test(phase-11): add backend-mediated login specs |
| T2 GREEN | 4fc2489 | feat(phase-11): implement backend-mediated twitch login with s256 ticket redemption |

## Results

- `flutter test`: 133 tests, all passed (baseline 93; +5 backoff, +8 bootstrap, +10 refresh, +17 login).
- `flutter analyze lib test`: 14 issues (baseline 14, no new). All touched files: No issues found.
- Service specs (bootstrap + refresh + login, 35 tests) run 5 times in a row: 5/5 green, every run 35/35. All timing is `fakeAsync`-driven, so the concurrency cases are deterministic.
- Mutation checks (made by hand, then reverted): removing the single-flight reuse breaks the concurrent-callers test; removing the storage write breaks the bootstrap persistence tests; invalidating the session at the start of `login()` breaks the 3 "login while a saved session is in retry" tests.
- `dart format --output=none --set-exit-if-changed` on the 7 touched Dart files (explicit paths): exit 0.
- Only the user's own `auth_token_service_contract_test.dart` is still modified.

## Backend contract sources

`BACKEND-NOTES.md` still does not exist. I checked the start URL and query parameter against backend `02-05-PLAN.md` (`GET /auth/twitch/start?challenge=<S256>`, `@Query('challenge')`) and `02-06-PLAN.md` (`twitch_not_configured` redirect). The callback shape is `klimmeck://auth?ticket=…|error=…` (unchanged from 11-02).

## Deviations from Plan

**1. [Rule 2 - Correctness] `initialize()` does not wait for the first network attempt**
- The plan said "initialize() returns after the first attempt". The phase rule says `initialize()` must not need the network to return. Now `initialize()` emits `AuthBootstrapping`, reads the storage and starts the resolve with `unawaited`. The spec checks this with a `refreshSession` that never completes: `initialize()` still completes.

**2. [Rule 1 - Correctness] Stale outcomes are always "superseded"**
- A `SessionRejected` from a session that was already replaced (epoch changed) now completes with the private `_SessionSuperseded` instead of the rejection. Callers of `getAccessToken()` then get the current session's token, not `null`.
- After the storage write there is a second epoch check, so a logout during the write cannot bring the old session back into memory.

**3. [Rule 1 - Correctness] Identity guard on the in-flight completer**
- `finally` clears `_refreshInFlight` only if it is still the same completer. `_supersedeSession()` (used by login, `_endSession` and dispose) detaches the in-flight completer. The result: after a login, a forced refresh never joins the old session's flight. 11-06 `recoverFromUnauthorized` relies on this.

**4. [CLAUDE.md - no behaviour-switching booleans] `_endSession(reason)` has no `notifyBackend` flag**
- Its only caller in this plan is the refresh revocation. 11-06 `logout()` should do its best-effort backend step (D-13/D-36) and then call `_endSession(UnauthenticatedReason.signedOut)`. Do not add a flag.
- Order inside `_endSession`: epoch++ / timers off / in-flight detached → memory forgotten (D-13: discard the JWT immediately) → teardown hook → `store.clear()` → emit.

**5. Identity re-emission lives in the refresh path**
- `_applySession` only updates memory and scheduling. The refresh path re-emits `AuthAuthenticated` only when `user.id` changes. Login always emits once. This avoids a double emission on account switch. There is an extra spec for the "user id changed" re-emission.

**6. Test helper fix inside the T2 GREEN commit**
- `runLogin` in the login spec used `.then(...)` without `<void>`, so `onError` had the wrong return type at runtime. I typed it `.then<void>`. Only the test harness changed, not the behaviour under test.

## Notes for 11-06

- The three remaining stubs are exactly `logout()`, `handleRevocation()` and `recoverFromUnauthorized()` (`UnimplementedError('11-06')`). `_logoutTimeout` is stored with `// ignore: unused_field` until `logout()` uses it: remove that ignore in 11-06.
- Reusable private building blocks:
  - `_refreshSingleFlight()`: needs `_refreshToken != null`.
  - `_endSession(reason)`
  - `_supersedeSession()`
  - `_forgetSession()`
  - `_persistRefreshToken()`
  - `_hasFreshAccessToken`
  - `_accessToken`, `_epoch`, `_isDisposed`
- `handleRevocation()` is basically `_endSession(UnauthenticatedReason.sessionExpired)`.
- `recoverFromUnauthorized({rejectedToken})`: if `_accessToken != rejectedToken` return it; else forced `_refreshSingleFlight()` with the same `SessionRejected` → `null` / transient → `null` mapping that you decide. `getAccessToken()` returns the previous token on transient errors.
- `getAccessToken()` past `_refreshAt` calls the network on every invocation while the backend is unreachable. Single-flight bounds concurrency but not frequency. That is acceptable, but keep it in mind for the reactive retry-once paths (11-07).
- Login maps unexpected `AuthApiException` subtypes from `exchangeLoginTicket` to `LoginFailedException(<runtimeType>)`.

## Known Stubs

- `logout()`, `handleRevocation()`, `recoverFromUnauthorized()` throw `UnimplementedError('11-06')`. This is intentional per plan; 11-06 implements them and checks that they are gone.

## Self-Check: PASSED

- Files found: `lib/utils/backoff.dart`, `lib/repository/services/auth/session_auth_token_service.dart`, `test/utils/backoff_test.dart`, `test/repository/services/auth/session_auth_token_service_{bootstrap,refresh,login}_test.dart`.
- Commits found: a1e3ded, ef6e6e6, c5aaed7, 4fc2489.
