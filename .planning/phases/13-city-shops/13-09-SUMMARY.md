---
phase: 13-city-shops
plan: 09
subsystem: journal
tags: [companion, pet, journal, bottom-sheet, optimistic, tdd]
requires: [13-06, 13-08]
provides:
  - CompanionSection («Compagno» slot of the Journal + owned-pets parchment sheet)
  - emptyCompanionSlotLine / noOwnedCompanionsLine copy constants
  - CompanionCubit provider in the Journal harness (idleCompanionCubit default)
affects: [13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "BlocBuilder<CharacterCubit> + BlocBuilder<CompanionCubit> over displayedPetId (optimistic overlay of 13-08)"
    - "cubit read from the outer context before showModalBottomSheet, callbacks passed into the sheet"
key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
    - test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart
  modified:
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/helpers/journal_harness.dart
    - test/screens/mainScreen/tabs/journal/journal_items_test.dart
decisions:
  - "the slot row is a CompanionRow with isEquipped: true and showCoins: false, so «Al tuo fianco» shows in the slot too; the sheet-marked test scopes companionEquippedMark to the PaperSheetModal"
  - "displayed pet resolved from ownedPets first, then assets.pet when the id matches; unknown id → empty slot line"
  - "haptic lightImpact unless toggle returns ignoredPending; the sheet always pops after one tap (T-13-30)"
metrics:
  duration: ~10min
  completed: 2026-11-02
  tasks: 2
  files: 5
---

# Phase 13 Plan 09: Journal «Compagno» slot Summary

`CompanionSection` after «Armatura» in the Journal: shows the displayed companion (pending overlay of `CompanionCubit` over `assets.pet`) as a coin-less `CompanionRow`, or «Nessun compagno al tuo fianco»; a tap opens a `PaperSheetModal` with the owned pets (equipped one marked, «Non possiedi compagni» when empty) where a tap calls `CompanionCubit.toggle(character, petId)` and closes the sheet. No travel gate, no price, no image, no chrome (D-10, D-13, D-15).

## Tasks

| Task | Commits | Files |
|------|---------|-------|
| 1 CompanionSection | f70987a (RED), 93a6d23 (GREEN) | companion_section.dart, companion_section_test.dart |
| 2 Journal insertion + harness | b3788d7 (RED), 67e815b (GREEN) | journal.dart, journal_harness.dart, journal_items_test.dart |

## RED failures observed

- Task 1: compile failure — `Error: Undefined name 'emptyCompanionSlotLine'` / `'noOwnedCompanionsLine'` (and the missing `companion_section.dart` import target).
- Task 2: `the Journal shows the «Compagno» slot right after «Armatura» (D-10)` failed with `Expected: exactly one matching candidate / Actual: Found 0 widgets with type "CompanionSection"`; the 6 existing items tests stayed green with the new harness provider.

## Created API

- `lib/screens/mainScreen/tabs/journal/sections/companion_section.dart`:
  - `const String emptyCompanionSlotLine = 'Nessun compagno al tuo fianco';`
  - `const String noOwnedCompanionsLine = 'Non possiedi compagni';`
  - `const CompanionSection({super.key, required double size})` — `Section(sectionName: 'Compagno', data: GestureDetector(key: ValueKey('companion_slot'), …))`; `SizedBox.shrink()` when the character is not loaded.
  - Sheet rows: `CompanionRow(key: ValueKey('owned-pet-${pet.id}'), showCoins: false, isEquipped: pet.id == displayedId, onTap: …)`.
- `test/helpers/journal_harness.dart`: `CompanionCubit idleCompanionCubit()` (MockCompanionCubit, `whenListen(..., initialState: const CompanionState())`); `pumpJournalPage(tester, {required characterCubit, required spellsCubit, CompanionCubit? companionCubit})`.

## Insertion (journal.dart)

```dart
                              _buildArmorSection(
                                character,
                                screenWidth,
                                lootSize,
                              ),
                              CompanionSection(size: lootSize),
                              _buildOwnedItemsSection(character, lootSize),
                              const SizedBox(height: 120),
```

Order check (`awk` of the plan) exits 0.

## Gates

- `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart`: 10 green.
- `flutter test test/screens/mainScreen/tabs/journal test/screens/mainScreen/components`: 287 green.
- `flutter test test/screens/auth test/screens/mainScreen`: 1051 green (was 1040 + 11 new).
- `flutter analyze`: 50 issues, all info, 0 error, 0 warning.
- `dart format` run on companion_section.dart, companion_section_test.dart, journal_harness.dart, journal_items_test.dart (one by one). `journal.dart` was NOT formatter-clean before the edit, so it was hand-edited (2 lines: import + insertion) and not formatted.
- `grep -rli cavalcatura lib` → 0.

## Deviations from Plan

- The harness default cubit uses only `whenListen(..., initialState: const CompanionState())` (which stubs `state`), not an extra `when(() => mock.state)`; same effect.
- The «marked» test scopes `companionEquippedMark` to the sheet because the slot row also shows it (isEquipped: true in the slot, as the plan prescribes).
- Test names for the two copy cases interpolate the constants (`«$emptyCompanionSlotLine»`), producing the exact titles of the plan.

Otherwise the plan executed as written. No Known Stubs (copy is provisional per D-13 by design). No new threat surface.

## Self-Check: PASSED

- Files exist: companion_section.dart, companion_section_test.dart.
- Commits f70987a, 93a6d23, b3788d7, 67e815b present in `git log`.
