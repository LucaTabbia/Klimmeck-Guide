---
phase: 15-travel-food
plan: 07
subsystem: board
tags: [flutter, dart, board, travel, food, cubit, quest-sheet]

requires:
  - phase: 15-travel-food
    provides: TravelRepository.previewQuest + QuestAcceptanceFailure.starving (15-03), QuestInfoSheet(travelPreview:) + travelLineKey (15-06)
provides:
  - per-sheet QuestTravelPreviewCubit (idle → loading → loaded(preview?) / failed, refresh, request token, SafeEmit)
  - pure policy needsTravelPreview(Quest, QuestViewer) = acceptable AND standard lane
  - one RepositoryProvider<TravelRepository> in AuthenticatedShell, read by TravelCubit and by the Board
  - Board wiring: request on open, «Viaggio» line, canTear false when starving, refresh on the starving acceptance refusal
affects: [15-08, 15-09]

tech-stack:
  added: []
  patterns:
    - "Per-sheet cubit provided inside the Board's keyed sheet subtree (ValueKey('board-sheet-<id>')): it lives exactly as long as the opened sheet"
    - "Swipe gate on a quote: canTear = canAccept && preview?.arrivesAlive != false (resist + haptic), isEnabled stays the in-flight flag"

key-files:
  created:
    - lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit.dart
    - lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_state.dart
    - test/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit_test.dart
  modified:
    - lib/models/quest/board_policy.dart
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/tabs/board/board.dart
    - test/models/quest/board_policy_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/mainScreen/tabs/board/board_test.dart
    - test/screens/mainScreen/tabs/board/board_acceptance_test.dart

key-decisions:
  - "The Board's preview subtree is extracted in _travelPreviewSheet(viewer, selected) and the paper in _tearableSheet(viewer, selected, {travelPreview}) to keep the AnimatedBuilder shallow (Clean Code; plan put the BlocProvider inline)"
  - "The starving refresh listener sits inside the sheet subtree and filters on questId == selected.id; the Board-level _onAcceptanceOutcome keeps recomposing on every QuestAcceptanceFailed (D-05)"

patterns-established:
  - "QuestTravelPreviewCubit(TravelRepository) .load({characterId, questId}) / .refresh(); states QuestTravelPreviewIdle/Loading/Loaded(preview?)/Failed(failure)"

requirements-completed: []  # mark-complete forbidden here; FOOD-02/03 advanced, traceability in 15-09

duration: 20min
completed: 2026-11-05
---

# Phase 15 Plan 07: The Board half of the quest food cost Summary

**Opening an acceptable standard-lane quest on the Board now asks the BE `questTravelPreview` once for the session character through a per-sheet `QuestTravelPreviewCubit`; the answer feeds the «Viaggio» line of `QuestInfoSheet`, a starving answer makes the paper resist (`canTear: false`, light haptic, no `acceptQuest`), a `TRAVEL_STARVING` acceptance refusal recomposes the paper and refreshes that sheet's preview, and the session owns one `TravelRepository` shared by `TravelCubit` and the Board.**

## Performance

- Duration: ~20 min
- Tasks: 3/3
- Files: 2 lib created, 3 lib modified, 1 test created, 4 tests modified

## Accomplishments

