---
phase: 12-hardening
plan: 09
subsystem: auth
tags: [hardening, auth, leak-tracking, identity, push]
requires: ["12-08"]
provides:
  - "test/helpers/leak_tracking_bloc_observer.dart: LeakTrackingBlocObserver (test-only BlocObserver dispatching cubit create/close to leak_tracker)"
  - "test/screens/auth/authenticated_shell_leak_test.dart: HARDEN-05 shell-level leak test (notDisposed + hasListener + WeakReference/forceGC) with two observer self-checks"
  - "test/screens/auth/identity_transitions_test.dart: HARDEN-06 cross-device identity sequence over the real SessionSyncScope + AuthGate + SessionHome"
  - "NotificationIntentCubit drops a pending tap on a direct user change"
affects: [12-15, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "LeakTesting.enable() in the file's main() only; Bloc.observer saved/restored per test; experimentalLeakTesting per testWidgets"
    - "runAsync(pumpEventQueue) before runAsync(forceGC) so async disposals settle before the retention check"
    - "Theme fonts settled once in setUpAll inside runZonedGuarded (google_fonts loads fail under the real event loop)"
key-files:
  created:
    - test/helpers/leak_tracking_bloc_observer.dart
    - test/screens/auth/authenticated_shell_leak_test.dart
    - test/screens/auth/identity_transitions_test.dart
  modified:
    - lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart
    - test/screens/auth/notificationIntentCubit/notification_intent_cubit_test.dart
decisions:
  - "The shell leak test ignores only the framework class ImageStreamCompleterHandle (sign-in logo still loading in the process image cache); no gameplay cubit is ignored, withIgnoredAll is never used"
  - "NotificationIntentCubit clears on previous.user.id != next.user.id (D-11); a same-user refresh keeps the pending tap"
metrics:
  duration: "~50 min"
  completed: 2026-11-09
---

# Phase 12 Plan 09: Shell leak test, identity transitions and the pending-tap gap Summary

HARDEN-05 and HARDEN-06 proven at shell level: logging out of the real authenticated shell closes all 22 shell cubits (plus `SessionSyncCubit`), cancels all five live fake subscriptions and lets every cubit and the `ServerClockService` be garbage collected; the cross-device identity sequence rebuilds the keyed subtrees through the real `SessionSyncCubit` → `adoptUser` path; the one gap the research flagged (a pending push tap surviving a direct `Authenticated(A)` → `Authenticated(B)`) was confirmed RED and fixed.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 1 | LeakTrackingBlocObserver and the shell leak test (HARDEN-05) | 11a3df9 | test/helpers/leak_tracking_bloc_observer.dart, test/screens/auth/authenticated_shell_leak_test.dart |
| 2 | Cross-device identity transitions (HARDEN-06) | 4bbacc4 | test/screens/auth/identity_transitions_test.dart |
| 3 | RED: pending tap on a user change | 0d3f2cd | test/screens/auth/notificationIntentCubit/notification_intent_cubit_test.dart |
| 3 | GREEN: drop the pending tap on a user change | 89a4d8c | lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart |

## Per-case outcome

Task 1 (`authenticated_shell_leak_test.dart`, 5 tests):
- «the observer dispatches one create and one close per cubit (D-05)» — green at first run (the observer works); it also asserts `leaks.notDisposed` empty after `declareNotDisposedObjectsAsLeaks()`, so a missing `dispatchObjectDisposed` would fail it.
- «an unclosed cubit is reported as notDisposed (D-05)» — green at first run; it fails if `dispatchObjectCreated` is removed (T-12-28).
- «logout leaves no cubit undisposed or reachable (D-05)», «logout cancels every live subscription of the shell (D-05)», «logout shows the sign-in screen (D-05)» — green on the current product once the harness issues below were fixed (the shell already closes its cubits, Phase 3/11). No product leak found.
- Mutation check (not committed): an unclosed `_ProbeCubit` created in the probe's `initState` made the file fail at `tearDownAll` with three `_ProbeCubit` notDisposed entries, so the test can fail.

Task 2 (`identity_transitions_test.dart`, 4 tests): all green at first run — D-11 «already the design» (`AuthGate` keys on `user.id`, `SessionHome` on `character:<id>`, the gate listener pops root routes on a character/user change).

Task 3: «a direct switch to another user drops the pending tap (D-11)» RED as expected (actual states `[pending]`, expected `[pending, empty]`); «a refresh of the same user keeps the pending tap (D-11)» green at RED time (guard of the fix). Both green after the fix.

## Leak tracker calls used by the self-checks

Group `LeakTrackingBlocObserver` (plain `test(...)`, declared before the widget tests so tracking is not started yet):
- `setUp`: `startedHere = !LeakTracking.isStarted; if (startedHere) LeakTracking.start(config: LeakTrackingConfig.passive());` then `previousPhase = LeakTracking.phase; LeakTracking.phase = const PhaseSettings(name: 'observer self-check');` (the phase left by a `testWidgets` teardown is `PhaseSettings.ignored()`, which would make `startTracking` a no-op).
- body: `LeakTracking.declareNotDisposedObjectsAsLeaks(); final leaks = await LeakTracking.collectLeaks();` (`collectLeaks` drains `gcedNotDisposedLeaks`, so nothing leaks into the file-level report); the unclosed cubit is closed after the collection.
- `tearDown`: `LeakTracking.phase = previousPhase; if (startedHere) LeakTracking.stop();`.
- `leaks.notDisposed.single.type` contains `_ProbeCubit` (type = `package:bloc/bloc.dart/_ProbeCubit`-style full class name).

## withIgnored

- `ImageStreamCompleterHandle` — `LeakTesting.settings.withTrackedAll().withIgnored(classes: ['ImageStreamCompleterHandle'])` (helper `_shellLeakTesting()`): the `Image.asset` logo of `SignInScreen` is still loading in the process-wide image cache when the last test ends; the handle belongs to the framework cache, not to the session. `imageCache..clear()..clearLiveImages()` in the group `tearDown` disposes the resolved `Image`/`ImageInfo`/`_CachedImage` of the earlier tests, so only that one class is ignored.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] google_fonts loads fail under `tester.runAsync`**
- **Found during:** Task 1
- **Issue:** `forceGC` inside `tester.runAsync` lets the real event loop run; the pending `GoogleFonts` loads of `KlimmeckGuideTheme` (fonts not bundled, `allowRuntimeFetching = false`) then fail as uncaught errors in the test (the fake zone of other widget tests never completes them).
- **Fix:** `setUpAll(_settleThemeFonts)`: builds `KlimmeckGuideTheme.instance` once inside `runZonedGuarded` and awaits `GoogleFonts.pendingFonts()` with the errors swallowed; the theme fields are built once, so no later load is triggered.
- **Files modified:** test/screens/auth/authenticated_shell_leak_test.dart
- **Commit:** 11a3df9

