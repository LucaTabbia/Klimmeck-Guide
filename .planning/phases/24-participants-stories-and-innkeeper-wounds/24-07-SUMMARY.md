---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 07
subsystem: innkeeper
tags: [wounds, corrections, wizard, innkeeper-wounds, switch]
requires: ["24-06"]
provides:
  - "InjuryChips({carried, innkeeperCarried, removed, added, innkeeperAdded, onRemovalToggled, onAddToggled}) with keptKeyOf / addedKeyOf / innkeeperNoteKey / innkeeperLabelOf / carriedHeading / addedHeading / innkeeperNote"
  - "CorrectionSection.isWoundRemovalEnabled and FightStep.isWoundRemovalEnabled (default: storyAndWoundCorrectionsEnabled)"
  - "MissionDraftCubit.saveCorrections(..., declaresRemovals: false)"
  - "Recap line «Ferite tolte: …» in missionRecapLinesOf (recap and both confirmations)"
affects: [24-10, 24-11]
tech-stack:
  added: []
  patterns: ["the absence of a callback is the mode: onRemovalToggled == null means removal off, no flag inside the chips"]
key-files:
  created: []
  modified:
    - lib/screens/innkeeper/components/injury_chips.dart
    - lib/screens/innkeeper/missionCompletion/components/correction_section.dart
    - lib/screens/innkeeper/missionCompletion/steps/fight_step.dart
    - lib/screens/innkeeper/missionCompletion/steps/recap_step.dart
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - lib/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart
    - test/screens/innkeeper/components/injury_chips_test.dart
    - test/screens/innkeeper/missionCompletion/components/correction_section_test.dart
    - test/screens/innkeeper/missionCompletion/steps/fight_step_test.dart
    - test/screens/innkeeper/missionCompletion/steps/recap_step_test.dart
    - test/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit_test.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
decisions:
  - "an added chip carries « (dell'oste)» only when the wound is in the correction's added list AND in the served effective innkeeperInjuries: a wound just added by hand stays plain until the BE serves it back"
  - "the screen's one parameter isStoryAndWoundInputEnabled drives both the removal in the chips and declaresRemovals on the save"
  - "the recap's «Ferite tolte» is the union of the served effective injuriesRemoved over the fights, in served order, lowercase, after «Ferite: …»"
metrics:
  duration: "~20 min"
  completed: 2026-11-21
---

# Phase 24 Plan 07: Corrections that remove and re-add wounds Summary

Under «Ferite» the correction section now shows two groups: «Ferite presenti» (one chip per wound carried at the start of the fight, selected = kept, a tap removes it, the innkeeper's labelled «<ferita> (dell'oste)» from the served `innkeeperInjuriesBefore`) and «Ferite da aggiungere» (every wound type; a carried wound not removed is disabled, a removed one is addable again). With the switch on the fight's save declares its removals (`injuriesRemoved` always sent, `[]` included) and the recap reads «Ferite tolte: …». With the switch off (today's constant) nothing is removable, the note is not drawn and the key never leaves the app.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect carried wounds removable and re-addable in the corrections | 160419f7 |
| 1 GREEN | Remove and re-add wounds in the corrections | 442248fc |
| 2 RED | Expect the removals sent by the fight and told by the recap | 40e86a0c |
| 2 GREEN | Send wound removals and list them in the recap | 36f03378 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (160419f7):** both files did not compile (`keptKeyOf`, `addedKeyOf`, `innkeeperNoteKey`, the new constructor, `isWoundRemovalEnabled` missing).
- **Task 1 GREEN (442248fc):** `flutter test test/screens/innkeeper` → 445 passed; analyzer «47 issues found» (`ANALYZE_GATE_OK`).
- **Task 2 RED (40e86a0c):** fight step, Cubit and screen tests did not compile (`isWoundRemovalEnabled`, `declaresRemovals`); the three recap cases failed on the missing line.
- **Task 2 GREEN (36f03378):** `flutter test test/screens/innkeeper` → 456 passed; analyzer «47 issues found» (`ANALYZE_GATE_OK`); `tool/hardening_check.sh` OK. The full suite was not run (reserved to 24-10).

## Rewritten cases (old titles → new)

`injury_chips_test.dart` (whole file rewritten, 3 → 12 cases):
- «an injury the character already had is selected and locked (D-14)» → «with removal off the carried wounds are shown and not tappable (pre-gate)» and «a carried wound is shown as kept and a tap asks to remove it (D-13)»
- «an injury the fight adds is selected and removable (D-14)» and «an injury not present can be added (D-06)» → «a wound not carried toggles as before»

