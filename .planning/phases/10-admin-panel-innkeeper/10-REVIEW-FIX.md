---
phase: 10-admin-panel-innkeeper
fixed: 2026-10-29T18:42:04Z
source: 10-REVIEW.md
review_path: .planning/phases/10-admin-panel-innkeeper/10-REVIEW.md
iteration: 1
fix_scope: all
findings_total: 9
findings_in_scope: 9
fixed_count: 9
skipped_count: 0
not_needed_count: 0
status: all_fixed
---

# Phase 10: Code Review Fix Report

**Fixed at:** 2026-10-29T18:42:04Z
**Source review:** `.planning/phases/10-admin-panel-innkeeper/10-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/10-admin-panel` (no push). Start `7333881`, final HEAD `ddaa970`.

**Summary:**
- Findings in the review: 9 (0 critical, 3 warnings, 6 info)
- Findings in scope: 9 (the orchestrator ruled on every Info item)
- Fixed: 9 (WR-01, WR-02, WR-03, IN-01, IN-02, IN-03, IN-04, IN-05, IN-06)
- Not needed: 0
- Skipped: 0

Every behaviour fix went Red → Green: a failing-test commit (`test(admin|map): …`), then the fix commit (`fix(admin|map): …`). IN-06 is a behaviour-preserving refactor covered by the existing form and recap tests (`refactor(admin): …`). Commits use plain `git` with explicit paths, carry no trailers and rewrite no history.

