---
phase: 06-quest-accept-info-sheets
plan: 11
subsystem: map
tags: [map, quest-paper, state-label, overlay, tdd]
requires: [06-02, 06-06, 06-09]
provides:
  - QuestPaperLayer (standard-lane intact paper + server-driven state label, top-left, tap -> onOpen)
  - QuestInfoOverlay.stateLabel (read-only sheet with optional state line)
  - WorldMap wiring (_openFromPaper, label cleared by marker selection)
affects: [06-12]
key-files:
  created:
    - lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart
    - test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart
    - test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
decisions:
  - "The paper layer reads CharacterCubit and QuestCubit; anything missing (lane, catalogue entry, loaded state) renders nothing, never a spinner"
  - "No Timer/Ticker/DateTime.now: label depends only on startDate == null and the quest type"
metrics:
  tasks: 2
  tests: "1306 -> 1317 passing, analyze 54 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 11: Quest paper on the Map Summary

The accepted standard-lane quest stays on the Map as its intact board paper (top-left, slight tilt, token styling) with the state label `In viaggio` / per-type text; tapping it opens the existing read-only overlay with the state line, with no swipe gesture.

## Commits

- 3ca9f45 / 9e732ce: test then feat for `QuestPaperLayer` (RED: undefined class)
- 3ca9f45 + 3f3f733 test(map): overlay tests (RED: no `stateLabel` parameter); 3f3f733 fixes a wrong `TearablePaper` import path in the first commit
- 9355c2a feat(map): open the accepted quest read-only from its paper

## Deviations from Plan

**1. [Rule 3 - Blocking] Wrong import path in the overlay test.** `TearablePaper` lives in `shared/components/tear/`; the RED commit was split into two (3ca9f45, 3f3f733). No behavioural impact.

## Notes

- `world_map.dart` and `quest_info_overlay.dart` hand-edited; diff only contains the planned hunks.
- Map is not re-centred; visuals provisional (D-19).

## Known Stubs

None.

## Self-Check: PASSED

Files and commits verified; full `flutter test` green (1317), `flutter analyze` 54 issues (<= 56), 0 errors.
