---
phase: 08-spells-section-journal-tab
plan: 11
subsystem: ui
tags: [flutter, dart, bloc, spells, journal, haptics, sliding-sheet]

# Dependency graph
requires:
  - phase: 08-05
    provides: "`Spellbook.of(character, pending:)`, `entryFor`, `activeSpellIds`, `SpellToggleIntent`"
  - phase: 08-06
    provides: "`SpellsCubit.toggle(character, spellId) → SpellToggleIntent` (positional), `SpellsState { pending, outcome }`"
  - phase: 08-07
    provides: "`SpellRecoveryCubit({clock})`, `inputsOf`, `follow`, `state.statuses` / `statusOf`"
  - phase: 08-08
    provides: "`SpellInfoSheet({spell, usages, recovery, isActive, isPending, onToggle})`"
  - phase: 08-09
    provides: "`SpellbookContent`, `SpellResistSignal`, keys `spell-row-<id>` / `spell-slot-<id>`, `pumpSpellsHarness(…, wrap:)`"
  - phase: 08-10
    provides: "`SpellsCubit` provided by `AuthenticatedShell`, `SpellOutcomeListener` in `MainScreen`, `MockSpellsCubit`"
provides:
  - "`SpellsSection({cardSize, onShowDetails})`: «Magie imparate» section owning the `SpellRecoveryCubit` (dies with the Journal page)"
  - "`toggleSpellWithFeedback(context, character:, spellId:)`: haptics from the `SpellsCubit` intent"
  - "`SpellDetailsSheet({spell})`: `SpellInfoSheet` bound to live `CharacterCubit` / `SpellsCubit` / `SpellRecoveryCubit` state"
  - "`typedef ShowSpellDetails = void Function(Spell, SpellRecoveryCubit)`"
  - "Journal hosting the section and the spell sheet in its existing sliding info sheet; `SpellRow` removed"
