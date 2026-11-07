---
phase: 17-unlockable-lore
plan: 02
subsystem: models
tags: [flutter, dart, graphql, equatable, quests, enemies, lore]

requires:
  - 17-01 (CharacterStatus.unlockedLore, LoreType.label)
provides:
  - QuestEnemy.known (bool; strict on the board, lenient on results, written by toJson, in props)
  - QuestFragment / QuestResultFragment select `enemies { quantity known enemy { id name imagePath xp } }`
  - questEnemyJson(known: true by default)
  - strongestEntryOf(List<QuestEnemy>) -> QuestEnemy?; strongestEnemyOf delegates to it
  - QuestSheetDetails.isStrongestEnemyKnown (true without enemies)
affects: [17-04, 17-05, 17-09, 17-10]

tech-stack:
  added: []
  patterns:
    - "Strict boolean wire flag (`is! bool` -> FormatException) reused by the strict board list and the lenient result list"

key-files:
  created: []
  modified:
    - lib/models/quest/quest_enemy.dart
    - lib/graphql/fragments/quest_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/models/quest/quest_sheet_details.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/models/quest/quest_enemy_test.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/graphql/board_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart

key-decisions:
  - "QuestEnemy.known is required and strict: missing/non-bool -> FormatException('QuestEnemy.known missing'); the board drops the quest, results drop the entry (D-03)"
  - "QuestEnemy.toJson writes known so the result round trip keeps every entry (D-19, Pitfall 4)"
  - "The portrait flag follows the strongest entry's own known; isStrongestEnemyKnown defaults to true (no enemies) (D-08)"

requirements-completed: []

duration: 9min
completed: 2026-11-07
---

# Phase 17 Plan 02: QuestEnemy.known and the strongest entry Summary

**`QuestEnemy.known` read strictly from both quest fragments and written back by `toJson`, plus `strongestEntryOf` and `QuestSheetDetails.isStrongestEnemyKnown` so the portrait can follow the strongest enemy's own flag.**

## Performance

- Duration: ~9 min
- Tasks: 2 (4 code commits: two RED/GREEN pairs)
- Files modified: 10 (4 lib, 6 test), none created

## Accomplishments

- `QuestEnemy({required enemy, required quantity, required known})`; `fromJson` throws `FormatException('QuestEnemy.known missing')` when `known` is not a `bool`; `toJson` writes `'known': known` after `'quantity'`; `props => [enemy, quantity, known]`.
- Both fragments select `known` right after `quantity` inside `enemies { }`; registry unchanged (45; `git diff HEAD~2` of the registry files empty).
- `questEnemyJson` gains `bool known = true` (written after `'quantity'`) in the SAME GREEN commit as the model and both fragments (D-19, Pitfall 5).
- `QuestEnemy? strongestEntryOf(List<QuestEnemy>)` (highest `xp`, `null` = 0, first wins ties); `Enemy? strongestEnemyOf(...) => strongestEntryOf(enemies)?.enemy`.
- `QuestSheetDetails.isStrongestEnemyKnown` (`final bool`, constructor `this.isStrongestEnemyKnown = true`, `of` sets `strongest?.known ?? true`), in `props` after `strongestEnemy`.

## Task Commits

1. Task 1 RED `d7f8d61` test(models): expect the known flag on quest enemies
2. Task 1 GREEN `223d93d` feat(models): read whether the character knows each quest enemy
3. Task 2 RED `409e280` test(models): expect the strongest enemy entry and its known flag
4. Task 2 GREEN `14a5a92` feat(models): expose the strongest enemy entry and its known flag

## RED failures observed

- Task 1: `quest_enemy_test.dart` compile error «The getter 'known' isn't defined for the type 'QuestEnemy'» (:78, :82); `board_documents_test.dart` «selects the enemies with quantity, known and xp (D-01, D-02, D-03)» and `quest_result_documents_test.dart` «selects the enemies fought with known, the spells used and the rescued (D-07, D-03)» failed on the `contains` of the new selection.
- Task 2: compile errors «Method not found: 'strongestEntryOf'» (quest_enemy_test.dart) and «The getter 'isStrongestEnemyKnown' isn't defined for the type 'QuestSheetDetails'» (quest_sheet_details_test.dart).
- No case green at the first run (all new cases sit in files that failed compilation or on the new pins).

## Hand-written enemy entries grep

`grep -rnE "'enemy': " test` outside `quest_enemy_test.dart` / `quest_fixtures.dart`:
```
test/shared/components/popup/quest_info_sheet_test.dart:113:      'enemy': 'combat',
test/shared/components/popup/quest_info_sheet_test.dart:184:            {'quantity': 1, 'enemy': _enemy},
test/shared/components/popup/quest_info_sheet_test.dart:201:              {'quantity': 1, 'enemy': _enemy},
test/shared/components/popup/quest_info_sheet_test.dart:355:      'enemy': QuestInfoSheet.combatFamilyKey,
test/shared/components/popup/quest_info_sheet_test.dart:360:      'enemy': 'combat',
test/shared/components/popup/quest_info_sheet_test.dart:711:          {'quantity': 1, 'enemy': _enemy},
```
:184, :201, :711 became `{'quantity': 1, 'known': true, 'enemy': _enemy}` in the GREEN commit; :113, :355, :360 are QuestType-keyed maps (not enemy entries), untouched. No `"enemy"` double-quoted entries.

## Gates

- `flutter test test/models test/graphql test/tool test/shared test/screens/mainScreen` → `+1957: All tests passed!` (after Task 1).
- `flutter test test/models/quest test/shared/components/popup` → `+268: All tests passed!` (after Task 2).
- `flutter analyze` last line `50 issues found.` — 0 error, 0 warning (baseline unchanged) after each task.
- `dart format` run one by one on every touched file; only the two RED test files `quest_enemy_test.dart` and `quest_result_documents_test.dart` were reflowed (new lines only); the others printed `0 changed`.

## Notes

- **D-14 / Pitfall 9:** from this plan on the board (`QuestFragment`) and the results (`QuestResultFragment`) select `known`, which exists only on a BE with Phase 16; the branch must not run against the BE on port 3001 (develop without Phase 16).
- **D-18:** `quest_result_fragment.dart` and `quest_result_documents_test.dart` are shared with the parked FE Phase 16 branch; the edit is additive and local (`known` inside `enemies`, one doc-comment line, one pin/title update).

## Deviations from Plan

None - plan executed exactly as written. (The `quest_info_sheet_test.dart` edit was anticipated by the plan's Task 1 step 4; the bookkeeping progress uses the orchestrator's `2/10` instead of the plan's `02/10`.)

## Known Stubs

None.

## Self-Check: PASSED
