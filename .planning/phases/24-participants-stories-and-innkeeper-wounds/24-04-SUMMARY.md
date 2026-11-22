---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 04
subsystem: innkeeper
tags: [stories, wizard, reading-page, guided-flow]
requires: ["24-03"]
provides:
  - "StoriesStep (readers, participants, onRetry, footer) with StoriesStartFooter and StoriesNextFooter"
  - "MissionPage { stories, place, encounters, fight, prizes, recap }; MissionCompletionScreen.storiesTitle"
  - "MissionStepHeader.stepCount as a required parameter (the screen passes MissionPage.values.length)"
  - "the absent-draft branch reads the card's participants through ensureLoaded and never starts the draft"
  - "test helper _header(MissionPage, title) / _headerOf(...) in mission_completion_screen_test.dart"
affects: [24-05, 24-06]
tech-stack:
  added: []
  patterns: ["the page receives its footer as a widget instead of a mode flag", "one frame (step counter + page) shared by the absent and the served branch"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/steps/stories_step.dart
    - test/screens/innkeeper/missionCompletion/steps/stories_step_test.dart
  modified:
    - lib/screens/innkeeper/missionCompletion/mission_completion_screen.dart
    - lib/screens/innkeeper/missionCompletion/components/mission_step_header.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_screen_test.dart
    - test/screens/innkeeper/missionCompletion/mission_completion_route_test.dart
  deleted:
    - lib/screens/innkeeper/missionCompletion/steps/start_step.dart
decisions:
  - "The start footer stacks the note above the button (Column + Wrap): a Row squeezed the note to zero width beside the button and «Riprova»"
  - "«Riprova» sits in the StoriesStep row beside the footer, only on a failed read; the start button never reads the participants state"
  - "The served «Storie» page shows no leave note beside the counter (the note stays on «Luogo»)"
  - "Explicit retries call load; opening and the start call ensureLoaded (no forced reread)"
metrics:
  duration: "~40 min"
  completed: 2026-11-21
---

# Phase 24 Plan 04: Reading page in the wizard Summary

The guided flow opens on «Passo 1 di 6 · Storie»: one closed dropdown per participant of the card, the start note and «Inizia la missione» at the bottom; after the start the same page is one «Indietro» away from «Luogo», with «Avanti» and no save.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the stories page before the mission starts | 94ce4647 |
| 1 GREEN | Build the stories page of the guided flow | 83e34b09 |
| 2 RED | Expect the wizard to open on the stories | 15e2582d |
| 2 GREEN | Open the guided flow on the participants' stories | 19db3d05 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (94ce4647):** `stories_step_test.dart` did not compile (missing widget).
- **Task 1 GREEN (83e34b09):** `stories_step_test.dart` → 12 passed; `flutter test test/screens/innkeeper` → 363 passed.
- **Task 2 RED (15e2582d):** `mission_completion_screen_test.dart` did not compile (`MissionPage.stories` missing; the absent branch still built `StartStep`, the header still said «di 5»).
- **Task 2 GREEN (19db3d05):** `mission_completion_screen_test.dart` → 77 passed; `flutter test test/screens/innkeeper` → 373 passed.

## Rewritten test cases (mission_completion_screen_test.dart)

| Old title | New title |
|-----------|-----------|
| opening shows the loader, then «Inizia la missione» without a draft (D-28) | an absent draft opens the stories of the card's participants and never starts the mission (D-02, D-28) |
| tapping «Inizia la missione» starts the draft (D-11, D-28) | «Inizia la missione» starts the draft once and lands on «Luogo» (D-02, D-28) |
| «Indietro» is disabled on «Luogo» | «Indietro» is disabled on the stories and enabled on «Luogo» |
| «Riprova» on «Luogo» reads the participants again (D-31) | same title; now `ensureLoaded` once at the open and `load` once on the retry (was `load` twice) |

Same titles, new assertions: the three resumed-draft cases that verified `participantsCubit.load([_aldo, _bea])` now verify `ensureLoaded([_aldo, _bea])`; the 27 header pins «Passo k di 5 · …» go through `_headerOf(MissionPage.<page>, '<titolo>')` (`_headerText` is gone).

New cases: «the stories are read with the card's ids while the draft is absent (D-02)»; «a draft found absent after the load reads the stories with the card's ids (D-02)»; «the rank of a card participant follows the name once its character is read (D-03)»; «the participants are asked once more with the draft's ids after the start, through ensureLoaded (no forced reread)»; «while the start is in flight the button is disabled and the stories stay readable (D-28)»; «a failed read on the stories keeps «Inizia la missione» enabled and «Riprova» reads again (D-31)»; «a refused start stays on the stories with the failure line»; «Indietro from «Luogo» shows the stories with «Avanti» (D-02)»; «Avanti on the stories returns to «Luogo» without saving (D-02)»; «Riprova on the stories of a started mission reads the draft's participants again (D-31)».

## Gates

- Analyzer after each GREEN: `47 issues found.` → `ANALYZE_GATE_OK`.
- Trailer check after every commit: `0`.
- `test ! -f …/start_step.dart && ! grep -rn "StartStep\|di 5 ·" lib test` → OK; `static const int stepCount` → 0; `ensureLoaded(` in the screen → 2; `D-02` in the screen test → 7; `ListView.builder|showDialog|showModalBottomSheet` in `stories_step.dart` → 0.
- `bash tool/hardening_check.sh` → exit 0.
- Formatted one by one; every existing file was formatter-clean before the edits (no `style` commit).
- Full suite not run (REPO-RULES: only in 24-01 and 24-10).

## Deviations from Plan

**1. [Rule 3 - Blocking] `mission_completion_route_test.dart` adapted (outside `files_modified`)**
- **Found during:** Task 2, GREEN run of `test/screens/innkeeper`.
- **Issue:** the route test builds the real Cubits over a mocked repository; with an absent draft the screen now reads the card's participants, and `readCharacter` was not stubbed (`Null is not a subtype of Future<Character>`).
- **Fix:** stubs for `readCharacter` and `listPointsOfInterest`, the arrow seed, and one more assertion (each card participant read once, the mission never started). Title extended with «reads the stories without starting … D-02». It went into the GREEN commit `19db3d05`, not into the RED one.

**2. [Rule 1 - Layout] The start footer is a column, not a row**
- **Found during:** Task 1, GREEN run.
- **Issue:** note, button and «Riprova» on one row left the note zero width in the test font (overflow of 1971 px).
- **Fix:** note above, button (and loader) below in a `Wrap`; «Riprova» stays beside the footer, bottom-aligned. To look at in the UAT (landscape height: counter + list + two-line note + button).

Details worth knowing:

- The plan counted 28 header pins; 27 were found and rewritten (the 28th was the doc comment of the header widget, updated too).
- Three cases of `stories_step_test.dart` beyond the plan's list: «no Riprova is offered while the read has not failed», «a read still running leaves Inizia la missione enabled (D-31)», and the retry / start assertions merged where the plan listed them apart.
- No other pin of the old shape was found outside the two wizard test files (`grep -rn "di 5\|StartStep\|stepCount" lib test`).

## Notes for the next plans

- **24-06** adds `MissionPage.additions`: the header count follows `MissionPage.values.length` by itself, and the screen tests follow through `_header(page, title)` — only the literal pins «Passo 1 di 6 · Storie» (2 places) and «Passo 2 di 6 · Luogo» (1 place) need the new number. `_pageOf(MissionDraftStep.stories)` still returns `MissionPage.recap` (comment «fino al 24-06»): repoint it to `additions`. `_enterPrevious` and `_titleOf` / `_buildPage` are exhaustive switches: the new value will not compile until handled.
- The screen's frame is `_buildFrame(stepNumber, title, headerSide, onBack, page)`; the stories page is `_buildStories(readersOf, onRetry, footer)`. Readers: `_cardReaders(participantsState)` before the draft (rank from `titleOf`), `_draftReaders(draft)` after.
- The harness of `mission_completion_screen_test.dart` now stubs `participantsCubit.ensureLoaded(any())` and seeds `CloudinaryAssets.arrowDown` in `openWizard`.
- Any test that opens the wizard through `openMissionCompletion` with an absent draft must stub `repository.readCharacter` and `listPointsOfInterest`.
- `ensureLoaded` is dropped while `Loading`: a start tapped during the first read does not read twice (same ids); if the card and the draft ever listed different ids, the missing one shows the reading line (tolerated, Pitfall 7).

## Known Stubs

None.

## Threat surface

No new surface beyond the plan's register: T-24-14 (opening never starts: `verifyNever(draftCubit.start)` and `verifyNever(repository.startMissionDraft)`), T-24-15 (the start button ignores the participants state: tests on `Failed` and `Loading`), T-24-16 (no log, no storage; the Cubit dies with the route).

## Self-Check: PASSED

`stories_step.dart` and `stories_step_test.dart` exist, `start_step.dart` is gone; commits `94ce4647`, `83e34b09`, `15e2582d`, `19db3d05` are in `git log`.
