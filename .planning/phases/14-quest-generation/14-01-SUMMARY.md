---
phase: 14-quest-generation
plan: 01
subsystem: models
tags: [quest, models, enemies, pet, fixtures, tdd]
requires: []
provides:
  - QuestEnemy (strict listFrom / lenientListFrom, toJson), enemyLinesOf, strongestEnemyOf
  - QuestInfos.enemies / QuestInfos.description (QuestInfos.enemy removed)
  - QuestPrizes.pet
  - QuestSheetDetails.enemyLines / strongestEnemy / petPrizeLine
  - fixtures questEnemyJson + questJson/buildQuest params enemies, description, prizes
affects: [14-02, 14-03, 14-05, 14-06]
tech-stack:
  added: []
  patterns: [strict-vs-lenient list parsing, key whitelist before Enemy.fromJson]
key-files:
  created:
    - lib/models/quest/quest_enemy.dart
    - test/models/quest/quest_enemy_test.dart
  modified:
    - lib/models/quest/quest_infos.dart
    - lib/models/quest/quest_prizes.dart
    - lib/models/quest/quest_sheet_details.dart
    - lib/shared/components/popup/quest_info_sheet.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/models/quest/quest_test.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
decisions:
  - "QuestEnemy.lenientListFrom catches Object (FormatException and TypeError) per entry; listFrom lets both propagate so Quest.tryFromJson skips the quest"
  - "enemyLinesOf returns the bare name only when exactly one named type with total quantity 1 remains"
metrics:
  duration: ~20 min
  completed: 2026-11-04
  tasks: 3
  commits: 6
---

# Phase 14 Plan 01: Quest-side models for the BE Phase 13 contract Summary

`QuestEnemy { enemy, quantity }` with strict (board) and lenient (results) list parsers plus the pure `enemyLinesOf` / `strongestEnemyOf`; `QuestInfos.enemies` replaces `QuestInfos.enemy`, `QuestInfos.description` and `QuestPrizes.pet` parse from the wire, and `QuestSheetDetails` exposes `enemyLines`, `strongestEnemy` and `petPrizeLine`; the combat body only reads `details.strongestEnemy` (layout untouched until 14-05).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | QuestEnemy, list parsers, enemyLinesOf, strongestEnemyOf | d5cdbe7 (test), 4fef6c4 (feat) |
| 2 | QuestInfos.enemies/description, QuestPrizes.pet, fixtures | 723811e (test), 4493030 (feat) |
| 3 | QuestSheetDetails enemyLines/strongestEnemy/petPrizeLine | 208b6c3 (test), 88217b4 (feat) |

## RED failures observed

- Task 1: compile failure — `Error: Method not found: 'strongestEnemyOf'` (and missing `package:klimmeck_guide/models/quest/quest_enemy.dart`, `QuestEnemy`, `enemyLinesOf`).
- Task 2: compile failure — `The getter 'enemies' isn't defined for the type 'QuestInfos'`, `The getter 'description' isn't defined for the type 'QuestInfos'`, `The getter 'pet' isn't defined for the type 'QuestPrizes'`.
- Task 3: compile failure — `The getter 'enemyLines' isn't defined for the type 'QuestSheetDetails'` (same for `strongestEnemy`, `petPrizeLine`).

No test was green at its first run.

## Tests

- `flutter test test/models/quest/quest_enemy_test.dart` → 10/10 passed.
- `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/board` → 180 passed (after Task 2).
- `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart` → 163 passed (after Task 3, includes the 6 new quest_test and 5 new sheet details tests).
- Analyzer after every code task: `50 issues found.` (all info), 0 error, 0 warning → `ANALYZE_GATE_OK`.

## Exact names created

- `lib/models/quest/quest_enemy.dart`:
  - `class QuestEnemy extends Equatable { const QuestEnemy({required Enemy enemy, required int quantity}); factory QuestEnemy.fromJson(Map<String, dynamic>); static List<QuestEnemy> listFrom(Object? json); static List<QuestEnemy> lenientListFrom(Object? json); Map<String, dynamic> toJson(); }`
  - `List<String> enemyLinesOf(List<QuestEnemy> enemies)`
  - `Enemy? strongestEnemyOf(List<QuestEnemy> enemies)`
- `QuestInfos`: `final List<QuestEnemy> enemies` (ctor `this.enemies = const []`), `final String? description` (ctor `this.description`); `toJson` writes `"enemies": [{"enemy": id, "quantity": n}]` and `"description"`.
- `QuestPrizes`: `final Pet? pet` (ctor optional `this.pet`), top-level private `_petFrom(Object?)` (null unless `id` is a String); `toJson` `"pet": pet?.id`.
- `QuestSheetDetails`: `required List<String> enemyLines`, `required Enemy? strongestEnemy`, `required String? petPrizeLine`; private `_petPrizeLine(String?)` → `'Compagno in premio: $name'`.
- Fixtures: `questEnemyJson({String id = 'enemy-1', String? name = 'Lupo grigio', String? imagePath, int? xp = 10, int quantity = 1})`; `questJson` / `buildQuest` gain `List<Map<String, dynamic>>? enemies`, `String? description`, `Map<String, dynamic>? prizes` (the `enemy` param is gone).

## Files formatted

`dart format` run on each touched file by name. Note: in Task 2 RED the three test files were formatted in one `dart format` invocation naming the three files explicitly (not a directory); only `quest_info_sheet_test.dart` changed (the reflow of the three edited `buildQuest(...)` calls). `quest_prizes.dart` was reflowed by the formatter only on the edited lines (`_petFrom` signature and `props`).

## Deviations from Plan

### Acceptance grep mismatch (no code change)

- Task 2 acceptance `grep -c "Pet? pet" lib/models/quest/quest_prizes.dart` = 1 prints **2**: the field `final Pet? pet;` (:23) and the `copyWith` parameter `Pet? pet,` (:52) which the plan's own action requires ("`copyWith` and `props` gain `pet`"). The grep was written without the copyWith parameter in mind; the implementation follows the action.

Otherwise the plan executed as written.

## Known Stubs

None. `petPrizeLine` copy is provisional by decision D-06 (rendered in 14-05).

## Threat Flags

None beyond the plan's register (T-14-01..03 mitigated and under test).

## Self-Check: PASSED

- lib/models/quest/quest_enemy.dart, test/models/quest/quest_enemy_test.dart exist.
- Commits d5cdbe7, 4fef6c4, 723811e, 4493030, 208b6c3, 88217b4 present in `git log`.
