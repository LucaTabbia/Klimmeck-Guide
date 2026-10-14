---
phase: 03-real-time-sync-foundation
plan: 06
subsystem: auth-sync
tags: [cubit, graphql-subscription, watchdog, silent-retry]
requires: [03-02, 03-03]
provides:
  - SessionSyncCubit (single owner of userUpdated, me refetch, socket and lifecycle wiring)
affects: [03-08]
key-files:
  created:
    - lib/screens/auth/syncCubit/session_sync_cubit.dart
    - lib/screens/auth/syncCubit/session_sync_state.dart
    - test/screens/auth/syncCubit/session_sync_cubit_test.dart
  modified:
    - test/screens/auth/cubit/auth_cubit_test.dart
decisions:
  - FORBIDDEN/NOT_FOUND on the user stream is terminal with one single-flight me refetch
  - close() releases watchdog sources and marks the cubit closed before awaiting cancellations
metrics:
  completed: 2026-10-14
  tests: 603 passing (baseline 579), analyze 57 issues (baseline)
---

# Phase 3 Plan 06: SessionSyncCubit Summary

SessionSyncCubit is the single `userUpdated` consumer: events enter the session through `adoptUser`, transient failures resubscribe silently with 1 to 60 s backoff, FORBIDDEN/NOT_FOUND ends the stream with one `me` refetch, and resume and refresh requests share a single-flight silent refetch that is discarded when a live event overtook it.

## Commits
- test(sync): failing tests for the session user stream
- feat(sync): session user stream owner
- test(sync): failing tests for resume refetch and watchdog wiring
- feat(sync): refetch the user on resume and on request

## Deviations from Plan
1. [Rule 1 - Bug] `close()` as planned awaited subscription cancellations before `super.close()`, so `isClosed` stayed false while a refetch was in flight and a late result was still adopted, and the watchdog timer stayed pending. Fixed by releasing watchdog sources first and calling `super.close()` synchronously inside `Future.wait`.
2. Tests use a `FakeLifecycle` and a plain broadcast `StreamController` for refresh requests instead of the real buses, to assert `hasListener` after close.
3. The AuthCubit SYNC-07 test passed immediately (the cubit already mirrors the service stream), so it has no red phase; it locks the behavior.

## Known Stubs
None.

## Self-Check: PASSED
