---
phase: 15-travel-food
plan: 06
subsystem: quest
tags: [flutter, dart, quest, travel, food, quest-sheet]

requires:
  - phase: 15-travel-food
    provides: foodText/lifeText/starvingPhrase (15-01), TravelPreview.food/hpLost/arrivesAlive (15-01)
provides:
  - pure QuestTravelLine {text, isStarving} built from TravelPreview? (null without a preview)
  - QuestSheetDetails.travelLine (null on the narrative family)
  - QuestInfoSheet.travelPreview data-only parameter and the «Viaggio» line (travelLineKey) in the combat and service bodies
affects: [15-07, 15-09]

tech-stack:
  added: []
  patterns:
    - "The shared quest sheet takes the travel preview as data (TravelPreview?), never a cubit: read-only callers pass nothing and get no line"

key-files:
  created:
    - lib/models/quest/quest_travel_line.dart
    - test/models/quest/quest_travel_line_test.dart
  modified:
    - lib/models/quest/quest_sheet_details.dart
    - lib/shared/components/popup/quest_info_sheet.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart

key-decisions:
  - "The «Viaggio» line sits right after the time line and before the title line in both the combat right column and the service column (D-04, Claude's discretion on the exact position)"
  - "The starving line shows the user phrase only, no food and no number (mirror of D-10 on the confirmation sheet)"

patterns-established:
  - "QuestTravelLine.of(TravelPreview?) → QuestTravelLine? ; QuestSheetDetails.of(quest, {viewer, travelPreview})"

requirements-completed: []  # mark-complete forbidden here; FOOD-02/03 advanced, traceability in 15-09

duration: 9min
completed: 2026-11-05
---

# Phase 15 Plan 06: The «Viaggio» line of the quest sheet Summary

**A pure `QuestTravelLine` turns the owner-only preview into «Viaggio: 1x Razione da viaggio · nessuna perdita», «Viaggio: nessun cibo · −136 HP» or the red «Viaggio: Non hai cibo a sufficienza per il viaggio»; `QuestSheetDetails.travelLine` carries it (never on story/worldMission) and `QuestInfoSheet` renders it in the combat and service bodies from a data-only `TravelPreview? travelPreview` parameter, so the map overlay (no preview) shows nothing.**

## Performance

- Duration: ~9 min
- Tasks: 2/2
- Files: 1 lib created, 2 lib modified, 1 test created, 2 tests modified

## Accomplishments

- `lib/models/quest/quest_travel_line.dart`: `class QuestTravelLine extends Equatable { const QuestTravelLine({required String text, required bool isStarving}); static QuestTravelLine? of(TravelPreview? preview); props [text, isStarving] }`; private constants `_prefix = 'Viaggio: '`, `_separator = ' · '` (U+00B7), `_noFoodText = 'nessun cibo'`. Starving → `const QuestTravelLine(text: 'Viaggio: ' + starvingPhrase, isStarving: true)`; otherwise `foodText(preview.food, empty: 'nessun cibo')` + ' · ' + `lifeText(preview)`. Imports only equatable and `../travel/travel_cost_text.dart`, `../travel/travel_preview.dart` (Flutter-free, no utils).
- `lib/models/quest/quest_sheet_details.dart`: `factory QuestSheetDetails.of(Quest quest, {QuestViewer? viewer, TravelPreview? travelPreview})`; `final family = questSheetFamilyOf(type)` computed once; new required ctor param / field `final QuestTravelLine? travelLine` = `family == QuestSheetFamily.narrative ? null : QuestTravelLine.of(travelPreview)`; added to `props`. Only the factory calls the constructor.
- `lib/shared/components/popup/quest_info_sheet.dart`: ctor param `this.travelPreview` (field `final TravelPreview? travelPreview`); `static const Key travelLineKey = ValueKey('questSheet.travelLine')` after `costLineKey`; `_buildContent` passes `travelPreview: travelPreview`; `List<Widget> _travelLine(QuestSheetDetails details)` (Text, `bodyLarge`, `bloodRed` when `isStarving`); `..._travelLine(details)` inserted after `..._timeLine()` in `_combatBody` (right column) and `_serviceBody`. `_narrativeBody` unchanged.

## Task Commits

1. Task 1 RED `3be5350` test(models): expect the travel line of the quest sheet; GREEN `e37e809` feat(models): build the travel line of the quest sheet
2. Task 2 RED `d37e24b` test(quest): expect the travel line on combat and service sheets; GREEN `0be2029` feat(quest): show the travel line on combat and service sheets

## RED failures observed

- Task 1: compilation failure — `Error when reading 'lib/models/quest/quest_travel_line.dart': No such file or directory`, `No named parameter with the name 'travelPreview'`, `Undefined name 'QuestTravelLine'`, `The getter 'travelLine' isn't defined for the type 'QuestSheetDetails'`.
- Task 2: compilation failure — `quest_info_sheet_test.dart:75:13: Error: No named parameter with the name 'travelPreview'`, `Member not found: 'travelLineKey'`.

## Tests added

- `test/models/quest/quest_travel_line_test.dart` (5 tests, D-04/D-06/D-11); local helper `_preview({food = const [], hpLost = 0, arrivesAlive = true})`.
- `test/models/quest/quest_sheet_details_test.dart` group `'travel line'` (4 tests, D-04); imports `quest_travel_line.dart`, `travel_preview.dart`, `travel_fixtures.dart`.
- `test/shared/components/popup/quest_info_sheet_test.dart`: `_pump` gains `TravelPreview? travelPreview`; top-level helpers `_travelPreview({bool arrivesAlive = true})` (food [Razione ×1], hpLost 0 or 20910) and `_travelLineIn(Key familyKey)`; group `'travel line'` (7 tests, D-04 / D-04, D-06). File: 55 tests.

## Verification

- Task 1: `flutter test test/models/quest test/shared/components/popup/quest_info_sheet_test.dart` → `+197: All tests passed!`.
- Task 2: `flutter test test/shared/components/popup test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map test/models/quest` → `+509: All tests passed!`.
- Analyzer last line `50 issues found.` (all info), `ANALYZE_GATE_OK` after each code task.
- Acceptance greps: `class QuestTravelLine` 1, `·` 1, `'nessun cibo'` 1, `QuestTravelLine.of(travelPreview)` 1, `travelLine: family == QuestSheetFamily.narrative` 1, `D-(04|06|11)\)` in quest_travel_line_test 5, `D-04)` in quest_sheet_details_test 4, Flutter/utils imports in the model none; `travelLineKey` 2, `_travelLine(details)` 2, `travelPreview: travelPreview` 1, `D-04(, D-06)?\)` in quest_info_sheet_test 10.
- `dart format` on each touched file, one by one: no reflow of untouched members.

## Deviations from Plan

None in behaviour. Notes: the `travelLine` field doc was wrapped over two lines to stay within 80 columns (dart format does not rewrap comments); the `QuestSheetDetails.of` signature is formatted over several lines (grep anchors are single identifiers, unaffected). The Wave 0 checklist item of VALIDATION was left unticked, as the previous plans did.

## Known Stubs

None. The line is fed by 15-07 (the Board's per-sheet `QuestTravelPreviewCubit`); until then no caller passes a preview, which is the intended read-only behaviour.

## Threat Flags

None (T-15-16: the line composes `foodText`/`lifeText` only, `arrivesAlive` the only starving signal; T-15-17: no line without a preview, narrative always null — pinned by tests).

## Self-Check: PASSED
