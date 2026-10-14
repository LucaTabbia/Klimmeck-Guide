---
phase: 02-character-creation
plan: 02
subsystem: auth
tags: [auth, session, auth-gate, bloc]
requires: []
provides:
  - AuthTokenService.adoptUser(User) on the contract, DevAuthTokenService and SessionAuthTokenService
  - AuthCubit.adoptUser delegating to the service
  - AuthGate rebuild rule when the same user gains a currentCharacter
affects: [02-09]
key-files:
  modified:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - lib/screens/auth/cubit/auth_cubit.dart
    - lib/screens/auth/auth_gate.dart
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
    - test/screens/auth/cubit/auth_cubit_test.dart
    - test/screens/auth/auth_gate_test.dart
  created:
    - test/repository/services/auth/session_auth_token_service_adopt_user_test.dart
key-decisions:
  - "adoptUser accepts no token and is ignored unless the session is authenticated and user.id matches (T-02-02-01/02)"
  - "_changesCharacter is in _shouldRebuild only, not _leavesSession: no session teardown on character gain"
requirements-completed: []  # CHAR-07/CHAR-01 close with the screen plans (09+)
duration: 15min
completed: 2026-10-09
---

# Phase 2 Plan 02: adoptUser and gate rebuild Summary

The session service stays the source of truth for the created user: `adoptUser` re-emits `AuthAuthenticated` with the same token, and `AuthGate` now rebuilds when the same user gains a character.

## Commits
- 3fa87c7 test(character-creation): add failing tests for adopting the created user
- de47d8c feat(character-creation): let the session adopt the user returned by createCharacter
- d8fb413 test(character-creation): add failing gate test for a user gaining a character
- 7677550 fix(character-creation): rebuild the gate when the user gains a character

## Verification
- `flutter test`: 298 passed (287 baseline + 11 new)
- `flutter analyze lib test`: 12 issues (unchanged baseline)
- `dart format` applied to touched files only

## Deviations from Plan
None. In the session test, the "later re-emit" case uses the plan's fallback: a proactive refresh does not re-emit for the same user id, so the test asserts that a new listener gets the adopted user replayed after the refresh.

## Known Stubs
None.

## Self-Check: PASSED
