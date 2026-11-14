---
phase: 21-innkeeper-mission-completion-flow
plan: 03
subsystem: players-lock
tags: [mission-lock, failure-classifiers, journal, equipment, repository]
requires: ["21-02"]
provides:
  - "EquipmentFailure + EquipmentException + equipmentFailureFrom (lib/repository/equipment_failure.dart)"
  - "EquipmentRepository.equip(EquipItemRequest) guarded (15 s timeout, successful:false -> declined)"
  - "KlimmeckGraphQl.equipItem returns Future<bool> through _successfulMutation and keeps the OperationException"
  - "JournalCubit(EquipmentRepository) with sealed JournalState: JournalIdle, JournalEquipRefused(failure, sequence)"
  - "equipmentNoticeFor + equipmentNoticeTitle 'Equipaggiamento non cambiato'; Journal BlocListener publishes it"
affects: [21-05, 21-16]
tech-stack:
  added: []
  patterns: ["CompanionRepository pattern (_guard + classifier) applied to equipItem", "refusal state with growing sequence + publishNotice dedupKey 'equip|<failure>|<sequence>'"]
key-files:
  created:
    - lib/repository/equipment_failure.dart
    - lib/repository/equipment_repository.dart
    - lib/screens/mainScreen/tabs/journal/cubit/equipment_notice.dart
    - test/repository/equipment_failure_test.dart
    - test/repository/equipment_repository_test.dart
    - test/screens/mainScreen/tabs/journal/cubit/journal_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/cubit/equipment_notice_test.dart
    - test/screens/mainScreen/tabs/journal/journal_equip_refusal_test.dart
  modified:
    - lib/repository/services/graphql/graphql.dart
    - lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart
    - lib/screens/mainScreen/tabs/journal/cubit/journal_state.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/repository/services/graphql/graphql_transaction_test.dart
    - test/helpers/mocks.dart
    - test/helpers/journal_harness.dart
decisions:
  - "Equipment refusal banner title 'Equipaggiamento non cambiato' (new copy, to review in UAT)"
  - "The Journal listener lives on the Journal page (not session level like potions): a refusal arrives while the Journal is open"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 16
---

# Phase 21 Plan 03: Equipment refusal made visible Summary

An `equipItem` refusal (including `MISSION_IN_PROGRESS`) is no longer swallowed into a `JournalError` nobody renders: `equipItem` keeps the `OperationException` through `_successfulMutation`, a new `EquipmentRepository` classifies it into `EquipmentFailure`, `JournalCubit` emits `JournalEquipRefused(failure, sequence)` and the Journal publishes «Equipaggiamento non cambiato» / «Sei impegnato in una missione: aspetta l'esito» through `InAppNotificationsCubit` (D-11, D-30, LB-1).

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | ced2d797 | test(shared): expect an equipment classifier and repository |
| 1 GREEN | 50651bc3 | feat(shared): classify equipItem refusals through a repository |
| 2 RED | b5e985f6 | test(journal): expect a visible equipment refusal |
| 2 GREEN | f3be5a42 | feat(journal): show the equipment refusal banner |

## RED evidence

- Task 1: `equipment_failure_test` / `equipment_repository_test` failed to compile (`lib/repository/equipment_failure.dart` missing). `graphql_transaction_test` alone: `equipItem sends equipItem…` failed (`Expected: {'id': 'c-1', 'itemId': 'e-1', 'slotType': 'arms'}`, `Actual: Instance of 'EquipItemRequest'`) and `keeps the OperationException code (LB-1)` failed (`Expected: throws OperationException with code MISSION_IN_PROGRESS`, `Actual: Future<String>` — the old body threw a plain `Exception`). The 4 existing doTransaction cases stayed green.
- Task 2: compile failure (`Couldn't find constructor 'JournalIdle'`, `JournalEquipRefused` not found, `MockEquipmentRepository` not assignable to `KlimmeckGraphQl`).
- Green at first run: none of the new cases (all depended on missing types/behaviour), except the equipment_failure "ignores the message text" and EquipmentException.toString cases, which were RED only by compilation.

## Copy for the user's UAT review

- New title: **«Equipaggiamento non cambiato»** (pattern «Magia non equipaggiata» / «Compagno non equipaggiato»).
- Descriptions reuse existing lines: missionInProgress → «Sei impegnato in una missione: aspetta l'esito»; forbidden → «Questo personaggio non può farlo»; connection → «Connessione assente, riprova»; declined → «Il server ha rifiutato la richiesta, riprova»; notFound / badUserInput / timedOut / unknown → «Qualcosa è andato storto, riprova»; unauthenticated → no banner.

## Evidence

- `getGenericErrorMessage` count in `graphql.dart`: before 12, after 11.
- `getData` removal: `grep -rn "getData(" lib test` before removal listed `journal_cubit.dart:18` (the definition) and only ShopCubit callers — no caller of `JournalCubit.getData`. `KlimmeckGraphQl.getEquipment` stays (public, still pinned by `test/graphql/character_fragment_test.dart`).
- `grep -rn "\.equipItem(" lib` after the plan: `equipment_repository.dart` (the only GraphQL caller) and `journal.dart` (`context.read<JournalCubit>().equipItem`).
- Acceptance greps: `missionInProgressCode` in equipment_failure.dart = 1; `grep -A3 "Future<bool> equipItem" | grep -c _successfulMutation` = 1; `MockEquipmentRepository` in mocks.dart = 1; `KlimmeckGraphQl` / `appLog` in journal_cubit.dart = 0 / 0; `equipmentNoticeFor` in journal.dart = 1; `EquipmentRepository(graphQl: graphQl)` in authenticated_shell.dart = 1; `D-30` in equipment_notice_test = 2.
- Tests: Task 1 verify `+21 All tests passed`; Task 2 verify `flutter test test/screens/mainScreen/tabs/journal test/screens/auth test/repository` → `+1324 All tests passed` (google_fonts load messages are the usual offline noise).
- Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK` after both GREEN commits.
- Formatter: every touched existing file was formatter-clean beforehand (pre-check `--set-exit-if-changed`); formatted one by one: the 8 new files, graphql.dart, graphql_transaction_test.dart, mocks.dart, journal_harness.dart, journal_cubit.dart, journal_state.dart, journal.dart, authenticated_shell.dart.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Journal harness provides JournalCubit**
- **Found during:** Task 2
- **Issue:** the new `BlocListener<JournalCubit, JournalState>` at the Journal build root needs a `JournalCubit` in every Journal widget test; `test/helpers/journal_harness.dart` did not provide one.
- **Fix:** `MockJournalCubit` in `test/helpers/mocks.dart`, `idleJournalCubit()` + optional `journalCubit` parameter in `pumpJournalPage` (both outside `files_modified`).
- **Commit:** b5e985f6

**2. [Rule 2 - Missing test] Listener wiring test**
- **Found during:** Task 2
- **Issue:** the plan's tests cover cubit and notice but not the Journal listener.
- **Fix:** `test/screens/mainScreen/tabs/journal/journal_equip_refusal_test.dart`: a refusal publishes the banner with dedupKey `equip|missionInProgress|1` (D-30); unauthenticated publishes nothing.
- **Commit:** b5e985f6

**3. Commit scope** — the plan's `test(repository)` / `feat(repository)` use a scope not in the REPO-RULES list: `shared` used instead (as in 21-01).

## Known Stubs

None.

## Threat Flags

None: T-21-08 (refusal state + listener + notice), T-21-09 (no `appLog`, no server text, only `extensions.code`) and T-21-10 (`_guard` maps every `Object` to `unknown`) mitigated as planned.

## Self-Check: PASSED
