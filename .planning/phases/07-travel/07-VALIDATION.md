---
phase: 7
slug: travel
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-10-24
---

# Phase 7 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK 3.35.5 / Dart 3.9.2) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 |
| **Config file** | none (defaults); mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/travel_fixtures.dart` (07-01), fakes `test/helpers/fakes/fake_server_clock_service.dart` (07-03) and the existing `fake_notification_permission_port.dart`, map harness `test/helpers/map_harness.dart` (07-08), `buildTestApp`, `useLandscapePhone`, `seedSvgCache` |
| **Quick run command** | `flutter test test/models test/graphql test/repository test/tool test/screens/mainScreen test/screens/auth` |
| **Full suite command** | `flutter test` (baseline 1350) + `flutter analyze` (≤ 54 issues, 0 errors) + `dart format --output=none --set-exit-if-changed <each new or format-clean touched file>` + `tool/schema_check` vs BE `origin/develop` (32 `OK`) |
| **Estimated runtime** | per task ~5-20 s (task test files); quick run ~20 s; full suite ~40 s |

---

## Sampling Rate

- **After every task commit:** the task's test file(s) (`<automated>` of the task) + `flutter analyze <touched files>` + format check on new/clean files only
- **After every plan (wave sampling):** the quick run command
- **Before `/gsd-verify-work`:** full suite green, analyzer ≤ 54 / 0 errors, schema check 32/32 against BE `origin/develop`, device E2E recorded (07-11)
- **Max feedback latency:** 60 seconds (full `flutter test` only in 07-11, repo rule)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 07-01-01 | 01 | 1 | TRAVEL-02 | T-07-01-05 | "no cost" amendment on record (C3) | docs | `grep -c 'ETA + costo' .planning/PROJECT.md docs/rules/ui-ux.md` (= 0) + `grep -c '_Emendato il 2026-10-24' .planning/REQUIREMENTS.md` (≥ 2) | ✅ | ✅ green |
| 07-01-02 | 01 | 1 | TRAVEL-01, TRAVEL-04 | T-07-01-01/04 | malformed travel → null; shared point order (C1) | unit | `flutter test test/models/wire_lat_lng_test.dart test/models/point_of_interest_test.dart test/models/travel` | ❌ W0 | ✅ green |
| 07-01-03 | 01 | 1 | TRAVEL-01, TRAVEL-04 | T-07-01-01/02/03 | `activeTravel` parsed, no `copyWith` forgery, no `pet` selected | unit | `flutter test test/models/character test/graphql test/repository/services/graphql test/screens/mainScreen/characterCubit` | ❌ W0 (+ extend fragment test) | ✅ green |
| 07-02-01 | 02 | 1 | TRAVEL-03 | T-07-02-01/02 | no crash on degenerate routes; progress only from server now | unit | `flutter test test/models/travel/travel_route_test.dart` | ❌ W0 | ✅ green |
| 07-02-02 | 02 | 1 | TRAVEL-02 | T-07-02-03 | same city → no destination (D-02) | unit | `flutter test test/models/travel/travel_time_format_test.dart test/models/travel/travel_destination_test.dart` | ❌ W0 | ✅ green |
| 07-03-01 | 03 | 1 | TRAVEL-03 | T-07-03-01/02 | RTT offset, silent failure, resync on resume, `offsetChanges` after each successful sync | unit (fake_async) | `flutter test test/repository/services/time/server_clock_service_test.dart` | ❌ W0 | ✅ green |
| 07-03-02 | 03 | 1 | TRAVEL-02 | T-07-03-03/04/05 | codes only, fixed copy, no banner on UNAUTHENTICATED | unit | `flutter test test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit` | ❌ W0 | ✅ green |
| 07-04-01 | 04 | 2 | TRAVEL-03 | T-07-04-01 | Board + Shop disabled off a marker and while travelling | unit + widget | `flutter test test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` | ✅ extend | ✅ green |
| 07-04-02 | 04 | 2 | TRAVEL-03 | T-07-04-02/03 | travelEnd tap only latches a focus on the own pawn | cubit + widget | `flutter test test/screens/mainScreen/tabs/map/map_focus_cubit_test.dart test/screens/mainScreen/components/notification_intent_landing_test.dart test/screens/auth/authenticated_shell_test.dart` | ❌ W0 + ✅ extend | ✅ green |
| 07-05-01 | 05 | 2 | TRAVEL-02, TRAVEL-03 | T-07-05-06 | typed `$request`; registry 32 | unit + scripted | `flutter test test/models/request/travel_request_test.dart test/graphql/travel_documents_test.dart test/tool` (+ early schema check) | ❌ W0 | ⬜ pending |
| 07-05-02 | 05 | 2 | TRAVEL-02, TRAVEL-03 | T-07-05-01/02 | `successful:false` is a failure; codes preserved | unit | `flutter test test/repository/services/graphql` | ❌ W0 | ⬜ pending |
| 07-05-03 | 05 | 2 | TRAVEL-02 | T-07-05-03/04/05 | no OperationException leaks; 15 s timeout; permission prompt only after success | unit (fake_async) | `flutter test test/repository/travel_repository_test.dart test/repository` | ❌ W0 | ⬜ pending |
| 07-06-01 | 06 | 2 | TRAVEL-03, TRAVEL-04 | T-07-06-01/03 | deterministic position; memo per travel; empty route safe | cubit | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit` | ❌ W0 | ⬜ pending |
| 07-06-02 | 06 | 2 | TRAVEL-03 | T-07-06-02/04/05/06 | ≤ 2 refetch requests per offset, timer stops only when settled on a synced clock, recomputes + restarts on `offsetChanges` ("resync" test), server time only | cubit (fake_async) | `flutter test test/screens/mainScreen/tabs/map/travelProgressCubit` | ✅ (07-06-01) | ⬜ pending |
| 07-07-01 | 07 | 3 | TRAVEL-02 | T-07-07-01/02/05 | double "Parti" ignored; late answers ignored by request token; 30 s hold | cubit (fake_async) | `flutter test test/screens/mainScreen/travelCubit` | ❌ W0 | ⬜ pending |
| 07-07-02 | 07 | 3 | TRAVEL-02 | T-07-07-03/04/06 | banner by code once; settle on activeTravel; clock/cubit closed with the shell | widget | `flutter test test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart test/screens/auth` | ❌ W0 + ✅ extend | ⬜ pending |
| 07-08-01 | 08 | 4 | TRAVEL-03 | T-07-08-01 | degenerate polylines skipped | widget | `flutter test test/screens/mainScreen/tabs/map/travel_route_layer_test.dart` | ❌ W0 | ⬜ pending |
| 07-08-02 | 08 | 4 | TRAVEL-02 | T-07-08-02/03/04/05 | "Parti" only on shown numbers; sheet closes itself if mounted on an already settled state; no chrome; no blocking loading | widget | `flutter test test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` | ❌ W0 | ⬜ pending |
| 07-09-01 | 09 | 5 | TRAVEL-03, TRAVEL-04 | T-07-09-02/03/04 | controller used only after map ready; bounded rereads; no leaked timers | widget | `flutter test test/screens/mainScreen/tabs/map` | ❌ W0 | ⬜ pending |
| 07-09-02 | 09 | 5 | TRAVEL-02 | T-07-09-01/05/06 | no client teleport; same city silent; cubit passed to the root sheet; no sheet stuck after an early rejection | widget | `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/characterCubit` | ✅ (07-09-01) | ⬜ pending |
| 07-10-01 | 10 | 6 | TRAVEL-02 | T-07-10-02/04 | drag only when free; no spring back on unrelated events | widget | `flutter test test/screens/mainScreen/tabs/map` | ❌ W0 | ⬜ pending |
| 07-10-02 | 10 | 6 | TRAVEL-03, TRAVEL-04 | T-07-10-01/03/05 | pawn from backend data only; snap on the BE event; reconstruction after kill | widget | `flutter test test/screens/mainScreen/tabs/map` | ✅ (07-10-01, 07-09) | ⬜ pending |
| 07-11-01 | 11 | 7 | all | T-07-11-01/02 | documents valid vs BE `origin/develop`; gates | scripted + full suite | schema check (32 `OK`) + `flutter test` + `flutter analyze` | ✅ | ⬜ pending |
| 07-11-02 | 11 | 7 | all | T-07-11-03/04 | server-time interpolation, prompt after "Parti", rejections as domain banners | manual | device E2E (`07-HUMAN-UAT.md`) | — | ⬜ pending (human E2E) |
| 07-11-03 | 11 | 7 | all | T-07-11-05/06 | ticks only for passed steps | docs | `grep -c '^status: complete' .planning/phases/07-travel/07-HUMAN-UAT.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is folded into the RED step of each task (TDD): every `❌ W0` file above is created failing-first by its own task, before the implementation.

- [x] `test/helpers/fixtures/travel_fixtures.dart` — `departureWire`/`destinationWire`, `travelPathJson`, `activeTravelJson`, `travelPreviewJson`, `travellingCharacterJson`, `travelCityJson` (07-01 Task 2; polyline endpoints equal the POI locations, C1)
- [x] `test/helpers/fakes/fake_server_clock_service.dart` — settable server now, settable `isSynced`, `resync(...)` emitting on `offsetChanges` (07-03 Task 1)
- [ ] `test/helpers/mocks.dart` — `MockTravelRepository` (07-05), `MockTravelCubit` (07-07), `MockTravelProgressCubit` (07-08), `MockWorldMapCubit` (07-09)
- [ ] `test/helpers/map_harness.dart` — minimal offline `FlutterMap` wrapper (07-08 Task 1)
- [ ] C1 device probe written into the E2E recipe (07-11 Task 2 step 1)

No framework install needed: every library is already in `pubspec.yaml` / `pubspec.lock`.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dashed preview starts on the pawn (C1 coordinate order on real data) | TRAVEL-02, TRAVEL-03 | needs the real BE road graph and the real map image | 07-11 Task 2 step 1 |
| Moving the phone clock does not move the pawn | TRAVEL-03 | system clock change on a device | 07-11 Task 2 step 4 |
| Kill mid-travel and relaunch resumes on the road | TRAVEL-04 | process death + cold start on a device | 07-11 Task 2 step 5 |
| "Viaggio completato" push in killed/background/foreground + tap → camera on the pawn | TRAVEL-03 | FCM delivery and OS notification tap | 07-11 Task 2 step 6 |
| Automatic quest travel without push | TRAVEL-03 | BE job/sweep timing with real data | 07-11 Task 2 step 7 |
| TRAVEL_IN_PROGRESS / QUEST_IN_PROGRESS banners from a real race | TRAVEL-02 | needs a second client acting on the same character | 07-11 Task 2 step 8 |
| Teleport by hand, pet halving the duration | TRAVEL-03 | innkeeper call and DB-prepared pet | 07-11 Task 2 steps 9-10 |
| Permission prompt only after the first successful "Parti" | TRAVEL-02 | OS permission dialog | 07-11 Task 2 step 3 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references (set when 07-11 Task 1 confirms every `❌ W0` file exists)
- [x] No watch-mode flags
- [x] Feedback latency < 60s per task
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
