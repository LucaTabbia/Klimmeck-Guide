---
phase: 11-auth-session-bootstrap
plan: 03
subsystem: auth
tags: [flutter_secure_storage, graphql, error-mapping, session-store]
requires: [11-02]
provides:
  - SessionStore / SecureSessionStore (encrypted refresh token, first-launch wipe)
  - InMemorySessionStore fake, MockFlutterSecureStorage, MockBackendAuthApi, MockBackendMeSource
  - AuthSessionFragment, AuthMutations (ExchangeLoginTicket, RefreshSession, Logout), AuthQueries.getMe
  - AuthApiException sealed family + mapAuthOperationException
  - BackendAuthApi / BackendMeSource interfaces, GraphQlBackendAuthApi (dedicated client)
affects: [11-04, 11-05, 11-06, 11-07, 11-11]
key-files:
  created:
    - lib/repository/storage/session_store.dart
    - lib/graphql/fragments/auth_session_fragment.dart
    - lib/graphql/mutations/auth_mutations.dart
    - lib/graphql/queries/auth_queries.dart
    - lib/repository/services/auth/auth_api_exception.dart
    - lib/repository/services/auth/backend_auth_api.dart
    - lib/repository/services/auth/graphql_backend_auth_api.dart
    - test/helpers/fakes/in_memory_session_store.dart
    - test/repository/storage/session_store_test.dart
    - test/repository/services/auth/graphql_backend_auth_api_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - lib/repository/services/auth/auth.dart
    - test/helpers/mocks.dart
key-decisions:
  - "refreshSession: only SESSION_EXPIRED / SESSION_REVOKED are terminal (SessionRejected); everything else is TransientAuthFailure"
  - "Auth API uses a dedicated GraphQLClient (HttpLink only, no auth link, no retry)"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 03: Session store and backend auth API Summary

Encrypted refresh-token storage with first-launch wipe and read-failure recovery, plus a GraphQL backend auth API on a dedicated client with strict, non-destructive error mapping.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | 3ef2e17 | test(phase-11): add secure session store specs |
| T1 GREEN | 4d7f053 | feat(phase-11): add secure session store with first launch wipe |
| T2 RED | 6ab4960 | test(phase-11): add backend auth api contract and error mapping specs |
| T2 GREEN | 2f53e08 | feat(phase-11): add auth graphql documents and dedicated backend auth api |

## Results

- `flutter test`: 81 tests, all passed (baseline 57).
- `flutter analyze lib test`: 14 issues (baseline 14, no new); touched files "No issues found".
- `dart format --output=none --set-exit-if-changed` on explicit touched files: exit 0.
- Only the user's own `auth_token_service_contract_test.dart` remains modified.

## Backend contract sources used

BACKEND-NOTES.md does not exist yet and `src/schema.gql` does not yet contain `AuthSession` (checked). All names come from source 3 (backend plans), to be re-verified by 11-11 against the real schema:

| Operation | Source | Shape used |
|-----------|--------|------------|
| `exchangeLoginTicket(ticket: String!, codeVerifier: String!)` | 02-06-PLAN.md | returns `AuthSession` |
| `refreshSession(refreshToken: String!)` | 02-06-PLAN.md | returns `AuthSession` |
| `logout` | 02-05-PLAN.md (`logout(): Promise<boolean>`), 02-07-PLAN.md | scalar Boolean, no selection |
| `me` | 02-07-PLAN.md | returns `User` (`id twitchId twitchPoints role currentCharacter { id }`) |
| `AuthSession { accessToken accessTokenExpiresAt refreshToken user }` | 02-05/02-06 | as in fragment |
| Error codes | 02-06 | SESSION_EXPIRED, SESSION_REVOKED, LOGIN_TICKET_INVALID, UNAUTHENTICATED |

Open points: exact `logout`/`me` GraphQL signatures and the `User` field names/enum values (`role`) are inferred from the plans, not from a generated schema; `BAD_REQUEST` is treated as a possible code per the plan.

## Deviations from Plan

- Test helper `operationNameOf(request)` reads the operation name from the document: the `gql()` documents do not populate `request.operation.operationName`, so the plan's suggested lookup returned null.
- `NetworkException` in tests needs a non-null `originalException`.
- Doc comment in `graphql_backend_auth_api.dart` reworded so the `AuthAuthLink` acceptance grep returns 0.
- `mocks.dart` Mock for `BackendAuthApi`/`BackendMeSource` went in the GREEN commit (needs production types); `MockFlutterSecureStorage` was in RED.
- No other deviations.

## Notes for next plans

- `SecureSessionStore({storage, preferences})` is injectable; constants `refreshTokenKey`, `firstLaunchDoneKey`. Writes propagate exceptions (persist-before-forget is the service's job).
- `GraphQlBackendAuthApi.forEndpoint(httpUrl)` builds the production client (15 s request timeout); `GraphQlBackendAuthApi(client:)` for tests.
- `logout`/`fetchMe` take the bearer as parameter; HTTP 401 or UNAUTHENTICATED there maps to `AccessTokenRejected`.
- `auth.dart` barrel now exports `auth_api_exception`, `backend_auth_api`, `graphql_backend_auth_api`.
- `User.fromJson` accepts `currentCharacter: {id}` (Character fields optional).

## Known Stubs

None.

## Self-Check: PASSED

- All created files FOUND; commits 3ef2e17, 4d7f053, 6ab4960, 2f53e08 FOUND.
