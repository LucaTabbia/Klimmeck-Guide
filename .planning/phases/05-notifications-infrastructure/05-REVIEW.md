---
phase: 05-notifications-infrastructure
reviewed: 2026-10-20
depth: standard
branch: feat/05-notifications-infrastructure
status: issues_found
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
---

# Phase 5: Code Review Report

**Reviewed:** 2026-10-20
**Depth:** standard (cross-file tracing on coordinator, AuthCubit, intent cubit, landing, bootstrap, background isolate)
**Scope:** `git diff origin/develop...HEAD` over `lib`, `android`, `pubspec.yaml`, `test` (about 54 lib files plus 38 test files)
**Status:** issues_found

## Summary

The phase is well built. The layering is respected: widgets reach services only through cubits, and the plugins are confined to their adapters (enforced by `push_boundaries_test`). Payload validation is strict, and the only URL ever opened is the `TwitchChannel.uri` constant. Logs carry only `runtimeType` or failure names. `google-services.json` is ignored and not tracked. `flutter analyze` reports no new issue on phase files. `flutter test test/repository/services/push test/screens/auth` passes.

No critical issues. The three warnings are race and robustness gaps in `PushRegistrationCoordinator`. They have a low probability of showing up but real consequences: a stale device row, a device that is never registered, and a stale active user in the prefs mirror. The info items are small hardening and cleanup points.

| ID | Severity | File | Title |
|----|----------|------|-------|
| WR-01 | Warning | push_registration_coordinator.dart:109-117 | `unregister()` does not wait for an in-flight registration, which can re-create the row after removal |
| WR-02 | Warning | push_registration_coordinator.dart:32-33, 81-95 | Registration gives up after about 15 s with no later trigger |
| WR-03 | Warning | push_registration_coordinator.dart:61-74 | Auth-state handlers are not serialised (active-user write vs clear) |
| IN-01 | Info | in_app_notifications_cubit.dart:60-63 | `open(event)` dismisses whatever banner is current, not the tapped one |
| IN-02 | Info | in_app_notifications_cubit.dart:45-73 | `publish`/`dismiss` after `close()` still touch queue and timer |
| IN-03 | Info | device_identity_store.dart:1, notification_intent.dart:53 | `validEventId` is shared by the device-id store but lives in the intent model |
| IN-04 | Info | push_bootstrap.dart:27-36 | Only Firebase init is time-bounded before `runApp` |
| IN-05 | Info | in_app_notifications_cubit.dart:34-35, push_event.dart:44 | The 15-minute `streamerLive` window only suppresses same-minute keys |
| IN-06 | Info | CLAUDE.md (Stack) | Stack still lists Firebase Auth after `firebase_auth` was removed |

## Warnings

### WR-01: `unregister()` does not wait for an in-flight registration

**File:** `lib/repository/services/push/push_registration_coordinator.dart:81-117`
**Issue:** `unregister()` sets `_suspended`, bumps `_generation` and sends the unregister mutation. A `register` mutation already on the wire is not awaited or cancelled: `silentRetry` only checks `isCancelled` before an attempt and after a wait. If the register request reaches the backend after the unregister (reordering, or a slow first attempt), the device row is re-created for a user who is logging out.

The backend `logout` may clean it up, but `BACKEND-NOTES` D-08 describes the unregister-before-logout order as the guarantee, and that guarantee has a hole. Pitfall 5 is only closed for retries and refreshes, not for the request in flight.

**Fix:** Keep the current registration future (`Future<void>? _registration`) and await it, capped, inside `unregister()` before sending the removal:
```dart
Future<void>? _inFlight;

void _register({String? token}) {
  final generation = ++_generation;
  _inFlight = silentRetry<void>(/* unchanged */);
  unawaited(_inFlight!);
}

Future<void> unregister() async {
  if (_sessionUserId == null || !_hasSeenToken) return;
  _suspended = true;
  _generation++;
  await _guarded('registration drain', () async => await _inFlight);
  await _guarded('unregister', () async { /* unchanged */ });
}
```
`AuthCubit` already caps the whole call at 2 s, so the logout is not blocked. Add a test with a fake repository whose `register` completes after `unregister` is requested.

### WR-02: Registration gives up after about 15 s with no later trigger

**File:** `lib/repository/services/push/push_registration_coordinator.dart:32-33, 81-95`
**Issue:** `maxRegistrationAttempts = 5` with a 30 s cap and exponential backoff 1, 2, 4, 8 s gives up after about 15 s. After `onGiveUp` nothing re-triggers the registration until FCM rotates the token or the process restarts. A user who logs in, or cold-starts, offline or on a flaky network for more than 15 s plays the whole session with no device row. All push (background and killed included) is silently lost, and nothing in the UI or logs after the single `Push registration stopped` line signals it.

