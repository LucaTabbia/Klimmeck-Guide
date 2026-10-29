---
phase: 09-combat-result-sheet
plan: 04
subsystem: repository + shop
tags: [flutter, dart, combat, awaiting-aid, shop, failure-classifier, bloc_test, banner]

# Dependency graph
requires:
  - phase: BE Phase 9 (Combat Result and Admin Outcomes, on BE develop)
    provides: "`AWAITING_AID` on `travelPreview`/`startTravel`/`acceptQuest`; `doTransaction` codes (`SHOP_NOT_IN_CITY`, `INSUFFICIENT_FUNDS`, `ITEM_NOT_OWNED`, `INSUFFICIENT_ITEM_QUANTITY`, `INVALID_QUANTITY`, `ITEM_NOT_FOUND`, `ITEM_NOT_TRADABLE`, `TRANSACTION_TOTAL_MISMATCH`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`)"
  - phase: 07-travel / 06-quest-accept-info-sheets
    provides: "classifier pattern by `extensions.code` (`travel_failure.dart`, `quest_acceptance_failure.dart`), outcome listener pattern (`TravelOutcomeListener`)"
provides:
  - "`awaitingAidCode = 'AWAITING_AID'` (travel_failure.dart), `TravelFailure.awaitingAid`, `QuestAcceptanceFailure.awaitingAid` with provisional banner copy"
  - "`lib/repository/transaction_failure.dart`: `enum TransactionFailure` + `transactionFailureFrom(OperationException)`"
  - "`KlimmeckGraphQl.doTransaction` rethrows the raw `OperationException`, `FormatException` on a malformed payload"
  - "`TransactionError(this.failure)`; `TransactionCubit(graphQl, {resetDelay = defaultResetDelay})` with a cancellable reset `Timer`"
  - "`transactionNoticeFor(TransactionFailure)` + `transactionNoticeTitle`; `TransactionOutcomeListener` wrapping `Shop`"
  - "`MockTransactionCubit` in `test/helpers/mocks.dart`"
