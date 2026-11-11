---
phase: 19-model-review
plan: 13
subsystem: planning
tags: [uat, device, handoff, requirements, security-close]
requires: ["19-12", "BE Phase 19 (BE PR #33, 48b20701)"]
provides:
  - "19-HUMAN-UAT.md complete: steps 1–11 pass, optional 12–14 skipped, extra checks A–C, findings F1 and F2"
  - "MODEL-01..04 complete in REQUIREMENTS.md"
  - "FE BACKEND-NOTES.md with the contract consumed, behaviours, UAT outcome, BE questions and the two product rules of the UAT"
  - "19-SECURITY.md closed at 56/56 (T-19-50, T-19-51 after the device E2E)"
affects: [milestone v1.1 close]
tech-stack:
  added: []
  patterns: ["gated device E2E guided by the orchestrator, results from the user's words, DB readings from the orchestrator"]
key-files:
  created:
    - .planning/phases/19-model-review/BACKEND-NOTES.md
  modified:
    - .planning/phases/19-model-review/19-HUMAN-UAT.md
    - .planning/phases/19-model-review/19-VALIDATION.md
    - .planning/phases/19-model-review/19-SECURITY.md
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "User rule during the UAT: enemy quests are single-player with a minimum rank, no seats (quick task 261111-enm on both repos); boss seats stay rank-exact"
  - "User rule during the UAT: pet shops by city size (village 1, city at most 2, capital at most 3 and at least one), applied at DB"
  - "Step 7 recorded as pass on the second attempt: the first fight was lost and a defeat pays nothing to the companion"
  - "Step 2 on the innkeeper's character is inconclusive (every lore unlocked); completed by check A with a non-innkeeper character"
metrics:
  duration: "UAT session 2026-11-11 (record and closing ~20 min)"
  completed: 2026-11-11
  tasks: 3
  files: 7
---

# Phase 19 Plan 13: Device E2E and closing documents Summary

The model review is proven on the Android device against the BE Phase 19 code with the migrated data and the pet content. Pets show attack, defense and rarity colour in the shop and in the Journal, a bought pet becomes an owned entry with its experience, a won fight pays the companion («Il tuo compagno guadagna 2 PE», 0 → 2 / 100), the spells sit on the single list in learning order, boots go through `feet`, and Map, Library and result sheet look as before. MODEL-01..04 are complete; Phase 19 is closed at 13/13.

## UAT verdict per step (source)