Rule 2 (invisible recovery) is respected, but the recovery is bounded too tightly for a mobile network. D-07 asks for "bounded exponential retry", not for a permanent give-up.

**Fix:** Re-run `_register()` when the app returns to foreground (`AppLifecycleEvents.foregrounded`, already available) while `_sessionUserId != null && !_suspended` and the last attempt ended in give-up (a `_registered` flag). Alternatively, raise the attempts to the 8 and 60 s defaults of `silentRetry`. Add a test: fail 5 times, emit a foreground event, expect a new registration.

### WR-03: Auth-state handlers are not serialised

**File:** `lib/repository/services/push/push_registration_coordinator.dart:57, 61-74, 119-126`
**Issue:** `Stream.listen(_onAuthState)` does not wait for the previous async handler. `Authenticated` suspends at `await _guarded('active user write', ...)`. If `Unauthenticated` arrives in that window (a fast revoke or sync-lost right after login), `_endSession` runs `_activeUser.clear` while `write(user.id)` is still pending.

`_register()` is protected, because `_sessionUserId == null` makes `isCancelled` true. The prefs mirror is not: the final value depends on platform-channel ordering. If the write lands last, `klimmeck.push.activeUserId` stays set after logout. The background isolate would then keep showing system notifications for a logged-out user whose toggles are on, until the next login or logout. The consequence is a privacy leak on a shared device, not a crash.

**Fix:** Serialise the handlers with a promise chain:
```dart
Future<void> _queue = Future.value();

void _enqueue(AuthState state) {
  _queue = _queue.then((_) => _onAuthState(state));
}
// start(): _authStates.listen(_enqueue)
```
Alternatively use `asyncMap(_onAuthState)` on the stream, which serialises natively. Add a test with a fake `ActiveUserStore` whose `write` is delayed and check that the final state is cleared.

## Info

### IN-01: `open(event)` dismisses the current banner, not the tapped one

**File:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart:60-63`
**Issue:** `open(event)` calls `dismiss()` unconditionally. During the 250 ms `AnimatedSwitcher` cross-fade the outgoing banner A is still tappable while B is already `state.current`. Tapping A routes A's intent but dismisses B before the user sees it.
**Fix:** `if (state.current == event) dismiss();` and then `await _router.handle(event.intent)`.

### IN-02: `publish`/`dismiss` after `close()` still touch queue and timer

**File:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart:45-73`
**Issue:** `close()` cancels the timer and subscription (sound). `publish` is public, though, and Phase 7/9 producers will call it. After `close()`, `publish` or `dismiss` can create a new `Timer` in `_showNext`. The emit is swallowed by `SafeEmit`, but the timer fires later and the queue grows.
**Fix:** Add `if (isClosed) return;` at the top of `publish` and `_showNext`.

### IN-03: `validEventId` is shared by the device-id store but lives in the intent model

**File:** `lib/repository/storage/device_identity_store.dart:1`, `lib/models/notification_intent.dart:53`
**Issue:** The storage layer imports `models/notification_intent.dart` only for the `[A-Za-z0-9._-]{1,128}` regex. The name `validEventId` is wrong for a device id, and the coupling is accidental (naming.md, SoC).
**Fix:** Move the regex helper to `lib/utils/backend_identifier.dart` as `isValidBackendIdentifier` or `validBackendId`, and use it from both places.

### IN-04: Only Firebase init is time-bounded before `runApp`

**File:** `lib/repository/services/push/push_bootstrap.dart:27-36`
**Issue:** `Firebase.initializeApp()` has a 3 s timeout. `notifications.initialize()` and `notifications.launchIntent()` are awaited with no bound. They are local platform calls, but a stuck channel would block `runApp`, against the "nothing blocks runApp" requirement. The failure path itself is correct: every `Object` falls back to disabled ports.
**Fix:** Wrap the second `try` body in `.timeout(_firebaseInitTimeout)` or reuse a shared `_localInitTimeout`. A late `launchIntent` result is not lost, because the disabled ports keep the app usable.

### IN-05: The 15-minute `streamerLive` window only suppresses same-minute keys

**File:** `lib/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit.dart:34-35`, `lib/models/push_event.dart:44`
**Issue:** The dedup key for an id-less event is `streamerLive|<UTC minute of sentAt>`. The 15-minute expiry therefore matters only for repeated deliveries with the same `sentAt` minute. A second broadcast with a new `sentAt` minute within 15 minutes is shown. This may be intended, since the backend sends one broadcast per go-live, but the comment "Pari al TTL del broadcast" suggests wider suppression.
**Fix:** Clarify the doc comment, or key `streamerLive` on the type alone if the 15-minute suppression is the goal.

### IN-06: Stack still lists Firebase Auth after `firebase_auth` was removed

