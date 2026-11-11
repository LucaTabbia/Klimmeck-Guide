---
phase: 18-heal-quests-by-size
plan: 13
subsystem: planning
tags: [uat, device, handoff, requirements]
requires: ["18-12", "BE Phase 18 (BE PR #31, 66df2ef2)"]
provides:
  - "18-HUMAN-UAT.md complete: steps 1–14 pass, optional 15 skipped, extra checks E1–E6"
  - "HEAL-01..06 complete in REQUIREMENTS.md"
  - "FE BACKEND-NOTES.md with the contract consumed, behaviours, UAT outcome and BE questions"
affects: [19]
tech-stack:
  added: []
  patterns: ["gated device E2E guided by the orchestrator, results from the user's words and the orchestrator's probe"]
key-files:
  created:
    - .planning/phases/18-heal-quests-by-size/18-HUMAN-UAT.md
    - .planning/phases/18-heal-quests-by-size/BACKEND-NOTES.md
  modified:
    - .planning/phases/18-heal-quests-by-size/18-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "User rule during the UAT: a Library book never opened marks every entry «Nuovo», also at the first opening (Phase 17 D-07 amended; fix 4ceae05 / c26de1a)"
  - "User rule during the UAT: pawn labels on one line in a smaller font (fix 36f4238 / 6d0b2c2, after a rejected two-line fix)"
  - "E5 recorded as «not explicitly confirmed by the user», not as pass"
metrics:
  duration: "UAT session 2026-11-11 (record and closing ~25 min)"
  completed: 2026-11-11
  tasks: 3
  files: 6
---

# Phase 18 Plan 13: Device E2E and closing documents Summary

The heal quests by city size are proven on the Android device with a player identity against BE `develop` `66df2ef2`. One heal per size worked: village to 50 %, city to 80 %, capital to full. The «Guarite» line appeared, the useless heal was torn and became whole again live, and a potion was drunk from the Journal with its countdown and lore. The second-potion refusal was proved by the orchestrator's probe. HEAL-01..06 are complete.

## UAT verdict per step (source)

| Step | Result | Source |
|------|--------|--------|
| 1–10 | pass | user |
| 11 | pass after the in-UAT fix («Nuovo» on a book never opened) | user |
| 12 | pass (`POTION_RECOVERING` + `recoveryUntil`, HP and inventory unchanged) | orchestrator probe |
| 13–14 | pass | user |
| 15 | skipped (optional) | — |
| E1 | pass after fix (pawn label on one line) | user |
| E2, E3, E4, E6 | pass (E6: arrest, guard won, guard lost) | user |
| E5 | not explicitly confirmed by the user; magic sheet asset finding fixed | user |
| extra | `magic` quest: spell learned with enough xp | user |

## Requirements ticked

Every mandatory step of each requirement passed, checked by hand against the map:
- HEAL-01 (1, 3, 4, 5)
- HEAL-02 (2, 3, 4)
- HEAL-03 (1–4 + the gate of 18-12)
- HEAL-04 (9, 11, 13, 14)
- HEAL-05 (8, 10, 12)
- HEAL-06 (6, 7)

All six are `[x]` and their traceability rows read `Complete`.

## Commits

- `a7c74a1` docs(phase-18): add the heal quests device UAT (Task 1)
- UAT fixes by the orchestrator: `4ceae05`, `c26de1a`, `2ba76fc`, `c7c8207`, `5a8c15b`, `5998749`, `36f4238`, `6d0b2c2`, `82df9d5`, `471546e` (listed in `18-HUMAN-UAT.md`)
- `3673f22` docs(phase-18): record the heal quests device E2E (Task 3)

## Gaps

None for the HEAL requirements. Open items, recorded in STATE and in the BE notes:
- **Auto-realignment after a network loss** (step 3): after the network came back, the app did not realign within ~40 s and was restarted. This was not reproduced in a controlled way.
- **E5 not explicitly confirmed** by the user.
- **Pre-existing 22 px overflow** of a narrative sheet in the landscape harness: not exercised in this UAT.

## Provisional visuals for the user's review

- The torn heal paper is borrowed from the generic torn announcement sheets.
- Order of the two sheet rows: «Cura le tue ferite: …» then «Vita: …».
- The potion sheet layout on `PaperSheetModal`: «Bevi <nome>?», the «Cura» and «Ricarica» lines, «Bevi» / «Non ora», and the outcome on the same sheet.

## PR reminder

The user opens the PR with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` from `feat/18-heal-quests-by-size`, never `main`. It should mention:
- the cure rows on the quest sheet
- «Guarite» on the result sheet
- the torn sheet of a useless heal
- the Journal potions with the recovery countdown and the lore line
- the prison and guard quick tasks
- the UAT fixes
- the dependency on BE Phase 18

## Deviations from Plan

1. The extra-check table E1–E6 was added on the orchestrator's instruction (quick tasks 261110-cgd / 261110-prp / 261110-shs2). It uses `E`-prefixed ids so that the 15-step grep still holds.
2. The fix hashes in the UAT record are in backticks. Without them, the all-digit hash `5998749` would match the step-row grep.
3. Code fixes were made during the UAT by the orchestrator, not by this plan. They are recorded here and in `18-HUMAN-UAT.md`.
4. The prerequisite counts differ from the BE handoff: 58 cities / 10 capitals as re-read at DB, against the handoff's 59 / 9. Both total 166.

## Self-Check: PASSED

- `18-HUMAN-UAT.md` and `BACKEND-NOTES.md` exist.
- Commits `a7c74a1` and `3673f22` are in `git log`.
- `grep -c "^- \[x\] 18-[01][0-9]-PLAN.md" ROADMAP.md` = 13.
- `Plan: 13 of 13` = 1.
- The secret greps = 0.
