---
phase: 05-notifications-infrastructure
plan: 04
subsystem: push-ports-adapters
tags: [fcm, firebase, flutter_local_notifications, permission_handler, url_launcher, ports-adapters, background-isolate, tdd]
requires:
  - "05-01: Gradle/Firebase wiring, plugin dependencies"
  - "05-02: PushEvent, NotificationIntent, PushChannel, stableNotificationId"
  - "05-03: ActiveUserStore, DeviceIdentityStore"
provides:
  - "PushMessagingPort (token, tokenRefreshes, foregroundMessages; no FCM opened callbacks)"
  - "LocalNotificationsPort (initialize, show, taps, launchIntent, cancelAll)"
  - "NotificationPermissionPort + NotificationPermissionStatus { notDetermined, denied, granted }"
  - "LinkOpener"
  - "NoopPushMessaging, NoopLocalNotifications, UnsupportedNotificationPermission"
  - "PushServices + const PushServices.disabled({permission})"
  - "acceptPushEvent / handleDataMessage (pure, never throw)"
  - "FirebasePushMessaging, FlutterLocalNotificationsAdapter (initialize / initializeWithoutTaps), PermissionHandlerNotificationPermission, UrlLauncherLinkOpener"
  - "firebaseBackgroundMessageHandler (@pragma('vm:entry-point'), no Firebase.initializeApp)"
  - "bootstrapPush() guarded Firebase init (3 s timeout) called in main() before runApp; KlimmeckGuideApp.push"
  - "Test fakes: FakePushMessagingPort, RecordingLocalNotificationsPort, RecordingLinkOpener, FakeNotificationPermissionPort, InMemoryDeviceIdentityStore, InMemoryActiveUserStore"
  - "push_boundaries_test.dart plugin import allow-list"
affects: [05-05, 05-06, 05-07, 05-08, 05-09]
tech-stack:
  added: []
  patterns:
    - "Ports & adapters: one plugin per adapter file, enforced by a static-scan test"
    - "Two intention-revealing init methods instead of a behaviour flag (initialize / initializeWithoutTaps)"
    - "Guarded bootstrap returning a no-op bundle on any failure (D-02)"
key-files:
  created:
    - lib/repository/services/push/push_messaging_port.dart
    - lib/repository/services/push/local_notifications_port.dart
    - lib/repository/services/push/notification_permission_port.dart
    - lib/repository/services/push/link_opener.dart
    - lib/repository/services/push/disabled_push_ports.dart
    - lib/repository/services/push/push_services.dart
    - lib/repository/services/push/data_message_handler.dart
    - lib/repository/services/push/firebase_push_messaging.dart
    - lib/repository/services/push/flutter_local_notifications_adapter.dart
    - lib/repository/services/push/permission_handler_notification_permission.dart
    - lib/repository/services/push/url_launcher_link_opener.dart
    - lib/repository/services/push/push_background_handler.dart
    - lib/repository/services/push/push_bootstrap.dart
    - test/repository/services/push/disabled_push_ports_test.dart
    - test/repository/services/push/data_message_handler_test.dart
    - test/repository/services/push/push_boundaries_test.dart
    - test/helpers/fakes/fake_push_messaging_port.dart
    - test/helpers/fakes/recording_local_notifications_port.dart
    - test/helpers/fakes/recording_link_opener.dart
    - test/helpers/fakes/fake_notification_permission_port.dart
    - test/helpers/fakes/in_memory_device_identity_store.dart
    - test/helpers/fakes/in_memory_active_user_store.dart
  modified:
    - lib/main.dart
decisions:
  - "Boundaries test scans only import directives (not every string) so the allow-list cannot be tripped by comments; it excludes itself from the test/ scan"
  - "The 'iOS rinviato (D-03)' remark in bootstrapPush sits on its own line above the early return instead of trailing it"
metrics:
  duration: "~25 min"
  completed: 2026-10-19
  tasks: 3
  files: 23
---

# Phase 5 Plan 04: Push ports, adapters, background entry and guarded bootstrap Summary

