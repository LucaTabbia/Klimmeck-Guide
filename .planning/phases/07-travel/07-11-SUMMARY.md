---
phase: 07-travel
plan: 11
subsystem: testing
tags: [uat, device-e2e, schema-check, traceability, travel, backend-handoff]

# Dependency graph
requires:
  - phase: 07-travel (07-01 .. 07-10)
    provides: "activeTravel on the character, server clock, travel documents and repository, TravelCubit, route layer, parchment sheet, pawn modes"
  - phase: BE 08-travel-lifecycle-travel-01
    provides: "activeTravel, travelPreview, startTravel, serverTime, travelEnd push (BE develop, PR #11 + #12)"
provides:
  - "Schema check 32/32 against BE origin/develop 3df1b37 and the phase gates (Task 1)"
  - "07-HUMAN-UAT.md: Android device E2E 2026-10-26, steps 1-11 pass, step 12 observed (status: complete)"
  - "TRAVEL-01..04 ticked, roadmap row closed (11/11, Complete, 2026-10-26), verification passed"
  - "BACKEND-NOTES §3/§4: BE handoff §11 d outcome (d.1-d.8 all verified, no BE defect) for the BE side"
affects: [quick task gold route dash, FE PR feat/07-travel -> develop, FE Phase 9, FE Phase 10, feat/party-waiting]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Device UAT notes quote the user's verdicts verbatim; DB preparation and invalid attempts recorded separately in «Note di esecuzione»"

key-files:
  created:
    - .planning/phases/07-travel/07-HUMAN-UAT.md
    - .planning/phases/07-travel/07-11-SUMMARY.md
  modified:
    - .planning/phases/07-travel/07-VALIDATION.md
    - .planning/phases/07-travel/07-VERIFICATION.md
    - .planning/phases/07-travel/BACKEND-NOTES.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/PROJECT.md

key-decisions:
  - "Phase 7 complete: device E2E steps 1-11 pass (12 is an observation: «12: Ulby»), TRAVEL-01..04 ticked"
  - "Gold main colour for the route dash (user request in UAT step 3) is a follow-up quick task, not part of this plan"
  - "In game endTime is always startTime + duration: the 6b first attempt with only endTime shortened in the DB is an invalid test, not a FE defect"

requirements-completed: [TRAVEL-01, TRAVEL-02, TRAVEL-03, TRAVEL-04]

# Metrics
duration: 3 sessions (2026-10-24 gate and UAT opening, 2026-10-26 device UAT and recording)
completed: 2026-10-26
---

# Phase 7 Plan 11: Travel gate and device E2E Summary

**Schema check 32/32 against BE origin/develop, phase gates green, and the Android device E2E of the travel flow passed (steps 1-11, step 12 observed), closing TRAVEL-01..04 and handing the BE §11 d outcome to the BE side.**

## Performance

- **Duration:** across 2026-10-24 (Tasks 1-2) and 2026-10-26 (device UAT, Task 3)
- **Completed:** 2026-10-26
- **Tasks:** 3/3
- **Files modified:** 8 planning documents + this summary (no code)

## Accomplishments

- Task 1 (gate, 2026-10-24): BE `origin/develop` 3df1b37 exposes `type ActiveTravel` with `road: TravelPath!`; schema check 32/32 `OK`, 0 failures; `flutter test` 1644 passed (1671 after the later review fixes); `flutter analyze` 54 issues, 0 errors; new files format-clean, DIRTY files untouched, no trailers on the branch.
- Task 2 (checkpoint): `07-HUMAN-UAT.md` opened with the 12 device steps; the user ran them on a Samsung SM-S938B via USB on 2026-10-26.
- Task 3: the verdicts recorded verbatim (steps 1-11 pass, step 12 «12: Ulby»), `07-HUMAN-UAT.md` `status: complete`; `07-VALIDATION.md` approved; `07-VERIFICATION.md` `status: passed` with a «Human verification outcome (2026-10-26)» section; TRAVEL-01..04 ticked with the traceability row Complete; ROADMAP plan box, phase line, coverage rows and Progress Table closed; BACKEND-NOTES §3 (outcome d.1-d.8, C1 probe, Pitfall 10 observation) and §4 (UAT data actually used, no real-user ids or secrets); STATE position Phase 7 complete; PROJECT.md travel items moved from Active to Validated.

## Device E2E outcome (requirement mapping)

