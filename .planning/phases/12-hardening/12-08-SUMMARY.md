---
phase: 12-hardening
plan: 08
subsystem: auth
tags: [hardening, auth, logout, refresh, single-flight, websocket]
requires: ["12-07"]
provides:
  - "test/repository/services/auth/logout_flow_test.dart: HARDEN-03 end-to-end logout flow over the loopback WebSocket (real SessionAuthTokenService + GraphQLClientHolder + AuthCubit)"
  - "test/repository/services/auth/concurrent_unauthorized_refresh_test.dart: HARDEN-04 single flight through the real AuthAuthLink and AuthInterceptor"
affects: [12-09, 12-15, 12-17]
tech-stack:
  added: []
  patterns:
    - "Recording onSessionTeardown wrapper around holder.reset() to place the link disposal in the logout sequence"
    - "Real-time loopback flow with now: () => testNow injected into the service"
key-files:
  created:
    - test/repository/services/auth/logout_flow_test.dart
    - test/repository/services/auth/concurrent_unauthorized_refresh_test.dart
  modified: []
decisions:
  - "Orchestrator ruling (Rule 4, option A): HARDEN-03 asserts the CLIENT-side teardown order of Phase 11 D-12; the server-side socket close and stream completion are not part of the guarantee"
  - "No production change: both flows confirm existing behaviour (D-08 audit)"
metrics:
  duration: "~45 min (including the checkpoint round trip)"
  completed: 2026-11-09
---

# Phase 12 Plan 08: Atomic logout flow and concurrent 401 single flight Summary

Two test-only proofs (D-08 «verified, not reinvented»): the atomic logout runs end to end over a real loopback socket in the order push unregister → backend logout with the own token → WS link disposed and client recreated → store cleared → `AuthUnauthenticated(signedOut)`, the old client is GC'd; two concurrent unauthorized answers (GraphQL + REST) on one `SessionAuthTokenService` share exactly one rotation and never sign the user out.

## Tasks

| Task | Name | Commit | Files |
| ---- | ---- | ------ | ----- |
| 2 | Concurrent 401 share one refresh (HARDEN-04) | a8a27b0 | test/repository/services/auth/concurrent_unauthorized_refresh_test.dart |
| 1 | End-to-end logout flow (HARDEN-03) | 032b1ee | test/repository/services/auth/logout_flow_test.dart |

Task 2 was committed before Task 1 because Task 1 waited on the orchestrator's ruling (checkpoint); the tasks are independent.

## Tests and first-run outcome

`logout_flow_test.dart` (6 tests, `test(...)` only, `Timeout(Duration(seconds: 20))`, no `Future.delayed`):

| Test | Outcome |
| ---- | ------- |
| logout tears the session down in order: push, backend logout, link disposed, store cleared, signedOut (D-08) | green after the ruling; product order already held. The first draft (server `done` in the sequence) failed, see Deviations; one intermediate run failed only because the test asserted before the async `signedOut` delivery — fixed with an `emitsThrough(const AuthUnauthenticated())` barrier (test defect, not product) |
| the server socket is closed after logout (D-08) | green at first run: the flow already holds (D-08 audit) |
| the old subscription stays silent after logout (D-08) | green at first run: the flow already holds (D-08 audit) |
| logout replaces the GraphQL client with a new one (D-08) | green at first run: the flow already holds (D-08 audit) |
| the old GraphQL client is released after logout (D-05) | green at first run: `forceGC(fullGcCycles: 3, timeout: 10 s)` awaited directly in `test(...)` clears the `WeakReference<GraphQLClient>` |
| logout closes only the own session on the backend (D-10) | green at first run: the flow already holds (D-08 audit) |

Recorded `events` order (final): `['push.unregister', 'api.logout:<a1>', 'socket.close.sent', 'store.clear', 'state:signedOut']`.
Recorded order of the first draft (server-side `done` as the marker): `['push.unregister', 'api.logout:<a1>', 'store.clear', 'state:signedOut', 'socket.closed']`.

`concurrent_unauthorized_refresh_test.dart` (3 tests): all green at first run — single flight already holds through both links (D-08 audit).
- two concurrent unauthorized answers trigger exactly one refresh (D-08)
- both requests are retried with the refreshed token (D-08)
- concurrent unauthorized answers never sign the user out (D-08)

## Deviations from Plan

### Rule 4 ruling by the orchestrator (Task 1, option A)

- **Found during:** Task 1, first run of the draft.
- **Issue:** two behaviours of the plan could not hold without changing the GraphQL link layer:
  1. the server's `WebSocket.done` fires one round trip after `holder.reset()` resolves (graphql 5.2.1 `WebSocketLink.dispose()` resolves when the close frame is flushed), so it lands after `store.clear` and the emit; a bounded wait on the channel in `reset()` was tried and reverted (no effect, no trace in git);
  2. with graphql 5.2.1 and `autoReconnect: true`, a subscription stream never completes after dispose (`websocket_client.dart:543-555` closes the response only when `!config.autoReconnect`): it only goes silent.
- **Ruling:** CONTEXT D-08 says HARDEN-03 is «verified, not reinvented». The product guarantee of Phase 11 D-12 is the CLIENT-side teardown order, and the recording shows it holds (close frame flushed by `holder.reset()` before `store.clear`). The server `done` is an asynchronous observation, not part of the guarantee. In the app the subscription listeners are cancelled by the cubits closed when `AuthGate` rebuilds the keyed subtree (Phase 11 D-12/D-26), which plan 12-09's shell-level leak test proves.
- **Change:** the order test records `socket.close.sent` through the recording `onSessionTeardown` wrapper (`holder.reset().then(recordCloseSent)`); the server close is a separate test (`await socket.done`, `closeCode != null`); `emitsDone` became a silence proof (after logout and the old socket's `done`, the server emits the old subscription id on the new socket; the new subscription receives its own event as the real signal, then `pumpEventQueue()`, the old stream's events list stays empty).
- **Deferred idea (D-14 review by area, not a fix here):** a session-scoped wrapper around the `WebSocketLink` that closes every subscription's stream on `GraphQLClientHolder.reset()` (listeners would get `onDone`), plus a bounded wait for the server close handshake.

### Other

- **[Rule 3] Clock injection:** both files pass `now: () => testNow` to the service; with the default `DateTime.now` the fixture JWTs (dated 2026-10-06) are stale and every `getAccessToken()` would refresh.
- **[Rule 3] Name clash:** `import 'package:dio/dio.dart' hide Response;` in the concurrency test (gql_exec `Response`); the REST status is returned as `int?`.
- **Gate literal:** the doc comment of the logout test no longer names `testWidgets` (acceptance grep `= 0`).

## Gates

- `flutter test test/repository/services/auth test/network test/screens/auth/cubit`: +201, All tests passed.
- `logout_flow_test.dart` run 5 times in a row: +6 each time.
- `flutter analyze`: 47 issues, all info, 0 error, 0 warning.
- `dart format` on both files individually.
- Acceptance greps: logout test `D-08)` 4, `D-05)` 1, `D-10)` 1, `WeakReference<GraphQLClient>` 2, `forceGC(` 1, leak_tracker import 1, `Future.delayed` 0, `testWidgets` 0, key link `onSessionTeardown: .*holder\.reset` 1; concurrency test `D-08)` 3, `AuthAuthLink(` 1, `AuthInterceptor(` 1, `Completer` 4, `Future.delayed` 0.
- Trailer check 0 on both commits.

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: test/repository/services/auth/logout_flow_test.dart
- FOUND: test/repository/services/auth/concurrent_unauthorized_refresh_test.dart
- FOUND: a8a27b0, 032b1ee
