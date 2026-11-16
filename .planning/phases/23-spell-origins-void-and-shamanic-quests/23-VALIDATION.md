---
phase: 23
slug: spell-origins-void-and-shamanic-quests
status: draft
nyquist_compliant: false
wave_0_complete: true
created: 2026-11-15
---

# Phase 23 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail (existing harness `test/helpers/`; no new Cubit in this phase) |
| **Config file** | none — no install |
| **Quick run command** | `flutter test <touched test paths>` |
| **Full suite command** | `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'` |
| **Estimated runtime** | ~120 seconds per targeted run; full suite only in 23-07 (timeout ≥ 300000 ms; baseline 5041) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test paths>`
- **After every plan wave:** Run the test directories named in the plan's `<verification>` (the full suite runs only in the gate plan 23-07, REPO-RULES)
- **Before `/gsd-verify-work`:** Full suite green and schema check 55 × OK (23-07), device E2E (23-08)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 23-01-01 | 01 | 1 | ORIGIN-01..ORIGIN-06 | T-23-03 | requirements Pending only; no mark-complete | docs | `grep -cE '^\| ORIGIN-0[1-6] \| Phase 23 \| Pending \|$' .planning/REQUIREMENTS.md (= 6)` | ✅ | ✅ green |
| 23-01-02 | 01 | 1 | ORIGIN-03 | T-23-01, T-23-02 | unknown quest type still drops only that quest; wire names pinned | unit | `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/innkeeper` | ✅ extend | ✅ green |
| 23-01-03 | 01 | 1 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?1 of 8" .planning/STATE.md` | — | ✅ green |
| 23-02-01 | 02 | 2 | ORIGIN-01, ORIGIN-02 | T-23-06, T-23-07, T-23-08 | lenient origin and level; no level comparison; nothing selected | unit + widget | `flutter test test/models test/utils test/shared test/graphql test/screens/mainScreen/tabs/journal` | ❌ W0 + ✅ extend | ✅ green |
| 23-02-02 | 02 | 2 | ORIGIN-02 | T-23-05 | `minXpToLearn` selected nowhere; Phase 24 fields unselected | document pin | `flutter test test/graphql test/tool test/models` | ✅ extend | ✅ green |
| 23-02-03 | 02 | 2 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?2 of 8" .planning/STATE.md` | — | ✅ green |
| 23-03-01 | 03 | 3 | ORIGIN-03 | T-23-09, T-23-10 | legacy `magic` read as `arcane`, never written | unit + widget | `flutter test test/models test/utils test/screens/mainScreen/tabs/board` | ✅ extend | ✅ green |
| 23-03-02 | 03 | 3 | ORIGIN-03 | T-23-10, T-23-11 | wire `void` ↔ `theVoid`; ids only as constants | unit + widget | `flutter test test/models test/utils test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart` | ✅ extend | ✅ green |
| 23-03-03 | 03 | 3 | ORIGIN-03 | T-23-12, T-23-13 | rites torn below the rank; «Studiando…» proven RED-first | unit + widget | `flutter test test/models/quest test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart test/screens/mainScreen/tabs/board` | ✅ extend | ✅ green |
| 23-03-04 | 03 | 3 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?3 of 8" .planning/STATE.md` | — | ✅ green |
| 23-04-01 | 04 | 4 | ORIGIN-04 | T-23-14, T-23-16, T-23-17 | new city types parse; visibility only from the served size | unit + widget | `flutter test test/models test/screens/mainScreen/tabs/map` | ✅ extend | ✅ green |
| 23-04-02 | 04 | 4 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?4 of 8" .planning/STATE.md` | — | ✅ green |
| 23-05-01 | 05 | 5 | ORIGIN-04 | T-23-18, T-23-19 | replaced id pinned; eight ids audited once each | unit + audit | `flutter test test/models/enums/city_type_test.dart test/models/city_test.dart test/screens/mainScreen/tabs/map/layers/city_markers_layer_test.dart` + audit of 23-05 | ✅ extend | ✅ green |
| 23-05-02 | 05 | 5 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?5 of 8" .planning/STATE.md` | — | ✅ green |
| 23-06-01 | 06 | 6 | ORIGIN-05 | T-23-23 | icon ids only as constants | unit | `flutter test test/models/enums test/models/spell_test.dart` | ✅ extend | ✅ green |
| 23-06-02 | 06 | 6 | ORIGIN-05 | T-23-21, T-23-22, T-23-24 | no overflow at 48 px; no origin → drawn as before | widget | `flutter test test/shared test/screens/mainScreen/tabs/journal test/screens/innkeeper` | ✅ extend | ✅ green |
| 23-06-03 | 06 | 6 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?6 of 8" .planning/STATE.md` | — | ✅ green |
| 23-07-01 | 07 | 7 | ORIGIN-06, ORIGIN-01, ORIGIN-02, ORIGIN-05 | T-23-25, T-23-26, T-23-27, T-23-28, T-23-29 | gate before any selection; BE read-only | gate + document pin | `schema gate block of 23-07 + flutter test test/graphql` | ✅ extend | ✅ green |
| 23-07-02 | 07 | 7 | ORIGIN-06 | T-23-25 | every document valid on the merged SDL | gate | `schema check 55 × OK + full suite` | ✅ | ✅ green |
| 23-07-03 | 07 | 7 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?7 of 8" .planning/STATE.md` | — | ✅ green |
| 23-08-01 | 08 | 8 | ORIGIN-06 | T-23-31, T-23-33 | names only, no secrets | docs | `gate re-check of 23-08 + secrets grep = 0` | ❌ created in Task 1 | ⬜ pending |
| 23-08-02 | 08 | 8 | ORIGIN-01..ORIGIN-05 | T-23-34, T-23-35 | rank floor and origin pool seen on the device | manual | `23-HUMAN-UAT.md steps 1–8` | ❌ created in 23-08 | ⬜ pending |
| 23-08-03 | 08 | 8 | ORIGIN-01..ORIGIN-06 | T-23-32 | mark-complete only for passed steps | docs | `grep -q "^status: \(complete\|partial\)" 23-HUMAN-UAT.md` | — | ⬜ pending |
| 23-09-01 | 09 | 8 | ORIGIN-07, ORIGIN-08 | T-23-36 | requirements Pending only; no mark-complete | docs | `grep -cE '^\| ORIGIN-0[1-8] \| Phase 23 \| Pending \|$' .planning/REQUIREMENTS.md (= 8)` | ✅ | ✅ green |
| 23-09-02 | 09 | 8 | ORIGIN-02 | T-23-37 | served level printed only; no learn time | unit + widget | `flutter test test/utils/spell_lines_test.dart test/shared/components/spell_info_test.dart` | ✅ extend | ✅ green |
| 23-09-03 | 09 | 8 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?8 of 14" .planning/STATE.md` | — | ✅ green |
| 23-10-01 | 10 | 9 | ORIGIN-07 | T-23-38 | lenient learning spell and spell draw; no exception | unit | `flutter test test/models test/graphql` | ✅ extend | ⬜ pending |
| 23-10-02 | 10 | 9 | ORIGIN-08 | T-23-38, T-23-39, T-23-40 | lenient spell found and failed research; nothing selected | unit | `flutter test test/models test/graphql` | ✅ extend | ⬜ pending |
| 23-10-03 | 10 | 9 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?9 of 14" .planning/STATE.md` | — | ⬜ pending |
| 23-11-01 | 11 | 10 | ORIGIN-07 | T-23-42 | part labels from served facts only | unit + bloc | `flutter test test/utils test/models/quest test/screens/mainScreen/tabs/map` | ❌ W0 + ✅ extend | ⬜ pending |
| 23-11-02 | 11 | 10 | ORIGIN-07 | T-23-41, T-23-43 | countdown on the server clock; display only | unit + bloc | `flutter test test/utils test/models/quest test/screens/mainScreen/tabs/map` | ❌ W0 | ⬜ pending |
| 23-11-03 | 11 | 10 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 10 of 14" .planning/STATE.md` | — | ⬜ pending |
| 23-12-01 | 12 | 11 | ORIGIN-07 | — | countdown owned by the Map; no blocking loading | widget | `flutter test test/screens/mainScreen/tabs/map` | ✅ extend | ⬜ pending |
| 23-12-02 | 12 | 11 | ORIGIN-07 | — | pawn and overlay labels of the two parts | widget | `flutter test test/screens/mainScreen/tabs/map` | ✅ extend | ⬜ pending |
| 23-12-03 | 12 | 11 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 11 of 14" .planning/STATE.md` | — | ⬜ pending |
| 23-13-01 | 13 | 12 | ORIGIN-08 | — | result sheets printed from served facts | widget | `flutter test test/utils test/shared/components/popup` | ✅ extend | ⬜ pending |
| 23-13-02 | 13 | 12 | ORIGIN-08 | — | research pushes open the result like questEnd | unit | `flutter test test/models test/repository/services/push test/screens/mainScreen/components` | ✅ extend | ⬜ pending |
| 23-13-03 | 13 | 12 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 12 of 14" .planning/STATE.md` | — | ⬜ pending |
| 23-14-01 | 14 | 13 | ORIGIN-07, ORIGIN-08 | — | gate before any selection; BE read-only | gate + document pin | `schema gate block of 23-14 + flutter test test/graphql` | ✅ extend | ⬜ pending |
| 23-14-02 | 14 | 13 | ORIGIN-07, ORIGIN-08 | — | every document valid on the BE SDL | gate | `schema check 55 × OK + full suite` | ✅ | ⬜ pending |
| 23-14-03 | 14 | 13 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 13 of 14" .planning/STATE.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each new test file is created RED-first by the task that needs it (no separate Wave 0 plan):

