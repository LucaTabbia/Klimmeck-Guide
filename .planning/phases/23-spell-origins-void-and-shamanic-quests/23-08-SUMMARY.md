---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 08
subsystem: planning
tags: [device-e2e, uat, handoff, phase-closure]
requires: ["23-14"]
provides:
  - "23-HUMAN-UAT.md (status: complete) with the 12 device steps, results from the user's words, the not-run list and the UAT decisions"
  - "BACKEND-NOTES.md of the FE phase: contract W-1..W-13, FE behaviours, UAT outcome, questions for the BE"
  - "ORIGIN-01..ORIGIN-08 complete; ROADMAP Phase 23 14/14 Complete; 23-VALIDATION approved"
affects: []
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/23-spell-origins-void-and-shamanic-quests/23-HUMAN-UAT.md
    - .planning/phases/23-spell-origins-void-and-shamanic-quests/BACKEND-NOTES.md
  modified:
    - .planning/phases/23-spell-origins-void-and-shamanic-quests/23-VALIDATION.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "UAT run before the BE PR #44 merge on BE branch feat/24-origini-magie-quest-void-shamanic 3f82fa50 (orchestrator ruling, as for 23-07 and 23-14); schema check to be repeated on BE develop after the merge"
  - "Capital markers aarakocraCapital / dragonbornCapital 46 instead of 39 (user, amends D-16; a1df181d)"
  - "School quests research 4 h at DB, learn times 30 min (L6) to 12 h (L20), recovery 15 min (L6) to 8 h (L20) (user, DB content)"
  - "BE D-33: study-lore draw in the school quests at 15 % (user)"
  - "No Journal line for the spell being learned; no Map banner when the result sheet opens directly; research pushes follow the «Fine quest» toggle (user)"
metrics:
  duration: "~35 min"
  completed: 2026-11-16
---

# Phase 23 Plan 08: Device E2E record and phase closure Summary

The device UAT run by the orchestrator with the user on 2026-11-16 (Samsung SM-S938B, local BE from `feat/24-origini-magie-quest-void-shamanic` @ `3f82fa50`) is recorded step by step, the FE handoff for the BE is written, ORIGIN-01..ORIGIN-08 are complete and Phase 23 is closed (14/14). The executor ran no app, no device and no BE.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 | Gate re-check, UAT record, FE BACKEND-NOTES | e1a6e088 |
| 2 | Device E2E (human, run by the orchestrator with the user before this plan) | — |
| 3 | Record the E2E, mark requirements, close planning docs, BE notes §3 | 1588c1e3 |

## Gates (run by this plan)

- Gate re-check on BE ref `3f82fa50` (read-only `git show`): `GATE_OK` (origin, minLevelToLearn, aarakocraCapital, Pet.known, learningSpell, spellDraw, spellFound, spellResearchFailed). The SDL of `3f82fa50` equals the BE working tree and has no diff against `f3313bd2` (gate of 23-14). BE branch HEAD is now `8e87cc35` (docs only after `3f82fa50`).
- Schema check against the BE SDL: `dumped 55 documents`, 55 × OK, exit 0. **To be repeated on BE `develop` after the merge of PR #44 (orchestrator).**
- `flutter analyze`: 47 issues, all info, 0 warnings, 0 errors.
- `flutter test`: `02:11 +5170: All tests passed!` (5169 after 23-14 + 1 from the infused spell card fix).

## Verdict per step

