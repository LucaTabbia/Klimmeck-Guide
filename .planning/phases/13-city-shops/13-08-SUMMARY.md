---
phase: 13-city-shops
plan: 08
subsystem: companion
tags: [companion, pet, cubit, optimistic, listener, session, tdd]
requires: [13-03, 13-04, 13-05]
provides:
  - CompanionCubit (single slot, optimistic overlay, token, settle timer, mutation queue, sync, close)
  - CompanionState / PendingCompanion / CompanionOutcome / displayedPetId
  - companionNoticeFor (fixed banner copy, D-06)
  - CompanionOutcomeListener (sync on every character, banner, silent re-read)
  - CompanionCubit provided by AuthenticatedShell, listener mounted in MainScreen
affects: [13-09, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "Phase 8 SpellsCubit shape reduced to one slot: one token, one timer, one succeeded flag"
    - "session-level outcome listener nested inside SpellOutcomeListener"
key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart
    - lib/screens/mainScreen/tabs/journal/companionCubit/companion_state.dart
    - lib/screens/mainScreen/tabs/journal/companionCubit/companion_notice.dart
    - lib/screens/mainScreen/components/companion_outcome_listener.dart
    - test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/companionCubit/companion_notice_test.dart
    - test/screens/mainScreen/components/companion_outcome_listener_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/helpers/mocks.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/main_screen_quest_results_test.dart
decisions:
  - "toggle on a pending slot returns ignoredPending before any work: one companion operation in flight at a time"
  - "_start keeps the previous outcome in the pending state (same as SpellsState.copyWith); sync and settle keep it too; _close replaces it"
  - "stale views for the listener = notOwned, notFound, timedOut (failed) plus every settledByTimeout"
metrics:
  duration: ~25min
  completed: 2026-11-02
  tasks: 3
  files: 13
---

# Phase 13 Plan 08: Companion slot state and session wiring Summary

`CompanionCubit` is the Phase 8 `SpellsCubit` reduced to one slot: a tap shows the pet in the «Compagno» slot (or empties it) at once, sends `equipPet`/`unequipPet` through `CompanionRepository`, and closes only on `characterUpdated` (`sync`), on a refusal (rollback plus a typed outcome) or after the 15 s settle timeout. `companionNoticeFor` maps failures to fixed Italian copy, `CompanionOutcomeListener` forwards every new character to `sync`, publishes banners and re-reads the character on stale views. The cubit lives in `AuthenticatedShell`, the listener in `MainScreen`.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | CompanionCubit: single-slot optimistic equip/unequip | 88a5de2 (test), efc59a6 (feat) |
| 2 | companionNoticeFor and CompanionOutcomeListener | 467cd49 (test), 3808393 (feat) |
| 3 | Shell provider and MainScreen mount | 2c7291c (test), fd47358 (feat) |

## RED failures observed

- Task 1: compile failure, `Error when reading 'lib/screens/mainScreen/tabs/journal/companionCubit/companion_cubit.dart': No such file or directory`, `Undefined name 'CompanionOperation'`, `Method not found: 'PendingCompanion'`.
- Task 2: compile failure, `Error when reading '.../companionCubit/companion_notice.dart'`, `Method not found: 'companionNoticeFor'` (the listener file also missing). `spell_outcome_listener_test.dart` was green (14) with the new `MockCompanionCubit` before the commit.
- Task 3: `provides the companion cubit and closes it on removal (D-10)` failed with `ProviderNotFoundException` (no `CompanionCubit` above the main screen builder); `mounts the companion outcome listener with the pages (D-06)` failed with `Found 0 widgets with type "CompanionOutcomeListener"`.

## Names and signatures created

- `companion_state.dart` (`part of 'companion_cubit.dart'`): `enum CompanionOperation { equip, unequip }`, `enum CompanionToggleIntent { equip, unequip, ignoredPending }`, `enum CompanionOutcomeKind { failed, settledByTimeout }`, `const PendingCompanion({required String petId, required CompanionOperation operation})`, `const CompanionOutcome({required int sequence, required String petId, required CompanionOperation operation, required CompanionOutcomeKind kind, PetEquipFailure? failure})`, `const CompanionState({PendingCompanion? pending, CompanionOutcome? outcome})` with `String? displayedPetId(Character character)`.
- `companion_cubit.dart`: `CompanionCubit(CompanionRepository repository, {Duration settleTimeout = defaultSettleTimeout})`, `static const Duration defaultSettleTimeout = CompanionRepository.defaultTimeout`, `CompanionToggleIntent toggle(Character character, String petId)`, `void sync(Character character)`, `Future<void> close()`.
- `companion_notice.dart`: `const String companionEquipNoticeTitle = 'Compagno non equipaggiato'`, `const String companionUnequipNoticeTitle = 'Compagno non rimosso'`, `KGNotification? companionNoticeFor(CompanionOutcome outcome)`.
- `companion_outcome_listener.dart`: `const CompanionOutcomeListener({super.key, required Widget child})`; dedup key `companion|<kind>|<failure or ->|<petId>`.
- `test/helpers/mocks.dart`: `class MockCompanionCubit extends MockCubit<CompanionState> implements CompanionCubit {}` right after `MockSpellsCubit`.

## Deviations from Plan

- Cubit test: the 13 titles are as listed. Only four titles carry `(D-06)`/`(D-10)`, so the cases sit in two groups named `'optimistic slot (D-10)'` and `'settle timer (D-10)'`, which gives 6 matching lines for the `≥ 5` grep. No title was renamed.
- Listener test: «re-reads the character after a stale-view refusal (D-06)» covers both `notOwned` and `notFound` in a single test (loop). The listener and notice tests also check the exact copy and the absence of a re-read on `forbidden`.
- Bookkeeping uses the orchestrator's `8/11` / `Plan: 8 of 11`, not the plan's `08/11`.
- No dart format reflow on any touched file. All acceptance greps match on one line.

Nothing else: the plan ran as written.

## Gates

- `flutter test test/screens/mainScreen/tabs/journal/companionCubit test/screens/mainScreen/components/companion_outcome_listener_test.dart`: 23 green (13 cubit + 5 notice + 5 listener).
- `flutter test test/screens/auth test/screens/mainScreen`: 1040 green. `flutter test test/repository`: 740 green.
- `flutter analyze`: 50 issues, all info, 0 error, 0 warning.
- «Cavalcatura» absent from `lib/`.

## Known Stubs

None. Plan 13-09 builds the visual «Compagno» slot that calls `toggle`.

## Self-Check: PASSED

- All 7 created files exist. Commits 88a5de2, efc59a6, 467cd49, 3808393, 2c7291c, fd47358 are on `feat/13-city-shops`.