| Requirement | Steps | Result |
|-------------|-------|--------|
| TRAVEL-01 | 3, 5 | pass |
| TRAVEL-02 | 1, 2, 3, 8 | pass |
| TRAVEL-03 | 3, 4, 6, 7, 9 | pass |
| TRAVEL-04 | 5 | pass |

Steps 10 (pet) and 11 (Board/Shop off a city) pass; step 12 is the Pitfall 10 observation (the sheet named "Ulby" at low zoom). BE handoff §11 d.1-d.8 all verified, no BE defect.

## Task Commits

1. **Task 1: schema check, gates and validation sign-off** - `4d7e57e` (docs)
2. **Task 2: open the device UAT** - `9e0b08f` (docs)
3. **Task 3: record the device E2E, tick the requirements, close the roadmap row, update the BE handoff** - `af7765c` (docs)

**Plan metadata:** this summary - `docs(phase-7): add plan 07-11 summary`

## Files Created/Modified

- `.planning/phases/07-travel/07-HUMAN-UAT.md` - device E2E record, verbatim verdicts, «Note di esecuzione»
- `.planning/phases/07-travel/07-VALIDATION.md` - 07-11-02/03 green, `status: approved`, approval 2026-10-26
- `.planning/phases/07-travel/07-VERIFICATION.md` - `status: passed`, `human_verification: []` (resolved), outcome section appended
- `.planning/phases/07-travel/BACKEND-NOTES.md` - §3 outcome per §11 d step, §4 UAT data, line for BE `08-HUMAN-UAT.md`
- `.planning/REQUIREMENTS.md` - TRAVEL-01..04 ticked, traceability row Complete
- `.planning/ROADMAP.md` - 07-11 box, phase line `(completed 2026-10-26)`, coverage rows, Progress Table `11/11 | Complete | 2026-10-26`
- `.planning/STATE.md` - Phase 7 complete, next steps
- `.planning/PROJECT.md` - travel requirements moved to Validated, last-updated line

## Decisions Made

- The gold main colour for the route dash (user, UAT step 3) is deferred to a quick task on `feat/07-travel` before the PR.
- The 6b first attempt is recorded as invalid (test-data error), not as a failure.

## Deviations from Plan

### Execution deviations

**1. BE used from the Phase 9 branch instead of `origin/develop`**
- **Found during:** Task 2 (device run)
- **Issue:** the plan expects the local BE from `develop`; the run used the local BE from `feat/09-combat-result-admin-outcomes` @ c4582b9, which contains `origin/develop` 3df1b37 plus the BE Phase 9 (PR #13).
- **Impact:** none on the travel contract (schema check 32/32 against `origin/develop` in Task 1); recorded in `be_ref` of `07-HUMAN-UAT.md`, BACKEND-NOTES §3 and STATE.

**2. Step 6b redone**
- **Found during:** Task 2 (step 6, foreground arrival)
- **Issue:** the orchestrator first shortened only `endTime` in the DB; the app computes the position from `startTime` + `duration` and the remaining time from `endTime`, so the pawn stayed at the start and jumped at the banner («Ho visto 1 min. poi 0 min. …»).
- **Fix:** redone shortening `startTime` and `endTime` coherently (duration intact): «pass». In game `endTime` is always `startTime + duration`: no FE defect.

**3. Scope additions requested by the orchestrator**
- `07-VERIFICATION.md` brought to `status: passed` with an appended outcome section (frontmatter list of the 12 pending human items replaced by `human_verification: []`, as in the Phase 6 report; the body is unchanged); `PROJECT.md` travel items moved from Active to Validated.
- ROADMAP/REQUIREMENTS edited by hand (no `gsd-tools roadmap update-plan-progress` / `requirements mark-complete`), STATE via python3 UTF-8.

## Issues Encountered

None beyond the invalid 6b attempt above.

## Next Phase Readiness

- Quick task: route dash in the gold main colour.
- Then the FE PR `feat/07-travel` → `develop` (never `main`), opened with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop …`; the description should mention C1 (shared point order), C3 (rule-file amendment authorised by D-03) and D-12 (Shop rule, BE Phase 9 `SHOP_NOT_IN_CITY` pending).
- FE Phase 9/10 after the merge of the BE PR #13.
- The branch `feat/party-waiting` is stacked on `feat/07-travel`.
- The BE side copies BACKEND-NOTES §3/§4 into BE `08-HUMAN-UAT.md` (this repo never edits the BE).

## Self-Check: PASSED

- Files: 07-HUMAN-UAT.md, 07-11-SUMMARY.md present
- Commits: 4d7e57e, 9e0b08f, af7765c found
