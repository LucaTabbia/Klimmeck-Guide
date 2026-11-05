---
phase: 15-travel-food
plan: 02
subsystem: graphql
tags: [flutter, dart, graphql, travel, food, quest]

requires:
  - phase: 15-travel-food
    provides: TravelPreviewFragment, TravelPreview.food/hpLost/arrivesAlive, travel fixtures (15-01)
provides:
  - GetQuestTravelPreview document (AcceptQuestRequest!, shared TravelPreviewFragment)
  - schema-check registry at 45 documents
  - KlimmeckGraphQl.previewQuestTravel(AcceptQuestRequest) -> Future<TravelPreview?>
affects: [15-03, 15-07, 15-08]

tech-stack:
  added: []
  patterns:
    - "Nullable query result: containsKey guard (missing -> FormatException) then null -> null, else strict parse"

key-files:
  created: []
  modified:
    - lib/graphql/queries/travel_queries.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/tool/schema_check_documents_test.dart
    - test/repository/services/graphql/graphql_travel_test.dart

key-decisions:
  - "A missing questTravelPreview key is a FormatException; an explicit null is the no-travel answer (D-01). The graphql client keeps the null key in result.data (observed: the «returns null…» test is green with the containsKey guard)"

patterns-established: []

requirements-completed: []  # mark-complete forbidden here; FOOD-02 advanced, traceability in 15-09

duration: 8min
completed: 2026-11-05
---

# Phase 15 Plan 02: Quest travel preview on the wire Summary

**`GetQuestTravelPreview($request: AcceptQuestRequest!)` reusing `TravelPreviewFragment`, registered as the 45th schema-check document, and `KlimmeckGraphQl.previewQuestTravel` returning a nullable, never-cached `TravelPreview`.**

## Performance

- Duration: ~8 min
- Tasks: 2/2
- Files modified: 7 (3 lib/tool, 4 test)

## Accomplishments

- `TravelQueries.getQuestTravelPreview` (non-raw `static const String`, `\$request`, `${TravelPreviewFragment.fields}`); collapsed it contains `questTravelPreview(request: $request) { distance duration road { coordinates distance } food { quantity item { id name } } hpLost arrivesAlive }`.
- Registry entry `'GetQuestTravelPreview': TravelQueries.getQuestTravelPreview` right after `GetTravelPreview`; doc comment gains «la Phase 15 aggiunge `GetQuestTravelPreview`;». The three count tests say 45.
- `Future<TravelPreview?> previewQuestTravel(AcceptQuestRequest request)` right after `previewTravel` in `lib/repository/services/graphql/graphql.dart`: `performQuery` (noCache) → `_dataOrThrow` → missing key `FormatException('questTravelPreview missing')`, `null` → `null`, otherwise `_travelPreviewFrom` (FormatException on non-map/parse error); coded `OperationException` rethrown raw.

## Task Commits

1. Task 1 RED `04b50d6` test(graphql): expect the quest travel preview document
2. Task 1 GREEN `4be3bee` feat(graphql): add the quest travel preview document
3. Task 2 RED `294176e` test(graphql): expect the quest travel preview service call
4. Task 2 GREEN `0434505` feat(graphql): preview the travel of a quest acceptance

## RED failures observed

- Task 1: `test/graphql/travel_documents_test.dart:61:50: Error: Member not found: 'getQuestTravelPreview'.` (compile failure, also :78, :90); `test/tool/schema_check_documents_test.dart: the registry lists 45 documents (D-12) [E] Expected: <45> Actual: <44>`.
- Task 2: `graphql_travel_test.dart:147:24: Error: The method 'previewQuestTravel' isn't defined for the type 'KlimmeckGraphQl'.` (also :223, :224).

## Tests

- Task 1 GREEN: `flutter test test/graphql test/tool` → +139, all passed.
- Task 2 GREEN: `flutter test test/repository/services/graphql/graphql_travel_test.dart test/repository` → +757, all passed.
- Plan verification: `flutter test test/graphql test/tool test/repository` → +896, all passed.
- Null-key behaviour: `dataResponse({'questTravelPreview': null})` keeps the key in `result.data`, so the `containsKey` guard holds and «returns null when the acceptance involves no travel (D-01)» is green; the guard was kept unchanged.
- Analyzer after each task: `50 issues found.` (info only), `ANALYZE_GATE_OK`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Third pinned registry count**
- **Found during:** Task 1 GREEN
- **Issue:** `test/graphql/shop_documents_test.dart:128` («the global catalogue queries left the registry (D-01)», Phase 13) also pins `schemaCheckDocuments.length` to 44; the plan listed only two count tests, so `flutter test test/graphql` went red at 45.
- **Fix:** expectation 44 → 45 (title unchanged, it belongs to Phase 13 D-01). It went in the GREEN commit rather than RED because it was discovered there.
- **Files modified:** test/graphql/shop_documents_test.dart
- **Commit:** 4be3bee

**2. Doc comment rewrap in the registry**
- The inserted sentence pushed a doc-comment line beyond 80 columns (`dart format` does not reflow comments); the last three comment lines were rewrapped by hand, keeping «la Phase 15 aggiunge» on one line so the plan grep still counts 1.

## Format

`dart format` run one by one on every touched file; `travel_queries.dart` reflowed the new constant to `=\n      '''` (same style as `getTravelPreview`), `graphql_travel_test.dart` reflowed the long test titles; no untouched member moved.

## Known Stubs

None.

## Self-Check: PASSED

- Files modified exist; commits 04b50d6, 4be3bee, 294176e, 0434505 present in `git log`.
