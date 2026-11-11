---
phase: 19-model-review
plan: 03
subsystem: models
tags: [models, repository, lenient-parsing, entry-boundary, equipment, city, shop, tdd]
requires: ["19-02"]
provides:
  - "AssetQuantity.tryFromJson(Object?): null for a non-map or for an entry whose item throws while parsing; an entry without an item is kept"
  - "CharacterAssets.ownedItems / ownedEquipments read through the boundary (non-list → empty list)"
  - "CityShop pools: equipment / loot through AssetQuantity.tryFromJson, pets through Pet.tryFromJson (non-list → empty list)"
  - "EquipmentItem.tryFromJson(Object?) and Equipment.fromJson reading every worn slot through it (unreadable item → empty slot)"
  - "City.tryFromJson(Object?) and KlimmeckGraphQl.getCities keeping the cities that parse"
affects: [19-04, 19-10, 19-12]
tech-stack:
  added: []
  patterns: ["strict item parser + tryFromJson entry boundary (map check, try / on Object → null) + nonNulls at the list"]
key-files:
  created:
    - test/models/asset_quantity_test.dart
    - test/models/equipment_test.dart
    - test/repository/services/graphql/graphql_get_cities_test.dart
  modified:
    - lib/models/asset_quantity.dart
    - lib/models/character/character_assets.dart
    - lib/models/city_shop.dart
    - lib/models/equipment_item.dart
    - lib/models/equipment.dart
    - lib/models/city.dart
    - lib/repository/services/graphql/graphql.dart
    - test/models/character/character_assets_test.dart
    - test/models/city_shop_test.dart
    - test/models/city_test.dart
decisions:
  - "LootItem.fromJson, EquipmentItem.fromJson and City.fromJson stay strict: only the list (or the slot) around them drops the entry"
  - "The owned lists of CharacterAssets stay growable (List<AssetQuantity>.from) with unchanged field types"
  - "getCities logs nothing about a dropped city (no payload, no count)"
metrics:
  duration: "~20 min"
  completed: 2026-11-11
  tasks: 3
  files: 13
---

# Phase 19 Plan 03: Entry boundaries for items, worn slots, shop pool and cities — Summary

An owned or pool entry whose item cannot be parsed is dropped at the list, an unreadable worn item reads as an empty slot, and `getCities` keeps the cities that parse — rows 8, 9, 10, 12 of the MODEL-04 table, with the item and city parsers still strict and nothing on the wire touched.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `edfe953` | test(models): pin the asset entry boundaries |
| 2 | `c41dc9d` | fix(models): drop unreadable asset entries at the list boundary |
| 3 | `bab0941` | test(models): pin the worn slot boundary |
| 4 | `51443e3` | fix(models): read an unreadable worn item as an empty slot |
| 5 | `f1caa39` | test(repository): pin the city list boundary |
| 6 | `9255e45` | fix(repository): keep the cities that parse |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — run separately, as the plan asks.

`flutter test test/models/asset_quantity_test.dart` → `+0 -1: Some tests failed.` (compile failure of the new file: `Error: Member not found: 'AssetQuantity.tryFromJson'`) — the expected RED of a new API; its six cases were not observed individually in RED.

`flutter test test/models/character/character_assets_test.dart test/models/city_shop_test.dart` → `+8 -6: Some tests failed.`

- «drops an owned item with an unknown effect and keeps the others (D-16)»: `Invalid argument (name): No enum value with that name: "teleport"` (`loot_item.dart 47:29` through `character_assets.dart 35:61`)
- «drops an owned equipment with an unknown equip type and keeps the others (D-16)»: `No enum value with that name: "cape"` (`equipment_item.dart 38:28`)
- «owned lists that are not lists are empty (D-16)»: `NoSuchMethodError: Class 'int' has no instance method 'map'`
- «drops a pool loot entry with an unknown effect (D-16)»: `No enum value with that name: "teleport"` (through `CityShop._assets`)
- «drops a pool equipment entry with an unknown rarity (D-16)»: `No enum value with that name: "mythic"` (`equipment_item.dart 50:29`)
- «drops a pool pet that is not a map or has no id (D-16)»: `type 'String' is not a subtype of type 'Map<String, dynamic>' in type cast` (`city_shop.dart 26:33`)

Green at the first run: «a pool without a city id still throws (D-16)» — the `FormatException` of today, pinned against a regression of the GREEN step.

**Task 2** — `flutter test test/models/equipment_test.dart` → compile failure of the new file: `Error: Member not found: 'EquipmentItem.tryFromJson'` (4 call sites). The four `Equipment.fromJson` cases were not observed individually in RED (same file).

**Task 3**

- `flutter test test/models/city_test.dart` → compile failure: `Error: Member not found: 'City.tryFromJson'`.
- `flutter test test/repository/services/graphql/graphql_get_cities_test.dart` → `+1 -1`: «getCities keeps the cities that parse and drops a city with an unknown type (D-16)»: `Invalid argument (name): No enum value with that name: "floatingCitadel"` (`city.dart 35:52` through `graphql.dart 318:42`).

