---
phase: 03-real-time-sync-foundation
plan: 03
subsystem: graphql
tags: [subscription, userUpdated, error-codes, FORBIDDEN, NOT_FOUND]
requires: [03-01]
provides:
  - UserSubscriptions.userUpdated (OnUserChanged)
  - graphQlErrorCode, accessDeniedCodes, isAccessDeniedError
  - SubscriptionStreamException, GraphQlAccessDeniedException
  - KlimmeckGraphQl.subscribeToUser()
affects: [03-06, 03-07, 03-09]
tech-stack:
  added: []
  patterns: [payload-free typed exceptions, error code extraction for both wire shapes]
key-files:
  created:
    - lib/graphql/subscriptions/user_subscriptions.dart
    - lib/repository/services/graphql/graphql_error_code.dart
    - lib/repository/services/graphql/graphql_sync_exceptions.dart
    - test/graphql/user_subscription_documents_test.dart
    - test/repository/services/graphql/graphql_error_code_test.dart
    - test/repository/services/graphql/graphql_sync_test.dart
  modified:
    - lib/repository/services/graphql/graphql.dart
    - tool/schema_check/schema_check_documents.dart
key-decisions:
  - "Error code read from graphqlErrors (real backend shape) first, SubscriptionError payload list parsed defensively"
  - "getCharacter keeps its generic Exception for non-access-denied failures (cold start D-16 unchanged)"
requirements-completed: [SYNC-01, SYNC-02]
duration: 20min
completed: 2026-10-14
---

# Phase 3 Plan 03: GraphQL sync boundary Summary

`OnUserChanged` document plus `subscribeToUser()`, FORBIDDEN/NOT_FOUND recognition in both wire shapes, and payload-free typed exceptions so cubits can separate terminal from transient failures.

## Commits

- e8e6952 test: failing OnUserChanged document tests
- e1e02fe feat: OnUserChanged document and schema-check entry
- 4847d88 test: failing error code tests
- 96789b7 feat: error code extraction and typed exceptions
- 2863ecb test: failing sync stream tests
- 065101a feat: `subscribeToUser`, hardened `subscribeToCharacter`, access-denied `getCharacter`

## Deviations from Plan

None - plan executed as written. The `characterUpdated` document is untouched (D-02/D-05). `graphql.dart` was formatter-clean beforehand, so it was formatted normally. The sync test file received a small helper fix (`_errorOf`) and a nullable `role?.name` after the RED commit, folded into the feat commit.

## Verification

- Full `flutter test`: 567 passing (baseline 542, +25)
- `flutter analyze`: 57 issues (baseline unchanged); touched files clean
- BE schema check for `OnUserChanged` deferred to plan 09 (BE Phase 3 not merged)

## Known Stubs

None.

## Self-Check: PASSED
