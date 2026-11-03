---
phase: 13-city-shops
plan: 11
subsystem: validation
tags: [device-uat, e2e, android, cityShop, pets, handoff, requirements]
requires:
  - phase: 13-10
    provides: schema gate green on the merged BE Phase 12 (`origin/develop` `0585b2e`), 43/43 documents OK, VALIDATION rows 13-11 pending
  - phase: BE 12 (negozi per città)
    provides: merged `cityShop` contract, pools on the real DB, handoff with the pool field names (`shopEquipment`, `shopLoot`, `shopPets`) and the UAT cities
provides:
  - "`13-HUMAN-UAT.md`: device E2E record, 11 steps verbatim, results only from the user's words (steps 1–10 pass, 11 skipped), `status: complete`"
  - SHOP-02, SHOP-03, SHOP-04 marked complete; REQUIREMENTS traceability row and ROADMAP coverage rows Complete
  - "`BACKEND-NOTES.md`: FE handoff for the BE (contract consumed, codes read, FE behaviour, E2E outcome, questions incl. the latent unpopulated-refs defect under `me.currentCharacter`)"
  - "`13-VALIDATION.md` approved (13-11-01..03 green, 13-11-04 D-17 row green)"
  - ROADMAP Phase 13 complete 11/11; STATE closed with the FE PR as the next step and the 13-02 device note resolved
affects: [FE PR feat/13-city-shops, BE Phase 12 UAT follow-up, FE 14]
tech-stack:
  added: []
  patterns:
    - "device UAT record (NN-HUMAN-UAT.md): steps verbatim, results only from the user's words, an «Actual setup» subsection when the run differs from the planned setup, user rules found on the device recorded as D-NN and fixed in TDD on the branch before the record"
key-files:
  created:
    - .planning/phases/13-city-shops/13-HUMAN-UAT.md
    - .planning/phases/13-city-shops/BACKEND-NOTES.md
    - .planning/phases/13-city-shops/13-11-SUMMARY.md
  modified:
    - .planning/phases/13-city-shops/13-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
key-decisions:
  - "SHOP-02/03/04 ticked only after every mandatory step passed on the device per the user's words (step 4 after the D-17 fix); optional step 10 was run, so the `ITEM_NOT_IN_SHOP` proof is a device proof and the fallback wording of the plan `<output>` does not apply"
  - "D-17 (companion dropdown) is a UAT finding fixed in TDD on the branch before this record, not a gap: the phase closes `complete` with no `--gaps` round"
  - "STATE/ROADMAP/REQUIREMENTS closed by hand (python3 UTF-8; `requirements mark-complete` only for the checkboxes), not with the gsd-tools state commands, as in 13-10 (REPO-RULES)"
patterns-established: []
requirements-completed: [SHOP-02, SHOP-03, SHOP-04]
duration: ~11min
completed: 2026-11-03
---

# Phase 13 Plan 11: Device E2E and handoff Summary

**The city shops are proven on the Android phone against the merged BE Phase 12 (`0585b2e`): village / city / capital pools with no legendary item, a Cavallo da viaggio bought in Talmvere, equipped from the Journal dropdown (D-17) and sold in Valantar with the slot emptied by the subscription, the Shop cell closed on Necrorian and a live `ITEM_NOT_IN_SHOP` refusal after a DB curation; SHOP-02/03/04 complete, VALIDATION approved, handoff `BACKEND-NOTES.md` written, Phase 13 closed 11/11.**

## Performance

