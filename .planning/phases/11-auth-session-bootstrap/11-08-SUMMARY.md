---
phase: 11-auth-session-bootstrap
plan: 08
subsystem: auth
tags: [graphql, websocket, reconnect, backoff, client-lifecycle]
requires: [11-07]
provides:
  - WsReconnectPolicy (current-token connection_init, refresh on 4401/4403, capped backoff)
  - buildGraphQLConnection (synchronous factory, replaces initGraphQLClient)
  - GraphQLClientHolder (reset = dispose WebSocketLink + recreate client/link)
affects: [11-09, 11-10, 11-11]
tech-stack:
  added: []
  patterns: [injected clock for time-based policy, record typedef for client+link pair, ValueNotifier holder]
key-files:
  created:
    - lib/repository/services/graphql/ws_reconnect_policy.dart
    - lib/repository/services/graphql/graphql_client_holder.dart
    - test/repository/services/graphql/ws_reconnect_policy_test.dart
    - test/repository/services/graphql/graphql_client_holder_test.dart
  modified:
    - lib/repository/services/graphql/graphql_client_provider.dart
    - lib/main.dart
key-decisions:
  - "The 500 ms auth retry delay is granted only to the first attempt after a stable connection; repeated auth rejections fall into the capped backoff (no 500 ms refresh loop)"
  - "The WebSocketLink is never recreated after a refresh (D-37); only GraphQLClientHolder.reset() disposes and recreates it"
  - "main.dart passes no recovery yet: wiring the real service + recovery is 11-10's job"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 08: WS silent re-auth and GraphQL client holder Summary

The WebSocket now sends the CURRENT token on every (re)connect, recovers through `UnauthorizedRecovery` on close 4401/4403 before reconnecting (about 500 ms), and otherwise backs off 1/2/4…60 s, resetting only after a connection that lasted 30 s or more. `GraphQLClientHolder.reset()` disposes the socket and installs a fresh client in the `ValueNotifier` that `GraphQLProvider` listens to. `initGraphQLClient` (which captured the token once at boot) is gone.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | 1857c45 | test(phase-11): add websocket reconnect policy specs |
| T1 GREEN | 391560a | feat(phase-11): add websocket reconnect policy with current-token init payload |
| T2 RED | 27bfa38 | test(phase-11): add graphql client holder reset specs |
| T2 GREEN | 27e0b76 | feat(phase-11): add graphql client holder and synchronous auth-aware connection factory |

## Results

