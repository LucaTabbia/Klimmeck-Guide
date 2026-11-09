---
phase: 12-hardening
plan: 15
subsystem: auth/graphql
tags: [hardening, session, revocation, websocket, 4409, two-devices, be-phase-17]
requires: ["12-14"]
provides:
  - "top-level const int wsSessionRevokedCloseCode = 4409 in ws_reconnect_policy.dart; WsReconnectPolicy.authRejectedCloseCodes = {4401, 4403, wsSessionRevokedCloseCode}"
  - "FakeGraphQlWsServer.onConnectionInit hook (false = no ack) and closeSocket(ws, code, reason)"
  - "FakeSessionBackend implements BackendAuthApi: last login wins (newLogin), SESSION_REVOKED + reason on refresh of a revoked session"
  - "dual_session_revocation_test.dart: five D-06 cases in-process on loopback"
affects: [12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "A revoked socket is never reconnected on its close reason: 4409 → single-flight refresh → the refused refresh decides the notice"
    - "Real-time loopback harness with a recording WsReconnectPolicy subclass: closures seen by the link + a deterministic signal for the next connect attempt"
key-files:
  created:
    - test/helpers/fakes/fake_session_backend.dart
    - test/repository/services/auth/dual_session_revocation_test.dart
    - .planning/phases/12-hardening/12-15-SUMMARY.md
  modified:
    - lib/repository/services/graphql/ws_reconnect_policy.dart
    - test/repository/services/graphql/ws_reconnect_policy_test.dart
    - test/helpers/fakes/fake_graphql_ws_server.dart
    - test/helpers/fakes/fake_graphql_ws_server_test.dart
decisions:
  - "D-09: 4409 joins the auth-rejected close codes; the close reason is ignored, the bounded attempt counter is shared with 4401/4403"
  - "D-06: the two-device proof asserts close codes on the CLIENT side (what the link's policy saw), not the server WebSocket.closeCode (that is the peer's echo and races with the client's own close)"
metrics:
  duration: "~25 min"
  completed: 2026-11-09
---

# Phase 12 Plan 15: 4409 and the two-device revocation harness Summary

A WebSocket closed `4409` (`wsSessionRevokedCloseCode`) now takes the `4401` path in `WsReconnectPolicy` (single-flight refresh first, bounded, close reason ignored), and an in-process two-device harness on `FakeSessionBackend` + `FakeGraphQlWsServer` proves «l'ultimo login caccia l'altro» in its five D-06 cases; names proven on fakes; plan 16 proves them on the merged BE.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | 948d05f | test(graphql): expect the revoked-session close code to refresh first |
| 1 GREEN | a804bce | feat(graphql): treat close code 4409 like an expired token |
| 2 RED | 9374553 | test(test): expect closeSocket and a connection_init hook on the WS fake |
| 2 GREEN | cc6fb1d | test(test): add the session backend fake and WS close hooks |
| 3 | 0365c63 | test(auth): prove the last login replaces the other device |

## What was built

- `lib/repository/services/graphql/ws_reconnect_policy.dart`: `const int wsSessionRevokedCloseCode = 4409;` (top-level, doc citing BE `WS_SESSION_REVOKED_CLOSE_CODE` and D-09); `static const Set<int> authRejectedCloseCodes = {4401, 4403, wsSessionRevokedCloseCode};` (formatter splits it over lines); class doc «4401 / 4403 / 4409 … senza leggere il motivo della chiusura».
- `test/helpers/fakes/fake_graphql_ws_server.dart`: `bool Function(WebSocket ws, Map<String, dynamic>? payload)? onConnectionInit;` (null → ack as before; false → no ack), `Future<void> closeSocket(WebSocket ws, int code, String reason) => ws.close(code, reason);`, `dropWith` doc «4401/4403/4409/1001».
- `test/helpers/fakes/fake_session_backend.dart`: `FakeSessionBackend({required User user, DateTime? issuedAt /* default testNow */})`, `onRevoked(String sessionId, String reason)` (reason `''` when missing), `revokeAll(String? reason)`, `sessionIdOfAccessToken(String)`, `revokeReasonOf(String sessionId)` (null when active/unknown, `''` when revoked without reason). Session ids `s1`, `s2`…; refresh tokens `r-<sessionId>-<n>`; access tokens `buildTestJwt(issuedAt: issuedAt - n s, subject: user.id)` (unique, never stale with `now: () => testNow`); `accessTokenExpiresAt = issuedAt + 15 min`. `logout` revokes with `userLogout` without calling `onRevoked` (BE OQ3).
- `test/repository/services/auth/dual_session_revocation_test.dart`: `_Device` bundle (InMemorySessionStore, `SessionAuthTokenService(api: backend, browser: const _TicketBrowser(), backendBaseUrl: http://127.0.0.1/, onSessionTeardown: () => holder.reset(), now: () => testNow, createChallenge: () => _challenge)`, `GraphQLClientHolder` whose `connect` builds a `_RecordingWsReconnectPolicy` per link, recorded `states`); `_RecordingWsReconnectPolicy extends WsReconnectPolicy` (`closures` list of `({int? code, String? reason})`, `nextConnectAttempt` future completed by `buildInitialPayload`). Server hook maps the bearer to a session, closes a revoked one `4409 <reason>` at `connection_init`; `backend.onRevoked` closes the live socket of the session.

## TDD record

- Task 1 RED: 4 failures — `4409` returned the 1 s backoff instead of `authRetryDelay` (×3) and the failed-recovery case saw zero recovery calls.
- Task 2 RED: compile failure (`closeSocket` / `onConnectionInit` undefined).
- Task 3: product cases green at first run — the production path was written test-first in plan 14 (reason mapping) and Task 1 (4409 routing). The first run had three red cases caused by the HARNESS (server-side `WebSocket.closeCode` is the peer's code and is null/racy when the client closes on its own): the assertions were moved to the closures recorded by the client policy before committing. Mutation check: removing `wsSessionRevokedCloseCode` from the set turns all five cases red (20 s timeouts), restored before commit.
- Case (e) waits on the revoked link's single post-dispose reconnect attempt (`nextConnectAttempt`, fired by the graphql 5.2.1 timer about 1 s after the 4409, then dropped by the disposed check before any socket) and then a B round trip through the server; zero `connection_init` from A after the teardown.

Stability (three consecutive runs of the dual-session file):
```
00:03 +5: All tests passed!
00:02 +5: All tests passed!
00:02 +5: All tests passed!
```

## Gates

- `flutter test test/repository/services/graphql`: 182 green after Task 1 (194 with test/helpers/fakes after Task 2).
- `flutter test test/repository/services test/screens/auth test/helpers`: 698, All tests passed.
- `flutter analyze`: 47 issues found (all info), 0 error, 0 warning.
- `bash tool/hardening_check.sh`: `hardening_check: OK`.
- `dart format` on each touched file individually (no reflow of untouched members).
- Trailer check 0 on all five commits; no `flutter build` in this plan.

## Deviations from Plan

- [Test harness] The browser of each device is a private `_TicketBrowser implements BrowserAuthenticator` instead of a `MockBrowserAuthenticator` stub (same answer `klimmeck://auth?ticket=T`, no mocktail fallback registration needed).
- [Test harness] Close codes/reasons asserted on the client policy (`_RecordingWsReconnectPolicy.closures`) instead of the server socket's `closeCode`, see TDD record. Case (a) checks B's socket open through the round trip plus `closeCode == null`.
- [Test harness] Case (e) adds the deterministic `nextConnectAttempt` barrier before the B round trip so the proof covers the reconnect timer the disposed link still arms.

No product defect found; no `lib/` change beyond Task 1.

## Known Stubs

None.

## Note for the orchestrator

Names proven on fakes; plan 16 proves them on the merged BE. After this plan the review by area (D-14) runs before plan 16. Deferred idea from 12-08 still open: a session-scoped WS link wrapper that completes subscription streams on reset.

## Self-Check: PASSED
