---
phase: 17-unlockable-lore
plan: 12
subsystem: map
tags: [map, unknown-city, pawn-tap, hit-test, tdd]

requires:
  - phase: 17-08
    provides: "UnknownCityModal(cityName:) with line; WorldMap._openCityLore → name-only sheet or loadLoreData (D-11)"
  - phase: 17-11
    provides: "CachedSvg placeholder is an empty box while the file loads (D-21): opaque hit-test on tappable pictures"
provides:
  - "UnknownCityModal stretched to the width its paper host gives it (CrossAxisAlignment.stretch): name and line centred on the sheet (D-23)"
  - "CharacterMarkerLayer.onCityTap (optional): a tap without drag on the idle pawn opens the city whose marker it stands on, resolved by currentCityOf (D-24)"
  - "WorldMap._gameLayers wires CharacterMarkerLayer(onCityTap: _openCityLore); teleport layers untouched"
affects: [17-10]

tech-stack:
  added: []
  patterns:
    - "Draggable child = GestureDetector(behavior: HitTestBehavior.opaque, onTap: …): a tap never starts a drag, a drag is never blocked by the tap recognizer"
    - "the city under the pawn is resolved by marker id with the shared currentCityOf (board_policy.dart), never by PointOfInterest equality"

key-files:
  created: []
  modified:
    - lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/screens/mainScreen/tabs/map/components/unknown_city_modal_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart

key-decisions:
  - "The pawn tap reuses the existing currentCityOf(cities, location) of lib/models/quest/board_policy.dart (id comparison already used by WorldMap, board, shop, satchel) instead of a new _cityUnderPawn with firstWhereOrNull"
  - "The D-23 test host is 800 px wide with a 50 px padding (inner 700): with the plan's 400/50 host the case was green at the first run because the test font wraps the line and widens the Column to the whole host already"
  - "The tap detector on the pawn is opaque (D-21): the pawn is tappable and draggable even before its SVG file is on disk"

requirements-completed: []

duration: ~22min
completed: 2026-11-08
---

# Phase 17 Plan 12: Centred unknown-city sheet and city tap from the pawn Summary

**The name-only paper sheet fills the width its `PaperSheetModal` host gives it, so the city name and «Non conosci ancora questa città.» read centred on the paper (D-23); a tap without drag on the idle pawn opens the city whose marker the character stands on through the same `_openCityLore` path as a marker tap (lore when known, name-only sheet when not), while the drag, the travelling pawn and the teleport pawn are unchanged (D-24).**

## Performance

- **Duration:** ~22 min (2026-11-08T19:33Z → 19:41Z)
- **Tasks:** 3/3
- **Files:** 7 Dart files modified (3 lib, 4 test) + this SUMMARY + bookkeeping
- **Commits:** 4 code (2 RED, 2 GREEN) + 2 docs

## Accomplishments

### Task 1 — unknown-city sheet centred on the paper (D-23)
- `lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart`: `Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [...])`; the `AutoSizeText` name and the `Text` line keep `textAlign: TextAlign.center`; copy (`static const String line = 'Non conosci ancora questa città.'`), sizes and spacers untouched. Inside `PaperSheetModal` (`Stack → Padding(horizontal: width / 7) → SizedBox(height: width, child: child)`) the child receives a bounded max width and no forced width: stretched, the Column takes the whole inner width and the texts centre on it.

### Task 2 — a tap on the idle pawn opens the city it stands on (D-24)
- `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart`:
  - `const CharacterMarkerLayer({super.key, required this.cities, required this.zoomNotifier, required this.mapController, required this.bounds, required this.onDragUpdate, required this.onDragEnd, this.onCityTap})`; `final void Function(City city)? onCityTap;` (optional: the existing tests and the teleport build stay valid).
  - `VoidCallback? _cityTapOf(CharacterLoaded state, TravelState travel)`: `null` unless `widget.onCityTap != null`, `travel is TravelIdle` and `currentCityOf(widget.cities, state.character.status?.location)` finds a city (marker id == location id); otherwise `() => onCityTap(city)`.
  - `_buildIdlePawn` passes `onTap: _cityTapOf(state, travel)` to `_buildDraggablePawn(String pawnPath, {required bool canDrag, VoidCallback? onTap})`, whose `Draggable.child` is now `GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: _pawn(pawnPath))`. `_buildTravellingPawn` keeps `_scaled(_pawn(pawnPath))` with no gestures (D-08/D-13).
  - New import `'../../../../../models/quest/board_policy.dart'` (for `currentCityOf`).
- `lib/screens/mainScreen/tabs/map/world_map.dart`: `_gameLayers()` → `CharacterMarkerLayer(..., onCityTap: _openCityLore)`; `_teleportLayers` untouched (`CityMarkersLayer` without callback + `TeleportPawnLayer`).

