---
phase: 24
slug: participants-stories-and-innkeeper-wounds
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-11-21
---

# Phase 24 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail (existing harness `test/helpers/`; no new Cubit in this phase, two Cubits extended) |
| **Config file** | none — no install |
| **Quick run command** | `flutter test <touched test paths>` |
| **Full suite command** | `flutter test -r expanded 2>&1 | tr '\r' '\n' | grep -E '\[E\]|All tests passed|Some tests failed'` |
| **Analyzer gate** | `OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" | tail -1; ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo "$OUT" | grep -qE '^47 issues found' && echo ANALYZE_GATE_OK` — baseline 47 info / 0 warning / 0 error, enforced: a 48th info fails the gate |
| **Schema check** | `dart run tool/schema_check/dump_documents.dart <dir>` + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema.gql> <dir>` — 55 documents (24-10) |
| **Suite baseline** | 5296 tests green on the stacked branch before the phase (5170 at the close of Phase 23, plus the layout review's tests) |
| **Estimated runtime** | ~120 seconds per targeted run; full suite only in 24-01 (baseline) and 24-10 (timeout ≥ 300000 ms) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched test paths>` and the analyzer gate
- **After every plan wave:** Run the test directories named in the plan's `<verification>`
- **Before `/gsd-verify-work`:** Full suite green and schema check 55 × OK (24-10), device E2E (24-11)
- **Max feedback latency:** 120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 24-01-01 | 01 | 1 | STORY-02, WOUND-01 | T-24-01, T-24-03 | lenient additions, step and wound lists; origin never computed; no document touched | unit | `flutter test test/models/mission test/screens/innkeeper/missionCompletion/steps` | ✅ extend | ✅ green |
| 24-01-02 | 01 | 1 | STORY-02, WOUND-01 | T-24-02, T-24-04 | `injuriesRemoved` sent only when declared (then `[]` included) or non-empty; additions section only when present; code → own line; switch off | unit | `flutter test test/models/request test/repository/innkeeper_failure_test.dart test/config test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart` | ❌ W0 (`test/config/story_and_wound_corrections_test.dart`) + ✅ extend | ✅ green |
| 24-01-03 | 01 | 1 | — | — | N/A (bookkeeping, baseline recorded) | docs | `grep -qE "Plan: 0?1 of 11" .planning/STATE.md` | — | ✅ green |
| 24-02-01 | 02 | 2 | WOUND-02, WOUND-03, STORY-03 | T-24-07, T-24-08 | lenient status and result; flag only for a served true; origin part of equality | unit | `flutter test test/models/character test/models/quest_result` | ✅ extend | ✅ green |
| 24-02-02 | 02 | 2 | WOUND-02, STORY-03 | T-24-06 | no Phase 25 field selected before the gate | document pin | `flutter test test/graphql test/tool` + grep on `lib/graphql` | ✅ extend | ✅ green |
| 24-02-03 | 02 | 2 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?2 of 11" .planning/STATE.md` | — | ✅ green |
| 24-03-01 | 03 | 3 | STORY-01 | T-24-10, T-24-11 | story as plain text, no popup, no log | widget | `flutter test test/shared/components/background_entries_test.dart test/screens/innkeeper/missionCompletion/components/participant_story_test.dart test/screens/mainScreen/tabs/profile` | ❌ W0 (two new files) | ✅ green |
| 24-03-02 | 03 | 3 | STORY-01 | T-24-13 | one read per set of ids; reread after a failure | bloc | `flutter test test/screens/innkeeper/missionCompletion/missionParticipantsCubit` | ✅ extend | ✅ green |
| 24-03-03 | 03 | 3 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?3 of 11" .planning/STATE.md` | — | ✅ green |
| 24-04-01 | 04 | 4 | STORY-01 | T-24-15 | the start never depends on the read | widget | `flutter test test/screens/innkeeper/missionCompletion/steps/stories_step_test.dart` | ❌ W0 | ✅ green |
| 24-04-02 | 04 | 4 | STORY-01 | T-24-14 | opening never creates the draft; explicit start | widget | `flutter test test/screens/innkeeper` + no `StartStep` / «di 5 ·» left | ✅ rewrite | ✅ green |
| 24-04-03 | 04 | 4 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?4 of 11" .planning/STATE.md` | — | ✅ green |
| 24-05-01 | 05 | 5 | STORY-02 | T-24-20, T-24-21 | save before completion; no completion after a refused save; saved draft kept after a refused completion | bloc | `flutter test test/screens/innkeeper/missionCompletion/missionDraftCubit` | ✅ extend | ✅ green |
| 24-05-02 | 05 | 5 | STORY-02 | T-24-18, T-24-19 | counter is UX only; grapheme clusters; no storage, no log | widget | `flutter test test/screens/innkeeper/missionCompletion/steps/additions_step_test.dart test/screens/characterCreation` | ❌ W0 | ✅ green |
| 24-05-03 | 05 | 5 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?5 of 11" .planning/STATE.md` | — | ✅ green |
| 24-06-01 | 06 | 6 | STORY-02 | T-24-23, T-24-24, T-24-25 | confirmation before every completion; one completion path; nothing new sent with the switch off | widget | `flutter test test/screens/innkeeper/missionCompletion/steps/recap_step_test.dart test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart` | ✅ rewrite | ✅ green |
| 24-06-02 | 06 | 6 | STORY-02 | T-24-26, T-24-27 | unsaved additions saved on back and leave; never trapped; landscape keyboard | widget | `flutter test test/screens/innkeeper` | ✅ extend | ✅ green |
| 24-06-03 | 06 | 6 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?6 of 11" .planning/STATE.md` | — | ✅ green |
| 24-07-01 | 07 | 7 | WOUND-01 | T-24-28, T-24-29, T-24-30 | marks only from served lists; removal only with the switch on; only carried wounds removable | widget | `flutter test test/screens/innkeeper/components/injury_chips_test.dart test/screens/innkeeper/missionCompletion/components/correction_section_test.dart` | ✅ rewrite | ✅ green |
| 24-07-02 | 07 | 7 | WOUND-01 | T-24-31 | removals sent whole and told before the completion | widget | `flutter test test/screens/innkeeper` | ✅ extend | ✅ green |
| 24-07-03 | 07 | 7 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?7 of 11" .planning/STATE.md` | — | ✅ green |
| 24-08-01 | 08 | 8 | WOUND-02 | T-24-33 | display filter only; no chrome, no loader | unit + widget | `flutter test test/screens/mainScreen/tabs/journal/journal_innkeeper_wounds_test.dart test/screens/mainScreen/characterCubit test/screens/mainScreen/tabs/board` | ❌ W0 (journal test) + ✅ extend | ⬜ pending |
| 24-08-02 | 08 | 8 | WOUND-02 | T-24-34, T-24-35 | Board reread on an origin flip, silent; shop line unchanged | unit + widget | `flutter test test/utils/item_lines_test.dart test/shared/components/item_row_test.dart test/screens/mainScreen/tabs/journal/sections test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart test/screens/mainScreen/components/quest_scope_listener_test.dart` | ✅ extend | ⬜ pending |
| 24-08-03 | 08 | 8 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?8 of 11" .planning/STATE.md` | — | ⬜ pending |
| 24-09-01 | 09 | 9 | STORY-03, WOUND-03 | T-24-37, T-24-39 | story line and healed line from served fields only | widget | `flutter test test/shared/components/popup/quest_result_sheet_test.dart` | ✅ extend | ⬜ pending |
| 24-09-02 | 09 | 9 | STORY-03 | T-24-38 | sigil proven with no new code | bloc + widget | `flutter test test/screens/mainScreen/newEntriesCubit test/screens/mainScreen/components/new_entries_listener_test.dart test/screens/mainScreen/tabs/profile` | ✅ extend | ⬜ pending |
| 24-09-03 | 09 | 9 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 0?9 of 11" .planning/STATE.md` | — | ⬜ pending |
| 24-10-01 | 10 | 10 | STORY-04, STORY-02, STORY-03, WOUND-01, WOUND-02, WOUND-03 | T-24-40, T-24-41, T-24-42, T-24-43, T-24-44 | gate before any selection and before the switch; BE read-only | gate + document pin | `schema gate block of 24-10 + flutter test test/graphql test/config` | ✅ extend | ⬜ pending |
| 24-10-02 | 10 | 10 | STORY-04 | T-24-40 | every document valid on the merged SDL | gate | `schema check 55 × OK + full suite + tool/hardening_check.sh` | ✅ | ⬜ pending |
| 24-10-03 | 10 | 10 | — | — | N/A (bookkeeping) | docs | `grep -qE "Plan: 10 of 11" .planning/STATE.md` | — | ⬜ pending |
| 24-11-01 | 11 | 11 | STORY-04 | T-24-46, T-24-49 | names only, no secrets; gate re-check on the ref under test | docs | `gate re-check of 24-11 + secrets grep = 0` | ✅ | ⬜ pending |
| 24-11-02 | 11 | 11 | STORY-01..STORY-03, WOUND-01..WOUND-03 | T-24-48 | device and DB actions by the orchestrator only | manual | `24-HUMAN-UAT.md steps 1–10` | ✅ | ⬜ pending |
| 24-11-03 | 11 | 11 | STORY-01..STORY-04, WOUND-01..WOUND-03 | T-24-47 | mark-complete only for passed steps | docs | `grep -q "^status: \(complete\|partial\)" 24-HUMAN-UAT.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

Each new test file is created RED-first by the task that needs it (no separate Wave 0 plan); the suite baseline is measured by 24-01 Task 1 before any edit:

- [x] Suite baseline measured on the stacked branch — 24-01-01
- [x] `test/config/story_and_wound_corrections_test.dart` — 24-01-02
- [x] Fixtures: `missionEffectsJson` / `missionOutcomeJson` / `missionDraftJson` with the Phase 25 keys (only when non-null), `missionBackgroundAdditionJson` — 24-01-01; result fixture with `backgroundEntryAdded` / `injuriesRemoved` — 24-02-01
- [x] `test/shared/components/background_entries_test.dart`, `test/screens/innkeeper/missionCompletion/components/participant_story_test.dart` — 24-03-01
- [x] `test/screens/innkeeper/missionCompletion/steps/stories_step_test.dart` — 24-04-01
- [x] `test/screens/innkeeper/missionCompletion/steps/additions_step_test.dart` — 24-05-02
- [ ] `test/screens/mainScreen/tabs/journal/journal_innkeeper_wounds_test.dart` — 24-08-01
- [ ] Cache seed of `CloudinaryAssets.arrowDown` in every test that mounts a `Dropdown` (24-03, 24-04, 24-05, 24-06)
- No framework install, no golden test (none exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Reading page before the start, players still free, no popup | STORY-01 | real BE lock of the participants, real stories | `24-HUMAN-UAT.md` steps 1–2 |
| Removing, keeping, adding and re-adding wounds; marks served back | WOUND-01 | BE origin rule and revalidation | steps 3, 10 |
| Recap «Avanti», last page, counter, landscape keyboard | STORY-02 | real keyboard and device size | step 4 |
| Additions found again after leaving | STORY-02 | real draft on the BE | step 5 |
| «Concludi» writes the additions with the completion | STORY-02 | BE transaction | step 6 |
| Story line, joined «Guarite» line, wax sigil on Profile and entry | STORY-03, WOUND-03 | real `characterUpdated` and result | step 7 |
| «Troppo grave per essere curata» in the Journal | WOUND-02 | real served origin, user's judgement of the mark | step 8 |
| Heal quests, potions and prizes never touch an innkeeper wound; shop line looked at | WOUND-02 | BE cure rule, `noEffect`, refusals | step 9 |
| Board whole again after an origin flip, without restart | WOUND-02 | live `characterUpdated` + reread | step 10 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 120s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (closed by 24-11)
