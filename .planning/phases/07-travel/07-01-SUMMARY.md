---
phase: 07-travel
plan: 01
subsystem: models
tags: [flutter, dart, latlong2, equatable, graphql, travel]

# Dependency graph
requires:
  - phase: BE Phase 8 (travel lifecycle, TRAVEL-01)
    provides: "`status.activeTravel { road { coordinates distance } startTime endTime duration to }` on BE develop (PR #11/#12)"
  - phase: 03-realtime-character-sync
    provides: "`CharacterFragment.fullFields` shared by `character` and `characterUpdated`"
provides:
  - "latLngFromWire / tryLatLngFromWire: one wire point order for POIs and routes (C1)"
  - "Flutter-free TravelPath, ActiveTravel (tryFromJson parse boundary), TravelPreview"
  - "CharacterStatus.activeTravel parsed from every character payload"
  - "character fragment selects activeTravel (bootstrap, silent refresh, live)"
  - "test/helpers/fixtures/travel_fixtures.dart for every later Phase 7 plan"
  - "planning docs and ui-ux rule file without any travel cost (D-03, C3)"
affects: [07-02, 07-05, 07-06, 07-07, 07-08, 07-09, 07-10, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Wire point helper shared by every model that reads [a, b] coordinates"
    - "Defensive parse boundary (tryFromJson → null) for server data nested in the character"
    - "copyWith exposes no parameter for server-only fields (activeTravel)"

key-files:
  created:
    - lib/models/wire_lat_lng.dart
    - lib/models/travel/travel_path.dart
    - lib/models/travel/active_travel.dart
    - lib/models/travel/travel_preview.dart
    - test/helpers/fixtures/travel_fixtures.dart
    - test/models/wire_lat_lng_test.dart
    - test/models/point_of_interest_test.dart
    - test/models/travel/travel_path_test.dart
    - test/models/travel/active_travel_test.dart
    - test/models/travel/travel_preview_test.dart
    - test/models/character/character_status_test.dart
  modified:
    - lib/models/point_of_interest.dart
    - lib/models/character/character_status.dart
    - lib/graphql/fragments/character_fragment.dart
    - test/graphql/character_fragment_test.dart
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - docs/rules/ui-ux.md

key-decisions:
  - "Polyline points and POI locations go through the same latLngFromWire order, no swap (D-18 C1)"
  - "A malformed activeTravel parses as null and malformed route points are dropped: one bad travel never blanks the character (T-07-01-01)"
  - "activeTravel.to stays a plain String id; assets.pet is never selected (D-18 C2, BE handoff 11 b)"
  - "docs/rules/ui-ux.md travel confirmation rewritten as a parchment sheet with no cost, authorised by user decision D-03"

patterns-established:
  - "Wire coordinates: always latLngFromWire / tryLatLngFromWire, never an inline LatLng(json[0], json[1])"
  - "Travel fixtures: top-level functions with named defaults whose route endpoints equal the POI wires (C1)"

requirements-completed: []

# Metrics
duration: 5min
completed: 2026-10-24
---

# Phase 7 Plan 01: Travel models, wire points and no-cost amendment Summary

**One wire→LatLng order shared by POIs and travel routes, Flutter-free `TravelPath`/`ActiveTravel`/`TravelPreview`, a defensively parsed `CharacterStatus.activeTravel` selected by the character fragment, and planning docs that no longer promise a travel cost.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-10-24T14:07:00Z
- **Completed:** 2026-10-24T14:12:00Z
- **Tasks:** 3
- **Files modified:** 20

## Accomplishments

- PROJECT, REQUIREMENTS (TRAVEL-01 note, TRAVEL-02/03 amendments, footer), ROADMAP Phase 7 (criterion 1 amended, discuss decision resolved, UI hint no) and `docs/rules/ui-ux.md` describe the parchment confirmation sheet without cost; the stale duplicate TRAVEL-02 open question is gone from STATE.md.
- `latLngFromWire` replaces the inline `LatLng` in `PointOfInterest.fromJson`; `tryLatLngFromWire` drops malformed and out-of-range points (no `LatLng` assert can trip).
- `TravelPath` (unmodifiable points, distance), `ActiveTravel` (road, UTC dates, duration in ms, `to` as `String`, `tryFromJson`), `TravelPreview` (distance, duration, road).
- `CharacterStatus.activeTravel` (optional constructor parameter, `tryFromJson`, `toJson`, props; `copyWith` keeps it without exposing a parameter) and the fragment block `activeTravel { road { coordinates distance } startTime endTime duration to }` (10 added lines, hand edit).
- Travel fixtures (`departureWire`, `destinationWire`, `travelPathJson`, `activeTravelJson`, `travelPreviewJson`, `travellingCharacterJson`, `travelCityJson`) ready for the later plans.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | No-cost travel confirmation in docs and ui-ux rule file | `6c9e66b` | docs |
| 2 | RED: travel models and wire points tests + fixtures | `090d058` | test |
| 2 | GREEN: shared wire helper and travel models | `174362c` | feat |
| 3 | RED: activeTravel on the character tests | `6ac88c1` | test |
| 3 | GREEN: activeTravel on CharacterStatus and in the fragment | `9861d46` | feat |

No refactor commits were needed. Plan metadata commit: see the final `docs(phase-7)` commit.

### RED evidence

- Task 2: `test/models/wire_lat_lng_test.dart:2:8: Error: Error when reading 'lib/models/wire_lat_lng.dart': No such file or directory` (same for `travel_preview.dart`, `travel_path.dart`, `active_travel.dart`). `point_of_interest_test.dart` was already green: it is a characterisation test locking the unchanged POI behaviour before the refactor to `latLngFromWire`.
- Task 3: `character_status_test.dart:21:19: Error: The getter 'activeTravel' isn't defined for the type 'CharacterStatus'.` and `Expected: contains 'activeTravel { road { coordinates distance } startTime endTime duration to }'` in `character_fragment_test.dart` (the new `pet` and `characterUpdated` parse tests passed already, as guards).

## Verification

- `flutter test test/models/wire_lat_lng_test.dart test/models/point_of_interest_test.dart test/models/travel`: 32 tests, all passed.
- `flutter test test/models/character test/graphql test/repository/services/graphql test/screens/mainScreen/characterCubit`: 163 tests, all passed.
- Quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth`: 1096 tests, all passed.
- `flutter analyze` on every touched Dart file/directory: No issues found.
- `dart format --output=none --set-exit-if-changed` on the 11 Task 2 files plus `character_status.dart`, `character_status_test.dart`, `character_fragment_test.dart` (measured clean before the edit): 0 changed. `character_fragment.dart` (DIRTY) hand-edited only; `git diff --stat develop...HEAD` on it: `10 insertions(+)`, no deletion.
- No `package:flutter` import under `lib/models/`.
- No REQUIREMENTS checkbox ticked, traceability row `| TRAVEL-01 through TRAVEL-04 | TBD` unchanged.
- 07-VALIDATION.md rows 07-01-01/02/03 set to ✅ green; Wave 0 item `travel_fixtures.dart` ticked.

## Decisions Made

- The `docs/rules/ui-ux.md` change (travel confirmation = parchment bottom sheet, never `AlertDialog`, backend distance/duration/ETA, no cost) is authorised by the user decision 07-CONTEXT D-03 (CLAUDE.md: rule files change only with the user's word).
- `TravelPreview.duration` got a `/// Millisecondi.` doc comment for symmetry with `ActiveTravel.duration` (no behaviour).

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. `activeTravel` is parsed but not yet rendered: the renderer, cubits and map wiring are the scope of plans 07-02..07-10 by design.

## Threat Flags

None: no new endpoint or trust boundary beyond the plan's threat model (T-07-01-01..05 mitigated and tested).

## Next Phase Readiness

- 07-02 (route geometry) and 07-05/06/07 can import `TravelPath`, `ActiveTravel`, `TravelPreview` and the travel fixtures.
- TRAVEL-01 remains unticked until 07-11.

## Self-Check: PASSED

All 11 created files exist; commits 6c9e66b, 090d058, 174362c, 6ac88c1, 9861d46 are in `git log`; no commit carries a `Co-Authored-By` or `Generated with` trailer.
