---
phase: 03-real-time-sync-foundation
reviewed: 2026-10-14T00:00:00Z
depth: standard
files_reviewed: 59
files_reviewed_list:
  - lib/config/env_config.dart
  - lib/graphql/subscriptions/user_subscriptions.dart
  - lib/main.dart
  - lib/repository/services/auth/auth.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/services/auth/session_terminator.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/graphql/graphql_client_holder.dart
  - lib/repository/services/graphql/graphql_client_provider.dart
  - lib/repository/services/graphql/graphql_error_code.dart
  - lib/repository/services/graphql/graphql_sync_exceptions.dart
  - lib/repository/services/graphql/socket_connection_monitor.dart
  - lib/repository/services/sync/app_lifecycle_events.dart
  - lib/repository/services/sync/sync_health.dart
  - lib/repository/services/sync/sync_watchdog.dart
  - lib/repository/services/sync/user_refresh_requests.dart
  - lib/screens/auth/app_lifecycle_bridge.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/auth/session_home.dart
  - lib/screens/auth/session_sync_scope.dart
  - lib/screens/auth/syncCubit/session_sync_cubit.dart
  - lib/screens/auth/syncCubit/session_sync_state.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/screens/signIn/sign_in_screen.dart
  - lib/utils/silent_retry.dart
  - pubspec.yaml
  - test/graphql/user_subscription_documents_test.dart
  - test/helpers/fakes/fake_graphql_ws_server.dart
  - test/helpers/fakes/fake_graphql_ws_server_test.dart
  - test/helpers/fakes/recording_sync_health.dart
  - test/helpers/fixtures/sync_event_fixtures.dart
  - test/helpers/fixtures/sync_event_fixtures_test.dart
  - test/helpers/mocks.dart
  - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
  - test/repository/services/auth/session_auth_token_service_terminate_test.dart
  - test/repository/services/graphql/graphql_error_code_test.dart
  - test/repository/services/graphql/graphql_sync_test.dart
  - test/repository/services/graphql/socket_connection_monitor_test.dart
  - test/repository/services/graphql/ws_resubscribe_integration_test.dart
  - test/repository/services/sync/app_lifecycle_events_test.dart
  - test/repository/services/sync/sync_watchdog_test.dart
  - test/repository/services/sync/user_refresh_requests_test.dart
  - test/screens/auth/app_lifecycle_bridge_test.dart
  - test/screens/auth/auth_gate_test.dart
  - test/screens/auth/authenticated_shell_test.dart
  - test/screens/auth/cubit/auth_cubit_test.dart
  - test/screens/auth/session_home_test.dart
  - test/screens/auth/session_sync_scope_test.dart
  - test/screens/auth/syncCubit/session_sync_cubit_test.dart
  - test/screens/mainScreen/characterCubit/character_cubit_test.dart
  - test/screens/signIn/sign_in_screen_test.dart
  - test/tool/schema_check_documents_test.dart
  - test/utils/silent_retry_test.dart
  - tool/schema_check/dump_documents.dart
  - tool/schema_check/schema_check_documents.dart
  - tool/schema_check/validate_documents.js
findings:
  critical: 0
  warning: 3
  info: 6
  total: 9
status: issues_found
---

# Phase 3: Real-Time Sync Foundation — Code Review

Scope: the 59 files listed in the frontmatter (phase diff against `develop` @ `326b9f0`), reviewed at standard depth against `CLAUDE.md`, `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md` and the Phase 3 decisions (D-03, D-14, D-15). `flutter analyze` on the Phase 3 `lib/`, `tool/` and test directories reports no issues (57 pre-existing issues elsewhere, unchanged).

## Summary

Production code is solid against the project rules and decisions D-03, D-14 and D-15.

