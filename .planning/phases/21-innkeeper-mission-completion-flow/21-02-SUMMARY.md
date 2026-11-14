---
phase: 21-innkeeper-mission-completion-flow
plan: 02
subsystem: players-lock
tags: [mission-lock, failure-classifiers, shop, spells, companion]
requires: ["21-01"]
provides:
  - "TransactionFailure.missionInProgress (banner 'Negozio non disponibile' + wait line, no shopkeeper bubble)"
  - "SpellEquipFailure.missionInProgress (wait line under 'Magia non equipaggiata' / 'Magia non tolta')"
  - "PetEquipFailure.missionInProgress (wait line under 'Compagno non equipaggiato' / 'Compagno non rimosso')"
affects: [21-03, 21-05]
tech-stack:
  added: []
  patterns: ["one enum value + one classifier arm + one notice arm per locked action, copy from lib/utils/mission_lines.dart"]
key-files:
  created: []
  modified:
    - lib/repository/transaction_failure.dart
    - lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart
    - lib/repository/spell_equip_failure.dart
    - lib/screens/mainScreen/tabs/journal/spellsCubit/spell_notice.dart
    - lib/repository/pet_equip_failure.dart
    - lib/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart
    - test/repository/transaction_failure_test.dart
    - test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart
    - test/repository/spell_equip_failure_test.dart
    - test/screens/mainScreen/tabs/journal/spellsCubit/spell_notice_test.dart
    - test/repository/pet_equip_failure_test.dart
    - test/screens/mainScreen/tabs/journal/companionCubit/companion_notice_test.dart
decisions:
  - "The mission refusal is never a stale-view reread: kept out of the _staleViewFailures sets of the spell and companion listeners (LB-1)"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 12
---

# Phase 21 Plan 02: Mission lock plumbing II Summary

`MISSION_IN_PROGRESS` refused by `doTransaction`, `equipSpell`/`unequipSpell` and `equipPet`/`unequipPet` now maps to a dedicated `missionInProgress` value in each classifier and shows the shared wait line «Sei impegnato in una missione: aspetta l'esito» under the title of each action (D-11, D-30).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Shop refusal during a mission is a banner | b2a502ff (RED), 837c7831 (GREEN) |
| 2 | Spell and companion refusals during a mission | 59db4827 (RED), 5bd9116b (GREEN) |
| 3 | Bookkeeping | this commit |

### RED evidence

- Task 1: `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart` failed at compile time: `Member not found: 'missionInProgress'` (both files).
- Task 2: the four test files failed at compile time with `Member not found: 'missionInProgress'` (`+0 -4: Some tests failed`).

No case was green at the first run.

### GREEN

- Task 1: `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop test/screens/mainScreen/components` → `+249: All tests passed!`
- Task 2: `flutter test test/repository test/screens/mainScreen/tabs/journal test/screens/mainScreen/components/spell_outcome_listener_test.dart test/screens/mainScreen/components/companion_outcome_listener_test.dart` → `+1132: All tests passed!`
- Analyzer after each code task: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK`.

## Extra switch sites

- `grep -rn "TransactionFailure\.imprisoned" lib`: besides the classifier and the two notice switches, `transaction_outcome_listener.dart:40` (prison-only: computes the release time and feeds `PrisonCubit`, no treatment needed for the mission) and a doc reference in `transaction_state.dart:18`. No change there: the listener already publishes any non-null `transactionNoticeFor` result, deduped by `transaction|missionInProgress`.
- `grep -rn "SpellEquipFailure\.forbidden\|PetEquipFailure\.forbidden" lib`: only the classifiers and the two `_failureLine` switches. No other exhaustive switch.
- The `_staleViewFailures` sets in `spell_outcome_listener.dart` / `companion_outcome_listener.dart` do not contain the new values (grep count 0).

## Test adjustments

The two existing transaction notice tests that iterate `TransactionFailure.values` excluding the banner cases («every other failure stays in the shopkeeper bubble», «only the off-city and prison refusals have no bubble line») now also exclude `missionInProgress` (done in the RED commit).

## Formatting

All twelve touched files were formatter-clean before editing; `dart format` run on each file one by one after editing (only `transaction_notice_test.dart` and `companion_notice_test.dart` were rewrapped, in the RED commits).

## Deviations from Plan

None - plan executed exactly as written. Progress recorded as `2/18` in the ROADMAP row per the orchestrator.

## Self-Check: PASSED
