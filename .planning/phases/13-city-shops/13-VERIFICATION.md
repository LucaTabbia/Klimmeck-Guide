---
phase: 13-city-shops
verified: 2026-11-02T22:02:16Z
status: human_needed
score: "6/6 success criteria verified in code and tests for plans 13-01..13-09; SHOP-02/03/04 accounted for; schema-gated plan 13-10 and device E2E plan 13-11 deferred"
overrides_applied: 0
re_verification:
  previous_status: none
  note: "Initial verification. No previous VERIFICATION.md existed."
gaps: []
deferred:
  - truth: "13-10: contract names (cityShop, CityShop, CitySize, City.size/hasShop, CharacterAssets.ownedPets, TransactionItems.petAssets, Pet.sellable/speedModifier, equipPet/unequipPet input names A1, CitySize values A2) proved on the merged BE `origin/develop:src/schema.gql`, and the 43 documents re-validated (43/43 OK)"
    addressed_in: "Plan 13-10 (gated on the BE Phase 12 PR merge, CONTEXT D-12)"
    evidence: "13-10-PLAN.md; the FE registry holds 43 documents and its test passes, but the names are agreed from BE 12-CONTEXT, not yet proved on the merged SDL (RESEARCH confidence MEDIUM for A1/A2)."
  - truth: "13-10: full-suite and analyzer gate, new Dart files format-clean, 13-VALIDATION.md filled and signed off (nyquist_compliant / wave_0_complete still draft/false)"
    addressed_in: "Plan 13-10"
    evidence: "13-VALIDATION.md frontmatter is `status: draft`, `nyquist_compliant: false`, `wave_0_complete: false`; sign-off is a 13-10 task."
  - truth: "13-10: error codes ITEM_NOT_IN_SHOP / PET_ALREADY_OWNED / PET_NOT_OWNED confirmed in the BE `GameRuleErrorCode` enum"
    addressed_in: "Plan 13-10"
    evidence: "The FE classifiers map the three codes (transaction_failure.dart) and are tested against fixtures; the enum lives in the BE repo and is proved by the gate plan."
  - truth: "13-11: `13-HUMAN-UAT.md`, `BACKEND-NOTES.md`, device E2E (11 steps), SHOP-02/03/04 ticked in REQUIREMENTS.md, ROADMAP/STATE closure (13-10 and 13-11 left `[ ]` in ROADMAP by design)"
    addressed_in: "Plan 13-11 (human checkpoint, gated on BE Phase 12 merge and device run)"
    evidence: "13-11-PLAN.md; `ls .planning/phases/13-city-shops/` has no 13-HUMAN-UAT.md and no BACKEND-NOTES.md; REQUIREMENTS.md keeps SHOP-02..04 as `[ ]` / Pending by design."
