---
phase: 21-innkeeper-mission-completion-flow
plan: 01
subsystem: players-lock
tags: [mission-lock, character-status, failure-classifiers, copy]
requires: []
provides:
  - "CharacterStatus.missionInProgress / guidedMissionInProgress (lenient, default false, not selected)"
  - "missionInProgressCode = 'MISSION_IN_PROGRESS' (lib/repository/mission_in_progress.dart)"
  - "missionInProgressLabel, missionInProgressRefusalLine (lib/utils/mission_lines.dart)"
  - "TravelFailure.missionInProgress, QuestAcceptanceFailure.missionInProgress with the wait-line banner"
affects: [21-02, 21-03, 21-04, 21-16]
tech-stack:
  added: []
  patterns: ["shared refusal code file + shared copy file (prison pattern)", "lenient bool read `json['x'] == true`"]
key-files:
  created:
    - lib/repository/mission_in_progress.dart
    - lib/utils/mission_lines.dart
    - test/utils/mission_lines_test.dart
  modified:
    - lib/models/character/character_status.dart
    - lib/repository/travel_failure.dart
    - lib/screens/mainScreen/travelCubit/travel_notice.dart
    - lib/repository/quest_acceptance_failure.dart
    - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
    - test/models/character/character_status_test.dart
    - test/repository/travel_failure_test.dart
    - test/screens/mainScreen/travelCubit/travel_notice_test.dart
    - test/repository/quest_acceptance_failure_test.dart
    - test/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice_test.dart
    - test/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit_test.dart
decisions:
  - "Commit scope `shared` instead of the plan's `repository` (not in the REPO-RULES scope list)"
  - "MISSION_IN_PROGRESS not added to the stale-list set of QuestAcceptanceOutcomeListener (LB-1: the refusal stays a visible banner)"
metrics:
  duration: ~20min
  completed: 2026-11-14
---

# Phase 21 Plan 01: Mission lock plumbing I Summary

The two served mission flags are modelled on `CharacterStatus` (lenient `== true`, default `false`, in `toJson`/`copyWith`/`props`, selected nowhere under `lib/graphql`), and `MISSION_IN_PROGRESS` now maps to `TravelFailure.missionInProgress` / `QuestAcceptanceFailure.missionInProgress`. Both show «Sei impegnato in una missione: aspetta l'esito» under their usual titles. The code and the copy each live in one shared file.

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Mission flags on CharacterStatus | `a7e5b7bf` test, `e03e5001` feat | 95 tests of `test/models/character` green |
| 2 Shared code/copy, travel and acceptance refusals | `c985636d` test, `f7811586` feat | 266 tests green (the Task 2 verify set + `test/models/character`) |
| 3 Bookkeeping | this commit | ROADMAP 1/18, STATE `Plan: 01 of 18`, VALIDATION 21-01-01..03 green |

## RED evidence

- Task 1: compile error `The getter 'missionInProgress' / 'guidedMissionInProgress' isn't defined for the type 'CharacterStatus'` (all 5 cases of the group `mission flags (BE Phase 22)`).
- Task 2: compile errors `Member not found: 'missionInProgress'` on `TravelFailure`/`QuestAcceptanceFailure` (5 files) and `Error when reading 'lib/repository/mission_in_progress.dart'` (mission_lines_test).
- No case was green at the first run.

## Extra switch sites (Task 2 step 5)

`grep -rn "TravelFailure\.imprisoned\|QuestAcceptanceFailure\.imprisoned" lib` found no other exhaustive switch over either enum. The only other sites are the prison-duration getters in `travel_outcome_listener.dart:66` and `quest_acceptance_outcome_listener.dart:80`, which are not switches, and the `_staleListFailures` set in `quest_acceptance_outcome_listener.dart`. Following LB-1, that set did NOT get the new value. So the code has no extra sites.

## Verification

- `flutter test test/models test/repository` (after Task 1): 1864 green. Task 2 verify set + `test/models/character`: 266 green.
- Analyzer last line: `47 issues found.` (47 info / 0 warning / 0 error), `ANALYZE_GATE_OK` after both code tasks.
- `grep -rn "missionInProgress" lib/graphql`: empty. Registry untouched (46).
- `grep -rn "'MISSION_IN_PROGRESS'" lib`: only `lib/repository/mission_in_progress.dart`.
- Formatted one by one: all files touched. All of them were formatter-clean before (pre-check). Only `test/repository/travel_failure_test.dart` was changed by the formatter, on the new test only.

## Deviations from Plan

1. **[Scope] Commit scope `shared` replaces `repository`** in the Task 2 commits. REPO-RULES lists `models, graphql, innkeeper, map, journal, shop, quests, shared, utils, test`, and REPO-RULES wins over the plan.
2. **Test helper name**: the plan says `_coded(code)`. The existing helper in both classifier tests is `_withCode(code)`, and it was reused.
3. **Cubit test**: the `quest_travel_preview_cubit_test` case also asserts in `verify` that `travelNoticeFor(TravelFailure.missionInProgress)` gives the wait line (the plan's «that state's notice is the travel wait line»).

## Known Stubs

None. `missionInProgressLabel` is defined and pinned by a test but has no reader yet. The later lock plans (pawn, Journal) will read it.

## Self-Check: PASSED

- Files created exist: `lib/repository/mission_in_progress.dart`, `lib/utils/mission_lines.dart`, `test/utils/mission_lines_test.dart`.
- Commits exist: `a7e5b7bf`, `e03e5001`, `c985636d`, `f7811586`.
