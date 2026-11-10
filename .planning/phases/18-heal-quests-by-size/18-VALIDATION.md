---
phase: 18
slug: heal-quests-by-size
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-11-10
---

# Phase 18 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `18-RESEARCH.md` §Validation Architecture, extended with HEAL-06 (CONTEXT D-20, added during the plan and not covered by the research).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3` |
| **Config file** | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `journal_harness.dart`, `map_harness.dart`, `fakes/fake_server_clock_service.dart`, `fixtures/`) |
| **Quick run command** | `flutter test <touched test files>` |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, only in the gate plan 18-12, Bash timeout ≥ 300 000 ms) |
| **Analyzer gate** | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| **Schema gate** | `dart run tool/schema_check/dump_documents.dart <dir>` + `node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK (plan 18-12) |
| **Estimated runtime** | quick runs 5–40 s; full suite ~90 s (about 3700 tests before the phase) |

---

## Sampling Rate

- **After every task commit:** the touched test files + the repo-wide analyzer gate + the trailer check
- **After every plan:** the test directories named in the plan's `<verification>`
- **Phase gate (18-12):** full suite in foreground, analyzer, format of the phase's new files one by one, trailer grep over `develop..HEAD`, schema check 46 × OK, product-rule greps
- **Before `/gsd-verify-work`:** full suite green
- **Max feedback latency:** 60 seconds per task (quick runs)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 18-01-01 | 01 | 1 | HEAL-01 | T-18-01, T-18-03 | a malformed cure is `null` and the quest stays; share outside [0, 1] → no rows | unit | `flutter test test/models` | ❌ W0 (`quest_cure_test.dart`) / ✅ | ✅ green |
| 18-01-02 | 01 | 1 | HEAL-02 | T-18-02 | a non-list `injuriesHealed` is `[]`, the result stays | unit | `flutter test test/models test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (add group) | ✅ green |
| 18-02-01 | 02 | 2 | HEAL-05 | T-18-04, T-18-05, T-18-06 | bad date / bad recovery → `null`, never a throw; `copyWith` keeps the recovery end | unit | `flutter test test/models` | ❌ W0 (`loot_recovery_test.dart`, `potion_fixtures.dart`) / ✅ | ✅ green |
| 18-02-02 | 02 | 2 | HEAL-04 | T-18-07 | strict numbers/date in `UseItemResult`, lenient lists | unit | `flutter test test/models test/shared/components/popup/quest_result_sheet_test.dart` | ❌ W0 (`use_item_result_test.dart`) / ✅ | ✅ green |
| 18-03-01 | 03 | 3 | HEAL-01, HEAL-02 | T-18-08, T-18-09 | only the viewer's own curable injuries are listed; no rule beyond the percentage | unit | `flutter test test/utils/item_lines_test.dart` | ✅ (add groups) | ✅ green |
| 18-03-02 | 03 | 3 | HEAL-05 | T-18-08 | times only from `LootRecovery`, one humaniser, turns never shown | unit | `flutter test test/utils` | ✅ (add groups) | ✅ green |
| 18-04-01 | 04 | 4 | HEAL-01 | T-18-10, T-18-11 | rows computed in the widget, keyed by the cure, in the three families; absent without cure / match; elided article (D-21); no chrome; `lib/models` untouched | widget | `flutter test test/shared/components/popup/quest_info_sheet_test.dart test/models/quest` | ✅ (add group) | ✅ green |
| 18-04-02 | 04 | 4 | HEAL-01 | T-18-11, T-18-12 | Board and Map feed the live injuries of the current character only | widget | `flutter test test/screens/mainScreen/characterCubit/character_selectors_test.dart test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map` | ❌ W0 (`character_selectors_test.dart`) / ✅ | ✅ green |
| 18-05-01 | 05 | 5 | HEAL-02 | T-18-14 | «Guarite» between HP and injuries; consumables untouched | widget | `flutter test test/shared/components/popup` | ✅ (add group) | ⬜ pending |
| 18-05-02 | 05 | 5 | HEAL-05 | T-18-13, T-18-15 | the row decides nothing; turns never rendered | widget | `flutter test test/shared/components test/screens/mainScreen/tabs/journal` | ✅ (add groups) | ⬜ pending |
| 18-06-01 | 06 | 6 | HEAL-04 | T-18-16, T-18-21 | the mutation sends the item id only; registry 46 | unit | `flutter test test/graphql test/tool test/repository/services/graphql` | ❌ W0 (`use_item_document_test.dart`, `graphql_use_item_test.dart`) / ✅ | ⬜ pending |
| 18-06-02 | 06 | 6 | HEAL-04 | T-18-17, T-18-18, T-18-19, T-18-20 | failures from `extensions.code` only; server date only for a recovery; timeout mapped | unit | `flutter test test/repository` | ❌ W0 (`item_use_failure_test.dart`, `item_use_repository_test.dart`) / ✅ | ⬜ pending |
| 18-07-01 | 07 | 7 | HEAL-04 | T-18-22, T-18-24 | no second call while drinking; not optimistic | cubit | `flutter test test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 18-07-02 | 07 | 7 | HEAL-05 | T-18-23, T-18-25 | countdown on the server clock, display only; timer cancelled on close | cubit (`fakeAsync`) | `flutter test test/screens/mainScreen/tabs/journal/potionRecoveryCubit test/screens/mainScreen/tabs/journal/potionCubit` | ❌ W0 | ⬜ pending |
| 18-08-01 | 08 | 8 | HEAL-04 | T-18-26, T-18-27, T-18-28, T-18-29 | fixed copy by failure; remaining time from the server date; one banner per refusal | unit + widget | `flutter test test/screens/mainScreen/tabs/journal/potionCubit test/screens/mainScreen/components/potion_outcome_listener_test.dart` | ❌ W0 | ⬜ pending |
| 18-08-02 | 08 | 8 | HEAL-04 | — | N/A (provider and listener wiring) | widget | `flutter test test/screens/auth test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/main_screen_quest_results_test.dart test/screens/mainScreen/components` | ✅ (add cases) | ⬜ pending |
| 18-09-01 | 09 | 9 | HEAL-04 | T-18-30, T-18-33 | one shared lore line (D-21); the mutation starts from «Bevi» only; no spinner; no chrome | unit + widget | `flutter test test/utils/lore_lines_test.dart test/shared/components/popup test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart` | ❌ W0 | ⬜ pending |
| 18-09-02 | 09 | 9 | HEAL-04, HEAL-05 | T-18-33 | section owns and closes its countdown cubit; behaviour unchanged | widget (guard) | `flutter test test/screens/mainScreen/tabs/journal` | ✅ (untouched guards) | ⬜ pending |
| 18-09-03 | 09 | 9 | HEAL-04, HEAL-05 | T-18-31, T-18-32, T-18-34, T-18-35 | no call during the countdown; no tap while awaiting aid; state from the stream | widget | `flutter test test/screens/mainScreen/tabs/journal test/screens/mainScreen/main_screen_test.dart` | ❌ W0 (`items_section_test.dart`) / ✅ | ⬜ pending |
| 18-10-01 | 10 | 10 | HEAL-06 | T-18-36, T-18-37 | the flag is read, never computed; malformed → `false` | unit | `flutter test test/models/quest test/screens/mainScreen/tabs/board test/shared/components/popup/quest_info_sheet_test.dart` | ✅ (add groups) | ⬜ pending |
| 18-10-02 | 10 | 10 | HEAL-06 | T-18-36, T-18-38, T-18-40 | inert sheet makes no accept call; reread only in a city and only on a value change | widget | `flutter test test/screens/mainScreen/tabs/board test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` | ✅ (add groups) | ⬜ pending |
| 18-11-01 | 11 | 11 | HEAL-06 | T-18-39, T-18-50 | refusal explained with the fixed copy chosen by the code, list reread once | unit + widget | `flutter test test/repository test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/components test/screens/mainScreen/tabs/board` | ✅ (add cases) | ⬜ pending |
| 18-12-01 | 12 | 12 | HEAL-03 | T-18-41, T-18-42, T-18-43, T-18-45 | BE read-only; gate stops and parks; no rename | gate | the seven `grep -cF` on `origin/develop:src/schema.gql` (`GATE_OK`) | ✅ | ⬜ pending |
| 18-12-02 | 12 | 12 | HEAL-01, HEAL-02, HEAL-04, HEAL-05, HEAL-06 | T-18-43 | 46/46 documents valid on the merged schema | unit + gate | `flutter test test/graphql test/tool test/models test/repository` + `dump_documents.dart` / `validate_documents.js` | ✅ (pins of RESEARCH §F13) | ⬜ pending |
| 18-12-03 | 12 | 12 | HEAL-03 | T-18-44 | product-rule greps empty; full suite, analyzer, format, trailers | gate | `flutter test` (full, foreground) | ✅ | ⬜ pending |
| 18-13-01 | 13 | 13 | HEAL-03 | T-18-46 | no ids, tokens or URIs in the record | docs | `test -f .planning/phases/18-heal-quests-by-size/18-HUMAN-UAT.md` + row count 15 | ❌ (created by the task) | ⬜ pending |
| 18-13-02 | 13 | 13 | HEAL-01..06 | T-18-48 | probe outside the repo; outcomes only | manual (device checkpoint) | `18-HUMAN-UAT.md` steps 1–15 | — | ⬜ pending |
| 18-13-03 | 13 | 13 | HEAL-01..06 | T-18-46, T-18-47 | requirements ticked only on passed steps | docs | `grep` checks of the task on UAT / BACKEND-NOTES / STATE | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Test files and helpers that do not exist yet; each is created in the RED step of the task that needs it (no separate Wave 0 plan: every task is TDD).

- [ ] `test/models/quest/quest_cure_test.dart` — HEAL-01 (18-01)
- [ ] `test/models/loot_recovery_test.dart`, `test/models/use_item_result_test.dart` — HEAL-05, HEAL-04 (18-02)
- [ ] `test/helpers/fixtures/potion_fixtures.dart` (`lootRecoveryJson`, `healPotionJson`, `ownedHealPotionJson`, `useItemResultJson`); `questCureJson` in `quest_fixtures.dart`; `injuriesHealed` + `healResultJson` in `quest_result_fixtures.dart` (18-01, 18-02)
- [ ] `test/screens/mainScreen/characterCubit/character_selectors_test.dart` — HEAL-01 (18-04)
- [ ] `test/graphql/use_item_document_test.dart`, `test/repository/services/graphql/graphql_use_item_test.dart`, `test/repository/item_use_failure_test.dart`, `test/repository/item_use_repository_test.dart` — HEAL-04 (18-06)
- [ ] `test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart`, `test/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit_test.dart` — HEAL-04, HEAL-05 (18-07)
- [ ] `test/screens/mainScreen/tabs/journal/potionCubit/potion_notice_test.dart`, `test/screens/mainScreen/components/potion_outcome_listener_test.dart` — HEAL-04 (18-08)
- [ ] `test/utils/lore_lines_test.dart` — HEAL-04, D-21 (18-09)
- [ ] `test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart`, `test/screens/mainScreen/tabs/journal/sections/items_section_test.dart` — HEAL-04, HEAL-05 (18-09)
- [ ] Mocks in `test/helpers/mocks.dart`: `MockItemUseRepository` (18-06), `MockPotionCubit` (18-07); `idlePotionCubit`, the new `journalCharacter` parameters and the potion provider in `test/helpers/journal_harness.dart` (18-09)
- [ ] Fixture parameters for HEAL-06: `noEffect` on `questJson` / `buildQuest`, `currentLifePoints` / `maxLifePoints` / `injuries` on `characterWithLanesJson` (18-10)
- No framework install needed; `FakeServerClockService` already covers the clock.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real cure by city size (village 50 %, city 80 %, capital full), «Guarite» line with real content | HEAL-01, HEAL-02, HEAL-03 | content lives at DB and the cure is applied by the BE | `18-HUMAN-UAT.md` steps 1–5 |
| Torn sheet of a useless heal and its return after a seeded injury or HP loss | HEAL-06 | the per-viewer flag is computed by the BE on the real character; the torn paper is a provisional visual to review | `18-HUMAN-UAT.md` steps 6–7 |
| «Ricarica» rows with the real times, HP animation and banner timing on the phone | HEAL-04, HEAL-05 | BE timing and content; visuals are provisional and device-reviewed | `18-HUMAN-UAT.md` steps 8, 9, 13, 14 |
| Countdown across app background/foreground (clock resync) | HEAL-05 | real clock and lifecycle | `18-HUMAN-UAT.md` step 10 |
| Lore «Il limite del corpo» arriving in the Library with «Nuovo» | HEAL-04 | Phase 17 flow against the real BE | `18-HUMAN-UAT.md` step 11 |
| `POTION_RECOVERING` with `extensions.recoveryUntil` from the real BE | HEAL-05 | not reachable from the disabled parchment (D-19): orchestrator's GraphQL probe | `18-HUMAN-UAT.md` step 12 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for the per-task runs
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
