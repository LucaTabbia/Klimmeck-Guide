---
phase: 06-quest-accept-info-sheets
plan: 04
subsystem: notifications
tags: [in-app-banner, cubit, tdd, quest-acceptance]
requires: []
provides:
  - InAppNotificationsCubit.publishNotice(KGNotification, dedupKey:)
  - InAppNotice + InAppNotificationsState.notice / isShowing
  - shell overlay rendering notices (tap = dismiss)
  - MockInAppNotificationsCubit
affects: [06-03, 06-05]
tech-stack:
  added: []
  patterns: [shared heterogeneous banner queue (PushEvent | InAppNotice)]
key-files:
  modified:
    - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart
    - lib/screens/auth/inAppNotificationsCubit/in_app_notifications_state.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/helpers/mocks.dart
decisions:
  - "Notices share the push queue and timer; dedup window equals the display duration, key namespaced 'notice|'"
  - "Notice tap calls dismiss() only; the tap router is never involved"
metrics:
  tasks: 2
  tests: "1049 -> 1060 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 04: Domain notices on the in-app banner Summary

`publishNotice` puts local domain notices (quest acceptance errors, D-04) into the Phase 5 parchment strip with the same queue, 5 s timer and look as push banners; a notice tap only dismisses it.

## Commits

- 0576cfd `test(notifications): add failing tests for local domain notices` (RED: `publishNotice` undefined)
- 5e5bb7f feat(notifications): publish local domain notices in the in-app banner
- 1b841e8 test(notifications): add failing tests for rendering domain notices (RED: notice text not found)
- e57104a feat(notifications): show domain notices above the game

## Deviations from Plan

- [Rule 1 - cleanup] Removed the now-unused `push_event.dart` import from `authenticated_shell.dart` (caused by the `_bannerFor` signature change; keeps analyze at 56).
- The third shell test (auto-hide after 5 s) passes trivially in RED because nothing renders yet; the other two failed as expected.

## Known Stubs

None.

## Self-Check: PASSED
