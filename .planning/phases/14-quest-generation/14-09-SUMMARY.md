---
phase: 14-quest-generation
plan: 09
subsystem: journal
tags: [models, graphql, journal, shop, equipment, jewels, qgen-06, tdd]
requires:
  - 14-08 (phase branch state at 75fac7e)
provides:
  - "`enum AccessoryUseType { attack, defense }` with labels «Attacco» / «Difesa»"
  - "`EquipmentItem.accessoryUseTypes` (`List<AccessoryUseType>?`, optional ctor param, unmodifiable, unknown names dropped)"
  - "`accessoryUsageLine(EquipmentItem)` pure «Uso: …» line"
  - "`EquipmentFragment.fields` and `fieldsWithFullSpell` select `accessoryUseTypes` (not `simpleFields`, not `definition`)"
  - "`EquipmentInfoSheet.usageKey` «Uso» line below the item name (Journal and shop)"
affects: [14-10, 14-11]
tech-stack:
  added: []
  patterns: [tolerant enum parsing with asNameMap, pure line function in utils/item_lines.dart]
key-files:
  created:
    - lib/models/enums/accessory_use_type.dart
    - test/models/enums/accessory_use_type_test.dart
    - test/models/equipment_item_test.dart
  modified:
    - lib/models/equipment_item.dart
    - lib/utils/item_lines.dart
    - lib/graphql/fragments/equipment_fragment.dart
    - lib/shared/components/popup/equipment_info_sheet.dart
    - test/utils/item_lines_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/character_fragment_test.dart
    - test/shared/components/popup/equipment_info_sheet_test.dart
decisions:
  - "`toJson` always writes the `accessoryUseTypes` key (null for pieces without it), like the other nullable fields of `EquipmentItem`"
  - "The «Uso» line is plain `Text` in `bodyMedium`, no colour override, centred, between the name and the stats"
metrics:
  duration: ~15 min
  completed: 2026-11-04
  tasks: 3
  commits: 6
---

# Phase 14 Plan 09: Jewels' «Uso» line Summary

Rings and necklaces now tell the player whether they act in attack, defense or both. `EquipmentItem` parses `accessoryUseTypes` tolerantly: unknown names are dropped through `asNameMap`, never a throw (T-14-20). The shop, equipment and Journal documents select the field; quest and result items (`simpleFields`) do not. `EquipmentInfoSheet`, the one sheet used by the Journal and the shop (D-15), shows «Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa» below the item name, only for a ring or a necklace with a non-empty list (D-12). There is no filter, no equip constraint and no icon in the lists. Tested on fixtures; no check ran against the BE schema and the BE repo was not read.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | AccessoryUseType, EquipmentItem.accessoryUseTypes, accessoryUsageLine | 66cc9f8 (test), b3450d7 (feat) |
| 2 | Equipment fragments select accessoryUseTypes | df402ae (test), c990b92 (feat) |
| 3 | «Uso» line on EquipmentInfoSheet | 031b86a (test), c0263a4 (feat) |

## Exact names and signatures

