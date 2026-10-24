---
phase: 07-travel
plan: 07
subsystem: ui-state
tags: [flutter, dart, bloc, cubit, travel, listener, provider, fake_async, tdd]

# Dependency graph
requires:
  - phase: 07-travel (07-01)
    provides: "`TravelPreview`, `CharacterStatus.activeTravel`, `travel_fixtures.dart` (`travelPreviewJson`, `travelCityJson`, `travellingCharacterJson`, `activeTravelJson`)"
  - phase: 07-travel (07-03)
    provides: "`TravelFailure` / `TravelException`, `travelNoticeFor`, `ServerClockService` + `FakeServerClockService`"
  - phase: 07-travel (07-04)
    provides: "`MapFocusCubit` in the shell (providers order), `KlimmeckGraphQl.getServerTime`"
  - phase: 07-travel (07-05)
    provides: "`TravelRepository.preview / start`, `MockTravelRepository`"
provides:
  - "`TravelCubit.preview / start / cancel / reset` with states `TravelIdle`, `TravelPreviewing`, `TravelConfirming`, `TravelStarting`, `TravelStarted`, `TravelFailed` + `TravelStage`"
  - "`TravelOutcomeListener`: banner by code (dedup `travel|<failure>|<cityId>`), reset after failures, settle of `TravelStarted` on `activeTravel`"
  - "Shell providers: `RepositoryProvider<ServerClockService>(lazy: false)` synced at creation and on resume, `BlocProvider<TravelCubit>` with `TravelRepository` + root `NotificationPermissionGate`"
  - "`MockTravelCubit` in `test/helpers/mocks.dart`"