- `quest_travel_preview_state.dart` (`part of`): `sealed class QuestTravelPreviewState extends Equatable`; `final class QuestTravelPreviewIdle`, `QuestTravelPreviewLoading` (props `[]`), `QuestTravelPreviewLoaded(this.preview)` (`final TravelPreview? preview`), `QuestTravelPreviewFailed(this.failure)` (`final TravelFailure failure`).
- `quest_travel_preview_cubit.dart`: `class QuestTravelPreviewCubit extends Cubit<QuestTravelPreviewState> with SafeEmit<QuestTravelPreviewState>`; `QuestTravelPreviewCubit(TravelRepository)`; `Future<void> load({required String characterId, required String questId})`; `Future<void> refresh()` (no-op before `load`); `_fetch()` with `_requestToken` (superseded answers dropped), `TravelException` → `Failed(error.failure)`, any other error → `Failed(TravelFailure.unknown)`. No Flutter widget import, no `BuildContext`.
- `board_policy.dart`: imports `quest_availability.dart`; `bool needsTravelPreview(Quest quest, QuestViewer viewer)` = type non-null AND `laneOf(type) == QuestLane.standard` AND `standingOf(quest, viewer).canAccept`.
- `authenticated_shell.dart`: `RepositoryProvider<TravelRepository>(create: (context) => TravelRepository(graphQl: graphQl, permissionGate: context.read<NotificationPermissionGate>()))` right before `BlocProvider<TravelCubit>`, which now builds `TravelCubit(context.read<TravelRepository>(), clock: …)` (lazy provider, one instance).
- `board.dart`: the keyed `SingleChildScrollView` child is `_travelPreviewSheet(viewer, selected)` = `BlocProvider<QuestTravelPreviewCubit>` (create: `QuestTravelPreviewCubit(context.read<TravelRepository>())`, `load(characterId: viewer.characterId, questId: selected.id)` only when `needsTravelPreview(selected, viewer)`) → `BlocListener<QuestAcceptanceCubit, QuestAcceptanceState>` (`listenWhen`: `QuestAcceptanceFailed` with `QuestAcceptanceFailure.starving` and `questId == selected.id` → `refresh()`) → `BlocBuilder<QuestTravelPreviewCubit, QuestTravelPreviewState>` → `_tearableSheet(viewer, selected, travelPreview: Loaded ? preview : null)`. `_tearableSheet` holds the former `BlocSelector` + `TearablePaper` with `canTear: standingOf(selected, viewer).canAccept && travelPreview?.arrivesAlive != false`, `isEnabled: isIdle` unchanged, `QuestInfoSheet(quest: selected, viewer: viewer, travelPreview: travelPreview)`. `_onAcceptanceOutcome` untouched (it already recomposes on every `QuestAcceptanceFailed`).

## Task Commits

1. Task 1 RED `a0a753b` test(board): expect the per-sheet travel preview cubit; GREEN `297b033` feat(board): add the per-sheet travel preview cubit
2. Task 2 RED `5659a44` test(travel): expect a shared travel repository in the session; GREEN `5fd2c44` feat(travel): provide one travel repository to the session
3. Task 3 RED `188bcac` test(board): expect the travel preview on the quest sheet; GREEN `88fae45` feat(board): show the travel cost on the quest sheet

## RED failures observed

- Task 1: compilation failure — `Error when reading 'lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit.dart': No such file or directory`, `'QuestTravelPreviewCubit' isn't a type`; `board_policy_test.dart:161:9: Error: Method not found: 'needsTravelPreview'`.
- Task 2: `provides one travel repository for the travel flows (D-08) [E]` — `ProviderNotFoundException: Could not find the correct Provider<TravelRepository> above this BlocBuilder<SplashCubit, …>`. The Board harness changes (provider + `previewQuest → null` stub in `board_test.dart` and `board_acceptance_test.dart`) were green at once (harness only, Wave 0 D-12): `+59 -1` with the only failure the shell test.
- Task 3: 5 of the 8 new tests red (`asks its travel preview once`, `the travel line appears`, `a starving preview makes the paper resist`, `a starving acceptance refusal … refreshes`, `another refusal recomposes without refreshing`). Green at once, by nature negative assertions that hold before the wiring: `an acceptable story asks no travel preview (D-04)`, `a quest the viewer cannot accept asks no travel preview (D-04)`, `a failed preview shows no line and keeps the swipe (D-04)`.

## Listener ordering (research A2)

On `QuestAcceptanceFailed(h-1, starving)` both the Board-level `BlocListener` (`_onAcceptanceOutcome` → `_tearKey.currentState?.recompose()`) and the sheet-subtree listener (`refresh()`) fire on the same state emission; ordering between them does not matter: the recompose acts on the `TearablePaperState` (same `GlobalKey`, survives the `BlocBuilder` rebuild) and the refresh only swaps the preview → line + `canTear`. Observed in the test: `isTorn` false after one second, `previewQuest` called 2 times, `refreshQuests` only the initial Board call (no board reread).

## Tests added

- `test/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit_test.dart` (9 tests, D-04/D-05/D-08): helpers `stubPreview()`, `stubAnswers(List<Future<TravelPreview?> Function()>)`, `loadQuest(cubit)`; fixtures `preview` (food [Razione ×1]) and `starving` (`arrivesAlive: false`, hpLost 20910).
- `test/models/quest/board_policy_test.dart` group `'needsTravelPreview'` (3 tests, D-04); imports `quest_availability.dart`.
- `test/screens/auth/authenticated_shell_test.dart`: «provides one travel repository for the travel flows (D-08)»; imports `travel_repository.dart`.
- `test/screens/mainScreen/tabs/board/board_test.dart` and `board_acceptance_test.dart`: `late MockTravelRepository travelRepository;`, default stub `previewQuest(any, any) → null` in `setUp`, `RepositoryProvider<TravelRepository>.value(value: travelRepository)` first in the `MultiBlocProvider` list.
- `board_acceptance_test.dart` group `'travel preview (FOOD-02)'` (8 tests, D-04/D-05/D-08); local helpers `stubTravelPreview(TravelPreview?)`, `verifyNoTravelPreview()`, `travelLine(tester)` (the `Text` at `QuestInfoSheet.travelLineKey`). The eligible story fixture is `buildQuest(id: 's-paladin', type: 'story', minTitle: 'paladin', requiredPoints: 100)` (character title paladin, 1200 points).

