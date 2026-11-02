---
phase: 13-city-shops
plan: 01
subsystem: models
tags: [models, pet, city, shop, transaction, fixtures, tdd]
requires: []
provides:
  - Pet.speedModifier / Pet.sellable
  - CharacterAssets.ownedPets
  - City.size / City.hasShop
  - CityShop pool model
  - TransactionItems.petAssets
  - EquipPetRequest / UnequipPetRequest
  - test/helpers/fixtures/shop_fixtures.dart
affects: [13-02, 13-03, 13-04, 13-05, 13-06, 13-07, 13-08, 13-09, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "enum parsing via values.asNameMap()[raw] (unknown -> null, never byName throw)"
    - "request inputs serialised as explicit plain maps (no reliance on jsonEncode calling toJson)"
key-files:
  created:
    - lib/models/city_shop.dart
    - lib/models/request/equip_pet_request.dart
    - test/helpers/fixtures/shop_fixtures.dart
    - test/models/pet_test.dart
    - test/models/character/character_assets_test.dart
    - test/models/city_test.dart
    - test/models/city_shop_test.dart
    - test/models/request/transaction_request_test.dart
    - test/models/request/equip_pet_request_test.dart
  modified:
    - lib/models/pet.dart
    - lib/models/character/character_assets.dart
    - lib/models/city.dart
    - lib/models/request/transaction_request.dart
decisions:
  - "City.hasShop defaults to true when absent (fixtures without the flag keep their shop, D-15)"
  - "TransactionItems.toJson now emits plain maps; TransactionRequest/TransactionItems fields are final (no caller reassigned them)"
metrics:
  duration: ~15 min
  completed: 2026-11-02
  tasks: 2
  files: 13
---

# Phase 13 Plan 01: City shop models Summary

Flutter-free models for the BE Phase 12 contract: `Pet.speedModifier`/`sellable`, `CharacterAssets.ownedPets`, `City.size` (asNameMap, unknown → null) and `City.hasShop` (absent → true), the new `CityShop` pool, `TransactionItems.petAssets`, `EquipPetRequest`/`UnequipPetRequest`, plus the shared shop JSON fixtures.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | 60baab4 | test(models): expect pet speed, owned pets and city shop flags |
| 1 GREEN | 164b951 | feat(models): parse pet speed, owned pets and city shop flags |
| 2 RED | d7d5470 | test(models): expect the city pool and pet trade requests |
| 2 GREEN | 5818532 | feat(models): add the city pool and pet trade requests |

## RED failures observed

- Task 1: compile failures — `The getter 'speedModifier' isn't defined for the type 'Pet'`, `The getter 'sellable' isn't defined for the type 'Pet'`, `The getter 'ownedPets' isn't defined for the type 'CharacterAssets'`, `The getter 'size' isn't defined for the type 'City'` (and `hasShop`).
- Task 2: compile failures — `Undefined name 'CityShop'`, `No named parameter with the name 'petAssets'`, `Error when reading 'lib/models/request/equip_pet_request.dart': No such file or directory`.
- No test was green at its first run.

## Created names and signatures

- `Pet({..., this.speedModifier, this.sellable})`: `final double? speedModifier` (`(json['speedModifier'] as num?)?.toDouble()`), `final bool? sellable` (`json['sellable'] as bool?`); both in `toJson`, `copyWith`, `props`.
- `CharacterAssets({..., this.ownedPets = const []})`: `final List<Pet> ownedPets` (unmodifiable when parsed; `const []` when absent); `toJson` writes `"ownedPets": [ids]`; in `props`.
- `City({..., this.size, this.hasShop = true})`: `final CitySizeType? size` (`CitySizeType.values.asNameMap()[json["size"]]`), `final bool hasShop` (`json["hasShop"] as bool? ?? true`); `toJson` writes `size?.name`, `hasShop`; in `copyWith`, `props`.
- `CityShop({required String cityId, required List<AssetQuantity> equipment, required List<AssetQuantity> loot, required List<Pet> pets})`, `factory CityShop.fromJson(Map<String, dynamic>)`: reads `json['city']['id']`, throws `FormatException('cityShop.city.id missing')` if not a String; absent lists → empty; all lists unmodifiable; Equatable on all four fields.
- `TransactionItems({required equipAssets, required lootAssets, this.petAssets = const []})`, `toJson()` → `{'equipAssets': [...maps], 'lootAssets': [...maps], 'petAssets': [...maps]}`.
- `EquipPetRequest({required String id, required String petId})` → `{'id', 'petId'}`; `UnequipPetRequest({required String id})` → `{'id'}`; both Equatable.
- Fixtures (`test/helpers/fixtures/shop_fixtures.dart`): `coinsJson({gold, silver, copper})`, `petJson({id='pet-travel-horse', name='Cavallo da viaggio', speedModifier=2, sellable=true, buyPrice, sellPrice})`, `catPetJson()` (id `pet-cat`, speedModifier null), `equipmentAssetJson({id='e-sword', rarity='common', quantity=1})` (equipType `weapon`), `lootAssetJson({id='l-potion', quantity=1})` (effect `heal`), `cityShopJson({cityId='city-talmvere', equipment, loot, pets})`.

## Verification

- Task 1 verify: 19 tests passed (11 new + 8 satchel_availability).
- Task 2 verify: 21 tests passed (10 new + 11 existing transaction tests).
- Plan verification (`flutter test test/models` + transaction + satchel tests): 521 passed.
- `flutter analyze`: 51 issues, all info, 0 error, 0 warning (baseline unchanged).
- `dart format` run one by one on the 13 touched files; the 6 test files were formatted before the RED commit, the models showed 0 changes.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Plan inconsistency] D-tag acceptance grep cannot reach 11**
- **Found during:** Task 1 acceptance
- **Issue:** `grep -c "(D-04)\|…\|(D-15)"` over the three test files sums to 9, not ≥ 11. The plan mandates titles "exactly as listed": «lists speedModifier and sellable in props» carries no tag, and «(wire default, D-15)» does not match the literal `(D-15)`.
- **Fix:** kept the titles exactly as listed (the title rule wins over the count); no artificial tags added.
- **Commit:** 60baab4

**2. [Boy Scout] `TransactionRequest` fields made `final`**
- As the plan allowed: grep confirmed no caller reassigns `boughtItems`/`soldItems`/`total`/`id`/`isTotalPositive`. Commit 5818532.

## Known Stubs

None.

## Self-Check: PASSED

All 9 created files and the 4 modified files exist; commits 60baab4, 164b951, d7d5470, 5818532 are in `git log`.
