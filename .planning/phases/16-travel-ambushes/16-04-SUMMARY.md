---
phase: 16-travel-ambushes
plan: 04
subsystem: results
tags: [flutter, dart, cubit, quest-result, ambush, queue]

requires:
  - phase: 16-01
    provides: QuestResult.isAmbush, ambushWonResultJson / ambushLostResultJson fixtures
provides:
  - QuestResultsState.showingGroup (List<QuestResult>) + `showing` getter, `presentable`, `isSettlingAmbushes`
  - Group-wide presented/closed/dismissedExternally(headId) on QuestResultsCubit; _isKnown over the whole open group
  - Live batch settling: a live ambush emits the merged queue with pendingRefetch inFlight and runs one read; a live ambush during an in-flight read chains exactly one more
affects: [16-05, 16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "Presentable unit = head alone, or the consecutive isAmbush results from the head, re-evaluated at every read"
    - "Chained single-flight refetch (`_isRefetchChained`) instead of a debounce timer"

key-files:
  created: []
  modified:
    - lib/screens/mainScreen/questResultsCubit/quest_results_state.dart
    - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
    - test/screens/mainScreen/questResultsCubit/quest_results_queue_test.dart
    - test/screens/mainScreen/questResultsCubit/quest_results_delivery_test.dart

key-decisions:
  - "`showing` became a getter over `showingGroup.first`: every existing reader (death path, presenter, tests) compiles unchanged (D-11)"
  - "A chained read keeps pendingRefetch inFlight in the first read's final emit, so the presenter never sees a `done` gap between the two reads (D-12)"

requirements-completed: []

duration: 6min
completed: 2026-11-06
---

# Phase 16 Plan 04: Ambush group queue and batch settling Summary

**`QuestResultsCubit` presents, acknowledges and requeues the consecutive ambush reports at the head of the queue as one group, and a live ambush re-reads `unacknowledgedQuestResults` (one chained read at most) so the whole arrival batch is queued before the presenter opens it.**

## Accomplishments

- State: field `final List<QuestResult> showingGroup` (default `const []`) replaces `showing`; `QuestResult? get showing => showingGroup.isEmpty ? null : showingGroup.first`; `List<QuestResult> get presentable` (head alone, or `queue.takeWhile(isAmbush)` when the head is an ambush; `const []` on an empty queue); `bool get isSettlingAmbushes => head?.isAmbush == true && pendingRefetch == PendingRefetch.inFlight`. `copyWith({List<QuestResult>? showingGroup, ...})`; `withoutShowing` signature unchanged (empty group); `props` list `showingGroup`.
- Cubit: `presented(String headId)` moves `presentable` into `showingGroup`, skips it from the queue, `position += group.length`; `closed(String headId)` adds every id to `_closedIds`, emits `withoutShowing`, acknowledges each id in order through `_acknowledgeQuietly` (serialised tail, best effort per id, skips already-acknowledged ids); `dismissedExternally(String headId)` requeues the whole group with `_merged(group)` and `position = position > group.length ? position - group.length : 0`. All three ignore an id that is not `group.first.id`. `_isKnown` checks `state.showingGroup.any(...)`.
- Batch settling: `bool _isRefetchChained = false`; `refetchPending() => _refetchInFlight ??= _performRefetch().whenComplete(_onRefetchSettled)`; `_onRefetchSettled()` clears the in-flight future and, if chained and not closed, resets the flag and runs one more `refetchPending()`; `_settleAmbushes()` chains when a read is in flight, else starts one. `_performRefetch`'s final emit sets `inFlight` while chained, else `failed`/`done`. `_accept` on a live ambush emits `pendingRefetch: inFlight` in the same emit as the merged queue, then calls `_settleAmbushes()`. No new timer.

## Task Commits

1. Task 1 RED — `6fc0452` test(results): expect the ambush group in the result queue
2. Task 1 GREEN — `68499fb` feat(results): present and acknowledge ambush reports as a group
3. Task 2 RED — `4f24a5f` test(results): expect live ambushes to settle their batch
4. Task 2 GREEN — `3e7d62e` feat(results): settle the ambush batch before presenting it

## Tests added

- `quest_results_queue_test.dart`: group `'QuestResultsCubit ambush group (D-05, D-11)'` (10 tests, titles as in the plan); file-level helpers `_won(id, minute)` / `_lost(id, minute)` (resolvedAt `2026-10-27T11:2<minute>:00.000Z`); group-local `idsOf(results)` and `presentGroup()` (offers `[_won('a1', 0), _lost('a2', 5), _success('q')]` and presents `a1`).
- `quest_results_delivery_test.dart`: group `'QuestResultsCubit ambush settling (D-12)'` (5 tests, fakeAsync `withHarness`), same `_won`/`_lost` helpers at file level; states recorded via `h.cubit.stream.listen(states.add)`.

## RED failures observed

- Task 1: compilation failure, `The getter 'showingGroup' isn't defined for the type 'QuestResultsState'` (and `presentable`): the whole file failed to load.
- Task 2: compilation failure, `The getter 'isSettlingAmbushes' isn't defined for the type 'QuestResultsState'` (4 sites). Behaviourally, «a live quest result triggers no settling read (D-12)» would have been green on the old cubit (no settling existed: `calls == 1`); it is a guard that settling stays ambush-only, red only through the missing getter.

## Gates

- `flutter test test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart`: Task 1 +249 all passed, Task 2 +254 all passed (every pre-existing test unchanged).
- `flutter analyze`: 0 error, 0 warning; last line `50 issues found.` (baseline, all info).
- `dart format` run one by one on the four touched files (only the test files and the state file reflowed; no untouched members moved).
- Acceptance greps: showingGroup field 1, showing getter 1, presentable 1, `state.showing?.id == id` 0, `showingGroup.any` 1, queue `D-11)` 9, `D-05` 5; `isSettlingAmbushes` getter 1, `_isRefetchChained` 5, `_settleAmbushes` 1, `Timer(` 1, delivery `D-12)` 6. Trailer check 0 on every commit.

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Threat Flags

None (T-16-09 and T-16-10 mitigated by the dedup and external-pop tests; T-16-11 accepted as planned).

## Self-Check: PASSED

- Files modified exist; commits 6fc0452, 68499fb, 4f24a5f, 3e7d62e present in `git log`.
