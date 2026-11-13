---
phase: 20-rank-specific-prizes-for-group-quests
plan: 01
subsystem: quests
tags: [tests, contract-pins, prizes, mixed-boss, seats]
requires: []
provides:
  - "mixedBossJson / buildMixedBoss fixture (seats paladin x2 + adventurer x1, minTitle adventurer)"
  - "served prize block pins on model, Board sheet and Map overlay (RANKP-01)"
  - "mixed-rank boss seat pins (RANKP-02)"
affects: [20-02, 20-03, 20-04]
tech-stack:
  added: []
  patterns: ["contract pins green at the first run, test-only plan"]
key-files:
  created: []
  modified:
    - test/helpers/fixtures/quest_fixtures.dart
    - test/models/quest/quest_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/models/quest/quest_capacity_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/models/quest/quest_state_label_test.dart
decisions:
  - "No production code: every case pins a contract lib/ already honours (research F1, F4); no rankPrizes parameter added to the fixtures (the payload key is added with a cascade on questJson)"
metrics:
  duration: "~15 min"
  completed: 2026-11-13
  tasks: 2
  files: 8
---

# Phase 20 Plan 01: Contract pins for the served prize block and mixed-rank bosses Summary

Test-only plan: 17 new contract pins prove the app prints exactly the BE-served `prizes` block (any viewer title, Board and Map, `rankPrizes` ignored, no spell row) and judges a mixed-rank boss (paladin x2 + adventurer x1) per seat title; no file under `lib/` changed.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 | a7bd39c7 | test(quests): pin the served prize block on the quest sheet |
| 2 | f0f721f5 | test(quests): pin the seats of a mixed-rank boss |

## First-run results (all GREEN, as expected for contract pins)

### Task 1 (RANKP-01)

| Test | File | First run | Why green |
|------|------|-----------|-----------|
| reads the served block and ignores rankPrizes (D-22) | quest_test.dart | green | `Quest.fromJson` reads only the keys it knows; `tryFromJson` not null (T-20-02) |
| prints the served block whatever the viewer's title (D-07, D-18) | quest_info_sheet_test.dart | green | the rewards area reads `quest.prizes` and never the viewer (paladin, adventurer, hero, null) |
| a rankPrizes list on the payload changes nothing on the sheet (D-22) | quest_info_sheet_test.dart | green | no model field carries the list |
| no spell row: a served spell prints nothing (D-23) | quest_info_sheet_test.dart | green | `spell` is neither parsed nor rendered (research F6); `takeException()` null |
| the served cure lines stay as served (D-07, D-23) | quest_info_sheet_test.dart | green | the cure lines read `quest.prizes.cure` plus the character's injuries, never the title |
| the map sheet prints the served block with no viewer (D-07) | quest_info_overlay_test.dart | green | the overlay forwards the listed quest object (research F2) |

Run: `flutter test` on the three files → 107 tests, All tests passed.

### Task 2 (RANKP-02)

| Test | File | First run | Why green |
|------|------|-----------|-----------|
| draws one line per seat title in wire order (D-03, D-25) | quest_sheet_details_test.dart | green | `_slotLinesOf` collects distinct titles in wire order: «Paladino: 1 / 2», «Avventuriero: 0 / 1», highlight `[false, true]` |
| has no any-rank line (D-02, D-25) | quest_sheet_details_test.dart | green | no null-title seat in the fixture |
| shows the lowest seat title as the minimum (D-25) | quest_sheet_details_test.dart | green | «Titolo minimo: Avventuriero» comes from `minTitle`; rookie ineligible |
| paladin seats full: an adventurer can join, a paladin cannot (D-03, D-25) | quest_capacity_test.dart | green | exact seats per (folded) title |
| adventurer seat full: a paladin can join, an adventurer cannot (D-03, D-25) | quest_capacity_test.dart | green | exact seats per title, no wildcard overflow |
| a paladin never takes the adventurer seat (D-03) | quest_capacity_test.dart | green | no overflow into a lower seat although one seat is free (T-20-03) |
| a hero finds no seat (D-25) | quest_capacity_test.dart | green | no seat for the hero title, no wildcard |
| an adventurer is available on a mixed boss (D-25) | quest_availability_test.dart | green | title gate on `minTitle` passes, the adventurer seat is free |
| a rookie is below the minimum title (D-25) | quest_availability_test.dart | green | `isTitleEligible` runs before the seats → `titleMismatch` |
| a hero finds the mixed boss full (D-25) | quest_availability_test.dart | green | hero is above the minimum, no hero seat → `full` |
| a mixed boss counts the party against every seat (D-25) | quest_state_label_test.dart | green | the counter uses the total of the seats: «In attesa del gruppo 1/3» |

Run: `flutter test test/models/quest test/screens/mainScreen/components/quest_scope_listener_test.dart` → 261 tests, All tests passed (the D-04 rank-up reread pin stays green).

## Verification

- Files formatted one by one with `dart format`: all eight touched test files (quest_info_sheet_test, quest_sheet_details_test, quest_capacity_test, quest_availability_test reflowed by the formatter; the others unchanged).
- Analyzer last line (both tasks): `47 issues found.` → `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error).
- `grep -rn "rankPrizes" lib` → empty; `git diff HEAD~2 --stat -- lib` → empty.
- Acceptance greps: D-22 in quest_test 1; D-07 in quest_info_sheet_test 2; D-23 in quest_info_sheet_test 2; D-07 in quest_info_overlay_test 1; `mixedBossJson` 2; D-25 counts 3 / 3 / 3 / 1.
- Trailer check after each commit: 0.

## Deviations from Plan

None - plan executed exactly as written. (The quest_info_sheet_test file gained the import `package:klimmeck_guide/shared/components/coins_display.dart` for `find.byType(CoinsDisplay)`.)

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/helpers/fixtures/quest_fixtures.dart (mixedBossJson, buildMixedBoss)
- FOUND: a7bd39c7, f0f721f5
