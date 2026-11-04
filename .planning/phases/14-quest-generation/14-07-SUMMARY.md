---
phase: 14-quest-generation
plan: 07
subsystem: innkeeper
tags: [graphql, innkeeper, cubit, quest-generation, qgen-03, tdd]
requires:
  - 14-03 (registry at 43 documents)
provides:
  - "`GenerateQuests` mutation document, registered in the schema-check registry (44 documents)"
  - "`KlimmeckGraphQl.generateQuests()` returning the `created` count"
  - "`InnkeeperRepository.generateQuests()` through the shared `_guard` (15 s timeout, existing classifier)"
  - "`QuestGenerationCubit` (idle → submitting → succeeded{created} / failed{failure, serial}) and `MockQuestGenerationCubit`"
affects: [14-08, 14-10, 14-11]
tech-stack:
  added: []
  patterns: [UI → Cubit → Repository → Service, sealed Equatable states with a failure serial, SafeEmit]
key-files:
  created:
    - lib/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart
    - lib/screens/innkeeper/questGenerationCubit/quest_generation_state.dart
    - test/repository/services/graphql/graphql_generate_quests_test.dart
    - test/screens/innkeeper/questGenerationCubit/quest_generation_cubit_test.dart
  modified:
    - lib/graphql/mutations/quest_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/innkeeper_repository.dart
    - test/graphql/quest_mutations_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/tool/schema_check_documents_test.dart
    - test/repository/innkeeper_repository_test.dart
    - test/helpers/mocks.dart
decisions:
  - "`generateQuests()` guards the payload with `is Map<String, dynamic>` (not `as`), so a non-map payload is a FormatException like a missing `created`"
  - "No new failure code: the classifier `innkeeperFailureFrom` is untouched (A5, BE D-16 defines only FORBIDDEN)"
metrics:
  duration: ~20 min
  completed: 2026-11-04
  tasks: 3
  commits: 6
---

# Phase 14 Plan 07: Quest generation data path Summary

The data path of «Genera missioni» is in place. The `GenerateQuests` document has no arguments and selects `created`. It is registered in the schema-check registry, which now holds 44 documents. `KlimmeckGraphQl.generateQuests()` returns `created` and throws `FormatException` when it is missing. `InnkeeperRepository.generateQuests()` goes through `_guard`: 15 s timeout, `FORBIDDEN` → forbidden, link error → connection, malformed → malformed. `QuestGenerationCubit` runs one generation at a time and gives every failure its own serial. Everything is tested on mocks with the contract names of 14-REPO-RULES. No check runs against the BE schema in this plan; the BE repo was not touched or read.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | GenerateQuests document, registry (44), KlimmeckGraphQl.generateQuests | 102561c (test), 7cf2039 (feat) |
| 2 | InnkeeperRepository.generateQuests through _guard | 1020d70 (test), 6c73e8c (feat) |
| 3 | QuestGenerationCubit + MockQuestGenerationCubit | 744ff32 (test), ef6d5a1 (feat) |

## Exact names and signatures

- `QuestMutations.generateQuests` (`static const String`): `mutation GenerateQuests { generateQuests { created } }`.
- Registry: `'GenerateQuests': QuestMutations.generateQuests,` right after `'AbandonQuest'`; the doc comment says «la Phase 14 aggiunge `GenerateQuests`».
- `KlimmeckGraphQl.generateQuests()` → `Future<int>`; throws `OperationException` (via `_dataOrThrow`) or `FormatException('generateQuests.created missing')`.
- `InnkeeperRepository.generateQuests()` → `Future<int> generateQuests() => _guard(_graphQl.generateQuests);`
- `lib/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart`: `class QuestGenerationCubit extends Cubit<QuestGenerationState> with SafeEmit<QuestGenerationState>`, ctor `QuestGenerationCubit({required InnkeeperRepository repository})`, `Future<void> generate()` (returns early while `QuestGenerationSubmitting`), private `_failureSerial`.
- `quest_generation_state.dart` (part): `sealed class QuestGenerationState extends Equatable`; `QuestGenerationIdle()`, `QuestGenerationSubmitting()`, `QuestGenerationSucceeded({required int created})`, `QuestGenerationFailed({required InnkeeperFailure failure, required int serial})`.
- `test/helpers/mocks.dart`: `class MockQuestGenerationCubit extends MockCubit<QuestGenerationState> implements QuestGenerationCubit {}` (after `MockRequestCompletionCubit`). `MockKlimmeckGraphQl` / `MockInnkeeperRepository` are mocktail `Mock`s, so they need no explicit method for `generateQuests`.

