---
phase: 15
slug: travel-food
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-05
---

# Phase 15 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test ^10.0.0 + mocktail ^1.0.5 + fake_async ^1.3.3 (pubspec.yaml) |
| **Config file** | none — shared helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `fixtures/travel_fixtures.dart`, `fakes/fake_server_clock_service.dart`, `haptic_recorder.dart`) |
| **Quick run command** | `flutter test <touched test paths>` (the `<automated>` command of the task) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, Bash timeout ≥ 300000 ms) |
| **Estimated runtime** | ~10 s per task subset (251 phase-subset tests measured at research); ~75 s full suite (3180 tests at 14-10) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command + the analyzer gate (`OUT=$(flutter analyze 2>&1); ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`, baseline 50 info / 0 error / 0 warning) + trailer check `git log -1 --format=%B | grep -ciE "co-authored-by|generated with"` = 0
- **After every plan wave:** Run `flutter test test/models test/graphql test/tool test/repository test/shared test/screens/auth test/screens/mainScreen` (one plan = one wave, linear chain)
- **Before `/gsd-verify-work`:** Full suite must be green (15-08 Task 2)
- **Max feedback latency:** 15 seconds per task subset

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 15-01-01 | 01 | 1 | FOOD-01 | T-15-01 | malformed food entry dropped; item whitelist `{id, name}` | unit | `flutter test test/models/travel` | ❌ W0 (`travel_food_item_test.dart`) | ⬜ pending |
| 15-01-02 | 01 | 1 | FOOD-01, FOOD-02 | T-15-01, T-15-02 | missing fields → `[]`/0/`true`; core fields strict; document selects `food { quantity item { id name } }` | unit | `flutter test test/models/travel test/graphql test/tool test/repository/services/graphql/graphql_travel_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` | ✅ (extend `travel_preview_test.dart`, `travel_documents_test.dart`) | ⬜ pending |
| 15-01-03 | 01 | 1 | FOOD-01, FOOD-02, FOOD-04 | T-15-03 | texts print BE values only; `−` is U+2212 | unit | `flutter test test/models test/shared/components/popup/quest_info_sheet_test.dart` | ❌ W0 (`quantity_line_test.dart`, `travel_cost_text_test.dart`) | ⬜ pending |
| 15-02-01 | 02 | 2 | FOOD-02 | T-15-06 | shared fragment only; registry 45 | unit | `flutter test test/graphql test/tool` | ✅ (extend) | ⬜ pending |
| 15-02-02 | 02 | 2 | FOOD-02 | T-15-04, T-15-05 | `null` → null; missing/malformed → FormatException; coded error kept; never cached | unit | `flutter test test/repository/services/graphql/graphql_travel_test.dart test/repository` | ✅ (extend) | ⬜ pending |
| 15-03-01 | 03 | 3 | FOOD-03 | T-15-07, T-15-09 | `TRAVEL_STARVING` → `starving`; banner copy from the FE catalogue | unit | `flutter test test/repository/travel_failure_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/components/travel_outcome_listener_test.dart` | ✅ (extend) | ⬜ pending |
| 15-03-02 | 03 | 3 | FOOD-03 | T-15-07, T-15-09 | acceptance `starving`; banner; no board reread | unit/widget | `flutter test test/repository/quest_acceptance_failure_test.dart test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart test/screens/mainScreen/tabs/board` | ✅ (extend) | ⬜ pending |
| 15-03-03 | 03 | 3 | FOOD-02 | T-15-08 | 15 s timeout → `timedOut`; no permission prompt | unit | `flutter test test/repository` | ✅ (extend) | ⬜ pending |
| 15-04-01 | 04 | 4 | FOOD-03 | T-15-10, T-15-11 | requote only on starving; token drops late answers; no cubit food check | bloc | `flutter test test/screens/mainScreen/travelCubit test/screens/mainScreen/tabs/map test/screens/mainScreen/components` | ✅ (extend) | ⬜ pending |
| 15-04-02 | 04 | 4 | FOOD-03 | T-15-12 | one banner per requote edge, no reset | widget | `flutter test test/screens/mainScreen/components test/screens/mainScreen/travelCubit` | ✅ (extend) | ⬜ pending |
| 15-04-03 | 04 | 4 | FOOD-03 | — | N/A (pawn/camera hold) | widget | `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/travelCubit test/screens/mainScreen/components` | ✅ (extend) | ⬜ pending |
| 15-05-01 | 05 | 5 | FOOD-01, FOOD-04 | T-15-13, T-15-14, T-15-15 | «Parti» gated on `arrivesAlive`; wrapped rows; no `hpLost` in the widget | widget | `flutter test test/screens/mainScreen/tabs/map` | ✅ (extend, placeholders 3 → 5) | ⬜ pending |
| 15-05-02 | 05 | 5 | FOOD-03 | T-15-13 | sheet open through the requote; other refusals close it | widget | `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/components` | ✅ (extend) | ⬜ pending |
| 15-06-01 | 06 | 6 | FOOD-02 | T-15-16, T-15-17 | line from BE values only; narrative always null | unit | `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart` | ❌ W0 (`quest_travel_line_test.dart`) | ⬜ pending |
| 15-06-02 | 06 | 6 | FOOD-02, FOOD-03 | T-15-17 | no line without a preview (read-only path) | widget | `flutter test test/shared/components/popup test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map test/models/quest` | ✅ (extend) | ⬜ pending |
| 15-07-01 | 07 | 7 | FOOD-02 | T-15-19 | request only when acceptable + standard lane; token + SafeEmit | bloc/unit | `flutter test test/screens/mainScreen/tabs/board/questTravelPreviewCubit test/models/quest` | ❌ W0 (`quest_travel_preview_cubit_test.dart`) | ⬜ pending |
| 15-07-02 | 07 | 7 | FOOD-02 | — | N/A (one shared repository) | widget | `flutter test test/screens/auth test/screens/mainScreen/tabs/board test/screens/mainScreen/main_screen_test.dart` | ✅ (Board harness W0) | ⬜ pending |
| 15-07-03 | 07 | 7 | FOOD-02, FOOD-03 | T-15-18, T-15-20, T-15-21 | session character only; starving paper resists; refresh on starving refusal | widget | `flutter test test/screens/mainScreen/tabs/board test/screens/mainScreen test/shared/components/popup` | ✅ (extend) | ⬜ pending |
| 15-08-01 | 08 | 8 | FOOD-01..04 | T-15-22, T-15-23, T-15-24 | BE read-only; no `.env`; 45/45 OK before the device | gate | `git -C <BE> show origin/develop:src/schema.gql \| grep -c TravelFoodItem` + `flutter test test/graphql test/tool test/models test/repository` | ✅ | ⬜ pending |
| 15-08-02 | 08 | 8 | FOOD-01..04 | T-15-25 | sanity greps: no client arithmetic, no stale swipe gate | gate | `flutter test` (full) | ✅ | ⬜ pending |
| 15-09-01 | 09 | 9 | FOOD-01..04 | T-15-26 | UAT record without ids/URIs/tokens | doc | `grep -cE "^\| [1-7] \|" .planning/phases/15-travel-food/15-HUMAN-UAT.md` | ❌ (created by the task) | ⬜ pending |
| 15-09-02 | 09 | 9 | FOOD-01..04 | T-15-28, T-15-29 | human checkpoint; DB seeds outside the repo | manual | device E2E (`15-HUMAN-UAT.md`) | — | ⬜ pending |
| 15-09-03 | 09 | 9 | FOOD-01..04 | T-15-26, T-15-27 | mark-complete only on passed steps | doc | `grep -q "## 4. E2E outcome" .planning/phases/15-travel-food/BACKEND-NOTES.md` | ❌ (created by the task) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/travel/travel_food_item_test.dart` — FOOD-01 (15-01 Task 1)
- [ ] `test/helpers/fixtures/travel_fixtures.dart` — `travelFoodItemJson` + `food`/`hpLost`/`arrivesAlive` params of `travelPreviewJson`, emitted only when given (15-01 Task 1)
- [ ] `test/models/quantity_line_test.dart`, `test/models/travel/travel_cost_text_test.dart` — FOOD-01/02/04 (15-01 Task 3)
- [ ] pinned tests updated RED first (D-12): `test/graphql/travel_documents_test.dart` selection (15-01 Task 2), registry count 44 → 45 in `travel_documents_test.dart` and `test/tool/schema_check_documents_test.dart` (15-02 Task 1), placeholders 3 → 5 in `travel_confirmation_sheet_test.dart` (15-05 Task 1)
- [ ] `test/models/quest/quest_travel_line_test.dart` — FOOD-02 (15-06 Task 1)
- [ ] `test/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit_test.dart` — FOOD-02 (15-07 Task 1)
- [ ] Board harness: `RepositoryProvider<TravelRepository>.value` + default `previewQuest → null` stub in `board_test.dart` and `board_acceptance_test.dart` (15-07 Task 2)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Trip fully covered: «Cibo» list, «Vita: nessuna perdita», food decreased in the Journal | FOOD-01, FOOD-04 | needs the merged BE, real food consumption and `characterUpdated` | `15-HUMAN-UAT.md` step 1 |
| Trip partially covered: «Vita: −N HP», HP reduced in the Journal | FOOD-01, FOOD-04 | BE-side HP loss at departure | step 2 |
| Trip refused at preview: red phrase, «Parti» disabled | FOOD-01 | BE `arrivesAlive` on real numbers | step 3 |
| Starving refusal at departure: banner, sheet open, route kept | FOOD-03 | DB change between preview and «Parti» | step 4 |
| «Viaggio» line on combat/service sheets only | FOOD-02 | BE owner-only `questTravelPreview` on real markers | step 5 |
| Starving quest: red line, paper resists; refusal recomposes | FOOD-02, FOOD-03 | DB change between preview and swipe | step 6 |
| Teleport consumes nothing | FOOD-04 | innkeeper flow on the device | step 7 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 15s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