### Task 3 — gates and bookkeeping
- Full suite `01:15 +3443: All tests passed!` (3437 at 17-11 + 6 new cases). Analyzer `50 issues found.` (0 error / 0 warning, the baseline). `dart format --output=none --set-exit-if-changed` → `FORMAT_OK` on the 7 touched Dart files. Trailers `git log 215f1fc..HEAD --format=%B | grep -ciE 'co-authored-by|generated with|claude-session'` → `0`.

## Task Commits

1. Task 1 RED `a5dd4a0` test(map): centre the unknown-city sheet on the paper (D-23); GREEN `b04f73b` fix(map): stretch the unknown-city sheet to the paper width
2. Task 2 RED `8adf0f7` test(map): open the city under the pawn on tap (D-24); GREEN `11dd8f9` feat(map): open the city sheet from a tap on the idle pawn
3. Task 3 `docs(phase-17): record the plan 12 gates` (this SUMMARY); bookkeeping `docs(phase-17): record plan 12 progress` (ROADMAP 11/12 + `[x] 17-12-PLAN.md`, STATE `Plan: 11 of 12`, VALIDATION rows 17-12-01/02 green)

## RED failures observed

- Task 1 (`unknown_city_modal_test.dart`, «fills the paper width and centres the name and the line (D-23)»): `Expected: <700> / Actual: <576.0>` at `tester.getSize(find.byType(UnknownCityModal)).width` — the Column is as wide as its widest text (the unwrapped line, 32 glyphs × 18 px under the test font) and sits at the left edge of the padding. With the plan's literal host (`SizedBox(width: 400)`, padding 50, expected width 300 / centre 200) the case was **green at the first run**: the 576 px line wraps inside 300 px and the wrapped `Text` takes the whole 300 px, so the Column already filled the host and `CrossAxisAlignment.center` (the default) centred the name on it (see deviation 1).
- Task 2 (`character_marker_layer_test.dart`): compile failure `Error: No named parameter with the name 'onCityTap'` (`pumpLayer` → `CharacterMarkerLayer(onCityTap: tapped.add)`), whole file red.
- Task 2 (`world_map_teleport_test.dart`, «tapping the pawn on an unknown city opens the name-only sheet (D-24)»): `Expected: exactly one matching candidate / Actual: Found 0 widgets with type "UnknownCityModal"` — the seeded pawn picture hit-tests, the `MarkerLayer` above `CityMarkersLayer` wins the hit test and the city marker under the pawn never receives the tap: the device finding reproduced in the harness.

## Tests

- `unknown_city_modal_test.dart` (2 cases): new «fills the paper width and centres the name and the line (D-23)» — host `Align(topLeft) → SizedBox(800×600) → Stack → Padding(horizontal 50) → SizedBox(height 400) → UnknownCityModal('Bosa')`; asserts width 700 and both text centres `closeTo(400, 1)`. The D-11 case unchanged.
- `character_marker_layer_test.dart` (+4, 17 cases): `characterLoaded({String locationId = 'city-marker-1', activeTravel, pendingQuest, awaitingAid})`; `late List<City> tapped` recorder, `pumpLayer` passes `onCityTap: tapped.add`; group «pawn tap (D-24)» with the helper `tapPawn(tester)` (`tester.tap(find.byKey(CharacterMarkerLayer.pawnKey))` + `pump(const Duration(seconds: 1))`, the unconsumed tap goes to the map which waits for a double tap, as the existing «the layer without a callback leaves the markers inert» case): «a tap on the idle pawn opens the city it stands on (D-24)» (`tapped == [cityA]`, `dragEnds` empty, pawn still `home`), «a tap on the pawn away from any city marker opens nothing (D-24)» (`locationId: 'poi-road-1'`), «a tap while a travel sheet is open opens nothing (D-24)» (`travel: confirming()`), «a tap on the travelling pawn opens nothing (D-24)» (`activeTravelJson()` + `travelling()`). The D-01 drag case «releasing east resolves the nearest city» stays green (T-17-38).
- `world_map_teleport_test.dart` (+1): «tapping the pawn on an unknown city opens the name-only sheet (D-24)» — `unknownCity` (`city-3`/«Bosa», marker `city-marker-3` at `[-10.0, -20.0]`, `type: drusteaCapital`, `relatedLore: null`), `characterLoaded(locationId: 'city-marker-3', location: bosaMarker)`, `pumpWorldMap(cities: [cityA, cityB, unknownCity])`, real `tester.tap` on the pawn → one `UnknownCityModal` with «Bosa» and the line, no `CityModal`, `verifyNever(loadLoreData)`, `verifyNever(travelCubit.preview)`, no exception.
- `world_map_travel_test.dart` (harness): `pumpWorldMap(tester, {required character, travelState, serverNow, quests, teleportState, List<City>? cities})` → `WorldMap(cities: cities ?? [cityA, cityB])`.
- Task 1: task file 2/2; `flutter test test/screens/mainScreen/tabs/map` → `+235`. Task 2: `+240`. Task 3: full suite `+3443`.
- Acceptance greps: Task 1 `CrossAxisAlignment.stretch` 1, copy line 1, `D-23)` 1; Task 2 `onCityTap: _openCityLore` 2, `onCityTap` in the layer 5, `HitTestBehavior.opaque` 1, `D-24)` 5 (layer test) / 1 (teleport test), `git diff --stat` on `teleport_pawn_layer.dart` and `quest_markers_layer.dart` empty.