## RED failures observed

- Task 1: compilation failure `Member not found: 'generateQuests'` (3 sites in `quest_mutations_test.dart`), `The method 'generateQuests' isn't defined for the type 'KlimmeckGraphQl'`; `the registry lists 44 documents (D-14)` → `Expected: <44> Actual: <43>`.
- Task 2: compilation failure `The method 'generateQuests' isn't defined for the type 'InnkeeperRepository'`.
- Task 3: compilation failure `Error when reading 'lib/screens/innkeeper/questGenerationCubit/quest_generation_cubit.dart'` (test and `mocks.dart`), `Type 'QuestGenerationState' not found`.

## Tests

- Task 1: `flutter test test/graphql test/tool test/repository/services/graphql/graphql_generate_quests_test.dart` → 136 passed.
- Task 2: `flutter test test/repository/innkeeper_repository_test.dart` → 22 passed (16 + 6 new).
- Task 3: `flutter test test/screens/innkeeper test/repository/innkeeper_repository_test.dart` → 176 passed (7 new cubit tests).
- Plan verification: `flutter test test/graphql test/tool test/repository test/screens/innkeeper` → 1036 passed.

## Acceptance greps

- `mutation GenerateQuests` 1; `'GenerateQuests': QuestMutations.generateQuests` 1; registry entries `^  '[A-Za-z]+':` 44; `Future<int> generateQuests` 1; `D-(09|10|14))` 3 + 4 + 1 = 8.
- `_guard(_graphQl.generateQuests)` 1; `D-(09|10))` in the repository test 6; `git diff HEAD~2 -- lib/repository/innkeeper_failure.dart | wc -l` 0.
- `class QuestGenerationCubit` 1; `sealed class QuestGenerationState` 1; `if (state is QuestGenerationSubmitting) return;` 1; `package:flutter/material.dart` 0; `class MockQuestGenerationCubit` 1; `D-(09|10))` in the cubit test 7.
- Analyzer after each task: 50 issues, all info, 0 error / 0 warning → `ANALYZE_GATE_OK`. Trailer check 0 after every commit.
- `dart format` was run on each touched file one by one. The new test files were reformatted, and so was `quest_mutations_test.dart` (its long test title was wrapped). The production files did not change under the formatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Two older tests hard-coded the registry count at 43**
- **Found during:** Task 1 (GREEN, verify command `flutter test test/graphql …`)
- **Issue:** `test/graphql/travel_documents_test.dart` («the schema check registers 43 documents») and `test/graphql/shop_documents_test.dart` («the global catalogue queries left the registry (D-01)») assert `schemaCheckDocuments.length == 43`. Both turned red once `GenerateQuests` was registered.
- **Fix:** both assertions now expect 44, and the travel test title says 44. The count is also owned by the new `test/tool` test «the registry lists 44 documents (D-14)».
- **Files modified:** test/graphql/travel_documents_test.dart, test/graphql/shop_documents_test.dart
- **Commit:** 7cf2039

**2. [Formatting] Registry doc comment re-wrapped by hand**
- The inserted «la Phase 14 aggiunge `GenerateQuests`» pushed one doc-comment line past 80 columns, so it was re-wrapped onto two lines (this is a comment, not a grep target).

## Notes

- The shell tests that pump the Locanda need no `generateQuests` stub yet: the panel does not create or read the cubit until 14-08.
- Between the RED and GREEN commits of Task 3, `test/helpers/mocks.dart` did not compile, so any test importing it would have failed. That state lasted for one commit only (744ff32 → ef6d5a1).

## Known Stubs

None.

## Self-Check: PASSED
