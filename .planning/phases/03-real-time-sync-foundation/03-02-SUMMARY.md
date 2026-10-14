---
phase: 03-real-time-sync-foundation
plan: 02
subsystem: sync
tags: [watchdog, lifecycle, silent-retry, fake_async]
requires: []
provides:
  - SyncSource + SyncHealth contract
  - SyncWatchdog (3-minute degraded-time clock)
  - AppLifecycleEvents / AppLifecycleEventBus
  - UserRefreshRequests / UserRefreshRequestBus
  - silentRetry (bounded, cancellable)
  - RecordingSyncHealth test fake
affects: [03-06, 03-07, 03-08]
tech-stack:
  added: []
  patterns: [Flutter-free sync primitives tested with fakeAsync]
key-files:
  created:
    - lib/repository/services/sync/sync_health.dart
    - lib/repository/services/sync/sync_watchdog.dart
    - lib/repository/services/sync/app_lifecycle_events.dart
    - lib/repository/services/sync/user_refresh_requests.dart
    - lib/utils/silent_retry.dart
    - test/repository/services/sync/sync_watchdog_test.dart
    - test/repository/services/sync/app_lifecycle_events_test.dart
    - test/repository/services/sync/user_refresh_requests_test.dart
    - test/utils/silent_retry_test.dart
    - test/helpers/fakes/recording_sync_health.dart
  modified: []
key-decisions:
  - "Watchdog measures continuous degraded time, never silence; terminated streams count only when no stream is healthy"
requirements-completed: [SYNC-03]
duration: 15min
completed: 2026-10-14
---

# Phase 3 Plan 02: Sync primitives Summary

Flutter-free sync primitives: degraded-time `SyncWatchdog` (suspend/resume, single latch, FORBIDDEN rule), lifecycle and user-refresh buses, and a bounded cancellable `silentRetry` reusing `exponentialBackoff`.

## Commits
- 51d6534 test(sync): failing tests for the watchdog
- 5ae7c3f feat(sync): degraded-time sync watchdog
- 8d9bf47 test(sync): failing tests for the buses
- 34cdd5a feat(sync): lifecycle and user refresh request buses
- 1de7121 test(sync): failing tests for the silent retry
- 190f879 feat(sync): bounded silent retry

## Verification
- `flutter test`: 528 passing (baseline 495; +19 watchdog, +7 buses, +8 silent retry)
- `flutter analyze`: 57 issues, identical to baseline; touched files clean
- Touched files formatter-clean (explicit paths only); no `package:flutter` import in the new lib files

## Deviations from Plan
None - plan executed exactly as written. The bus tests use `Future<void>.delayed(Duration.zero)` only to flush microtasks of broadcast streams (no timer-driven logic); watchdog and retry tests use `fakeAsync`.

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED
