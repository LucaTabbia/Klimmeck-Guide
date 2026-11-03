---
phase: 13-city-shops
fixed: 2026-11-02T22:12:41Z
source: 13-REVIEW.md
review_path: .planning/phases/13-city-shops/13-REVIEW.md
iteration: 1
fix_scope: all
findings_total: 6
findings_in_scope: 6
fixed_count: 4
skipped_count: 0
not_needed_count: 2
status: all_fixed
---

# Phase 13: Code Review Fix Report

**Fixed at:** 2026-11-02T22:12:41Z
**Source review:** `.planning/phases/13-city-shops/13-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/13-city-shops` (no push). Start `0d56d1e`, final code HEAD `5137fbd`.

**Summary:**
- Findings in the review: 6 (0 critical, 2 warnings, 4 info)
- Findings in scope: 6 (the orchestrator ruled on every item before the fixer ran)
- Fixed: 4 (WR-01, WR-02, IN-01, IN-04)
- Not needed: 2 (IN-02, IN-03), recorded with the orchestrator's reason, no code change
- Skipped: 0

Every behaviour fix went Red → Green: a failing-test commit (`test(shop|companion): …`), then the fix commit (`fix(shop|companion): …`). IN-01 is a dead-code removal (`refactor(models): …`). Commits use plain `git` with explicit paths, carry no trailers and rewrite no history.

These decisions still hold:
- Rule 2: the only new wait is the pool reload on an explicit tap of the buy cell after a `ShopError`; nothing new loads in the background.
- The backend stays the source of truth: the selections are only reconciled with `ownedPets` and the pool served by the BE; no new filter by rarity, size, price or `sellable`.
- `TradeSelection` stays Flutter-free; no GraphQL document changed (`git diff 0d56d1e..HEAD -- lib/graphql` is empty).

## Gate finale

| Check | Result |
|-------|--------|
| `flutter analyze` (repo-wide) | **50 issues, all info, 0 errors / 0 warnings**: unchanged baseline |
| `flutter test test/models test/repository test/graphql test/tool` (foreground) | **1383 passed, 0 failed** |
| `flutter test test/screens/mainScreen` (foreground) | **895 passed, 0 failed** |
| `flutter test test/screens/auth test/shared test/utils` (foreground) | **416 passed, 0 failed** |
| `dart format --output=none --set-exit-if-changed` on every touched file | clean; each file was formatted on its own (none of the known dirty files was touched) |
| Trailers on `0d56d1e..HEAD` (`co-authored-by` / `generated with`) | 0 |
| `git status --short` | empty after the report commit |

## Per-finding table

| ID | Severity | Outcome | Commits (test → fix) | Tests added |
|----|----------|---------|----------------------|-------------|
| WR-01 | Warning | fixed | `71d2b30` → `15fcc34` | `shop_test.dart` «a buy sheet opened while the pool loads fills in when it arrives (D-03)», «tapping the buy cell after a failed load retries the pool (rule 2)» |
| WR-02 | Warning | fixed: requires human verification | `e17cda9` → `cd15d78` | `trade_selection_test.dart` 4 tests (WR-02); `shop_test.dart` «a pet bought meanwhile leaves the purchase selection (D-08)», «a pet that left the inventory leaves the sale selection (D-07)» |
| IN-01 | Info | fixed (refactor) | — → `57d37c8` | none: two assertions removed with the function |
| IN-02 | Info | not_needed | — | — |
| IN-03 | Info | not_needed | — | — |
| IN-04 | Info | fixed | `a7c5e6e` → `5137fbd` | `companion_section_test.dart` «a tap while an operation is pending keeps the sheet open, no haptic (IN-04)» |

## WR-01: Buy sheet opened during loading or after a failed load stays empty

**Ruling:** FIX. The buy sheet reads the pool live through the cubits captured before `showModalBottomSheet`; a tap on the buy cell after `ShopError` of the current city calls `getData(cityId)` before opening the sheet. Sell side unchanged.

