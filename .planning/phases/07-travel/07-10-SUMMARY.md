---
phase: 07-travel
plan: 10
subsystem: ui
tags: [flutter, dart, flutter_map, bloc, travel, pawn, draggable, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-02)
    provides: "`formatTravelDuration(Duration)`, `travelArrivingLabel` (D-08, D-10)"
  - phase: 07-travel (07-06)
    provides: "`TravelProgressActive { position, remainingTime, isArriving }` / `TravelProgressIdle`"
  - phase: 07-travel (07-07)
    provides: "`TravelIdle` / `TravelPreviewing` / `TravelConfirming` / `TravelStarting` / `TravelStarted` / `TravelFailed`, `MockTravelCubit`"
  - phase: 07-travel (07-08)
    provides: "`mapHarness`, `MockTravelProgressCubit`"
  - phase: 07-travel (07-09)
    provides: "`WorldMap` mounting `CharacterMarkerLayer` under a per-map `TravelProgressCubit`; `pumpWorldMap` harness"
provides:
  - "`CharacterMarkerLayer` pawn modes derived from state only: free/draggable, blocked (`maxSimultaneousDrags: 0`), confirming (on the destination marker), travelling (interpolated point + floating label, no drag, no tap)"
  - "`CharacterMarkerLayer.pawnKey` (`ValueKey('map.pawn')`) and `CharacterMarkerLayer.travelLabelKey` (`ValueKey('map.travelLabel')`)"
  - "`test/screens/mainScreen/tabs/map/character_marker_layer_test.dart` (14 tests) and the TRAVEL-04 kill-reconstruction test on the real `WorldMap`"
affects: [07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Widget position as a pure function of cubit states (`_dragPoint ?? _confirmingDestination(travel) ?? location`); no listener resets a field"
    - "Floating marker label: second `Marker` on the same point with explicit width/height and `alignment: Alignment.topCenter`, wrapped in `IgnorePointer`"

key-files:
  created:
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
    - .planning/phases/07-travel/07-VALIDATION.md

key-decisions:
  - "Pawn draggable only when `activeTravel == null`, `pendingQuest == null` and `TravelIdle` (D-01 client pre-check); `TravelFailed` and `TravelStarted` keep the pawn home and non-draggable until the flow returns to idle"
  - "While travelling the pawn is a plain keyed `CachedSvg` (no `Draggable`, no gesture widget); the label is a parchment `AutoSizeText` above it with theme tokens only"
  - "`_handleDragEnd` clears `_dragPoint` before calling `onDragEnd`, so the pawn shows the confirming destination from `TravelCubit` and springs home on idle without any listener (Pitfall 3)"

requirements-completed: []

# Metrics
duration: 25min
completed: 2026-10-24
---

# Phase 7 Plan 10: Pawn Travel Modes Summary

**`CharacterMarkerLayer` rewritten into state-derived pawn modes: draggable only when free, held on the destination while the sheet is open, and during a travel drawn on the interpolated point with a floating "1 h 12 min" / "In arrivo…" label, snapping only when the backend clears `activeTravel`.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-10-24
- **Tasks:** 2 (5 commits: 2 RED, 2 GREEN, 1 refactor)
- **Files modified:** 3 code/test files + VALIDATION

## Accomplishments

- `BlocConsumer` + `_tmpLocation` removed: the pawn point is `_dragPoint ?? _confirmingDestination(travel) ?? status.location` inside `BlocBuilder<CharacterCubit>` → `BlocBuilder<TravelProgressCubit>` → `BlocBuilder<TravelCubit>`; an unrelated `CharacterLoaded` while confirming no longer springs the pawn back (Pitfall 3).
- `Draggable(maxSimultaneousDrags: canDrag ? null : 0)` with `_canStartTravel` (D-01); previewing/confirming/starting show the pawn on the destination marker; `TravelStarted` puts it home until `activeTravel` arrives (Pitfall 4); back to `TravelIdle` springs it home (D-04).
- Drag target rule unchanged (`findCityContainingPoint ?? findNearestCity`); `onDragEnd(target?.markerLocation?.location, target)`.
- Travelling mode: pawn at `progress.position ?? status.location`, second `Marker` (160×72, `Alignment.topCenter`) with `_TravelLabel` (`IgnorePointer`, parchment, `radius`, `spacingSm/Xs`, `labelLarge` in `darkWood`) showing `formatTravelDuration(remainingTime)` or `travelArrivingLabel` (D-08, D-13). Snap happens when the progress cubit goes idle and the character carries the new location (D-10).
- TRAVEL-04: a fresh `WorldMap` mounted 80 of 160 min into a travel shows the pawn at `TravelRoute.pointAt(0.5)` and the label `1 h 20 min` from the first frames.

## Task Commits

| # | Task | Commit | Type |
|---|------|--------|------|
| 1 | RED: pawn drag mode tests | `f192d87` | test |
| 1 | GREEN: drag only when free, hold on the destination | `b15ff0e` | feat |
| 2 | RED: travelling pawn label tests + kill reconstruction | `fd193e7` | test |
| 2 | GREEN: travelling pawn with the remaining time | `f49c198` | feat |
| 2 | Share the keyed pawn between the modes | `05d3b51` | refactor |

## Verification

- `flutter test test/screens/mainScreen/tabs/map` -> all passed (`character_marker_layer_test.dart`: 14, `world_map_travel_test.dart`: 15).
- `flutter analyze lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart test/screens/mainScreen/tabs/map` -> No issues found (same as before the plan).
- `dart format --output=none --set-exit-if-changed` on both test files -> exit 0; `character_marker_layer.dart` (DIRTY) hand-formatted only.
- Acceptance greps: `BlocConsumer` 0, `_tmpLocation` 0, `maxSimultaneousDrags: canDrag ? null : 0` 1, `findNearestCity` 1, `travelLabelKey = ValueKey('map.travelLabel');` 1, `travelArrivingLabel` 1, `formatTravelDuration(` 1, `alignment: Alignment.topCenter` 2, `IgnorePointer` 1, `DateTime.now|ServerClockService` 0, `Color(0x|fontSize:` 0; test greps `unrelated` 1, `maxSimultaneousDrags` 7, `snap` 1, `kill` 2. Task 1 commits touch only the layer and its test.
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` -> 1347 passed.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Test cities outside the harness viewport**
- **Found during:** Task 1 GREEN
- **Issue:** with `Epsg4326` at zoom 2 the map is ~5.7 px per degree, so a city at longitude 120 (as in `world_map_travel_test.dart`) is outside the 780 px `mapHarness` and `MarkerLayer` culls the pawn marker.
- **Fix:** the layer test places city B at `[10, 60]` and drags by 200 px; the real-map tests keep their own geometry.
- **Files modified:** test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
- **Commit:** `b15ff0e`

### Notes

- State changes delivered through the mocked streams need two pumps before the `MarkerLayer` reflects them (same as the 07-09 route-removal test); the "unrelated" and spring-back tests pump twice so they are not vacuous.
- A small refactor commit (`05d3b51`) extracts the keyed pawn shared by the draggable and travelling modes (Boy Scout).

## Issues Encountered

None.

## Known Stubs

None. The label style is provisional by plan (theme tokens only), not a stub.

## Threat Flags

None: no surface beyond the plan's threat model (T-07-10-01..05 mitigated/accepted and tested).

## Next Phase Readiness

- 07-11 (phase gate) can run the full suite and the traceability; `world_map.dart`, `map_utils.dart` and `map_constants.dart` are untouched by this plan.

## Self-Check: PASSED
