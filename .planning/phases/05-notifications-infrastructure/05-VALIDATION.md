---
phase: 5
slug: notifications-infrastructure
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-10-19
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 — all already in `pubspec.yaml` |
| **Config file** | none — shared mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/` (push fakes created by plan 04: `FakePushMessagingPort`, `RecordingLocalNotificationsPort`, `RecordingLinkOpener`, `FakeNotificationPermissionPort`, `InMemoryDeviceIdentityStore`, `InMemoryActiveUserStore`; plan 07: `RecordingNotificationIntentSink`) |
| **Quick run command** | `flutter test <the task's test file(s)>` (see map) |
| **Full suite command** | `flutter test` (baseline 762 tests, ~27 s) + `flutter analyze` (baseline 57 → gate ≤ 56 with 0 errors after plan 01 deletes `lib/utils/notification.dart`) + `dart format --output=none --set-exit-if-changed <each touched file>` (single files only, never a directory) |
| **Estimated runtime** | quick ~3–10 s per file; full ~30 s; Android scratch build ~90–180 s (plans 01, 04, 05, 09 only) |

---

## Sampling Rate

- **After every task commit:** the task's `<verify><automated>` command (targeted test files) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>`
- **After every plan wave:** `flutter test test/models test/utils test/config test/graphql test/tool test/repository test/screens/auth test/screens/mainScreen test/shared/components` + `flutter analyze` total ≤ 56
- **Before `/gsd-verify-work`:** full `flutter test` green (> 762), `flutter analyze` ≤ 56 / 0 errors, schema check 27 × OK against BE `origin/develop` ≥ `0828719`, scratch builds with and without `google-services.json`, device UAT done (plan 09)
- **Max feedback latency:** ~10 s per task (builds excluded)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 5-01-01 | 01 | 1 | NOTIF-01, NOTIF-03..05 | T-05-01-01, T-05-01-02, T-05-01-03 | JSON never committed; build passes without it (WARN) | scripted (Gradle build A + C) | `grep` checks on Gradle/manifest + `flutter build apk --debug` with and without the JSON (05-01 Task 1 steps 6-7) | ✅ tooling | ⬜ |
| 5-01-02 | 01 | 1 | NOTIF-01 | T-05-01-04 | no new surface except `uuid`; analyzer 57 → 56 | static + full suite | `flutter analyze` (= 56) && `flutter test` | ✅ | ⬜ |
| 5-02-01 | 02 | 1 | NOTIF-03..05, NOTIF-07, NOTIF-08 | T-05-02-04 | explicit wire names; stable FNV ids; fixed Twitch constant | unit | `flutter test test/models/notification_category_test.dart test/models/notification_test.dart test/utils/stable_notification_id_test.dart test/config/push_config_test.dart` | ❌ W0 (category test exists, extended) | ⬜ |
| 5-02-02 | 02 | 1 | NOTIF-03..06 | T-05-02-01, T-05-02-02, T-05-02-03 | strict payload parsing; id regex; no URL in models | unit | `flutter test test/models/notification_intent_test.dart test/models/push_event_test.dart` | ❌ W0 | ⬜ |
| 5-03-01 | 03 | 2 | NOTIF-01 | T-05-03-01 | documents without identity input; listed for schema check | unit (document + Link.function) | `flutter test test/graphql/push_mutations_test.dart test/repository/services/graphql/graphql_push_test.dart test/tool/schema_check_documents_test.dart` | ❌ W0 (schema-check test exists) | ⬜ |
| 5-03-02 | 03 | 2 | NOTIF-01 | T-05-03-02, T-05-03-03 | mapping by `extensions.code` only; no token in exception text | unit | `flutter test test/repository/push_device_failure_test.dart test/repository/push_device_repository_test.dart` | ❌ W0 | ⬜ |
| 5-03-03 | 03 | 2 | NOTIF-01 | T-05-03-04, T-05-03-05 | device-wide UUID never rotated; active user mirror with clear | unit | `flutter test test/repository/storage` | ❌ W0 | ⬜ |
| 5-04-01 | 04 | 3 | NOTIF-03..05 | T-05-04-05 | disabled ports inert; no plugin in contracts | unit | `flutter test test/repository/services/push/disabled_push_ports_test.dart` | ❌ W0 | ⬜ |
| 5-04-02 | 04 | 3 | NOTIF-03..05, NOTIF-08 | T-05-04-01, T-05-04-02, T-05-04-04 | show only with active user + toggle on; never throws; stable id | unit | `flutter test test/repository/services/push/data_message_handler_test.dart` | ❌ W0 | ⬜ |
| 5-04-03 | 04 | 3 | NOTIF-03..05 | T-05-04-03, T-05-04-05, T-05-04-06 | plugins only in adapters; no Firebase init in isolate; guarded bootstrap | unit (static) + build | `flutter test test/repository/services/push/push_boundaries_test.dart` + `flutter build apk --debug` | ❌ W0 | ⬜ |
| 5-05-01 | 05 | 4 | NOTIF-01 | T-05-05-02 | unregister then logout; 2 s ceiling; failure never blocks | cubit (fake_async) | `flutter test test/screens/auth/cubit/auth_cubit_test.dart` | ✅ (extended) | ⬜ |
| 5-05-02 | 05 | 4 | NOTIF-01 | T-05-05-01, T-05-05-03, T-05-05-04, T-05-05-05 | one register per user; bounded retry; suspension; session-end clear + cancelAll | unit (fake_async) | `flutter test test/repository/services/push/push_registration_coordinator_test.dart` | ❌ W0 | ⬜ |
| 5-05-03 | 05 | 4 | NOTIF-01 | T-05-05-01 | coordinator lives for the process; AuthCubit gets the cleanup | full suite + build | `flutter test` + `flutter build apk --debug` | ✅ | ⬜ |
| 5-06-01 | 06 | 5 | NOTIF-02 | T-05-06-01, T-05-06-02 | prompt only on notDetermined; no call site in Phase 5 | unit + static | `flutter test test/repository/services/push/notification_permission_gate_test.dart test/repository/services/push/push_boundaries_test.dart` | ❌ W0 | ⬜ |
| 5-06-02 | 06 | 5 | NOTIF-02 | T-05-06-03 | read-only status; re-check on foreground; never requests | cubit + widget (shell) | `flutter test test/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit_test.dart test/screens/auth/authenticated_shell_test.dart` | ❌ W0 (shell test exists, extended) | ⬜ |
| 5-06-03 | 06 | 5 | NOTIF-02 | T-05-06-01 | hint only when denied; theme tokens; no spinner | widget | `flutter test test/screens/mainScreen/tabs/settings` | ❌ W0 (section/settings tests exist, extended) | ⬜ |
| 5-07-01 | 07 | 6 | NOTIF-06 | T-05-07-02 | intent survives sign-in; cleared at session end and on creation page | cubit | `flutter test test/screens/auth/notificationIntentCubit/notification_intent_cubit_test.dart` | ❌ W0 | ⬜ |
| 5-07-02 | 07 | 6 | NOTIF-06 | T-05-07-01, T-05-07-04 | only `TwitchChannel.uri` launched; personal → buffered | unit | `flutter test test/repository/services/push/notification_tap_router_test.dart` | ❌ W0 | ⬜ |
| 5-07-03 | 07 | 6 | NOTIF-06 | T-05-07-03 | Map tab landing with `hasClients` guard; root sheets popped; empty popup hook | widget | `flutter test test/screens/mainScreen/components/notification_intent_landing_test.dart test/screens/mainScreen` | ❌ W0 | ⬜ |
| 5-08-01 | 08 | 7 | NOTIF-07, NOTIF-08, NOTIF-03..05 | T-05-08-01, T-05-08-02, T-05-08-04 | foreground never shows a system notification; dedup window; queue; 5 s | unit + cubit (fake_async) | `flutter test test/repository/services/push/foreground_push_events_test.dart test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart` | ❌ W0 | ⬜ |
| 5-08-02 | 08 | 7 | NOTIF-07 | T-05-08-05 | no SnackBar/MaterialBanner/Scaffold; ≥ 44 px; semantics | widget | `flutter test test/shared/components/kg_notification_banner_test.dart` | ❌ W0 | ⬜ |
| 5-08-03 | 08 | 7 | NOTIF-07, NOTIF-08 | T-05-08-03 | banner in shell only; tap = system-notification action | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | ✅ (extended) | ⬜ |
| 5-09-01 | 09 | 8 | NOTIF-01..08 (D-21) | T-05-09-01, T-05-09-02 | 27 documents validate against BE develop; gates green; builds with/without JSON | scripted gate | `flutter test` + `tool/schema_check` (dump + `validate_documents.js` against `origin/develop:src/schema.gql`) + scratch builds A/C | ✅ tooling | ⬜ |
| 5-09-02 | 09 | 8 | NOTIF-01..08 | T-05-09-03, T-05-09-04, T-05-09-05 | device UAT 3 states × 3 types; unregister before logout; no cold-launch prompt | manual (checkpoint) | `grep -c "result: \(pass\|fail\|skipped\)" .planning/phases/05-notifications-infrastructure/05-HUMAN-UAT.md` | ❌ (created by 5-09-01) | ⬜ |

