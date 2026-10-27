---
phase: 08-spells-section-journal-tab
plan: 04
subsystem: models
tags: [flutter, dart, equatable, spells, recovery, countdown, copy]

# Dependency graph
requires:
  - phase: 08-01
    provides: "`formatGameDuration` (lib/utils/game_duration_format.dart), spell fixtures (`spellJson`, `spellFixtureNow`)"
provides:
  - "Flutter-free `SpellRecoveryInput`, sealed `SpellRecoveryStatus` (Full/Countdown/Arriving/Unknown) and `spellRecoveryStatusOf(input, serverNow)` in `lib/models/spell/spell_recovery_status.dart`"
  - "Every Italian string of the Spells section in `lib/utils/spell_lines.dart`: `spellSummaryLine`, per-item label helpers, empty-state constants"
affects: [08-07, 08-08, 08-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Status quantized on what the label shows (whole minutes, 0 = under a minute): equal labels are equal Equatable states, so a ticking cubit only emits when the text changes"
    - "Server now always a parameter: no `DateTime.now()` in lib/models/spell or lib/utils/spell_lines.dart"

key-files:
  created:
    - lib/models/spell/spell_recovery_status.dart
    - lib/utils/spell_lines.dart
    - test/models/spell/spell_recovery_status_test.dart
    - test/utils/spell_lines_test.dart
  modified: []

key-decisions:
  - "Sub-minute wording: «meno di 1 min» (`remainingMinutes: 0`); ≥ 1 min uses `formatGameDuration` (ceil)"
  - "Sub-minute branch extracted into the private `_wholeMinutesShown` helper (early-return style) instead of the plan's inline second `if`; behaviour identical"
  - "`spellUsagesLabel` falls back to `maxUsages` when `usages` is null (pre-9.1 BE / inactive spell without state)"

patterns-established:
  - "Spell copy lives only in `lib/utils/spell_lines.dart` (provisional, D-19)"

requirements-completed: []  # SPELL-02 / SPELL-05 building blocks; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 8min
completed: 2026-10-27
---

# Phase 8 Plan 04: Spell Recovery Status and Italian Spell Lines Summary

**Pure `spellRecoveryStatusOf(input, serverNow)` deriving Full/Countdown/Arriving/Unknown from `recoveries[0] − serverNow` only, quantized to the label's minutes, plus every Italian string of the Spells section (summary line «Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12», detail labels, empty-state copies) in one unit-tested util**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-10-27T13:18:00Z
- **Completed:** 2026-10-27T13:26:00Z
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 4 (4 created)

## Accomplishments

- Recovery derivation with no clock dependency and no recovery math beyond the earliest instant minus the injected server now (T-8-10 mitigated: past instant → `Arriving`, usages never restored locally)
- Countdown quantized to whole minutes rounded up, `0` = under a minute; two nows 10 s apart inside the same ceil minute give equal statuses
- All section strings defined once and tested: summary line with all variants, detail-sheet labels, empty-state constants (T-8-11 mitigated: formatted durations, no raw ms, no ids)

## Task Commits

1. **Task 1 RED: failing recovery status tests** - `dd8fa8b` (test)
2. **Task 1 GREEN: derive the spell recovery status from server time** - `d5300de` (feat)
3. **Task 2 RED: failing spell lines tests** - `b1f67e4` (test)
4. **Task 2 GREEN: write the spell summary and detail lines** - `5905342` (feat)

**Plan metadata:** see `docs(phase-8): record plan 04 progress`

### RED failure outputs

- Task 1: `test/models/spell/spell_recovery_status_test.dart:149:15: Error: Couldn't find constructor 'SpellRecoveryInput'.` (plus the missing-file import error; compile failure, as expected)
- Task 2: `test/utils/spell_lines_test.dart:5:8: Error: Error when reading 'lib/utils/spell_lines.dart': No such file or directory`, `Error: Method not found: 'spellSummaryLine'.`, `Error: Method not found: 'spellUseTypeLabel'.` (compile failure, as expected)

## Public API for plans 08-07, 08-08, 08-09

`package:klimmeck_guide/models/spell/spell_recovery_status.dart` (Flutter-free, imports only equatable):

```dart
class SpellRecoveryInput extends Equatable {
  const SpellRecoveryInput({required String spellId, required int usages, required int? maxUsages, required List<DateTime> recoveries});
  // props: [spellId, usages, maxUsages, recoveries]
}
sealed class SpellRecoveryStatus extends Equatable {}
final class SpellRecoveryFull extends SpellRecoveryStatus { const SpellRecoveryFull(); }
final class SpellRecoveryCountdown extends SpellRecoveryStatus { const SpellRecoveryCountdown({required int remainingMinutes}); } // 0 = under a minute
final class SpellRecoveryArriving extends SpellRecoveryStatus { const SpellRecoveryArriving(); }
final class SpellRecoveryUnknown extends SpellRecoveryStatus { const SpellRecoveryUnknown(); }
SpellRecoveryStatus spellRecoveryStatusOf(SpellRecoveryInput input, DateTime serverNow);
```

Rules: `maxUsages == null || usages >= maxUsages` → Full (usages win over leftover instants); empty `recoveries` → Unknown; earliest instant (list need not be sorted) `<= serverNow` → Arriving; `< 1 min` → Countdown(0); else Countdown(ceil minutes).

`package:klimmeck_guide/utils/spell_lines.dart` (pure, imports models + `formatGameDuration`):

| Symbol | Output |
|--------|--------|
| `const spellLineSeparator` | `' · '` |
| `const noSpellSlotsLine` | `'Nessuno slot per le magie: cresci di rango'` (D-11) |
| `const noKnownSpellsLine` | `'Non hai ancora imparato nessuna magia'` (D-12) |
| `String spellSummaryLine({required Spell spell, required int? usages, required SpellRecoveryStatus recovery})` | `'Usi: 3 · Recupero: 2 h · Danno: Fuoco 12'` at Full; `'Usi: 1/3 · prossimo tra 12 min · Danno: Fuoco 12'`, `'… in arrivo… …'`, `'… in recupero …'` below max; null items dropped |
| `String? spellUsagesLabel({required int? usages, required int? maxUsages})` | `'Usi: 3'` / `'Usi: 1/3'`; `usages` null → max; both null → null |
| `String formatRecoveryCountdown(int remainingMinutes)` | `'meno di 1 min'` for ≤ 0, else `formatGameDuration` |
| `String? spellRecoveryLabel(SpellRecoveryStatus)` | Full → null; `'prossimo tra X'`; `'in arrivo…'`; `'in recupero'` |
| `String? spellRecoveryTimeLabel(Spell)` | `'Recupero: 2 h'` (ms), null without `recoveryTime` |
| `String? spellDamageLabel(EnergyDamage?)` | `'Danno: Fuoco 12'`; power 0/null → `'Danno: Fuoco'`; no type → null |
| `String? spellUseTypeLabel(UseType?)` | `'Uso: Attacco'` / null |
| `String? spellMaxUsagesLabel(int?)` | `'Usi massimi: 3'` / null |
| `String? spellLearnLabel(Spell)` | `'Per impararla: 100 XP · 1 h di studio'`, XP-only, time-only, or null (`requiredLearnTime` read as ms, assumption A3) |

## Files Created/Modified

- `lib/models/spell/spell_recovery_status.dart` - recovery input, sealed status, derivation
- `lib/utils/spell_lines.dart` - all Italian spell strings
- `test/models/spell/spell_recovery_status_test.dart` - 15 cases
- `test/utils/spell_lines_test.dart` - 21 cases

## Verification

- Task 1 verify: 15 tests green; `flutter analyze lib/models/spell test/models/spell`: no issues; acceptance greps OK; format check exit 0
- Task 2 verify: 21 tests green; `flutter analyze lib/utils test/utils`: no issues; all acceptance greps = expected; format check exit 0
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1728, all passed**
- Full `flutter analyze`: **53 issues, 0 errors** (no new issue)

## Decisions Made

- See key-decisions above. The test-file helpers (`_input`, `_at`) keep every instant `DateTime.utc` and the server now is `spellFixtureNow`.

## Deviations from Plan

None - plan executed exactly as written (the `_wholeMinutesShown` extraction is a cosmetic restructuring of the plan's sketch with identical behaviour, noted under key-decisions).

## Issues Encountered

None.

## Known Stubs

None. Copy is provisional by design (D-19).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-07 (`SpellRecoveryCubit`): build one `SpellRecoveryInput` per known spell (usages from `status.spellStates`, fallback `ActiveSpell.usages`/`maxUsages`), call `spellRecoveryStatusOf(input, serverClock.now())` on each tick; Equatable statuses mean emit-on-change is free.
- 08-08 / 08-09: render `spellSummaryLine(...)` in rows and the detail labels in the sheet; use `noSpellSlotsLine` / `noKnownSpellsLine` for the empty states. Banner copies (D-07, D-11, D-17) are NOT in this file yet.

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
