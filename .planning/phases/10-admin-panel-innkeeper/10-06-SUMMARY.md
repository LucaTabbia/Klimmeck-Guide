---
phase: 10-admin-panel-innkeeper
plan: 06
subsystem: admin-panel
tags: [admin, innkeeper, cubit, completion, dialog, tdd]
requires: [10-01, 10-02, 10-04, 10-05]
provides:
  - RequestCompletionCubit (lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart)
  - sealed RequestCompletionState (Loading, LoadFailed, Editing, Succeeded)
  - MockRequestCompletionCubit (test/helpers/mocks.dart)
  - DestructiveConfirmationDialog.confirmButtonStyle + showDestructiveConfirmation(confirmButtonStyle:)
affects: [10-07]
tech-stack:
  added: []
  patterns: [route-scoped action cubit with sealed state, Future.wait parallel reads, in-flight guard on submit, failureSerial to re-signal the same failure]
key-files:
  created:
    - lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart
    - lib/screens/innkeeper/requestCompletionCubit/request_completion_state.dart
    - test/screens/innkeeper/requestCompletionCubit/request_completion_cubit_test.dart
  modified:
    - lib/shared/components/modal/destructive_confirmation_dialog.dart
    - test/shared/components/modal/destructive_confirmation_dialog_test.dart
    - test/helpers/mocks.dart
key-decisions:
  - "load() runs only from Loading or LoadFailed and never twice at once (_isLoading); from LoadFailed it emits Loading first, from the initial Loading it emits Editing directly"
  - "submit() sends CompletePendingRequestInput(pendingQuestId: card.pendingQuestId, outcomes: state.overrides): one call closes the request for every participant (D-05, BE 09 §9)"
  - "A failed submit keeps the drafts and bumps failureSerial, so the UI can re-show the same failure code; any edit clears failure (failureSerial kept)"
  - "confirmButtonStyle defaults to destructiveButtonStyle: delete, logout and abandon stay red with no caller change"
requirements-completed: []
duration: 25min
completed: 2026-10-29
---

# Phase 10 Plan 06: Request completion cubit Summary

Flutter-free `RequestCompletionCubit` that reads every participant of a card in parallel (`Future.wait` on `readCharacter`), edits the clamped `ParticipantDraft`s, and submits one guarded `completePendingRequest` with the first-entry id and only the changed participants, yielding the `QuestResult`s or a typed `InnkeeperFailure`; plus an optional neutral `confirmButtonStyle` on the shared confirmation dialog.

## What was built

- **State** (`request_completion_state.dart`, `part of`): `RequestCompletionLoading()`, `RequestCompletionLoadFailed({required InnkeeperFailure failure})`, `RequestCompletionEditing({required List<ParticipantDraft> drafts, bool isSubmitting = false, InnkeeperFailure? failure, int failureSerial = 0})` with `List<ParticipantOverride> get overrides => overridesOf(drafts)` and `copyWith({drafts, isSubmitting, failure, failureSerial})` (omitting `failure` clears it), `RequestCompletionSucceeded({required List<QuestResult> results})`.
- **Cubit**: `RequestCompletionCubit({required InnkeeperRepository repository, required RequestCard card})` with `SafeEmit`; `Future<void> load()`, `setHp(characterId, hp)`, `toggleInjury(characterId, InjuryType)`, `setConsumableUsed(characterId, itemId, quantity)`, `setSpellUsed(characterId, spellId, usages)`, `Future<void> submit()`. Edits are ignored outside `Editing`, while submitting, or for an unknown character id.
- **Dialog**: `DestructiveConfirmationDialog({…, ButtonStyle? confirmButtonStyle})` and `showDestructiveConfirmation(…, ButtonStyle? confirmButtonStyle)`; style is `confirmButtonStyle ?? KlimmeckGuideTheme.destructiveButtonStyle`.

## TDD evidence

- Task 1 RED (`4933de3`): compile failure — `The method 'setSpellUsed' isn't defined for the type 'Object'` (cubit/state types missing).
- Task 1 GREEN (`c0f52d3`): 16/16 cubit tests.
- Task 2 RED (`fbc4b77`): `Error: The method 'submit' isn't defined for the type 'RequestCompletionCubit'`; dialog test `Error: No named parameter with the name 'confirmButtonStyle'`.
- Task 2 GREEN (`a13acd9`): `request_completion_cubit_test.dart` 27/27, `destructive_confirmation_dialog_test.dart` 8/8; `test/screens/innkeeper` + `test/shared/components/modal` 92/92; full suite 2711 green (2681 + 30).
- Analyzer gate: 51 issues (all info), no error/warning, gate exit 0.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | 4933de3 | test(admin): expect the completion form state |
| 1 GREEN | c0f52d3 | feat(admin): add the completion form cubit |
| 2 RED | fbc4b77 | test(admin): expect the completion submission and neutral confirm |
| 2 GREEN | a13acd9 | feat(admin): submit the completion with only the changed participants |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Correctness] Load guard against duplicate loads and a duplicate Loading emission**
- **Found during:** Task 1
- **Issue:** the plan's `load()` sketch had no guard; a double tap on «Riprova» would run two read batches, and `Cubit.emit` lets a first emission equal to the initial state through, so an unconditional `emit(Loading)` would duplicate the initial Loading.
- **Fix:** private `_canLoad` (only from `Loading`/`LoadFailed`, `_isLoading` false); `Loading` is emitted only when coming from `LoadFailed`.
- **Commit:** c0f52d3

**2. [Rule 3 - Blocking] Double-submit test seeds by `load()` instead of `emit`**
- **Found during:** Task 2 RED
- **Issue:** calling the protected `emit` from the test is an analyzer `warning` (invalid_use_of_protected_member) that would fail the repo-wide gate.
- **Fix:** the test loads the form through the mocked reads, then submits twice.
- **Commit:** fbc4b77

**3. [Naming] `ParticipantDraft.asOverride`** — the plan's interfaces call it `override`; the real 10-01 member is `asOverride` (used indirectly via `overridesOf`). No code impact.

## Threat model

- T-10-22 mitigated: `isSubmitting` guard, double-submit test asserts one `complete` call.
- T-10-23: `notFound` surfaced as `InnkeeperFailure.notFound` (test), UI removes the card in 10-07.
- T-10-24: clamped drafts + `overridesOf` diff; `overrideInvalid` kept as a form-level failure (test).

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/screens/innkeeper/requestCompletionCubit/request_completion_cubit.dart
- FOUND: lib/screens/innkeeper/requestCompletionCubit/request_completion_state.dart
- FOUND: test/screens/innkeeper/requestCompletionCubit/request_completion_cubit_test.dart
- FOUND commits: 4933de3, c0f52d3, fbc4b77, a13acd9
