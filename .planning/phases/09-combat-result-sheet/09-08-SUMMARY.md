---
phase: 09-combat-result-sheet
plan: 08
subsystem: state + ui
tags: [flutter, cubit, combat, awaiting-aid, death, satchel, map, pawn]

# Dependency graph
requires:
  - phase: 09-02
    provides: "`CharacterStatus.awaitingAid` (`AwaitingAid?`), fixtures `awaitingAidJson()` / `travellingCharacterJson(awaitingAid:)`"
provides:
  - "`CharacterUnavailable` state: quiet «character gone but still current» (D-13 b)"
  - "`CharacterCubit._markCharacterGone`: one user refresh per cubit lifetime, refetch on resume disabled afterwards"
  - "`disabledSatchelPages(isAwaitingAid:)`: Board and Shop disabled while wounded (D-16)"
  - "`CharacterMarkerLayer.awaitingAidLabelKey` / `awaitingAidLabel`: «In attesa di soccorso» over the idle pawn; drag gate on `awaitingAid`"
affects: [09-09, 09-10, 09-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One-shot terminal latch in a cubit (`_isCharacterGone`): every terminal FORBIDDEN/NOT_FOUND path (load, refetch, stream) goes through one method that requests the user refresh only once"
    - "Named record typedef as `BlocSelector` value (`_SatchelInputs`) instead of a positional tuple"

key-files:
  created: []
  modified:
    - lib/screens/mainScreen/characterCubit/character_cubit.dart
    - lib/screens/mainScreen/characterCubit/character_state.dart
    - test/screens/mainScreen/characterCubit/character_cubit_test.dart
    - lib/screens/mainScreen/components/satchel_availability.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/main_screen_test.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart

key-decisions:
  - "A terminal FORBIDDEN/NOT_FOUND at the first load emits `CharacterUnavailable` (no `CharacterError`); after a load it keeps the last `CharacterLoaded`; in both cases one `requestUserRefresh` per cubit lifetime and `refreshCharacter` becomes a no-op"
  - "MainScreen shows nothing new for `CharacterUnavailable`: `MainScreenCubit.loadData()` is never called, so the cold-start `KGLoader` stays (allowed at cold start) until the death sheet (09-10/09-11) and the BE `userUpdated(null)` re-key the shell"
  - "The awaiting-aid label reuses `_TravelLabel` (IgnorePointer parchment) in a second Marker with the travelling-label geometry"

patterns-established:
  - "Satchel availability inputs come from `status` as a named record `({location, isTravelling, isAwaitingAid})`"

requirements-completed: []

# Metrics
duration: 20min
completed: 2026-10-28
---

# Phase 9 Plan 08: Wounded State and Quiet Unavailable Character Summary

**`CharacterCubit` now treats a terminal FORBIDDEN/NOT_FOUND as a quiet `CharacterUnavailable` (cold start) or a kept `CharacterLoaded` (in session), with a single user refresh per lifetime and no refetch loop; a wounded character (`status.awaitingAid`) gets «In attesa di soccorso» over the idle pawn, cannot drag it, and has Board and Shop disabled in the satchel.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-10-28
- **Tasks:** 3 (6 commits, TDD)
- **Files modified:** 9 (0 created)

## Accomplishments

- `CharacterUnavailable` state and `_markCharacterGone` latch (D-13 b, T-9-23, T-9-24)
- `disabledSatchelPages(isAwaitingAid:)` + `MainScreen` wiring through a named record selector (D-16, T-9-25)
- Wounded pawn label and drag gate in the DIRTY `CharacterMarkerLayer`, hand-edited (21 added / 1 deleted line)

## Task Commits

1. **Task 1 RED** — `5b5d0be` test(combat): expect a quiet unavailable character
2. **Task 1 GREEN** — `1cd7f68` feat(combat): keep a dead current character quiet
3. **Task 2 RED** — `770efb3` test(combat): expect board and shop closed while awaiting aid
4. **Task 2 GREEN** — `69c6bc1` feat(combat): close board and shop while awaiting aid
5. **Task 3 RED** — `f03a760` test(combat): expect the wounded pawn label and drag gate
6. **Task 3 GREEN** — `f6392f7` feat(combat): show the wounded pawn and block its drag

## RED failures (expected)

- Task 1: `Error: Couldn't find constructor 'CharacterUnavailable'.` (compilation failure of `character_cubit_test.dart`)
- Task 2: `Error: No named parameter with the name 'isAwaitingAid'.` in `satchel_availability_test.dart`; in `main_screen_test.dart` `awaiting aid on a city marker board and shop do nothing` and `awaiting aid the board and shop cells look disabled` failed (the Profilo case passed, as expected)
- Task 3: `Error: Member not found: 'awaitingAidLabelKey'.` (compilation failure of `character_marker_layer_test.dart`)

## Verification

- Full suite: 2323 → **2335** tests green (+12: 4 cubit, 2 satchel availability, 3 main screen, 3 marker layer)
- `flutter analyze`: **52 issues** (baseline 53), 0 errors
- Acceptance greps: `class CharacterUnavailable` = 1; `_markCharacterGone` = 4; `requestUserRefresh()` = 1; `isAwaitingAid` in satchel_availability = 2; `isAwaitingAid:` in main_screen = 4; `awaitingAidLabelKey` in marker layer = 2; `awaitingAid == null` = 1; marker layer numstat `21 1`
- Format: all CLEAN files were formatter-clean before the edit (including `character_marker_layer_test.dart`) and are formatter-clean after; the DIRTY marker layer was never formatted

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

### Auto-adjusted

**1. [Rule 1 - Clarity] Satchel doc line wording**
- The plan's doc line `/// … e mai in attesa di soccorso (Phase 9 D-16).` was written as `/// Mai neppure in attesa di soccorso (Phase 9 D-16).` (the ellipsis read as a dangling fragment). No behaviour change. Commit `69c6bc1`.

**2. [Clean Code] Named record typedef for the selector**
- The plan asked for the record `({PointOfInterest? location, bool isTravelling, bool isAwaitingAid})`; it is declared once as the private typedef `_SatchelInputs` in `main_screen.dart` and used by the `BlocSelector`, `_isPageDisabled` and `_satchelInputsOf` (no repetition of the record shape). Commit `69c6bc1`.

**3. [Test] Disabled-look check**
- `main_screen_test.dart` has no finder for the darker cell in the travel tests; the wounded test asserts `disabledPages == {board, shop}` on both `SatchelMenu` and `MenuBackground` (the widgets that paint the disabled look). Commit `770efb3`.

**4. [Clean Code] Single doc paragraph instead of per-path comments in the cubit**
- The class doc now describes FORBIDDEN/NOT_FOUND for load, refetch and stream together, mentioning `CharacterUnavailable` and D-13.

## Known Stubs

None. `awaitingAidLabel` copy is provisional by design (D-19).

## Next Phase Readiness

- 09-09 can provide `MapAvailabilityCubit`; the drag gate already blocks the wounded pawn independently
- 09-10 listens to `CharacterUnavailable` to refetch the unacknowledged results (cubits never call cubits)

## Self-Check: PASSED

- All 9 modified files exist; commits 5b5d0be, 1cd7f68, 770efb3, 69c6bc1, f03a760, f6392f7 present in `git log`
