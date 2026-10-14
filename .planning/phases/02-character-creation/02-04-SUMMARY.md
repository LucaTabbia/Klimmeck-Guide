---
phase: 02-character-creation
plan: 04
subsystem: character-creation
tags: [theme, widget, portrait, tdd]
requires: []
provides:
  - KlimmeckGuideTheme.spacingXs/Sm/Md/Lg/Xl (4/8/16/24/32)
  - materialTheme.inputDecorationTheme (parchment sheet fields, errorStyle = errorText)
  - materialTheme.chipTheme (gold selected, parchment, bronze border)
  - CharacterPortrait widget + CharacterPortrait.resolve (local file, remote URL, silhouette)
affects: [02-05, 02-06, 02-07, 02-08, 02-09]
key-files:
  created:
    - lib/shared/components/character_portrait.dart
    - test/theme/kg_theme_test.dart
    - test/shared/components/character_portrait_test.dart
  modified:
    - lib/theme/kg_theme.dart
key-decisions:
  - "Field/chip look lives only in the theme (D-06, D-32); no existing screen uses TextField or ChoiceChip so nothing changes visually"
  - "Portrait fallback decided in one place (D-14): FileImage, then CachedNetworkImageProvider, then the bundled silhouette; errorBuilder falls back silently to the silhouette (T-02-04-01/02)"
requirements-completed: []  # CHAR-05 / CHAR-09 close with the screen plans that consume these building blocks
duration: 15min
completed: 2026-10-09
---

# Phase 2 Plan 04: Sheet theme tokens and portrait resolver Summary

Theme tokens (input decoration, chip theme, spacing scale) and the single `CharacterPortrait` resolver with silhouette fallback, so later plans build the sheet with no inline styles or fallback logic.

## Commits
- 2098423 test(character-creation): add failing tests for the sheet theme tokens
- a0044ec feat(character-creation): add sheet tokens for fields, chips and spacing
- 0862c07 test(character-creation): add failing tests for the portrait resolver
- 5a704cb feat(character-creation): add the character portrait resolver

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Theme test needs the test binding and a widget-test zone**
- **Found during:** Task 1 GREEN
- **Issue:** `KlimmeckGuideTheme.instance` loads Google Fonts; in a plain `test` this fails (no binding / font asset lookup).
- **Fix:** the theme tests are `testWidgets` and create the instance lazily after `allowRuntimeFetching = false`.
- **Files modified:** test/theme/kg_theme_test.dart
- **Commit:** a0044ec

**2. [Rule 3 - Blocking] `InputDecorationThemeData` type**
- On Flutter 3.35 `ThemeData.inputDecorationTheme` is `InputDecorationThemeData`; the test uses that type.

Otherwise the plan was executed as written.

## Verification
- `flutter test`: 341 passed (328 baseline + 13 new)
- `flutter analyze lib test`: 12 issues (unchanged baseline)
- Format check clean on touched files only
- Widget tests do not use `pumpAndSettle`

## Known Stubs
None.

## Self-Check: PASSED
