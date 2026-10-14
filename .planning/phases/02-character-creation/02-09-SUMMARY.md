---
phase: 02-character-creation
plan: 09
subsystem: character-creation
tags: [screen, widget, parchment-sheet, tdd, italian-copy]
requires: [02-01, 02-02, 02-04, 02-08]
provides:
  - CharacterCreationScreen (single landscape page, BlocListener -> AuthCubit.adoptUser, Esci -> confirmLogout)
  - PortraitColumn, SubmitBar, SheetRow, EnumChoiceRow, SheetTextField
  - character_creation_messages.dart (Italian copy for NameError, AgeError, CharacterCreationFailure, PortraitPickFailure)
  - MockCharacterCreationCubit, MockAuthCubit
affects: [02-10]
key-files:
  created:
    - lib/screens/characterCreation/character_creation_screen.dart
    - lib/screens/characterCreation/components/character_creation_messages.dart
    - lib/screens/characterCreation/components/sheet_row.dart
    - lib/screens/characterCreation/components/enum_choice_row.dart
    - lib/screens/characterCreation/components/sheet_text_field.dart
    - lib/screens/characterCreation/components/portrait_column.dart
    - lib/screens/characterCreation/components/submit_bar.dart
    - test/screens/characterCreation/character_creation_screen_test.dart
    - test/screens/characterCreation/components/character_creation_messages_test.dart
    - test/screens/characterCreation/components/sheet_components_test.dart
    - test/screens/characterCreation/components/portrait_column_test.dart
    - test/screens/characterCreation/components/submit_bar_test.dart
  modified:
    - test/helpers/mocks.dart
key-decisions:
  - "SheetTextField owns its controller (initialValue read once), so typed text survives every error rebuild (CHAR-08/09)"
  - "PortraitColumn is a LayoutBuilder + SingleChildScrollView with a clamped portrait height: it scrolls instead of overflowing when the keyboard is open"
  - "Age helper precedence: known traits -> range; failed -> only the inline retry row; no race -> 'Scegli prima la razza'; race but traits loading -> 'Consulto le cronache delle razze…'"
  - "Crea sits at the end of the scroll column (not pinned) because the landscape keyboard leaves very little height"
requirements-completed: [CHAR-02, CHAR-03, CHAR-04, CHAR-05, CHAR-08, CHAR-09]  # CHAR-07 (and CHAR-01) close with 02-10 once the screen is wired into the app
duration: 40min
completed: 2026-10-09
---

# Phase 2 Plan 09: Character creation screen Summary

The provisional parchment character sheet: one landscape page with portrait column and Italian choice-chip rows, inline errors, Crea with its own progress, Esci via the shared logout dialog, and `createdUser` handed to `AuthCubit.adoptUser`.

## Commits
- test(character-creation): add failing tests for the sheet copy and components
- feat(character-creation): add the sheet copy and form components
- test(character-creation): add failing tests for the portrait column and the submit bar
- feat(character-creation): add the portrait column and the submit bar
- fix(character-creation): let the portrait column scroll instead of overflowing
- test(character-creation): add failing tests for the character creation screen
- feat(character-creation): add the character creation screen

## Deviations from Plan

**1. [Rule 1 - Bug] PortraitColumn overflowed at 780x360**
- **Found during:** Task 2 GREEN (and anticipated for the keyboard-open screen test)
- **Issue:** the plan's `Column` + `Flexible` layout overflowed when the buttons wrapped or the pick-failure text was long, and would overflow with the keyboard open.
- **Fix:** `LayoutBuilder` + `SingleChildScrollView`, portrait height clamped between 80 and 240 from the available height; tighter padding (spacingMd), compact buttons with a 44 dp minimum.
- **Commit:** fix(character-creation): let the portrait column scroll instead of overflowing

**2. [Rule 1 - Test bug]** `TextButton.icon` builds a private subclass, so `find.byType(TextButton)` misses it; the test uses a `byWidgetPredicate`. The Rimuovi tap uses `ensureVisible` because the column can scroll.

**3. [Rule 3]** Removed two unused imports from the screen test to stay at the 12-issue analyzer baseline.

## Verification
- `flutter test`: all green (425 baseline + new component and screen tests)
- `flutter analyze lib test`: 12 issues (baseline)
- `dart format --set-exit-if-changed` clean on touched files only
- No `Color(0x`, `fontSize:`, `fontFamily:`, `KgLoader`, `showDialog`, `Navigator.push` in `lib/screens/characterCreation/`; the only `repository/` imports in the UI are domain enums (failure/picker types), no service calls

## Known Stubs
None. The screen is not yet reachable from `main.dart`; wiring is plan 02-10.

## Self-Check: PASSED
