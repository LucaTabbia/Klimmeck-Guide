---
phase: 19-model-review
plan: 06
subsystem: ui
tags: [companions, quest-result, result-sheet, lenient-parse, window, tdd]
requires: ["19-05"]
provides:
  - "QuestResult.petXpGained (int, lenient: absent, non-number, zero or negative → 0; in toJson and props)"
  - "companionXpGainedLine(int petXpGained) in lib/utils/quest_outcome_lines.dart (null at zero and below)"
  - "QuestResultSheet.companionXpKey (ValueKey('questResult.companionXp')): the line right after the character xp line"
  - "questResultJson(petXpGained: …) in test/helpers/fixtures/quest_result_fixtures.dart (default 0, always written)"
affects: [19-11, 19-13]
tech-stack:
  added: []
  patterns: ["additive field before the gate: model + line + sheet on fixtures, selection in the gated flip (Phase 18 pattern)"]
key-files:
  created: []
  modified:
    - lib/models/quest_result/quest_result.dart
    - lib/utils/quest_outcome_lines.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/models/quest_result/quest_result_test.dart
    - test/utils/quest_outcome_lines_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
decisions:
  - "The helper lives in quest_outcome_lines.dart (result-sheet lines), not in item_lines.dart (Journal/shop companion strings) — the planner's choice, kept"
  - "The companion line does not depend on the character xp line: it shows with xpGained 0"
metrics:
  duration: "~10 min"
  completed: 2026-11-11
  tasks: 2
  files: 7
---

# Phase 19 Plan 06: Companion xp on the quest result and on the result sheet — Summary

`QuestResult.petXpGained` is read leniently (anything unreadable is 0), `companionXpGainedLine` prints «Il tuo compagno guadagna 12 PE», and the result sheet hosts it right after the character xp line — invisible against the BE of today, because the field is selected only from the gated plan 19-11.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `06fa27c` | test(models): expect the companion xp on the quest result |
| 2 | `ea22354` | feat(models): read the companion xp gained from the result |
| 3 | `2ecab6a` | test(shared): expect the companion xp line on the result sheet |
| 4 | `bc5b078` | feat(shared): show the companion xp on the result sheet |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/models/quest_result/quest_result_test.dart test/utils/quest_outcome_lines_test.dart` → `+0 -2: Some tests failed.`, compile failure of both files, as the plan expected:

- `test/models/quest_result/quest_result_test.dart:662:21: Error: The getter 'petXpGained' isn't defined for the type 'QuestResult'.` (also :669, :677, :685)
- `test/utils/quest_outcome_lines_test.dart:73:14: Error: Method not found: 'companionXpGainedLine'.` (also :77, :78)

The eight new cases were not observed individually in RED (compile failure of the file).

**Task 2** — `flutter test test/shared/components/popup/quest_result_sheet_test.dart` → `+0 -1: Some tests failed.`, compile failure:

- `quest_result_sheet_test.dart:1126:57: Error: Member not found: 'companionXpKey'.` (also :1138, :1148, :1163)

The four new cases were not observed individually in RED; in particular «no companion line at zero (D-03)» would be green before the implementation by construction (pin of the window state).

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models/quest_result test/utils` (Task 1 `<verify>`) | `+230: All tests passed!` |
| `flutter test test/shared/components/popup test/screens/mainScreen/main_screen_quest_results_test.dart` (Task 2 `<verify>`) | `+168: All tests passed!` |
| plan `<verification>` (`test/models/quest_result test/utils test/shared/components/popup`) | `+395: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `final int petXpGained` 1 · `'petXpGained': petXpGained` (model) 1 · `String? companionXpGainedLine(int petXpGained)` 1 · `'Il tuo compagno guadagna 12 PE'` in the lines test 1 · `D-03)` 6 (model test, ≥ 6) / 2 (lines test, ≥ 2) · `petXpGained` in `lib/graphql/fragments/quest_result_fragment.dart` 0.

Task 2: `ValueKey('questResult.companionXp')` 1 · `companionXpGainedLine(_result.petXpGained)` 1 (single line, no `grep -A2` needed) · `Il tuo compagno guadagna` in the sheet 0 (the copy lives in the helper) · `D-03)` in the sheet test 6 (≥ 4; two matches are older titles naming the Phase 9 D-03).

Plan-wide: `git diff cef24bd --stat -- lib/graphql` empty (window rule D-15). `git status --short` → ` M pubspec.lock` only.

## What was built

- `quest_result.dart`: ctor `this.petXpGained = 0`, the field next to `xpAfter`, `petXpGained: _nonNegativeInt(json['petXpGained'])` with the private `_nonNegativeInt` (`json is num && json > 0 ? json.toInt() : 0` — no existing helper did this: `_countFrom` returns a nullable and keeps negatives), `toJson` key, `props`. The model has no `copyWith`.
- `quest_outcome_lines.dart`: `companionXpGainedLine` — the served number, no arithmetic, no reference to the enemies' xp or to `maxXp` (T-19-21).
- `quest_result_sheet.dart`: `companionXpKey` next to `xpKey`; the entry after `..._line(_xpText(), QuestResultSheet.xpKey)` with the same `_line` builder (`bodyMedium`, same top padding): no new style, icon or chrome. The file already imported `quest_outcome_lines.dart`.
- Fixture: `questResultJson` takes `int petXpGained = 0` and always writes the key (after `xpAfter`).

## Files formatted

`dart format` one by one on the seven touched files. Reflowed: only `quest_result_sheet_test.dart` (the added group); the other six were already clean after the edit.

## Deviations from Plan

None — plan executed as written. Notes:

- «an absent companion xp is 0 (D-03)» builds the fixture with `petXpGained: 12` and then removes the key, so the zero cannot come from the fixture default.
- «a companion xp that is not a number is 0 (D-03)» also asserts `tryFromJson` keeps the result (T-19-22), for each of `'12'`, `null`, `[]`.
- «no companion line at zero (D-03)» also asserts that no text containing «Il tuo compagno» exists.
- «the companion line shows without character xp (D-03)» uses `xpGained: 0, xpAfter: 200` and asserts the xp key is absent.

## Notes for the next plans

- **19-11 (gate):** selecting `petXpGained` in `quest_result_fragment.dart` (after `xpAfter`, research :89) is all it takes to light the line up — no model or widget change. The line also appears on the ambush carousel, which reuses the sheet.
- `questResultJson` now always writes `'petXpGained'`: a test that needs the payload of the BE of today removes the key (`..remove('petXpGained')`). Recorded-payload pins that compare whole maps against `questResultJson()` would see the extra key; none failed in the suites run here (`test/models/quest_result`, `test/utils`, `test/shared/components/popup`, `main_screen_quest_results_test.dart`) — the full suite runs at the gate plan.
- A fractional number on the wire is truncated (`toInt()`), as for the other counters of the model.
- **Device E2E (19-13):** a fight with the equipped companion → «Il tuo compagno guadagna N PE» right under «Esperienza: …»; a result without xp for the character (e.g. a defeat) still shows the companion line if the BE serves a gain; no companion equipped → no line.

## Known Stubs

None. The line is hidden until 19-11 by design (window D-15), not a stub: the data source is wired on the model.

## Threat Flags

None — no new surface. T-19-21 (no share or cap computed: helper prints the served number), T-19-22 (lenient parse pinned for absent / non-number / negative, result kept), T-19-23 (field in `props`, test) are covered above.

## Self-Check: PASSED

- The seven modified files exist; no file created besides this summary.
- Commits `06fa27c`, `ea22354`, `2ecab6a`, `bc5b078` are in `git log`.
