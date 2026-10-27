---
phase: 08-spells-section-journal-tab
plan: 01
subsystem: models
tags: [flutter, dart, equatable, spells, fixtures, formatting]

# Dependency graph
requires:
  - phase: BE Phase 9.1 (Spell State and Recovery Contract, proposed)
    provides: "`CharacterStatus.spellStates: [SpellState!]!` with `spell { id }`, `usages`, ISO-8601 `Z` `recoveries` (09.1-CONTEXT D-05; NOT on BE develop yet)"
  - phase: 07-travel
    provides: "tolerant parse boundary pattern (`ActiveTravel.tryFromJson`) and `formatTravelDuration`"
provides:
  - "Flutter-free `SpellState { spellId, usages, recoveries }` with fromJson / tryFromJson / toJson (UTC instants, sorted ascending, unmodifiable)"
  - "`CharacterStatus.spellStates`: `null` when the field is absent, malformed entries skipped, kept by `copyWith`, in `props`/`toJson`"
  - "`formatGameDuration` in `lib/utils/game_duration_format.dart`, shared by travel and spells; `formatTravelDuration` removed"
  - "`test/helpers/fixtures/spell_fixtures.dart`: `spellFixtureNow`, `spellJson`, `activeSpellJson`, `spellStateJson`, `spellbookCharacterJson`, `spellbookCharacter`"
affects: [08-04, 08-05, 08-12]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Per-entry parse boundary for a server list: `json.map(X.tryFromJson).whereType<X>()`, non-list → `null` (field absent)"
    - "Game durations live in `lib/utils/` and are shared across features"

key-files:
  created:
    - lib/models/spell/spell_state.dart
    - lib/utils/game_duration_format.dart
    - test/helpers/fixtures/spell_fixtures.dart
    - test/models/spell/spell_state_test.dart
    - test/utils/game_duration_format_test.dart
  modified:
    - lib/models/character/character_status.dart
    - lib/models/travel/travel_time_format.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
    - test/models/character/character_status_test.dart
    - test/models/travel/travel_time_format_test.dart

key-decisions:
  - "`spellStates == null` means 'field absent' (pre-9.1 BE or fragment not yet extended) and drives the fallback; `[]` stays an empty list"
  - "`_minutesPerHour`/`_minutesPerDay` moved with the formatter: no other function in travel_time_format.dart used them"

patterns-established:
  - "Spell fixtures: `spellbookCharacterJson(spellStates: null)` omits the key entirely = pre-9.1 payload"

requirements-completed: []  # Foundations only for SPELL-05 / SPELL-02; traceability is done by plan 08-12 (no mark-complete here)

# Metrics
duration: 33min
completed: 2026-10-27
---

# Phase 8 Plan 01: Spell State Model, Fixtures and Shared Duration Formatter Summary

**Tolerant `SpellState` model and optional `CharacterStatus.spellStates` against the proposed BE 9.1 contract, Wave 0 spell fixtures, and `formatGameDuration` moved to `lib/utils` for travel and spells**

## Performance

- **Duration:** ~33 min
- **Started:** 2026-10-27T12:31:00Z
- **Completed:** 2026-10-27T13:04:00Z
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 11 (5 created, 6 modified)

## Accomplishments

- `SpellState` parses `{'spell': {'id'}, 'usages', 'recoveries'}` into UTC instants, sorted ascending, unmodifiable; `tryFromJson` returns `null` for every malformed shape (T-8-01, T-8-02 mitigated)
- `CharacterStatus.spellStates` is `null` without the key, a list otherwise; malformed entries are skipped and the rest of the status still parses; `copyWith` keeps it, `props` and `toJson` include it
- One duration formatter (`formatGameDuration`) for travel and spells; both travel callers switched; travel behaviour unchanged (all map tests green)
- Spell fixtures ready for every later plan

## Task Commits

1. **Task 1 RED: spell fixtures + failing SpellState/status tests** - `e5dcdc1` (test)
2. **Task 1 GREEN: SpellState + optional CharacterStatus.spellStates** - `4b656d2` (feat)
3. **Task 2 RED: move the duration tests to utils** - `a28784a` (test)
4. **Task 2 GREEN: share the game duration formatter** - `627e419` (refactor)

