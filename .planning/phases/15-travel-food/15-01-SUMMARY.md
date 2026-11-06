---
phase: 15-travel-food
plan: 01
subsystem: models
tags: [flutter, dart, graphql, equatable, travel, food]

requires:
  - phase: 07-travel
    provides: TravelPreview, GetTravelPreview, travel fixtures
provides:
  - TravelFoodItem with tolerant tryFromJson / listFrom (whitelist {id, name})
  - TravelPreview.food / hpLost / arrivesAlive with old-BE defaults ([] / 0 / true)
  - TravelPreviewFragment shared by GetTravelPreview (and by 15-02 GetQuestTravelPreview)
  - shared quantityLine helper («Nx nome») reused by recommended loot, enemy lines and food
  - pure texts starvingPhrase / noLifeLostText / foodText / lifeText (U+2212)
  - fixtures travelFoodItemJson + food/hpLost/arrivesAlive params of travelPreviewJson
affects: [15-02, 15-03, 15-04, 15-05, 15-06, 15-07, 15-08]

tech-stack:
  added: []
  patterns:
    - "Tolerant list parsing with per-entry drop and whitelisted nested fields"
    - "Shared GraphQL fragment interpolated in a non-raw const document (\\$request)"

key-files:
  created:
    - lib/models/travel/travel_food_item.dart
    - lib/models/travel/travel_cost_text.dart
    - lib/models/quantity_line.dart
    - lib/graphql/fragments/travel_preview_fragment.dart
    - test/models/travel/travel_food_item_test.dart
    - test/models/travel/travel_cost_text_test.dart
    - test/models/quantity_line_test.dart
  modified:
    - lib/models/travel/travel_preview.dart
    - lib/models/quest/quest_sheet_details.dart
    - lib/models/quest/quest_enemy.dart
    - lib/graphql/fragments/fragments.dart
    - lib/graphql/queries/travel_queries.dart
    - test/models/travel/travel_preview_test.dart
    - test/graphql/travel_documents_test.dart
    - test/helpers/fixtures/travel_fixtures.dart

key-decisions:
  - "GetTravelPreview selection moved from 15-02 to 15-01: REPO-RULES require the three fields in the document in the same commit as the model (285bebd)"
  - "TravelFoodItem passes only {id, name} to LootItem.fromJson so an unknown effect/rarity can never drop the preview"

patterns-established:
  - "quantityLine(int, String) is the single «Nx nome» formatter under lib/models/"

requirements-completed: []  # mark-complete forbidden here; FOOD-01, FOOD-02, FOOD-04 advanced, traceability in 15-09

duration: 12min
completed: 2026-11-05
---

# Phase 15 Plan 01: Travel food models Summary

**Tolerant `TravelFoodItem`, `TravelPreview.food/hpLost/arrivesAlive` with old-BE defaults, the shared `TravelPreviewFragment` in `GetTravelPreview` (same commit as the model), one `quantityLine` helper and the pure `foodText`/`lifeText`/`starvingPhrase` texts.**

## Performance

- **Duration:** ~12 min
- **Started:** 2026-11-05T20:50:00Z
- **Completed:** 2026-11-05T21:03:04Z
- **Tasks:** 3 (6 commits, TDD pairs)
- **Files modified:** 15 (7 created, 8 modified)

## Accomplishments

- `TravelFoodItem { item: LootItem, quantity: int }` in `lib/models/travel/travel_food_item.dart`: `static TravelFoodItem? tryFromJson(Object?)`, `static List<TravelFoodItem> listFrom(Object?)` (unmodifiable, BE order, malformed entries dropped), `String get name`, `toJson()`.
- `TravelPreview` gains `food` (default `const []`), `hpLost` (default `0`), `arrivesAlive` (default `true`); `distance/duration/road` stay strict; `hpLost` non-num → 0, `arrivesAlive` non-bool → true; included in `toJson` and `props`.
- `TravelPreviewFragment.fields` (`distance duration road { coordinates distance } food { quantity item { id name } } hpLost arrivesAlive`), exported from the barrel; `TravelQueries.getTravelPreview` is now a non-raw const interpolating it.
- `quantityLine(int quantity, String name)` in `lib/models/quantity_line.dart`, now used by `recommendedLootLines` (quest_sheet_details) and `enemyLinesOf` (quest_enemy; the single-enemy bare-name rule untouched).
- `lib/models/travel/travel_cost_text.dart`: `starvingPhrase`, `noLifeLostText`, `foodText(List<TravelFoodItem>, {required String empty})`, `lifeText(TravelPreview)` («−N HP» with U+2212, «nessuna perdita», or the user phrase when `!arrivesAlive`).

## Task Commits

1. **Task 1: TravelFoodItem + fixtures** — `a962772` (test), `dd56314` (feat)
2. **Task 2: TravelPreview fields + fragment + GetTravelPreview** — `622dfbc` (test), `285bebd` (feat; model and document in the same commit)
3. **Task 3: quantityLine + travel cost texts** — `c80ffd3` (test), `ab63422` (feat)

## RED failures observed

- Task 1: compile failure — `Error: Undefined name 'TravelFoodItem'` (file `travel_food_item.dart` missing).
- Task 2: compile failure — `The getter 'food' / 'hpLost' / 'arrivesAlive' isn't defined for the type 'TravelPreview'`; documents test assertion failure — `Expected: contains '... food { quantity item { id name } } hpLost arrivesAlive }'`, `Actual: '... road { coordinates distance } } }'`.
- Task 3: compile failure — `Error when reading 'lib/models/quantity_line.dart': No such file or directory`, `Method not found: 'quantityLine'`.
- No test was green at its first run.

## Verification

- `flutter test test/models test/graphql test/tool test/repository/services/graphql/graphql_travel_test.dart test/screens/mainScreen/travelCubit test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart test/shared/components/popup/quest_info_sheet_test.dart` → `+861: All tests passed!`
- Per task: Task 1 `test/models/travel` +67; Task 2 verify set +289; Task 3 `test/models` + quest_info_sheet +645.
- Analyzer: `50 issues found.` (all info), 0 error / 0 warning → `ANALYZE_GATE_OK` after each task.
- `dart format` run on each touched file one by one: no file changed except `test/models/travel/travel_preview_test.dart` (reflow of the new tests only).
- Note: the app now selects `food`/`hpLost`/`arrivesAlive`, which the BE gains only with its Phase 14 (not merged yet); the schema proof is 15-08 (gated).

## Deviations from Plan

None - plan executed exactly as written. (Bookkeeping uses the orchestrator's `1/9` and `Plan: 1 of 9` instead of the plan's `01/9` / `Plan: 01 of 9`.)

## Known Stubs

None. `noLifeLostText` is provisional copy by design (D-02/D-06), not a stub.

## Self-Check: PASSED

- All 7 created files exist; commits a962772, dd56314, 622dfbc, 285bebd, c80ffd3, ab63422 present in `git log`.
