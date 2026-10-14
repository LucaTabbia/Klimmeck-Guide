---
phase: 03-real-time-sync-foundation
plan: 07
subsystem: sync
tags: [character-cubit, resubscribe, backoff, resume-refetch, shell]
requires: [03-02, 03-03]
provides:
  - hardened CharacterCubit (silent resubscribe, terminal FORBIDDEN/NOT_FOUND, resume refetch)
  - AuthenticatedShell wired with SyncHealth, AppLifecycleEvents, UserRefreshRequests
affects: [03-08]
key-files:
  modified:
    - lib/screens/mainScreen/characterCubit/character_cubit.dart
    - test/screens/mainScreen/characterCubit/character_cubit_test.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/auth/authenticated_shell_test.dart
decisions:
  - FORBIDDEN/NOT_FOUND on the character stream is terminal with one user refresh request
  - close() releases health and marks the cubit closed synchronously inside Future.wait (as in 03-06)
metrics:
  completed: 2026-10-14
  tests: 624 passing (baseline 603), analyze 57 issues (baseline)
---

# Phase 3 Plan 07: CharacterCubit hardening Summary

CharacterCubit keeps its cold-start Loading/Loaded/Error flow, then never emits Loading or Error again: stream failures resubscribe silently with 1 to 60 s backoff, FORBIDDEN/NOT_FOUND ends the stream with one user refresh request, and resume refetches the whole character silently with stale-result discard. The shell injects the sync dependencies from the session scope.

## Commits
- test(sync): add failing tests for the hardened character stream
- feat(sync): keep the character stream silent and terminal on access denied
- test(sync): add failing tests for the character resume refetch
- feat(sync): refetch the character silently on resume
- test(sync): add failing shell tests for the sync dependencies
- feat(sync): provide the sync dependencies to the character cubit

## Deviations from Plan
1. [Rule 1 - Bug] `close()` mirrors 03-06: releases the health source and bumps the refresh generation first, then calls `super.close()` synchronously inside `Future.wait`, so `isClosed` is true while cancellations are awaited.
2. Test helpers renamed to public names (`CharacterHarness`, `FakeLifecycle`) to satisfy `library_private_types_in_public_api`.
3. Between the Task 1 feat commit and the Task 3 feat commit `authenticated_shell.dart` does not compile (new required constructor params), as the plan's task order implies; the full suite is green at the last commit.
4. Shell test: the live-status test needs two `pump()` calls after the push (bloc stream hop) and a sync StreamController.
5. Added `_terminateStream` idempotence and `_scheduleResubscribe` no-op when terminated (defensive).

## Known Stubs
None.

## Self-Check: PASSED
