---
phase: 6
slug: quest-accept-info-sheets
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-10-21
---

# Phase 6 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK 3.35.5) + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 |
| **Config file** | none (defaults); mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/quest_fixtures.dart` (06-01), helpers `test/helpers/haptic_recorder.dart` (06-05), `test/helpers/svg_cache_seed.dart` (06-06) |
| **Quick run command** | `flutter test test/models test/graphql test/repository test/screens/mainScreen test/screens/auth test/shared test/tool` |
| **Full suite command** | `flutter test` (baseline 1006) + `flutter analyze` (≤ 56, 0 errors) + `dart format --output=none --set-exit-if-changed <new or format-clean touched files>` |
| **Estimated runtime** | ~30 seconds (full suite) |

---

## Sampling Rate

- **After every task commit:** the task's test file(s) + `flutter analyze <touched files>`
- **After every plan wave:** quick run command
- **Before `/gsd-verify-work`:** full suite green, schema check 29/29 OK against BE `origin/develop` (after the BE Phase 8 merge), device E2E done
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-01-01 | 01 | 1 | QUEST-03..07 | T-06-01-04 | amendments on record | docs | `grep -c '_Emendato il 2026-10-21' .planning/REQUIREMENTS.md` | ✅ | ✅ green |
| 06-01-02 | 01 | 1 | QUEST-04 | T-06-01-01/02 | malformed quest skipped; D-32 mirrored; `hasRankSlots` only for the Phase 8 list | unit | `flutter test test/models/quest` | ❌ W0 | ✅ green |
| 06-01-03 | 01 | 1 | QUEST-04, QUEST-07 | T-06-01-03 | lanes select only `quest { id }` | unit | `flutter test test/models/pending_quest_test.dart test/models/character/character_quests_test.dart test/graphql/character_fragment_test.dart` | ❌ W0 | ✅ green |
| 06-02-01 | 02 | 2 | QUEST-04 | T-06-02-01 | classifier advisory, BE order; legacy `Int` 0 = no client constraint (`legacy-0`) | unit | `flutter test test/models/quest/quest_lane_test.dart test/models/quest/quest_availability_test.dart` | ❌ W0 | ✅ green |
| 06-02-02 | 02 | 2 | QUEST-04 | T-06-02-04 | city/lane/title listing | unit | `flutter test test/models/quest/board_policy_test.dart` | ❌ W0 | ✅ green |
| 06-02-03 | 02 | 2 | QUEST-05, QUEST-07 | T-06-02-02/03 | cost by type; label without clock | unit | `flutter test test/models/quest/quest_cost_line_test.dart test/models/quest/quest_state_label_test.dart test/models/quest/quest_blocked_reason_test.dart test/models/enums/title_type_test.dart` | ❌ W0 | ✅ green |
| 06-03-01 | 03 | 2 | QUEST-03 | T-06-03-04 | `successful:false` is a failure | unit | `flutter test test/graphql/quest_mutations_test.dart test/models/request/accept_quest_request_test.dart test/repository/services/graphql/graphql_quest_acceptance_test.dart test/tool` | ❌ W0 | ✅ green |
| 06-03-02 | 03 | 2 | QUEST-06 | T-06-03-01/03 | codes only, never message text | unit | `flutter test test/repository/quest_acceptance_failure_test.dart test/repository/quest_acceptance_repository_test.dart` | ❌ W0 | ✅ green |
| 06-03-03 | 03 | 2 | QUEST-02, QUEST-06 | T-06-03-02/05/06 | double-submit guard; late response ignored | cubit | `flutter test test/screens/mainScreen/questAcceptanceCubit test/screens/auth/authenticated_shell_test.dart` | ❌ W0 | ✅ green |
| 06-04-01 | 04 | 1 | QUEST-06 | T-06-04-02/04 | dedup window; push path unchanged | cubit (fake_async) | `flutter test test/screens/auth/inAppNotificationsCubit` | ✅ extend | ✅ green |
| 06-04-02 | 04 | 1 | QUEST-06 | T-06-04-03 | notice tap = dismiss only | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | ✅ extend | ✅ green |
| 06-05-01 | 05 | 1 | QUEST-02 | T-06-05-01 | thresholds pinned | unit | `flutter test test/shared/components/tear/tear_gesture_test.dart test/shared/components/tear/tear_geometry_test.dart` | ❌ W0 | ✅ green |
| 06-05-02 | 05 | 1 | QUEST-02 | T-06-05-02/03/04 | single onTorn; blocked resists | widget | `flutter test test/shared/components/tear/tearable_paper_test.dart` | ❌ W0 | ✅ green |
| 06-06-01 | 06 | 3 | QUEST-01, QUEST-05 | T-06-06-03 | counts only, no ids | unit | `flutter test test/models/quest/quest_sheet_details_test.dart` | ❌ W0 | ✅ green |
| 06-06-02 | 06 | 3 | QUEST-01, QUEST-05 | T-06-06-01/04 | families render without G1 data | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart` | ❌ W0 | ✅ green |
| 06-07-01 | 07 | 3 | QUEST-04 | T-06-07-01/04/05 | tolerant list; typed `$id` | unit | `flutter test test/graphql/board_documents_test.dart test/repository/services/graphql/graphql_board_data_test.dart test/tool` | ❌ W0 | ✅ green |
| 06-07-02 | 07 | 3 | QUEST-04 | T-06-07-02/03/06 | never QuestLoading on refresh; cubit → `QuestBoardRepository` only; `loadQuest` keeps city POIs | cubit + unit | `flutter test test/screens/mainScreen/questCubit/quest_cubit_test.dart test/repository/quest_board_repository_test.dart` | ✅ extend + ❌ W0 | ✅ green |
| 06-08-01 | 08 | 3 | QUEST-04 | T-06-08-03 | policy pure | unit | `flutter test test/screens/mainScreen/components/satchel_availability_test.dart` | ❌ W0 | ✅ green |
| 06-08-02 | 08 | 3 | QUEST-04 | T-06-08-01/02 | onItemTap guard; no inner Stack, enabled item still taps (`satchel wiring`) | widget | `flutter test test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` | ✅ extend | ✅ green |
| 06-09-01 | 09 | 4 | QUEST-04 | — | deterministic paper | unit + widget | `flutter test test/models/quest/quest_paper_asset_test.dart test/screens/mainScreen/tabs/board/sheet_test.dart` | ❌ W0 | ✅ green |
| 06-09-02 | 09 | 4 | QUEST-01, QUEST-04 | T-06-09-01/02/03 | POIs only of the current city | widget | `flutter test test/screens/mainScreen/tabs/board/board_test.dart` | ❌ W0 | ✅ green |
| 06-10-01 | 10 | 5 | QUEST-02 | T-06-10-01/02/05 | session character id; blocked swipe | widget | `flutter test test/screens/mainScreen/tabs/board/board_acceptance_test.dart` | ❌ W0 | ✅ green |
| 06-10-02 | 10 | 5 | QUEST-03, QUEST-06 | T-06-10-03/04/06/07 | Map only on success; domain banner also after leaving the Board (session listener) | widget | `flutter test test/screens/mainScreen/tabs/board/board_acceptance_test.dart test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart` | ❌ W0 | ✅ green |
| 06-11-01 | 11 | 5 | QUEST-03, QUEST-07 | T-06-11-01/03 | no clock in the paper | widget | `flutter test test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart` | ❌ W0 | ✅ green |
| 06-11-02 | 11 | 5 | QUEST-02, QUEST-03 | T-06-11-02 | no gesture on the Map overlay | widget | `flutter test test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` | ❌ W0 | ✅ green |
| 06-12-01 | 12 | 6 | all | T-06-12-01/02/05 | documents valid vs BE Phase 8 schema | unit + scripted | `flutter test test/graphql/board_documents_test.dart test/tool` + schema check | ✅ | ✅ green |
| 06-12-02 | 12 | 6 | all | T-06-12-03 | rejections surface as domain banners | manual | device E2E (06-HUMAN-UAT.md) | — | ⬜ pending (human E2E) |
| 06-12-03 | 12 | 6 | all | T-06-12-04 | ticks only for passed steps | docs | `grep -c '^status: complete' .planning/phases/06-quest-accept-info-sheets/06-HUMAN-UAT.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Wave 0 is folded into the RED step of each task (TDD): every `❌ W0` file above is created failing-first by its own task.

- [ ] `test/helpers/fixtures/quest_fixtures.dart` — Phase 8-shaped + legacy quest/lane/character JSON (06-01 Task 2; `buildViewer`/`buildLanes` in 06-02)
- [ ] `test/helpers/mocks.dart` — `MockQuestAcceptanceRepository`, `MockQuestAcceptanceCubit` (06-03), `MockInAppNotificationsCubit` (06-04), `MockQuestBoardRepository` (06-07)
- [ ] `test/helpers/haptic_recorder.dart` (06-05), `test/helpers/svg_cache_seed.dart` (06-06)
- [ ] (deferred to E2E step 3) Probe of the final `quests` document against a running BE (06-12 Task 1 step 4; G1/G2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Tear feel, haptic pattern, Map paper, banners on a real device against BE Phase 8 | QUEST-01..07 | haptics and real backend data cannot be judged in widget tests; needs the user's Android phone and a running BE with the UAT catalogue | 06-12 Task 2 (12 steps), recorded in `06-HUMAN-UAT.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 60s
- [x] Nyquist compliance flag set in frontmatter (06-12 Task 1)

**Approval:** pending