Green at the first run: «getCities still throws when the list is missing (D-16)» (the `Exception('No cities found')` of today) and, once the file compiled, «City.fromJson stays strict on an unknown type (D-16)» (the strict contract the widgets rely on, as the plan expected).

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models test/screens/mainScreen/tabs/shop` (Task 1) | `+895: All tests passed!` |
| `flutter test test/models test/screens/mainScreen/tabs/journal` (Task 2) | `+1060: All tests passed!` |
| `flutter test test/models test/repository test/screens/mainScreen/cubit` (Task 3) | `+1738: All tests passed!` |
| plan `<verification>` (`test/models test/repository test/screens/mainScreen/tabs/shop test/screens/mainScreen/tabs/journal`) | `+2002: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |
| `sh tool/hardening_check.sh` | exit 0 (ran without device or network) |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `static AssetQuantity? tryFromJson` 1 · `AssetQuantity.tryFromJson` in `character_assets.dart` 1 (≥ 1), `AssetQuantity.fromJson` 0 · in `city_shop.dart`: `AssetQuantity.tryFromJson` 1, `Pet.tryFromJson` 1, `Pet.fromJson` 0 · `git diff HEAD~2 --stat -- lib/models/loot_item.dart lib/models/equipment_item.dart lib/models/asset_item.dart lib/models/quest lib/models/quest_result` empty · `D-16)` 6 / 3 / 4.

Task 2: `EquipmentItem.tryFromJson(` in `equipment.dart` 9, `EquipmentItem.fromJson(` 0 · `static EquipmentItem? tryFromJson` 1 · `D-16)` in `equipment_test.dart` 5 · `toJson` lines in the diff of `equipment.dart` 0.

Task 3: `static City? tryFromJson` 1 · `City.tryFromJson` in `graphql.dart` 1 · `CityType.values.byName` in `city.dart` 1 · `D-16)` 4 (`city_test.dart`) / 2 (`graphql_get_cities_test.dart`) · `debugPrint(|print(` in `graphql.dart` 0 before and after.

Over the whole plan: `lib/graphql`, `lib/models/quest`, `lib/models/quest_result`, `loot_item.dart`, `asset_item.dart` untouched; `equipment_item.dart` only gains `tryFromJson` (additions only, `fromJson` unchanged). All single-line greps matched without `grep -A3`. `git status --short` → ` M pubspec.lock` only (plus the plan files the planner is editing, not ours).

## Growable lists

`grep -rnE "owned(Items|Equipments)\b" lib | grep -E "\.add|\.remove|sort\("` prints nothing: no caller mutates the owned lists. They stay growable anyway (`List<AssetQuantity>.from`, and `<AssetQuantity>[]` for a non-list), exactly as before. The shop pools stay `List.unmodifiable` (existing pin «exposes unmodifiable lists» green).

## Files formatted

`dart format` one by one on every touched file. Reflowed: `lib/models/character/character_assets.dart` (only the new `_entriesFrom` member), and the test files `equipment_test.dart` and `city_test.dart` before their first commit. Every other file was already clean. The formatter-dirty `asset_item.dart` and `equip_type.dart` are only imported.

## Deviations from Plan

None that needed a rule — plan executed as written. Notes:

- `city_shop.dart`: one private helper `_entries(Object? raw)` (a non-list → empty list) is shared by the three pools, instead of repeating the `is List` check twice.
- `equipment.dart`: the nine `fromJson` keys are now written with single quotes (as in the plan's skeleton); key names unchanged, `toJson` untouched.
- `graphql_get_cities_test.dart` copies the harness of `graphql_use_item_test.dart` without its `requests` recorder (no case inspects the request).
- Three long test titles are split by the formatter over two adjacent string literals; the title text is intact and the `D-16)` counts hold.
- No log line was added to `getCities` for a dropped city (the plan left it optional).

## Notes for the next plans

- `Pet.tryFromJson` (19-04) only checks «map with a string `id`»: it does NOT catch a throw inside `Pet.fromJson` (e.g. a pet whose `damages` — later `attack` / `defense` — is not a map still throws through the shop pool). If 19-04 wants row 12 airtight for the new fields, guard the non-map value in `Pet.fromJson` or give `OwnedPet.tryFromJson` / the pool a `try`.
- The boundaries catch `on Object`: a malformed shape inside an item (wrong cast) drops the entry too, not only an unknown enum name.
- `AssetQuantity.tryFromJson` keeps an entry without an item (`item` null) as before: readers of the owned lists still have to handle `entry.item == null`.
- `Equipment.fromJson` still takes a `Map<String, dynamic>` and `CharacterAssets` still guards `wearedEquipment` with `!= null` only: a non-map `wearedEquipment` value still throws (outside rows 8–12).
- 19-10 (boots slot rename): `test/models/equipment_test.dart` never names the boots slot; in `lib/models/equipment.dart` the slot line is now `foots: EquipmentItem.tryFromJson(json['foots']),` (single quotes) — adjust any grep anchored to the old double-quoted form.
- `graphql_get_cities_test.dart` builds its cities from `travelCityJson` (the lore `image` key comes from that funnel only): the `Lore.imagePath` flip needs no edit in this file.
- `City.tryFromJson` is used only by `getCities`; other `City.fromJson` call sites (quests, character payload) are unchanged.
- No file under `lib/graphql` was touched; the registry stays at 46 documents.

## Known Stubs

None.

## Self-Check: PASSED

- Created files exist: `test/models/asset_quantity_test.dart`, `test/models/equipment_test.dart`, `test/repository/services/graphql/graphql_get_cities_test.dart`.
- Commits `edfe953`, `c41dc9d`, `bab0941`, `51443e3`, `f1caa39`, `9255e45` are in `git log`.
