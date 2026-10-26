---
phase: 07-travel
fixed_at: 2026-10-24T15:33:37Z
review_path: .planning/phases/07-travel/07-REVIEW.md
iteration: 1
fix_scope: all
findings_total: 9
findings_in_scope: 9
fixed: 8
skipped: 0
not_needed: 1
status: all_fixed
---

# Phase 7: Code Review Fix Report

**Fixed at:** 2026-10-24T15:33:37Z
**Source review:** `.planning/phases/07-travel/07-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/07-travel` (no push)

**Summary:**
- Findings in the review: 9 (0 critical, 3 warnings, 6 info)
- Findings in scope: 9 (the orchestrator ruled on every Info item)
- Fixed: 8 (WR-01, WR-02, WR-03, IN-01, IN-03, IN-04, IN-05, IN-06)
- Not needed: 1 (IN-02, a deliberate design choice, Pitfall 6)
- Skipped: 0

Every behaviour fix went Red → Green: a failing-test commit (`test(...)`), then the fix commit. Pure refactors and the comment-only change (IN-01, IN-03, IN-05) have no test commit and rely on the existing suites (testing.md exception). Commits use Conventional Commits, plain `git`, no trailers, no history rewriting. No user decision (D-01..D-20) was changed: "Parti"/"Resta" (D-03), the server clock (D-07), the optional silent reread (D-10) and the C1 point order (D-18) all hold.

## Gate after the fixes

| Check | Result |
|-------|--------|
| `flutter test` (full suite) | **1671 passed, 0 failed** (1644 before, +27 new tests) |
| `flutter analyze` | **54 issues, 0 errors**: unchanged baseline, none in a touched file |
| `dart format --output=none --set-exit-if-changed` | clean on every touched file that was clean before; `world_map.dart` and `map_constants.dart` (format-dirty baseline) were hand-edited, never formatted |
| `tool/schema_check` | not run: no GraphQL document touched (`startTravel` still selects `response successful`) |

## Per-finding table

| ID | Outcome | Commits (test → fix) | Note |
|----|---------|----------------------|------|
| WR-01 | fixed | `e8a47fa` → `6c25ea4` | "Resta" disabled, PopScope and a drag guard while `TravelStarting`; the sheet closes itself with `pop()` |
| WR-02 | fixed: requires human verification | `5b4d510` → `d15771d` | Session-scoped `ArrivalRereadLedger`; `TravelProgressCubit.claimArrivalReread()` sets a real cap of 2 per travel |
| WR-03 | fixed: requires human verification | `0175091` → `2f8d79c` | No arrival, reread or ETA from an unsynced clock; preview syncs; ETA filled on the first sync |
| IN-01 | fixed (documented) | — → `dac2520` | POI strict, route tolerant, as before; the contract is now written down |
| IN-02 | not_needed | — | Deliberate (Pitfall 6): no `activeTravel` parameter on `copyWith` |
| IN-03 | fixed | — → `4834469` | Named constants in `MapConstants` |
| IN-04 | fixed | `763064d` → `a3b2444` | `_isSameTravel` uses full `ActiveTravel` equality |
| IN-05 | fixed | — → `0b59f02` | `sealed class TravelQuote` shared by `TravelConfirming` and `TravelStarting` |
| IN-06 | fixed | `daf1fb0` → `dec893c`, `d310bc1` → `f46b5ef` | `successful: false` → `TravelFailure.declined` with its own line; sheet opens only when the preview started |

## Fixed Issues

### WR-01: "Resta" stays active while `startTravel` is in flight

**Files modified:** `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart`, `lib/screens/mainScreen/tabs/map/world_map.dart`
**Tests:** `test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart`: "disables Resta while the start is in flight", "back and barrier cannot dismiss a start in flight" (`Navigator.maybePop`, the path the barrier and system back use), "a start rejection still closes the blocked sheet". `test/screens/mainScreen/tabs/map/world_map_travel_test.dart`: "dragging the sheet down cannot dismiss a start in flight", plus a control "dragging the sheet down dismisses it before the start".
**Commits:** `e8a47fa` (test), `6c25ea4` (fix)
**Applied fix:** In `TravelStarting`, "Resta" gets `onPressed: null` and the content is wrapped in `PopScope(canPop: state is! TravelStarting)`. Two details go beyond the review:
1. The self-close listener now uses `Navigator.pop()` (only while its route is current) instead of `maybePop()`. The listener runs before the `PopScope` rebuilds, so `maybePop` would still see `canPop: false` and the sheet would never close on `TravelStarted`/`TravelFailed`. A mutation run confirmed it: with `maybePop`, two existing tests fail.
2. A drag to the `DraggableScrollableSheet` minimum makes `showModalBottomSheet` call `Navigator.pop` directly, which skips `PopScope`. The map's builder wraps `PaperSheetModal` in a `NotificationListener<DraggableScrollableNotification>` that stops the notification while `TravelStarting`. `PaperSheetModal` (shared) is untouched.

