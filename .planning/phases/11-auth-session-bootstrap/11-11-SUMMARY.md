---
phase: 11-auth-session-bootstrap
plan: 11
subsystem: auth
tags: [contract-verification, backend-handoff, phase-gate]
requires: [11-10]
provides:
  - Verified app vs real backend contract (zero mismatches)
  - BACKEND-NOTES.md handoff for the BE agent with pending-UAT checklist
affects: []
key-files:
  created:
    - .planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md
  modified:
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/auth_token_service.dart
metrics:
  completed: 2026-10-06
---

# Phase 11 Plan 11: Contract verification, phase gate, backend handoff

Compared the app against the real backend `schema.gql` and Phase 2 BACKEND-NOTES: no mismatch found, so no `fix` commit was needed. Wrote BACKEND-NOTES.md and fixed two stale dartdocs.

## Contract comparison (app vs real backend)

| Element | App | Backend | Result |
|---|---|---|---|
| `exchangeLoginTicket(ticket, codeVerifier)` | `$ticket: String!, $codeVerifier: String!` | `(codeVerifier: String!, ticket: String!): AuthSession!` | MATCH |
| `refreshSession(refreshToken)` | `String!` | `String!` -> `AuthSession!` | MATCH |
| `logout` | `mutation Logout { logout }` | `logout: Boolean!`, access token required | MATCH |
| `me` | `GetMe` | `me: User!` | MATCH |
| `AuthSession` fields | `accessToken accessTokenExpiresAt refreshToken user` (`DateTime.parse` ISO) | same, `DateTime!` | MATCH |
| `User` selection | `id twitchId twitchPoints role currentCharacter { id }` | all exist (`currentCharacter: Character` nullable) | MATCH |
| `RoleType` | `guard, adventurer, innkeeper` (parsed `byName`) | `adventurer guard innkeeper` | MATCH |
| Start path / param | `auth/twitch/start?challenge=` relative to `BASE_URL` | `GET /auth/twitch/start?challenge=` | MATCH |
| Deep link | `klimmeck://auth`, `ticket` / `error` | `klimmeck://auth?ticket=|error=` | MATCH |
| `error` codes | `access_denied` silent, `twitch_not_configured` dedicated, others generic (`LoginRejectedByBackend`) | `twitch_not_configured, invalid_request, invalid_state, access_denied, twitch_client_mismatch, twitch_exchange_failed` | MATCH |
| Auth error codes | `SESSION_EXPIRED`, `SESSION_REVOKED`, `LOGIN_TICKET_INVALID`, `UNAUTHENTICATED` | same | MATCH |
| Refresh terminal set | only `SESSION_EXPIRED` / `SESSION_REVOKED`; malformed token -> `SESSION_EXPIRED` upstream | confirmed (never `UNAUTHENTICATED`) | MATCH |
| GraphQL unauthenticated | HTTP 200 + `extensions.code` | same | MATCH |
| REST unauthenticated | 401 -> one refresh + one retry | 401 body with `code` | MATCH |
| WS payload | `{ "Authorization": "Bearer <token>" }` read per connect | `Authorization` (or lowercase) | MATCH |
| WS close codes | 4401 / 4403 -> refresh then reconnect, capped backoff | 4403 `Forbidden`, 4401 `Token expired` | MATCH |
| Logout | refresh first via `getAccessToken()` (D-36), 4 s timeout | needs valid access token | MATCH |
| Timings | proactive `lifetime - 60 s`, floor 30 s | TTL 15 min, grace 30 s | MATCH |
| Dev bypass | `DEV_AUTH_*`, `DEV_AUTH_USER_ID` fallback only, `me` realign | token min 16 chars, user id ignored, role change needs BE restart | MATCH |
| Secrets | `grep TWITCH_CLIENT\|client_secret lib .env.example` finds nothing | n/a | MATCH |

MISMATCHES: none.

## Phase gate

- `flutter test`: 247 tests, all passed
- `flutter analyze lib test`: 11 issues (unchanged baseline, none new)
- `flutter build apk --debug`: exit 0; `minSdk = 23` in `android/app/build.gradle.kts` restored by hand and not committed
- Format check on phase files by explicit path: all clean except `lib/routes/routes.dart`, whose pre-existing code (present before the phase) was never formatted; left untouched (D-38, out of scope)
- `git status --short`: only ` M test/repository/services/auth/auth_token_service_contract_test.dart` (user edit intact)

## Commits

- `b47f9e0` docs(phase-11): fix outdated auth service dartdocs (`DevAuthTokenService.initialize()` now cites `AuthCubit.start()`; `AuthTokenService.authStateStream` lists `AuthCubit` instead of `SplashCubit`)
- `bdb191a` docs(phase-11): add backend handoff notes for auth session bootstrap

## Deviations from Plan

None - plan executed as written. Requirements not marked complete in REQUIREMENTS.md and `nyquist_compliant` not flipped (not requested).

## Known Stubs / pending items

- TOS and Privacy footer buttons on SignInScreen: empty `onPressed` (URLs undefined)
- Logout entry point: Phase 4 (Settings)
- `MainScreen` hard-coded character id (pre-existing)
- Events missed during a WS reconnect gap are not replayed (Phase 3: refetch-on-reconnect)
- Real-device Twitch login UAT pending until keys arrive (checklist in BACKEND-NOTES.md, D-28)

## Self-Check: PASSED

BACKEND-NOTES.md and commits b47f9e0, bdb191a verified present.
