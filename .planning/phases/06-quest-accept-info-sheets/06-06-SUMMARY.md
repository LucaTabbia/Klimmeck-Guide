---
phase: 06-quest-accept-info-sheets
plan: 06
subsystem: quest-info-sheet
tags: [quest, widget, view-model, tdd]
requires: [06-01, 06-02]
provides:
  - QuestSheetDetails.of(quest, viewer) pure view-model (family, title line, slot lines, cost line, blocked reason, loot, lore)
  - questSheetFamilyOf / QuestSheetFamily / QuestSlotLine
  - QuestInfoSheet(quest, viewer, stateLabel) with combat, narrative and service families and widget keys
  - seedSvgCache(assetIds) test helper
affects: [06-07, 06-08]
tech-stack:
  added: []
  patterns: [pure view-model rendered by a stateless widget, token-based provisional visuals]
key-files:
  created:
    - lib/models/quest/quest_sheet_details.dart
    - test/models/quest/quest_sheet_details_test.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/helpers/svg_cache_seed.dart
  modified:
    - lib/shared/components/popup/quest_info_sheet.dart
decisions:
  - "QuestInfoSheet is now a StatelessWidget; duration computed in build"
  - "Slot lines reuse the canRegisterWithTitle overflow formula (D-32), never expose character ids"
metrics:
  tasks: 2
  tests: "1189 -> 1233 passing, analyze 56 issues, 0 errors"
  completed: 2026-10-21
---

# Phase 6 Plan 06: Per-type quest info sheets Summary

Pure `QuestSheetDetails` view-model plus a rewritten `QuestInfoSheet` with three families (combat, narrative, service), blood-red eligibility/balance indicators, per-rank slot lines, live cost line (hard-coded 3000 removed) and optional state label.

## Commits
- cbba3f6 test(quest): add failing tests for the quest sheet view-model
- 9d17738 feat(quest): describe each quest sheet as a pure view-model
- (RED widget) test(quest): add failing widget tests for the quest sheet families
- ce45d66 feat(quest): render quest sheets in combat, narrative and service families

## Deviations from Plan
- [Rule 3] Added missing `quest_lane.dart` import (home of `registeredQuestTypes`) in the view-model; no behavioural change.
- Text columns of combat/service wrapped in `SingleChildScrollView` to avoid overflow on the parchment (provisional layout).

## Known Stubs
None. Missing lore/enemy/loot (BE gap G1) simply omit their blocks.

## Self-Check: PASSED
Files and commits verified; full suite green (1233), analyze 56 issues, 0 errors.
