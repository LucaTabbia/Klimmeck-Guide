---
phase: 07-travel
plan: 08
subsystem: ui
tags: [flutter, dart, flutter_map, polyline, bottom-sheet, bloc, travel, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-01)
    provides: "`TravelPreview` / `TravelPath`, `City.relatedLore.image`, `travel_fixtures.dart`"
  - phase: 07-travel (07-02)
    provides: "`formatTravelDistance`, `formatTravelDuration`, `formatArrival`"
  - phase: 07-travel (07-06)
    provides: "`TravelProgressCubit` with `TravelProgressIdle` / `TravelProgressActive { route, travelled, remaining, ... }`"
  - phase: 07-travel (07-07)
    provides: "`TravelCubit` states and `start()` / `cancel()`, `MockTravelCubit`"
provides:
  - "`TravelRouteLayer` + pure `travelRoutePolylines({progress, travel})`: dashed preview while confirming/starting/started, two-tone live route, nothing when idle"
  - "`TravelConfirmationSheet` (StatefulWidget): destination name/image, backend distance/duration/ETA, `…` placeholders, Parti/Resta, self-closing on start/rejection and post-frame guard on an already settled flow"
  - "`test/helpers/map_harness.dart` (`mapHarness(layers, controller:, onMapReady:)`) and `MockTravelProgressCubit`"
