---
phase: 21-innkeeper-mission-completion-flow
plan: 18
subsystem: planning
tags: [uat, device-e2e, handoff, closing]
requires:
  - phase: 21-innkeeper-mission-completion-flow
    provides: "21-16 gate and wiring, 21-17 Phase 10 form retired (registry 54, full suite green)"
provides:
  - "21-HUMAN-UAT.md complete, verdict approved (steps 1–10 pass, 11 pass, 12 not run)"
  - "BACKEND-NOTES.md §3 UAT outcome and §4 merge order (BE PR #41 before the FE PR)"
  - "GMFLOW-01..08 complete; ROADMAP Phase 21 18/18 Complete 2026-11-14; VALIDATION approved"
affects: [fe-pr-21, be-pr-41, phase-22, milestone-v1.1-close]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/21-innkeeper-mission-completion-flow/21-18-SUMMARY.md
  modified:
    - .planning/phases/21-innkeeper-mission-completion-flow/21-HUMAN-UAT.md
    - .planning/phases/21-innkeeper-mission-completion-flow/BACKEND-NOTES.md
    - .planning/phases/21-innkeeper-mission-completion-flow/21-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "be_ref of the UAT record is BE branch feat/mission-start-push (PR #41, not merged), not origin/develop: the gate was not re-run on a ref that does not carry PR #41"
  - "Merge order: BE PR #41 first, then the FE PR feat/21-innkeeper-mission-completion → develop (FE selects pendingQuest.quest.infos.type and reads pointOfInterests.city, handles PushEventType.missionStart)"
  - "Step 12 (second device) not run by the user's choice; optional, does not block GMFLOW-02"
metrics:
  duration: "~3.5 h wall clock including the device UAT (Task 1 at 04087482, Task 3 + SUMMARY 2026-11-14 ~15:50–16:05 UTC)"
  completed: 2026-11-14
  tasks: 3
  files: 7
---

# Phase 21 Plan 18: Device E2E, handoff and closing Summary

