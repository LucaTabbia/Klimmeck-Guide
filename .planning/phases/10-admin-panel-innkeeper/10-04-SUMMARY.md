---
phase: 10-admin-panel-innkeeper
plan: 04
subsystem: admin-teleport
tags: [admin, innkeeper, teleport, cubit, map, tdd]
requires: [10-01, 10-02, 10-03]
provides:
  - TeleportTarget.fromCharacter (lib/models/travel/teleport_target.dart)
  - TeleportModeCubit (prepare, teleportTo, cancel, acknowledgeSuccess)
  - TeleportModeState (TeleportIdle, TeleportPreparing, TeleportPreparationFailed, TeleportActive, TeleportSucceeded)
  - MapAvailabilityState.isTeleportMode + MapAvailabilityCubit.teleportModeChanged
  - MockTeleportModeCubit (test/helpers/mocks.dart)
affects: [10-05, 10-08, 10-09, 10-10]
tech-stack:
  added: []
  patterns: [shell-level Flutter-free mode cubit, generation token checked after every await, same-city no-op mirrored from travelDestinationFor]
key-files:
  created:
    - lib/models/travel/teleport_target.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_state.dart
    - test/models/travel/teleport_target_test.dart
    - test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart
    - lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_state.dart
    - test/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit_test.dart
    - test/helpers/mocks.dart
key-decisions:
  - "A character read that yields no point or no sex is TeleportPreparationFailed(failure: malformed): no mode change (C3)"
  - "prepare bumps the generation too: cancel() during the character read drops the late answer"
  - "FORBIDDEN on teleport goes through cancel() (generation bump + TeleportIdle); every other failure returns to TeleportActive(failure) with isTeleporting false"
  - "TeleportActive.copyWith takes failure as InnkeeperFailure? Function()? so a new drop can clear it"
requirements-completed: []
duration: 12min
completed: 2026-10-29
---

# Phase 10 Plan 04: Teleport mode state machine Summary

Flutter-free, shell-level `TeleportModeCubit` that reads `character(id)` before entering teleport mode (point + pawn sex via `TeleportTarget.fromCharacter`), calls `teleportCharacter` once per real drop with no confirmation (same-city drop is a no-op via `travelDestinationFor`), keeps coded failures for the Map chip, ends on `FORBIDDEN`, and never resurrects a cancelled mode; plus `MapAvailabilityState.isTeleportMode`, which makes the Map not free for the Phase 9 result presenter.

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | TeleportTarget and the TeleportModeCubit state machine | 8139a6a | 5e22816 |
| 2 | isTeleportMode on the map availability | 31f30cf | 776da71 |

## TDD evidence

- Task 1 RED: compile failure, `Error when reading 'lib/models/travel/teleport_target.dart': No such file or directory` and `Undefined name 'TeleportTarget'`.
- Task 1 GREEN: `teleport_target_test.dart` 5 tests + `teleport_mode_cubit_test.dart` 18 tests = 23 passing.
- Task 2 RED: compile failure, `No named parameter with the name 'isTeleportMode'`, `The method 'teleportModeChanged' isn't defined for the type 'MapAvailabilityCubit'`.
- Task 2 GREEN: `map_availability_cubit_test.dart` 9 tests; with `test/screens/mainScreen/components` 115 passing (presenter unaffected).
- Plan verification: `flutter test test/models/travel test/screens/mainScreen/tabs/map test/screens/mainScreen/components` → 335 passing, exit 0.
- Analyzer gate (repo-wide): 51 issues, all `info`, exit 0.

## Deviations from Plan

None in behaviour. Notes:
- Two extra tests beyond the listed behaviours: a `character(id)` read answered after `cancel()` does not enter the mode (the generation guard also covers `prepare`), and a drop outside `TeleportActive` is ignored.
- The two plan-dictated doc comments (on `TeleportActive` and on `isTeleportMode`) were wrapped to 80 columns by hand; wording unchanged.

## Threat mitigations

- T-10-14: same-city no-op and `isTeleporting` guard (tests «a drop on the current city…», «a drop while a teleport is in flight…»).
- T-10-15: `_generation` checked after every await (tests «a late success after cancel…», «a read answered after cancel…»).
- T-10-16: FE ends the mode on `forbidden` (test «a lost role ends the mode»); BE remains the judge.
- T-10-17: `isTeleportMode` in `isFreeBeneathRoutes` (availability test, C13).

## Known Stubs

None. `teleportModeChanged` has no UI writer yet: `WorldMap` writes it in plan 10-09.

## Self-Check: PASSED

- All 5 created files and 4 modified files exist; commits 8139a6a, 5e22816, 31f30cf, 776da71 are in `git log`.