affects: [07-09, 07-10, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Map layer fed by two cubits through a pure polyline function, unit-tested apart from the widget"
    - "Sheet mounted outside the shell providers reads the cubit via `BlocProvider.value`; a post-frame check closes it when the flow settled before the first frame"

key-files:
  created:
    - lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
    - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
    - test/helpers/map_harness.dart
    - test/screens/mainScreen/tabs/map/travel_route_layer_test.dart
    - test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart
  modified:
    - test/helpers/mocks.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "`_dashed` is a `final` top-level: `StrokePattern.dashed` asserts on `segments.length`, so it cannot be a const expression in flutter_map 8.2.1 (fallback foreseen by the plan)"
  - "Sheet text styles: destination in `textTheme.titleMedium` (the app theme defines no `headlineSmall`), labels/values in `bodyMedium`, placeholder tinted `darkBronze`"
  - "Actions order Resta | Parti, each a `TextButton` (min 44x44, `darkWood`) wrapped in `Semantics(label:, button: true)`"

patterns-established:
  - "`mapHarness` for every map layer test: offline `FlutterMap` (Epsg4326, centre 0,0, zoom 2) with only the layers under test"

requirements-completed: []

# Metrics
duration: 7min
completed: 2026-10-24
---

# Phase 7 Plan 08: Travel route layer and confirmation sheet Summary

**`TravelRouteLayer` draws the backend road from cubit states only (one dashed `darkWood` polyline from the confirmation until `activeTravel`, then the travelled part solid `royalCrimson` and the remaining part dashed), and `TravelConfirmationSheet` shows the destination at once, the backend distance/duration/ETA after the preview, and makes "Parti" the only path to `startTravel`; plus the offline `mapHarness` used by every map test of the phase.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-10-24T14:45:40Z
- **Completed:** 2026-10-24T14:52:00Z
- **Tasks:** 2
- **Files modified:** 5 created + 1 modified (+ 3 planning files)

## Accomplishments

- `travelRoutePolylines`: live route wins when `TravelProgressActive` with a non-empty route; otherwise the preview road of `TravelConfirming` / `TravelStarting` / `TravelStarted` (exhaustive switch on the sealed state), so there is no flicker between "Parti" and `activeTravel` (Pitfall 4). Parts with fewer than 2 points are skipped; nothing to draw -> `SizedBox.shrink()` instead of a `PolylineLayer` (T-07-08-01).
- `TravelConfirmationSheet`: `AutoSizeText` destination name, `CachedSvg` lore image (120x120) only when present, three rows `Distanza` / `Durata` / `Arrivo` with values from a private record built only for `TravelConfirming` / `TravelStarting` (`formatTravelDistance`, `formatTravelDuration(ms)`, `formatArrival(eta, serverNow: previewedAt)`), otherwise `…` in `darkBronze`. No cost row, no spinner, no chrome.
- "Parti" enabled only in `TravelConfirming` (T-07-08-02); "Resta" calls `cancel()` and pops. A `BlocListener` pops on `TravelStarted` / `TravelFailed`; `initState` schedules `_closeIfAlreadySettled()` which pops when the state is already `TravelIdle` / `TravelFailed` at mount.
- `mapHarness` (no tile layer, no network) and `MockTravelProgressCubit` (hand-added to the non-formatter-clean `mocks.dart`).

## Task Commits

| # | Task | Commit | Type |
|---|------|--------|------|
| 1 | RED: map harness, `MockTravelProgressCubit`, route layer tests | `962704a` | test |
| 1 | GREEN: travel route layer (dashed preview, two-tone live route) | `b5832ab` | feat |
| 2 | RED: confirmation sheet tests | `8039720` | test |
| 2 | GREEN: parchment travel confirmation sheet | `8dc509f` | feat |

## Verification

- `flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart` -> 12 passed (7 widget + 5 pure-function tests).
- `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` -> 13 passed (including 3 `already ... at mount` mount-guard tests).
- `flutter test test/screens/mainScreen/tabs/map` -> 65 passed.
- `flutter analyze` on all touched lib/test files -> No issues found.
- `dart format --output=none --set-exit-if-changed` on the 5 new files -> exit 0 (`test/helpers/mocks.dart` was already not formatter-clean: hand-edited only).
- Acceptance greps: all as specified (`Widget mapHarness(` 1, `TileLayer` 0, `MockTravelProgressCubit extends MockCubit<TravelProgressState>` 1, `List<Polyline> travelRoutePolylines({` 1, `StrokePattern.dashed` 1, `Color(0x` 0; sheet: chrome 0, `'Parti'` 1, `'Resta'` 1, `costo` 1, `addPostFrameCallback` 1, `already` in test 3, `formatArrival(` 1, repository/service 0, `Color(0x|fontSize:` 0).
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` -> 1318 passed.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `StrokePattern.dashed` is not const-evaluable**
- **Found during:** Task 1 GREEN (`const_eval_property_access` on `segments.length`)
- **Fix:** `_dashed` became `final StrokePattern _dashed = StrokePattern.dashed(segments: const [12, 8]);`, the fallback the plan anticipated.
- **Files modified:** lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
- **Commit:** `b5832ab`

### Notes

- An unused `package:flutter/material.dart` import in the RED route-layer test was removed in the GREEN commit (`b5832ab`) to keep `flutter analyze` clean.
- `headlineSmall` (suggested by the plan) is not defined by the app `TextTheme`; the destination uses `titleMedium` (Cinzel), still a theme token.
- In the modal pop tests "Resta" is invoked through `onPressed` because the `DraggableScrollableSheet` opens at 50% and the button sits below the fold on the 780x360 surface; direct-mount tests tap it for real.

## Issues Encountered

None.

## Known Stubs

None. The widgets are complete; mounting them on the map (opening the sheet, inserting the layer) is plan 07-09 by design.

## Threat Flags

None: no new surface beyond the plan's threat model (T-07-08-01..05 mitigated and tested).

## Next Phase Readiness

- 07-09 can insert `const TravelRouteLayer()` under the markers (needs `TravelProgressCubit` and `TravelCubit` above `FlutterMap`) and open the sheet with `showModalBottomSheet(... BlocProvider<TravelCubit>.value(value: cubit, child: PaperSheetModal(child: TravelConfirmationSheet(destination: city))))`.
- `mapHarness` and `MockTravelProgressCubit` are ready for the map tests of 07-09 / 07-10.

## Self-Check: PASSED
