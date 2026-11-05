---
phase: 14-quest-generation
fixed: 2026-11-04T19:32:18Z
source: 14-REVIEW.md
review_path: .planning/phases/14-quest-generation/14-REVIEW.md
rulings_path: .planning/phases/14-quest-generation/14-REVIEW-RULINGS.md
iteration: 1
fix_scope: all
findings_total: 6
findings_in_scope: 6
fixed_count: 6
skipped_count: 0
not_needed_count: 1
deferred_count: 0
status: all_fixed
---

# Phase 14: Code Review Fix Report

**Fixed at:** 2026-11-04T19:32:18Z
**Source review:** `.planning/phases/14-quest-generation/14-REVIEW.md`
**Rulings:** `.planning/phases/14-quest-generation/14-REVIEW-RULINGS.md`
**Iteration:** 1
**Branch:** `feat/14-quest-generation` (no push). Start `608618b`, final code HEAD `fe62932`.

**Summary:**
- Findings in the review: 6 (0 critical, 1 warning, 5 info)
- Findings in scope: 6 (the orchestrator ruled on every item before the fixer ran)
- Fixed: 6 (WR-01, IN-01, IN-02, IN-03, IN-04, and the `toJson` part of IN-05)
- Not needed: 1 part (the `EnemyRoster` extraction of IN-05), recorded with the orchestrator's reason, no code change
- Skipped: 0. Deferred: 0.

Every behaviour fix went Red → Green: a failing-test commit (`test(quest|models): …`), then the fix commit (`fix(quest|models): …`). IN-03 is a dead-code removal (`refactor(graphql): …`). Commits use plain `git` with explicit paths, carry no trailers and rewrite no history.

These decisions still hold:
- Rule 2: nothing new loads; no spinner or skeleton added on the gameplay sheets.
- The backend stays the source of truth: the FE still only merges enemy lines by id and picks the highest `xp` for the portrait (D-02).
- Registry stays at 44 documents. The only GraphQL change is the deletion of the unused `EquipmentFragment.definition` (`EquipmentItemFields`); no selection of a used document changed.
- No new dependency, Cloudinary asset id or environment variable. Models stay Flutter-free.

## Gate finale

| Check | Result |
|-------|--------|
| `flutter analyze` (repo-wide) | **50 issues found, all info, 0 errors / 0 warnings**: unchanged baseline |
| `flutter test` (full suite, foreground) | **`01:12 +3180: All tests passed!`** |
| `dart format --output=none --set-exit-if-changed` on every touched file | clean; each file was formatted on its own |
| Trailers on `608618b..HEAD` (`co-authored-by` / `generated with`) | 0 |
| `git status --short` | empty before the report commit |

## Per-finding table

| ID | Severity | Outcome | Commits (test → fix) | Tests added / changed |
|----|----------|---------|----------------------|-----------------------|
| WR-01 | Warning | fixed | `d66f788` → `32d7fc2` | `quest_info_sheet_test.dart` «companion prize»: «coins, a prize item (equipment) and a pet keep the card square (D-06)», «… (loot) …» |
| IN-01 | Info | fixed | `079c87a` → `8ed407b` | `enemy_portrait_test.dart`: «a raster portrait still loading announces no image (D-03)»; existing semantics test renamed «a shown SVG portrait carries a semantic label (D-03)» |
| IN-02 | Info | fixed | `e2d16f3` → `1e7dc78` | `pet_test.dart` group «Pet.tryFromJson»: valid map, non-map, missing / non-string id |
| IN-03 | Info | fixed (refactor) | — → `f9c46df` | none: no test asserted the fragment text |
| IN-04 | Info | fixed | `0aa9233` → `7376547` | `quest_enemy_test.dart`: «a named enemy beside unnamed ones keeps its count (D-02)» |
| IN-05 (`toJson`) | Info | fixed | `c2491a4` → `fe62932` | `quest_test.dart`: «toJson round-trips the enemies through fromJson (D-01)» replaces «toJson writes enemies as id and quantity (D-01)» |
| IN-05 (`EnemyRoster`) | Info | not_needed | — | — |

## WR-01: Prize row with coins + item + pet squeezes the item card

