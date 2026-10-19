---
phase: 05-notifications-infrastructure
plan: 02
subsystem: push-models
tags: [models, notifications, fcm, parsing, equatable, fnv1a, tdd]
requires: []
provides:
  - "NotificationCategory.wireType / fromWireType / isPersonal (pinned backend push types, never enum.name)"
  - "KGNotification: const + Equatable, fromJson/toJson kept"
  - "stableNotificationId(String key): FNV-1a 32-bit reduced to 31 bits, isolate-stable"
  - "NotificationIntent { category, id?, sentAt } + toPayload / tryFromPayload"
  - "PushEvent + tryParse + dedupKey + notificationId + intent + notification"
  - "validEventId / parseSentAt shared boundary helpers (lib/models/notification_intent.dart)"
  - "TwitchChannel.url / uri and PushChannel.id / name / description / smallIcon constants"
affects: [05-03, 05-04, 05-05, 05-06, 05-07, 05-08, 05-09]
tech-stack:
  added: []
  patterns: ["Strict tryParse at the payload boundary: null instead of throwing", "Dedup key and Android id derived from one getter pair on the event"]
key-files:
  created:
    - lib/utils/stable_notification_id.dart
    - lib/config/twitch_channel.dart
    - lib/config/push_channel.dart
    - lib/models/notification_intent.dart
    - lib/models/push_event.dart
    - test/models/notification_test.dart
    - test/utils/stable_notification_id_test.dart
    - test/config/push_config_test.dart
    - test/models/notification_intent_test.dart
    - test/models/push_event_test.dart
  modified:
    - lib/models/notification_category.dart
    - lib/models/notification.dart
    - test/models/notification_category_test.dart
decisions:
  - "PushEvent._sentAtMinute normalises through toUtc() itself, so a PushEvent built directly with a local DateTime still yields the UTC-minute key (the plan relied on callers passing UTC)"
  - "Commit scope `push` as in the plan's action text"
metrics:
  duration: "~12 min"
  completed: 2026-10-19
  tasks: 2
  files: 13
---

# Phase 5 Plan 02: Pure push value layer Summary

Flutter-free value layer of the phase: pinned wire names on `NotificationCategory` (`fromWireType`, `isPersonal`), strict boundary parsers `PushEvent.tryParse` and `NotificationIntent.tryFromPayload` (unknown type, empty/non-string fields, bad `sentAt` -> null; ids only for personal types and only `[A-Za-z0-9._-]{1,128}`), FNV-1a 31-bit `stableNotificationId` matching the four reference vectors, `KGNotification` upgraded to const + Equatable, and `TwitchChannel` / `PushChannel` constants.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 RED | Failing tests: wire names, stable ids, KGNotification, push constants | 065b1ad | 4 test files |
| 1 GREEN | Wire names, stable ids, const Equatable KGNotification, TwitchChannel, PushChannel | 9137872 | 5 lib files |
| 2 RED | Failing tests: PushEvent, NotificationIntent | 8e5f785 | 2 test files |
| 2 GREEN | PushEvent and NotificationIntent | 011c13c | 2 lib files |

No REFACTOR commit: nothing to clean after GREEN.

## TDD evidence

**Task 1 RED** (`flutter test` on the four files):
```
test/models/notification_category_test.dart:25:45: Error: The getter 'wireType' isn't defined for the type 'NotificationCategory'.
test/models/notification_test.dart:5:24: Error: Cannot invoke a non-'const' constructor where a const expression is expected.
```
**Task 1 GREEN:** `+19: All tests passed!`

**Task 2 RED:**
```
test/models/notification_intent_test.dart:3:8: Error: Error when reading 'lib/models/notification_intent.dart': No such file or directory
```
**Task 2 GREEN:** `+33: All tests passed!` (both files); `flutter test test/models test/utils test/config` -> `+93: All tests passed!`

## Verification

- `flutter test` (full suite): **812 passed** (762 baseline + 50 new), 0 failed
- `flutter analyze`: **56 issues, 0 errors** (unchanged from plan 01 baseline)
- `flutter analyze` on the 13 touched files: `No issues found!`
- `dart format --output=none --set-exit-if-changed` on the 13 touched files: 0 changed
- Pre-edit format check: `lib/models/notification_category.dart` and `test/models/notification_category_test.dart` were already formatter-clean at baseline (`Formatted 2 files (0 changed)`), so they were formatted by path and stay clean. `lib/models/notification.dart` was rewritten entirely and formatted.
- Acceptance greps: `travelEnd('travel_end', 'travelEnd')` = 1; `.name` in category = 0; `hashCode` in stable id = 1 (dartdoc only); `0x811c9dc5` = 1; `const KGNotification(` = 1; `url|Uri` in push_event.dart = 0; `package:flutter/` in all six lib files = 0. Tests import only `flutter_test` and project files (no plugin imports).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] UTC normalisation of the dedup minute inside PushEvent**
- **Found during:** Task 2
- **Issue:** the plan's `_sentAtMinute` read `sentAt.year/…/minute` directly, correct only when `sentAt` is already UTC; a `PushEvent` built with a local `DateTime` (constructor is public) would produce a key in local time and break dedup across isolates/devices.
- **Fix:** `_sentAtMinute` calls `sentAt.toUtc()` first. Extra test: `'2026-10-18T14:00:42.123+02:00'` -> `streamerLive|2026-10-18T12:00:00.000Z`.
- **Files modified:** lib/models/push_event.dart, test/models/push_event_test.dart
- **Commit:** 011c13c / 8e5f785

### Additions within scope
- Extra malformed cases in tests beyond the plan list: missing `type`, non-string `title`, numeric `sentAt`; id outside the alphabet dropped in `PushEvent` too.
- One-line dartdoc on `parseSentAt` (public helper).

## Known Stubs

None. `KGNotification`, `PushEvent`, `NotificationIntent` have no consumers yet by design: plans 05-03..05-08 wire them.

## Threat Flags

None: no new network, file or auth surface; T-05-02-01..03 mitigations are implemented and tested, T-05-02-04 accepted.

## Self-Check: PASSED

- All 13 files exist; commits 065b1ad, 9137872, 8e5f785, 011c13c present in `git log`.
