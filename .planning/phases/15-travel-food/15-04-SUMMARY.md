---
phase: 15-travel-food
plan: 04
subsystem: travel
tags: [flutter, dart, travel, food, cubit, map, banners]

requires:
  - phase: 15-travel-food
    provides: TravelFailure.starving and travelNoticeFor(starving) (15-03), starvingPhrase (15-01)
provides:
  - TravelRequoting (TravelQuote subclass) with TravelRequoting.from(TravelStarting) and withEta
  - TravelCubit._requote on a TRAVEL_STARVING start refusal (Starting -> Requoting -> Confirming under _previewToken)
  - one starvation banner on entering TravelRequoting, no reset()
  - route, pawn and camera held through the requote
affects: [15-05, 15-09]

tech-stack:
  added: []
  patterns:
    - "A refusal that keeps the flow open is a TravelQuote state, not a TravelFailed: the session listener announces on the state edge (previous is! X && current is X) and never resets"

key-files:
  created: []
  modified:
    - lib/screens/mainScreen/travelCubit/travel_state.dart
    - lib/screens/mainScreen/travelCubit/travel_cubit.dart
    - lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
    - lib/screens/mainScreen/components/travel_outcome_listener.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/screens/mainScreen/travelCubit/travel_cubit_test.dart
    - test/screens/mainScreen/tabs/map/travel_route_layer_test.dart
    - test/screens/mainScreen/components/travel_outcome_listener_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart

key-decisions:
  - "Only TravelFailure.starving requotes; every other start refusal still ends in TravelFailed(stage: start) (Phase 7 D-14)"
  - "A failing requote ends in TravelFailed(stage: preview): the sheet closes through its existing TravelFailed listener and the session listener banners and resets"
  - "The camera refit fires only on previous is! TravelQuote && current is TravelConfirming: a requote never moves the camera"

patterns-established:
  - "Edge-triggered banner for a non-terminal refusal state (TravelOutcomeListener third BlocListener)"

requirements-completed: []  # mark-complete forbidden here; FOOD-03 advanced, traceability in 15-09

duration: 15min
completed: 2026-11-05
---

# Phase 15 Plan 04: TravelRequoting state machine Summary

**A `TRAVEL_STARVING` refusal of `startTravel` moves `TravelCubit` Starting -> `TravelRequoting` (last quote kept) -> Confirming with a fresh BE preview under `_previewToken`; the session listener publishes «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio» once on entering the requote without `reset()`; the dashed route, the pawn on the destination and the camera all hold through it.**

## Performance

- Duration: ~15 min
- Tasks: 3/3
- Files modified: 11 (6 lib, 5 test)

## Accomplishments

- `travel_state.dart`: `final class TravelRequoting extends TravelQuote` (after `TravelStarting`), constructor `{destination, preview, eta, previewedAt}`, `TravelRequoting.from(TravelStarting starting)`, `@override TravelRequoting withEta({required DateTime eta, required DateTime previewedAt})`.
- `travel_cubit.dart`: `start()` keeps `final starting = TravelStarting.from(confirming)`; on `TravelException` with `TravelFailure.starving` → `return _requote(starting);`. `Future<void> _requote(TravelStarting starting)` bumps `_previewToken`, emits `TravelRequoting.from(starting)`, re-asks `_repository.preview(characterId: _characterId!, poiId: destination.markerLocation!.id)`, emits `_confirmingFrom(...)` or `_failPreview(token, ...)` (stage preview). `cancel()` also accepts `TravelRequoting`; `_isStale` = `token != _previewToken || (state is! TravelPreviewing && state is! TravelRequoting)`. No `arrivesAlive` check in the cubit (D-10).
- `travel_route_layer.dart` `_previewPoints`: `TravelRequoting(:final preview)` in the route arm.
- `travel_outcome_listener.dart`: third `BlocListener<TravelCubit, TravelState>` with `listenWhen: previous is! TravelRequoting && current is TravelRequoting` → `_announce(context, failure: TravelFailure.starving, destination: ...)`; `_announce(BuildContext, {required TravelFailure failure, required City destination})`, dedup key unchanged `'travel|${failure.name}|${destination.id}'`. Class doc updated.
- `character_marker_layer.dart` `_confirmingDestination`: `TravelRequoting(:final destination)` holds the pawn on the destination.
- `world_map.dart` refit listener: `previous is! TravelQuote && current is TravelConfirming` with comment `// D-03: il preventivo rinnovato non riposiziona la camera.`

## Task Commits

