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
| 17-01-01 | 01 | 1 | LORE-01 | T-17-01 | unknown/missing lore type → null, entry kept; wire type round trips; Italian titles pinned | unit/widget | `flutter test test/models/enums/lore_type_test.dart test/models/lore_test.dart test/screens/mainScreen/tabs/library/library_data_page_test.dart test/graphql/lore_documents_test.dart` | ❌ W0 (`lore_type_test.dart`, `library_data_page_test.dart`, `lore_fixtures.dart`) | ✅ green |
| 17-01-02 | 01 | 1 | LORE-01 | T-17-02, T-17-03 | `unlockedLore` non-list → `[]`, non-strings dropped, carried by `copyWith`; fragment in the same commit; registry 45 | unit | `flutter test test/models test/graphql test/tool test/screens/mainScreen/characterCubit` | ✅ (extend `character_status_test.dart`, `character_fragment_test.dart`) | ✅ green |
| 17-02-01 | 02 | 2 | LORE-02 | T-17-04, T-17-06 | missing/non-bool `known` drops the board quest or the result entry; `toJson` writes `known`; fixture default `true` in the same commit | unit | `flutter test test/models test/graphql test/tool test/shared test/screens/mainScreen` | ✅ (pins RED first: `board_documents_test.dart:51-55`, `quest_result_documents_test.dart:50-66`, `quest_enemy_test.dart`) | ✅ green |
| 17-02-02 | 02 | 2 | LORE-02 | T-17-05 | the strongest entry carries its own `known`; no client inference | unit | `flutter test test/models/quest test/shared/components/popup` | ✅ (extend `quest_enemy_test.dart`, `quest_sheet_details_test.dart`) | ✅ green |
| 17-03-01 | 03 | 3 | LORE-02 | T-17-07 | malformed `loreUnlocked` entries dropped, result kept; round trip; registry 45 | unit | `flutter test test/models test/graphql test/tool test/shared/components/popup test/screens/mainScreen/questResultsCubit test/screens/mainScreen/components` | ✅ (extend `quest_result_test.dart`, `quest_result_documents_test.dart`) | ✅ green |
| 17-03-02 | 03 | 3 | LORE-02 | T-17-08, T-17-09 | lines as plain text from `loreUnlocked` only, prefix by BE type, no `outcome` branch | widget | `flutter test test/shared/components/popup test/screens/mainScreen/components` | ✅ (extend `quest_result_sheet_test.dart`) | ✅ green |
| 17-04-01 | 04 | 4 | LORE-02 | T-17-10 | `ColorFiltered(srcIn, deepNight)` over SVG and raster; «Sagoma del nemico»; no pixel reads | widget | `flutter test test/shared/components/enemy_portrait_test.dart` | ✅ (extend `enemy_portrait_test.dart`) | ✅ green |
| 17-04-02 | 04 | 4 | LORE-02 | T-17-11 | sheets pass the BE `known` of the strongest enemy only | widget | `flutter test test/shared/components/popup test/screens/mainScreen/components test/screens/mainScreen/tabs/board` | ✅ (extend `quest_info_sheet_test.dart`, `quest_result_sheet_test.dart`) | ✅ green |
| 17-05-01 | 05 | 5 | LORE-01 | — | four books with today's mapping; every type in one book | unit | `flutter test test/models/enums/library_book_test.dart` | ❌ W0 (`library_book_test.dart`) | ⬜ pending |
| 17-05-02 | 05 | 5 | LORE-01 | T-17-12, T-17-13, T-17-14 | baselines keyed per character and book, outside `klimmeck.session`; failures reach the caller | unit | `flutter test test/repository/storage` | ❌ W0 (`library_bookmarks_store_test.dart`, `in_memory_library_bookmarks_store.dart`, fake `getStringList`/`setStringList`) | ⬜ pending |
| 17-06-01 | 06 | 6 | LORE-01 | T-17-15, T-17-16, T-17-17, T-17-18 | set comparison, single-flight + trailing, stale completion dropped, no loading/error on refresh, marks vs baseline | bloc | `flutter test test/screens/mainScreen/tabs/library test/screens/auth test/screens/mainScreen/main_screen_test.dart` | ❌ W0 (`library_cubit_test.dart`) | ⬜ pending |
| 17-06-02 | 06 | 6 | LORE-01 | T-17-15, T-17-17 | `BlocListener<CharacterCubit>` forwards ids, seeded at mount; no spinner nor `Placeholder` | widget | `flutter test test/screens/mainScreen/tabs/library` | ❌ W0 (`library_test.dart`) | ⬜ pending |
| 17-07-01 | 07 | 7 | LORE-01 | T-17-20, T-17-21 | «Nuovo» ribbon in the book ink; null-safe name/description | widget | `flutter test test/screens/mainScreen/tabs/library/components/lore_card_test.dart` | ❌ W0 (`lore_card_test.dart`) | ⬜ pending |
| 17-07-02 | 07 | 7 | LORE-01 | T-17-19 | only received lore rendered; empty sections hidden; empty-book line; `ValueKey(type)` | widget | `flutter test test/screens/mainScreen/tabs/library` | ✅ (extend `library_data_page_test.dart`, `library_test.dart`) | ⬜ pending |
| 17-08-01 | 08 | 8 | LORE-03 | T-17-22, T-17-23 | null `relatedLore` → name-only modal, never `lore(id)` | widget | `flutter test test/screens/mainScreen/tabs/map` | ❌ W0 (`unknown_city_modal_test.dart`) + extend `world_map_teleport_test.dart` | ⬜ pending |
| 17-08-02 | 08 | 8 | LORE-03 | T-17-24 | silent `refreshCities` (no `MainScreenLoading`, list kept on failure) on an id-set change | bloc/widget | `flutter test test/screens/mainScreen` | ❌ W0 (`main_screen_cubit_test.dart`) + extend `main_screen_test.dart` | ⬜ pending |
| 17-09-01 | 09 | 9 | LORE-01..03 | T-17-25, T-17-26, T-17-27 | BE read-only, no fetch; no `.env`; 45/45 OK before the device | gate | `git -C <BE> show origin/develop:src/schema.gql \| grep -c loreUnlocked` + `flutter test test/graphql test/tool test/models test/repository` | ✅ | ⬜ pending |
| 17-09-02 | 09 | 9 | LORE-01..03 | T-17-28 | sanity greps: no `knownEnemies`, no cubit-to-cubit stream, no `relatedLore!`, lore queries unchanged | gate | `flutter test` (full) | ✅ | ⬜ pending |
| 17-10-01 | 10 | 10 | LORE-01..03 | T-17-29, T-17-31 | UAT record with the player identity, without ids/URIs/tokens | doc | `grep -cE "^\| [1-8] \|" .planning/phases/17-unlockable-lore/17-HUMAN-UAT.md` | ❌ (created by the task) | ⬜ pending |
| 17-10-02 | 10 | 10 | LORE-01..03 | T-17-32 | human checkpoint; BE, identity and DB seeds outside the repo | manual | device E2E (`17-HUMAN-UAT.md`) | — | ⬜ pending |
| 17-10-03 | 10 | 10 | LORE-01..03 | T-17-29, T-17-30 | mark-complete only on passed steps | doc | `grep -q "## 3. UAT outcome" .planning/phases/17-unlockable-lore/BACKEND-NOTES.md` | ❌ (created by the task) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/models/enums/lore_type_test.dart` (17-01), `test/models/enums/library_book_test.dart` (17-05) — LORE-01 (`label`, `isBestiary`, books)
- [x] `test/repository/storage/library_bookmarks_store_test.dart` + `getStringList`/`setStringList` in `test/helpers/fakes/fake_shared_preferences_async.dart` (17-05) — LORE-01
- [x] `test/helpers/fakes/in_memory_library_bookmarks_store.dart` (17-05), `test/helpers/fixtures/lore_fixtures.dart` (`loreJson`, `loreRefJson`, 17-01) — shared fixtures
- [x] `test/screens/mainScreen/tabs/library/cubit/library_cubit_test.dart` (17-06), `library_data_page_test.dart` (17-01, extended 17-07), `library_test.dart` (17-06), `components/lore_card_test.dart` (17-07) — LORE-01
- [x] `test/screens/mainScreen/tabs/map/components/unknown_city_modal_test.dart`, `test/screens/mainScreen/cubit/main_screen_cubit_test.dart` (17-08) — LORE-03
- [x] pinned tests updated RED first (RESEARCH F10, REPO-RULES «Completed after the research»): 17-01 (`character_status_test`, `character_fragment_test`, `lore_test`), 17-02 (`board_documents_test`, `quest_result_documents_test`, `quest_enemy_test`, `quest_fixtures`, `quest_sheet_details_test`), 17-03 (`quest_result_test`), 17-04 (`enemy_portrait_test`, sheets), 17-06 (`authenticated_shell_test`), 17-08 (`world_map_teleport_test`, `main_screen_test`)

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
