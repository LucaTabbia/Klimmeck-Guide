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
| 8-03-01 | 03 | 2 | SPELL-01, SPELL-05 | T-8-09 | one `BookmarkRibbon`; equipment card and sheet keep geometry (left, length, peek, curve, top offsets), sheet tap → `onEquip` once, no ribbon when the equip state is `null` | widget | `flutter test test/shared/components/bookmark_ribbon_test.dart test/shared/components/cards test/shared/components/popup` | ✅ | ✅ green |
| 8-03-02 | 03 | 2 | SPELL-01, SPELL-05 | T-8-08 | `SpellCard` renders without `!` crashes when `useType`, `energyDamage` or `power` are null; bookmark only when `isMarked` is non-null; pending-ink tokens 0.5 / 200 ms | widget | `flutter test test/shared/components/cards` | ✅ | ✅ green |
| 8-03-03 | 03 | 2 | SPELL-05 | — | N/A (pure extraction: `UsagesPencilCounter` shared by both cards, behaviour identical) | widget | `flutter test test/shared/components` | ✅ | ✅ green |
| 8-04-01 | 04 | 2 | SPELL-05 | T-8-10 | recovery derived only from `recoveries[0] − serverNow` (earliest instant); usages never restored locally; past instant → `Arriving` until the BE emits; full/over-max/null max → `Full`; no instants → `Unknown`; countdown quantized to whole minutes (0 = under a minute) | unit | `flutter test test/models/spell/spell_recovery_status_test.dart` | ✅ | ✅ green |
| 8-04-02 | 04 | 2 | SPELL-02, SPELL-05 | T-8-11 | durations formatted (no raw ms), fixed Italian copy, no ids; summary line, detail labels and empty-state copies defined once | unit | `flutter test test/utils/spell_lines_test.dart` | ✅ | ✅ green |
| 8-05-01 | 05 | 2 | SPELL-01, SPELL-04, SPELL-07 | T-8-12 / T-8-14 | null `ActiveSpell.spell` skipped; slots generated from `maxActiveSpells` only with a bounds check (extra actives only marked in the list); usages fallback state → `ActiveSpell.usages` → catalog `maxUsages`; visibility iff spells or slots | unit | `flutter test test/models/spell/spellbook_test.dart` | ✅ | ✅ green |
| 8-05-02 | 05 | 2 | SPELL-03, SPELL-04 | T-8-13 | optimistic view = server − pending unequips + pending equips (tap order, known spells only, no duplicates); intents on the optimistic count (pending → ignored, F5 slots-full block, no slots → blocked, legacy active with 0 slots → unequip) | unit | `flutter test test/models/spell/spellbook_test.dart` | ✅ | ✅ green |
| 8-06-01 | 06 | 3 | SPELL-03, SPELL-04 | T-8-16 / T-8-17 | one pending op per spell (tap on pending → `ignoredPending`, no call); blocked intents (slots full on the optimistic count, no slots) never call the BE and emit a sequenced outcome; `sync` clears only operations matched by server `activeSpells`; no state read from the mutation response, no Flutter import | unit (bloc) | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit` | ✅ | ✅ green |
| 8-06-02 | 06 | 3 | SPELL-04, SPELL-06 | T-8-15 / T-8-16 / T-8-18 | every op ends once: subscription match, failure (outcome with `SpellEquipFailure`, non-domain → `unknown`) or 15 s timer (succeeded → silent, in flight → `timedOut`); request tokens drop late answers; `close()` cancels all timers and late answers emit nothing | unit (fakeAsync) | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit` | ✅ | ✅ green |
| 8-07-01 | 07 | 3 | SPELL-05 | T-8-19 / T-8-21 | statuses derived per known spell from `ServerClockService.now()` (never `DateTime.now`); `inputsOf` maps entries in list order with the usages fallback; equal states deduplicated; no Flutter import | unit (bloc) | `flutter test test/screens/mainScreen/tabs/journal/spellRecoveryCubit` | ✅ | ✅ green |
| 8-07-02 | 07 | 3 | SPELL-05 | T-8-19 / T-8-20 / T-8-21 | periodic timer only while a countdown exists (stops at `Arriving`, none for Full/Unknown/Arriving); emits only when the shown minute changes; `offsetChanges` re-derives and restarts the timer; `Arriving` never restores a use (new `follow` does); `close()` leaves no timer and ignores later offset events | unit (fakeAsync) | `flutter test test/screens/mainScreen/tabs/journal/spellRecoveryCubit` | ✅ | ✅ green |
| 8-08-01 | 08 | 3 | SPELL-02, SPELL-04 | T-8-22 | `SpellInfo` has no `!` reads: every line (name, description, energy/use icons, damage, use type, max usages, recovery time, learn requirements, current usages + recovery) appears only when its data exists; an all-null catalog spell renders without exception | widget | `flutter test test/shared/components/spell_info_test.dart` | ✅ | ✅ green |
| 8-08-02 | 08 | 3 | SPELL-04 | T-8-23 | `SpellInfoSheet` only calls `onToggle` (decision stays in `SpellsCubit`, wired in 08-11); ribbon marked iff active, pending ink 0.5 iff pending, inert without `onToggle`; no AppBar/SnackBar/AlertDialog | widget | `flutter test test/shared/components/popup test/shared/components/bookmark_ribbon_test.dart` | ✅ | ✅ green |
| 8-09-01 | 09 | 3 | SPELL-01, SPELL-07 | T-8-24 / T-8-25 | slot row = exactly `slots.length` boxes in a `Wrap` (bounded by `Spellbook`), zero slots → neutral line only; slot card shows the counter only, pending ink 0.5 only from `SpellSlot.isPending`; gestures only reported via callbacks (no cubit, no haptics); `SpellResist` shakes once per new non-null trigger | widget | `flutter test test/screens/mainScreen/tabs/journal/components/spell_resist_test.dart test/screens/mainScreen/tabs/journal/components/spell_slot_row_test.dart` | ✅ | ✅ green |
| 8-09-02 | 09 | 3 | SPELL-01, SPELL-02 | T-8-24 | row card without counter, bookmark iff `entry.isActive`, pending ink iff `entry.isPending`; compact line from `spellSummaryLine`; rows in BE order (no re-ordering), missing recovery → `Full`; empty list → «Non hai ancora imparato nessuna magia»; resist signal shakes only that spell's row and slot | widget | `flutter test test/screens/mainScreen/tabs/journal/components` | ✅ | ✅ green |
| 8-10-01 | 10 | 4 | SPELL-06 | T-8-26 / T-8-27 / T-8-28 / T-8-29 | `spellNoticeFor` copy only from the domain enum (no `SPELL_`/`MAX_`/`Exception`/`null` in any description, no server `.message`); `alreadyActive`/`notActive`/`unauthenticated` → no banner; listener syncs every new loaded character, reacts only to a changed `outcome`, publishes via `publishNotice` with dedup key `spell\|kind\|failure\|spellId`, silent `refreshCharacter()` on the five stale-view codes, nothing on `unauthenticated` | unit + widget | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit/spell_notice_test.dart test/screens/mainScreen/components/spell_outcome_listener_test.dart` | ✅ | ✅ green |
| 8-10-02 | 10 | 4 | SPELL-06 | T-8-30 | `SpellsCubit` provided by `AuthenticatedShell` (fresh `SpellsState`, closed on shell removal), never by a Journal tab; `SpellOutcomeListener` mounted in `MainScreen` so a rollback banner appears on any page | widget | `flutter test test/screens/auth test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/components` | ✅ | ✅ green |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/fixtures/spell_fixtures.dart`: `spellJson`, `activeSpellJson`, `spellStateJson`, `spellbookCharacterJson` (with and without `spellStates`; UTC ISO instants) — plan 08-01
- [ ] `test/helpers/mocks.dart`: `MockSpellsRepository`, `MockSpellsCubit`, `MockSpellRecoveryCubit` (registerFallbackValue for `Character` where `toggle`/`sync` are verified)
- [ ] (base in 08-09: `test/helpers/spells_harness.dart` `pumpSpellsHarness(tester, child, {wrap})` + `seedSpellSvgs()`; providers via `wrap` in 08-11) A section harness helper (fixed-width `SingleChildScrollView` + providers: `CharacterCubit`, `SpellsCubit`, `RepositoryProvider<ServerClockService>.value(FakeServerClockService)`) and `seedSvgCache` ids for the spell fixtures
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