| Step | Requirements | Verdict |
|------|--------------|---------|
| 1 City markers | ORIGIN-04 | pass (capitals 39 → 46 at the user's request, `a1df181d`; DB: lore images realigned, Thengran / Balkuldir swapped) |
| 2 Origin and level in the Journal | ORIGIN-01, 02, 05 | pass |
| 3 Shamanic rite (Thengran) | ORIGIN-03 | pass (two failed researches, then spell found, learning, second sheet) |
| 4 Void rite (Necrorian) | ORIGIN-03 | pass (BE restarted during the learning: the sweep closed it at boot) |
| 5 Arcane quest (Valantar) | ORIGIN-03 | pass |
| 6 Origin lore | ORIGIN-06 | pass («Il Vuoto e l'Abisso dei Diavoli» on the learning-end sheet) |
| 7 Origin on other cards | ORIGIN-05 | shop «Magia infusa»: fail → fixed during the UAT (`4bcd0d9c` / `776a8303`) → pass; innkeeper prize cards: NOT RUN on the device |
| 8 Home cities and city tier | — (BE) | heal, shop, city lore: pass; birth cities: NOT RUN on the device |
| 9 Research part | ORIGIN-07 | pass for the three school rites; `study` with / without the draw: NOT OBSERVED |
| 10 Research succeeded | ORIGIN-07, 08 | pass with the app open; background push «Ricerca riuscita»: NOT OBSERVED |
| 11 End of the learning | ORIGIN-08, 02 | pass; background push «Missione conclusa»: NOT OBSERVED |
| 12 Research failed | ORIGIN-08 | pass, background push «Ricerca conclusa» received instead of the quest-end push |

## Not run on the device (covered by tests)

- Step 7, innkeeper prize cards (user decision, no story / worldMission request available) — 48 px no-overflow widget test in `test/shared/components/cards/spell_card_test.dart`.
- Step 8, birth cities of dragonborn / aarakocra (user decision) — BE specs `character-creation.resolver.int-spec.ts`, `starting-location.service.int-spec.ts`.
- Step 9, `study` quest with the draw («Ricercando…») and without it («Studiando…») — unit / widget tests of 23-11 and 23-12.
- Step 10, push «Ricerca riuscita» in background — push tests of 23-13.
- Step 11, push «Missione conclusa» in background after the learning — push tests of 23-13.

## Requirements ticked

ORIGIN-01..ORIGIN-08, all eight: every mandatory step has its device part passed and no step is left failing (the only fail, step 7 shop card, was fixed and re-checked during the UAT). ORIGIN-05, ORIGIN-07 and ORIGIN-08 rely in part on test coverage for the parts listed above, accepted by the user's decisions during the UAT.

## Gaps

None open for `/gsd-plan-phase 23 --gaps`. Copy: no amendment; visuals: capital marker size (done, `a1df181d`) and infused card overflow (done, `776a8303`). The user will rework the UI layouts in a dedicated later phase.

## Deviations from Plan

1. **[Orchestrator ruling] Task 2 was run before this plan.** The orchestrator guided the user through the 12 steps on 2026-11-16; this plan only recorded the relayed results (no checkpoint returned).
2. **[Orchestrator ruling] BE ref.** Gate and schema check on BE branch `feat/24-origini-magie-quest-void-shamanic` `3f82fa50`, not on `origin/develop` (PR #44 not merged). BE PR #43 is already merged on BE `develop` (`4b2ed03a`).
3. **[Orchestrator request] ROADMAP wording.** The Phase 23 line at the top of `ROADMAP.md` named the origin and quest `magic`; it now reads `arcane` (renamed from `magic`, label «Magia»). The user's verbatim quotes in §Phase 23 Goal are untouched (the amendment line below them already explains the rename).
4. **[Rule 2 - Correctness] 23-VALIDATION manual table** brought in line with D-28 / D-32 («Per impararla: Livello N» without the learn time, «Ricercando…») and extended with steps 9–12.
5. STATE progress counters set by hand (6 phases, 79 plans) instead of `state update-progress`, to avoid the known quirks of gsd-tools on this STATE file.

## PR reminder

After the BE PR #44 merge (and the FE Phase 22 PR), the user opens: `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` from `feat/23-spell-origins-void-and-shamanic-quests` — never `main`.

## Known Stubs

None (docs only).

## Self-Check: PASSED

- Files exist: `23-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `23-08-SUMMARY.md`.
- Commits `e1a6e088`, `1588c1e3` present in `git log`; no attribution trailer.
