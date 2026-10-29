---
phase: 09-combat-result-sheet
plan: 12
subsystem: graphql + repository + app wiring
tags: [flutter, graphql, combat, quest-result, be-9.2, schema-check, shell]

# Dependency graph
requires:
  - phase: 09-03
    provides: "`QuestResultFragment`, `GetQuestResult`, `KlimmeckGraphQl.getQuestResult`, `QuestResultRepository._guard`, delivery ports"
  - phase: 09-06
    provides: "`QuestResultsCubit` consuming `PendingQuestResults` / `QuestResultAcknowledger` (15 s timeout, no retry on malformed)"
  - phase: 09-11
    provides: "`AuthenticatedShell` building `QuestResultsCubit` with the null-object ports"
  - phase: BE 9.2 (PR #15, origin/develop 8f30d1d)
    provides: "`unacknowledgedQuestResults`, `acknowledgeQuestResult`, `QuestResult.acknowledgedAt`"
provides:
  - "`QuestResultQueries.listUnacknowledgedQuestResults` (`ListUnacknowledgedQuestResults`) and `QuestResultMutations.acknowledgeQuestResult` (`AcknowledgeQuestResult`, new file `lib/graphql/mutations/quest_result_mutations.dart`)"
  - "`QuestResultFragment.fields` selects `acknowledgedAt` right after `resolvedAt`"
  - "schema-check registry at 38 documents, 38/38 OK against BE origin/develop 8f30d1d"
  - "`KlimmeckGraphQl.getUnacknowledgedQuestResults()` (parsed item by item) and `KlimmeckGraphQl.acknowledgeQuestResult(String id)`"
  - "`QuestResultRepository implements PendingQuestResults, QuestResultAcknowledger`"
  - "shell passes one `QuestResultRepository` as `repository`, `pending` and `acknowledger`; null objects removed"
affects: [09-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "List-level shape error → FormatException; per-item `QuestResult.tryFromJson` skipping malformed entries (09-REVIEW IN-04)"
    - "Shared repository failure-mapping test helper `_expectDeliveryFailures<T>` (stub + call closures)"

key-files:
  created:
    - lib/graphql/mutations/quest_result_mutations.dart
  modified:
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/graphql/queries/quest_result_queries.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/quest_result_repository.dart
    - lib/repository/quest_result_delivery_ports.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/graphql/quest_result_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/repository/services/graphql/graphql_quest_result_test.dart
    - test/repository/quest_result_repository_test.dart
    - test/screens/auth/authenticated_shell_test.dart
  deleted:
    - test/repository/quest_result_delivery_ports_test.dart

key-decisions:
  - "BE 9.2 contract adopted unchanged: names, argument and CommonResponse shape match the FE proposal (no alignment needed); the FE operation name stays ListUnacknowledgedQuestResults (the BE handoff example names it UnacknowledgedQuestResults, operation names are client-side)"
  - "Null objects NoPendingQuestResults / NoQuestResultAcknowledger deleted with their test file: no other user (Boy Scout); the two port interfaces stay"
  - "One QuestResultRepository instance per shell serves stream, pending list and acknowledgement"

requirements-completed: []

# Metrics
duration: ~8min
completed: 2026-10-29
---

# Phase 9 Plan 12: BE 9.2 result delivery contract live Summary

**Unacknowledged quest results are read from `unacknowledgedQuestResults` (item-by-item parsing, malformed entries skipped) and every closed sheet is confirmed through `acknowledgeQuestResult`, with `QuestResultRepository` implementing both delivery ports in the shell and all 38 documents validated against BE `origin/develop` 8f30d1d.**

## Performance

- **Duration:** ~8 min (first task commit 09:01, last 09:04 local, 2026-10-29)
- **Tasks:** 2 (4 TDD commits)
- **Files modified:** 15 (1 created, 13 modified, 1 deleted)

## BE gate (Task 1 step 1)

BE ref: `origin/develop` = **`8f30d1d`** (fetched 2026-10-29).

```
329:  acknowledgeQuestResult(id: String!): CommonResponse!
515:  unacknowledgedQuestResults: [QuestResult!]!
572:  acknowledgedAt: DateTime
```

`type CommonResponse { response: String!  successful: Boolean! }`. Handoff found at `.planning/phases/09.2-quest-result-delivery-contract/BACKEND-NOTES.md`: names «quelli proposti dal FE, invariati», no event on acknowledgement, death ack unlinks `currentCharacter` (D-12), results per **user** (not per character), cap 50, `resolvedAt` ASC with id tie-break. No semantic drift → no checkpoint.

## Accomplishments

- Fragment selects `acknowledgedAt`; `ListUnacknowledgedQuestResults` (no variables) and `AcknowledgeQuestResult($id: String!)` selecting `successful response`; registry 36 → 38.
- `KlimmeckGraphQl.getUnacknowledgedQuestResults()`: `unacknowledgedQuestResults` not a `List` → `FormatException`; items through `QuestResult.tryFromJson`, nulls dropped, server order kept, `List.unmodifiable`; coded errors rethrown raw.
- `KlimmeckGraphQl.acknowledgeQuestResult(id)`: `successful != true` or missing payload → `FormatException('acknowledgeQuestResult not successful')`; `NOT_FOUND` / `FORBIDDEN` rethrown raw.
- `QuestResultRepository.fetchUnacknowledged()` / `acknowledge(resultId)` through the existing `_guard` (notFound, forbidden, connection, malformed, unknown, timedOut after 15 s — all tested with `fake_async`).
- Shell: one repository for `repository:` / `pending:` / `acknowledger:`; class doc updated.

## Task Commits

1. **Task 1 RED** — `4ce6558` test(combat): expect the result delivery documents of BE 9.2
2. **Task 1 GREEN** — `f27008e` feat(combat): add the BE 9.2 result delivery documents
3. **Task 2 RED** — `ea71ba8` test(combat): expect the BE 9.2 result delivery calls
4. **Task 2 GREEN** — `888c09c` feat(combat): deliver unacknowledged results and acknowledge them

## RED evidence

- Task 1: `quest_result_documents_test.dart` failed to compile (`Error: Undefined name 'QuestResultMutations'`, `listUnacknowledgedQuestResults` undefined) and `travel_documents_test.dart` `Expected: <38> Actual: <36>` → `+109 -2: Some tests failed.`
- Task 2: `graphql_quest_result_test.dart` `Error: The method 'getUnacknowledgedQuestResults' isn't defined for the type 'KlimmeckGraphQl'` (and `acknowledgeQuestResult`), repository and shell tests failing to compile on the same missing members.

## Schema check (Task 1 step 6)

```
dumped 38 documents
validate_documents.js exit 0 — 38 lines "OK", 0 failures, including:
OK AcknowledgeQuestResult.graphql
OK GetQuestResult.graphql
OK ListUnacknowledgedQuestResults.graphql
OK OnQuestResultReceived.graphql
```

## Verification

- `flutter test test/graphql test/tool test/models/quest_result` → +126 all passed
- `flutter test test/repository test/screens/auth test/screens/mainScreen` → +1560 all passed
- Full `flutter test` → **2483 all passed** (2452 before this plan: +8 Task 1, +25 Task 2, −2 null-object tests)
- `flutter analyze` → 52 issues, 0 errors (baseline ≤ 53); `flutter analyze lib/repository lib/screens/auth` → no issues
- `dart format --output=none --set-exit-if-changed` on all touched lib/tool/test files → exit 0 (all were clean before editing)
- `grep -rn "NoPendingQuestResults\|NoQuestResultAcknowledger" lib test` → empty

## Decisions Made

See frontmatter `key-decisions`.

## Deviations from Plan

1. **[Rule 3 - Blocking] `test/graphql/travel_documents_test.dart` bumped 36 → 38** — not in `files_modified`, but it pins the registry size; the 38 pin lives there only (no duplicate count test added in `quest_result_documents_test.dart`).
2. **Existing fragment test reworded** — `never selects enemy locations nor acknowledgedAt` became `never selects enemy locations` + `selects the BE 9.2 acknowledgedAt right after resolvedAt` (the old assertion contradicted the plan).
3. **Model test was not RED** — `QuestResult.fromJson` already parsed `acknowledgedAt` since 09-01; the handoff-payload test (`acknowledgedAt: null` key present on a death result) passed immediately and stands as a characterization test. No model change.
4. **`test/repository/quest_result_delivery_ports_test.dart` deleted** — it only tested the removed null objects (plan step 4).
5. **Mutation selection order** `successful response` (as the plan's behaviour requires); `quest_mutations.dart` uses `response successful` — irrelevant to the server.

## Known Stubs

None.

## Threat Flags

None (T-9-42..T-9-46 handled as planned: gate + 38/38, contract read before editing, FORBIDDEN mapped, per-item parsing, only `git fetch/show/ls-tree` on the BE; the validator loads `graphql` from the BE `node_modules` via `NODE_PATH`, as the repo's schema-check procedure does, no `.env` read).

## Next Phase Readiness

09-13 (device E2E / UAT) can run: cold start, resume and WS reconnection now hit `ListUnacknowledgedQuestResults`; closing a sheet sends `AcknowledgeQuestResult`; acknowledging a death triggers the BE `userUpdated(currentCharacter: null)`.

## Self-Check: PASSED

- FOUND: lib/graphql/mutations/quest_result_mutations.dart
- FOUND commits: 4ce6558, f27008e, ea71ba8, 888c09c
