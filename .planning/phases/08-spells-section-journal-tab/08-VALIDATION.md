---
phase: 8
slug: spells-section-journal-tab
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-10-27
---

# Phase 8 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 + fake_async 1.3.3 |
| **Config file** | none (mocks `test/helpers/mocks.dart`, fixtures `test/helpers/fixtures/`, fakes `test/helpers/fakes/`) |
| **Quick run command** | `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth` |
| **Full suite command** | `flutter test` + `flutter analyze` (≤ 53 issues, 0 errors) |
| **Estimated runtime** | ~25 s quick / ~50 s full |

---

## Sampling Rate

- **After every task commit:** the task's test file(s) + `flutter analyze <touched files>` + format check on new/clean files only
- **After every plan wave:** Run `flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`
- **Before `/gsd-verify-work`:** Full suite must be green (`flutter test` + `flutter analyze` ≤ 53 issues, 0 errors)
- **Max feedback latency:** ~25 s

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 8-01-01 | 01 | 1 | SPELL-05 | T-8-01 / T-8-02 | malformed `spellStates` entries skipped, non-list → `null`, the rest of the status parses; recoveries UTC and sorted ascending | unit | `flutter test test/models/spell/spell_state_test.dart test/models/character` | ✅ | ✅ green |
| 8-01-02 | 01 | 1 | SPELL-02 | — | N/A (pure move, behaviour identical) | unit | `flutter test test/utils/game_duration_format_test.dart test/models/travel test/screens/mainScreen/tabs/map` | ✅ | ✅ green |
| 8-02-01 | 02 | 1 | SPELL-03, SPELL-06 | T-8-03 / T-8-04 | `EquipSpellRequest` never sends `usages`; `EquipSpell`/`UnequipSpell` return only `successful` (no state from the response); registry keys renamed, still 34 | unit | `flutter test test/models/request/equip_spell_request_test.dart test/graphql/spell_documents_test.dart test/tool test/repository/services/graphql/graphql_spells_test.dart` | ✅ | ✅ green |
| 8-02-02 | 02 | 1 | SPELL-04, SPELL-06 | T-8-05 / T-8-06 / T-8-07 | classification by `extensions.code` only (message ignored); `FORBIDDEN` → `forbidden`; 15 s → `timedOut`; no `OperationException` escapes `SpellsRepository` | unit | `flutter test test/repository/spell_equip_failure_test.dart test/repository/spells_repository_test.dart` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/fixtures/spell_fixtures.dart`: `spellJson`, `activeSpellJson`, `spellStateJson`, `spellbookCharacterJson` (with and without `spellStates`; UTC ISO instants) — plan 08-01
- [ ] `test/helpers/mocks.dart`: `MockSpellsRepository`, `MockSpellsCubit`, `MockSpellRecoveryCubit` (registerFallbackValue for `Character` where `toggle`/`sync` are verified)
- [ ] A section harness helper (fixed-width `SingleChildScrollView` + providers: `CharacterCubit`, `SpellsCubit`, `RepositoryProvider<ServerClockService>.value(FakeServerClockService)`) and `seedSvgCache` ids for the spell fixtures
- [x] Move `test/models/travel/travel_time_format_test.dart`'s `formatTravelDuration` group to `test/utils/game_duration_format_test.dart` — plan 08-01
- [ ] `main_screen_test.dart` provider for `MockSpellsCubit` (Pitfall 9) in the plan that mounts the listener

No framework install needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Countdown from real `recoveries` (~2 min and ~30 min) on the active spell; «in arrivo…» then the use returns within the sweep (≤ 60 s) | SPELL-05 | real BE clock, Bull job/sweep | Journal open on the `mage` UAT character; watch the first instant pass |
| Unequip a recovering spell: countdown keeps running in its row; re-equip: usages unchanged (D-01 user rule) | SPELL-05 | needs 9.1 semantics | tap active row, wait, tap again |
| Equip/unequip optimistic look then full on `characterUpdated` | SPELL-06 | real subscription latency | tap rows/slot cards |
| Full slots → resist + banner, no network call; zero-slot character → neutral line + «Nessuno slot disponibile» | SPELL-03, SPELL-07 | real data | sub-mage UAT character |
| Race rejection (`MAX_ACTIVE_SPELLS_REACHED` / `SPELL_ALREADY_ACTIVE` from a second client) → rollback + banner / silent realign | SPELL-06 | needs a second client | GraphiQL equip on the same character, then tap |
| Phone clock moved: countdown unchanged | SPELL-05 | system clock | settings → time |
| Long-press sheet and its toggle | SPELL-04 | gesture feel | — |
| Slot unlock: GM raises xp/title → new box appears live | SPELL-07 | BE data change | innkeeper/DB edit |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 8s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
