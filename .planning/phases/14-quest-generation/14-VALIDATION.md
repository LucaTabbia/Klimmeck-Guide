---
phase: 14
slug: quest-generation
status: approved
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-04
---

# Phase 14 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 (pubspec.lock) |
| **Config file** | none — shared helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `fixtures/`) |
| **Quick run command** | `flutter test <touched test paths>` |
| **Full suite command** | `flutter test` (foreground, Bash timeout ≥ 300000 ms) |
| **Estimated runtime** | ~14 s per task subset; ~75 s full suite (3031 tests at the end of Phase 13) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test paths>` (the `<automated>` command of the task) + the analyzer gate (`ANALYZE_GATE_OK`, ≤ 50 issues, 0 error / 0 warning)
- **After every plan wave:** Run `flutter test test/models test/utils test/graphql test/tool test/repository test/shared test/screens/innkeeper test/screens/mainScreen` (one plan = one wave, linear chain)
- **Before `/gsd-verify-work`:** Full suite must be green (14-10 Task 2)
- **Max feedback latency:** 14 seconds per task subset

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 14-01-01 | 01 | 1 | QGEN-01 | T-14-01, T-14-02 | malformed entry → FormatException; enemy whitelist id/name/imagePath/xp | unit | `flutter test test/models/quest/quest_enemy_test.dart` | ✅ | ✅ green |
| 14-01-02 | 01 | 1 | QGEN-01, QGEN-05 | T-14-01, T-14-03 | bad `enemies` entry skips only that quest; pet without id ignored | unit | `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/board` | ✅ | ✅ green |
| 14-01-03 | 01 | 1 | QGEN-01 | — | N/A | unit | `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart` | ✅ | ✅ green |
| 14-02-01 | 02 | 2 | QGEN-02 | T-14-04, T-14-05 | malformed result entry dropped, result kept; non-numeric stage → null | unit | `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart test/repository test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit test/screens/innkeeper` | ✅ | ✅ green |
| 14-02-02 | 02 | 2 | QGEN-02 | T-14-05 | pet without id ignored; pet-only reward not empty | unit | `flutter test test/models/quest_result test/shared/components/popup/quest_result_sheet_test.dart` | ✅ | ✅ green |
| 14-03-01 | 03 | 3 | QGEN-01, QGEN-05 | T-14-06, T-14-07 | no `relatedLore`/`locations` under an enemy; no old single-enemy selection | unit | `flutter test test/graphql test/tool test/models/quest` | ✅ | ✅ green |
| 14-03-02 | 03 | 3 | QGEN-02 | T-14-06, T-14-07 | same, for the result fragment | unit | `flutter test test/graphql test/tool test/models/quest_result test/repository/services/graphql` | ✅ | ✅ green |
| 14-04-01 | 04 | 4 | QGEN-01, QGEN-02 | T-14-08 | only `https` with host or Cloudinary `v<n>/…`; http/file/data → null | unit | `flutter test test/utils/enemy_portrait_url_test.dart` | ❌ W0 | ⬜ pending |
| 14-04-02 | 04 | 4 | QGEN-01, QGEN-02 | T-14-09 | failed/unresolvable portrait → empty box, no spinner, offline tests | widget | `flutter test test/shared/components/enemy_portrait_test.dart test/utils/enemy_portrait_url_test.dart` | ❌ W0 | ⬜ pending |
| 14-05-01 | 05 | 5 | QGEN-01 | T-14-10, T-14-11 | no overflow with many lines; no `Image.asset` | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map` | ✅ | ⬜ pending |
| 14-05-02 | 05 | 5 | QGEN-05 | T-14-10 | long announcement scrolls, plain `Text` | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart` | ✅ | ⬜ pending |
| 14-05-03 | 05 | 5 | QGEN-01 | — | N/A | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/models/quest` | ✅ | ⬜ pending |
| 14-05-04 | 05 | 5 | QGEN-04 | — | N/A (proof, no production change) | widget/unit | `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart` | ✅ | ⬜ pending |
| 14-06-01 | 06 | 6 | QGEN-02 | T-14-13 | portrait only through `EnemyPortrait`; no `Image.asset` | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen/components` | ✅ | ⬜ pending |
| 14-06-02 | 06 | 6 | QGEN-02, QGEN-04 | T-14-12 | counters printed, never computed | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart test/screens/mainScreen test/screens/innkeeper` | ✅ | ⬜ pending |
| 14-07-01 | 07 | 7 | QGEN-03 | T-14-16 | only `extensions.code`; `created` missing → FormatException | unit | `flutter test test/graphql test/tool test/repository/services/graphql/graphql_generate_quests_test.dart` | ❌ W0 | ⬜ pending |
| 14-07-02 | 07 | 7 | QGEN-03 | T-14-14, T-14-16 | FORBIDDEN → forbidden; 15 s timeout; classifier unchanged | unit | `flutter test test/repository/innkeeper_repository_test.dart` | ✅ | ⬜ pending |
| 14-07-03 | 07 | 7 | QGEN-03 | T-14-15 | second call ignored while submitting; distinct failure serials | bloc | `flutter test test/screens/innkeeper test/repository/innkeeper_repository_test.dart` | ❌ W0 | ⬜ pending |
| 14-08-01 | 08 | 8 | QGEN-03 | T-14-17 | button disabled while submitting; cubit provided by the route | widget | `flutter test test/screens/innkeeper test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart` | ❌ W0 | ⬜ pending |
| 14-08-02 | 08 | 8 | QGEN-03 | T-14-17 | confirmation before the call; «Annulla» sends nothing | widget | `flutter test test/screens/innkeeper` | ✅ | ⬜ pending |
| 14-08-03 | 08 | 8 | QGEN-03 | T-14-18, T-14-19 | FORBIDDEN closes the panel; fixed copy, never the server message | widget | `flutter test test/screens/innkeeper test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart` | ✅ | ⬜ pending |
| 14-09-01 | 09 | 9 | QGEN-06 | T-14-20 | unknown use name dropped (`asNameMap`), never a throw | unit | `flutter test test/models/enums/accessory_use_type_test.dart test/models/equipment_item_test.dart test/utils/item_lines_test.dart test/utils/filter_values_test.dart` | ❌ W0 | ⬜ pending |
| 14-09-02 | 09 | 9 | QGEN-06 | — | N/A | unit | `flutter test test/graphql test/tool` | ✅ | ⬜ pending |
| 14-09-03 | 09 | 9 | QGEN-06 | T-14-21 | no filter, no equip constraint, no list icon | widget | `flutter test test/shared/components/popup/equipment_info_sheet_test.dart test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop` | ✅ | ⬜ pending |
| 14-10-01 | 10 | 10 | QGEN-01, QGEN-02, QGEN-03, QGEN-05, QGEN-06 | T-14-22, T-14-23, T-14-24 | names proven on the merged SDL, 44/44 OK; BE read-only | cross-repo | gate `git -C <BE> show origin/develop:src/schema.gql \| grep -c QuestEnemy` ≥ 1, then `flutter test test/graphql test/tool test/models` + `validate_documents.js` | ✅ | ⬜ pending (gated: BE Phase 13 merge) |
| 14-10-02 | 10 | 10 | QGEN-01..06 | T-14-25 | full suite, analyzer, format, trailers, sanity greps | full suite | `flutter test` | ✅ | ⬜ pending (gated) |
| 14-11-01 | 11 | 11 | QGEN-01..06 | — | gate re-check, UAT file without secrets | manual prep | `test -f .planning/phases/14-quest-generation/14-HUMAN-UAT.md` | ❌ W11 | ⬜ pending (gated) |
| 14-11-02 | 11 | 11 | QGEN-01..06 | T-14-29 | device E2E against the merged BE | manual (human E2E) | `test -f .planning/phases/14-quest-generation/14-HUMAN-UAT.md` | ❌ W11 | ⬜ pending (human E2E) |
| 14-11-03 | 11 | 11 | QGEN-01..06 | T-14-26, T-14-27, T-14-28 | mark-complete only on passed steps; no ids/tokens/URIs in notes | records | `grep -q "## 4. E2E outcome" .planning/phases/14-quest-generation/BACKEND-NOTES.md` | ❌ W11 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each «❌ W0» file is created by the RED step of its own task (TDD, tests before code); no framework install needed.

