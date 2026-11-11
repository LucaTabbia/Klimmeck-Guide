---
phase: 19-model-review
plan: 05
subsystem: ui
tags: [companions, journal, shop, item-lines, rarity, window, tdd]
requires: ["19-04"]
provides:
  - "companionXpLine(int xp, int? maxXp), petAttackLine(Pet), petDefenseLine(Pet) in lib/utils/item_lines.dart (pure, null when there is nothing to print)"
  - "OwnedCompanionRow takes the entry (required OwnedPet owned) and prints «Esperienza: N / maxXp» (key companion-xp-<petId>)"
  - "CompanionCard: attack / defense labels and the name in RarityType.color; CardLabel.color (optional, null = theme colour)"
  - "CompanionRow: attack / defense texts (keys companion-attack-<petId>, companion-defense-<petId>) and the name in the rarity colour"
affects: [19-11, 19-13]
tech-stack:
  added: []
  patterns: ["pure line helper returning null → the host hides the line", "optional colour on CardLabel passed to copyWith (null keeps the theme colour)"]
key-files:
  created: []
  modified:
    - lib/utils/item_lines.dart
    - lib/screens/mainScreen/tabs/journal/components/owned_companion_row.dart
    - lib/screens/mainScreen/tabs/journal/components/companion_content.dart
    - lib/shared/components/cards/card_label.dart
    - lib/shared/components/cards/companion_card.dart
    - lib/shared/components/companion_row.dart
    - test/utils/item_lines_test.dart
    - test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart
    - test/shared/components/cards/companion_card_test.dart
    - test/shared/components/companion_row_test.dart
decisions:
  - "The xp line is text on the owned row, under the «Al tuo fianco» mark; it is not on the parchment (four labels at most) and not in the slot"
  - "A damage entry without a power prints the lowercase label alone; an entry with a null type is skipped"
  - "Rarity = the companion NAME in RarityType.color, as on the item cards; no word, badge or new colour"
metrics:
  duration: "~20 min"
  completed: 2026-11-11
  tasks: 3
  files: 10
---

# Phase 19 Plan 05: Companion lines and rarity colour (Journal and shop) — Summary

