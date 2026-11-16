---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 04
subsystem: map
tags: [city-type, markers, cloudinary, visibility]
requires: ["23-03"]
provides:
  - "CityType.aarakocraCapital (39), CityType.dragonbornCapital (39), CityType.dragonbornVillage (30), no alwaysVisible"
  - "CloudinaryAssets.aarakocraCapital / dragonbornCapital / dragonbornVillage with the real ids of D-21"
affects: [23-05, 23-07, 23-08]
tech-stack:
  added: []
  patterns: ["data-driven city markers: a new enum value plus a constant, no parser or layer change"]
key-files:
  created: []
  modified:
    - lib/models/enums/city_type.dart
    - lib/config/cloudinary_assets.dart
    - test/models/enums/city_type_test.dart
    - test/models/city_test.dart
    - test/screens/mainScreen/tabs/map/layers/city_markers_layer_test.dart
decisions:
  - "aarakocraCapital sits right after aarakocraVillage, dragonbornCapital and dragonbornVillage right after mountainVillage (enum order is not on the wire: byName)"
  - "No alwaysVisible on the new capitals: the served size capital already shows them from zoom 0"
metrics:
  duration: "~10 min"
  completed: 2026-11-15
---

# Phase 23 Plan 04: City types aarakocraCapital, dragonbornCapital, dragonbornVillage Summary

Murnborim (`aarakocraCapital`), Thengran (`dragonbornCapital`) and Veg Faldir (`dragonbornVillage`) now parse through `City.tryFromJson` instead of being dropped. The two capitals use the Talmvere marker size (39) and the village uses 30. Each is drawn from a constant that holds its real Cloudinary id. Visibility still comes only from the served `City.size`.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the aarakocra and dragonborn city types | aabc5431 |
| 1 GREEN | Add the aarakocra and dragonborn city types | c0e069e4 |
| 2 | Bookkeeping | (this docs commit) |

## TDD

- **RED (aabc5431):** compilation failed in all three files, as expected. «Member not found: 'aarakocraCapital' / 'dragonbornCapital' / 'dragonbornVillage'» appeared on `CityType` and on `CloudinaryAssets` in city_type_test, on `CityType` in city_test, and on the `CloudinaryAssets` seeds in city_markers_layer_test. Run: `+0 -3`. The runtime failure the plan anticipates (`City.tryFromJson` returning null because `byName` throws an `ArgumentError`) was never reached on its own: values and constants landed together in GREEN, so the code never compiled without them.
- **GREEN (c0e069e4):** `flutter test test/models test/screens/mainScreen/tabs/map test/repository` → **2429 passed**.
- **Green at the first run:** none could be, because every new case referenced a missing member. The existing «only Talmvere keeps its marker visible at every zoom (D-13)» and «a city with an unknown type is null (D-16)» were not touched and stayed green after GREEN.

## Verification

- `grep -c "aarakocraCapital(size: 39\|dragonbornCapital(size: 39\|dragonbornVillage(size: 30" lib/models/enums/city_type.dart` = 3: each value fits on one line, nothing wrapped
- `alwaysVisible: true` = 1. Each of the three ids appears exactly once in `cloudinary_assets.dart`
- `git diff HEAD~2 --stat -- lib/models/city.dart lib/screens lib/graphql` → empty, so the parser, the markers and the layer are untouched and the registry stays at 55
- `D-16` appears 2 times in city_type_test and `D-15` appears 3 times in city_test
- Formatter: `dart format` ran one file at a time on the five touched files. It reflowed only two test files (the long new titles); both lib files were already clean
- Analyzer: `47 issues found`, which is 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`

## Rules with no FE code

- D-18 (home cities), D-22 (heal and shop tier) and D-23 (city lore) are BE rules or DB content, so they need no FE code. The `aarakocraVillage` id is replaced in 23-05, not here.

## Deviations from Plan

None. The plan ran as written.

## Self-Check: PASSED
