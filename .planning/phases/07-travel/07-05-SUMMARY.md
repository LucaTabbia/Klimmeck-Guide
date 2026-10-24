---
phase: 07-travel
plan: 05
subsystem: api
tags: [flutter, dart, graphql, travel, repository, notifications, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-01)
    provides: "`TravelPreview.fromJson`, `test/helpers/fixtures/travel_fixtures.dart` (`travelPreviewJson`)"
  - phase: 07-travel (07-03)
    provides: "`TravelFailure`, `TravelException`, `travelFailureFrom` (by `extensions.code`)"
  - phase: 05-notifications-infrastructure
    provides: "`NotificationPermissionGate.ensureRequested()` (D-10 single call site reserved for Phase 7)"
provides:
  - "`TravelRequest { id, poiId }` input model"
  - "Documents `GetServerTime`, `GetTravelPreview($request: TravelRequest!)`, `StartTravel($request: TravelRequest!)`; registry 29 -> 32"
  - "`cities` selects `relatedLore { id description image }`"
  - "`KlimmeckGraphQl.getServerTime()`, `previewTravel(TravelRequest)`, `startTravel(TravelRequest)` with guarded parsing"
  - "`TravelRepository.preview/start`: domain failures, 15 s timeout, permission gate asked once after a successful start (unawaited, errors swallowed)"
  - "`MockTravelRepository` in `test/helpers/mocks.dart`"
