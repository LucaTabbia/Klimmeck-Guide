---
phase: 19-model-review
plan: 02
subsystem: models
tags: [models, lenient-parsing, damages, spell, title, tdd]
requires: ["19-01"]
provides:
  - "BaseDamage.tryFromJson(Object?) / EnergyDamage.tryFromJson(Object?): null for a non-map, a missing type or an unknown type name"
  - "Damages.fromJson: entries read through the two boundaries, nulls dropped; a non-list base/energy is an empty list"
  - "Spell.fromJson: energyDamage through EnergyDamage.tryFromJson (unknown type or non-map → null, the spell stays)"
  - "CharacterStatus.fromJson: title through TitleType.values.asNameMap() (unknown or non-string → null)"
affects: [19-03, 19-04, 19-12]
tech-stack:
  added: []
  patterns: ["entry-level tryFromJson boundary + nonNulls at the list (precedent: SpellState.tryFromJson)"]
key-files:
  created:
    - test/models/damages_test.dart
    - test/models/spell_test.dart
  modified:
    - lib/models/base_damage.dart
    - lib/models/energy_damage.dart
    - lib/models/damages.dart
    - lib/models/spell.dart
    - lib/models/character/character_status.dart
    - test/models/character/character_status_test.dart
decisions:
  - "The strict BaseDamage.fromJson / EnergyDamage.fromJson factories stay (public signatures unchanged) but no production parser calls them any more"
  - "Damages lists stay growable and typed (List<T>.from), field types unchanged (List<BaseDamage>? / List<EnergyDamage>?)"
metrics:
  duration: "~10 min"
  completed: 2026-11-11
  tasks: 2
  files: 8
---

# Phase 19 Plan 02: Lenient damage entries, spell energy and title — Summary

A damage entry with an unknown or missing type is dropped at the list boundary (never kept with a `null` type), a spell with an unknown `energyDamage.type` keeps everything but its energy damage, and an unknown `CharacterStatus.title` is `null` — rows 5–7 of the MODEL-04 table, nothing on the wire touched.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `ef0af0a` | test(models): pin the damage entry boundary |
| 2 | `b3dd66c` | fix(models): drop damage entries with an unknown type |
| 3 | `675cef2` | test(models): pin the unknown spell energy and title |
| 4 | `abe280b` | fix(models): survive an unknown spell energy or title |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/models/damages_test.dart` → `+0 -1: Some tests failed.` (compile failure of the new file: `Error: Member not found: 'BaseDamage.tryFromJson'` / `'EnergyDamage.tryFromJson'`) — the expected RED of a new API. Because the file did not compile, the `Damages.fromJson` cases were not observed individually in RED.

**Task 2** — `flutter test test/models/spell_test.dart test/models/character/character_status_test.dart` → `+50 -4: Some tests failed.`

- «an unknown energy type leaves the spell without energy damage (D-16)»: `Invalid argument (name): No enum value with that name: "plasma"`
- «an energy damage that is not a map is null (D-16)»: `type 'String' is not a subtype of type 'Map<String, dynamic>'`
- «an unknown title is null and the status survives (D-16)»: `Invalid argument (name): No enum value with that name: "archmageOfNowhere"`
- «a title that is not a string is null (D-16)»: `type 'int' is not a subtype of type 'String'`

Green at the first run (pins against a regression of the GREEN step, as the plan expected):

- «parses a known energy damage (D-16)» — the strict factory already read a known name.
- «a known title still parses (D-16)» — `byName('paladin')` already worked.

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models test/shared/components` (Task 1) | `+1124: All tests passed!` |
| `flutter test test/models test/screens/mainScreen/tabs/journal` (Task 2) | `+1042: All tests passed!` |
| plan `<verification>` (`test/models test/shared/components test/screens/mainScreen/tabs/journal`) | `+1346: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `byName` in `damages.dart` 0 · `BaseDamage.tryFromJson` 1 · `EnergyDamage.tryFromJson` 1 · `static BaseDamage? tryFromJson` 1 · `static EnergyDamage? tryFromJson` 1 · `D-16)` in `damages_test.dart` 16 (≥ 10) · `git diff HEAD~2 --stat -- lib/shared lib/screens lib/graphql lib/models/enums` empty.

Task 2: `EnergyDamage.tryFromJson(json['energyDamage'])` in `spell.dart` 1 · `TitleType.values.byName` 0 · `TitleType.values.asNameMap()` 1 · `D-16)` 3 (`spell_test.dart`) / 3 (`character_status_test.dart`).

All single-line greps matched without `grep -A3`. `git status --short` → ` M pubspec.lock` only.

## Call sites of the damage factories

- `Damages.fromJson`: `lib/models/enemy.dart:48`, `lib/models/pet.dart:42`, `lib/models/equipment_item.dart:52` (all guarded by `json["damages"] != null`, unchanged).
- `BaseDamage.fromJson` / `EnergyDamage.fromJson`: were called only by `damages.dart` and `spell.dart`; after this plan no call site is left in `lib` or `test` (the factories stay, as the plan asks).
- No caller mutates the lists; they stay growable `List<T>.from(...)` as before.

## Files formatted

`dart format` one by one on every touched file: all already clean except the new `test/models/damages_test.dart` (reflowed before its first commit). The formatter-dirty `damage_type.dart` / `energy_type.dart` are only imported.

## Deviations from Plan

None — plan executed exactly as written. Notes:

- The `Damages.fromJson` cases set both `base` and `energy` where the behaviour is symmetric (missing type, non-map entries), and the `tryFromJson` groups have four cases each (known, unknown name, missing type, non-map): more pins than the plan's minimum, same titles' rule suffix `(D-16)`.
- Two long test titles are wrapped by the formatter onto their own line (`test(\n 'title',`), the title text is intact.

## Notes for the next plans

- `Pet.attack` / `Pet.defense` (19-03/19-04) can go straight through `Damages.fromJson`: no entry with a `null` type can come out of it, so `petAttackLine` / `petDefenseLine` may rely on `type` being non-null for parsed values (the field type is still `DamageType?` / `EnergyType?`, a hand-built `BaseDamage(type: null, …)` is still possible in tests).
- `Damages.fromJson` still takes a `Map<String, dynamic>`: a caller must keep its own guard for a non-map `damages` value (`Pet`, `Enemy`, `EquipmentItem` only check `!= null`; a non-map `damages` still throws there — outside rows 5–7).
- A missing `base` / `energy` key is an empty list (as before); a `null` list never comes out of `Damages.fromJson`.
- `BaseDamage.fromJson` / `EnergyDamage.fromJson` are now dead in `lib` (kept by the plan): candidates for removal in a later cleanup if no fixture needs them.
- No file under `lib/graphql`, `lib/shared`, `lib/screens`, `lib/models/enums` was touched; the registry stays at 46 documents.

## Known Stubs

None.

## Self-Check: PASSED

- Created files exist: `test/models/damages_test.dart`, `test/models/spell_test.dart`.
- Commits `ef0af0a`, `b3dd66c`, `675cef2`, `abe280b` are in `git log`.
