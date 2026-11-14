---
phase: 21-innkeeper-mission-completion-flow
plan: 06
subsystem: teleport-data
tags: [teleport, poi, labels, graphql, schema-check]
requires: ["21-05"]
provides:
  - "PoiType enhanced enum with Italian `label` (29 values, demonicPortal appended last)"
  - "placeLabelOf(PointOfInterest) — «Rovine presso Talmvere» / city name for a marker (D-29)"
  - "TeleportDestination { poiId, point, label, isCityMarker } with ofCity(City?) / ofPlace(PointOfInterest); innerPlacesOf(List<PointOfInterest>)"
  - "PointOfInterestQueries.listPointsOfInterest (ListPointsOfInterest), registry 47"
  - "fixture pointOfInterestJson in test/helpers/fixtures/travel_fixtures.dart"
affects: [21-07, 21-08, 21-13]
tech-stack:
  added: []
  patterns: ["one naming rule for places (placeLabelOf), Flutter-free model (equatable + latlong2)"]
key-files:
  created:
    - lib/models/travel/teleport_destination.dart
    - lib/graphql/queries/point_of_interest_queries.dart
    - test/models/enums/poi_type_test.dart
    - test/models/travel/teleport_destination_test.dart
  modified:
    - lib/models/enums/poi_type.dart
    - tool/schema_check/schema_check_documents.dart
    - test/helpers/fixtures/travel_fixtures.dart
    - test/tool/schema_check_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - test/models/point_of_interest_test.dart
    - test/models/enemy_test.dart
decisions:
  - "The two lenient-parsing tests that used `demonicPortal` as the unknown name now use `moon` (demonicPortal is a known type since D-29)"
  - "The doc comment of placeLabelOf avoids angle brackets (`unintended_html_in_doc_comment` would raise the analyzer to 49 infos)"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 13
---

# Phase 21 Plan 06: Inner-place data Summary

Italian labels for all 29 POI types (with `demonicPortal` no longer dropped), one place-naming rule «<tipo> presso <città>», the `TeleportDestination` model for city markers and inner places, and the live `ListPointsOfInterest` document registered as the 47th schema-check entry.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | c5a5050b | test(models): expect labelled POI types and teleport destinations |
| 1 GREEN | 6d4fd65d | feat(models): name inner places and model teleport destinations |
| 2 RED | aab37ce7 | test(graphql): expect the ListPointsOfInterest document |
| 2 GREEN | d7d70178 | feat(graphql): add the ListPointsOfInterest query for the teleport |
| 3 | (this commit) | docs(phase-21): record plan 06 progress |

## RED per task

- Task 1: compile failure — `Member not found: 'demonicPortal'`, `The getter 'label' isn't defined for the type 'PoiType'`, and `teleport_destination.dart` missing (`+0 -2`).
- Task 2: compile failure — `Error when reading 'lib/graphql/queries/point_of_interest_queries.dart'`, `Undefined name 'PointOfInterestQueries'`; the three other count pins failed on `46 != 47` (`+161 -4`).
- No case was green at the first run.

## Proposed PoiType labels (for the user's review at the UAT, D-29)

battleground «Campo di battaglia», all «Ovunque», vulcano «Vulcano», ruins «Rovine», dungeon «Sotterraneo», city «Città», graveyard «Cimitero», swamp «Palude», oasis «Oasi», harkenIsland «Isola di Harken», hills «Colline», minnelyForest «Foresta di Minnely», farNorth «Estremo Nord», drusteaPlains «Pianure di Drustea», undergroundLamstone «Sottosuolo di Lamstone», mountainLamstone «Monte Lamstone», glounet «Glounet», desert «Deserto», liberiaIsland «Isola di Liberia», valanPlains «Pianure di Valan», belleholmLake «Lago di Belleholm», belleholmIsland «Isola di Belleholm», temistosLake «Lago di Temistos», undergroundTemistos «Sottosuolo di Temistos», ladows «Ladows», delants «Delants», mountainTemistos «Monte Temistos», forest «Foresta», demonicPortal «Portale demoniaco».

## Results

- `flutter test test/models` → +1002 green; `flutter test test/tool test/graphql` → +186 green.
- Registry 46 → 47; the four count pins moved RED-first. Extra check: every dumped document validated against the BE `origin/develop` `src/schema.gql` (47/47 OK, `ListPointsOfInterest` included).
- `grep "PoiType\.\w* *[,)]\|switch.*PoiType" lib`: no exhaustive switch over PoiType; the only hits are the two comparisons in `teleport_destination.dart`.
- Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.
- Formatted one by one (all formatter-clean before): poi_type.dart, teleport_destination.dart, point_of_interest_queries.dart, schema_check_documents.dart, travel_fixtures.dart, poi_type_test.dart, teleport_destination_test.dart, point_of_interest_test.dart, enemy_test.dart and the four pin test files.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Two existing tests used `demonicPortal` as the «unknown» POI type**
- **Found during:** Task 1 GREEN (`test/models/point_of_interest_test.dart` «drops a type name this client does not know (D-08, D-16)» and `test/models/enemy_test.dart` «parses a locations list and drops an unknown name (D-16)» went red: `[city, demonicPortal]` instead of `[city]`).
- **Fix:** their unknown sample became `'moon'`; the rule they pin (unknown name dropped) is unchanged.
- **Files modified:** the two test files (outside `files_modified`). **Commit:** 6d4fd65d

**2. [Rule 1 - Analyzer] Doc comment of placeLabelOf**
- The plan's doc text «<tipo> presso <città>» raised two `unintended_html_in_doc_comment` infos (49). Reworded to «Tipo presso città» per un luogo interno (es. «Rovine presso Talmvere»). **Commit:** 6d4fd65d

### Extra tests
- `ofPlace names the inner place and keeps its point (D-01, D-29)` and `a city without marker gives no destination (D-01)` (split out of the ofCity case, also covers `ofCity(null)`).

## Known Stubs

None. (`placeLabelOf` returns `''` for a POI with no usable type and no city: by contract, `ofPlace` then refuses it.)

## Threat Flags

None: `ListPointsOfInterest` reads world data already covered by T-21-19.

## Self-Check: PASSED
