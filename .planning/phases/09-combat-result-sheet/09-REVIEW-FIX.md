---
phase: 09-combat-result-sheet
fixed: 2026-10-28T00:24:32Z
source: 09-REVIEW.md
review_path: .planning/phases/09-combat-result-sheet/09-REVIEW.md
iteration: 1
fix_scope: all
findings_total: 10
findings_in_scope: 10
fixed_count: 8
skipped_count: 0
not_needed_count: 2
status: all_fixed
---

# Phase 9: Code Review Fix Report

**Fixed at:** 2026-10-28T00:24:32Z
**Source review:** `.planning/phases/09-combat-result-sheet/09-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/09-combat-result-sheet` (no push). Start `ffb4dec`, final HEAD `786c1a5`.

**Summary:**
- Findings in the review: 10 (0 critical, 4 warnings, 6 info)
- Findings in scope: 10 (the orchestrator ruled on every Info item)
- Fixed: 8 (WR-01, WR-03, WR-04, IN-01, IN-02, IN-03, IN-04, IN-05)
- Not needed: 2
  - WR-02: the app is locked to landscape. A defensive clamp was still applied, with a test.
  - IN-06: an accepted fragility, now stated in the class doc.
- Skipped: 0

Every behaviour fix went Red → Green: a failing-test commit (`test(combat): …`), then the fix commit (`fix(combat): …`). IN-06 is a docs-only commit (`docs(combat): …`). Commits use Conventional Commits and plain `git` with explicit paths. They carry no trailers and rewrite no history.

These decisions still hold:
- D-07: no banner on the free Map.
- D-13: no routing hold, and the death sheet opens over the cold-start loader.
- D-19: visuals are still provisional.
- D-20: TDD.

No GraphQL document changed: `lib/graphql/` and `tool/schema_check/` are untouched, the registry stays at 36, and there is no `acknowledgedAt` selection. Cubits stay Flutter-free and never call another cubit. There is no new app chrome and no new blocking loader.

## Gate finale

| Check | Result |
|-------|--------|
| Full `flutter test` (foreground) | **2452 passed, 0 failed** (2432 before, +20 new tests) |
| `flutter analyze` | **52 issues, 0 errors**: unchanged baseline, none in a touched file |
| `dart format --output=none --set-exit-if-changed` on every touched file (none DIRTY) | clean. Each file was clean before its edit and was formatted file by file after it (no directory format) |
| `git diff --name-only origin/develop...HEAD -- lib/graphql tool` | identical to `ffb4dec` (same 6 files); `git diff ffb4dec..HEAD -- lib/graphql tool` is empty |
| Trailers on `origin/develop..HEAD` (`co-authored` / `generated with`) | 0 |
| Final HEAD | `786c1a5` |

## Per-finding table

| ID | Outcome | Commits (test → fix) | Note |
|----|---------|----------------------|------|
| WR-01 | fixed: requires human verification | `ae6a1c4` → `811aaff` | The resubscribe timer runs `refetchPending()` right after `_subscribe()`. `_attempt` still resets on the first live event |
| WR-02 | not_needed (defensive clamp applied) | `6358969` → `c94af65` | The app is locked to landscape (`lib/main.dart:76-79`). A min-constraint clamp keeps the parchment ratio and gives an identical layout in landscape |
| WR-03 | fixed: requires human verification | `0c6e2da` → `194c6a0` | `PendingRefetch { idle, inFlight, done, failed }` in the state. Cold start with `CharacterUnavailable` and nothing to show shows `KGError` with pull-to-refresh |
| WR-04 | fixed | `284e3e4` → `173dcd0` | `QuestResultsCubit.portTimeout = 15 s` on `fetchUnacknowledged` and on every serialised mutation |
| IN-01 | fixed | `5765cfa` → `253aec4` | The pending read is merged in one emit, sorted by `_byResolution` |
| IN-02 | fixed (verified real) | `c08af3a` → `9495d36` | The flag stayed `true` even after release. `WorldMap` ends the drag when the travel progress becomes active |
| IN-03 | fixed: requires human verification | `91015f4` → `3041559` | `suppress` vs `publish` depends only on «sheet ground» (free Map or death in the queue), not on `head`/`showing` |
| IN-04 | fixed | `37870f9` → `5373bed` | `malformed` joins the non-retried set. Per-item parsing is left to 09-12 (see the note below) |
| IN-05 | fixed | `f60e239` → `56b6c7b` | `TransactionOutcomeListener` is mounted in `MainScreen` above `SpellOutcomeListener` and removed from `Shop` |
| IN-06 | not_needed (docs) | — → `786c1a5` | One sentence in the `CharacterCubit` class doc |

