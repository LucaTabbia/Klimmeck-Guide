---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 12
subsystem: map
tags: [research, learning, countdown, pawn-label, quest-overlay]
requires: ["23-11"]
provides:
  - "WorldMap owns SpellLearningCubit (server clock), follows pendingQuest.learningEndsAt at mount and at every characterUpdated that changes it, closes it in dispose"
  - "Quest overlay opened from the paper reads spellLearningLine(name, remaining) during the learning part, questStateLabel otherwise"
  - "Pawn activity label: learning line > «Ricercando…» (school type or board quest prizes.spellDraw) > per-type label"
affects: [23-13, 23-14, 23-08]
tech-stack:
  added: []
  patterns: ["Map-scoped countdown cubit like TravelProgressCubit, provided with BlocProvider.value"]
key-files:
  created: []
  modified:
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
decisions:
  - "The overlay label reads the followed lane `_selectedLane`: `_followLane` already replaces it with the current lane of the same quest at every characterUpdated, so no second lane lookup is needed"
  - "The pawn finds the board quest by the lane's quest id in QuestLoaded (pattern of the paper layer) only to read prizes.spellDraw"
metrics:
  duration: "~30 min"
  completed: 2026-11-16
---

# Phase 23 Plan 12: Map learning countdown, pawn and overlay labels of the two parts Summary

The Map now counts down the learning part and shows both parts of a draw quest: «Ricercando…» above the pawn during the research, «Imparando «Dardo»: 28 min» above the pawn and in the quest overlay during the learning, «Imparando «Dardo»…» once the time is over until the BE frees the lane. Everything follows the served lane; no loader, no chrome.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the learning line in the quest overlay | 5d4c0c72 |
| 1 GREEN | Show the spell being learned in the quest overlay | b3824297 |
| 2 RED | Expect the research and learning pawn labels | 33248277 |
| 2 GREEN | Label the research and learning above the pawn | 34df28ed |
| 3 | Bookkeeping | (this docs commit) |

## RED failures

- `world_map_travel_test.dart`: «the quest overlay reads the spell being learned…», «the overlay turns to the learning line…», «the overlay of a learning already over…» — `Actual: 'Apprendimento…'` (from `questStateLabel`).
- `character_marker_layer_test.dart`: «a study quest reads the research part only when the board quest carries the draw» — `Actual: 'Studiando…'`; the two learning cases — `Actual: 'Ricercando…'`.

Green at the first run (as foreseen by the plan):
- «the paper reads Apprendimento during the learning part (D-26)» — the paper follows `questStateLabel` since 23-11.
- «a school quest in progress reads the research part above the pawn (D-26)» — `missionActivityLabelOf` maps the three schools to «Ricercando…» since 23-11.
- The research half of «the overlay turns to the learning line…» (`'Ricercando…'` before the change) — same reason.

## Harnesses

- `character_marker_layer_test.dart` gained `BlocProvider<QuestCubit>` (`MockQuestCubit`, `QuestLoaded(quests)`) and `BlocProvider<SpellLearningCubit>` (local `_MockSpellLearningCubit` driven by a stream), with `quests:` and `learning:` parameters on `pumpLayer`.
- Every harness that pumps `WorldMap` already provided `ServerClockService` (needed by `TravelProgressCubit`): no provider added anywhere. The pawn layer reads `SpellLearningCubit` from the `MultiBlocProvider` of `WorldMap`.

## Verification

- `flutter test test/screens/mainScreen/tabs/map test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/main_screen_quest_results_test.dart`: `+370: All tests passed!` (after Task 1); `flutter test test/screens/mainScreen/tabs/map`: `+332: All tests passed!` (after Task 2).
- Acceptance greps: `_learningCubit.close()` 1, `_learningCubit.follow` 1, `spellLearningLine` 1 in `world_map.dart`; `D-29` 3 in the travel test; `isSpellResearchQuest` 1 and `spellLearningLine` 1 in `character_marker_layer.dart`; no `'Ricercando…` / `'Imparando` literal under `lib/screens`; no `CircularProgressIndicator` in the layer.
- Analyzer `47 issues found`, `ANALYZE_GATE_OK`.
- Full suite: `+5146: All tests passed!` (baseline 5138 + 8).

## Deviations from Plan

1. **[Simplification] Overlay label without a second lane lookup.** The plan asked for `_stateLabelOf(selected, quest, current, learningRemaining)` fed by a `BlocSelector` on the character's current lane. `_followLane` (WR-01) already sets `_selectedLane` to the current lane of the same quest at every `characterUpdated` (and closes the sheet otherwise), so the followed lane IS the current one: `_stateLabelOf(lane, quest, learningRemaining)` reads it directly. The in-session case («the overlay turns to the learning line when the part changes in session») proves it. The overlay tree was split into `_buildQuestOverlay` (quest list + learning selector) and `_buildQuestInfoOverlay` (injuries selector + overlay) to keep the nesting shallow; `onAbandon` still reads `_selectedLane?.isWaitingForParty`.
2. **[Test timing] Two pumps after a learning state.** The rebuild case of the pawn needed `pump()` twice after `learningStates.add(...)` (the pattern of the prison cases of the same file); added in the GREEN commit, no assertion changed.
3. Boy Scout: the prison / acceptance selectors moved, with the two new ones, into `_buildIdlePawnInputs` (as the plan asked).

## Notes for 23-13 / 23-14

- On a real BE only the school types change label until 23-14 selects `learningSpell` on the lane and `prizes { spellDraw }` on the board quest; then the `study` draw and the learning line come alive with no further code.

## Threat Flags

None: no new network surface; the countdown is display only and the lane is freed by the BE (T-23-45); `_learningCubit.close()` in `dispose` (T-23-46).

## Self-Check: PASSED

- Commits 5d4c0c72, b3824297, 33248277, 34df28ed present in `git log`; the four modified files exist.