affects: [08-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Section-owned ticker cubit handed to a sheet hosted higher in the tree via `BlocProvider.value` (the sheet never owns the cubit)"
    - "Haptic chosen from the intent returned synchronously by the cubit action (widgets own haptics, cubits own decisions)"

key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/sections/spells_section.dart
    - test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart
    - test/screens/mainScreen/tabs/journal/journal_spells_test.dart
  modified:
    - lib/screens/mainScreen/tabs/journal/journal.dart
  deleted:
    - lib/shared/components/spell_row.dart

key-decisions:
  - "`SpellsCubit.toggle` is called positionally (`toggle(character, spellId)`), the real 08-06 API, not with the named arguments of the plan sketch"
  - "One info-sheet slot in the Journal: equipment and spell selections are mutually exclusive; the dismissed status clears both"
  - "`_buildEquipmentInfoSheet` renamed `_buildInfoSheet`; its child falls back to `_buildSpellSheet()` when no equipment is selected"
  - "`test/helpers/spells_harness.dart` unchanged: the `wrap:` parameter of 08-09 was enough for the providers"

patterns-established:
  - "Journal sections live in `tabs/journal/sections/` as self-contained widgets reading their own cubits (D-21)"

requirements-completed: []

# Metrics
duration: 25min
completed: 2026-10-27
---

# Phase 8 Plan 11: Spells Section and Journal Wiring Summary

**`SpellsSection` with a section-owned live countdown, intent-driven haptics and D-18 shake, plus the long-press `SpellDetailsSheet` hosted in the Journal's existing sliding sheet; the old `_buildSpellsSection` (with its `!` reads) and `SpellRow` are gone.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-10-27T14:13:30Z
- **Completed:** 2026-10-27T14:38:00Z
- **Tasks:** 2
- **Files modified:** 5 (3 created, 1 modified, 1 deleted)

## Accomplishments

- `SpellsSection` (`lib/screens/mainScreen/tabs/journal/sections/spells_section.dart`): `BlocProvider<SpellRecoveryCubit>(create:)` with the `ServerClockService`; `initState` follows the current character, a `BlocListener<CharacterCubit>` re-follows on every new character; `BlocSelector<CharacterCubit>` → `BlocBuilder<SpellsCubit>` builds `Spellbook.of(character, pending:)`, returns `SizedBox.shrink()` when not visible, otherwise `Dropdown('Magie imparate', SpellbookContent(...))` with the recovery statuses, the toggle handler, the long-press callback and the resist signal from `SpellsState.outcome`.
- `toggleSpellWithFeedback`: `equip`/`unequip` → `HapticFeedback.lightImpact()`, `blockedSlotsFull`/`blockedNoSlots` → `HapticFeedback.selectionClick()`, `ignoredPending`/`ignoredUnknown` → nothing.
- `SpellDetailsSheet`: live `isActive`/`isPending` from the optimistic `Spellbook`, `usages` from `entryFor`, recovery from `SpellRecoveryCubit.state.statusOf`, ribbon → `toggleSpellWithFeedback`.
- `journal.dart` (hand edits, never formatted): `SpellsSection(cardSize: lootSize, onShowDetails: _selectSpell)` in place of `_buildSpellsSection(lootSize)`; fields `_selectedSpell` / `_selectedSpellRecovery`; `_selectSpell` / `_selectEquipment` clear each other; the dismissed status clears all three; `_buildInfoSheet` (renamed) falls back to `_buildSpellSheet()` → `BlocProvider<SpellRecoveryCubit>.value(value: recovery, child: SpellDetailsSheet(spell:))`. Geometry and the outer dismiss `GestureDetector` unchanged.
- `lib/shared/components/spell_row.dart` deleted with `git rm` (only importer was `journal.dart`).

`git diff --stat 4fa45ad HEAD -- lib/screens/mainScreen/tabs/journal/journal.dart`: `1 file changed, 41 insertions(+), 73 deletions(-)` — hunks: imports (−2 spell_card/spell_row, +3 spell/section/recovery cubit), 2 fields, dismissed `setState`, removed `_buildSpellsSection` (65 lines), rename + `: _buildSpellSheet()`, new `_buildSpellSheet`, `_selectEquipment` / new `_selectSpell`, the `SpellsSection(...)` call and the `_buildInfoSheet` call. No reformatting.

## Task Commits

1. **Task 1 RED** — `6595b56` `test(spells): add failing tests for the spells section`
2. **Task 1 GREEN** — `4854296` `feat(spells): add the spells section with live countdown`
3. **Task 2 RED** — `88fdeae` `test(spells): add failing tests for the journal spell sheet`
4. **Task 2 GREEN** — `7d2c1ba` `feat(spells): host the spells section and sheet in the journal`
5. **Task 2 REFACTOR** — `d403302` `refactor(spells): remove the unused SpellRow`

## RED outputs

- Task 1: compilation failure — `Error when reading 'lib/screens/mainScreen/tabs/journal/sections/spells_section.dart': No such file or directory`, `Method not found: 'SpellsSection'`, `Method not found: 'SpellDetailsSheet'`.
- Task 2: 1 passed (the old section already showed «Magie imparate»), 4 failed with `Bad state: No element` at `WidgetController.ensureVisible` — the old Journal has no `spell-row-*` / `spell-slot-*` keys and no spell sheet.

## Test counts

- `test/screens/mainScreen/tabs/journal/sections`: 14/14
- `test/screens/mainScreen/tabs/journal`: 110/110 (incl. 5 new Journal tests)
- `test/screens/mainScreen/tabs/journal test/shared`: 245/245
- Plan-end quick run (`test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): 1894/1894
- `flutter analyze`: 53 issues, 0 errors (≤ 53 gate). Per-directory analyze of `tabs/journal` reports the 2 pre-existing `avoid_print` infos in `journal_cubit.dart` (out of scope, already in the 53).

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `SpellsCubit.toggle` signature**
- **Found during:** Task 1
- **Issue:** the plan sketch calls `toggle(character: …, spellId: …)`; the 08-06 cubit takes positional arguments.
- **Fix:** `toggle(character, spellId)` in the code; tests stub `toggle(any(), any())`.
- **Commit:** 6595b56 / 4854296

**2. [Rule 1 - Test bug] Shake measured one frame too early**
- **Found during:** Task 1 GREEN
- **Issue:** the broadcast stream of the mocked `SpellsCubit` delivers the new state after the first `pump`, so the `SpellResist` trigger changed one frame later and the translation at +75 ms was still 0.
- **Fix:** the shake test pumps one extra frame before the 75 ms pump (committed with GREEN).
- **Commit:** 4854296

**3. [Rule 1 - Test bug] `SpellDetailsSheet` test hung**
- **Found during:** Task 1 GREEN
- **Issue:** the RED version created the real `SpellRecoveryCubit` in the test body, provided it with `.value` and awaited `recovery.close()` in the body; the run never finished (process killed after minutes).
- **Fix:** the test provides the cubit with `BlocProvider(create:)` so the tree teardown closes it (research Pitfall 5); it also asserts the sheet receives a `SpellRecoveryCountdown`. Production `journal.dart` still uses `.value` (the section owns the cubit).
- **Commit:** 4854296

**4. [Acceptance check] `grep 'SpellRow'` matches `KnownSpellRow`**
- The verify command's `test -z "$(grep -rn 'SpellRow\|_buildSpellsSection' lib test)"` can never pass: `KnownSpellRow` (plan 08-09) contains the substring. Verified with a word-boundary grep instead: `grep -rnw "SpellRow\|_buildSpellsSection" lib test` prints nothing, `grep -rn "spell_row.dart" lib test` prints nothing.

**5. [Acceptance check] per-directory analyze exit code**
- `flutter analyze lib/screens/mainScreen/tabs/journal …` exits 1 on the 2 pre-existing `avoid_print` infos in `journal_cubit.dart` (untouched, already counted in the 53). No new issue.

---

**Total deviations:** 3 auto-fixed (1 blocking, 2 test bugs), 2 acceptance-check notes
**Impact on plan:** none on scope or behaviour.

## Issues Encountered

- A long-running `flutter test` was moved to the background by the tool timeout during the hang above; it was killed and later runs used a foreground watchdog loop. No process of this executor is left running.

## Known Stubs

None. Visuals are provisional by design (D-19).

## Threat Flags

None — no new network surface. T-8-31 (haptic from the cubit intent, ignored → none), T-8-32 (ticker closed on unmount, tested), T-8-33 (spell `!` reads removed from `journal.dart`, grep = 0), T-8-34 (no loader/dialog widgets, grep = 0) mitigated.

## Next Phase Readiness (plan 08-12)

- **Section wiring:** `journal.dart` calls `SpellsSection(cardSize: lootSize, onShowDetails: _selectSpell)` between `_buildInjuriesSection()` and `_buildArmorSection(...)`. The section reads `CharacterCubit`, `SpellsCubit` (from `AuthenticatedShell`) and `ServerClockService` (`RepositoryProvider` in the shell); it creates and closes its own `SpellRecoveryCubit`.
- **Sheet hosting:** one sliding sheet in the Journal `Stack` (`_buildInfoSheet`, `Positioned(top: _positionAnimation.value, right: 0)`); equipment selection wins, otherwise `_buildSpellSheet()` gives `BlocProvider<SpellRecoveryCubit>.value(value: <section cubit>, child: SpellDetailsSheet(spell:))`. A tap outside → `reverse()`; `isDismissed` clears equipment, spell and recovery.
- **`SpellRow` removal:** touched only `journal.dart` (imports) and the deleted file; nothing else imported it.
- **Gate test files:** `test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart`, `test/screens/mainScreen/tabs/journal/journal_spells_test.dart`, plus the existing `test/screens/mainScreen/tabs/journal` and `test/shared` suites. `journal_spells_test.dart` seeds the Journal SVGs (spell set, coins, the literal `healEffect` URL and the male mannequin) so `pumpAndSettle` never waits on a `CachedSvg` download.
- The fragment line (`status.spellStates { spell { id } usages recoveries }`) is still absent: today the section shows the D-03/D-04 fallback («in recupero») for a used active spell.

## Self-Check: PASSED

- FOUND: lib/screens/mainScreen/tabs/journal/sections/spells_section.dart, test/screens/mainScreen/tabs/journal/sections/spells_section_test.dart, test/screens/mainScreen/tabs/journal/journal_spells_test.dart
- GONE: lib/shared/components/spell_row.dart
- FOUND commits: 6595b56, 4854296, 88fdeae, 7d2c1ba, d403302

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
