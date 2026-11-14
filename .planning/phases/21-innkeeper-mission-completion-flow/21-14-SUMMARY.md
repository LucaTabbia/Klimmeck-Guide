---
phase: 21-innkeeper-mission-completion-flow
plan: 14
subsystem: innkeeper
tags: [wizard, guided-mission, widget-test, fights, corrections]
requires: ["21-13"]
provides:
  - "EncountersStep(draft, isSubmitting, onNext(List<List<MissionEnemyInput>>)) — «Scontri» fights editor bounded by mission_limits.dart"
  - "EnemyPicker(onPick) — lazy ListView.builder over MissionEnemiesState.visible, «Cerca» → setQuery, «Mostra tutti» → setShowAll"
  - "FightStep(draft, fightIndex, isSubmitting, onSimulate, onChangeEnemies, onNext(List<MissionCorrection>)) — «Scontro k di N»"
  - "CorrectionSection(participant, outcome, correction, itemNameOf, spellNameOf, onChanged) — per-character corrections within served bounds"
  - "host: pages encounters and fight wired; fight index navigation; «Indietro» walks the fights back"
affects: [21-15, 21-16, 21-17, 21-18]
tech-stack:
  added: []
  patterns: ["step pages own their primary «Avanti» (key MissionCompletionScreen.nextKey) because the edit state is local to the page", "host _enter(page, {fightIndex}) is the only place the page changes; entering «Scontri» loads the enemy list only when missing", "FightStep re-seeds its local corrections from the served effective effects whenever the served fight changes (didUpdateWidget)"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/components/enemy_picker.dart
    - lib/screens/innkeeper/missionCompletion/components/correction_section.dart
    - lib/screens/innkeeper/missionCompletion/steps/encounters_step.dart
    - lib/screens/innkeeper/missionCompletion/steps/fight_step.dart
    - test/screens/innkeeper/missionCompletion/components/enemy_picker_test.dart
    - test/screens/innkeeper/missionCompletion/components/correction_section_test.dart
    - test/screens/innkeeper/missionCompletion/steps/encounters_step_test.dart
    - test/screens/innkeeper/missionCompletion/steps/fight_step_test.dart
    - test/screens/innkeeper/components/injury_chips_test.dart
  modified:
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
decisions:
  - "«Avanti» on «Scontri» is disabled while any fight has no enemy: the BE refuses it (MissionFightInput.enemies @ArrayMinSize(1), BE 22-15)"
  - "With zero fights the picker stays visible but a pick is ignored (no selected fight); «Aggiungi scontro» creates and selects one"
  - "«Avanti» of the fight page sits in the action Wrap next to «Simula»/«Rilancia» and «Cambia nemici» (the page is ~140 px high in landscape): the enemies line is the first item of the lazy list"
  - "«Indietro»: fight k>0 → fight k-1, fight 0 → «Scontri», «Premi» → last fight (or «Scontri» with zero fights), «Riepilogo» → «Premi», «Scontri» → «Luogo»"
  - "The slider shows `hpAfter` clamped to 1..maxLifePoints only for display (a served 0 would assert); the value sent is the served/corrected one until the innkeeper moves it"
metrics:
  duration: "~60 min"
  completed: 2026-11-14
---

# Phase 21 Plan 14: Wizard UI 2 Summary

«Scontri» builds zero, one or several fights from the served enemy list (lazy `EnemyPicker` with «Cerca» and «Mostra tutti», no client filter) with UI bounds from `mission_limits.dart`, and «Scontro k di N» runs the BE simulation in order, shows the served verdict and engine line, and edits the corrections within served bounds, always sending the full list (one per participant with `hpAfter`).

**Still not wired: «Completa» opens the Phase 10 form** (D-28; wiring in 21-16).

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 «Scontri» | `cb628599` test (RED), `c63897c5` feat (GREEN) | `flutter test test/screens/innkeeper/missionCompletion` +116 green |
| 2 «Scontro k di N» | `bd3ea293` test (RED), `0c338a0b` feat (GREEN) | `flutter test test/screens/innkeeper` +324 green |
| 3 Bookkeeping | `docs(phase-21): record plan 14 progress` | ROADMAP 14/18, STATE `Plan: 14 of 18`, VALIDATION 21-14-01..03 ✅ |

### RED evidence

- Task 1: `enemy_picker_test.dart` and `encounters_step_test.dart` failed to load (missing `EnemyPicker` / `EncountersStep`); in `mission_completion_screen_test.dart` «Avanti» on «Scontri» (two cases) and «opening «Scontri» loads the enemy list once (D-03)» failed (no widget, no load). `mission_enemies_cubit_test.dart` also showed a loading `[E]` in the same run: spurious (shared compile with the broken files), green standalone (+10).
- Task 2: `correction_section_test.dart`, `fight_step_test.dart` failed to load (missing classes), `mission_completion_screen_test.dart` failed to load (imports `fight_step.dart`).

### Green at the first run (with reason)

- `injury_chips_test.dart` (3 cases): `InjuryChips` already has the D-14 semantics (existing = selected + disabled, added = selected + toggleable); the cases re-pin `completion_form_test.dart` «an existing injury is selected and disabled» so 21-17 can delete the old form test. Its loading `[E]` in the combined RED run was the shared compile; standalone +3.
- Screen: «a list already served is not read again (D-03)» (no load existed yet) and ««Indietro» from «Scontri» goes back to «Luogo»» (enum-order back already did it).
- Added at GREEN, not RED: ««Indietro» from «Premi» goes back to the last fight» (pins the back rule written in the same commit).

## The D-14 lock is per fight

The D-14 lock is per fight: an injury added by fight k-1 is locked on fight k (it is in fight k's served `injuriesBefore`) and removed by correcting fight k-1 (voids the following fights, D-24) — same rule as the BE. `CorrectionSection` passes `outcome.injuriesBefore` as `InjuryChips.existing` and `correction.injuries` as `added`; pinned by «injuries added by an earlier fight are locked in the next one (D-14)».

## BE caps used (UI bounds only, the BE judges)

From `lib/models/mission/mission_limits.dart`: `maxMissionFights` 10 («Aggiungi scontro» disabled), `maxEnemyEntriesPerFight` 10 (a new enemy is ignored, an enemy already in the fight still increments), `minEnemyQuantity` 1 (first pick), `maxEnemyQuantity` 20 (`QuantityStepper.max`, a pick at 20 changes nothing). No literal repeated in the widgets (`grep -cE "max: (20|99)\b"` = 0).

## Copy for the UAT review

Outside the D-30 / Open Question 8 table (research F-5 proposal): «Leggendario» (trailing text of a legendary enemy row) and «PE n · PV n» (enemy row subtitle; `–` when the BE serves no value). Reused Phase 10 copy: «Punti vita», «Ferite», «Consumabili», «Magie», «Nessun consumabile», «Nessuna magia attiva». The engine line is «PV a → b». A consumable/spell without a name in the participant's served character shows its id (plan: `itemNameOf(id) ?? id`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Correctness] «Avanti» on «Scontri» disabled while a fight has no enemy**
- **Found during:** Task 1
- **Issue:** the BE refuses an empty fight (`MissionFightInput.enemies @ArrayMinSize(1)`), so «Aggiungi scontro» + «Avanti» would always end in a refusal.
- **Fix:** `_canGoOn` requires every fight to have a pick; pinned by «a fight without enemies keeps «Avanti» disabled (BE: at least one enemy per fight)».
- **Files modified:** encounters_step.dart, encounters_step_test.dart
- **Commit:** `cb628599`, `c63897c5`

**2. [Rule 3 - Blocking] Fight page layout**
- **Found during:** Task 2
- **Issue:** the plan's column (enemies line, actions row, list, «Avanti») overflowed the ~141 px page height of the host in landscape.
- **Fix:** «Avanti» joins «Simula»/«Rilancia» and «Cambia nemici» in a `Wrap`; the enemies line is item 0 of the lazy `ListView.builder` of the sections.
- **Files modified:** fight_step.dart
- **Commit:** `0c338a0b`

**3. [Rule 1 - Bug] `simulated!` / slider assertion guards**
- **Found during:** Task 2
- **Issue:** the plan's `outcome.simulated!.hpAfter` would crash on an outcome with only a correction; a served `hpAfter` outside 1..max would assert in `Slider`.
- **Fix:** the engine line is shown only when `simulated != null`; the slider value is clamped for display only.
- **Files modified:** correction_section.dart
- **Commit:** `0c338a0b`

Test-helper note: in `encounters_step_test.dart` picks jump the picker list to the top before tapping (`scrollUntilVisible` scrolled past the first rows after the first pick).

## Formatter and analyzer

- Pre-check: `mission_completion_screen.dart` and its test were formatter-clean before the change.
- Formatted one by one: enemy_picker.dart, encounters_step.dart, correction_section.dart, fight_step.dart, mission_completion_screen.dart and the six test files.
- Analyzer after each code task: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.

## Known Stubs

- `MissionPage.prizes` / `MissionPage.recap` still render `SizedBox.shrink()` in the host (21-15 adds them).

## Self-Check: PASSED

- Files: the four lib files and five new test files exist.
- Commits `cb628599`, `c63897c5`, `bd3ea293`, `0c338a0b` present in `git log`.
