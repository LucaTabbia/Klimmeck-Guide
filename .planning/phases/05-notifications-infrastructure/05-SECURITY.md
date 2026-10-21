---
phase: 05
slug: notifications-infrastructure
status: secured
threats_total: 42
threats_mitigated: 42
threats_open: 0
asvs_level: 1
created: 2026-10-20
---

# Phase 05 - Security (Notifications Infrastructure, FE)

Audit of the `<threat_model>` blocks of plans 05-01..05-09 against HEAD of `feat/05-notifications-infrastructure` (after the code-review fixes). `flutter test` on push, models, auth, repository suites: all green (603 tests). `git ls-files` lists no `google-services.json` / `GoogleService-Info.plist`; both are in `.gitignore` (lines 155-156).

Disposition: M = mitigate (verified in code), A = accept (rationale re-verified, logged below).

## Summary

| Threat | Disp | Status | Mitigation (file:line) | Test |
|--------|------|--------|------------------------|------|
| T-05-01-01 | M | mitigated | `.gitignore:155`; no tracked file | `git ls-files` = 0 |
| T-05-01-02 | M | mitigated | `android/app/build.gradle.kts:48-49` (`missingGoogleServicesStrategy = WARN`); disabled ports on Firebase failure `push_bootstrap.dart:23-27` | `disabled_push_ports_test.dart` |
| T-05-01-03 | M | mitigated | `android/app/src/main/res/raw/keep.xml` (`tools:keep="@drawable/ic_stat_klimmeck"`) | manual (build/UAT) |
| T-05-01-04 | A | accepted | only `uuid` added; `firebase_auth` removed | n/a |
| T-05-02-01 | M | mitigated | `lib/models/push_event.dart:26-41` (wire-type whitelist, non-empty title/body, `parseSentAt`, id only if personal and `validBackendIdentifier`, never throws); `lib/utils/backend_identifier.dart:1-6` | `push_event_test.dart` (parses personal/questEnd, drops id for streamerLive, drops id outside alphabet, malformed cases) ; `data_message_handler_test.dart` ("drops an unknown type", "without a title", "unparseable sentAt") |
| T-05-02-02 | M | mitigated | `push_event.dart` and `notification_intent.dart` hold no url/Uri (grep empty); only URL is `lib/config/twitch_channel.dart:7-9` | `notification_tap_router_test.dart` "the payload id never chooses the opened URL" |
| T-05-02-03 | M | mitigated | `notification_intent.dart:27-44` (null/empty, `FormatException` guard, `Map<String,dynamic>` shape check, unknown type -> null, id regex) | `notification_intent_test.dart` (null for malformed payloads, drops invalid id) |
| T-05-02-04 | A | accepted | `stable_notification_id.dart:7-14` FNV-1a 31 bit; collision only replaces a tray entry | `push_event_test.dart` notificationId group |
| T-05-03-01 | M | mitigated | `push_device_repository.dart:15-27`: `register(deviceId, token)` carries no user field; identity from the bearer (BE) | `push_device_repository_test.dart` |
| T-05-03-02 | M | mitigated | `push_device_failure.dart:26` `toString()` prints failure name only; no variable logging in repository | `push_device_failure_test.dart` "prints only the failure name" |
| T-05-03-03 | M | mitigated | `push_device_failure.dart:33-45` maps on `graphQlErrorCode` only | `push_device_failure_test.dart` "ignores the server message text", "maps $code" |
| T-05-03-04 | M | mitigated | `device_identity_store.dart:41` `validBackendIdentifier(stored)` else regenerate | `device_identity_store_test.dart` |
| T-05-03-05 | A | accepted | opaque id in app-private SharedPreferences (`active_user_store.dart:20`), `allowBackup="false"` in manifest; cleared at session end | `active_user_store_test.dart` |
| T-05-04-01 | M | mitigated | `data_message_handler.dart:19,37,44-51` (no active user -> drop; toggles read for that user); clear on session end `push_registration_coordinator.dart` `_endSession` (`_activeUser.clear`, `cancelAll`) | `data_message_handler_test.dart` "shows nothing without an active user and reads no toggle", "ignores the toggles of another user"; coordinator_test "session end" group |
| T-05-04-02 | M | mitigated | `data_message_handler.dart:14-25` (`tryParse` boundary, try/catch on preferences and active user) | `data_message_handler_test.dart` "drops the message when preferences/active user cannot be read" |
| T-05-04-03 | M | mitigated | `push_bootstrap.dart:23-27` (3 s timeout + catch); `local_notifications_startup.dart:14,29` (2 s timeouts, post-review fix); every failure path returns `PushServices.disabled` | `local_notifications_startup_test.dart` ("never answers" cases), `disabled_push_ports_test.dart` |
| T-05-04-04 | M | mitigated | all `debugPrint` in push/auth/storage paths use fixed text, `runtimeType` or failure name (`data_message_handler.dart:16,23,48`; `push_bootstrap.dart:25,41`; `coordinator:129,210`; `auth_cubit.dart:64`); no token/user id/payload printed | grep audit (this report) + UAT evidence |
| T-05-04-05 | M | mitigated | plugin import allow-list | `push_boundaries_test.dart` "push plugins are imported only by their adapters" and plugin-backed files not imported by tests |
| T-05-04-06 | M | mitigated | `notification_tap_router.dart:26` only `TwitchChannel.uri`; `url_launcher_link_opener.dart:14` receives URIs from caller | `notification_tap_router_test.dart` |
| T-05-05-01 | M | mitigated | `auth_cubit.dart:~55-62` unregister before `_authTokenService.logout()`; coordinator `unregister()` (suspend, generation++, drain in-flight `_drainAttemptInFlight`) ; `_endSession` clear + `cancelAll()` | `auth_cubit_test.dart` "unregisters the push device before the service logout"; coordinator_test unregister group ("waits for the registration in flight", "cancels a pending retry", "a token arriving after the suspension is not registered") and session end group ("an end arriving during the active user write clears it") |
| T-05-05-02 | M | mitigated | `auth_cubit.dart:62-66` `.timeout(pushUnregisterTimeout)` (2 s) + `on Object` catch | `auth_cubit_test.dart` "caps ... two seconds", "a hanging unregister delays ... by two seconds" (fake_async), "a failing unregister never blocks" |
| T-05-05-03 | M | mitigated | coordinator `_onAuthState` (`user.id == _sessionUserId` return), `maxRegistrationAttempts` bounded `silentRetry` | coordinator_test "re-emissions for the same user do not register again", "transient failures stop after five attempts" |
| T-05-05-04 | M | mitigated | `_describe` logs failure name / `runtimeType` only (`coordinator:199-201`) | grep audit |
| T-05-05-05 | M | mitigated | `_suspended` + `_generation` in `_isCancelled` (`coordinator:132-133`), re-checked after token fetch (`:149`), attempt drained before unregister | coordinator_test "a token arriving after the suspension is not registered" |
| T-05-06-01 | M | mitigated | `notification_permission_gate.dart:12-13` idempotent, in-flight dedup; no prompt call in main/auth_gate/splash/settings | `notification_permission_gate_test.dart` ("prompts once", "shares one prompt"); `push_boundaries_test.dart` prompt-free static test |
| T-05-06-02 | M | mitigated | nothing persisted; status read from OS via permission_handler | gate tests |
| T-05-06-03 | M | mitigated | Settings cubit catches read failure and keeps state | settings notification permission cubit tests |
| T-05-06-04 | A | accepted | status only, local | n/a |
| T-05-07-01 | M | mitigated | `notification_tap_router.dart:21-29` | `notification_tap_router_test.dart` "a streamerLive tap opens the Twitch channel only", "the payload id never chooses the opened URL" |
| T-05-07-02 | M | mitigated | `notification_intent_cubit.dart` `_onAuthState` clears on Authenticated->Unauthenticated and on creation page; `offer` ignored on creation page; tray cleared by `_endSession` | `notification_intent_cubit_test.dart` |
| T-05-07-03 | M | mitigated | `hasClients` guard in `notification_intent_landing.dart`; pending kept otherwise | landing/shell widget tests |
| T-05-07-04 | M | mitigated | `NotificationIntent.tryFromPayload` in adapter, before the router | `notification_intent_test.dart` |
| T-05-08-01 | M | mitigated | `foreground_push_events.dart:24-30` `acceptPushEvent` with shell `userId` | `foreground_push_events_test.dart` "ignores the toggles of another user" |
| T-05-08-02 | M | mitigated | foreground feed has no `LocalNotificationsPort`; cubit dedup (`in_app_notifications_cubit.dart:32-37,84-90`: personal 2 min, streamerLive 15 min by type) | `in_app_notifications_cubit_test.dart` dedup tests (lines 128-189) |
| T-05-08-03 | M | mitigated | `InAppNotificationsCubit.open()` -> `NotificationTapRouter` | cubit tests lines 263-278 |
| T-05-08-04 | M | mitigated | queue + dedup + one at a time (`:42,75-80`); `kg_notification_banner.dart:59,68` `maxLines` 1 and 2; post-close no-ops | cubit tests "shows queued events one at a time", "publish/dismiss after close starts no timer" |
| T-05-08-05 | A | accepted | banner renders plain `Text` | n/a |
| T-05-09-01 | M | mitigated | 05-09 contract validation of 27 documents against BE schema (see 05-VERIFICATION.md) | 05-VERIFICATION evidence |
| T-05-09-02 | M | mitigated | file untracked and ignored; this audit only checked `git ls-files` | `git ls-files` = 0 |
| T-05-09-03 | M | mitigated | `05-HUMAN-UAT.md` holds outcomes and field names only, token projected out | doc review |
| T-05-09-04 | M | mitigated | UAT logout step: row removed before BE logout, nothing delivered after; code path as T-05-05-01 | `05-HUMAN-UAT.md`, auth_cubit_test |
| T-05-09-05 | M | mitigated | no prompt at cold launch; static guard | UAT step 2, `push_boundaries_test.dart` |