**RED observed (`d66f788`):** both variants (equipment, loot), landscape harness 780x360: `Expected: Size(121.8, 121.8)  Actual: Size(88.2, 121.8)`; no RenderFlex exception was thrown, the card was only distorted.

**Fix (`32d7fc2`):** `lib/shared/components/popup/quest_info_sheet.dart` `_prizeRow`: the item card sits in `SizedBox(width: constraints.maxHeight)` instead of `Flexible`; the companion line keeps `Flexible` (3 lines, ellipsis); the coins column is `maxWidth * 0.35` only when both a prize item and a companion are present, `0.5` otherwise (named constants `_coinsShare`, `_coinsShareBesideItemAndCompanion`). The 14-05 case (coins + pet) stays green.

## IN-01: `EnemyPortrait` doc and semantics

**RED observed (`079c87a`):** with the pending cache manager the label `Ritratto del nemico` was found on the empty raster placeholder.

**Fix (`8ed407b`):** `lib/shared/components/enemy_portrait.dart`: the raster branch builds the picture in the `imageBuilder` of `CachedNetworkImage` (`Image(image:, height:, fit: BoxFit.contain)`) wrapped in the `Semantics`; placeholder and errorWidget stay `SizedBox.shrink()`; the SVG branch keeps the `Semantics` around `CachedSvg` (unchanged, as ruled). The doc comment now says «Raster: nessuno spinner; SVG: lo spinner di [CachedSvg] mentre carica».

## IN-02: `_petFrom` duplicated

**RED observed (`e2d16f3`):** compile error, `Pet.tryFromJson` did not exist (new API, unavoidable compile-level RED).

**Fix (`1e7dc78`):** `static Pet? tryFromJson(Object? json)` on `Pet` (map with a `String` id → `Pet.fromJson`, null otherwise); `QuestPrizes.fromJson` and `QuestRewards.fromJson` call it; both private `_petFrom` deleted. Prize and reward tests unchanged and green.

## IN-03: `EquipmentFragment.definition` dead code

**Fix (`f9c46df`):** deleted the `name` constant (`EquipmentItemFields`), the `definition` getter and the two imports only it used (`coins_fragment.dart`, `damage_fragment.dart`). `grep` found no consumer in `lib`, `test` or `tool`. `test/graphql`, `test/repository` and `test/tool` green.

## IN-04: bare enemy name beside unnamed entries

**RED observed (`0aa9233`):** `[Goblin x1, <unnamed> x2]` → `Expected: ['1x Goblin']  Actual: ['Goblin']`.

**Fix (`7376547`):** `enemyLinesOf` computes `total = enemies.fold<int>(0, (sum, entry) => sum + entry.quantity)` over all entries and returns the bare name only when `names.length == 1 && total == 1`; nameless entries still get no line.

## IN-05: asymmetric `toJson` / `EnemyRoster`

**RED observed (`c2491a4`):** `FormatException: QuestEnemy.enemy missing` on `QuestInfos.fromJson(infos.toJson())`.

**Fix (`fe62932`):** `QuestInfos.toJson` emits `enemies.map((e) => e.toJson()).toList()`. No caller serialises a quest today.

**Not needed (`EnemyRoster` extraction):** the two sheets already read the same pure helpers (`enemyLinesOf`, `strongestEnemyOf`, `EnemyPortrait.canShow`) and differ only in layout; a shared view model is introduced when Phase 16 (ambush outcomes) adds the third consumer. No code changed for it.

## Notes for the device UAT

- **Boss sheet with coins + prize item + companion (WR-01):** the prize card stays square at the full row height; the coins column is narrower (35% of the row instead of 50%) and the «Compagno in premio: <nome>» line takes the rest, up to 3 lines with ellipsis. Prize rows without an item or without a companion look as before.
- **Enemy lines (IN-04):** a quest whose enemies include an entry without a name now shows «1x <nome>» for the named enemy instead of the bare name. Only reachable with a DB enemy missing its name.
- **Accessibility (IN-01):** with TalkBack on, «Ritratto del nemico» is announced for a raster portrait only once the picture is shown, not while it loads or after it fails. No visual change.
- IN-02, IN-03 and IN-05 have no user-visible effect.

---

_Fixed: 2026-11-04T19:32:18Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