affects: [07-07, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repository `_guard<T>` generic wrapper: timeout + OperationException -> domain failure mapping shared by query and mutation"
    - "Fire-and-forget side effect after success via `unawaited(future.then((_) {}, onError: ...))`"

key-files:
  created:
    - lib/models/request/travel_request.dart
    - lib/graphql/queries/travel_queries.dart
    - lib/graphql/queries/server_time_queries.dart
    - lib/graphql/mutations/travel_mutations.dart
    - lib/repository/travel_repository.dart
    - test/models/request/travel_request_test.dart
    - test/graphql/travel_documents_test.dart
    - test/repository/services/graphql/graphql_travel_test.dart
    - test/repository/travel_repository_test.dart
  modified:
    - lib/graphql/queries/city_queries.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/helpers/mocks.dart
    - test/repository/services/push/push_boundaries_test.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The Phase 5 boundary test now pins `lib/repository/travel_repository.dart` as the only `ensureRequested(` caller outside the gate (was: no caller at all)"
  - "`test/helpers/mocks.dart` is not format-clean: the mock was added by hand, never formatted"

patterns-established:
  - "Travel transport errors never leave TravelRepository: every path is a TravelException(TravelFailure)"

requirements-completed: []

# Metrics
duration: 7min
completed: 2026-10-24
---

# Phase 7 Plan 05: Travel GraphQL contract and repository Summary

**`GetServerTime` / `GetTravelPreview` / `StartTravel` documents (registry 32, all `OK` against BE `origin/develop`), the lore image on `cities`, the three `KlimmeckGraphQl` calls with guarded parsing, and `TravelRepository` that maps every rejection by `extensions.code`, times out at 15 s and asks the notification permission only after a confirmed start.**

## Performance

- **Duration:** ~7 min
- **Started:** 2026-10-24T14:26:30Z
- **Completed:** 2026-10-24T14:33:00Z
- **Tasks:** 3
- **Files modified:** 9 created + 5 modified source/test files + 3 planning files

## Accomplishments

- `TravelRequest` (`id` = session character, `poiId` = destination `City.markerLocation.id`), Equatable.
- Three named operations with typed `$request: TravelRequest!`; `cities` gains exactly one line (`image` in `relatedLore`).
- Registry `schemaCheckDocuments` 29 -> 32 (`GetServerTime` after `GetMe`, `GetTravelPreview` after `GetCity`, `StartTravel` after `AcceptQuest`), in the same commit as the documents (Pitfall 12).
- `getServerTime` (non-string -> `FormatException`), `previewTravel` (`_travelPreviewFrom` parsing boundary like `_userFrom`), `startTravel` (`successful != true` or missing payload -> `FormatException('startTravel not successful')`); raw `OperationException` with code preserved; `noCache` verified (two previews hit the link twice).
- `TravelRepository`: `_guard<T>` (15 s timeout -> `timedOut`, `OperationException` -> `travelFailureFrom`, anything else -> `unknown`); `start` calls `_askNotificationPermission()` only after `await _guard(...)` returned, unawaited and with errors swallowed.

## Task Commits

| Task | Name | Commit | Type |
|------|------|--------|------|
| 1 | RED: travel documents, request, registry 32 | `0eae00e` | test |
| 1 | GREEN: travel preview, start and server time documents | `fd057b5` | feat |
| 2 | RED: travel service calls | `ba73ee4` | test |
| 2 | GREEN: travelPreview, startTravel and serverTime calls | `c9883a5` | feat |
| 3 | RED: travel repository (+ `MockTravelRepository`) | `961d430` | test |
| 3 | GREEN: travel repository with the permission prompt | `7d3cf86` | feat |

No refactor commits were needed. Plan metadata commit: see the final `docs(phase-7)` commit.

### RED evidence

- Task 1: compile failure, `lib/models/request/travel_request.dart` / `travel_queries.dart` not found.
- Task 2: compile failure, `getServerTime`/`previewTravel`/`startTravel` not defined on `KlimmeckGraphQl`.
- Task 3: compile failure, `lib/repository/travel_repository.dart` not found.

## Early schema check

`git -C <BE> show origin/develop:src/schema.gql` into the scratchpad, `dump_documents.dart` -> `dumped 32 documents`, `validate_documents.js` exit 0: **32 `OK`, 0 failures** (including `OK GetServerTime.graphql`, `OK GetTravelPreview.graphql`, `OK StartTravel.graphql`, `OK cities.graphql`). The BE working tree was never touched. Binding check remains in 07-11.

## Verification

- Task 1: `flutter test test/models/request/travel_request_test.dart test/graphql test/tool`: 55 tests passed; analyze clean.
- Task 2: `flutter test test/repository/services/graphql`: 101 tests passed; analyze clean; format check exit 0.
- Task 3: `flutter test test/repository`: 538 tests passed; analyze clean on the repository, its test, `mocks.dart` and the boundary test.
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth`: 1239 tests, all passed.
- Acceptance greps: registry entries `^  '` = 32; each new registry key = 1; `relatedLore` + `image` = 1, `city_queries.dart` diff = 1 insertion; document signatures = 1 each; service signatures = 1 each, `startTravel not successful` = 1; `MockTravelRepository` = 1; `ensureRequested()` = 1; `grep -B3 "_askNotificationPermission();" | grep -c "await _guard"` = 1; `defaultTimeout = Duration(seconds: 15)` = 1.
- Format: new files and `graphql.dart`, `schema_check_documents.dart`, `push_boundaries_test.dart` (all measured clean before editing) formatted, 0 changed; `city_queries.dart` and `mocks.dart` hand-edited only.
- 07-VALIDATION.md rows 07-05-01, 07-05-02, 07-05-03 set to ✅ green.

## Decisions Made

- Hanging-gate case tested with a local `_HangingPermissionPort` (status never completes) rather than extending the shared fake; it is a stub of the port, not a mocktail mock, so the "no mock redefinition" rule of `mocks.dart` is respected.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Phase 5 boundary test forbade any `ensureRequested(` caller**
- **Found during:** Task 3 (GREEN run of `test/repository`)
- **Issue:** `test/repository/services/push/push_boundaries_test.dart` "only the gate defines ensureRequested" expected no file under `lib/` other than the gate to contain `ensureRequested(`; the plan's prescribed call site in `TravelRepository` made it fail. Phase 5 D-10 reserved exactly this call site for Phase 7, but the plan did not list the test.
- **Fix:** added `_travelRepository = 'lib/repository/travel_repository.dart'` and changed the assertion to `expect(callers, [_travelRepository])` (test renamed "only the travel repository calls ensureRequested"). The guard stays strict: any other caller still fails. The "Phase 5 surfaces never reach the prompt" test is unchanged.
- **Files modified:** test/repository/services/push/push_boundaries_test.dart
- **Commit:** `7d3cf86`

## Issues Encountered

None besides the deviation above.

## Known Stubs

None. The consumers (`TravelCubit`, shell wiring of `fetchServerTime: graphQl.getServerTime`) arrive in 07-07.

## Threat Flags

None: T-07-05-01 (typed variables, test on `requests.single.variables`), T-07-05-02 (`successful:false` -> `FormatException` -> `unknown`), T-07-05-03 (`_guard`), T-07-05-04 (15 s `fake_async` tests for preview and start), T-07-05-05 (gate only after success; never on preview/rejection/timeout; failing or hanging gate does not affect `start`), T-07-05-06 (registry 32 + early schema check 32 OK) all mitigated as planned.

## Next Phase Readiness

- 07-07 can construct `TravelRepository(graphQl:, permissionGate:)` (gate already provided at the app root) and mock it with `MockTravelRepository`.
- TRAVEL-02 / TRAVEL-03 remain unticked until 07-11.

## Self-Check: PASSED

All 9 created files exist; commits 0eae00e, fd057b5, ba73ee4, c9883a5, 961d430, 7d3cf86 are in `git log`; no commit carries a `Co-Authored-By` or `Generated with` trailer.