- [x] `test/models/enums/spell_origin_test.dart` — 23-02-01 (icons added in 23-06-01)
- [x] `test/helpers/fixtures/spell_fixtures.dart` — `spellJson` loses `minXpToLearn` and gains `origin` / `minLevelToLearn` (keys only when non-null) — 23-02-01
- [x] Cache seeds of the four rite sheets in `board/sheet_test.dart`, `board/board_test.dart` and of the void sheet in `map/quest_paper_layer_test.dart` — 23-03-02
- [x] Cache seeds of the three city markers in `city_markers_layer_test.dart` — 23-04-01
- [x] Cache seeds of the three origin icons in `spell_card_test.dart`, `spell_info_test.dart`, `spell_info_sheet_test.dart` — 23-06-02
- No framework install, no golden test (none exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| City markers of Murnborim, Thengran, Veg Faldir and the new Balkuldir drawing, size and zoom | ORIGIN-04 | real Cloudinary files and served sizes | `23-HUMAN-UAT.md` step 1 |
| Origin icon first, «Origine: …», «Per impararla: Livello N · …», no «XP» | ORIGIN-01, ORIGIN-02, ORIGIN-05 | real served origin and level, real icons | step 2 |
| Shamanic rite end to end (torn below mage, sheet, «Studiando…», result, shamanic spell) | ORIGIN-03 | BE draw by origin, DB quest, rank floor | step 3 |
| Void rite end to end in Necrorian | ORIGIN-03 | BE draw by origin, DB quest, rank floor | step 4 |
| Arcane quest after the type migration, old result readable | ORIGIN-03 | BE migration of stored data | step 5 |
| Origin lore unlocked by the first spell of an origin (result sheet, Library) | ORIGIN-06 | server-side unlock via `Spell.relatedLore` | step 6 |
| Origin icon on the innkeeper prize cards and a shop item with an infused spell | ORIGIN-05 | real selections at 48 px on the device | step 7 |
| Home cities, city-tier heal and shops, new city lore (BE rules, observed) | — | BE rules and DB content | step 8 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
