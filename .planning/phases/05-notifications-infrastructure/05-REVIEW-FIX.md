---
phase: 05-notifications-infrastructure
fixed_at: 2026-10-20T00:00:00Z
review_path: .planning/phases/05-notifications-infrastructure/05-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
skipped: 0
status: complete
---

# Phase 5: Code Review Fix Report

**Source review:** .planning/phases/05-notifications-infrastructure/05-REVIEW.md
**Iteration:** 1

Gates: `flutter test` is green with 1006 tests (baseline 986, 20 new). `flutter analyze` stays at 56 issues with 0 errors. All of them were there before, and none is in a touched file. Every touched Dart file passes `dart format --set-exit-if-changed`. The tests still never import a push plugin (`push_boundaries_test` is green).

| Finding | Outcome | Commit |
|---------|---------|--------|
| WR-01 | fixed: requires human verification (race logic) | 98a7ccd |
| WR-02 | fixed: requires human verification (retry logic) | 7fef522 |
| WR-03 | fixed: requires human verification (ordering logic) | 1ef63a3 |
| IN-01 | fixed | 089ab6f |
| IN-02 | fixed | d2973e5 |
| IN-03 | fixed (pure move/rename) | f4596ba |
| IN-04 | fixed | 2c6e5cc |
| IN-05 | fixed (dedup now by type for `streamerLive`) | 49d1057 |
| IN-06 | fixed (docs) | 61e0bfd |

## Fixed Issues

### WR-01: `unregister()` does not wait for an in-flight registration

**Files modified:** `lib/repository/services/push/push_registration_coordinator.dart`, `test/repository/services/push/push_registration_coordinator_test.dart`, `test/helpers/fakes/fake_push_messaging_port.dart`
**Commit:** 98a7ccd
**Tests added:** three tests. (1) A register held on a `Completer`: unregister waits, and `verifyInOrder` checks register before unregister. (2) A register that never completes: the removal goes out after `registrationDrainTimeout`, and that timeout is shorter than `AuthCubit.pushUnregisterTimeout`. (3) A token that arrives after the suspension is not registered. Tests 1 and 3 were red first.
**Applied fix:** The coordinator now tracks the attempt in flight (`_attemptInFlight`), not the whole retry. This way it never waits through a backoff delay. `unregister()` suspends, bumps the generation, then awaits that attempt, capped at 1 s (`registrationDrainTimeout`). The rest of the 2 s budget in D-08 is left for the removal mutation. `_registerOnce` also checks cancellation after it gets the token, so a `token()` call that resolves late can no longer send a register. One change goes beyond the review's snippet: `_hasSeenToken` is now checked after the drain, and the suspension also applies when push is off. Before, an attempt still waiting for its first token returned early without suspending. The "push disabled skips any wait" test is still green.

### WR-02: Registration gives up after about 15 s with no later trigger

**Files modified:** `lib/repository/services/push/push_registration_coordinator.dart`, `lib/main.dart`, `test/repository/services/push/push_registration_coordinator_test.dart`
**Commit:** 7fef522
**Tests added:** four tests. (1) Retries exhausted, then a foreground: one new attempt (red first). (2) After a success, a foreground does nothing. (3) A foreground while retries are still running does nothing. (4) A foreground after the session ended does nothing.
**Applied fix:** A new optional `foregrounds` stream parameter defaults to an empty stream, so existing constructor calls still compile. `main.dart` passes `_lifecycleBus.foregrounded`. `onGiveUp` sets `_retryOnForeground`. On the next foreground, if a session is active and not suspended, the coordinator runs a new silent, bounded `_register()`. The flag is cleared when a registration starts and when the session ends. There is no UI. A successful registration still happens once per user per process (D-07).

### WR-03: Auth-state handlers are not serialised

**Files modified:** `lib/repository/services/push/push_registration_coordinator.dart`, `test/repository/services/push/push_registration_coordinator_test.dart`, `test/helpers/fakes/in_memory_active_user_store.dart`
**Commit:** 1ef63a3
**Test added:** the `InMemoryActiveUserStore` write is held on a `pendingWrite` completer, and `Unauthenticated` arrives during it. The final `userId` must be null. It was red first: the value was `'u-1'`, which is the privacy leak.
**Applied fix:** I chose a future chain (`_authQueue = _authQueue.then(...)`) over `asyncMap`. That way the fix does not depend on how a paused broadcast subscription buffers events. `_onAuthState` never throws because each step is guarded, so the chain cannot break. D-09 holds: the active user is always cleared after any pending write.