### WR-02: Reread cap of 2 per travel is not enforced across remounts and clock changes

**Files modified:** `lib/screens/mainScreen/tabs/map/travelProgressCubit/arrival_reread_ledger.dart` (new), `travel_progress_cubit.dart`, `travel_progress_state.dart` (doc only), `lib/screens/mainScreen/tabs/map/world_map.dart`, `lib/screens/auth/authenticated_shell.dart`
**Tests:** `travel_progress_cubit_test.dart` adds the group `claimArrivalReread (WR-02)` on `fakeAsync`: nothing while idle or before the first threshold; one claim per threshold, two at most; a remounted map sharing the ledger gets no new reread; a backward resync does not re-arm a claimed threshold; a different travel starts with a fresh budget. `world_map_travel_test.dart` adds "returning to the map in the arriving window adds no reread" and "a backward resync does not reread the same threshold". `authenticated_shell_test.dart` checks that the shell provides the ledger.
**Commits:** `5b4d510` (test), `d15771d` (fix)
**Applied fix:** `arrivalRefetchCount` keeps its meaning (thresholds reached according to the clock). A plain `ArrivalRereadLedger`, provided once per session by `AuthenticatedShell` (`RepositoryProvider`, next to `ServerClockService`), counts the rereads actually requested per travel identity (`startTime`, `endTime`, `to`; a repeated polyline is not a new travel). `TravelProgressCubit` receives it (`rereads:`, optional with a fresh default for unit tests) and exposes `bool claimArrivalReread()`: true only when the reached thresholds exceed the rereads already claimed for that travel. `WorldMap` calls `refreshCharacter()` only when the claim succeeds, both at mount (the overdue-arrival case of 07-09 is kept, within the cap) and on each threshold increase. Red evidence: the new tests first failed to compile (new API). A mutation run (ledger ignoring its budget) then failed 5 of them, which shows they pin the cap.
**Human check:** on device, open the map after `endTime + 5 s`, switch tab and come back within the minute: the BE log should show at most 2 `character` reads for that travel.

### WR-03: Refetch and ETA can be driven by an unsynced (device) clock

**Files modified:** `travel_progress_cubit.dart`, `lib/screens/mainScreen/travelCubit/travel_cubit.dart`, `travel_state.dart`, `travel_confirmation_sheet.dart`
**Tests:** `travel_progress_cubit_test.dart` adds "an unsynced clock decides no arrival and no reread (WR-03)": the ticker stays alive and the first resync decides; the existing stale-offset test now expects `isArriving: false` / count 0 before the resync. `travel_cubit_test.dart` adds the group `unsynced clock (WR-03)`: preview syncs an unsynced clock and leaves `eta`/`previewedAt` null; no extra sync when already synced; the first sync fills the ETA in `TravelConfirming` and in `TravelStarting`; an ETA already computed is never recomputed; `close()` stops listening. `travel_confirmation_sheet_test.dart` adds "keeps only the arrival pending on an unsynced clock" ("Parti" stays enabled).
**Commits:** `0175091` (test), `2f8d79c` (fix)
**Applied fix:** `_snapshot` sets `isArriving: isSynced && progress >= 1` and `arrivalRefetchCount: isSynced ? … : 0`. `_isSettled` no longer needs its own `isSynced` check: an unsynced clock is never "arriving", so the ticker keeps running and `offsetChanges` recomputes as before. The pawn still moves on the provisional clock, as it did before. In `TravelCubit.preview`, `unawaited(_clock.sync())` runs when `!isSynced` (single-flight in the service). `eta`/`previewedAt` are nullable and stay null until a synced `now()` exists. The cubit listens to `offsetChanges` (cancelled in `close()`) and fills a missing ETA once. The sheet shows the existing `…` placeholder for "Arrivo" meanwhile. Red evidence: the progress-cubit tests failed on behaviour (2 failures); the cubit and sheet tests first failed to compile (nullable `eta`).
**Human check:** cold start with the BE slow or offline: the sheet shows distance and duration with "Arrivo …" until the first `serverTime` answer.

### IN-01: Two coordinate helpers, different strictness

**Files modified:** `lib/models/wire_lat_lng.dart`
**Commit:** `dac2520` (docs)
**Applied fix:** Following the ruling, `PointOfInterest` stays strict and the route stays tolerant. Their doc comments now state the contract: `latLngFromWire` is strict because a POI location anchors markers and the character's position, so a broken POI is a data defect that must surface. `tryLatLngFromWire` is tolerant and used only for polyline nodes, so one bad node shortens the route instead of dropping the character. Both use the same C1 order (D-18). The review's alternative (tolerant `PointOfInterest.fromJson`) was not applied. It would silently hide markers and change the Phase 3/6 parsing contract outside this phase's scope.

