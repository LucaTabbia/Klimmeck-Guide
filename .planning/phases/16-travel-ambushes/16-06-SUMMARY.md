---
phase: 16-travel-ambushes
plan: 06
subsystem: map
tags: [flutter, dart, characterization, travel, reroute, ambush, pins]

requires:
  - phase: 16-05
    provides: presenter + carousel (the last lib change of the phase before the park)
provides:
  - Reroute proof on TravelProgressCubit (group 'lost ambush reroute (Phase 16)', 4 cases, D-03)
  - Reroute proof on the real WorldMap (group 'lost ambush reroute (D-03)', 3 cases, D-02/D-03)
  - D-07/D-17 pins on TravelConfirmationSheet (2 cases) and QuestTravelLine (1 case)
affects: [16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "Characterization tests: describe behaviour that already holds, green at first run by design"

key-files:
  created: []
  modified:
    - test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
    - test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart
    - test/models/quest/quest_travel_line_test.dart

key-decisions:
  - "No production change for the reroute (research F6): TravelProgressCubit.follow rebuilds on any ActiveTravel change and the map renders the rewritten travel as received (D-03)"

requirements-completed: []

duration: 7min
completed: 2026-11-06
---

# Phase 16 Plan 06: Reroute proof and D-07/D-17 pins Summary

Characterization tests prove that a BE-rewritten `activeTravel` restarts the pawn at the ambush point, draws the new dashed route, updates the remaining time, refocuses the camera and gets a fresh arrival budget; the confirmation sheet and the quest «Viaggio» line are pinned against any ambush wording. Zero lib change.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Reroute proof on TravelProgressCubit and on the WorldMap | 897e6ab | travel_progress_cubit_test.dart, world_map_travel_test.dart |
| 2 | Pin the confirmation sheet and the quest «Viaggio» line (D-07, D-17) | 785baaa | travel_confirmation_sheet_test.dart, quest_travel_line_test.dart |

## Cases (all green at first run — reason: no production change needed, research F6 / D-07)

travel_progress_cubit_test.dart, group `lost ambush reroute (Phase 16)` (local helpers `advanceBy(FakeAsync, FakeServerClockService, Duration)` and `followReroute(FakeAsync, FakeServerClockService, {ArrivalRereadLedger? rereads})`; ambush wire = `[ambushPoint.latitude, ambushPoint.longitude]`, Pitfall 6):
- a lost ambush reroute restarts the pawn from the ambush point (D-03)
- the remaining route is the whole new road from the pawn (D-03)
- the pawn then advances along the new road (D-03)
- the rerouted travel gets a fresh arrival budget (D-03)

world_map_travel_test.dart, group `lost ambush reroute (D-03)` (local helper `pumpRerouted(WidgetTester)`; import `package:klimmeck_guide/utils/game_duration_format.dart` added):
- the dashed route follows the rewritten travel from the ambush point (D-03)
- the remaining time follows the rewritten travel (D-03)
- a focus after the defeat centres the rerouted pawn (D-02, D-03)

travel_confirmation_sheet_test.dart (local `phase15Labels` + `expectThePhase15RowsInOrder(WidgetTester)`):
- shows exactly the Phase 15 rows and never mentions an ambush (D-07, D-17)
- a starving preview still never mentions an ambush (D-07, D-17)

quest_travel_line_test.dart:
- the line keeps the Phase 15 text and never mentions an ambush (D-07, D-17)

Run output Task 1: `00:02 +72: All tests passed!`; Task 2 (with the registry test, «the registry lists 45 documents (D-12)» still green): `00:01 +39: All tests passed!`.

The first run of the cubit file failed to COMPILE (not a behavioural RED): `TravelProgressActive.position` is `LatLng?`, so `state.position.latitude` was rejected; fixed in the test with `state.position!` before any assertion ran. No behavioural case was ever red.

## Gates

- `flutter analyze`: 50 issues (all info), 0 error, 0 warning after each task.
- Plan verification `flutter test test/screens/mainScreen/tabs/map test/models/quest test/tool`: `00:09 +397: All tests passed!`
- FULL suite (orchestrator instruction, foreground): `01:13 +3390: All tests passed!`
- `dart format` on the four touched test files only, one by one.
- `git diff develop --stat -- lib/screens/mainScreen/tabs/map lib/models/travel lib/screens/mainScreen/travelCubit` → empty; `git diff develop --stat` on the confirmation sheet, quest line, travel queries and travel preview fragment → empty; `Imbosc` absent from the three travel lib files.
- Production untouched by this plan: `git diff 87deefa..HEAD -- lib | wc -l` → `0`.

## Deviations from Plan

- **Orchestrator proof base:** the brief asked to prove `git diff d0a62ac..HEAD -- lib` empty. It is not (467 lines): `d0a62ac` is the bookkeeping commit of plan 16-02, and plans 16-03..16-05 changed lib by design (`quest_result_sheet.dart`, `quest_results_{cubit,state}.dart`, `ambush_report_carousel.dart`, `quest_result_presenter.dart`; commits 7ba0770, 49d37d9, 68499fb, 3e7d62e, d05e516, ffb1ef2). None of those is a travel/map file. The proof for this plan is `git diff 87deefa..HEAD -- lib` = empty, plus the develop diffs above on travel/map/sheet/line = empty. Nothing was changed to "make" the requested diff empty.
- Test-code compile fix (`state.position!`), see above. Otherwise the plan was executed as written.

## Known Stubs

None.

## Self-Check: PASSED

- Four modified test files exist; commits 897e6ab and 785baaa are in `git log`.
