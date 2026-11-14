---
phase: 22-companion-defeat-rest-and-recovery
plan: 15
subsystem: models / innkeeper
tags: [mission, guided-completion, companion, correction, slider]
requires: ["22-14"]
provides: ["MissionCompanion on MissionFightOutcome.companion", "MissionFightEffects.companionLifeAfter", "MissionCorrection.companionLifeAfter + withCompanionLife", "LifeSlider shared by the character and companion sliders", "companion block in CorrectionSection"]
affects: ["22-16 (gate: selects MissionFightOutcome.companion and MissionFightEffects.companionLifeAfter)"]
tech-stack:
  added: []
  patterns: ["lenient nested model returning null on malformed input", "JSON key emitted only when non-null (if-case)", "one stateless slider widget for two life values"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/components/life_slider.dart
  modified:
    - lib/models/mission/mission_fight.dart
    - lib/models/request/mission_draft_inputs.dart
    - lib/screens/innkeeper/missionCompletion/components/correction_section.dart
    - test/helpers/fixtures/mission_fixtures.dart
    - test/models/mission/mission_fight_test.dart
    - test/models/request/mission_draft_inputs_test.dart
    - test/screens/innkeeper/missionCompletion/components/correction_section_test.dart
decisions:
  - "minLifeAfterFight (= 1) is the floor of both sliders; «Sconfitto» shows when the companion value equals it (plan default, D-17)"
  - "Companion slider value = correction.companionLifeAfter ?? companion.lifeBefore (plan default)"
  - "No companion line in the recap step (plan default, not requested by D-17)"
  - "A served outcome without effects keeps companionLifeAfter null in the completed corrections: the key is not sent and the BE keeps the companion as at the start of the fight"
metrics:
  duration: ~20 min
  completed: 2026-11-14
---

# Phase 22 Plan 15: Innkeeper companion life slider Summary

The guided completion now reads each participant's companion at the start of a fight (`MissionCompanion`: pet id, name, lifeBefore, maxLifePoints, lenient) and the served `companionLifeAfter`; the innkeeper corrects it with a second slider «Compagno: <nome>» under the character's, bounded `1..maxLifePoints` served, with «x / max» and «Sconfitto» at the floor. `companionLifeAfter` is sent only when set, and nothing is selected yet, so against today's BE the section and the wire are unchanged. Last pre-gate plan: 16–17 wait for the BE Phase 23 merge.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Mission companion, effects and correction fields (lenient) | 512f0b5d (RED), a4f700ee (GREEN) |
| 2 | LifeSlider extracted and the companion slider in the corrections | 0047d264 (RED), 503ca181 (GREEN) |
| 3 | Bookkeeping | this commit |

## RED failures

- Task 1: compile errors — `MissionCompanion` undefined, no `companion` on `MissionFightOutcome`, no `companionLifeAfter` on `MissionFightEffects` / `MissionCorrection`, no `withCompanionLife` (mission_fight_test, mission_draft_inputs_test fail to load; mission_draft_test reported a load failure in the same batch and passed alone, collateral of the batch compile).
- Task 2: compile errors — `life_slider.dart` missing, `LifeSlider`, `CorrectionSection.companionSliderKeyFor` / `companionDefeatedKeyFor` undefined.

## Tests

- Models +8: mission_fight_test 4 (companion read, malformed companion null with the outcome kept, no companion when absent, effects companionLifeAfter served/null/malformed); mission_draft_inputs_test 4 (fromEffects copies, withCompanionLife changes only it, other `with…` keep it, toJson only when set).
- Innkeeper +6: character slider inside `LifeSlider` with its bounds and text; companion heading/slider bounds/value; fallback to lifeBefore (extra case); onChanged sends `withCompanionLife`; «Sconfitto» at the floor; without a companion the section is today's.
- `flutter test test/models test/screens/innkeeper` → 1414 green after Task 1; `flutter test test/screens/innkeeper` → 328 green after Task 2. Expected suite total 4980 + 14 = 4994 (full suite not run).
- Analyzer 47 info / 0 warning / 0 error, ANALYZE_GATE_OK after each code task. All touched files formatter-clean before and after.

## Acceptance

- `grep -rn "companionLifeAfter" lib/graphql` prints nothing (Pitfall 1).
- `grep -c "LifeSlider(" correction_section.dart` = 2; `grep -c "Slider(" life_slider.dart` = 2 (the class constructor line and the Material `Slider(`; ≥ 1 required).
- `grep -c "D-33" mission_fight_test.dart` = 4; `grep -c "D-17" correction_section_test.dart` = 7.
- STATE reads `Plan: 15 of 17` (not zero-padded, as the brief requires).

## Deviations from Plan

None in behaviour. Extra cases beyond the plan's list (declared): «other corrections keep the companion life (D-17)» as its own test, «without a served companion life the slider starts at lifeBefore (D-17)», and the malformed-number branch of `companionLifeAfter`. `_lifePoints` was removed (its content moved into `LifeSlider`, Pitfall 9 doc comment kept there).

## Known Stubs

None. Pre-gate the companion is never selected, so the block never shows on a real draft until 22-16 adds the selection (intended, Pitfall 1).

## Threat surface

T-22-48 (slider bounded to served `1..maxLifePoints`, BE validates), T-22-49 (key only when non-null, tested) mitigated as planned. No new surface.

## Self-Check: PASSED

Files exist (life_slider.dart, this SUMMARY); commits 512f0b5d, a4f700ee, 0047d264, 503ca181 present on the branch.
