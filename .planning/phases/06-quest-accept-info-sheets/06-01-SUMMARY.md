---
phase: 06-quest-accept-info-sheets
plan: 01
subsystem: quest-models
tags: [quest, models, graphql-fragment, tdd, requirements]
requires: []
provides:
  - AdventurerSlot / RegisteredAdventurer tolerant parsing (BE Phase 7 and Phase 8 shapes)
  - quest_capacity (BE Phase 8 D-32 rule)
  - Quest.tryFromJson parse boundary
  - three quest lanes on Character.quests and in the character fragment
  - shared quest fixtures
affects: [06-02, 06-03, 06-06, 06-07, 06-09, 06-10, 06-11, 06-12]
tech-stack:
  added: []
  patterns: [tolerant wire parsing via listFrom, tryFromJson parse boundary]
key-files:
  created:
    - lib/models/quest/adventurer_slot.dart
    - lib/models/quest/registered_adventurer.dart
    - lib/models/quest/quest_capacity.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/models/quest/adventurer_slot_test.dart
    - test/models/quest/registered_adventurer_test.dart
    - test/models/quest/quest_capacity_test.dart
    - test/models/quest/quest_test.dart
    - test/models/pending_quest_test.dart
    - test/models/character/character_quests_test.dart
    - test/graphql/character_fragment_test.dart
  modified:
    - lib/models/quest/quest.dart
    - lib/models/quest/quest_requirements.dart
    - lib/models/pending_quest.dart
    - lib/models/character/character_quests.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/screens/mainScreen/tabs/board/components/sheet.dart
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "requiredAdventurers is List<AdventurerSlot> with hasRankSlots marking the Phase 8 wire shape"
  - "Sheet torn rule uses isFullForEveryone (a quest with no slots is never torn)"
metrics:
  tasks: 3
  tests: "1006 -> 1049, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 01: Quest foundation Summary

Quest models that read both BE Phase 7 (`Int`, `[String]`) and Phase 8 (`[{title,count}]`, `[{character,title}]`) shapes, the D-32 rank capacity rule, a tolerant `Quest.tryFromJson`, and the three lanes on `Character.quests` plus the character fragment; requirement amendments recorded first.

## Commits

- e5f6bf3 docs(phase-6): amend QUEST-03..07 and supersede roadmap criteria 3 and 4
- 4e65eea test(quest): failing tests for rank slots, registrations, tolerant parsing (RED: compile errors, `Couldn't find constructor 'RegisteredAdventurer'`)
- 424864f feat(quest): rank slots and registrations with the D-32 capacity rule
- d55b751 test(quest): failing tests for the three quest lanes (fragment test failed on missing `activeStoryQuest`)
- 0213e67 feat(quest): read the three quest lanes from the character

## Deviations from Plan

- The optional contract check (Task 3 step 5, schema check vs BE `origin/develop`) was not run; it is covered by plan 06-12.
- `RegisteredAdventurer.from` was implemented with a Dart 3 map pattern instead of the plain Map check; behaviour is the specified one.

## Known Stubs

None.

## Self-Check: PASSED
