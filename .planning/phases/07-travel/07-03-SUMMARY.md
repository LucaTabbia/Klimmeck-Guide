---
phase: 07-travel
plan: 03
subsystem: repository
tags: [flutter, dart, graphql, fake_async, travel, tdd]

# Dependency graph
requires:
  - phase: 03-realtime-character-sync
    provides: "graphQlErrorCode / forbiddenCode / notFoundCode, AppLifecycleEvents.foregrounded"
  - phase: BE Phase 7/8 handoff
    provides: "`serverTime` query (§5), travel rejection codes (BE 08 §2)"
provides:
  - "ServerClockService: now() = device now + RTT-compensated offset, isSynced, offsetChanges, single-flight sync with 10 s timeout, resync on foregrounded (D-07)"
  - "FakeServerClockService: settable now, settable isSynced, advance, syncCalls, resync(serverNow) emitting offsetChanges"
  - "TravelFailure / TravelException / travelFailureFrom by extensions.code only (D-14)"
  - "travelNoticeFor: fixed Italian banner copy, null for unauthenticated"
  - "travelInProgressCode single definition in travel_failure.dart, imported by the quest catalogue"
affects: [07-05, 07-06, 07-07, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Server clock by injection: fetch function + foregrounded stream + DateTime Function() now, no GraphQL document dependency"
    - "Rejection catalogue per mutation family: code constants + failure enum + *FailureFrom + *NoticeFor"

key-files:
  created:
    - lib/repository/services/time/server_clock_service.dart
    - lib/repository/travel_failure.dart
    - lib/screens/mainScreen/travelCubit/travel_notice.dart
    - test/helpers/fakes/fake_server_clock_service.dart
    - test/repository/services/time/server_clock_service_test.dart
    - test/repository/travel_failure_test.dart
    - test/screens/mainScreen/travelCubit/travel_notice_test.dart
  modified:
    - lib/repository/quest_acceptance_failure.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The clock swallows a synchronous throw of the fetch too (fetch called inside the try), keeping the previous offset"
  - "travelInProgressCode lives only in travel_failure.dart; quest_acceptance_failure.dart imports it with `show` (Boy Scout, T-07-03-05)"

patterns-established:
  - "Time-sensitive consumers read ServerClockService.now() and recompute on offsetChanges; tests use FakeServerClockService.resync"

requirements-completed: []

# Metrics
duration: 4min
completed: 2026-10-24
---

# Phase 7 Plan 03: Server clock and travel rejection catalogue Summary

**A silent, RTT-compensated `ServerClockService` (offset from `serverTime`, resync on every resume, `offsetChanges` after each successful sync) with its test fake, plus the `TravelFailure` catalogue mapped by `extensions.code` only and its fixed Italian banner copy.**

## Performance

- **Duration:** ~4 min
- **Started:** 2026-10-24T14:16:00Z
- **Completed:** 2026-10-24T14:20:00Z
- **Tasks:** 2
- **Files modified:** 8 source/test files + 3 planning files

## Accomplishments

- `ServerClockService` (`lib/repository/services/time/`, no Flutter import): offset zero and `isSynced == false` before the first sync; midpoint RTT compensation; failure, synchronous throw and 10 s timeout keep the last offset and never throw; concurrent `sync()` share one fetch; every `foregrounded` event resyncs (device clock change corrected); `offsetChanges` broadcast emits after each successful sync only; `dispose()` cancels the lifecycle subscription and closes the stream.
- `FakeServerClockService` with settable `current`/`isSynced`, `advance`, `syncCalls`, `resync(serverNow)` emitting on `offsetChanges`.
- `TravelFailure` (11 values), `TravelException`, `travelFailureFrom` (codes only; link error without code → `connection`; anything else → `unknown`).
- `travelNoticeFor`: title `Viaggio non partito`, exhaustive switch without `default`, `unauthenticated → null`, no technical token in any line.
- `travelInProgressCode` moved to `travel_failure.dart`; quest acceptance mapping unchanged and green.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | RED: server clock tests + fake | `839f282` | test |
| 1 | GREEN: ServerClockService | `ff083a0` | feat |
| 2 | RED: travel rejections and copy tests | `184002f` | test |
| 2 | GREEN: TravelFailure catalogue + banner copy + code move | `783edb7` | feat |

No refactor commits were needed. Plan metadata commit: see the final `docs(phase-7)` commit.

### RED evidence

- Task 1: `test/repository/services/time/server_clock_service_test.dart:5:8: Error: Error when reading 'lib/repository/services/time/server_clock_service.dart': No such file or directory` (and `Type 'ServerClockService' not found` in the fake).
- Task 2: `test/repository/travel_failure_test.dart:5:8: Error: Error when reading 'lib/repository/travel_failure.dart': No such file or directory` (and `Undefined name 'TravelFailure'`).

## Verification

- `flutter test test/repository/services/time/server_clock_service_test.dart`: 15 tests passed (12 clock + 3 fake).
- `flutter test test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit`: 65 tests passed.
- Quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth`: 1181 tests, all passed.
- `flutter analyze` on every touched file/directory: No issues found.
- `dart format --output=none --set-exit-if-changed` on the 7 new files and on `quest_acceptance_failure.dart` (measured clean before the edit): 0 changed.
- Acceptance greps: `const String travelInProgressCode` exactly once in `lib` (travel_failure.dart); `.message` 0 in travel_failure.dart; `default:` 0 in travel_notice.dart; `package:flutter` 0 in server_clock_service.dart; all the other counts = 1.
- 07-VALIDATION.md rows 07-03-01 and 07-03-02 set to ✅ green; Wave 0 item `fake_server_clock_service.dart` ticked.

## Decisions Made

- Added a test for a synchronously throwing fetch (the plan's note on the `try` placement), so that guarantee is locked.
- Banner lines copied verbatim from the plan table (D-14); the `timedOut` line is split in two adjacent literals by the formatter, same text.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None. Not yet wired by design: 07-05 provides the `serverTime` fetch and the repository, 07-06/07-07 consume the clock, the failure catalogue and `travelNoticeFor`.

## Threat Flags

None: T-07-03-01..05 mitigated and tested (device clock test, timeout + single-flight + failure tests, message-ignored case and token loop, null notice for unauthenticated, single code definition).

## Next Phase Readiness

- 07-05 can build `ServerClockService(fetchServerTime: …, foregrounded: appLifecycleEvents.foregrounded)` and map mutation errors with `travelFailureFrom`.
- TRAVEL-02 / TRAVEL-03 remain unticked until 07-11.

## Self-Check: PASSED

All 7 created files exist; commits 839f282, ff083a0, 184002f, 783edb7 are in `git log`; no commit carries a `Co-Authored-By` or `Generated with` trailer.