1. Task 1 RED `6ce3f0d` test(travel): expect the starving requote of a departure; GREEN `5af97dd` feat(travel): requote a departure refused for starvation
2. Task 2 RED `51a33c6` test(travel): expect the starvation banner without a reset; GREEN `4b0e6b4` feat(travel): announce the starvation refusal and keep the sheet
3. Task 3 RED `e50b369` test(travel): expect the pawn and camera to hold during a requote; GREEN `5933b71` feat(travel): hold pawn and camera during a starving requote

## RED failures observed

- Task 1: compile failure — `travel_cubit_test.dart:412:23: Error: Undefined name 'TravelRequoting'.`, `:540:23 Method not found: 'TravelRequoting'.`, `:549:26 'TravelRequoting' isn't a type.`; `travel_route_layer_test.dart:134:17: Error: Method not found: 'TravelRequoting'.`
- Task 2: all 3 new tests failed with `No matching calls (actually, no calls at all).` on `publishNotice` (the plan expected only the first to fail; the other two also verify one banner, so they were red too until the edge listener existed).
- Task 3: «requoting holds the pawn on the destination (D-03)» → `Expected: LatLng(10.0, 60.0) Actual: LatLng(10.0, 20.0)` (pawn snapped home); «a requote keeps the camera when the new quote arrives (D-03)» → `Expected: LatLng(8.286133, 25.0) Actual: LatLng(-1.403509, 70.0)` (camera refitted).

Green at first run: «a fresh quote after idle still fits the camera (D-03)» — current behaviour already refits from Idle; the test pins that the narrowed `listenWhen` keeps it.

## Tests added

- `travel_cubit_test.dart` group `'starving refusal'` (7, D-03): keeps the quote and previews again; asks the backend again (`called(2)`); every other start refusal still fails the start; a failing requote fails the preview stage; cancel during the requote goes idle and drops the late answer (title split over two adjacent literals by me, `(D-03)'` on its own line); withEta on a requote stays a requote; drops a late requote answer after close. Helper `stubPreviews(List<Future<TravelPreview> Function()>)` (sequential answers) local to the group; fixture `starvingPreview = TravelPreview.fromJson(travelPreviewJson(food: const [], hpLost: 20910, arrivesAlive: false))`.
- `travel_route_layer_test.dart`: «keeps the dashed preview while requoting (D-03)».
- `travel_outcome_listener_test.dart` group `'starving requote'` (3): «a starving refusal publishes the user phrase once and keeps the flow (D-03, D-06)», «the clock re-emit of a requote publishes nothing more (D-03)», «the new quote after a requote publishes nothing more (D-03)». New top-level fixtures `preview`, `eta`, `previewedAt`, `starting`, `starvingNotice`.
- `character_marker_layer_test.dart` (group `'confirming pawn (D-02, D-04)'`): «requoting holds the pawn on the destination (D-03)».
- `world_map_travel_test.dart` (group `'drag to travel (D-01..D-04)'`): «a requote keeps the camera when the new quote arrives (D-03)», «a fresh quote after idle still fits the camera (D-03)».

## Verification

- `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/travelCubit test/screens/mainScreen/components` → `+410: All tests passed!`
- Analyzer last line `50 issues found.` (all info), `ANALYZE_GATE_OK` after each task.
- Acceptance greps: all at the expected counts (single-line, no `-A3` needed).
- `dart format` on every touched file, one by one: `travel_outcome_listener_test.dart`, `world_map_travel_test.dart` and `travel_outcome_listener.dart` reflowed the new code only; `character_marker_layer.dart` (known formatter-dirty) reflowed four untouched members (`Marker(point:, child:)`, `_labelOf`, `Transform.scale(...)`, `childWhenDragging: Opacity(...)`) — accepted per REPO-RULES, behaviour unchanged.

## Deviations from Plan

None - plan executed exactly as written (Task 2: all three RED tests failed rather than only the first, see above).

## Notes for 15-05

- `TravelConfirmationSheet` needs no change for the flow to survive: its close listener fires only on `TravelStarted`/`TravelFailed`; «Parti» is enabled only on `TravelConfirming` (so already off during `TravelRequoting`); `_numbersOf` matches `TravelQuote` (old numbers kept, no placeholder flash); `canPop` is `state is! TravelStarting`, so the sheet is dismissible during the requote and `cancel()` (now accepting `TravelRequoting`) drops the late answer.

## Threat Flags

None (T-15-10/11/12 mitigations covered by the tests above; no new surface).

## Self-Check: PASSED
