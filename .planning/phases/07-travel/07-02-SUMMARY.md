---
phase: 07-travel
plan: 02
subsystem: models
tags: [flutter, dart, latlong2, intl, equatable, travel, tdd]

# Dependency graph
requires:
  - phase: 07-travel plan 01
    provides: "TravelPath / ActiveTravel / TravelPreview, latLngFromWire (C1)"
provides:
  - "TravelRoute.of / pointAt / splitAt: planar length interpolation along the polyline (D-06, D-07)"
  - "travelProgress({serverNow, startTime, durationMs}): server-time progress, duration <= 0 means arrived"
  - "formatTravelDuration / formatTravelDistance / formatArrival / travelArrivingLabel (D-03, D-08, D-10)"
  - "travelDestinationFor: drag destination rule, same city = silent spring back (D-01, D-02)"
affects: [07-06, 07-08, 07-09, 07-10, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Route geometry measured once (cumulative planar lengths on Epsg4326 degrees), never latlong2.Distance"
    - "Time-dependent pure functions take serverNow as an argument; no DateTime.now in lib/models/travel"
    - "Italian domain strings as top-level pure functions in lib/models (intl DateFormat numeric patterns only)"

key-files:
  created:
    - lib/models/travel/travel_route.dart
    - lib/models/travel/travel_time_format.dart
    - lib/models/travel/travel_destination.dart
    - test/models/travel/travel_route_test.dart
    - test/models/travel/travel_time_format_test.dart
    - test/models/travel/travel_destination_test.dart
  modified:
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "_lerp clamps t to the segment ends so a vertex hit returns the exact vertex: splitAt never duplicates a point by floating-point noise"
  - "formatTravelDuration rounds up to the minute, so a positive remaining time never reads '0 min'"
  - "formatArrival compares calendar dates built with DateTime(y, m, d + 1), DST safe, never Duration(days: 1)"

patterns-established:
  - "Travel strings: formatTravelDuration / formatTravelDistance / formatArrival are the only formatters for the sheet and the pawn label"

requirements-completed: []

# Metrics
duration: 2min
completed: 2026-10-24
---

# Phase 7 Plan 02: Route geometry, server-time progress and Italian travel strings Summary

**Pure, Flutter-free `TravelRoute` (length-based interpolation and travelled/remaining split), `travelProgress` driven only by the server clock, Italian duration/distance/arrival formatters and the `travelDestinationFor` drag rule, all written test-first.**

## Performance

- **Duration:** ~2 min (code); plus docs
- **Started:** 2026-10-24T14:13:50Z
- **Completed:** 2026-10-24T14:15:23Z
- **Tasks:** 2
- **Files modified:** 6 source/test files + 3 planning files

## Accomplishments

- `TravelRoute.of` collapses consecutive duplicates, measures cumulative planar lengths (`math.sqrt` of degree deltas, no `latlong2.Distance`), exposes unmodifiable `points`/`cumulative`, Equatable on `points`.
- `pointAt` clamps progress, returns `null` on an empty route and the only point on a zero-length route; `splitAt` returns both halves sharing the current point, with no duplicated vertex.
- `travelProgress` = clamp(elapsed / duration, 0, 1), `durationMs <= 0` → 1; no `DateTime.now` anywhere under `lib/models/travel`.
- `formatTravelDuration` ('40 min', '2 h 40 min', '1 g 3 h', ceil to the minute, negatives → '0 min'), `formatTravelDistance` ('15,8 km', '204 km'), `formatArrival` ('oggi alle', 'domani alle', 'il dd/MM alle', local time), `travelArrivingLabel = 'In arrivo…'`.
- `travelDestinationFor`: another city with a marker is the destination; the current city, no target or a city without marker give `null`; an unknown location leaves the judgement to the BE.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | RED: route interpolation and travelProgress tests | `93583b5` | test |
| 1 | GREEN: TravelRoute + travelProgress | `e89baa5` | feat |
| 2 | RED: travel strings and destination tests | `b1a6ef8` | test |
| 2 | GREEN: Italian formatters + travelDestinationFor | `a9f47da` | feat |
| 2 | REFACTOR: rename local `now` to `serverLocal` in formatArrival | `81bd30a` | refactor |

Plan metadata commit: see the final `docs(phase-7)` commit.

### RED evidence

- Task 1: `test/models/travel/travel_route_test.dart:2:8: Error: Error when reading 'lib/models/travel/travel_route.dart': No such file or directory`
- Task 2: `test/models/travel/travel_time_format_test.dart:2:8: Error: Error when reading 'lib/models/travel/travel_time_format.dart': No such file or directory` (and `Method not found: 'formatTravelDuration'`)

## Verification

- `flutter test test/models/travel`: all passed (17 route tests + 23 format tests + 5 destination tests, plus the 07-01 model tests).
- `TZ=America/Los_Angeles flutter test test/models/travel/travel_time_format_test.dart`: all passed (local `DateTime` fixtures are timezone independent).
- `flutter analyze lib/models/travel test/models/travel`: No issues found.
- `dart format --output=none --set-exit-if-changed` on the 6 new files: 0 changed.
- `grep -F "DateTime.now"` / `Distance(` / `package:flutter` / `initializeDateFormatting` under `lib/models/travel`: none.
- 07-VALIDATION.md rows 07-02-01 and 07-02-02 set to ✅ green.

## Decisions Made

- `_lerp` returns the exact segment end when `t >= 1` (and the start when `t <= 0`), so `splitAt` on a vertex compares equal and never emits a duplicate point.
- Named constants `_minutesPerHour`, `_minutesPerDay`, `_wholeKmThreshold` instead of magic numbers (Clean Code).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Acceptance grep false positive] Renamed `now` to `serverLocal` in `formatArrival`**
- **Found during:** Task 2
- **Issue:** the acceptance check `grep -c "DateTime.now"` is a regex (`.` matches any character) and matched `DateTime(now.year, …)`, reporting 2 although the file never calls `DateTime.now()`.
- **Fix:** renamed the local variable to `serverLocal` (clearer, too); behaviour unchanged, tests green, format clean.
- **Files modified:** lib/models/travel/travel_time_format.dart
- **Commit:** `81bd30a`

## Issues Encountered

None.

## Known Stubs

None. The functions are not wired yet by design: plans 07-06 (progress cubit), 07-08 (sheet, route layer) and 07-09/07-10 (map) consume them.

## Threat Flags

None: T-07-02-01..03 mitigated and tested (degenerate routes, duration <= 0, server-time only, same-city destination), T-07-02-04 accepted.

## Next Phase Readiness

- 07-06 can compute progress with `travelProgress` + `TravelRoute.pointAt`; 07-08 can render with `splitAt` and the formatters; 07-09/07-10 can resolve drops with `travelDestinationFor`.
- TRAVEL-02 / TRAVEL-03 remain unticked until 07-11.

## Self-Check: PASSED

All 6 created files exist; commits 93583b5, e89baa5, b1a6ef8, a9f47da, 81bd30a are in `git log`; no commit carries a `Co-Authored-By` or `Generated with` trailer.
