---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 11
subsystem: planning
tags: [device-e2e, uat, handoff, phase-closure]
requires: ["24-10"]
provides:
  - "24-HUMAN-UAT.md (status: complete) with the ten device steps and the extra steps 0 and 11, results from the user's words, the not-run list, the changes and the decisions of the session"
  - "BACKEND-NOTES.md of the FE phase complete: contract W-1..W-13, FE behaviours, UAT outcome, questions for the BE (one still open)"
  - "STORY-01..STORY-04 and WOUND-01..WOUND-03 complete; ROADMAP Phase 24 11/11 Complete; 24-VALIDATION approved"
affects: []
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/24-participants-stories-and-innkeeper-wounds/24-HUMAN-UAT.md
  modified:
    - .planning/phases/24-participants-stories-and-innkeeper-wounds/BACKEND-NOTES.md
    - .planning/phases/24-participants-stories-and-innkeeper-wounds/24-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "UAT run on BE develop a5b140a6 (BE PR #50, story quest without a place, on top of the Phase 25 merge 95582457 read by the gate of 24-10); gate and schema check repeated on a5b140a6"
  - "Four permanent rank story quests with no place, one per rank, as DB content (user)"
  - "D-20: a heal item line lists every wound it cures, innkeeper wounds included (user, amends D-15 for the item lines)"
  - "D-21: the reader's innkeeper wounds in red in the line «Cura: …» (user); the heal quest line stays filtered; Q10 (shop line) closed"
  - "D-22: «Ferite» of the Journal as a dropdown, absent without wounds (user)"
  - "D-23: recap and additions in one dropdown per participant, header summary «aggiunta N/1000» (user)"
  - "The worldMission halves of steps 2 and 6 judged on an improvised worldMission (no worldMission content in the DB)"
metrics:
  duration: "~40 min (Task 3)"
  completed: 2026-11-22
---

# Phase 24 Plan 11: Device E2E record and phase closure Summary

The device UAT run by the orchestrator with the user on 2026-11-22 (Samsung SM-S938B, local BE from BE `develop` @ `a5b140a6`) is recorded step by step, the FE handoff for the BE is complete, STORY-01..STORY-04 and WOUND-01..WOUND-03 are complete and Phase 24 is closed (11/11). The executor ran no app, no adb, no BE and no DB script: results and the user's words come only from the orchestrator's record of the session.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | Gate re-check, the UAT script and the FE BACKEND-NOTES | a015035d |
| 2 | Device E2E (human checkpoint, run by the orchestrator with the user) | commits of the session, below |
| 3 | Record the E2E, mark the requirements, close the planning documents, complete the BE notes | (this docs commit) |

## Gates (Task 3, final tree, HEAD 639a24b8 + the closing documents)

BE repo read-only (`git show` / `git log` on `origin/develop`, no fetch).

- Gate re-check of the plan on BE `origin/develop`: `GATE_OK`

```
a5b140a6 Merge pull request #50 from LucaTabbia/fix/story-quests-without-place
```

