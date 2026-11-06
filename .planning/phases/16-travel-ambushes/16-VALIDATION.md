---
phase: 16
slug: travel-ambushes
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-06
---

# Phase 16 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test ^10.0.0 + mocktail ^1.0.5 + fake_async ^1.3.3 (pubspec.yaml) |
| **Config file** | none — shared helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `fixtures/quest_result_fixtures.dart`, `fixtures/travel_fixtures.dart`, `fakes/fake_pending_quest_results.dart`, `fakes/recording_quest_result_acknowledger.dart`, `fakes/fake_server_clock_service.dart`) |
| **Quick run command** | `flutter test <touched test paths>` (the `<automated>` command of the task) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, Bash timeout ≥ 300000 ms) |
| **Estimated runtime** | ~10–16 s per task subset; ~76 s full suite (3310 tests at 15-08) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command + the analyzer gate (`OUT=$(flutter analyze 2>&1); ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`, baseline 50 info / 0 error / 0 warning) + trailer check `git log -1 --format=%B | grep -ciE "co-authored-by|generated with"` = 0
- **After every plan wave:** Run `flutter test test/models test/graphql test/tool test/repository test/shared test/screens/mainScreen` (one plan = one wave, linear chain)
- **Before `/gsd-verify-work`:** Full suite must be green (16-07 Task 2)
- **Max feedback latency:** 16 seconds per task subset

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 16-01-01 | 01 | 1 | AMBUSH-02 | T-16-01, T-16-02 | unknown/missing kind → quest; malformed city throws (dropped at the boundary) | unit | `flutter test test/models/quest_result` | ❌ W0 (`quest_result_kind_test.dart`, `ambush_report_test.dart`) | ✅ green |
| 16-01-02 | 01 | 1 | AMBUSH-02 | T-16-01, T-16-03 | ambush without report / quest without quest dropped; fragment grows in the same commit; registry 45 | unit | `flutter test test/models test/graphql test/tool test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components/quest_result_presenter_test.dart test/repository` | ✅ (extend `quest_result_test.dart`, `quest_result_documents_test.dart`) | ✅ green |
| 16-02-01 | 02 | 2 | AMBUSH-01 | T-16-05, T-16-06 | BE title/body verbatim; toggle filters only the ambush push | unit/widget | `flutter test test/models/notification_category_test.dart test/models/push_event_test.dart test/repository/services/push test/repository/storage test/screens/mainScreen/tabs/settings` | ✅ (extend, pinned maps RED first) | ✅ green |
| 16-02-02 | 02 | 2 | AMBUSH-01 | T-16-04 | tap only latches the camera focus | widget | `flutter test test/screens/mainScreen/components/notification_intent_landing_test.dart test/repository/services/push/notification_tap_router_test.dart test/screens/mainScreen/main_screen_test.dart` | ✅ (extend) | ✅ green |
| 16-03-01 | 03 | 3 | AMBUSH-02 | T-16-08 | ambush place as plain text | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (extend) | ✅ green |
| 16-03-02 | 03 | 3 | AMBUSH-02 | T-16-07 | no client branch on rewards; BE zeros hide them | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/components/quest_result_presenter_test.dart` | ✅ (extend) | ✅ green |
| 16-04-01 | 04 | 4 | AMBUSH-02 | T-16-09, T-16-10 | group dedup; external pop requeues unacknowledged | bloc/unit | `flutter test test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` | ✅ (extend `quest_results_queue_test.dart`) | ✅ green |
| 16-04-02 | 04 | 4 | AMBUSH-02 | T-16-11 | one settling read, one chained; no debounce timer | bloc/unit | `flutter test test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` | ✅ (extend `quest_results_delivery_test.dart`) | ✅ green |
| 16-05-01 | 05 | 5 | AMBUSH-02 | T-16-12 | «Continua» closes from any page (user veto); no programmatic paging | widget | `flutter test test/shared/components/popup` | ❌ W0 (`ambush_report_carousel_test.dart`) | ⬜ pending |
| 16-05-02 | 05 | 5 | AMBUSH-02, AMBUSH-03 | T-16-13, T-16-14 | Phase 9 gates; no questEnd banner for ambushes; toggle never gates the carousel | widget | `flutter test test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit test/screens/mainScreen/main_screen_test.dart test/shared/components/popup` | ✅ (extend `quest_result_presenter_test.dart`) | ⬜ pending |
| 16-06-01 | 06 | 6 | AMBUSH-01 | T-16-15 | reroute rendered as received; no lib diff on map/travel | unit/widget | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit test/screens/mainScreen/tabs/map/world_map_travel_test.dart` | ✅ (extend) | ⬜ pending |
| 16-06-02 | 06 | 6 | AMBUSH-03 | T-16-16 | no ambush wording on the confirmation sheet or the quest line | widget/unit | `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart test/models/quest/quest_travel_line_test.dart test/tool/schema_check_documents_test.dart` | ✅ (extend, D-17 pins) | ⬜ pending |
| 16-07-01 | 07 | 7 | AMBUSH-01..03 | T-16-17, T-16-18, T-16-19 | BE read-only; no `.env`; 45/45 OK before the device | gate | `git -C <BE> show origin/develop:src/schema.gql \| grep -c AmbushReport` + `flutter test test/graphql test/tool test/models test/repository` | ✅ | ⬜ pending |
| 16-07-02 | 07 | 7 | AMBUSH-01..03 | T-16-20 | sanity greps: no FE defeat copy, `PushEvent` unchanged, no reroute mechanism, no gated carousel | gate | `flutter test` (full) | ✅ | ⬜ pending |
| 16-08-01 | 08 | 8 | AMBUSH-01..03 | T-16-21 | UAT record without ids/URIs/tokens | doc | `grep -cE "^\| [1-7] \|" .planning/phases/16-travel-ambushes/16-HUMAN-UAT.md` | ❌ (created by the task) | ⬜ pending |
| 16-08-02 | 08 | 8 | AMBUSH-01..03 | T-16-23, T-16-24 | human checkpoint; DB seeds outside the repo | manual | device E2E (`16-HUMAN-UAT.md`) | — | ⬜ pending |
| 16-08-03 | 08 | 8 | AMBUSH-01..03 | T-16-21, T-16-22 | mark-complete only on passed steps | doc | `grep -q "## 4. E2E outcome" .planning/phases/16-travel-ambushes/BACKEND-NOTES.md` | ❌ (created by the task) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/quest_result/quest_result_kind_test.dart`, `test/models/quest_result/ambush_report_test.dart` — AMBUSH-02 (16-01 Task 1)
- [ ] `test/helpers/fixtures/quest_result_fixtures.dart` — `ambushCityJson`, `ambushReportJson` (16-01 Task 1), `ambushWonResultJson`, `ambushLostResultJson` (16-01 Task 2)
- [ ] pinned tests updated RED first (D-17, RESEARCH F7): `quest_result_documents_test.dart` and `quest_result_test.dart` (16-01 Task 2), `notification_category_test.dart`, `push_event_test.dart`, `data_message_handler_test.dart`, `notification_preferences_store_test.dart`, `notification_preferences_cubit_test.dart`, `notification_preferences_section_test.dart` (16-02 Task 1), `notification_intent_landing_test.dart` (16-02 Task 2); registry count stays 45 (`test/tool/schema_check_documents_test.dart`, 16-01/16-06)
- [ ] `test/shared/components/popup/ambush_report_carousel_test.dart` — AMBUSH-02 (16-05 Task 1)
- [ ] characterization pins green at first run by design (no production change): reroute tests (16-06 Task 1), confirmation sheet and quest line pins (16-06 Task 2)

No framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Won ambush: no push, pawn keeps going; at arrival `travelEnd` + one-page carousel with coins and XP, no «Missione conclusa» | AMBUSH-02, AMBUSH-03 | needs the merged BE, the ambush job/sweep and the arrival transaction | `16-HUMAN-UAT.md` step 1 |
| Lost ambush: push + banner «Imboscata!», tap → Map on the pawn restarting from the point, quest lane free | AMBUSH-01 | real FCM, BE reroute of `activeTravel`, `characterUpdated` | step 2 |
| Arrival after a defeat: «Sconfitta», «Portato a <città>», no rewards; cold restart shows nothing | AMBUSH-02 | reports held until arrival, ack on the BE | step 3 |
| Two ambushes → «1 di 2» / «2 di 2», «Continua» on page 1 acknowledges both | AMBUSH-02 | redraw after a victory on the BE, batch delivery by the change stream | step 4 |
| «Imboscate» off: no push/banner, reroute and carousel still there | AMBUSH-01 | device preference vs real push | step 5 |
| Confirmation sheet and quest «Viaggio» line unchanged | AMBUSH-03 | real previews on the device (also pinned by 16-06 tests) | step 6 |
| (optional) GM teleport delivers the held reports | AMBUSH-02 | innkeeper flow on the device | step 7 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 16s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
