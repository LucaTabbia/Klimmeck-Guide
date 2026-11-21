---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 06
subsystem: innkeeper
tags: [stories, additions, wizard, guided-flow, switch]
requires: ["24-05"]
provides:
  - "MissionPage.additions, MissionCompletionScreen.additionsTitle, storyPageLineOf(name), the parameter isStoryAndWoundInputEnabled (default: storyAndWoundCorrectionsEnabled)"
  - "RecapStep.onNext (given → «Avanti», key MissionCompletionScreen.nextKey, no completion) and the top-level confirmMissionCompletion(context, lines:)"
  - "Test harness: openWizard(..., isStoryAndWoundInputEnabled = false), _header/_headerOf(..., withAdditions = false), _draftAt(step, additions: {id: text})"
affects: [24-07, 24-10]
tech-stack:
  added: []
  patterns: ["the reachable pages are one getter: the header count and the page of the served step both read it", "a call's acceptance is one helper (_isAccepted) shared by the page change and by the leave"]
key-files:
  created: []
  modified:
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - lib/screens/innkeeper/missionCompletion/steps/recap_step.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
    - test/screens/innkeeper/missionCompletion/steps/recap_step_test.dart
decisions:
  - "conclude receives the screen's map as it is: the additions seeded from the draft plus every field touched, raw text (untrimmed), no key for a participant never seeded nor typed — the Cubit builds one entry per participant and trims"
  - "the confirmation of «Concludi» keeps the confirm label «Completa» (confirmMissionCompletion has one label; no new copy)"
  - "a draft reopened on the last page reads the prize names too: «Indietro» leads to the recap"
  - "unsaved = the trimmed text of a participant of the served draft differs from draft.additionOf(id)?.text ?? ''"
metrics:
  duration: "~10 min"
  completed: 2026-11-21
---

# Phase 24 Plan 06: Additions wired in the wizard (behind the switch) Summary

