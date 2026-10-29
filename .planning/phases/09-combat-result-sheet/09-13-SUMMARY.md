---
phase: 09-combat-result-sheet
plan: 13
subsystem: planning
tags: [uat, device-e2e, traceability, schema-check, closure]

# Dependency graph
requires:
  - phase: 09-12
    provides: "BE 9.2 documents (`UnacknowledgedQuestResults`, `AcknowledgeQuestResult`, `acknowledgedAt`) live in the repository ports; schema check 38/38"
provides:
  - "Phase gates against the merged BE (`8f30d1d`): full suite 2483 green, analyzer 52 / 0 errors, schema check 38/38 OK, new files format-clean, 0 trailers"
  - "`09-HUMAN-UAT.md`: Android device E2E 12/12 pass, user verdicts quoted, session notes and findings F1/F2/F3"
  - "COMBAT-01..10 ticked in REQUIREMENTS (traceability Complete); ROADMAP Phase 9 closed 13/13"
  - "`BACKEND-NOTES.md` §5 «Esito»: what the BE delivered right, F2 rule change request, FE items, UAT notes, §2.5 answers"
affects: [phase-9-pr, be-phase-10, be-9.3-companion]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schema-gated closure (pattern 08-12/08-14): BE gate → code gates → device UAT checkpoint → traceability"

key-files:
  created:
    - .planning/phases/09-combat-result-sheet/09-HUMAN-UAT.md
    - .planning/phases/09-combat-result-sheet/09-13-SUMMARY.md
  modified:
    - .planning/phases/09-combat-result-sheet/09-VALIDATION.md
    - .planning/phases/09-combat-result-sheet/BACKEND-NOTES.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/PROJECT.md
    - .planning/STATE.md

key-decisions:
  - "Banner on a busy Map is intended (user, AskUserQuestion 2026-10-29: «Sì: banner finché la Mappa non è libera»): the review-fix IN-03 rule is kept, no change"
  - "F1 (party counter / torn state of the own quest not live during the own travel) is Phase 7 party-counter behaviour, not a COMBAT gap: COMBAT-10 ticked, F1 fixed on the branch before the FE PR"
  - "F2 (fight a started quest as if the archived participant's seat were still there) routed to the BE as a rule change — BE Phase 10 or a 9.3 companion, decision pending"
  - "STATE progress set from the disk counts (100 PLAN / 100 SUMMARY), not from the stale frontmatter (88)"

patterns-established: []

requirements-completed: [COMBAT-01, COMBAT-02, COMBAT-03, COMBAT-04, COMBAT-05, COMBAT-06, COMBAT-07, COMBAT-08, COMBAT-09, COMBAT-10]

# Metrics
duration: ~1h30 (gates 09:07–09:12 local, device UAT 09:14–10:30 local, closure after)
completed: 2026-10-29
---

# Phase 9 Plan 13: Phase Gates, Device E2E and Closure Summary

**The combat result sheet is proven on the Android device against BE `develop` `8f30d1d` (Phase 9 + 9.2): 12/12 UAT steps pass, COMBAT-01..10 are ticked, the phase is closed 13/13, and the BE has the outcome plus one rule-change request (F2) in `BACKEND-NOTES.md` §5.**

## Performance

- **Completed:** 2026-10-29
- **Tasks:** 3/3 (Task 2 = blocking human checkpoint, run by the user with the orchestrator)
- **Files modified:** 8 (planning documents only; no `lib/` or `test/` change)

## Accomplishments

- **Task 1 (gates, `e930d4c`):** BE gate on `origin/develop` `8f30d1d` (the three 9.2 names present); schema check **38/38 OK**, 0 failures; full `flutter test` **2483 passed** (baseline 2139); `flutter analyze` **52 issues / 0 errors** (≤ 53); no `UNFORMATTED` file among the phase's new Dart files, DIRTY files not reformatted; `Co-Authored-By`/`Generated with` trailers on the branch: **0**; `09-VALIDATION.md` rows 9-01-01 … 9-13-01 green.
- **Task 2 (device UAT, opened at `23bfaed`):** Samsung SM S938B, USB, real Twitch login (user 1) plus a second account through the dev bypass driven by the orchestrator; 12/12 pass (details and quotes in `09-HUMAN-UAT.md`).
- **Task 3 (closure):** UAT recorded (`status: complete`), VALIDATION approved (`nyquist_compliant: true`), REQUIREMENTS / ROADMAP / PROJECT / STATE updated, BACKEND-NOTES §5 written.

## Requirement ↔ step traceability

