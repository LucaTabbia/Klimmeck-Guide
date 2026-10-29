---
phase: 09-combat-result-sheet
plan: 03
subsystem: quest result transport (GraphQL documents, service, repository, delivery ports)
tags: [flutter, dart, combat, graphql, subscription, repository, schema-check, fake_async]

# Dependency graph
requires:
  - phase: 09-combat-result-sheet
    provides: "`QuestResult` model + fixtures (09-01); classifier pattern `transactionFailureFrom` (09-04)"
provides:
  - "`QuestResultFragment.fields` (lib/graphql/fragments/quest_result_fragment.dart, exported by fragments.dart)"
  - "`OnQuestResultReceived` (`QuestResultSubscriptions.questResultReceived`) and `GetQuestResult` (`QuestResultQueries.getQuestResult`), registered (36 documents) and OK against BE origin/develop 10e5f43"
  - "`KlimmeckGraphQl.subscribeToQuestResults(String characterId)` → `Stream<QuestResult>`; `KlimmeckGraphQl.getQuestResult(String id)` → `Future<QuestResult>`"
  - "`QuestResultFailure` enum, `QuestResultException`, `questResultFailureFrom(OperationException)`"
  - "`QuestResultRepository({required KlimmeckGraphQl graphQl, Duration timeout})` with `watch(characterId)` / `fetch(resultId)` and private generic `_guard`"
  - "Ports `PendingQuestResults.fetchUnacknowledged()` / `QuestResultAcknowledger.acknowledge(resultId)` + null objects `NoPendingQuestResults` / `NoQuestResultAcknowledger`"
  - "`MockQuestResultRepository` in test/helpers/mocks.dart"
