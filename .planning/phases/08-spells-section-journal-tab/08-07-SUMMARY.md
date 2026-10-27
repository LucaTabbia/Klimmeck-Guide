---
phase: 08-spells-section-journal-tab
plan: 07
subsystem: state-management
tags: [flutter, dart, bloc, cubit, spells, countdown, server-clock, fake-async]

# Dependency graph
requires:
  - phase: 08-04
    provides: "`SpellRecoveryInput`, sealed `SpellRecoveryStatus`, pure `spellRecoveryStatusOf(input, serverNow)`"
  - phase: 08-05
    provides: "`Spellbook.of(...)` with `SpellbookEntry { spell, usages, recoveries, ... }`"
  - phase: 07
    provides: "`ServerClockService` (`now()`, `offsetChanges`), `TravelProgressCubit` ticker template, `FakeServerClockService`"
provides:
  - "`SpellRecoveryCubit` (`tabs/journal/spellRecoveryCubit/`): server-time recovery status per known spell, self-idling 1 s ticker, recompute on clock offset changes"
  - "`SpellRecoveryState { statuses }` + `statusOf(spellId)` (unknown id → `SpellRecoveryFull`)"
affects: [08-09, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ticker template of `TravelProgressCubit` applied to spells: `Timer.periodic` only while at least one `SpellRecoveryCountdown` exists, Equatable dedup of the whole status map so rebuilds happen only when a label changes"

key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart
    - lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_state.dart
    - test/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit_test.dart
  modified: []

key-decisions:
  - "`spell_recovery_state.dart` is a `part of` the cubit (same convention as `spells_cubit`/`travel_progress_cubit`), so callers import only `spell_recovery_cubit.dart`"
  - "`offsetChanges` always calls `_refresh()` (no early return on empty inputs: an empty map re-emitted is deduplicated)"
  - "No GREEN commit for task 2: the task-1 implementation (which followed the plan's code sketch, timer stop + offset listener included) already satisfied every ticker case"

patterns-established:
  - "Section-owned ticker cubit: provided by `BlocProvider(create:)` in the section, so tree teardown closes it and no timer survives widget tests (research Pitfall 5)"

requirements-completed: []  # SPELL-05 building block; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 12min
completed: 2026-10-27
---

# Phase 8 Plan 07: SpellRecoveryCubit Countdown Ticker Summary

**`SpellRecoveryCubit` derives «prossimo tra X» for every known spell from `ServerClockService.now()` via `spellRecoveryStatusOf`, ticks every second only while a countdown exists, stops at `Arriving`/`Full`/`Unknown`, restarts on `offsetChanges`, and leaves no timer or subscription after `close()`**

## Performance

- **Duration:** ~12 min
- **Completed:** 2026-10-27
- **Tasks:** 2 (3 commits: RED, GREEN, ticker coverage)
- **Files modified:** 3 (3 created)

## Accomplishments

- Server-anchored derivation per spell (D-04, T-8-19): never the device clock, recompute on clock resync
- Self-idling ticker (D-04, research Pattern 8, T-8-20): one periodic timer only while a countdown exists, none otherwise; whole-map Equatable dedup, so a 1 s tick emits only when the shown minute changes
- `Arriving` changes only the label; a use comes back only through a new `follow` after `characterUpdated` (T-8-21, CLAUDE.md rule 4)

## Task Commits

1. **Task 1 RED: failing tests for the spell recovery cubit** - `3aadf8c` (test)
2. **Task 1 GREEN: follow spell recovery on server time** - `aeb8b8d` (feat)
3. **Task 2: ticker lifecycle tests** - `82962bd` (test; already green, see Deviations)

**Plan metadata:** see `docs(phase-8): record plan 07 progress`

### RED failure outputs

- Task 1: `spell_recovery_cubit_test.dart:5:8: Error: Error when reading 'lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart': No such file or directory`, `:31:21: Error: Method not found: 'SpellRecoveryCubit'.` (compile failure, as expected)
- Task 2: the 7 `ticker` cases passed on the task-1 implementation. RED evidence is the task-1 commit; to prove the cases bite, a temporary mutation (no `_stopTimer()` when idle, offset listener doing nothing) was run and reverted: `ticker under a minute reads 0, then arriving stops the timer [E]` and `ticker an offset change re-derives and restarts the timer [E]` (`+10 -2: Some tests failed.`).

## Public API for plans 08-09 and 08-11

`package:klimmeck_guide/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart` (the state is a `part`, Flutter-free apart from `flutter_bloc`):

```dart
class SpellRecoveryState extends Equatable {
  const SpellRecoveryState(this.statuses);
  final Map<String, SpellRecoveryStatus> statuses;      // unmodifiable, keyed by spell id
  SpellRecoveryStatus statusOf(String spellId);          // missing id → const SpellRecoveryFull()
}

class SpellRecoveryCubit extends Cubit<SpellRecoveryState> with SafeEmit<SpellRecoveryState> {
  SpellRecoveryCubit({required ServerClockService clock, Duration tick = defaultTick});
  static const Duration defaultTick = Duration(seconds: 1);
  static List<SpellRecoveryInput> inputsOf(Spellbook spellbook); // entries order; usages ?? maxUsages ?? 0
  void follow(List<SpellRecoveryInput> inputs);           // recompute now; starts/stops the ticker
  @override Future<void> close();                         // cancels timer + offset subscription
}
```

Initial state: `SpellRecoveryState(const {})`. Status types (from 08-04): `SpellRecoveryFull` (show nothing), `SpellRecoveryCountdown(remainingMinutes)` (0 = under a minute), `SpellRecoveryArriving` («in arrivo…»), `SpellRecoveryUnknown` (static «in recupero»).

## Files Created/Modified

- `lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart` - cubit, `inputsOf`, ticker
- `lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_state.dart` - `SpellRecoveryState` (`part of`)
- `test/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit_test.dart` - 12 cases (`follow` 5, `ticker` 7)

## Verification

- Task 1 / task 2 verify (`flutter test test/screens/mainScreen/tabs/journal/spellRecoveryCubit && flutter analyze <cubit dir> <test dir>`): 5 then 12 tests green, no issues; all acceptance greps as expected (`pendingTimers` 8, `resync(` 2, `Future<void> close()` 1, no `DateTime.now`/Flutter import); format check exit 0
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1795, all passed**
- Full `flutter analyze`: **53 issues, 0 errors** (no new issue)

## Decisions Made

See key-decisions above.

## Deviations from Plan

**1. [Plan allowance] Task 2 has no separate GREEN `feat` commit**
- **Found during:** Task 2
- **Issue:** the plan's task-1 code sketch already contained the stop-when-idle branch, the offset listener and `close()`, so all task-2 behaviours passed immediately.
- **Fix:** as the plan prescribes for this case, the RED evidence is the task-1 commit; the ticker tests were committed as `test(spells): cover the spell recovery ticker lifecycle` (not "failing"), and a reverted mutation run proves they fail on a broken ticker (see RED outputs).
- **Files modified:** test file only
- **Commit:** `82962bd`

Otherwise none (the `_refresh` uses an early `return _stopTimer();` like `TravelProgressCubit` instead of the sketch's if/else, same behaviour).

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-11 (section): `BlocProvider(create: (context) => SpellRecoveryCubit(clock: context.read<ServerClockService>())..follow(SpellRecoveryCubit.inputsOf(Spellbook.of(character))))` inside the section (never in the shell: the ticker must die with the Journal page, D-16); a `BlocListener<CharacterCubit>` re-calls `follow(inputsOf(...))` on every character change (that is how a restored use leaves `Arriving`). `follow` with equal inputs emits nothing, so calling it on every emission is safe.
- 08-09 (row/detail): read `context.select((SpellRecoveryCubit c) => c.state.statusOf(spell.id))` per row so only the affected row rebuilds; map the four statuses to the `spell_lines.dart` copy. The detail sheet reads the same instance (pass it with `BlocProvider.value` if the sheet is pushed on a new route).
- Widget tests that mount the real cubit with a countdown must close it (tree teardown via `BlocProvider(create:)`) or use a fixture without countdowns, otherwise flutter_test reports a pending timer (Pitfall 5).

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
