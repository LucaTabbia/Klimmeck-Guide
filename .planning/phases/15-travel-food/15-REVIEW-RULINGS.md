---
phase: 15-travel-food
ruled: 2026-11-05T21:50:00Z
source: 15-REVIEW.md (0 critical, 1 warning, 2 info) + 15-VERIFICATION.md (human_needed, 0 gaps, 3 deferred)
rulings:
  fix: 2
  not_needed: 1
  deferred: 0
---

# Review rulings — Phase 15 Travel Food (orchestrator, 2026-11-05)

Facts checked on the code before ruling: `board.dart` `_travelPreviewSheet` calls `cubit.load(...)` only inside `BlocProvider.create`, so a sheet opened on a quest that is not yet acceptable keeps the cubit `Idle` for its whole life even when `viewer` changes (the keyed subtree is rebuilt with the new `viewer`, but `create` does not run again); `QuestTravelPreviewCubit.refresh()` returns early while the ids are unset. The scenario of WR-01 is reachable (channel points arriving through the subscription while a hunt sheet is open with `insufficientPoints`).

| ID | Severity | Ruling | Direction for the fixer |
|----|----------|--------|-------------------------|
| WR-01 | warning | **FIX** | Make the per-sheet preview follow acceptability, not only the opening. Direction: keep the policy pure (`needsTravelPreview` unchanged); in `board.dart` make the preview subtree react to the `viewer` it receives — a small private `StatefulWidget` (e.g. `_QuestTravelPreviewLoader(viewer, selected, child)`) whose `initState`/`didUpdateWidget` calls `context.read<QuestTravelPreviewCubit>().load(characterId: viewer.characterId, questId: selected.id)` when `needsTravelPreview(selected, viewer)` is true and the cubit state is `QuestTravelPreviewIdle` (never twice: a loaded/loading/failed cubit is left alone; no call from `build`). `refresh()` stays a no-op before `load()` (the loader covers the D-05 case because the policy is true whenever a swipe was possible). Do NOT blank a loaded preview when the quest stops being acceptable (the stale line is the milder case and the swipe is already gated by `canAccept`). RED first in `board_acceptance_test.dart`: «a sheet opened before the quest is acceptable asks the travel preview once it becomes acceptable (D-04)» — pump a hunt with `insufficientPoints` (`verifyNever(previewQuest)`), then make the viewer acceptable (emit the new points/character state the existing tests use), `await tester.pump()`, expect `previewQuest` called exactly once and the «Viaggio» line visible; a second RED pins that an already loaded cubit is not reloaded when the viewer changes again (`called(1)` after two viewer emissions). Keep the Board free of networking (cubit only) and the loader widget private to `board.dart`. |
| IN-01 | info | **FIX** | Centralise the two «no food» copies next to `noLifeLostText` in `lib/models/travel/travel_cost_text.dart` as two named constants (the sheet's «nessuno» and the quest line's «nessun cibo» are deliberately different per surface, CONTEXT «Claude's discretion»): e.g. `noFoodSheetText = 'nessuno'`, `noFoodLineText = 'nessun cibo'`; `travel_confirmation_sheet.dart` and `quest_travel_line.dart` import them and drop their private constants. Refactor commit, no behaviour change; the existing tests pinned on the literals stay green (run them). |
| IN-02 | info | **NOT_NEEDED** | The reflow of untouched members in `board.dart` and `character_marker_layer.dart` is the accepted consequence of the repo rule «`dart format` only on touched files» applied to two files that were not formatter-clean (15-REPO-RULES §Format: «a touched file that reflows untouched members under `dart format` is accepted and noted in the SUMMARY»); both SUMMARY files record it. Nothing to do. |

Verifier notes: 0 gaps; the 3 deferred items belong to the gated plans 15-08/15-09 (BE merge) and are not rulings.