## Fixed Issues

### WR-01: No reread after a resubscription

**Files modified:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart`
**Test:** `quest_results_delivery_test.dart`, "a resubscription reads what resolved during the backoff". In `fakeAsync`: a stream error, then a result placed in `FakePendingQuestResults.results` during the backoff, then the clock moves past the backoff.
**RED:** `Expected: ['r-gap']  Actual: []`
**Commits:** `ae6a1c4` (test), `811aaff` (fix)
**Applied fix:** In the `_scheduleResubscribe` timer callback, after `_subscribe()`, the cubit calls `unawaited(refetchPending())`. The single-flight merges it with any refetch already started by `ConnectionRestored`. `_attempt` still resets on the first live event, as the ruling asks.
**Human check:** on device, drop the WS for more than 30 s while a quest resolves. The sheet must appear after the resubscription, without a resume.

### WR-02: Result sheet box on portrait phones

**Verification:** `lib/main.dart:76-79` calls `SystemChrome.setPreferredOrientations([landscapeLeft, landscapeRight])` before `runApp`. No other route changes the orientation; `setPreferredOrientations` appears nowhere else in `lib/`. So a portrait phone is not reachable. iOS `Info.plist` lists portrait orientations, but the Flutter lock wins on phones. The only narrow windows left are iPad multitasking and Android split screen. The finding is therefore **not needed** as a bug.

**Defensive clamp, applied (my call):** the change carries no risk. In landscape `maxHeight * 315/375 < maxWidth`, so `min(...)` returns exactly the old width and height. The existing sheet, presenter and `MainScreen` tests (780×360) stay green. A new test covers the narrow case.

**Files modified:** `lib/shared/components/popup/quest_result_sheet.dart`
**Test:** `quest_result_sheet_test.dart`, "a narrow surface keeps the parchment ratio and the button inside it". On a 360×800 surface it checks that the parchment `CachedSvg` keeps the 315/375 ratio and that the «Continua» rect lies inside it. It also checks that no exception is thrown.
**RED:** `Expected: a numeric value within <0.000001> of <0.84>  Actual: <0.45>`
**Commits:** `6358969` (test), `c94af65` (fix)
**Applied fix:** `sheetWidth = math.min(maxWidth, maxHeight * _aspectRatio)` and `sheetHeight = sheetWidth / _aspectRatio`. The existing `SingleChildScrollView` absorbs the smaller height.

### WR-03: Cold start with `CharacterUnavailable` leaves the loader with no way out

**Files modified:**
- `lib/screens/mainScreen/questResultsCubit/quest_results_state.dart`
- `quest_results_cubit.dart`
- `lib/screens/mainScreen/main_screen.dart`
- `test/.../quest_results_queue_test.dart`: the expected state of one test now includes `pendingRefetch: done`.

**Tests:**
- `quest_results_delivery_test.dart`, group "refetch progress (09-REVIEW WR-03)". It covers:
  - starts idle;
  - a read in flight is `inFlight`;
  - a completed read is `done`;
  - a read retried in silence stays `inFlight`;
  - a read that gives up is `failed`, and a later read is `done`.

  Two existing "not retried / retried in silence" tests now expect `pendingRefetch: failed`.
- `main_screen_test.dart`, group "unavailable character at cold start (09-REVIEW WR-03)":
  - `idle` and `inFlight` keep the `KGLoader`;
  - `done` and `failed` with no sheet show `KGError`, and pull-to-refresh calls `refetchPending()` once and `requestUserRefresh()` once;
  - a death acknowledged (`done`) keeps the loader, because the shell is about to switch to character creation.

**RED:**
- Compile RED on `PendingRefetch`.
- Once the state existed, the behavioural RED: `Expected: no matching candidates  Actual: _TypeWidgetFinder:<Found 1 widget with type "KGLoader">` (done/failed cases).

**Commits:** `0c6e2da` (test), `194c6a0` (fix)

**Applied fix:**
- `enum PendingRefetch { idle, inFlight, done, failed }` in `QuestResultsState`.
- `_performRefetch` emits `inFlight` before its first `await`. That happens synchronously in the same microtask as the `CharacterUnavailable` listener of the presenter, so no error frame flashes before the refetch. At the end it emits `failed` when `silentRetry` calls `onGiveUp`, and `done` otherwise.
- New getter `isSettledWithoutSheets`: still accepting sheets, empty queue, nothing showing, and refetch `done` or `failed`.
- `MainScreen`'s fallback branch is now a private `_ColdStart` widget. It uses `context.select` on `CharacterCubit` (unavailable) and `QuestResultsCubit` (settled). When both are true, it shows the cold-start error widget. Its refresh calls `UserRefreshRequests.requestUserRefresh()`, the shell port already used by `CharacterCubit`, then `QuestResultsCubit.refetchPending()`.
- The error UI is the same `KGError` + `RefreshIndicator` (pull-to-refresh, D-16) as the `MainScreenError` branch. It is not a tap target, to keep the same visual language. Boy Scout: both branches now share `_RetryableError` and `_visibleHeight`.
- The death-over-loader end-to-end test stays green.

**Human check:** on device, force a cold start with a dead character whose result list cannot be read (BE 9.2 down or no network). After the silent retries (about 2 min), the error screen must appear, and pull-to-refresh must retry.

Until 09-12, `NoPendingQuestResults` answers `[]` at once. So a `CharacterUnavailable` cold start now shows the error right after the first read instead of spinning forever.

### WR-04: Ports without a timeout

**Files modified:** `quest_results_cubit.dart`, `lib/repository/quest_result_delivery_ports.dart` (doc comments)
**Tests:** `quest_results_delivery_test.dart`, group "port timeout (09-REVIEW WR-04)". Both tests use `hold` completers that never complete:
- "a read that never answers is retried after the timeout": a second call starts after `portTimeout` + the first backoff. After `silentRetry` gives up, the single-flight is free: state `failed`, and a foreground triggers a new read.
- "a death acknowledgement that never answers fails": `inFlight` changes to `failed` after 15 s, and the sheet stays `showing`, so the button can retry.

**RED:** `Expected: <2>  Actual: <1>` and `Expected: DeathAcknowledgement.failed  Actual: DeathAcknowledgement.inFlight`. The compile RED on `portTimeout` was also observed. The behavioural RED was captured with the constant in place but not yet used.
**Commits:** `284e3e4` (test), `173dcd0` (fix)
**Applied fix:**
- `static const Duration portTimeout = Duration(seconds: 15)`.
- `_pending.fetchUnacknowledged().timeout(portTimeout)` inside `_performRefetch`, and `mutation().timeout(portTimeout)` inside `_serialised`.
- `TimeoutException` is already a failure on both paths: the refetch retries it as transient, a quiet acknowledgement stays pending, and a death acknowledgement becomes `failed`.
- The doc comments of `PendingQuestResults` and `QuestResultAcknowledger` now state that the consumer enforces the timeout.

### IN-01: Refetch accepted one result at a time

**Files modified:** `quest_results_cubit.dart`
**Test:** "a read is queued as one sorted batch (09-REVIEW IN-01)". The port returns `[r-2 (12:01), r-1 (12:00)]`. The distinct non-empty queues emitted must be exactly `[[r-1, r-2]]`.
**RED:** `Expected: [['r-1', 'r-2']]  Actual: [['r-2'], ['r-1', 'r-2']]`
**Commits:** `5765cfa` (test), `253aec4` (fix)
**Applied fix:**
- `_unseen(results)` filters out `acknowledgedAt` and `_isKnown`, and dedups by id inside the batch.
- `_inserted(result)` became `_merged(Iterable)`, sorted with `_byResolution`.
- The batch and the final `pendingRefetch` value go out in a single `emit`.
- Live arrivals and the requeue after an external pop use `_merged([x])`.

### IN-02: `isPawnDragging` stuck when the `Draggable` unmounts mid-drag

**Verification:** in Flutter 3.35, `drag_target.dart:527-537` guards the `onDragEnd` callback of `Draggable` with `if (mounted)`. A pawn swapped out mid-drag therefore never reports the end. The pinning test confirmed this: the flag was still `true` both after the swap and after the gesture was released. So the finding is real, and it was fixed.

The awaiting-aid case does not unmount the pawn: it stays the idle `Draggable` with `maxSimultaneousDrags: 0`. That drag still ends normally on release, and a second test pins it.

**Files modified:** `lib/screens/mainScreen/tabs/map/world_map.dart` (formatter-clean). The DIRTY `character_marker_layer.dart` was not touched.
**Tests:** `world_map_availability_test.dart`, group "pawn drag source removed (09-REVIEW IN-02)":
- "a travel that replaces the dragged pawn ends the drag";
- "an awaited aid keeps the pawn and ends the drag on release".

**RED:** `Expected: false  Actual: <true>` (line 131, right after the travelling character is emitted; it was also stuck after `gesture.up()`)
**Commits:** `c08af3a` (test), `9495d36` (fix)
**Applied fix:**
- A `BlocListener<TravelProgressCubit>` on `_progressCubit` fires when the progress becomes `TravelProgressActive`, which is the exact condition that swaps the idle pawn for the travelling one. It calls `_endPawnDrag()`.
- `_endPawnDrag()` clears `pawnDragChanged(false)` and stops the camera follow. `_handleCharacterDragEnd` reuses it.
- A `CharacterUnavailable` in session does not unmount the layer, because the cubit keeps the last `CharacterLoaded`. So no other listener is needed.

### IN-03: Arrival banner decided with `head == arrival`

**Files modified:** `lib/screens/mainScreen/components/quest_result_presenter.dart`, `lib/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_state.dart`
**Tests:** `quest_result_presenter_test.dart`:
- The old pin "a live arrival behind a queued head gets the banner" encoded the behaviour the ruling rejects. It was rewritten as "a live arrival behind an open sheet on the free map gets no banner (09-REVIEW IN-03)": `suppress('questEnd|result-b')` once, `publish` never.
- New guard test: "a live arrival behind a covered map still gets the banner", where a foreign dialog over the shell still leads to `publish`.

**RED:** `No matching calls. All calls: MockInAppNotificationsCubit.publish(PushEvent(NotificationCategory.questEnd, Missione conclusa, …, result-b))`
**Commits:** `91015f4` (test), `3041559` (fix)
**Applied fix:**
- New `_isSheetGround()`: still accepting sheets, and not covered by a route other than the presenter's own sheet. On top of that, either a death is in the queue, or the Map is free under the routes (`MapAvailabilityState.isFreeBeneathRoutes`, new; `isFree` now builds on it) and travel is `TravelIdle`.
- `_announceArrival` suppresses when `_isSheetGround()` holds and publishes otherwise.
- `_canPresent()` is now `!_isShowingSheet && head != null && _isSheetGround()`. The presentation behaviour is identical: with no sheet showing, the coverage check is the same as before.

**Human check:** on the free Map with a sheet open, resolve a second quest. No «Missione conclusa» banner may appear, and the second sheet must open after «Continua».

### IN-04: `malformed` retried as transient

**Files modified:** `quest_results_cubit.dart`
**Test:** the "a `<failure>` read is not retried" loop now also includes `QuestResultFailure.malformed` (one call, state `failed`).
**RED:** `Expected: <1>  Actual: <8>`
**Commits:** `37870f9` (test), `5373bed` (fix)
**Applied fix:** `_isTransient` excludes `malformed` together with `forbidden`, `unauthenticated` and `notFound`, with a doc line: parsing is deterministic.

**Note for 09-12:** the real `PendingQuestResults` adapter must parse `unacknowledgedQuestResults` **item by item**:
- use `QuestResult.tryFromJson` per element;
- skip the malformed entries, and orphans with `item: null`;
- return the rest.

It must not throw `QuestResultException(malformed)` for the whole list. Otherwise a single bad document hides every pending sheet: the read is now not retried, so `pendingRefetch` becomes `failed` and the user sees no sheet at all. Plan 09-12 needs:
- a RED case in the adapter test: a list with one malformed and one valid item yields the valid one;
- only a list-level shape error (for example `data` not being a list) maps to `malformed`.

### IN-05: `TransactionOutcomeListener` only inside `Shop`

**Files modified:**
- `lib/screens/mainScreen/main_screen.dart`
- `lib/screens/mainScreen/tabs/shop/shop.dart`
- `lib/screens/mainScreen/tabs/shop/components/transaction_outcome_listener.dart` (doc)

**Tests:**
- `main_screen_test.dart`, "a shop refusal answered away from the shop shows the banner (09-REVIEW IN-05)": with the Profile tab visible, a `TransactionError(shopNotInCity)` publishes «Negozio non disponibile» with `dedupKey: 'transaction|shopNotInCity'` once.
- Both `MainScreen` harnesses (`main_screen_test.dart` satchel wiring and `main_screen_quest_results_test.dart`) now provide `MockTransactionCubit` (`TransactionInitial`).

**RED:** `No matching calls (actually, no calls at all).`
**Commits:** `f60e239` (test), `56b6c7b` (fix)
**Applied fix:**
- `TransactionOutcomeListener` wraps `SpellOutcomeListener` inside the `MainScreenLoadData` branch of `_buildScreen`, next to the other outcome listeners.
- `Shop` no longer wraps itself. It keeps its own `BlocListener`, including `_showRefusal`, which hides the bubble when a refusal has a banner.
- Boy Scout: the deep `Scaffold`/`Stack` of the loaded branch moved to `_buildPagesWithSatchel(cities, disabledPages)`, so the extra listener did not add another nesting level.
- The listener file stays in `tabs/shop/components/`. Moving it would only churn the test path.

## Not needed

### WR-02: see above

Portrait is unreachable (`lib/main.dart:76-79`). The defensive clamp was applied with the 360×800 test (`6358969` → `c94af65`).

### IN-06: `_isCharacterGone` for the cubit lifetime

**File:** `lib/screens/mainScreen/characterCubit/character_cubit.dart`
**Reason:** following the ruling, this is an accepted fragility:
- the BE answers FORBIDDEN/NOT_FOUND deterministically;
- one user refresh per cubit lifetime is the intended design;
- `SessionSyncCubit` re-reads `me` on every resume (`session_sync_cubit.dart:80-83`, `refreshUser()`), and the shell re-keys when `currentCharacter` changes.

The class doc already described the behaviour but not why it is accepted. One sentence was added (docs only, no test).
**Commit:** `786c1a5` (`docs(combat): note why a gone character stays gone for the cubit`)

---

_Fixed: 2026-10-28T00:24:32Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