| Requirement | Mapped steps | Result |
|-------------|--------------|--------|
| COMBAT-01 | 1, 2, 3 | pass, pass, pass |
| COMBAT-02 | 1 | pass |
| COMBAT-03 | 6 | pass |
| COMBAT-04 | 6 | pass |
| COMBAT-05 | 1, 7, 10 | pass, pass (redo), pass (inside 5A) |
| COMBAT-06 | 5 | pass |
| COMBAT-07 | 2, 5 | pass, pass (banner on a busy Map = intended, user decision) |
| COMBAT-08 | 6, 8, 9, 12 | pass, pass (on the Map), pass, pass |
| COMBAT-09 | 1, 4, 8, 9 | pass, pass, pass (on the Map), pass |
| COMBAT-10 | 6, 11 | pass, pass (F1 is Phase 7 party-counter behaviour, not a COMBAT gap) |

## Task Commits

1. **Task 1: Phase gates** — `e930d4c` (docs)
2. **Task 2: Device UAT opened** — `23bfaed` (docs)
3. **Task 3: Record the E2E and close the phase** — see the final commit `docs(phase-9): record the combat result device E2E`

## Decisions Made

- Banner on a busy Map kept as intended (user decision 2026-10-29, step 5B).
- F1 does not block COMBAT-10: the started-boss seat rule (BE 9.2) held — the counter read 2/2 before and after the deletion — while the missing live update during the own travel belongs to the Phase 7 party counter (quick task 261026-prt).
- F2 is a BE rule change, routed in BACKEND-NOTES §5.2; no FE change expected.
- Step 8 accepted on the Map tab (the death occurred during the first attempt of step 7 while the user was on the Map); the «any tab» variant stays covered by the presenter death widget tests.

## Deviations from Plan

- **Step 7 first attempt failed as a test setup** (rookie rescuer against the rescaled enemy → aid lost → death of the wounded character); that death became step 8 and step 7 was redone with roles inverted. Not a defect.
- **Step 11 checked on the Map quest sheet instead of the Board:** the Board is not reachable during an own started quest (`teleportCharacter` refused with `QUEST_IN_PROGRESS`).
- **Step 7 wounded side** («Sei stato salvato») verified in the DB only: the second account has no device.
- **STATE progress** recomputed from disk (100/100 plans) because the frontmatter counter was stale (88 with 99 SUMMARYs on disk).
- **PROJECT.md** updated (Validated item, Active item removed, Key Decision row, footer), not listed in the plan's `files_modified`, per the phase-transition rule of the document.

## Findings (gaps outside the COMBAT requirements)

- **F1 (FE, before the FE PR):** the party counter / torn state of the own quest did not update during the own automatic travel. User, 2026-10-29: «Una missione risulta al completo non appena l'ultimo avventuriero la accetta, non all'arrivo sul marker». Fixed by the orchestrator on `feat/09-combat-result-sheet` after this plan.
- **F2 (BE rule change):** user, 2026-10-29: «Il nemico dovrebbe venir combattuto come se ci fossero ancora entrambi i personaggi, non solo Reavor. Altrimenti se tutti se ne andassero da una missione con un mostro forte sarebbe sconfitta automatica per chi resta. Per quello lasciamo il posto pieno». BE Phase 10 or a 9.3 companion, decision pending.
- **F3 (FE, minor, to check):** «In attesa del gruppo» on a solo quest between the deadline and the resolution (user, 2026-10-29: «la missione mi dava come stato "in attesa del gruppo" prima del foglio risultato»).

## Issues Encountered

None in the documents; the UAT tooling (DB backdating, enemy rescaling, revives) is recorded in `09-HUMAN-UAT.md` «Session notes».

## User Setup Required

None.

## Next Phase Readiness

- Fix F1 (and check F3) on `feat/09-combat-result-sheet`, then open the FE PR with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` (never `main`; BE PR #15 already merged). Mention in the PR: the shop failure catalogue and the `doTransaction` rethrow, the `CharacterUnavailable` state, the `aid` family move, `InAppNotificationsCubit.suppress`, the reconnection bus, and the BE 9.2 dependency.
- BE side: report §5 in the BE 9.2 UAT; decide where F2 lands (BE Phase 10 or 9.3).

## Self-Check: PASSED

- FOUND: `.planning/phases/09-combat-result-sheet/09-HUMAN-UAT.md` (`status: complete`)
- FOUND: `## 5. Esito` and «a cura del lato BE» in `BACKEND-NOTES.md`
- FOUND: `nyquist_compliant: true` in `09-VALIDATION.md`
- FOUND: commits `e930d4c`, `23bfaed`
