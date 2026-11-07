---
phase: 17
slug: unlockable-lore
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-11-07
---

# Phase 17 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test ^10.0.0 + mocktail ^1.0.5 + fake_async ^1.3.3 (pubspec.yaml); stores tested with `FakeSharedPreferencesAsync` (`test/helpers/fakes/`), never `SharedPreferences.setMockInitialValues` (RESEARCH C2) |
| **Config file** | none — shared helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `fixtures/quest_result_fixtures.dart`, `fixtures/travel_fixtures.dart`, `fakes/`) |
| **Quick run command** | `flutter test <touched test paths>` (the `<automated>` command of the task) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, Bash timeout ≥ 300000 ms) |
| **Estimated runtime** | ~10–16 s per task subset; ~76 s full suite (3310 tests on `develop` at 15-08) |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command + the analyzer gate (`OUT=$(flutter analyze 2>&1); ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`, baseline 50 info / 0 error / 0 warning) + trailer check `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` = 0
- **After every plan wave:** Run `flutter test test/models test/graphql test/tool test/repository test/shared test/screens/mainScreen` (one plan = one wave, linear chain)
- **Before `/gsd-verify-work`:** Full suite must be green (schema gate plan)
- **Max feedback latency:** 16 seconds per task subset

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 17-01-01 | 01 | 1 | LORE-0X | T-17-01 / — | _rows added by the planner, one per task_ | unit | `flutter test <paths>` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/models/enums/lore_type_test.dart`, `test/models/enums/library_book_test.dart` — LORE-01 (`label`, `isBestiary`, books)
- [ ] `test/repository/storage/library_bookmarks_store_test.dart` + `getStringList`/`setStringList` in `test/helpers/fakes/fake_shared_preferences_async.dart` — LORE-01
- [ ] `test/helpers/fakes/in_memory_library_bookmarks_store.dart`, `test/helpers/fixtures/lore_fixtures.dart` (`loreJson`, `loreRefJson`) — shared fixtures
- [ ] `test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart`, `library_data_page_test.dart`, `library_test.dart` — LORE-01
- [ ] `test/screens/mainScreen/tabs/map/components/city_modal_test.dart` (or `unknown_city_modal_test.dart`), `test/screens/mainScreen/cubit/main_screen_cubit_test.dart` — LORE-03
- [ ] pinned tests updated RED first (RESEARCH F10, REPO-RULES «Completed after the research»)

No framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Live Library refresh on a real arrival, «Nuovo» across reopenings and restarts, silhouette on the phone, the study roll, delete/recreate reset — all with a player identity (the dev bypass is the innkeeper) | LORE-01, LORE-02, LORE-03 | BE timing (change stream, per-identity filters, 50 % roll) cannot be reproduced in widget tests | `17-HUMAN-UAT.md` (gated UAT plan) |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