**2. [Rule 3 - Blocking] `ServerClockService` still reachable right after one forceGC**
- **Found during:** Task 1
- **Issue:** with a single `runAsync(forceGC)` the clock (disposed by its `RepositoryProvider` through `unawaited(clock.dispose())`) was still reachable; one more real event-loop turn released it (verified: a second `runAsync` makes `formattedRetainingPath` return null). It is the async disposal still in flight, not a retention.
- **Fix:** `await tester.runAsync(pumpEventQueue);` before `await tester.runAsync(() => forceGC(fullGcCycles: 3, timeout: const Duration(seconds: 10)));`, with a comment. A really retained object stays reachable after both.
- **Files modified:** test/screens/auth/authenticated_shell_leak_test.dart
- **Commit:** 11a3df9

**3. [Rule 3 - Blocking] import of `flutter_bloc` instead of `package:bloc/bloc.dart` in the helper**
- **Found during:** Task 1
- **Issue:** `bloc` is not a direct dependency (only `flutter_bloc`); importing it would add a `depend_on_referenced_packages` analyzer info.
- **Fix:** the helper imports `package:flutter_bloc/flutter_bloc.dart` (re-exports `BlocObserver`/`BlocBase`); the `library:` label stays `'package:bloc/bloc.dart'` as in the plan skeleton.
- **Commit:** 11a3df9

Otherwise the plan executed as written.

## Gates

- `flutter analyze`: 47 issues, all info, 0 error, 0 warning (unchanged baseline).
- `flutter test test/screens/auth/authenticated_shell_leak_test.dart`: 5 passed (+ leak-free `tearDownAll`).
- `flutter test test/screens/auth/identity_transitions_test.dart test/screens/auth/auth_gate_test.dart test/screens/auth/session_home_test.dart`: 31 passed.
- `flutter test test/screens/auth test/repository/services/push`: 257 passed.
- `bash tool/hardening_check.sh`: `hardening_check: OK`.
- `dart format` on the five touched files one by one: all clean (none was formatter-dirty).
- No `flutter build` in this plan.

## Known Stubs

None.

## Self-Check: PASSED
