---
phase: 05-notifications-infrastructure
plan: 05
subsystem: push-registration
tags: [fcm, push, registration, logout, auth-cubit, silent-retry, fake_async, tdd]
requires:
  - "05-03: PushDeviceRepository, PushDeviceFailure, DeviceIdentityStore, ActiveUserStore"
  - "05-04: PushMessagingPort, LocalNotificationsPort, PushServices, KlimmeckGuideApp.push, test fakes"
provides:
  - "PushSessionCleanup + NoPushSessionCleanup (lib/repository/services/push/push_session_cleanup.dart)"
  - "AuthCubit(service, {pushCleanup}) + AuthCubit.pushUnregisterTimeout (2 s); logout() = unregister (capped, failures swallowed) -> service.logout()"
  - "PushRegistrationCoordinator (start, unregister, dispose): one registration per user id per process, refresh re-register, silentRetry 5 attempts / 30 s cap, suspension + generation cancel, _hasSeenToken early return, session end clears ActiveUserStore + cancelAll()"
  - "MockPushSessionCleanup in test/helpers/mocks.dart"
  - "Composition-root wiring: _pushCoordinator in _KlimmeckGuideAppState, started in initState, disposed in dispose, passed to AuthCubit"
affects: [05-06, 05-07, 05-08, 05-09]
tech-stack:
  added: []
  patterns:
    - "Orchestration in the cubit through an optional named port, frozen service contract untouched"
    - "Generation counter + suspension flag fed to silentRetry.isCancelled to kill stale retries"
key-files:
  created:
    - lib/repository/services/push/push_session_cleanup.dart
    - lib/repository/services/push/push_registration_coordinator.dart
    - test/repository/services/push/push_registration_coordinator_test.dart
  modified:
    - lib/screens/auth/cubit/auth_cubit.dart
    - test/screens/auth/cubit/auth_cubit_test.dart
    - test/helpers/mocks.dart
    - lib/main.dart
decisions:
  - "unregister() moves the device-id read inside the guarded block (block body instead of the plan's one-liner) so a storage failure is swallowed like a network one"
  - "dispose() also nulls _sessionUserId so late in-flight retries are inert"
metrics:
  duration: "~20 min"
  completed: 2026-10-19
  tasks: 3
  files: 7
---

# Phase 5 Plan 05: Push registration lifecycle and logout ordering Summary

`AuthCubit.logout()` now awaits an optional `PushSessionCleanup` (capped at 2 s, every failure swallowed with a `runtimeType`-only log) before the backend logout, without touching the frozen `AuthTokenService` contract. `PushRegistrationCoordinator` owns the registration lifecycle for the whole process: one registration per user id (re-emitted `AuthAuthenticated` ignored), re-registration on token refresh, a missing token waits for `tokenRefreshes` without retrying, bounded silent retry (5 attempts, 30 s cap; `invalidToken`/`invalidDeviceId`/`unauthenticated` stop at once), suspension + generation bump on `unregister()` so no retry or refresh can race back before logout, no network call and no wait when no token was ever seen, and at session end the active-user mirror is cleared and the tray emptied (only after a real session). `main.dart` creates the coordinator, starts it in `initState` and passes it to `AuthCubit`.

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 RED | Failing tests for unregistering push before logout (+ MockPushSessionCleanup) | 8592c54 | auth_cubit_test.dart, mocks.dart |
| 1 GREEN | PushSessionCleanup + AuthCubit.logout() ordering with the 2 s ceiling | 2597cc0 | push_session_cleanup.dart, auth_cubit.dart |
| 2 RED | Failing tests for the push registration coordinator | 3f87115 | push_registration_coordinator_test.dart |
| 2 GREEN | PushRegistrationCoordinator | 60c6140 | push_registration_coordinator.dart |
| 3 | Composition-root wiring | 1662ef6 | lib/main.dart |

No REFACTOR commit: nothing to clean after GREEN.

## TDD evidence

- Task 1 RED: `test/helpers/mocks.dart:14:8: Error: Error when reading 'lib/repository/services/push/push_session_cleanup.dart': No such file or directory` / `test/screens/auth/cubit/auth_cubit_test.dart:186:24: Error: Member not found: 'pushUnregisterTimeout'.`
- Task 1 GREEN: `flutter test test/screens/auth test/shared/components/modal` -> `+112: All tests passed!` (5 new logout tests incl. fake_async 1999 ms / 2000 ms)
- Task 2 RED: `push_registration_coordinator_test.dart:7:8: Error: Error when reading 'lib/repository/services/push/push_registration_coordinator.dart': No such file or directory`
- Task 2 GREEN: `flutter test test/repository/services/push` -> `+49: All tests passed!` (26 existing + 23 new)

## Verification

- `flutter test` (full): **912 passed** (884 baseline + 5 AuthCubit + 23 coordinator), 0 failed
- `flutter analyze`: **56 issues, 0 errors** (baseline unchanged); every touched file `No issues found!`
- `flutter build apk --debug`: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`
- `git diff --stat -- lib/repository/services/auth` empty (frozen contract untouched)
- Acceptance greps: `pushUnregisterTimeout = Duration(seconds: 2);` 1, `PushSessionCleanup pushCleanup = const NoPushSessionCleanup()` 1, `_unregisterPushDevice()` before `_authTokenService.logout()`, `MockPushSessionCleanup` 1, `class PushRegistrationCoordinator implements PushSessionCleanup` 1, `maxRegistrationAttempts = 5;` 1, `silentRetry` 1, `_hasSeenToken` 3, bloc/material/widgets/BuildContext 0, permission request 0, `late final PushRegistrationCoordinator _pushCoordinator` 1, `_pushCoordinator.start();` 1, `_pushCoordinator.dispose()` 1, `ensureRequested|Permission.` in main.dart 0
- Test names include "re-emissions" (Pitfall 4) and "cancels a pending retry" (Pitfall 5)
- Formatting: `main.dart`, `auth_cubit.dart`, `auth_cubit_test.dart`, `mocks.dart` were formatter-clean at baseline (`--set-exit-if-changed` exit 0) and stay clean; new files formatted by path; no directory format

## Deviations from Plan

**1. [Formatter] `AuthCubit(widget.authTokenService, pushCleanup: _pushCoordinator)` is wrapped by `dart format`**
- The single-line acceptance grep returns 0 because the formatter splits the call over three lines (`AuthCubit(` / `widget.authTokenService,` / `pushCleanup: _pushCoordinator,`). The plan's automated verify (`grep -q "pushCleanup: _pushCoordinator"`) passes; formatter-clean output was kept.

**2. [Rule 2 - Robustness] device-id read inside the guarded unregister**
- The coordinator's `unregister()` reads the device id inside `_guarded`, so a storage failure is swallowed like a network one and never surfaces to `AuthCubit` (which would catch it anyway). Same behaviour otherwise.

No other deviation; no commit message rewritten.

## Known Stubs

None. (`LinkOpener` still has no caller: plan 05-07.)

## Threat Flags

None: T-05-05-01..05 mitigated as planned (unregister-first + suspension + mirror/tray clear; 2 s timeout; per-user dedup + bounded retry; logs carry failure names/`runtimeType` only; generation counter checked by `silentRetry.isCancelled`).

## Self-Check: PASSED

- Created files present: push_session_cleanup.dart, push_registration_coordinator.dart, push_registration_coordinator_test.dart
- Commits 8592c54, 2597cc0, 3f87115, 60c6140, 1662ef6 present in `git log`; no `Co-Authored-By` trailer in any of them
