---
phase: 12-hardening
plan: 11
subsystem: repository
tags: [hardening, error-codes, bad-user-input, shop, quest-abandon, quest-results]
requires: ["12-10"]
provides:
  - "TransactionFailure.badUserInput, QuestAbandonFailure.badUserInput, QuestResultFailure.badUserInput mapped from badUserInputCode over HTTP 200 and HTTP 400"
  - "Shop bubble keeps genericRefusalLine and no banner; abandon notice keeps «Impossibile abbandonare ora, riprova»; quest-result banner «Risultato non disponibile» / «Qualcosa è andato storto, riprova»"
  - "QuestResultsCubit publishes a notice for badUserInput on a tap and never retries a badUserInput pending read"
affects: [12-12, 12-13, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "badUserInput right before unauthenticated, arm `badUserInputCode => X.badUserInput` before `unauthenticatedCode`"
key-files:
  created:
    - .planning/phases/12-hardening/12-11-SUMMARY.md
  modified:
    - lib/repository/transaction_failure.dart
    - test/repository/transaction_failure_test.dart
    - test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart
    - lib/repository/quest_abandon_failure.dart
    - test/repository/quest_abandon_failure_test.dart
    - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
    - test/screens/mainScreen/questAbandonCubit/quest_abandon_notice_test.dart
    - lib/repository/quest_result_failure.dart
    - test/repository/quest_result_failure_test.dart
    - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
    - test/screens/mainScreen/questResultsCubit/quest_result_notice_test.dart
    - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
    - test/screens/mainScreen/questResultsCubit/quest_results_delivery_test.dart
decisions:
  - "Copy ruling (user veto D-13a): badUserInput renders what each surface renders for unknown; only the silent quest-result surface gains the generic line; no new string"
  - "badUserInput is deterministic on quest results: never retried by the pending refetch (same set as malformed/notFound/forbidden)"
metrics:
  duration: "~15 min"
  completed: 2026-11-09
---

# Phase 12 Plan 11: BAD_USER_INPUT on shop transactions, quest abandon and quest results Summary

Three more classifiers (`TransactionFailure`, `QuestAbandonFailure`, `QuestResultFailure`) map `BAD_USER_INPUT` to a dedicated `badUserInput` value over HTTP 200 and HTTP 400; each surface keeps its existing generic copy and the quest-result banner, silent before, now shows «Qualcosa è andato storto, riprova».

## Tasks

| Task | Name | Commits | Files |
|------|------|---------|-------|
| 1 | Shop transactions | 34c86b3 (test), d733f9a (feat) | transaction_failure.dart + 2 tests |
| 2 | Quest abandon | 3b8aa97 (test), 36d873f (feat) | quest_abandon_failure.dart, quest_abandon_notice.dart + 2 tests |
| 3 | Quest results | a69e83d (test), a872e38 (feat) | quest_result_failure.dart, quest_result_notice.dart, quest_results_cubit.dart + 3 tests |

## Copy ruling applied per surface

- Shop: `shopkeeperRefusalLine(badUserInput) == genericRefusalLine` («Hmmm... Qualcosa non mi torna. Riproviamo?») via the existing wildcard; `transactionNoticeFor(badUserInput) == null`. `transaction_notice.dart` unchanged.
- Quest abandon: `badUserInput` joined to the `connection || timedOut || unknown` arm → «Impossibile abbandonare ora, riprova».
- Quest results: new arm `QuestResultFailure.badUserInput => 'Qualcosa è andato storto, riprova'` under the title `questResultNoticeTitle`.

## RED observed

- Task 1: compile failure `Member not found: 'badUserInput'` in transaction_failure_test (:71, :80) and transaction_notice_test (:40, :47).
- Task 2: compile failure in quest_abandon_failure_test :52 and quest_abandon_notice_test :27.
- Task 3: compile failure in quest_result_failure_test :51, quest_result_notice_test :29/:44, quest_results_delivery_test :277/:528/:535.
- «connection stays silent (D-13)» is a guard pinning unchanged behaviour (would have passed alone).

## Names created

- `TransactionFailure.badUserInput`, `QuestAbandonFailure.badUserInput`, `QuestResultFailure.badUserInput` (right before `unauthenticated`, two-line doc as plan 10), arms `badUserInputCode => X.badUserInput` with `import 'package:klimmeck_guide/repository/spell_equip_failure.dart' show badUserInputCode;`.
- Test helper `_fromHttp400(String code)` copied locally in the three classifier test files.
- `QuestResultsCubit._isNoticeWorthy` now a const-set lookup {notFound, forbidden, badUserInput}; `_isTransient` set gains `badUserInput`.

## Verification

- `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop` → 74 passed.
- `flutter test test/repository/quest_abandon_failure_test.dart test/screens/mainScreen/questAbandonCubit` → 24 passed.
- `flutter test test/repository test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components test/screens/mainScreen/tabs/shop test/screens/mainScreen/questAbandonCubit` → 1113 passed.
- `flutter analyze`: `47 issues found.` (all info, 0 error, 0 warning).
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- `dart format` on each touched file: 0 changed.
- No new user-visible string.

## Deviations from Plan

**1. [Rule 2 - Missing critical functionality] The quest-result banner needed the cubit gate too**
- **Found during:** Task 3 (read of the `questResultNoticeFor` caller path)
- **Issue:** `QuestResultsCubit.requestFromTap` only emits a `QuestResultNotice` when `_isNoticeWorthy` (notFound/forbidden), so the new notice arm alone would never reach the screen; and `_isTransient` would have retried a deterministic `badUserInput` pending read forever.
- **Fix:** `badUserInput` added to `_isNoticeWorthy` and to the non-transient set of `_isTransient`; docs updated. Tests «a badUserInput tap produces a notice (D-13)» and «a badUserInput read is not retried (D-13)» in quest_results_delivery_test.dart; the existing «every other failure stays silent» notice test excludes `badUserInput`.
- **Files modified:** lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart, test/screens/mainScreen/questResultsCubit/quest_results_delivery_test.dart, test/screens/mainScreen/questResultsCubit/quest_result_notice_test.dart
- **Commits:** a69e83d, a872e38

## Known Stubs

None.

## Self-Check: PASSED

- Commits 34c86b3, d733f9a, 3b8aa97, 36d873f, a69e83d, a872e38 present in `git log`; all files in key-files exist.
