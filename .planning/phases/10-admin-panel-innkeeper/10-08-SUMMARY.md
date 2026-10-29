---
phase: 10-admin-panel-innkeeper
plan: 08
subsystem: map
tags: [map, teleport, pawn, drag, refactor, ui, tdd]
requires: [10-04]
provides:
  - MapUtils.dropTargetCity (lib/screens/mainScreen/tabs/map/utils/map_utils.dart)
  - mixin PawnDragging (lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart)
  - pawnScaleForZoom + PawnLabel (lib/screens/mainScreen/tabs/map/layers/pawn_visuals.dart)
  - TeleportPawnLayer (lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart)
  - TeleportModeChip + teleportFailureTextOf (lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart)
affects: [10-09, 10-10]
tech-stack:
  added: []
  patterns: [State mixin with abstract hooks for layer-level drag bookkeeping, shared pawn visuals file]
key-files:
  created:
    - lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart
    - lib/screens/mainScreen/tabs/map/layers/pawn_visuals.dart
    - lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart
    - lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart
    - test/screens/mainScreen/tabs/map/utils/map_utils_test.dart
    - test/screens/mainScreen/tabs/map/teleport_pawn_layer_test.dart
    - test/screens/mainScreen/tabs/map/components/teleport_mode_chip_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/utils/map_utils.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
key-decisions:
  - "The Phase 7 drop rule lives once in MapUtils.dropTargetCity; the layer-level LatLng conversion and the release live once in the PawnDragging mixin (own pawn + teleport pawn)"
  - "_TravelLabel moved (not copied) to the public PawnLabel; the pawn scale formula moved to pawnScaleForZoom"
  - "TeleportModeChip is a parchment DecoratedBox with a 44x44 GestureDetector «Annulla»; failure copy per code only (D-17)"
requirements-completed: []
duration: 20min
completed: 2026-10-29
---

# Phase 10 Plan 08: Map teleport pieces Summary

The Phase 7 drop rule and drag bookkeeping are extracted once (`MapUtils.dropTargetCity`, `PawnDragging` mixin, `PawnLabel`/`pawnScaleForZoom`) with the own pawn behaving exactly as before, and on top of them the teleport mode gets its `TeleportPawnLayer` (only the chosen character's pawn with a floating name, draggable with the same drop rule) and the in-style `TeleportModeChip` («Annulla» + per-code failure line).

## What was built

- **Task 1 (refactor):** `static City? dropTargetCity(LatLng point, List<City> cities)` in `MapUtils` (hand edit, DIRTY file); `pawn_visuals.dart` with `double pawnScaleForZoom(double zoom)` and `PawnLabel({key, required String text})` (the former `_TravelLabel` body: `IgnorePointer` + parchment `DecoratedBox` + `AutoSizeText` `labelLarge`/`darkWood`); `pawn_dragging.dart` with `mixin PawnDragging<T extends StatefulWidget> on State<T>` — getter `LatLng? dragPoint`, abstract `MapController get pawnMapController`, `List<City> get dropCities`, `void onPawnDragUpdate(LatLng point)`, `void onPawnDragEnd(LatLng? finalLocation, City? targetCity)`, and the handlers `handlePawnDragUpdate(DragUpdateDetails)` / `handlePawnDragEnd()`. `_CharacterMarkerLayerState` now `with PawnDragging<CharacterMarkerLayer>`, uses `dragPoint`, `pawnScaleForZoom`, `PawnLabel` (keys `travelLabelKey` / `awaitingAidLabelKey` unchanged); `_dragPoint`, `_handleDragUpdate`, `_handleDragEnd`, `_calculateCharacterScale`, `_TravelLabel` and the `auto_size_text`, `kg_theme`, `map_utils` imports are gone.
- **Task 2:** `TeleportPawnLayer({key, required TeleportTarget target, required List<City> cities, required ValueNotifier<double> zoomNotifier, required MapController mapController, required bool canDrag, required onDragUpdate(LatLng), required onDragEnd(LatLng?, City?)})`, keys `TeleportPawnLayer.pawnKey` = `ValueKey('map.teleportPawn')`, `TeleportPawnLayer.nameLabelKey` = `ValueKey('map.teleportNameLabel')`; `String? teleportFailureTextOf(InnkeeperFailure?)`; `TeleportModeChip({key, required String characterName, required InnkeeperFailure? failure, required bool isTeleporting, required VoidCallback onCancel})` with `cancelKey` = `ValueKey('map.teleportCancel')`, `cancelLabel` = 'Annulla'.

DIRTY files, hand edits only (`git diff --stat 3161c18 09ae4d0`):

```
 .../tabs/map/layers/character_marker_layer.dart    | 101 +++++----------------
 .../mainScreen/tabs/map/utils/map_utils.dart       |   5 +
 2 files changed, 27 insertions(+), 79 deletions(-)
```

## TDD evidence

- Task 1 RED (`3161c18`): compile failure — `Error: Member not found: 'MapUtils.dropTargetCity'`, `Error: Method not found: 'pawnScaleForZoom'`. GREEN (`09ae4d0`): `test/screens/mainScreen/tabs/map` 175/175 (4 new + every Phase 7 marker/travel/availability test unchanged).
- Task 2 RED (`e9ba1aa`): compile failure — `Error when reading 'lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart': No such file or directory`, `Error when reading '.../layers/teleport_pawn_layer.dart'`, `Method not found: 'TeleportPawnLayer'`. GREEN (`244a883`): teleport_pawn_layer_test 4/4, teleport_mode_chip_test 10/10.
- `test/screens/mainScreen/tabs/map`: 189 green. Full suite: 2785 green (2767 + 18). Analyzer: 51 issues (all info), gate exit 0.

## Deviations from Plan

1. **Mixin `handlePawnDragUpdate` uses early returns** (`renderObject is! RenderBox`, then `!hasSize || !attached`) instead of the nested `if`: same behaviour, Clean Code early-return rule.
2. **Teleport test duplicates `cityA`/`cityB`** locally (no import from another test file); `map_utils_test` uses its own `aldheim` with an `area` placed near Valdoria's marker so that «contains» and «nearest» give different answers.
3. **`TeleportModeChip` cancel `Center(widthFactor: 1, heightFactor: 1)`** so the hit area hugs the 44×44 minimum instead of expanding to the column width; padding uses `spacingMd`/`spacingXs`.

## Known Stubs

None. Copy and visuals provisional (D-22) as planned; the layer and chip are not wired into `WorldMap` yet (plan 10-09).

## Threat Flags

None — T-10-30 (Phase 7 tests untouched and green, one `dropTargetCity`), T-10-31 (conversion at layer level in the mixin, drop tested to cityB), T-10-32 (per-code Italian copy) mitigated.

## Self-Check: PASSED

- Files created exist; commits 3161c18, 09ae4d0, e9ba1aa, 244a883 present on `feat/10-admin-panel`.
