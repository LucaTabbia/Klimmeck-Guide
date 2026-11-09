---
phase: 12-hardening
plan: 06
subsystem: screens
tags: [hardening, logging, release]
requires: ["12-05"]
provides:
  - "Every log of lib/ goes through appLog (silent under kReleaseMode); zero direct debugPrint/print/developer.log outside lib/utils/app_log.dart"
  - "test/utils/app_log_routing_test.dart guards the whole lib/ tree (D-03)"
affects: [12-07, 12-16]
tech-stack:
  added: []
  patterns:
    - "Whole-tree source guard: _routedRoots = ['lib']"
key-files:
  created: []
  modified:
    - test/utils/app_log_routing_test.dart
    - lib/screens/auth/cubit/auth_cubit.dart
    - lib/screens/auth/syncCubit/session_sync_cubit.dart
    - lib/screens/mainScreen/characterCubit/character_cubit.dart
    - lib/screens/mainScreen/cubit/main_screen_cubit.dart
    - lib/screens/mainScreen/questCubit/quest_cubit.dart
    - lib/screens/splash/cubit/splash_cubit.dart
    - lib/shared/components/cached_svg.dart
    - lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart
    - lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart
    - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart
    - lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart
decisions:
  - "Exception values in MainScreenCubit, CachedSvg, LibraryCubit (4), JournalCubit (2), WorldMapCubit reduced to ${e.runtimeType}; other messages verbatim (D-03c)"
metrics:
  duration: "~10 min"
  completed: 2026-11-09
---

# Phase 12 Plan 06: Screen and shared logs through appLog Summary

The remaining 23 direct log calls of `lib/screens` and `lib/shared` (13 files) now go through `appLog`, exception values are reduced to their `runtimeType`, and the routing guard covers the whole `lib/` tree.

## Tasks

| Task | Commit | Description |
|------|--------|-------------|
| 1 RED | 7c1783a | `_routedRoots = ['lib']` in `test/utils/app_log_routing_test.dart` |
| 1 GREEN (partial) | d053093 | auth, sync, character, main screen, quest, splash cubits + CachedSvg routed |
| 2 | 71dadcf | journal (cubit + widget), library, world map, notification preferences/permission routed |

## TDD

- RED: `flutter test test/utils/app_log_routing_test.dart` failed on `no direct log call under lib (D-03)` listing exactly 23 sites.
- Between Task 1 and Task 2 the guard stayed red by design (Task 1 routed 7 files / 10 calls; Task 2 routed the remaining 13 calls); it is green after 71dadcf.
- The seven repository roots of plan 05 are subsumed by `'lib'`: the guard now generates a single test.

## Verification

- Whole-tree grep `grep -rnE '(^|[^A-Za-z_])(debugPrint|print)\(|developer\.log\(' lib --include='*.dart' | grep -v '^lib/utils/app_log.dart:'` prints nothing.
- Task 1 tests: `flutter test test/screens/auth test/screens/mainScreen/characterCubit test/screens/mainScreen/cubit test/screens/mainScreen/questCubit test/screens/splash test/shared` -> 520 passed.
- Task 2 tests: `flutter test test/utils test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/map test/screens/mainScreen/tabs/settings` -> 621 passed.
- Analyzer: `47 issues found.` (all info; 0 error, 0 warning) — down 3 from the 50 baseline (the three `avoid_print` of journal_cubit/world_map_cubit).
- Acceptance: library_cubit `runtimeType` count 4, `error: $e'` count 0; journal_cubit `appLog(` 2; world_map_cubit `appLog(` 1; main_screen_cubit `refreshCities error: ${e.runtimeType}` 1; cached_svg `runtimeType` 1.

## Deviations from Plan

- The acceptance grep `const \['lib'\]` matches the equivalent form `const List<String> _routedRoots = ['lib'];` (the plan allows it): the typed declaration was kept.
- Unused `package:flutter/foundation.dart` imports removed (analyzer warnings after routing) from `auth_cubit.dart`, `notification_preferences_cubit.dart`, `notification_permission_cubit.dart`. `package:flutter/cupertino.dart` in journal_cubit/world_map_cubit is still used (not flagged) and was kept.

## Formatter reflows

`dart format` on touched files reflowed untouched code in the two baseline-dirty files: `journal.dart` (`didChangeDependencies` Tween chain) and `world_map_cubit.dart` (class header on one line, `catch` indentation). In the two settings cubits it joined the now-shorter `appLog(...)` calls onto one line. All other touched files: 0 changed.

## Threat Flags

None: T-12-17 mitigated as planned (routing + runtimeType + whole-tree guard).

## Self-Check: PASSED

- Commits 7c1783a, d053093, 71dadcf present in `git log`.
- All 14 modified files exist.