`correction_section_test.dart` (group «wounds (Phase 24)», 2 → 9 cases):
- «injuriesBefore are locked, the fight's injuries toggle (D-14)» → «with the switch off no carried wound is removable and the note is absent (pre-gate)» and «a wound the fight adds still toggles (D-06)»
- «injuries added by an earlier fight are locked in the next one (D-14)» → «a wound added by an earlier fight is carried in the next one and cannot be added twice (D-16)»

Tests moved from the old key `completion.injury.<name>` to the new keys: only these two files used it (`correction_section_test.dart`'s `_chip` helper became `_keptChip` / `_addedChip`). No other test in the repo referenced the old key.

## What was built

- **`InjuryChips`:** two `_Group`s (heading in `bodyMedium` + `Wrap`); the first only when `carried` is not empty. Kept chip: `selected: !removed.contains(injury)`, `onSelected` null without `onRemovalToggled`. Add chip: `selected: added.contains(injury)`, disabled when carried and not removed. The note (`innkeeperNoteKey`) only with `onRemovalToggled != null`. No origin is derived: the marks read `innkeeperCarried` and `innkeeperAdded` only.
- **`CorrectionSection`:** `isWoundRemovalEnabled` → `onRemovalToggled: correction.withInjuryRemovalToggled`, otherwise null; `innkeeperAdded` = `outcome.effective?.innkeeperInjuries`.
- **`FightStep`:** `isWoundRemovalEnabled` handed to every section; nothing else changed (a served correction with removals reseeds through `MissionCorrection.fromEffects`).
- **Cubit / screen:** `saveCorrections(..., declaresRemovals:)` → `fightsInputWithCorrections(..., declaresRemovals:)`; the screen passes `widget.isStoryAndWoundInputEnabled` to both the fight step and the save.
- **Recap:** `_characterLines` collects the served effective effects once, then «Ferite: …» and «Ferite tolte: …» through one helper (`_injuryNamesOf`).

## Deviations from Plan

**1. Switch off is not pixel-identical to before** — the truth «exactly as today» holds for behaviour (no carried wound tappable, nothing new sent), not for layout: the two groups and their headings are drawn in both modes, so a carried wound now appears selected and locked under «Ferite presenti» and unselected and locked under «Ferite da aggiungere» (before: one selected, locked chip in a single list). This is what the plan's GREEN step prescribes; flagged for the UAT.

**2. Extra cases beyond the plan's list** — section: «a wound the fight adds still toggles (D-06)», «a wound added by an earlier fight is carried in the next one and cannot be added twice (D-16)», «an added wound is marked only when the served effect lists it among the innkeeper's (D-12)», «with the switch on the note is drawn (D-12)»; recap: the pure-function twins of the two widget cases.

**3. Existing `saveCorrections` verifications left as they were** — only the group's stub gained `declaresRemovals: any(named: …)`; the existing `verify`s omit the parameter, which mocktail reads as `false`, true for a harness with the switch off.

## Known Stubs

None. Removal is unreachable in the running app until 24-10 flips `storyAndWoundCorrectionsEnabled` — by design (gate).

## Threat Flags

None: no new surface beyond the plan's register (T-24-28..T-24-31 covered by the cases above).

## For the next plans

- 24-10: flipping the constant needs no change in these tests (`storyAndWoundCorrectionsEnabled` appears 0 times in the chips, section and fight step tests); only `mission_completion_route.dart` relies on the default.
- A wound added by hand in the current correction shows a plain label until the served effect lists it in `innkeeperInjuries` (after the save, post-gate) — to look at in the UAT (24-11) together with the layout of the two groups with the switch off.
- The «Concludi» / «Completa» confirmation shows «Ferite tolte: …» through `missionRecapLinesOf`.

## Self-Check: PASSED

- Commits 160419f7, 442248fc, 40e86a0c, 36f03378 present in `git log`.
- Acceptance greps: `completion.injury.kept.|completion.injury.added.` 2 in `injury_chips.dart`; old key prefix absent from `lib`; `simulated` 0 in `injury_chips.dart`; `Ferite tolte` 1 in `recap_step.dart`; `isWoundRemovalEnabled` 3 in `fight_step.dart`; `declaresRemovals` 3 in the Cubit; `lib/config/story_and_wound_corrections.dart` still `false`.
