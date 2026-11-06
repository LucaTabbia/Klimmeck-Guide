---
phase: 15-travel-food
reviewed: 2026-11-05T21:43:00Z
depth: standard
files_reviewed: 30
files_reviewed_list:
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/fragments/travel_preview_fragment.dart
  - lib/graphql/queries/travel_queries.dart
  - lib/models/quantity_line.dart
  - lib/models/quest/board_policy.dart
  - lib/models/quest/quest_enemy.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest/quest_travel_line.dart
  - lib/models/travel/travel_cost_text.dart
  - lib/models/travel/travel_food_item.dart
  - lib/models/travel/travel_preview.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/travel_failure.dart
  - lib/repository/travel_repository.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/components/travel_outcome_listener.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_cubit.dart
  - lib/screens/mainScreen/tabs/board/questTravelPreviewCubit/quest_travel_preview_state.dart
  - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart
  - lib/screens/mainScreen/tabs/map/layers/travel_route_layer.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/travelCubit/travel_cubit.dart
  - lib/screens/mainScreen/travelCubit/travel_notice.dart
  - lib/screens/mainScreen/travelCubit/travel_state.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - tool/schema_check/schema_check_documents.dart
findings:
  critical: 0
  warning: 1
  info: 2
  total: 3
status: issues_found
---

# Phase 15: Code Review Report

**Reviewed:** 2026-11-05T21:55:00Z
**Depth:** standard
**Files Reviewed:** 30
**Status:** issues_found

## Summary

Plans 15-01..15-07 reviewed against 15-CONTEXT D-01..D-13 and the review checklist. The implementation is faithful to the contract and the amended decisions:

- Parsing is tolerant (`TravelFoodItem.listFrom` drops malformed entries, `TravelPreview` defaults food empty / hpLost 0 / arrivesAlive true), the nullable `questTravelPreview` is kept distinct from a failure (`containsKey` check, `null` vs `FormatException`), models are Flutter-free Equatable.
- One shared `quantityLine`; `starvingPhrase` / `foodText` / `lifeText` only print BE numbers (U+2212); no client food/HP arithmetic anywhere in `lib/`.
- `TravelCubit` requote runs under `_previewToken`, `cancel()` covers Requoting, a failed requote goes to `TravelFailed` (sheet closes, banner by code), `start()` is a no-op outside Confirming, `withEta` keeps the subclass. The outcome listener announces once on entry to Requoting without `reset()`; route layer, pawn layer and the narrowed camera refit are correct. All `switch` over `TravelState` are exhaustive.
- Classifiers read `extensions.code` only; `TRAVEL_STARVING` is a single constant mapped to both failures; both notices use `starvingPhrase`.
- `RepositoryProvider<TravelRepository>` gives one instance shared with `TravelCubit`; `QuestTravelPreviewCubit` lives in the keyed sheet subtree (closed with the sheet), token guards stale answers, `canTear: false` (not `isEnabled`) on a starving preview, no board reread on the starving refusal. `QuestInfoSheet` receives `TravelPreview?` only. No spinners, no chrome, no payload logging, no raw server text in the UI.

One real behavioural gap (WR-01) and two quality notes. Plans 15-08/15-09 (schema gate, device E2E, handoff) are gated on the BE merge and are deferred, not findings.

## Warnings

### WR-01: The per-sheet travel preview is requested once, at sheet creation, and never follows the quest becoming acceptable

**File:** `lib/screens/mainScreen/tabs/board/board.dart:277-288` (and `quest_travel_preview_cubit.dart:32-35`)
**Issue:** `needsTravelPreview(selected, viewer)` is evaluated only inside `BlocProvider.create`, i.e. once when the sheet opens. `canAccept` depends on live viewer data (`QuestAvailability.insufficientPoints`, `laneBusy`, `full`, `notAcceptable`). Scenario: the viewer opens a standard-lane sheet with too few channel points (or with the lane busy); the cubit stays `Idle` and no preview is requested. Points accrue (or the lane frees) while the sheet is open, `canAccept` flips to true, the swipe becomes available but there is no «Viaggio» line and no starving guard. If the character would starve, the user swipes, the BE refuses with `TRAVEL_STARVING`, and the `refresh()` introduced by D-05 is a silent no-op because `_characterId`/`_questId` were never set (`refresh()` returns early), so the line never appears even after the refusal. The inverse is milder: a loaded preview stays on screen after the quest stops being acceptable (e.g. last slot taken).
**Why it matters:** D-04 says the preview is requested when the sheet is open and the swipe would be available; the current code honours that only for the instant of opening. The user loses the cost information (FOOD-01/FOOD-02) exactly in a reachable flow, and the D-05 refresh does not recover it.
**Suggested fix:** Make the cubit follow acceptability, not just creation. For example, wrap the subtree in a `BlocListener`/`didUpdateWidget`-style trigger that calls `load(...)` when `needsTravelPreview` turns true while the cubit is `Idle`, and have the starving-refusal `refresh()` fall back to `load(characterId: viewer.characterId, questId: selected.id)` when the ids are unset (or pass the ids to `refresh`). Optionally feed `null` to the sheet when `!needsTravelPreview` so a stale line disappears.
RED test first (`board_acceptance_test.dart`): pump the board with a hunt quest that is `insufficientPoints` (stub `previewQuest` untouched, `verifyNever`), then emit a viewer with enough points and `await tester.pump()`; expect `previewQuest` called once and `travelLine` present. Second RED test (`quest_travel_preview_cubit_test.dart`): `refresh()` before any `load()` after a starving acceptance failure still requests the preview (or the Board passes the ids).

## Info

### IN-01: The «no food» copy lives in two private constants in two layers

**File:** `lib/models/quest/quest_travel_line.dart:14` and `lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart:50`
**Issue:** `'nessun cibo'` (quest line) and `'nessuno'` (sheet row) are private constants in different files, while the sibling copy `noLifeLostText` is public in `travel_cost_text.dart`. A widget owns a model-level phrase.
**Why it matters:** The copy is explicitly provisional (D-02, user review on device): the next copy tweak has to touch two layers, and the UI file carries a text constant that the rest of the family keeps in the pure helper file.
**Suggested fix:** Move both to `lib/models/travel/travel_cost_text.dart` (`noFoodRowText`, `noFoodLineText`) next to `noLifeLostText`; the pinned tests in `travel_cost_text_test.dart` already cover that file.

### IN-02: Unrelated formatter churn in touched files

**File:** `lib/screens/mainScreen/tabs/board/board.dart:40-44,246-252`, `lib/screens/mainScreen/tabs/map/layers/character_marker_layer.dart:124-190`
**Issue:** The format pass on the touched files rewrote several unrelated expressions (`_tearKey` declaration, `Tween` chain, `Marker`, `_labelOf`, `Transform.scale`, `childWhenDragging`) inside the feature commits, making the Phase 15 diff noisier to review.
**Why it matters:** Harmless at runtime and allowed by the Boy Scout rule for touched files, but it hides the few real changes (e.g. the `TravelRequoting` case in `_confirmingDestination`) in `git blame`/review.
**Suggested fix:** None required for this PR; prefer a separate `refactor`/`style` commit when a format pass changes lines outside the feature in future phases.

---

_Reviewed: 2026-11-05T21:55:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
