---
phase: 21-innkeeper-mission-completion-flow
plan: 08
subsystem: map
tags: [teleport, poi, map, drop-rule]
requires: ["21-07"]
provides:
  - "teleportDropTarget({releasePoint, places, cities, toScreen, radius = teleportPlaceDropRadius}) — pure rule: nearest inner place within 32 screen px, else TeleportDestination.ofCity(MapUtils.dropTargetCity(...)) (D-01, D-29)"
  - "PawnDragging.resolvePawnDrop(LatLng) — overridable hook; default = Phase 7 city rule (player unchanged, Pitfall 6)"
  - "TeleportPawnLayer({target, places, cities, zoomNotifier, mapController, canDrag, onDragUpdate, onDrop}) — onDrop(TeleportDestination?) replaces onDragEnd"
  - "TeleportPoiLayer({places, zoomNotifier}) — one 14 px dot per inner place from city zoom, no tap; placeKeyFor(poiId)"
  - "Chip copy «Trascina {nome} su una città o un luogo»"
affects: [21-09, 21-13, 21-18]
tech-stack:
  added: []
  patterns: ["mixin hook overridden only by the teleport pawn", "pure drop rule with an injected screen projection"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/map/utils/teleport_drop.dart
    - lib/screens/mainScreen/tabs/map/layers/teleport_poi_layer.dart
    - test/screens/mainScreen/tabs/map/utils/teleport_drop_test.dart
    - test/screens/mainScreen/tabs/map/layers/teleport_poi_layer_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/layers/pawn_dragging.dart
    - lib/screens/mainScreen/tabs/map/layers/teleport_pawn_layer.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart
    - test/screens/mainScreen/tabs/map/teleport_pawn_layer_test.dart
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
    - test/screens/mainScreen/tabs/map/components/teleport_mode_chip_test.dart
decisions:
  - "Drops on inner places are resolved even below city zoom (dots hidden): the rule does not depend on visibility"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 21 Plan 08: Map inner-POI layer and teleport-only drop rule Summary

The innkeeper's teleport pawn now drops on the nearest inner place within 32 screen pixels (ruins, caves…) or else on the city of the Phase 7 rule; a purple dot per inner place is drawn only in teleport mode from city zoom; the player's travel drop is untouched. Live on today's BE: inner-POI teleport can be tried on the device.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Pure teleport drop rule and the overridable drop hook | 431808a0 (RED), ee1694d4 (GREEN) |
| 2 | POI layer, teleport pawn over destinations, world map wiring and chip copy | c62a312e (RED), 8f02e496 (GREEN) |
| 3 | Bookkeeping | this commit |

### RED evidence
- Task 1: `teleport_drop_test.dart` failed to compile — `lib/screens/mainScreen/tabs/map/utils/teleport_drop.dart` missing, `teleportDropTarget` not found.
- Task 2: compilation failure — `teleport_poi_layer.dart` missing, `TeleportPoiLayer` undefined in `world_map_teleport_test.dart` and `teleport_poi_layer_test.dart`; `teleport_pawn_layer_test.dart` used the new `places`/`onDrop` parameters.

### Retargeted pins
- `teleport_pawn_layer_test.dart` «releasing east resolves the nearest city» → «… (D-01)»: the recorder stores `TeleportDestination?`; expects `[TeleportDestination.ofCity(cityB)]` (point = Valdoria marker). Group renamed `teleport drag (D-01, D-29)`. New case «releasing on an inner place reports the place (D-29)».
- `world_map_teleport_test.dart` «only the chosen pawn and the cities are on the map» → «only the chosen pawn, the cities and the places are on the map», now also expects one `TeleportPoiLayer`. New cases: «teleport mode shows the places layer between cities and pawn (D-29)» (layer order in `FlutterMap.children`), «player mode has no places layer (D-29)», «a drop on an inner place teleports there (D-01)».
- `teleport_mode_chip_test.dart` «invites to drag the character and offers Annulla» → «invites to drag the character on a city or a place and offers Annulla (D-29)»; the «reads in progress while teleporting» negative check now looks for the new copy too.

### Green at first run
None of the new cases: all were RED by compilation.

## Verification
- `flutter test test/screens/mainScreen/tabs/map` after Task 1: +284 green (player travel pins included).
- `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/components/teleport_mode_landing_test.dart`: +298 green.
- Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.
- `map_utils.dart` and `character_marker_layer.dart` untouched (`git diff HEAD~4 --stat` empty).
- Formatted one by one (all formatter-clean before): teleport_drop.dart, teleport_drop_test.dart, pawn_dragging.dart, teleport_pawn_layer.dart, teleport_pawn_layer_test.dart, teleport_poi_layer.dart, teleport_poi_layer_test.dart, world_map.dart, world_map_teleport_test.dart, teleport_mode_chip.dart, teleport_mode_chip_test.dart.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Unused import in the RED test**
- **Found during:** Task 1 GREEN analyzer gate (48 infos)
- **Issue:** `package:flutter/widgets.dart` in `teleport_drop_test.dart` was redundant with `flutter_test` (`unnecessary_import` info, baseline 47 broken).
- **Fix:** import removed in the GREEN commit ee1694d4.

Otherwise the plan executed as written. Test helpers: inner-place points in the widget tests are computed from the map camera (`screenOffsetToLatLng(latLngToScreenOffset(aldheimMarker) + dragOffset)`) so the drag ends on the place regardless of the projection.

## Known Stubs
None.

## Threat Flags
None (T-21-24..26 mitigated as planned: default hook unchanged, layer only in `_teleportLayers`, dot without tap or label).

## Self-Check: PASSED
