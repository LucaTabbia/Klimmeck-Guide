---
phase: 22-companion-defeat-rest-and-recovery
plan: 08
subsystem: quests
tags: [companion, quest-sheet, innkeeper, companion-card, long-press, d-06, d-34, d-35]
requires: ["22-03 PetFragment (today's SDL fields)", "22-04 CompanionCard", "22-05 showCompanionDetails", "22-07 CompanionRow.onLongPress"]
provides: ["QuestFragment prizes.pet through PetFragment", "QuestSheetDetails.petPrize (Pet?)", "CompanionCard prize on QuestInfoSheet with details on long press", "innkeeper prize rows and prize catalogue open the companion details"]
affects: ["22-16 gate (quests / OnQuestUpdated change again when recoveryTime joins PetFragment)"]
tech-stack:
  added: []
  patterns: ["prize row: coins width capped at the room the square cards leave"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/quest_fragment.dart
    - test/graphql/quest_documents_test.dart
    - test/graphql/board_documents_test.dart
    - lib/models/quest/quest_sheet_details.dart
    - test/models/quest/quest_sheet_details_test.dart
    - lib/shared/components/popup/quest_info_sheet.dart
    - test/shared/components/popup/quest_info_sheet_test.dart
    - test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart
    - lib/screens/innkeeper/missionCompletion/steps/prizes_step.dart
    - test/screens/innkeeper/missionCompletion/steps/prizes_step_test.dart
    - lib/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet.dart
    - test/screens/innkeeper/missionCompletion/components/prize_catalogue_sheet_test.dart
decisions:
  - "petPrize is null when the pet or its name is null/empty (same rule as the old text line, D-06)"
  - "The prize card is square (constraints.maxHeight); the coins width is capped at maxWidth - cards * maxHeight so coins + item + companion never overflow"
  - "Quest-sheet and innkeeper long presses pass no name (catalogue view, species as title)"
metrics:
  duration: ~30 min
  completed: 2026-11-14
---

# Phase 22 Plan 08: Companion cards in the quest-sheet prize and the innkeeper prize rows Summary

The quest-sheet prize companion is now a `CompanionCard` (image, species in the rarity colour, speed) instead of the text «Compagno in premio: X»; a long press opens `showCompanionDetails`. `QuestFragment` selects `prizes.pet { PetFragment.fields }`, so `quests` and `OnQuestUpdated` carry the card fields. The innkeeper prize rows (`prizes_step.dart`) and the prize catalogue (`prize_catalogue_sheet.dart`) open the same details on long press; the tap still picks and the remove button still removes. The result sheet keeps its text line (D-35).

## Live-safe check

`awk '/^type QuestPrizes /,/^}/' <BE origin/develop src/schema.gql> | grep -cE '^ +pet: Pet$'` printed `1` before Task 1 (`QuestPrizes.pet: Pet`; every `PetFragment` field is in today's `type Pet`, proof in 22-03).

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | Prize companion card on the quest sheet | 3a33a11b (RED), 628752ce (GREEN) |
| 2 | Innkeeper prize rows open the companion details | 32c60bec (RED), b3d48622 (GREEN) |
| 3 | Bookkeeping | this commit |

## RED failures

- Task 1: `quest_sheet_details_test.dart` did not compile (`The getter 'petPrize' isn't defined for the type 'QuestSheetDetails'`); `quest prizes select the companion through PetFragment (D-35)` failed (`pet { id name }`); quest sheet cases «the prize companion is a card with its name (D-34, D-35)», «a long press on the prize companion opens its details (D-35)», the two served-prize-block cases (D-07/D-18, D-22) and the map overlay case failed (no `CompanionCard` / `CardLabel` title).
- Task 2: both D-35 cases failed with `Found 0 widgets with type "CompanionInfoSheet"`.

## Retargeted tests

- `quest_sheet_details_test`: the two `petPrizeLine` cases became «petPrize is the prize companion (D-35)» and «petPrize is null without a pet or a pet name (D-06)» (also covers an empty name).
- `quest_info_sheet_test`: «shows «Compagno in premio» …» replaced by the card case and the long-press case; the served-block cases (viewer titles, rankPrizes) read the card title `CardLabel` under `CompanionCard.titleKeyOf('pet-owl')`; the layout cases with item + companion stay (D-06) and now pass thanks to the coins cap.
- `quest_info_overlay_test` (map, outside files_modified): the served-block case reads the card title instead of the text line.
- `board_documents_test` (outside files_modified): «selects the companion prize (D-06, D-35)» and the cure-order case pin `pet { <PetFragment> }` instead of `pet { id name }`.

`quests` and `OnQuestUpdated` now also carry `PetFragment`: they change again at the gate when `recoveryTime` joins the fragment.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Prize row overflowed with coins + item + companion**
- **Found during:** Task 1 GREEN
- **Issue:** the square companion card (width = maxHeight) does not shrink like the old `Flexible` text; with the 0.35 coins share the row overflowed by 14 px in the two «keep the card square» cases.
- **Fix:** `coinsWidth = min(maxWidth * share, max(0, maxWidth - cardCount * maxHeight))` (`dart:math` show max, min); shares unchanged.
- **Files modified:** lib/shared/components/popup/quest_info_sheet.dart
- **Commit:** 628752ce

**2. [Rule 3 - Blocking] Tests outside files_modified pinned the old text/selection**
- `test/screens/mainScreen/tabs/map/quest_info_overlay_test.dart` (retargeted in the RED commit 3a33a11b) and `test/graphql/board_documents_test.dart` (retargeted in the GREEN commit 628752ce, found when running `test/graphql`).

### Other notes

- `_prizeRow` gained a `BuildContext` parameter (the sheet is a StatelessWidget; context comes from the `LayoutBuilder`). `_petPrizeMaxLines` removed (unused).
- STATE reads `Plan: 8 of 17` (orchestrator format): the plan's `grep -q "Plan: 08 of 17"` (Task 3 verify, VALIDATION 22-08-03) does not match, expected. ROADMAP row `8/17 | In Progress`.

## Verification

- `flutter test test/graphql test/models/quest test/shared/components/popup test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map` → +1060 all passed (after Task 1).
- `flutter test test/screens/innkeeper` → +322 all passed (after Task 2).
- Analyzer: 47 issues (info only), ANALYZE_GATE_OK after each code task. Registry untouched (54). All touched files formatter-clean before and after.
- Tests: +4 (quest documents +1, quest sheet +1, prizes step +1, prize catalogue +1) → expected suite 4850 (full suite not run).

## Known Stubs

None.

## Self-Check: PASSED

Commits 3a33a11b, 628752ce, 32c60bec, b3d48622 present in `git log`; all modified files exist.
