---
phase: 08-spells-section-journal-tab
plan: 05
subsystem: models
tags: [flutter, dart, equatable, spells, optimistic-ui, view-model]

# Dependency graph
requires:
  - phase: 08-01
    provides: "`SpellState`, `CharacterStatus.spellStates` (nullable), spell fixtures (`spellJson`, `activeSpellJson`, `spellStateJson`, `spellbookCharacter`)"
provides:
  - "Flutter-free `Spellbook.of(character, pending:)` in `lib/models/spell/spellbook.dart`: visibility, slots, list entries, optimistic active order and toggle intents"
  - "`SpellOperation { equip, unequip }` and `SpellToggleIntent` enums used by `SpellsCubit` (08-06)"
affects: [08-06, 08-07, 08-09, 08-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One pure join of the character + pending overlay feeds every render and every tap decision (research Pattern 2): no widget computes spell state"
    - "Optimistic active order = server actives (null spells skipped, deduplicated) − pending unequips + pending equips in insertion order; equals the BE's `$push`/`$pull` order"

key-files:
  created:
    - lib/models/spell/spellbook.dart
    - test/models/spell/spellbook_test.dart
  modified: []

key-decisions:
  - "Slot spell objects come from `ActiveSpell.spell` for server actives and from `status.spells` for pending equips (unknown pending ids are dropped)"
  - "Usages always pass the server `ActiveSpell` to the fallback, also for an entry with a pending unequip (its usages do not jump to `maxUsages` while the unequip is in flight)"
  - "Duplicate server active ids keep the first occurrence (defensive, `putIfAbsent`)"
  - "`intentFor` was added in task 2 only (task 1 GREEN shipped without it instead of an `UnimplementedError` stub); the `SpellToggleIntent` enum was already in task 1 to satisfy its acceptance grep"

patterns-established:
  - "Spell section view model: `Spellbook` (immutable, Equatable, `List.unmodifiable` / `Map.unmodifiable`)"

requirements-completed: []  # SPELL-01/03/04/07 building blocks; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 10min
completed: 2026-10-27
---

# Phase 8 Plan 05: Pure Spellbook View Summary

**`Spellbook.of(character, pending:)` joins `status.spells`, `status.spellStates` and `assets.activeSpells` into visibility, `maxActiveSpells` slots, BE-ordered entries with the usages fallback, and the optimistic overlay on which every toggle intent (equip, unequip, blocked slots full/no slots, ignored pending/unknown) is decided**

## Performance

- **Duration:** ~10 min
- **Completed:** 2026-10-27
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 2 (2 created)

## Accomplishments

- Section visibility (D-12), slot row of exactly `maxActiveSpells` boxes with bounds check and null-spell skip (D-10 amended F6, T-8-12, SPELL-07 / T-8-14), entries in `status.spells` order with active spells marked in place (D-14, D-15)
- Usages fallback table (D-02/D-03): `state.usages` → `ActiveSpell.usages` → catalog `maxUsages`; `recoveries` from the state or empty
- Optimistic overlay (D-16) and toggle intents on the optimistic count (D-07 amended F5, D-11; T-8-13)

## Task Commits

1. **Task 1 RED: failing spellbook join tests** - `6d66860` (test)
2. **Task 1 GREEN: derive the spellbook view from the character** - `e8cef9c` (feat)
3. **Task 2 RED: failing overlay and intent tests** - `d789ed3` (test)
4. **Task 2 GREEN: compute toggle intents on the optimistic view** - `233c505` (feat)

**Plan metadata:** see `docs(phase-8): record plan 05 progress`

### RED failure outputs

- Task 1: `test/models/spell/spellbook_test.dart:4:8: Error: Error when reading 'lib/models/spell/spellbook.dart': No such file or directory`, `Error: Type 'Spellbook' not found.` (compile failure, as expected)
- Task 2: `test/models/spell/spellbook_test.dart:282:24: Error: The method 'intentFor' isn't defined for the type 'Spellbook'.` (compile failure, as expected; the overlay cases would also have failed since task 1 ignored `pending`)

## Public API for plans 08-06, 08-07, 08-09, 08-11

`package:klimmeck_guide/models/spell/spellbook.dart` (Flutter-free, imports `dart:math`, equatable and models):

```dart
enum SpellOperation { equip, unequip }
enum SpellToggleIntent { equip, unequip, blockedSlotsFull, blockedNoSlots, ignoredPending, ignoredUnknown }

class SpellSlot extends Equatable {
  const SpellSlot.empty();                         // spell/usages null, isPending false
  const SpellSlot.filled({required Spell spell, required int? usages, required bool isPending});
  final Spell? spell; final int? usages; final bool isPending;
  bool get isEmpty;                                // spell == null
}

class SpellbookEntry extends Equatable {
  const SpellbookEntry({required Spell spell, required int? usages, required bool isActive, required bool isPending, required List<DateTime> recoveries});
}

class Spellbook extends Equatable {
  factory Spellbook.of(Character? character, {Map<String, SpellOperation> pending = const {}});
  final bool isVisible;                            // spells.isNotEmpty || slotCount > 0
  final int slotCount;                             // max(0, maxActiveSpells ?? 0)
  final List<SpellSlot> slots;                     // length == slotCount (empty when 0)
  final List<SpellbookEntry> entries;              // status.spells order
  final List<String> activeSpellIds;               // optimistic order (may exceed slotCount with legacy data)
  final Map<String, SpellOperation> pending;       // unmodifiable copy
  SpellbookEntry? entryFor(String spellId);
  SpellToggleIntent intentFor(String spellId);
}
```

Intent order: pending → `ignoredPending`; optimistically active → `unequip` (also with 0 slots); not in `status.spells` → `ignoredUnknown`; `slotCount == 0` → `blockedNoSlots`; `activeSpellIds.length >= slotCount` → `blockedSlotsFull`; else `equip`.

Overlay rules: a pending `equip` of an id not in `status.spells` is ignored; a pending `equip` of a spell already active server-side is not duplicated; an entry with a pending `unequip` has `isActive false, isPending true`; a pending-equip slot/entry has `isPending true` and usages `state?.usages ?? maxUsages`.

## Files Created/Modified

- `lib/models/spell/spellbook.dart` - enums, `SpellSlot`, `SpellbookEntry`, `Spellbook`
- `test/models/spell/spellbook_test.dart` - 30 cases (`join` 14, `overlay` 7, `intentFor` 9)

## Verification

- Task 1 / task 2 verify (`flutter test test/models/spell/spellbook_test.dart && flutter analyze lib/models/spell test/models/spell`): 14 then 30 tests green, no issues; all acceptance greps = expected; format check exit 0
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1758, all passed** (+30 vs 08-04)
- Full `flutter analyze`: **53 issues, 0 errors** (no new issue)

## Decisions Made

See key-decisions above.

## Deviations from Plan

None - plan executed exactly as written. (Task 1 GREEN omitted `intentFor` rather than stubbing it, as the plan allowed; the optimistic computation is factored into the private `_optimisticActiveById` / `_serverActiveById` helpers instead of inline code, same behaviour.)

## Issues Encountered

None.

## Known Stubs

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-06 (`SpellsCubit`): keep `Map<String, SpellOperation>` pending (insertion-ordered), build `Spellbook.of(character, pending: pending)`, switch on `intentFor(id)`; only `equip`/`unequip` reach `SpellsRepository`; `blockedSlotsFull`/`blockedNoSlots` drive the D-07/D-11 banners; `ignored*` do nothing. Clear an id from `pending` when `characterUpdated` reflects it or on rollback.
- 08-07 (`SpellRecoveryCubit`): per entry, `SpellRecoveryInput(spellId: entry.spell.id, usages: entry.usages ?? maxUsages, maxUsages: entry.spell.maxUsages, recoveries: entry.recoveries)`.
- 08-09 / 08-11: render `slots` (only when `slotCount > 0`, else `noSpellSlotsLine`) and `entries` (empty → `noKnownSpellsLine`); hide the section when `!isVisible`; pending look from `isPending`.

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