With the input on, the recap shows «Avanti», saves the step `stories` and opens «Passo 7 di 7 · Aggiunte alle storie»; «Concludi» there is the only completion and asks the confirmation first. With the input off (today's default) the flow ends on the recap with «Completa» exactly as before and counts 6 pages. The texts live in the screen State, are seeded once, and are saved on «Concludi», on «Indietro» and on leaving the wizard.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the additions page after the recap | 386cf61e |
| 1 GREEN | End the guided flow on the story additions | 22f2d52f |
| 2 RED | Expect unsaved additions saved on back and on leave | d32a5273 |
| 2 GREEN | Keep unsaved story additions on back and on leave | 98364f8a |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (386cf61e):** both files did not compile (`MissionPage.additions`, `additionsTitle`, `isStoryAndWoundInputEnabled`, `onNext`, `confirmMissionCompletion` missing).
- **Task 1 GREEN (22f2d52f):** `flutter test test/screens/innkeeper` → 417 passed.
- **Task 2 RED (d32a5273):** 7 cases failed (save on «Indietro», save on leave, refused leave, re-arm); the landscape keyboard case and the «no change» cases were already green (the frame's keyboard rule covers the page, as the plan expected).
- **Task 2 GREEN (98364f8a):** `flutter test test/screens/innkeeper` → 429 passed. Analyzer «47 issues found» after both code tasks; `tool/hardening_check.sh` green.

## What was built

- **Reachable pages:** `_reachablePages` = every `MissionPage`, minus `additions` when the input is off. The header count is its length (6 / 7); `_pageOf(MissionDraftStep.stories)` is its last page (`additions` on, `recap` off) with the «naming trap» comment. `_pageOf` is now an instance method.
- **Recap:** `onNext` given → «Avanti» (disabled while submitting or while a fight is not simulated), no dialog, no completion. Not given → «Completa» with `confirmMissionCompletion`. The screen passes `onNext` only with the input on; `complete()` is therefore reachable only with it off.
- **Texts:** `_seededAdditions` (`null` until the last page is first entered), seeded in `_enter(MissionPage.additions)` from `draft.backgroundAdditions` of the Cubit's current state; every `onChanged` replaces the map (`{...texts, id: text}`).
- **«Concludi»:** `confirmMissionCompletion(lines: recap lines + «Storia di <nome>: una nuova pagina» per participant with a non-empty trimmed text)`, then `cubit.conclude(texts)`. Nothing is called on «Annulla».
- **The exact map `conclude` receives:** the screen's map, e.g. a draft with no additions and only Aldo typed → `{char-aldo: 'Ha salvato il villaggio.'}`; Bea typed then cleared → `{char-aldo: '…', char-bea: ''}`. Same map for `saveAdditions`.
- **«Indietro» from the last page:** unsaved texts → `saveAdditions(texts)` (no step) through `_runThenOpen` → recap only if not refused; no unsaved text → recap at once, no call.
- **Leave rule as built:** `PopScope.canPop` is false while a call runs OR on the last page with unsaved texts (unless the previous leave-save was refused). `onPopInvokedWithResult(didPop: false)` → if the block was the unsaved text and no call is running: `saveAdditions(texts)`, then `_leave(null)` when accepted; when refused the wizard stays (the snackbar shows the failure line) and `_wasLeaveSaveRefused` is set, so the next attempt pops freely without saving. Typing in any field resets the flag. On every other page the leave is unchanged. System back and the bar's arrow both go through it.
- **Keyboard:** nothing new — the frame hides the counter and pads the body, `AdditionsStep` hides its button row; proven in landscape with the keyboard open on Bea's field.

## Deviations from Plan

**1. [Rule 2 - Missing functionality] Prize names for a draft reopened on the last page**
- **Found during:** Task 1
- **Issue:** `_openServedStep` loaded the prize names only when reopening on the recap; a draft reopened on the additions page and taken back by «Indietro» would show fallback prize names.
- **Fix:** `_showsPrizeNamesFrom(page)` (recap or additions); test «a draft reopened on the last page reads the prize names for the recap behind it».
- **Commit:** 22f2d52f

**2. [Refactor in scope] `_isAccepted` extracted from `_runThenOpen`** — the «not refused» serial check is shared with the leave-save (commit 98364f8a).

**3. Literal header pins of 24-04 kept, not updated** — the note of 24-04 expected «di 6» → «di 7»; the harness passes the input off by default, so «Passo 1 di 6 · Storie» (x2) and «Passo 2 di 6 · Luogo» stay true. New literal pins: «Passo 6 di 6 · Riepilogo» (off), «Passo 7 di 7 · Aggiunte alle storie» (on).

**4. One test case corrected between RED and GREEN (Task 1):** typing `''` into an empty field fires no `onChanged`; the case types a draft text first, then clears it.

Boy-scout candidate of 24-05 (the duplicated participants-state switches of `StoriesStep` / `AdditionsStep`) left alone: neither file is in this plan's scope.

## Known Stubs

None. The last page is unreachable in the running app until 24-10 flips `storyAndWoundCorrectionsEnabled` — by design (gate).

## For the next plans

- 24-10: flipping the constant changes `mission_completion_route.dart`'s screen (it relies on the default) and no test of these two files (grep `storyAndWoundCorrectionsEnabled` = 0 in both).
- 24-07 (fight step, correction section, chips): same harness rule — a helper parameter defaulting to `false`.
- `_header(page, title, withAdditions: true)` for cases with the input on.

## Self-Check: PASSED

- Commits 386cf61e, 22f2d52f, d32a5273, 98364f8a present in `git log`.
- `lib/config/story_and_wound_corrections.dart` still `false`; acceptance greps: `MissionPage.additions` 7, `confirmMissionCompletion` 2, `onPopInvokedWithResult` 1, `SharedPreferences|appLog` 0.
