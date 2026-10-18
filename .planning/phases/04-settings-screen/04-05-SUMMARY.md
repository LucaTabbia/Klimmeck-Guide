---
phase: 04-settings-screen
plan: 05
subsystem: session-wiring
tags: [flutter, bloc, auth, shell, composition-root]
requires: [04-03, 04-04]
provides:
  - Regression tests: both adoptUser implementations accept a User whose currentCharacter is null
  - AuthenticatedShell provides NotificationPreferencesCubit (loaded for userId) and CharacterDeletionCubit
  - Shell-level BlocListener handing deletedUser to AuthCubit.adoptUser (handoverRejected on refusal)
  - main.dart composition root owns one SharedPreferencesNotificationPreferencesStore, passes it with userId: user.id
affects: [04-06 (Settings tab reads both cubits), 04-07]
tech-stack:
  added: []
  patterns: [hand-over at shell level so it survives leaving the Settings page; cubits closed with the shell]
key-files:
  created: []
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/main.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/repository/services/auth/session_auth_token_service_adopt_user_test.dart
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
key-decisions:
  - "No production change to adoptUser/AuthGate/SessionHome: characterization tests prove both services accept a character-less user"
  - "Preferences store never referenced by logout/teardown code (D-11): values survive logout and account change"
requirements-completed: []
duration: ~15 min
completed: 2026-10-16
---

# Phase 4 Plan 05: Session wiring Summary

The session shell now owns the two Settings cubits and turns a successful character deletion into an `adoptUser` hand-over, with the preferences store created once at the composition root.

## Commits
- 088cf17 test(auth): guard adoptUser for a user whose character was deleted (characterization, passed on first run, no lib change)
- a0e8fd0 test(settings): add failing shell tests for settings cubits and deletion hand-over (RED)
- c90df37 feat(settings): provide settings cubits in the session shell (GREEN)

## Verification
- `flutter test`: 732 before, 738 after, all green (2 auth regression tests + 4 shell tests).
- `flutter analyze`: 57 issues (pre-existing baseline), 0 errors; all touched files "No issues found!".
- Touched files verified formatter-clean by explicit path (no directory format).

## Deviations from Plan

**1. [Rule 3 - Blocking] Missing import in the RED shell test**
- **Found during:** Task 2 GREEN
- **Issue:** the RED test file used `AuthState`/`AuthAuthenticated` without importing `repository/services/auth/auth.dart`, so it failed analysis independent of the missing constructor args.
- **Fix:** import added in the GREEN commit (c90df37).

Otherwise none: plan executed as written.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED

- Files modified exist: `lib/screens/auth/authenticated_shell.dart`, `lib/main.dart`, the three test files.
- Commits 088cf17, a0e8fd0, c90df37 present on `feat/04-settings-screen`; no `Co-Authored-By` trailer.
- `flutter test` 738 green, `flutter analyze` 57 issues / 0 errors.
