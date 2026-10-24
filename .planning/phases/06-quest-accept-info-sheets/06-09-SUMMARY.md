---
phase: 06-quest-accept-info-sheets
plan: 09
subsystem: board
tags: [board, quest-paper, torn, widget-test, tdd]
requires: [06-02, 06-06, 06-07, 06-08]
provides:
  - questPaperAssetIds / questPaperAssetId (type -> asset family, deterministic variant by quest id)
  - stateless keyed Sheet with isTorn
  - Board(cities) listing through boardQuestsFor + standingOf, silent refreshQuests(cityId:) on open
affects: [06-10]
key-files:
  created:
    - lib/models/quest/quest_paper_asset.dart
    - test/models/quest/quest_paper_asset_test.dart
    - test/screens/mainScreen/tabs/board/sheet_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
  modified:
    - lib/screens/mainScreen/tabs/board/components/sheet.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/main_screen.dart
decisions:
  - "Selection on the Board is kept by quest id and re-resolved against the listed quests, so an open sheet follows catalogue refreshes"
  - "No viewer (character off a city marker, or quests not loaded) means no papers at all, never an exception"
metrics:
  tasks: 2
  tests: "1288 passing, analyze 54 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 09: Board listing and torn papers Summary

The Board lists the quests of the current city, every worldMission, the story of the exact title and the owner's active lanes, with torn papers where the quest is the owner's or full, and opens `QuestInfoSheet` for the live viewer.

## Commits

- ef99875 test(board): add failing tests for deterministic quest papers
- ec81f09 feat(board): pick quest papers deterministically by type and torn state
- 5b80b48 test(board): add failing tests for the board listing
- 243f4fa feat(board): list the quests of the current city with their torn state

## Notes

- `Sheet` no longer uses `Random`; the image is chosen from the quest id, so rebuilds never change it. Story now has a torn variant for its owner.
- `board.dart` hand-edited (not format-clean); removing the dead `quest.id ?? ...` cleared 2 analyzer warnings: total 56 -> 54.
- `cityPointIds` is used only when `QuestLoaded.cityId` equals the current city id (T-06-09-01).

## Deviations from Plan

None - plan executed exactly as written.

## Known Stubs

None.

## Self-Check: PASSED
