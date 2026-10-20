---
phase: 05-notifications-infrastructure
plan: 09
status: complete
subsystem: cross-repo-verification
tags: [schema-check, validation, uat, checkpoint, push, fcm]
requires: [05-01, 05-02, 05-03, 05-04, 05-05, 05-06, 05-07, 05-08]
provides:
  - Phase 5 verified across repos (27 documents against BE origin/develop 0828719) and on a physical Android device
  - FE -> BE handoff with the UAT outcome that closes the Android item of the BE Phase 5 HUMAN-UAT
affects: [phase-7-travel, phase-9-combat-result, be-phase-5-push-fcm]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/05-notifications-infrastructure/BACKEND-NOTES.md
    - .planning/phases/05-notifications-infrastructure/05-HUMAN-UAT.md
  modified:
    - .planning/phases/05-notifications-infrastructure/05-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "Topic subscription failure of streamer-live is a BE/ops finding (service account lacks cloudmessaging.topicSubscriptions.create), not a Phase 5 FE gap; remedy roles/firebasecloudmessaging.admin, recorded as a BE action item in BACKEND-NOTES 5.1"
  - "C1 limitation not observed on Samsung SM-S938B / Android 16: a revoke from system settings was classified denied and the hint row appeared"
requirements-completed: [NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05, NOTIF-06, NOTIF-07, NOTIF-08]
metrics:
  completed: 2026-10-20
completed: 2026-10-20
---

# Phase 5 Plan 09: Cross-repo gate and device UAT Summary

All 27 app GraphQL documents validate against BE `origin/develop` `0828719`, every phase gate is green, the app builds with and without `google-services.json`, and the user approved the 10-step device UAT on 2026-10-20 (Samsung SM-S938B, Android 16, real Twitch login, BE `sendTestPush`). Push works in foreground, background and killed state for `travelEnd`, `questEnd` and `streamerLive`. One BE/ops finding came out of the session: the service account lacks the IAM permission to subscribe tokens to the `streamer-live` topic.

## Phase 5 overview (plans 01-08)

- **05-01:** Android native wiring: Google Services plugin 4.5.0 with the `WARN` missing-file strategy, explicit `POST_NOTIFICATIONS`, `ic_stat_klimmeck` small icon, `firebase_auth` dropped, `uuid` direct, legacy `NotificationsBloc` deleted.
- **05-02:** Pure value layer: `NotificationCategory` wire names, strict `PushEvent.tryParse` / `NotificationIntent.tryFromPayload`, FNV-1a `stableNotificationId`.
- **05-03:** Device data path: `RegisterPushDevice` / `UnregisterPushDevice`, `PushDeviceRepository` with code-mapped failures, device-wide UUID v4 `DeviceIdentityStore`.
- **05-04:** Ports, adapters, background entry and guarded bootstrap (`PushServices.disabled()` when Firebase is unavailable), shared display rule `acceptPushEvent`.
- **05-05:** `PushRegistrationCoordinator` (login, cold start, token refresh) and unregister in `AuthCubit.logout()` before the backend logout (2 s cap).
- **05-06:** `NotificationPermissionGate.ensureRequested()` for Phase 7, static guard, Settings hint row driven by `NotificationPermissionCubit`.
- **05-07:** One `NotificationTapRouter`: personal types → Map tab via `NotificationIntentCubit`, `streamerLive` → Twitch `lordreavor`.
- **05-08:** Foreground in-app banner through `InAppNotificationsCubit.publish` with `(type, id)` dedup, no system notification in foreground.

## Task 1: Schema check, gates, builds, sign-off (done)

Commit `e89e303` (`docs(phase-5): verify the schema and sign off the validation`).

