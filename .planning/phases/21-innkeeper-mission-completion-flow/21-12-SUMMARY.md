---
phase: 21-innkeeper-mission-completion-flow
plan: 12
subsystem: innkeeper
tags: [mission-draft, cubit, bloc-test, guided-mission, wizard]
requires: ["21-11"]
provides:
  - "MissionDraftCubit({repository, pendingQuestId}) — load, start, saveStep, saveFights, simulate, saveCorrections, savePrizes, discard, complete over the served draft"
  - "MissionParticipantsCubit({repository}) — load(characterIds); Loaded.commonLocationId / placeLabelFor / itemNameOf / spellNameOf"
  - "MissionEnemiesCubit({repository, pendingQuestId}) — load, setShowAll, setQuery; state.visible"
  - "MissionPrizeOptionsCubit({repository, pendingQuestId}) — loadFor, loadAll"
  - "MockMissionDraftCubit, MockMissionParticipantsCubit, MockMissionEnemiesCubit, MockMissionPrizeOptionsCubit in test/helpers/mocks.dart"
affects: [21-13, 21-14, 21-15, 21-16, 21-17]
tech-stack:
  added: []
  patterns: ["served draft replaces the state on every reply (no local merge)", "one call at a time via _act guard on isSubmitting", "generation counter: only the latest enemy list request updates the state"]
key-files:
  created:
    - lib/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit.dart
    - lib/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_state.dart
    - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit.dart
    - lib/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_state.dart
    - lib/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit.dart
    - lib/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_state.dart
    - lib/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit.dart
    - lib/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_state.dart
    - test/screens/innkeeper/missionCompletion/missionDraftCubit/mission_draft_cubit_test.dart
    - test/screens/innkeeper/missionCompletion/missionParticipantsCubit/mission_participants_cubit_test.dart
    - test/screens/innkeeper/missionCompletion/missionEnemiesCubit/mission_enemies_cubit_test.dart
    - test/screens/innkeeper/missionCompletion/missionPrizeOptionsCubit/mission_prize_options_cubit_test.dart
  modified:
    - test/helpers/mocks.dart
decisions:
  - "MissionDraftCubit.load runs only from Loading/LoadFailed (pattern of RequestCompletionCubit); after Ready a reload means a new cubit (the landing rebuilds the wizard)"
  - "A successful action keeps failureSerial (only the failure is cleared), so a later refusal is always a new serial"
  - "simulate(i) with an index the served draft does not have sends nothing; the order rule (k after k-1, D-24) stays on the BE/UI"
  - "MissionParticipantsCubit reads characters (in parallel) then places sequentially, so a failed character read never leaves an unhandled places future"
  - "MissionEnemiesCubit.setShowAll with the current value sends nothing; a stale reply after a newer toggle is dropped (generation counter)"
metrics:
  duration: "~25 min"
  completed: "2026-11-14"
  tasks: 3
  files: 13
---

# Phase 21 Plan 12: Wizard Cubits — draft, participants, enemies, prize options Summary

Four single-responsibility Cubits for the guided mission wizard: `MissionDraftCubit` holds only the served draft and replaces it with every BE reply (D-09), creates it only on explicit start (D-11, D-28) and lets one call run at a time; the participants, enemies and prize-options Cubits hold served data only (names/labels, served enemy order with «Mostra tutti» and a display-only name search, served prize catalogue per character) — no bound, filter or rule computed on the device (rule 4). Plus four mock cubits for the page tests.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | MissionDraftCubit over the served draft | `de19e687` test(innkeeper): expect the mission draft cubit; `d2a8f1e3` feat(innkeeper): add the mission draft cubit |
| 2 | Participants, enemies and prize-options cubits | `af1264e4` test(innkeeper): expect the participants, enemies and prize cubits; `f61afb4e` feat(innkeeper): add the participants, enemies and prize cubits |
| 3 | Bookkeeping | `docs(phase-21): record plan 12 progress` |

## RED evidence

- Task 1: `flutter test test/screens/innkeeper/missionCompletion/missionDraftCubit` → `+0 -1` (compile failure: `mission_draft_cubit.dart` missing, `MissionDraftState` not found in `mocks.dart`).
- Task 2: `flutter test test/screens/innkeeper/missionCompletion` → compile failures (`mission_enemies_cubit.dart`, `mission_participants_cubit.dart`, `mission_prize_options_cubit.dart` missing; read from both the tests and `mocks.dart`).
- No case was green at the first run (all behind compile failures).

## GREEN

- `flutter test test/screens/innkeeper/missionCompletion` → `+24: All tests passed!` (Task 1).
- `flutter test test/screens/innkeeper` → `+229: All tests passed!` (Task 2).
- Analyzer: `47 issues found.` (47 info / 0 warning / 0 error) → `ANALYZE_GATE_OK` after each code task.
- Acceptance greps: draft cubit `package:flutter/` 0, `fightsInputWith*` 2, `appLog` 0; test `D-28` 2, `D-24` 3; enemies cubit/state `\.xp|isLegendary|legendary|locations` 0/0; prize cubit `rarity` 0; enemies test `D-03` 3; mock classes 4.
- Formatted one by one: the eight new lib files, the four new test files, `test/helpers/mocks.dart` (all new or formatter-clean before; the formatter reflowed `mission_draft_cubit_test.dart`, `mission_enemies_cubit_test.dart`, `mission_participants_state.dart`).

## Deviations from Plan

None in behaviour. Notes:
- Extra cases beyond the plan list: draft — load ignored once ready, double start ignored, simulate out of range sends nothing, actions ignored without a served draft, the next action clears the shown failure, a refused completion keeps the draft (`questInProgress`, D-25); participants — double load ignored, places read failure; enemies — same toggle sends nothing, stale reply after a newer toggle dropped, empty search shows all, a new load clears the failure; prize options — read in flight not sent again.
- `MissionDraftCubit` uses `_submit(Future<MissionDraft> Function(MissionDraft draft) call)` as the plan says, on top of a private `_act` guard shared with `discard` / `complete` (which do not return a draft).
- `MissionEnemiesState.copyWith` takes `InnkeeperFailure? Function()? failure` (omitted = keep, so `setQuery` never clears a shown failure).
- The test «a second action while submitting is ignored» reaches Ready through `load()` (calling the protected `emit` from a test would be an analyzer warning).

## Threat Flags

None: the surface is the one in the plan's threat model (T-21-39..42); no `appLog`, no new network operation.

## Known Stubs

None (nothing under `lib/screens` uses the Cubits yet — the pages come in 21-13..21-15, as planned).

## Self-Check: PASSED
