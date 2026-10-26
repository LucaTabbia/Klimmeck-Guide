---
phase: 07-travel
plan: 09
subsystem: ui
tags: [flutter, dart, flutter_map, bloc, travel, camera, bottom-sheet, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-02)
    provides: "`travelDestinationFor({target, location})` (D-01/D-02)"
  - phase: 07-travel (07-04)
    provides: "`MapFocusCubit` with `isCharacterFocusPending` / `consumeCharacterFocus()` (D-15)"
  - phase: 07-travel (07-06)
    provides: "`TravelProgressCubit.follow(ActiveTravel?)`, `TravelProgressActive { position, arrivalRefetchCount }`"
  - phase: 07-travel (07-07)
    provides: "`TravelCubit.preview` / `cancel`, `TravelConfirming { preview.road }`, `ServerClockService` in the shell, `MockTravelCubit`"
  - phase: 07-travel (07-08)
    provides: "`TravelRouteLayer`, `TravelConfirmationSheet` (mount guard), `MockTravelProgressCubit`"
provides:
  - "`WorldMap` travel wiring: per-map `TravelProgressCubit` fed by `CharacterCubit.activeTravel`, `const TravelRouteLayer()` under the markers, one-shot framing on `onMapReady` (D-09), latched `travelEnd` focus consumption (D-15), bounded silent rereads (D-10)"
  - "Drag release → `travelDestinationFor` → `TravelCubit.preview` + parchment sheet on a transparent barrier, `whenComplete(cancel)`, camera fitted to the previewed route above the sheet (D-01..D-04)"
  - "`CharacterCubit.changeCharacterLocation` teleport stub removed (T-07-09-01)"
  - "`test/screens/mainScreen/tabs/map/world_map_travel_test.dart` with the top-level `pumpWorldMap` harness (reused by 07-10) and `MockWorldMapCubit`"
