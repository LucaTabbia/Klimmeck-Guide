---
phase: 21
slug: innkeeper-mission-completion-flow
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-11-14
---

# Phase 21 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` + `mocktail` (+ `fake_async` where timers); helpers in `test/helpers/` |
| **Config file** | none beyond `pubspec.yaml` / `analysis_options.yaml` |
| **Quick run command** | `flutter test <touched test files>` (foreground) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, timeout ≥ 300 000 ms; baseline 4339 green) |
| **Analyzer gate** | `flutter analyze --no-fatal-infos` → 0 error / 0 warning (baseline 47 info) |
| **Schema gate** | block-anchored `awk` checks on `git -C <BE> show origin/develop:src/schema.gql` + `dump_documents.dart` / `validate_documents.js` → every document OK |
| **Estimated runtime** | targeted tests 10–60 s; full suite ≈ 4 min |

---

## Sampling Rate

- **After every task commit:** the task's `<automated>` command + the analyzer gate + the trailer check (`git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` = 0)
- **After every plan wave:** the test directories named in the plan (one plan = one wave, linear chain)
- **Before `/gsd-verify-work`:** full suite green, schema check every document OK
- **Max feedback latency:** 120 s per task

---

## Requirements → Test Map (from the research)

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| GMFLOW-01 | POI list parsed leniently; drop resolves nearest inner POI within radius else city; same place → no call; return target reopens panel + wizard | unit + bloc + widget | `flutter test test/models/travel test/screens/mainScreen/tabs/map test/screens/mainScreen/components/teleport_mode_landing_test.dart test/screens/innkeeper/innkeeper_panel_screen_test.dart` | ✅ extend; ❌ W0 `teleport_poi_layer_test.dart`, `teleport_drop_test.dart`, `teleport_destination_test.dart` |
| GMFLOW-02 | load/start/resume at served step/discard; exits on NOT_FOUND/FORBIDDEN/request gone; no submit while in flight | bloc + widget | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 |
| GMFLOW-03 | enemy list served, name search, «Mostra tutti» refetch, picks × quantity, fights add/remove, one save | bloc + widget | same dir | ❌ W0 |
| GMFLOW-04 | simulate/rerun, outcome rendering, slider from simulated HP within served bounds, injuries removable, steppers within served bounds, «Da simulare» from served null | unit + widget | same dir + `test/screens/innkeeper/components/injury_chips_test.dart` | ❌ W0 |
| GMFLOW-05 | prefilled entries, remove, add from catalogue (tabs, search), spells tab empty when served empty | bloc + widget | same dir | ❌ W0 |
| GMFLOW-06 | recap text, neutral confirm, complete → results recap, failures per code; old form deleted | unit + widget | `flutter test test/screens/innkeeper` | ✅ panel test; ❌ W0 recap |
| GMFLOW-07 | `missionInProgress` parsed; blocked line on Board; shop page closed; pawn label; drag gate; Journal rows disabled with status line; `MISSION_IN_PROGRESS` in 7 classifiers + notices | unit + widget | `flutter test test/models/character test/models/quest test/repository test/screens/mainScreen` (targeted files) | ✅ extend; ❌ W0 `equipment_failure_test.dart`, `equipment_repository_test.dart`, `mission_lines_test.dart` |
| GMFLOW-07 | `statusFields` selects `missionInProgress` (gated) | document pin | `flutter test test/graphql` | ✅ add pin |
| GMFLOW-08 | gate + N × OK + full suite | gate | gate script + schema check + full suite | ✅ |
| GMFLOW-08 | device: wizard end to end, lock and notice on the participant, release at completion and at discard, normal-mission lock | manual | `21-HUMAN-UAT.md` | ❌ (created in the last plan) |

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 21-01-01 | 01 | 1 | GMFLOW-07 | T-21-01, T-21-02 | flags modelled leniently, never selected pre-gate | unit | `flutter test test/models/character` | ✅ extend | ✅ green |
| 21-01-02 | 01 | 1 | GMFLOW-07 | T-21-03, T-21-04 | MISSION_IN_PROGRESS is a visible banner on travel/acceptance and the quest travel preview | unit | `flutter test test/utils/mission_lines_test.dart test/repository/travel_failure_test.dart test/repository/quest_acceptance_failure_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit test/screens/mainScreen/tabs/board/questTravelPreviewCubit` | ❌ W0 mission_lines_test | ✅ green |
| 21-01-03 | 01 | 1 | GMFLOW-07 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-01-SUMMARY.md && grep -q "Plan: 01 of 18" .planning/STATE.md` | — | ✅ green |
| 21-02-01 | 02 | 2 | GMFLOW-07 | T-21-06, T-21-07 | shop refusal is a banner, never the bubble | unit | `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop` | ✅ extend | ✅ green |
| 21-02-02 | 02 | 2 | GMFLOW-07 | T-21-05 | spell/companion refusal visible, not a stale reread | unit | `flutter test test/repository test/screens/mainScreen/tabs/journal` | ✅ extend | ✅ green |
| 21-02-03 | 02 | 2 | GMFLOW-07 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-02-SUMMARY.md && grep -q "Plan: 02 of 18" .planning/STATE.md` | — | ✅ green |
| 21-03-01 | 03 | 3 | GMFLOW-07 | T-21-09, T-21-10 | equipItem keeps the code; guarded repository | unit | `flutter test test/repository/equipment_failure_test.dart test/repository/equipment_repository_test.dart test/repository/services/graphql/graphql_transaction_test.dart` | ❌ W0 equipment_failure_test, equipment_repository_test | ✅ green |
| 21-03-02 | 03 | 3 | GMFLOW-07 | T-21-08 | equip refusal reaches the player as a banner (LB-1) | bloc + unit | `flutter test test/screens/mainScreen/tabs/journal test/screens/auth` | ❌ W0 journal_cubit_test, equipment_notice_test | ✅ green |
| 21-03-03 | 03 | 3 | GMFLOW-07 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-03-SUMMARY.md && grep -q "Plan: 03 of 18" .planning/STATE.md` | — | ✅ green |
| 21-04-01 | 04 | 4 | GMFLOW-07 | T-21-11 | every quest blocked from the served flag only, mission line after the existing reasons (D-23) | unit | `flutter test test/models/quest` | ✅ extend | ✅ green |
| 21-04-02 | 04 | 4 | GMFLOW-07 | T-21-12, T-21-13, T-21-14 | shop closed, drag blocked, pawn label only for the guided flow, no chrome | widget | `flutter test test/screens/mainScreen` | ✅ extend | ✅ green |
| 21-04-03 | 04 | 4 | GMFLOW-07 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-04-SUMMARY.md && grep -q "Plan: 04 of 18" .planning/STATE.md` | — | ✅ green |
| 21-05-01 | 05 | 5 | GMFLOW-07 | T-21-16 | potions locked; potion refusal visible | unit + widget | `flutter test test/repository/item_use_failure_test.dart test/screens/mainScreen/tabs/journal` | ✅ extend | ✅ green |
| 21-05-02 | 05 | 5 | GMFLOW-07 | T-21-15, T-21-17 | armour/companion/spells locked in-world, equip never sent | widget | `flutter test test/screens/mainScreen/tabs/journal` | ❌ W0 journal_mission_lock_test | ✅ green |
| 21-05-03 | 05 | 5 | GMFLOW-07 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-05-SUMMARY.md && grep -q "Plan: 05 of 18" .planning/STATE.md` | — | ✅ green |
| 21-06-01 | 06 | 6 | GMFLOW-01 | T-21-18 | unknown POI type dropped, demonicPortal kept | unit | `flutter test test/models` | ❌ W0 poi_type_test, teleport_destination_test | ✅ green |
| 21-06-02 | 06 | 6 | GMFLOW-01 | T-21-20 | document registered (47) with pins | document pin | `flutter test test/tool test/graphql` | ✅ extend | ✅ green |
| 21-06-03 | 06 | 6 | GMFLOW-01 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-06-SUMMARY.md && grep -q "Plan: 06 of 18" .planning/STATE.md` | — | ✅ green |
| 21-07-01 | 07 | 7 | GMFLOW-01 | T-21-22 | malformed POI dropped, list survives | unit | `flutter test test/repository/services/graphql/graphql_points_of_interest_test.dart test/repository/innkeeper_repository_test.dart` | ❌ W0 graphql_points_of_interest_test | ✅ green |
| 21-07-02 | 07 | 7 | GMFLOW-01 | T-21-21, T-21-23 | teleport only via the Locanda mode; player drop untouched; failed places read keeps the city teleport (D-29) | bloc + widget | `flutter test test/screens/mainScreen/tabs/map test/screens/innkeeper` | ✅ extend | ✅ green |
| 21-07-03 | 07 | 7 | GMFLOW-01 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-07-SUMMARY.md && grep -q "Plan: 07 of 18" .planning/STATE.md` | — | ✅ green |
| 21-08-01 | 08 | 8 | GMFLOW-01 | T-21-24 | default drop rule unchanged for the player | unit | `flutter test test/screens/mainScreen/tabs/map` | ❌ W0 teleport_drop_test | ✅ green |
| 21-08-02 | 08 | 8 | GMFLOW-01 | T-21-25, T-21-26 | POI layer only in teleport mode, no tap, no chrome | widget | `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/components/teleport_mode_landing_test.dart` | ❌ W0 teleport_poi_layer_test | ✅ green |
| 21-08-03 | 08 | 8 | GMFLOW-01 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-08-SUMMARY.md && grep -q "Plan: 08 of 18" .planning/STATE.md` | — | ✅ green |
| 21-09-01 | 09 | 9 | GMFLOW-01, GMFLOW-02 | T-21-28, T-21-29 | card rebuilt from the fresh snapshot, reopened once | widget | `flutter test test/screens/innkeeper test/screens/mainScreen/components` | ✅ extend | ✅ green |
| 21-09-02 | 09 | 9 | GMFLOW-02 | T-21-27, T-21-30 | draft marker modelled, not selected pre-gate | unit + widget | `flutter test test/models/pending_request test/screens/innkeeper` | ✅ extend | ✅ green |
| 21-09-03 | 09 | 9 | GMFLOW-02 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-09-SUMMARY.md && grep -q "Plan: 09 of 18" .planning/STATE.md` | — | ✅ green |
| 21-10-01 | 10 | 10 | GMFLOW-02..05 | T-21-31, T-21-33 | malformed draft entry dropped, never the draft | unit | `flutter test test/models` | ❌ W0 mission_fixtures, test/models/mission/* | ✅ green |
| 21-10-02 | 10 | 10 | GMFLOW-03..05 | T-21-32, T-21-34 | inputs rebuilt from the served draft, full corrections list with hpAfter for every participant; BE caps in one file | unit | `flutter test test/models` | ❌ W0 mission_draft_inputs_test | ✅ green |
| 21-10-03 | 10 | 10 | GMFLOW-02 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-10-SUMMARY.md && grep -q "Plan: 10 of 18" .planning/STATE.md` | — | ✅ green |
| 21-11-01 | 11 | 11 | GMFLOW-02..06 | T-21-37 | eight documents registered (55), no gated selection | document pin | `flutter test test/graphql test/tool` | ❌ W0 mission_documents_test | ✅ green |
| 21-11-02 | 11 | 11 | GMFLOW-02..06 | T-21-35, T-21-36, T-21-38 | innkeeper-only ops through _guard, no payload logs | unit | `flutter test test/repository` | ❌ W0 graphql_mission_test | ✅ green |
| 21-11-03 | 11 | 11 | GMFLOW-02 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-11-SUMMARY.md && grep -q "Plan: 11 of 18" .planning/STATE.md` | — | ✅ green |
| 21-12-01 | 12 | 12 | GMFLOW-02, GMFLOW-04..06 | T-21-40, T-21-41, T-21-42 | served draft replaces state; one call at a time | bloc | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 mission_draft_cubit_test | ⬜ pending |
| 21-12-02 | 12 | 12 | GMFLOW-03, GMFLOW-05 | T-21-39 | no client filter on enemies/prizes | bloc | `flutter test test/screens/innkeeper` | ❌ W0 three cubit tests | ⬜ pending |
| 21-12-03 | 12 | 12 | GMFLOW-02 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-12-SUMMARY.md && grep -q "Plan: 12 of 18" .planning/STATE.md` | — | ⬜ pending |
| 21-13-01 | 13 | 13 | GMFLOW-02 | T-21-43, T-21-44, T-21-45, T-21-46 | explicit start, exits on NOT_FOUND/FORBIDDEN/gone | widget | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 mission_completion_screen_test, route_test | ⬜ pending |
| 21-13-02 | 13 | 13 | GMFLOW-01 | T-21-43 | teleport prepared with resumeCardKey | widget | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 place_step_test | ⬜ pending |
| 21-13-03 | 13 | 13 | GMFLOW-02 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-13-SUMMARY.md && grep -q "Plan: 13 of 18" .planning/STATE.md` | — | ⬜ pending |
| 21-14-01 | 14 | 14 | GMFLOW-03 | T-21-50, T-21-65 | served list, lazy, no client filter; BE caps (10 fights, 10 entries, quantity 1..20) | widget | `flutter test test/screens/innkeeper/missionCompletion` | ❌ W0 encounters_step_test, enemy_picker_test | ⬜ pending |
| 21-14-02 | 14 | 14 | GMFLOW-04 | T-21-47, T-21-48, T-21-49 | served bounds, injuriesBefore locked per fight (D-14), order enforced, full corrections list | widget | `flutter test test/screens/innkeeper` | ❌ W0 fight_step_test, correction_section_test, injury_chips_test | ⬜ pending |
| 21-14-03 | 14 | 14 | GMFLOW-04 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-14-SUMMARY.md && grep -q "Plan: 14 of 18" .planning/STATE.md` | — | ⬜ pending |
| 21-15-01 | 15 | 15 | GMFLOW-05 | T-21-51, T-21-52 | served catalogue only, free non-negative coins/xp | widget | `flutter test test/screens/innkeeper` | ❌ W0 prizes_step_test, prize_catalogue_sheet_test, quantity_stepper_test | ⬜ pending |
| 21-15-02 | 15 | 15 | GMFLOW-06 | T-21-53 | explicit neutral confirmation before completing | widget | `flutter test test/screens/innkeeper` | ❌ W0 recap_step_test | ⬜ pending |
| 21-15-03 | 15 | 15 | GMFLOW-06 | — | bookkeeping only | docs | `test -f .planning/phases/21-innkeeper-mission-completion-flow/21-15-SUMMARY.md && grep -q "Plan: 15 of 18" .planning/STATE.md` | — | ⬜ pending |
| 21-16-01 | 16 | 16 | GMFLOW-07, GMFLOW-08 | T-21-55, T-21-56, T-21-57 | gate before any selection; deviation stops | gate + document pin | schema gate block + `flutter test test/graphql/character_fragment_test.dart test/graphql/pending_request_documents_test.dart` | ✅ extend | ⬜ pending |
| 21-16-02 | 16 | 16 | GMFLOW-02, GMFLOW-06 | T-21-66 | «Completa» and the resume open the wizard, innkeeper-only path | widget | `flutter test test/screens/innkeeper test/screens/mainScreen/components` | ✅ retarget | ⬜ pending |
| 21-16-03 | 16 | 16 | GMFLOW-08 | — | targeted regression + bookkeeping | docs | `flutter test test/graphql test/models test/repository test/screens/innkeeper test/screens/mainScreen test/tool` | — | ⬜ pending |
| 21-17-01 | 17 | 17 | GMFLOW-06, GMFLOW-08 | T-21-68 | registry 54 and document gone pinned RED (anchored `length, 54)`) | document pin | `flutter test test/tool test/graphql` (RED) | ✅ retarget | ⬜ pending |
| 21-17-02 | 17 | 17 | GMFLOW-06, GMFLOW-08 | T-21-59, T-21-67 | old override path deleted in groups ≤ 8 files; 54 × OK | widget + gate | `flutter test test/screens/innkeeper test/graphql test/tool test/repository test/models` + schema check | ✅ retarget | ⬜ pending |
| 21-17-03 | 17 | 17 | GMFLOW-08 | T-21-58 | full suite, hardening_check, no payload logs; VALIDATION closed | gate | full suite (alone, ≥300 s) + `bash tool/hardening_check.sh` | ✅ | ⬜ pending |
| 21-18-01 | 18 | 18 | GMFLOW-08 | T-21-60, T-21-62 | NAMES only in the UAT and BE notes | docs | gate re-check + `grep -cE "^\| [0-9]+ \|" 21-HUMAN-UAT.md` = 12 | ❌ created here | ⬜ pending |
| 21-18-02 | 18 | 18 | GMFLOW-01..08 | T-21-63 | second bearer probes expect MISSION_IN_PROGRESS | manual | `21-HUMAN-UAT.md` (human checkpoint) | — | ⬜ pending |
| 21-18-03 | 18 | 18 | GMFLOW-01..08 | T-21-61 | mark-complete only for passed requirements | docs | `grep -q "Plan: 18 of 18" .planning/STATE.md` | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/fixtures/mission_fixtures.dart` — `missionDraftJson({step, fights, …})`, `missionFightJson`, `simulatedOutcomeJson`, `missionEnemyJson`, `prizeOptionsJson`, `pointOfInterestJson` — planned: 21-10 Task 1 (`pointOfInterestJson` in `travel_fixtures.dart`, 21-06 Task 1) — delivered in 21-10
- [x] `test/models/mission/*_test.dart` — fromJson/toJson/Equatable/lenient per entry — planned: 21-10 — delivered in 21-10
- [x] `test/screens/innkeeper/missionCompletion/**` — cubits (bloc_test) and pages (widget) — planned: 21-12..21-15
- [x] `test/screens/mainScreen/tabs/map/layers/teleport_poi_layer_test.dart`, `utils/teleport_drop_test.dart` — planned: 21-08
- [x] `test/repository/equipment_failure_test.dart`, `equipment_repository_test.dart` (21-03); `test/utils/mission_lines_test.dart` (21-01)
- [x] Mocks: `MockMissionDraftCubit`/`MockMissionEnemiesCubit` in `test/helpers/mocks.dart` (pattern of existing mock cubits) — planned: 21-12, with `MockEquipmentRepository` in 21-03
- No framework install, no golden test (none exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guided flow end to end on the device, lock and notice on the players' side | GMFLOW-01..08 | Needs the Samsung device, the merged BE Phase 22 and a worldMission + a story written at DB by the orchestrator | Outline below; the orchestrator guides one step per message |

### Device E2E outline (from the research; full steps in plan 21-18)

Accounts/data: the innkeeper's own character (the streamer always has one, Phase 10 D-02) + one second account's character, both on the same worldMission (seats seeded at DB as in 10-HUMAN-UAT); a story for the innkeeper's character; a worldMission with rank blocks (FE/BE Phase 20) written at DB by the orchestrator. One device is enough if the innkeeper's own character participates: the lock and the notice are seen on the same phone after closing the Locanda; the second character's refusals are proved by the orchestrator's GraphQL probes with that bearer (`MISSION_IN_PROGRESS`).
1. «Completa» on the worldMission → «Inizia la missione» → draft created; leave the Locanda: own pawn «Missione in corso», Journal rows disabled, shop page closed, Board line; drag the pawn → nothing. Probe the second character: `startTravel`/`acceptQuest`/`doTransaction`/`equipItem`/`useItem` → `MISSION_IN_PROGRESS`.
2. Reopen the Locanda → card resumes the draft at «Luogo» → «Teletrasporta il gruppo» → drop on an inner POI → back in the wizard at the same request, pawns moved; «Resta qui» skip on a second run.
3. «Scontri»: filtered list, search, «Mostra tutti», two fights with quantities → «Avanti».
4. Fight 1 «Simula» (loader) → outcome; «Rilancia»; corrections (slider, remove an engine injury, add one, consumables/spells); fight 2 simulated from fight 1's corrected state; change fight 1's enemies → fight 1 and 2 «Da simulare».
5. Close the app, reopen from Settings → the wizard resumes at the served step (also from a second device if available).
6. «Premi»: prefilled block per character, remove one, add from catalogue (a pet; a spell only for the mage).
7. «Riepilogo» → «Completa» → confirmation → results recap; players get the result sheet with the enemies faced; lock released live.
8. Discard path on the story: start → «Scarta la bozza» → lock released live; teleport stays.
9. D-12: a normal hunt after arrival → Journal locked with «Missione in corso», released at the result.
Not observable on the device (tests only): every classifier row, lenient parsing, invalidation edge cases, stale-draft code (if N-9), two-device concurrency (optional).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120 s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