- **Duration:** ~11 min (executor; the device run itself was held by the orchestrator with the user before this executor was spawned)
- **Started:** 2026-11-03T18:32:04Z
- **Completed:** 2026-11-03T18:43Z
- **Tasks:** 3 (Task 2 is the human checkpoint, run on the device by the orchestrator with the user)
- **Files modified:** 6 (`13-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `13-VALIDATION.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`) + this SUMMARY; no Dart file touched by this plan

## Accomplishments

- Gate re-checked (BE repo read-only: `fetch -q`, `show`, `log`, `ls-tree`): `origin/develop` = `0585b2e` (merge of PR #18 `feat/12-negozi-per-citta`); `grep -c "cityShop"` on `origin/develop:src/schema.gql` → `3`; BE handoff at `.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md` (pool fields `shopEquipment`, `shopLoot`, `shopPets`; §7 UAT cities).
- `13-HUMAN-UAT.md` written with the 11 steps verbatim and the requirement ↔ step map, then filled only with the user's words: steps 1–9 pass, optional 10 pass (run), optional 11 skipped (Redis not running locally); step 4 failed on the first build and passed after D-17.
- SHOP-02, SHOP-03, SHOP-04 marked complete; traceability row `| SHOP-02, SHOP-03, SHOP-04   | Phase 13 | Complete (BE Phase 12 merged; Android device E2E 2026-11-03) |`.
- ROADMAP: `- [x] 13-11-PLAN.md` (11/11 ticked), `- [x] **Phase 13: City Shops** … (completed 2026-11-03)`, coverage rows SHOP-02/03/04 `Complete`, Progress Table `| 13. City Shops | 11/11 | Complete | 2026-11-03 |`, a D-17 decisions line in §Phase 13.
- STATE: `Plan: 11 of 11`, Phase 13 complete, completed phases 12, progress 112/122 (92 %), next step = the FE PR `feat/13-city-shops` → `develop` by the user, then FE 14 → 15 → 16 → 17, FE 12 last; the 13-02 device note struck through as resolved.
- `13-VALIDATION.md`: `status: approved`, `**Approval:** approved 2026-11-03`, rows 13-11-01..03 green, new row 13-11-04 (D-17 widget tests) green, runtime 3031 tests / ~72 s, D-17 cited in the manual-only section.
- `BACKEND-NOTES.md` (FE → BE handoff): §1 contract consumed, §2 codes read, §3 FE behaviour, §4 E2E outcome with the actual setup and the UAT data (no ids, no secrets), §5 questions (latent unpopulated refs under `me.currentCharacter`, `hasShop` liveness, removal of the deprecated catalogue queries, `equipPet` idempotence, `City.size` for the markers); last line «Da riportare nella UAT della BE Phase 12 a cura del lato BE (questo repo non modifica il BE).»

## Task Commits

1. **Task 1: Gate re-check and the UAT record with the 11 steps** — `15d7b6c` (docs(phase-13): add the city shops device UAT)
2. **Task 2: Device E2E on the Android phone** — human checkpoint, run by the orchestrator with the user before this executor; the fix found by it was committed on the branch during the UAT: `8ac0ede` (test(journal): expect the companion section as a spells-like dropdown), `e26c72a` (feat(journal): put the companions on cards in a dropdown with the slot), `6cda912` (docs(phase-13): record D-17, the companion dropdown from the device UAT)
3. **Task 3: Record the E2E, mark the requirements, close the planning documents, hand off to the BE** — `3433d9d` (docs(phase-13): record the city shops device E2E)

**Plan metadata:** `docs(phase-13): record plan 11 progress` (this SUMMARY only; the ROADMAP/STATE/VALIDATION bookkeeping of the plan travelled in `3433d9d`, as the plan `<output>` prescribes).

## UAT verdict per step (from `13-HUMAN-UAT.md`)

| Step | Result | User's words / note |
|------|--------|---------------------|
| 1 cold start, Shop cell enabled | pass | «pass» (1–4 reported together after the D-17 rebuild) |
| 2 Talmvere village pool, Cavallo da viaggio «Velocità ×2», no city name | pass | «pass» |
| 3 buy the horse, slot stays empty, buy list without it | pass | «La sezione compagno non mostra il cavallo dopo l'acquisto» (expected, D-08); DB oro 98 → 97, `ownedPets` = [horse], `pet` null |
| 4 Journal «Compagno» → equip the horse | pass (after D-17) | first build: «La sezione compagno non è apribile. Tutto ok?» → rule «Ma che scelta di merda che hai fatto. Ma fai una roba in stile sezione Magie Imparate. Dropdown, con lista dentro le pergamene e che si possono cliccare per equipaggiare il pet in uno slot» → D-17 (`8ac0ede`, `e26c72a`, `6cda912`), app reinstalled → «pass» |
| 5 Blu Minore (`drusteaSeaCity`) city pool | pass | «pass» |
| 6 Valantar capital pool, Cavallo leggero + Cammello | pass | «pass su tutti i punti» |
| 7 sell the equipped horse, slot emptied by the subscription | pass | «pass su tutti i punti»; wallet < 50 ag not available (88 ag); DB `pet` null, `ownedPets` [] |
| 8 sell a legendary item | pass | «pass su tutti i punti»; wallet after 6–8: 102 oro 63 ag 9 ra |
| 9 Necrorian: Shop disabled, Board enabled | pass | «pass» |
| 10 (optional) `ITEM_NOT_IN_SHOP` after a DB curation | pass (run) | «Cuffia imbottita» removed from `shopEquipment` (10 → 9) → «Questa merce non la tratto», row gone, wallet unchanged; «pass» |
| 11 (optional) equip during a travel | skipped | «Redis non in esecuzione in locale: un viaggio avviato non si chiuderebbe» |

## Requirements ticked (checked by hand against the map)

| Requirement | Mandatory steps | Results | Checkbox |
|---|---|---|---|
| SHOP-02 | 1, 2, 5, 6, 9 | pass, pass, pass, pass, pass | `- [x] **SHOP-02**` (REQUIREMENTS.md line 177) |
| SHOP-03 | 7, 8, 10 | pass, pass, pass (10 run) | `- [x] **SHOP-03**` (line 178) |
| SHOP-04 | 2, 3, 4, 6, 7 | pass, pass, pass (after D-17), pass, pass | `- [x] **SHOP-04**` (line 179) |

Commands: `node "$HOME/.claude/get-shit-done/bin/gsd-tools.cjs" requirements mark-complete SHOP-02` → `{ updated: true, marked_complete: ["SHOP-02"] }`, same for SHOP-03 and SHOP-04 (one id per call). The tool ticked the three checkboxes but left the traceability row untouched: the row and the footer «Last updated» entry were set by hand (python3 UTF-8), as the plan foresaw.

## Gates after D-17 (code changed after the 13-10 gate)

- Full suite, foreground, output to a scratch file read with `tr '\r' '\n'`: `flutter test` → `01:09 +3031: All tests passed!`, exit 0, 72 s, 0 failure markers (13-10: 3027; +4 net after the D-17 rewrite of the companion section tests).
- Analyzer gate of 13-10: `flutter analyze` → `50 issues found. (ran in 3.4s)`, error/warning count 0 → `ANALYZE_GATE_OK` (≤ 50; the exit code 1 comes from the info-level baseline, as before).
- Row 13-11-04 command: `flutter test test/screens/mainScreen/tabs/journal test/shared/components/cards` → `+185: All tests passed!` (the orchestrator's broader run `test/shared/components` gave 350 green during the UAT).
- Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` → `0` over 79 commits (re-checked after each commit of this plan → 0).
- Secrets greps (T-13-36): `grep -ciE "mongodb(\+srv)?://|token=|password"` → `0` on `BACKEND-NOTES.md` and `13-HUMAN-UAT.md`.

## Files Created/Modified

- `.planning/phases/13-city-shops/13-HUMAN-UAT.md` — device E2E record (setup verbatim + actual setup, 11 steps, results, verdict, not observed, D-17 fix table, session notes).
- `.planning/phases/13-city-shops/BACKEND-NOTES.md` — FE handoff for the BE (§0–§5).
- `.planning/phases/13-city-shops/13-VALIDATION.md` — approved; rows 13-11-01..04 green; D-17 outcome paragraphs.
- `.planning/REQUIREMENTS.md` — SHOP-02/03/04 `[x]`, traceability row Complete, footer entry.
- `.planning/ROADMAP.md` — Phase 13 line and plan checkbox ticked, Progress Table 11/11 Complete 2026-11-03, coverage rows Complete, D-17 decisions line.
- `.planning/STATE.md` — Phase 13 complete, `Plan: 11 of 11`, progress 12 phases / 112 plans / 92 %, next step the FE PR, 13-02 device note resolved, `last_updated` 2026-11-03T18:41:46Z (python3 UTF-8).

## Decisions Made

- Requirements ticked strictly on the user's words per the map; step 10 run on the device, so no fallback wording for SHOP-03.
- D-17 treated as a finding fixed during the UAT (TDD on the branch, gates re-run here), not as a gap: `status: complete`, no `/gsd-plan-phase 13 --gaps`.
- The SHOP-04 coverage row of the ROADMAP already existed (added 2026-11-02, the plan assumed it did not): updated in place to `Complete` instead of adding a second row.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Full suite and analyzer gate re-run after the 13-10 gate**
- **Found during:** Task 3 (orchestrator instruction: the code changed after the 13-10 gate because of D-17)
- **Issue:** the 13-10 counts (3027 tests) no longer described the branch
- **Fix:** full `flutter test` (3031 green, 72 s) and the 13-10 analyzer gate (50 issues / 0 error / 0 warning, `ANALYZE_GATE_OK`) run in foreground; counts recorded here and in `13-VALIDATION.md` (runtime row + row 13-11-04)
- **Files modified:** `.planning/phases/13-city-shops/13-VALIDATION.md`
- **Committed in:** `3433d9d`

**2. [Rule 1 - Tool gap] `requirements mark-complete` did not update the traceability row**
- **Found during:** Task 3
- **Fix:** traceability row and footer set by hand (python3 UTF-8); the three checkboxes came from the tool
- **Files modified:** `.planning/REQUIREMENTS.md`
- **Committed in:** `3433d9d`

**3. [Bookkeeping] Task 2 ran outside this executor**
- The human checkpoint was held on the device by the orchestrator with the user before this executor was spawned; the results were transcribed from the user's words as relayed (nothing invented), and the actual setup (BE from `dist/` on port 3001 with `adb reverse tcp:3000 tcp:3001`, DB teleport script replicating `teleportCharacter`, migrated horse removed before step 1, Redis off) is recorded under «Actual setup» in `13-HUMAN-UAT.md` and §4 of `BACKEND-NOTES.md`.

**4. [Boy Scout] ROADMAP §Phase 13 decisions line for D-17**
- Added `**Decisions made (2026-11-03, 13-CONTEXT.md D-17, device UAT)**` so the ROADMAP matches the CONTEXT (criterion 5 «tapping it lists the owned pets» is superseded by the dropdown).

**5. [REPO-RULES] gsd-tools state commands not used**
- STATE/ROADMAP edited with python3 UTF-8 (asserting one occurrence per replacement) instead of `state advance-plan` / `update-progress` / `record-metric` / `roadmap update-plan-progress`, as in 13-10; the frontmatter counters were advanced by hand (12 phases, 112 plans, 92 %).

---

**Total deviations:** 5 (1 gate re-run, 1 tool gap, 1 checkpoint run by the orchestrator, 1 Boy Scout, 1 bookkeeping method). No Dart file touched by this plan, no scope creep.

## Issues Encountered

- None. The plan's acceptance greps all passed at the first run (`^\| (1[01]|[1-9]) \|` = 11, `SHOP-02 (1, 2, 5, 6, 9)` = 1, `status: complete` = 1, `## 5. Questions for the BE` = 1, secrets 0, `- [x] 13-NN-PLAN.md` = 11, `Plan: 11 of 11` = 1).

## User Setup Required

None further for this plan. **PR reminder (the user opens it, never the executor):** from `feat/13-city-shops`, `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` (never `main`), mentioning: the D-14 net-positive sale fix (`canAfford`), the removal of the two catalogue queries (`equipmentAssetsQuantity`, `lootAssetsQuantity`, 45 → 43 documents), the shared `_successfulMutation` helper (`equipSpell`/`unequipSpell`/`equipPet`/`unequipPet`), the shopkeeper bubble lines («Questa merce non la tratto», «Hai già questo compagno»), the BE Phase 12 dependency (PR #18 merged, `0585b2e`), and **D-17** (the «Compagno» section as a dropdown like «Magie imparate», user decision during the device UAT).

## Known Stubs

None — this plan changed no Dart file.

## Threat Flags

None. T-13-36: no real user id, character id, token or URI in `13-HUMAN-UAT.md` / `BACKEND-NOTES.md` (acceptance greps 0). T-13-37: every tick traces to the user's words in the UAT table. T-13-38: BE repo touched only with `fetch -q`, `show`, `log`, `ls-tree`. T-13-39: innkeeper account used as planned (teleport done at DB by the orchestrator, `RolesGuard` unchanged).

## Next Step

Phase 13 is complete (11/11). The user opens the FE PR `feat/13-city-shops` → `develop`; the BE side reads `BACKEND-NOTES.md` §5 (latent unpopulated refs under `me.currentCharacter`). Then FE 14 (Quest Generation companion, after the BE Phase 13 merge) → 15 → 16 → 17, FE 12 (Hardening) last.

## Self-Check: PASSED

- `13-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `13-VALIDATION.md` exist; commits `15d7b6c`, `3433d9d` (this plan) and `8ac0ede`, `e26c72a`, `6cda912` (D-17 during the UAT) are in `git log`.
