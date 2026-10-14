---
phase: 02-character-creation
plan: 08
subsystem: character-creation
tags: [cubit, bloc-test, tdd, submit]
requires: [02-07]
provides:
  - CharacterCreationCubit.submit() with upload-then-mutation and URL reuse keyed by local path
  - CHARACTER_ALREADY_EXISTS recovery via fetchCurrentUser (createdUser exposed, notice only if the re-read fails)
affects: [02-09]
key-files:
  modified:
    - lib/screens/characterCreation/cubit/character_creation_cubit.dart
    - test/screens/characterCreation/cubit/character_creation_cubit_test.dart
key-decisions:
  - "On success isSubmitting stays true so the form stays locked until the gate adopts createdUser"
  - "Broad catch in submit maps unexpected errors to unknown so the spinner can never get stuck"
  - "alreadyExists re-reads me; a user without a character or a failing re-read falls back to the alreadyExists notice"
requirements-completed: []  # CHAR-05/07/09 close with the screen plan (02-09); this plan delivers the cubit logic only
duration: 15min
completed: 2026-10-09
---

# Phase 2 Plan 08: Cubit submit Summary

submit() uploads the portrait first, reuses the uploaded URL only for the same local file, sends the mutation, and recovers from CHARACTER_ALREADY_EXISTS by re-reading `me`.

## Commits
- 71d92fb test: failing tests for submitting the character
- fc7a38d feat: submit with upload-then-mutation
- 5facc5d test: failing tests for the already-exists recovery
- fa42feb feat: recover an existing character instead of stranding the user

## Deviations from Plan
- [Rule 3] The unused `create_character_request.dart` import in the test file was removed (analyzer would have exceeded the 12 baseline); folded into the last feat commit.
- In the RED step for Task 2 only the adoption test failed; the fallback, no-re-read and close-safety tests already held with the Task 1 implementation (they pin existing behavior).

## Verification
- `flutter test`: 425 passed (408 baseline + 17 new)
- `flutter analyze lib test`: 12 issues (baseline)
- `dart format --set-exit-if-changed` clean on the 2 touched files

## Known Stubs
None.

## Self-Check: PASSED
