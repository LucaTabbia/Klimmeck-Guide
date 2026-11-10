---
phase: 18-heal-quests-by-size
plan: 08
subsystem: journal
tags: [notices, listener, session-wiring, potions, tdd]
requires: ["18-03", "18-07"]
provides:
  - "potionNoticeFor(ItemUseFailure failure, {Duration? remaining}) -> KGNotification? and const potionNoticeTitle = 'Pozione non bevuta'"
  - "PotionOutcomeListener({required Widget child}): session-level banner for PotionRefused, silent refreshCharacter() after notOwned / timedOut"
  - "BlocProvider<PotionCubit> at the authenticated shell (PotionCubit(ItemUseRepository(graphQl: graphQl))), closed with the shell"
  - "PotionOutcomeListener mounted in MainScreen inside CompanionOutcomeListener"
affects: [18-09, 18-13]
tech-stack:
  added: []
  patterns: ["companion_notice.dart notice function", "CompanionOutcomeListener session-level BlocListener with publishNotice + dedupKey carrying the refusal sequence"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart
    - lib/screens/mainScreen/components/potion_outcome_listener.dart
    - test/screens/mainScreen/tabs/journal/potionCubit/potion_notice_test.dart
    - test/screens/mainScreen/components/potion_outcome_listener_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/auth/authenticated_shell_leak_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/main_screen_quest_results_test.dart
decisions:
  - "Planner's choice kept: silent refreshCharacter() only after notOwned / timedOut; recovery, no-effect and every other refusal reread nothing; a successful drink publishes nothing and rereads nothing"
  - "Remaining time = server recoveryUntil (on PotionRefused) minus ServerClockService.now(), never the character's local potionRecoveryUntil; null / zero / negative -> generic notice"
  - "dedupKey = 'potion|<failure>|<itemId>|<sequence>' so two identical refusals inside the display window are both shown"
metrics:
  duration: "~20 min"
  completed: 2026-11-10
---

# Phase 18 Plan 08: Potion notices and wiring Summary

Refused potions become a `KGNotification` parchment banner «Pozione non bevuta» with the fixed copy chosen by the `ItemUseFailure` only and the server's remaining time for a recovery in course; `PotionCubit` now lives at the authenticated shell and `PotionOutcomeListener` sits in the main screen's outcome-listener chain.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | potionNoticeFor and the session-level PotionOutcomeListener | b83feee (test), 2ee935c (feat) |
| 2 | PotionCubit at the shell and the listener in the main screen | 008b3be (test), 7e232d9 (feat) |

## Names and signatures created

- `lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart`: `const String potionNoticeTitle = 'Pozione non bevuta';` private `_genericLine`; `KGNotification? potionNoticeFor(ItemUseFailure failure, {Duration? remaining})`; private `_recoveringLine(Duration?)` uses `potionReadyInLine` (item_lines.dart).
- `lib/screens/mainScreen/components/potion_outcome_listener.dart`: `class PotionOutcomeListener extends StatelessWidget` (`const PotionOutcomeListener({super.key, required this.child})`); `BlocListener<PotionCubit, PotionState>` with `listenWhen: current is PotionRefused && previous != current`; reads `ServerClockService`, `InAppNotificationsCubit`, `CharacterCubit` from the context; static `_staleViewFailures = {notOwned, timedOut}`.
- Shell: `BlocProvider<PotionCubit>(create: (_) => PotionCubit(ItemUseRepository(graphQl: graphQl)))` right after the `CompanionCubit` provider.
- Main screen: `CompanionOutcomeListener(child: PotionOutcomeListener(child: _buildPagesWithSatchel(...)))`.

## RED failures observed

- Task 1: compile failure — `Error when reading 'lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart': No such file or directory`, `Method not found: 'potionNoticeFor'` (and the missing listener file).
- Task 2: `Could not find the correct Provider<PotionCubit> above this _ShellProbe Widget` (leak test, 4 failures incl. tearDownAll), `provides the potion cubit and closes it on removal (D-11)` failed with ProviderNotFoundException, `mounts the potion outcome listener in the session chain (D-18)` failed (listener not found). 6 failures, 63 passing.

Test files that needed the new provider: `test/screens/mainScreen/main_screen_test.dart` (satchel-wiring group, `MockPotionCubit` idle) and `test/screens/mainScreen/main_screen_quest_results_test.dart` (`_MainScreenHarness`, `MockPotionCubit` idle).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Pinned test] Shell reference count in the leak test 24 -> 25**
- **Found during:** Task 2 GREEN
- **Issue:** `authenticated_shell_leak_test.dart` pins `expect(references, hasLength(24))` (the number of shell-provided objects read by the probe); adding `context.read<PotionCubit>()` makes it 25. The RED run hid it behind the ProviderNotFoundException.
- **Fix:** pin moved to 25 in the GREEN commit (noted in its body).
- **Files modified:** test/screens/auth/authenticated_shell_leak_test.dart
- **Commit:** 7e232d9

No other deviation. The shell doc comment names no Journal cubit, so it was left untouched.

## Gates

- `flutter test test/screens/mainScreen/tabs/journal/potionCubit test/screens/mainScreen/components/potion_outcome_listener_test.dart` -> 21 green (12 new + 9 of 18-07).
- `flutter test test/screens/auth test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/main_screen_quest_results_test.dart test/screens/mainScreen/components test/screens/mainScreen/tabs/journal/potionCubit` -> 383 green.
- Full `flutter test` -> 3856 tests, «All tests passed» (3842 + 14 new).
- `flutter analyze --no-fatal-infos` -> `47 issues found.` (all info, 0 error, 0 warning).
- `bash tool/hardening_check.sh` -> `hardening_check: OK`.
- `dart format` run one by one on the 10 touched files; all formatter-clean (the two new test files were reflowed once before the RED commit).
- No `JournalCubit` change (`git diff fd40bb3 --stat -- lib/screens/mainScreen/tabs/journal/cubit` empty).

## Threat surface

T-18-26..T-18-29 mitigated as planned (fixed copy by enum, server date only, sequence in the dedup key, no notice for `unauthenticated`). No new surface.

## Known Stubs

None. No fragment selects the new names yet (gated plan 18-12, as designed).

## Self-Check: PASSED

- Files created exist: potion_notice.dart, potion_outcome_listener.dart, potion_notice_test.dart, potion_outcome_listener_test.dart.
- Commits b83feee, 2ee935c, 008b3be, 7e232d9 present in `git log`.
