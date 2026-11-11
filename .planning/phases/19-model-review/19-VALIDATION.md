---
phase: 19
slug: model-review
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-11-11
---

# Phase 19 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution. Source: `19-RESEARCH.md` §Validation Architecture, extended with the rulings D-13..D-19 and BE D-25 / D-26 (device steps only).

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3` |
| **Config file** | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `journal_harness.dart`, `spells_harness.dart`, `fakes/`, `fixtures/`) |
| **Quick run command** | `flutter test <touched test files>` |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, only in the gate plan 19-12, alone in its Bash call, timeout ≥ 300 000 ms) |
| **Analyzer gate** | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| **Schema gate** | name greps + block-anchored `awk` checks on `git -C <BE> show origin/develop:src/schema.gql` (plans 19-10..19-13); `dart run tool/schema_check/dump_documents.dart <dir>` + `node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK (plans 19-11, 19-12) |
| **Estimated runtime** | quick runs 5–60 s; full suite ~96 s (4031 tests before the phase) |

---

## Sampling Rate

- **After every task commit:** the touched test files + the repo-wide analyzer gate + the trailer check
- **After every plan:** the test directories named in the plan's `<verification>`
- **Pre-gate plans (19-01..19-09):** no fragment or document change; the app keeps working against the BE of today (window rule D-15)
- **Phase gate (19-12):** full suite in foreground, analyzer, format of the phase's new files one by one, trailer grep over the phase's commits, schema check 46 × OK, leftover-name grep, product-rule greps
- **Before `/gsd-verify-work`:** full suite green
- **Max feedback latency:** 60 seconds per task (quick runs)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 19-01-01 | 01 | 1 | MODEL-01, MODEL-04 | T-19-01, T-19-03 | POI type list lenient; location absent / null / first element null → null, any other malformed location strict; no quest back-link | unit | `flutter test test/models/point_of_interest_test.dart test/models/wire_lat_lng_test.dart` | ✅ (add group) | ✅ green |
| 19-01-02 | 01 | 1 | MODEL-01, MODEL-04 | T-19-02 | `Weaknesses.fromJson` never throws, unknown names dropped; enemy locations lenient | unit | `flutter test test/models test/graphql/quest_result_documents_test.dart` | ❌ W0 (`weaknesses_test.dart`, `enemy_test.dart`) | ✅ green |
| 19-02-01 | 02 | 2 | MODEL-04 | T-19-04, T-19-05 | a damage entry with an unknown / missing type is dropped, never nulled | unit | `flutter test test/models test/shared/components` | ❌ W0 (`damages_test.dart`) | ⬜ pending |
| 19-02-02 | 02 | 2 | MODEL-04 | T-19-06 | unknown spell energy → no energy damage; unknown title → null | unit | `flutter test test/models test/screens/mainScreen/tabs/journal` | ❌ W0 (`spell_test.dart`) / ✅ | ⬜ pending |
| 19-03-01 | 03 | 3 | MODEL-04 | T-19-07, T-19-08, T-19-11 | an unreadable owned / pool entry is dropped; item parsers stay strict | unit | `flutter test test/models test/screens/mainScreen/tabs/shop` | ❌ W0 (`asset_quantity_test.dart`) / ✅ | ⬜ pending |
| 19-03-02 | 03 | 3 | MODEL-04 | T-19-09 | an unreadable worn item is an empty slot | unit | `flutter test test/models test/screens/mainScreen/tabs/journal` | ❌ W0 (`equipment_test.dart`) | ⬜ pending |
| 19-03-03 | 03 | 3 | MODEL-04 | T-19-10, T-19-12 | a city of an unknown type is dropped alone; nothing logged | unit | `flutter test test/models test/repository test/screens/mainScreen/cubit` | ❌ W0 (`graphql_get_cities_test.dart`) / ✅ | ⬜ pending |
| 19-04-01 | 04 | 4 | MODEL-02 | T-19-14 | catalogue pet with attack / defense, no per-character field; no wire change | unit | `flutter test test/models test/screens/mainScreen/tabs/shop test/shared/components` | ✅ (rewrite) | ⬜ pending |
| 19-04-02 | 04 | 4 | MODEL-02 | T-19-13, T-19-15, T-19-16 | malformed owned entry dropped; one window branch; xp in the props | unit + widget | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components test/graphql/character_fragment_test.dart` | ❌ W0 (`owned_pet_test.dart`, `ownedPetJson`) / ✅ | ⬜ pending |
| 19-05-01 | 05 | 5 | MODEL-02 | T-19-17, T-19-18 | lines print served numbers, no clamp, no arithmetic | unit | `flutter test test/utils/item_lines_test.dart` | ✅ (add groups) | ⬜ pending |
| 19-05-02 | 05 | 5 | MODEL-02 | T-19-17, T-19-19 | experience as text, hidden without a maximum; life shown nowhere | widget | `flutter test test/screens/mainScreen/tabs/journal` | ✅ (add group) | ⬜ pending |
| 19-05-03 | 05 | 5 | MODEL-02 | T-19-18, T-19-20 | attack / defense hidden when empty; no overflow; copy only in the helpers | widget | `flutter test test/shared/components test/screens/mainScreen/tabs/shop test/screens/mainScreen/tabs/journal` | ✅ (add groups) | ⬜ pending |
| 19-06-01 | 06 | 6 | MODEL-02 | T-19-21, T-19-22, T-19-23 | `petXpGained` lenient → 0; no share computed | unit | `flutter test test/models/quest_result test/utils` | ✅ (add groups) | ⬜ pending |
| 19-06-02 | 06 | 6 | MODEL-02 | T-19-21 | companion line after the xp line, hidden at 0 | widget | `flutter test test/shared/components/popup test/screens/mainScreen/main_screen_quest_results_test.dart` | ✅ (add group) | ⬜ pending |
| 19-07-01 | 07 | 7 | MODEL-03 | T-19-24, T-19-26 | `active` read from the entry; malformed state dropped; non-null list | unit | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/innkeeper` | ✅ (rewrite groups) | ⬜ pending |
| 19-07-02 | 07 | 7 | MODEL-03 | T-19-25, T-19-27 | window reader pure, never throws, not wired | unit | `flutter test test/models` | ❌ W0 (`legacy_spell_states_test.dart`, deleted in 19-11) | ⬜ pending |
| 19-08-01 | 08 | 8 | MODEL-03 | T-19-28, T-19-29, T-19-30, T-19-31, T-19-32 | view and cubit on the single list; one order rule; window reader wired once; fixtures untouched | unit + cubit + widget | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/innkeeper test/graphql/character_fragment_test.dart` | ❌ W0 (`character_test.dart`) / ✅ (add group) | ⬜ pending |
| 19-09-01 | 09 | 9 | MODEL-03 | T-19-54 | test-only migration of the spell fixture funnel and its callers; no `lib` diff; pass counts recorded | unit + cubit + widget (guard) | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/innkeeper test/graphql/character_fragment_test.dart` | ✅ (fixtures rewritten) | ⬜ pending |
| 19-09-02 | 09 | 9 | MODEL-03 | T-19-33, T-19-34 | one spell list on the models; equipped-spell model deleted | unit | `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components test/screens/innkeeper test/graphql/character_fragment_test.dart` | ✅ (add cases) | ⬜ pending |
| 19-10-01 | 10 | 10 | MODEL-04 | T-19-35, T-19-36, T-19-37, T-19-39 | BE read-only; gate stops and parks; no rename | gate | name greps + block-anchored `awk` checks on `origin/develop:src/schema.gql` (`GATE_OK`) | ✅ | ⬜ pending |
| 19-10-02 | 10 | 10 | MODEL-03 | T-19-38 | `toJson` key = enum name = fragment slot, one atomic commit; request sends `feet` | unit | `flutter test test/models test/graphql test/tool test/screens/mainScreen/tabs/journal` | ❌ W0 (`equip_item_request_test.dart`) / ✅ | ⬜ pending |
| 19-10-03 | 10 | 10 | MODEL-01 | T-19-37 | `Lore.imagePath` in model, documents and readers, one atomic commit | unit + widget | `flutter test test/models test/graphql test/tool test/screens/splash test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/map` | ✅ (pins) | ⬜ pending |
| 19-11-01 | 11 | 11 | MODEL-02, MODEL-03 | T-19-40, T-19-41, T-19-43 | selections flipped after the gate; 46 × OK; nothing beyond the contract | unit + gate | `flutter test test/graphql test/tool test/models test/repository` + `dump_documents.dart` / `validate_documents.js` | ✅ (pins of RESEARCH §F11) | ⬜ pending |
| 19-11-02 | 11 | 11 | MODEL-02 | T-19-42 | a bare pet map is dropped (window branch deleted RED-first) | unit | `flutter test test/models test/graphql test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components` | ✅ | ⬜ pending |
| 19-11-03 | 11 | 11 | MODEL-03 | T-19-42 | no legacy spell translation; leftover-name grep empty | unit + grep | `flutter test test/models test/graphql test/tool test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/innkeeper` | ✅ | ⬜ pending |
| 19-12-01 | 12 | 12 | MODEL-04 | T-19-45, T-19-46, T-19-47, T-19-48 | gate, 46 × OK, leftover and product-rule greps empty | gate | gate re-check + schema check + greps (`LEFTOVER_OK`) | ✅ | ⬜ pending |
| 19-12-02 | 12 | 12 | MODEL-01..04 | T-19-49 | full suite, analyzer, format, trailers | gate | `flutter test` (full, foreground) | ✅ | ⬜ pending |
| 19-13-01 | 13 | 13 | MODEL-04 | T-19-50, T-19-52 | no ids, tokens or URIs in the record; gate re-checked | docs | `test -f .planning/phases/19-model-review/19-HUMAN-UAT.md` + row count 13 | ❌ (created by the task) | ⬜ pending |
| 19-13-02 | 13 | 13 | MODEL-01..04 | T-19-53 | seeds outside the repo; outcomes only | manual (device checkpoint) | `19-HUMAN-UAT.md` steps 1–13 | — | ⬜ pending |
| 19-13-03 | 13 | 13 | MODEL-01..04 | T-19-50, T-19-51 | requirements ticked only on passed steps | docs | `grep` checks of the task on UAT / BACKEND-NOTES / STATE | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Test files and helpers that do not exist yet; each is created in the RED step of the task that needs it (no separate Wave 0 plan: every task is TDD).

