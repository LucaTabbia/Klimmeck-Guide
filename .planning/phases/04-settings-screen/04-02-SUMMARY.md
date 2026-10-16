---
phase: 04-settings-screen
plan: 02
subsystem: ui
tags: [flutter, theme, dialog, destructive-actions]
requires: []
provides:
  - materialTheme.switchTheme (gold/bronze on, wood/parchment off, silver disabled)
  - KlimmeckGuideTheme.destructiveButtonStyle and destructiveOutlinedButtonStyle
  - DestructiveConfirmationDialog + showDestructiveConfirmation
  - showDeleteCharacterConfirmation(context, characterName:)
affects: [04-06 (Settings tab uses switches, Esci, Elimina personaggio), 04-07]
tech-stack:
  added: []
  patterns: [theme tokens instead of per-widget colours, one shared bool-returning dialog on the root Navigator]
key-files:
  created:
    - lib/shared/components/modal/destructive_confirmation_dialog.dart
    - lib/shared/components/modal/delete_character_confirmation_dialog.dart
    - test/shared/components/modal/destructive_confirmation_dialog_test.dart
    - test/shared/components/modal/delete_character_confirmation_dialog_test.dart
  modified:
    - lib/theme/kg_theme.dart
    - test/theme/kg_theme_test.dart
    - lib/shared/components/modal/logout_confirmation_dialog.dart
key-decisions:
  - "Logout dialog is now a thin wrapper over DestructiveConfirmationDialog; its original test file is untouched and green"
requirements-completed: []
duration: ~10 min
completed: 2026-10-16
---

# Phase 4 Plan 02: Theme tokens and shared destructive dialog Summary

Switch theme and two destructive button styles live in `kg_theme.dart`; logout and character deletion share one non-dismissible `DestructiveConfirmationDialog` that returns a bool and reads no cubit.

## Commits
- test(theme): add failing tests for switch and destructive button styles (RED)
- feat(theme): add switch theme and destructive button styles (GREEN)
- test(ui): add failing tests for the shared destructive confirmation dialog (RED)
- refactor(ui): share the destructive confirmation dialog with logout and deletion (GREEN)

## Results
- Tests: 661 -> 675 (+14), all green. `flutter analyze`: 57 issues (baseline, 0 errors); touched files: no issues; touched files formatter-clean.
- `logout_confirmation_dialog_test.dart` unchanged and green.
- Requirements SET-02/03/05 are not ticked here: plan 04-07 owns traceability.

## Deviations from Plan
None - plan executed exactly as written.

## Known Stubs
None.

## Self-Check: PASSED
