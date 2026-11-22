---
phase: 24-participants-stories-and-innkeeper-wounds
fixed_at: 2026-11-22T00:00:00Z
review_path: .planning/phases/24-participants-stories-and-innkeeper-wounds/24-REVIEW.md
iteration: 1
fix_scope: all
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 24: Code Review Fix Report

**Fixed at:** 2026-11-22
**Source review:** `.planning/phases/24-participants-stories-and-innkeeper-wounds/24-REVIEW.md`
**Iteration:** 1

**Summary:**
- Findings in scope: 4 (1 warning, 3 info; orchestrator ruling: fix all)
- Fixed: 4
- Skipped: 0

**Gates after the last fix:** `flutter test -r failures-only` → `+5549: All tests passed!` (baseline 5535); `flutter analyze` → «47 issues found»; `tool/hardening_check.sh` → `hardening_check: OK`.

## Fixed Issues

### WR-01: «Luogo» uses the positions read before the mission started

**Files modified:** `lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart`, `lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart`, `lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_state.dart`, `lib/screens/innkeeper/missionCompletion/steps/place_step.dart` (tests: the cubit test, `place_step_test.dart`, `mission_completion_screen_test.dart`)
**Commits:** 974e6121 (RED), 8fff0119 (GREEN)
**Status:** fixed: requires human verification (state handling; covered by tests, not run on a device)
**Applied fix:**
- The screen tells apart a draft just created by «Inizia la missione» (`MissionDraftAbsent` → `MissionDraftReady`) from a draft that already existed (read at the opening or after «Riprova»). The first calls the new `MissionParticipantsCubit.reread`, the second keeps `ensureLoaded` (one read, D-02).
- `reread` waits for a read still running (it started while the players were free) and then reads characters and places again: the start tapped during the first read is covered too.
- A read of the same ids over a `MissionParticipantsLoaded` no longer passes through `Loading`: the state stays `Loaded` with `isRereadingPositions`, so the stories dropdowns keep their text and no loader appears in the wizard. This also holds for «Riprova» (`load`).
- While the reread runs, and after a failed one (`positionsFailure`), the positions are unknown: `locationIdOf` and `commonLocationId` give `null`, so «Luogo» shows the names without a place and «Resta qui» is disabled; «Teletrasporta il gruppo» stays available (D-31). A failed reread shows the failure line and «Riprova» on «Luogo», and keeps the stories.
- Regression test with the real cubit: both participants read in the ruins with the stories, they move, «Inizia la missione» → «Luogo» shows no old place and «Resta qui» saves the new one. Verified RED against the previous behaviour (`ensureLoaded` at the start).

### IN-01: `healedInjuriesLine` has no caller left in `lib/`

**Files modified:** `lib/utils/item_lines.dart`, `lib/shared/components/healed_injuries_text.dart`, `test/utils/item_lines_test.dart`
**Commit:** a2f10c75
**Applied fix:** function removed, the comment of `HealedInjuriesText` reworded; the test group now asserts on `healedInjuryLabels` (single label, enum order, no labels for an item with no «Cura» line). No RED commit: a removal.

### IN-02: The counter under the addition field counts the untrimmed text

**Files modified:** `lib/screens/innkeeper/missionCompletion/steps/additions_step.dart`, `lib/shared/components/sheet_text_field.dart`, `test/screens/innkeeper/missionCompletion/steps/additions_step_test.dart`
**Commits:** 1ce57e5c (RED), ebfd99ce (GREEN)
**Applied fix:** `SheetTextField` takes an optional `counterText`; the addition field drops `maxLength` and shows `AdditionsStep.counterOf(text)`, the same string the header summary is built from («aggiunta N/1000»), both from the one count of the limit (graphemes of the trimmed text). The field is in error only through `errorText`, that is by the same rule. Tests with spaces and line breaks at the edges, 998 letters plus three line breaks, 1001 letters between spaces, emoji clusters.

### IN-03: Null-check operators on the served status in the «Ferite» selector

**Files modified:** `lib/screens/mainScreen/characterCubit/character_selectors.dart`, `lib/screens/mainScreen/tabs/journal/journal.dart`, `test/screens/mainScreen/characterCubit/character_selectors_test.dart`
**Commits:** 7a8d2dc1 (RED), edb1b755 (GREEN)
**Applied fix:** the selector moved beside `curableInjuriesOf` as `woundsOf` (typedef `CharacterWounds`): `null` without a character or without a status, no wounds for a list not served; the Journal uses it and the builder already shows no section in both cases. Unit tests for the four cases.

**Not touched, out of the finding:** `_buildCoinsSection` in the same file still reads `state.character.status!.coins` (older than this phase): a Journal built for a character with no status would still fail there.

## Documentation

`.planning/ROADMAP.md`, Phase 24 success criterion 5 amended to the behaviour decided at the device UAT (D-20, D-21): heal item lines list every wound, the reader's innkeeper wounds in red; the heal quest line still lists only what will be cured.

---

_Fixed: 2026-11-22_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
