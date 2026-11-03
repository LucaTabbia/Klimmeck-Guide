---
phase: 13
slug: city-shops
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-11-02
---

# Phase 13 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail + fake_async (pubspec.lock) |
| **Config file** | none (shared helpers in test/helpers/) |
| **Quick run command** | `flutter test <touched test paths>` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~77 s (3027 tests, measured in 13-10) |

---

## Sampling Rate

- **After every task commit:** Run `flutter test <touched paths>`
- **After every plan wave:** Run `flutter test test/screens/mainScreen test/models test/repository test/graphql test/tool`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** `flutter test <touched paths>` per task

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 13-01-01 | 01 | 1 | SHOP-02, SHOP-04 | T-13-01 | unknown size → null, absent hasShop → true | unit | `flutter test test/models/pet_test.dart test/models/character/character_assets_test.dart test/models/city_test.dart` | ✅ | ✅ green |
| 13-01-02 | 01 | 1 | SHOP-02, SHOP-04 | T-13-02, T-13-03 | malformed pool → FormatException; pets quantity 1 | unit | `flutter test test/models/city_shop_test.dart test/models/request/transaction_request_test.dart test/models/request/equip_pet_request_test.dart` | ✅ | ✅ green |
| 13-02-01 | 02 | 2 | SHOP-02, SHOP-04 | T-13-04 | contract-only selections, no city name, no imagePath | unit (document) | `flutter test test/graphql test/tool` | ✅ | ✅ green |
| 13-02-02 | 02 | 2 | SHOP-02, SHOP-04 | T-13-05, T-13-06 | malformed payload → FormatException, coded errors rethrown | unit | `flutter test test/repository/services/graphql/graphql_shop_test.dart` | ✅ | ✅ green |
| 13-04-01 | 04 | 2 | SHOP-02 | T-13-12, T-13-13 | shop gate from the BE flag only | unit | `flutter test test/screens/mainScreen/components/satchel_availability_test.dart` | ✅ | ✅ green |
| 13-04-02 | 04 | 2 | SHOP-02 | T-13-12 | Shop disabled, Board open on a shopless marker | widget | `flutter test test/screens/mainScreen/main_screen_test.dart` | ✅ | ✅ green |
| 13-06-01 | 06 | 2 | SHOP-04 | T-13-18, T-13-19 | pets quantity 1, owned pets hidden, no sellable filter | unit | `flutter test test/models/shop/trade_selection_test.dart` | ✅ | ✅ green |
| 13-06-02 | 06 | 2 | SHOP-04 | T-13-20 | speed printed as served, text-only row | widget | `flutter test test/utils/item_lines_test.dart test/shared/components/companion_row_test.dart` | ✅ | ✅ green |
| 13-03-01 | 03 | 3 | SHOP-03 | T-13-08 | codes only, new refusals in the bubble, banner only off-city | unit | `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart` | ✅ | ✅ green |
| 13-03-02 | 03 | 3 | SHOP-04 | T-13-09, T-13-10, T-13-11 | typed failures, 15 s timeout, no payload in toString | unit | `flutter test test/repository/pet_equip_failure_test.dart test/repository/companion_repository_test.dart` | ✅ | ✅ green |
| 13-05-01 | 05 | 4 | SHOP-02 | T-13-14, T-13-15 | last-request-wins, no raw text, no print | bloc | `flutter test test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart` | ✅ | ✅ green |
| 13-05-02 | 05 | 4 | SHOP-02, SHOP-03 | T-13-14, T-13-17 | load on open / city change / ITEM_NOT_IN_SHOP only | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_pool_loader_test.dart` | ✅ | ✅ green |
| 13-05-03 | 05 | 4 | SHOP-02, SHOP-03 | T-13-16 | matching pool only, bubble copy from typed failures, 43 documents | unit (registry) | `flutter test test/graphql test/tool` | ✅ | ✅ green |
| 13-07-01 | 07 | 5 | SHOP-03, SHOP-04 | T-13-21, T-13-23 | net-positive signable, net-negative above wallet refused, one-shot signature | widget | `flutter test test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart` | ✅ | ✅ green |
| 13-07-02 | 07 | 5 | SHOP-03, SHOP-04 | T-13-22, T-13-24 | owned pets hidden, legendary sellable, no equip on purchase | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart` | ✅ | ✅ green |
| 13-08-01 | 08 | 5 | SHOP-04 | T-13-26, T-13-28 | overlay settled only by the subscription, timer cleanup | bloc | `flutter test test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart` | ✅ | ✅ green |
| 13-08-02 | 08 | 5 | SHOP-04 | T-13-25, T-13-27 | fixed copy, stale views re-read silently | widget | `flutter test test/screens/mainScreen/tabs/journal/companionCubit test/screens/mainScreen/components/companion_outcome_listener_test.dart` | ✅ | ✅ green |
| 13-08-03 | 08 | 5 | SHOP-04 | T-13-28 | provider closed with the shell | widget | `flutter test test/screens/auth test/screens/mainScreen` | ✅ | ✅ green |
| 13-09-01 | 09 | 6 | SHOP-04 | T-13-29, T-13-30 | owned ids only, one tap per sheet, no travel gate | widget | `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart` | ✅ | ✅ green |
| 13-09-02 | 09 | 6 | SHOP-04 | T-13-31 | slot after Armatura, no price | widget | `flutter test test/screens/mainScreen/tabs/journal` | ✅ | ✅ green |
| 13-10-01 | 10 | 7 | SHOP-02, SHOP-03, SHOP-04 | T-13-32, T-13-34 | names proven on the merged SDL, 43 OK | cross-repo | schema check of 13-10 | ✅ | ✅ green |
| 13-10-02 | 10 | 7 | SHOP-02, SHOP-03, SHOP-04 | T-13-35 | full suite, analyzer, format, trailers | full suite | `flutter test` | ✅ | ✅ green |
| 13-11-01 | 11 | 8 | SHOP-02, SHOP-03, SHOP-04 | — | gate re-check, UAT file | manual prep | `test -f .planning/phases/13-city-shops/13-HUMAN-UAT.md` | ❌ W8 | ⬜ pending |
| 13-11-02 | 11 | 8 | SHOP-02, SHOP-03, SHOP-04 | — | device E2E: three pools, companion bought/equipped/sold, Shop cell disabled on Necrorian | manual (device) | `13-HUMAN-UAT.md` (11 steps) | ❌ W8 | ⬜ pending (human E2E) |
| 13-11-03 | 11 | 8 | SHOP-02, SHOP-03, SHOP-04 | — | records: handoff `BACKEND-NOTES.md`, requirements, ROADMAP/STATE closure | manual (records) | `test -f .planning/phases/13-city-shops/BACKEND-NOTES.md` | ❌ W8 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

