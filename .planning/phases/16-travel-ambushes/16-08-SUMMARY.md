---
phase: 16-travel-ambushes
plan: 08
subsystem: planning
tags: [uat, device-e2e, android, ambush, handoff, requirements, closure]

requires:
  - phase: 16-07
    provides: schema gate passed on the merged BE Phase 15 (45/45 OK on BE develop 9103440), UAT seed field names
  - phase: 16-09
    provides: D-19 carousel affordance (peeking pages + opening nudge), inserted from the step 4 finding and re-checked on the device during this plan's E2E
provides:
  - 16-HUMAN-UAT.md complete (steps 1–7 pass, 7 optional, 2026-11-09, BE develop 6be50d2) with the user's words per step
  - AMBUSH-01..03 marked complete (REQUIREMENTS checkboxes, traceability row, footer)
  - ROADMAP Phase 16 closed 9/9 (completed 2026-11-09), STATE at plan 9 of 9, VALIDATION approved 2026-11-09
  - BACKEND-NOTES.md (FE handoff for the BE): contract, push, FE behaviour, E2E outcome, questions for the BE
affects: [17-unlockable-lore, 12-hardening]

tech-stack:
  added: []
  patterns:
    - "Device E2E as a blocking human checkpoint; results recorded only from the user's words; requirements ticked only when every mandatory step passed"
    - "FE handoff per phase in BACKEND-NOTES.md (contract consumed, push, behaviour, E2E outcome, questions) — no ids, tokens or URIs"

key-files:
  created:
    - .planning/phases/16-travel-ambushes/BACKEND-NOTES.md
    - .planning/phases/16-travel-ambushes/16-08-SUMMARY.md
  modified:
    - .planning/phases/16-travel-ambushes/16-HUMAN-UAT.md
    - .planning/phases/16-travel-ambushes/16-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The plan's closure totals (Plan 08 of 8, 8 ROADMAP checkboxes) are superseded by 9 of 9: plan 16-09 (D-19) was inserted and executed during the E2E"
  - "be_ref updated to the BE develop ref the run actually used (6be50d2, BE Phases 15 and 16 merged) instead of the 9103440 the record was written against on 2026-11-07"
  - "The user's step 4 rule (the detour after a defeat is always safe) is recorded as already honoured by BE D-03 — no BE change requested, pinned in BACKEND-NOTES §5"
  - "STATE/ROADMAP bookkeeping edited by python3 (UTF-8, exact-match replacements) instead of the gsd-tools state commands, as the resume brief prescribes; requirements mark-complete run through gsd-tools as the plan prescribes"

requirements-completed: [AMBUSH-01, AMBUSH-02, AMBUSH-03]

duration: Task 1 on 2026-11-07 (gate re-check + UAT record), device E2E on 2026-11-09 with plan 16-09 in between, Task 3 ≈ 15 min on 2026-11-09
completed: 2026-11-09
---

# Phase 16 Plan 08: Device E2E, requirements and closure Summary

**The travel ambushes are proven on the Android device against BE `develop` `6be50d2` (steps 1–7 pass, step 7 optional): won ambush → silent travel and a one-page carousel at the arrival; lost ambush → `ambushDefeat` push + banner, pawn restarting from the point on the new route, quest lane freed, «Portato a» at the arrival; two reports → «1 di 2» / «2 di 2» acknowledged together; «Imboscate» off mutes only the push; confirmation sheet unchanged; GM teleport delivers the held report. AMBUSH-01..03 ticked, Phase 16 closed 9/9, handoff written.**

## Accomplishments

- **Task 1 (2026-11-07, `db9601b`):** gate re-checked (`AmbushReport` ×2 on BE `origin/develop` `9103440`), `16-HUMAN-UAT.md` created with the setup, the session data (field names only), the 7 steps verbatim and the requirement ↔ step map.
- **Task 2 (human checkpoint, 2026-11-09):** the device E2E ran with the orchestrator seeding the ambushes at DB and the user reporting each step; the user's carousel finding at step 4 became D-19 and plan 16-09, executed and re-checked on the device while the E2E closed (commits `58a33de`…`24aee99`, `16-09-SUMMARY.md`).
- **Task 3 (2026-11-09, `1b871e6`):** results and the user's words per step recorded; `status: complete`, `completed`, `be_ref: 6be50d2`, verdict; session notes; VALIDATION rows 16-08-01..03 green and approval 2026-11-09; AMBUSH-01..03 marked complete with `requirements mark-complete` plus the traceability row and the footer; ROADMAP Phase 16 `[x]` (completed 2026-11-09), `16-08-PLAN.md` ticked, «Plans: 9 plans», Progress Table `9/9 | Complete | 2026-11-09`, AMBUSH coverage rows Complete; STATE at plan 9 of 9 with the next step (FE PR, then Phase 17 rebase, FE 12 last), the FE 16 / BE 15 open question resolved; `BACKEND-NOTES.md` §1–§5 written.

