---
phase: 08-spells-section-journal-tab
plan: 06
subsystem: state-management
tags: [flutter, dart, cubit, bloc, spells, optimistic-ui, fake-async]

# Dependency graph
requires:
  - phase: 08-02
    provides: "`SpellsRepository.equip/unequip`, `SpellEquipException(SpellEquipFailure)`, `MockSpellsRepository`"
  - phase: 08-05
    provides: "`Spellbook.of(character, pending:)`, `intentFor`, `SpellOperation`, `SpellToggleIntent`"
provides:
  - "`SpellsCubit` (Flutter-free optimistic overlay): `toggle`, `sync`, `close`, `settleTimeout`, `defaultSettleTimeout` (15 s)"
  - "`SpellsState { pending, outcome }`, `SpellOutcome { sequence, spellId, operation, kind, failure }`, `SpellOutcomeKind { blockedSlotsFull, blockedNoSlots, failed }`"
affects: [08-09, 08-10, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-key request tokens + per-key settle timers: every pending operation ends exactly once (subscription, failure or timeout)"
    - "One-shot outcomes made distinct by a monotonically increasing `sequence` inside the state"

key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart
    - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_state.dart
    - test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart
  modified: []

key-decisions:
  - "`spells_state.dart` is a `part of` the cubit (project convention of `travel_state.dart`/`journal_state.dart`); importing `spells_cubit.dart` exposes all state types"
  - "`sync` keeps the last `outcome` (copyWith): listeners must react to outcome changes (`previous.outcome != current.outcome`), not to every state"
  - "A failure emits `SpellsState(pending: without id, outcome: failed)` in ONE emit; a blocked tap keeps `pending` unchanged"

patterns-established:
  - "Optimistic overlay cubit: tap → pending + timer + unawaited call; success never builds state, it only waits for the subscription"

requirements-completed: []  # SPELL-03/04/06 traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 20min
completed: 2026-10-27
---

# Phase 8 Plan 06: SpellsCubit Pending Overlay Summary

**Flutter-free `SpellsCubit` that turns spell taps into one token-guarded pending operation per spell, closed exactly once by the `characterUpdated` match, a `SpellEquipFailure` or a 15 s settle timer, with sequenced one-shot outcomes for banners and spring-back**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-10-27T13:25:00Z
- **Completed:** 2026-10-27T13:46:00Z
- **Tasks:** 2 (each RED + GREEN)
- **Files modified:** 3 (all new)

## Accomplishments

- `toggle(character, spellId)` computes the intent on `Spellbook.of(character, pending: state.pending)` and returns it synchronously (for haptics); equip/unequip → pending + timer + repository call, blocked → sequenced outcome without any call, ignored → nothing.
- `sync(character)` clears every pending operation the server `assets.activeSpells` already reflects (one emit, timers cancelled).
- Repository success clears only if the latest snapshot already matches, otherwise waits; failures (domain or not → `unknown`) and the in-flight timeout (`timedOut`) clear with a `failed` outcome in one emit; an unmatched success is cleared silently at 15 s; late answers are dropped by token; `close()` cancels all timers.

## Public API (for plans 08-09, 08-10, 08-11)

Import: `package:klimmeck_guide/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart` (state types are a `part`; `SpellOperation`/`SpellToggleIntent` come from `lib/models/spell/spellbook.dart`, `SpellEquipFailure` from `lib/repository/spell_equip_failure.dart`).

```dart
class SpellsCubit extends Cubit<SpellsState> with SafeEmit<SpellsState> {
  SpellsCubit(SpellsRepository repository, {Duration settleTimeout = defaultSettleTimeout});
  static const Duration defaultSettleTimeout = Duration(seconds: 15);
  final Duration settleTimeout;
  SpellToggleIntent toggle(Character character, String spellId); // sync return
  void sync(Character character);   // call on every CharacterCubit state with a character
  Future<void> close();             // cancels every settle timer
}

enum SpellOutcomeKind { blockedSlotsFull, blockedNoSlots, failed }

class SpellOutcome extends Equatable {
  final int sequence;               // 1, 2, 3… — distinct per outcome
  final String spellId;
  final SpellOperation operation;   // blocked outcomes are always `equip`
  final SpellOutcomeKind kind;
  final SpellEquipFailure? failure; // non-null only for `failed`
}

class SpellsState extends Equatable {
  const SpellsState({Map<String, SpellOperation> pending = const {}, SpellOutcome? outcome});
  final Map<String, SpellOperation> pending; // unmodifiable once emitted by the cubit
  final SpellOutcome? outcome;               // the LAST outcome, kept across later emits
  SpellsState copyWith({Map<String, SpellOperation>? pending, SpellOutcome? outcome});
}
```

Notes for the consumers:
- **08-09 (section/rows):** build the view with `Spellbook.of(character, pending: spellsState.pending)`; use the intent returned by `toggle` for haptics (blocked → resist + `selectionClick`). Spring-back (D-18) fires on a new `outcome` with `kind == failed` for that `spellId`.
- **08-10 (shell + listener):** provide the cubit in `AuthenticatedShell` with the `SpellsRepository`; the listener must (a) call `spellsCubit.sync(character)` on every `CharacterCubit` state carrying a character, (b) react only when `outcome` changes (`listenWhen: (p, c) => p.outcome != c.outcome && c.outcome != null`), mapping `blockedSlotsFull`/`blockedNoSlots` to banners and `failed` to the D-17 table (`alreadyActive`/`notActive` → silent `refreshCharacter()`; `notKnown`/`slotsFull`/`notFound` → banner + refresh; `unauthenticated` silent; `timedOut` included). The cubit never calls another cubit.
- **08-11:** the cubit has no Flutter import and no `HapticFeedback`; haptics stay in widgets.
- The cubit stores the latest `Character` seen by `toggle` or `sync`; until the listener calls `sync`, a successful request can only be closed by the 15 s timer (silently).

## Task Commits

1. **Task 1 RED: toggle/sync tests** - `abaa5b6` (test)
2. **Task 1 GREEN: pending overlay** - `ff832dd` (feat)
3. **Task 2 RED: settling tests** - `52857be` (test)
4. **Task 2 GREEN: answers, timer, tokens, close** - `e30e56f` (feat)

## RED failure outputs

- Task 1: compile failure, `spells_cubit.dart` missing — `Error: The method 'toggle' isn't defined for the type 'Object?'` (… `Some tests failed.`).
- Task 2: 7 of the 11 new tests failed against the task 1 implementation (`+18 -7: Some tests failed.`), e.g. `Expected: SpellsState({}, SpellOutcome(1, spell-a, SpellOperation.unequip, SpellOutcomeKind.failed, SpellEquipFailure.notActive))  Actual: SpellsState({spell-a: SpellOperation.unequip}, null)` and `Expected: SpellToggleIntent.equip  Actual: SpellToggleIntent.ignoredPending` (no timeout). The success/sync/close cases already passed because task 1 had no timers and swallowed answers.

## Verification

- `flutter test test/screens/mainScreen/tabs/journal/spellsCubit`: 25 tests green (14 toggle/sync, 11 settling).
- Plan-end quick run `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`: +1783, all passed.
- `flutter analyze` on the plan files: no issues; full analyze: 53 issues (≤ 53), 0 errors.
- Acceptance greps: `SpellToggleIntent toggle(` 1, `with SafeEmit<SpellsState>` 1, `package:flutter/` imports 0, `CommonResponse|successful` 0, `defaultSettleTimeout = Duration(seconds: 15);` 1, `Future<void> close()` 1, `fakeAsync` 10, `timedOut` 5; `dart format --set-exit-if-changed` on the 3 files exits 0.

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

None that change behaviour. Sequencing notes:
- Task 1 GREEN did not yet keep `_latest`, tokens or the timer (the analyzer flagged an unused `_latest` field as a new warning); they arrived in task 2 together with rules 3-6, as the plan scopes them.
- `spells_state.dart` is written as `part of 'spells_cubit.dart'` (repo convention) instead of a standalone import; the contents are the plan's.

## Issues Encountered

None.

## Threat Flags

None — no new network surface; T-8-15..T-8-18 mitigations are implemented and tested (settle timer, no response data read, `ignoredPending`, `SafeEmit` + `close()`).

## Next Phase Readiness

Plans 08-09/08-10/08-11 can consume `SpellsCubit` as listed above.

## Self-Check: PASSED

- FOUND: lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart, spells_state.dart, test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart
- FOUND commits: abaa5b6, ff832dd, 52857be, e30e56f

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