| Step | Result | Source |
|------|--------|--------|
| 1 | pass (content finding F2 fixed at DB) | user |
| 2 | pass (inconclusive on the innkeeper's character; completed by check A) | user |
| 3–6 | pass | user |
| 7 | pass on the second attempt (first fight lost: no line, `petXpGained` 0; finding F1) | user + orchestrator's DB reading |
| 8–11 | pass | user |
| 12–14 | skipped (optional) | — |
| A | pass (non-innkeeper: pet lore page with «Nuovo» after the purchase) | user |
| B | pass («Minaccia» above the rank torn, «Titolo minimo: …» in red, no seat) | user |
| C | pass, visual (a «Minaccia» at or below the rank whole and acceptable; boss unchanged) | user |

## Requirements ticked

Every mandatory step of each requirement passed, checked by hand against the map:
- MODEL-01 (9, 10, 11)
- MODEL-02 (1, 2, 3, 7, 8)
- MODEL-03 (4, 5, 6)
- MODEL-04 (9 + the gates of 19-10 / 19-12)

All four are `[x]` and their traceability rows read `Complete` (`requirements mark-complete`, diff checked: 8 lines, nothing else touched).

## Commits

- `7897713c` docs(phase-19): write the device checklist of the model review (Task 1, earlier in the session)
- UAT fixes by the orchestrator (quick task 261111-enm): `a29360bd`, `169daeda`, `73530a5f`
- `f91b8d10` docs(phase-19): record the model review device E2E (UAT record + requirements)
- `66ef3472` docs(phase-19): hand off the model review to the backend
- `docs(phase-19): summarize plan 13` (this file)
- `docs(phase-19): record plan 13 progress` (VALIDATION, SECURITY, ROADMAP, STATE)

Trailer check after every commit: `0`.

## Gates recorded (not re-run in this plan)

Last full run after the quick task (orchestrator): `+4239 All tests passed!` (4216 + 23), analyzer 47 info / 0 warning / 0 error, `hardening_check` OK. No code changed in this plan; no `flutter test`, no device, no backend touched by the executor.

## Gaps

None for the MODEL requirements. Open notes, recorded in `19-HUMAN-UAT.md`, STATE and the BE notes:
- The unregistered flags UF-19-01..03 of the security audit are accepted as they are.
- Device look to keep an eye on: long «Attacco» lines shrink; the common ink is close to the normal ink (the user found both fine).
- Pets as quest prizes (step 14) were not seen on the device; steps 12 and 13 were not run.
- The abandon button of the map sheet may flash next to «In combattimento…» for a solo quest (pre-existing).
- The innkeeper's test character carries two more injuries from this UAT (`missingLeftHand`, `brokenRightLeg`).

## Provisional visuals for the user's review

- The companion experience as text under «Al tuo fianco» (no bar).
- Attack and defense as two parchment labels in the Journal and two row texts in the shop.
- Rarity as the colour of the pet name, like the item cards.

None was objected to on the device.

## PR reminder

The user opens the PR with `GH_TOKEN=$(gh auth token --user LucaTabbia) gh pr create --base develop` from `feat/19-model-review`, never `main`, and only AFTER the BE quick-task PR `fix/enemy-quests-single-player` is merged: the FE now judges `enemy` quests like the new BE. It should mention:
- the companion experience, attack and defense lines and the rarity colour
- the result line of the companion
- the spells on the single list in learning order
- the `feet` / `wornEquipment` / `imagePath` renames
- the parser hardening
- the quick task 261111-enm (enemy quests single-player with a minimum rank)
- the dependency on BE Phase 19 and on the BE quick task

After the merge: the milestone v1.1 close (both phases are complete; nothing was archived here).

## Deviations from Plan

None under Rules 1–4. Inside the plan's latitude, on the orchestrator's instruction:

1. **Sections beyond the plan's Task 3.** `19-HUMAN-UAT.md` gets «Findings and extra checks» (F1, F2, checks A–C, the fix table, the open notes); `BACKEND-NOTES.md` gets a fifth section «Product rules added during the UAT». The extra checks use letter ids so the 14-step row grep still holds; the hashes are in backticks.
2. **Step 7 differs from its expected text.** The character is a legend at the xp cap: the sheet has no character xp line, so the companion line shows alone instead of «right after» it. It also passed on the second attempt, with the enemy's life lowered at DB by the orchestrator. Recorded as pass with the note.
3. **Step 6 used boots bought during the step,** not boots already in the inventory.
4. **Questions of the plan's §4 already answered.** Research A2, A4 and A5 were answered by the BE handoff (see `19-10-SUMMARY.md`); the notes record them as answered and keep only the order of `ownedPets` and the `characterUpdated` question open.
5. **`19-SECURITY.md` closed here** (not in the plan's file list): T-19-50 and T-19-51 closed, totals 56/56, the three unregistered flags accepted as they are. The file still contains the grep pattern words of the audit as text (pre-existing rows); the acceptance grep is run on the UAT record and the BE notes, as the plan says.
6. **STATE frontmatter set by hand** (`status: phase-complete`, 2/2 phases, 26/26 plans, 100 %) and the milestone lines of ROADMAP and STATE say «both phases complete, milestone close pending»; the milestone was not archived.
7. **Split of the commits:** UAT + requirements, handoff, SUMMARY, bookkeeping — instead of the plan's single Task 3 commit.
8. **Character names in the UAT record.** The two test characters are named as the orchestrator reported them; the BE notes describe them by role only. No user id, twitch id or identity value is written anywhere.

## Known Stubs

None.

## Threat Flags

None — documents only. T-19-50 and T-19-51 are closed in `19-SECURITY.md` («After the device E2E»).

## Self-Check: PASSED

- `19-HUMAN-UAT.md` (`status: complete`, 14 step rows, no empty result) and `BACKEND-NOTES.md` (`## 3. UAT outcome`, `## 4. Questions and notes for the BE`) exist.
- Commits `f91b8d10` and `66ef3472` are in `git log`.
- `grep -c "^- \[x\] 19-[01][0-9]-PLAN.md" ROADMAP.md` = 13; `Plan: 13 of 13` = 1.
- The secret grep prints 0 on the UAT record, the BE notes and this file.