These decisions still hold:
- Cubits stay Flutter-free, use `SafeEmit` and never call another cubit (the panel's `PopScope` calling `TeleportModeCubit.cancel()` is UI orchestration).
- The Map in teleport mode gets no new chrome: the chip only loses its «Annulla» tap while the teleport is in flight.
- No GraphQL document changed: `git diff 7333881..HEAD -- lib/graphql` is empty (`pendingQuest` selection stays in plan 10-11).

## Gate finale

| Check | Result |
|-------|--------|
| Full `flutter test` (foreground) | **2830 passed, 0 failed** (2820 before, +10 new tests; one cubit test rewritten for IN-03) |
| `flutter analyze` (repo-wide gate) | **51 issues, all info, 0 errors/warnings**: unchanged baseline |
| `dart format --output=none --set-exit-if-changed` on every touched file (none DIRTY) | clean; each file was clean before its edit and was formatted file by file |
| `git status --short` | empty except this uncommitted report |
| Trailers on `7333881..HEAD` (`co-authored-by` / `generated with`) | 0 |
| Start / final HEAD | `7333881` / `ddaa970` |

## Per-finding table

| ID | Severity | Outcome | Commits (test → fix) | Test added |
|----|----------|---------|----------------------|------------|
| WR-01 | Warning | fixed | `ba1c649` → `1da21a5` | `innkeeper_panel_screen_test.dart` «completing the last card still shows the results» |
| WR-02 | Warning | fixed | `bc33e45` → `154cbb5` | `pending_requests_cubit_test.dart` «a completion after the snapshot dropped the card hides nothing» |
| WR-03 | Warning | fixed | `502139f` → `658e4d1` | `request_completion_screen_test.dart` «while submitting the system back keeps the form», «while editing the system back leaves the form» |
| IN-01 | Info | fixed | `4d2115c` → `3703453` | `pending_requests_cubit_test.dart` «a snapshot newer than a slow refetch wins over its result» |
| IN-02 | Info | fixed | `3703616` → `36e8390` | `request_completion_cubit_test.dart` «an unexpected error while reading ends in a malformed load failure» |
| IN-03 | Info | fixed: requires human verification | `abb052c` → `be4e480` | `teleport_mode_cubit_test.dart` «is ignored while the teleport is in flight, the success still lands» (replaces «a late success after cancel emits nothing»); `teleport_mode_chip_test.dart` «tapping Annulla while teleporting does nothing» |
| IN-04 | Info | fixed | `8da38ee` → `50336fb` | `world_map_teleport_test.dart` «leaving the mode during a pawn drag ends the drag» |
| IN-05 | Info | fixed | `df72293` → `71b87ab` | `innkeeper_panel_screen_test.dart` «leaving the panel during the read cancels it», «the landing pop of an active mode keeps it» |
| IN-06 | Info | fixed (refactor) | — → `ddaa970` | none new: covered by `completion_form_test.dart` and `completion_recap_test.dart`; the test gaps it named are closed by WR-01/02/03 |

## Fixed Issues

### WR-01: The results recap vanished when the last card was completed

**Files modified:** `lib/screens/innkeeper/innkeeper_panel_screen.dart`
**Test:** the mock `PendingRequestsCubit` is driven through `whenListen` with a `StreamController`; `openCompletion` returns a `Completer` future. After the tap, an empty snapshot replaces the queue (the empty state shows), then the opener completes with `CompletionCompleted(results)`.
**RED:** `markCompleted` was called 0 times (the `BlocSelector` builder context was unmounted, `_complete` returned early).
**Commits:** `ba1c649` (test), `1da21a5` (fix)
**Applied fix:** `build` passes its own context to `_buildScaffold(panelContext)`, the `BlocBuilder` hands it to `_buildQueue(panelContext, state)` and the item builder uses it for `_complete` and «Teletrasporta». The `BlocSelector` builder context is no longer named.

### WR-02: `markCompleted` after the snapshot left a hidden id forever

**Files modified:** `lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart`
**Test:** snapshot with both cards, snapshot without the world mission, then `markCompleted(worldMission)`: `hiddenQuestIds` stays empty, and a later snapshot with the same quest shows both cards.
**RED:** `Expected: empty, Actual: {'quest-world-1'}`
**Commits:** `bc33e45` (test), `154cbb5` (fix)
**Applied fix:** `markCompleted` returns early when `state.requests` no longer lists the quest.

### WR-03: The completion form could be left during the submit

**Files modified:** `lib/screens/innkeeper/request_completion_screen.dart`
**Test:** the screen is pushed on a real route with a mock cubit; `tester.binding.handlePopRoute()` (system back) keeps the route with `isSubmitting: true` and pops it with `isSubmitting: false`.
**RED:** the route popped while submitting.
**Commits:** `502139f` (test), `658e4d1` (fix)
**Applied fix:** `build` is a `BlocSelector<RequestCompletionCubit, RequestCompletionState, bool>` on `state is RequestCompletionEditing && state.isSubmitting` that wraps the Scaffold in `PopScope(canPop: !isSubmitting)`. The programmatic `Navigator.pop` of the outcomes is unaffected (all route-exit tests stay green). The AppBar back arrow uses `maybePop`, so it is blocked too.

### IN-01: A slow refetch could overwrite a newer snapshot

**Files modified:** `lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart`
**Test:** in `fakeAsync`, a refetch on a `Completer` starts, a snapshot without the world mission arrives, then the stale refetch answers with both cards.
**RED:** the stale list replaced the snapshot.
**Commits:** `4d2115c` (test), `3703453` (fix)
**Applied fix:** `_snapshotVersion` grows in `_onSnapshot`; `_performRefetch` records it before the await and drops a result when it changed.

### IN-02: `load()` ignored errors other than `InnkeeperException`

**Files modified:** `lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart`
**Test:** `readCharacter` throws a plain `StateError`; expected `[RequestCompletionLoadFailed(failure: malformed)]`.
**RED:** `Bad state: unexpected character shape` escaped the cubit.
**Commits:** `3703616` (test), `36e8390` (fix)
**Applied fix:** an `on Object` branch after the typed one emits `RequestCompletionLoadFailed(failure: InnkeeperFailure.malformed)`; the `finally` still resets `_isLoading`, so «Riprova» works.

### IN-03: Cancelling during the teleport left the character moved without feedback

**Files modified:** `lib/screens/mainScreen/tabs/map/teleportModeCubit/teleport_mode_cubit.dart`, `lib/screens/mainScreen/tabs/map/components/teleport_mode_chip.dart`
**Tests:** cubit: `teleportTo` in flight, `cancel()`, then the success: expected `[TeleportActive(isTeleporting: true), TeleportSucceeded]`. This replaces the earlier test «a late success after cancel emits nothing», whose contract the ruling reverses. Chip: a tap on «Annulla» with `isTeleporting: true` does not call `onCancel`.
**RED:** the cubit went to `TeleportIdle`; the chip counted 1 cancel.
**Commits:** `abb052c` (test), `be4e480` (fix)
**Applied fix:** `cancel()` returns while `state` is `TeleportActive(isTeleporting: true)`; otherwise it calls the new private `_leave()` (generation bump + idle). The FORBIDDEN branch of `_handleTeleportFailure` now calls `_leave()` directly, because at that moment the state is still `isTeleporting: true` and `cancel()` would be ignored (the existing FORBIDDEN test stays green). The lost-role listener still calls `cancel()`: during a teleport in flight it is ignored and the result lands (FORBIDDEN → idle anyway). The chip sets `onTap: null` and `Semantics(enabled: false)` while teleporting.
**Human check:** on device, tap «Annulla» right after releasing the pawn on a city: nothing happens, then the panel reopens on success.

### IN-04: `isPawnDragging` could stay on when teleport mode ended mid-drag

**Files modified:** `lib/screens/mainScreen/tabs/map/world_map.dart`
**Test:** teleport mode, a gesture started on the teleport pawn and moved twice (`isPawnDragging == true`), then `TeleportIdle` is emitted: the pawn is gone and `isPawnDragging` is false.
**RED:** `Expected: false, Actual: <true>`
**Commits:** `8da38ee` (test), `50336fb` (fix)
**Applied fix:** the `!isActive` branch of `_syncTeleportMode` returns `_endPawnDrag()` (sets `pawnDragChanged(false)` and stops the camera animation).

### IN-05: Leaving the panel during the teleport read still landed on the Map

**Files modified:** `lib/screens/innkeeper/innkeeper_panel_screen.dart`
**Tests:** the panel pushed on a real route. With `TeleportPreparing`, a system back pops the panel and calls `cancel()` once. With `TeleportActive`, `popUntil(isFirst)` (as the landing does) pops it without calling `cancel()`.
**RED:** «No matching calls» for `cancel()` (the `TeleportActive` guard test passed already, as expected).
**Commits:** `df72293` (test), `71b87ab` (fix)
**Applied fix:** the panel content is wrapped in `PopScope(onPopInvokedWithResult: …)`; on any completed pop (back, lost role, FORBIDDEN) `_cancelTeleportRead` calls `TeleportModeCubit.cancel()` only when the state is `TeleportPreparing`.

### IN-06: Duplicated fallback labels

**Files modified:** `lib/screens/innkeeper/components/completion_recap.dart`, `lib/screens/innkeeper/components/participant_override_section.dart`
**Commit:** `ddaa970`
**Applied fix:** public `unnamedItemLabel` / `unnamedSpellLabel` in `completion_recap.dart`, reused by `ParticipantOverrideSection` (its private copies removed). Behaviour unchanged: the existing form tests on «Oggetto» / «Magia sconosciuta» and the recap tests stay green. The test gaps named by the finding are closed by the WR-01, WR-02 and WR-03 tests.

## Not needed

None.

---

_Fixed: 2026-10-29T18:42:04Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
