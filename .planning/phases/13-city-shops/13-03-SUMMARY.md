---
phase: 13-city-shops
plan: 03
subsystem: shop
tags: [repository, failures, companion, shop, tdd]
requires: [13-02]
provides:
  - TransactionFailure.itemNotInShop / petAlreadyOwned / petNotOwned
  - shopkeeperRefusalLine + genericRefusalLine
  - PetEquipFailure / PetEquipException / petEquipFailureFrom
  - CompanionRepository + MockCompanionRepository
affects: [13-05, 13-07, 13-08, 13-09]
tech-stack:
  added: []
  patterns:
    - "classifiers switch on graphQlErrorCode only (never the server message)"
    - "CompanionRepository clones SpellsRepository: _confirm (false -> declined) + _guard (15 s timeout)"
key-files:
  created:
    - lib/repository/pet_equip_failure.dart
    - lib/repository/companion_repository.dart
    - test/repository/pet_equip_failure_test.dart
    - test/repository/companion_repository_test.dart
  modified:
    - lib/repository/transaction_failure.dart
    - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart
    - test/repository/transaction_failure_test.dart
    - test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart
    - test/helpers/mocks.dart
decisions:
  - "shopkeeperRefusalLine returns null only for shopNotInCity (the banner); transactionNoticeFor is unchanged, so the three new codes never become banners (D-05, Phase 9 D-16)"
  - "petNotOwnedCode is shared: pet_equip_failure.dart imports it from transaction_failure.dart; badUserInputCode is reused from spell_equip_failure.dart"
metrics:
  duration: ~15min
  completed: 2026-11-02
  tasks: 2
  files: 9
---

# Phase 13 Plan 03: Classifiers and companion repository Summary

`ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED` are typed `TransactionFailure`s with shopkeeper bubble lines (`shopkeeperRefusalLine`, provisional copy D-13), the `equipPet`/`unequipPet` refusals are typed by `petEquipFailureFrom`, and `CompanionRepository` (15 s timeout, every error a `PetEquipException`) plus `MockCompanionRepository` are ready for the `CompanionCubit` (13-08).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Three new transaction failures and the shopkeeper bubble line | fac42d1 (RED), d61c282 (GREEN) |
| 2 | PetEquipFailure classifier and CompanionRepository | d1be39c (RED), 634c8b2 (GREEN) |

## Created names and signatures

- `lib/repository/transaction_failure.dart`: `const String itemNotInShopCode = 'ITEM_NOT_IN_SHOP'`, `petAlreadyOwnedCode = 'PET_ALREADY_OWNED'`, `petNotOwnedCode = 'PET_NOT_OWNED'`; enum values `itemNotInShop`, `petAlreadyOwned`, `petNotOwned` inserted after `totalMismatch` (before `notFound`).
- `lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart`: `const String genericRefusalLine = 'Hmmm... Qualcosa non mi torna. Riproviamo?'`; `String? shopkeeperRefusalLine(TransactionFailure failure)` → `shopNotInCity` null, `itemNotInShop` «Questa merce non la tratto», `petAlreadyOwned` «Hai già questo compagno», `petNotOwned` «Questo compagno non è più tuo», `insufficientFunds` «Non ti bastano le monete», everything else `genericRefusalLine`. `transactionNoticeFor` unchanged.
- `lib/repository/pet_equip_failure.dart`: `enum PetEquipFailure { notOwned, notFound, forbidden, badUserInput, unauthenticated, connection, timedOut, declined, unknown }`; `class PetEquipException implements Exception { const PetEquipException(this.failure); final PetEquipFailure failure; }` (`toString()` → `PetEquipException(<name>)`); `PetEquipFailure petEquipFailureFrom(OperationException exception)`.
- `lib/repository/companion_repository.dart`: `CompanionRepository({required KlimmeckGraphQl graphQl, this.timeout = defaultTimeout})`, `static const Duration defaultTimeout = Duration(seconds: 15)`, `Future<void> equip({required String characterId, required String petId})`, `Future<void> unequip({required String characterId})`.
- `test/helpers/mocks.dart`: `class MockCompanionRepository extends Mock implements CompanionRepository {}` after `MockSpellsRepository`.

## RED failures observed

- Task 1: `transaction_failure_test.dart: Error: Member not found: 'itemNotInShop'` (+ `petAlreadyOwned`, `petNotOwned`); `transaction_notice_test.dart: Error: Method not found: 'shopkeeperRefusalLine'`, `Undefined name 'genericRefusalLine'`.
- Task 2: `Error when reading 'lib/repository/pet_equip_failure.dart'` / `'lib/repository/companion_repository.dart'`, `Undefined name 'PetEquipFailure'`, `'CompanionRepository' isn't a type`.

## Verification

- `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart test/repository/pet_equip_failure_test.dart test/repository/companion_repository_test.dart` → 41 green.
- `flutter test test/screens/mainScreen/tabs/shop` → 22 green; `flutter test test/repository` → 740 green.
- `flutter analyze` → 51 issues (all info), 0 error, 0 warning.
- `dart format` run one by one on the 9 touched files.
- Acceptance greps: all single-line greps pass (no formatter wrap); `grep -c "message" lib/repository/pet_equip_failure.dart` = 0 (the doc comment says «messaggi»).

## Deviations from Plan

None - plan executed exactly as written. Bookkeeping uses the orchestrator's progress number 5/11 instead of the plan's 03/11.

## Known Stubs

None.

## Self-Check: PASSED
