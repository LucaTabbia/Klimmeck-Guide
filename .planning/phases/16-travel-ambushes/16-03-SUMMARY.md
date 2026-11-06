---
phase: 16-travel-ambushes
plan: 03
subsystem: results
tags: [flutter, dart, widget, quest-result, ambush]

requires:
  - phase: 16-01
    provides: QuestResult.kind / QuestResult.ambush (AmbushReport, AmbushCity), nullable quest, ambush fixtures
provides:
  - QuestResultSheet.ambushPlaceKey + «Imboscata presso <nearCity.name>» in place of quest title/type
  - QuestResultSheet.reachedCityKey + «Portato a <reachedCity.name>» right after «Ferite» on a lost ambush
affects: [16-05, 16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "Ambush variant of the result sheet driven only by `result.ambush` presence; no outcome/kind branch for rewards/XP (BE zeros hide them)"

key-files:
  created: []
  modified:
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/shared/components/popup/quest_result_sheet_test.dart

key-decisions:
  - "Ambush header and «Portato a» line keyed on `_result.ambush` / `ambush.reachedCity` nullability, never on outcome or kind (D-04, D-13, rule 4)"

requirements-completed: []

duration: 5min
completed: 2026-11-06
---

# Phase 16 Plan 03: Ambush result sheet Summary

**`QuestResultSheet` renders an ambush report: «Imboscata presso <nearCity.name>» + local date replace the quest title/type, «Portato a <reachedCity.name>» follows «Ferite» on a defeat, and rewards/XP show exactly what the BE sends.**

## Performance

- Duration: ~5 min
- Completed: 2026-11-06
- Tasks: 2 (4 commits, TDD red/green each)
- Files: 1 lib modified, 1 test modified

## Accomplishments

- `lib/shared/components/popup/quest_result_sheet.dart`:
  - `static const Key ambushPlaceKey = ValueKey('questResult.ambushPlace');` (after `questTypeKey`).
  - `static const Key reachedCityKey = ValueKey('questResult.reachedCity');` (after `injuriesKey`).
  - `_header()` now spreads `..._placeLine()` instead of `..._questTitle()`; `List<Widget> _placeLine()` returns `_questTitle()` when `_result.ambush == null`, otherwise one centred `bodyMedium` `Text('Imboscata presso ${ambush.nearCity.name}', key: ambushPlaceKey)`.
  - `_content()`: `..._line(_reachedCityText(), QuestResultSheet.reachedCityKey),` right after `..._injuries(),`; `String? _reachedCityText()` returns null unless `_result.ambush?.reachedCity` is non-null, then `'Portato a ${city.name}'`.
  - Class doc mentions «report d'imboscata 16-CONTEXT D-04» (rewrapped to 80 columns).
  - No new outcome/kind branch: `grep -cE "QuestOutcome.failure|isAmbush"` = 1 (the existing `_outcomeInk` arm).

## Task Commits

1. Task 1 RED — `93c7803` test(results): expect the ambush header on the result sheet
2. Task 1 GREEN — `7ba0770` feat(results): show the ambush place on the result sheet
3. Task 2 RED — `33873b8` test(results): expect the city reached after a lost ambush
4. Task 2 GREEN — `49d37d9` feat(results): show the city reached after a lost ambush

## Tests added

New `group('ambush report (Phase 16)')` at the end of `quest_result_sheet_test.dart` (12 tests, all titled with `D-04)`):
- Task 1: «an ambush reads «Imboscata presso <città>» in place of the quest title (D-04, D-13)», «the ambush header keeps the outcome label and ink (D-04)», «the ambush header shows the local ambush instant (D-04)», «the near city of a lost ambush is the one of the report (D-04)», «a quest result keeps its title and type and no ambush line (D-04)».
- Task 2: «a lost ambush shows «Portato a <città>» right after «Ferite» (D-04, D-13)», «a won ambush has no «Portato a» line (D-04)», «a quest result never shows «Portato a» (D-04)», «a won ambush shows the coins and the experience (D-04)», «a lost ambush shows no rewards and no experience (D-04, D-13)», «an ambush shows the enemies fought and the HP bar (D-04)», «a lost ambush keeps «Continua» as the only close (D-04)».

## RED failures observed

- Task 1: compile error `Member not found: 'ambushPlaceKey'` (whole file fails to load).
- Task 2: compile error `Member not found: 'reachedCityKey'`.
- Both REDs are compile-level. Behaviourally, several cases would have been green without the GREEN change, by design: the quest-result regressions («a quest result keeps its title…», «a quest result never shows «Portato a»»), the reused blocks (enemies/HP/«Ferite», «Continua», won coins/XP), and the rewards/XP absence on a lost ambush — the BE sends zero coins and `xpGained: 0` on a defeat (research A2), so the existing `hasRewards` / `xpGained <= 0` guards already hide them; no client branch was added (rule 4, T-16-07).

## Gates

- `flutter test test/shared/components/popup test/screens/mainScreen/components/quest_result_presenter_test.dart`: all passed (popup dir 118, sheet + presenter 61).
- `flutter analyze`: 0 error, 0 warning.
- `dart format` on the two touched files only (no reflow of untouched members).
- Cloudinary SVGs: the existing `setUp` seed covers everything the ambush pages render (ambush enemies have no `imagePath`, so no portrait; coins seeded).

## Deviations from Plan

- **Test detail (not a rule deviation):** «a lost ambush shows no rewards and no experience (D-04, D-13)» also asserts `reachedCityKey` is present, so the test proves it ran on an ambush page and fails with the rest of the file until GREEN.
- **Bookkeeping numbering:** the orchestrator's `3/8` / `Plan: 3 of 8` used instead of the plan's `03/8` / `Plan: 03 of 8` (brief wins).
- Otherwise none — plan executed as written.

## Known Stubs

None.

## Threat Flags

None (city names rendered as plain `Text`, T-16-08 accepted; no outcome branch, T-16-07 mitigated).

## Self-Check: PASSED
