---
phase: 07-travel
plan: 04
subsystem: ui
tags: [flutter, dart, flutter_bloc, satchel, notifications, travel, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-01)
    provides: "`CharacterStatus.activeTravel` and `test/helpers/fixtures/travel_fixtures.dart`"
  - phase: 06-quest-accept-info-sheets
    provides: "`disabledSatchelPages`, `isOnCityMarker`, dark-scrim disabled visual in MenuBackground/SatchelMenu (D-11/D-13)"
  - phase: 05-notifications-infrastructure
    provides: "`NotificationIntentLanding` + `defaultNotificationPopups` registry (D-15)"
provides:
  - "SatchelLayout.shopPageIndex = 5 (Negozio entry uses it, Bacheca uses boardPageIndex)"
  - "disabledSatchelPages(location, cities, isTravelling): {} only on a city marker without travel, otherwise {board, shop}"
  - "MainScreen selects the record (location, isTravelling) for the satchel and the onItemTap guard"
  - "MapFocusCubit (session level, SafeEmit): requestCharacterFocus / consumeCharacterFocus latch"
  - "defaultNotificationPopups = { travelEnd: focusCharacterOnMap }"
  - "AuthenticatedShell provides BlocProvider<MapFocusCubit>"
affects: [07-09, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "BlocSelector on a Dart record (value equality) to rebuild only when one of several inputs changes"
    - "Latched UI request cubit for actions that must survive the frame in which the consumer is not mounted"

key-files:
  created:
    - lib/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart
    - lib/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_state.dart
    - test/screens/mainScreen/tabs/map/map_focus_cubit_test.dart
  modified:
    - lib/screens/mainScreen/components/satchel_availability.dart
    - lib/screens/mainScreen/components/satchel_layout.dart
    - lib/screens/mainScreen/main_screen.dart
    - lib/screens/mainScreen/components/notification_popup_registry.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/components/notification_intent_landing_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The travel flag is `status.activeTravel != null`: covers free and automatic quest travel, since `status.location` stays the departure marker until the BE closes the travel (Pitfall 11)"
  - "The travelEnd popup entry ignores `intent.id` and only latches a focus on the own pawn (T-07-04-02); the map consumes the latch in 07-09"

patterns-established:
  - "Session-level latched request cubit (MapFocusCubit) read by popup registry entries instead of touching a MapController"

requirements-completed: []

# Metrics
duration: 5min
completed: 2026-10-24
---

# Phase 7 Plan 04: Satchel travel rule and travelEnd camera focus Summary

**Board and Shop are enabled only on a city marker with no `activeTravel` (same dark-scrim visual and onItemTap guard as Phase 6), and a `travelEnd` tap now latches a session-level "centre the camera on the pawn" request in a new `MapFocusCubit`, with no sheet or popup.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-10-24T14:21:00Z
- **Completed:** 2026-10-24T14:26:00Z
- **Tasks:** 2
- **Files modified:** 12 source/test files + 3 planning files

## Accomplishments

- `SatchelLayout.shopPageIndex = 5`; the Bacheca and Negozio entries reference `boardPageIndex` / `shopPageIndex`.
- `disabledSatchelPages` takes `required bool isTravelling` and disables `{board, shop}` everywhere except a city marker without travel (D-12).
- `MainScreen` selects `(PointOfInterest?, bool)` through the static `_satchelInputsOf`, used both by the `BlocSelector` and by `_isPageDisabled` (single source for the visual and the tap guard).
- `MapFocusCubit` + `MapFocusState` (`isCharacterFocusPending`), `SafeEmit`, consume returns `true` only when something was pending.
- `defaultNotificationPopups` now holds the single `travelEnd: focusCharacterOnMap` entry (top-level tear-off, map stays `const`); it serves both the system notification tap and the in-app banner tap (D-15/D-16).
- `AuthenticatedShell` provides `MapFocusCubit` after `QuestAcceptanceCubit` and closes it with the shell.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | RED: board and shop disabled while travelling | `b56bebc` | test |
| 1 | GREEN: disable board and shop off a city or while travelling | `f7af796` | feat |
| 2 | RED: travelEnd camera focus tests | `edd3d4f` | test |
| 2 | GREEN: MapFocusCubit, registry entry, shell provider | `849a07d` | feat |

No refactor commits were needed. Plan metadata commit: see the final `docs(phase-7)` commit.

### RED evidence

- Task 1: `main_screen_test.dart:202:43: Error: Member not found: 'shopPageIndex'` (and the missing `isTravelling` parameter in `satchel_availability_test.dart`).
- Task 2: `map_focus_cubit_test.dart:3:8: Error: Error when reading 'lib/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart': No such file or directory`.

### Deliberate changes to existing tests (prescribed by the plan)

- `satchel_availability_test.dart`: every call passes `isTravelling:`; the old `{4}` expectations are now `{4, 5}`; added the travelling-on-a-city case and the `shopPageIndex` entry test.
- `main_screen_test.dart`: "off a city marker another item still navigates" now taps `6` and expects `6` (the Negozio is disabled off a city); `pumpOpenSatchel` accepts an optional `activeTravel` and then builds the character with `travellingCharacterJson`; added Negozio-off-city, travelling (Bacheca/Negozio inert, Profilo navigates) and Negozio-on-city cases.
- `notification_intent_landing_test.dart`: the Phase 5 assertion `expect(defaultNotificationPopups, isEmpty)` is replaced by `keys.toSet() == {NotificationCategory.travelEnd}` (test renamed "Phase 7 registers only the travelEnd popup"); `pumpLanding` accepts an optional `MapFocusCubit`; new landing case with the real registry.
- `authenticated_shell_test.dart`: "provides the gameplay cubits and closes them on removal" also reads `MapFocusCubit` and checks `isClosed`.

## Verification

- `flutter test test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart`: 51 tests passed.
- `flutter test test/screens/mainScreen/tabs/map/map_focus_cubit_test.dart test/screens/mainScreen/components/notification_intent_landing_test.dart test/screens/auth/authenticated_shell_test.dart`: 33 tests passed.
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth`: 1194 tests, all passed.
- `flutter analyze` on every touched file/directory: No issues found.
- Every touched existing file was measured format-clean before the edit; `dart format` run on those files and on the 3 new files only (0 changed after the edits).
- Acceptance greps: all counts as required (`isTravelling: isTravelling` = 2, `activeTravel != null` = 1, `questEnd:` = 0, `showModalBottomSheet|showDialog` = 0, the rest = 1; `activeTravel` in `main_screen_test.dart` = 5).
- 07-VALIDATION.md rows 07-04-01 and 07-04-02 set to ✅ green.

## Decisions Made

None beyond the plan; the key decisions above restate the plan's design.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. By design the latch is not consumed yet: `WorldMap` calls `consumeCharacterFocus()` in plan 07-09.

## Threat Flags

None: T-07-04-01 (travel flag + same guard in `_isPageDisabled`, widget tests), T-07-04-02 (entry ignores `intent.id`, landing test with the real registry), T-07-04-03 (latched request, cubit tests) mitigated; T-07-04-04 transferred to BE Phase 9.

## Next Phase Readiness

- 07-09 can read `MapFocusCubit` in `WorldMap` and call `consumeCharacterFocus()` once the map is ready.
- TRAVEL-03 remains unticked until 07-11.

## Self-Check: PASSED

All 3 created files exist; commits b56bebc, f7af796, edd3d4f, 849a07d are in `git log`; no commit carries a `Co-Authored-By` or `Generated with` trailer.
