---
phase: 07-travel
plan: 06
subsystem: ui-state
tags: [flutter, dart, bloc, cubit, travel, map, fake_async, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-01)
    provides: "`ActiveTravel`, `TravelPath`, `test/helpers/fixtures/travel_fixtures.dart` (`activeTravelJson`, `travelPathJson`)"
  - phase: 07-travel (07-02)
    provides: "`TravelRoute.of / pointAt / splitAt`, top-level `travelProgress` (duration <= 0 -> 1)"
  - phase: 07-travel (07-03)
    provides: "`ServerClockService { now(), isSynced, offsetChanges }`, `FakeServerClockService` with `advance` / `resync`"
provides:
  - "`TravelProgressCubit.follow(ActiveTravel?)`: route measured once per travel (`startTime` + `endTime` memo), snapshot = pure function of `(activeTravel, serverNow)`"
  - "`TravelProgressIdle` / `TravelProgressActive { travel, route, position, travelled, remaining, remainingTime, isArriving, arrivalRefetchCount }`"
  - "1 s ticker (`defaultTick`), arrival hold on the last point, `arrivalRefetchDelays` = [+5 s, +65 s] (count 0..2)"
  - "Ticker stops only when settled on a synced clock; every `offsetChanges` event recomputes and restarts it; `close()` cancels timer and subscription"
affects: [07-09, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Single `_refresh()` for tick, new travel and offset change: emit snapshot, stop when settled, else `_timer ??= Timer.periodic`"
    - "fake_async cubit tests advancing BOTH the fake server clock and fake time (`step` helper)"

key-files:
  created:
    - lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart
    - lib/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_state.dart
    - test/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit_test.dart
  modified:
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "TravelProgressCubit takes ServerClockService directly (Cubit -> Service): it is a pure, fakeable time source and the cubit touches only now() / isSynced / offsetChanges, no I/O"
  - "follow(null) while idle is an explicit early return (`_travel == null`): bloc's emit does not dedup the very first emission equal to the initial state"
  - "On an offset change the running periodic timer is kept (`??=`) instead of cancelled and recreated: same observable behaviour, one code path"

patterns-established:
  - "Renderer cubits never complete server-side work: the state leaves Active only via follow(null) fed by the backend event"

requirements-completed: []

# Metrics
duration: 5min
completed: 2026-10-24
---

# Phase 7 Plan 06: TravelProgressCubit Summary

**`TravelProgressCubit` turns `(activeTravel, ServerClockService.now())` into pawn position, travelled/remaining polylines and remaining time on a 1 s ticker, measures the route once per travel, holds "In arrivo…" on the last point until `follow(null)`, raises at most two silent reread requests and stops ticking only when nothing can change on a synced clock, recovering on every offset correction.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-10-24T14:33:30Z
- **Completed:** 2026-10-24T14:38:30Z
- **Tasks:** 2
- **Files modified:** 3 created + 3 planning files

## Accomplishments

- Sealed `TravelProgressState` (`TravelProgressIdle`, `TravelProgressActive`), Equatable, `part of` the cubit.
- `follow(travel)`: memo on `startTime` + `endTime` (D-06, the polyline repeated by every `characterUpdated` is not re-measured, same `TravelRoute` instance); different travel rebuilds the route; `follow(null)` cancels the timer and returns to idle (D-10).
- Snapshot: `travelProgress` on server time (D-07), `route.pointAt` / `splitAt`, `remainingTime = endTime - serverNow` clamped at zero, `isArriving = progress >= 1`, `arrivalRefetchCount` = delays already elapsed past `endTime` (C4: arithmetic on server values only, nothing from distance or speed).
- Degenerate travels: empty polyline -> `position == null`, empty splits, no throw; `duration: 0` -> arriving immediately.
- Ticker: `Timer.periodic(1 s)`, Equatable dedup means an unchanged server now emits nothing; settled = `_clock.isSynced && isArriving && count == 2` -> timer stopped (an `endTime` 3 days in the past settles on the first state with no timer).
- `offsetChanges.listen` in the constructor: recompute + restart the ticker; while idle nothing happens; `close()` cancels timer and subscription.

## Task Commits

| # | Task | Commit | Type |
|---|------|--------|------|
| 1 | RED: travel progress state tests | `30e26dc` | test |
| 1 | GREEN: derive the pawn position from the active travel | `6056441` | feat |
| 2 | RED: ticker, arrival, refetch, resync tests | `545f594` | test |
| 2 | GREEN: tick on server time and hold at arrival | `e7d2394` | feat |

## Verification

- `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit` -> 23 tests passed (11 for Task 1, 12 for Task 2).
- `flutter analyze lib/screens/mainScreen/tabs/map/travelProgressCubit test/screens/mainScreen/tabs/map/travelProgressCubit` -> No issues found.
- `dart format --output=none --set-exit-if-changed` on the three new files -> exit 0.
- Acceptance greps: `DateTime.now` 0, `package:flutter/` 0, `offsetChanges.listen` 1, `_clock.isSynced` 1, `Future<void> close()` 1, `defaultTick` 1, `seconds: 65` within `-A2` 1; test file: `kill` 1, `server time` 1, `pendingTimers` 13, `resync` 8.
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` -> 1262 passed.

## Architecture note

The cubit depends on `ServerClockService` directly (Cubit -> Service, not through a repository). This is deliberate (checker INFO 4): the clock is a pure, fakeable time source and the cubit uses only `now()`, `isSynced` and `offsetChanges`; the `serverTime` network sync stays inside the service and is never triggered by the cubit. The cubit never reads `DateTime.now()`, never calls another cubit (07-09 feeds it through a `BlocListener<CharacterCubit>` inside `WorldMap`) and never completes a travel.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `follow(null)` while idle emitted `TravelProgressIdle`**
- **Found during:** Task 1 GREEN
- **Issue:** the plan relied on SafeEmit + Equatable dedup, but `Cubit.emit` lets the first emission through even when equal to the initial state, so the `blocTest` "follow(null) while idle emits nothing" failed.
- **Fix:** `_stopFollowing()` returns early when `_travel == null`.
- **Files modified:** travel_progress_cubit.dart
- **Commit:** `6056441`

### Structural simplifications (behaviour as planned)

- The plan's `_onTick` / `_restartTimer` pair is one `_refresh()` (emit, stop if settled, else `_timer ??= Timer.periodic(...)`), used by the tick, `follow` and `_onOffsetChanged`. On an offset change an already running ticker is kept instead of cancelled and recreated; a stopped ticker is restarted. All `resync` tests (stale unsynced offset, settled-then-resync) pass with this shape.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None: no new surface beyond the plan's threat model (T-07-06-01..06 all mitigated and tested).

## Next Phase Readiness

- 07-09 can provide `TravelProgressCubit(clock: <ServerClockService>)` inside `WorldMap`, feed it `character.status.activeTravel` via `BlocListener<CharacterCubit>`, and reread the character silently on every `arrivalRefetchCount` increment.

## Self-Check: PASSED