affects: [09-06, 09-10, 09-11, 09-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shared result fragment between the live subscription and the by-id query (one shape, one parser)"
    - "Delivery ports with null objects so the shell composes the 9.2 delivery before the BE merge"

key-files:
  created:
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/graphql/subscriptions/quest_result_subscriptions.dart
    - lib/graphql/queries/quest_result_queries.dart
    - lib/repository/quest_result_failure.dart
    - lib/repository/quest_result_repository.dart
    - lib/repository/quest_result_delivery_ports.dart
    - test/graphql/quest_result_documents_test.dart
    - test/repository/services/graphql/graphql_quest_result_test.dart
    - test/repository/quest_result_failure_test.dart
    - test/repository/quest_result_repository_test.dart
    - test/repository/quest_result_delivery_ports_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/helpers/mocks.dart
    - test/graphql/travel_documents_test.dart

key-decisions:
  - "QuestResultFragment.fields is a `static const String` (like QuestFragment), not a getter: all interpolated fragments are const"
  - "QuestResultRepository maps FormatException to `malformed` (distinct from `unknown`), so 09-06 can skip a corrupt result without retry"

requirements-completed: []

# Metrics
duration: ~12min
completed: 2026-10-28
---

# Phase 9 Plan 03: Quest result transport Summary

**Shared `QuestResultFragment` behind `OnQuestResultReceived` and `GetQuestResult` (36/36 OK against BE `10e5f43`), typed `KlimmeckGraphQl` methods, `QuestResultRepository` with code-only `QuestResultFailure` and a 15 s timeout, and the Flutter-free 9.2 delivery ports with null objects.**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-10-28
- **Tasks:** 2 (4 commits, TDD RED → GREEN each)
- **Files:** 11 created, 5 modified

## Accomplishments

- Result fragment with the D-03 content: `ItemUnion` variants via `EquipmentFragment.simpleFields` (carries `equipType`, C5) and `LootFragment.simpleFields` + `description effect power`, `enemy { id name imagePath }` without `locations`, no `acknowledgedAt`.
- Both documents registered in `tool/schema_check` (34 → 36) and validated against BE `origin/develop`.
- `subscribeToQuestResults` keeps the stream alive past a malformed event (T-9-15); `getQuestResult` rethrows the raw `OperationException` or a `FormatException`.
- `QuestResultRepository.fetch` turns every failure into `QuestResultException` (`notFound`, `forbidden`, `unauthenticated`, `connection`, `timedOut`, `malformed`, `unknown`); `watch` passes the typed stream through.
- `NoPendingQuestResults` (`[]`) / `NoQuestResultAcknowledger` (no-op) for the shell until the gated 09-12.

## Task Commits

1. **Task 1 RED** — `c828375` test(combat): expect the quest result documents
2. **Task 1 GREEN** — `65fc8f1` feat(combat): add the quest result subscription and query
3. **Task 2 RED** — `39ed3eb` test(combat): expect the quest result repository
4. **Task 2 GREEN** — `1788d4f` feat(combat): add the quest result repository and delivery ports

## TDD evidence

Task 1 RED (`flutter test test/graphql/quest_result_documents_test.dart`):
```
Error: Error when reading 'lib/graphql/queries/quest_result_queries.dart': No such file or directory
Error: Undefined name 'QuestResultQueries'.
00:01 +0 -1: Some tests failed.
```

Task 2 RED (four new test files):
```
test/repository/quest_result_failure_test.dart:5:8: Error: Error when reading 'lib/repository/quest_result_failure.dart': No such file or directory
test/repository/quest_result_failure_test.dart:16:20: Error: Undefined name 'QuestResultFailure'.
test/repository/quest_result_failure_test.dart:23:16: Error: Method not found: 'questResultFailureFrom'.
```

GREEN: `flutter test test/graphql test/tool` → `+82: All tests passed!`; `flutter test test/repository/quest_result_*_test.dart test/repository/services/graphql` → `+149: All tests passed!`.

## Schema check (BE `origin/develop` = `10e5f43`)

```
dumped 36 documents
OK AbandonQuest.graphql
OK AcceptQuest.graphql
OK CreateCharacter.graphql
OK DeleteCharacter.graphql
OK EquipSpell.graphql
OK ExchangeLoginTicket.graphql
OK GetCity.graphql
OK GetMe.graphql
OK GetQuestResult.graphql
OK GetRaceTraits.graphql
OK GetServerTime.graphql
OK GetTravelPreview.graphql
OK Logout.graphql
OK OnQuestResultReceived.graphql
OK OnQuestUpdated.graphql
OK OnUserChanged.graphql
OK RefreshSession.graphql
OK RegisterPushDevice.graphql
OK StartTravel.graphql
OK UnequipSpell.graphql
OK UnregisterPushDevice.graphql
OK character.graphql
OK characterUpdated.graphql
OK cities.graphql
OK doTransaction.graphql
OK equipItem.graphql
OK equipment.graphql
OK equipmentAssetsQuantity.graphql
OK equipmentItems.graphql
OK equipmentItemsByIds.graphql
OK lootAssetsQuantity.graphql
OK lootItems.graphql
OK lootItemsByIds.graphql
OK lore.graphql
OK lores.graphql
OK quests.graphql
exit=0
```

36 `OK`, 0 failures. No `acknowledgedAt`, `ListUnacknowledgedQuestResults` or `AcknowledgeQuestResult` in `lib/graphql/` (T-9-17).

## Verification

- Full suite: 2259 → **2293** tests, all green.
- `flutter analyze`: **52 issues** (baseline 53), 0 errors.
- All acceptance greps pass; `dart format --set-exit-if-changed` clean on every created/modified Dart file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Registry count pinned at 34 in `travel_documents_test.dart`**
- **Found during:** Task 1 GREEN
- **Issue:** `test/graphql/travel_documents_test.dart` asserts `schemaCheckDocuments.length == 34`; the two new documents made it fail.
- **Fix:** the test now expects 36 (name and assertion). File was formatter-clean before and after.
- **Files modified:** test/graphql/travel_documents_test.dart
- **Commit:** 65fc8f1

### Notes

- The Task 2 verify command's `flutter analyze lib/repository test/repository test/helpers/mocks.dart` reports one pre-existing warning (`unnecessary_cast` in `test/repository/services/auth/auth_token_service_contract_test.dart:40`, last touched in Phase 1, part of the 53 baseline), so that sub-command exits non-zero; no issue comes from this plan. Out of scope, not fixed.
- `QuestResultFragment.fields` is `static const String` rather than the `static String get` sketched in the plan (same value; const like `QuestFragment.fields`).

## Threat model

- T-9-15: malformed event → `FormatException` error event, the next valid event is still delivered (test `keeps delivering after a malformed event`).
- T-9-16: `FORBIDDEN`/`NOT_FOUND` → `forbidden`/`notFound` by code only, no data returned.
- T-9-17: schema check 36/36, no 9.2 field/operation.
- T-9-18: exceptions carry only operation/code/failure name (`QuestResultException(forbidden)`); no logging of payloads added.
- T-9-19: 15 s timeout → `timedOut` (fake_async test).

## Known Stubs

- `NoPendingQuestResults` / `NoQuestResultAcknowledger` (lib/repository/quest_result_delivery_ports.dart) are intentional null objects until the gated plan 09-12 swaps in the repository-backed 9.2 implementations.

## Self-Check: PASSED

- All 11 created files exist; commits c828375, 65fc8f1, 39ed3eb, 1788d4f present in `git log`.