- [x] `test/models/quest/quest_enemy_test.dart` — QGEN-01 (14-01-01)
- [x] `test/helpers/fixtures/quest_fixtures.dart` → `questEnemyJson`, `enemies` / `description` / `prizes` params — QGEN-01, QGEN-05 (14-01-02)
- [x] `test/helpers/fixtures/quest_result_fixtures.dart` → `enemies`, stages, `rewardPet`, `dungeonResultJson` — QGEN-02 (14-02)
- [ ] `test/utils/enemy_portrait_url_test.dart`, `test/shared/components/enemy_portrait_test.dart` (mocktail `BaseCacheManager`) — QGEN-01, QGEN-02 (14-04)
- [ ] `test/repository/services/graphql/graphql_generate_quests_test.dart` — QGEN-03 (14-07-01)
- [ ] `test/screens/innkeeper/questGenerationCubit/quest_generation_cubit_test.dart` + `MockQuestGenerationCubit` in `test/helpers/mocks.dart` — QGEN-03 (14-07-03)
- [ ] `test/screens/innkeeper/components/generate_quests_button_test.dart` + `QuestGenerationCubit` provider in the panel harness — QGEN-03 (14-08)
- [ ] `test/models/enums/accessory_use_type_test.dart`, `test/models/equipment_item_test.dart` — QGEN-06 (14-09-01)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| «Genera missioni» against the real generator (count in the SnackBar, new quests on the board after reopening the tab) | QGEN-03 | needs the merged BE generator and the innkeeper account on the device | 14-HUMAN-UAT step 1 (+ step 2 for the new quests) |
| Generated enemy/boss sheets with announcement, «Nx nome» lines, slots | QGEN-01, QGEN-05 | real generated data (BE D-07/D-22) only after the BE merge | 14-HUMAN-UAT steps 2–3 |
| Dungeon stage order and «Esplorazione: tappa k di N» after a real resolution | QGEN-02, QGEN-04 | the dungeon resolver and the enrichment migration live in the BE | 14-HUMAN-UAT steps 4–5 |
| crime/guard sheet on the device | QGEN-04, QGEN-05 | fixed quests seeded by BE Phase 11 | 14-HUMAN-UAT step 6 |
| Jewels' «Uso» after the BE migration | QGEN-06 | `accessoryUseTypes` is written by a BE boot migration | 14-HUMAN-UAT step 7 |
| Real network portrait from a Cloudinary path | QGEN-01 | widget tests stay offline (A3) | 14-HUMAN-UAT step 8 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 14s (per-task subsets; the full suite runs only in 14-10)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-11-04 (planning; device rows close in 14-11)
