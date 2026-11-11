---
phase: 12-hardening
plan: 05
subsystem: repository
tags: [hardening, logging, release]
requires: ["12-04"]
provides:
  - "Every log of lib/repository goes through appLog (silent under kReleaseMode)"
  - "test/utils/app_log_routing_test.dart: per-directory guard against direct debugPrint/print/developer.log calls (D-03)"
affects: [12-06, 12-07]
tech-stack:
  added: []
  patterns:
    - "Source guard test looping over _routedRoots, one test per root"
key-files:
  created:
    - test/utils/app_log_routing_test.dart
  modified:
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/services/graphql/graphql_client_holder.dart
    - lib/repository/services/rest/auth_interceptor.dart
    - lib/repository/storage/session_store.dart
    - lib/repository/services/sync/sync_watchdog.dart
    - lib/repository/cache/image_warmer.dart
    - lib/repository/services/push/data_message_handler.dart
    - lib/repository/services/push/local_notifications_startup.dart
    - lib/repository/services/push/notification_tap_router.dart
    - lib/repository/services/push/push_bootstrap.dart
    - lib/repository/services/push/push_registration_coordinator.dart
    - lib/repository/services/push/url_launcher_link_opener.dart
decisions:
  - "Messages kept verbatim; the only text change is the [SyncWatchdog] prefix on the former developer.log call (D-03c)"
metrics:
  duration: "~10 min"
  completed: 2026-11-09
---

# Phase 12 Plan 05: Repository logs through appLog Summary

All 31 direct log calls of `lib/repository` (14 files) now go through `appLog`, silent in release, and `test/utils/app_log_routing_test.dart` fails on any new `debugPrint(`/`print(`/`developer.log(` under the seven routed roots (D-03c, HARDEN-01, HARDEN-08).

## Tasks

| Task | Commits | Result |
|---|---|---|
| 1 Guard + auth/graphql/rest/storage/sync/cache | `8b5526d` test, `cafb28e` refactor | 20 sites routed |
| 2 Guard extended + push | `303c190` test, `591ebe1` refactor | 11 sites routed |

## RED observed

Task 1 (`flutter test test/utils/app_log_routing_test.dart`, 6 failing): auth 12 (dev_auth 4, session_auth 8), graphql 3 (graphql.dart 2, graphql_client_holder.dart 1), rest 1, storage 2, sync 1, cache 1 = 20.
Task 2 (7 tests, 6 green + 1 failing): push 11 (push_registration_coordinator 2, data_message_handler 3, notification_tap_router 1, push_bootstrap 2, url_launcher_link_opener 1, local_notifications_startup 2).

## Counts after

`appLog(` per file: session_auth_token_service 8, dev_auth_token_service 4, graphql 2, graphql_client_holder 1, auth_interceptor 1, session_store 2, sync_watchdog 1, image_warmer 1, data_message_handler 3, local_notifications_startup 2, notification_tap_router 1, push_bootstrap 2, push_registration_coordinator 2, url_launcher_link_opener 1.
`grep -rnE '(^|[^A-Za-z_])(debugPrint|print)\(|developer\.log\(' lib/repository` prints nothing. Direct log sites left in `lib/` outside `app_log.dart`: 23 (was 54).
Imports: `package:flutter/foundation.dart` removed where it became unused (graphql.dart, session_store.dart and all six push files); `dart:developer` removed from sync_watchdog.dart; `foundation.dart show debugPrint` removed from image_warmer.dart; kept in dev_auth_token_service, session_auth_token_service, graphql_client_holder, auth_interceptor (still used).
No exception value was interpolated (all already `${error.runtimeType}`; `push_registration_coordinator._describe` returns a failure enum name or the runtimeType). Token/bearer/jwt/authorization interpolation grep near `appLog(` prints nothing.

## Gates

- `flutter test test/utils test/repository/services/auth test/repository/services/graphql test/repository/storage test/repository/services/sync test/repository/cache test/network`: 522 green (all directories exist).
- `flutter test test/utils test/repository/services test/repository/push_device_repository_test.dart`: 576 green.
- `flutter analyze`: `50 issues found.` all info, 0 error, 0 warning.
- `dart format` on each touched file: session_auth_token_service, session_store, image_warmer, local_notifications_startup, push_bootstrap reflowed (only the routed calls/imports they contain, the files were clean at baseline); the others unchanged.

## Deviations from Plan

- The `graphql.dart` doc comment the plan asked to fix already read «composition root (`lib/bootstrap/`)» (updated by plan 02): left as is.
- Full suite not re-run (not prescribed); last full run 3580 after 12-02.

## Self-Check: PASSED
