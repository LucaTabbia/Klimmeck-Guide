---
phase: 21-innkeeper-mission-completion-flow
plan: 05
subsystem: players-lock
tags: [mission-lock, journal, potions, companion, spells, equipment]
requires: ["21-04"]
provides:
  - "ItemUseFailure.missionInProgress (after awaitingAid), mapped from MISSION_IN_PROGRESS"
  - "potionNoticeFor(missionInProgress) = «Pozione non bevuta» / missionInProgressRefusalLine"
  - "ItemsSection: heal potions disabled with statusLine «Missione in corso» (after the awaiting-aid early return, before the countdown)"
  - "CompanionSection.missionLockedKey = ValueKey('journal.companion.missionLocked'); SpellsSection.missionLockedKey = ValueKey('journal.spells.missionLocked')"
  - "Journal armour rows: onSelect null, isDisabled, statusLine «Missione in corso»; EquipmentInfoSheet.onEquip null; _equipItem guard"
affects: [21-16]
tech-stack:
  added: []
  patterns: ["served flag CharacterStatus.missionInProgress read in one helper per file; no lane or quest read (D-16)"]
key-files:
  created:
    - test/screens/mainScreen/tabs/journal/journal_mission_lock_test.dart
  modified:
    - lib/repository/item_use_failure.dart
    - lib/screens/mainScreen/tabs/journal/potionCubit/potion_notice.dart
    - lib/screens/mainScreen/tabs/journal/sections/items_section.dart
    - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
    - lib/screens/mainScreen/tabs/journal/sections/spells_section.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/repository/item_use_failure_test.dart
    - test/screens/mainScreen/tabs/journal/potionCubit/potion_notice_test.dart
    - test/screens/mainScreen/tabs/journal/sections/items_section_test.dart
    - test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart
    - test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart
    - test/helpers/journal_harness.dart
decisions:
  - "Awaiting aid keeps precedence over the mission lock on potions (read-only row, no status line, D-23)"
  - "The mission lock hides the potion countdown (status «Missione in corso» instead of «pronta fra …»)"
  - "The flag read is factored in one helper per file (`_isOnMission`) instead of repeating `status?.missionInProgress ?? false` (CLAUDE.md zero duplication)"
metrics:
  completed: 2026-11-14
  tasks: 3
  files: 13
---

# Phase 21 Plan 05: Players' lock in the Journal and the potion refusal Summary

During any mission in progress (served `CharacterStatus.missionInProgress`) the Journal refuses every change that the simulation reads: heal potions in «Oggetti», the companion slot, the spell toggles (section and details sheet) and the armour rows are disabled or inert, each with the in-world line «Missione in corso» (plain `Text` / `ItemRow.statusLine`, no chip, no dialog); a `useItem` refused with `MISSION_IN_PROGRESS` now shows «Pozione non bevuta» / «Sei impegnato in una missione: aspetta l'esito» (D-11, D-12, D-16, D-30). Nothing is derived from lanes or quests.

## Commits

| Task | Commit | Subject |
|------|--------|---------|
| 1 RED | bd8f51d8 | test(journal): expect locked potions during a mission |
| 1 GREEN | 4e471c2c | feat(journal): lock the potions during a mission |
| 2 RED | fa37c596 | test(journal): expect locked companion, spells and armour |
| 2 GREEN | 02c14734 | feat(journal): lock companion, spells and armour during a mission |

## RED evidence

- Task 1: `item_use_failure_test` and `potion_notice_test` failed at compile time — `Member not found: 'missionInProgress'`; `items_section_test` failed on «a heal potion is disabled with «Missione in corso» (D-12, D-30)» and «the countdown is not shown while the mission locks the potion (D-12)» (+20 -4). «awaiting aid keeps the read-only row (D-23)» was green at the first run: it pins the existing precedence of the awaiting-aid early return, which the GREEN change had to preserve.
- Task 2: `companion_section_test` and `spells_section_test` failed at compile time — `Member not found: 'missionLockedKey'`; `journal_mission_lock_test` «an armour row is disabled …» failed with `Expected: true, Actual: <false>` (isDisabled). «without a mission the same tap sends equipItem (D-12)» was green at the first run (existing behaviour, control case proving the harness taps the row and the real `JournalCubit` reaches `EquipmentRepository.equip`).

## Tests

- `flutter test test/repository/item_use_failure_test.dart test/screens/mainScreen/tabs/journal test/screens/mainScreen/components/potion_outcome_listener_test.dart` → +262 all green.
- `flutter test test/screens/mainScreen/tabs/journal test/screens/mainScreen` → +1239 all green.
- Plan verification `flutter test test/repository test/screens/mainScreen` → +2146 all green.
- New cases: D-11 mapping (both error shapes), D-30 potion banner, group `mission in progress (Phase 21)` in items_section_test (3), companion_section_test (2), spells_section_test (3, incl. `SpellDetailsSheet.onToggle == null`), new journal_mission_lock_test (2, real `JournalCubit` over `MockEquipmentRepository`, worn sword in `rightHand`).

## Format and analyzer

All 12 pre-existing touched files were formatter-clean before the change; each was formatted one by one afterwards (the formatter only rewrapped the new code in companion_section.dart, spells_section.dart and the three Task 2 test files). Analyzer: `47 issues found` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK` after both code tasks.

## Deviations from Plan

1. **[CLAUDE.md - Clean Code] Flag read factored in a helper.** `journal.dart` has a top-level `_isOnMission(Character)` used by the armour rows, `EquipmentInfoSheet.onEquip` and the `_equipItem` guard; `spells_section.dart` has `_isOnMission(Character?)` used by the section and the details sheet. Consequence: the acceptance grep `grep -c "missionInProgress" journal.dart` gives **2** (helper + `missionInProgressLabel`) instead of ≥ 3; the wiring is shown by `grep -c "_isOnMission" journal.dart` = 4 and covered by journal_mission_lock_test.
2. **EquipmentInfoSheet «Equipaggia».** With `onEquip: null` the sheet keeps its `BookmarkRibbon` (it renders whenever `isEquipped != null` and also shows the equipped state); its tap calls `onEquip?.call()` and therefore does nothing. Same behaviour as `SpellInfoSheet` with `onToggle: null`. `equipment_info_sheet.dart` is outside `files_modified`, so it was not changed; a hidden ribbon would need a plan of its own.
3. The `items_section.dart` doc comment now reads «Quattro fatti … missione in corso (Phase 21 D-12) …».

## Known Stubs

None. `missionInProgress` is still not selected in `CharacterFragment` (gated plan 21-16, by design — Pitfall 2): on today's BE it stays `false` and nothing locks.

## Self-Check: PASSED

- Commits bd8f51d8, 4e471c2c, fa37c596, 02c14734 present on `feat/21-innkeeper-mission-completion`.
- All created/modified files exist; `grep -c "missionInProgress" lib/screens/mainScreen/components/potion_outcome_listener.dart` = 0 (not a stale-view failure, T-21-16); no lane/quest read in the companion and spells sections (D-16); no AppBar / AlertDialog / spinner added.