Guided mission completion proved end to end on the Samsung phone against BE branch `feat/mission-start-push` (BE PR #41): start and lock with `MISSION_IN_PROGRESS` on six probed mutations, teleport onto an inner POI, two simulated and corrected fights, resume, rank-block prizes, completion with result sheets, discard and the normal-mission lock — verdict **approved**, GMFLOW-01..08 complete, Phase 21 closed at 18/18.

## Execution

- **Task 1** (previous executor): `04087482` docs(phase-21): add the guided mission device UAT and backend notes — gate `GATE_OK` on `origin/develop` `4aed73bb`.
- **Task 2** (human checkpoint, run by the orchestrator with the user): **approved**. This executor resumed from Task 3 and did not run the app, the BE or `adb`.
- **Task 3**: `b6b5c06a` docs(phase-21): record the guided mission device E2E.

## Verdict per step (source: user; DB readings by the orchestrator)

| Step | Result |
|------|--------|
| 1 Start and lock | pass — draft for 2 participants; probes `travelPreview`, `startTravel`, `acceptQuest`, `doTransaction`, `equipItem`, `useItem` → all `MISSION_IN_PROGRESS` |
| 2 Teleport on an inner POI and return | pass — after the BE fix of `pointOfInterests.city` (PR #41) and FE fixes |
| 3 Stay | pass |
| 4 Encounters | pass |
| 5 Simulation and corrections | pass — fight 2 from fight 1's corrected state (DB); «Rilancia» same numbers accepted (placeholder engine) |
| 6 Resume | pass |
| 7 Prizes | pass |
| 8 Completion | pass — two `gmCompleted` results with the 3 enemies, draft and requests gone |
| 9 Discard | pass |
| 10 Normal mission lock | pass |
| 11 (optional) zero fights | pass |
| 12 (optional) second device | not run — user: «passo 12 credo sia futile, dovremmo aver testato che alla login su un altro dispositivo, la sessione aperta su quello precedente si chiude» |

## Requirements ticked

Every id has all its mandatory steps `pass` (map in `21-HUMAN-UAT.md`): GMFLOW-01 (2, 3), GMFLOW-02 (1, 6, 9), GMFLOW-03 (4), GMFLOW-04 (5), GMFLOW-05 (7), GMFLOW-06 (8), GMFLOW-07 (1, 8, 9, 10), GMFLOW-08 (gates of 21-16/21-17 + steps 1–10). Marked with `requirements mark-complete` one id at a time; boxes `[x]` and traceability rows `Complete` verified.

## UAT fixes

Commits landed on the branch by the orchestrator during the UAT (`git log 58703276..cf8bbc07`, Task 1 excluded), RED-first:

- `f057d235` test(push): expect the mission start notification category
- `7031efb0` feat(push): add the mission start notification category
- `10aa79e0` docs(roadmap): add phase 22 companion defeat, rest and recovery
- `469a93b4` test(quests): expect an accepted story to close its sheet with a notice
- `3b93b40c` test(quests): expect the map at once and a preparing label on a tear
- `facd3507` feat(quests): leave the board at the tear and tell who waits for the inn
- `3640e2b8` test(map): expect the inn mode notices in the small map size
- `4db40ce7` fix(map): shrink the inn mode badge and instruction
- `40184aa1` fix(map): name the group in the inn mode instruction
- `ff610d2a` test(map): expect a tap on a place dot to show its types
- `4dc66f49` feat(map): show the types of a place on a tap in inn mode
- `d9d24e63` fix(map): keep the city of a place on its own line in the types label
- `154e9d0e` test(innkeeper): expect the wizard on the place step after a cancel
- `8dd82e55` fix(innkeeper): reopen the wizard on the place step after a cancel
- `3de60300` test(innkeeper): expect compact wizard buttons and the search by the step
- `66c04849` feat(innkeeper): compact the wizard buttons and move the enemy search up
- `7d2ed391` test(innkeeper): expect a curtain over the queue while the wizard resumes
- `95a5b235` fix(innkeeper): hide the queue while the panel resumes the wizard
- `d30fab6b` test(innkeeper): expect one button row at the bottom and no keyboard overflow
- `0e4a22c2` feat(innkeeper): put every wizard button on one row at the bottom
- `bf702624` test(innkeeper): expect the verdict on top and a closed section per character
- `62fbf2b3` feat(innkeeper): fold each character of a fight under its life change
- `a26d091f` test(innkeeper): expect folded prizes and a page that yields to the keyboard
- `2c4b3868` feat(innkeeper): fold the prizes per character and yield to the keyboard
- `b10e7dae` test(innkeeper): expect the completion results when the queue answers first
- `c4f08298` fix(innkeeper): let a call in flight decide the exit of the wizard
- `e090d46b` test(innkeeper): expect request cards without a teleport button
- `ddd88ec8` test(innkeeper): pin the shell teleport mode without the card button
- `2ef7097c` refactor(innkeeper): drop the teleport button from the request card
- `ebdbed98` docs(teleport): name the mission wizard as the only teleport entry
- `d5e475a0` test(quests): expect the map only once the torn sheet has left
- `e3540fc1` fix(quests): leave for the map after the torn sheet has left
- `3e4813a2` test(map): expect the pawn to name the activity of a running mission
- `ffb236b9` feat(map): name the activity of a running mission over the pawn
- `31fb9d8b` test(map): expect the pawn label 10 px over the pawn at every zoom
- `bea3a4c9` fix(map): keep the pawn label at a fixed distance from the pawn
- `0923484e` fix(map): bring the pawn label 5 px over the pawn
- `e4386c3d` test(map): expect an arrow towards a pawn that is off the screen
- `cf8bbc07` feat(map): point an arrow at the pawn when it is off the screen

## Deviations from Plan

1. **[Orchestrator override] Resumed from Task 3** — Task 2 was run by the orchestrator with the user; outcomes taken from the orchestrator's record of the user's words, nothing invented.
2. **[Orchestrator override] be_ref** — the UAT ran on BE `feat/mission-start-push` (PR #41, local tip `6dbfd9df` = `develop` `4aed73bb` + mission-start push + POI city fix + lane quest type), not on `origin/develop` as the plan assumed. Recorded honestly in `21-HUMAN-UAT.md` frontmatter and body, in `BACKEND-NOTES.md` and in VALIDATION. The gate was NOT re-run against `origin/develop` as if it were the tested BE.
3. **Schema check skipped** — validating the 54 documents would need the PR #41 SDL (a BE ref change); skipped by instruction. Registry still 54: `tool/schema_check/` unchanged since 58703276 and the four pins (`test/tool/schema_check_documents_test.dart`, `test/graphql/shop_documents_test.dart`, `travel_documents_test.dart`, `loot_fragment_test.dart`) still read `length, 54`.
4. **No full suite, no build, no analyzer run by this executor** — the orchestrator's end-of-UAT run is recorded: `+4722: All tests passed!`, analyzer 47 info / 0 warning / 0 error.
5. **[Rule 1 - stale doc] ROADMAP milestone line** said «Phase 21 not planned yet» → «Phase 21 planned and complete 2026-11-14» (same commit as Task 3).
6. **STATE frontmatter** — `state update-progress` wrote `status: completed` and 47/48 before this SUMMARY existed; corrected by hand to `status: executing` (milestone v1.1 still open with Phase 22), `completed_phases: 4`, `completed_plans: 48`, `percent: 100`.
7. **Plan's mage/paladin** → rookie/legend characters (adaptation already written by Task 1).

## Gaps and open items (no `--gaps` plan needed)

- The off-screen pawn arrow (`cf8bbc07`, added last) is not yet confirmed by the user on the device.
- Copy written by the orchestrator during the UAT, open to the user's review: «Missione accettata» / «L'oste è stato avvisato: la missione comincerà quando la avvia»; push «La missione comincia» / «L'oste ha dato inizio a «titolo»»; preference «Inizio missione»; «In preparazione…»; activity labels (Cacciando…, Esplorando…, Combattendo…, Soccorrendo…, Studiando…, In cura…, Lavorando…, Tramando…, Di guardia…).
- Copy amendments of the proposed strings («Copy to review»): none requested by the user.

## Next step / PR reminder

1. Merge BE PR #41 (`feat/mission-start-push`) FIRST — the FE branch needs `PushEventType.missionStart`, `pointOfInterests.city` and `pendingQuest.quest.infos.type`.
2. Then the FE PR `feat/21-innkeeper-mission-completion` → `develop` (opened as a draft by the orchestrator; never `main`): `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop --draft`.
3. Then Phase 22 (companion defeat, rest and recovery) or the milestone v1.1 close.

## Threat surface

No code change in this plan; T-21-60 mitigated (secrets grep = 0 on both docs), T-21-61 mitigated (mark-complete only for passed requirements).

## Self-Check: PASSED

Files found: 21-18-SUMMARY.md, 21-HUMAN-UAT.md; commits found: 04087482, b6b5c06a.