human_verification:
  - test: "1. Cold start, the satchel opens; on a city marker with a shop the Shop cell is enabled (SHOP-02)"
    expected: "Shop cell enabled on a marker whose city has a shop"
    why_human: "device E2E of the gated plan 13-11 (needs the BE Phase 12 data, City.hasShop served live)"
  - test: "2. Teleport to a village (Talmvere, talmvereVillage), open the shop (SHOP-02, D-02, SHOP-04)"
    expected: "Only common/uncommon items; «Compagni» shows Cavallo da viaggio with price and «Velocità ×2»; no city name anywhere"
    why_human: "needs the live cityShop pool seeded by the BE and the innkeeper teleport on a device"
  - test: "3. Buy the Cavallo da viaggio (D-08)"
    expected: "Bubble success; the Journal «Compagno» slot stays empty (buying never equips); the buy list no longer shows it"
    why_human: "real purchase against the BE with a seeded wallet (>= 2 oro)"
  - test: "4. Journal, tap «Compagno» (SHOP-04)"
    expected: "The owned list shows Cavallo da viaggio; tap it: the slot shows it immediately (optimistic) and stays after the subscription"
    why_human: "optimistic overlay settled by the live characterUpdated subscription"
  - test: "5. Teleport to a city (a `*City` of the same region) (SHOP-02)"
    expected: "Different pool, up to rare, no legendary"
    why_human: "pool content is BE data (seeded at boot, curated in the DB)"
  - test: "6. Teleport to a capital (Valantar) (SHOP-02/04)"
    expected: "Different pool including ultrarare, no legendary; «Compagni» lists Cavallo leggero and Cammello"
    why_human: "pool content is BE data"
  - test: "7. In Valantar sell the Cavallo da viaggio (marked equipped in the sell sheet), wallet below 50 ag if possible (Pitfall 4; SHOP-03/04, D-08)"
    expected: "Success; the Journal slot empties through the subscription"
    why_human: "end-to-end sale and subscription delivery, wallet below the gain exercises the D-14 fix against the real BE"
  - test: "8. Sell an owned legendary item, if the character has one (D-09; otherwise record «not available»)"
    expected: "Sale succeeds (legendary owned items stay sellable)"
    why_human: "needs a legendary item owned by the test character"
  - test: "9. Teleport to Necrorian (D-04)"
    expected: "The Shop cell is disabled, the Board cell is not"
    why_human: "depends on the BE serving City.hasShop false for Necrorian"
  - test: "10. Optional ITEM_NOT_IN_SHOP: with the shop page open, remove a listed item from that city's pool in the DB, then buy it (SHOP-03)"
    expected: "Bubble «Questa merce non la tratto», the row disappears after the reload"
    why_human: "needs a DB edit by the user and the BE refusal"
  - test: "11. Optional: equip / unequip during a travel (D-10)"
    expected: "Equip and unequip work during a travel"
    why_human: "real-time travel on a device"
---

# Phase 13: City Shops - Verification Report

**Phase Goal:** The shop a player opens on a city marker sells only that city's own pool of items (equipment, loot, companions) as served by the backend `cityShop(cityId)` query, with the pool, `City.size`, `City.hasShop` and every refusal owned by the backend; the frontend adapts the existing shop, keeps selling possible everywhere with infinite stock and catalogue prices, disables the Shop cell where the city has no shop, and adds a «Compagni» list in the buy/sell sheets and a «Compagno» Journal slot that equips one of the owned pets, never automatically on purchase.
**Branch:** feat/13-city-shops @ 03dcb52 (base develop b6eb4d4)
**Verified:** 2026-11-02
**Status:** human_needed
**Re-verification:** No, initial verification.
**Scope note:** plans 13-10 (schema gate vs merged BE Phase 12) and 13-11 (device E2E, handoff, closure) are gated on the BE Phase 12 merge (CONTEXT D-12). Their must-haves are deferred, not gaps. REQUIREMENTS.md keeps SHOP-02..04 as `[ ]` / Pending by design.

## Evidence gathered (run by the verifier)

| Check | Result |
|-------|--------|
| `flutter test test/models test/repository test/graphql test/tool` | 1379 passed, "All tests passed!" |
| `flutter test test/screens/mainScreen` | 890 passed, "All tests passed!" |
| `flutter test test/screens/auth test/shared test/utils` | 416 passed, "All tests passed!" |
| `flutter analyze` | 50 issues, all info (0 error, 0 warning); baseline ≈ 50 held, the `avoid_print` in `shop_cubit.dart` is gone |
| `print(` in `lib/screens/mainScreen/tabs/shop` | none |
| Schema-check registry (`tool/schema_check/schema_check_documents.dart`) | 43 entries (as the 13-05 plan expects); byIds catalogue documents remain because `KlimmeckGraphQl.getEquipmentItems/getLootItems` still exist |
| `git log b6eb4d4..HEAD` trailers `Co-Authored-By` / `Generated with` | 0 |
| TODO/FIXME in new shop, companion, journal-slot files | none |
| `git status --short` before writing this report | clean |

