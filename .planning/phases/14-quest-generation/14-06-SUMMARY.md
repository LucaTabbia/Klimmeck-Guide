---
phase: 14-quest-generation
plan: 06
subsystem: ui
tags: [result-sheet, enemies, portrait, dungeon, companion, qgen-02, qgen-04, tdd]
requires:
  - 14-01 (enemyLinesOf / strongestEnemyOf)
  - 14-02 (QuestResult.enemies / stagesCleared / stagesTotal, QuestRewards.pet, dungeonResultJson)
  - 14-04 (EnemyPortrait + EnemyPortrait.canShow)
provides:
  - Result sheet enemies block = strongest-enemy portrait (when resolvable) + BE-ordered «Nx nome» lines, under `QuestResultSheet.enemyKey`
  - «Esplorazione: tappa k di N» line for a dungeon result (BE counters printed, never computed)
  - «Compagno ottenuto: <nome>» line in the rewards section, also for a pet-only reward
  - QGEN-04 proof on the result side (dungeon renders like any combat result)
affects: [14-11, phase-16, phase-17]
tech-stack:
  added: []
  patterns: [same enemies rule as the quest sheet (portrait only through EnemyPortrait.canShow), counters rendered through the existing _line helper]
key-files:
  created: []
  modified:
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
decisions:
  - "The stage line goes through the existing `_line` helper right after the enemies block (same padding and style as the XP/level lines)"
  - "The companion line is the last child of the rewards `_section`, after the item rows; `hasRewards` already counts the pet (14-02), so a pet-only reward shows the section"
metrics:
  duration: ~15 min
  completed: 2026-11-04
  tasks: 2
  commits: 4
---

# Phase 14 Plan 06: Result sheet for the multi-enemy contract Summary

The result sheet now lists the enemies fought as «Nx nome» lines in BE order (bare name for a single enemy × 1) under `QuestResultSheet.enemyKey`, with the `EnemyPortrait` of the strongest enemy only when `EnemyPortrait.canShow` is true. `Image.asset` is gone from the result sheet, which closes IN-03 there. A dungeon result shows «Esplorazione: tappa k di N» from the BE counters. A companion reward shows «Compagno ottenuto: <nome>» in the rewards section. A GM completion still shows no enemy block.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Enemies fought block with the strongest portrait | 17e8a69 (test), 804d036 (feat) |
| 2 | Dungeon stages and companion reward lines | e0da620 (test), ccb18cf (feat) |

## Exact names and signatures

- `QuestResultSheet.enemyPortraitKey = ValueKey('questResult.enemyPortrait')`
- `QuestResultSheet.stagesKey = ValueKey('questResult.stages')`
- `QuestResultSheet.petRewardKey = ValueKey('questResult.petReward')`
- `_QuestResultSheetState._enemies()` (renamed from `_enemy()`): `[]` when `enemyLinesOf(_result.enemies)` is empty; otherwise `Column(key: enemyKey)[ if EnemyPortrait.canShow(path) SizedBox(height: 48, EnemyPortrait(key: enemyPortraitKey, imagePath:, height: 48)), Text(line, center, bodyMedium) per line ]`.
- `_stagesText()`: null when `stagesTotal` is null; else `'Esplorazione: tappa ${stagesCleared ?? 0} di $total'`. Rendered with `_line(_stagesText(), QuestResultSheet.stagesKey)` right after `..._enemies()` in `_content()`.
- `_petRewardText()`: null for a null/empty `rewards.pet?.name`; else `'Compagno ottenuto: $name'`. Rendered as `Text(text, key: petRewardKey, style: bodyMedium)` after `_itemRows(rewards.items)`.
- Test file: constants `_trollPortrait = 'v1/troll_test.svg'` (added to the `setUp` seed list) and `_owl = {'id': 'pet-owl', 'name': 'Gufo reale'}`; new groups 'enemies fought' (4 tests) and 'dungeon and companion' (7 tests); imports `quest_type.dart` and `quest_outcome.dart`.

## RED failures observed

- Task 1: compilation failure `Member not found: 'enemyPortraitKey'` (3 sites).
- Task 2: compilation failure `Member not found: 'stagesKey'` (4 sites) and `'petRewardKey'` (2 sites).

## Tests

- `flutter test test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/components` → 151 passed (Task 1).
- `flutter test test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen test/screens/innkeeper` → 1078 passed (Task 2).
- `quest_result_sheet_test.dart` alone → 35 passed (24 before + 11 new).
- Existing «gmCompleted: no enemy and the title change» and «shows the D-03 content…» stay green unchanged.

## Acceptance greps

- `Image.asset` 0, `EnemyPortrait(` 1, `enemyLinesOf(_result.enemies)` 1, `key: QuestResultSheet.enemyKey` 1, `D-07` in the test 3 (Task 1).
- `stagesKey` 2, `Esplorazione: tappa` 1, `petRewardKey` 2, `Compagno ottenuto: ` 1, `D-07)\|D-11)` 8 (Task 2).
- Analyzer: 50 issues, all info, 0 error / 0 warning → `ANALYZE_GATE_OK` after both tasks.
- `dart format` run on the two touched files only.

## Deviations from Plan

None - plan executed exactly as written. (The `Text` of the pet line was split over several lines by `dart format`; no grep depended on it.)

## Known Stubs

None. Copy «Esplorazione: tappa k di N» and «Compagno ottenuto: <nome>» is provisional per D-07.

## Self-Check: PASSED
