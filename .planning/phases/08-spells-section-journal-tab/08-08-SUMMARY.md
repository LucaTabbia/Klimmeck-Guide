---
phase: 08-spells-section-journal-tab
plan: 08
subsystem: ui
tags: [flutter, dart, widgets, spells, sheet, bookmark, null-safety]

# Dependency graph
requires:
  - phase: 08-03
    provides: "`BookmarkRibbon`, `SpellCard(isMarked:, usages:)`, pending-ink theme tokens"
  - phase: 08-04
    provides: "`SpellRecoveryStatus` and the detail labels in `lib/utils/spell_lines.dart`"
provides:
  - "`SpellInfo(spell, usages, recovery)`: every D-09 field, each line optional, no `!` reads"
  - "`SpellInfoSheet`: parchment detail sheet (frame of `EquipmentInfoSheet`) whose red bookmark is the equip/disequip toggle"
  - "`BookmarkRibbon.opacity` (default 1) animated with `pendingInkDuration`"
affects: [08-09, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Pending look of a ribbon = `BookmarkRibbon(opacity: isPending ? pendingInkOpacity : 1)` (the ribbon stays the direct Stack child)"
    - "Presentational sheet: values in, one callback out; host decides open/dismiss and what the toggle does"

key-files:
  created:
    - lib/shared/components/popup/spell_info_sheet.dart
    - test/shared/components/spell_info_test.dart
    - test/shared/components/popup/spell_info_sheet_test.dart
  modified:
    - lib/shared/components/spell_info.dart
    - lib/shared/components/bookmark_ribbon.dart
    - test/shared/components/bookmark_ribbon_test.dart

key-decisions:
  - "Sheet ribbon uses `curve: Curves.linear` like `EquipmentInfoSheet` (same affordance, D-09); the plan snippet omitted the curve"
  - "`SpellInfo` icon rows put their label in a `Flexible` so long names/labels never overflow the sheet"
  - "`SpellInfo` is formatter-clean as hand-written (check exit 0), so no formatter run was needed on the former dirty file"

patterns-established:
  - "Spell detail copy only from `spell_lines.dart` helpers; current line = usages + recovery joined by `spellLineSeparator`"

requirements-completed: []  # SPELL-02 / SPELL-04 building blocks; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 5min
completed: 2026-10-27
---

# Phase 8 Plan 08: Spell Detail Info and Spell Info Sheet Summary

**`SpellInfo` rewritten null-safe with every D-09 field (name, description, element + power, use type, max usages, recovery time, learn requirements, current usages + next recovery) and a new parchment `SpellInfoSheet` whose shared `BookmarkRibbon` is the equip/disequip toggle, marked when active and dimmed to the pending ink while its operation runs**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-10-27T13:52:46Z
- **Completed:** 2026-10-27T13:57:17Z
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 6 (3 created, 3 modified)

## Accomplishments

- `SpellInfo` no longer crashes on partial catalog data (T-8-22): the former `spell.energyDamage!.type!`, `spell.name!`, `spell.useType!` reads are gone; each line is rendered only when its helper returns a value
- `SpellInfoSheet` mirrors `EquipmentInfoSheet` (same `svgWidth`/`svgHeight`, `emptySheet` parchment, padded `LayoutBuilder`) with `SpellCard` + a scrollable `SpellInfo`; the ribbon only calls `onToggle` (T-8-23: the decision stays in `SpellsCubit`, wired in 08-11)
- `BookmarkRibbon` gained `opacity` (wraps the rotated SVG in `AnimatedOpacity` with `pendingInkDuration`); the 08-03 ribbon/equipment tests stay green

## Task Commits

1. **Task 1 RED: failing tests for the spell detail info** - `adf1689` (test)
2. **Task 1 GREEN: show every spell detail in the info block** - `bf8c8b9` (feat)
3. **Task 2 RED: failing tests for the spell info sheet** - `0989304` (test)
4. **Task 2 GREEN: add the spell info sheet with the bookmark toggle** - `d48329c` (feat)

**Plan metadata:** see `docs(phase-8): record plan 08 progress`

### RED failure outputs

- Task 1: `test/shared/components/spell_info_test.dart:39:44: Error: No named parameter with the name 'usages'.` (compile failure, as expected)
- Task 2: `spell_info_sheet_test.dart:8:8: Error: Error when reading 'lib/shared/components/popup/spell_info_sheet.dart': No such file or directory`, `Error: Method not found: 'SpellInfoSheet'.`; `bookmark_ribbon_test.dart:44:21: Error: No named parameter with the name 'opacity'.`, `:159:21: Error: The getter 'opacity' isn't defined for the type 'BookmarkRibbon'.`

## Public API for plans 08-09 and 08-11

```dart
// lib/shared/components/spell_info.dart
class SpellInfo extends StatelessWidget {
  const SpellInfo({Key? key, required Spell spell, required int? usages,
    required SpellRecoveryStatus recovery});
  // Column(start): [energy icon 50x50 + name (AutoSizeText bodyLarge w800)]
  //   [use icon + 'Uso: …'] [description] ['Danno: …'] ['Usi massimi: …']
  //   ['Recupero: …'] ['Per impararla: …'] [current line]
  // current line = [spellUsagesLabel(usages, maxUsages), spellRecoveryLabel(recovery)]
  //   .whereType<String>().join(' · ')  → 'Usi: 1/3 · prossimo tra 12 min' / 'Usi: 3'
  // every line omitted when its data is null; needs a bounded width (Flexible labels)
}

// lib/shared/components/popup/spell_info_sheet.dart
class SpellInfoSheet extends StatelessWidget {
  const SpellInfoSheet({Key? key,
    required Spell spell,
    required int? usages,                 // SpellbookEntry.usages
    required SpellRecoveryStatus recovery, // SpellRecoveryState.statusOf(spell.id)
    required bool isActive,                // SpellbookEntry.isActive (optimistic)
    required bool isPending,               // SpellbookEntry.isPending
    VoidCallback? onToggle});              // null → ribbon inert (no GestureDetector)
  // Returns a Stack sized like EquipmentInfoSheet: width = h*1.3*(315/375), height = h*1.3
  // (h = MediaQuery height). Last child: BookmarkRibbon(isMarked: isActive,
  // length: h/2.5, peek: h/4, left: 20, curve: Curves.linear,
  // opacity: isPending ? pendingInkOpacity : 1, onTap: onToggle).
  // SpellCard inside has no counter and no bookmark (usages/isMarked null).
}

// lib/shared/components/bookmark_ribbon.dart (added)
BookmarkRibbon({..., double opacity = 1, ...}); // AnimatedOpacity(pendingInkDuration) around the rotated SVG
```

How it is opened/dismissed: the sheet has no open/close logic of its own. Plan 08-11 hosts it in the Journal page `Stack` exactly like `EquipmentInfoSheet` (research Pattern 7): same `AnimationController`, `Positioned(top: _positionAnimation.value, right: 0)`, outer tap → `reverse()`, clear the selection on `isDismissed`. The host must rebuild the sheet from `SpellsCubit` + `CharacterCubit` (`Spellbook.of(character, pending: state.pending).entryFor(id)`) and `SpellRecoveryCubit` so `isActive`/`isPending`/`usages`/`recovery` stay live; `onToggle` → the same shared toggle handler as the row (`spellsCubit.toggle(character, spell.id)` + haptics/resist in the widget). If the sheet ends up on a new route, pass `SpellRecoveryCubit` with `BlocProvider.value`.

## Files Created/Modified

- `lib/shared/components/spell_info.dart` - rewritten: `usages`/`recovery`, every D-09 line, null-safe
- `lib/shared/components/popup/spell_info_sheet.dart` - new parchment detail sheet
- `lib/shared/components/bookmark_ribbon.dart` - `opacity` parameter
- `test/shared/components/spell_info_test.dart` - 3 cases
- `test/shared/components/popup/spell_info_sheet_test.dart` - 7 cases
- `test/shared/components/bookmark_ribbon_test.dart` - +2 cases (opacity)

## Verification

- Task 1 verify: 3 tests green; analyze on the two files → no issues; greps: `final SpellRecoveryStatus recovery;` 1, `'!\.'` 0, `'!,'` 0 (single quotes), `spellLearnLabel(` 1; test format check exit 0
- Task 2 verify: `flutter test test/shared/components/popup test/shared/components/bookmark_ribbon_test.dart` (plus spell_info) **+53 all passed**; `flutter analyze lib/shared/components test/shared/components` → no issues; greps: class 1, `BookmarkRibbon(` 1, `bookmarkRed` 0, `pendingInkOpacity` 1, chrome 0, `final double opacity;` 1; format check on the 4 files exit 0
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1807, all passed** (was +1795 after 08-07; +12 new)
- Full `flutter analyze`: **53 issues, 0 errors** (no new issue)

## Decisions Made

See key-decisions in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `SpellInfo` icon row overflowed inside the sheet**
- **Found during:** Task 2 GREEN
- **Issue:** in the sheet (landscape phone, ~306 px content width) the name row of `SpellInfo` overflowed by 38 px (`RenderFlex overflowed`, `spell_info.dart:66`).
- **Fix:** the label of `_iconRow` is wrapped in `Flexible`; the sheet tests cover it (an overflow fails them).
- **Files modified:** lib/shared/components/spell_info.dart
- **Commit:** d48329c (in the Task 2 GREEN commit)

**2. Sheet ribbon curve**
- The plan's snippet did not set `curve`; `Curves.linear` was set to match the equipment sheet's toggle (same affordance, D-09, as the 08-03 summary recommends). No test asserts it.

**3. Formatting of `spell_info.dart`**
- The file was DIRTY before; after the hand rewrite `dart format --output=none --set-exit-if-changed` exits 0, so the formatter was never run on it (nothing to record beyond that).

---

**Total deviations:** 1 auto-fix, 2 notes
**Impact on plan:** none on scope.

## Issues Encountered

None.

## Known Stubs

None. Visuals and copy are provisional by design (D-19).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-09: rows/slot cards can share the pending look through `BookmarkRibbon(opacity:)` or `pendingInkOpacity` directly; the row summary line still comes from `spellSummaryLine`.
- 08-11: host `SpellInfoSheet` in the Journal `Stack` (Pattern 7) and feed it live values as described above; tests that mount the real `SpellRecoveryCubit` with a countdown must let the tree close it (Pitfall 5).

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
