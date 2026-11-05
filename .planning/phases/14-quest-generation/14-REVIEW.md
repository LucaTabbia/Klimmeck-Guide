---
phase: 14-quest-generation
reviewed: 2026-11-04T19:20:19Z
depth: standard
files_reviewed: 26
files_reviewed_list:
  - lib/graphql/fragments/equipment_fragment.dart
  - lib/graphql/fragments/quest_fragment.dart
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/graphql/mutations/quest_mutations.dart
  - lib/models/enums/accessory_use_type.dart
  - lib/models/equipment_item.dart
  - lib/models/quest/quest_enemy.dart
  - lib/models/quest/quest_infos.dart
  - lib/models/quest/quest_prizes.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/quest_result/quest_rewards.dart
  - lib/repository/innkeeper_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/screens/innkeeper/components/generate_quests_button.dart
  - lib/screens/innkeeper/innkeeper_panel_route.dart
  - lib/screens/innkeeper/innkeeper_panel_screen.dart
  - lib/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart
  - lib/screens/innkeeper/questGenerationCubit/quest_generation_state.dart
  - lib/shared/components/enemy_portrait.dart
  - lib/shared/components/popup/equipment_info_sheet.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/utils/enemy_portrait_url.dart
  - lib/utils/item_lines.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 1
  info: 5
  total: 6
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-11-04
**Depth:** standard
**Files Reviewed:** 26 (plans 14-01..14-09; 14-10 and 14-11 are gated on the BE Phase 13 merge and are deferred, not findings)

## Summary

The phase is in good shape. `flutter analyze` on the touched trees reports no issues. Checked and found correct:

- **Parsing sides.** The strict `QuestEnemy.listFrom` is used only on the board side (`QuestInfos`, so a malformed entry drops the quest through `Quest.tryFromJson`). The lenient `lenientListFrom` is used only on the result side. `stagesCleared` and `stagesTotal` go through a null-safe `_countFrom`. `QuestRewards.isEmpty` counts the pet. `_petFrom` ignores a pet without a string id.
- **Pure helpers.** `enemyLinesOf` merges by id, keeps the BE order, and prints the bare name only for exactly one type with total 1. `strongestEnemyOf` treats null xp as 0 and ties go to the first entry. `enemyPortraitUrl` accepts only `https` with a host or `v<n>/…`.
- **Contract discipline.** Documents select exactly the agreed fields. There is no `relatedLore` or `locations` under an enemy, no single `enemy {` selection is left in `lib/graphql`, and `GenerateQuests` is in the registry. Classifiers read `extensions.code` only. There is no `print` and no raw server text in the UI.
- **Jewels.** `AccessoryUseType` parsing ignores unknown values. The «Uso» line is built only for ring and necklace. `accessoryUseTypes` is in `fields` and `fieldsWithFullSpell`, so Journal, shop and pet equipment all receive it.
- **Locanda.** The cubit is a no-op while submitting. It never goes back to Idle. Failures carry a serial. The `SafeEmit` mixin covers emits after close. The route provides the cubit lazily. The dialog precedes the call. `isClosed` is checked after the await. `FORBIDDEN` reuses `_closeUnavailable`. Other failures get the fixed copy.
- **Rules 1, 2 and 4.** No `Image.asset`, no app chrome outside the utility screen, no loading scaffolding on the gameplay sheets. The `CachedSvg` spinner is the accepted baseline: the sheet background uses the same widget, and today no enemy has an `.svg` path (see IN-01).

One layout risk is untested (WR-01) and five quality items remain.

## Warning

### WR-01: Prize row with coins + item + pet squeezes the item card, and the combination is untested

**File:** `lib/shared/components/popup/quest_info_sheet.dart:353-390`
**Issue:** `_prizeRow` lays out `CoinsDisplay(width: maxWidth * 0.5)` plus two `Flexible` children (item card, pet text) in one `Row`. With all three present, the item card and the pet text share the remaining 50% at flex 1 each. That is about 25% of the width each, roughly 88 px in the 780x360 landscape test surface. `EquipmentItemCard` and `LootItemCard` are built with `size: constraints.maxHeight`, about 122 px there. A card sized for 122 px is therefore forced into a loose maximum of about 88 px. Before the pet line the item had about 176 px, so this is a regression introduced by the pet line. The only widget test for the overflow fix (`quest_info_sheet_test.dart:434-454`) covers coins + pet without a `prizeItem`. A boss quest carrying coins, a prize item and a pet is exactly the reward shape D-06 introduces. I could not run it (read-only review), so whether the card throws a RenderFlex overflow or only distorts is unconfirmed.
**Why it matters:** A boss sheet is the one where players look at the prizes most closely. It would render a squeezed or overflowing card, and in debug a yellow-black overflow banner.
**Suggested fix:** Write the RED test first in `quest_info_sheet_test.dart`: group «companion prize», `prizeCoins` + `prizeItem` (equipment and loot variants) + `pet`, pumped in landscape, `expect(tester.takeException(), isNull)` and `tester.getSize` of the item card equal to its requested size. Then make the row degrade explicitly. For example, give the pet line its own line under the row (a `Column` of Row + Text inside the `Expanded`), or size the item card with `min(constraints.maxHeight, remainingWidth)`. Either keeps the card square.