## Goal Achievement

### Observable Truths (ROADMAP success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Shop lists only the pool served by `cityShop`; no FE filtering by rarity/size/price; no city name | VERIFIED (code + tests) | `ShopQueries.getCityShop` (`cityShop(cityId: $cityId)`), `CityShop` model, `ShopCubit.getData(cityId)` last-request-wins, `ShopPoolLoader`, `Shop(cities:)` reads only the marker city pool; tests `shop_cubit_test`, `shop_pool_loader_test`, `shop_documents_test`, `city_shop_test` green. Live pool content is human step 2/5/6 |
| 2 | `ITEM_NOT_IN_SHOP` / `PET_ALREADY_OWNED` mapped and shown in the bubble; only `SHOP_NOT_IN_CITY` stays a banner; pool reloaded after the refusal | VERIFIED | `transaction_failure.dart` codes and enum values; `transaction_notice.dart` lines «Questa merce non la tratto» / «Hai già questo compagno»; `shop_pool_loader.dart:43` reloads on `itemNotInShop`; tests green. Live refusal is human step 10 |
| 3 | Shop cell disabled where `City.hasShop` is false, Board stays open | VERIFIED | `satchel_availability.dart:28` `city.hasShop ? const {} : _shopOnly`; `satchel_availability_test` and `main_screen_test` green. Live Necrorian is human step 9 |
| 4 | Buy sheet «Compagni» (hides owned, speed only for mounts), sell sheet owned pets with the equipped one marked, buying never equips, legendary sellable | VERIFIED | `TradeSelection` (`purchasablePets`, `buildTransactionRequest`, `petAssets` quantity 1), `companionSpeedLabel`, `CompanionRow`, `ShopModal` «Compagni» dropdown, `TransactionModal` on `TradeSelection`, D-14 `canAfford` fix; tests `trade_selection_test`, `companion_row_test`, `item_lines_test`, `shop_modal_test`, `transaction_modal_test` green |
| 5 | Journal «Compagno» slot after «Armatura»; tap lists owned pets and equips/unequips via `equipPet`/`unequipPet` with the optimistic pattern | VERIFIED | `CompanionSection` in `journal.dart`, `CompanionCubit` (single slot, optimistic overlay, rollback, 15 s timeout), `CompanionRepository`, `CompanionOutcomeListener`, provider in `AuthenticatedShell`, documents `EquipPet`/`UnequipPet`; tests green. Live optimistic/subscription behaviour is human step 4 and 7 |
| 6 | Selling works everywhere; device UAT visits a village, a city and a capital, buys, equips, sells, finds Shop disabled on Necrorian | DEFERRED to plan 13-11 | Device E2E; see `human_verification` |