**RED observed (`71d2b30`):** new `test/screens/mainScreen/tabs/shop/shop_test.dart` (real `ShopCubit` over `MockKlimmeckGraphQl`, the full `Shop(cities:)` page). (1) `getCityShop` held by a `Completer`, sheet opened during `ShopLoading`, completer completed: `Found 0 widgets with text "Equipaggiamento e-sword"`. (2) First `getCityShop` throws (`ShopError('city-1')`), tap on the buy cell: `Expected: <2> Actual: <1>` calls.

**Fix (`15fcc34`):** `lib/screens/mainScreen/tabs/shop/shop.dart`:
- `_openBuySheet(character)` captures `ShopCubit` and `CharacterCubit`, calls `_retryFailedPool` (only `ShopError` whose `cityId` is the marker city), then opens the sheet with `BlocBuilder<ShopCubit>` → `BlocBuilder<CharacterCubit>` → `ShopModal(_buyStock(state, characterState))`. Empty lists while loading or on error, filled when `ShopLoadData` of the current city arrives.
- `_openSellSheet(character)` passes the snapshot `_sellStock(character)` as before.
- `_showModalShop({required bool isBuy, required stockOf})` builds the `ShopModal` from a private `_SheetStock` (equipments, items, pets, equippedPetId). `ShopModal` keeps its `_selection` from `initState`: only the lists change, the widget is not recreated.
- The page's outer `BlocBuilder<ShopCubit>` is gone (Boy Scout): nothing on the page reads the pool any more, only the buy sheet and the `ShopLoadData` prune listener do. Removing it re-indented `_buildShop` (formatter), hence the large diff.
- `_cityIdOf(character)` is shared by `_poolOf` and the retry.

**Test harness notes:**
- New `test/helpers/fakes/svg_http_overrides.dart` (`useSvgHttpOverrides()`): `EditPencilRubber` uses `SvgPicture.network`, and the test binding's 400 empty body threw `Bad state: Invalid SVG data`. The fake answers every request with a 1x1 SVG and is restored in `addTearDown`. It is the first test that pumps the full `Shop` page with its sheets.
- The shop cells use full Cloudinary URLs, so the test seeds `SvgCache` with those URLs directly (`_seedShopCells`). The GREEN commit also seeds `CloudinaryAssets.weaponType`: once the sword row appeared, its unseeded type icon kept a spinner going and `pumpAndSettle` timed out.

**Files:** `lib/screens/mainScreen/tabs/shop/shop.dart`, `test/screens/mainScreen/tabs/shop/shop_test.dart` (new), `test/helpers/fakes/svg_http_overrides.dart` (new).

## WR-02: A pet already owned (or already sold) stays in the selection

**Ruling:** FIX. `retainPurchasable(pool, {required owned})` also drops the owned pets; `retainOwned(owned)` for the sell side; `_ShopState` prunes both selections when the owned pet ids change (`CharacterLoaded` → `CharacterLoaded`).

**RED observed (`e17cda9`):**
- `test/models/shop/trade_selection_test.dart`: compile failure `No named parameter with the name 'owned'` and `The method 'retainOwned' isn't defined for the type 'TradeSelection'`. The two existing `retainPurchasable(_poolWithSwordOnly)` calls became `…, owned: const []` in the same RED commit.
- `shop_test.dart`: with the horse in the buy selection (set through `ShopModal.onSelect`), a character update adding it to `ownedPets` leaves the complete cell on screen (`Expected: no matching candidates, Found 1`); the same for a sell selection after a character update that removes the horse.

**Fix (`cd15d78`):**
- `lib/models/shop/trade_selection.dart`: `retainPurchasable(CityShop pool, {required List<Pet> owned})` filters by the pool, then `withoutOwned(owned)`; `TradeSelection withoutOwned(List<Pet> owned)` (buy side when no pool of the current city is loaded); `TradeSelection retainOwned(List<Pet> owned)` (sell side). Assets are never touched by the two owned filters. No Flutter import.
- `lib/screens/mainScreen/tabs/shop/shop.dart`: the page listeners become a `MultiBlocListener`; `_pruneBuySelection` passes `owned:`; new `BlocListener<CharacterCubit, CharacterState>(listenWhen: _ownedPetsChanged)` → `_pruneOnOwnedPets(character)`, which sets `_toBuy` (against the pool when available, always against owned) and `_toSell = _toSell.retainOwned(owned)`. `_ownedPetsChanged` compares the id sets with `setEquals` (new `package:flutter/foundation.dart` import). `_ownedPetsOf(character)` replaces the three `character.assets?.ownedPets ?? const []`.
- `withoutOwned` got its own model test in the GREEN commit («withoutOwned drops an owned pet and keeps the assets (WR-02)»): the no-pool branch needed the helper, so the test was green at its first run.

