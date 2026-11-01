---
phase: 10-admin-panel-innkeeper
plan: 02
subsystem: admin-transport
tags: [admin, innkeeper, graphql, repository, tdd]
requires: [10-01]
provides:
  - PendingRequestFragment.fields
  - PendingRequestQueries.getPendingRequests (GetPendingRequests)
  - PendingRequestSubscriptions.pendingRequestsUpdated (OnPendingRequestsUpdated)
  - PendingRequestMutations.completePendingRequest (CompletePendingRequest)
  - TravelMutations.teleportCharacter (TeleportCharacter)
  - KlimmeckGraphQl.subscribeToPendingRequests / getPendingRequests / completePendingRequest / teleportCharacter
  - InnkeeperFailure, InnkeeperException, innkeeperFailureFrom
  - InnkeeperRepository (watchQueue, fetchQueue, readCharacter, complete, teleport)
  - MockInnkeeperRepository (test/helpers/mocks.dart)
affects: [10-03, 10-04, 10-05, 10-06, 10-11]
tech-stack:
  added: []
  patterns: [item-by-item queue parsing with count-only debug log, code-only failure classifier, generic _guard with 15 s timeout]
key-files:
  created:
    - lib/graphql/fragments/pending_request_fragment.dart
    - lib/graphql/queries/pending_request_queries.dart
    - lib/graphql/subscriptions/pending_request_subscriptions.dart
    - lib/graphql/mutations/pending_request_mutations.dart
    - lib/repository/innkeeper_failure.dart
    - lib/repository/innkeeper_repository.dart
    - test/graphql/pending_request_documents_test.dart
    - test/repository/services/graphql/graphql_pending_requests_test.dart
    - test/repository/innkeeper_failure_test.dart
    - test/repository/innkeeper_repository_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - lib/graphql/mutations/travel_mutations.dart
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - test/graphql/travel_documents_test.dart
    - test/repository/services/graphql/graphql_travel_test.dart
    - test/helpers/mocks.dart
decisions:
  - "startTravel and teleportCharacter share a private `_travelMutation(document, field, request)` in KlimmeckGraphQl (same shape as `_spellSlotMutation`), instead of a copy of the startTravel body"
  - "`watchQueue()` returns the service stream unchanged: its errors stay `SubscriptionStreamException(operation: 'pendingRequestsUpdated')` / `FormatException`, not InnkeeperException (the queue cubit of 10-03 classifies them)"
metrics:
  duration: 15min
  completed: 2026-10-29
---

# Phase 10 Plan 02: Innkeeper transport Summary

Queue fragment without `pendingQuest`/`user`/`pointsSpent`, four new documents registered (registry 38 → 42, schema check 42/42 against BE `origin/develop` `8f30d1d`), typed service methods with item-by-item parsing, a code-only `InnkeeperFailure` classifier and the `InnkeeperRepository` the three panel cubits build on.

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | Queue fragment, four documents, registry 42, schema check | 2bf10f2 | 4bd0df7 |
| 2 | Typed service methods (queue, completion, teleport) | 62a6820 | 7b50d5c |
| 3 | InnkeeperFailure classifier and InnkeeperRepository | ad9c97f | 0aec659 |

## RED failures (expected)

- Task 1: `Error when reading 'lib/graphql/mutations/pending_request_mutations.dart': No such file or directory` (plus queries/subscriptions), `Undefined name 'PendingRequestFragment'` — compilation failed.
- Task 2: `The method 'subscribeToPendingRequests' isn't defined for the type 'KlimmeckGraphQl'` (and `getPendingRequests`, `completePendingRequest`, `teleportCharacter`).
- Task 3: `Error when reading 'lib/repository/innkeeper_failure.dart': No such file or directory`, `Undefined name 'InnkeeperFailure'`.

## Schema check (BE `origin/develop` = `8f30d1d`)

```
dumped 42 documents
validate_documents.js exit 0 — 42 lines «OK …», 0 failures, including:
OK CompletePendingRequest.graphql
OK GetPendingRequests.graphql
OK OnPendingRequestsUpdated.graphql
OK TeleportCharacter.graphql
```

## Verification

- `pending_request_documents_test.dart` 11, `travel_documents_test.dart` 16, `graphql_pending_requests_test.dart` 12, `graphql_travel_test.dart` 20, `innkeeper_failure_test.dart` 11, `innkeeper_repository_test.dart` 16 — all green.
- `flutter test test/graphql test/tool test/repository`: 820 green; full suite: 2601 green.
- Repo-wide analyzer gate: 51 issues (all `info`), exit 0.
- No `pendingQuest` in `lib/graphql` outside the pre-existing Character fragment and the doc comment of the queue fragment.

## Deviations from Plan

1. **[Boy Scout - Refactor] Shared `_travelMutation` helper** — Task 2: instead of duplicating the `startTravel` body for `teleportCharacter` (the plan's «same shape as startTravel»), both now delegate to a private `_travelMutation(document, field, request)`, mirroring `_spellSlotMutation`. Error messages unchanged (`startTravel malformed`, `teleportCharacter malformed`); the existing startTravel tests stay green. Commit 7b50d5c.

Otherwise the plan was executed as written.

## Known Stubs

None.

## Self-Check: PASSED
