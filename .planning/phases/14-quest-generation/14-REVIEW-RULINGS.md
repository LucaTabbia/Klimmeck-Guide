# Orchestrator rulings on 14-REVIEW.md (FE Phase 14) — apply in this order, one commit pair (RED test → GREEN fix) per finding

## WR-01 — FIX
Direction: make `_prizeRow` degrade explicitly when coins, a prize item and a companion are all present. The item card keeps its requested size (wrap it in a `SizedBox(width: constraints.maxHeight)` instead of `Flexible`), the companion line takes the remaining width (`Flexible`/`Expanded`, `maxLines: 3`, ellipsis), and the coins column shrinks to `constraints.maxWidth * 0.35` only when both the item and the companion are present (keep `0.5` otherwise, so the existing layouts do not move). The companion line stays inside the prizes block, no image (D-06). Keep the 14-05 overflow case (coins + pet) green.
RED first in `test/shared/components/popup/quest_info_sheet_test.dart`, group «companion prize»: pump (landscape harness) a quest with `prizeCoins` + `prizeItem` (one equipment variant and one loot variant) + `pet`; expect `tester.takeException()` null, the item card (`EquipmentItemCard` / `LootItemCard`) size equal to the row height it requested, and the companion text (`QuestInfoSheet.petPrizeKey`) present. Seed the coin SVGs and the item type SVGs with `seedSvgCache` as the existing D-06 test does.

## IN-01 — FIX (doc + semantics)
Direction: (a) correct the doc comment of `lib/shared/components/enemy_portrait.dart` («raster: nessuno spinner; SVG: lo spinner di `CachedSvg` mentre carica»); (b) announce `Semantics(label: EnemyPortrait.semanticLabel, image: true)` only around a rendered picture: raster branch → move the `Semantics` into the `imageBuilder` of `CachedNetworkImage` (placeholder and errorWidget stay `SizedBox.shrink()`), SVG branch unchanged.
RED first in `test/shared/components/enemy_portrait_test.dart`: with the pending cache manager (raster never arrives) `find.bySemanticsLabel(EnemyPortrait.semanticLabel)` findsNothing; with a seeded SVG (`seedSvgCache`) it findsOneWidget (`tester.ensureSemantics()`, dispose the handle). Adjust the existing semantics test accordingly.

## IN-02 — FIX (Boy Scout)
Direction: add `static Pet? tryFromJson(Object? json)` on `Pet` (`lib/models/pet.dart`: returns `Pet.fromJson` only for a `Map<String, dynamic>` whose `id` is a `String`, null otherwise) and call it from `QuestPrizes` and `QuestRewards`, deleting both private `_petFrom`. Keep the existing prize/reward tests green; add the two cases (non-map, missing id) to `test/models/pet_test.dart` (create it if missing). Models stay Flutter-free.

## IN-03 — FIX (Boy Scout, delete)
`EquipmentFragment.definition` / `EquipmentItemFields` has no consumer in `lib`, `test` or `tool` (verified by the orchestrator): delete the getter and its doc comment in a single `refactor(graphql): drop the unused equipment definition fragment` commit; if a test asserts its text, delete that assertion too. Analyzer must stay 0 error / 0 warning; the registry stays at 44 documents.

## IN-04 — FIX
Direction: in `enemyLinesOf` (`lib/models/quest/quest_enemy.dart`) decide the bare-name case on the UNFILTERED total: `final total = enemies.fold<int>(0, (sum, e) => sum + e.quantity);` and use the bare name only when `names.length == 1 && total == 1`; nameless entries still get no line.
RED first in `test/models/quest/quest_enemy_test.dart`: `[Goblin x1, <unnamed id> x2]` → `['1x Goblin']` (D-02); keep `[Goblin x1]` → `['Goblin']`.

## IN-05 — FIX (toJson only) / NOT_NEEDED (roster extraction)
- `QuestInfos.toJson` (`lib/models/quest/quest_infos.dart`): emit `"enemies": enemies.map((e) => e.toJson()).toList()` so that `QuestInfos.fromJson(infos.toJson())` round-trips (no caller serialises a quest today: verified by the orchestrator). RED first in `test/models/quest/quest_test.dart`: round-trip of a quest with two enemies keeps the enemies (ids, names, xp, quantities). `fix(models)` scope.
- The `EnemyRoster` extraction shared by the two sheets is NOT_NEEDED now: the two sheets already read the same pure helpers (`enemyLinesOf`, `strongestEnemyOf`, `EnemyPortrait.canShow`) and differ in layout; a shared view model is introduced when Phase 16 (ambush outcomes) adds the third consumer. Record this reason in REVIEW-FIX.md; do not change code for it.
