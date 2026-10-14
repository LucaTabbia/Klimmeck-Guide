---
phase: 03-real-time-sync-foundation
plan: 01
subsystem: testing
tags: [graphql-transport-ws, fixtures, schema-check, requirements]
requires: []
provides:
  - FakeGraphQlWsServer (loopback graphql-transport-ws peer for socket tests)
  - sync_event_fixtures (userJson, characterJson, dataResponse, errorCodeResponse, malformedUserResponse)
  - schema-check tooling (schemaCheckDocuments, dump_documents.dart, validate_documents.js)
affects: [03-05, 03-06, 03-07, 03-09]
tech-stack:
  added: []
  patterns: [real-socket tests with plain test(), per-document schema validation with the BE graphql-js]
key-files:
  created:
    - test/helpers/fakes/fake_graphql_ws_server.dart
    - test/helpers/fakes/fake_graphql_ws_server_test.dart
    - test/helpers/fixtures/sync_event_fixtures.dart
    - test/helpers/fixtures/sync_event_fixtures_test.dart
    - tool/schema_check/schema_check_documents.dart
    - tool/schema_check/dump_documents.dart
    - tool/schema_check/validate_documents.js
    - test/tool/schema_check_documents_test.dart
  modified:
    - .planning/REQUIREMENTS.md
key-decisions:
  - "SYNC-05 reworded without admin-swap (D-08); SYNC-02 carries the D-05 deferral note; SYNC-01..07 mapped to Phase 3"
requirements-completed: [SYNC-03, SYNC-05, SYNC-06]
duration: 25min
completed: 2026-10-14
---

# Phase 3 Plan 01: Wave 0 scaffolding Summary

Fake graphql-transport-ws server, sync payload fixtures and a graphql-js schema-check pipeline, plus the SYNC-05/SYNC-02 requirement amendments. Nothing in `lib/` changed.

## Commits
- 39252b4 test(sync): failing self-test for the fake server
- 3dba2ff test(sync): fake graphql-transport-ws server
- (RED) test(sync): failing tests for fixtures and the schema-check list
- e5a960c chore(sync): fixtures and schema-check tooling
- 8f1aaa1 docs(phase-3): amend SYNC-05 and map sync requirements

## Verification
- `flutter test`: 495 passing (baseline 481 + 6 server + 8 fixtures/schema tests)
- `flutter analyze`: 57 issues, identical to the baseline; the touched files report none
- Touched Dart files are formatter-clean (explicit paths only)

## Baseline schema check (current BE schema, no `userUpdated` yet)
23 documents dumped, all `OK` (CreateCharacter, ExchangeLoginTicket, GetMe, GetRaceTraits, Logout, RefreshSession, character, characterUpdated, cities, doTransaction, equipItem, equipSpell, equipment, equipmentAssetsQuantity, equipmentItems, equipmentItemsByIds, lootAssetsQuantity, lootItems, lootItemsByIds, lore, lores, quests, unequipSpell). No pre-existing drift.

## Deviations from Plan
**1. [Rule 1 - Bug in plan] Operation count is 23, not 25.** The plan's `<interfaces>` list enumerates 23 operations (14 queries, 8 mutations, 1 subscription); the "25" figure was a miscount. `schemaCheckDocuments` holds all 23 and the completeness test enforces set equality with the sources.

No other deviations. The `_Client` helper in the server self-test exposes a `closed` completer because a WebSocket stream is single-subscription.

## Known Stubs
None.

## Threat Flags
None. The server binds 127.0.0.1 on an ephemeral port; the tooling only reads the BE repo and dumps to a scratch directory.

## Self-Check: PASSED
