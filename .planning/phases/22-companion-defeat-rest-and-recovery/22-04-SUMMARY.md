---
phase: 22-companion-defeat-rest-and-recovery
plan: 04
subsystem: shared
tags: [companion, card, details-sheet, image, refactor]
requires: [22-03]
provides:
  - "DetailsSheetFrame: shared parchment frame of the long-press details sheets (D-22)"
  - "SpellInfoSheet built on DetailsSheetFrame (behaviour unchanged)"
  - "CompanionCard with image (EnemyPortrait), chosen name / species title, species + level sub-label, speed; no attack/defense (D-20, D-22, D-34, D-37)"
affects: [22-05, 22-06, 22-11, 22-12]
tech-stack:
  added: []
  patterns: ["one details-sheet frame with a cardBuilder(cardSize) and a scrolling body"]
key-files:
  created:
    - lib/shared/components/popup/details_sheet_frame.dart
    - test/shared/components/popup/details_sheet_frame_test.dart
  modified:
    - lib/shared/components/popup/spell_info_sheet.dart
    - lib/shared/components/cards/companion_card.dart
    - test/shared/components/cards/companion_card_test.dart
key-decisions:
  - "Attack and defense leave the companion card (they move to the details sheet in 22-05 and stay in the shop row text); the speed label stays on the card"
  - "Pet image reuses EnemyPortrait (https / Cloudinary-relative v<n>/ paths only), height size * 0.45; sub-label CardLabel at cardSize size * 0.75"
  - "EquipmentInfoSheet left alone (out of scope, research F-3)"
metrics:
  duration: "~20 min"
  completed: 2026-11-14
---

# Phase 22 Plan 04: Details sheet frame and companion card restyle Summary

One parchment frame `DetailsSheetFrame` (card at half the inner width above a scrolling body, optional bookmark) now backs `SpellInfoSheet`, and `CompanionCard` reads like the spell and equipment cards: pet image via `EnemyPortrait`, the chosen name (or the species) as title in the rarity colour, species and «Livello N» below, speed kept, attack and defense removed.

## Tasks

| Task | Commits |
|------|---------|
| 1 Extract DetailsSheetFrame | 59a0cd90 test(shared): expect a shared details sheet frame; ada4830b refactor(shared): share the details sheet frame |
| 2 Restyle CompanionCard | 5c77f3c6 test(shared): expect the companion card with image and name; 5e1c3848 feat(shared): restyle the companion card with its image |
| 3 Bookkeeping | docs(phase-22): record plan 04 progress |

## RED failures

- Task 1: `details_sheet_frame_test.dart` failed to load (`details_sheet_frame.dart` did not exist).
- Task 2: compile errors: no named parameter `name`, members `CompanionCard.imageKeyOf` / `titleKeyOf` / `speciesKeyOf` not found.

## Retargeted card tests (companion_card_test.dart)

Removed (their checks move to `CompanionInfo` in 22-05; attack/defense wording is still covered by `companion_row_test.dart` and `item_lines_test.dart`):
- «shows the attack and the defense under the speed (D-13)»
- «hides the defense when it is empty (D-13)»
- «hides the attack of a pet without attack and keeps its defense (D-13)»
- «shows neither line when the wire carries no attack, defense, maxXp or rarity (lenient)»
- «four labels fit the parchment without overflow (D-13)»

Replaced by «the card carries no attack or defense: they live in the details (D-22)» and «fits without overflow at Journal size in landscape (D-22)».

Rewritten: «the rarity adds no text (D-20)» (now expects only title + speed with attack/defense served); «the speed, attack and defense labels keep their colour (D-20)» → «the species and speed labels keep their colour (D-20)».

Kept: «shows the name and the speed of a riding companion (D-17)» (now also checks the speed sits below the title), «shows only the name of a companion without speed (D-17)», «carries the bookmark when asked to mark the card (D-17)», «draws the name in the colour of the rarity like the item cards (D-20)», «a pet without rarity keeps the name colour of today (D-20)».

Added: 2 image cases (D-34), 2 name/species cases (D-20), 3 level cases (D-37), plus the two D-22 cases above. All card tests now run in landscape at the Journal card size 120 (`(780 - 180) / 5`).

## Verification

- `flutter test test/shared/components/popup test/screens/mainScreen/tabs/journal` → +447 all passed.
- `flutter test test/shared test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop` → +675 all passed.
- `spell_info_sheet_test.dart` untouched (T-22-14).
- Analyzer 47 issues (info only), ANALYZE_GATE_OK. All touched files formatter-clean (were clean before).
- Tests: +3 (frame) +4 net (card 12 → 16) → expected suite 4789 (full suite not run).

## Deviations from Plan

- `SpellInfoSheet` doc comment worded without the class name, so the acceptance grep `grep -c "DetailsSheetFrame" spell_info_sheet.dart` = 1 holds (the import line counts nothing; the build call is the one match).
- Wave-0 checkbox for `details_sheet_frame_test.dart` in 22-VALIDATION.md ticked.
- STATE `Plan: 4 of 17` and Progress `4/17 | In Progress` per orchestrator; the plan's literal grep `Plan: 04 of 17` (Task 3 verify, VALIDATION 22-04-03) does not match — expected.

## Known Stubs

None.

## Self-Check: PASSED
