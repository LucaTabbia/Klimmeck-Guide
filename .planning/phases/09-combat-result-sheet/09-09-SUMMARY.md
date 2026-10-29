---
phase: 09-combat-result-sheet
plan: 09
subsystem: ui wiring
tags: [flutter, cubit, combat, map-availability, shell, world-map]

# Dependency graph
requires:
  - phase: 09-05
    provides: "`MapAvailabilityCubit` (pageChanged / questSheetChanged / pawnDragChanged / routeCoveredChanged, `isFree`)"
  - phase: 09-08
    provides: "MainScreen `_SatchelInputs` wiring and the `pumpOpenSatchel` harness"
provides:
  - "`AuthenticatedShell` provides one `MapAvailabilityCubit` per session (closed with the shell)"
  - "`MainScreen` writes `isMapPage` on the first `MainScreenLoadData`, on every page change, and resets it on dispose"
  - "`WorldMap` writes `isQuestSheetOpen` (open from marker/paper, close on dismissed) and `isPawnDragging` (drag update / drag end), resets both on dispose"
  - "Test harness: `setUpWorldMapHarness()` + global `mapAvailability` in `world_map_travel_test.dart`; `pumpMainScreen` / `openSatchel` in `main_screen_test.dart`"
affects: [09-10, 09-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shell-wide UI signal written only by widgets; the cubit is cached in `initState` and reset in `dispose` so a stale flag never survives an unmount"

key-files:
  created:
    - test/screens/mainScreen/tabs/map/world_map_availability_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/auth/authenticated_shell_test.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/main_screen_test.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart

key-decisions:
  - "MainScreen turns its `BlocListener<CharacterCubit>` into a `MultiBlocListener` and adds the `MainScreenLoadData` listener there (instead of wrapping the `BlocBuilder`): same behaviour, a 30-line diff instead of a 170-line re-indent"
  - "MainScreen also resets `isMapPage` to false on dispose (cubit cached in `initState`), so a MainScreen replaced inside a living shell never leaves the Map marked visible"
  - "`jumpToPage` already fires `onPageChanged` (F1 probe), so the satchel and `_showMap` need no extra write"
  - "The world-map harness exposes a shared `setUpWorldMapHarness()` and a global `mapAvailability` (created/closed per test like `mapFocusCubit`) instead of an optional `pumpWorldMap` parameter"

patterns-established:
  - "Map test files reuse `world_map_travel_test.dart` via `import 'world_map_travel_test.dart' hide main;` + `setUpWorldMapHarness()`"

requirements-completed: []

# Metrics
duration: 25min
completed: 2026-10-28
---

# Phase 9 Plan 09: Map Availability Writers Summary

**`AuthenticatedShell` now provides a session-wide `MapAvailabilityCubit`, fed by `MainScreen` (Map page, including the initial page once the cold-start loader is gone) and by `WorldMap` (in-map quest sheet and pawn drag), with every writer resetting its flag on dispose.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-10-28
- **Tasks:** 2/2 (TDD, 4 commits)
- **Files:** 1 created, 6 modified

## Accomplishments

- Shell: `BlocProvider<MapAvailabilityCubit>(create: (_) => MapAvailabilityCubit())` next to `MapFocusCubit`, class doc extended (D-23).
- MainScreen: `_reportMapPage(page)` → `pageChanged(isMapPage: page == NotificationIntentLanding.worldMapPageIndex)`, called from `onPageChanged` and from a `BlocListener<MainScreenCubit>` with `listenWhen: previous is! MainScreenLoadData && current is MainScreenLoadData` (initial page 0 never fires `onPageChanged`, F1). Dispose writes `isMapPage: false`.
- WorldMap: `_availability` cached in `initState`; `questSheetChanged(true)` in `_selectQuest` / `_openFromPaper`, `questSheetChanged(false)` in `_clearSelection` (dismissed animation or map tap); `pawnDragChanged(true)` first line of `_handleCharacterDragUpdate`, `pawnDragChanged(false)` first line of `_handleCharacterDragEnd`; dispose resets both (T-9-14 / T-9-37).

## Task Commits

1. **Task 1 RED** - `56dc2d9` test(combat): expect the map page in the availability signal
2. **Task 1 GREEN** - `b087eb6` feat(combat): report the visible map page
3. **Task 2 RED** - `8e07e95` test(combat): expect the map overlay and drag in the availability
4. **Task 2 GREEN** - `0b250a4` feat(combat): report the map overlay and pawn drag

## RED evidence

- Task 1: `provides the map availability cubit and closes it on removal` → `ProviderNotFoundException: Could not find the correct Provider<MapAvailabilityCubit>`; `the loaded pages open on the map page` and `the map page follows every satchel navigation` → `Expected: true, Actual: <false>`.
- Task 2: 5 of 6 tests failed with `Expected: true, Actual: <false>` (quest sheet from paper, from marker, pawn drag, unmount with sheet open, unmount mid-drag); `a release that opens the travel sheet ends the drag` passed vacuously in RED (the flag was never set) and became meaningful with GREEN.

## Verification

- `flutter test test/screens/auth/authenticated_shell_test.dart test/screens/mainScreen/main_screen_test.dart` → +44 green
- `flutter test test/screens/mainScreen/tabs/map` → +148 green
- Full suite: 2391 → 2402 green (+11)
- `flutter analyze`: 52 issues (baseline 53), 0 errors; touched files: no issues
- `grep -c "MapAvailabilityCubit()" authenticated_shell.dart` = 1; `grep -c "pageChanged(" main_screen.dart` = 2; `grep -c "questSheetChanged(" world_map.dart` = 4; `grep -c "pawnDragChanged(" world_map.dart` = 3
- `character_marker_layer.dart` (DIRTY) untouched; all touched files formatter-clean

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Existing MainScreen test without the new provider**
- **Found during:** Task 1 GREEN
- **Issue:** `loads exactly the character of the session` pumped `MainScreen` without `MapAvailabilityCubit`; `initState` now reads it.
- **Fix:** the test provides a real `MapAvailabilityCubit`.
- **Commit:** `b087eb6`

**2. [Rule 2 - Correctness] MainScreen resets `isMapPage` on dispose**
- **Found during:** Task 1 GREEN
- **Issue:** the plan resets only the WorldMap flags; a MainScreen replaced inside a living shell (e.g. `_ShellBody` back to the splash) would leave `isMapPage == true` and let a sheet open off the Map.
- **Fix:** cubit cached in `initState`, `pageChanged(isMapPage: false)` in `dispose`; test `a removed main screen is no longer the map page` (added in GREEN, it passes vacuously before the implementation).
- **Commit:** `b087eb6`

**3. [Design] `MultiBlocListener` instead of wrapping the `BlocBuilder`**
- Same semantics as the plan's `BlocListener<MainScreenCubit, MainScreenState>`; avoids re-indenting the whole build body.

**4. [Harness] Shared world-map setup**
- `pumpWorldMap` gets the cubit from a global `mapAvailability` set up by the new top-level `setUpWorldMapHarness()` (moved out of the travel test `main`), not from an optional parameter; the new test file imports the travel test with `hide main`.
- The «release opens the travel sheet» case uses the existing `dragPawnBy` (no frame between moves): pumping between `moveBy` calls lets the drag smooth-scroll timer move the camera, so the release lands on a different city.

## Known Stubs

None.

## Next Phase Readiness

- 09-10 (presenter) writes the fourth flag, `routeCoveredChanged`, and reads `isFree`.
- 09-11 mounts the presenter in `MainScreen` and provides `QuestResultsCubit`: `main_screen_test.dart` already provides a real `MapAvailabilityCubit` in every harness.

## Self-Check: PASSED
