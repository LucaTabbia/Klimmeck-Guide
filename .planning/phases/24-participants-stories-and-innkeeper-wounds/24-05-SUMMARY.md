---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 05
subsystem: innkeeper
tags: [stories, additions, wizard, guided-flow, cubit]
requires: ["24-04"]
provides:
  - "MissionDraftCubit.saveAdditions(textsByCharacterId, {step}) and MissionDraftCubit.conclude(textsByCharacterId)"
  - "SheetTextField in lib/shared/components/sheet_text_field.dart (behaviour unchanged)"
  - "AdditionsStep (readers, participants, texts, onChanged, isSubmitting, onConclude, onRetry) with isTooLong, fieldKeyFor, concludeKey, retryKey"
affects: [24-06]
tech-stack:
  added: []
  patterns: ["the page is stateless about the texts: the owner passes the map and gets onChanged(characterId, text)", "a two-call action keeps the last served draft in a local and re-emits it on a refusal"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/steps/additions_step.dart
    - test/screens/innkeeper/missionCompletion/steps/additions_step_test.dart
  modified:
    - lib/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart
    - lib/screens/characterCreation/character_creation_screen.dart
    - test/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit_test.dart
    - test/screens/characterCreation/components/sheet_components_test.dart
  moved:
    - "lib/screens/characterCreation/components/sheet_text_field.dart -> lib/shared/components/sheet_text_field.dart"
decisions:
  - "conclude is its own guarded method, not a call through _act: _act re-emits the draft served BEFORE the call, conclude must re-emit the SAVED one after a refused completion"
  - "«Riprova» (failed read of the stories) sits in the bottom row between «Indietro» and the spacer, key mission.additions.retry; it never disables «Concludi»"
  - "«Concludi» is disabled when any value of the texts map is too long (not only the readers' ones)"
metrics:
  duration: "~30 min"
  completed: 2026-11-21
---

# Phase 24 Plan 05: Additions — Cubit actions and the page widget Summary

The Cubit saves one story addition per participant as its own draft section and closes the mission in one action (save with the step `stories`, then completion); the last page exists as a widget proven alone: per participant the story dropdown and one optional 1000-character field, with «Concludi» disabled only while a text is too long or a call is in flight. Nothing is reachable from the wizard yet (24-06).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the additions saved and the mission concluded in one action | 7eb39203 |
| 1 GREEN | Save the story additions and conclude in one action | 80b9a324 |
| 2 refactor | Promote SheetTextField to the shared components | aa54d886 |
| 2 RED | Expect the last page with one addition per participant | bbb3ef22 |
| 2 GREEN | Build the story additions page | a7e19f73 |
| 3 | Bookkeeping | (this docs commit) |

## TDD

- **Task 1 RED (7eb39203):** `mission_draft_cubit_test.dart` did not compile (`saveAdditions`, `conclude` missing).
- **Task 1 GREEN (80b9a324):** `flutter test test/screens/innkeeper/missionCompletion` → 257 passed.
- **Task 2 refactor (aa54d886):** `git mv` (history kept), two imports; `flutter test test/screens/characterCreation` → 106 passed.
- **Task 2 RED (bbb3ef22):** `additions_step_test.dart` did not compile (missing widget).
- **Task 2 GREEN (a7e19f73):** `additions_step_test.dart` → 19 passed; `flutter test test/screens/innkeeper test/screens/characterCreation` → 505 passed.

## What was built

- `saveAdditions` goes through `_save` like `savePrizes`; the input comes from `backgroundAdditionsInputOf(draft.participants, texts)` — one entry per participant of the SERVED draft, trimmed, the empty ones included (REPO-RULES «Additions on the save»; the research line «only non-empty texts are sent» is superseded by it).
- `conclude`: guard (ready and not submitting) → submitting → save with `MissionDraftStep.stories` → the saved draft, still submitting → `completeGuidedMission` → `MissionDraftCompleted`. An `InnkeeperException` at either call emits the last served draft (the old one after a refused save, the saved one after a refused completion) with the failure and `failureSerial + 1`. `complete()` is untouched (the recap uses it while the switch is off).
- `AdditionsStep`: `Column` → `Expanded(SingleChildScrollView(Column))` with, per reader, `ParticipantStory` and `SheetTextField` (`minLines: 3`, `maxLines: 5`, `maxLength: 1000`); bottom row `MissionBackButton` · «Riprova» (failed read only) · `Spacer` · «Concludi», hidden while `MediaQuery.viewInsetsOf(context).bottom > 0`. No dialog, no `ListView.builder`, no state.

## Assumption A2: confirmed

`characters` is reachable through `package:flutter/material.dart` / `widgets.dart` (no import of `package:characters`, `pubspec.yaml` untouched). `AdditionsStep.isTooLong('👨‍👩‍👧‍👦' * 1000)` is false and `* 1001` is true: clusters are counted, not UTF-16 units. The field's own counter reads `0/1000` and `5/1000` after «Drago».

## Gates

- Analyzer after each code commit (GREEN 1, refactor, GREEN 2): `47 issues found.` → `ANALYZE_GATE_OK`.
- Trailer check after every commit: `0`.
- `grep -c "Future<void> conclude\|Future<void> saveAdditions"` in the Cubit → 2; `appLog|print(` in the Cubit and in the page → 0; `ListView.builder` in the page → 0; `package:characters` under `lib/models` → none; `grep -rn "characterCreation/components/sheet_text_field.dart" lib test` → nothing; `git diff HEAD~3 -- pubspec.yaml` → empty.
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- Formatted one by one; every existing file was formatter-clean before the edits (no `style` commit).
- Full suite not run (REPO-RULES: only in 24-01 and 24-10).

## Deviations from Plan

**1. [Rule 1 - Test harness] The page test mounts a Scaffold that does not resize**
- **Found during:** Task 2, GREEN run.
- **Issue:** the RED harness used a default `Scaffold`, which consumes the keyboard inset: the page never saw it and the keyboard case failed on a correct page.
- **Fix:** `resizeToAvoidBottomInset: false`, as the wizard and `prizes_step_test.dart` do. It went into the GREEN commit `a7e19f73`, not into the RED one.

Details worth knowing:

- Cases beyond the plan's list — Cubit: «conclude does nothing without a served draft». Page: «an empty text is not too long», «the story so far is read again from the dropdown (D-04, D-08)», «shortening a text too long enables Concludi again», «a failed read shows the failure line and Riprova, and never blocks Concludi (D-31)», «no Riprova is offered while the read has not failed», «the bottom row holds Indietro and Concludi in landscape».
- `AdditionsStep.retryKey` is not in the plan's contract: the contract has `onRetry` and no place for it; it follows `StoriesStep`.
- The two switches that read `MissionParticipantsState` (loaded / failure line) are the same in `StoriesStep` and `AdditionsStep`. `stories_step.dart` is outside this plan's files: the duplication is left for 24-06, which touches the screen that feeds both.

## Notes for the next plans

- **24-06** owns the texts in the screen State (seeded once from `draft.additionOf(id)` at the first entry of the page) and must rebuild `AdditionsStep` with the new map on every `onChanged`: the error text and the disabled «Concludi» are computed from `texts`, the page keeps nothing.
- `SheetTextField` reads `initialValue` once: passing a new `texts` map never changes what a field shows. A field that must really be reset needs a new key.
- `conclude(texts)` already saves: the screen must not call `saveAdditions` before it. `saveAdditions(texts, step: …)` is for «Indietro» and for leaving the wizard.
- After a refused completion the state is the SAVED draft with the failure: the screen's texts and the draft agree, nothing to reseed.
- Tests that mount `AdditionsStep` need `resizeToAvoidBottomInset: false` on the Scaffold to see the keyboard, and the arrow seed (`CloudinaryAssets.arrowDown`).
- In landscape (360 logical px) one participant block is a closed dropdown plus a three-line field: to look at in the UAT with the wizard's header above it.

## Known Stubs

None. `AdditionsStep` has no caller in `lib` by design: 24-06 wires it behind `storyAndWoundCorrectionsEnabled`.

## Threat surface

No new surface beyond the plan's register: T-24-18 (the page only disables «Concludi»; the refusal `additionTooLong` is re-emitted with the draft), T-24-19 (texts only in widget parameters and in the input; no log, no storage), T-24-20 (`verifyNever(completeGuidedMission)` after a refused save), T-24-21 (the saved draft stays served after a refused completion).

## Self-Check: PASSED

`additions_step.dart`, `additions_step_test.dart` and `lib/shared/components/sheet_text_field.dart` exist, `lib/screens/characterCreation/components/sheet_text_field.dart` is gone; commits `7eb39203`, `80b9a324`, `aa54d886`, `bbb3ef22`, `a7e19f73` are in `git log`.
