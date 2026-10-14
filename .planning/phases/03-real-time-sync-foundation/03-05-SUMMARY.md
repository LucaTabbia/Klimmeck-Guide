---
phase: 03-real-time-sync-foundation
plan: 05
subsystem: graphql-transport
tags: [websocket, keep-alive, reconnect, resubscribe, token-rotation, integration-test]
requires: [03-01]
provides:
  - buildWebSocketLink (shared by production and tests)
  - connectWithKeepAlive / openKeepAliveChannel (ping 25 s, connect timeout 10 s)
  - SocketConnectionMonitor.watch() and GraphQLClientHolder.watchConnection()
  - real-socket regression tests for SYNC-03, SYNC-04, SYNC-06
affects: [03-06, 03-07, 03-09]
tech-stack:
  added: [web_socket_channel ^3.0.3 (promoted to direct, locked 3.0.3 unchanged)]
  patterns: [plain test() against a loopback graphql-transport-ws server, monitor creates the socket client only when absent]
key-files:
  created:
    - lib/repository/services/graphql/socket_connection_monitor.dart
    - test/repository/services/graphql/socket_connection_monitor_test.dart
    - test/repository/services/graphql/ws_resubscribe_integration_test.dart
  modified:
    - lib/repository/services/graphql/graphql_client_provider.dart
    - lib/repository/services/graphql/graphql_client_holder.dart
    - lib/config/env_config.dart
    - pubspec.yaml
    - pubspec.lock
key-decisions:
  - "Keep-alive lives in a testable openKeepAliveChannel with named interval parameters; connectWithKeepAlive is the production default"
  - "Old-listener silence after reset is asserted as no further events, not stream completion (dispose does not close the Dart stream)"
requirements-completed: [SYNC-03, SYNC-04, SYNC-06]
duration: 25min
completed: 2026-10-14
---

# Phase 3 Plan 05: Socket transport and real-socket proof Summary

Keep-alive WebSocket connect (ping 25 s, connect timeout 10 s) behind a shared `buildWebSocketLink`, an observable `Stream<bool>` socket state via `GraphQLClientHolder.watchConnection()`, and 12 loopback tests proving resubscribe on the same stream, token rotation on the same link, FORBIDDEN wire behaviour and logout teardown.

## Commits
- ee01350 test(graphql): failing real-socket tests for resubscribe and token rotation
- 183af28 feat(graphql): detect half-open sockets with a keep-alive connect
- c3bb7f4 test(graphql): failing tests for socket observation and reset teardown
- 3c5c97a feat(graphql): expose the session socket state

## Verification
- Full `flutter test`: 579 passing (baseline 567, +12)
- `flutter analyze`: 57 issues, identical to baseline; touched files clean and formatter-clean
- Integration tests run 3 times in a row: 12/12 green each time
- `pubspec.lock` diff: only `web_socket_channel` `dependency: transitive` to `"direct main"`

## Deviations from Plan

**1. [Rule 1 - Plan assumption wrong] `innerWebSocket` does not exist in web_socket_channel 3.0.3.** The keep-alive test could not read `innerWebSocket.pingInterval`. Replaced with: a constants test (25 / 10), a test that `connectWithKeepAlive` returns a ready `IOWebSocketChannel`, and a behavioural test where a peer that never answers pings gets the channel closed with `goingAway` (100 ms ping). To allow the short interval, `connectWithKeepAlive` delegates to a new `openKeepAliveChannel(uri, protocols, {pingInterval, connectTimeout})`.

**2. [Rule 1 - Test shape] Reset teardown asserts "no more events" on the old listener** instead of stream completion: `WebSocketLink.dispose` closes the socket but does not complete the Dart stream.

**3. Test polling.** `_untilFrames` uses `Stream.periodic(...).firstWhere(...).timeout(5s)` (no `Future.delayed`) to wait for the reconnect handshake after a FORBIDDEN completion.

## Findings
- After a FORBIDDEN `complete`, the socket still reconnects (second `connection_init`) but never re-sends the completed operation: cubits own the retry policy.
- First reconnect delay is 1 s (policy backoff), so each drop test takes about 1 s of real time.

## Known Stubs
None.

## Threat Flags
None. T-03-05-01..05 mitigated as planned; T-03-05-06 (cleartext `ws://`) remains transferred to Phase 12.

## Self-Check: PASSED
