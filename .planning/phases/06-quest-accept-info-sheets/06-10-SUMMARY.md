---
phase: 06-quest-accept-info-sheets
plan: 10
subsystem: board
tags: [board, tear, quest-acceptance, bloc-listener, widget-test, tdd]
requires: [06-03, 06-04, 06-05, 06-07, 06-08, 06-09]
provides:
  - Swipe-left tear on the Board QuestInfoSheet firing QuestAcceptanceCubit.accept
  - QuestAcceptanceOutcomeListener (session-level banner, stale-list refresh, reset)
  - Board.onQuestAccepted -> MainScreen jumps to the Map page
affects: [06-11, 06-12]
key-files:
  created:
    - lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart
    - test/screens/mainScreen/components/quest_acceptance_outcome_listener_test.dart
    - test/screens/mainScreen/tabs/board/board_acceptance_test.dart
  modified:
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - test/screens/mainScreen/main_screen_test.dart
decisions:
  - "Banner, refreshQuests and reset() live in QuestAcceptanceOutcomeListener mounted above the PageView; the Board listener only recomposes on failure and calls onQuestAccepted on success"
  - "The tearable child is wrapped in a transparent ColoredBox so the swipe also registers on transparent areas of the sheet"
metrics:
  tasks: 2
  tests: "1306 passing, analyze 54 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 10: Swipe-to-accept wiring Summary

Tearing the Board's open quest sheet now accepts the quest (no dialog, no undo): success lands on the Map tab, a rejection recomposes the paper and shows the domain banner, even when the answer arrives after the user left the Board.

## Tasks

| Task | Commit | Notes |
| ---- | ------ | ----- |
| 1 RED | d2921aa | failing interaction tests |
| 1 GREEN | 23b3727 | `TearablePaper` around the selected `QuestInfoSheet` (`canTear: standingOf(...).canAccept`, `isEnabled` off while `QuestAccepting`), `accept(characterId: viewer.characterId, ...)` |
| 2 RED | 9d0006e | failing outcome tests incl. "rejection after leaving the Board still publishes the banner" |
| 2 GREEN | 23bd194 | `QuestAcceptanceOutcomeListener`, Board `BlocListener` (recompose / `onQuestAccepted`), `MainScreen` mount + `_showMap` |

## Deviations from Plan

**1. [Rule 3 - Blocking] Existing harnesses needed the new provider.** `board_test.dart` (06-09) and `main_screen_test.dart` (06-08) broke because the Board/MainScreen now read `QuestAcceptanceCubit`; added the mock provider there (and a MainScreen-level test that a rejection while on another tab still publishes the banner and resets). Files outside the plan list, test-only.

**2. [Rule 2 - Robustness] Transparent `ColoredBox` around `QuestInfoSheet` inside `TearablePaper`.** The paper's `GestureDetector` defers to its child; transparent regions of the sheet would not start the drag. `ColoredBox(Colors.transparent)` makes the whole sheet hit-testable without touching `tearable_paper.dart`.

**3. Test tooling.** `pumpAndSettle` times out on the Board (looping animations), so the tests use bounded `pump`s; the sheet animation needs a pump before the 400 ms pump to start; drags start at y=180 because the sheet is taller than the 360 px viewport; `registerFallbackValue(KGNotification)` added where `any()` is used.

## Notes

- The plan's grep `refreshQuests(cityId: _currentCityId` does not match literally because the formatter wraps the call over lines; the behavior (and the call) is present and tested.
- `board.dart` hand-edited (re-indented the wrapped Stack by hand); `main_screen.dart` and new files are format-clean.
- An acceptance answered while the Board is not mounted navigates nowhere (by design); only the banner must survive.
- Manual device smoke against BE `develop` not run here (reserved for 06-12).

## Known Stubs

None.

## Self-Check: PASSED

Files and commits d2921aa, 23b3727, 9d0006e, 23bd194 verified; full `flutter test` green (1306), `flutter analyze` 54 issues (<= 56), 0 errors.
