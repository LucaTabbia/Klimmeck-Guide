---
phase: 13-city-shops
plan: 06
subsystem: shop
tags: [models, shop, pet, companion, widget, tdd]
requires: [13-01]
provides:
  - TradeSelection value object (assets + pets)
  - purchasablePets / buildTransactionRequest
  - companionSpeedLabel / companionEquippedMark
  - shared text-only CompanionRow
affects: [13-07, 13-09]
tech-stack:
  added: []
  patterns:
    - "pets travel beside the asset lists in a pure value object (Pet is not an AssetItem)"
    - "speed line prints the served speedModifier as is, Italian decimal comma"
key-files:
  created:
    - lib/models/shop/trade_selection.dart
    - lib/shared/components/companion_row.dart
    - test/models/shop/trade_selection_test.dart
    - test/shared/components/companion_row_test.dart
  modified:
    - lib/utils/item_lines.dart
    - test/utils/item_lines_test.dart
decisions:
  - "companionEquippedMark = 'Al tuo fianco' lives in lib/utils/item_lines.dart with the other row copy (D-19 Phase 8)"
  - "CompanionRow is a GestureDetector (HitTestBehavior.opaque) > Container(color, padding) > Row; the selected highlight is primaryGold.withAlpha(100) like equipment_box.dart"
metrics:
  duration: ~20min
  completed: 2026-11-02
  tasks: 2
  files: 6
---

# Phase 13 Plan 06: Trade selection, speed label and companion row Summary

Flutter-free `TradeSelection { assets, pets }` owning totals, the `equipAssets`/`lootAssets`/`petAssets` split (pets always quantity 1), pool pruning and `purchasablePets`, plus `companionSpeedLabel` («Velocità ×2», «Velocità ×2,5») and the shared text-only `CompanionRow` for the shop sheets (13-07) and the Journal slot (13-09).

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | TradeSelection value object and purchasablePets | e1b0622 | c3ff8d9 |
| 2 | companionSpeedLabel and the shared text-only CompanionRow | b241d8f | 76ae265 |

## RED failures observed

- Task 1: compile failure, `Error: Couldn't find constructor 'TradeSelection'` (file `lib/models/shop/trade_selection.dart` absent).
- Task 2: `test/utils/item_lines_test.dart:62:16: Error: Method not found: 'companionSpeedLabel'`; `Error when reading 'lib/shared/components/companion_row.dart': No such file or directory`.

## Created API (exact)

- `lib/models/shop/trade_selection.dart`:
  - `class TradeSelection extends Equatable { const TradeSelection({this.assets = const [], this.pets = const []}); final List<AssetQuantity> assets; final List<Pet> pets; bool get isEmpty; bool containsPet(String petId); Coins total({required bool isBuy}); TradeSelection withAssets(List<AssetQuantity> assets); TradeSelection addPet(Pet pet) /* idempotent by id */; TradeSelection removePet(String petId); TradeSelection retainPurchasable(CityShop pool); TransactionItems toTransactionItems(); props [assets, pets] }`
  - `List<Pet> purchasablePets(List<Pet> pool, List<Pet> owned)` (pool order, only owned ids removed)
  - `TransactionRequest buildTransactionRequest({required String characterId, required TradeSelection bought, required TradeSelection sold, required Coins total, required bool isTotalPositive})`
- `lib/utils/item_lines.dart`: `const String companionEquippedMark = 'Al tuo fianco';`, `String? companionSpeedLabel(Pet pet)`.
- `lib/shared/components/companion_row.dart`: `const CompanionRow({super.key, required Pet pet, required double size, bool isBuy = true, bool showCoins = true, bool isEquipped = false, bool isSelected = false, VoidCallback? onTap})`; keys `ValueKey('companion-speed-${pet.id}')`, `ValueKey('companion-equipped-${pet.id}')`.

## Tests

- `test/models/shop/trade_selection_test.dart`: 15 tests green.
- `test/utils/item_lines_test.dart`: 8 tests (5 existing + 3 new) green.
- `test/shared/components/companion_row_test.dart`: 7 tests green.
- Plan verification `flutter test test/models/shop test/utils test/shared/components`: 268 green.
- Analyzer: 51 issues (info only), 0 error, 0 warning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Row test size raised to 120**
- **Found during:** Task 2 GREEN
- **Issue:** with `size: 40` (then 80) the column `CoinsDisplay` (three coin lines) overflowed vertically in the test font (RenderFlex overflow 29/12 px), failing the price tests.
- **Fix:** the test pumps `CompanionRow` with `_rowSize = 120`, the size the shop sheets give their rows on the 800 px test surface (`(width - 200) / 5`). Production code unchanged. The test-file change is in the GREEN commit 76ae265.
- **Files modified:** test/shared/components/companion_row_test.dart

`Coins.operator +` already normalises (`.normalize()`), so the totals sum with `+` directly as planned.

## Known Stubs

None. `CompanionRow` is not wired into a screen yet by design (13-07 shop sheets, 13-09 Journal slot).

## Self-Check: PASSED

- Files: lib/models/shop/trade_selection.dart, lib/shared/components/companion_row.dart, test/models/shop/trade_selection_test.dart, test/shared/components/companion_row_test.dart exist.
- Commits e1b0622, c3ff8d9, b241d8f, 76ae265 present on `feat/13-city-shops`.
