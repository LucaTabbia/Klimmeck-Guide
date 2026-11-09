---
phase: 12-hardening
group: A
reviewed: 2026-11-09T18:35:37Z
depth: standard
files_reviewed: 18
files_reviewed_list:
  - lib/repository/services/auth/auth.dart
  - lib/repository/services/auth/auth_api_exception.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/graphql/graphql_client_holder.dart
  - lib/repository/services/graphql/ws_reconnect_policy.dart
  - lib/repository/services/rest/auth_interceptor.dart
  - lib/repository/storage/session_store.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/cubit/auth_cubit.dart
  - lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart
  - lib/screens/auth/syncCubit/session_sync_cubit.dart
  - lib/screens/signIn/sign_in_screen.dart
  - test/helpers/fakes/fake_graphql_ws_server.dart
  - test/helpers/fakes/fake_session_backend.dart
  - test/helpers/leak_tracking_bloc_observer.dart
findings:
  critical: 0
  warning: 0
  info: 6
  total: 6
status: issues_found
---

# Phase 12 (Hardening) — Group A review: session, WebSocket and auth

## Summary

Scope: the 18 files of group A plus the matching suites (`logout_flow_test`, `concurrent_unauthorized_refresh_test`, `dual_session_revocation_test`, `authenticated_shell_leak_test`, `identity_transitions_test`, `ws_reconnect_policy_test`, `graphql_backend_auth_api_test`, `notification_intent_cubit_test`, `auth_gate_test`, `sign_in_screen_test`). `dual_session_revocation_test` and `logout_flow_test` were run once each in the foreground: both green.

The revocation contract holds as specified:
- `mapAuthOperationException` reads `extensions.reason` from the same GraphQL error that carried the code, and honours it only on `SESSION_REVOKED`. A test covers `SESSION_EXPIRED` + reason.
- `_rotateSession` is the single mapping point (cold start, proactive and reactive refresh all go through it). `newLogin` and `roleChanged` map to their notices, anything else maps to `sessionExpired`. `handleRevocation()` stays `sessionExpired`. The logout-only refresh ignores reasons.
- `AuthGate._noticeFor` is an exhaustive switch. The copy matches the REPO-RULES byte for byte. `_shouldRebuild` handles a reason change.
- `WsReconnectPolicy` routes `4409` like `4401` through `recoverFromUnauthorized(rejectedToken: _lastSentToken)`, without parsing the close reason. Attempts are bounded, and the dual-session test proves no `connection_init` from A after the teardown.
- Single flight holds across `AuthAuthLink`, `AuthInterceptor` and the WS policy (`_refreshInFlight`).
- Logout order is push unregister, backend logout, link disposed, store cleared, `Unauthenticated`, and a test pins it. The old client is released.
- `SecureSessionStore` persists only the refresh token. `allowBackup` is `false`.
- No token reaches a log: `appLog` takes `runtimeType` only, and `appLog` is muted in release.
- The dev bypass is not referenced from `lib/main.dart`, `app_bootstrap.dart` or `session_auth_composition.dart`.
- `leak_tracker` and `leak_tracker_flutter_testing` are `dev_dependencies`.
- Identity transitions are covered. `AuthGate` is keyed on `user.id`, root dialogs are closed on user and character changes, and `NotificationIntentCubit` drops a pending tap on a direct user change (RED-first test present). It keeps the tap on a same-user rotation.

No critical issues and no warnings: no scenario was found where a revoked session stays usable, a token is logged or persisted outside the secure store, or a harness proves nothing at all. Six info items remain, all low-risk. One DEFERRED note on the session-scoped link wrapper follows the list.

Deferred note, not a finding (orchestrator ruling A on `logout_flow_test`): graphql 5.2.1 `autoReconnect` streams never complete after dispose, so `logout_flow_test` proves the old stream silent rather than done. A session-scoped link wrapper that completes subscriptions on dispose is a clean idea, but it changes the link layer for a leak that no consumer sees. `SessionSyncCubit` cancels its own subscription and `GraphQLClientHolder` drops the client, which the weak-reference test proves released. It does not deserve a finding in this phase. Keep it in the backlog.

## Critical

None.

## Warning

None.

## Info

### A-IN-01: `_endSession` is not single-flight across rotation rejection, `terminateSession` and `handleRevocation`

**File:** `lib/repository/services/auth/session_auth_token_service.dart:186-194, 394-400`
**Issue:** `logout()` and `terminateSession()` each have their own in-flight guard, but `_endSession` itself does not.
- `_rotateSession` calls `_endSession(replacedByNewLogin)` on `SessionRejected`.
- `terminateSession` only skips when `_logoutInFlight != null` or `_channel.current is! AuthAuthenticated`. The state stays `Authenticated` until the final `emit`, after the awaited teardown and `_clearStore`.
- A `terminateSession(syncLost)` from the watchdog that lands in that window runs a second teardown and a second store clear, and emits a second terminal state.
- `AuthGate` rebuilds on the reason change, so «Connessione persa» replaces the specific notice.

**Why it matters:** the window is a few milliseconds and needs the sync watchdog to latch exactly as the refusal lands, so it is unlikely. Still, the doc promise «emette un solo stato terminale» is only half enforced, and the specific notice (the point of D-12) can be overwritten.
**Suggested fix:** make the terminal transition idempotent. Keep a single `Future<void>? _endInFlight` in `_endSession` (`return _endInFlight ??= _doEndSession(reason).whenComplete(...)`), or set a `_isEnding` flag in `_supersedeSession`-adjacent code and make `terminateSession` return early on it. RED test first in `session_auth_token_service_terminate_test.dart`:
1. Refresh rejected with `newLogin`, and a teardown that blocks on a `Completer`.
2. Call `terminateSession(syncLost)` while the teardown is blocked.
3. Release the teardown and assert exactly one `AuthUnauthenticated`, with reason `replacedByNewLogin`, and teardown called once.

