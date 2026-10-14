---
phase: 03-real-time-sync-foundation
plan: 08
subsystem: auth-session-sync
tags: [flutter, bloc, sync, lifecycle, composition-root]
requires: [03-04, 03-05, 03-06, 03-07]
provides:
  - SessionSyncScope (watchdog, health, refresh bus, eager SessionSyncCubit)
  - AppLifecycleBridge (onPause/onRestart to AppLifecycleEventBus)
  - SessionHome shell keyed by character id
  - main.dart wiring (terminator, watchConnection, bridge, scope)
affects: [03-09]
key-files:
  created:
    - lib/screens/auth/session_sync_scope.dart
    - lib/screens/auth/app_lifecycle_bridge.dart
    - test/screens/auth/session_sync_scope_test.dart
    - test/screens/auth/app_lifecycle_bridge_test.dart
  modified:
    - lib/screens/auth/session_home.dart
    - test/screens/auth/session_home_test.dart
    - lib/main.dart
requirements-completed: [SYNC-01, SYNC-03, SYNC-04, SYNC-05]
duration: n/a
completed: 2026-10-14
---

# Phase 3 Plan 08: Session sync wiring Summary

Session-wide real-time sync wired into the widget tree: eager `userUpdated` scope under the user-keyed subtree, shell re-keyed per character id, lifecycle bridge on onPause/onRestart, watchdog expiry routed to `terminateSession(syncLost)`.

## Commits
- b4eda51 test(sync): add failing tests for the session sync scope
- 608a0cb feat(sync): add the session sync scope
- fd5dc72 test(sync): add failing tests for re-keying the shell on character change
- 645e35f feat(sync): recreate the gameplay shell when the character changes
- 3d06f77 test(sync): add failing tests for the app lifecycle bridge
- 85015ae feat(sync): wire the real-time sync into the app

## Verification
- Full `flutter test`: 639 passing (baseline 624).
- `flutter analyze`: 57 issues, same pre-existing baseline; touched files clean.
- `main.dart`, `session_home.dart` and its test were formatter-clean before editing; formatted by explicit path only.

## Deviations from Plan
- [Rule 1 - test fix] Scope tests use broadcast controllers (remount reuses them); shell test expects Flutter's real order `init c1, init c2, dispose c1` (new element built before the old one is unmounted) and `BlocProvider(lazy: false)` in the spy shell so the cubit is created.
- Bridge tests passed immediately after the implementation file was added (RED commit was the missing-file failure).
- Bridge dartdoc reworded to avoid the literal `onResume` (acceptance grep = 0).
- main.dart: wrapping the provider tree re-indented the build method (diff larger than the logical change).
- `test/helpers/mocks.dart` untouched.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
