---
phase: 13-city-shops
reviewed: 2026-11-02T18:00:00Z
depth: standard
files_reviewed: 38
files_reviewed_list:
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/fragments/pet_fragment.dart
  - lib/graphql/mutations/character_mutations.dart
  - lib/graphql/queries/city_queries.dart
  - lib/graphql/queries/equipment_item_queries.dart
  - lib/graphql/queries/loot_item_queries.dart
  - lib/graphql/queries/shop_queries.dart
  - lib/models/character/character_assets.dart
  - lib/models/city.dart
  - lib/models/city_shop.dart
  - lib/models/pet.dart
  - lib/models/request/equip_pet_request.dart
  - lib/models/request/transaction_request.dart
  - lib/models/shop/trade_selection.dart
  - lib/repository/companion_repository.dart
  - lib/repository/pet_equip_failure.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/transaction_failure.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/components/companion_outcome_listener.dart
  - lib/screens/mainScreen/components/satchel_availability.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart
  - lib/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart
  - lib/screens/mainScreen/tabs/journal/companionCubit/companion_state.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
  - lib/screens/mainScreen/tabs/shop/components/shop_modal.dart
  - lib/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart
  - lib/screens/mainScreen/tabs/shop/components/transaction_modal.dart
  - lib/screens/mainScreen/tabs/shop/shop.dart
  - lib/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart
  - lib/screens/mainScreen/tabs/shop/shopCubit/shop_state.dart
  - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart
  - lib/shared/components/companion_row.dart
  - lib/utils/item_lines.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 2
  info: 4
  total: 6
status: issues_found
---

# Phase 13: Code Review Report

**Reviewed:** 2026-11-02
**Depth:** standard
**Files Reviewed:** 38
**Status:** issues_found

## Summary

The phase is clean on the contract and on the product rules. Documents select only the agreed fields (`PetFragment`, `cityShop`, `equipPet`/`unequipPet`, `size`/`hasShop`, `ownedPets`), the registry holds 43 documents, the two global catalogue queries are gone with no leftover consumer, classifiers read `extensions.code` only, titles are «Compagni»/«Compagno», only `SHOP_NOT_IN_CITY` is a banner, `ITEM_NOT_IN_SHOP`/`PET_ALREADY_OWNED`/`PET_NOT_OWNED` go to the shopkeeper bubble, buying never equips, and nothing filters by rarity/size/price/sellable. `ShopCubit` is last-request-wins, `CompanionCubit` (token, FIFO, settle timer, `close`) and `CompanionOutcomeListener` (dedup key, silent refresh on stale views) hold up, D-14 (`isPositive ||`) is correct, and there are no `print`s or raw server messages. `flutter analyze` on the touched trees shows only the 5 baseline infos.

No critical findings. Two warnings concern the shop sheet (a buy sheet that stays empty and cannot be recovered; a stale pet that stays in the purchase selection). The rest is quality.

## Critical

None.

## Warning

### WR-01: Buy sheet opened during loading or after a failed load stays empty, and there is no way to retry

**File:** `lib/screens/mainScreen/tabs/shop/shop.dart:125-151,341-349` (with `shop_cubit.dart:18-29`, `shop_pool_loader.dart:35-39`)
**Issue:** `_showModalShop` receives `equipments/items/pets` as plain lists computed at tap time from `_poolOf(state, character)`. While the pool is loading (the `ShopLoading` emitted by `getData` on mount, on a city change and after `ITEM_NOT_IN_SHOP`), or after a `ShopError`, `_poolOf` returns null, so the sheet opens with three empty lists. The sheet is built from the captured snapshot, so it does not update when the load completes. After `ShopError` nothing reloads: the loader fires only on mount, on a city change and on `itemNotInShop`, so a transient network failure leaves an empty «Acquisto» sheet until the user leaves and re-enters the page, with no message at all (the cubit comment says «la pagina resta usabile» but only selling works).
**Why it matters:** The user taps the shop (an explicit action, so a wait is allowed by rule 2) and sees an empty store that looks like the real pool. After the `ITEM_NOT_IN_SHOP` refusal, the reload that should remove the stale row can be raced the same way if the user reopens the sheet at once.
**Suggested fix:** Make the buy sheet read the pool live: wrap `ShopModal`'s inputs in a `BlocBuilder<ShopCubit, ShopState>` using the cubit captured before `showModalBottomSheet` (the sheet lives above the shell providers, as `CompanionSection._openOwned` already notes), recompute `_poolOf`/`purchasablePets` inside it, and call `getData(cityId)` again when the buy cell is tapped in `ShopError`. RED tests first in `test/screens/mainScreen/tabs/shop/`: (1) `getCityShop` stubbed with a delayed `Completer`, open the buy sheet, complete it, expect the rows to appear without reopening; (2) `getCityShop` fails once then succeeds, tap buy twice, expect the second tap to retry and show the rows.

