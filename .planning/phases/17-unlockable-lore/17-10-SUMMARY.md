---
phase: 17-unlockable-lore
plan: 10
subsystem: uat
tags: [uat, device, e2e, handoff, requirements, docs]

requires:
  - phase: 17-09
    provides: "schema gate 45/45 OK on the merged BE Phase 16 (6be50d2); handoff names for the player identity and the DB tricks"
  - phase: 17-11, 17-12
    provides: "fixes from the device run (D-20..D-24) rebuilt into the APK before the player run and the step 3 re-check"
  - phase: BE 16 (lore sbloccabili)
    provides: "merged on BE develop as 6be50d2 (PR #25); player identity by environment variables of the BE process; study roll forced through LORE_STUDY_CHANCE"
provides:
  - "17-HUMAN-UAT.md: device E2E record, status complete, steps 1–7 pass and optional step 8 pass from the user's words"
  - "LORE-01, LORE-02, LORE-03 marked complete (REQUIREMENTS checkboxes, traceability row, footer)"
  - "ROADMAP Phase 17 complete 12/12 on 2026-11-09 with the LORE coverage rows Complete; STATE Plan 12 of 12 with the D-18 next steps; VALIDATION approved with every row green"
  - "BACKEND-NOTES.md (FE Phase 17 handoff): contract consumed, behaviours proved, UAT outcome, nine questions and notes for the BE"
affects: [FE Phase 16 PR, feat/17-unlockable-lore PR, FE Phase 12]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/17-unlockable-lore/17-HUMAN-UAT.md
    - .planning/phases/17-unlockable-lore/BACKEND-NOTES.md
    - .planning/phases/17-unlockable-lore/17-10-SUMMARY.md
  modified:
    - .planning/phases/17-unlockable-lore/17-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Every result comes from the user's words; step 3 is recorded as pass after the 17-12 fixes were re-verified on the device on 2026-11-09, with the original findings kept verbatim in its Note"
  - "The plan's 10/10 bookkeeping is superseded by the orchestrator's 12/12: plans 17-11 and 17-12 were inserted and executed during the UAT"
  - "The record names the identity mechanism (development auth bypass by role on the BE process) and the environment variable names only; no identity value, character id, token or URI anywhere in the phase documents"

requirements-completed: [LORE-01, LORE-02, LORE-03]

duration: ~20min of executor time in two halves (Task 1 on 2026-11-08, Task 3 on 2026-11-09); the device E2E ran between them
completed: 2026-11-09
---

# Phase 17 Plan 10: Device E2E with a player identity and the FE handoff Summary

**The unlockable-lore phase is proven on the Android phone with a player identity against BE `develop` `6be50d2`: steps 1–7 and the optional step 8 pass (birth geography only, live «Nuovo» page at the arrival, name-only sheet for an unknown city, silhouette → portrait in clear + «Nuova pagina del Bestiario: Falco», «Conoscenza appresa: Hilword Valantar» from a study, reset on recreation, silhouette kept after a defeat); LORE-01..03 are complete, ROADMAP/STATE/REQUIREMENTS/VALIDATION are closed at 12/12 and the BE has its handoff.**

## Performance

- **Duration:** Task 1 ~3 min (2026-11-08 15:46–15:49 UTC); Task 3 ~17 min (2026-11-09 09:27–09:45 UTC); the human checkpoint (Task 2) ran between them on the device, guided by the orchestrator
- **Tasks:** 3/3 (1 auto, 1 human checkpoint, 1 auto)
- **Files:** 3 created (`17-HUMAN-UAT.md`, `BACKEND-NOTES.md`, this SUMMARY), 4 modified (`17-VALIDATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`); 0 lib/test files
- **Code commits:** 0 (documentation only, as the plan prescribes)

## Task 1 — gate re-check and the UAT record (2026-11-08)

