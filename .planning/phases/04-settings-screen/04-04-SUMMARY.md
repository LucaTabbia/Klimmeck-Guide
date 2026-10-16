---
phase: 04-settings-screen
plan: 04
subsystem: character-deletion
tags: [flutter, graphql, repository, cubit, character-deletion]
requires: []
provides:
  - CharacterMutations.deleteCharacter (argument-less `mutation DeleteCharacter { deleteCharacter { ...UserFields } }`) listed in schemaCheckDocuments
  - KlimmeckGraphQl.deleteCharacter()
  - CharacterDeletionFailure + CharacterDeletionException + characterDeletionFailureFrom (mapping by extensions.code only)
  - CharacterDeletionRepository (deleteCurrentCharacter, fetchCurrentUser)
  - CharacterDeletionCubit (in-flight guard, CHARACTER_NOT_FOUND refetch, handoverRejected, SafeEmit)
  - MockCharacterDeletionRepository
affects: [04-05 (shell-level BlocListener to AuthCubit.adoptUser), 04-06, 04-07 (schema check against BE schema, SET-05 traceability)]
tech-stack:
  added: []
  patterns: [exact mirror of the character creation path (_guard, failure enum, hand-over via state)]
key-files:
  created:
    - lib/repository/character_deletion_failure.dart
    - lib/repository/character_deletion_repository.dart
    - lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart
    - lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_state.dart
    - test/graphql/character_deletion_document_test.dart
    - test/repository/services/graphql/graphql_character_deletion_test.dart
    - test/repository/character_deletion_failure_test.dart
    - test/repository/character_deletion_repository_test.dart
    - test/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit_test.dart
  modified:
    - lib/graphql/mutations/character_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/helpers/mocks.dart
key-decisions:
  - "Deletion carries no arguments or variables: identity from the bearer only (BE 03.1)"
  - "Errors mapped by extensions.code only; UNAUTHENTICATED constant reused from auth_api_exception.dart"
  - "isDeleting stays true after success; the shell listener (plan 05) hands deletedUser to AuthCubit.adoptUser"
requirements-completed: []
duration: ~15 min
completed: 2026-10-16
---

# Phase 4 Plan 04: Character deletion data path Summary

Test-first Service -> Repository -> Cubit path for `deleteCharacter`: argument-less mutation listed for the schema check in the same commit, code-mapped failures, and a cubit with in-flight guard, CHARACTER_NOT_FOUND recovery via `me` refetch and a hand-over state ready for `adoptUser` (wired in plan 05).

## Commits
- 1315905 test(graphql): add failing tests for the DeleteCharacter mutation (RED)
- ff64544 feat(graphql): add the DeleteCharacter mutation (GREEN; document + schema-check listing + service method)
- 4880f43 test(settings): add failing tests for character deletion failures and repository (RED)
- 9ac4731 feat(settings): map character deletion errors in a repository (GREEN)
- 7da25a4 test(settings): add failing tests for the character deletion cubit (RED)
- 87066a1 feat(settings): add the character deletion cubit (GREEN)

## Verification
- `flutter test`: 698 before, 732 after, all green (34 new tests), including `test/tool/schema_check_documents_test.dart`.
- `flutter analyze`: 57 issues (pre-existing baseline), 0 errors; all touched files clean.
- Touched files verified with `dart format --output=none --set-exit-if-changed` by explicit path.

## Deviations from Plan
None - plan executed as written. (The RED commit for task 2 leaves `test/helpers/mocks.dart` importing a not-yet-existing repository file, as expected for RED; fixed by the GREEN commit.)

## Known Stubs
None.

## Threat Flags
None.

## Self-Check: PASSED

- Key files exist on disk: `lib/graphql/mutations/character_mutations.dart` (DeleteCharacter), `lib/repository/character_deletion_failure.dart`, `lib/repository/character_deletion_repository.dart`, `lib/screens/mainScreen/tabs/settings/deletionCubit/` — verified by the orchestrator 2026-10-16.
- Commits 1315905, ff64544, 4880f43, 9ac4731, 7da25a4, 87066a1 present on `feat/04-settings-screen`; no `Co-Authored-By` trailer.
- `flutter test` 732 green, `flutter analyze` 57 issues / 0 errors (executor report).
