---
phase: 02-character-creation
plan: 10
subsystem: character-creation
tags: [routing, wiring, composition-root, profile-portrait, tdd]
requires: [02-02, 02-04, 02-09]
provides:
  - SessionHome (null-check branch creation vs shell, D-01)
  - AuthenticatedShell(characterId) and MainScreen(characterId), hardcoded id removed (D-27)
  - main.dart composition of CharacterCreationScreen with real dependencies
  - ProfileImage(imagePath) rendered through CharacterPortrait (D-14)
  - MockCharacterCubit, MockQuestCubit, MockMainScreenCubit
affects: []
key-files:
  created:
    - lib/screens/auth/session_home.dart
    - test/screens/auth/session_home_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/tabs/profile/components/profile_image_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/main_screen.dart
    - lib/main.dart
    - lib/screens/mainScreen/tabs/profile/components/profile_image.dart
    - lib/screens/mainScreen/tabs/profile/profile.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/helpers/mocks.dart
key-decisions:
  - "SessionHome holds only the currentCharacter null check; main.dart stays the composition root"
  - "ProfileImage has no fallback logic: CharacterPortrait owns it (D-14); unused File? image param removed"
requirements-completed: [CHAR-01, CHAR-07]
duration: ~25min
completed: 2026-10-09
---

# Phase 2 Plan 10: Wiring Summary

Users without a character land on the creation sheet, character owners enter a shell that loads their own character id, and the profile shows the portrait via the shared resolver.

## Commits
- e4ba95c test: failing tests for the session home branch
- b8d7085 feat: add the session home branch
- 4474642 test: failing tests for loading the real character
- 45f1ade fix: route by character and load the session character in the shell
- 12d9c1e test: failing tests for the profile portrait
- cc5ca03 feat: show the character portrait in the profile

## Deviations from Plan
None of substance. Boy Scout in MainScreen.initState as planned (super.initState first, const Duration). Mock initial states use non-const constructors (CharacterInitial/QuestInitial have no const constructor).

CHAR-05 was closed by 02-09 and is not re-claimed here.

## Verification
- `flutter test`: 470 passed, 0 failed
- `flutter analyze lib test`: 12 issues (baseline)
- `grep -rn 68c191de541d89c481b8322b lib`: empty; no silhouette.jpeg in profile tab
- `flutter build apk --debug`: succeeded
- Not verified on device (dev bypass end-to-end).

## Known Stubs
None.

## Self-Check: PASSED
