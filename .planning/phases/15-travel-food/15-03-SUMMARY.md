---
phase: 15-travel-food
plan: 03
subsystem: repository
tags: [flutter, dart, travel, food, quest, failures, banners]

requires:
  - phase: 15-travel-food
    provides: starvingPhrase (15-01), KlimmeckGraphQl.previewQuestTravel (15-02)
provides:
  - travelStarvingCode = 'TRAVEL_STARVING' (one shared constant)
  - TravelFailure.starving and QuestAcceptanceFailure.starving
  - both banners with the user phrase via starvingPhrase
  - TravelRepository.previewQuest({characterId, questId}) -> Future<TravelPreview?>
affects: [15-04, 15-06, 15-07]

tech-stack:
  added: []
  patterns:
    - "One error code shared by two classifiers: the constant lives in travel_failure.dart and is imported by quest_acceptance_failure.dart via `show`"

key-files:
  created: []
  modified:
    - lib/repository/travel_failure.dart
    - lib/screens/mainScreen/travelCubit/travel_notice.dart
    - lib/repository/quest_acceptance_failure.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - lib/repository/travel_repository.dart
    - test/repository/travel_failure_test.dart
    - test/screens/mainScreen/travelCubit/travel_notice_test.dart
    - test/repository/quest_acceptance_failure_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
    - test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart
    - test/repository/travel_repository_test.dart

key-decisions:
  - "starving stays out of QuestAcceptanceOutcomeListener._staleListFailures: the starving acceptance refusal rereads no board (D-05); the listener file is untouched"
  - "previewQuest reuses the travel _guard: failures surface as TravelException(TravelFailure.*), including starving, timedOut after 15 s"

patterns-established: []

requirements-completed: []  # mark-complete forbidden here; FOOD-02/FOOD-03 advanced, traceability in 15-09

duration: 7min
completed: 2026-11-05
---

# Phase 15 Plan 03: Starvation refusal and quest travel preview repository Summary

**`TRAVEL_STARVING` maps to `TravelFailure.starving` and `QuestAcceptanceFailure.starving` through one shared constant, both banners read «Non hai cibo a sufficienza per il viaggio» from `starvingPhrase`, the starving acceptance refusal rereads no board, and `TravelRepository.previewQuest` exposes the nullable acceptance preview through the travel `_guard` (15 s timeout).**

## Performance

- Duration: ~7 min
- Tasks: 3/3
- Files modified: 11 (5 lib, 6 test)

## Accomplishments

- `lib/repository/travel_failure.dart`: `const String travelStarvingCode = 'TRAVEL_STARVING';` after `awaitingAidCode`; enum value `starving` after `awaitingAid` (doc comment BE Phase 14 D-11); arm `travelStarvingCode => TravelFailure.starving`.
- `lib/screens/mainScreen/travelCubit/travel_notice.dart`: imports `travel_cost_text.dart`; `TravelFailure.starving => starvingPhrase` → «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio».
- `lib/repository/quest_acceptance_failure.dart`: `show awaitingAidCode, travelInProgressCode, travelStarvingCode;`; enum value `starving` after `awaitingAid`; arm `travelStarvingCode => QuestAcceptanceFailure.starving`.
- `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart`: imports `travel_cost_text.dart`; `QuestAcceptanceFailure.starving => starvingPhrase` → «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio».
- `lib/repository/travel_repository.dart`: `Future<TravelPreview?> previewQuest({required String characterId, required String questId})` = `_guard(() => _graphQl.previewQuestTravel(AcceptQuestRequest(id: characterId, questId: questId)))`, right after `preview`.

## Task Commits

1. Task 1 RED `cc4f94c` test(travel): expect the starvation refusal and its banner; GREEN `9541105` feat(travel): classify the starvation refusal of a departure
2. Task 2 RED `d9f1ecf` test(quest): expect the starvation refusal of an acceptance; GREEN `283af7e` feat(quest): classify the starvation refusal of an acceptance
3. Task 3 RED `0444f09` test(repository): expect the quest travel preview; GREEN `531f949` feat(repository): preview the travel of a quest acceptance

## RED failures observed

- Task 1: compile failure in both files — `test/repository/travel_failure_test.dart:22:40: Error: Member not found: 'starving'.` and `test/screens/mainScreen/travelCubit/travel_notice_test.dart:17:21: Error: Member not found: 'starving'.`
- Task 2: compile failure — `test/repository/quest_acceptance_failure_test.dart:27:49: Error: Member not found: 'starving'.`, `quest_acceptance_notice_test.dart:27:30: Error: Member not found: 'starving'.` (the listener test failed to compile on the same missing member).
- Task 3: compile failure — `test/repository/travel_repository_test.dart:173:41: Error: The method 'previewQuest' isn't defined for the type 'TravelRepository'.`

Green without production change once the enum existed: «a starving refusal publishes the user phrase and rereads no board (D-05, D-06)» in the listener test — by design, the listener already publishes `questAcceptanceNoticeFor` for every failure and `starving` is not in `_staleListFailures`; the test pins that it never joins the set.

## Tests added

- `travel_failure_test.dart`: «maps TRAVEL_STARVING to starving (D-06)» + `byCode` entry.
- `travel_notice_test.dart`: «starving explains the missing food with the user phrase (D-06)» + `descriptions` entry (literal phrase).
- `quest_acceptance_failure_test.dart`: «maps TRAVEL_STARVING to starving (D-06)» + code map entry.
- `quest_acceptance_notice_test.dart`: «starving explains the missing food with the user phrase (D-06)» + description map entry (imports `models/notification.dart`).
- `quest_acceptance_outcome_listener_test.dart`: «a starving refusal publishes the user phrase and rereads no board (D-05, D-06)» (title split over two adjacent string literals by the formatter; the `D-05, D-06)` literal stays on one line).
- `travel_repository_test.dart`: group `'previewQuest'`, 6 tests (D-04/D-08), `registerFallbackValue(const AcceptQuestRequest(id: '', questId: ''))` in `setUpAll`.

## Verification

- `flutter test test/repository test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/components test/screens/mainScreen/tabs/board` → `+995: All tests passed!`
- `flutter test test/repository` → `+767: All tests passed!`
- Analyzer last line `50 issues found.` (all info), `ANALYZE_GATE_OK` after each task.
- `dart format` on every touched file, one by one: only `quest_acceptance_outcome_listener_test.dart` changed (reflow of the new test).

## Deviations from Plan

None - plan executed exactly as written. Note: the existing failure tests name their helper `_withCode` (not `_coded` as the plan's behavior text says); the new tests use the existing helper.

## Threat Flags

None (no new surface beyond the plan's threat model; T-15-07/08/09 mitigations covered by the tests above).

## Self-Check: PASSED