### WR-02: A pet already owned (or already sold) stays in the selection and every retry is refused

**File:** `lib/models/shop/trade_selection.dart:40-53`, `lib/screens/mainScreen/tabs/shop/shop.dart:292-298`
**Issue:** `retainPurchasable(pool)` prunes only against the new pool. It does not drop pets the character now owns, which `purchasablePets` hides from the list (D-08). Scenario: the user signs a pet purchase, the response is lost or times out (`TransactionError`, selection kept by design), `characterUpdated` then delivers the pet in `ownedPets`. The buy list no longer shows it, but `_toBuy.pets` still holds it, the transaction sheet still lists it, and each new signature returns `PET_ALREADY_OWNED` («Hai già questo compagno») until the user finds the eraser. The sell side has the mirror case: `_toSell.pets` is never reconciled with `ownedPets`, so a pet that left the inventory gives `PET_NOT_OWNED` forever.
**Why it matters:** A reachable dead end after a network blip. The BE refuses safely, but the FE keeps proposing the same refused request.
**Suggested fix:** Make the reconciliation total: `TradeSelection.retainPurchasable(pool, {required List<Pet> owned})` drops pets whose id is in `owned`, and a symmetric `retainOwned(List<Pet> owned)` for the sell side. Apply both in `_ShopState` when `ownedPets` changes (a `BlocListener<CharacterCubit>` with `listenWhen` on `ownedPets`), not only on `ShopLoadData`. RED tests in `test/models/shop/trade_selection_test.dart`: a buy selection containing pet `p1` pruned against a pool that still lists `p1` with `owned: [p1]` returns no pets; a sell selection with `p1` pruned against `owned: []` returns no pets.

## Info

### IN-01: `isOnCityMarker` is now dead code in `lib`

**File:** `lib/models/quest/board_policy.dart:18` (left by `lib/screens/mainScreen/components/satchel_availability.dart:23-27`)
**Issue:** `disabledSatchelPages` switched to `currentCityOf`, so `isOnCityMarker` has no production caller; only `test/models/quest/board_policy_test.dart` references it.
**Fix:** Remove it and its test group in the next touch of that file (Boy Scout), or keep it deliberately and say so.

### IN-02: `CharacterAssets.toJson` is not the inverse of `fromJson` for the pets

**File:** `lib/models/character/character_assets.dart:61-62`
**Issue:** `toJson` writes `"pet": pet?.id` and `"ownedPets": [ids]`, while `fromJson` casts each element to a `Map` (`Pet.fromJson`). A round trip throws a cast error. Nothing calls `Character.toJson` today (verified by grep), and the `pet` half predates the phase, but `ownedPets` extends the inconsistency.
**Fix:** Serialize with `pet?.toJson()` and `ownedPets.map((p) => p.toJson())`. RED test in `test/models/character/`: `CharacterAssets.fromJson(assets.toJson()) == assets` with a pet and one owned pet.

### IN-03: Error-code constants are shared across failure files by importing a sibling classifier

**File:** `lib/repository/pet_equip_failure.dart:5-8`
**Issue:** `pet_equip_failure.dart` imports `badUserInputCode` from `spell_equip_failure.dart` and `petNotOwnedCode` from `transaction_failure.dart` just to reach two string constants, creating a coupling between three independent classifiers.
**Fix:** Move the shared codes (`BAD_USER_INPUT`, `PET_NOT_OWNED`) next to `graphQlErrorCode` in `graphql_error_code.dart` and import from there. Behaviour unchanged; the existing classifier tests cover it.

### IN-04: Tapping a pet in the «Compagno» list while an operation is pending closes the sheet with no feedback

**File:** `lib/screens/mainScreen/tabs/journal/sections/companion_section.dart:99-103,115-120`
**Issue:** `toggle` returns `ignoredPending` while a request is in flight (a few seconds at most, up to 15 on a slow link). `onTap` pops the sheet regardless, so the user's tap vanishes silently: no haptic, and the sheet is gone.
**Fix:** Pop the sheet only when the intent is not `ignoredPending`, or disable the rows (`onTap: null`) while `companion.pending != null`. RED widget test in `companion_section_test.dart`: with a pending equip, tapping another pet leaves the sheet open and sends no second mutation.

---

_Reviewed: 2026-11-02_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
