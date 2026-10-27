---
phase: 08-spells-section-journal-tab
plan: 12
subsystem: graphql
tags: [flutter, dart, graphql, spells, schema-check, uat, device-e2e]

# Dependency graph
requires:
  - phase: 08-11
    provides: "`SpellsSection` + Journal wiring + `SpellDetailsSheet`, fallback «in recupero» without `spellStates`"
  - phase: BE-09.1
    provides: "`CharacterStatus.spellStates { spell usages recoveries }` on BE `develop` `10e5f43` (PR #14)"
provides:
  - "`CharacterFragment` selects `status.spellStates { usages recoveries spell { id } }` (the only fragment change of the phase)"
  - "`SpellState.fromJson` normalises every recovery instant to UTC (`.toUtc()`, security observation O-1)"
  - "`08-HUMAN-UAT.md`: device E2E 12/12 pass on Android against BE `develop` `10e5f43`"
  - "SPELL-01..SPELL-07 ticked in REQUIREMENTS.md; BE handoff §7 updated with the E2E outcome"
affects: [08-13, 08-14, 09-combat-result-sheet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Schema-gated fragment flip: BE gate on `origin/develop:src/schema.gql` first, then `tool/schema_check` against the merged SDL, then the device E2E"
    - "Device offline simulation over USB: drop the `adb reverse` tunnel (connection failure) or route the port to a silent listener (timeout path)"

key-files:
  created:
    - .planning/phases/08-spells-section-journal-tab/08-HUMAN-UAT.md
    - .planning/phases/08-spells-section-journal-tab/08-12-SUMMARY.md
  modified:
    - lib/models/spell/spell_state.dart
    - lib/graphql/fragments/character_fragment.dart
    - test/models/spell/spell_state_test.dart
    - test/graphql/character_fragment_test.dart
    - .planning/phases/08-spells-section-journal-tab/08-VALIDATION.md
    - .planning/phases/08-spells-section-journal-tab/BACKEND-NOTES.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "Phase 8 stays open after 12/12: the user asked for plans 08-13/08-14 (D-22..D-28) in the same PR, so only the 08-12 roadmap checkbox is ticked; the phase line, the Progress Table row and the coverage rows are left to the phase close"
  - "Traceability row set to `Complete` for SPELL-01..07 (all their steps passed on the device)"
  - "Airplane mode replaced by tunnel removal (step 8) and a silent listener (step 12B) because the app talks to the BE over USB `adb reverse`"
  - "Two-character scenario played by the single dev character seeded as `mage` then `adventurer` (scratchpad script, never in a repo)"

patterns-established:
  - "BE change stream on the characters collection delivers direct DB seeds live: device UATs can switch scenarios without restarting the app"

requirements-completed: [SPELL-01, SPELL-02, SPELL-03, SPELL-04, SPELL-05, SPELL-06, SPELL-07]

# Metrics
duration: multi-session (Task 1-2 before the checkpoint; UAT and Task 3 on 2026-10-27)
completed: 2026-10-27
---

# Phase 8 Plan 12: spellStates Fragment, Schema Gate and Device E2E Summary

**`spellStates` selected in `CharacterFragment` after the BE 9.1 gate (`10e5f43`, PR #14), recovery instants normalised to UTC, `tool/schema_check` 34 OK, and the Spells section proven on an Android device 12/12 — SPELL-01..SPELL-07 ticked; the phase continues with 08-13/08-14.**

## Performance

- **Completed:** 2026-10-27
- **Tasks:** 3 (Task 1 auto, Task 2 human checkpoint, Task 3 auto)
- **Files modified:** 4 code/test + 7 planning documents

## Accomplishments

- **BE gate:** `spellStates` present on BE `origin/develop:src/schema.gql` at `10e5f43` (PR #14); SDL equal to the proposal A1/A2; BE repo read with `fetch`/`show` only.
- **O-1 fix:** `SpellState.fromJson` turns every recovery instant into UTC at parse (`.toUtc()`), under TDD.
- **Fragment:** `CharacterFragment` selects `spellStates { usages recoveries spell { id } }`, reaching `character` and `characterUpdated` only.
- **Gates:** `tool/schema_check` 34 OK against BE `origin/develop`; full suite green (2096 tests); `flutter analyze` 53 info, 0 errors (≤ 53 gate).
- **Device E2E:** 12/12 pass on Samsung SM-S938B (Android) via `adb reverse tcp:3000 tcp:3000`, BE `develop` `10e5f43` run locally (`node dist/main`, sweep 60 s), FE `ba7d866`. Step 9 happened in branch A (subscription won).
- **Closure (phase still open):** UAT record, validation sign-off, SPELL-01..07 ticked, 08-12 roadmap checkbox, BE handoff §7, STATE position.

## Task Commits

1. **Task 1 RED** — `09c92a0` `test(spells): expect spell recoveries normalised to UTC at parse`
2. **Task 1 GREEN** — `a55ca4c` `fix(spells): normalise spell recovery instants to UTC at parse`
3. **Task 1 RED** — `1501741` `test(spells): expect spellStates in the character fragment`
4. **Task 1 GREEN** — `88ba990` `feat(spells): select spellStates in the character fragment`
5. **Task 1 docs** — `76d30a1` `docs(phase-8): validate the spell documents and gates`
6. **Task 2** — `ba7d866` `test(phase-8): open the device UAT checklist`
7. **Task 3** — `docs(phase-8): record the spells device E2E` (this commit)

## Device E2E outcome

| Step | Requirement(s) | Result | Note |
|------|----------------|--------|------|
| 1 List and slots | SPELL-01/02/07 | pass | «Passo 1 pass» |
| 2 Countdown | SPELL-05 | pass | «Passo 2 pass: usi tornati a 2/3»; sweep +28 s (18:15:26 vs 18:14:58), DB 2/3 with one residual instant, mirror 2 |
| 3 Recovery never stops | SPELL-05 | pass | «Passo 3 pass»; instant moved to +30 s at the user's request; «1 usi restituiti» at 18:19:26 (instant 18:19:07) with the slot empty; re-equip 3/3 unchanged |
| 4 Optimistic toggle | SPELL-03/04/06 | pass | «Passo 4 pass» |
| 5 Full slots | SPELL-03 | pass | «Passo 5 pass» |
| 6 Zero slots | SPELL-03/07 | pass | «Passo 6 pass» (adventurer seed received live) |
| 7 No spells | SPELL-01 | pass | «Passo 7 pass»; extra D-12: mage + 0 spells → empty slot box + «Non hai ancora imparato nessuna magia» |
| 8 Rollback | SPELL-06 | pass | tunnel removed: «Mi dice direttamente connessione assente riprova, senza attesa»; realigned without loading |
| 9 Race / stale view | SPELL-06 | pass | branch A: Palla di fuoco already in the slot on reopening |
| 10 Long-press sheet | SPELL-02/04 | pass | «passo 10 pass» |
| 11 Server time | SPELL-05 | pass | «passo 11 pass» |
| 12 Slot unlock + tab change | SPELL-06/07 | pass | «Confermo entrambe le parti»; A live slot box, B timeout banner on the Map within 15 s, card sprang back |

Requirement → passed steps: SPELL-01 (1, 7), SPELL-02 (1, 10), SPELL-03 (4, 5, 6), SPELL-04 (4, 10), SPELL-05 (2, 3, 11), SPELL-06 (4, 8, 9, 12), SPELL-07 (1, 6, 12).

**Adaptations** (details in `08-HUMAN-UAT.md` session notes): one dev character played as `mage` then `adventurer` (scratchpad seeds, spells Palla di fuoco and Scurovisione); airplane mode replaced by removing the USB tunnel (step 8, `SpellEquipFailure.connection`, immediate rollback) and by a listener that never answers (step 12B, timeout path); seeds delivered live by the BE change stream on the characters collection (steps 6, 7, 12A without restart); step 3 instant shortened at the user's request. No user ids, Twitch ids, tokens or `.env` values recorded.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Amendments (orchestrator, phase extension)

**1. Phase not closed** — Task 3 step 4 asks to tick all Phase 8 plan checkboxes, mark the phase line and set the Progress Table and coverage rows to `Complete`. Because the user extended the phase with 08-13/08-14 (08-CONTEXT D-22..D-28), only the `08-12-PLAN.md` checkbox was ticked (08-01..08-11 were already ticked); the phase line, `**Plans**: 12 plans`, the coverage rows `SPELL-0N | Phase 8 | Pending` and the Progress Table row stay as they are for the orchestrator.

**2. Traceability wording** — the row reads `| SPELL-01 through SPELL-07   | Phase 8 | Complete |` (orchestrator wording) instead of the plan's long parenthetical.

**3. STATE next step** — next step is plan 08-13 then 08-14 on the same branch, then the FE PR, instead of the PR right away. The resolved «BE Phase 9.1» open item is struck through with its resolution rather than deleted.

**4. `fe_ref`** — `08-HUMAN-UAT.md` carried `fe_ref: 76d30a1` (written before its own commit); set to `ba7d866`, the FE actually under test.

---

**Total deviations:** 4 orchestrator amendments, 0 auto-fixes in Task 3.

## Issues Encountered

None.

## Gaps

None — 12/12 pass, nothing for `/gsd-plan-phase 8 --gaps`.

## Known Stubs

None.

## Threat Flags

None — Task 3 is documents only. T-8-37 (no `.env` read, no ids/tokens in the notes), T-8-38 (step 11 pass), T-8-39 (ticks only for passed steps), T-8-40 (BE repo untouched; BE UAT left to the BE side) mitigated.

## Next

Phase 8 continues on `feat/08-spells-section-journal-tab` with plan 08-13 (use-type filter + use-type line for spells, shop chips limited to the present types) and plan 08-14 (effect labels + filter for items). After them: the FE PR `feat/08-spells-section-journal-tab` → `develop` with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` (never `main`), mentioning the `EquipSpell`/`UnequipSpell` rename (D-21), the shared bookmark/pencil counter refactors touching equipment widgets, the `formatTravelDuration` → `formatGameDuration` move and the BE 9.1 dependency.

## Self-Check: PASSED

- FOUND: 08-HUMAN-UAT.md (`status: complete`, 12 pass rows), 08-VALIDATION.md (`status: approved`), BACKEND-NOTES.md («a cura del lato BE»)
- FOUND commits: 09c92a0, a55ca4c, 1501741, 88ba990, 76d30a1, ba7d866

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