- **Subscription leaks and `close()` ordering:** none found. Every subscription and timer is cancelled in `close()`. `SafeEmit` covers late emits. The `release()` calls run before `super.close()`, and the watchdog latch makes a late `release` harmless.
- **Terminal handling:** FORBIDDEN and NOT_FOUND are terminal in both cubits, with a single `me` refresh request and no hot loop.
- **Stale results:** `CharacterCubit` is correct, using a generation counter plus event count. `SessionSyncCubit` is correct except for the single-flight caveat in WR-01.
- **Watchdog:** the timing is correct. It runs only on continuous degradation, is suspended in background, and fires once. A terminated stream counts as degraded only when no stream is healthy.
- **Logging and payloads:** exceptions carry only operation name and code. Logs print only `code` or `runtimeType`. Malformed payloads become `FormatException('... malformed: <runtimeType>')`.
- **Token rotation:** `buildInitialPayload` reads the current token on every connect and never throws.
- **Project rules:** no blocking loading in session (all refetches are silent), the backend stays the source of truth, and the layering respects `architecture.md`.

## Warnings

### WR-01: `refreshUser` single-flight can hand the stream-rejection recovery an older response

**File:** `lib/screens/auth/syncCubit/session_sync_cubit.dart:86-87, 134, 151-161`
**Issue:** `refreshUser()` returns the in-flight future. The terminal-stream recovery (`_terminateUserStream`, or `CharacterCubit` via the request bus) is meant to pick up a changed `currentCharacter`. If a foreground refetch started earlier, the recovery joins that older request, which can return the pre-change `currentCharacter`. The shell then never re-keys, and the character stream stays terminated until the next foreground. Joining a request that is in a 60 s retry backoff also delays recovery.
**Fix:** Queue one follow-up refetch when a request arrives during a flight, for example a `_refreshQueued` flag. Alternatively, make terminal-triggered refreshes bypass the join:

```dart
Future<void> refreshUser({bool force = false}) {
  final inFlight = _refreshInFlight;
  if (inFlight != null && !force) return inFlight;
  return _refreshInFlight = (inFlight ?? Future<void>.value())
      .then((_) => _performUserRefresh())
      .whenComplete(() => _refreshInFlight = null);
}
```

### WR-02: A user-stream resubscribe can run against the freshly recreated client during session teardown

**File:** `lib/screens/auth/syncCubit/session_sync_cubit.dart:120-149`, `lib/repository/services/graphql/graphql_client_holder.dart:43-54`, `lib/repository/services/auth/session_auth_token_service.dart:524-530`
**Issue:** `_endSession` first forgets the session, then runs `holder.reset()`, then clears the store, and only then emits `AuthUnauthenticated`. Disposing the link completes the `userUpdated` stream while the cubit is still alive. `onDone` calls `_scheduleResubscribe` with a 1 s timer. If the store clear plus teardown takes longer than that, `_subscribeToUser` resolves the new client and opens a socket on the new link with no token. That socket then sits unauthenticated on SignIn. It retries against 4403 with backoff, and the next login's `watchConnection` finds a socket that is already open.
**Fix:** Stop the cubit's resubscribe path once a session end is under way. For example, have the watchdog `onExpired` and the auth channel mark the scope as ending, or have `SessionSyncCubit` skip `_scheduleResubscribe` and `_subscribeToUser` when `_watchdog.isLatched` is true. A smaller option is to expose `bool get isExpired` on `SyncWatchdog` and check it in the timer callback.

### WR-03: `SyncWatchdog._expire` swallows nothing, so a failing terminate becomes an unhandled async error

**File:** `lib/repository/services/sync/sync_watchdog.dart:100-104`
**Issue:** `unawaited(_onExpired())` has no error handler. If `terminateSession` throws, for example `_channel.emit` on a closed channel or a store failure, the error is unhandled. The watchdog is latched, so there is no second attempt and the user stays in a dead session.
**Fix:**

```dart
void _expire() {
  _timer = null;
  _isLatched = true;
  unawaited(_onExpired().catchError((Object error) {
    debugPrint('[Sync] watchdog teardown failed: ${error.runtimeType}');
  }));
}
```