**Score:** 6/6 success criteria verified in code and tests for 13-01..13-09 (criterion 6 is the deferred device E2E).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `lib/models/city_shop.dart`, `pet.dart`, `city.dart`, `character_assets.dart`, `request/transaction_request.dart`, `request/equip_pet_request.dart` | models of 13-01 | VERIFIED | exist, tested (`test/models/**`) |
| `lib/graphql/fragments/pet_fragment.dart`, `queries/shop_queries.dart`, `mutations/character_mutations.dart`, `queries/city_queries.dart` | documents of 13-02 | VERIFIED | contain `cityShop`, `EquipPet`, `UnequipPet`, `size hasShop` |
| `lib/repository/transaction_failure.dart`, `pet_equip_failure.dart`, `companion_repository.dart` | classifiers of 13-03 | VERIFIED | tested |
| `lib/screens/mainScreen/components/satchel_availability.dart` | gate of 13-04 | VERIFIED | reads `City.hasShop` |
| `lib/screens/mainScreen/tabs/shop/{shopCubit,components/shop_pool_loader.dart,shop.dart}` | 13-05 | VERIFIED | wired in `main_screen.dart` |
| `lib/models/shop/trade_selection.dart`, `lib/shared/components/companion_row.dart`, `lib/utils/item_lines.dart` | 13-06 | VERIFIED | tested |
| `shop_modal.dart`, `transaction_modal.dart` | 13-07 | VERIFIED | tested |
| `companionCubit/*`, `companion_outcome_listener.dart`, `authenticated_shell.dart` | 13-08 | VERIFIED | provider and listener mounted |
| `sections/companion_section.dart`, `journal.dart` | 13-09 | VERIFIED | slot after «Armatura» |
| `13-HUMAN-UAT.md`, `BACKEND-NOTES.md` | 13-11 | DEFERRED | absent by design |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `ShopPoolLoader` | `ShopCubit.getData` | mount / city change / `itemNotInShop` listener | WIRED | `shop_pool_loader.dart:43`, loader test green |
| `KlimmeckGraphQl.getCityShop` | `ShopQueries.getCityShop` | query document | WIRED | `graphql_shop_test` green |
| `Shop` | `buildTransactionRequest` -> `petAssets` | `TradeSelection` | WIRED | `shop.dart`, `trade_selection.dart:74` |
| `CompanionSection` | `CompanionCubit.toggle` -> `CompanionRepository` -> `equipPet`/`unequipPet` | cubit + repository | WIRED | companion tests green |
| `AuthenticatedShell` | `CompanionCubit` / `CompanionOutcomeListener` in `MainScreen` | provider | WIRED | `authenticated_shell_test`, `main_screen_test` green |
| `disabledSatchelPages` | `City.hasShop` | `currentCityOf` | WIRED | `satchel_availability.dart:28` |

### Behavioral Spot-Checks

Test suites above are the behavioural evidence; no server was started. Live behaviour against the BE is the device E2E.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| SHOP-02 | 13-01, 02, 04, 05 | pool via `cityShop`, `hasShop` gate, no FE filtering, no city name | SATISFIED in code and tests; device steps 1, 2, 5, 6, 9 pending (13-11) | truths 1, 3 |
| SHOP-03 | 13-03, 05, 07 | `ITEM_NOT_IN_SHOP` in the bubble, reload, sell everywhere incl. legendary | SATISFIED in code and tests; device steps 7, 8, 10 pending | truths 2, 4 |
| SHOP-04 | 13-01, 02, 03, 06, 07, 08, 09 | «Compagni» lists, `petAssets`, «Compagno» slot, equip/unequip | SATISFIED in code and tests; device steps 2, 3, 4, 6, 7 pending | truths 4, 5 |

No orphaned requirements: ROADMAP maps only SHOP-02/03/04 to Phase 13. Boxes stay unticked until 13-11.

### Anti-Patterns Found

None blocking. No TODO/FIXME, no `print(` in the touched shop/companion code, no `package:flutter` leakage checked in models by grep-level inspection of the new files' roles (SUMMARYs state Flutter-free; tests pass).

### Human Verification Required

The 11 device steps of `13-RESEARCH.md` §Device E2E, listed in the frontmatter (`human_verification`). Setup: BE `develop` with Phase 12 merged running locally, Samsung via USB with `adb reverse tcp:3000 tcp:3000`, innkeeper device account, test character with >= 2 oro. Requirement map: SHOP-02 (1, 2, 5, 6, 9), SHOP-03 (7, 8, 10), SHOP-04 (2, 3, 4, 6, 7).

### Gaps Summary

No gaps. Everything plans 13-01..13-09 promised exists, is wired and is covered by passing tests (2685 tests across the requested directories, 0 failures; analyzer 0 error / 0 warning). Remaining work is the gated plan 13-10 (schema proof against the merged BE SDL, validation sign-off) and plan 13-11 (device E2E, handoff, closure).

---

_Verified: 2026-11-02_
_Verifier: Claude (gsd-verifier)_