## Accepted risks log

| Threat | Rationale |
|--------|-----------|
| T-05-01-04 | Only `uuid` added (already transitive); attack surface reduced by removing `firebase_auth`. |
| T-05-02-04 | Notification-id collision only replaces a tray entry; no data impact. |
| T-05-03-05 | Active user id is an opaque backend id in app-private storage (backup disabled), cleared at session end. |
| T-05-06-04 | Permission status is device-local, no exposure. |
| T-05-08-05 | Title/body rendered with `Text`, no HTML/markdown interpretation; system notification text is plain. |
| T-05-07-02 residual | Killed-state tap followed by sign-in as another account lands on the Map tab only, no payload data shown. |

## Partially mitigated / open

None.

## Out of scope / notes

- Manifest: `POST_NOTIFICATIONS` declared; only `MainActivity` and flutter_web_auth_2 `CallbackActivity` exported (both required: launcher and OAuth callback, pre-existing); no new exported component; `allowBackup="false"`. Notification receivers come from plugin manifests (non-exported by default).
- Revocation / sync-lost paths do not unregister (no bearer); mitigated by `AuthUnauthenticated` clearing the active user so the background handler drops messages, and by the BE token claim at next login (BE section 5.6).
- A background `show` already in progress while the session ends can still post one notification after `cancelAll()`; very narrow window, low severity, informational.
- Unregistered flags from SUMMARY.md Threat Flags: none identified requiring new threats.
- BE/ops finding from UAT (not an FE threat): subscription to topic `streamer-live` denied by IAM for the service account (`firebase-admin` 14.5.0 `subscribeToTopic`); requires granting the relevant FCM/IAM role to the BE service account. Tracked for BE/ops, no FE change.
