---
phase: 21-innkeeper-mission-completion-flow
plan: 07
subsystem: teleport-mode
tags: [teleport, poi, cubit, graphql, map]
requires: ["21-06"]
provides:
  - "KlimmeckGraphQl.getPointsOfInterest() — ListPointsOfInterest (noCache), per-entry parse, FormatException when the list is missing"
  - "InnkeeperRepository.listPointsOfInterest() through _guard (D-29)"
  - "TeleportModeCubit.prepare(..., String? resumeCardKey) reads the character then the places; a failed places read falls back to places const []"
  - "TeleportModeCubit.teleportTo(TeleportDestination) — sends destination.poiId for every participant; same place = no call (C16)"
  - "TeleportActive.places / .resumeCardKey; TeleportSucceeded.resumeCardKey; TeleportCancelled.resumeCardKey (D-28)"
affects: [21-08, 21-09, 21-13]
tech-stack:
  added: []
  patterns: ["places read in its own guard after the character read (Phase 10 path never regresses)", "return key carried by the states, never wizard state across the Map (Pitfall 1)"]
key-files:
  created:
    - test/repository/services/graphql/graphql_points_of_interest_test.dart
  modified:
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/innkeeper_repository.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart
    - lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_state.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/repository/innkeeper_repository_test.dart
    - test/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit_test.dart
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
decisions:
  - "Commit scope `shared` instead of the plan's `repository` (not in the REPO-RULES scope list), as in 21-01/21-03"
  - "The TeleportDestination mocktail fallback lives in the shared world map harness (setUpWorldMapHarness in world_map_travel_test.dart), because its setUp stubs teleportTo(any()) for every map test file"
  - "A character without a pawn (target null) stays TeleportPreparationFailed(malformed) without reading the places"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 10
---

# Phase 21 Plan 07: Teleport mode over places Summary

The innkeeper's teleport now reads the world's places (`ListPointsOfInterest`, per-entry lenient), carries the inner places and the card to resume (`resumeCardKey`) on its states, and teleports to any `TeleportDestination` by `poiId`; the Map's city drop goes through `TeleportDestination.ofCity`, player travel is untouched.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | 877bc40d | test(shared): expect the points of interest read |
| 1 GREEN | 3266e642 | feat(shared): read the points of interest for the teleport |
| 2 RED | 22c52d58 | test(map): expect teleport destinations, places and a return key |
| 2 GREEN | 760f3960 | feat(map): teleport to destinations with a return key |
| 3 | (this commit) | docs(phase-21): record plan 07 progress |

## RED per task

- Task 1: compile failure — `The method 'getPointsOfInterest' isn't defined for the type 'KlimmeckGraphQl'` (and `listPointsOfInterest` on the repository) (`+0 -2`).
- Task 2: compile failure — `No named parameter with the name 'places'` / `'resumeCardKey'`, `The argument type 'TeleportDestination' can't be assigned to the parameter type 'City'` (cubit test and world map teleport test) (`+0 -2`).
- No case was green at the first run (every file failed to compile).

## Retargeted pins

- `teleport_mode_cubit_test.dart` group `teleportTo` and the `cancel` in-flight case: every `cubit.teleportTo(valantar|borgo)` → `cubit.teleportTo(TeleportDestination.ofCity(valantar|borgo)!)`; setUp stubs `listPointsOfInterest` with `const <PointOfInterest>[]` so the existing prepare cases keep their expectations.
- `world_map_teleport_test.dart`: «releasing the pawn on a city teleports there» → «a city drop teleports to the city marker destination (D-01)» verifying `teleportTo(TeleportDestination.ofCity(cityB)!)`; the `verifyNever(teleportTo(any()))` case unchanged.

## New tests

- graphql_points_of_interest_test: «sends ListPointsOfInterest and parses every place (D-29)», «a malformed place is dropped, the others stay (Pitfall 8)» (`location: 'x'` and a non-map entry), «a missing list is a FormatException», «an error keeps the OperationException code».
- innkeeper_repository_test group `listPointsOfInterest`: service list (D-29), FormatException → malformed, FORBIDDEN → forbidden.
- teleport_mode_cubit_test: inner places carried in order after the character read (D-01, D-29); failed places read keeps the city teleport (D-29); resumeCardKey on the active state (D-28); inner place `poiId` for every participant (D-01); current place makes no call (D-01, Phase 10 C16); success carries the key (D-28, Pitfall 1); cancel carries the key (D-28, Pitfall 1); a refusal keeps places and key (D-28, extra).

## Results

- `flutter test test/repository test/screens/mainScreen/tabs/map test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/innkeeper` → +1373 green.
- Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK` after each code task.
- Formatted one by one (all formatter-clean before): graphql.dart, innkeeper_repository.dart, teleport_mode_cubit.dart, teleport_mode_state.dart, world_map.dart, graphql_points_of_interest_test.dart, innkeeper_repository_test.dart, teleport_mode_cubit_test.dart, world_map_teleport_test.dart, world_map_travel_test.dart.
- `grep -c resumeCardKey teleport_mode_state.dart` = 10; `appLog` in the cubit = 0; `TeleportDestination.ofCity` in world_map.dart = 1.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] TeleportDestination fallback in the shared world map harness**
- **Found during:** Task 2 GREEN. `setUpWorldMapHarness()` (in `test/screens/mainScreen/tabs/map/world_map_travel_test.dart`, shared with the teleport and availability tests) stubs `teleportCubit.teleportTo(any())` in setUp: with the new `TeleportDestination` parameter mocktail needs a fallback, otherwise every world map test file goes red.
- **Fix:** its `setUpAll` registers `TeleportDestination.ofCity(cityA)!` next to `cityA` (+ import). No travel case changed. The plan's acceptance `git diff HEAD~2 --stat -- world_map_travel_test.dart character_marker_layer.dart` therefore prints this one 6-line harness change; `character_marker_layer.dart` is untouched and player travel behaviour (Pitfall 6) is unchanged. The plan's «register a fallback TeleportDestination» in world_map_teleport_test is covered by the harness.
- **Commit:** 760f3960

**2. Scope `shared` instead of `repository`** for the Task 1 commits (REPO-RULES scope list).

## Known Stubs

None. `places` has no reader yet: the POI layer and the drop rule come in 21-08, the landing reading `resumeCardKey` in 21-09, the wizard's prepare with a key in 21-13 (by plan).

## Threat Flags

None: T-21-21 (teleport only via TeleportModeCubit, FORBIDDEN leaves the mode — unchanged), T-21-22 (per-entry parse + places fallback, both tested), T-21-23 (only the teleport path changed).

## Self-Check: PASSED