- Gate (BE repo read-only): `git -C <BE> show origin/develop:src/schema.gql | grep -c "loreUnlocked"` → `1`; `git -C <BE> log --oneline -1 origin/develop` → `6be50d2 Merge pull request #25 from LucaTabbia/feat/16-lore-sbloccabili`.
- BE Phase 16 handoff read with `git -C <BE> show origin/develop:.planning/phases/16-lore-sbloccabili/BACKEND-NOTES.md` (§3 identity, §4 DB tricks, §7 observations; ids masked in the executor's own output, nothing but names copied). The handoff names the player identity switch → no «BLOCKED» condition.
- `17-HUMAN-UAT.md` created: frontmatter (`status: in-progress`, `be_ref: 6be50d2`, `date: 2026-11-08`, empty `verdict:`), the Setup paragraph verbatim, «Player identity» (variable names only; rule «every LORE step runs as the player; the innkeeper sees everything»), «Session data» (seed field names (a)–(g) from the handoff and `17-09-SUMMARY.md`), the 8 steps verbatim in the `| Step | Requirements | Decisions | Expected | Result | Note |` table with empty Result/Note cells, the requirement ↔ step map line verbatim with the D-05/D-19 note.
- Acceptance greps: rows `^\| [1-8] \|` = 8; `status: in-progress` = 1; `be_ref:` = 1; `Non conosci ancora questa città.` = 2; `LORE-01 (1, 2, 5)` = 1; `player identity` (ci) = 5; secrets grep = 0; subject 50 bytes; trailer check 0; `git status --short` empty.
- Commit `721f70c` docs(phase-17): add the unlockable lore device UAT.

## Task 2 — human checkpoint (device E2E, 2026-11-08 → 2026-11-09)

Run by the user with the orchestrator (BE on port 3001 from `develop` `6be50d2`, player identity on the BE process, `adb reverse tcp:3000 tcp:3001`, DB seeds outside the repo). The first device run as the innkeeper got the app killed by the Android low-memory killer on «Luoghi» → plan 17-11 (D-20..D-22) inserted and executed, APK rebuilt; the player run then passed steps 1–2; step 3 raised two findings → plan 17-12 (D-23, D-24) inserted and executed, APK rebuilt, step 3 re-verified on 2026-11-09; steps 4–8 passed. The executor never ran the device, the BE or the DB.

## Task 3 — record, requirements, closure, handoff (2026-11-09)

1. `17-HUMAN-UAT.md`: `status: complete`, `completed: 2026-11-09`, one-line `verdict:`; Result/Note per step from the user's words (Italian verbatim); «Session notes» with the two device runs, the 17-11/17-12 insertions and the seeds; «Verdict» per requirement.
2. `17-VALIDATION.md`: rows `17-10-01..03` → `✅ green` (File Exists → `✅`); `**Approval:** approved 2026-11-09 (plan 17-10; every row green, device rows included)`; «Device E2E passed on 2026-11-09 (`17-HUMAN-UAT.md`, steps 1–8; …)» added after the gate line.
3. Requirements: `node gsd-tools.cjs requirements mark-complete LORE-01 LORE-02 LORE-03` → `marked_complete: [LORE-01, LORE-02, LORE-03]` (it ticked the three checkboxes only); traceability row → `| LORE-01 through LORE-03     | Phase 17 | Complete (BE Phase 16 merged; Android device E2E 2026-11-09) |` and the footer `_Last updated: 2026-11-09 — Phase 17 complete: …_` by hand.
4. `ROADMAP.md`: `- [x] 17-10-PLAN.md` (12 of 12 ticked), `- [x] **Phase 17: Unlockable Lore** — … (completed 2026-11-09)`, coverage rows `| LORE-0N | Phase 17 | Complete |`, Progress Table `| 17. Unlockable Lore | 12/12 | Complete | 2026-11-09 |`.
5. `BACKEND-NOTES.md` created: `## 1. Contract consumed by the FE`, `## 2. FE behaviours proved`, `## 3. UAT outcome (FE Phase 17, 2026-11-09)`, `## 4. Questions and notes for the BE` (A3 order, D-09 board staleness / `questUpdated`, `imagePath` of unknown enemies T-17-10, travel sheet without image, A1 two emissions, the user's content rule on study quests, board reachable only from a city, the 17-11 boot load pattern, road speed factors), closing line «Da riportare nella UAT della BE Phase 16 a cura del lato BE (questo repo non modifica il BE).».
6. `STATE.md` (python3 UTF-8): position → Phase 17 COMPLETE 2026-11-09, `Plan: 12 of 12`, `Completed phases: 15 (… 17)`, Next Phase = FE 16 PR first, then rebase `feat/17-unlockable-lore` on `develop` and its PR (D-18), then FE 12 (Hardening) last; Status and Last activity rewritten (the 17-09/17-10 parking notes removed; the strikethrough Phase 10 history line untouched); frontmatter `last_updated`, `last_activity`, `completed_phases: 15`.
7. Commit `573f671` docs(phase-17): record the unlockable lore device E2E.

## UAT verdict per step

| Step | Result | User's words |
|------|--------|--------------|
| 1 | pass | «pass» |
| 2 | pass | «partito», then «pass» |
| 3 | pass | «Vorrei il nome della città e la scritta Non conosci ancora questa città. centrate orizzontalmente rispetto al foglio. Non posso cliccare su una città in cui sono. Per il resto pass» → D-23/D-24 (17-12); re-verified 2026-11-09: «pass» |
| 4 | pass | «Ho 2 ore e 15 min di viaggio, per il resto pass» |
| 5 | pass | «Per aprire il tabellone devo tornare in città. Il resto lo confermo», then «pass» |
| 6 | pass | «pass e vai» (+ product rule «Le missioni studio dovrebbero essere tutto disponibili fin dal grado rookie», applied at DB by the orchestrator) |
| 7 | pass | «pass e creato», then «pass» |
| 8 (optional) | pass | «Accettata e pass» |

## Requirements ticked (checked by hand against the map)

- LORE-01 ← steps 1, 2, 5: all `pass` → `[x]`.
- LORE-02 ← steps 4, 5, 6: all `pass` (optional 8 `pass`) → `[x]`.
- LORE-03 ← steps 1, 3, 7: all `pass` (3 after the 17-12 fixes) → `[x]`.

## Gaps

None — no `/gsd-plan-phase 17 --gaps` needed. The findings of the run were absorbed by plans 17-11 and 17-12 (their own SUMMARYs); the study-quest content rule was applied at DB by the orchestrator (no FE or BE code).

## Deviations from Plan

### Acceptance discrepancies (noted, not fixed)

1. **12/12 instead of 10/10.** The plan's acceptance `grep -c "Plan: 10 of 10"` = 1 and 10 ticked `17-NN-PLAN.md` are superseded by the orchestrator's totals after the insertion of 17-11 and 17-12: `Plan: 12 of 12` and 12 ticked plans (REPO-RULES: the orchestrator's k/N wins).
2. **VALIDATION legend.** The executor's own stricter check `grep -c "⬜ pending"` = 1 is the legend line `*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*`, not a row (REPO-RULES «skeleton literal» trap); every Per-Task row is green.
3. **STATE frontmatter.** `completed_phases` moved 14 → 15; `total_plans`/`completed_plans`/`percent` were left as they were (their previous values were not derivable from the on-disk SUMMARY count, and the plan asked nothing about them). The gsd-tools `state`/`roadmap` commands were not used: the bookkeeping was written by hand (Edit/python3 UTF-8) as the orchestrator's brief asked.
4. **Identity record wording.** `17-HUMAN-UAT.md` names `DEV_AUTH_ROLE` with the player role word (`adventurer`) and `LORE_STUDY_CHANCE` with `1` as mechanism constants (both already in `17-09-SUMMARY.md` and the RESEARCH); `BACKEND-NOTES.md` names the mechanism only. No twitchId, access token, character id or URI anywhere (secrets greps 0 on both files).
5. **File creation.** `17-HUMAN-UAT.md`, `BACKEND-NOTES.md` and this SUMMARY were written with Bash heredocs (auto-mode rule from the user's memory) instead of the Write tool; edits to existing documents with python3 `encoding='utf-8'` and a uniqueness assertion per replacement.

### Code

None — no lib/test file touched, no test run, no `dart format`, no `flutter analyze` (last measured at 17-12: 0 error / 0 warning).

## Shared result files with the parked FE Phase 16 (CONTEXT D-18)

Not touched by this plan (documentation only).

## PR reminder (D-18 merge order)

1. The FE Phase 16 PR first (`feat/16-travel-ambushes` → `develop`, after its device UAT 16-08 from its own APK).
2. Then rebase `feat/17-unlockable-lore` on `develop` (orchestrator/user; rebase, never merge `develop` in) and open its PR from the branch with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` (never `main`), mentioning: the unlocked-lore Library with «Nuovo» bookmarks, the enemy silhouettes, the result lines, the unknown-city modal, the lazy book page and boot warm-up (17-11), the centred sheet and pawn tap (17-12), and the BE Phase 16 dependency (the branch never runs against a BE without it, D-14).
3. FE 12 (Hardening) last.

## Known Stubs

None.

## Threat Flags

None. T-17-29 (no ids/tokens/URIs/identity values; secrets greps 0 on `17-HUMAN-UAT.md` and `BACKEND-NOTES.md`), T-17-30 (`mark-complete` only after every mandatory step passed per the user's words), T-17-31 (player identity as a Setup requirement, mechanism named from the handoff) and T-17-32 (BE repo read-only `show`/`log`/`ls-tree`; BE process, identity and DB handled outside the repo) mitigated as planned.

## Self-Check: PASSED

- Files: `17-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `17-VALIDATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` exist.
- Commits: `721f70c` (Task 1) and `573f671` (Task 3) in `git log`.
