---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 08
subsystem: journal
tags: [wounds, innkeeper-wounds, journal, cure-lines, board-reread]
requires: ["24-07"]
provides:
  - "Journal.beyondCureLine / Journal.beyondCureKeyOf(injury)"
  - "InjuryNameIcon({injury, note, noteKey})"
  - "curableInjuriesOf(CharacterState) (characterInjuriesOf deleted)"
  - "healedInjuriesLine(item, {beyondCure})"
  - "ItemRow.injuriesBeyondCure / PotionSheet.injuriesBeyondCure (default const [])"
  - "QuestScopeListener scope keyed on innkeeperInjuries (in a city only)"
affects: [24-09, 24-10, 24-11]
tech-stack:
  added: []
  patterns: ["display filters over served lists: the client lists, the BE cures"]
key-files:
  created:
    - test/screens/mainScreen/tabs/journal/journal_innkeeper_wounds_test.dart
  modified:
    - lib/screens/mainScreen/tabs/journal/components/injury_name_icon.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - lib/screens/mainScreen/characterCubit/character_selectors.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/utils/item_lines.dart
    - lib/shared/components/item_row.dart
    - lib/screens/mainScreen/tabs/journal/sections/items_section.dart
    - lib/screens/mainScreen/tabs/journal/components/potion_sheet.dart
    - lib/screens/mainScreen/components/quest_scope_listener.dart
    - test/helpers/journal_harness.dart
    - test/helpers/fixtures/quest_fixtures.dart
    - test/screens/mainScreen/characterCubit/character_selectors_test.dart
    - test/utils/item_lines_test.dart
    - test/shared/components/item_row_test.dart
    - test/screens/mainScreen/tabs/journal/sections/items_section_test.dart
    - test/screens/mainScreen/tabs/journal/components/potion_sheet_test.dart
    - test/screens/mainScreen/components/quest_scope_listener_test.dart
decisions:
  - "the Journal line is drawn with KlimmeckGuideTheme.instance.errorText (Cinzel 12, blood red): an existing emphasis style, no new asset"
  - "InjuryNameIcon keeps a minimum height of 50 instead of a fixed one, and its label column is Flexible: the note wraps instead of overflowing"
  - "the Journal «Ferite» selects a record (injuries, innkeeperInjuries) so the section follows an origin flip"
  - "characterInjuriesOf deleted: Board and Map were its only callers"
metrics:
  duration: "~25 min"
  completed: 2026-11-21
---

# Phase 24 Plan 08: Player side of the innkeeper wounds Summary

The Journal «Ferite» writes «Troppo grave per essere curata» under a wound listed in the served `innkeeperInjuries`; the quest sheets (Board and Map) read `curableInjuriesOf`, so «Cura le tue ferite: …» never lists an innkeeper wound; the Journal's potion rows and the potion sheet leave those wounds out of «Cura: …»; the Board is reread in silence when only `innkeeperInjuries` changes in a city. Against today's BE the list is empty and nothing changes on screen.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 style | Format injury_name_icon.dart (formatter only) | 4d46ccaa |
| 1 RED | Expect the innkeeper wounds told apart | aa23c4e0 |
| 1 GREEN | Mark innkeeper wounds, keep them out of the cure line | 34b63a23 |
| 2 RED | Expect cure lines and the Board to follow the wound origin | fead9e2d |
| 2 GREEN | Cure lines and Board reread follow the wound origin | 0efacd0a |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (aa23c4e0):** both files did not compile (`Journal.beyondCureKeyOf`, `Journal.beyondCureLine`, `curableInjuriesOf` missing).
- **Task 1 GREEN (34b63a23):** `flutter test test/screens/mainScreen/tabs/journal test/screens/mainScreen/characterCubit test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/map test/shared/components/popup` → 1016 passed; analyzer «47 issues found» (`ANALYZE_GATE_OK`).
- **Task 2 RED (fead9e2d):** item lines, item row and potion sheet tests did not compile (`beyondCure`, `injuriesBeyondCure`); the two Journal cases and the origin-flip reread failed on behaviour.
- **Task 2 GREEN (0efacd0a):** `flutter test test/utils test/shared/components test/screens/mainScreen/tabs/journal test/screens/mainScreen/components test/screens/mainScreen/tabs/shop` → 1269 passed; `test/screens/innkeeper`, Board, Map and characterCubit → 886 passed; analyzer «47 issues found» (`ANALYZE_GATE_OK`); `tool/hardening_check.sh` OK. The full suite was not run (reserved to 24-10).

## What the code does

- `InjuryNameIcon` takes an optional `note` (and `noteKey`) drawn under the label in `errorText`; the Journal passes it only for a wound in `innkeeperInjuries`.
- `curableInjuriesOf` = the character's `injuries` minus `innkeeperInjuries`; `curableInjuriesLine` and `QuestInfoSheet` are untouched.
- `healedInjuriesLine(item, beyondCure:)` skips the listed wounds; no line when nothing is left. `ItemsSection` passes `character.status?.innkeeperInjuries` to its rows and to `PotionSheet` (read at the opening). The equipment rows, the shop, the wizard's prizes and the result sheet pass nothing and keep the catalogue line.
- `QuestScopeListener`: `_QuestScope.innkeeperInjuries`, built with `_injurySetOf`, only in a city.

## Deviations from Plan

**1. [Rule 3 - Test support] Two fixtures outside `files_modified` gained an optional parameter**
- `test/helpers/journal_harness.dart` → `journalCharacter(innkeeperInjuries:)`; `test/helpers/fixtures/quest_fixtures.dart` → `characterWithLanesJson(innkeeperInjuries:)`. Both write the key only when passed (the rule of 24-01 / 24-02). Commits aa23c4e0 and fead9e2d.

**2. [Addition] One more widget case than the plan lists**
- `items_section_test`: «the potion sheet opened from the Journal leaves the innkeeper wounds out (D-15)» proves the wiring `ItemsSection` → `PotionSheet`, which the sheet's own test cannot see.

## Known limits

- The case «the line appears when only the origin of a wound changes» emits a character rebuilt from JSON, so it proves the section follows the new state; it does not isolate the record selector from the old list selector (a rebuilt character carries a new list either way).
- The shop's potion line still lists the whole `canHeal` by design (ruling 4: to look at in the UAT).

## Threat model

- T-24-33: the lines are display filters over served lists; no rule, no refusal mapping added.
- T-24-34: Board reread keyed on `innkeeperInjuries` (three listener cases).
- T-24-35: the reread goes through the existing silent `refreshQuests`; no loader, no chrome added.

## Self-Check: PASSED

- Files: `journal_innkeeper_wounds_test.dart` present; every modified path above is in the commits listed.
- Commits 4d46ccaa, aa23c4e0, 34b63a23, fead9e2d, 0efacd0a present in `git log`.
