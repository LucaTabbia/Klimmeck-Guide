---
phase: 12-hardening
plan: 14
subsystem: auth
tags: [hardening, session, revocation, sign-in, notices, be-phase-17]
requires: ["12-13"]
provides:
  - "SessionRejected(code, {reason}) with props [code, reason]; reason parsed leniently from extensions.reason of the SAME coded error, only for SESSION_REVOKED"
  - "constants sessionRevokedReasonNewLogin = 'newLogin', sessionRevokedReasonRoleChanged = 'roleChanged'"
  - "UnauthenticatedReason.replacedByNewLogin / .roleChanged; SignInNotice.replacedByNewLogin / .roleChanged with the fixed copy"
  - "SessionAuthTokenService._rotateSession ends a refused session with _unauthenticatedReasonOf(error) on the reactive, proactive and cold-start paths"
affects: [12-15, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "The FE labels a BE revocation, never decides it: unknown or missing reason = neutral notice"
key-files:
  created:
    - .planning/phases/12-hardening/12-14-SUMMARY.md
  modified:
    - lib/repository/services/auth/auth_api_exception.dart
    - test/repository/services/auth/graphql_backend_auth_api_test.dart
    - lib/repository/services/auth/auth_token_service.dart
    - lib/screens/auth/auth_gate.dart
    - test/screens/auth/auth_gate_test.dart
    - lib/screens/signIn/sign_in_screen.dart
    - test/screens/signIn/sign_in_screen_test.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - test/repository/services/auth/session_auth_token_service_revocation_test.dart
decisions:
  - "D-12: only newLogin and roleChanged get a dedicated notice; reuseDetected, userLogout, any other string, a missing reason and SESSION_EXPIRED keep «La sessione è scaduta, accedi di nuovo.»"
  - "D-12: handleRevocation() stays sessionExpired; the logout-only refresh (_backendLogoutToken) ignores the reason and the logout ends signedOut"
metrics:
  duration: "~8 min"
  completed: 2026-11-09
---

# Phase 12 Plan 14: Revocation reason end to end on the client Summary

A refused refresh `SESSION_REVOKED` + `extensions.reason` now becomes `SessionRejected(sessionRevokedCode, reason: …)`, `SessionAuthTokenService` ends the session with `replacedByNewLogin` / `roleChanged` / `sessionExpired` on every refresh path, and the sign-in screen shows «Hai effettuato l'accesso da un altro dispositivo.» or «Il tuo ruolo è cambiato, accedi di nuovo.»; names proven on fakes; plan 16 proves them on the merged BE.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | eae127f | test(auth): expect the revocation reason on SessionRejected |
| 1 GREEN | 2a0bf72 | feat(auth): parse the revocation reason of SESSION_REVOKED |
| 2 RED | 01bcd52 | test(auth): expect notices for a new login and a role change |
| 2 GREEN | 9ac4da1 | feat(auth): show dedicated notices for a new login and a role change |
| 3 RED | 5559757 | test(auth): expect the revocation reason to drive the sign-out reason |
| 3 GREEN | c9ba7c8 | feat(auth): end a revoked session with the reason the backend gave |
| 2 follow-up | 15ffb2f | refactor(auth): spell the new-login notice without an escaped quote |

## What was built

- `lib/repository/services/auth/auth_api_exception.dart`: `const String sessionRevokedReasonNewLogin = 'newLogin';`, `const String sessionRevokedReasonRoleChanged = 'roleChanged';`; `SessionRejected(this.code, {this.reason})`, `final String? reason;`, `props => [code, reason]`; `mapAuthOperationException` uses `GraphQLError? _firstCodedError(List<GraphQLError>)` (first error whose `extensions['code']` is a `String`) and `String? _revokeReasonOf(GraphQLError)` (non-empty `String` or null); arms `sessionExpiredCode => const SessionRejected(sessionExpiredCode)`, `sessionRevokedCode => SessionRejected(sessionRevokedCode, reason: _revokeReasonOf(error!))`. The 401 → `AccessTokenRejected` and link → `TransientAuthFailure('network')` branches are unchanged (T-12-41).
- `lib/repository/services/auth/auth_token_service.dart`: `enum UnauthenticatedReason { signedOut, sessionExpired, replacedByNewLogin, roleChanged, syncLost }`.
- `lib/screens/signIn/sign_in_screen.dart`: `enum SignInNotice { none, sessionExpired, connectionLost, replacedByNewLogin, roleChanged }`; private constants `_replacedByNewLoginNotice` (double-quoted literal) and `_roleChangedNotice`; two `_noticeText` arms.
- `lib/screens/auth/auth_gate.dart`: `_noticeFor` arms `replacedByNewLogin => SignInNotice.replacedByNewLogin`, `roleChanged => SignInNotice.roleChanged`.
- `lib/repository/services/auth/session_auth_token_service.dart`: `static UnauthenticatedReason _unauthenticatedReasonOf(SessionRejected rejection)` (switch on `rejection.reason`: newLogin → replacedByNewLogin, roleChanged → roleChanged, `_` → sessionExpired); `_rotateSession` calls `_endSession(_unauthenticatedReasonOf(error))`. Verified by reading: `_attemptBootstrap` and `_runProactiveRefresh` reach `_rotateSession` through `_refreshSingleFlight`; `_backendLogoutToken` calls `_api.refreshSession` directly and swallows `SessionRejected` (returns null), so the logout always ends `signedOut`.

## RED evidence

- Task 1: compile failure on `reason:` (`Found this candidate, but the arguments don't match. const SessionRejected(this.code);`).
- Task 2: compile failure `Member not found: 'replacedByNewLogin'` / `'roleChanged'` (auth_gate_test.dart:157, 162, 171, 175 and the sign-in test).
- Task 3: 3 of 6 red, each `Expected: AuthUnauthenticated(<reason>) / Actual: AuthUnauthenticated(UnauthenticatedReason.sessionExpired)` — reactive newLogin, proactive newLogin, cold-start roleChanged. Green at the first run, as guards (expected by the plan): «an unknown or missing reason ends with sessionExpired (D-12)» (baseline always sessionExpired), «handleRevocation stays sessionExpired (D-12)», «a logout whose refresh is refused for a new login still ends signed out (D-12)» (logout refresh is outside the single flight).

## Gates

- `flutter test test/repository/services/auth` → 169 «All tests passed» (after Task 1).
- `flutter test test/screens/auth test/screens/signIn test/repository/services/auth` → 364 (after Task 2), 370 (after Task 3) «All tests passed».
- `flutter test test/screens/signIn test/screens/auth` → 195 «All tests passed» (after the follow-up).
- `flutter analyze`: 47 issues found (all info), 0 error, 0 warning (after every code task).
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- Acceptance greps: all as required (`D-12)` = 6 in each of the API and revocation tests, 3 in auth_gate_test, 2 in sign_in_screen_test; `fakeAsync` 9 → 15; `_unauthenticatedReasonOf(` = 2).
- `dart format` on each touched file individually: no reflow of untouched members.

## Deviations from Plan

1. **[Rule 1 - acceptance] New-login copy as a double-quoted literal** — the GREEN commit of Task 2 wrote `'Hai effettuato l\'accesso da un altro dispositivo.'`; the acceptance grep `grep -cF "Hai effettuato l'accesso da un altro dispositivo."` printed 0 because of the escape. Fixed in a separate commit (15ffb2f, no amend) with a double-quoted literal (lint-clean: `flutter_lints` has no `prefer_single_quotes`, which would allow it anyway for a string containing `'`). The test files keep the escaped form (no grep on them).
2. Test helper in graphql_backend_auth_api_test.dart: `gqlError(code, {Object? reason = _noReason})` with a sentinel `const Object _noReason = Object();` so `reason` is added to `extensions` only when passed, plus `gqlErrors(List<GraphQLError>)` and `codedError(...)` for the two-error case — as the plan describes, named here for the next plans.

## Known Stubs

None.

## Threat surface

No new surface: T-12-39..T-12-42 mitigated as planned (Task 1 lenient parsing and unchanged 401 branch; Task 3 teardown once on every path, logout wins).

## Self-Check: PASSED

- Commits exist: eae127f, 2a0bf72, 01bcd52, 9ac4da1, 5559757, c9ba7c8, 15ffb2f.
- All modified files exist; `git status --short` clean apart from this bookkeeping.
