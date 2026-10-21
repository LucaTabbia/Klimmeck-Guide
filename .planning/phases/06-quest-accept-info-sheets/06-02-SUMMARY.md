---
phase: 06-quest-accept-info-sheets
plan: 02
subsystem: quest-models
tags: [quest, availability, board-policy, pure-dart, tdd]
requires: [06-01]
provides:
  - QuestLane, laneOf, registeredQuestTypes, nonRepeatableQuestTypes, laneQuestOf
  - QuestViewer (value for the classifier)
  - QuestAvailability / QuestStanding / standingOf / isTitleEligible (BE evaluation order)
  - boardQuestsFor, currentCityOf, isOnCityMarker
  - costLineOf / QuestCostLine, questStateLabel, questBlockedReasonOf, TitleType.label
  - fixtures buildViewer, buildLanes
affects: [06-03, 06-06, 06-07, 06-09, 06-10, 06-11]
tech-stack:
  added: []
  patterns: [flutter-free pure functions carrying behaviour, all copy in one place]
key-files:
  created:
    - lib/models/quest/quest_lane.dart
    - lib/models/quest/quest_viewer.dart
    - lib/models/quest/quest_availability.dart
    - lib/models/quest/board_policy.dart
    - lib/models/quest/quest_cost_line.dart
    - lib/models/quest/quest_state_label.dart
    - lib/models/quest/quest_blocked_reason.dart
    - test/models/quest/quest_lane_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/models/quest/board_policy_test.dart
    - test/models/quest/quest_cost_line_test.dart
    - test/models/quest/quest_state_label_test.dart
    - test/models/quest/quest_blocked_reason_test.dart
    - test/models/enums/title_type_test.dart
  modified:
    - lib/models/enums/title_type.dart
    - test/helpers/fixtures/quest_fixtures.dart
decisions:
  - "Empty slot list is a catalogue defect only when requirements.hasRankSlots (Phase 8 shape); legacy Int 0 leaves the BE to judge"
  - "isTorn is computed independently of the availability reason"
metrics:
  tasks: 3
  tests: "1085 -> 1137 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 02: Quest availability layer Summary

Pure Dart classifier (reason + torn) in BE evaluation order, board listing policy, cost line, state label, refusal copy and Italian title labels for D-02, D-10, D-11, D-12, D-15.

## Commits

- 5f167c4 test(quest): failing tests for lanes and the classifier (RED: `QuestViewer` / `quest_lane.dart` not found, compile errors)
- bdd4afd feat(quest): classify quest availability in backend order
- f3b33ab test(quest): failing tests for the board listing policy (RED: `boardQuestsFor` undefined)
- 08aea59 feat(quest): list board quests by city, lane and title
- 74401bf test(quest): failing tests for cost line, state label, blocked reasons (RED: missing libraries / `TitleType.label`)
- 409dbad feat(quest): add the cost line, the state label and the blocked reasons

## Deviations from Plan

- The acceptance grep for the literal `'Punti canale: $balance / $cost'` on one line returns 0: `dart format` splits the ternary across two lines (the string literal is intact on line 17). Behaviour is covered by the test.
- Fixture imports of the new `quest_viewer.dart` mean the RED run fails at compile time (accepted pattern from 06-01).

## Known Stubs

None.

## Self-Check: PASSED