## Info

### IN-01: Terminated user stream during character creation leads to logout after 3 minutes

**File:** `lib/repository/services/sync/sync_watchdog.dart:30-36`, `lib/main.dart:~230`
**Issue:** The scope also covers the creation screen, where no character stream exists. If `userUpdated` is rejected with FORBIDDEN or NOT_FOUND there, `isDegraded` stays true and the user is logged out mid-form with "Connessione persa". The one-shot `touch()` after the refetch only extends the window once. This follows the accepted Open Question 3 but is a user-visible data-loss path. Consider documenting it in the plan notes, or counting the creation phase as healthy.

### IN-02: `DevAuthTokenService.terminateSession` has no logout-in-flight guard

**File:** `lib/repository/services/auth/dev_auth_token_service.dart:96-101`
**Issue:** The session service skips termination while `_logoutInFlight != null`. The dev stub does not, so a concurrent `logout()` and watchdog expiry emit two `AuthUnauthenticated` states, and the reason may be overwritten with `syncLost`.
**Fix:** Track a `_logoutInFlight` future in the dev stub and return early, as the session service does.

### IN-03: A terminated character stream never recovers if the refetch returns the same character id

**File:** `lib/screens/mainScreen/characterCubit/character_cubit.dart:130-140`
**Issue:** Recovery depends on the shell re-keying when `currentCharacter.id` changes. If the FORBIDDEN was transient or the id is unchanged, the stream stays terminated until app restart. Foreground refetches keep the state roughly fresh, and `markTerminated` stops the watchdog from logging out. Backend behaviour makes this acceptable, but it is a silent, permanent loss of live updates.
**Fix:** Optionally allow one delayed resubscribe attempt after a successful `me` refetch that kept the same id. `loadCharacter` also does not reset `_isStreamTerminated`, `_attempt` or `_resubscribeTimer` on a repeated call. That path is currently only reachable after a failed load, so it is latent.

### IN-04: `silentRetry` delays are not cancellable, and its documentation understates the worst case

**File:** `lib/utils/silent_retry.dart:3-4, 33`
**Issue:** `Future.delayed` keeps a closed cubit's refresh alive for up to 60 s. It is harmless because `isCancelled` is checked afterwards, but it leaves pending timers. The "about 2 minutes" comment ignores the 30 s per-attempt `queryRequestTimeout`: a worst case of 8 attempts plus 123 s of backoff is well over 3 minutes. `touch()` re-arms the window anyway.
**Fix:** Correct the comment, or use a cancellable timer.

### IN-05: `CharacterError(error.toString())` surfaces raw exception text

**File:** `lib/screens/mainScreen/characterCubit/character_cubit.dart:72`, `lib/repository/services/graphql/graphql.dart:39-52`
**Issue:** `getGenericErrorMessage` interpolates `linkException` and server messages. The access-denied case also exposes `GraphQlAccessDeniedException(character, code: ...)`. This is pre-existing and cold-start only. If the text is ever rendered, map it to a fixed user message instead.

### IN-06: Tooling scripts are fragile and carry a machine-specific path

**File:** `tool/schema_check/validate_documents.js:6`, `tool/schema_check/dump_documents.dart:10`
**Issue:** The usage comment hardcodes `/Users/lucatabbia/...`. `validate_documents.js` crashes with an unhelpful error when its arguments are missing, and `args.single` throws `StateError` on a wrong argument count.
**Fix:** Use a placeholder such as `$BE_REPO`, and add `if (!schemaPath || !docsDir) { console.error('usage: ...'); process.exit(2); }` plus an equivalent check in the Dart script.

## Tests

No reliability problems found. Assertions are present and the fakes are deterministic.

---

_Reviewed: 2026-10-14_
_Reviewer: Claude (gsd-code-reviewer, sonnet)_
_Depth: standard_
