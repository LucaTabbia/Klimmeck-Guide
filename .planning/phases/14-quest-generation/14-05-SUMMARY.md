---
phase: 14-quest-generation
plan: 05
subsystem: ui
tags: [quest-sheet, enemies, portrait, announcement, companion, qgen-04, tdd]
requires:
  - 14-01 (QuestSheetDetails.enemyLines / strongestEnemy / petPrizeLine, QuestInfos.description, fixtures)
  - 14-04 (EnemyPortrait + EnemyPortrait.canShow)
provides:
  - Quest sheet combat body = strongest-enemy portrait (when resolvable) + BE-ordered «Nx nome» lines + «Consigliati»
  - Announcement under the title in the combat, service and narrative families
  - «Compagno in premio: <nome>» line in the prize row
  - QGEN-04 proof tests (crime/guard service, dungeon combat)
affects: [14-06, 14-11, phase-17]
tech-stack:
  added: []
  patterns: [one QuestSheetDetails computation per build passed to both halves of the sheet, shared _recommendedLoot block for combat and service]
key-files:
  created: []
  modified:
    - lib/shared/components/popup/quest_info_sheet.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/models/quest/quest_sheet_details_test.dart
decisions:
  - "The companion prize line sits in the prize row (Flexible, max 3 lines, ellipsis), not under it: under the row the coin column overflowed the landscape sheet by 78 px (D-06, Rule 1)"
  - "The prize row takes its height from its own LayoutBuilder instead of the repeated `maxHeight - 30`"
metrics:
  duration: ~25 min
  completed: 2026-11-04
  tasks: 4
  commits: 7
---

# Phase 14 Plan 05: Quest sheet for the multi-enemy contract Summary

The quest sheet's combat body now shows the `EnemyPortrait` of `details.strongestEnemy` only when `EnemyPortrait.canShow` is true, then one `AutoSizeText` per `details.enemyLines` entry in BE order, then «Consigliati». The announcement `infos.description` sits under the title in all three families, in italic and scrollable. The prize row names the companion. `Image.asset` is gone from the sheet, so IN-03 is closed there. QGEN-04 is proven by tests and needed no production change.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Combat body: portrait, «Nx nome» lines, «Consigliati» | c770e4f (test), e82f294 (feat) |
| 2 | Announcement under the title | f06c9bf (test), 39db15c (feat) |
| 3 | «Compagno in premio» line | 071930b (test), ef7bc2b (feat) |
| 4 | QGEN-04 proof (tests only) | c16d03c (test) |

## Exact names and signatures

`lib/shared/components/popup/quest_info_sheet.dart`, class `QuestInfoSheet`:
- New keys: `static const Key descriptionKey = ValueKey('questSheet.description');`, `static const Key petPrizeKey = ValueKey('questSheet.petPrize');`, `static const Key enemyPortraitKey = ValueKey('questSheet.enemyPortrait');`, `static const Key recommendedLootKey = ValueKey('questSheet.recommendedLoot');`. New copy constant: `static const String recommendedLootTitle = 'Consigliati';`. New private constant: `static const int _petPrizeMaxLines = 3;`.
- `_buildContent` computes `final details = QuestSheetDetails.of(quest!, viewer: viewer);` once and passes it to `_buildQuestInfo(QuestSheetDetails details)` and `_buildRewards(QuestSheetDetails details)`.
- `List<Widget> _description(KlimmeckGuideTheme theme)`: `[]` for a null or empty description. Otherwise `Flexible(SingleChildScrollView(Text(key: descriptionKey, textAlign: center, style: bodyLarge.copyWith(fontStyle: FontStyle.italic))))`. It sits between the title `Flexible` and the body `Expanded(flex: 4)`.
- `_combatBody`: the left `Expanded(_enemyColumn)` appears only when `enemyLines` or `recommendedLootLines` is non-empty. The right column (time, title, slots) is unchanged.
- `Widget _enemyColumn(QuestSheetDetails details)`: `Column[ if canShow → Expanded(EnemyPortrait(key: enemyPortraitKey, imagePath: strongest.imagePath)), Flexible(SingleChildScrollView(Column[ AutoSizeText(line, max 12, min 8, center, bodyLarge) per enemyLines, ..._recommendedLoot ])) ]`.
- `List<Widget> _recommendedLoot(QuestSheetDetails details)`: `[]` when empty. Otherwise `[Text(recommendedLootTitle, key: recommendedLootKey, style: specialText), Text(line, style: bodyLarge)…]`. The combat body and `_serviceBody` both use it.
- `_buildRewards` → `Column[SizedBox(30, «Ricompense:»), Expanded(LayoutBuilder(→ _prizeRow(details, constraints)))]`.
- `Widget _prizeRow(QuestSheetDetails details, BoxConstraints constraints)`: `Row(spaceBetween)[CoinsDisplay(height: maxHeight, width: maxWidth*0.5)?, Flexible(EquipmentItemCard|LootItemCard size maxHeight)?, Flexible(Text(petPrizeLine, key: petPrizeKey, maxLines 3, ellipsis, center, bodyLarge))?]`.