- `lib/models/enums/accessory_use_type.dart`: `enum AccessoryUseType { attack(label: 'Attacco'), defense(label: 'Difesa'); const AccessoryUseType({required this.label}); final String label; }` (no image, Flutter-free).
- `lib/models/equipment_item.dart`: ctor gains optional `this.accessoryUseTypes`; `final List<AccessoryUseType>? accessoryUseTypes;`; `fromJson` → top-level private `_accessoryUseTypesFrom(Object? json)` (non-list → null; `List.unmodifiable`); `toJson` `'accessoryUseTypes': accessoryUseTypes?.map((type) => type.name).toList()`; `copyWith({…, List<AccessoryUseType>? accessoryUseTypes})`; `props` includes it.
- `lib/utils/item_lines.dart`: `String? accessoryUsageLine(EquipmentItem item)` — null unless `equipType` is `ring`/`necklace` and at least one use is present; canonical order attack → defense, duplicates once, labels lower-cased, joined with ` e `.
- `lib/graphql/fragments/equipment_fragment.dart`: `accessoryUseTypes` right after `equipType` in `fields` and `fieldsWithFullSpell`.
- `lib/shared/components/popup/equipment_info_sheet.dart`: `static const Key usageKey = ValueKey('equipmentInfo.usage');`; `final usage = accessoryUsageLine(widget.equipmentItem);` in `build`; `if (usage != null) Text(usage, key: EquipmentInfoSheet.usageKey, textAlign: TextAlign.center, style: KlimmeckGuideTheme.instance.bodyMedium)` between the name `SizedBox(height: 30)` and the stats `Expanded`.
- Test fixtures: `test/models/equipment_item_test.dart` `_piece(String equipType, {List<String>? uses})`; `test/utils/item_lines_test.dart` `_jewel(EquipType, List<AccessoryUseType>?)` (direct ctor); `test/shared/components/popup/equipment_info_sheet_test.dart` `_jewel(equipType, name, uses)`, `_ring(uses)` («Anello di rubino»), `_necklace(uses)` («Collana d'ambra»), `_pump(tester, {EquipmentItem? item, isEquipped, onEquip})` (default `_helm`), setUp seeds `ringType` and `necklaceType`.

## RED failures observed

- Task 1: compile failure — `Error when reading 'lib/models/enums/accessory_use_type.dart': No such file or directory`, `Undefined name 'AccessoryUseType'`.
- Task 2: 2 failures — «GetCityShop equipment selects accessoryUseTypes (D-15)» and «the Journal assets select accessoryUseTypes on equipment (D-15)». «quest and result items keep the simple fields without use types (D-15)» was green at the first run by design: it guards `simpleFields` against the change.
- Task 3: compile failure — `Member not found: 'usageKey'`.

## Tests

- Task 1 verify: `+27: All tests passed!` (4 files).
- Task 2 verify `flutter test test/graphql test/tool`: `+135: All tests passed!`.
- Task 3 verify (sheet + journal + shop): `+226: All tests passed!`.
- Plan verification (`test/models test/utils test/graphql test/tool` + sheet + journal + shop): `+1009: All tests passed!`.
- Full suite `flutter test` (orchestrator instruction, foreground): `+3173: All tests passed!`, exit 0.
- `flutter analyze` repo-wide: `50 issues found.` — 0 error, 0 warning (all info, baseline unchanged).

## Acceptance greps

- `enum AccessoryUseType` = 1; `asNameMap` in equipment_item.dart = 1; `accessoryUseTypes` in equipment_item.dart = 8 (≥ 5).
- `String? accessoryUsageLine` = 1; `'Uso: ` = 1; `D-1[25])` in the three Task 1 test files = 12.
- `^ *accessoryUseTypes$` in equipment_fragment.dart = 2; `D-15)` in the two graphql tests = 3.
- `usageKey` in the sheet = 2; `accessoryUsageLine(widget.equipmentItem)` = 1; `accessoryUseTypes` in `item_row.dart`, `cards/`, `filter_values.dart` = nothing; `D-12)` in the sheet test = 5.
- `package:flutter/` in the enum and the model = nothing.

## Deviations from Plan

- **Formatter reflow (accepted per REPO-RULES):** `dart format lib/graphql/fragments/equipment_fragment.dart` reflowed the untouched getters `definition` and `fieldsWithFullSpell` (`=>` then the string on the next line) and dropped the trailing blank line. `dart format test/utils/item_lines_test.dart` reflowed the new tests only.
- **`accessoryUsageLine` guard on two lines:** the `if` with both `equipType` checks goes over 80 columns, so it uses a block `{ return null; }` instead of the single-line form of the skeleton. The behaviour is unchanged.
- **Boy Scout:** the blank line between the name `SizedBox` and the stats `Expanded` in `equipment_info_sheet.dart` went away where the «Uso» line now sits.
- **Bookkeeping:** the plan's `<output>` writes `09/11` and `Plan: 09 of 11`; the orchestrator's `9/11` / `Plan: 9 of 11` win. The STATE status line already said that 14-10/14-11 wait for the BE merge; it now says plans 01–09 are done on mocks.

## Known Stubs

None.

## Threat Flags

None. T-14-20 is mitigated by `asNameMap` and the test «drops unknown use names instead of throwing (D-12)». T-14-21 is accepted: the FE adds no equip constraint.

## Self-Check: PASSED

- Files: `lib/models/enums/accessory_use_type.dart`, `test/models/enums/accessory_use_type_test.dart`, `test/models/equipment_item_test.dart` exist.
- Commits: 66cc9f8, b3450d7, df402ae, c990b92, 031b86a, c0263a4 in `git log 75fac7e..HEAD`; trailer check `0` after each.
