---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 02
subsystem: models
tags: [character-status, quest-result, wire-boundary, document-pins]
requires: ["24-01"]
provides:
  - "CharacterStatus.innkeeperInjuries (lenient, default empty, in toJson, copyWith pass-through and props)"
  - "QuestResult.backgroundEntryAdded (true only for a served true), QuestResult.injuriesRemoved (lenient), QuestResult.healedOrRemovedInjuries"
  - "three «not selected before the gate» pins on the status, draft and result fragments (24-10 flips them)"
affects: [24-08, 24-09, 24-10]
tech-stack:
  added: []
  patterns: ["a served subset list is part of the status equality, so an origin flip alone emits"]
key-files:
  created: []
  modified:
    - lib/models/character/character_status.dart
    - lib/models/quest_result/quest_result.dart
    - test/models/character/character_status_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/mission_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
decisions:
  - "healedOrRemovedInjuries is a pure getter of the model: injuriesHealed as served, then the wounds of injuriesRemoved not already listed"
  - "CharacterStatus.copyWith passes innkeeperInjuries through with no parameter (nobody edits it locally), like spellStates"
metrics:
  duration: "~15 min"
  completed: 2026-11-21
---

# Phase 24 Plan 02: Player-side models and the «nothing selected» pins Summary

The status reads the player's innkeeper wounds and the result reads the story flag and the removed wounds, all leniently and unselected: against today's BE they read their neutral values; three named pins break if a pre-gate plan selects a Phase 25 field.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect innkeeper wounds on the status and the result | a4f01715 |
| 1 GREEN | Read innkeeper wounds, removed wounds and the story flag | ce8a44d5 |
| 2 | Pin the Phase 25 fields out of the documents until the gate | 6f5c7036 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (a4f01715):** compile failure, as expected: `character_status_test.dart` and `quest_result_test.dart` did not load (`innkeeperInjuries`, `backgroundEntryAdded`, `injuriesRemoved`, `healedOrRemovedInjuries` undefined). `flutter test test/models/character test/models/quest_result` → `+64 -3`.
- **Task 1 GREEN (ce8a44d5):** `flutter test test/models test/screens/mainScreen/characterCubit test/shared/components/popup` → 1469 passed. No existing `toJson` expectation needed the new keys (none compares a whole map).
- **Task 2 (6f5c7036), green at the first run by construction:** the three pins assert an absence that already holds; their purpose is to turn RED if a plan before 24-10 selects a field. `flutter test test/graphql test/tool` → 244 passed; `grep -rnE "innkeeperInjuries|injuriesRemoved|backgroundAdditions|backgroundEntryAdded" lib/graphql` → empty.

## Gates

- Analyzer after each code task: `47 issues found.` → `ANALYZE_GATE_OK`.
- Trailer check after every commit: `0`.
- `grep -c innkeeperInjuries lib/models/character/character_status.dart` = 6; `grep -c healedOrRemovedInjuries lib/models/quest_result/quest_result.dart` = 1; `24-10 flips this` once per pin file.
- Formatted, one by one: the eight files of `key-files`; all were formatter-clean before the edits (no `style` commit).
- Full suite not run (REPO-RULES: only in 24-01 and 24-10).

## Deviations from Plan

None - plan executed as written. Details worth knowing:

- The equality and round-trip cases of the result are one test («the story flag and the removed wounds survive toJson -> fromJson and take part in equality»), like the Phase 24-BE neighbour for `spellFound`.
- The test helper `statusJson` of `character_status_test.dart` gained `innkeeperInjuries` (absent by default).

## Notes for the next plans

- `CharacterStatus.innkeeperInjuries` is non-nullable (`const []` when absent) while `injuries` stays nullable; it is in `props`, so `CharacterCubit` emits on an origin flip with identical `injuries` (24-08 can key `QuestScopeListener` on it).
- `QuestResult.healedOrRemovedInjuries` is the list for the single «Guarite: …» line of 24-09; `backgroundEntryAdded` gates «La tua storia ha una nuova pagina».
- Fixture: `questResultJson(backgroundEntryAdded:, injuriesRemoved:)`, keys written only when non-null.
- 24-10 flips the three pins: `character_fragment_test.dart` («innkeeperInjuries is not selected before the gate…»), `mission_documents_test.dart` («the draft selects no addition…»), `quest_result_documents_test.dart` («the result selects neither…»).

## Known Stubs

None. The new fields have no consumer until 24-08 / 24-09 and read neutral values until the gate, by design.

## Self-Check: PASSED

Modified files exist; commits `a4f01715`, `ce8a44d5`, `6f5c7036` are in `git log`.
