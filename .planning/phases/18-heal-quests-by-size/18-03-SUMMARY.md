---
phase: 18-heal-quests-by-size
plan: 03
subsystem: utils
tags: [utils, lines, copy, cure, potions, recovery, tdd]
requires: ["18-01", "18-02"]
provides:
  - "curableInjuriesLine(QuestCure?, List<InjuryType>?) -> String? (viewer-filtered, character order, deduplicated)"
  - "lifeShareLine(QuestCure?) -> String? («Vita: almeno il N%», elided «l'» for 8, 11, 80-89, «Vita: al massimo» at share >= 1, null at share <= 0)"
  - "healedLine(List<InjuryType>) -> String? («Guarite: …», given order)"
  - "recoveryLine(LootRecovery?) -> String? («Ricarica: …» via formatGameDuration)"
  - "potionReadyInLine(Duration) -> String («pronta fra …» via formatGameDuration)"
affects: [18-04, 18-05, 18-09]
tech-stack:
  added: []
  patterns: ["pure top-level line helpers next to healedInjuriesLine, one humaniser (formatGameDuration)"]
key-files:
  created: []
  modified:
    - lib/utils/item_lines.dart
    - test/utils/item_lines_test.dart
decisions:
  - "curableInjuriesLine uses a Set literal over the character's injuries: character order, each label once (D-03)"
  - "lifeShareLine rounds share × 100 to the nearest integer; the elision rule is a private _elidesArticle(int) (D-21)"
  - "the countdown label keeps the planner's name potionReadyInLine (not in the REPO-RULES list; added, nothing renamed)"
metrics:
  duration: "~8 min"
  completed: 2026-11-10
  tasks: 2
  files: 2
---

# Phase 18 Plan 03: Line helpers Summary

Five pure line helpers in `lib/utils/item_lines.dart` — viewer-filtered cure line, life row with Italian article elision, healed line, recovery line and potion countdown — all with the fixed REPO-RULES copy, durations humanised by the untouched `formatGameDuration`.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | curableInjuriesLine, lifeShareLine, healedLine | bbabc68 (test), 9041eff (feat) |
| 2 | recoveryLine, potionReadyInLine | bb4f2f1 (test), f58c06b (feat) |

## Signatures

```dart
String? curableInjuriesLine(QuestCure? cure, List<InjuryType>? characterInjuries);
String? lifeShareLine(QuestCure? cure);
String? healedLine(List<InjuryType> injuries);
String? recoveryLine(LootRecovery? recovery);
String potionReadyInLine(Duration remaining);
```

New imports in `item_lines.dart`: `quest/quest_cure.dart`, `loot_recovery.dart`, `utils/game_duration_format.dart`. No `package:flutter/` import.

## RED failures observed

- Task 1: compile failure, `Error: Method not found: 'curableInjuriesLine'.` (and `lifeShareLine`, `healedLine`).
- Task 2: compile failure, `Error: Method not found: 'recoveryLine'.` (and `potionReadyInLine`).

No case was green at the first run (all helpers were new).

## Tests

- `flutter test test/utils/item_lines_test.dart`: 35 tests, all passed (18 before the plan; Task 1 adds 12 → 30: curableInjuriesLine 5, lifeShareLine 5, healedLine 2; Task 2 adds 5 → 35: recoveryLine 3, potionReadyInLine 2).
- `flutter test test/utils`: 110 tests, all passed (the pinned `game_duration_format_test.dart` untouched).
- `git diff HEAD~4 --stat -- lib/utils/game_duration_format.dart test/utils/game_duration_format_test.dart` prints nothing.

## Gates

- Analyzer last line: `47 issues found.` (47 info, 0 error, 0 warning; unchanged from baseline); `ANALYZE_GATE_OK` after both tasks.
- `dart format` run on `lib/utils/item_lines.dart` and `test/utils/item_lines_test.dart` only, one by one.
- Greps: `severity` = 0, `QuestType` = 0, literal `Duration(minutes|hours|seconds` in the helper = 0, `formatGameDuration(` = 2.
- Trailer check `0` after every commit.

## Deviations from Plan

None - plan executed exactly as written. Bookkeeping uses the orchestrator's `3/13` / `Plan: 3 of 13` instead of the plan's `03/13`.

## Notes for later plans

- Edge values of `lifeShareLine` left as specified: a share in [0.995, 1) prints «Vita: almeno il 100%»; a share in (0, 0.005) prints «Vita: almeno il 0%» (only exactly 0 hides the row). The BE is not expected to serve them.

## Threat Flags

None.

## Self-Check: PASSED
