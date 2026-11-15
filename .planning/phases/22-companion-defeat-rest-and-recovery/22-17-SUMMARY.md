---
phase: 22-companion-defeat-rest-and-recovery
plan: 17
subsystem: planning
tags: [uat, device, companions, handoff, closing]
requires:
  - phase: 22-16
    provides: schema gate on the merged BE Phase 23 SDL, companion care switch on
provides:
  - device E2E record (22-HUMAN-UAT.md, status partial)
  - FE BACKEND-NOTES with the UAT outcome (§3) and BE questions (§4)
  - PET requirements ticked on passed steps
affects: [phase-22 PR, BE PR #43, v1.1 milestone close]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/22-companion-defeat-rest-and-recovery/22-HUMAN-UAT.md
    - .planning/phases/22-companion-defeat-rest-and-recovery/BACKEND-NOTES.md
  modified:
    - .planning/phases/22-companion-defeat-rest-and-recovery/22-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "PET-03 kept In Progress: the user passed step 8 but the unknown companion silhouette and the shop buy list long press are not seen on the device; PET-09 follows it"
  - "Gap of step 8 not blocking by the orchestrator's choice; the user decides whether to see it on the device or accept it"
  - "Phase 22 line and Progress row of the ROADMAP not marked complete (status partial); the 17 plan boxes ticked"
requirements-completed: [PET-01, PET-02, PET-04, PET-05, PET-06, PET-07, PET-08, PET-10]
duration: 15min
completed: 2026-11-15
---

# Phase 22 Plan 17: Device E2E, handoff and closing Summary

**Companion device E2E on 2026-11-15 against BE `fix/23-dungeon-xp-and-innkeeper-corrections` (PR #43, HEAD 3d2e1f1e): eight of nine steps passed outright, step 8 passed by the user with two points still to see on the device; eight PET requirements complete, PET-03 / PET-09 in progress.**

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | Gate re-check, UAT record, FE BACKEND-NOTES | 344192c4 |
| 2 | Device E2E (guided by the orchestrator, checkpoint) | — (no code; fixes in separate TDD commits, below) |
| 3 | Record the E2E, requirements, VALIDATION, BACKEND-NOTES §3, STATE / ROADMAP | 042920cc |

## Verdict per step

| Step | Requirements | Result |
|------|--------------|--------|
| 1 Defeat in a fight | PET-02, PET-06 | pass (user rule: no xp to a defeated companion → BE bf812a33) |
| 2 Rest | PET-01, PET-02 | pass |
| 3 Potion on a companion | PET-01, PET-04 | pass (probes `PET_DEFEATED`, `PET_POTION_RECOVERING`) |
| 4 Names | PET-05 | pass after two fixes (keyboard, sheet top edge); `PET_NAME_INVALID` by probe |
| 5 Ambush mid-travel with a mount | PET-06, PET-07 | pass with one correction («Prosegui a piedi» only when the travel goes on; covered by tests, not re-seen on the device) |
| 6 «In forze» push | PET-07 | pass |
| 7 Innkeeper slider | PET-08 | pass |
| 8 Details on long press | PET-03 | partial: user «Il resto lo confermo, pass»; to see on the device: unknown companion silhouette / no details, long press in the shop buy list |
| 9 Companion level up | PET-10 | pass |

## Requirements

- Complete (`requirements mark-complete`): PET-01, PET-02, PET-04, PET-05, PET-06, PET-07, PET-08, PET-10 — every mandatory step passed.
- In Progress: PET-03 (step 8, two points to see on the device); PET-09 (needs steps 1–9 all passed).

## Fixes made during the UAT (not tasks of this plan)

- 644a115c / c138fadf — pages stay still when a sheet opens the keyboard (step 4).
- 91759384 / 8e07d31b — name sheet parchment anchored to its torn top edge (step 4).
- 866a8148 / 6670a8c2 / 356fffec — no «Prosegui a piedi» when carried to a city (step 5).
- 6e3a0336, 376e8edf, 293e6371, 321d773c, e747645a, a0614862, a01e3967 — `Pet.known`: unknown companion as a black silhouette with no details (step 8, UF-01).
- BE (orchestrator, PR #43): bf812a33 companion xp only from fights left standing, 9106b66e omitted corrections = simulated, e4268b72 `Pet.known`.
- Suite after the fixes 5041 green, analyzer 47 info / 0 warning / 0 error, schema check 55 × OK.

## Gaps

- **Step 8 on the device** (open, not blocking by the orchestrator's choice, the user decides): needs an identity that has not unlocked the companion's lore (the innkeeper sees every companion as known) and the shop buy list long press (e.g. the camel at Valantar). Not a code gap: if the user wants it seen, a short device check closes PET-03 and PET-09; `/gsd-plan-phase 22 --gaps` only if that check fails.

## Copy amendments

None. Push texts and «Prosegui a piedi» not contested; only the condition of «Prosegui a piedi» changed (step 5).

## Product notes / questions

- With the `adb reverse` tunnel down the app, not reaching the BE, showed the character creation (pre-existing, to review with the user).
- `Pet.known` resolved for the streamer may draw unknown prize companions as silhouettes in the innkeeper wizard (BACKEND-NOTES §4.7).
- Operational: the magic quest «Iniziazione arcana a Valantar» was restored from the backup at the user's request.

## Deviations from Plan

- `status: partial` with Task 3 step 4: Phase 22 line and Progress row not marked complete; the Progress row reads `17/17 | In Progress (gap: step 8 on the device)`.
- `22-VALIDATION.md` approval left pending with the reason (set when the user rules on the gap).
- `be_ref` records the BE branch actually under test (PR #43 HEAD) rather than `origin/develop`, since the UAT ran on it.
- STATE frontmatter `progress` counters not recomputed (no `state update-progress`, per the executor brief).

## Next

1. The user rules on the step 8 gap.
2. Merge BE PR #43 (it carries `Pet.known`, selected by the FE).
3. FE PR from `feat/22-companion-defeat-rest-and-recovery` to `develop` (never `main`): `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop`.
4. v1.1 milestone close.

## Self-Check: PASSED

- Files exist: 22-HUMAN-UAT.md, BACKEND-NOTES.md, 22-VALIDATION.md, 22-17-SUMMARY.md.
- Commits exist: 344192c4, 042920cc.