- `flutter test`: **189 tests, all passed** (baseline 168, plus 15 policy specs and 6 holder/factory specs)
- `flutter analyze lib test`: **14 issues** (equal to the baseline; zero in the plan's files)
- `dart format --output=none --set-exit-if-changed` on the 6 plan files, by explicit path: exit 0 (`lib/main.dart` was already formatter-clean, so no exclusion was needed)
- Close codes and the payload key were checked against the backend's `02-RESEARCH.md` §Q2 (there is no `BACKEND-NOTES.md` in BE phase 02 yet): 4403 = rejected at connect, 4401 + `Token expired` = JWT expired on a live socket, payload `{'Authorization': 'Bearer <jwt>'}`. They match the plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Correctness / T-11-36] The 500 ms auth retry is bounded**
- **Found during:** Task 1
- **Issue:** In the plan's algorithm, `onConnectionLost` returns `authRetryDelay` whenever recovery yields a token, and it does not touch `_attempt`. If the server kept rejecting the socket (for example 4403 for a reason a refresh cannot fix) while the refresh kept succeeding, the app would reconnect and refresh every 500 ms forever. That breaks the "no hot loop" truth.
- **Fix:** The 500 ms delay is used only when `_attempt == 0`, which means the first failure after a stable connection (or the first failure ever). The attempt counter is then incremented. Any further auth rejection before the connection stabilises calls recovery again (single-flight) but returns the exponential backoff (2 s, 4 s, …, capped at 60 s). The normal 15-minute expiry still gets the 500 ms path, because that connection was stable and the counter was reset.
- **Test:** "repeated rejections right after a recovered token do not loop hot" expects `[500 ms, 2 s, 4 s, 8 s]`.
- **Commit:** 391560a

**2. [Rule 3 - Blocking] Nullable compare in the RED spec**
- `onConnectionLost` returns `Future<Duration?>` (the library's signature), so `delays.every((d) => d <= max)` did not compile. Changed it to `d!`, and the change went into the GREEN commit 391560a.

**3. [Style] `recoverFromUnauthorized(rejectedToken: _lastSentToken)` kept on one line**
- The call was extracted into a small `_refreshedToken(recovery)` arrow method, so the formatter keeps the plan's grep-checked expression on one line. Behaviour is the same as the plan's inline try/catch.

## Decisions Made

- `buildGraphQLConnection` uses `const Duration(seconds: EnvConfig.…)`. The EnvConfig values are compile-time `fromEnvironment` constants, so this is legal and lint-clean.
- `GraphQLClientHolder.reset()` is idempotent: each reset disposes only the link it currently owns, so two resets in a row dispose two distinct links and connect three times in total (tested). A dispose that throws is logged with `runtimeType` only and the new client is still installed (tested).
- The factory reads no token at construction (tested with `verifyZeroInteractions`). The `WebSocketLink` has no `SocketClient` until the first subscription.

## Notes for 11-09 / 11-10 (composition root wiring)

1. **Recovery:** `main.dart` currently calls `buildGraphQLConnection(authService: authTokenService)` with **no `recovery`**, so the dev stub keeps working and WS 4401/4403 just back off. When 11-10 builds the real `SessionAuthTokenService`, pass the same instance as the recovery to the GraphQL factory and to `RestClient(... recovery:)`. Use `recovery: service is UnauthorizedRecovery ? service as UnauthorizedRecovery : null`, or keep a typed reference to the real service. The dev stub does not implement `UnauthorizedRecovery`, so it must stay `null`.
2. **Holder lifetime:** create `GraphQLClientHolder(connect: () => buildGraphQLConnection(authService: service, recovery: recovery))` once in `main()`. The `connect` closure is called again on every `reset()`, so it must capture the same service and recovery. Pass `holder.client` (a `ValueNotifier<GraphQLClient>`) to `GraphQLProvider`, which must stay **above `MaterialApp`** because `KlimmeckGraphQl` resolves the client via `navigatorKey.currentContext`.
3. **Teardown hook:** `onSessionTeardown` on the session service must call `holder.reset()` (D-12 step 3), for example `onSessionTeardown: () => holder.reset()`. There is a chicken-and-egg problem: the service needs the hook, and the holder's factory needs the service. The simplest fix is to build the service with a hook closure that refers to a `late final GraphQLClientHolder holder` declared before it. `reset()` is safe to call twice in a row (the SessionRejected-inside-logout edge case).
4. **What stops reconnects after a session ends:** the policy itself never stops the `SocketClient`. Once the service is `Unauthenticated`, `getAccessToken()` returns null, the payload is `{}`, the server answers 4403 and recovery returns null, so the client backs off up to 60 s. The socket is actually stopped by `holder.reset()` through the teardown hook. That hook **must** be wired in 11-10, or a dead socket keeps retrying every 60 s.
5. **Missed events in the reconnect gap** are not replayed; refetch-on-reconnect belongs to Phase 3 (note it in BACKEND-NOTES in 11-11).
6. **Also:** `RestClient` in `main.dart` is still built without `recovery` (unchanged, 11-10).

## Known Stubs

None. Passing no recovery in `main.dart` is intentional for the dev-bypass path and is wired in 11-10.

## Threat Flags

None. No new endpoints or trust boundaries beyond the plan's threat model (T-11-35..T-11-38 are mitigated as planned; T-11-36 is strengthened by deviation 1).

## Self-Check: PASSED

- FOUND: lib/repository/services/graphql/ws_reconnect_policy.dart
- FOUND: lib/repository/services/graphql/graphql_client_holder.dart
- FOUND: test/repository/services/graphql/ws_reconnect_policy_test.dart
- FOUND: test/repository/services/graphql/graphql_client_holder_test.dart
- FOUND commits: 1857c45, 391560a, 27bfa38, 27e0b76
