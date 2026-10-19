---
phase: 05-notifications-infrastructure
plan: 08
subsystem: push-foreground-banner
tags: [notifications, foreground, in-app-banner, cubit, dedup, queue, design-system, tdd]
requires:
  - "05-02: PushEvent (dedupKey, intent, notification), KGNotification, NotificationCategory.streamerLive"
  - "05-04: PushMessagingPort.foregroundMessages, acceptPushEvent, FakePushMessagingPort.foreground"
  - "05-06: AuthenticatedShell notificationPermission field, PushServices as KlimmeckGuideApp.push"
  - "05-07: NotificationTapRouter provided above AuthGate, RecordingNotificationIntentSink, RecordingLinkOpener"
provides:
  - "ForegroundPushEvents.events (lib/repository/services/push/foreground_push_events.dart): onMessage -> acceptPushEvent -> Stream<PushEvent>, no LocalNotificationsPort"
  - "InAppNotificationsCubit + InAppNotificationsState (publish, dismiss, open, queue, 5 s auto-dismiss, dedup (type,id) 2 min / (type, sentAt minute) 15 min for streamerLive)"
  - "KgNotificationBanner (lib/shared/components/kg_notification_banner.dart): parchment strip on KGNotification, min height 44, max width 480, one semantics button"
  - "AuthenticatedShell.pushMessaging + BlocProvider<InAppNotificationsCubit> + _InAppNotificationOverlay (Stack + top SafeArea + AnimatedSwitcher 250 ms)"
  - "main.dart shellBuilder passes widget.push.messaging"
affects: [05-09, 07, 09]
tech-stack:
  added: []
  patterns:
    - "Single publication path cubit (publish) shared by every banner producer"
    - "Structural D-13 guarantee: the foreground feed has no system-notification dependency"
    - "Banner tap UI -> Cubit.open -> NotificationTapRouter (D-19)"
key-files:
  created:
    - lib/repository/services/push/foreground_push_events.dart
    - test/repository/services/push/foreground_push_events_test.dart
    - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart
    - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_state.dart
    - test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart
    - lib/shared/components/kg_notification_banner.dart
    - test/shared/components/kg_notification_banner_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/auth/authenticated_shell_test.dart
    - lib/main.dart
decisions:
  - "InAppNotificationsCubit.close() starts the subscription cancel, then awaits super.close() before the cancel, so isClosed is true as soon as the shell releases it"
  - "The banner semantics label is the title plus the description (the plan asked for a label containing the title), with a semantics onTap so screen readers can activate it"
  - "No MockInAppNotificationsCubit added to test/helpers/mocks.dart: the shell tests use the real cubit"
metrics:
  duration: "~12 min"
  completed: 2026-10-19
  tasks: 3
  files: 10
---

# Phase 5 Plan 08: Foreground In-App Banner Summary

When the app is in the foreground, a push now shows up only as an in-app banner. `ForegroundPushEvents` takes FCM `onMessage`, runs it through the shared `acceptPushEvent` filter (the shell user's toggles) and has no `LocalNotificationsPort` dependency, so it cannot raise a system notification. Every event then goes through `InAppNotificationsCubit.publish`, which queues it and drops duplicates (same `(type, id)` within 2 min, or the same `streamerLive` minute within 15 min). The cubit shows `KgNotificationBanner`, a themed parchment strip mounted in the authenticated shell, one at a time for 5 s. A tap calls `InAppNotificationsCubit.open(event)`, which dismisses the banner and then calls `NotificationTapRouter`. That gives the same landing as a system notification tap: the Map tab for travel/quest events, the Twitch channel for `streamerLive`.

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | ForegroundPushEvents feed + InAppNotificationsCubit | 82f6ca7 | bf5ed72 |
| 2 | KgNotificationBanner widget | c4d1da9 | 2340ac9 |
| 3 | Banner mount in AuthenticatedShell + main wiring | 488e756 | c195ec3 |

RED failures observed:
- Task 1: `Error when reading 'lib/repository/services/push/foreground_push_events.dart': No such file or directory`
- Task 2: `Error when reading 'lib/shared/components/kg_notification_banner.dart': No such file or directory`
- Task 3: `authenticated_shell_test.dart:115:17: Error: No named parameter with the name 'pushMessaging'.`

## Verification

- `flutter test`: **986 tests, all passed** (956 baseline + 30 new: 4 feed, 12 cubit, 7 banner, 7 shell)
- `flutter analyze`: **56 issues, 0 errors** (unchanged baseline); every touched file reports "No issues found!"
- `dart format --output=none --set-exit-if-changed` clean on all created/modified files. The four pre-existing files (`lib/main.dart`, `authenticated_shell.dart`, its test, `mocks.dart`) were format-clean at baseline and are still clean. `mocks.dart` was not touched.
- Acceptance greps: the feed has 0 `LocalNotificationsPort|.show(` and 1 `acceptPushEvent(`. The cubit has 1 each of the duration constants, `Future<void> open(PushEvent event)` and `_router.handle(event.intent)`, and 0 `BuildContext`/`material`. The banner has 0 `SnackBar|MaterialBanner|Scaffold|AppBar|Color(0x`. The shell has 1 provider, 1 `ForegroundPushEvents(`, 1 `.open(event)`, 0 `.handle(`, 1 `router: context.read<NotificationTapRouter>()`, 0 SnackBar/MaterialBanner/ScaffoldMessenger. `lib/screens/characterCreation` has no `InAppNotificationsCubit`.
- Tests never import the push plugins (only the pre-existing `push_boundaries_test.dart` mentions them, as a boundary check).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `InAppNotificationsCubit.close()` never reported closed under the shell**
- **Found during:** Task 3 (shell test "closes the in-app notifications cubit on removal")
- **Issue:** The planned `await _subscription.cancel(); return super.close();` kept `isClosed` false after the shell was disposed. The cancel future of the `asyncExpand` stream is completed in the root zone, so it never resolves inside the widget test's fake-async zone, and `super.close()` was never reached. In a real app this would also delay the close until a later microtask.
- **Fix:** Start the cancel, `await super.close()`, then `await` the cancel. The subscription is still cancelled first and synchronously, so no event can be published after close.
- **Files modified:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart`
- **Commit:** c195ec3

**2. [Grep acceptance / formatter] `pushMessaging: widget.push.messaging` in `lib/main.dart`**
- `grep -c "pushMessaging: widget.push.messaging" lib/main.dart` returns 0 only because `dart format` splits the argument across two lines (`pushMessaging:` / `widget.push.messaging,`) at that nesting depth. The wiring is in place (lines 341-342). The formatted code was kept, as instructed.

**3. [Minor] Banner dartdoc reworded**
- The planned dartdoc mentioned "SnackBar/MaterialBanner", which tripped the chrome grep (count 1). It now reads "nessun componente di sistema". No behaviour change.

**4. [Rule 2 - Accessibility] Semantics carries the description and a tap action**
- `excludeSemantics: true` hid the InkWell's tap action, so the `Semantics` wrapper now also has `onTap`. The label is "title. description", so a screen reader user hears the whole banner. It still contains the title as required.

The 900 px surface in the plan's behaviour list is `useLandscapePhone` (780x360 logical). The width assertion (≤ 480) holds there.

## Known Stubs

None.

## Threat Flags

None. The tap route, the toggle filter and the URL constant match T-05-08-01..05.

## Self-Check: PASSED

- All 7 created files exist; all 6 task commits (82f6ca7, bf5ed72, c4d1da9, 2340ac9, 488e756, c195ec3) are in `git log`.