## Files formatted

Every touched Dart file by name, each `0 changed` (all 7 were format-clean at baseline, checked with `dart format --output=none --set-exit-if-changed` before editing; `character_marker_layer.dart`, listed as dirty by the research of 2026-11-07, was clean at HEAD `215f1fc`). `cached_svg.dart`, `dropdown.dart`, `city_modal.dart` untouched.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - TDD] D-23 test host widened so the case fails before the fix**
- **Found during:** Task 1 RED (the plan's `SizedBox(width: 400)` / padding 50 / expected 300 and 200 passed at the first run: under the test font the line is 576 px wide, wraps inside 300 px and widens the Column to the whole host already).
- **Fix:** host `SizedBox(width: 800, height: 600)`, padding 50, expected width 700 and centres `closeTo(400, 1)` — wider than the unwrapped line, so the unstretched Column (576 px at x = 50) fails and the stretched one passes. Same host shape as the plan (mirrors `PaperSheetModal`), same assertions, different numbers; a comment in the test says why.
- **Commit:** `a5dd4a0`.

**2. [Boy Scout - zero duplication] `currentCityOf` instead of a new `_cityUnderPawn`**
- The plan sketched `_cityUnderPawn` with `firstWhereOrNull` over `markerLocation?.id == location?.id`; `lib/models/quest/board_policy.dart` already exposes `City? currentCityOf(List<City> cities, PointOfInterest? location)` with exactly that id comparison (used by `WorldMap._refreshPartyCount`, the board, the shop, the satchel). The layer imports it; no `package:collection` import. **Commit:** `11dd8f9`.

**3. [Rule 3 - harness] `pumpWorldMap` takes an optional `cities` list**
- `test/screens/mainScreen/tabs/map/world_map_travel_test.dart` (outside `files_modified`) hard-coded `WorldMap(cities: [cityA, cityB])`, both with lore; the D-24 case needs an unknown city under the pawn. Additive `List<City>? cities` parameter, default unchanged, no existing case touched (the plan: «add a fixture rather than changing the existing cases»). Likewise `characterLoaded` of the layer test gains `locationId` (default `'city-marker-1'`). **Commit:** `8adf0f7`.

### Test details beyond the plan (noted)
- The three «opens nothing» cases pump one second after the tap (double-tap wait of the map) and assert `tester.takeException()` null; the positive case also pins `pawnPoint == home`.
- The D-24 world-map case also asserts `verifyNever(travelCubit.preview(...))` (T-17-38: a tap never starts a travel).

## Notes for the UAT (17-10) and BACKEND-NOTES

- The pawn detector is opaque: the player's pawn is now tappable and draggable even in the instant before its SVG file is on disk (before, the D-21 empty placeholder did not hit-test). A tap on the pawn while a travel sheet is open or while travelling does nothing, as before.
- The tap on the pawn goes through `_openCityLore`: on a known city the lore sheet opens (`loadLoreData`), on an unknown one the name-only sheet; nothing is decided on the FE (`City.relatedLore` from the viewer-filtered `cities` read).
- No GraphQL document, model or fragment touched; registry unchanged.

## Shared result files with the parked FE Phase 16 (CONTEXT D-18)

Not touched.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: T-17-37 accepted (same `_openCityLore` path, no new data path); T-17-38 mitigated by the D-01 drag case staying green next to the four D-24 tap cases and by `verifyNever(preview)` in the world-map case. No new network endpoint, auth path, file access or schema change.

## Self-Check: PASSED

- Files exist: `unknown_city_modal.dart`, `character_marker_layer.dart`, `world_map.dart`, `unknown_city_modal_test.dart`, `character_marker_layer_test.dart`, `world_map_teleport_test.dart`, `world_map_travel_test.dart`, this SUMMARY.
- Commits `a5dd4a0`, `b04f73b`, `8adf0f7`, `11dd8f9` in `git log`.
