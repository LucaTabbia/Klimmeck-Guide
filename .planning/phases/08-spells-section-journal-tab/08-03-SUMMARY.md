---
phase: 08-spells-section-journal-tab
plan: 03
subsystem: ui
tags: [flutter, dart, widgets, spells, equipment, bookmark, refactor, theme]

# Dependency graph
requires:
  - phase: 08-01
    provides: "spell fixtures (`spellJson`) used by the SpellCard tests"
provides:
  - "`BookmarkRibbon` (AnimatedPositioned for a Stack) and `CardBookmark` (card-sized wrapper) in `lib/shared/components/bookmark_ribbon.dart`: the only red-bookmark implementation"
  - "`SpellCard(isMarked:)` with null-safe reads of `useType`, `energyDamage.type`, `energyDamage.power`; unused `onTap` removed"
  - "`UsagesPencilCounter(value:)` shared by `SpellCard` and `EquipmentItemCard`"
  - "`KlimmeckGuideTheme.pendingInkOpacity` (0.5) and `pendingInkDuration` (200 ms)"
  - "`spell_info.dart:52` analyzer warning fixed (baseline 54 → 53)"
affects: [08-08, 08-09, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A StatelessWidget that returns `AnimatedPositioned` is placed directly in a `Stack` (shared ribbon)"
    - "Widget geometry asserted through the widget's own fields plus the rendered offset (no goldens)"

key-files:
  created:
    - lib/shared/components/bookmark_ribbon.dart
    - lib/shared/components/usages_pencil_counter.dart
    - test/shared/components/bookmark_ribbon_test.dart
    - test/shared/components/usages_pencil_counter_test.dart
    - test/shared/components/cards/equipment_item_card_test.dart
    - test/shared/components/cards/spell_card_test.dart
    - test/shared/components/popup/equipment_info_sheet_test.dart
  modified:
    - lib/shared/components/cards/equipment_item_card.dart
    - lib/shared/components/popup/equipment_info_sheet.dart
    - lib/shared/components/cards/spell_card.dart
    - lib/shared/components/spell_info.dart
    - lib/theme/kg_theme.dart

key-decisions:
  - "Ribbon shared as `BookmarkRibbon` + `CardBookmark` (not an `isSelected` on SpellCard): one implementation for card, sheet and spells (D-14 zero duplication)"
  - "`UsagesPencilCounter` extracted without the `Positioned`: the two cards keep their own anchor (equipment `top: 5`, spell `bottom: 0`)"
  - "Pending-ink tokens placed right after `radius` in `KlimmeckGuideTheme`"

patterns-established:
  - "Red bookmark anywhere = `BookmarkRibbon` (free-form, e.g. a sheet toggle with `onTap`) or `CardBookmark(isMarked, cardSize)` as the last child of a card Stack"

requirements-completed: []  # SPELL-01 / SPELL-05 building blocks; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 25min
completed: 2026-10-27
---

# Phase 8 Plan 03: Shared Bookmark Ribbon, Pencil Counter and SpellCard Bookmark Summary

**One `BookmarkRibbon`/`CardBookmark` replacing both equipment ribbon copies, a shared `UsagesPencilCounter`, `SpellCard(isMarked:)` with null-safe catalog reads, pending-ink theme tokens and the `spell_info.dart` warning fix (analyzer 54 → 53)**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-10-27
- **Tasks:** 3 (6 TDD commits: 3 RED, 2 GREEN feat, 1 GREEN refactor)
- **Files modified:** 12 (7 created, 5 modified)

## Accomplishments

- `bookmarkRed` is referenced in `lib` only by `bookmark_ribbon.dart` (plus the asset registry and the unrelated library-page book colour)
- `EquipmentItemCard` and `EquipmentInfoSheet` use the shared ribbon with today's geometry: card `length = width = size/2.5`, `peek 20`, `left 5`, `easeInOut`; sheet `length = h/2.5`, `peek = h/4`, `left 20`, `Curves.linear`, natural SVG width, tap → `onEquip` (T-8-09 covered by widget tests)
- `SpellCard` no longer has `!.` assertions: icons omitted when `useType`/`energyDamage.type` are null, power shown only when non-null and non-zero (T-8-08)
- The pencil counter exists once; the local optimistic `_isSelected` + `Future.delayed` of `EquipmentItemCard` is untouched (out of scope)

## Task Commits

1. **Task 1 RED: failing tests for the shared bookmark ribbon** - `3edb98b` (test)
2. **Task 1 GREEN: share the red bookmark ribbon** - `eab6af0` (feat)
3. **Task 2 RED: failing tests for the spell card bookmark** - `308d578` (test)
4. **Task 2 GREEN: mark active spell cards with the bookmark** - `6b678fa` (feat)
5. **Task 3 RED: failing tests for the shared pencil counter** - `5b11e24` (test)
6. **Task 3 REFACTOR: share the pencil usages counter** - `b272c90` (refactor)

**Plan metadata:** see `docs(phase-8): record plan 03 progress`

### RED failure outputs

- Task 1: `test/shared/components/bookmark_ribbon_test.dart:4:8: Error: Error when reading 'lib/shared/components/bookmark_ribbon.dart': No such file or directory`, `Error: Method not found: 'BookmarkRibbon'.` (compile failure; the card and sheet tests failed for the same import)
- Task 2: `spell_card_test.dart:28:13: Error: No named parameter with the name 'isMarked'.`, `Error: Member not found: 'pendingInkOpacity'.`, `Error: Member not found: 'pendingInkDuration'.`
- Task 3: `usages_pencil_counter_test.dart:4:8: Error: Error when reading 'lib/shared/components/usages_pencil_counter.dart': No such file or directory`, `Error: Method not found: 'UsagesPencilCounter'.`

## Public API for later plans (08-08, 08-09, 08-11)

```dart
// lib/shared/components/bookmark_ribbon.dart
class BookmarkRibbon extends StatelessWidget {        // returns AnimatedPositioned: direct child of a Stack
  const BookmarkRibbon({Key? key, required bool isMarked, required double length,
    required double peek, double? width, double left = 5,
    Curve curve = Curves.easeInOut, VoidCallback? onTap});
  static const Duration slideDuration;                 // 300 ms
  // top: isMarked ? 0 : -length + peek
  // width == null → CachedSvg(height: length), natural aspect ratio
  // width != null → SizedBox(height: length, width: width, child: CachedSvg)
  // onTap == null → no GestureDetector
}
class CardBookmark extends StatelessWidget {           // put it as the LAST child of a square card Stack
  const CardBookmark({Key? key, required bool isMarked, required double cardSize});
  // Padding(top: cardSize/25) + SizedBox(cardSize - cardSize/25, cardSize) + Stack[
  //   BookmarkRibbon(length: cardSize/2.5, width: cardSize/2.5, peek: 20)]
}

// lib/shared/components/usages_pencil_counter.dart
class UsagesPencilCounter extends StatelessWidget {    // 25x50 box; caller positions it
  const UsagesPencilCounter({Key? key, required int value});
  // AnimatedSwitcher 400 ms, AnimatedPencilText keyed ValueKey<int>(value)
}

// lib/shared/components/cards/spell_card.dart
const SpellCard({Key? key, required Spell spell, required double size,
  int? usages,      // non-null → UsagesPencilCounter at Positioned(right: 7, bottom: 0)
  bool? isMarked}); // null → no bookmark; true/false → CardBookmark on top
// `onTap` REMOVED (no caller used it; gestures live in the section rows, D-06)

// lib/theme/kg_theme.dart
KlimmeckGuideTheme.pendingInkOpacity   // 0.5
KlimmeckGuideTheme.pendingInkDuration  // Duration(milliseconds: 200)
```

Notes:
- 08-09: `spell_row.dart:31` still passes `usages:` to the row `SpellCard`; D-13 says the row card has no counter (only the slot card) — the row rework belongs to 08-09, untouched here.
- 08-08: `spell_info.dart` changed only at line 52 (`'${spell.energyDamage?.power ?? ''}'`); its `spell.useType!` read on line 46 is still there for 08-08 to make null-safe.
- A spell sheet toggle can reuse `BookmarkRibbon(onTap: …, left: 20, curve: Curves.linear, length: h/2.5, peek: h/4)` exactly like `EquipmentInfoSheet`.

## Files Created/Modified

- `lib/shared/components/bookmark_ribbon.dart` - shared ribbon + card wrapper
- `lib/shared/components/usages_pencil_counter.dart` - shared pencil counter
- `lib/shared/components/cards/equipment_item_card.dart` - `CardBookmark` + `UsagesPencilCounter` (hand edits, format-dirty file; `_bookmarkUrl` removed)
- `lib/shared/components/popup/equipment_info_sheet.dart` - `BookmarkRibbon` toggle (hand edit, format-dirty file)
- `lib/shared/components/cards/spell_card.dart` - `isMarked`, null-safe reads, `onTap` removed, shared counter (hand edits, format-dirty file)
- `lib/shared/components/spell_info.dart` - one-line warning fix (hand edit)
- `lib/theme/kg_theme.dart` - pending-ink tokens (clean file, formatted)
- Tests: ribbon 8, equipment card 4, equipment sheet 4, spell card 9, counter 2 cases

## Verification

- Task 1 verify: 47 tests green; analyze on the path set reported only the `spell_info.dart:52` warning still due in Task 2 (exit 1 for that reason only)
- Task 2 verify: cards tests green; `flutter analyze lib/shared/components lib/theme test/shared/components` → no issues; full analyzer **53 issues, 0 errors**
- Task 3 verify: `flutter test test/shared/components` **+121 all passed**; analyze on the path set → no issues
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1692, all passed** (was +1665 after 08-02; +27 new)
- All acceptance greps and format checks pass (the `!.` count was run with single quotes: `grep -c '!\.'` → 0)

## Decisions Made

- The pencil counter's two copies were identical except for the value (verified block by block); the `Positioned` anchors differ (equipment `top: 5`, spell `bottom: 0`, not `bottom: 0` for both as the plan's interface note said), so the anchor stays in each card and the shared widget is just the 25x50 box — no extra constructor parameter needed.
- `UsagesPencilCounter` splits the transition and layout builders into private static methods (same values: 400 ms, easeOutCubic/easeInCubic, Interval(0.3, 1.0, easeOut), scale 1.2 → 1.0).

## Deviations from Plan

### Verify-command notes (no code change)

**1. Task 1 `<automated>` analyze step exited 1 because of the `spell_info.dart:52` warning**
- **Found during:** Task 1 verify
- **Issue:** the plan fixes that baseline warning in Task 2, but Task 1's analyze path (`lib/shared/components`) already includes it.
- **Fix:** none needed in Task 1; fixed by Task 2 as planned, after which the same command reports no issues.

**2. Interface note on the counter anchor**
- **Issue:** the plan's `<interfaces>` says both counters sit at `Positioned(right: 7, bottom: 0)`; the equipment card actually uses `top: 5`.
- **Fix:** kept each card's own `Positioned` (as Task 3's action prescribes); behaviour unchanged.

---

**Total deviations:** 2 (verify/interface notes, no scope change)
**Impact on plan:** none.

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-08 / 08-09 / 08-11 can compose `CardBookmark`, `BookmarkRibbon`, `UsagesPencilCounter`, `SpellCard(isMarked:, usages:)` and the pending-ink tokens.
- Analyzer ceiling from now on: **53**.

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