- [x] `test/models/weaknesses_test.dart`, `test/models/enemy_test.dart` — MODEL-01 (19-01)
- [ ] `test/models/damages_test.dart`, `test/models/spell_test.dart` — MODEL-04 (19-02)
- [ ] `test/models/asset_quantity_test.dart`, `test/models/equipment_test.dart`, `test/repository/services/graphql/graphql_get_cities_test.dart` — MODEL-04 (19-03)
- [ ] `test/models/owned_pet_test.dart`; `ownedPetJson` and the `maxXp` / `attack` / `defense` parameters of `petJson` in `test/helpers/fixtures/shop_fixtures.dart` — MODEL-02 (19-04)
- [ ] `petXpGained` in `questResultJson` (`test/helpers/fixtures/quest_result_fixtures.dart`) — MODEL-02 (19-06)
- [ ] `active` / `spell` parameters of `spellStateJson`; `test/models/character/legacy_spell_states_test.dart` (window, deleted in 19-11) — MODEL-03 (19-07)
- [ ] `test/models/character/character_test.dart` — MODEL-03 (19-08)
- [ ] single-list `spellbookCharacterJson` / `spellbookCharacter` in `test/helpers/fixtures/spell_fixtures.dart` and its callers — MODEL-03 (19-09)
- [ ] `test/models/request/equip_item_request_test.dart` — MODEL-03 (19-10)
- No framework install, no new mock, no harness provider needed (`pumpJournalPage` unchanged).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Pets with «Attacco» / «Difesa» in the shop and in the Journal, «Esperienza: N / maxXp» with the content written at DB | MODEL-02 | content lives at DB (BE D-25); nobody owns a pet today: bought or seeded during the UAT | `19-HUMAN-UAT.md` steps 1, 3 |
| Pet lore in the Library with «Nuovo» after the purchase | MODEL-02 | BE D-26, Phase 17 flow against the real BE (no FE code) | `19-HUMAN-UAT.md` step 2 |
| Spells of the migrated character on the single list, slots in learning order, equip / unequip confirmed without a jump | MODEL-03 | migrated data and stream timing of the real BE | `19-HUMAN-UAT.md` steps 4, 5 |
| Boots through the real `equipItem` with `feet` | MODEL-03 | real mutation and migrated equipment | `19-HUMAN-UAT.md` step 6 |
| «Il tuo compagno guadagna N PE» after a real fight and the row growing by N; no line without companion | MODEL-02 | the share and the cap are BE rules on a real fight | `19-HUMAN-UAT.md` steps 7, 8 |
| Map untouched, Library images from the migrated `imagePath`, enemies on the result sheet | MODEL-01, MODEL-04 | real data (642 POI, 438 lore with an image) | `19-HUMAN-UAT.md` steps 9, 10, 11 |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s for the per-task runs
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
