---
phase: 14-quest-generation
plan: 02
subsystem: models
tags: [quest-result, models, enemies, dungeon, pet, fixtures, tdd]
requires:
  - 14-01 (QuestEnemy.lenientListFrom, strongestEnemyOf, questEnemyJson)
provides:
  - QuestResult.enemies / stagesCleared / stagesTotal (QuestResult.enemy removed)
  - QuestRewards.pet counted by isEmpty
  - fixtures questResultJson params enemies, stagesCleared, stagesTotal, rewardPet; dungeonResultJson
affects: [14-03, 14-06]
tech-stack:
  added: []
  patterns: [lenient per-entry list parsing for results, numeric-or-null counters]
key-files:
  created: []
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/models/quest_result/quest_rewards.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_result_test.dart
decisions:
  - "Stage counters parse through _countFrom (num → int, anything else → null) so a malformed counter never drops the result"
  - "QuestRewards.toJson writes pet only when set, as {id, name}, which round-trips through Pet.fromJson"
metrics:
  duration: ~15 min
  completed: 2026-11-04
  tasks: 2
  commits: 4
---

# Phase 14 Plan 02: Result-side models for the BE Phase 13 contract Summary

`QuestResult.enemies` (parsed with `QuestEnemy.lenientListFrom`, so a malformed entry is dropped and the result kept) replaces `QuestResult.enemy`, `stagesCleared` / `stagesTotal` arrive as nullable ints for dungeons, and `QuestRewards.pet` parses and counts in `isEmpty` so a pet-only reward shows; the result sheet only reads `strongestEnemyOf(_result.enemies)` (layout untouched until 14-06).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | QuestResult.enemies (lenient) + stagesCleared / stagesTotal | fea7f66 (test), 1e46eca (feat) |
| 2 | QuestRewards.pet counted by isEmpty | 2c9c7f5 (test), 6f6b318 (feat) |

## RED failures observed

- Task 1: compile failure — `Error: The getter 'enemies' isn't defined for the type 'QuestResult'`, `The getter 'stagesCleared' isn't defined for the type 'QuestResult'`, `The getter 'stagesTotal' isn't defined for the type 'QuestResult'`.
- Task 2: compile failure — `Error: The getter 'pet' isn't defined for the type 'QuestRewards'`.

No test was green at its first run (both RED runs were whole-file compile failures).

## Tests

- After Task 1: `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart test/repository test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit test/screens/innkeeper` → 1149 passed.
- After Task 2: `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart` → 75 passed; `test/models/quest_result/quest_result_test.dart` alone → 46 passed.
- Analyzer after each code task: `50 issues found.` (all info), 0 error, 0 warning → `ANALYZE_GATE_OK`.
- Acceptance greps: `Enemy? enemy` 0, `_enemyFrom` 0, `QuestEnemy.lenientListFrom` 1, `stagesCleared` 5, `stagesTotal` 5, `hasEnemy` 0, `dungeonResultJson` 1 (fixtures), `result.enemy\b` nothing, `D-0[17])` 7; `pet == null` 1, `Pet? pet` 1, `rewardPet` 2, no `package:flutter/` in `lib/models/quest_result`.

## Exact names created

- `QuestResult` (lib/models/quest_result/quest_result.dart): `final List<QuestEnemy> enemies`, `final int? stagesCleared`, `final int? stagesTotal` (all `required` in the ctor, only `fromJson` calls it); `fromJson` → `QuestEnemy.lenientListFrom(json['enemies'])`, `_countFrom(json['stagesCleared'])`, `_countFrom(json['stagesTotal'])`; `static int? _countFrom(Object? json)`; `toJson` writes `'enemies': [entry.toJson()]`, `'stagesCleared'`, `'stagesTotal'` (always, null outside a dungeon); all three in `props`. Removed: field `enemy`, `_enemyFrom`, the `enemy.dart` import.
- `QuestRewards` (lib/models/quest_result/quest_rewards.dart): `const QuestRewards({required this.coins, required this.items, this.pet})`, `final Pet? pet`, `bool get isEmpty => coins.toCopper() == 0 && items.isEmpty && pet == null`, `static Pet? _petFrom(Object? json)` (null unless Map with String `id`), `toJson` `if (pet != null) 'pet': {'id', 'name'}`, `props => [coins, items, pet]`.
- `QuestResultSheet._enemy()`: `final enemy = strongestEnemyOf(_result.enemies);` (import `quest_enemy.dart`).
- Fixtures (test/helpers/fixtures/quest_result_fixtures.dart, now imports `quest_fixtures.dart`): `questResultJson` gains `List<Object?>? enemies` (default `[questEnemyJson(imagePath: 'enemies/wolf.png')]`), `Object? stagesCleared`, `Object? stagesTotal` (always written, default null), `Map<String, dynamic>? rewardPet` (written as `rewards.pet` only when non-null); `hasEnemy` removed; `gmCompletedResultJson` passes `enemies: const []`. New `dungeonResultJson({String id = 'result-dungeon', String outcome = 'failure', int stagesCleared = 1, int stagesTotal = 3})`: questType `dungeon`, title `Le grotte di Bosa`, enemies `3x Goblin (id goblin, xp 7)`, `Capo goblin (goblin-chief, xp 21)`, `Troll (troll, xp 126, imagePath v1/troll_test.svg)`; zero coins / no items unless `outcome == 'success'`.
- Tests (test/models/quest_result/quest_result_test.dart): in 'parsing per outcome' «parses the enemies fought in BE order (D-07)», «keeps xp of the enemies fought for the portrait (D-01)», «a dungeon carries stagesCleared and stagesTotal (D-07)», «stages are null outside a dungeon (D-07)», «a GM completion has no enemies»; new group 'companion reward' (4 tests); in 'tolerance' the rewritten «an enemy with locations never reaches Enemy.fromJson», «drops a malformed enemies entry and keeps the result (D-01)», «a missing enemies key gives an empty list (D-01)», «a non-numeric stage counter is null, the result is kept (D-07)»; round-trip payloads `dungeon`, `dungeon victory`, `pet reward`.

## Files formatted

`dart format` run on each touched file by name, one by one; every run reported `0 changed`. In the fixture the `Troll` `questEnemyJson(...)` call of the plan skeleton was written already wrapped (over 80 columns on one line).

## Deviations from Plan

None - plan executed exactly as written. Small additions inside the plan's intent: the dungeon test also asserts the BE order of the enemy ids, and the non-numeric stage test also asserts `stagesCleared == 1` survives. The BE repo was not needed (no schema read).

## Known Stubs

None. The result sheet still renders only the strongest enemy with `Image.asset` by design until 14-06 (D-07, D-03).

## Threat Flags

None beyond the plan's register (T-14-04, T-14-05 mitigated and under test).

## Self-Check: PASSED

- All five modified files exist; commits fea7f66, 1e46eca, 2c9c7f5, 6f6b318 present in `git log`.