affects: [07-08, 07-09, 07-10, 07-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Request token (`_previewToken`) invalidated by `preview` and `cancel`: a late answer is dropped even when the new state equals the old one"
    - "Session listener with two BlocListeners (cubit outcome + CharacterCubit edge) to settle a mutation on the subscription, never on the mutation response"

key-files:
  created:
    - lib/screens/mainScreen/travelCubit/travel_cubit.dart
    - lib/screens/mainScreen/travelCubit/travel_state.dart
    - lib/screens/mainScreen/components/travel_outcome_listener.dart
    - test/screens/mainScreen/travelCubit/travel_cubit_test.dart
    - test/screens/mainScreen/components/travel_outcome_listener_test.dart
  modified:
    - lib/screens/mainScreen/main_screen.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/helpers/mocks.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "TravelCubit takes ServerClockService directly (Cubit -> Service): pure, fakeable time source used only for now() to compute eta = serverNow + preview.duration (C4)"
  - "start() returns early when the cubit was closed during the await, so no hold timer is armed after close()"
  - "An unexpected (non-TravelException) error maps to TravelFailure.unknown for both preview and start"

patterns-established:
  - "Mutation slices with a confirmation step: idle -> previewing -> confirming -> starting -> started/failed, outcome handled by a session-level listener"

requirements-completed: []

# Metrics
duration: 6min
completed: 2026-10-24
---

# Phase 7 Plan 07: Travel confirmation flow Summary

**`TravelCubit` drives preview -> "Parti"/"Resta" -> start with a request-token guard against late answers, a double-tap guard and a 30 s hold; `TravelOutcomeListener` publishes rejections as Phase 5 domain banners by code and settles the flow only when `activeTravel` shows up on the character; the shell provides a session `ServerClockService` (synced at creation and on resume) and the `TravelCubit`, both closed with the session.**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-10-24T14:39:00Z
- **Completed:** 2026-10-24T14:45:00Z
- **Tasks:** 2
- **Files modified:** 5 created + 5 modified (+ 3 planning files)

## Accomplishments

- Sealed `TravelState` (`part of` the cubit), Equatable `final class` states; `TravelConfirming`/`TravelStarting` carry `destination`, `preview`, `eta`, `previewedAt`.
- `preview(characterId, destination)`: ignored unless idle and the city has a `markerLocation`; emits `TravelPreviewing(destination)` immediately, then `TravelConfirming` with `eta = clock.now() + preview.duration` (ms) or `TravelFailed(stage: preview)`.
- `_previewToken` incremented by every `preview` and every `cancel`: answers of a cancelled or replaced request are dropped, including the case of an equal `TravelPreviewing` state (test "the token drops the answer of a replaced equal request").
- `start()` only from `TravelConfirming`, moves to `TravelStarting` before the await (double "Parti" = one request), then `TravelStarted(destination, preview)` with no travel state built from the response (D-05); a `Timer(defaultStartedHold = 30 s)` returns to idle if `activeTravel` never arrives; `close()` cancels it.
- `cancel()` only from previewing/confirming; `reset()` no-op while starting.
- `TravelOutcomeListener` (MultiBlocListener): `TravelFailed` -> `travelNoticeFor` (no banner for `unauthenticated`) + `reset()`; `TravelStarted` -> reset at once if the character already travels; `CharacterCubit` edge "not travelling -> travelling" -> reset only if the flow is `TravelStarted`.
- `MainScreen` mounts it inside `QuestAcceptanceOutcomeListener`, so a rejection answered on another tab still shows the banner.
- `AuthenticatedShell`: `RepositoryProvider<ServerClockService>(lazy: false)` built from `graphQl.getServerTime` + `AppLifecycleEvents.foregrounded`, `unawaited(clock.sync())` at creation, disposed with the shell; `BlocProvider<TravelCubit>` with `TravelRepository(graphQl, context.read<NotificationPermissionGate>())`.

## Task Commits

| # | Task | Commit | Type |
|---|------|--------|------|
| 1 | RED: travel confirmation flow tests + `MockTravelCubit` | `47e534c` | test |
| 1 | GREEN: travel confirmation cubit | `dccf291` | feat |
| 2 | RED: outcome listener, MainScreen and shell wiring tests | `60d3f29` | test |
| 2 | GREEN: publish travel rejections and wire the travel cubit | `ce7df75` | feat |

## Verification

- `flutter test test/screens/mainScreen/travelCubit` -> 35 passed (23 new cubit tests + 12 notice tests).
- `flutter test test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart test/screens/auth` -> 201 passed.
- `flutter analyze` on all touched lib/test files -> No issues found.
- `dart format --output=none --set-exit-if-changed` on the new files and on the format-clean touched files -> exit 0 (`test/helpers/mocks.dart` is not formatter-clean: hand-edited only).
- Acceptance greps: all as specified (`_previewToken` 4, `DateTime.now` 0, `package:flutter/` 0, `dedupKey: 'travel|` 1, `TravelOutcomeListener(` 1, `RepositoryProvider<ServerClockService>` 1 with `lazy: false` on the next line, `BlocProvider<TravelCubit>` 1, `context.read<NotificationPermissionGate>()` 1, `fetchServerTime: graphQl.getServerTime` 1).
- Plan-end quick run `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` -> 1293 passed.

## Architecture note

`TravelCubit` depends on `ServerClockService` directly (Cubit -> Service, not through a repository). This is deliberate (checker INFO 4): the clock is a pure, fakeable time source and the cubit only calls `now()` to compute `eta = serverNow + preview.duration` (sanctioned C4: arithmetic on server values, BE handoff §4). The network sync of the clock is owned by the shell provider, never by the cubit. The cubit never reads `DateTime.now()`, never shows server text (only `travelNoticeFor` in the listener), never calls another cubit (the listener publishes the banner and resets) and never builds travel state from `startTravel`'s `CommonResponse`.

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Hold timer could be armed after `close()`**
- **Found during:** Task 1 GREEN (test "drops a late start answer after close")
- **Issue:** with the plan's shape, a `startTravel` answer arriving after `close()` would skip the emit (SafeEmit) but still arm the 30 s `Timer`, leaking it past the session.
- **Fix:** `start()` returns early when `isClosed` after the await.
- **Files modified:** lib/screens/mainScreen/travelCubit/travel_cubit.dart
- **Commit:** `dccf291`

### Notes

- The plan's `catch (_)` -> `unknown` was applied to `start()` too (not only `preview`), so the UI never sees an unexpected exception from either action; covered by the preview test, same code path for start.

## Issues Encountered

None.

## Known Stubs

None.

## Threat Flags

None: no new surface beyond the plan's threat model (T-07-07-01..06 mitigated and tested).

## Next Phase Readiness

- 07-08 (sheet) can read `TravelPreviewing` / `TravelConfirming` / `TravelStarting` and call `start()` / `cancel()`; `previewedAt` decides "oggi"/"domani" in the ETA.
- 07-09/07-10 (map) can call `preview(characterId:, destination:)` on drop and keep the preview route while `TravelStarted` (Pitfall 4).

## Self-Check: PASSED
