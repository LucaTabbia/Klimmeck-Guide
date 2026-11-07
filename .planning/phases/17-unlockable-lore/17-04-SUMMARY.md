---
phase: 17-unlockable-lore
plan: 04
subsystem: shared
tags: [flutter, dart, widgets, quests, quest-results, lore, accessibility]

requires:
  - 17-02 (QuestEnemy.known, strongestEntryOf, QuestSheetDetails.isStrongestEnemyKnown, questEnemyJson(known))
  - 17-03 (QuestResultSheet lore lines; shared result files)
provides:
  - EnemyPortrait.known (bool, default true), EnemyPortrait.silhouetteFilter, EnemyPortrait.unknownSemanticLabel («Sagoma del nemico»)
  - QuestInfoSheet portrait follows QuestSheetDetails.isStrongestEnemyKnown
  - QuestResultSheet portrait follows strongestEntryOf(result.enemies)?.known ?? true
affects: [17-10]

tech-stack:
  added: []
  patterns:
    - "Silhouette = ColorFiltered(ColorFilter.mode(deepNight, srcIn)) inside the Semantics wrapper, same picture, same size"
    - "Widget-tree assertions for the filter (raster branch via imageBuilder called directly), never pixels"

key-files:
  created: []
  modified:
    - lib/shared/components/enemy_portrait.dart
    - lib/shared/components/popup/quest_info_sheet.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/shared/components/enemy_portrait_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart

key-decisions:
  - "The silhouette wraps the picture inside _announced, so SVG and raster share it and the label switches with known (D-08, D-17)"
  - "The result sheet passes only the BE known of the strongest entry; absent strongest -> true; no outcome inference (D-09)"

requirements-completed: []

duration: 5min
completed: 2026-11-07
---

# Phase 17 Plan 04: Black silhouette of unknown enemies Summary

**`EnemyPortrait(known: false)` paints the existing SVG or raster portrait as a `ColorFiltered(deepNight, srcIn)` black silhouette labelled «Sagoma del nemico»; the quest sheet and the result sheet pass the strongest enemy's own BE `known`.**

## Performance

- Duration: ~5 min
- Tasks: 2 (4 commits)
- Files modified: 6 (3 lib, 3 test), no new file

## Task Commits

1. Task 1 RED `1fd7661` test(shared): expect the silhouette of an unknown enemy
2. Task 1 GREEN `b89edd6` feat(shared): draw unknown enemies as black silhouettes
3. Task 2 RED `7428a38` test(quests): expect silhouettes of unknown enemies on the sheets
4. Task 2 GREEN `40b7c30` feat(quests): show unknown strongest enemies as silhouettes

## What was built

- `lib/shared/components/enemy_portrait.dart`: ctor `EnemyPortrait({super.key, required this.imagePath, this.height, this.cacheManager, this.known = true})`; `final bool known`; `static const String unknownSemanticLabel = 'Sagoma del nemico'`; `static const ColorFilter silhouetteFilter = ColorFilter.mode(KlimmeckGuideTheme.deepNight, BlendMode.srcIn)`; `_announced` picks the label by `known` and wraps the picture in `ColorFiltered(colorFilter: silhouetteFilter, child: picture)` when unknown. Class doc no longer says «la Phase 17 lo scurirà».
- `quest_info_sheet.dart` `_enemyColumn`: `known: details.isStrongestEnemyKnown`.
- `quest_result_sheet.dart` `_enemies()`: `final strongest = strongestEntryOf(_result.enemies); final portraitPath = strongest?.enemy.imagePath;` and `known: strongest?.known ?? true`; doc gains the D-08/D-09 note.

## TDD

- Task 1 RED: compile errors (`known` named parameter missing, `silhouetteFilter` and `unknownSemanticLabel` not found).
- Task 2 RED: 2 failing of the 5 new cases («an unknown strongest enemy is a silhouette and its lines stay (D-08)», «after a defeat an unknown enemy stays a silhouette (D-09)»: 0 `ColorFiltered`). The three «in clear» cases («a known strongest enemy is drawn in clear beside unknown ones (D-08)», «a victory shows the defeated enemies in clear (D-09)», «the portrait follows the strongest enemy's own known (D-08)») were green at the first run by construction: before GREEN the sheets never draw a silhouette; they pin that the GREEN does not over-darken.
- Task 1: «a known enemy keeps today's portrait (D-08)» and «no portrait path still renders nothing when unknown (D-08)» were part of a RED that failed at compile time, so they never ran red on their own; same reason as above.

## Verification

- `flutter test test/shared/components/enemy_portrait_test.dart` → +12 all passed.
- `flutter test test/shared/components/popup test/screens/mainScreen/components test/screens/mainScreen/tabs/board` → +292 all passed.
- `flutter test test/shared test/screens/mainScreen/components test/screens/mainScreen/tabs/board` → +425 all passed.
- `flutter analyze`: `50 issues found.` (all info), 0 error, 0 warning.
- `dart format` on the 6 touched files one by one: 0 changed each (all formatter-clean). `cached_svg.dart` untouched.
- Trailer check 0 on all commits.

## Notes

- D-18: `quest_result_sheet.dart` and `quest_result_sheet_test.dart` are shared with the parked FE Phase 16 branch; the lib edit is local to `_enemies()` (3 lines + doc line); the test edit is additive (new import of `quest_fixtures.dart`, a local `silhouetteOfPortrait()` finder and three tests inside the existing `'enemies fought'` group). The ambush carousel of FE Phase 16 reuses `_enemies()` and inherits the rule when the branches meet (D-09).
- `quest_info_sheet_test.dart`: `_goblinPack` gains `{bool goblinsKnown = true, bool chiefKnown = true}`; existing callers unchanged.
- A5: rendering of `ColorFiltered(srcIn)` over `SvgPicture`/raster in a release build is checked on the device in 17-10.
- `strongestEnemyOf` now has no caller in `lib/` (only its definition and its tests in `quest_enemy_test.dart`); left in place (tested public helper, out of this plan's files).
- T-17-10 mitigated (filter on both branches, tests on both); the image file is still downloaded because the BE sends `imagePath` (accepted, BACKEND-NOTES §4). T-17-11 mitigated (sheets read only `known`).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED

- All 6 modified files exist; commits 1fd7661, b89edd6, 7428a38, 40b7c30 present in `git log`.
