---
phase: 06-quest-accept-info-sheets
plan: 03
subsystem: quest-acceptance
tags: [quest, graphql, mutation, cubit, error-mapping, tdd]
requires: [06-04]
provides:
  - QuestMutations.acceptQuest (AcceptQuest document) and AcceptQuestRequest
  - KlimmeckGraphQl.acceptQuest (void, successful:false or missing payload -> FormatException)
  - QuestAcceptanceFailure / QuestAcceptanceException / questAcceptanceFailureFrom (by extensions.code)
  - QuestAcceptanceRepository.accept
  - QuestAcceptanceCubit (accept/reset) provided by AuthenticatedShell
  - questAcceptanceNoticeFor (failure -> KGNotification copy, pure Dart)
affects: [06-10]
tech-stack:
  added: []
  patterns: [deleteCharacter vertical slice, SafeEmit session cubit, copy table as pure function]
key-files:
  created:
    - lib/graphql/mutations/quest_mutations.dart
    - lib/models/request/accept_quest_request.dart
    - lib/repository/quest_acceptance_failure.dart
    - lib/repository/quest_acceptance_repository.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_state.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - test/graphql/quest_mutations_test.dart
    - test/models/request/accept_quest_request_test.dart
    - test/repository/services/graphql/graphql_quest_acceptance_test.dart
    - test/repository/quest_acceptance_failure_test.dart
    - test/repository/quest_acceptance_repository_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_cubit_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
  modified:
    - lib/repository/services/graphql/graphql.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/helpers/mocks.dart
    - test/screens/auth/authenticated_shell_test.dart
decisions:
  - "Error codes are top-level consts in quest_acceptance_failure.dart, no magic strings"
  - "Acceptance cubit lives in the session shell so late responses survive tab changes"
metrics:
  tasks: 3
  tests: "1137 -> 1189 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 03: Quest acceptance slice Summary

`AcceptQuest` mutation with Repository -> Cubit path mirroring `deleteCharacter`: rejection codes mapped by `extensions.code` only, a double-submit-safe `QuestAcceptanceCubit` provided per session, and a fixed Italian banner copy table (`Missione non accettata`) ready for the Board listener in 06-10.

## Commits

- 6ad2620 test(quest): failing tests for the AcceptQuest mutation (RED: missing `quest_mutations.dart`, `AcceptQuestRequest`)
- 170d4a6 feat(quest): send the AcceptQuest mutation
- 440b512 test(quest): failing tests for acceptance failures (RED: missing failure/repository libraries)
- 607064c feat(quest): map acceptance rejections to domain failures
- 53f070f test(quest): failing tests for the acceptance cubit and banner copy (RED: missing cubit/notice libraries)
- e578bf6 feat(quest): accept quests through a session cubit

## Schema check

`tool/schema_check` against BE `origin/develop`: 28 documents dumped, all `OK` (including `AcceptQuest.graphql`, `quests.graphql`, `characterUpdated.graphql`).

## Deviations from Plan

- Test-side only: the cubit test helper `stubAccept` initially returned `void` (compile error caught on the first GREEN run); fixed to return `When<Future<void>>` within the Task 3 commit.
- `dart format` on the new test files reformatted them before the RED commits; `mocks.dart`, `schema_check_documents.dart`, `authenticated_shell*.dart` were measured clean and stayed clean.

## Known Stubs

None.

## Self-Check: PASSED

All created files exist; commits 6ad2620, 170d4a6, 440b512, 607064c, 53f070f, e578bf6 present; `flutter test` 1189 green, `flutter analyze` 56 issues (baseline), 0 errors.