## Verification

- Task 1: `flutter test test/screens/mainScreen/tabs/board/questTravelPreviewCubit test/models/quest` → `+161: All tests passed!`.
- Task 2: `flutter test test/screens/auth test/screens/mainScreen/tabs/board test/screens/mainScreen/main_screen_test.dart` → `+226: All tests passed!`.
- Task 3: `flutter test test/screens/mainScreen/tabs/board test/screens/mainScreen test/shared/components/popup` → `+1059: All tests passed!`.
- Plan verification: `flutter test test/screens/auth test/screens/mainScreen test/models/quest test/shared/components/popup` → `+1373: All tests passed!`.
- Full suite (orchestrator instruction, last plan before the park): `flutter test` → `01:15 +3308: All tests passed!`.
- Analyzer last line `50 issues found.` (all info), 0 error / 0 warning, `ANALYZE_GATE_OK` after each code task.
- Acceptance greps: `class QuestTravelPreviewCubit` 1, `_requestToken` 5, `SafeEmit` ≥ 1, `final class QuestTravelPreviewLoaded` 1, `final class QuestTravelPreviewFailed` 1, Flutter widget imports / `BuildContext` in the cubit folder none, `bool needsTravelPreview` 1, `D-0[458])` in the cubit test 9, `D-04)` in board_policy_test 3; shell `RepositoryProvider<TravelRepository>(` 1, `TravelRepository(` 1, `context.read<TravelRepository>()` 1, `RepositoryProvider<TravelRepository>.value` 1 in each Board test, `D-08)` in the shell test 1; board.dart `BlocProvider<QuestTravelPreviewCubit>` 1, `needsTravelPreview(selected, viewer)` 1, `context.read<TravelRepository>()` 1, `travelPreview?.arrivesAlive != false` 1, `isEnabled: isIdle` 1, `QuestAcceptanceFailure.starving` 1, `refresh()` 1, `travelPreview: travelPreview` 1; `D-0[458]` / `D-0[458])` in board_acceptance_test 8 / 8.
- Trailer check `0` after every commit; subjects ≤ 72 bytes (54, 51, 62, 58, 57, 52).

## Deviations from Plan

- **Structure (Clean Code, no behaviour change):** the plan put the `BlocProvider<QuestTravelPreviewCubit>` tree inline as the `child:` of the keyed `SingleChildScrollView`; after `dart format` it nested twelve levels deep, so it lives in `Widget _travelPreviewSheet(QuestViewer viewer, Quest selected)` (doc comment on the per-sheet lifetime and the D-05 refresh) and the scroll view calls it. All plan greps still match once.
- **Format reflow:** `dart format lib/screens/mainScreen/tabs/board/board.dart` reflowed two untouched members (the `Tween<double>(…).evaluate(` line in `_buildQuestInfoSheet` and the `_accept` arrow body): accepted per REPO-RULES (board.dart was not formatter-clean).
- **Bookkeeping numbers:** `7/9` and `Plan: 7 of 9` per the orchestrator (the plan's `07/9` is wrong). The Wave 0 checklist items of VALIDATION are ticked now (all files exist and pass); the «Wave 0 covers all MISSING references» sign-off item is left to the gate plan.

## Known Stubs

None. With the BE Phase 14 not merged, the real `questTravelPreview` answer is exercised only in mocks; the schema gate (15-08) and the device E2E (15-09) cover it after the merge.

## Threat Flags

None. T-15-18 (only `viewer.characterId` sent — pinned by «asks its travel preview once (D-04, D-08)»), T-15-19 (policy + per-sheet scope + `_requestToken` + `SafeEmit` — pinned), T-15-20 (`canTear` gate + BE refusal recomposed and refreshed — pinned), T-15-21 accepted (failed preview shows nothing, swipe as today — pinned).

## Self-Check: PASSED
