---
phase: 13-city-shops
plan: 05
subsystem: shop
tags: [shop, cubit, graphql, pool, tdd]
requires: [13-01, 13-02, 13-03]
provides:
  - ShopCubit.getData(cityId) with last-request-wins
  - ShopLoading(cityId) / ShopLoadData(pool) / ShopError(cityId)
  - ShopPoolLoader (mount / city change / ITEM_NOT_IN_SHOP)
  - Shop(cities:) reading only the marker city pool
  - MockShopCubit
affects: [13-07, 13-08, 13-09, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "shell-scoped cubit + page-side cityId match (_poolOf) instead of resetting the cubit"
    - "non-visual loader widget with MultiBlocListener and listenWhen on derived city ids"
key-files:
  created:
    - lib/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart
    - test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart
    - test/screens/mainScreen/tabs/shop/components/shop_pool_loader_test.dart
  modified:
    - lib/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart
    - lib/screens/mainScreen/tabs/shop/shopCubit/shop_state.dart
    - lib/screens/mainScreen/tabs/shop/shop.dart
    - lib/screens/mainScreen/main_screen.dart
    - lib/graphql/queries/equipment_item_queries.dart
    - lib/graphql/queries/loot_item_queries.dart
    - lib/repository/services/graphql/graphql.dart
    - tool/schema_check/schema_check_documents.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/helpers/mocks.dart
decisions:
  - "ShopPoolLoader wraps the whole Shop tree (outside the TransactionCubit BlocListener), so it mounts and unmounts with the page"
  - "The stale-row predicate is a private helper _isStaleRowRefusal (one itemNotInShop reference)"
  - "The registry doc comment names the removed documents only generically, so `grep -rn AssetsQuantity lib tool` is empty"
metrics:
  duration: ~25min
  completed: 2026-11-02
  tasks: 3
  files: 14
---

# Phase 13 Plan 05: Shop on the per-city pool Summary

The shop now loads `cityShop(cityId)` of the marker city through `ShopCubit.getData(cityId)` (last request wins, no `print`, no raw text); a non-visual `ShopPoolLoader` triggers the load on mount, on a city change and after `ITEM_NOT_IN_SHOP`; `Shop(cities:)` shows only the pool whose `cityId` matches the current city and speaks every refusal through `shopkeeperRefusalLine`; the two global catalogue documents, service methods and registry entries are gone (43 documents).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | ShopCubit.getData(cityId) last-request-wins | bf031ba (RED), 7fe4c15 (GREEN) |
| 2 | ShopPoolLoader | 29e0d48 (RED), 8d2b337 (GREEN) |
| 3 | Shop(cities:), bubble lines, catalogue removed | e7417d0 (RED), 7eff79c (GREEN) |

## Created names and signatures

- `lib/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart`: `ShopCubit(this.graphQl) : super(const ShopInitial())`, `String? _requestedCityId`, `Future<void> getData(String cityId)`; no `package:flutter/` import.
- `shop_state.dart` (part): `abstract class ShopState extends Equatable` (no `@immutable`); `const ShopInitial()`; `const ShopLoading(String cityId)`; `const ShopLoadData(CityShop pool)` with `String get cityId => pool.cityId`, props `[pool]`; `const ShopError(String cityId)` (no message field).
- `lib/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart`: `const ShopPoolLoader({super.key, required List<City> cities, required Widget child})`; reads `CharacterCubit`, `ShopCubit`, `TransactionCubit` from context.
- `lib/screens/mainScreen/tabs/shop/shop.dart`: `const Shop({super.key, required List<City> cities})`; `CityShop? _poolOf(ShopState state, Character character)`; `Widget _buildPage()`; `build` returns `ShopPoolLoader(cities: widget.cities, child: _buildPage())`; `_showRefusal` uses `shopkeeperRefusalLine`.
- `lib/screens/mainScreen/main_screen.dart`: `Shop(cities: cities)`.
- `test/helpers/mocks.dart`: `class MockShopCubit extends MockCubit<ShopState> implements ShopCubit {}` after `MockTransactionCubit`.
- Removed: `EquipmentItemQueries.getAllEquipmentAssetsQuantity`, `LootItemQueries.getAllLootAssetsQuantity`, `KlimmeckGraphQl.getAllEquipmentAssetsQuantity`, `KlimmeckGraphQl.getAllLootAssetsQuantity`, the `asset_quantity.dart` import of `graphql.dart`, registry entries `equipmentAssetsQuantity` / `lootAssetsQuantity`.

## RED failures observed

- Task 1: compile failures — `Too many positional arguments: 0 allowed, but 1 found` (`ShopLoading('city-a')`, `ShopError('city-a')`, `getData('city-a')`), `Too few positional arguments: 2 required, 1 given` (`ShopLoadData(pool)`).
- Task 2: `Error when reading 'lib/screens/mainScreen/tabs/shop/components/shop_pool_loader.dart': No such file or directory`, `Method not found: 'ShopPoolLoader'`.
- Task 3: `the global catalogue queries left the registry (D-01)` → `Expected: not contains 'equipmentAssetsQuantity'`; `the schema check registers 43 documents` → `Expected: <43> Actual: <45>`.

## Verification

- `flutter test test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart` → 5 green; `shop_pool_loader_test.dart` → 7 green.
- `flutter test test/graphql test/tool test/screens/mainScreen test/repository/services/graphql` → 1127 green.
- `flutter test test/screens/mainScreen test/graphql test/tool test/repository` → 1704 green.
- `flutter analyze` → 51 issues before, 50 after (the `avoid_print` of `shop_cubit.dart` is gone), all info, 0 error, 0 warning.
- `grep -rn "AssetsQuantity" lib tool` → empty.
- D-02 greps: `grep -c "\.name" shop_pool_loader.dart` = 0; added lines of `shop.dart` with `.name` in 7eff79c = 0 and in 7fe4c15 = 0.
- `grep -rn "Cavalcatura" lib` → empty.

## Deviations from Plan

1. **[Rule 1 - Test bug] Event queue flushed in the two last-request-wins tests** (Task 1, 7fe4c15): the cubit stream delivers asynchronously, so the listener missed the final `ShopLoadData` when cancelled right after the `await`; added `await pumpEventQueue()` before `subscription.cancel()`. The test change went into the GREEN commit.
2. **[Rule 3 - Blocking] `test/graphql/travel_documents_test.dart` updated** (Task 3 RED, e7417d0): its «registers 45 documents» test became «registers 43 documents» (title and value), outside the plan's `files_modified`.
3. **Registry doc comment** (Task 3): the plan's suggested sentence names `equipmentAssetsQuantity` / `lootAssetsQuantity`, which conflicts with the acceptance grep `grep -rn "AssetsQuantity" lib tool` = empty; the comment says «ha tolto i due cataloghi globali di equipaggiamento e loot (BE D-20: deprecati, nessun consumer)».
4. **Formatter reflow** of untouched members in `equipment_item_queries.dart` and `loot_item_queries.dart` (both were not formatter-clean before; `static String get x =>` followed by `'''` on the next line). Accepted per REPO-RULES.
5. `_isStaleRowRefusal(TransactionState)` extracted in the loader for the `listenWhen` predicate (readability; same behaviour).
6. Bookkeeping uses the orchestrator's progress number 6/11 instead of the plan's 05/11.

## Known Stubs

None. The buy/sell selections stay `List<AssetQuantity>` (13-07 moves them to `TradeSelection`); pets of the pool are not shown yet (13-07).

## Self-Check: PASSED
