---
phase: 10-admin-panel-innkeeper
plan: 03
subsystem: admin-queue
tags: [admin, innkeeper, cubit, subscription, tdd]
requires: [10-01, 10-02]
provides:
  - PendingRequestsCubit (start, refetch, markCompleted, close)
  - PendingRequestsState (requests, isLoaded, isForbidden, serverNow, hiddenQuestIds, cards)
  - MockPendingRequestsCubit (test/helpers/mocks.dart)
affects: [10-05, 10-07]
tech-stack:
  added: []
  patterns: [route-scoped subscription cubit with bounded backoff, server-clock tick only while a travel runs, keyed one-shot arrival rereads, single-flight silent refetch]
key-files:
  created:
    - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart
    - lib/screens/innkeeper/pendingRequestsCubit/pending_requests_state.dart
    - test/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit_test.dart
  modified:
    - test/helpers/mocks.dart
key-decisions:
  - "PendingRequestsCubit has no resubscribe refetch: the BE sends a snapshot on every subscription (C5)"
  - "Arrival rereads are keyed characterId|endTime|index: a repeated travel never schedules twice, a new endTime gets its own pair"
  - "Busy lanes are ignored by the tick and the rereads (they have no card)"
  - "A non-FORBIDDEN refetch failure is silent and never retried by itself; FORBIDDEN from refetch or stream is terminal"
requirements-completed: []
duration: 15min
completed: 2026-10-29
---

# Phase 10 Plan 03: Pending requests queue cubit Summary

Route-scoped, Flutter-free `PendingRequestsCubit` owning `pendingRequestsUpdated` with the Phase 3 silent reconnection (backoff capped at `WsReconnectPolicy.maxReconnectDelay`, terminal FORBIDDEN), a `ServerClockService` tick only while a listed participant travels, one silent reread at `endTime + 5 s` / `+ 65 s`, resume refetch and the optimistic hide of a completed card.

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | Subscription lifecycle (snapshot, replace, resubscribe, FORBIDDEN, close) | c07a1b9 | cb5c726 |
| 2 | Server-clock tick, arrival rereads, resume/single-flight refetch, optimistic hide | 57daa64 | 96e6014 |

## TDD evidence

- Task 1 RED: compile failure, `Error: Method not found: 'PendingRequestsState'` and `The method 'start' isn't defined` (the cubit did not exist).
- Task 2 RED: compile failure, `Member not found: 'arrivalRereadDelays'`, `No named parameter with the name 'lifecycle'`, `The method 'refetch' isn't defined`, `The method 'markCompleted' isn't defined`.
- GREEN: `pending_requests_cubit_test.dart` 11/11 after Task 1, 26/26 after Task 2. Full suite 2627 passing (2601 + 26). Repo-wide analyzer 51 issues (all info), gate exit 0.

## Public surface (for 10-05 / 10-07)

- `PendingRequestsCubit({required InnkeeperRepository repository, required ServerClockService clock, required AppLifecycleEvents lifecycle, Duration tick = defaultTick, List<Duration> rereadDelays = arrivalRereadDelays})`; `static const defaultTick = 1 s`, `static const arrivalRereadDelays = [5 s, 65 s]`.
- `void start()` opens the subscription and listens to `lifecycle.foregrounded` (each event → `refetch()`); call once after creation.
- `Future<void> refetch()` single-flight, silent; `InnkeeperFailure.forbidden` → terminal.
- `void markCompleted(String questId)` adds to `hiddenQuestIds`; a snapshot without that quest drops the id.
- `PendingRequestsState({required DateTime serverNow, List<PendingRequest> requests = const [], bool isLoaded = false, bool isForbidden = false, Set<String> hiddenQuestIds = const {}})`, `List<RequestCard> get cards`, `copyWith`.

## Deviations from Plan

1. **[Rule 3 - Blocking] `lifecycle` constructor parameter introduced in Task 2, not Task 1.** Storing an unused `_lifecycle` in Task 1 would have produced an `unused_field` warning (gate fails); the foreground listener belongs with `refetch()` in Task 2. Final constructor matches the plan.
2. **Process slip: `dart format` was run once on the new directory `lib/screens/innkeeper/pendingRequestsCubit/`** (Task 1 GREEN) instead of naming the two files. The directory held only the two new files of this plan; no other file was touched (0 changed outside them).
3. **Test style:** the cubit tests use a `QueueHarness` under `fakeAsync` (one `blocTest` for the replace sequence) because backoff, tick and rereads are time-driven; `pass()` advances the fake server clock and the timers together one second at a time.
4. **Extra test:** the constants `defaultTick` and `arrivalRereadDelays` are asserted, plus a busy-lane traveller that must not tick.

## Threat model

T-10-10 (bounded backoff, single timer, reset on snapshot), T-10-11 (FORBIDDEN terminal from stream and refetch, resume ignored afterwards), T-10-12 (close cancels subscription, foreground listener, backoff, tick and every reread timer; callbacks check `isClosed || _isTerminated`), T-10-13 (`DateTime.now` count 0) are each covered by a test.

## Known Stubs

None.

## Self-Check: PASSED