affects: [07-10, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Screen-owned cubit (`late final` in `initState`, closed in `dispose`) exposed to the layers with `BlocProvider.value`"
    - "Camera moves only after `onMapReady` (`_isMapReady` gate), never on progress ticks"

key-files:
  created:
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/screens/mainScreen/characterCubit/character_cubit.dart
    - test/helpers/mocks.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "An arrival already overdue when the map mounts triggers one silent reread from `initState`: the `TravelProgressCubit` emits its first snapshot before the `BlocListener` subscribes, so the listener alone would miss it (D-10)"
  - "`build` split into `_buildListeners()` + `_buildMap()` so the new `BlocProvider.value` + `MultiBlocListener` wrapper does not leave the subtree mis-indented in the non-formatter-clean `world_map.dart`"
  - "The teleport-stub removal is its own `refactor(map)` commit"

patterns-established:
  - "`pumpWorldMap(tester, character:, travelState:, serverNow:)` mounts the real `WorldMap` with mocked shell cubits, a real `MapFocusCubit` and a `FakeServerClockService`; camera read via `FlutterMap.mapController!.camera`"

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-10-24
---

# Phase 7 Plan 09: WorldMap travel wiring Summary

**`WorldMap` now follows the backend `activeTravel` through its own `TravelProgressCubit` (route layer, one-shot framing on map ready, `travelEnd` focus, at most two silent rereads after `endTime`), and releasing the pawn on another city calls `TravelCubit.preview` and opens the parchment sheet over a transparent barrier with the camera fitted to the route; the client teleport stub is gone.**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-10-24T14:45Z (after 07-08)
- **Completed:** 2026-10-24T15:02Z
- **Tasks:** 2
- **Files modified:** 1 created + 3 modified (+ 3 planning files)

## Accomplishments

- Per-map `TravelProgressCubit` created in `initState` from `ServerClockService` and the current `activeTravel`, closed in `dispose` (no timer survives the map, T-07-09-04); a `BlocListener<CharacterCubit>` feeds `follow(...)` only when `activeTravel` changes, so the backend clearing it removes the route (D-10).
- `const TravelRouteLayer()` right after `_buildMapImage()` (markers above the route); `BlocProvider<TravelProgressCubit>.value` above `FlutterMap`.
- `onMapReady: _handleMapReady`: with a travel in progress the camera moves to the interpolated pawn once; progress ticks never move it again (D-09, no recenter control). `_consumeCharacterFocus()` serves a latched or live `MapFocusCubit` request only after map ready, targeting the travelling pawn or `status.location.location` (D-15, T-07-09-02).
- `BlocListener<TravelProgressCubit>` fires `refreshCharacter()` only when `arrivalRefetchCount` increases (max 2 per travel, T-07-09-03).
- `_handleCharacterDragEnd` → `travelDestinationFor` (same city = nothing, D-02) → `preview(characterId, destination)` + `_showTravelConfirmation` (`barrierColor: Colors.transparent`, `BlocProvider.value(value: travelCubit)`, `.whenComplete(travelCubit.cancel)`). `BlocListener<TravelCubit>` on entering `TravelConfirming` runs `_fitPreviewRoute` (`CameraFit.coordinates`, bottom padding half the screen + 24, `maxZoom: MapConstants.maxZoom`; no-op under 2 points or before map ready).
- `CharacterCubit.changeCharacterLocation` and its `latlong2` import removed.

## Task Commits

| # | Task | Commit | Type |
|---|------|--------|------|
| 1 | RED: WorldMap travel harness + `MockWorldMapCubit` | `6b0871a` | test |
| 1 | GREEN: follow the active travel on the world map | `5cf75b5` | feat |
| 2 | RED: drag-to-travel sheet tests | `0714927` | test |
| 2 | GREEN: open the travel confirmation from the pawn drag | `548b127` | feat |
| 2 | Drop the drag teleport stub | `fdf382c` | refactor |

## Verification

- `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/characterCubit` -> 100 passed (`world_map_travel_test.dart`: 14).
- `flutter analyze` on `world_map.dart`, `character_cubit.dart`, `world_map_travel_test.dart`, `mocks.dart` -> No issues found.
- `dart format --output=none --set-exit-if-changed` on `character_cubit.dart` and the new test -> exit 0; `world_map.dart` and `mocks.dart` hand-edited only (not formatter-clean).
- Acceptance greps: all as specified (`onMapReady: _handleMapReady` 1, `const TravelRouteLayer()` 1 and right after `_buildMapImage(),`, `_progressCubit.close()` 1, `\.consumeCharacterFocus()` 1, `refreshCharacter()` 1, no removed `_animateMapTo`/`_handlePositionChanged` lines, `barrierColor: Colors.transparent` 1, `whenComplete(travelCubit.cancel)` 1, `BlocProvider.value(` 1, `travelDestinationFor(` 1, `CameraFit.coordinates(` 1, chrome 0; `changeCharacterLocation` nowhere in lib/test, `latlong2` 0 in `character_cubit.dart`).
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` -> 1332 passed.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Overdue arrival at mount was never reread**
- **Found during:** Task 1 design of the reread test
- **Issue:** `follow(...)` in `initState` emits the first `TravelProgressActive` (already `arrivalRefetchCount >= 1` when the map opens after `endTime + 5 s`) before the `BlocListener` subscribes; the listener sees no increase, so the silent reread of D-10 would never happen for a map opened late.
- **Fix:** `_initializeTravelProgress()` calls `_rereadCharacter()` once when the initial count is > 0; later increases go through the listener (still at most two rereads per travel).
- **Files modified:** lib/screens/mainScreen/tabs/map/world_map.dart
- **Commit:** `5cf75b5`

### Notes

- The plan's single `listener: (context, _) => context.read<CharacterCubit>().refreshCharacter()` became the private `_rereadCharacter()` shared by the listener and the mount check; `grep -c "refreshCharacter()"` is still 1.
- "Dismissing the sheet" is tested with `Navigator.pop`: `PaperSheetModal` (shared, out of scope) is a full-height `DraggableScrollableSheet` inside the bottom sheet's `Material`, so a tap above the parchment never reaches the barrier (same as `CityModal` today). Dismissal in the app goes through drag-down or system back; both route through `whenComplete(cancel)`.
- The route-removal test pumps twice: the mocked character event, the progress cubit emission and the route layer rebuild land on consecutive frames.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None: no surface beyond the plan's threat model (T-07-09-01..06 mitigated and tested).

## Next Phase Readiness

- 07-10 extends `world_map_travel_test.dart` (`pumpWorldMap`, `cityA`/`cityB`, `characterLoaded`, `previewKeepsTheSheetOpen`, `dragPawnBy`) and changes only `character_marker_layer.dart`; `CharacterMarkerLayer` callbacks are unchanged. While the sheet is open the pawn still sits on the destination city after the drop (Pitfall 3 spring-back is 07-10's rendering mode work).

## Self-Check: PASSED
