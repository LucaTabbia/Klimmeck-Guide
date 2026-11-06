---
phase: 15-travel-food
plan: 05
subsystem: travel
tags: [flutter, dart, travel, food, confirmation-sheet, docs]

requires:
  - phase: 15-travel-food
    provides: foodText/lifeText/starvingPhrase (15-01), TravelPreview.food/hpLost/arrivesAlive (15-01), TravelRequoting (15-04)
provides:
  - «Cibo» and «Vita» rows under «Arrivo» on TravelConfirmationSheet (five «…» placeholders while previewing)
  - red «Vita» row with the user phrase and «Parti» disabled on arrivesAlive false
  - widget tests pinning the sheet through the starving requote
  - ui-ux.md travel confirmation rule with food and life (D-13)
affects: [15-08, 15-09]

tech-stack:
  added: []
  patterns:
    - "A value row takes its colour and line count as values (maxLines, valueColor), never a boolean flag"

key-files:
  created: []
  modified:
    - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
    - test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart
    - docs/rules/ui-ux.md

key-decisions:
  - "«Parti» is gated in the widget only (TravelConfirming && preview.arrivesAlive); the cubit keeps no food check (D-10) and the BE refusal stays the defence"
  - "The sheet needs no code for the requote: TravelRequoting is a TravelQuote (numbers kept), not TravelConfirming (Parti off), not TravelStarted/TravelFailed (no close)"

patterns-established:
  - "_numberRow(context, label, value, {int maxLines = 1, Color? valueColor})"

requirements-completed: []  # mark-complete forbidden here; FOOD-01/03/04 advanced, traceability in 15-09

duration: 12min
completed: 2026-11-05
---

# Phase 15 Plan 05: Food and life rows on the travel confirmation sheet Summary

**`TravelConfirmationSheet` shows the BE food list («1x Razione da viaggio, 1x Mela selvatica» / «nessuno», up to 3 lines) and the life lost («−136 HP» / «nessuna perdita») under «Arrivo»; on `arrivesAlive: false` the «Vita» row reads «Non hai cibo a sufficienza per il viaggio» in `bloodRed` with no number and «Parti» is disabled; the sheet stays open on the last numbers through `TravelRequoting`; the stale «nessun costo» notes are gone from the doc comment and `docs/rules/ui-ux.md`.**

## Performance

- Duration: ~12 min
- Tasks: 2/2
- Files modified: 3 (1 lib, 1 test, 1 doc)

## Accomplishments

- `travel_confirmation_sheet.dart`: imports `models/travel/travel_cost_text.dart`; `typedef _TravelNumbers = ({String distance, String duration, String? arrival, String food, String life, bool isStarving})`; `_numbersOf` fills `food: foodText(preview.food, empty: _noFoodText)`, `life: lifeText(preview)`, `isStarving: !preview.arrivesAlive`; state constants `_foodMaxLines = 3`, `_lifeMaxLines = 2`, `_noFoodText = 'nessuno'`; `_numberRow(BuildContext context, String label, String? value, {int maxLines = 1, Color? valueColor})` with style `bodyMedium?.copyWith(color: value == null ? darkBronze : valueColor)` (placeholder style unchanged; `copyWith(color: null)` keeps bodyMedium); rows «Cibo» (maxLines 3) and «Vita» (maxLines 2, `bloodRed` when `isStarving`) after «Arrivo»; «Parti» `onPressed: state is TravelConfirming && state.preview.arrivesAlive ? … : null`. Class doc rewritten as the plan prescribes (15-CONTEXT D-02, D-03). The widget never reads `hpLost` (FOOD-04).
- `docs/rules/ui-ux.md` travel confirmation bullet rewritten (cibo consumato e vita persa, red «Vita», «Parti» spento, sheet open on starving refusal).

## Task Commits

1. Task 1 RED `ee53cff` test(travel): expect food and life rows on the confirmation sheet; GREEN `ae2139b` feat(travel): show food and life lost on the confirmation sheet
2. Task 2 RED (green at first run) `b590ad5` test(travel): expect the sheet to survive a starving requote; REFACTOR `a776a5e` refactor(travel): document the food rows of the confirmation sheet; DOCS `f0a0837` docs(phase-15): describe the food rows of the travel sheet

