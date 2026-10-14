---
phase: 02-character-creation
plan: 06
subsystem: graphql
tags: [graphql, fragments, error-mapping, facade]
requires: [02-03]
provides:
  - UserFragment (UserFields) shared by GetMe and AuthSessionFields
  - CharacterMutations.createCharacter (CreateCharacter), CharacterQueries.getRaceTraits (GetRaceTraits)
  - CharacterCreationFailure, CharacterCreationException, characterCreationFailureFrom (pure mapper, both error paths)
  - KlimmeckGraphQl({resolveClient}), getRaceTraits(), createCharacter(request), getMe()
affects: [02-07, 02-11]
key-files:
  created:
    - lib/graphql/fragments/user_fragment.dart
    - lib/repository/character_creation_failure.dart
    - test/graphql/character_creation_documents_test.dart
    - test/repository/character_creation_failure_test.dart
    - test/repository/services/graphql/graphql_character_creation_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - lib/graphql/fragments/auth_session_fragment.dart
    - lib/graphql/queries/auth_queries.dart
    - lib/graphql/queries/character_queries.dart
    - lib/graphql/mutations/character_mutations.dart
    - lib/repository/services/graphql/graphql.dart
key-decisions:
  - "Mapper reads only extensions.code from graphqlErrors then ServerException.parsedResponse; messages never used"
  - "Facade throws raw OperationException / FormatException; mapping happens in the repository (plan 07)"
  - "KlimmeckGraphQl resolveClient defaults to the navigatorKey lookup, existing callers unchanged"
requirements-completed: []  # CHAR-03/07/09 close with the repository and screen plans
duration: 20min
completed: 2026-10-09
---

# Phase 2 Plan 06: GraphQL documents, error mapper and facade Summary

Documents, a pure code-to-failure mapper and an injectable facade now cover the BE 2.1 creation contract.

## Commits
- 9ef3e35 test: failing tests for the documents
- d9ee9fc feat: create-character and race-traits documents
- bc61a2b test: assert the variable type on the parsed node
- 30eb1eb refactor: share the user selection through UserFields
- 02bef3a test: failing tests for the error mapper
- d90ef6a feat: map backend creation codes to domain failures
- 3c7769f test: failing tests for the facade methods
- 5ca6495 refactor: compose the auth session fragment by interpolation
- 2c9ab1c feat: creation operations in the GraphQL facade

## Schema check (D-33)
BE `src/schema.gql` already contains the contract: `createCharacter(input: CreateCharacterInput!): User!`, `raceTraits: [RaceTraits!]!`, `CreateCharacterInput` (age, background, classType, imagePath, name, pronoun, race, sex) and `RaceTraits { maxAge minAge race }`. Documents and `CreateCharacterRequest.toJson()` match; no divergence. `currentCharacter { id }` only, as agreed.

## Deviations
- [Rule 1 - Bug] My first document test compared `NamedTypeNode.toString()`; fixed to assert `name.value` and `isNonNull` (bc61a2b). The GREEN commit d9ee9fc therefore had that one test failing.
- [Rule 1 - Lint] Plan's `'''...''' + UserFragment.definition` in AuthSessionFragment triggered `prefer_interpolation_to_compose_strings`; switched to interpolation (5ca6495). Same for nothing else: the `+` style remains in AuthQueries/CharacterMutations (const concatenation, matches AuthMutations, not flagged).

## Verification
- `flutter test`: 379 passed (354 baseline + 25 new)
- `flutter analyze lib test`: 12 issues (baseline)
- `dart format` only on touched files; the directory-wide check is not clean because of the known baseline

## Known Stubs
None.

## Self-Check: PASSED
