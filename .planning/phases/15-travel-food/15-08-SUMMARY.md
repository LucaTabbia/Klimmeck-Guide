---
phase: 15-travel-food
plan: 08
subsystem: graphql
tags: [flutter, graphql, schema-gate, validation, travel, food]

requires:
  - phase: 15-travel-food
    provides: TravelPreviewFragment + GetQuestTravelPreview (15-01, 15-02), travelStarvingCode (15-03), Board wiring (15-07)
  - phase: BE-14-viaggio-e-cibo
    provides: merged SDL (TravelFoodItem, TravelPreview food/hpLost/arrivesAlive, questTravelPreview) and BACKEND-NOTES codes table
provides:
  - contract names proven on the merged BE origin/develop b492a46 (no code change)
  - schema check 45/45 OK against the merged SDL
  - completed 15-VALIDATION.md (rows 15-01-01..15-08-02 green, wave_0_complete true)
affects: [15-09]

tech-stack:
  added: []
  patterns: []

key-files:
  created:
    - .planning/phases/15-travel-food/15-08-SUMMARY.md
  modified:
    - .planning/phases/15-travel-food/15-VALIDATION.md

key-decisions:
  - "Names confirmed on the merged BE: no alignment commit, no code change"

requirements-completed: []

duration: 10min
completed: 2026-11-06
---

# Phase 15 Plan 08: Schema gate against the merged BE Phase 14 Summary

**Every FE contract name (TravelFoodItem, TravelPreview.food/hpLost/arrivesAlive, nullable questTravelPreview, TRAVEL_STARVING) confirmed on BE origin/develop b492a46; 45/45 documents validate, full suite 3310 green, analyzer 0 error / 0 warning.**

## Performance

- Duration: ~10 min
- Completed: 2026-11-06
- Tasks: 2 (Task 1 without commit: names confirmed)
- Files modified: 1 (+ this SUMMARY and the bookkeeping files)

## Task 1 — BE gate and contract proof

BE ref: `git -C <BE> fetch -q origin develop` succeeded (FETCH_OK, no SSH failure). `origin/develop` = `b492a46`:

```
b492a46 Merge pull request #23 from LucaTabbia/feat/14-viaggio-e-cibo
3163279 Merge pull request #22 from LucaTabbia/docs/13.1-uat-device
efb3bf9 docs(state): record the phase 14 PR number
ee42c69 docs(phase-14): complete phase execution
e1e048b docs(phase-14): add the security audit report
```

Gate: `grep -c "TravelFoodItem"` on the merged schema = `2` (≥ 1, gate open).

```
type TravelFoodItem {
  item: LootItem!
  quantity: Int!
}
type TravelPreview {
  arrivesAlive: Boolean!
  distance: Float!
  duration: Float!
  food: [TravelFoodItem!]!
  hpLost: Int!
  road: TravelPath!
}
548:  questTravelPreview(request: AcceptQuestRequest!): TravelPreview
input AcceptQuestRequest {
  id: String!
  questId: String!
}
LootItem: 5:  id: ID!   7:  name: String
```

`git diff --stat 698ae82 origin/develop -- src/schema.gql`: 9 insertions = the 8 expected SDL lines + 1 blank line separating `TravelFoodItem` from `TravelPath`.

BE handoff `.planning/phases/14-viaggio-e-cibo/BACKEND-NOTES.md` §2 Codici:

```
| `TRAVEL_STARVING` | `Non hai cibo a sufficienza per il viaggio` | `startTravel`, `acceptQuest` (corsia standard con viaggio reale su strada) | quando `currentLifePoints − hpLost < 1` sul cibo del momento (D-11) | ... |
```

Other codes listed for `questTravelPreview`: `NOT_FOUND`, `FORBIDDEN`, `QUEST_NOT_IN_CITY`, `QUEST_NOT_ACCEPTABLE`, `BAD_USER_INPUT`, `UNAUTHENTICATED` — all pre-existing codes, no new code besides `TRAVEL_STARVING`; `travelPreview` never answers `TRAVEL_STARVING`. §9: a rejected nullable query answers `data: { questTravelPreview: null }` + `errors` (FE `previewQuestTravel` rethrows the coded error, consistent).

Comparison with the FE names: all identical → **names confirmed**, no RED/GREEN alignment, no code commit.

Schema check:

```
dumped 45 documents
validate_documents.js: exit 0, 45 × OK, grep -vc OK = 0
OK GetQuestTravelPreview.graphql
OK GetTravelPreview.graphql
```

`flutter test test/graphql test/tool test/models test/repository` → `+1515: All tests passed!`

## Task 2 — Full gates

- Full suite: `01:16 +3310: All tests passed!` (same as the post-fixer baseline).
- Analyzer: `50 issues found.` → `ANALYZE_GATE_OK` (0 error, 0 warning; 50 info = baseline).
- Format: 12 Dart files added on the branch (`develop...HEAD -- lib test tool`), no `UNFORMATTED` line.
- Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` = `0`.
- Sanity greps (each printed nothing, exit 1):
  - `grep -rn "package:flutter/" lib/models` → empty
  - `grep -rci "nessun costo" lib docs/rules | grep -v ":0$"` → empty (no stale note in docs/rules/ui-ux.md; no doc fix needed)
  - `grep -rnE "hpLost *[-+*/]|[-+*/] *hpLost|currentLifePoints" <food surfaces>` → empty
  - `grep -rn "isEnabled: false" lib/screens/mainScreen/tabs/board/board.dart` → empty
  - `grep -n "description" lib/graphql/fragments/travel_preview_fragment.dart` → empty
  - `grep -rln "package:flutter/material.dart\|package:flutter/widgets.dart" <questTravelPreviewCubit> <travelCubit>` → empty
- `15-VALIDATION.md`: rows 15-08-01/02 → `✅ green` (15-01..15-07 were already green, 18 rows); `grep -cE "^\| 15-0[1-8]-0[1-3] .*✅ green"` = 20; Wave 0 list already all `[x]`; sign-off «Wave 0 covers all MISSING references» ticked; `wave_0_complete: true`; gate line added above **Approval** (left `pending` for 15-09); 15-09 rows stay `⬜ pending`.

## Task Commits

1. Task 1: no commit (names confirmed)
2. Task 2: `7c53635` docs(phase-15): validate the travel food documents and gates

## Deviations from Plan

None - plan executed exactly as written. Notes:
- `grep -c "nyquist_compliant: true" 15-VALIDATION.md` prints `2`, not `1`: the frontmatter line plus the pre-existing sign-off checklist item «`nyquist_compliant: true` set in frontmatter» (written at planning time). Not changed.
- Bookkeeping uses `8/9` and `Plan: 8 of 9` (orchestrator format) instead of the plan's `08/9`.

## Known Stubs

None.

## Self-Check: PASSED

- 15-VALIDATION.md modified and committed in `7c53635` (FOUND)
- 15-08-SUMMARY.md written
