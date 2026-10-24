---
phase: 06-quest-accept-info-sheets
plan: 08
subsystem: satchel
tags: [satchel, board, availability, widget-test, tdd]
requires: [06-02]
provides:
  - disabledSatchelPages policy (FE Phase 7 extends it with activeTravel)
  - SatchelLayout.boardPageIndex, KlimmeckGuideTheme.disabledScrim
  - isEnabled on MenuSection / MenuItem, disabledPages on MenuBackground / SatchelMenu
  - MainScreen BlocSelector wiring and onItemTap guard
affects: [06-09, Phase 7]
key-files:
  created:
    - lib/screens/mainScreen/components/satchel_availability.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
  modified:
    - lib/screens/mainScreen/components/satchel_layout.dart
    - lib/theme/kg_theme.dart
    - lib/screens/mainScreen/components/menu_section.dart
    - lib/screens/mainScreen/components/menu_background.dart
    - lib/screens/mainScreen/components/menu_item.dart
    - lib/screens/mainScreen/components/satchel_menu.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/components/menu_background_test.dart
    - test/screens/mainScreen/components/menu_item_test.dart
    - test/screens/mainScreen/components/satchel_menu_test.dart
    - test/screens/mainScreen/main_screen_test.dart
decisions:
  - "MainScreen gets a @visibleForTesting pagesBuilder so the satchel wiring test does not need the providers of the real tabs"
metrics:
  tasks: 2
  tests: "1271 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 08: Board disabled outside a city Summary

The Bacheca entry of the satchel is darkened (grid cell scrim) and dimmed (flying icon) and ignores taps whenever the character is not on a city marker; `MainScreen.onItemTap` refuses a disabled page as a second line of defence (D-11, D-13).

## Commits

- a6cbbc7 feat(satchel): decide which satchel pages are reachable
- baa546f test(satchel): add failing tests for the disabled board entry (RED: missing `disabledPages` / `isEnabled` parameters)
- 9d968b8 feat(satchel): disable the board outside a city marker

The Task 1 RED commit is `test(satchel): add failing tests for the satchel availability policy` (compile failure on the missing library).

## Deviations from Plan

**1. [Rule 3 - Blocking] `MainScreen.pagesBuilder` (@visibleForTesting)** The mandatory "satchel wiring" tests pump the real `MainScreen`, whose real tabs (WorldMap, Shop, ...) need many cubits and the map stack. An optional builder replaces the tabs in tests only; production behaviour is unchanged (default `_buildPages`).

**2. Test timing:** tickers start on the first frame, so the satchel tests pump once after tapping the pouch before advancing time; the parent `AnimationController` in tests needs a duration.

## Known Stubs

None. The scrim and the 0.4 opacity are provisional visuals (D-19).

## Self-Check: PASSED
