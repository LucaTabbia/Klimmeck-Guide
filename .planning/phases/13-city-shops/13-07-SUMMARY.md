---
phase: 13-city-shops
plan: 07
subsystem: shop
tags: [shop, pet, companion, widget, tdd, bugfix]
requires: [13-05, 13-06]
provides:
  - net-positive transactions always signable (D-14)
  - TransactionModal on TradeSelection (companions in Acquisto/Vendita and in the total)
  - «Compagni» dropdown in ShopModal (buy pool minus owned, sell owned with equipped mark)
  - Shop wired through TradeSelection, purchasablePets, retainPurchasable, buildTransactionRequest
affects: [13-08, 13-09, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "both shop sides hold a TradeSelection; the request is the pure buildTransactionRequest"
    - "dropdown height split across the open menus net of the closed headers"
key-files:
  created:
    - test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart
  modified:
    - lib/screens/mainScreen/tabs/shop/components/transaction_modal.dart
    - lib/screens/mainScreen/tabs/shop/components/shop_modal.dart
    - lib/screens/mainScreen/tabs/shop/shop.dart
    - test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart
decisions:
  - "canAfford = isPositive || wallet.canAfford(total): the FE gate is UX only, the BE checks funds (T-13-21)"
  - "ShopModal._dropdownHeight reserves 180 + 43 x max(1, closedHeaders) and divides by max(1, openCount): identical to the old values with two menus, no overflow with three"
  - "the pencil does nothing on a companion row in the transaction sheet (a pet is always quantity 1); the rubber removes it"
metrics:
  duration: ~35min
  completed: 2026-11-02
  tasks: 2
  files: 5
---

# Phase 13 Plan 07: Companions in the shop sheets and the D-14 fix Summary

Net-positive transactions are signable whatever the wallet holds (regression test first); `TransactionModal` and `ShopModal` work on `TradeSelection`, list companions («Compagni» dropdown in the shop sheet, companion rows under «Acquisto»/«Vendita»), count them in the total; `Shop` hides owned pets from the buy list, marks the equipped one on the sell side, prunes the buy selection on a new matching pool and sends `buildTransactionRequest(...)`.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | TransactionModal: D-14 fix, companions in Acquisto/Vendita and in the total | a16aa0a (test), 07d172a (fix), ce47db0 (test), 3074031 (feat) |
| 2 | ShopModal «Compagni» dropdown and Shop wiring through TradeSelection | 7e61561 (test), e799a4e (feat) |

## RED failures observed

- Task 1 cycle A: `a net-positive sale is signable with a wallet below the gain (D-14)` failed at `expect(_redCross, findsNothing)` (the red cross was painted: 10 ag wallet vs +50 ag sale). The red-cross test for a purchase above the wallet passed at RED by design (it pins the existing behaviour that must survive the fix).
- Task 1 cycle B: compile failure `Error: No named parameter with the name 'toBuy'`.
- Task 2: compile failure `Error: No named parameter with the name 'pets'` (shop_modal_test.dart:103).

## Created / changed API (exact)

- `TransactionModal({super.key, required TradeSelection toBuy, required TradeSelection toSell, required void Function(Coins total, bool isTotalPositive) onConfirm, required void Function(TradeSelection selection, bool isBuy) onChanged, required Character character, bool? isAdd, required void Function(EquipmentItem) onEquipmentInfo})`. Companion row keys `ValueKey('trade-pet-${pet.id}')`. Totals computed in `build` via `TradeSelection.total`; `utils.dart` import (getTotalAmount) dropped.
- `ShopModal({super.key, required List<AssetQuantity> equipments, required List<AssetQuantity> items, List<Pet> pets = const [], required TradeSelection selection, required void Function(TradeSelection) onSelect, required bool isBuy, required bool? isAdd, required Function(EquipmentItem) onEquipmentInfo, String? equippedPetId})`. Dropdown `ValueKey('companions_dropdown')` «Compagni» only when `pets.isNotEmpty`; rows `CompanionRow(key: ValueKey('shop-pet-${pet.id}'), isEquipped: pet.id == equippedPetId, isSelected: selection.containsPet(pet.id))`; pencil `addPet`, rubber `removePet`, `isAdd == null` no callback.
- `Shop` (`_ShopState`): `TradeSelection _toBuy`, `_toSell`; `_onSelect(TradeSelection, bool isBuy)`; `_onConfirm` → `doTransaction(buildTransactionRequest(...))`; `_showModalShop({required equipments, required items, required List<Pet> pets, required bool isBuy, String? equippedPetId})`; buy pets = `purchasablePets(pool?.pets ?? const [], character.assets?.ownedPets ?? const [])`; sell = `ownedEquipments`/`ownedItems`/`ownedPets` with `equippedPetId: character.assets?.pet?.id`; `BlocListener<ShopCubit, ShopState>(listenWhen: current is ShopLoadData)` → `_pruneBuySelection(state)` (reads CharacterCubit, `_poolOf`, `retainPurchasable`). Page split into `_buildPage()` (listeners) and `_buildShop()` (builders).

## Tests

- `test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart`: 7 tests (2 D-14 + 5 D-07, incl. «the pencil leaves a companion selected once (D-07)»).
- `test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart`: 9 tests (3 existing Phase 8 + 6 new).
- Plan verification `flutter test test/screens/mainScreen/tabs/shop test/models/shop test/shared/components/companion_row_test.dart`: 69 green.
- `flutter test test/screens/mainScreen`: 855 green.
- Analyzer: 50 issues (info only), 0 error, 0 warning.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prescribed `_dropdownHeight` overflowed with three menus**
- **Found during:** Task 2 GREEN
- **Issue:** `(maxHeight - (180 + 43)) / openCount` reserves only one header; with the «Compagni» dropdown present and one menu open the two closed headers push the column 43 px past the sheet (RenderFlex overflow in 3 tests, also on the real 780 px sheet).
- **Fix:** `reserved = 180 + 43 * max(1, closedCount)`, divided by `max(1, openCount)`; identical values to the old code with two menus. Grep `_dropdownHeight` = 4 still holds.
- **Files modified:** lib/screens/mainScreen/tabs/shop/components/shop_modal.dart (commit e799a4e)

**2. [Rule 3 - Blocking] Test harness adjustments**
- Transaction sheet tests pump the modal in `SingleChildScrollView > SizedBox(height: 780)` (the geometry `PaperSheetModal` gives it) because the column does not fit 360 px.
- shop_modal_test gained a `tapPet` helper (taps the top of the row after `ensureVisible`): on the 360 px landscape surface a companion row (size 116 + padding) is taller than the open dropdown viewport, so `tap` on its centre missed. Added in the GREEN commit e799a4e.

**3. Acceptance grep note:** `grep -c "TransactionRequest(" shop.dart` prints 1, not 0, because it matches the substring of `buildTransactionRequest(`; there is no direct `TransactionRequest(` construction and the `request/transaction_request.dart` import is gone (grep = 0).

**4. Extra test** «the pencil leaves a companion selected once (D-07)» in transaction_modal_test pins the pencil no-op on pets.

## Threat mitigations

- T-13-21: net-negative above the wallet still red-crossed (test). T-13-22: `retainPurchasable` on every new matching pool. T-13-23: `canAfford && !_showSignature` guard kept. T-13-24: grep `sellable|CompanionCubit|equipPet` in shop.dart = 0.

## Known Stubs

None.

## Self-Check: PASSED

- Files: transaction_modal_test.dart created; transaction_modal.dart, shop_modal.dart, shop.dart, shop_modal_test.dart modified.
- Commits a16aa0a, 07d172a, ce47db0, 3074031, 7e61561, e799a4e present on `feat/13-city-shops`.
