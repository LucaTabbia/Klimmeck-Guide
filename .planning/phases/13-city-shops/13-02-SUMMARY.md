---
phase: 13-city-shops
plan: 02
subsystem: graphql
tags: [graphql, documents, service, pet, city-shop, tdd]
requires:
  - 13-01 (CityShop, EquipPetRequest/UnequipPetRequest, Pet.speedModifier/sellable, shop fixtures)
provides:
  - PetFragment.fields
  - CharacterFragment.assetsFields selects pet and ownedPets
  - cities selects size and hasShop
  - ShopQueries.getCityShop (GetCityShop)
  - CharacterMutations.equipPet / unequipPet (EquipPet / UnequipPet)
  - schema-check registry at 45 entries
  - KlimmeckGraphQl.getCityShop / equipPet / unequipPet
affects: [13-03, 13-05, 13-07, 13-08, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "one shared _successfulMutation(document, field, Map request) helper for every CommonResponse mutation of the character slots"
key-files:
  created:
    - lib/graphql/fragments/pet_fragment.dart
    - lib/graphql/queries/shop_queries.dart
    - test/graphql/shop_documents_test.dart
    - test/repository/services/graphql/graphql_shop_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/queries/city_queries.dart
    - lib/graphql/mutations/character_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/travel_documents_test.dart
decisions:
  - "_spellSlotMutation renamed _successfulMutation and takes the serialised request map; equipSpell/unequipSpell pass request.toJson() (behaviour unchanged)"
  - "From 13-02 the branch needs BE Phase 12 to run on a device (D-16), accepted by design"
metrics:
  duration: ~12 min
  completed: 2026-11-02
  tasks: 2
  files: 12
---

# Phase 13 Plan 02: City pool and companion documents Summary

GraphQL documents and service methods for the BE Phase 12 contract: `PetFragment` (no `imagePath`), `pet`/`ownedPets` in the character fragment, `size`/`hasShop` in `cities`, `GetCityShop` (city id only), `EquipPet`/`UnequipPet`, three new registry entries (45), and `KlimmeckGraphQl.getCityShop`/`equipPet`/`unequipPet` on a shared successful-flag helper.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | 08a45f2 | test(graphql): expect the city pool and companion documents |
| 1 GREEN | c6d87d9 | feat(graphql): add the city pool and companion documents |
| 2 RED | bc4e688 | test(graphql): expect the city pool and companion service calls |
| 2 GREEN | 6e155bb | feat(graphql): read the city pool and equip companions |

## RED failures observed

- Task 1: compile failure — `Error when reading 'lib/graphql/fragments/pet_fragment.dart': No such file or directory`, `Undefined name 'PetFragment'` (and `ShopQueries` / `shop_queries.dart` missing in `shop_documents_test.dart`).
- Task 2: compile failure — `The method 'getCityShop' isn't defined for the type 'KlimmeckGraphQl'`, same for `equipPet` and `unequipPet`.
- No test was green at its first run.

## Created names and signatures

- `lib/graphql/fragments/pet_fragment.dart`: `class PetFragment { static const String fields }` → `id name speedModifier sellable buyPrice { gold silver copper } sellPrice { gold silver copper }`; exported by `fragments.dart`.
- `CharacterFragment.assetsFields`: after `ownedItems { … }` adds `pet { ${PetFragment.fields} }` and `ownedPets { ${PetFragment.fields} }`.
- `CityQueries.getAllCities` (operation `cities`): `id type name size hasShop markerLocation { … } relatedLore { … }`.
- `lib/graphql/queries/shop_queries.dart`: `class ShopQueries { static String get getCityShop }` → `query GetCityShop($cityId: ID!) { cityShop(cityId: $cityId) { city { id } equipment { quantity item { ... on EquipmentItem { EquipmentFragment.fields } } } loot { quantity item { ... on LootItem { LootFragment.fields } } } pets { PetFragment.fields } } }`.
- `CharacterMutations.equipPet` (`mutation EquipPet($request: EquipPetRequest!) { equipPet(request: $request) { response successful } }`), `CharacterMutations.unequipPet` (`UnequipPet`, `UnequipPetRequest!`).
- Registry: `'GetCityShop'` after `'GetCity'`; `'EquipPet'`, `'UnequipPet'` after `'UnequipSpell'`; 45 entries.
- `KlimmeckGraphQl.getCityShop(String cityId) → Future<CityShop>` (variables `{'cityId': cityId}`; `data['cityShop']` not a map → `FormatException('cityShop malformed')`; errors → raw `OperationException` via `_dataOrThrow`).
- `KlimmeckGraphQl.equipPet(EquipPetRequest) → Future<bool>`, `unequipPet(UnequipPetRequest) → Future<bool>` (variables `{'request': request.toJson()}`; `successful` not bool → `FormatException('<field> malformed')`).
- `_successfulMutation(String document, String field, Map<String, dynamic> request)` replaces `_spellSlotMutation`.

## Verification

- Task 1 verify `flutter test test/graphql test/tool`: 121 passed.
- Task 2 verify `flutter test …graphql_shop_test.dart …graphql_spells_test.dart test/graphql test/tool`: 138 passed (7 new service tests).
- `flutter analyze`: 51 issues, all info, 0 error, 0 warning (baseline unchanged).
- `dart format` run one by one on the 12 touched files; it reflowed `static String get getAllCities =>` and `static const String fields =` onto the tall style (accepted).
- Acceptance greps all at the expected counts (`equipPet(` counts 2 because it also matches `unequipPet(`; criterion is ≥ 1).

## Device note

From plan 13-02 on the branch needs BE Phase 12 to run on a device: the cold start selects `size`/`hasShop`, the character fragment selects `pet`/`ownedPets`; against an older BE the GraphQL validation fails (research Pitfall 2, CONTEXT D-16). No device run until 13-11.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Obsolete test] `fullFields never selects the pet (BE handoff 11 b)` replaced**
- **Found during:** Task 1 RED
- **Issue:** the existing test in `test/graphql/character_fragment_test.dart` asserted the opposite of D-11 (no `pet` in the fragment) and would fail once `pet { … }` is selected.
- **Fix:** replaced by the new test «selects the equipped pet and the owned pets with PetFragment (D-11)».
- **Commit:** 08a45f2

**2. [Rule 3 - Blocking] registry count test bumped 42 → 45**
- **Found during:** Task 1 GREEN
- **Issue:** `test/graphql/travel_documents_test.dart` «the schema check registers 42 documents» failed (`Expected: <42> Actual: <45>`); the file was not in `files_modified`.
- **Fix:** title and value now 45 (13-05 will lower it to 43 when the two catalogues leave).
- **Commit:** c6d87d9

## Known Stubs

None.

## Self-Check: PASSED

All 4 created files and 8 modified files exist; commits 08a45f2, c6d87d9, bc4e688, 6e155bb are in `git log`.
