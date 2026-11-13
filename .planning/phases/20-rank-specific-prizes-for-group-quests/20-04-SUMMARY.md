---
phase: 20-rank-specific-prizes-for-group-quests
plan: 04
subsystem: planning / device UAT
tags: [uat, device-e2e, rank-prizes, dungeon-turns, closing]
requires:
  - 20-03 (schema gate, turn fields selected)
  - BE Phase 21 merged on BE develop (7f3506ac) and BE quick 261113-aql merged (697d40a1, PR #37)
provides:
  - 20-HUMAN-UAT.md (device E2E record, status complete)
  - BACKEND-NOTES.md §3 (UAT outcome for the BE)
  - VALIDATION approved, RANKP-01..04 complete, ROADMAP Phase 20 4/4 Complete
affects:
  - .planning/REQUIREMENTS.md, .planning/ROADMAP.md, .planning/STATE.md
  - .planning/quick/261113-aql-aid-locks-source-quest/261113-aql-SUMMARY.md
tech-stack:
  added: []
  patterns: [orchestrator-guided device UAT, verbatim user quotes, sanctioned step remap]
key-files:
  created:
    - .planning/phases/20-rank-specific-prizes-for-group-quests/20-HUMAN-UAT.md
    - .planning/phases/20-rank-specific-prizes-for-group-quests/20-04-SUMMARY.md
  modified:
    - .planning/phases/20-rank-specific-prizes-for-group-quests/BACKEND-NOTES.md
    - .planning/phases/20-rank-specific-prizes-for-group-quests/20-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
    - .planning/quick/261113-aql-aid-locks-source-quest/261113-aql-SUMMARY.md
decisions:
  - "The UAT record keeps the orchestrator's executed numbering (1–12) and maps each row to the plan's steps P1–P13 (sanctioned deviation: no 13-row count)"
  - "RANKP-01..04 complete by the orchestrator's closing ruling: P3 (Map) not executed and P8 (result without turns) not observed on the device, both covered by the tests of 20-01 / 20-02"
  - "STATE frontmatter status `phase-complete` (the value used for earlier completed phases); milestone v1.1 stays open (Phase 21 not planned)"
metrics:
  duration: ~25 min (executor; the device session itself was run earlier by the orchestrator)
  completed: 2026-11-13
  tasks: 3 (Task 2 checkpoint consumed by the orchestrator)
  files: 8
---

# Phase 20 Plan 04: Device E2E and phase closing Summary

Device E2E of the rank-specific prizes recorded from the orchestrator-guided session (12 executed steps, all pass, three FE fixes and the quick task 261113-aql born during the UAT), the gate re-run on the merged BE `697d40a1` (46 × OK, full suite 4339 green), RANKP-01..04 complete and every planning document of Phase 20 closed.

## Gate (Task 1, before writing)

- Block-anchored schema gate on BE `origin/develop:src/schema.gql` (`697d40a1`, refs not fetched): every check of `20-REPO-RULES.md` plus `Quest.awaitingRescue: Boolean!` → `GATE_OK`.
- Schema check: `dump_documents.dart` «dumped 46 documents», `validate_documents.js` 46 × OK.
- Full suite (foreground, once): `+4339: All tests passed!` (expected 4339).
- `flutter analyze --no-fatal-infos`: 47 issues (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.
- `tool/hardening_check.sh`: OK.

## UAT verdict per step (orchestrator's numbering)

| Step | Plan step(s) | Result |
|------|--------------|--------|
| 1 | P1, P4 (fallback block for the legend) | pass |
| 2 | P1, P2 | pass |
| 3 | P1, P2 | pass after 20-UAT-FIX-01 (first attempt «vedo Eroe 0/1») |
| 4 | P11 (optional) | pass (DB: each participant paid with its block) |
| 5 | P10 | pass (on an artificial job) |
| 6 | P5 | pass |
| 7 | P6, P11 | pass, finding F-A (four enemies on the aid → BE quick) |
| 8 | P7 (rescuer) | pass, copy amended → 20-UAT-FIX-02 |
| 9 | P5 («piano» copy) | pass |
| 10 | P6 | pass, finding F-C («,7» secondi) → 20-UAT-FIX-03 |
| 11 | P7 (rescuer) | pass |
| 12 | P9 | pass (on «Sterpaglia di Valantar», 8 floors) |

Not on the device: P3 (Map) not executed; P4 «torn as full» half not executed; P7 wounded side DB only; P8 not observed (no result without turns generated) — all covered by the tests of 20-01 / 20-02. D-16 (archiver release) is covered by the BE suite (BE D-27); device step 12 optional: skipped. P13 (non-caster spell, optional): skipped.

## Requirements ticked

| Requirement | Mandatory planned steps | On the device | By test |
|-------------|-------------------------|---------------|---------|
| RANKP-01 | P1, P2, P3, P4, P6 | P1, P2 (identity switch), P4 (fallback), P6 | P3 (`quest_info_overlay_test.dart`, D-07) |
| RANKP-02 | P1, P2 | P1, P2 | — |
| RANKP-03 | P5, P6, P7, P8, P9 | P5, P6, P7 (rescuer), P9 | P8 (`quest_result_sheet_test.dart`, `quest_outcome_lines_test.dart`); P7 wounded side DB |
| RANKP-04 | P10 + gates of 20-03 | P10 | gates re-run here on `697d40a1` |

All four marked complete with `requirements mark-complete` (checkbox and traceability row verified: `Complete`); Coverage line → 14 / 14.

## Born during the UAT (already committed, documented here)

- `20-UAT-FIX-01.md` — legends folded onto the hero seat lines (`42883521`, `baae07b8`, `3694085b`).
- `20-UAT-FIX-02.md` — «piano» copy for every turn line (`2f619639`, `b42e4f11`, `8a71b280`).
- `20-UAT-FIX-03.md` — duration wording without stray commas (`2d3ceb9c`, `bf1d2e78`, `92d661a5`).
- Quick `261113-aql` — the source hunt / dungeon of an open aid is torn for everyone (`2ba13273`, `5ded49b4`, `2a7effcd`, `f106ba29`, `93cb09fd`, `4b624753`); BE twin merged (PR #37).
- Reviews `20-REVIEW-UAT.md` / `20-REVIEW-UAT-FIX.md` — 8 findings, 6 fixed, 2 by ruling (`222314ce`, `6596807b`, `5e8536b4`, `fee3690a`, `1e665ade`, `a7d2a27c`, `4dd1d4af`, `331cf53c`, `0af419f7`, `9c10ff00`, `2c1e0714`, `a30195c1`, `f13a542e`, `c0ebdd4b`, `40c5277f`).

## Commits of this plan

| Task | Commit | Subject |
|------|--------|---------|
| 1 | `b67917b0` | docs(phase-20): add the rank prizes device UAT |
| 2 | — | checkpoint consumed by the orchestrator (results in `uat21-notes`, recorded verbatim) |
| 3 | `57d70f65` | docs(phase-20): record the rank prizes device E2E |
| SUMMARY | (this commit) | docs(phase-20): record plan 04 progress |

## Deviations from Plan

1. **[Orchestrator note] Checkpoint not stopped at.** The human-verify checkpoint (Task 2) was already consumed by the orchestrator; the results come verbatim from its notes file. No question asked, nothing invented.
2. **[Sanctioned] 12 executed rows instead of 13.** The session used the orchestrator's numbering 1–12 with other seeds (seats hero / mage instead of paladin / adventurer, two characters of different title instead of a title change at DB). The record keeps the plan's 13 steps verbatim as P1–P13 and maps each executed row; Task 1's 13-row check does not apply (the count is 12).
3. **[Orchestrator ruling] Requirements complete with P3 and P8 covered by tests.** Both are not on the device; the ruling «RANKP-01..04 marked complete» applies.
4. **[Rule 1 - stale docs] Copy refreshed outside the UAT record.** BACKEND-NOTES §2 (turn-line table with the old «turno» copy) and the quick-task update (old reason copy, «live» lock) aligned with `20-UAT-FIX-02.md` and `20-REVIEW-UAT-FIX.md`; ROADMAP success criterion 3 now quotes the «piano» copy; STATE quick-task row carries the amended reason and the not-live limit. Quick SUMMARY: the three stale sentences fixed as the orchestrator asked (live lock, reason copy, «no points» viewer), with an amendments paragraph.
5. **STATE frontmatter** `status: phase-complete` (as for earlier completed phases) with `Status:` line «Phase 20 complete …»; progress `3 / 4` phases, `27 / 30` plans.

## Gaps

None for `/gsd-plan-phase 20 --gaps`. Open, not blocking (in STATE): the lock is not live on an open Board (declared limit); the banner copy on a refused locked quest; `Quest.rankPrizes` readable by every authenticated user.

## PR reminder

The orchestrator opens the PR `feat/20-rank-specific-prizes` → `develop` (never `main`), e.g. `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop`. Mention: the served prize block (no client choice), the mixed-boss pins and the legend fold (20-UAT-FIX-01), the dungeon turn line with its fallback and the «piano» copy, the gated selection of the turn fields, `Quest.awaitingRescue` (quick 261113-aql), the duration wording fix, and the BE dependency (BE Phase 21 + PR #37, both on BE `develop`).

## Self-Check: PASSED

- FOUND: `20-HUMAN-UAT.md`, `BACKEND-NOTES.md` (§3), `20-VALIDATION.md` (Approval), `20-04-SUMMARY.md`.
- FOUND commits: `b67917b0`, `57d70f65`.
