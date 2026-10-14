---
phase: 03-real-time-sync-foundation
fixed_at: 2026-10-14T00:00:00Z
review_path: .planning/phases/03-real-time-sync-foundation/03-REVIEW.md
iteration: 1
findings_in_scope: 3
fixed: 3
skipped: 0
status: all_fixed
---

# Phase 3: Code Review Fix Report

**Source review:** .planning/phases/03-real-time-sync-foundation/03-REVIEW.md
**Iteration:** 1

Gates: `flutter analyze` stays at 57 issues (all pre-existing, none in touched files). `flutter test` final count is 645, all green (baseline 639).

## Fixed Issues

### WR-03: `SyncWatchdog._expire` unhandled async error

**Files modified:** `lib/repository/services/sync/sync_watchdog.dart`, `test/repository/services/sync/sync_watchdog_test.dart`
**Commit:** b103310
**Tests added:** a failing async expiry callback surfaces no unhandled error, and a synchronously throwing callback is contained too. Both assert that the latch stays set and the callback ran once. They were red first.
**Applied fix:** `_expire` runs the callback through `Future<void>.sync(...).catchError`, so sync and async failures are both contained. It logs only `error.runtimeType`, using `dart:developer` `log` because the watchdog stays Flutter-free. The latch stays set. It also exposes a public `isLatched` getter, which WR-02 uses.

### WR-02: Resubscribe during teardown on the recreated client

**Files modified:** `lib/screens/auth/syncCubit/session_sync_cubit.dart`, `test/screens/auth/syncCubit/session_sync_cubit_test.dart`
**Commit:** 88aecdb
**Tests added:** (1) a stream that completes after the watchdog latched is not reopened, and no Recovering state is emitted. (2) a pending resubscribe timer is dropped once the watchdog is disposed or latched, so only one `subscribeToUser` call is ever made. Both were red first.
**Applied fix:** a private `_isSessionEnding` getter (`isClosed || _watchdog.isLatched`) guards `_onUserStreamDone`, `_scheduleResubscribe` and the resubscribe timer callback.
**Status:** fixed: requires human verification. The guard keys on the watchdog latch (expiry or dispose). A user-initiated logout that does not latch the watchdog is not covered until the scope disposes it. See the note below.

### WR-01: Single-flight `refreshUser` joined an older response

**Files modified:** `lib/screens/auth/syncCubit/session_sync_cubit.dart`, `test/screens/auth/syncCubit/session_sync_cubit_test.dart`
**Commit:** 6126bff
**Tests added:**
- A terminal recovery request during a foreground flight triggers a second `me` fetch, and the newer result is adopted. It was red first.
- Requests during a flight coalesce into one follow-up. This replaces the old "three requests in flight produce one refetch" test, whose premise changes by design. It was red first.
- A foreground during a flight still joins it, with a single `getMe` call.
**Applied fix:** `refreshUser({bool force = false})`. The foreground path keeps joining the in-flight future. Forced requests (`_terminateUserStream` and the `userRefreshRequests` bus) queue one coalesced follow-up refetch after the current flight. Stale-result discard (`_eventCount`) is untouched. `_startUserRefresh` clears `_refreshInFlight` only if the flight is still the current one.
**Status:** fixed: requires human verification (concurrency logic).

## Skipped Issues

None in scope. IN-02 (the `DevAuthTokenService` logout-in-flight guard) was not fixed. It does not fall out of the teardown guard, because it lives in a different service. It was left alone as instructed, as were the other IN-xx items.

**Note on WR-02:** `SessionSyncCubit` only sees the watchdog latch, so the guard covers the watchdog-triggered teardown. Closing the remaining gap needs a "session ending" signal from the auth channel, which is out of scope here.

---

_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