Tests in `test/shared/components/popup/quest_info_sheet_test.dart` (30 → 46 tests):
- Top-level helpers: `_goblinPortrait = 'v1/goblin_test.svg'`, `_goblinChiefPortrait = 'v1/goblin-chief_test.svg'`, `_potion` (recommendedLoot entry 2x Pozione), `_goblinPack()` (Goblin x3 xp 7 + Capo goblin x1 xp 21, both with SVG portraits), `Finder _inCombat(String text)`. `setUp` seeds `emptySheet` and both goblin SVGs.
- Group 'combat': the asset-image test «shows the enemy image, name and required time» is REWRITTEN as «shows the portrait of the strongest enemy (D-02, D-03)» (C5, not a regression: the DB placeholder `assets/images/…` is unresolvable under D-03). New tests in this group: BE order, bare name, unresolvable path, Consigliati below the lines, Consigliati omitted, and no overflow with 6 types and 4 items.
- New groups: 'announcement' (3 family tests built in a loop, null/empty, long scroll), 'companion prize' (3 tests; the coins test seeds the gold/silver/copper SVGs), 'fixed types (QGEN-04)' (dungeon, plus crime and guard checked in one test via a loop with `reason: type`, which keeps the plan's exact title).
- `test/models/quest/quest_sheet_details_test.dart` group 'questSheetFamilyOf': new test «crime and guard stay in the service family, dungeon in combat, without alignment (D-11)».

## RED failures observed

- Task 1: compilation failure `Member not found: 'enemyPortraitKey'` (2 sites).
- Task 2: compilation failure `Member not found: 'descriptionKey'` (3 sites).
- Task 3: compilation failure `Member not found: 'petPrizeKey'` (3 sites). After the first GREEN attempt (line under the row, as the plan wrote it), the test «a pet prize with coins does not overflow (D-06)» failed with `A RenderFlex overflowed by 78 pixels on the bottom` (40 px after the LayoutBuilder change). That led to the deviation below.
- Task 4: green at first run. QGEN-04 is already satisfied by the existing mapping (D-11) and the Tasks 1–2 rendering; no `lib` change (`git diff HEAD~1 --stat -- lib` empty).

## Tests

- `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/models/quest test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map` → `+419: All tests passed!`
- `flutter test test/shared/components/popup/quest_info_sheet_test.dart` → `+46: All tests passed!`
- Analyzer gate: `50 issues found` (all info), 0 error / 0 warning → `ANALYZE_GATE_OK` after every code task.
- `dart format` run on each touched file one by one. The sheet and test files were reformatted only in the lines touched here.

## Acceptance greps

`Image.asset` 0; `EnemyPortrait(` 1; `EnemyPortrait.canShow` 1; `details.enemyLines` 2; `_recommendedLoot(details)` 2; `'Consigliati'` 1; `D-0[234])` 7 in the test; `find.byType(Image), findsOneWidget` 0; `descriptionKey` 2; `FontStyle.italic` 1; `D-05)` 3; `petPrizeKey` 2; `details.petPrizeLine` 2; `QuestSheetDetails.of(` 1; `D-06)` 3; `D-11` 1 (details test) and 2 (sheet test).

## Deviations from Plan

**1. [Rule 1 - Bug] Companion line placed in the prize row instead of under it**
- **Found during:** Task 3 GREEN
- **Issue:** the plan put `Text(petPrizeLine)` after the `Expanded(Row …)` in the rewards Column. With coins in the prize, the `CoinsDisplay` column (three rows whose text height is fixed) lost the line's height and overflowed the landscape sheet by 78 px.
- **Fix:** the line is a `Flexible(Text(…, maxLines: 3, ellipsis))` child of the prize row, next to the coins and the prize item. Still in the prizes block, still no image (D-06). The row now takes its height from its own `LayoutBuilder` (`_prizeRow`) instead of the outer `maxHeight - 30` repeated four times (Boy Scout).
- **Files modified:** lib/shared/components/popup/quest_info_sheet.dart
- **Commit:** ef7bc2b

**2. [Minor] crime/guard proof is one test with a loop**
- The plan gives one title for both types. A single `testWidgets` that loops over `crime` and `guard` (with `reason: type`) keeps that exact title.

## Contract note

No `lib/graphql` change in this plan. The BE was not read (no `fetch`; the SSH agent is down, so a local `origin/develop` would have been used had it been needed).

## Known Stubs

None. The copy «Compagno in premio: <nome>» is provisional by D-06 (it lives in `QuestSheetDetails`, 14-01).

## Self-Check: PASSED

- lib/shared/components/popup/quest_info_sheet.dart, test/shared/components/popup/quest_info_sheet_test.dart, test/models/quest/quest_sheet_details_test.dart: FOUND
- Commits c770e4f, e82f294, f06c9bf, 39db15c, 071930b, ef7bc2b, c16d03c: FOUND
