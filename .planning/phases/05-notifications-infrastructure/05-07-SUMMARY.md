---
phase: 05-notifications-infrastructure
plan: 07
subsystem: push-tap-routing
tags: [notifications, tap, intent, cubit, deep-link, twitch, map-tab, tdd]
requires:
  - "05-02: NotificationIntent, NotificationCategory.isPersonal, TwitchChannel.uri"
  - "05-04: LinkOpener, UrlLauncherLinkOpener, LocalNotificationsPort.taps, PushServices.launchIntent, RecordingLinkOpener"
  - "05-06: main.dart provider chain with RepositoryProvider<NotificationPermissionGate>"
provides:
  - "NotificationIntentSink (lib/repository/services/push/notification_intent_sink.dart)"
  - "NotificationIntentCubit + NotificationIntentState (offer, consume, cleared on Authenticated -> Unauthenticated and on the creation page)"
  - "NotificationTapRouter.handle(intent): personal -> sink.offer, streamerLive -> LinkOpener.open(TwitchChannel.uri)"
  - "main.dart: taps from the alive app and the launch tap (after first frame) routed through one router; RepositoryProvider<NotificationTapRouter> + BlocProvider<NotificationIntentCubit> above AuthGate (for plan 08 banner)"
  - "NotificationIntentLanding around the MainScreen PageView (hasClients guard, popUntil root, jumpToPage(0), per-type popup hook)"
  - "NotificationPopup typedef + empty defaultNotificationPopups for Phases 7/9"
  - "RecordingNotificationIntentSink test fake"
affects: [05-08, 05-09, 07, 09]
tech-stack:
  added: []
  patterns:
    - "Process-wide buffered intent cubit above AuthGate, cleared by auth transitions"
    - "Declarative consumer widget around the PageView instead of an imperative global router"
key-files:
  created:
    - lib/repository/services/push/notification_intent_sink.dart
    - lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart
    - lib/screens/auth/notificationIntentCubit/notification_intent_state.dart
    - test/screens/auth/notificationIntentCubit/notification_intent_cubit_test.dart
    - lib/repository/services/push/notification_tap_router.dart
    - test/repository/services/push/notification_tap_router_test.dart
    - test/helpers/fakes/recording_notification_intent_sink.dart
    - lib/screens/mainScreen/components/notification_popup_registry.dart
    - lib/screens/mainScreen/components/notification_intent_landing.dart
    - test/screens/mainScreen/components/notification_intent_landing_test.dart
  modified:
    - lib/main.dart
    - lib/screens/mainScreen/main_screen.dart
decisions:
  - "The intent cubit and the router are owned by _KlimmeckGuideAppState (late final) and provided with .value, so the alive-tap subscription and the launch tap share the instance the widgets read"
  - "The launch tap is routed in a post-frame callback; personal intents then wait in the cubit until NotificationIntentLanding mounts"
  - "Pending intents are consumed only when the PageController has clients; otherwise they stay pending (Pitfall 14)"
metrics:
  duration: "~20 min"
  completed: 2026-10-19
  tasks: 3
  files: 12
---

# Phase 5 Plan 07: Notification tap routing Summary

Every notification tap (system notification while alive, the tap that launched the app, later the in-app banner) goes through one `NotificationTapRouter`. Personal types (`travelEnd`, `questEnd`) are held in a `NotificationIntentCubit` above `AuthGate` until `MainScreen` lands on the Map tab. `streamerLive` opens only `TwitchChannel.uri`, externally, through `LinkOpener`. FCM `onMessageOpenedApp`/`getInitialMessage` are not used.

## Tasks

| Task | Name | RED commit | GREEN commit |
|------|------|------------|--------------|
| 1 | NotificationIntentCubit: buffer the tap across splash and sign-in, clear at session end | 468b09b | 16dc9d9 |
| 2 | NotificationTapRouter and tap-source wiring in main.dart | 5e26f8d | 7bac097 |
| 3 | Map-tab landing in MainScreen with the empty per-type popup hook | 76f7042 | 5f4bbfe |

RED failures observed:
- Task 1: `Error when reading 'lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart': No such file or directory`
- Task 2: `Error when reading 'lib/repository/services/push/notification_tap_router.dart': No such file or directory`
- Task 3: `Error when reading 'lib/screens/mainScreen/components/notification_intent_landing.dart': No such file or directory`

## Verification

- `flutter test`: **956 tests, all passed** (938 baseline + 8 cubit + 5 router + 5 landing).
- `flutter analyze`: **56 issues, 0 errors** (unchanged baseline); every touched file reports "No issues found!".
- `test/screens/mainScreen/main_screen_test.dart` unchanged (`git diff --quiet HEAD` passes), `flutter test test/screens/mainScreen` green (112).
- `grep -rn "onMessageOpenedApp\|getInitialMessage" lib | wc -l` = 0.
- Router: `TwitchChannel.uri` count 1, `Uri.parse|intent.id` count 0. Tests never import `url_launcher` or `flutter_local_notifications`; `push_boundaries_test` still green.
- `lib/main.dart` and `lib/screens/mainScreen/main_screen.dart` were formatter-clean at baseline and remain formatter-clean.

## Deviations from Plan

### Formatter line splits (acceptance greps, behaviour unchanged)

`dart format` split a few single-line acceptance patterns. The formatted code was kept:
- `class NotificationIntentCubit extends Cubit<NotificationIntentState>` / `implements NotificationIntentSink {` is now on two lines.
- `main.dart`: `taps.listen(` / `_tapRouter.handle,` and `addPostFrameCallback(` / `(_) => _tapRouter.handle(intent),` are now on two lines each.
- `defaultNotificationPopups =` / `{};` is now on two lines.

### Doc comment wording in the router

The router's doc comment refers to `[TwitchChannel]` instead of `[TwitchChannel.uri]`, so that the acceptance count `grep -c "TwitchChannel.uri"` = 1 matches the code line only.

### Commit subject

The Task 3 RED subject reads "…landing on map tab" (the "the" was dropped to stay under 72 characters). There was no rewrite.

No auto-fixed bugs (Rules 1-3) and no architectural changes.

## Threat Model Coverage

- T-05-07-01: the router opens only `TwitchChannel.uri`. A test with an id-bearing `streamerLive` intent asserts the URL.
- T-05-07-02: the intent is cleared on `Authenticated -> Unauthenticated` and on the creation page (cubit tests).
- T-05-07-03: the `hasClients` guard is in place. A test covers an intent pending before mount, consumed on the first frame.
- T-05-07-04: unchanged; the plan 04 adapter's `tryFromPayload` drops malformed payloads.

## Known Stubs

- `defaultNotificationPopups` is empty on purpose (D-15, user decision). Phase 7 adds `travelEnd` and Phase 9 adds `questEnd`.

## Self-Check: PASSED

All created files exist, and commits 468b09b, 16dc9d9, 5e26f8d, 7bac097, 76f7042 and 5f4bbfe are in `git log`.