**File:** `CLAUDE.md` (section Stack, line "Auth/Push")
**Issue:** Plan 05-01 removed `firebase_auth` (unused). `CLAUDE.md` still says "Firebase Auth (OAuth Twitch)", and it also omits `flutter_local_notifications`, `permission_handler` and `url_launcher`. This is documentation drift, not a code bug.
**Fix:** Update the Stack line to "Firebase Core + Messaging (FCM), flutter_local_notifications, permission_handler, url_launcher; auth is Twitch OAuth through the backend".

---

## Verified OK

- **Layering and boundaries:** widgets never call services. The banner tap goes through `InAppNotificationsCubit.open`, and the permission hint uses `NotificationPermissionCubit`. `push_boundaries_test` enforces plugin confinement, no `initializeApp` in the background handler, and no prompt call outside the gate. Tests do not import plugins.
- **Payload validation:** `PushEvent.tryParse` requires a known `type`, a non-empty `title` and `body`, and a parsable `sentAt`. Unknown types (`combatResult`) are dropped, and ids pass the `[A-Za-z0-9._-]{1,128}` allow-list. `NotificationIntent.tryFromPayload` rejects null, empty, non-JSON and non-map payloads, and bad types or dates.
- **Link opening:** `NotificationTapRouter` opens only `TwitchChannel.uri` (a compile-time constant) and never a payload value. `UrlLauncherLinkOpener` uses `externalApplication` and swallows launcher failures without `canLaunchUrl`.
- **Logging:** only `runtimeType`, `failure.name` or fixed strings. No token, device id or user id is logged. `pushDeviceFailureFrom` ignores server message text.
- **Background isolate:** `DartPluginRegistrant.ensureInitialized()` comes first and there is no Firebase init (C4). The entry point is top-level with `@pragma('vm:entry-point')`. It reads the active user and toggles from `SharedPreferencesAsync` with no cache, drops the message when there is no active user, and `handleDataMessage` never throws. Ids come from FNV-1a (`stableNotificationId`), so they are stable across isolates and VM versions.
- **`bootstrapPush`:** non-Android returns disabled. A Firebase failure or timeout returns disabled with the real permission port. A notification init failure returns disabled. All paths log only the error type.
- **`AuthCubit.logout()`:** unregister runs first, capped at 2 s, with any error swallowed, then `_authTokenService.logout()`. Logout is never blocked, and `Unauthenticated` resets `_suspended`.
- **Coordinator, apart from WR-01 to WR-03:** retries are cancelled by `_generation`, `_suspended` and `_sessionUserId`. Non-retryable codes stop retrying. `_hasSeenToken` correctly skips the network when push is off. `dispose()` cancels both subscriptions. `start()` is idempotent.
- **`NotificationIntentCubit`:** the buffer survives Bootstrapping, splash and sign-in. It clears on Authenticated to Unauthenticated and on the creation page. `offer` is ignored on the creation page. `close()` cancels the subscription before `super.close()`, and `consume()` is idempotent.
- **`NotificationIntentLanding`:** consumption is guarded by `mounted` and `hasClients`. The post-frame consume at `initState` covers taps from killed. `listenWhen` avoids re-consuming. `popUntil` on the root navigator, then `jumpToPage(0)`, matches `_buildPages` (WorldMap is index 0).
- **`close()` ordering:** `InAppNotificationsCubit.close()` cancels the timer and subscription, then awaits `super.close()`, then awaits the cancel. `NotificationPermissionCubit.close()` uses `Future.wait`, and its `refresh` after close is safe through `SafeEmit`. Both are sound.
- **Permission gate and port:** `ensureRequested` is single-flight and asks only when `notDetermined`. The Android classification via `permission_handler` matches the documented limit (D-10). Nothing in Phase 5 surfaces calls the prompt.
- **UI rules:** the banner uses `KlimmeckGuideTheme` tokens only, with no SnackBar, MaterialBanner or Scaffold, so rule 1 holds. It sits in the shell `Stack` (only with a character), and the `Align` overlay does not intercept touches outside the banner.
- **Android and secrets:** `POST_NOTIFICATIONS` is declared. Google-services 4.5.0 uses the `WARN` strategy. `keep.xml` protects `ic_stat_klimmeck` from shrinking. `allowBackup=false` is kept. `google-services.json` and `.env` are in `.gitignore` and not tracked. No hardcoded secrets in the diff.
- **Repository and GraphQL:** every `OperationException` is mapped to `PushDeviceException`. Documents live in `push_mutations.dart`. The device id is created once, concurrent reads share one creation, and a bad stored value is regenerated.
- **Tooling:** `flutter analyze` shows no new issue on phase files. The remaining findings are pre-existing (`board.dart`, `spell_info.dart`, `tools/`).

---

_Reviewed: 2026-10-20_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
