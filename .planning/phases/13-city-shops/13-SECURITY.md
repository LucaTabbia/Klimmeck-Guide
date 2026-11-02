---
phase: 13
slug: city-shops
audited: 2026-11-02
status: secured
asvs_level: 1
block_on: high
threats_total: 39
threats_mitigated: 21
threats_accepted: 5
threats_transferred: 7
threats_open: 0
threats_open_blocking: 0
threats_deferred: 6
open_ids: []
deferred_ids: [T-13-32, T-13-33, T-13-34, T-13-36, T-13-37, T-13-38]
updated: 2026-11-02
---

# Phase 13 - Security (City Shops, FE)

Audit of the threat registers of plans 13-01..13-11 (39 rows, T-13-01..T-13-39) against HEAD `72ce2bb` of `feat/13-city-shops` (base `develop` `b6eb4d4`, review fixes of `13-REVIEW-FIX.md` included). Evidence is the final code and the tests named in `13-VALIDATION.md` / the plans (test runs taken from `13-VERIFICATION.md`, not re-run). Plans 13-10 (schema gate vs merged BE SDL) and 13-11 (device E2E, traceability) are gated on the BE Phase 12 merge: their process threats are DEFERRED, not open. BE-side mitigations are TRANSFERRED with BE decision IDs (12-CONTEXT D-14/D-15/D-17/D-19) as evidence; the BE repo was not read or touched. No command read `.env`, `google-services.json` or environment variables. Implementation files read only.

Dispositions: mitigated / accepted / transferred / deferred.

## Threat Register

| ID | STRIDE | Component | Disposition | Evidence | Note |
|----|--------|-----------|-------------|----------|------|
| T-13-01 | DoS | `City.fromJson` size/hasShop | mitigated | `lib/models/city.dart:53` (`asNameMap()[json["size"]]`), `:54` (`hasShop ?? true`); `test/models/city_test.dart` | unknown size -> null, no throw |
| T-13-02 | Tampering | `TransactionItems.petAssets` | accepted | `lib/models/shop/trade_selection.dart` (pets sent qty 1); `test/models/request/transaction_request_test.dart` | BE refuses qty != 1 (`INVALID_QUANTITY`, BE D-17) and re-reads prices (D-19) |
| T-13-03 | DoS | `CityShop.fromJson` | mitigated | `lib/models/city_shop.dart:18` (`FormatException('cityShop.city.id missing')`); `test/models/city_shop_test.dart` | absent lists -> empty |
| T-13-04 | Info disclosure | `GetCityShop` / `PetFragment` selections | mitigated | `lib/graphql/queries/shop_queries.dart:8-12` (`city { id }` only); no pet `imagePath` in `lib/graphql` (grep: only quest/character fragments); `test/graphql/shop_documents_test.dart` | contract-only fields |
| T-13-05 | DoS | `getCityShop`, `_successfulMutation` | mitigated | `lib/repository/services/graphql/graphql.dart:359` (`cityShop malformed`), `:666`, `:713` (`successful is! bool`); `test/repository/services/graphql/` shop tests | |
| T-13-06 | Info disclosure | service errors | mitigated | errors rethrown as `OperationException`, no print (check A) | classified by code downstream |
| T-13-07 | EoP | `EquipPet`/`UnequipPet` | transferred | BE `@OwnsCharacter`, `PET_NOT_OWNED` (BE D-15) | FE sends only current character id |
| T-13-08 | Info disclosure | `transactionFailureFrom`, `petEquipFailureFrom` | mitigated | `lib/repository/transaction_failure.dart:48`, `lib/repository/pet_equip_failure.dart:43` (`graphQlErrorCode`); check B = no `.message`; `test/repository/transaction_failure_test.dart` | |
| T-13-09 | Spoofing/EoP | `equipPet` pet not owned | transferred | BE `PET_NOT_OWNED`/`FORBIDDEN` (BE D-15); FE typed failure + rollback (`companion_cubit.dart`) | |
| T-13-10 | DoS | `CompanionRepository` hang | mitigated | `lib/repository/companion_repository.dart:18` (15 s), `:40` (`.timeout`); `companion_repository_test.dart` (fake_async) | |
| T-13-11 | Info disclosure | `PetEquipException.toString` | mitigated | `lib/repository/pet_equip_failure.dart:38` (`failure.name` only) | |
| T-13-12 | Tampering | `disabledSatchelPages` UI gate | transferred | `lib/screens/mainScreen/components/satchel_availability.dart:28`; BE `SHOP_NOT_IN_CITY`/`ITEM_NOT_IN_SHOP` (BE D-19) | gate is UX only; stale-empty pool until next cold start accepted (RESEARCH Pattern 2) |
| T-13-13 | DoS | missing `hasShop` | mitigated | `lib/models/city.dart:18,54` default `true`; `satchel_availability_test.dart` | |
| T-13-14 | Tampering | stale pool purchase | mitigated | `lib/screens/mainScreen/tabs/shop/shopCubit/shop_cubit.dart:16-26` (`_requestedCityId` last-request-wins); `shop_pool_loader.dart:43` reload on `itemNotInShop`; BE D-19 | `shop_cubit_test.dart` |
| T-13-15 | Info disclosure | `ShopCubit` error path | mitigated | `ShopError(cityId)` no message; check A (no `print`) | |
| T-13-16 | Info disclosure | bubble copy | mitigated | `transactionCubit/transaction_notice.dart:24` fixed copy per typed failure; `transaction_notice_test.dart` | server text never shown |
| T-13-17 | DoS | repeated reloads | accepted | reload only on mount / city id change / `ITEM_NOT_IN_SHOP` (`shop_pool_loader.dart`); `shop_pool_loader_test.dart` | plan-documented accept |
| T-13-18 | Tampering | `TradeSelection.total`/`toTransactionItems` | transferred | BE `TRANSACTION_TOTAL_MISMATCH`, `INVALID_QUANTITY` (BE D-17); `trade_selection_test.dart` | |
| T-13-19 | Tampering | double pet purchase | mitigated | `purchasablePets` + idempotent `addPet` in `lib/models/shop/trade_selection.dart`, `shop_modal.dart`; BE `PET_ALREADY_OWNED` (D-14) | `trade_selection_test.dart` |
| T-13-20 | Info disclosure | `CompanionRow` | accepted | catalogue data only, own character; `companion_row_test.dart` | |
| T-13-21 | Tampering | `canAfford` net-positive relax | transferred | `transaction_modal.dart:70-71`; BE `INSUFFICIENT_FUNDS`/`TRANSACTION_TOTAL_MISMATCH` | net-negative above wallet stays blocked (`transaction_modal_test.dart`) |
| T-13-22 | Tampering | stale pool row after city change | mitigated | `trade_selection.dart:42` `retainPurchasable`; `shop.dart:367,382` | `shop_modal_test.dart` |
| T-13-23 | Repudiation | double submit | mitigated | `transaction_modal.dart:47,172` `canAfford && !_showSignature` | |
| T-13-24 | EoP | equip on purchase | mitigated | check F = no `equipPet`/`unequipPet`/`CompanionCubit` in `tabs/shop` (D-08) | |
| T-13-25 | EoP | equipping a pet not owned | transferred | BE `PET_NOT_OWNED` (BE D-15); FE rollback + silent re-read | `companion_cubit_test.dart` |
| T-13-26 | Tampering | optimistic overlay divergence | mitigated | `companion_cubit.dart:50` `ignoredPending`, settle via `characterUpdated`, timeout re-read | `companion_cubit_test.dart` |
| T-13-27 | Info disclosure | banners | mitigated | `journal/companionCubit/companion_notice.dart` fixed copy | `companion_outcome_listener_test.dart` |
| T-13-28 | DoS | leaked timers | mitigated | `companion_cubit.dart:70-73` `close()` -> `_forget()`, `:168` timer cancel; provider in `authenticated_shell.dart:244-245` | tests per plan |
| T-13-29 | EoP | tap on pet no longer owned | transferred | BE `PET_NOT_OWNED`; FE rollback + silent re-read | |
| T-13-30 | Tampering | double tap while pending | mitigated | `companion_cubit.dart:50` returns `ignoredPending` | `companion_section_test.dart` |
| T-13-31 | Info disclosure | Journal rows | accepted | own pets only, `showCoins: false` | |
| T-13-32 | Tampering | BE working tree during gate | deferred | plan 13-10 (read-only git refs) | gate not yet run |
| T-13-33 | Info disclosure | `.env` during gate | deferred | plan 13-10 | gate not yet run |
| T-13-34 | DoS | documents ahead of BE | deferred | plan 13-10 (43/43 on merged SDL before 13-11) | registry holds 43 documents locally (check E) |
| T-13-35 | Info disclosure | error routing sanity | mitigated | checks A, B (this audit) | |
| T-13-36 | Info disclosure | UAT / BACKEND-NOTES content | deferred | plan 13-11 | |
| T-13-37 | Repudiation | requirement traceability | deferred | plan 13-11 | |
| T-13-38 | Tampering | BE repo read-only | deferred | plan 13-11 | |
| T-13-39 | EoP | innkeeper teleport in UAT | accepted | dev account promoted by user, BE `RolesGuard` unchanged | |