## Task Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Gate re-check and the UAT record with the device steps | `db9601b` | 16-HUMAN-UAT.md |
| 2 | Device E2E on the Android phone (human checkpoint) | — (no code; 16-09 inserted from the finding) | — |
| 3 | Record the E2E, mark the requirements, close the planning documents, hand off to the BE | `1b871e6` | 16-HUMAN-UAT.md, 16-VALIDATION.md, BACKEND-NOTES.md, REQUIREMENTS.md, ROADMAP.md, STATE.md |
| — | This SUMMARY | see the `docs(phase-16): record plan 08 progress` commit | 16-08-SUMMARY.md |

## UAT verdict per step (from the user's words, `16-HUMAN-UAT.md`)

| Step | Requirements | Result | User's words |
|------|--------------|--------|--------------|
| 1 | AMBUSH-02, AMBUSH-03 | pass | «partito, foglio pass» · «pass» · «pass» |
| 2 | AMBUSH-01 | pass | «pass, ma non è possibile che continui a chiedermi di aprire il tabellone quando sono in viaggio: NON SI PUò FARE. Detto ciò, il foglio della quest che sta sulla mappa è scomparso, quindi non è più in coda» |
| 3 | AMBUSH-02 | pass | «pass» |
| 4 | AMBUSH-02 | pass | «pass, ma ciò che hai detto mi preoccupa. …» (detour-safety rule, already BE D-03) · «pass» · «pass. facciamo il test opzionale. Un feedback sul carosello: Non si campisce che sia un carosello. …» → D-19, plan 16-09; re-check «il movimento non si vede» → fix → «pass» |
| 5 | AMBUSH-01 | pass | «pass» · «pass» |
| 6 | AMBUSH-03 | pass | «partito, foglio pass» |
| 7 | AMBUSH-02 (optional) | pass | «pass» |

## Requirements ticked (mandatory steps checked by hand)

- **AMBUSH-01** — mandatory steps 2, 5: both `pass` → `[x]`.
- **AMBUSH-02** — mandatory steps 1, 3, 4: all `pass` (optional step 7 `pass` too) → `[x]`.
- **AMBUSH-03** — mandatory steps 1, 6: both `pass` → `[x]`.
- `requirements mark-complete AMBUSH-01 AMBUSH-02 AMBUSH-03` → `marked_complete` 3, `not_found` 0; checkboxes verified at lines 199–201; traceability row `Complete (BE Phase 15 merged; Android device E2E 2026-11-09)`; footer entry added.

## Gaps

None — no failing step; nothing for `/gsd-plan-phase 16 --gaps`.

Notes routed elsewhere (not gaps): the step 2 wording must never ask to open the Board during a travel (recorded in the UAT note and verdict); the detour-safety rule of the user is already BE D-03 (BACKEND-NOTES §5.5); `City.relatedLore` null on the pre-17 app is handled by FE Phase 17 D-11 (PR order 16 then 17); HP clamped at 1 on a defeat (480 → 1) and the second BE process running the sweeps are FYIs in BACKEND-NOTES §5.

## Acceptance checks run (Task 3)

