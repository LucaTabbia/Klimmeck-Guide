---
phase: 20-rank-specific-prizes-for-group-quests
plan: 02
subsystem: quest-results
tags: [models, result-sheet, dungeon, aid, turns, backend-notes]
requires: [20-01]
provides:
  - "DungeonTurnKind { exploration, fight } with lenient fromWire (lib/models/enums/dungeon_turn_kind.dart)"
  - "QuestResult.turnsTotal / turnsCompleted / lastTurn / lastTurnKind (lenient, in toJson and props)"
  - "dungeonTurnLine(QuestResult) pure helper and QuestResultSheet.turnsKey in the stages slot, fallback to the stages line"
  - "fixtures: four turn params on questResultJson / dungeonResultJson, aidDungeonResultJson"
  - "BACKEND-NOTES.md (FE handoff for the BE Phase 21; §3 waits for 20-04)"
affects: [20-03, 20-04]
tech-stack:
  added: []
  patterns: ["lenient enum via asNameMap()", "served numbers printed as text, no arithmetic on the device"]
key-files:
  created:
    - lib/models/enums/dungeon_turn_kind.dart
    - .planning/phases/20-rank-specific-prizes-for-group-quests/BACKEND-NOTES.md
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/utils/quest_outcome_lines.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_result_test.dart
    - test/utils/quest_outcome_lines_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
decisions:
  - "The Italian turn copy lives only in dungeonTurnLine; DungeonTurnKind carries no label"
  - "turnsTotal <= 0 is treated as absent (display guard, not a game rule)"
  - "rescued, death and gmCompleted get no turn line even with turn fields filled (ruling W2)"
metrics:
  duration: "~20 min"
  completed: 2026-11-13
---

# Phase 20 Plan 02: Dungeon turn line on the result sheet Summary

Four lenient dungeon-turn counters on `QuestResult` (`DungeonTurnKind` through `asNameMap()`), one pure `dungeonTurnLine` helper printing the BE's numbers as served in the stages slot of the result sheet, falling back to «Esplorazione: tappa N di M» when the BE sends no turns, plus the FE handoff `BACKEND-NOTES.md`. No fragment or document touched: against the BE of today the sheet is identical.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | 6d4a30ae | test(models): expect the dungeon turn fields on the quest result |
| 1 GREEN | abcd9653 | feat(models): read the dungeon turn counters on the quest result |
| 2 RED | 1d894773 | test(utils): expect one dungeon turn line on the result sheet |
| 2 GREEN | ddb87f04 | feat(shared): print the dungeon turn line on the result sheet |
| 3 | 9e0c2021 | docs(phase-20): add the backend notes of the rank prizes phase |

## TDD evidence

Task 1 RED (`flutter test -r expanded test/models/quest_result/quest_result_test.dart`, +67 -3 at the new group, 87 pass / 3 fail overall):
```
dungeon turns (Phase 20) reads the four turn fields of a dungeon result (D-22) [E]
  Expected: <8>
    Actual: <null>
dungeon turns (Phase 20) reads a fight as the last turn kind (D-22) [E]
  Expected: 'fight'
    Actual: <null>
dungeon turns (Phase 20) the turn fields are part of the props (D-22) [E]
  Expected: not QuestResult:<…> Actual: QuestResult:<…>   (equal today)
```
Green at the first run (pins, as the plan expected): «absent turn fields read as null» (lookup of a missing key is null), «an unknown turn kind is null and keeps the result», «a non-number turn count is null and keeps the result», «a non-string turn kind is null» (the keys were ignored before the fields existed; they pin against a future `byName` or cast).

Task 2 RED (`flutter test -r expanded test/utils/quest_outcome_lines_test.dart test/shared/components/popup/quest_result_sheet_test.dart`):
```
test/utils/quest_outcome_lines_test.dart:84:9: Error: Method not found: 'dungeonTurnLine'.
dungeon turns (Phase 20) a dungeon with turns shows one turn line in the stages slot (D-21) [E]
dungeon turns (Phase 20) a won dungeon aid shows the reached turn and the rescued count (D-21) [E]
```
Green at the first run in the sheet group: «no prize-share line» (no such copy exists), «without turns the stages line stays (D-24)» (today's line), «no turn line outside a dungeon (D-21)» (no widget with the key). The RED sheet test used `const ValueKey('questResult.turns')`, switched to `QuestResultSheet.turnsKey` in GREEN.

GREEN: `flutter test test/models/quest_result test/utils test/shared/components/popup test/screens/mainScreen/main_screen_quest_results_test.dart` → **430 tests, all passed** (the untouched stages pins of `quest_result_sheet_test.dart` «dungeon and companion» included). New tests in this plan: 7 (model) + 13 (helper) + 5 (sheet) = **25**; expected full suite 4256 + 25 = **4281** (not run here, gate plan 20-03).

## Final copy as implemented

`lib/utils/quest_outcome_lines.dart` — exactly the table of `20-REPO-RULES.md` §Contract: «Turni superati: C di T», «Ferito raggiunto al turno L di T», «Caduto al turno L di T, in esplorazione», «Caduto al turno L di T, in uno scontro», «Caduto al turno L di T»; `null` for `turnsTotal` null/≤ 0 and for `rescued`, `death`, `gmCompleted`. The `rescued || death || gmCompleted` pattern compiled as written (the formatter put it on three lines).

## Formatting and analyzer

`dart format` file by file: quest_result_fixtures.dart, quest_result_test.dart, dungeon_turn_kind.dart, quest_result.dart, quest_result_sheet.dart, quest_result_sheet_test.dart (0 changed); quest_outcome_lines_test.dart and quest_outcome_lines.dart (reflowed). Analyzer after each code task: `47 issues found.` → `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error). `git diff 61a04404 --stat -- lib/graphql` empty.

## Deviations from Plan

None in code - plan executed as written. Minor: in `quest_result_sheet.dart` the new `_turnsOrStages()` sits right above `_stagesText()`, with the existing doc comment of `_stagesText()` kept attached to it. In `BACKEND-NOTES.md` §4 the orchestrator's BE facts (BE plans 21-08..21-10, planned on BE branch `feat/21-…`, not merged) are appended after the eight questions; they answer question 5 (turn fields are filled on `death`, the FE prints no line anyway) and half of question 6 (lost fight without aid = `failure`; `awaitingAid` still open).

## Threat mitigations

T-20-05 (`asNameMap`, `_countFrom`, «keeps the result» pins, `byName` = 0), T-20-06 (no `+ 1` in helper and sheet, «never adds one» and «no prize-share line» cases), T-20-07 (`turnsTotal` ≤ 0 → fallback), T-20-08 (secret grep = 0), T-20-09 (no `lib/graphql` change).

## Park note for the orchestrator

Plans 20-03 and 20-04 are GATED on the BE Phase 21 merge (selection in `QuestResultFragment`, schema check, device E2E); the phase parks at 02/4 until then.

## Self-Check: PASSED

Files exist (dungeon_turn_kind.dart, BACKEND-NOTES.md, this SUMMARY); commits 6d4a30ae, abcd9653, 1d894773, ddb87f04, 9e0c2021 found in `git log`.
