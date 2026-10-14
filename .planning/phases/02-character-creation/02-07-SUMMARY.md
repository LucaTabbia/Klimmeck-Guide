---
phase: 02-character-creation
plan: 07
subsystem: character-creation
tags: [repository, cubit, bloc-test, tdd]
requires: [02-03, 02-05, 02-06]
provides:
  - CharacterCreationRepository (loadRaceTraits, pickPortrait, uploadPortrait, createCharacter, fetchCurrentUser) with only typed failures escaping
  - CharacterCreationCubit editing half (race traits load + retry, field edits, portrait pick/remove, form lock while submitting)
  - CharacterCreationState with derived nameError/ageError/isAgeEnabled/canSubmit, UploadedPortrait, RaceTraitsStatus
  - MockCharacterCreationRepository
affects: [02-08, 02-09]
key-files:
  created:
    - lib/repository/character_creation_repository.dart
    - lib/screens/characterCreation/cubit/character_creation_cubit.dart
    - lib/screens/characterCreation/cubit/character_creation_state.dart
    - test/repository/character_creation_repository_test.dart
    - test/screens/characterCreation/cubit/character_creation_cubit_test.dart
  modified:
    - test/helpers/mocks.dart
key-decisions:
  - "Validation errors are derived getters on the state, never stored: a race change re-validates the typed age without clamping (D-10)"
  - "loadRaceTraits ends in RaceTraitsStatus.failed on any error (generic catch) so loading can never hang; retry re-enters loading"
  - "Picking a portrait only stores the local path; no upload before submit (D-16)"
requirements-completed: []  # CHAR-02/03/04/05/08 close with the screen plans; this plan delivers the cubit/repository layer only
duration: 25min
completed: 2026-10-09
---

# Phase 2 Plan 07: Repository and cubit editing Summary

One repository hides facade, REST and picker behind domain failures, and one cubit state drives every field, the age gating and the local portrait preview.

## Commits
- 3f5e805 test: failing tests for the creation repository
- 4b9cc0b feat: creation repository
- 29bc1cc test: failing tests for the creation cubit editing
- 029913d feat: creation cubit editing actions

## Deviations from Plan
- [Rule 1 - Test bug] Mocktail `thenThrow` on a Future-returning mock throws synchronously, so the picker propagation test used `thenAnswer((_) async => throw ...)`. Same pattern in the cubit tests.
- [Rule 1 - Test bug] `Cubit` always emits its first state even if equal to the initial one (`_emitted` flag), so blocTest cases that start from the default state use `seed: () => const CharacterCreationState()` to expect only distinct states.
- Cubit uses a bare `catch (_)` in `loadRaceTraits` as the plan prescribed (T-02-07-02); repository tests cover the typed paths, the cubit test covers an unexpected `StateError`.

## Verification
- `flutter test`: 408 passed (379 baseline + 29 new)
- `flutter analyze lib test`: 12 issues (baseline)
- `dart format --set-exit-if-changed` clean on touched files only; no `package:flutter/` import in the new lib files; no `uploadPortrait` call in the cubit

## Known Stubs
None. Submit flow (upload, createCharacter, createdUser) is plan 08; the state fields exist but are unused until then.

## Self-Check: PASSED