*Status legend: ⬜ = not run yet · ✅ green · ❌ red · ⚠️ flaky. Each row's Status cell becomes `✅ green` when its command passes (plan 09 Task 1 sets the automated rows; Task 2 sets 5-09-02).*

---

## Wave 0 Requirements

- [ ] Native + dependency groundwork (plan 01): Google Services plugin 4.5.0 with `missingGoogleServicesStrategy = WARN`, `POST_NOTIFICATIONS`, `ic_stat_klimmeck` + `raw/keep.xml`, `-firebase_auth`, `+uuid ^4.5.1`, legacy util deleted (analyzer → 56), scratch builds A/C
- [ ] `test/helpers/fakes/fake_shared_preferences_async.dart` gains `getString` / `setString` / `remove` (plan 03)
- [ ] Push fakes under `test/helpers/fakes/` (plan 04 Task 1; `recording_notification_intent_sink.dart` in plan 07)
- [ ] Mocks in `test/helpers/mocks.dart`: `MockPushDeviceRepository` (03), `MockPushSessionCleanup` (05), `MockNotificationPermissionCubit` (06), `MockInAppNotificationsCubit` only if needed (08)
- [ ] `tool/schema_check/schema_check_documents.dart` updated in the same commit as `push_mutations.dart` (plan 03, RESEARCH Pitfall 16)
- [ ] Failing-first tests for every ❌ W0 row above before its implementation (RED commit per task)
- [ ] `push_boundaries_test.dart` guarding plugin imports (plan 04) and the "no `ensureRequested(` call site" rule (plan 06)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real FCM delivery in foreground / background / killed for travelEnd, streamerLive, questEnd | NOTIF-03, NOTIF-04, NOTIF-05 | Needs Firebase, the BE service account and a physical device (OEM background policy) | 05-09 Task 2 steps 5–7 with BE `sendTestPush` |
| Tap from tray / banner lands on the Map tab or opens Twitch from each state | NOTIF-06, NOTIF-07 | Activity launch, cold start and external app launch only exist on device | 05-09 Task 2 steps 5–7 |
| No permission prompt at cold launch; hint row appears/disappears with the OS setting | NOTIF-02 | OS permission dialog and system settings round-trip | 05-09 Task 2 steps 2 and 4 |
| Registration row per device; same deviceId after relaunch and re-login; row removed at logout | NOTIF-01 | Needs the BE database | 05-09 Task 2 steps 3 and 9 |
| Toggles off → nothing shown in any state (cross-isolate prefs read) | NOTIF-03..05 (SET-02/SET-04 consumption) | `SharedPreferencesAsync` across engines is device-only (RESEARCH A3) | 05-09 Task 2 step 8 |
| One surface per event in foreground | NOTIF-08 | Real duplicate delivery | 05-09 Task 2 step 5 (double send) |
| App runs without `google-services.json` | D-02 | Runtime Firebase failure path | 05-09 Task 2 step 10 (build part automated in 5-01-01 / 5-09-01) |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s per task (builds excluded)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-19 (plan-time; execution sign-off and `wave_0_complete: true` in plan 05-09)