Three pure helpers print «Esperienza: 40 / 300», «Attacco: tagliente 12, fuoco 5» and «Difesa: contundente 4», and the owned row, the companion parchment and the shop rows host them, with the companion name drawn in the rarity colour — all hidden against the BE of today, no file under `lib/graphql`, `lib/models` or the shop screens touched.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `00cd25c` | test(utils): expect the companion xp and damage lines |
| 2 | `781bf46` | feat(utils): add the companion xp and damage lines |
| 3 | `38b21b5` | test(journal): expect the experience line on owned companions |
| 4 | `307be95` | feat(journal): show the experience of owned companions |
| 5 | `117d8f8` | test(shared): expect pet attack, defense and rarity |
| 6 | `baab96d` | feat(shared): show pet attack, defense and rarity on companions |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/utils/item_lines_test.dart` → compile failure of the file, as the plan expected: `Error: Method not found: 'companionXpLine'.` (×6), `Error: Method not found: 'petAttackLine'.`, `Error: Method not found: 'petDefenseLine'.` The nine new cases were not observed individually in RED (same file).

**Task 2** — `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart` → `+13 -5: Some tests failed.`

- «the owned row shows the experience over the catalogue maximum (D-03)»: `Bad state: No element` (key `companion-xp-pet-travel-horse` absent)
- «every owned row has its own experience line (D-03)»: `Found 0 widgets with text "Esperienza: 40 / 300"`
- «the companion at the side shows the mark and the experience (D-03)»: `Found 0 widgets with key [<'companion-xp-pet-travel-horse'>]`
- «the life of the owned companion is shown nowhere (D-18)»: the xp key not found (the case first asserts the line is there, then that no «Vita» text exists)
- «tapping a row with the experience line still toggles the companion (D-03)»: `Bad state: No element`

Green at the first run: «no experience line while maxXp is not served (D-15)» — the pin of the window state, true before and after by construction.

**Task 3** — `flutter test test/shared/components/cards/companion_card_test.dart test/shared/components/companion_row_test.dart` → `+14 -11: Some tests failed.`

- card: the four «attack and defense» cases with served damages (texts not found, `hasLength(4)` on two labels), «draws the name in the colour of the rarity like the item cards (D-20)» (expected `bloodRed`, actual the theme ink), «the rarity adds no text (D-20)» (attack / defense labels missing), «the speed, attack and defense labels keep their colour (D-20)» (`Bad state: No element`)
- row: «draws the name in the colour of the rarity (D-20)» (expected `darkBronze`, actual `Color(0.1176, 0.1059, 0.0941)`), «shows the attack and the defense lines with their keys (D-13)», «each line is hidden when its damages are empty (D-13)», «the lines sit between the speed and the equipped mark (D-13)»

Green at the first run (pins of today's state, as the plan expected): «shows neither line for a pet as the BE of today serves it (D-15)» on the card and on the row, «a pet without rarity keeps the name colour of today (D-20)» (card, pinned to `KlimmeckGuideTheme.instance.bodyLarge.color`) and «a pet without rarity keeps the name style of today (D-20)» (row, `bodyMedium`).

A first RED run of the card file failed at load (`google_fonts was unable to load font`) because the test read the theme at group-declaration time; the read moved into a function called inside the tests before the RED commit.

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/utils/item_lines_test.dart` (Task 1) | `+45: All tests passed!` |
| `flutter test test/screens/mainScreen/tabs/journal` (Task 2) | `+222: All tests passed!` |
| `flutter test test/shared/components test/screens/mainScreen/tabs/shop test/screens/mainScreen/tabs/journal` (Task 3, includes `spell_card_test.dart`) | `+598: All tests passed!` |
| plan `<verification>` (`test/utils/item_lines_test.dart test/shared/components test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop`) | `+643: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: the three signatures 1 / 1 / 1 · the three fixed copies in the test 1 / 1 / 1 · `D-13)` 8 (≥ 6) · `D-03)` 8 (≥ 3) · `package:flutter/` in `item_lines.dart` 0.

Task 2: `companionXpLine(owned.xp, owned.pet.maxXp)` 1 · `companion-xp-` 1 · `currentLifePoints` 0 (D-18) · chrome/bar grep 0 · `D-03)` 4, `D-15)` 2, `D-18)` 1.

Task 3: `petAttackLine(pet)` / `petDefenseLine(pet)` 1 / 1 in the card and in the row · `pet.rarity?.color` 1 · `rarity.color` (row) 1 · `final Color? color` 1 · `Color(0x|Colors.` 0 in the three files (0 before) · copy literals in the widgets 0 · `companion-attack-` 1, `companion-defense-` 1 · `D-20)` 5 (card) / 3 (row) · `D-13)` 5 / 5 · `D-15)` 1 / 1 · `git diff HEAD~2 --stat` on `spell_card.dart`, `lib/models/enums`, `lib/theme`, `lib/config`, the shop screens: empty.

Plan-wide: `git diff 3aa346e --stat -- lib/graphql lib/models lib/screens/mainScreen/tabs/shop` empty. All single-line greps matched without `grep -A3`. `git status --short` → ` M pubspec.lock` only.

## Where each line appears (device review, after the gate 19-11)

Against the BE of today nothing is visible: `maxXp`, `attack`, `defense`, `rarity` are not selected until 19-11, so the three lines are hidden and the name keeps today's ink. After the gate:

| What | Where | How |
|------|-------|-----|
| «Esperienza: 40 / 300» | Journal → «Compagno» → each owned row, to the right of the parchment | plain `bodyMedium` text, under «Al tuo fianco» when the companion is at the side; no bar. NOT on the parchment, NOT in the slot at the top, NOT in the shop |
| «Attacco: tagliente 12, fuoco 5» | the companion parchment (Journal slot and owned rows), third label under the speed; the shop rows (buy, sell, transaction) under the speed | parchment: `CardLabel` (one line, auto-sized); row: `bodyMedium` text |
| «Difesa: contundente 4» | same hosts, right after the attack | same |
| rarity | the companion NAME on the parchment and on the shop rows | the name in `RarityType.color` (common `deepNight`, uncommon `mysticBlue`, rare `bloodRed`, ultrarare `arcanePurple`, legendary `darkBronze`); no word, no badge |

Planner's choices to look at on the device: the xp is text only (provisional); a parchment of a riding pet with attack and defense carries four labels (4/6 of its height — a long attack line shrinks down to 4 pt, check the readability with two or more damage types); a damage entry without a power prints the label alone («Attacco: tagliente»); the item rows have no rarity presentation of their own, so the companion rows borrow the cards' one. A `common` pet draws its name in `deepNight`, which may differ slightly from the theme ink of a pet without rarity.

## Files formatted

`dart format` one by one on every touched file. Reflowed: the three test files after the new groups were added (only the added code); the six `lib` files were already clean after the edit.

## Deviations from Plan

None that needed a rule — plan executed as written. Notes:

- `_damagesLine` delegates the part to a private `_damagePart(label, power)` (label lowercase, power appended when served) so the base and the energy loops share one rule; no arithmetic.
- `owned_companion_row.dart`: the build became a block body (`final pet = owned.pet;`, `xpLine`, `style`) — the widget tree is the plan's; the doc comment names the experience line (Boy Scout).
- `companion_content.dart`: the loop variable is `entry` (`owned` is the field).
- `companion_section_test.dart`: `_character` gained an optional `owned` list; the cat with a maximum is `{...catPetJson(), 'maxXp': 100}` (the `catPetJson` fixture takes no parameter and was left untouched).
- The «every owned row…» and «…lines sit between…» cases assert a little more than the plan's minimum (row membership; five distinct, sorted tops).

## Notes for the next plans

- **19-11 (gate):** selecting `attack defense maxXp rarity` in `PetFragment` and the owned entries is all it takes to light the lines up — no widget change. The widget fixtures of this plan already use the new shape.
- `OwnedCompanionRow` now needs an `OwnedPet`; `CompanionSlot` still takes the catalogue `Pet` (the slot shows no xp by design).
- `CardLabel.color` is available to other cards (`SpellCard` does not pass it and is pixel-identical).
- `companionXpLine` hides on `maxXp` null or ≤ 0: the window zeros of `OwnedPet` (`xp` 0 from a bare pet) can never be printed. After the BE content pass (BE D-25) every pet has a `maxXp`, so a new companion reads «Esperienza: 0 / N».
- **Device E2E (19-13):** check the four hosts above, plus a pet with no attack (only «Difesa») and the name colour per rarity in both the Journal and the shop.

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-17 (no clamp), T-19-18 (no arithmetic), T-19-19 (life read by no widget), T-19-20 (overflow test), T-19-56 (rarity adds no text, no colour literal) are covered by the tests and greps above.

## Self-Check: PASSED

- Modified files exist; no file created besides this summary.
- Commits `00cd25c`, `781bf46`, `38b21b5`, `307be95`, `117d8f8`, `baab96d` are in `git log`.