## Info

### IN-01: `EnemyPortrait` documentation says «mai uno spinner», but the SVG branch can show one; the semantics label is also announced for an empty box

**File:** `lib/shared/components/enemy_portrait.dart:8-11, 35`
**Issue:** The doc comment says «nessun riquadro … mai uno spinner». The SVG branch goes through `CachedSvg`, which shows a 14 px `CircularProgressIndicator` while loading (14-04-SUMMARY records this). In addition, `Semantics(label: 'Ritratto del nemico', image: true)` wraps the child even when `CachedNetworkImage` ends in its empty `errorWidget` or the SVG load fails, so a screen reader announces an image that is not there.
**Why it matters:** Only documentation and accessibility accuracy; no visible regression, because no enemy has an `.svg` Cloudinary path today.
**Suggested fix:** Correct the comment («raster: nessuno spinner; SVG: lo spinner di `CachedSvg`»). Optionally move `Semantics` into the `imageBuilder` of `CachedNetworkImage` so it exists only when the picture is shown.

### IN-02: `_petFrom` is duplicated in two models

**File:** `lib/models/quest/quest_prizes.dart:76-79` and `lib/models/quest_result/quest_rewards.dart:25-28`
**Issue:** The same `json is Map<String, dynamic> && json['id'] is String ? Pet.fromJson(json) : null` guard exists twice.
**Why it matters:** The Boy Scout rule asks for no micro-duplication. A change to the tolerance (for example a non-String `name`, which today still throws a TypeError inside `Pet.fromJson`) must be made in two places.
**Suggested fix:** Add one `Pet? Pet.tryFromRef(Object? json)` (or a top-level `petRewardFrom`) next to `Pet` and call it from both models, with the existing tests moved to it.

### IN-03: `EquipmentFragment.definition` is dead code and was left without `accessoryUseTypes`

**File:** `lib/graphql/fragments/equipment_fragment.dart:5-29`
**Issue:** The `EquipmentItemFields` fragment (`name` + `definition`) has no consumer in `lib`, `test` or `tool`, and it is the only equipment selection that did not get `accessoryUseTypes` in plan 14-01. If someone wires it later, jewels would silently lose their «Uso» line.
**Why it matters:** Latent inconsistency that nothing guards.
**Suggested fix:** Delete the unused fragment (separate Boy Scout commit), or add `accessoryUseTypes` to it.

### IN-04: `enemyLinesOf` can print the bare name for a quest with more than one enemy

**File:** `lib/models/quest/quest_enemy.dart:84-100`
**Issue:** Entries without a name are skipped before the «exactly one type with total 1» check. The input `[Goblin x1, <unnamed id x2>]` yields `names.length == 1 && quantity == 1`, so the sheet shows «Goblin» as if the quest were a single enemy, while the BE says three. `strongestEnemyOf` still counts the unnamed entry, so the portrait may belong to an enemy that has no line.
**Why it matters:** Wrong count only for a DB entry with a missing enemy name, so it is unlikely. But the bare-name rule is meant to say «one enemy», and it can lie.
**Suggested fix:** Decide the bare-name case on the unfiltered totals. For example, compute `total = enemies.fold(0, (s, e) => s + e.quantity)` and use the bare name only when `names.length == 1 && total == 1`. RED test first in `quest_enemy_test.dart`: `[named x1, unnamed x2]` renders «1x Goblin».

### IN-05: Residual duplication and an asymmetric `toJson`

**File:** `lib/shared/components/popup/quest_info_sheet.dart:199-229` and `lib/shared/components/popup/quest_result_sheet.dart:232-254`; `lib/models/quest/quest_infos.dart:53-55`
**Issue:** `_enemyColumn` and `_enemies` repeat the same three steps: take `strongestEnemyOf(...)?.imagePath`, gate on `EnemyPortrait.canShow`, then print one text per `enemyLinesOf` entry. They differ only in layout (Expanded versus a fixed 48 px box, AutoSizeText versus Text). Separately, `QuestInfos.toJson` emits `enemies: [{enemy: <id string>, quantity}]` while `fromJson` requires `enemy` to be a map, so the pair does not round-trip. `QuestResult.toJson` uses the full object shape. No caller serialises a `Quest` today (only `Character.toJson` is used), so this is dormant.
**Why it matters:** A third consumer (Phase 16 ambushes, Phase 17 portrait) would copy the block again. The `toJson` mismatch bites when someone adds a cache.
**Suggested fix:** Extract a small `EnemyRoster` view model (portrait path + lines) from `QuestSheetDetails`, reused by the result sheet, so the two sheets only differ in layout. Make `QuestInfos.toJson` emit `e.toJson()` for each entry, with a round-trip test.

---

_Reviewed: 2026-11-04_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
