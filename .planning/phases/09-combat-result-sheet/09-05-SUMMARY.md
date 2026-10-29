---
phase: 09-combat-result-sheet
plan: 05
subsystem: shell signals (map availability, session sync, in-app banners)
tags: [flutter, dart, combat, cubit, bus, websocket, banner, bloc_test, fake_async]

# Dependency graph
requires:
  - phase: 03-session-sync
    provides: "`SessionSyncCubit` (single socket observer), `SessionSyncScope`, `UserRefreshRequestBus` pattern"
  - phase: 05-push-notifications
    provides: "`InAppNotificationsCubit` (queue, personal dedup window, `PushEvent.dedupKey`)"
provides:
  - "`MapAvailabilityCubit` + `MapAvailabilityState` (`isMapPage`, `isRouteCovered`, `isQuestSheetOpen`, `isPawnDragging`, `isFree`) with four writers"
  - "`ConnectionRestoredEvents` (read interface, `Stream<void> restored`) + `ConnectionRestoredBus` (`notifyRestored()`, `close()`)"
  - "`SessionSyncCubit({..., ConnectionRestoredBus? connectionRestored})` notifying one restore per false → true socket transition after the first connection"
  - "`SessionSyncScope` provides `ConnectionRestoredBus` (closed on dispose) and `ConnectionRestoredEvents`"
  - "`InAppNotificationsCubit.suppress(String dedupKey)`"
affects: [09-06, 09-09, 09-10, 09-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shell availability as a Flutter-free cubit written only by the UI (Equatable drops repeated writes)"
    - "Reconnection signal as a session-scoped bus fed by the single socket observer, read through a narrow interface"

key-files:
  created:
    - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart
    - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_state.dart
    - lib/repository/services/sync/connection_restored_events.dart
    - test/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit_test.dart
    - test/repository/services/sync/connection_restored_events_test.dart
  modified:
    - lib/screens/auth/syncCubit/session_sync_cubit.dart
    - lib/screens/auth/session_sync_scope.dart
    - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart
    - test/screens/auth/syncCubit/session_sync_cubit_test.dart
    - test/screens/auth/session_sync_scope_test.dart
    - test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart

key-decisions:
  - "MapAvailabilityCubit starts with `isMapPage == false`: MainScreen must declare the initial page (F1, the initial page never fires onPageChanged)"
  - "The restore bus is optional on SessionSyncCubit, so the existing tests and constructions stay unchanged; SessionSyncScope always wires it"
  - "A first connection after an initial drop (`[false, true]`) is not a restore: only a socket that was connected once and came back counts"
  - "`suppress` uses the raw dedupKey (= `PushEvent.dedupKey`, e.g. `questEnd|<id>`) with the personal window (2 min), and touches only PushEvent entries, never local notices"

patterns-established:
  - "Result delivery consumers read `ConnectionRestoredEvents` (never the bus) and `MapAvailabilityCubit.state.isFree`"

requirements-completed: []

# Metrics
duration: ~15min
completed: 2026-10-27
---

# Phase 9 Plan 05: Shell Signals for Result Delivery Summary

**A Flutter-free «Map visible and free» cubit, a WebSocket reconnection bus fed by `SessionSyncCubit`, and `InAppNotificationsCubit.suppress(dedupKey)` so an open result sheet silences its own push banner.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-10-27
- **Tasks:** 3 (6 commits, TDD RED → GREEN each)
- **Files:** 5 created, 6 modified

## Accomplishments

- `MapAvailabilityCubit` with `pageChanged({required bool isMapPage})`, `routeCoveredChanged(bool)`, `questSheetChanged(bool)`, `pawnDragChanged(bool)`; `isFree = isMapPage && !isRouteCovered && !isQuestSheetOpen && !isPawnDragging`.
- `ConnectionRestoredBus` / `ConnectionRestoredEvents`; `SessionSyncCubit._onConnection` keeps the watchdog calls and notifies exactly once per `false → true` transition after the first connection; `SessionSyncScope` provides and disposes the bus.
- `InAppNotificationsCubit.suppress(dedupKey)`: marks the key for `personalDedupWindow`, removes queued `PushEvent`s with the key (order of the rest preserved), and moves past the current banner if it has the key (fresh timer for the next).

## Task Commits

1. **Task 1: MapAvailabilityCubit** — `45f7e76` (test), `20e7001` (feat)
2. **Task 2: ConnectionRestoredBus** — `e41b3b7` (test), `98ec406` (feat)
3. **Task 3: InAppNotificationsCubit.suppress** — `07c266e` (test), `c2b147e` (feat)

## RED evidence

- Task 1: `Error when reading 'lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart': No such file or directory` / `'MapAvailabilityCubit' isn't a type.`
- Task 2: `Error when reading 'lib/repository/services/sync/connection_restored_events.dart': No such file or directory` / `'ConnectionRestoredBus' isn't a type.`
- Task 3: `Error: The method 'suppress' isn't defined for the type 'InAppNotificationsCubit'.`

## Verification

- Plan verify commands: all green (map availability 7 tests; sync + scope + auth gate 93 tests; in-app notifications 29 tests).
- Full suite: 2236 → 2259 passing (+23).
- `flutter analyze`: 52 issues (baseline 53 → unchanged at 52 after 09-04), 0 errors.
- Format: every new file and the three CLEAN touched lib files plus the three touched test files pass `dart format --output=none --set-exit-if-changed`.

## Deviations from Plan

- Added two tests beyond the listed behaviours (a read-only-interface test on the bus and a "without a bus the socket still drives the watchdog" test in the `connection restored` group); scope test split into "provides" and "closes the bus when the session ends". No implementation deviation.
- Wrapped the `suppress` doc comment to three lines (the plan's two-line version exceeded 80 columns).

Otherwise the plan executed exactly as written.

## Threat Mitigations

- T-9-12: one restore per `false → true` transition, repeats ignored (`session_sync_cubit_test.dart` group `connection restored`).
- T-9-13: `suppress` marks the key and drops queued/current copies (`in_app_notifications_cubit_test.dart` group `suppress`).
- T-9-14: equality drops duplicate writes (`map_availability_cubit_test.dart`); reset on dispose belongs to 09-09.

## Known Stubs

None. The `MapAvailabilityCubit` has no writer wired yet and is not provided in the shell: plan 09-09 wires it (by design).

## Self-Check: PASSED