### IN-01: `open(event)` dismisses the current banner, not the tapped one

**Files modified:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart`, its test
**Commit:** 089ab6f
**Test added:** A and B are queued. After a dismiss, B is current. Then `open(A)` routes A's intent and B stays current. It was red first.
**Applied fix:** `if (state.current == event) dismiss();` runs before routing. The existing test "open dismisses the banner before routing" still holds.

### IN-02: `publish`/`dismiss` after `close()` still touch queue and timer

**Files modified:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart`, its test
**Commit:** d2973e5
**Tests added:** after `close()`, `publish` arms no timer, and neither does `dismiss` with events queued. Both were red first.
**Applied fix:** `if (isClosed) return;` at the top of `publish`. `_showNext` cancels the timer and then returns if the cubit is closed. This covers `dismiss` and timer-driven calls.

### IN-03: `validEventId` is shared by the device-id store but lives in the intent model

**Files modified:** `lib/utils/backend_identifier.dart` (new), `test/utils/backend_identifier_test.dart` (new), `lib/models/notification_intent.dart`, `lib/models/push_event.dart`, `lib/repository/storage/device_identity_store.dart`
**Commit:** f4596ba
**Applied fix:** The regex helper moved to `lib/utils/backend_identifier.dart` as `validBackendIdentifier(Object?) → String?`. I did not use an `is...` name because the function returns the value, not a bool. The storage layer no longer imports the intent model. Behaviour is unchanged. The helper got a small unit test, since `docs/rules/testing.md` asks for one per pure util. It had no direct test before.

### IN-04: Only Firebase init is time-bounded before `runApp`

**Files modified:** `lib/repository/services/push/local_notifications_startup.dart` (new, plugin-free), `lib/repository/services/push/push_bootstrap.dart`, `test/repository/services/push/local_notifications_startup_test.dart` (new), `test/helpers/fakes/recording_local_notifications_port.dart`
**Commit:** 2c6e5cc
**Tests added:** six tests on the new helpers. For init: success, failure, and a call that never completes (fake_async) all give the right result. For the launch read: an intent, a failure, and a call that never completes. The red was a missing symbol (new helpers).
**Applied fix:** `push_bootstrap.dart` imports plugins, so tests cannot touch it. I moved the two guarded steps into plugin-free helpers over `LocalNotificationsPort`. `initializeLocalNotifications` returns `false` if init fails or takes longer than 2 s, and the bootstrap then returns the disabled ports. `readLaunchIntent` returns `null` on failure or after 2 s. Each failure logs with `debugPrint`, using only the error type. The worst case before `runApp` is now 3 s + 2 s + 2 s.

### IN-05: The 15-minute `streamerLive` window only suppresses same-minute keys

**Files modified:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart`, its test, `.planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md`
**Commit:** 49d1057
**Test added:** a `streamerLive` banner with a different `sentAt` minute, sent 7 min after the first one, is dropped. It is shown again once the 15 min have passed. It was red first.
**Applied fix:** I took the second option. The banner cubit now suppresses `streamerLive` by type (`_suppressionKeyOf`) for the 15-minute window. Personal events keep `PushEvent.dedupKey`. `PushEvent.dedupKey` itself is unchanged, because it also sets the Android notification id and the banner `ValueKey`. The change follows the D-18 intent: one surface per go-live, even when a push and a future subscription producer deliver it with different times. The letter of D-18 said `(type, sentAt minute)`. The constant's doc comment now describes the window truthfully, and the BACKEND-NOTES handoff line was updated to match. Trade-off: if a stream goes live, stops and goes live again within 15 minutes, the second go-live gets no banner.

### IN-06: Stack still lists Firebase Auth

**Files modified:** `CLAUDE.md`
**Commit:** 61e0bfd
**Applied fix:** The Stack section now has an "Auth" line (Twitch OAuth through the backend, tokens in `flutter_secure_storage`) and a "Push" line (Firebase Core + Messaging data-only, `flutter_local_notifications`, `permission_handler`, `url_launcher`).

## Skipped Issues

None.

## Notes

- I left the CONTEXT decisions as they were. D-07: retries stay silent and bounded, and the foreground re-arm runs the same bounded retry. D-08: the drain stays inside the 2 s cap. D-09 now holds even under interleaving. D-17/D-18 hold. D-19: the new helpers are plugin-free, and no plugin import was added.
- The verifier's commit `13c618a` (`05-VERIFICATION.md`) landed between these fix commits. I did not touch that file.

---

_Fixed: 2026-10-20_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