**Plan metadata:** see `docs(phase-8): record plan 01 progress`

### RED failure outputs

- Task 1: `test/models/spell/spell_state_test.dart:2:8: Error: Error when reading 'lib/models/spell/spell_state.dart': No such file or directory` and `Error: Undefined name 'SpellState'.` (compile failure, as expected)
- Task 2: `test/utils/game_duration_format_test.dart:2:8: Error: Error when reading 'lib/utils/game_duration_format.dart': No such file or directory` and `Error: Method not found: 'formatGameDuration'.` (compile failure, as expected)

## Files Created/Modified

- `lib/models/spell/spell_state.dart` - per-spell state model (usages + recovery instants)
- `lib/models/character/character_status.dart` - optional `spellStates` (fromJson/toJson/copyWith/props)
- `lib/utils/game_duration_format.dart` - `formatGameDuration` (moved verbatim from travel)
- `lib/models/travel/travel_time_format.dart` - `formatTravelDuration` and its two constants removed
- `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart` - call + import (hand edit, format-dirty file, 2+/1-)
- `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart` - call + import
- `test/helpers/fixtures/spell_fixtures.dart` - Wave 0 spell fixtures
- `test/models/spell/spell_state_test.dart` - 16 SpellState cases
- `test/models/character/character_status_test.dart` - `spellStates` group (7) + `spellbookCharacter()` test
- `test/utils/game_duration_format_test.dart` - moved `formatGameDuration` group (12 cases, unchanged)
- `test/models/travel/travel_time_format_test.dart` - duration group removed

## Verification

- Task 1 verify: 41 tests green; `flutter analyze` on the touched paths: no issues
- Task 2 verify: 197 tests green; `grep -rn formatTravelDuration lib test` empty
- Plan-end quick run (`flutter test test/models test/utils test/graphql test/repository test/tool test/shared test/screens/mainScreen test/screens/auth`): **+1617, all passed**
- Full `flutter analyze`: **54 issues, 0 errors** (ceiling 54 until 08-03; no new issue)
- `lib/graphql` untouched; format checks of all new/clean files exit 0

## Decisions Made

- The fixture's doc comments are in Italian (project style) and the inline `// ms` notes of the plan's sketch became a doc comment on `spellJson`.
- The moved test group keeps exactly the 12 existing cases (the plan's behaviour list mentions 59 min / 26 h as examples "plus whatever cases exist today"; the move is verbatim, no case added or changed).

## Deviations from Plan

### Verify-command note (no code change)

**1. Task 2 `<automated>` analyze step exits 1 because of a pre-existing info**
- **Found during:** Task 2 verify
- **Issue:** `flutter analyze lib/utils lib/models/travel lib/screens/mainScreen/tabs/map ...` reports `info • Don't invoke 'print' in production code • lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart:24:7 • avoid_print`; `flutter analyze` exits non-zero on infos. The file is untouched by this plan (last change `5719931`, Phase 11) and the issue is part of the 54-issue baseline.
- **Fix:** none (out of scope per the scope boundary). Tests and the grep step pass; the only analyzer finding on the path set is that baseline info.

---

**Total deviations:** 1 (verify-command note, no code change)
**Impact on plan:** none; no scope creep.

## Issues Encountered

None.

## Known Stubs

None. `spellStates` stays `null` in real payloads until plan 08-12 extends the fragment (intentional, schema-gated).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- 08-04 / 08-05 can import `SpellState`, read `status.spellStates` (`null` = fallback path) and use `formatGameDuration` from `package:klimmeck_guide/utils/game_duration_format.dart`.
- Fixtures: `spellbookCharacter(spellStates: [spellStateJson()])` builds the 9.1 shape; omit `spellStates` for the pre-9.1 payload; `spellFixtureNow` = 10:00 UTC, default recoveries at 10:12 and 10:42 UTC.
- `spellJson` defaults: `recoveryTime` 7 200 000 ms («2 h»), `maxUsages` 3, `requiredLearnTime` 3 600 000 (unit still to confirm, A3).
- 08-03 must bring the analyzer to ≤ 53 (`spell_info.dart:52`).

## Self-Check: PASSED

---
*Phase: 08-spells-section-journal-tab*
*Completed: 2026-10-27*