- `<verify>`: `grep -q "^status: \(complete\|partial\)" 16-HUMAN-UAT.md && grep -q "AMBUSH-01 through AMBUSH-03 | Phase 16 |" REQUIREMENTS.md && grep -q "## 4. E2E outcome" BACKEND-NOTES.md` → exit 0.
- `grep -c "^status: complete" 16-HUMAN-UAT.md` → 1; rows `^\| [1-7] \|` → 7; rows still ending `| | |` → 0; `grep -c "be_ref: 6be50d2"` → 1.
- `grep -c "## 5. Questions for the BE" BACKEND-NOTES.md` → 1; `grep -c "D-16" BACKEND-NOTES.md` → 2; the plan's secret grep (Mongo URI scheme, token assignment, the word for a secret phrase; case-insensitive) → 0 on BACKEND-NOTES.md, 0 on 16-HUMAN-UAT.md and 0 on this SUMMARY.
- `grep -c "^- \[x\] 16-0[1-9]-PLAN.md" ROADMAP.md` → 9 (supersedes the plan's 8); Progress Table row `| 16. Travel Ambushes | 9/9 | Complete | 2026-11-09 |` → 1; `^| AMBUSH-0[1-3] | Phase 16 | Complete |` → 3; Phase 16 line `[x] … (completed 2026-11-09)` → 1.
- `grep -c "Plan: 9 of 9" STATE.md` → 1 (supersedes the plan's `Plan: 08 of 8`); parking mentions → 0.
- VALIDATION: `^\| 16-08-0[1-3] .*✅ green` → 3; `^\| 16-` rows with `⬜ pending` → 0; `Approval:** approved 2026-11-09` → 1.
- Commit `1b871e6`: subject 53 bytes; trailer grep (`co-authored-by|generated with|claude-session`) → 0; `git status --short` empty after it.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Closure totals 9/9 instead of the plan's 8/8**
- **Found during:** Task 3
- **Issue:** the plan's acceptance says `Plan: 08 of 8` and 8 ROADMAP checkboxes; plan 16-09 (D-19) was inserted and executed during the E2E, so the phase has 9 plans.
- **Fix:** STATE `Plan: 9 of 9`, ROADMAP 9 checkboxes ticked, Progress Table `9/9`, «**Plans**: 9 plans (…; 16-09 inserted on 2026-11-09 from the device E2E finding D-19)».
- **Files modified:** ROADMAP.md, STATE.md — **Commit:** `1b871e6`

**2. [Rule 1 - Bug] `be_ref` and the record's intro named the 2026-11-07 BE ref**
- **Found during:** Task 3
- **Issue:** `16-HUMAN-UAT.md` carried `be_ref: 9103440` (the ref the file was written against); the run happened against BE `develop` `6be50d2` (BE Phases 15 and 16 merged).
- **Fix:** `be_ref: 6be50d2`, the intro says both refs and which one the run used, the Session notes record it; VALIDATION and BACKEND-NOTES name `6be50d2` for the E2E and `9103440` for the gate.
- **Files modified:** 16-HUMAN-UAT.md, 16-VALIDATION.md, BACKEND-NOTES.md — **Commit:** `1b871e6`

**3. [Rule 2 - Missing] Session data of 2026-11-07 superseded by the 2026-11-09 run**
- **Found during:** Task 3
- **Issue:** the «Session data» section still described the legend character from Chargate; the run used a fresh rookie from Portonuovo.
- **Fix:** a one-line note at the top of the section pointing to the Session notes; the field names and BE facts kept (they were the ones used).
- **Files modified:** 16-HUMAN-UAT.md — **Commit:** `1b871e6`

### Not done on purpose

- `state advance-plan` / `update-progress` / `record-metric` / `record-session` and `roadmap update-plan-progress` were not run: the resume brief prescribes `.planning/*.md` edits via Edit or python3 only; the same fields (position, plan counter, progress frontmatter 15 phases / 151 plans / 144 done / 95 %, last activity, Progress Table row) were set by hand in the Task 3 commit. `requirements mark-complete` was run as the plan prescribes.
- No ROADMAP header «Last updated» note: the header stopped recording phase completions at Phase 10 (13–15 added none), so the pattern was kept.
- No push, no PR: the user opens the PR.

## Auth gates

None.

## PR reminder (for the user)

From `feat/16-travel-ambushes`, with the personal gh token per command (see the project git/PR memory), `gh pr create --base develop` — never `main`. Mention: the ambush result kind (`QuestResult.kind`, nullable `quest`, `ambush { … }`) and the carousel of result sheets (D-05, D-19 peeking pages + opening nudge); the defeat push category `ambushDefeat` with the «Imboscate» toggle and the Map tap; the reroute proof on `TravelProgressCubit` / `WorldMap`; the BE Phase 15 dependency (merged on BE `develop` `9103440`; the device E2E ran on `6be50d2` with BE Phase 16 merged too). Then rebase `feat/17-unlockable-lore` on `develop` and open its PR; FE 12 (Hardening) last.

## Known Stubs

None (documentation-only plan).

## Threat Flags

None. T-16-21 mitigated (secret grep 0 on both documents, no ids of real users), T-16-22 mitigated (requirements ticked only on passed mandatory steps, listed above), T-16-23 respected (no BE repo or DB access in Task 3).

## Self-Check: PASSED

- Files exist: 16-HUMAN-UAT.md, BACKEND-NOTES.md, 16-VALIDATION.md, REQUIREMENTS.md, ROADMAP.md, STATE.md.
- Commits present in `git log`: `db9601b` (Task 1), `1b871e6` (Task 3).