## RED failures observed

- Task 1 (8 red, 16 green): «shows the destination at once with five subtle placeholders (D-02)» → `Expected: exactly 5 matching candidates  Actual: Found 3 widgets with text "…"`; «labels the food and life rows under «Arrivo» (D-02)» → `Bad state: No element` (no «Cibo»); food / «nessuno» / «−136 HP» / «nessuna perdita» / red phrase tests → `Found 0 widgets with text …`; «wraps a long food list on up to three lines (D-10)» → `Bad state: No element`.
- Task 2: all 4 tests green at first run, as the plan expected, because of 15-04's state design: «stays open on a starving refusal with the last numbers and Parti disabled (D-03)» (the close listener keys on `TravelStarted`/`TravelFailed` only; `_numbersOf` matches `TravelQuote`, so numbers stay; «Parti» requires `TravelConfirming`); «shows the refreshed numbers once the requote answers (D-03)» (the new `TravelConfirming` rebuilds the rows; the Task 1 gate keeps «Parti» off on the starving preview); «Resta during a requote cancels and closes the sheet (D-03)» (`canPop` is `state is! TravelStarting`, «Resta» enabled outside Starting); «every other start refusal still closes the sheet (D-03)» (`TravelFailed` closes). No widget code change was needed; the REFACTOR commit only rewrote the doc comment.

## Tests added

- `travel_confirmation_sheet_test.dart`: pinned test retitled «shows the destination at once with five subtle placeholders (D-02)» (`findsNWidgets(5)`); 7 Task 1 tests (D-02, D-10, D-11); group `'starving requote'` with 4 tests (D-03). Local helpers: `confirmingAbout(TravelPreview quote)`, `previewWith({food, hpLost, arrivesAlive})`, `valueText(tester, value)` (the `AutoSizeText` ancestor of a text), `starvingPreview()` inside the group. New imports: `auto_size_text`, `theme/kg_theme.dart`, `models/travel/travel_cost_text.dart`. File: 28 tests.

## Verification

- `flutter test test/screens/mainScreen/tabs/map` → `+228: All tests passed!` (Task 1); `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/components` → `+368: All tests passed!` (Task 2).
- Analyzer last line `50 issues found.` (all info), `ANALYZE_GATE_OK` after each code task.
- Acceptance greps: `'Cibo'` 1, `'Vita'` 1, `preview.arrivesAlive` 2, `lifeText(preview)` 1, `foodText(preview.food` 1, `hpLost` 0, `findsNWidgets(5)` 1, `D-(02|10|11)\)` 8, `D-03)` 4, «nessun costo» in lib + docs/rules: none, `cibo consumato e vita persa` 1, `15-CONTEXT D-02` 1.
- `dart format` on the two Dart files, one by one: new code only, no reflow of untouched members.

## Deviations from Plan

1. [Rule 1 - test bug] «Resta during a requote cancels and closes the sheet (D-03)» first used `tester.tap(find.byKey(stayKey))`: with five rows the sheet in the 360 px landscape harness puts «Resta» off-screen (`Offset(292.9, 445.0) is outside … Size(780.0, 360.0)`), so the tap missed. Switched to `stayButton(tester).onPressed!()`, the pattern the existing «tapping Resta cancels and closes the sheet» already uses. Widget unchanged (on device `PaperSheetModal` scrolls). Fixed before the Task 2 test commit.
2. The `_noFoodText` doc comment written in Task 1 as `(15-CONTEXT D-02)` made the Task 2 grep `15-CONTEXT D-02` count 2; it was shortened to `(D-02)` in the refactor commit `a776a5e`.

## Known Stubs

None (copy «nessuno» is provisional per D-02/D-06, not a stub).

## Threat Flags

None (T-15-13 «Parti» gate, T-15-14 maxLines 3/2, T-15-15 no `hpLost` in the widget — all covered by the tests and greps above).

## Self-Check: PASSED
