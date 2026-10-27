---
phase: 08-spells-section-journal-tab
plan: 09
subsystem: ui
tags: [flutter, dart, widgets, spells, slots, bookmark, animation, optimistic-ui]

# Dependency graph
requires:
  - phase: 08-03
    provides: "`SpellCard(isMarked:, usages:)`, pending-ink theme tokens"
  - phase: 08-04
    provides: "`spellSummaryLine`, `noSpellSlotsLine`, `noKnownSpellsLine`, `SpellRecoveryStatus`"
  - phase: 08-05
    provides: "`Spellbook`, `SpellSlot`, `SpellbookEntry`"
provides:
  - "`SpellResist` horizontal shake + `SpellResistSignal` typedef + `resistTriggerFor`"
  - "`SpellSlotRow`: exactly `slots.length` bordered boxes (or the neutral zero-slot line), pending ink, keyed gestures"
  - "`KnownSpellRow`: card without counter, bookmark when active, description + compact line, pending ink, keyed gestures"
  - "`SpellbookContent`: slot row + rows in BE order from a `Spellbook` and a recovery map, callbacks only"
  - "`test/helpers/spells_harness.dart`: `pumpSpellsHarness(tester, child, {wrap})`, `seedSpellSvgs()`"
affects: [08-10, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Presentational section widgets: data in (`Spellbook`, status map, resist signal), callbacks out; the only local state is the shake controller"
    - "Shake driven by a changing int trigger (`didUpdateWidget`), never by the initial value"

key-files:
  created:
    - lib/screens/mainScreen/tabs/journal/components/spell_resist.dart
    - lib/screens/mainScreen/tabs/journal/components/spell_slot_row.dart
    - lib/screens/mainScreen/tabs/journal/components/known_spell_row.dart
    - lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart
    - test/helpers/spells_harness.dart
    - test/screens/mainScreen/tabs/journal/components/spell_resist_test.dart
    - test/screens/mainScreen/tabs/journal/components/spell_slot_row_test.dart
    - test/screens/mainScreen/tabs/journal/components/known_spell_row_test.dart
    - test/screens/mainScreen/tabs/journal/components/spellbook_content_test.dart
  modified: []

key-decisions:
  - "Harness takes `Widget Function(Widget body) wrap` instead of `List<SingleChildWidget> providers`: `SingleChildWidget` lives in `nested`, a transitive dependency (importing it would add a `depend_on_referenced_packages` issue); `wrap: (body) => MultiBlocProvider(providers: [...], child: body)` covers 08-11"
  - "The harness does not settle: callers choose `pump` (mid-animation asserts) or `pumpAndSettle`"
  - "Shake amplitudes after the first two steps are expressed as `amplitude * 2 / 3` (= 4 px) instead of a second magic number"

patterns-established:
  - "Gesture finders: `ValueKey('spell-row-<id>')`, `ValueKey('spell-slot-<id>')`, empty/any box `ValueKey('spell-slot-box-<index>')`; `KnownSpellRow` itself is keyed `ValueKey(<id>)` by `SpellbookContent`"

requirements-completed: []  # SPELL-01 / SPELL-02 / SPELL-07 rendering; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 12min
completed: 2026-10-27
---

# Phase 8 Plan 09: Slot Row, Known-Spell Rows, Shake and SpellbookContent Summary

**Pure section body for the Spells section: `SpellbookContent` renders a `Spellbook` as exactly `slotCount` bordered slot boxes (or «Nessuno slot per le magie: cresci di rango») followed by BE-ordered `KnownSpellRow`s (card without counter, red bookmark when active, description, «Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12»), with pending ink from the view model, a one-shot `SpellResist` shake keyed by a `(spellId, sequence)` signal, and every tap/long-press reported through callbacks**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-10-27T13:59:39Z
- **Completed:** 2026-10-27T14:11:00Z
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 9 (9 created)

## Accomplishments

- D-10/D-11/SPELL-07: the slot row shows `slots.length` boxes in a `Wrap` (T-8-25), filled boxes carry the slot card with its usages counter only (D-05); zero slots → neutral line, no boxes
- D-13/D-14/D-15: rows keep the BE order (no re-ordering code), card with `isMarked: entry.isActive` and no counter (fixes the `spell_row.dart:31` note of 08-03 for the new row; the old `SpellRow` stays until 08-11 replaces it), description + compact line
- D-16: `AnimatedOpacity(pendingInkOpacity / 1, pendingInkDuration)` on slot card and row card, driven only by `SpellSlot.isPending` / `SpellbookEntry.isPending` (T-8-24: no local optimistic flag)
- D-07/D-18: `SpellResist` runs one ±6 px, 300 ms horizontal shake per new non-null trigger; `SpellbookContent` routes one `SpellResistSignal` to both the row and the slot card of that spell
- D-12 content side: entries empty → «Non hai ancora imparato nessuna magia» under the slot row
- No `HapticFeedback`, no `context.read`, no cubit, no clock in any of the four widgets

## Task Commits

1. **Task 1 RED: failing tests for the spell slot row** - `861a8dd` (test)
2. **Task 1 GREEN: render the spell slot row** - `1a6861b` (feat)
3. **Task 2 RED: failing tests for the known spell rows** - `720e74c` (test)
4. **Task 2 GREEN: render known spells with bookmark and compact line** - `733e6f5` (feat)

**Plan metadata:** see `docs(phase-8): record plan 09 progress`

### RED failure outputs

- Task 1: `spell_resist_test.dart:3:8: Error: Error when reading 'lib/screens/mainScreen/tabs/journal/components/spell_resist.dart': No such file or directory`, `Error: Method not found: 'SpellResist'.`, `Error: Method not found: 'resistTriggerFor'.` (compile failure; the slot-row test failed on the same missing files)
- Task 2: `known_spell_row_test.dart:6:8: Error: Error when reading 'lib/screens/mainScreen/tabs/journal/components/known_spell_row.dart': No such file or directory`, `Error: Method not found: 'KnownSpellRow'.` (compile failure; `spellbook_content_test.dart` failed on the same import)

## Public API for plans 08-10 and 08-11

```dart
// lib/screens/mainScreen/tabs/journal/components/spell_resist.dart
typedef SpellResistSignal = ({String spellId, int sequence});
int? resistTriggerFor(SpellResistSignal? signal, String spellId); // sequence if same spell, else null
class SpellResist extends StatefulWidget {
  const SpellResist({Key? key, required int? trigger, required Widget child});
  static const Duration duration;  // 300 ms
  static const double amplitude;   // 6 px; TweenSequence 0→-6→6→-4→4→0, equal weights
  // shakes only when trigger changes to a NEW non-null value (didUpdateWidget);
  // the initial trigger, the same trigger again, or a change to null do nothing
}

// lib/screens/mainScreen/tabs/journal/components/spell_slot_row.dart
class SpellSlotRow extends StatelessWidget {
  const SpellSlotRow({Key? key, required List<SpellSlot> slots, required double cardSize,
    required ValueChanged<String> onTap,      // spell id of the tapped filled slot
    required ValueChanged<Spell> onLongPress, // spell of the long-pressed filled slot
    SpellResistSignal? resistSignal});
  // slots empty → Text(noSpellSlotsLine, bodyMedium)
  // else Wrap(spacing 10, runSpacing 10) of Container(key: 'spell-slot-box-$i', cardSize²,
  //   radius KlimmeckGuideTheme.radius, border deepNight 2); empty box: no child, no gesture
  // filled: GestureDetector(key: 'spell-slot-<id>', opaque) → SpellResist → AnimatedOpacity
  //   (pending ink) → SpellCard(usages: slot.usages, isMarked: null)
}

// lib/screens/mainScreen/tabs/journal/components/known_spell_row.dart
class KnownSpellRow extends StatelessWidget {
  const KnownSpellRow({Key? key, required SpellbookEntry entry, required SpellRecoveryStatus recovery,
    required double cardSize, required VoidCallback onTap, required VoidCallback onLongPress,
    int? resistTrigger});
  // GestureDetector(key: 'spell-row-<id>', opaque) → SpellResist(trigger: resistTrigger)
  //   → Padding(top 10) → Row[AnimatedOpacity(pending ink) → SpellCard(isMarked: entry.isActive),
  //   Expanded(Padding(left 20) → Column[description?, spellSummaryLine(...)])]
}

// lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart
class SpellbookContent extends StatelessWidget {
  const SpellbookContent({Key? key,
    required Spellbook spellbook,                          // Spellbook.of(character, pending: spellsState.pending)
    required Map<String, SpellRecoveryStatus> recoveries,  // missing id → SpellRecoveryFull()
    required double cardSize,                              // production: (screenWidth - 180) / 5
    required ValueChanged<String> onToggle,                // row tap AND slot tap → spell id
    required ValueChanged<Spell> onShowDetails,            // row long-press AND slot long-press → Spell
    SpellResistSignal? resistSignal});                     // shakes that spell's row + slot card
  // Padding(right 20) → Column(start)[SpellSlotRow, if entries empty Text(noKnownSpellsLine),
  //   for entry: KnownSpellRow(key: ValueKey(id), ...)]
  // Does NOT check spellbook.isVisible: the section (08-11) returns SizedBox.shrink() when false.
}

// test/helpers/spells_harness.dart
void seedSpellSvgs();  // emptyCardSheet, bookmarkRed, fireEnergy, attackUse, emptySheet, arrowDown
Future<void> pumpSpellsHarness(WidgetTester tester, Widget child,
  {Widget Function(Widget body) wrap}); // landscape phone, seeds SVGs, Scaffold → SingleChildScrollView
                                        // → SizedBox(width 600); does NOT settle
```

How 08-11 drives it:
- **Pending look:** nothing to do in the widgets — build the `Spellbook` with `pending: spellsCubit.state.pending`; `isPending` flows to slots and entries.
- **Spring-back / resist:** pass `resistSignal: (spellId: outcome.spellId, sequence: outcome.sequence)` from the latest `SpellsState.outcome` (blocked or failed); a new `sequence` shakes the row and (if present) the slot card once. Rebuilding with the same signal does not re-shake. For a blocked tap that has no outcome (none expected, the cubit emits one), a local sequence would work the same way.
- **Taps:** `onToggle(id)` → section handler: `final intent = spellsCubit.toggle(character, id)` → haptics per intent (D-08/D-07); `onShowDetails(spell)` → host opens `SpellInfoSheet`.
- **Recovery map:** `SpellRecoveryCubit` exposes `state.statusOf(id)`; either build the map from it in the section, or (finer rebuilds) keep `SpellbookContent` as is and pass a map built once per `SpellRecoveryState` change.

## Files Created/Modified

- `lib/screens/mainScreen/tabs/journal/components/spell_resist.dart` - shake widget, signal typedef, trigger helper
- `lib/screens/mainScreen/tabs/journal/components/spell_slot_row.dart` - slot row
- `lib/screens/mainScreen/tabs/journal/components/known_spell_row.dart` - known-spell row
- `lib/screens/mainScreen/tabs/journal/components/spellbook_content.dart` - section body
- `test/helpers/spells_harness.dart` - harness + SVG seeding
- Tests: resist 8, slot row 7, known row 7, content 7 cases (29)

## Verification

- Task 1 verify: 15 tests green; `flutter analyze` on the component dirs + harness → no issues; greps: typedef 1, `KlimmeckGuideTheme.radius` 1, `Radius.circular(15)` 0, `noSpellSlotsLine` 1, haptics/`context.read` 0; format check on the 5 files exit 0
- Task 2 verify: `flutter test test/screens/mainScreen/tabs/journal/components` **+29 all passed**; analyze → no issues; greps: class 1, `spellSummaryLine(` 1, `isMarked: entry.isActive` 1, `usages:` 1, `noKnownSpellsLine` 1, `sort|reversed` 0; format check on the 4 files exit 0
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1836, all passed** (was +1807 after 08-08; +29 new)
- Full `flutter analyze`: **53 issues, 0 errors** (no new issue)

## Decisions Made

See key-decisions in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Harness signature without `SingleChildWidget`**
- **Found during:** Task 1 RED
- **Issue:** the plan's `{List<SingleChildWidget> providers}` needs `package:nested` (or `provider`), neither a direct dependency; importing it would add an analyzer issue and break the ≤ 53 gate.
- **Fix:** `{Widget Function(Widget body) wrap}` (identity default); 08-11 passes `(body) => MultiBlocProvider(providers: [...], child: body)` or any `RepositoryProvider` nesting.
- **Files modified:** test/helpers/spells_harness.dart
- **Commit:** 861a8dd

Otherwise the plan was executed as written (an extra `resistTriggerFor` unit group and a content-level shake test that checks the signal reaches both row and slot card were added to the tests).

## Issues Encountered

None.

## Known Stubs

None. Visuals provisional by design (D-19).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-11: replace `_buildSpellsSection` in `journal.dart` with the extracted section wrapping `SpellbookContent` in the `Dropdown` (Pitfall 6: tap the «Magie imparate» header in its widget tests); delete or stop using `lib/shared/components/spell_row.dart` (the new row carries no counter, D-13).
- Widget tests mounting the real `SpellRecoveryCubit` with a countdown must let the tree teardown close it (08-07 note).

## Self-Check: PASSED