affects: [09-08, 09-10, 09-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Shop refusals follow the session classifier pattern: service rethrows `OperationException`, a Flutter-free classifier maps `extensions.code`, a notice function decides banner vs none, a listener publishes it"
    - "Cubit auto-reset with one cancellable `Timer` (cancelled on a new action and in `close`) instead of `Future.delayed`"

key-files:
  created:
    - lib/repository/transaction_failure.dart
    - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart
    - lib/screens/mainScreen/tabs/shop/components/transaction_outcome_listener.dart
    - test/repository/transaction_failure_test.dart
    - test/repository/services/graphql/graphql_transaction_test.dart
    - test/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit_test.dart
    - test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart
    - test/screens/mainScreen/tabs/shop/components/transaction_outcome_listener_test.dart
  modified:
    - lib/repository/travel_failure.dart
    - lib/repository/quest_acceptance_failure.dart
    - lib/screens/mainScreen/travelCubit/travel_notice.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_cubit.dart
    - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_state.dart
    - lib/screens/mainScreen/tabs/shop/shop.dart
    - test/repository/travel_failure_test.dart
    - test/repository/quest_acceptance_failure_test.dart
    - test/screens/mainScreen/travelCubit/travel_notice_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
    - test/helpers/mocks.dart

key-decisions:
  - "AWAITING_AID is not mapped in the shop classifier: the BE does not send it on doTransaction (handoff §2), so it stays `unknown` there (pinned by a test)"
  - "Only `shopNotInCity` becomes a banner; when it does, the shopkeeper bubble is hidden so the refusal is said once"
  - "TransactionCubit imports `flutter_bloc` instead of `bloc` (Boy Scout: removes a `depend_on_referenced_packages` info, analyzer 53 → 52)"

patterns-established:
  - "Shop transaction refusal → `TransactionError(failure)` → `TransactionOutcomeListener` banner by code"

requirements-completed: []

# Metrics
duration: 8min
completed: 2026-10-27
---

# Phase 9 Plan 04: Wounded and shop refusal classifiers Summary

**`AWAITING_AID` mapped to provisional banners in the travel and acceptance classifiers, and the shop gets its first failure catalogue: `doTransaction` rethrows the coded `OperationException`, `TransactionFailure` classifies every BE shop code, `TransactionError` carries it, and `TransactionOutcomeListener` banners «Il negozio è disponibile solo in città».**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-10-27T22:43:00Z
- **Completed:** 2026-10-27T22:51:00Z
- **Tasks:** 3 (6 commits, TDD red/green each)
- **Files:** Task 1 touched 8 files, Task 2 touched 7, Task 3 touched 6 (21 total, as in the plan's `files_modified`)

## Accomplishments

- `TravelFailure.awaitingAid` → «Sei in attesa di soccorso: non puoi partire»; `QuestAcceptanceFailure.awaitingAid` → «Sei in attesa di soccorso: non puoi accettare missioni»; classification by `extensions.code` only (real BE message with a bogus code → `unknown`).
- `doTransaction` no longer swallows the code (`Exception(message)`/`'Bad Transaction'` removed); it goes through `_dataOrThrow` and validates `response is String`.
- `TransactionCubit` is typed and tested (first `bloc_test`s), reset via one cancellable `Timer`, the payload-logging `debugPrint` removed (T-9-09, T-9-10).
- `Shop` wraps its tree in `TransactionOutcomeListener`; outside a city the banner replaces the bubble, every other refusal keeps «Hmmm... Qualcosa non mi torna. Riproviamo?».

## Task Commits

1. **Task 1: AWAITING_AID in travel and acceptance** — `9b1a99c` (test, RED), `d6dfa7e` (feat, GREEN)
2. **Task 2: TransactionFailure, doTransaction rethrow, typed TransactionCubit** — `e9a1c86` (test, RED), `27f6537` (feat, GREEN)
3. **Task 3: shop banner outside a city** — `cbc86dc` (test, RED), `3c5ac7d` (feat, GREEN)

## RED evidence

- Task 1: `test/repository/travel_failure_test.dart:21:37: Error: Member not found: 'awaitingAid'.` (same in the acceptance classifier and both notice tests)
- Task 2: `Error when reading 'lib/repository/transaction_failure.dart': No such file or directory` / `Undefined name 'TransactionFailure'`; service test against the old `doTransaction`: `throws the raw OperationException keeping the error code [E] Expected: throws <Instance of 'OperationException'> with code: 'SHOP_NOT_IN_CITY'`, both `FormatException` cases failed (`'Bad Transaction'` Exception / `int` is not a `String`).
- Task 3: `Error when reading 'lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart': No such file or directory`.

## Other exhaustive switches (Task 1 step 4)

None: outside the classifiers and notices, `TravelFailure.`/`QuestAcceptanceFailure.` appear only as constructed values (`timedOut`, `unknown`, `declined`) or in the `QuestAcceptanceOutcomeListener` refetch set, which is not exhaustive; the compiler flagged nothing.

## Verification

- Full suite: 2199 → **2236 tests, all green** (+37)
- `flutter analyze`: **52 issues** (baseline 53, one removed by the `flutter_bloc` import), 0 errors
- All new/touched files formatter-clean (all were CLEAN before editing)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Boy Scout] `TransactionCubit` imported `package:bloc` (not a direct dependency)**
- **Found during:** Task 2 analyze
- **Fix:** import `package:flutter_bloc/flutter_bloc.dart` instead; analyzer 53 → 52
- **Commit:** `27f6537`

### Additions within scope

- `transaction_cubit_test.dart` has, besides the 4 `blocTest`s, a `fake_async` test proving `close` leaves no pending timer (the `blocTest` alone cannot tell cancellation from the `isClosed` guard), one proving a new transaction replaces the pending reset, and one pinning the default 4 s delay.
- `transaction_failure_test.dart` pins `AWAITING_AID` → `unknown` on the shop path.
- `shop.dart`: the `TransactionError` branch moved into a small `_showRefusal(failure)` helper; the wrapper re-indented the whole `build` (formatter output, no logic change outside the error branch).

**Total deviations:** 1 auto-fixed (Boy Scout). **Impact:** none on scope.

## Known Stubs

None. Banner copy is provisional by design (D-19).

## Threat Flags

None: no new endpoint or trust boundary; T-9-08/09/10 mitigated as planned, T-9-11 accepted (client gating is plan 09-08).

## Next Phase Readiness

- 09-08 can rely on the BE-refusal fallback being in place while it adds client-side gating (pawn drag, Board, Shop).
- 09-10/09-11 can reuse `MockTransactionCubit` and the `TransactionOutcomeListener` pattern.

## Self-Check: PASSED