- Schema check of the registered documents against that SDL: `dumped 55 documents`, 55 × `OK`, exit 0. `QuestInfos.markerLocation: PointOfInterest` is nullable there (BE PR #50); every document validates.
- `flutter analyze`: `47 issues found.` (the baseline).
- Full suite, once, alone in its call (`flutter test -r failures-only`; code changed during the UAT): `+5535: All tests passed!` (5495 at the end of 24-10).
- `bash tool/hardening_check.sh`: `hardening_check: OK`.
- Task 1 gate (before the session): `GATE_OK` on `95582457`.

## Verdict per step

BE under test: `a5b140a6` = BE PR #50 «fix(quests): let a story quest live without a place» (quick task 261122-snp) on top of the Phase 25 merge `95582457` (BE PR #49). One phone; identity switched by a BE restart and a hot restart of the app. Words verbatim in `24-HUMAN-UAT.md`.

| Step | Result | Notes |
|------|--------|-------|
| 0 (extra) | pass | rank story on the Board, accepted from the city with no travel: «pass su tutto» |
| 1 | pass after fix | start note moved beside the button, then «Tutto perfetto, pass» |
| 2 | pass | story part «pass»; the «no background» line judged at step 11b |
| 3 | pass | «pass su tutto»; the third hand-added wound not run |
| 4 | pass | «pass su tutto»; the over-1000 paste not run |
| 5 | pass | «pass» |
| 6 | pass | «C'è scritto completa. Pass»; the worldMission half at step 11c |
| 7 | pass | three layout retouches, then «pass su tutto» |
| 8 | pass | «pass» |
| 9 | pass after fix | behaviour passed; potion lines changed by D-20 / D-21; heal quest line «Qua è corretto» |
| 10 | pass | Board reread «confirmo» / «pass su tutto»; removal and result «pass»; D-22 born here |
| 11 (extra) | pass | two participants on an improvised worldMission; D-23 born at 11c |

## Changes made during the session (FE, test first)

| Change | Commits |
|--------|---------|
| Story quest without a place: parsing pinned, no marker without a location (BE PR #50) | 5a0c5891, fb02b89c, 525f318e |
| Start note beside «Inizia la missione», «Riprova» beside the failure line (step 1) | bb6968be, 618a3093 |
| Short centred line between background entries (step 7) | 90ca2749, 0c8ad5b2 |
| Sigil of a new background entry on the right (step 7) | c0811a6c, e72cb247 |
| Rank medal on the top right corner of the portrait (step 7) | 9fcde1ca, a7cc8517 |
| D-20 heal items list every wound they cure | 703bcb82, 586be663, 1354f2b2 (record) |
| D-21 the reader's innkeeper wounds in red in «Cura: …» | d6353fcd, adb02382, e96618a2 (record) |
| D-22 «Ferite» as a dropdown, hidden without wounds | ef74a3e7, b6e29d00, b0483a95, c2f7e31e (record) |
| D-23 recap and additions in one dropdown per participant | fc7eae17, 465dd928, 97d65962, 6aa7695b, 639a24b8 (record) |

DB content decided by the user: four permanent rank `story` quests, one per rank, with no place, prizes or enemies (they stay). Every seed of the session was restored from a backup; the result sheets of the UAT and the improvised worldMission were deleted.

## Not run on the device (covered by tests)

- Step 4: the paste of a text over 1000 characters (tests of 24-05).
- Step 3: the third wound added by hand (tests of 24-07).

Run differently from the script: the worldMission halves of steps 2 and 6 on an improvised worldMission (step 11); step 8 with one innkeeper wound; the Board reread of step 10 by an origin flip at DB with the Board open.

## Requirements ticked

`requirements mark-complete` run one id at a time; the seven boxes and the seven traceability rows checked afterwards (`[x]`, `| <ID> | Phase 24 | Complete |`), no manual fix needed: STORY-01 (steps 1, 2), STORY-02 (4, 5, 6), STORY-03 (7), STORY-04 (gate of 24-10 and steps 1–10 passed), WOUND-01 (3, 10), WOUND-02 (8, 9, 10), WOUND-03 (7, 10). Coverage line unchanged (47 / 47 mapped).

## Gaps

None blocking. Open for the BE: Q12 of `BACKEND-NOTES.md` §4 (raw / dirty `innkeeperInjuries`), not exercised on the device.

## Deviations from Plan

**1. BE ref.** The session ran on `a5b140a6` (BE PR #50 on top of the Phase 25 merge), not on `95582457` recorded by Task 1; `be_ref` updated, gate and schema check repeated on it.

**2. Two extra steps (0 and 11)** added as rows of the table; the ten rows of the plan keep their text.

**3. Step 9 changed by the user (D-20, D-21).** The potion lines no longer leave the innkeeper wound out. The text of WOUND-02 in `REQUIREMENTS.md` carries a one-clause amendment, and the scope line of §Phase 24 in the ROADMAP names D-20..D-23 (the success criterion 5 of the ROADMAP still says «potion lines of the Journal never list it»: left as written, superseded by D-20).

**4. Closing gates as asked by the orchestrator:** the full suite run once more (code changed during the UAT) and `tool/hardening_check.sh` added.

**5. `24-VALIDATION.md`:** the Wave 0 line «Cache seed of `CloudinaryAssets.arrowDown`» stays unchecked and `wave_0_complete: false` untouched (not verified by this task).

**6. STATE frontmatter `progress`** (phase and plan counters) left as found: not recomputed by this task.

## PR reminder

Next: code review of the phase, then the PRs opened by the orchestrator with the user's personal account, base `develop`: first `fix/ui-layout-review` (needs the cherry-pick of `870238bb`), then this branch stacked on it.

## Known Stubs

None.

## Self-Check: PASSED

`24-HUMAN-UAT.md` `status: complete`; `## 3. UAT outcome (FE Phase 24, 2026-11-22)` in `BACKEND-NOTES.md`; `Plan: 11 of 11` in STATE; commit a015035d and the session commits listed above exist; secrets grep on the two phase documents prints nothing.
