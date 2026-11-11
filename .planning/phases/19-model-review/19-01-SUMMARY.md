---
phase: 19-model-review
plan: 01
subsystem: models
tags: [models, lenient-parsing, point-of-interest, enemy, weaknesses, tdd]
requires: []
provides:
  - "Weaknesses value (lib/models/weaknesses.dart): base, energy, lenient fromJson(Object?), toJson, props"
  - "Enemy.weaknesses (non-null, default const Weaknesses()); the two old lists are gone"
  - "shared top-level reader poiTypesFrom(Object?) in lib/models/enums/poi_type.dart (List<PoiType>?, unknown names dropped, non-list → null)"
  - "PointOfInterest without quest; location read by the private _locationFrom"
affects: [19-02, 19-03, 19-10, 19-12]
tech-stack:
  added: []
  patterns: ["lenient enum-list reader through asNameMap() + nonNulls (precedent: injuryTypesFrom)"]
key-files:
  created:
    - lib/models/weaknesses.dart
    - test/models/weaknesses_test.dart
    - test/models/enemy_test.dart
  modified:
    - lib/models/enums/poi_type.dart
    - lib/models/point_of_interest.dart
    - lib/models/enemy.dart
    - test/models/point_of_interest_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/tabs/map/world_map_availability_test.dart
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
    - test/screens/mainScreen/tabs/map/teleport_pawn_layer_test.dart
    - test/screens/mainScreen/components/teleport_mode_landing_test.dart
decisions:
  - "poiTypesFrom lives in lib/models/enums/poi_type.dart (the file was format-clean: no fallback file needed)"
  - "Enemy.weaknesses is an optional ctor parameter defaulting to const Weaknesses(); Enemy( is built only inside the model"
metrics:
  duration: "~15 min"
  completed: 2026-11-11
  tasks: 2
  files: 13
---

# Phase 19 Plan 01: POI and enemy parsers, Weaknesses — Summary

Lenient `PointOfInterest.type` / `Enemy.locations` through one shared `poiTypesFrom`, a guarded POI `location` that stays strict on malformed values, no `PointOfInterest.quest`, and `Enemy.weaknesses` as one lenient `Weaknesses { base, energy }` value — rows 1–4 of the MODEL-04 table, nothing on the wire touched.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `068abc2` | test(models): pin the lenient point of interest parsing |
| 2 | `62c42d4` | fix(models): parse point of interest types and location safely |
| 3 | `dffd7eb` | test(models): expect the enemy weaknesses value |
| 4 | `e34ddb3` | feat(models): read enemy weaknesses as one lenient value |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/models/point_of_interest_test.dart` → `+4 -7: Some tests failed.`

- «parses a list of known types (D-08)», «drops a type name this client does not know (D-08, D-16)», «an empty type list parses to an empty list (D-08)»: `type 'MappedListIterable<String, dynamic>' is not a subtype of type 'List<PoiType>?'` (`point_of_interest.dart 27:17`)
- «a type that is not a list is null (D-08)»: `NoSuchMethodError: Class 'String' has no instance method 'map'`
- «an absent location is null (D-17)», «a null location is null (D-17)»: `NoSuchMethodError: The method '[]' was called on null`
- «toJson writes no quest key (D-06)»: `Expected: not contains 'quest'  Actual: ['id', 'type', 'location', 'city', 'quest']`

Green at the first run (pins against a regression of the GREEN step, as the plan expected):

- «a location whose first element is null is null (D-17)» — today's `json["location"][0] != null` check already reads it as `null`.
- «a malformed location still throws (D-17)» — the strict `latLngFromWire` contract (and the unguarded index on `[]` / `'x'`) already throws.

**Task 2** — `flutter test test/models/weaknesses_test.dart test/models/enemy_test.dart` → `+0 -2: Some tests failed.` (compile failure of both files: `Couldn't find constructor 'Weaknesses'`, `The getter 'weaknesses' isn't defined for the type 'Enemy'`) — the expected RED of a new model.

## Tests and gates

| Command | Result |
|---------|--------|
| POI test + `wire_lat_lng_test` + the six touched screen tests | `+145: All tests passed!` |
| `flutter test test/models test/graphql/quest_result_documents_test.dart` | `+827: All tests passed!` |
| plan `<verification>` (`test/models`, `test/screens/mainScreen/tabs/map`, teleport landing, innkeeper panel) | `+1122: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `poiTypesFrom(json['type'])` 1 · `quest` 0 · `byName` 0 · `_locationFrom(json['location'])` 1 · `wire.first == null` 1 · test `D-17)` 4 · `first element is null` 1 · `D-08` 4 · `D-06)` 1 · `git diff HEAD~2 --stat -- lib/graphql lib/models/wire_lat_lng.dart` empty.

Task 2: `grep -rnE "energyWeaknesses|baseWeaknesses" lib test tool` empty · `Weaknesses.fromJson(json['weaknesses'])` 1 · `poiTypesFrom(json['locations'])` 1 · `byName` in `enemy.dart` 0 · `class Weaknesses extends Equatable` 1 · `package:flutter/` 0 · `grep -rn "weaknesses" lib/graphql` empty · `D-01)` 5 (weaknesses) / 4 (enemy) · `D-16)` 1.

All single-line greps matched without `grep -A3`. `git status --short` → ` M pubspec.lock` only.

## Files formatted

`dart format` one by one on every touched file; all were already clean except the new `test/models/weaknesses_test.dart` (one long `expect` reflowed before its first commit). No dirty baseline file was touched (`damage_type.dart` / `energy_type.dart` only imported).

## Deviations from Plan

None — plan executed exactly as written. Notes:

- The plan's line numbers for the six `quest: null` arguments point at the `PointOfInterest(` line; the argument sits five lines below in each file (one occurrence per file, removed).
- No other construction of `PointOfInterest(` exists in `lib` or `test`.
- `19-VALIDATION.md`: besides the two rows, the Wave 0 checkbox of `weaknesses_test.dart` / `enemy_test.dart` is ticked (the files now exist).

## Notes for the next plans

- `poiTypesFrom(Object?)` is the one lenient reader for a `List<PoiType>?`; it returns an unmodifiable list and `null` for a non-list.
- `Weaknesses.fromJson(Object?)` accepts only a `Map<String, dynamic>`; anything else is `const Weaknesses()`. Its lists are unmodifiable.
- `Enemy` constructor: `weaknesses` is optional (default `const Weaknesses()`); the other parameters are still `required`.
- `PointOfInterest` constructor is now `{id, type, location, city}`: a fixture that still passes `quest:` does not compile.
- `PointOfInterest.copyWith` still declares `dynamic city` (pre-existing, left as is: out of the plan's scope).
- Leftover grep of the phase: `energyWeaknesses|baseWeaknesses` already prints nothing in `lib test tool`.
- No file under `lib/graphql` was touched; the registry stays at 46 documents.

## Known Stubs

None.

## Self-Check: PASSED

- Created files exist: `lib/models/weaknesses.dart`, `test/models/weaknesses_test.dart`, `test/models/enemy_test.dart`.
- Commits `068abc2`, `62c42d4`, `dffd7eb`, `e34ddb3` are in `git log`.
