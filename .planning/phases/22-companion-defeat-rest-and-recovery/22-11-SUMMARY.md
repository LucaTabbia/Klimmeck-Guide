---
phase: 22-companion-defeat-rest-and-recovery
plan: 11
subsystem: journal
tags: [companion, name, rename, graphql, registry, classifier, single-flight, pitfall-10, d-18, d-19, d-21, d-23, d-31]
requires: ["22-02 name_rules / companion_lines (rename copy)", "22-05 companionCareEnabled (entry points in 22-12)"]
provides: ["CharacterMutations.renamePet (RenamePet)", "RenamePetRequest", "KlimmeckGraphQl.renamePet", "registry 55", "PetRenameFailure + petRenameFailureFrom + PetRenameException", "CompanionRepository.rename", "CompanionNameCubit (shell) + companionNameRefusalLine", "MockCompanionNameCubit"]
affects: ["22-12 name prompt and rename entry points (behind companionCareEnabled)", "22-16 gate schema check validates RenamePet"]
tech-stack:
  added: []
  patterns: ["one classifier per action (rename separate from equip)", "single-flight Cubit with one sequence counter for saved/refused states"]
key-files:
  created:
    - lib/models/request/rename_pet_request.dart
    - lib/repository/pet_rename_failure.dart
    - lib/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit.dart
    - lib/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_state.dart
    - lib/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_notice.dart
    - test/graphql/rename_pet_document_test.dart
    - test/models/request/rename_pet_request_test.dart
    - test/repository/services/graphql/graphql_rename_pet_test.dart
    - test/repository/pet_rename_failure_test.dart
    - test/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/companionNameCubit/companion_name_notice_test.dart
  modified:
    - lib/graphql/mutations/character_mutations.dart
    - lib/repository/services/graphql/graphql.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/companion_repository.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/tool/schema_check_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/repository/companion_repository_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/helpers/mocks.dart
decisions:
  - "RenamePet registered pre-gate (Phase 21 precedent), validated only in the gate's schema check; no entry point sends it before 22-12/22-16"
  - "CHARACTER_NAME_INVALID also maps to nameInvalid (defensive, research F-5); MISSION_IN_PROGRESS falls to unknown (the rename is not locked, D-31)"
  - "Saved and Refused share one sequence counter in CompanionNameCubit; an unexpected error is refused as unknown"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 11: Companion name plumbing Summary

The name action is wired end to end below the UI: the `RenamePet` mutation (`renamePet(request: RenamePetRequest!) { response successful }`, `RenamePetRequest { id, petId, name }` = character id, catalogue pet id, name), `KlimmeckGraphQl.renamePet`, the schema-check registry at 55, a dedicated rename classifier, `CompanionRepository.rename` with its own guard, and a single-flight `CompanionNameCubit` provided by the shell next to `CompanionCubit`, plus the inline refusal copy. RenamePet registered, not sent before the gate: no entry point exists until 22-12 (behind `companionCareEnabled`).

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 RenamePet document, request, service, registry 55 | 3ff59a41 (RED), 3a6fcd85 (GREEN) | document + request + service; four count pins 54 -> 55 |
| 2 Classifier, repository, Cubit in the shell | e51f2326 (RED), cb5b6215 (GREEN) | `petRenameFailureFrom`, `CompanionRepository.rename`, `CompanionNameCubit`, `companionNameRefusalLine`, shell provider, `MockCompanionNameCubit` |
| 3 Bookkeeping | this commit | ROADMAP 11/17, STATE `Plan: 11 of 17`, VALIDATION 22-11-01..03 green |

## RED failures

- Task 1: `flutter test test/graphql test/models/request test/repository/services/graphql test/tool` -> +459 -7: the four registry pins expected 55 (got 54); the three new test files failed to compile (`rename_pet_request.dart` missing, `CharacterMutations.renamePet` / `KlimmeckGraphQl.renamePet` undefined).
- Task 2: all five targeted files failed to compile (`pet_rename_failure.dart` and `companion_name_cubit.dart` missing; `CompanionRepository.rename` undefined; `mocks.dart` type not found).

## Verification

- `flutter test test/graphql test/models/request test/repository/services/graphql test/tool` -> +469 all passed.
- `flutter test test/repository test/screens/mainScreen/tabs/journal test/screens/auth` -> +1470 all passed.
- Analyzer: 47 issues (info only), ANALYZE_GATE_OK after both GREEN commits.
- Registry 55; `grep -rn "schemaCheckDocuments.length, 54" test` empty; 4 files at 55.
- `'PET_NAME_INVALID'` literal only in `lib/repository/pet_rename_failure.dart`; no `appLog` in the new code (T-22-36).
- Tests added: +33 (document 2, request 2, service 2, classifier 8, repository +5, cubit 8, notice 6; the shell case extended) -> expected suite 4920 (full suite not run).
- All touched files were formatter-clean before and after.

## Deviations from Plan

- Extra tests beyond the behavior list: request value equality, classifier «ignores the message text» and `toString`, repository «any other error becomes unknown», cubit «unexpected error refused as unknown» and «rename after close is ignored». MISSION_IN_PROGRESS is pinned to `unknown` inside the unknown-code case.
- The shell assertion extends «provides the gameplay cubits and closes them on removal» (title now ends `(D-19)`) and checks the idle state and the close.
- Doc comment of the registry rewrapped by hand (a comment line exceeded 80 columns after the insertion; comments are not reflowed by the formatter).
- STATE uses `Plan: 11 of 17` (orchestrator format).

## Known Stubs

None: the action has no entry point by design until 22-12 (T-22-35).

## Self-Check: PASSED
