---
phase: quick-261022-f0n
plan: 01
subsystem: quest-board
tags: [quest, board, worldMission, city-rule]
requirements: [QUEST-04]
key-files:
  modified:
    - lib/models/quest/board_policy.dart
    - lib/models/quest/quest_availability.dart
    - test/models/quest/board_policy_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
    - .planning/REQUIREMENTS.md
    - .planning/phases/06-quest-accept-info-sheets/06-HUMAN-UAT.md
commits:
  - { hash: 8225b9b, message: "test: worldMission follows the city rule (red)" }
  - { hash: 625cb89, message: "fix: list and accept a worldMission only in its own city (green)" }
  - { hash: 0ad7423, message: "test: board widget tests list worldMission only in its city" }
  - { hash: 10d6298, message: "docs: D-11, D-16(b), QUEST-04, UAT row 2" }
---

# Quick 261022-f0n: worldMission bound to its city

Only `story` is exempt from the city rule. `worldMission` is now listed on the board only when its marker is in the current city (the owner's own active one stays listed torn), and `standingOf` returns `notInCity` for it outside its city.

## Changes
- `board_policy.dart`: removed the `worldMission => true` branch, so it falls into the city check; doc comment updated.
- `quest_availability.dart`: notInCity check is now `lane != QuestLane.story`.
- Tests: pure policy/classifier tests rewritten (red commit first, 2 failures confirmed); board widget fixtures aligned (wm-0 in city listed, wm-1 foreign not listed, story listed from another city).
- Docs: D-11 amended, D-16(b) amended per the orchestrator ruling (06-RESEARCH.md and historical plans untouched), QUEST-04 and UAT row 2 updated.

## Gate
- test/models/quest: 105 passed; board widget tests: 19 passed; full suite: 1320 passed.
- flutter analyze: 54 issues (baseline, 0 errors, none in touched files).
- dart format check on the 5 Dart files: clean.

## Deviations
None. Plan executed as written (plus the D-16 fix requested by the orchestrator).
