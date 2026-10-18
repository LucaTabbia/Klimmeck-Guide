---
phase: 04-settings-screen
plan: 06
subsystem: settings-ui
tags: [flutter, widgets, settings, notifications, character-deletion, logout]
requires: [04-01, 04-02, 04-03, 04-04, 04-05]
provides:
  - SettingsSection (titled section container)
  - NotificationPreferencesSection (three themed SwitchListTiles bound to NotificationPreferencesCubit, inert until loaded)
  - AccountSection (Elimina personaggio with confirm, in-button progress, inline domain error; Esci via confirmLogout as last element)
  - CharacterDeletionFailureMessage (fixed Italian copy per failure code)
  - Settings tab (parchment sheet, title, character name header, 120 px satchel clearance) as MainScreen page 6
  - MockNotificationPreferencesCubit, MockCharacterDeletionCubit in test/helpers/mocks.dart
affects: [04-07]
tech-stack:
  added: []
  patterns: [cubit read before await across a root-navigator dialog; page count guarded by assert against SatchelLayout.entries]
key-files:
  created:
    - lib/screens/mainScreen/tabs/settings/settings.dart
    - lib/screens/mainScreen/tabs/settings/components/settings_section.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
    - lib/screens/mainScreen/tabs/settings/components/account_section.dart
    - lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart
    - test/screens/mainScreen/tabs/settings/settings_test.dart
    - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
    - test/screens/mainScreen/tabs/settings/components/account_section_test.dart
  modified:
    - lib/screens/mainScreen/main_screen.dart
    - test/helpers/mocks.dart
key-decisions:
  - "Hand-over of deletedUser stays in AuthenticatedShell (plan 05); the tab does not listen"
  - "No main_screen_test case for page 6 (accepted plan-check note, see below)"
requirements-completed: []
duration: ~25 min
completed: 2026-10-16
---

# Phase 4 Plan 06: Settings tab UI Summary

The Settings tab is now the seventh MainScreen page: a parchment sheet with the character name, three themed notification switches, a confirmed character deletion with in-button progress and code-based inline errors, and a logout button as the last scrollable element.

## Commits
- c75396c test(settings): add failing tests for the notification switches (RED)
- f6b493c feat(settings): add the notification switches section
- 6edc465 test(settings): add failing tests for the account section (RED)
- b7f446a feat(settings): add the account section with deletion and logout
- 7bd4fd3 test(settings): add failing tests for the settings tab (RED)
- d2ae733 feat(settings): add the settings tab as the seventh page

## Verification
- `flutter test`: 738 before, 759 after (+21 widget tests across the three new files), all green.
- `flutter analyze`: 57 issues (pre-existing baseline), 0 errors; all touched files "No issues found!".
- Touched files are formatter-clean by explicit path; no directory format run. `lib/screens/characterCreation/**` untouched (D-03).

## Accepted plan-check note (SET-01 at MainScreen level)
No `main_screen_test.dart` case is added for page 6: `MainScreenLoadData` mounts `WorldMap` (`flutter_map` network tiles, no fake tile provider in the test helpers). The wiring is guarded by the `pages.length == SatchelLayout.entries.length` assert in `_buildPages` (page order = `SatchelEntry.pageIndex`), by the plan 01 menu tests (`satchel_layout_test.dart`, `menu_background_test.dart`: tapping "Impostazioni" emits 6) and by the UAT of plan 07.

## Deviations from Plan

**1. [Rule 3 - Blocking] Mocks not present**
- **Found during:** Task 1
- **Issue:** the objective listed `MockNotificationPreferencesCubit`/`MockCharacterDeletionCubit` as existing; they were not in `test/helpers/mocks.dart` (the plan's Task 1 adds them, as specified).
- **Fix:** added in the Task 1 RED commit (c75396c).

**2. [Rule 1 - Bug, test-only] Wrong import path and a leftover helper in the RED settings test**
- **Found during:** Task 3 GREEN
- **Issue:** the RED test imported `models/character.dart` (real path `models/character/character.dart`) and referenced a removed `top` helper.
- **Fix:** corrected in the GREEN commit (d2ae733); test assertions unchanged in strength.

Otherwise none: plan executed as written.

## Known Stubs
None.

## Threat Flags
None. T-04-06-01..04 mitigations are implemented and tested (confirmation before deletion, disabled button while deleting, fixed domain copy, `confirmLogout` unchanged, inert switches without spinner).

## Self-Check: PASSED

- Created files exist (settings.dart, four components, three test files); modified main_screen.dart and mocks.dart.
- Commits c75396c, f6b493c, 6edc465, b7f446a, 7bd4fd3, d2ae733 present on `feat/04-settings-screen`; no `Co-Authored-By` trailer.
- `flutter test` 759 green, `flutter analyze` 57 issues / 0 errors.
