---
phase: 09-combat-result-sheet
plan: 06
subsystem: state
tags: [flutter, cubit, combat, quest-result, queue, acknowledgement, death, fake_async]

# Dependency graph
requires:
  - phase: 09-01
    provides: "`QuestResult` (`isDeath`, `acknowledgedAt`, `resolvedAt`), fixtures `successResultJson` / `deathResultJson` / `questResultJson(acknowledgedAt:)`"
  - phase: 09-03
    provides: "`QuestResultRepository.watch/fetch`, `QuestResultException`/`QuestResultFailure`, ports `PendingQuestResults` / `QuestResultAcknowledger`, `MockQuestResultRepository`"
  - phase: 09-05
    provides: "`ConnectionRestoredEvents` / `ConnectionRestoredBus`"
provides:
  - "`QuestResultsCubit`: one shell-scoped queue of due results (three sources, refetch triggers, acks, death ack, external-pop requeue, batch counter)"
  - "`QuestResultsState` + `DeathAcknowledgement` (part of the cubit library)"
  - "`QuestResultNotice` (own Flutter-free library; 09-10 adds `questResultNoticeFor` here)"
  - "Fakes `FakePendingQuestResults`, `RecordingQuestResultAcknowledger`"
affects: [09-10, 09-11, 09-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "FIFO serialisation of the cubit's mutations through a private future tail (`_serialised`): acks never run in parallel"
    - "Single-flight refetch (`_refetchInFlight ??= …whenComplete`) preceded by the retry of failed acks"
    - "`withoutShowing({queue, position})` instead of a boolean `clearShowing` flag in `copyWith` (CLAUDE.md: no behaviour-switching booleans)"

key-files:
  created:
    - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
    - lib/screens/mainScreen/questResultsCubit/quest_results_state.dart
    - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
    - test/screens/mainScreen/questResultsCubit/quest_results_queue_test.dart
    - test/screens/mainScreen/questResultsCubit/quest_results_delivery_test.dart
    - test/helpers/fakes/fake_pending_quest_results.dart
    - test/helpers/fakes/recording_quest_result_acknowledger.dart
  modified: []

key-decisions:
  - "Every acknowledgement (best-effort and death) goes through one FIFO tail: the BE never sees two acks of the same cubit in parallel (Phase 8 ruling)"
  - "`acknowledgeDeath` acts only when the showing result is a death (`isDeath`) — a non-death id is ignored even if showing, so `done` (which stops every sheet) can only follow a death"
  - "A terminal FORBIDDEN/NOT_FOUND on the result stream triggers one `refetchPending()` and no user refresh (CharacterCubit owns that, D-13 b)"
  - "The tap path does not retry: a network-type failure is silent and left to the next resume/reconnect refetch (D-11)"

patterns-established:
  - "Shell-scoped delivery cubit with `start()` separate from the constructor: the composition root decides when the sources open"

requirements-completed: []

# Metrics
duration: ~30min
completed: 2026-10-28
---

# Phase 9 Plan 06: QuestResultsCubit Summary

**Flutter-free `QuestResultsCubit` owning the result queue: FIFO by `resolvedAt` (ties by id) and deduplicated by id, fed by the `questResultReceived` subscription, the `questEnd` tap and the unacknowledged-results port, refilled at cold start/resume/reconnection, with best-effort FIFO acknowledgements, an awaited death acknowledgement followed by exactly one user refresh, external-pop requeue and the «k di N» batch counter.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-10-28
- **Tasks:** 2 (TDD: 2 RED + 2 GREEN commits)
- **Files created:** 7

## Accomplishments

- Queue rules (D-08, D-09, D-10): ordering, dedup against queued/showing/closed/pending-ack/acknowledged ids and `acknowledgedAt != null`, `presented` / `closed` / `dismissedExternally`, batch counter reset when the batch ends.
- Death acknowledgement (D-10, D-13): `idle → inFlight → done | failed`, re-entry guarded, no second ack on `closed`, one `requestUserRefresh()` per cubit lifetime after `done` (checker W2), `isAcceptingSheets == false` after `done`.
- Sources and triggers (D-09, D-11): subscription with silent bounded resubscribe, malformed event skipped, terminal codes stop it and trigger one refetch (checker I2); single-flight refetch on start/foreground/reconnection with failed acks retried first and `silentRetry` on transient port failures; foreground retries a failed death ack; tap filtered by `validBackendIdentifier`, re-read with `fetch`, notice only for NOT_FOUND/FORBIDDEN.

## Task Commits

1. **Task 1 RED: queue rules tests + fakes** — `21ed024` (test)
2. **Task 1 GREEN: state, notice, queue/presentation/acks** — `b18449c` (feat)
3. **Task 2 RED: sources and triggers tests** — `c254e18` (test)
4. **Task 2 GREEN: subscription, refetch, tap, close** — `e58c205` (feat)

## RED evidence

- Task 1: `quest_results_queue_test.dart` failed to compile — `Error when reading 'lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart': No such file or directory`, `Type 'QuestResultsCubit' not found`.
- Task 2: `quest_results_delivery_test.dart` failed to compile — `The method 'start' isn't defined for the type 'QuestResultsCubit'`, `The method 'requestFromTap' isn't defined for the type 'QuestResultsCubit'`.

## Public API (for 09-10 / 09-11)

```dart
QuestResultsCubit({
  required String characterId,
  required QuestResultRepository repository,
  required PendingQuestResults pending,
  required QuestResultAcknowledger acknowledger,
  required AppLifecycleEvents lifecycle,
  required ConnectionRestoredEvents connectionRestored,
  required UserRefreshRequests userRefresh,
});
void start();                              // subscribe + listen foreground/restored + one refetchPending()
Future<void> refetchPending();             // single-flight; retries failed acks first, then silentRetry(fetchUnacknowledged)
Future<void> requestFromTap(String? id);   // questEnd tap
void presented(String id);                 // only if id == head
void closed(String id);                    // only if id == showing; best-effort ack unless already acknowledged
void dismissedExternally(String id);       // only if id == showing; requeue, no ack, position - 1 (floor 0)
Future<void> acknowledgeDeath(String id);  // only if showing is that death and not inFlight/done
```

State: `queue` (unmodifiable, FIFO), `showing`, `position`, `arrival`, `arrivalSerial` (live subscription only), `notice` (`QuestResultNotice{resultId, failure, serial}`), `deathAcknowledgement`; getters `head`, `isUnlockedByDeath`, `total` (= `position + queue.length`), `isAcceptingSheets`.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Auto-fixed / adjusted

**1. [CLAUDE.md - Clean Code] `withoutShowing(...)` instead of `copyWith` clear flags**
- **Found during:** Task 1
- **Issue:** the plan suggested explicit boolean clear flags in `copyWith`; CLAUDE.md forbids boolean flags that switch behaviour.
- **Fix:** `copyWith` only replaces non-null values; `withoutShowing({queue, position})` builds the state with `showing == null`. `notice` never needs clearing (serial).
- **Commit:** `b18449c`

**2. [Rule 2 - Correctness] Acknowledgements serialised FIFO**
- **Found during:** Task 1
- **Issue:** two quick closes would run two acks in parallel (Phase 8 ruling: mutations of the same cubit are FIFO).
- **Fix:** private `_serialised` future tail for both best-effort and death acks; test «acknowledgements run one at a time, in close order».
- **Commit:** `b18449c`

**3. [Rule 2 - Correctness] `acknowledgeDeath` requires `showing.isDeath`**
- **Issue:** a non-death id reaching `done` would stop every later sheet.
- **Fix:** guard + test «only the death showing can be acknowledged».
- **Commit:** `b18449c`

**4. Task 1 kept only the dependencies it used**
- The Task 1 constructor already had the full signature, but `repository`, `lifecycle`, `connectionRestored` and `characterId` were stored only in Task 2 (otherwise `unused_field` warnings), and Task 1 shipped a minimal `refetchPending()` (needed by the queue tests to feed results); Task 2 replaced it with the single-flight/silent-retry version.

**5. Acceptance grep vs formatting**
- The key-link pattern `_repository\.(watch|fetch)\(` matches only `fetch` on one line: `dart format` split `_repository\n        .watch(_characterId)`. Formatting kept as is (orchestrator rule).

---

**Total deviations:** 3 auto-fixed (correctness/clean code), 2 notes. **Impact:** no scope change.

## Issues Encountered

None.

## Verification

- `flutter test test/screens/mainScreen/questResultsCubit` → 56 tests green (23 queue + 33 delivery).
- Full suite: 2335 → 2391 green.
- `flutter analyze`: 52 issues (baseline 53), none in the new files; cubit has no `package:flutter/` import.
- `dart format --output=none --set-exit-if-changed` on all 7 new files → exit 0.
- Acceptance greps: `validBackendIdentifier(` 1, `WsReconnectPolicy.maxReconnectDelay` 1, `silentRetry(` 1, `requestUserRefresh(` 1, `SyncHealth|debugPrint(.*result` 0.

## Known Stubs

None (the 9.2 port implementations stay null objects until plan 09-12, by design — C4).

## Next Phase Readiness

09-10 (presenter) can read `QuestResultsState` with `MapAvailabilityCubit`, call `presented/closed/dismissedExternally/acknowledgeDeath`, route `questEnd` taps to `requestFromTap` and call `refetchPending()` on `CharacterUnavailable`. 09-11 composes the cubit in `AuthenticatedShell` and calls `start()`.

## Self-Check: PASSED

- All 7 created files exist; commits `21ed024`, `b18449c`, `c254e18`, `e58c205` present in `git log`.

---
*Phase: 09-combat-result-sheet*
*Completed: 2026-10-28*
