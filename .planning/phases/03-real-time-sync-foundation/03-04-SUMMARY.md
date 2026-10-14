---
phase: 03-real-time-sync-foundation
plan: 04
subsystem: auth
tags: [session-terminator, sync-lost, sign-in-notice, auth-gate]
requires: []
provides:
  - UnauthenticatedReason.syncLost
  - SessionTerminator (guarded terminateSession on both auth services)
  - SignInNotice enum with the "Connessione persa" notice
  - AuthGate root-dialog pop on character change (D-10)
  - MockSessionTerminator
affects: [03-08]
tech-stack:
  added: []
  patterns: [narrow additive interface like UnauthorizedRecovery, single-flight termination]
key-files:
  created:
    - lib/repository/services/auth/session_terminator.dart
    - test/repository/services/auth/session_auth_token_service_terminate_test.dart
  modified:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/auth.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/screens/signIn/sign_in_screen.dart
    - lib/screens/auth/auth_gate.dart
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
    - test/helpers/mocks.dart
    - test/screens/signIn/sign_in_screen_test.dart
    - test/screens/auth/auth_gate_test.dart
    - .planning/phases/02-character-creation/02-SECURITY.md
key-decisions:
  - "terminateSession reuses _endSession (D-12 teardown) behind a guard on logout-in-flight and authenticated channel, plus single-flight"
requirements-completed: [SYNC-03, SYNC-04, SYNC-05]
duration: 25min
completed: 2026-10-14
---

# Phase 3 Plan 04: Session termination and routing Summary

Guarded `SessionTerminator.terminateSession(syncLost)` on the real and dev auth services, a `SignInNotice` enum showing "Connessione persa, accedi di nuovo.", and AuthGate popping root dialogs on any character change.

## Commits
- test(auth): failing tests for the sync-lost session termination
- feat(auth): guarded sync-lost session termination
- test(auth): failing tests for the connection lost notice
- feat(auth): connection lost notice after a sync-lost termination
- test(auth): expect root dialogs to close on character change
- feat(auth): close root dialogs on character change

## Verification
- `flutter test`: 542 passing (baseline 528, +14)
- `flutter analyze`: 57 issues, identical to baseline; touched files clean
- Touched files formatter-clean (explicit paths only); `showSessionExpiredNotice` fully removed; `handleRevocation` untouched

## Deviations from Plan
- The AuthGate `listenWhen` is formatted by dart_style over three lines, so the acceptance grep for the single-line `_leavesSession(previous, current) || _changesCharacter(previous, current)` does not match literally; the logic is identical.
- Dev test: the auth stream replays the last state, so expectations include the leading replayed `AuthAuthenticated` / `AuthUnauthenticated` (test-only adjustment).

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
