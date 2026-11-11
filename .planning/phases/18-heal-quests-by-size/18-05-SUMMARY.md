---
phase: 18-heal-quests-by-size
plan: 05
subsystem: shared
tags: [shared, quest-result, item-row, potions, recovery, tdd]
requires: ["18-01", "18-02", "18-03"]
provides:
  - "QuestResultSheet.healedKey = ValueKey('questResult.healed'): «Guarite: …» line between the HP bar and the injuries added, hidden when injuriesHealed is empty"
  - "ItemRow(isDisabled: false, statusLine: null): «Ricarica: …» line (key item-recovery-<id>), dimmed card (AnimatedOpacity key item-card-opacity-<id>), status line (key item-status-<id>)"
affects: [18-08, 18-09, 18-12, 18-13]
tech-stack:
  added: []
  patterns: ["display strings from the pure line helpers of lib/utils/item_lines.dart; disabled look reuses pendingInkOpacity / pendingInkDuration"]
key-files:
  created: []
  modified:
    - lib/shared/components/popup/quest_result_sheet.dart
    - lib/shared/components/item_row.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
    - test/shared/components/item_row_test.dart
decisions:
  - "The disabled look wraps the card inside ItemRow (AnimatedOpacity), loot_item_card.dart untouched (formatter-dirty)"
  - "ItemRow decides nothing: isDisabled and statusLine come from the caller, both off by default (T-18-13)"
metrics:
  duration: "~15 min"
  completed: 2026-11-10
  tasks: 2
  files: 4
---

# Phase 18 Plan 05: Result sheet «Guarite» and ItemRow recovery Summary

The result sheet prints «Guarite: <labels>» from `QuestResult.injuriesHealed` between the HP delta bar and the «Ferite» section; every loot `ItemRow` with a `recovery` prints «Ricarica: …» under its «Cura: …» line, and `ItemRow` can be drawn disabled (dimmed card) with a status line, both off by default so no call site changed.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | «Guarite» on the result sheet | 894b677 (test), ef025e5 (feat) |
| 2 | ItemRow recovery line, disabled look, status line | bf91038 (test), a8a2a24 (feat) |

## Names and signatures

- `lib/shared/components/popup/quest_result_sheet.dart`: `static const Key healedKey = ValueKey('questResult.healed');` (after `injuriesKey`); `_content()` spreads `..._line(healedLine(_result.injuriesHealed), QuestResultSheet.healedKey)` between `..._hp()` and `..._injuries()`; new import `package:klimmeck_guide/utils/item_lines.dart`.
- `lib/shared/components/item_row.dart`: ctor tail `this.onLongTap, this.isDisabled = false, this.statusLine`; fields `final bool isDisabled;`, `final String? statusLine;`; card wrapped in `AnimatedOpacity(key: ValueKey('item-card-opacity-<id>'), opacity: isDisabled ? KlimmeckGuideTheme.pendingInkOpacity : 1, duration: KlimmeckGuideTheme.pendingInkDuration)`; `_buildTexts(effectLine, injuriesLine, recoveryText)` appends `Text(key: ValueKey('item-recovery-<id>'))` then `Text(key: ValueKey('item-status-<id>'))`. `onSelect` still reaches the card only; a disabled row is expected to be built without `onSelect`.

## RED failures observed

- Task 1: `Error: Member not found: 'healedKey'.` (compile failure of quest_result_sheet_test.dart)
- Task 2: `Error: No named parameter with the name 'isDisabled'.` (compile failure of item_row_test.dart)

## Gates

- `flutter test test/shared/components/popup`: 155 tests, All tests passed.
- `flutter test test/shared/components test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop`: 517 tests, All tests passed (all ItemRow consumers: journal, shop components, result sheet).
- `flutter test test/shared/components/item_row_test.dart`: 13 tests.
- `flutter analyze --no-fatal-infos`: `47 issues found.` (47 info, 0 error, 0 warning), unchanged.
- `dart format` on the four touched files one by one (the two lib files 0 changed; the two test files only reflowed the new groups).
- Acceptance greps: all as specified (`turns` = 0 in item_row.dart; D-06) = 3, D-19) = 1, D-13) = 3, D-12) = 4; no diff under `lib/shared/components/cards` or `lib/screens/mainScreen/tabs/shop`; no changed line touching `_consumables` / `_itemRows`).

## Deviations from Plan

None - plan executed exactly as written. Note: the orchestrator's progress `5/13` and `Plan: 5 of 13` (no zero padding) were used instead of the plan's `05/13`.

## Known Stubs

None.

## Self-Check: PASSED
