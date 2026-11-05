---
phase: 15-travel-food
fixed: 2026-11-05T21:50:30Z
source: 15-REVIEW.md
review_path: .planning/phases/15-travel-food/15-REVIEW.md
rulings_path: .planning/phases/15-travel-food/15-REVIEW-RULINGS.md
iteration: 1
fix_scope: all
findings_total: 3
findings_in_scope: 3
fixed_count: 2
skipped_count: 0
not_needed_count: 1
deferred_count: 0
status: all_fixed
---

# Phase 15: Code Review Fix Report

**Fixed at:** 2026-11-05T21:50:30Z
**Source review:** `.planning/phases/15-travel-food/15-REVIEW.md`
**Rulings:** `.planning/phases/15-travel-food/15-REVIEW-RULINGS.md`
**Iteration:** 1
**Branch:** `feat/15-travel-food` (no push). Start `f2fac26`, final code HEAD `b0e990e`.

**Summary:**
- Findings in the review: 3 (0 critical, 1 warning, 2 info)
- Fixed: 2 (WR-01, IN-01)
- Not needed: 1 (IN-02), recorded with the orchestrator's reason, no code change
- Skipped: 0. Deferred: 0.

WR-01 went Red → Green (`test(board)` then `fix(board)`). IN-01 is a structural refactor with no behaviour change (`refactor(travel)`), covered by the existing tests pinned on the literals. Commits use plain `git` with explicit paths, carry no trailers and rewrite no history.

These decisions still hold:
- Rule 2: nothing new loads visibly; the late preview request adds no spinner (the line appears only when the answer arrives, D-04).
- The backend stays the source of truth (FOOD-04): the FE computes no food or HP number; the policy `needsTravelPreview` is unchanged and pure.
- Registry stays at 45 documents; no GraphQL document changed. No new dependency, Cloudinary asset id or environment variable.
- The Board stays free of networking: the new loader only calls `QuestTravelPreviewCubit.load`.

## Gate finale

| Check | Result |
|-------|--------|
| `flutter analyze` (repo-wide) | **50 issues found, all info, 0 errors / 0 warnings**: unchanged baseline |
| `flutter test` (full suite, foreground) | **`01:21 +3310: All tests passed!`** |
| `dart format` on every touched file | each file formatted on its own, 0 changed |
| Trailers on `f2fac26..HEAD` (`co-authored-by` / `generated with`) | 0 |
| `git status --short` | empty before the report commit |

## Per-finding table

| ID | Severity | Outcome | Commits | Tests added / changed |
|----|----------|---------|---------|-----------------------|
| WR-01 | Warning | fixed | `2e6a7a1` → `9754c8d` | `board_acceptance_test.dart` group «a sheet opened before the quest is acceptable»: «asks the travel preview once the quest becomes acceptable (D-04)», «a loaded preview is not asked again when the viewer changes (D-04)»; `pumpBoard` gains a `characterStates` stream |
| IN-01 | Info | fixed (refactor) | — → `b0e990e` | none: `quest_travel_line_test.dart`, `travel_cost_text_test.dart`, `travel_confirmation_sheet_test.dart` stay green on the literals |
| IN-02 | Info | not_needed | — | Orchestrator ruling: the reflow of untouched members in `board.dart` and `character_marker_layer.dart` is the accepted consequence of «`dart format` only on touched files» (15-REPO-RULES §Format) on two files that were not formatter-clean; both SUMMARY files record it |

## Details

### WR-01: the per-sheet travel preview follows acceptability

`board.dart` no longer calls `load` inside `BlocProvider.create`. A private `_QuestTravelPreviewLoader` (StatefulWidget, below the provider, above the starving-refusal listener) calls `QuestTravelPreviewCubit.load(characterId, questId)` from `initState` and `didUpdateWidget` when `needsTravelPreview(selected, viewer)` is true **and** the cubit is still `QuestTravelPreviewIdle`. A loading, loaded or failed cubit is left alone (no double request, nothing from `build`); a loaded preview is not blanked when the quest stops being acceptable (ruling). `refresh()` remains a no-op before `load()`: the D-05 case is covered because the loader has always loaded by the time a swipe was possible.

Deviation from the ruling's RED text: the ruling suggested a hunt with `insufficientPoints`, but `questAvailabilityOf` never returns `insufficientPoints` on the standard lane (`lane != QuestLane.standard` guard in `quest_availability.dart`), so a hunt cannot be in that state. The reachable trigger on the standard lane is the lane freeing up (`laneBusy` → available, a `characterUpdated` that clears `pendingQuest`): the RED tests open a hunt with the standard lane busy, `verifyNever(previewQuest)`, then emit the character with the lane free and expect exactly one `previewQuest('c-1', 'h-2')` and the «Viaggio» line; the second test emits free → busy → free and expects `called(1)`. RED failure: «No matching calls (actually, no calls at all)» on both.

### IN-01: the «no food» copies live in `travel_cost_text.dart`

`noFoodSheetText = 'nessuno'` (confirmation sheet «Cibo» row) and `noFoodLineText = 'nessun cibo'` (quest «Viaggio» line) sit next to `noLifeLostText`; `travel_confirmation_sheet.dart` and `quest_travel_line.dart` drop their private constants. The two strings stay deliberately different per surface (CONTEXT «Claude's discretion»).

## Notes for the device UAT

- **Changed behaviour (WR-01):** with a combat/service sheet open on the Board while the standard lane is busy (or the quest is otherwise not acceptable), when the lane frees and the swipe becomes available the «Viaggio» line now appears without closing and reopening the sheet (one `questTravelPreview` request). Worth a step in `15-HUMAN-UAT.md`: open a hunt sheet with a pending quest, free the lane at the DB (or let it resolve), watch the line appear; if the preview says starving the swipe resists.
- Once the line is shown it stays until the sheet closes, even if the quest stops being acceptable (e.g. last slot taken); the swipe is gated by `canAccept` anyway.
- IN-01 changes no visible text: «nessuno» on the confirmation sheet and «nessun cibo» on the quest line, as before.

---

_Fixed: 2026-11-05T21:50:30Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
