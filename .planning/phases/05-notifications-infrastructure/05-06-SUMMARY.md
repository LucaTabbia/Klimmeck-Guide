---
phase: 05-notifications-infrastructure
plan: 06
subsystem: push-permission
tags: [permission, permission_handler, settings, cubit, foreground-recheck, static-guard, tdd]
requires:
  - "05-04: NotificationPermissionPort, PermissionHandlerNotificationPermission, PushServices.permission, FakeNotificationPermissionPort"
  - "05-05: main.dart composition root with KlimmeckGuideApp.push"
provides:
  - "NotificationPermissionGate.ensureRequested() (lib/repository/services/push/notification_permission_gate.dart): prompts only on notDetermined, in-flight dedup, nothing persisted"
  - "RepositoryProvider<NotificationPermissionGate> above AuthCubit/AuthGate in main.dart, for Phase 7's first travel confirmation"
  - "push_boundaries_test group 'permission prompt (NOTIF-02)': no ensureRequested( outside the gate; main/AuthGate/Splash/Settings never contain ensureRequested(, Permission.notification, .request()"
  - "NotificationPermissionCubit + NotificationPermissionState (showsDisabledHint == denied), refresh() at shell mount and on every AppLifecycleEvents.foregrounded, openSettings()"
  - "AuthenticatedShell.notificationPermission (required) + BlocProvider<NotificationPermissionCubit>"
  - "NotificationPermissionHint (message/actionLabel constants) under the three toggles of NotificationPreferencesSection"
  - "MockNotificationPermissionCubit in test/helpers/mocks.dart"
affects: [05-07, 05-08, 05-09, 07]
tech-stack:
  added: []
  patterns:
    - "Single sanctioned prompt entry point guarded by a static source scan"
    - "Read-only permission cubit re-checked on foreground (return from system settings) without spinner"
key-files:
  created:
    - lib/repository/services/push/notification_permission_gate.dart
    - test/repository/services/push/notification_permission_gate_test.dart
    - lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart
    - lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_state.dart
    - test/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit_test.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_permission_hint.dart
    - test/screens/mainScreen/tabs/settings/components/notification_permission_hint_test.dart
  modified:
    - test/repository/services/push/push_boundaries_test.dart
    - lib/main.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/helpers/mocks.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
    - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
    - test/screens/mainScreen/tabs/settings/settings_test.dart
decisions:
  - "NotificationPermissionCubit.close() runs super.close() in parallel with the subscription cancel (Future.wait, as CharacterCubit does) so a provider that closes without awaiting sees isClosed at once"
metrics:
  duration: "~25 min"
  completed: 2026-10-19
  tasks: 3
  files: 15
---

# Phase 5 Plan 06: Notification permission gate and Settings hint Summary

Phase 7 gets one idempotent `NotificationPermissionGate.ensureRequested()` (prompts only while the OS is `notDetermined`, concurrent callers share one dialog, nothing persisted). A static guard checks that no Phase 5 surface ever calls it. Settings gets a read-only `NotificationPermissionCubit` that re-reads the OS status at shell mount and on every return to the foreground, plus a row "Le notifiche di sistema sono disattivate" + "Attiva" that shows only when the permission is denied.

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | Gate for Phase 7, never-called guard, provider above AuthGate | 5f445ad | 5a81c25 |
| 2 | NotificationPermissionCubit with foreground re-check, provided by the shell | ff90170 | 4dea30c |
| 3 | Denied-only hint row under the notification toggles | d45acef | d51280c |

RED evidence:
- Task 1: `notification_permission_gate_test.dart:2:8: Error: Error when reading 'lib/repository/services/push/notification_permission_gate.dart': No such file or directory` (the two new boundaries checks already passed, as planned)
- Task 2: `notification_permission_cubit_test.dart:5:8: Error: Error when reading 'lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart': No such file or directory`
- Task 3: `notification_preferences_section_test.dart:7:8: Error: Error when reading 'lib/screens/mainScreen/tabs/settings/components/notification_permission_hint.dart': No such file or directory`

## Verification

- `flutter test`: **938 tests, all passed** (baseline 912; +8 after Task 1, +9 after Task 2, +9 after Task 3)
- `flutter analyze`: **56 issues, 0 errors** (unchanged baseline); every touched file reports "No issues found!"
- `grep -rl "ensureRequested(" lib` prints only `lib/repository/services/push/notification_permission_gate.dart`
- `grep -rn "ensureRequested\|\.request()" lib/screens/mainScreen/tabs/settings | wc -l` = 0
- Gate has no `SharedPreferences|setBool|setString`; hint has no `SnackBar|AlertDialog|CircularProgressIndicator|Color(0x`
- Cubit tests assert `requestCalls == 0` in a tearDown for every case; the shell test checks `requestCalls == 0` too
- Tests import no push plugin (boundaries test green)
- Format: every pre-existing touched file was formatter-clean at baseline and stays clean; `dart format` was only run on touched files by path

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Cubit not closed synchronously on shell removal**
- **Found during:** Task 2 (shell test "provides the system permission status read once at mount")
- **Issue:** the planned `close() async { await _foregrounded.cancel(); return super.close(); }` delays `super.close()` past an await. `BlocProvider` disposes without awaiting, so `isClosed` was still false right after the shell was removed.
- **Fix:** `Future<void> close() => Future.wait([_foregrounded.cancel(), super.close()]);` (same pattern as `CharacterCubit.close()`), with a dartdoc explaining why
- **Files modified:** lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart
- **Commit:** 4dea30c

### Formatting-only acceptance mismatches (behaviour correct, formatted code kept)

- `grep -c "notificationPermission: widget.push.permission" lib/main.dart` = 0: `dart format` splits the argument over two lines (`notificationPermission:` / `widget.push.permission,`) because of the shellBuilder nesting depth. The wiring is there (line ~303).
- The gate's `ensureRequested()` body is split by the formatter onto a second line. The signature grep `Future<NotificationPermissionStatus> ensureRequested()` still matches 1.

### Minor

- Task 1 GREEN subject shortened to `feat(push): add the notification permission gate for travel confirmation` to stay within 72 chars.
- The section dartdoc from the plan is wrapped onto two lines (same text).

## Known Stubs

None. `NotificationPermissionGate` has no call site on purpose: Phase 7 adds the only sanctioned call at the first travel confirmation (D-10), and the guard test `only the gate defines ensureRequested` must be updated to allow that call site at that point.

## Threat Flags

None. The surface (OS prompt, system settings link) is covered by T-05-06-01..04.

## Self-Check: PASSED

- FOUND: all 7 created files
- FOUND: commits 5f445ad, 5a81c25, ff90170, 4dea30c, d45acef, d51280c
