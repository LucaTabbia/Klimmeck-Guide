---
phase: 04-settings-screen
plan: 01
subsystem: ui
tags: [flutter, satchel-menu, layout, settings]
requires: []
provides:
  - SatchelLayout table (labels, icons, page indices, grid cells, flight end-points)
  - Seven-entry satchel overlay with Impostazioni at page index 6
  - CloudinaryAssets.settings
affects: [04-06 (adds the Settings tab to MainScreen pages)]
tech-stack:
  added: []
  patterns: [single data table drives overlay cells and flying icons]
key-files:
  created:
    - lib/screens/mainScreen/components/satchel_layout.dart
    - test/screens/mainScreen/components/satchel_layout_test.dart
    - test/screens/mainScreen/components/menu_background_test.dart
    - test/screens/mainScreen/components/menu_item_test.dart
    - test/screens/mainScreen/components/satchel_menu_test.dart
  modified:
    - lib/config/cloudinary_assets.dart
    - lib/screens/mainScreen/components/menu_section.dart
    - lib/screens/mainScreen/components/menu_background.dart
    - lib/screens/mainScreen/components/menu_item.dart
    - lib/screens/mainScreen/components/satchel_menu.dart
key-decisions:
  - "Mappa cell has no bottom border so the horizontal divider never crosses its column"
  - "cellWidth shrinks to (width-152)/4 below 152 px so 667 px wide screens do not overflow"
requirements-completed: [SET-01]
duration: ~15 min
completed: 2026-10-16
---

# Phase 4 Plan 01: Satchel menu rework Summary

Satchel menu now shows seven entries (Mappa 1x2 on the left, 2x3 grid with Impostazioni at page 6) driven by one unit-tested `SatchelLayout` table that also computes every flying icon's landing point.

## Commits
- style(assets): format cloudinary_assets.dart
- test(menu): add failing tests for the satchel layout table (RED)
- feat(menu): add the satchel layout table with the settings entry (GREEN)
- test(menu): add failing tests for the seven-cell overlay (RED)
- feat(menu): render the satchel overlay from the layout table (GREEN)
- test(menu): add failing tests for satchel item landing points (RED)
- refactor(menu): land satchel items on their layout cells (GREEN)

## Results
- Tests: 645 -> 661 (+16), all green. `flutter analyze`: 57 issues (unchanged baseline, 0 errors); touched files: no issues; touched files formatter-clean.

## Deviations from Plan
None - plan executed exactly as written. Note: `MenuItem` keeps its start/apex maths; `menuImages` (dynamic map list) and the `index <= 2` branch were removed as planned.

## Known Stubs
None. Tapping Impostazioni has no page until plan 06 adds the Settings tab (as planned).

## Self-Check: PASSED
