---
phase: 08-spells-section-journal-tab
fixed: 2026-10-27T14:54:25Z
source: 08-REVIEW.md
review_path: .planning/phases/08-spells-section-journal-tab/08-REVIEW.md
iteration: 1
fix_scope: all
findings_total: 6
findings_in_scope: 6
fixed_count: 4
skipped_count: 0
not_needed_count: 2
status: all_fixed
---

# Phase 8: Code Review Fix Report

**Fixed at:** 2026-10-27T14:54:25Z
**Source review:** `.planning/phases/08-spells-section-journal-tab/08-REVIEW.md`
**Iteration:** 1
**Branch:** `feat/08-spells-section-journal-tab` (no push)

**Summary:**
- Findings in the review: 6 (0 critical, 2 warnings, 4 info)
- Findings in scope: 6 (the orchestrator ruled on every Info item)
- Fixed: 4 (WR-01, WR-02, IN-01, IN-02)
- Not needed: 2 (IN-03, which cannot happen as the code is wired today; IN-04, which plan 08-12 owns)
- Skipped: 0

Every behaviour fix went Red → Green: a failing-test commit (`test(spells): …`), then the fix commit. The IN-02 refactor changes no behaviour, so it has no Red commit (testing.md exception). Its pin test ships in the same commit. Commits use Conventional Commits and plain `git`, with no trailers and no history rewriting. CONTEXT D-07, D-16, D-17 and D-18 still hold: no state from `CommonResponse`, one pending operation per spell, an immediate optimistic overlay, and no blocking loading (rule #2).

## Gate after the fixes

| Check | Result |
|-------|--------|
| Quick suite (`test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`) | **1907 passed, 0 failed** (1894 before, +13 new tests) |
| `flutter analyze` | **53 issues, 0 errors**: unchanged baseline, none in a touched file |
| `dart format --output=none --set-exit-if-changed` | every touched file was clean before and was formatted file by file after the edit (no directory format) |
| `tool/schema_check` | not run: no GraphQL document touched |

## Per-finding table

| ID | Outcome | Commits (test → fix) | Note |
|----|---------|----------------------|------|
| WR-01 | fixed: requires human verification | `b3c1dc1` → `41e87ed` | New `SpellOutcomeKind.settledByTimeout` leads to a silent reread with no banner and no shake. `timedOut` is now in the stale-view set |
| WR-02 | fixed: requires human verification | `b5ba4dd` → `25b6cfc` | FIFO in `SpellsCubit`: one mutation in flight, sent in tap order. The overlay and the intent stay immediate. The 15 s settle still counts from the tap |
| IN-01 | fixed | `589b81e` → `edc09ec` | `toggle` sets `_latest` only when nothing was synced (`??=`) |
| IN-02 | fixed | — → `65137c0` | `defaultSettleTimeout = SpellsRepository.defaultTimeout`. A test pins the equality |
| IN-03 | not_needed | — | The section cannot be disposed while the Journal state lives (evidence below) |
| IN-04 | not_needed | — | The BE does not read `requiredLearnTime` and sets no unit. Plan 08-12 decides the display |

## Fixed Issues

### WR-01: No reread after a settle by timeout; `timedOut` not in the stale-view set

**Files modified:** `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_state.dart`, `spells_cubit.dart`, `spell_notice.dart`, `lib/screens/mainScreen/components/spell_outcome_listener.dart`, `lib/screens/mainScreen/tabs/journal/sections/spells_section.dart`

**Tests:**
- `spells_cubit_test.dart`: "a success still unmatched at the timeout clears with a realign outcome (WR-01)". This replaces the old "clears silently" test and uses an unequip, so the outcome carries its operation. "a late matching sync after the realign outcome emits nothing" is also new.
- `spell_outcome_listener_test.dart`: "timedOut: banner and silent re-read (WR-01)" and "a settle by timeout: no banner, silent re-read (WR-01)".
- `spell_notice_test.dart`: "a settle by timeout shows no banner (WR-01)".
- `spells_section_test.dart`: "a settle by timeout does not shake the row (WR-01)".

**Commits:** `b3c1dc1` (test), `41e87ed` (fix)

**Applied fix:**
1. When the 15 s settle timer fires on a request that answered successfully but got no matching `characterUpdated`, `_onSettleTimeout` emits an outcome of kind `settledByTimeout`. The same state also clears the overlay. `_fail` and this path now share a private `_close(spellId, operation, kind, {failure})`, so the emit is not duplicated.
2. `SpellOutcomeListener._isStaleView` is now an exhaustive `switch` on the kind. `settledByTimeout` triggers the reread. `failed` checks the stale-view set, which now includes `timedOut`, because the BE may have run the request. The blocked kinds do not reread. The banner for `timedOut` stays as it was, then the silent `refreshCharacter()` follows.
3. `spellNoticeFor` returns `null` for `settledByTimeout`, so there is no banner (same as `alreadyActive`/`notActive`).
4. The section used to turn every outcome into a resist signal. A settle is not a rejection, so the card must not shake (D-18 rollback is for blocks and rejections only). The new getter `SpellOutcome.springsBack` returns false for `settledByTimeout`, and the section passes no resist signal for it.

`refreshCharacter()` is already silent, idempotent and guarded by generation and `_eventCount`. If the late `characterUpdated` arrives, it wins.

**Human check:** on device, slow the BE answer or drop the WS for more than 15 s after a tap. Then:
- the Journal must realign with no spinner;
- a settle after a success shows no banner;
- a timeout with no answer shows the «Il server non ha risposto in tempo» banner, then the view realigns.

### WR-02: Equip and unequip run in parallel

**Files modified:** `lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart`

**Tests:** `spells_cubit_test.dart` adds the group `one mutation in flight at a time (WR-02)`. The scenario has full slots: unequip A, then equip B. The tests check that:
- both taps are optimistic at once, and only the first call starts;
- the next call starts when the previous one completes, in tap order;
- the next call starts when the previous one fails;
- the settle timeout still counts from the tap;
- a queued operation that settled before its turn is never sent;
- `close` drops the queued calls.

The existing "a new toggle after a timeout is a new operation" test now flushes microtasks between completing the first call and failing the second. With the queue, the second call starts only after the first ends.

**Commits:** `b5ba4dd` (test), `25b6cfc` (fix)

**Applied fix:**
- `_start` no longer fires `_send` with `unawaited`. It appends the job to a `Queue<Future<void> Function()>`. `_drainMutations` runs the jobs one after the other, awaiting each one. When the queue is idle, the first repository call still starts synchronously, so the existing timing holds.
- `_send` never throws: it maps every error to an outcome. A failed call therefore never blocks the queue, and the repository's own 15 s timeout bounds each call.
- `_send` returns early when its token is no longer current. An operation that settled by timeout, or that `close` cleared while it waited, is never sent. Without this, the BE could receive a mutation the UI has already rolled back.
- `close()` clears the queue.
- The overlay, the `toggle` return value (haptics, D-08) and the settle timer that starts at the tap (D-16) are unchanged.

**Human check:** on device, with all slots full, tap an active spell and then quickly tap an inactive one. Both cards should move at once, and the BE log should show `unequipSpell` before `equipSpell`, with no `MAX_ACTIVE_SPELLS_REACHED`.

### IN-01: `toggle` overwrites `_latest` with the widget-captured character

**Files modified:** `spells_cubit.dart`
**Tests:** `spells_cubit_test.dart`: "a tap with an older character keeps the synced one (IN-01)". It syncs a character with A active, taps A with the older character, and completes the request. The operation settles at once, with no timer left. Before the fix it stayed pending until the timeout.
**Commits:** `589b81e` (test), `edc09ec` (fix)
**Applied fix:** `toggle` uses `_latest ??= character`, so only `sync` updates `_latest`. The tap's character is used only until the first state arrives. `SpellOutcomeListener` forwards each `CharacterLoaded` change to `sync` as soon as the stream emits, before the widget rebuilds. So a character from `sync` is never older than the one the widget captured. The intent is still computed on the tap's character (what the user sees). The doc comment on `_latest` explains the reason.

### IN-02: 15 s timeout duplicated between `SpellsRepository` and `SpellsCubit`

**Files modified:** `spells_cubit.dart`, `test/.../spells_cubit_test.dart`
**Commit:** `65137c0` (refactor)
**Applied fix:** `SpellsCubit.defaultSettleTimeout = SpellsRepository.defaultTimeout`, so there is one source for the value. Following the ruling, behaviour does not change: there is no extra margin. The review's alternative (`repositoryTimeout + 2 s`) was not applied. The pin test "settles on the same 15 s as the repository (IN-02)" checks the equality and the 15 s value (D-16).

Since WR-01, a repository `timedOut` and a settle timeout both lead to a reread. So the question of which timer fires first no longer changes how the view realigns.

## Not needed

### IN-03: The sheet can hold a `SpellRecoveryCubit` that is already closed

**File:** `lib/screens/mainScreen/tabs/journal/journal.dart:40`, `280-288`

**Reason:** The stale reference needs the `SpellsSection` element (which owns the `BlocProvider<SpellRecoveryCubit>`) to be disposed while the same `_JournalState` lives on. Reading the code shows this cannot happen today:

1. `SpellsSection` is a fixed child of the Journal `Column`, always built while `CharacterLoaded`, with no conditional sibling before it. Its element, and so its cubit, is kept across rebuilds. The `!spellbook.isVisible` case returns `SizedBox.shrink()` inside `_SpellsSectionBody`, under the provider, so the provider stays mounted.
2. The section can only go away if the Journal builds its `Placeholder()`, which needs a non-loaded `CharacterState`. Only `CharacterCubit.loadCharacter` emits `CharacterLoading`/`CharacterError`. `refreshCharacter` never leaves `CharacterLoaded`, and the stream handlers emit only `CharacterLoaded`.
3. `loadCharacter` has one caller: `MainScreen.initState`. That runs before any Journal page of that `MainScreen` holds a selected spell. `AuthenticatedShell` is keyed by character id, so a new character means a new shell, a new `MainScreen` and a new `_JournalState` with empty selection fields.
4. The `PageView` disposes the Journal when it goes offscreen. That disposes `_JournalState` and its references together with the section.

No code change. If a future change adds a path that reloads the character in place (a `loadCharacter` while the Journal is mounted), the review's fix applies. The fix would clear `_selectedSpell`/`_selectedSpellRecovery` when the state is not loaded, or close the sheet when the section disposes.

### IN-04: `requiredLearnTime` unit not confirmed

**File:** `lib/utils/spell_lines.dart:59-71`
**Reason:** Following the ruling: the BE handoff states that the backend does not read `requiredLearnTime` and sets no unit for it. Plan 08-12, step 2 (contract alignment), owns the final display. If the unit is not milliseconds, that plan has a RED case in `spell_lines_test.dart` and the fix `fix(spells): read the learn time in its BE unit`. Assumption A3 (milliseconds) stays documented in the code. No change in this pass.

---

_Fixed: 2026-10-27T14:54:25Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
