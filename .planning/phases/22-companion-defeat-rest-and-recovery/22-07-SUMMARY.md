---
phase: 22-companion-defeat-rest-and-recovery
plan: 07
subsystem: shop
tags: [companion, shop, basket, companion-card, long-press, d-20, d-22, d-34, d-35]
requires: ["22-02 companionDisplayNameOf", "22-04 CompanionCard", "22-05 showCompanionDetails"]
provides: ["CompanionRow with CompanionCard, name and onLongPress", "ShopModal.petNames / onCompanionInfo", "TransactionModal.onCompanionInfo", "shop.dart sell names + details host"]
affects: ["22-08 innkeeper prize rows (same CompanionRow, long press to wire)"]
tech-stack:
  added: []
  patterns: ["names travel as Map<String, String> (catalogue pet id -> chosen name), sell side only"]
key-files:
  created: []
  modified:
    - lib/shared/components/companion_row.dart
    - test/shared/components/companion_row_test.dart
    - lib/screens/mainScreen/tabs/shop/components/shop_modal.dart
    - test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart
    - lib/screens/mainScreen/tabs/shop/components/transaction_modal.dart
    - test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart
    - lib/screens/mainScreen/tabs/shop/shop.dart
decisions:
  - "Only chosen names enter the names map (owned.name non-null, value = companionDisplayNameOf(owned)): passing the species as a name would print it twice on the card (title + species line)"
  - "The row keeps its speed text even though the card also prints the speed label (plan: speed, attack, defense and mark stay); row tests address the speed line by its key"
  - "Long press passes the same name the row shows: null on the buy side, the chosen name on the sell side"
metrics:
  duration: ~25 min
  completed: 2026-11-14
---

# Phase 22 Plan 07: Companion cards in the shop lists and the basket Summary

`CompanionRow` now leads with a `CompanionCard` (image, title in the rarity colour, species below when named) followed by the price and the speed/attack/defense/«Al tuo fianco» texts; the tap still selects/removes and a new long press calls `onLongPress`. In the shop buy list, the sell list and both sides of the basket a long press opens `showCompanionDetails`; the sell list and the sell side of the basket print the owned companion's chosen name (Pitfall 9), the buy side prints the species.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | CompanionRow with the card and the long press | bd84d08e (RED), a85f2f73 (GREEN) |
| 2 | Shop lists and basket open the details; sell side reads names | 94a9867b (RED), 3e311bec (GREEN) |
| 3 | Bookkeeping | this commit |

## RED failures

- Task 1: `companion_row_test.dart` did not compile (no `name` / `onLongPress` on `CompanionRow`).
- Task 2: `shop_modal_test.dart` (no `petNames`) and `transaction_modal_test.dart` (no `onCompanionInfo`) did not compile.

## Retargeted row tests (companion_row_test.dart)

- «is text-only: no image (D-13)» -> «shows the companion card before the texts (D-22, D-34)».
- «shows the name and the buy price», rarity group: the name is read from the card title `CardLabel` (`CompanionCard.titleKeyOf`) and its `color` (no rarity -> `null`, the card's default ink).
- Speed checks and the tap target use the `companion-speed-<id>` key (the card prints the speed label too, so `find.text('Velocità ×2')` is no longer unique).
- Order test: the name is no longer in the text column; it checks speed < attack < defense < mark (4 tops).
- No other test in test/shared, test/screens/mainScreen/tabs/shop, test/screens/innkeeper pinned the row's name `Text` style: none retargeted.

## Tests

- Added: row +3 (13 -> 16), shop_modal +3, transaction_modal +3 (incl. an extra «the buy side of the basket reads the species (D-20)») => +9, expected suite 4846 (full suite not run).
- `flutter test test/shared test/screens/mainScreen/tabs/shop test/screens/innkeeper`: +755 green after Task 1; `flutter test test/screens/mainScreen/tabs/shop`: +65 green after Task 2; innkeeper + row: +336 green.
- Analyzer 47 info, ANALYZE_GATE_OK after each code task. All touched files were and remain formatter-clean. `equipment_info_display.dart` untouched. No GraphQL change, registry 54.

## Deviations from Plan

- Extra test on the basket buy side (species) — strengthens D-20.
- The names map is built twice (shop.dart `_chosenPetNamesOf`, TransactionModal `_sellNames`) exactly as the plan prescribes; each is a three-line comprehension.
- STATE `Plan: 7 of 17`, Progress `7/17 | In Progress` per orchestrator; the plan's literal `Plan: 07 of 17` grep (Task 3 verify, VALIDATION 22-07-03) does not match — expected.

## Threat model

- T-22-21 mitigated: the long press only opens the read-only route; tests «the tap still selects» / «long press ... asks for its details» assert no selection change on long press.

## Known Stubs

None.

## Self-Check: PASSED