### A-IN-02: «reason only on `SESSION_REVOKED`» is enforced only by the parser, not by the service mapping

**File:** `lib/repository/services/auth/session_auth_token_service.dart:310-317`
**Issue:** `_unauthenticatedReasonOf` switches on `rejection.reason` alone. The constructor `SessionRejected(code, {reason})` allows `SessionRejected(sessionExpiredCode, reason: 'newLogin')`, which the service would map to `replacedByNewLogin`. Today only `mapAuthOperationException` builds the exception, so Pitfall 8 holds through that one door. The invariant lives in the wrong place: a future `BackendAuthApi` implementation, or a fake in a test, could break it silently.
**Why it matters:** this is defense in depth for the D-12 contract, not a bug today.
**Suggested fix:** guard the mapping on the code (`rejection.code == sessionRevokedCode ? switch (...) : sessionExpired`). Alternatively make the invariant structural with a named constructor `SessionRejected.revoked({this.reason})` and a `reason` getter that is null for the other code. RED test: `SessionRejected(sessionExpiredCode, reason: 'newLogin')` from a mocked `refreshSession` ends with `sessionExpired`.

### A-IN-03: stale documentation about the dev bypass after the entry-point split

**File:** `lib/repository/services/auth/dev_auth_token_service.dart:24-26`; `lib/repository/services/auth/auth_token_service.dart:29, 87-91`
**Issue:**
- The `DevAuthTokenService` header says «Nessuna guardia `kReleaseMode` (D-30): il backend è il confine di sicurezza. Lo stub viene rimosso in Phase 12.» Phase 12 D-01 chose a different outcome: the stub stays, reachable only from `lib/main_dev.dart` via `dev_auth_composition.dart`, and `lib/main.dart` never composes it.
- The `AuthTokenService` docs still call it «stub backed da `.env` per sviluppo locale» and describe the cold-start emission as Phase 1.

**Why it matters:** a future reader would think the removal is pending, or that production still ships a guard-less bypass.
**Suggested fix:** replace the two sentences with «Raggiungibile solo da `lib/main_dev.dart` (`dev_auth_composition.dart`); l'entry point di produzione non lo compone (Phase 12 D-01).» Comment-only change. Keep the literal `DEV_AUTH_` out of any production-graph file, per the REPO-RULES gate.

### A-IN-04: `logout_flow_test` «old subscription stays silent» does not prove the old link stops reconnecting

**File:** `test/repository/services/auth/logout_flow_test.dart:136-160`
**Issue:** the test proves the old stream silent by emitting an old-subscription id on the NEW socket. That frame never reaches the old client in any case: the old socket is closed and the old client's socket is not the new one. So `oldEvents.isEmpty` holds even if the old link were still alive and retrying. What D-08 actually asks («link disposed, no listener survives») is proved in the dual-session test through `nextConnectAttempt` and the 0 `connection_init` check. The logout flow does not check that the old link never opens a second socket.
**Why it matters:** a regression where `holder.reset()` stops disposing the link (or a reconnect timer outlives the dispose) would keep `logout_flow_test` green and only show up in the dual-session suite, and only on the revocation path.
**Suggested fix:** in the same test, after `await oldSocket.done`, await the old policy's next connect attempt on a real signal (the `_RecordingWsReconnectPolicy.nextConnectAttempt` pattern of `dual_session_revocation_test.dart`, ideally moved into `test/helpers/` and shared). Then assert `server.framesOf('connection_init')` has exactly two entries: the original and the new session's. Also record `oldEvents` receiving at least one event before the logout, so a stream that was never live cannot pass trivially.

### A-IN-05: `AuthInterceptor` double-gates its log with `kDebugMode` and `appLog`

**File:** `lib/repository/services/rest/auth_interceptor.dart:1-2, 56-58`
**Issue:** `appLog` is already muted in release, so `if (kDebugMode)` is redundant, and it is the only reason the file imports `flutter/foundation.dart`. The other auth files call `appLog` directly.
**Why it matters:** Boy Scout. It touches the same line the Phase 12 log migration already edited.
**Suggested fix:** call `appLog('[AuthInterceptor] token fetch failed: ${e.runtimeType}')` unconditionally and drop the import. No behaviour change, so no new test.

### A-IN-06: `AuthTokenService.handleRevocation()` has no production caller

**File:** `lib/repository/services/auth/auth_token_service.dart:136-143`; `lib/repository/services/auth/session_auth_token_service.dart:186-187`
**Issue:** after the refactors, the only callers of `handleRevocation()` are tests and the dev stub. Revocations reach the teardown through `_rotateSession` and `terminateSession`. The method stays in the contract and in two implementations as dead surface. Its documented behaviour (`sessionExpired`, no reason) also differs from the live path that maps reasons, which could mislead a future caller.
**Why it matters:** dead code in the contract of a security-sensitive component. It also invites a caller to bypass the reason mapping.
**Suggested fix:** if no future plan needs it, remove it from `AuthTokenService`, `SessionAuthTokenService`, `DevAuthTokenService` and the mocks and tests in one commit. Otherwise note in the doc that it is a test and dev hook and that live revocations go through `_rotateSession`. This is a refactor outside the phase hardening scope: acceptable to defer to the ruling.

---

_Reviewed: 2026-11-09T18:35:37Z_
_Reviewer: Claude (gsd-code-reviewer), group A_
_Depth: standard_
