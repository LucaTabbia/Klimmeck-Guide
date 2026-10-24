---
phase: 06-quest-accept-info-sheets
plan: 07
subsystem: board-data
tags: [quest, graphql, cubit, repository, silent-refresh, tdd]
requires: [06-01, 06-03]
provides:
  - CityQueries.getCity (GetCity) and KlimmeckGraphQl.getCityPointIds
  - quests document with registeredAdventurers and requirements (Phase 7 scalar shapes)
  - tolerant getQuests (Quest.tryFromJson, malformed quests skipped, id logged)
  - QuestBoardRepository (getQuests, getCityPointIds)
  - QuestCubit.refreshQuests({cityId}) silent, last call wins; QuestLoaded.cityId / cityPointIds
affects: [06-09, 06-10, 06-12]
key-files:
  created:
    - lib/repository/quest_board_repository.dart
    - test/graphql/board_documents_test.dart
    - test/repository/services/graphql/graphql_board_data_test.dart
    - test/repository/quest_board_repository_test.dart
  modified:
    - lib/graphql/queries/city_queries.dart
    - lib/graphql/queries/quest_queries.dart
    - lib/repository/services/graphql/graphql.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/screens/mainScreen/questCubit/quest_cubit.dart
    - lib/screens/mainScreen/questCubit/quest_state.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/mainScreen/questCubit/quest_cubit_test.dart
    - test/helpers/mocks.dart
decisions:
  - "QuestCubit reaches the service only through QuestBoardRepository (no KlimmeckGraphQl import)"
  - "loadQuest carries the city of the state at resolution time, so a refresh that landed in between is not wiped"
metrics:
  tasks: 2
  tests: "1259 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 07: Board data layer Summary

`GetCity` gives the POI ids of the current city, the `quests` document carries the develop-valid requirement fields, `getQuests` survives a malformed quest, and `QuestCubit.refreshQuests` re-reads quests and city POIs without ever emitting `QuestLoading`, through the new `QuestBoardRepository`.

## Schema check (BE origin/develop)

`dumped 29 documents`, 29 `OK` (including `GetCity.graphql` and `quests.graphql`).

## Commits

- f550ede test(board): add failing tests for the board data documents (RED: `getCityPointIds` undefined, `CityQueries.getCity` missing)
- 5be8497 feat(board): read the current city's points of interest and the quest requirements
- 2e7e5e3 test(board): add failing tests for the board repository and the silent quest refresh (RED: missing repository library)
- d5d6315 feat(board): refresh quests silently with the current city
- dee2bdb test(board): make the repository error case asynchronous

## Deviations from Plan

**1. [Rule 1 - Bug, test] Repository error test used a synchronous `thenThrow`** on a method that the repository returns directly, so it threw synchronously instead of rejecting the future. Fixed in dee2bdb (committed after d5d6315 by a command-chain slip).

## Known Stubs

None.

## Self-Check: PASSED