## Cross-cutting checks (run 2026-11-02, read-only)

| Check | Result |
|-------|--------|
| `grep -rn "print(" lib/screens/mainScreen/tabs/shop lib/screens/mainScreen/tabs/journal/companionCubit lib/repository/companion_repository.dart lib/models/shop` | no output (none) |
| `grep -rn "\.message" pet_equip_failure.dart transaction_failure.dart shop/transactionCubit` | no output; classifiers use `graphQlErrorCode` (`:43`, `:48`) |
| `grep -rln "cavalcatura" -i lib` | no output (none) |
| `grep -rn "sellable" lib/screens lib/models/shop/trade_selection.dart` | no output (FE never filters on it) |
| `grep -c "'" tool/schema_check/schema_check_documents.dart` | 68 (quote count; registry size asserted by tests) |
| `grep -n "43" test/graphql/travel_documents_test.dart test/graphql/shop_documents_test.dart` | `travel_documents_test.dart:139-140`, `shop_documents_test.dart:124` expect `schemaCheckDocuments.length == 43` |
| `grep -rn "equipPet\|unequipPet\|CompanionCubit" lib/screens/mainScreen/tabs/shop` | no output (D-08) |
| `git log b6eb4d4..HEAD --format=%B \| grep -ciE "co-authored-by\|generated with"` | 0 |
| `grep -rn "\.env\|google-services" lib` | only pre-existing hits (`main.dart`, `dev_auth_token_service.dart`, `auth_token_service.dart`, `env_config.dart`); `git diff b6eb4d4..HEAD -U0 -- lib` adds none |

## Open

None.

## Deferred

- T-13-32: BE tree stays untouched during the 13-10 gate (read-only git refs); gate waits for the BE Phase 12 merge.
- T-13-33: no `.env` read during the 13-10 gate.
- T-13-34: 43/43 documents proved on the merged SDL (names A1/A2) before 13-11.
- T-13-36: no real ids/tokens/URIs in `13-HUMAN-UAT.md` / `BACKEND-NOTES.md` (13-11).
- T-13-37: requirement traceability only for steps the user confirmed (13-11).
- T-13-38: BE repo read-only during 13-11.