Schema gate of 13-10 (2026-11-03, BE `origin/develop` `0585b2e`, merge of PR #18 `feat/12-negozi-per-citta`): `grep -c cityShop` = 3; `CityShop { city equipment loot pets }`, `CitySize { capital city village }`, `City.size: CitySize!` / `City.hasShop: Boolean!`, `CharacterAssets.ownedPets: [Pet!]!`, `TransactionItems.petAssets: [AssetQuantityInput!]`, `Pet.sellable: Boolean` / `Pet.speedModifier: Float`, `equipPet(request: EquipPetRequest!)` / `unequipPet(request: UnequipPetRequest!)`, `cityShop(cityId: ID!): CityShop!`, codes `ITEM_NOT_IN_SHOP` / `PET_ALREADY_OWNED` / `PET_NOT_OWNED` (A1/A2/A3 confirmed, no alignment needed); `dumped 43 documents`, 43 × OK, 0 failures.

---

## Wave 0 Requirements

Gaps listed in `13-RESEARCH.md` §Wave 0 Gaps, all closed by plans 13-01..13-09 (every file exists on `feat/13-city-shops`, verified in 13-10 with `git diff --name-only --diff-filter=A develop...HEAD -- test`):

- [x] `test/models/city_test.dart`, `test/models/pet_test.dart`, `test/models/city_shop_test.dart`, `test/models/character/character_assets_test.dart`, `test/models/request/transaction_request_test.dart`, `test/models/request/equip_pet_request_test.dart` — SHOP-02/04 models (13-01)
- [x] `test/graphql/shop_documents_test.dart` — documents (13-02); `test/repository/services/graphql/graphql_shop_test.dart` — service (13-02)
- [x] `test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart`, `test/screens/mainScreen/tabs/shop/components/shop_pool_loader_test.dart`, `test/screens/mainScreen/tabs/shop/shop_test.dart` — shop call (13-05); `test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart` — sheets (13-07)
- [x] `test/models/shop/trade_selection_test.dart`, `test/shared/components/companion_row_test.dart` — trade selection and companion row (13-06)
- [x] `test/repository/pet_equip_failure_test.dart`, `test/repository/companion_repository_test.dart` — classifiers (13-03)
- [x] `test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart`, `companion_notice_test.dart`, `test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart`, `test/screens/mainScreen/components/companion_outcome_listener_test.dart` — companion cubit, notice, listener, slot (13-08, 13-09)
- [x] `test/helpers/mocks.dart`: `MockShopCubit`, `MockCompanionCubit`, `MockCompanionRepository`; fallback values for `EquipPetRequest`/`UnequipPetRequest`
- [x] `test/helpers/fixtures/shop_fixtures.dart` — pool JSON (equipment, loot, a mount pet, a non-mount pet), owned/equipped pets; `test/helpers/fakes/svg_http_overrides.dart` — network SVG stand-in for the shop page test
- [x] Provider/harness updates: `test/screens/mainScreen/main_screen_test.dart`, `test/screens/mainScreen/main_screen_quest_results_test.dart`, `test/screens/auth/authenticated_shell_test.dart`, `test/helpers/journal_harness.dart` (`CompanionCubit` provided next to `SpellsCubit`)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Device E2E: three different pools (village, city, capital) with no legendary item, no city name on the sheets, companion bought where sold (Talmvere → Cavallo da viaggio), equipped in the Journal, sold elsewhere with the slot emptied by the subscription, Shop cell disabled on Necrorian while the Board stays open | SHOP-02, SHOP-03, SHOP-04 | real BE pools, real `characterUpdated` subscription, satchel gesture and parchment visuals on a device | `13-HUMAN-UAT.md` (plan 13-11), 11 steps; requirement ↔ step map SHOP-02 (1, 2, 5, 6, 9), SHOP-03 (7, 8, 10), SHOP-04 (2, 3, 4, 6, 7) |
| `ITEM_NOT_IN_SHOP` refusal in the shopkeeper bubble («Questa merce non la tratto») and the stale row gone after the pool reload | SHOP-03 | needs a DB curation of the city pool while the shop page is open (optional step 10) | with the shop open, remove a listed item from that city's pool in the DB (field name from the BE Phase 12 handoff), buy it → bubble line, row disappears after the reload |
| Equip / unequip a companion during a travel (slot interactive, no effect on the current travel) | SHOP-04 | needs a live travel and the real `equipPet` / `unequipPet` round trip (optional step 11, BE D-15) | start a travel, open the Journal «Compagno» slot, equip then unequip an owned pet → slot follows, travel unchanged |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 13s (`flutter test <touched test paths>` per task; the 13-10 subset of 643 tests ran in 15 s, single files well below)
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** pending (device rows 13-11-01..03 after the E2E of plan 13-11)
