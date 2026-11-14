---
phase: 21-innkeeper-mission-completion-flow
fixed_at: 2026-11-14
review_path: .planning/phases/21-innkeeper-mission-completion-flow/21-REVIEW.md
iteration: 1
findings_in_scope: 19
fixed: 19
skipped: 0
not_fixed_by_ruling: 2
status: all_fixed
---

# Phase 21: Code Review Fix Report

**Source review:** `21-REVIEW.md` (area A then area B, verbatim copies of the two review reports)
**Rulings:** orchestrator rulings of 2026-11-14 plus the B-11 amendment (see below)
**Base:** `ef0322ec` (plan 15 bookkeeping). One TDD pair per finding (RED `test(...)`, GREEN `fix(...)`), one `refactor(...)` commit for pure clean-ups.

## Amendment to B-11

The coordinator amended ruling B-11 during the run: the BE is getting a technical ceiling of 9 999 999 per coin denomination and for xp (wallet overflow protection, not a product cap), so the bound is **7 digits**, not 9. B-11 had not been committed yet, so it was implemented directly with `maxPrizeAmountDigits = 7` (no follow-up commit needed).

## Fixed

| ID | Sev | Commits (RED → GREEN) | What changed | Tests |
|----|-----|-----------------------|--------------|-------|
| B-01 | HIGH | `4e5fddaf` → `f6dfa674` | `fightsInputWithCorrections` sends the full corrections list only for the fight being corrected; every other fight goes with `corrections` absent (unchanged on the BE, which voids later fights itself). | `mission_draft_inputs_test`: «Avanti on fight 1 with fight 2 already corrected sends no corrections for fight 2 (D-24, D-31)», «…sends corrections for the given fight only (D-06, D-31)»; cubit `saveCorrections` test updated. |
| B-02 | HIGH | `a7e117d1` → `7b9be9ae` | `fightsInputWithEnemies` («Cambia nemici» / encounters save) sends `corrections` null on every fight; `_correctionsKeptFor` / `_sameEnemies` deleted. | `mission_draft_inputs_test`: «sends no corrections, the BE keeps the unchanged prefix (D-24)»; cubit test now pins the exact payload with no `corrections` after a corrected fight (in `00e2e186`). |
| B-04 | HIGH | `f1d040f5` → `0d085226` | `MissionParticipantsCubit` reads places separately: a failed places read gives `Loaded(places: {})`. «Teletrasporta il gruppo» enabled on `!isSubmitting` alone (needs only the draft participants); «Resta qui» still needs loaded characters. A failed participants read shows the existing error line (`MissionCompletionScreen.failureLineOf`, now public) and «Riprova» (existing copy) that reloads the participants. | participants cubit: «a failed read of the places loads the participants with no places (D-31)»; place step: «a failed participants read keeps the city teleport and offers «Riprova» (D-31)», loading state keeps the teleport; screen: ««Riprova» on «Luogo» reads the participants again (D-31)». |
| B-03 | MEDIUM | `8394ae00` → `a7b23396` | `MissionPrizeOptions.blockCure` (lenient `QuestCure.tryFromJson(block.cure)`, in props); `MissionPrizeInput.withCure()`; «Aggiungi cura» row only when the block has a cure and the chosen prize has none; the cure row reads the block cure first (the served one is null after a saved removal). | prize model: «the block cure is read leniently (D-22)»; inputs: `withCure` → `cure: true`; prizes step group «cure of the block (D-22)» (add back after removal, offered on a draft saved without it, absent when the block has none). |
| B-05 | MEDIUM | `ab392115` → `fabbc4f8` | `EnemyPicker`: failure with an empty list shows the wizard error line and «Riprova» (`cubit.load()`); a failure with enemies already listed keeps the list. | `enemy_picker_test`: two cases. |
| B-06 | MEDIUM | `ab392115` → `fabbc4f8` | `PrizesStep`: a failed options read (no options for that character) shows the error line and «Riprova» (`loadFor(id)`) under the character header. | `prizes_step_test`: «a failed options read shows the error line and «Riprova» reads again (D-07)». |
| B-07 | MEDIUM | `16322c84` → `f4a88a5a` | `_saveFights` sends `step: fights` when there are fights (resume never lands past «Scontri» with fights «Da simulare»); `MissionDraft.allFightsSimulated` (served verdicts, true with zero fights); «Avanti» of «Premi» and «Completa» disabled while it is false. | draft model, recap step, prizes step and screen tests (D-24). |
| B-08 | LOW | `6392d3dd` → `823ca048` | `FightStep(key: ValueKey(_fightIndex))`. | screen: «unsaved edits of a fight never follow «Indietro» to an identical fight (D-06)» (RED reproduced: 500 saved instead of 700). |
| B-09 | LOW | `f936e7f8` → `3e225a9c` | Wizard copy for `OUTCOME_OVERRIDE_INVALID`: «Operazione rifiutata: controlla scontri, correzioni e premi». The Phase 10 form keeps «Valori non accettati: controlla il modulo». | screen: «a refused wizard action names fights, corrections and prizes, not a form (D-24)». |
| B-10 | LOW | `163544d7` → `4b678275` | Encounters local list entries carry their `servedIndex`; the status badge reads the served fight it came from; a new fight shows none. | encounters step: «after removing a fight each card keeps the status of its own served fight (D-21, D-24)»; «an added fight shows no status (D-24)» was green at first run (index beyond the served list already gave no status). |
| B-11 | LOW | `819a7b9d` → `9e212627` | Coins / xp fields: digits only, `maxLength: maxPrizeAmountDigits` (7, BE technical ceiling 9 999 999) with an empty counter; constant in `mission_limits.dart`. | prizes step: «coins and xp take digits only, at most 7 (BE technical ceiling 9 999 999)». |
| B-12 | LOW | `00e2e186` (refactor) | Deleted `fightsInputOf`, `_servedCorrectionsOf`, the unreachable unknown-character branch of `_completedCorrections`, the unused `draft` parameter of `fightsInputWithEnemies`, and the unread `block.prizeCoins` / `block.xpPrize` selections (`block.cure` kept, now parsed). Literal `1` → `minPrizeItemQuantity` (prize item floor) and `minLifeAfterFight` (slider floor) in `mission_limits.dart`. | inputs, cubit, graphql, tool tests green before and after. |
| B-13 | LOW | `6731c824` → `233b1e50` | No trailing « · » for an unknown place; `_teleportGroup` returns without throwing on an empty participants list. | place step and screen tests. |
| B-14 | LOW | (in the commits above) | Test gaps covered by the tests of B-01..B-06; the constants-only caps test is removed (`819a7b9d`): every UI cap already has a behaviour test (10 fights, 10 entries, quantity 20, item 1..99) and the new 7-digit bound has its own. | — |
| A-01 | MEDIUM | `3e1c1ced` → `de3bb060` | `innerPlacesVisibleAt(zoom)` (one predicate, used by `TeleportPoiLayer` and by `teleportDropTarget`, which now takes the camera zoom): below `cityVisibleZoom` a drop resolves to the city as in Phase 10. The two widget tests that dropped on a place at zoom 2 (dots hidden) now drop at the city zoom (`mapHarness` gained an `initialZoom` parameter, default 2). | `teleport_drop_test`: «below the city zoom a drop near a hidden place resolves to the city (D-29)», predicate test. |
| A-02 | LOW | `b8f5b458` → `69cdb817` | `TeleportDestination.ofPlace` returns `null` for a place without a known `PoiType`; the cubit test fixture uses `forest`. | «a place with no known type is not a destination, so no dot (D-29)». |
| A-04 | LOW | `fb0e50a8` (refactor) | `Character.isOnMission` is the one reader (Journal, satchel, spells, companion, items, Map pawn travel gate, `QuestViewer.of`, main screen); `MissionLockedSection` + `ignoreMissionLockedToggle` in `lib/shared/components/mission_locked_section.dart` shared by companion and spells; `utcInstantOrNull` in `lib/models/utc_instant.dart` replaces the three copies (`PendingRequest`, `CharacterStatus`, `missionInstantOf`). Behaviour unchanged. | `test/models test/screens/mainScreen test/screens/innkeeper test/shared` +3034 and `test/repository test/graphql test/tool` +1158 green after. |

## Not fixed (orchestrator ruling, recorded for the UAT)

| ID | Sev | Reason |
|----|-----|--------|
| A-03 | LOW | The bookmark ribbon of the equipment info sheet looks active but is inert under the lock (same as the spell sheet today): product choice for the UAT. |
| A-05 | LOW | The teleport layer overriding the mixin's drop path is the accepted design of plan 21-08 (players' drop rule untouched). |

## New copy for the UAT list

- «Aggiungi cura» (prizes step, B-03)
- «Operazione rifiutata: controlla scontri, correzioni e premi» (wizard refusal for `OUTCOME_OVERRIDE_INVALID`, B-09)

No other new string: the failure lines and «Riprova» reused on «Luogo», the enemy list and the prize options are the wizard's existing copy.

## Gates

- Analyzer after every code commit: 47 info / 0 warning / 0 error.
- Targeted tests only (no full suite). `dart format` on touched files one by one; `spells_section.dart` was formatter-clean at the base and was re-formatted after the refactor.
- Wizard still unreachable from the panel (D-28); no gated field selected (D-30).

---

_Fixed: 2026-11-14_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
