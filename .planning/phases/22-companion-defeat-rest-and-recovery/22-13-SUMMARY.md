---
phase: 22-companion-defeat-rest-and-recovery
plan: 13
subsystem: models / shared
tags: [companion, result-sheet, ambush, lenient-model]
requires: ["22-12"]
provides: ["QuestCompanionOutcome", "QuestResult.companion", "AmbushReport.isOnFoot", "companion life/defeat/xp/on-foot lines on the result sheet and ambush pages"]
affects: ["22-16 (selects QuestResult.companion and AmbushReport.onFoot)"]
tech-stack:
  added: []
  patterns: ["lenient tryFromJson for a nested served entry", "dated record lines without clock (Pitfall 7)"]
key-files:
  created:
    - lib/models/quest_result/quest_companion_outcome.dart
    - test/models/quest_result/quest_companion_outcome_test.dart
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/models/quest_result/ambush_report.dart
    - lib/utils/quest_outcome_lines.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_result_test.dart
    - test/models/quest_result/ambush_report_test.dart
    - test/utils/quest_outcome_lines_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
    - test/shared/components/popup/ambush_report_carousel_test.dart
decisions:
  - "FE model named QuestCompanionOutcome: CompanionOutcome is taken by the equip outcome in companion_state.dart (plan default)"
  - "A defeated entry without a usable fullLifeAt (null or not after resolvedAt) prints «<nome> è stato sconfitto» alone (plan default, subset of the D-10 copy)"
  - "The companion name is trimmed when parsed; a blank name makes the whole entry null"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 13: Result sheet companion fate Summary

The served companion outcome of a result (`QuestResult.companion`, lenient `QuestCompanionOutcome`) and the ambush «on foot» marker (`AmbushReport.isOnFoot`) are modelled but not selected; the result sheet, and through it every ambush page, prints «Fenrir: 120 / 300 di vita», «Fenrir è stato sconfitto: riposa e tornerà fra 10 h» (duration `fullLifeAt − resolvedAt`), «Fenrir guadagna 12 PE» and «Prosegui a piedi».

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Models | 803b5d79 test(models): expect the companion outcome of a result · 43bc532d feat(models): read the companion outcome and the walk on foot | +9 tests; models + popup + questResultsCubit +1384 green |
| 2 Lines and sheet | 11e5c3dc test(shared): expect companion lines on the result sheet · 20017003 feat(shared): tell the companion's fate on the result sheet | +14 tests; utils + popup + mainScreen/components +606 green |
| 3 Bookkeeping | docs(phase-22): record plan 13 progress | — |

### RED failures
- Task 1: `quest_companion_outcome_test.dart` did not compile (`Undefined name 'QuestCompanionOutcome'`); `quest_result_test.dart` (`companion` getter) and `ambush_report_test.dart` (`isOnFoot` getter) did not compile.
- Task 2: `quest_outcome_lines_test.dart` did not compile (`Method not found: 'companionFightLifeLine'`, `companionDefeatResultLine`, `onFootLineOf`, `No named parameter with the name 'name'`); the sheet and carousel tests did not compile (`companionLifeKey`, `companionDefeatKey`, `onFootKey` missing).
- Cases that pass by absence once compiling (no life line when unharmed, nothing without a served companion, the prize stays text D-35): they guard the conditions and were RED only through compilation.

## What was built
- `QuestCompanionOutcome({required name, required lifeBefore, required lifePoints, required maxLifePoints, isDefeated = false, fullLifeAt})`; `static tryFromJson(Object?)` → null unless a map with a non-blank String `name` and `num` lifeBefore / lifePoints / maxLifePoints; `defeated == true`; `fullLifeAt` via `DateTime.tryParse(...)?.toUtc()` when a String; `toJson` keys name, lifeBefore, lifePoints, maxLifePoints, defeated, fullLifeAt; Equatable.
- `QuestResult.companion` (`QuestCompanionOutcome.tryFromJson(json['companion'])`), in `toJson` and `props`.
- `AmbushReport.isOnFoot` (`json['onFoot'] == true`, default false), `toJson` `'onFoot'`, `props`.
- `quest_outcome_lines.dart`: `companionFightLifeLine`, `companionDefeatResultLine(companion, resolvedAt)`, `companionXpGainedLine(int, {String? name})`, `const onFootLine`, `onFootLineOf(QuestResult)`. No clock.
- `QuestResultSheet`: keys `companionLifeKey`, `companionDefeatKey`, `onFootKey`; life and defeat lines after the injuries, «Prosegui a piedi» right after «Portato a …», the xp line passes `name: _result.companion?.name`.
- Fixtures: `companionOutcomeJson(...)`, `questResultJson(companion:)`, `ambushReportJson(onFoot:)` (keys only when non-null).

## Verification
- `flutter test test/models test/shared/components/popup test/screens/mainScreen/questResultsCubit` → +1384 all passed.
- `flutter test test/utils test/shared/components/popup test/screens/mainScreen/components` → +606 all passed.
- Analyzer 47 info, ANALYZE_GATE_OK after each code task. `grep -rn "companion\|onFoot" lib/graphql` prints nothing (Pitfall 1). Registry unchanged (55).
- Tests +23 → expected suite 4967 (full suite not run).

## Deviations from Plan

- Pitfall 7 widget test: no clock package is used by the sheet, so the test pins «10 h» with a `fullLifeAt` weeks before the wall clock of the run (a duration counted from now would read «0 min») and pumps 5 h more; same text.
- Extra cases: an unharmed-companion sheet shows no on-foot line; the on-foot line's order after «Portato a …»; the companion round trip / props in `quest_result_test` and `ambush_report_test`.
- The doc comment of `onFootLineOf` cites `[onFootLine]` instead of the literal so `grep -cF "Prosegui a piedi"` = 1.
- STATE `Plan: 13 of 17` (the plan's own format), Progress `13/17 | In Progress`. Wave-0 checkbox for `quest_companion_outcome_test.dart` ticked in VALIDATION.

## Known Stubs
None: the fields are lenient and unselected by design until gate plan 22-16.

## Self-Check: PASSED