**Why "requires human verification":** state reconciliation logic. The device UAT should check the lost-response path: a purchase whose answer times out, then `characterUpdated` delivering the pet, must clear it from the transaction sheet without a «Hai già questo compagno».

**Files:** `lib/models/shop/trade_selection.dart`, `lib/screens/mainScreen/tabs/shop/shop.dart`, `test/models/shop/trade_selection_test.dart`, `test/screens/mainScreen/tabs/shop/shop_test.dart`.

## IN-01: `isOnCityMarker` is now dead code in `lib`

**Ruling:** FIX (Boy Scout). Remove it and its two assertions, rename the test group to `currentCityOf`.

**RED:** none (dead-code removal; the remaining `currentCityOf` tests still cover the behaviour).

**Fix (`57d37c8`):** `isOnCityMarker` removed from `lib/models/quest/board_policy.dart`; `test/models/quest/board_policy_test.dart` loses the two assertions and the group is `currentCityOf`. `grep -rn isOnCityMarker lib test` is empty; the `city.dart` / `point_of_interest.dart` imports are still used by `currentCityOf`, so the analyzer stays clean.

**Files:** `lib/models/quest/board_policy.dart`, `test/models/quest/board_policy_test.dart`.

## IN-02: `CharacterAssets.toJson` is not the inverse of `fromJson` for the pets

**Ruling:** NOT_NEEDED. `CharacterAssets.toJson` writes `pet?.id` (pre-existing) and the `ownedPets` ids in the same style; the asymmetry with `fromJson` is the repo's existing convention for request payloads and nothing round-trips it. No code change.

## IN-03: Error-code constants shared by importing a sibling classifier

**Ruling:** NOT_NEEDED. The repo convention keeps each error-code constant in its classifier file (`character_creation_failure`, `travel_failure`, `quest_acceptance_failure`…); there is no shared `graphql_error_code.dart`. Importing `badUserInputCode` / `petNotOwnedCode` from the sibling classifiers follows that convention. No code change.

## IN-04: A tap in the «Compagno» list while an operation is pending closes the sheet with no feedback

**Ruling:** FIX. When `toggle` returns `CompanionToggleIntent.ignoredPending`, do not pop the sheet and do not fire the haptic; keep pop + haptic for equip/unequip.

**RED observed (`a7c5e6e`):** `companion_section_test.dart` «a tap while an operation is pending keeps the sheet open, no haptic (IN-04)» (mock `toggle` → `ignoredPending`, `recordHaptics`): `Found 0 widgets with type "PaperSheetModal"`. The no-haptic part already held before the fix (13-09 skipped the haptic on `ignoredPending`); the test pins it.

**Fix (`5137fbd`):** `lib/screens/mainScreen/tabs/journal/sections/companion_section.dart`: `_toggleWithFeedback` becomes `_toggle(cubit, character, pet, sheetContext)`, which returns early on `ignoredPending` and otherwise fires `HapticFeedback.lightImpact()` and pops the sheet. The existing equip/unequip tests (sheet closed after the tap) stay green.

**Files:** `lib/screens/mainScreen/tabs/journal/sections/companion_section.dart`, `test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart`.

## Notes for the device UAT (13-11)

- After a failed pool load (for example the tunnel dropped while the page mounted), tapping «Acquisto» reloads the pool. The sheet opens at once, starts empty, and fills in when the answer arrives. The same holds for a sheet opened during the first load.
- A pet bought or sold while the selection still held it (lost response, a second device) leaves the selection on the next `characterUpdated`. The complete-transaction cell disappears when nothing is left.
- In the Journal «Compagno» sheet, a tap during a pending equip/unequip does nothing visible (no haptic, the sheet stays open); tap again after the outcome.

---

_Fixed: 2026-11-02T22:12:41Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