### IN-03: Magic numbers in `_fitPreviewRoute`

**Files modified:** `lib/screens/mainScreen/tabs/map/utils/map_constants.dart`, `lib/screens/mainScreen/tabs/map/world_map.dart`
**Commit:** `4834469` (refactor)
**Applied fix:** `MapConstants.previewRoutePadding` (48), `previewSheetHeightFraction` (0.5) and `previewSheetGap` (24). Same framing; the existing "fits the camera on the previewed route" test stays green. Both files were hand-edited (format-dirty baseline).

### IN-04: `_isSameTravel` compares only start and end time

**Files modified:** `travel_progress_cubit.dart`
**Tests:** `travel_progress_cubit_test.dart`: "same times towards another destination rebuild the route", "same times on another road rebuild the route" (the existing "an equal travel keeps the measured route and emits nothing" still guards D-06)
**Commits:** `763064d` (test), `a3b2444` (fix)
**Applied fix:** `_isSameTravel(travel) => travel == _travel` uses `ActiveTravel` equality (road, times, duration, `to`). The WR-02 ledger keeps its own narrower identity (`startTime`, `endTime`, `to`), so a re-emitted road for the same travel does not reset the reread budget.

### IN-05: Duplicated field set in `TravelConfirming` / `TravelStarting`

**Files modified:** `travel_state.dart`, `travel_cubit.dart`, `travel_confirmation_sheet.dart`
**Commit:** `0b59f02` (refactor)
**Applied fix:** The change stayed small. `sealed class TravelQuote extends TravelState` holds `destination`, `preview`, `eta`, `previewedAt` and `props`, plus an abstract `withEta`. `TravelConfirming` and `TravelStarting` extend it with `super.` parameters. `TravelStarting.from(confirming)` replaces `_startingFrom`, and the WR-03 ETA fill collapses to one `quote.withEta(...)`. The sheet matches the base (`TravelQuote(:final preview, …)`). Equatable still tells the two leaves apart by runtime type. No new test (behaviour-preserving refactor); the cubit, sheet and map suites stayed green.

### IN-06: `successful: false` surfaced as the generic banner; sheet opened when `preview()` ignored the call

**Files modified:** `lib/repository/services/graphql/graphql.dart`, `lib/repository/travel_repository.dart`, `lib/repository/travel_failure.dart`, `lib/screens/mainScreen/travelCubit/travel_notice.dart` (first pair); `lib/screens/mainScreen/tabs/map/world_map.dart`, `travel_cubit.dart` (doc) (second pair)
**Tests:** `graphql_travel_test.dart`: `startTravel` returns `true`/`false`, `FormatException` only when `successful` is missing or the payload is null. `travel_repository_test.dart`: "an unsuccessful answer fails as declined, no prompt", "a malformed answer fails as unknown, no prompt" (stubs now answer `true`). `travel_notice_test.dart`: the `declined` copy. `travel_cubit_test.dart`: "is previewing as soon as preview() returns". `world_map_travel_test.dart`: "a preview the cubit ignored opens no sheet". The harness `previewTransitions(after:)` mirrors the synchronous transition, and "a preview rejected before the first frame leaves no sheet" now really emits `TravelFailed` + `TravelIdle`.
**Commits:** `daf1fb0` (test) → `dec893c` (fix); `d310bc1` (test) → `f46b5ef` (fix)
**Applied fix:**
1. `KlimmeckGraphQl.startTravel` returns `Future<bool>` (`successful`); `FormatException` is kept for a malformed answer. `TravelRepository.start` throws `TravelException(TravelFailure.declined)` on `false`, outside `_guard`, and asks no permission. New catalogue line under the same title "Viaggio non partito": "Il server ha rifiutato la partenza, riprova" (provisional copy in the `travel_notice.dart` style, D-14/D-19). `TravelOutcomeListener` needs no change.
2. Option chosen: a synchronous state check, not a `bool` return. `preview()` emits `TravelPreviewing` before its first `await` (now documented and pinned by a test). `_handleCharacterDragEnd` returns before `_showTravelConfirmation` when the state did not become `TravelPreviewing`. This kept the `Future<void>` API that the cubit tests await, with no fire-and-forget split.

## Not needed

### IN-02: `CharacterStatus.copyWith` cannot change `activeTravel`
**File:** `lib/models/character/character_status.dart:101`
**Reason:** Deliberate (07-RESEARCH Pitfall 6). A nullable `activeTravel ?? this.activeTravel` parameter could never clear a finished travel, and the `characterUpdated` snapshot is the only writer of `activeTravel` (D-05/D-10, backend as the source of truth). Adding the parameter would create the trap the review describes. No code change, per the orchestrator's ruling.

---

_Fixed: 2026-10-24T15:33:37Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
