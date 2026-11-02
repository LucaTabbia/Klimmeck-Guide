---
phase: 13
slug: city-shops
status: draft
nyquist_compliant: false
wave_0_complete: false
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
| **Estimated runtime** | ~70 s |

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

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `{tests/test_file.py}` — stubs for REQ-{XX}
- [ ] `{tests/conftest.py}` — shared fixtures
- [ ] `{framework install}` — if no framework detected

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| {behavior} | REQ-{XX} | {reason} | {steps} |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 13s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