| Gate | Result |
|------|--------|
| Schema check | 27 documents OK (including `OK RegisterPushDevice.graphql`, `OK UnregisterPushDevice.graphql`) against BE `origin/develop` `0828719`, exit 0, no drift on the 25 pre-existing documents |
| `flutter test` | 986 passed (run 3 times) |
| `flutter analyze` | 56 issues, 0 errors, none in the 87 Phase 5 Dart files |
| Formatter | `dart format --output=none --set-exit-if-changed` exit 0 on all 86 added/modified Dart files, one by one |
| Invariants | `ensureRequested(` outside the gate = 0; `onMessageOpenedApp\|getInitialMessage` = 0; `sendTestPush` in lib = 0; `initializeApp` in the background handler = 0; `ios/` diff empty; `google-services.json` not tracked |
| Build A (JSON present) | `✓ Built`, `google_app_id` = 1 |
| Build C (JSON absent after `flutter clean`) | `✓ Built`, `google_app_id` = 0; warning `File google-services.json is missing.` + `BUILD SUCCESSFUL` proved with `./gradlew :app:processDebugGoogleServices --rerun-tasks` (needed the `JAVA_HOME` of Android Studio's JBR); JSON restored (708 bytes) |
| Attribution trailers on the branch | 0 (after the orchestrator reworded one commit body) |

## Task 2: Device UAT (done)

Resume signal: overall verdict **approved**, steps 1-10 pass (step 1 indirect, step 4 full, step 8 foreground without an explicit user sentence). Session 2026-10-20, 17:50-19:21, run by the user (Luca) with the orchestrator driving `sendTestPush` and `adb`.

**Session facts:** Samsung SM-S938B (`RZCY92B5BWW`), Android 16 (API 36). BE local on :3000 from branch `feat/06-eventsub-punti-canale-streamer-live` (Phase 5 push code merged in it), `FIREBASE_SERVICE_ACCOUNT` of `klimmeck-guide-app`. Real Twitch login in the app (FE `DEV_AUTH_ENABLED=false`); the BE dev bypass (`DEV_AUTH_ROLE=innkeeper`, separate dev User) was used only to call `sendTestPush` with `targetUserId: 6ac61251c703dc50b8544865` (personal types) and without target for `streamerLive`.

| # | Step | Result |
|---|------|--------|
| 1 | BE boot with push enabled | pass (indirect): boot line not read; service account project `klimmeck-guide-app` read via firebase-admin, every push reached the device |
| 2 | No permission prompt | pass: none at cold launch, splash, sign-in, Settings (`POST_NOTIFICATIONS granted=false` without `USER_SET` until the 18:13:58 grant); 3 toggles, no hint row |
| 3 | Registration | pass: 1 row, `deviceId c3badace-7496-48cd-a59d-8847d0c2c990`, `platform android`; same `deviceId` after force-stop + relaunch, `lastSeenAt` updated; session restored without login |
| 4 | Permission hint | pass (no C1 limitation observed): grant → no row; revoke from system settings → row + "Attiva" → system page → re-enabled (`USER_SET`) → row gone |
| 5 | Foreground | pass: banners for the three types, no tray; taps → Map tab / Twitch; dedup of two identical `travelEnd` → one banner |
| 6 | Background | pass: three tray notifications (shield icon, BE title/body); taps → Map tab / Twitch |
| 7 | Killed | pass: background isolate started, notifications on `klimmeck_events`; tap → cold start, session restored, Map tab; live → Twitch |
| 8 | Toggles off | pass: messages received in foreground/background/killed, tray 0, no banner reported |
| 9 | Unregister before logout | pass: rows 0 after "Esci", `targeted 0`, tray 0; re-login → same `deviceId` |
| 10 | No-JSON smoke + prune | pass: `Push disabled: Firebase unavailable (PlatformException)`, game unchanged; prune `{ targeted 1, sent 0, pruned 1, failed 1 }` |

**BE/ops finding (not a Phase 5 FE defect):** `firebase-admin` 14.5.0 `subscribeToTopic` uses the FCM v1 `topicSubscriptions` endpoint, which requires `cloudmessaging.topicSubscriptions.create`; the service account lacks it, so `registerPushDevice` logs `subscribeToTopic(streamer-live): 1 token failed (messaging/authentication-error)` and devices never get `streamerLive`. The first two `streamerLive` sends (18:04, 18:05) did not arrive for this reason; after the orchestrator subscribed the token with the legacy API, delivery worked in all states. Remedy: grant `roles/firebasecloudmessaging.admin`, then re-register (kill + relaunch); optional BE fallback to `subscribeToTopicLegacy` on `authentication-error`. Recorded in `05-HUMAN-UAT.md` Gaps and `BACKEND-NOTES.md` §5.1.

**Observations (environment / out of scope):** a port-3000 conflict with an unrelated local dev server delayed the first Twitch login; pre-existing log line `CachedSvg: failed to load Invalid argument(s): No host specified in URI`.

**Records updated:**
- `05-HUMAN-UAT.md`: `status: complete`, 10 results with notes, Summary 10/10 passed, Gaps section with the BE/ops finding and the two observations.
- `BACKEND-NOTES.md` §5: outcome per state × type, toggles, logout, prune, C1 observation, closing line for the BE `05-HUMAN-UAT.md` Android test, §5.1 action item.
- `05-VALIDATION.md`: row 5-09-02 `✅ green`.
- `REQUIREMENTS.md`: NOTIF-01..NOTIF-08 ticked (NOTIF-02 annotated: gate + no cold-launch prompt, call site in Phase 7), traceability row Complete.
- `ROADMAP.md`: progress row 9/9 In Progress (the orchestrator closes the phase).
- `STATE.md`: plan 9 of 9 complete, 50/50 plans.

## Deviations from Plan

1. **Task 1 trailer grep false positive:** the trailer gate matched one commit body on the branch; the orchestrator fixed it with a message-only amend (`e89e303`). No code change.
2. **Step 10 interrupted once by a device disconnect:** the step was rerun and succeeded.

Nothing else.

## Known Stubs

None introduced by this plan (docs only). `defaultNotificationPopups` is empty by design until Phases 7/9 (see `BACKEND-NOTES.md` §3).

## Next

Phase close by the orchestrator, `/gsd-verify-work 5`, then the FE PR to `develop` opened by the user with `GH_TOKEN=$(gh auth token --user LucaTabbia)` (BE PR #8 already merged), mentioning the C1/C3/C4 decisions. BE/ops: grant the FCM Admin role to the service account.

## Self-Check: PASSED

Files present: `05-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `05-VALIDATION.md`, `05-09-SUMMARY.md`. Commit `e89e303` (Task 1) found; the UAT record commit follows this summary.
