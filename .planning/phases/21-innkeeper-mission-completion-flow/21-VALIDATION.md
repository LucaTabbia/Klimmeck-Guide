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
| 21-01-01 | 01 | 1 | GMFLOW-07 | T-21-01 / — | {expected secure behaviour} | unit | `{command}` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/helpers/fixtures/mission_fixtures.dart` — `missionDraftJson({step, fights, …})`, `missionFightJson`, `simulatedOutcomeJson`, `missionEnemyJson`, `prizeOptionsJson`, `pointOfInterestJson`
- [ ] `test/models/mission/*_test.dart` — fromJson/toJson/Equatable/lenient per entry
- [ ] `test/screens/innkeeper/missionCompletion/**` — cubits (bloc_test) and pages (widget)
- [ ] `test/screens/mainScreen/tabs/map/layers/teleport_poi_layer_test.dart`, `utils/teleport_drop_test.dart`
- [ ] `test/repository/equipment_failure_test.dart`, `equipment_repository_test.dart`; `test/utils/mission_lines_test.dart`
- [ ] Mocks: `MockMissionDraftCubit`/`MockMissionEnemiesCubit` in `test/helpers/mocks.dart` (pattern of existing mock cubits)
- No framework install, no golden test (none exist).

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Guided flow end to end on the device, lock and notice on the players' side | GMFLOW-01..08 | Needs the Samsung device, the merged BE Phase 22 and a worldMission + a story written at DB by the orchestrator | Outline below; the orchestrator guides one step per message |

### Device E2E outline (from the research)

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