Four plugin-free ports (`PushMessagingPort`, `LocalNotificationsPort`, `NotificationPermissionPort`, `LinkOpener`) with const no-op implementations bundled in `PushServices` / `PushServices.disabled()`, six test fakes, the pure display rule `acceptPushEvent` / `handleDataMessage` (valid message + mirrored active user + that user's toggle on, never throws, fixed-text logs only), four thin adapters over `firebase_messaging` / `flutter_local_notifications` / `permission_handler` / `url_launcher`, the top-level `@pragma('vm:entry-point')` background handler that never calls `Firebase.initializeApp()`, and `bootstrapPush()` called in `main()` before `runApp` behind a try/catch + 3 s timeout that falls back to no-op ports. A static-scan test fences plugin imports to the adapter files.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 RED | Failing tests for the disabled push ports + six fakes | 3273a91 | 7 test files |
| 1 GREEN | Port contracts and their no-op implementations | e8977c2 | 6 lib files |
| 2 RED | Failing tests for the data message handler | e9131db | 1 test file |
| 2 GREEN | Pure background display decision | 0048937 | data_message_handler.dart |
| 3 RED | Push plugin import boundaries guard | c8fef13 | push_boundaries_test.dart |
| 3 GREEN | Adapters, background entry, guarded bootstrap, main() wiring | 230abc1 | 6 lib files + lib/main.dart |

## RED evidence

- Task 1: `test/repository/services/push/disabled_push_ports_test.dart:5:8: Error: Error when reading 'lib/repository/services/push/notification_permission_port.dart': No such file or directory`
- Task 2: `test/repository/services/push/data_message_handler_test.dart:42:53: Error: Method not found: 'handleDataMessage'.`
- Task 3: tests 1-2 passed vacuously, test 3 failed with `PathNotFoundException: Cannot open file, path = 'lib/repository/services/push/push_background_handler.dart'` (`+2 -1: Some tests failed.`)

## Verification

- `flutter test test/repository/services/push`: 26 tests, all passed (6 disabled ports, 17 handler, 3 boundaries)
- `flutter test`: **884 tests, all passed** (baseline 858 + 26)
- `flutter analyze`: **56 issues, 0 errors** (baseline unchanged); `flutter analyze lib/repository/services/push lib/main.dart test/repository/services/push`: No issues found
- `flutter build apk --debug`: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`
- Acceptance greps: `@pragma('vm:entry-point')` 1, `initializeApp` in background handler 0, `DartPluginRegistrant.ensureInitialized()` 1, `onBackgroundMessage(firebaseBackgroundMessageHandler)` 1, `Push disabled: Firebase unavailable` 1, `LaunchMode.externalApplication` 1 / `canLaunchUrl(` 0, `shouldShowRequestRationale` 1, `onDidReceiveBackgroundNotificationResponse` 0, `await bootstrapPush()` 1, `required this.push` 1, `ensureRequested|.request()` in main.dart 0, `onMessageOpenedApp|getInitialMessage` in lib 0
- No plugin import in ports/no-ops/push_services/data_message_handler; no plugin import in `test/`
- `lib/main.dart` was formatter-clean at baseline (`--set-exit-if-changed` exit 0) and remains clean after the edit; every new file formatted by path (no directory format)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Convention] Commit subjects shortened to the 72-char limit**
- **Found during:** Task 1 GREEN / Task 3 GREEN
- **Issue:** the subjects dictated by the plan were 74 and 81 chars, over the orchestrator's 72-char rule
- **Fix:** rewrote only those two local, unpushed commit messages (`git filter-branch --msg-filter` on `f3294d2..HEAD`, code unchanged): `feat(push): add the push port contracts and their no-op implementations`, `feat(push): add push adapters, background entry and guarded bootstrap`
- **Commits:** e8977c2, 230abc1

No other deviation: all `const` fields in `FlutterLocalNotificationsAdapter` are accepted by flutter_local_notifications 19.3.0.

## Known Stubs

- `KlimmeckGuideApp.push` is stored but not consumed yet: by design, plans 05-05..05-08 wire registration, foreground banner, tap routing and the permission gate onto it.
- `LinkOpener` / `UrlLauncherLinkOpener` has no caller yet (plan 05-07 router).

## Threat Flags

None: all new surface (background isolate entry, Firebase bootstrap, external link opener) is covered by T-05-04-01..06.

## Self-Check: PASSED

- All 23 listed files exist; commits 3273a91, e8977c2, e9131db, 0048937, c8fef13, 230abc1 present in `git log`
- No `Co-Authored-By` trailer in any plan commit
