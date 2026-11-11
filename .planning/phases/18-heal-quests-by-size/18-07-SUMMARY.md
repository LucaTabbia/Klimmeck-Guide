---
phase: 18-heal-quests-by-size
plan: 07
subsystem: journal
tags: [cubit, potions, countdown, server-clock, tdd]
requires: ["18-06", "18-02"]
provides:
  - "PotionCubit(ItemUseRepository): drink(itemId) -> PotionDrinking, then PotionDrunk(itemId, UseItemResult) or PotionRefused(itemId, failure, {recoveryUntil, required sequence}); reset()"
  - "sealed PotionState: PotionIdle, PotionDrinking, PotionDrunk, PotionRefused"
  - "PotionRecoveryCubit({required ServerClockService clock, Duration tick = defaultTick}).follow(DateTime? potionRecoveryUntil); PotionRecoveryState(Duration? remaining) with isRecovering"
  - "MockPotionCubit in test/helpers/mocks.dart"
affects: [18-08, 18-09, 18-13]
tech-stack:
  added: []
  patterns: ["QuestAbandonCubit mutation flow + CompanionOutcome-like increasing sequence on refusals", "SpellRecoveryCubit lazy Timer.periodic on ServerClockService"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_state.dart
    - lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart
    - lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_state.dart
    - test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit_test.dart
  modified:
    - test/helpers/mocks.dart
decisions:
  - "PotionRecoveryCubit is its own cubit in its own folder (potionRecoveryCubit/), created and closed by the Journal «Oggetti» section (18-09); JournalCubit not grown"
  - "Remaining time rounded UP to the minute so the state changes once per minute (Cubit drops equal states)"
  - "Single-flight guard is the state itself: while PotionDrinking, every drink (any item) returns without a call; reset() is refused while drinking"
metrics:
  duration: "~15 min"
  completed: 2026-11-10
---

# Phase 18 Plan 07: Potion cubits Summary

`PotionCubit` (non-optimistic `useItem` state machine with server result or typed refusal carrying the server recovery date and an increasing `sequence`) and `PotionRecoveryCubit` (the «pronta fra …» countdown on `ServerClockService`, rounded up to the minute, timer only during a recovery and cancelled on close).

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | PotionCubit and its states | 8961302 (test), 19b7a3c (feat) |
| 2 | PotionRecoveryCubit, the countdown on the server clock | 37902ae (test), 2a87ca8 (feat) |

## Names and signatures created

- `class PotionCubit extends Cubit<PotionState> with SafeEmit<PotionState>`: `PotionCubit(ItemUseRepository repository)`; `Future<void> drink(String itemId)`; `void reset()`.
- `sealed class PotionState extends Equatable`; `final class PotionIdle()`, `PotionDrinking(String itemId)`, `PotionDrunk(String itemId, UseItemResult result)`, `PotionRefused(String itemId, ItemUseFailure failure, {DateTime? recoveryUntil, required int sequence})`.
- `class PotionRecoveryCubit extends Cubit<PotionRecoveryState> with SafeEmit<PotionRecoveryState>`: `PotionRecoveryCubit({required ServerClockService clock, Duration tick = defaultTick})`, `static const Duration defaultTick = Duration(seconds: 1)`, `void follow(DateTime? potionRecoveryUntil)`.
- `class PotionRecoveryState extends Equatable`: `const PotionRecoveryState(Duration? remaining)`, `bool get isRecovering`.
- `class MockPotionCubit extends MockCubit<PotionState> implements PotionCubit {}` (test/helpers/mocks.dart, after MockCompanionCubit).

## RED failures observed

- Task 1: `Error when reading 'lib/screens/mainScreen/tabs/journal/potionCubit/potion_cubit.dart': No such file or directory`; `test/helpers/mocks.dart:166:41: Error: Type 'PotionState' not found.`; `'PotionCubit' isn't a type.`
- Task 2: `Error when reading 'lib/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart': No such file or directory`; `Method not found: 'PotionRecoveryCubit'.`; `Couldn't find constructor 'PotionRecoveryState'.`

## Verification

- `flutter test test/screens/mainScreen/tabs/journal/potionCubit/potion_cubit_test.dart`: 9 tests green (8 behaviours + «starts idle»).
- `flutter test test/screens/mainScreen/tabs/journal/potionRecoveryCubit test/screens/mainScreen/tabs/journal/potionCubit`: 18 tests green.
- Full `flutter test` (mocks.dart touched): 3842 tests, «All tests passed».
- `flutter analyze --no-fatal-infos`: «47 issues found.» (all info, 0 error, 0 warning) -> ANALYZE_GATE_OK.
- Formatted one by one (all 0 changed): potion_cubit.dart, potion_state.dart, potion_recovery_cubit.dart, potion_recovery_state.dart, potion_cubit_test.dart, potion_recovery_cubit_test.dart, test/helpers/mocks.dart.
- Acceptance greps: cross-cubit/Flutter/Timer in potion_cubit.dart = 0; `D-11)` = 6, `D-19)` = 2; `_clock.now()` = 1, `DateTime.now()` = 0, `_stopTimer();` = 2, hard-coded `Duration(minutes|hours: N` = 0; `Future.delayed` in the countdown test = 0; `D-12)` = 9; `git diff HEAD~2 --stat -- lib/screens/mainScreen/tabs/journal/cubit` empty.

## Deviations from Plan

None - plan executed exactly as written. Additions within the plan's behaviours: an extra «starts idle» test; the single-flight test also proves a drink of a different item during the call makes no call; the null/past test also covers a date equal to the server now; the replace test also checks that `follow(null)` stops the timer.

## Threat mitigations

- T-18-22: «a second drink while drinking makes no call (D-11)».
- T-18-24: no CharacterCubit / other cubit / Timer in potion_cubit.dart (grep 0).
- T-18-25: «turns ready … stops its timer (D-12)», «close cancels the timer (D-12)».
- T-18-23: accepted, countdown is display only.

## Known Stubs

None. No widget, provider or listener yet: wiring belongs to 18-08 / 18-09 (as planned).

## Self-Check: PASSED
