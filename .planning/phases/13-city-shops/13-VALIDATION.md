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
