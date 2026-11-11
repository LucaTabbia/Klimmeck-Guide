---
phase: 18-heal-quests-by-size
plan: 06
subsystem: repository
tags: [graphql, repository, potions, use-item, failures, tdd]
requires: ["18-02"]
provides:
  - "CharacterMutations.useItem: named mutation UseItem($itemId: ID!) selecting hpBefore hpAfter injuriesHealed quantityLeft recoveryUntil loreUnlocked { id name type }; registered in schemaCheckDocuments (46)"
  - "KlimmeckGraphQl.useItem(String itemId) -> Future<UseItemResult> (OperationException raw, FormatException on a malformed answer)"
  - "graphQlErrorExtension(OperationException?, String key) -> Object?"
  - "ItemUseFailure (10 values), ItemUseException(failure, {recoveryUntil}), itemUseFailureFrom, itemUseExceptionFrom"
  - "ItemUseRepository({required graphQl, timeout = 15 s}).useItem(itemId); MockItemUseRepository"
affects: [18-07, 18-09, 18-12, 18-13]
tech-stack:
  added: []
  patterns: ["quest_abandon_repository / quest_abandon_failure pattern; extra extension read only from the coded error"]
key-files:
  created:
    - lib/repository/item_use_failure.dart
    - lib/repository/item_use_repository.dart
    - test/graphql/use_item_document_test.dart
    - test/repository/services/graphql/graphql_use_item_test.dart
    - test/repository/item_use_failure_test.dart
    - test/repository/item_use_repository_test.dart
  modified:
    - lib/graphql/mutations/character_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/services/graphql/graphql_error_code.dart
    - test/tool/schema_check_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - test/repository/services/graphql/graphql_error_code_test.dart
    - test/helpers/mocks.dart
decisions:
  - "UseItem document non-gated (D-19): registered now, validated against the merged BE SDL only in the gated plan 18-12"
  - "The server recoveryUntil is read only for POTION_RECOVERING, only as a String parsed by DateTime.tryParse, converted to UTC (T-18-18)"
metrics:
  duration: "~20 min"
  completed: 2026-11-10
  tasks: 2
  files: 16
---

# Phase 18 Plan 06: useItem plumbing Summary

The potion network path is in place: the `UseItem` mutation document (registry 45 → 46), `KlimmeckGraphQl.useItem`, a public reader of another `extensions` key (`graphQlErrorExtension`), the `ItemUseFailure` enum with `ItemUseException` carrying the server end of the recovery, and `ItemUseRepository`, which never lets an `OperationException` through.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | UseItem document, registry 46, KlimmeckGraphQl.useItem | 1fb2717 (test), 80d595c (feat) |
| 2 | graphQlErrorExtension, ItemUseFailure, ItemUseRepository | 54cc381 (test), a5eb839 (feat) |

## RED failures observed

- Task 1: `use_item_document_test.dart` and `graphql_use_item_test.dart` failed to compile (`Member not found: 'useItem'` on `CharacterMutations`; `The method 'useItem' isn't defined for the type 'KlimmeckGraphQl'`); the four count pins failed with `Expected: <46> Actual: <45>` (`schema_check_documents_test.dart` «the registry lists 46 documents (D-12)», `shop_documents_test.dart` «the global catalogue queries left the registry (D-01)», `travel_documents_test.dart` «the schema check registers 46 documents (D-12)», `loot_fragment_test.dart` «the registry stays at 46 documents»).
- Task 2: compile failures — `Error when reading 'lib/repository/item_use_failure.dart'` / `item_use_repository.dart`, `Method not found: 'graphQlErrorExtension'`, `Type 'ItemUseRepository' not found` in `mocks.dart`.

## Names and signatures created

- `lib/graphql/mutations/character_mutations.dart`: `static const String useItem` (operation `UseItem`).
- `tool/schema_check/schema_check_documents.dart`: `'UseItem': CharacterMutations.useItem` after `'UnequipPet'`; doc comment «la Phase 18 aggiunge `UseItem`».
- `lib/repository/services/graphql/graphql.dart`: `Future<UseItemResult> useItem(String itemId)`.
- `lib/repository/services/graphql/graphql_error_code.dart`: `Object? graphQlErrorExtension(OperationException? exception, String key)` (first error carrying a String `code`, graphql errors then HTTP ≥ 300 parsed errors).
- `lib/repository/item_use_failure.dart`: constants `itemNotUsableCode`, `potionRecoveringCode`, `itemNoEffectCode`, `recoveryUntilExtension`; `enum ItemUseFailure { potionRecovering, noEffect, awaitingAid, notOwned, notUsable, badUserInput, connection, timedOut, unauthenticated, unknown }`; `class ItemUseException implements Exception { const ItemUseException(this.failure, {this.recoveryUntil}); final ItemUseFailure failure; final DateTime? recoveryUntil; }` with `toString() == 'ItemUseException(<name>)'`; `ItemUseFailure itemUseFailureFrom(OperationException)`; `ItemUseException itemUseExceptionFrom(OperationException)`. Imports `awaitingAidCode`, `itemNotOwnedCode`, `unauthenticatedCode`, `badUserInputCode` (none redeclared).
- `lib/repository/item_use_repository.dart`: `ItemUseRepository({required KlimmeckGraphQl graphQl, this.timeout = defaultTimeout})`, `static const Duration defaultTimeout = Duration(seconds: 15)`, `Future<UseItemResult> useItem(String itemId)`.
- `test/helpers/mocks.dart`: `class MockItemUseRepository extends Mock implements ItemUseRepository {}`.

## Document ahead of the BE

The `UseItem` document is validated against the merged BE schema only in the gated plan 18-12; until `recovery` is selected there no heal parchment is tappable, so the document is never sent to a BE without Phase 18 (T-18-21, accepted).

## Gates

- `flutter test test/graphql test/tool test/repository/services/graphql`: 346 passed; `flutter test test/repository test/graphql test/tool`: 1028 passed.
- `flutter analyze --no-fatal-infos`: «47 issues found.» — 47 info, 0 error, 0 warning (unchanged).
- `bash tool/hardening_check.sh`: OK.
- `dart format` run file by file on every touched file; the only changes were on the new test files and `graphql_error_code_test.dart` (my added group). No formatter-dirty file touched.

## Deviations from Plan

- **[Boy Scout] Third pin title renamed:** `test/tool/schema_check_documents_test.dart` «the registry lists 45 documents (D-12)» also spelled the number; renamed to «… 46 documents (D-12)» together with the two titles the plan named.
- Additional test «the default timeout is 15 seconds» in `item_use_repository_test.dart` (mirrors `quest_abandon_repository_test.dart`).
- The timeout test uses a 20 ms bound with a never-completing future, exactly as `quest_abandon_repository_test.dart` (the pattern the plan prescribes).
- No case was green at the first run (all RED by compile failure or count mismatch).

## Known Stubs

None.

## Self-Check: PASSED
