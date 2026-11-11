---
phase: 12-hardening
reviewed: 2026-11-09T18:37:03Z
depth: standard (three parallel reviewers by area, CONTEXT D-14: A session/WS/auth, B bootstrap/release/logging infrastructure, C classifiers/models/map/cubit lifecycle)
files_reviewed: 81
files_reviewed_list:
  - .github/workflows/ci.yml
  - .gitignore
  - CLAUDE.md
  - android/app/build.gradle.kts
  - env/dev.json
  - env/prod.json
  - lib/bootstrap/app_bootstrap.dart
  - lib/bootstrap/auth_composition.dart
  - lib/bootstrap/dev_auth_composition.dart
  - lib/bootstrap/insecure_transport_screen.dart
  - lib/bootstrap/klimmeck_guide_app.dart
  - lib/bootstrap/session_auth_composition.dart
  - lib/config/env_config.dart
  - lib/config/insecure_transport_error.dart
  - lib/main.dart
  - lib/main_dev.dart
  - lib/models/enums/city_type.dart
  - lib/repository/cache/image_warmer.dart
  - lib/repository/character_creation_failure.dart
  - lib/repository/character_creation_repository.dart
  - lib/repository/character_deletion_failure.dart
  - lib/repository/innkeeper_failure.dart
  - lib/repository/push_device_failure.dart
  - lib/repository/quest_abandon_failure.dart
  - lib/repository/quest_acceptance_failure.dart
  - lib/repository/quest_result_failure.dart
  - lib/repository/services/auth/auth.dart
  - lib/repository/services/auth/auth_api_exception.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/graphql/graphql_client_holder.dart
  - lib/repository/services/graphql/graphql_error_code.dart
  - lib/repository/services/graphql/ws_reconnect_policy.dart
  - lib/repository/services/push/data_message_handler.dart
  - lib/repository/services/push/local_notifications_startup.dart
  - lib/repository/services/push/notification_tap_router.dart
  - lib/repository/services/push/push_bootstrap.dart
  - lib/repository/services/push/push_registration_coordinator.dart
  - lib/repository/services/push/url_launcher_link_opener.dart
  - lib/repository/services/rest/auth_interceptor.dart
  - lib/repository/services/rest/rest.dart
  - lib/repository/services/rest/rest_client_provider.dart
  - lib/repository/services/sync/sync_watchdog.dart
  - lib/repository/storage/session_store.dart
  - lib/repository/transaction_failure.dart
  - lib/repository/travel_failure.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/cubit/auth_cubit.dart
  - lib/screens/auth/notificationIntentCubit/notification_intent_cubit.dart
  - lib/screens/auth/syncCubit/session_sync_cubit.dart
  - lib/screens/characterCreation/components/character_creation_messages.dart
  - lib/screens/characterCreation/cubit/character_creation_cubit.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/screens/mainScreen/cubit/main_screen_cubit.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
  - lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart
  - lib/screens/mainScreen/questCubit/quest_cubit.dart
  - lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
  - lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart
  - lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart
  - lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart
  - lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart
  - lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart
  - lib/screens/mainScreen/travelCubit/travel_notice.dart
  - lib/screens/signIn/sign_in_screen.dart
  - lib/screens/splash/cubit/splash_cubit.dart
  - lib/shared/components/cached_svg.dart
  - lib/utils/app_log.dart
  - pubspec.yaml
  - test/helpers/fakes/fake_graphql_ws_server.dart
  - test/helpers/fakes/fake_graphql_ws_server_test.dart
  - test/helpers/fakes/fake_session_backend.dart
  - test/helpers/fixtures/dev_auth_env.dart
  - test/helpers/leak_tracking_bloc_observer.dart
  - tool/hardening_check.sh
findings:
  critical: 0
  warning: 5
  info: 20
  total: 25
status: issues_found
---
# Code review — Phase 12 Hardening (merge of groups A, B, C)

The three group reports (`12-REVIEW-A.md`, `12-REVIEW-B.md`, `12-REVIEW-C.md`) remain the source; this file merges them by severity.

## Summary

### Group A
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

### Group B
Bootstrap, release build, logging and CI infrastructure are in good shape. Verified clean:

- `lib/main.dart` is production-pure. `main_dev.dart` asserts the flavor before `dotenv.load`.
- The dev factory falls back to the session factory.
- `secureTransportBlocker` runs before push and before any client.
- The barrel no longer exports the dev service.
- `EnvConfig` precedence (override, then dart-define, then default) and blank-override handling are correct.
- Scheme comparison is case-insensitive.
- The debug branch logs key names only.
- `InsecureTransportError` carries key names only.
- No credential, `$e` or `error.toString()` is interpolated in any of the 59 `appLog` call sites. Every site uses `${e.runtimeType}`.
- The `pubspec` default-flavor plus flavored `.env` asset, the Gradle signing and flavor configuration, `.gitignore` for `env/*.local.json` and `key.properties`, and `ci.yml` (pinned Flutter, `--no-fatal-infos`, timeout, no secrets, guard before and after the build) all match the CONTEXT decisions.
- The `FakeGraphQlWsServer` tests wait on real signals with 2 s timeouts, with no `Future.delayed`.

There are no criticals. The findings are:

- one race in the push registration lifecycle that the tests do not cover (B-WR-01);
- one untested critical-class wiring point, the blocker call site (B-WR-02);
- two guard-script weaknesses that fail open or are trivially bypassed (B-WR-03, B-WR-04);
- eight info items.

### Group C
Group C is in good shape. The `BAD_USER_INPUT` work is complete and consistent:
- `badUserInput` exists in all classifiers.
- `badUserInputCode` is reused everywhere (no duplicated literal).
- The generic copy is pinned on every surface.
- `PushDeviceFailure.badUserInput` is non-retryable (the coordinator uses `isRetryable`).
- `QuestResultsCubit` does not retry it and shows the notice.

`graphQlErrorCode` reads the `ServerException.parsedResponse.errors` path. It keeps the `connection` fallback when no code is found, and no classifier maps a transport failure to `badUserInput`.

The moderation codes are read tolerantly (`responseData is Map`, non-string codes fall through to `uploadFailed`), and the two copies are as fixed. `CityType.cityClass` is gone with no reference left in `lib/` or `test/`. `size` and `imageId` are kept, per the D-13c veto. The marker visibility derives from `City.size` (`null` is hidden). I found no token in a log and no dev-bypass reference in this group.

The one real defect is a stale submit banner on the character-creation sheet after the two new moderation outcomes. The rest is quality and test-coverage notes.

## Critical

### Group A

None.

### Group C

None.

## Warning

### Group A

None.

### Group B

### B-WR-01: an overlapped registration attempt can outlive `unregister()` and re-create the device row after logout

**File:** `lib/repository/services/push/push_registration_coordinator.dart:112-125, 135-140, 157-166`
**Issue:** `_attemptInFlight` holds only the latest attempt (`_trackAttempt` overwrites it). `_register` is called again by every `tokenRefreshes` event, every foreground retry and every login. The generation counter only cancels an older attempt BEFORE `_repository.register`. Older attempt A can already be past that check and awaiting the network when a token refresh starts B. `_attemptInFlight` then points to B, and `unregister()` drains only B (which returns at once, cancelled). A's `register` is still in flight and `unregister` sends the removal. If A lands on the BE after the removal, it upserts the same `deviceId` row again.
**Why it matters:** after logout the device keeps receiving pushes for the logged-out user (Pitfall 5, WR-01 of Phase 5, which the single-slot design only half closes). This is the same single-flight gap as in the previous phases' reviews. The window is narrow (token refresh while a register is in flight, then logout), but it is user-visible and privacy relevant, and no test covers overlapping attempts. The existing test at line 344 covers only a single in-flight attempt.
**Suggested fix:** track every in-flight attempt, not the last one: `final Set<Future<void>> _attemptsInFlight = {};`, add in `_trackAttempt`, remove in `whenComplete`, and in `_drainAttemptInFlight` do `await _guarded('registration drain', () => Future.wait(_attemptsInFlight.toList()).timeout(registrationDrainTimeout))`. RED test first in `push_registration_coordinator_test.dart`: log in with a `register` that blocks on a Completer, emit a token refresh so a second attempt starts, call `unregister()`, release the first completer, and assert that no `register` completes after `unregister` was sent (the fake backend ends with no row), or that `unregister` waited for both.

### B-WR-02: nothing proves `bootstrapApp` actually runs the secure-transport blocker first

**File:** `lib/bootstrap/app_bootstrap.dart:34-39` (tests: `test/bootstrap/insecure_transport_screen_test.dart`, `entry_points_test.dart`)
**Issue:** the tests cover `secureTransportBlocker` and `EnvConfig.requireSecureTransport` in isolation. No test covers the call site: `if (blocker != null) return runApp(blocker);` placed before `bootstrapPush()` and before `GraphQlBackendAuthApi.forEndpoint` / the holder / `RestClient`. Deleting that line, or moving it after the client construction, keeps the whole suite green, and the CI APK greps do not detect it either (they grep for dev markers, not cleartext).
**Why it matters:** this is the one place where a release that talks cleartext is prevented (HARDEN-01, D-03b). D-01/D-16 already protect the neighbouring ordering (`flavorAssert < dotenvLoad`) with a source-order test; this ordering has none.
**Suggested fix:** add to `test/bootstrap/entry_points_test.dart`, mirroring the D-16 test: read `lib/bootstrap/app_bootstrap.dart` and assert `indexOf('secureTransportBlocker(isRelease: isRelease)') < indexOf('bootstrapPush()')` and `< indexOf('GraphQlBackendAuthApi.forEndpoint')`, plus `contains('return runApp(blocker)')`. A sturdier option is to inject `bootstrapPush` into `bootstrapApp` (a defaulted parameter) and assert with `isRelease: true` plus cleartext overrides that the push, auth and client factories are never invoked.

### B-WR-03: the bundle greps in `hardening_check.sh` fail open when `unzip` cannot read the APK

**File:** `tool/hardening_check.sh:22-31`
**Issue:** the three checks compare the output of `unzip ... | grep -c ...` with `"0"`. If `unzip` fails (not installed, a truncated or 0-byte file that still passes `[ -f ]`, a corrupt archive), `grep -c` prints `0` and every check passes. `pipefail` does not help because only the printed count is tested, not the status of the command substitution.
**Why it matters:** the whole point of the script is a negative proof («no `DEV_AUTH_` in the release bundle»). A guard that is green on an unreadable artifact proves nothing, and the CI runner and local gate (12-16) rely on «hardening_check: OK».
**Suggested fix:** validate the archive once and fail closed:
```bash
if [ -f "$apk" ] && unzip -tq "$apk" >/dev/null 2>&1; then
  ...existing three checks...
else
  fail "$apk not found or not a readable archive"
fi
```
Also assert a positive control, for example `unzip -l "$apk" | grep -q 'lib/.*libapp.so'`, so a grep over an empty stream cannot pass.

### B-WR-04: the «SharedPreferences write mentions a token» grep is blind to the formatter's multi-line calls

**File:** `tool/hardening_check.sh:17` (and the allow-list at line 15)
**Issue:** line 17 greps `\.set(String|StringList)\(` and then filters for `token|jwt|bearer|secret` on the SAME line. `dart format` puts the arguments of any longer call on the following lines (see `library_bookmarks_store.dart:44-47`), so `prefs.setString(\n  _refreshTokenKey,\n  value,\n)` is not detected. The allow-list (line 15) includes `session_store.dart`, which already imports `shared_preferences` and sits next to the secure-storage code, so it is exactly the file where a later plan could write a token this way. The same one-line limitation applies to the credential grep at line 20 (`-A3` helps there, line 17 has no context).
**Why it matters:** D-18's token-hygiene claim («no SharedPreferences write of a token») is one of the three reasons the script exists, and a formatter-shaped diff bypasses it.
**Suggested fix:** use context like line 20: `grep -rn -A3 -E '\.set(String|StringList)\(' lib --include='*.dart' | grep -iE 'token|jwt|bearer|secret' && fail "..."`. Optionally restrict the allow-list entry for `session_store.dart` to `setBool` with a dedicated check. RED check: a scratch copy of the script run against a file containing the multi-line `setString(\n _tokenKey, v)` form must exit 1.

### Group C

### C-WR-01: Moderation notice stays on screen after the player acts on it

**File:** `lib/screens/characterCreation/cubit/character_creation_cubit.dart:60-75`
**Issue:** `pickPortrait` and `removePortrait` never clear `submitFailure`.
- After `imageRejected`, the cubit clears `portraitPath` and the banner says «Immagine non ammessa, scegline un'altra.». The player picks a new image, and the old banner stays next to the new portrait until they edit a text field (`_editDraft` is the only place that resets it).
- After `moderationUnavailable`, the banner says «riprova o procedi senza immagine». Tapping Remove (the «proceed without image» path) leaves that banner on screen, although the player has already followed it.

**Why it matters:** The D-13b/D-19 flows are explicitly "new pick" and "retry or proceed without image". Both leave a misleading error visible. The player cannot tell whether the new pick was accepted, and the submit button is enabled while an error is still shown. No test pins the intended state after the pick or remove. `cubit.state.submitFailure` is never asserted in `character_creation_cubit_test.dart` after `pickPortrait` or `removePortrait`.

**Suggested fix:** RED tests first, in `test/screens/characterCreation/cubit/character_creation_cubit_test.dart`:
1. Seed `submitFailure: imageRejected`, then `pickPortrait` succeeds. Expect `submitFailure` null.
2. Seed `submitFailure: moderationUnavailable` with a `portraitPath`, then `removePortrait`. Expect `submitFailure` null.

Then:
```dart
emit(state.copyWith(portraitPath: path, submitFailure: null));          // pickPortrait
emit(state.copyWith(portraitPath: null, uploadedPortrait: null, submitFailure: null)); // removePortrait
```
Clearing every `submitFailure` is acceptable, since it is only ever a submit outcome.

## Info

### Group A

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

### Group B

### B-IN-01: the production-graph file lists are hand-maintained in two places and have already drifted

**File:** `test/bootstrap/entry_points_test.dart:13-19`, `tool/hardening_check.sh:8`
**Issue:** the Dart gate lists five bootstrap files by name, the shell script lists only three (`main.dart`, `app_bootstrap.dart`, `session_auth_composition.dart`) and omits `auth_composition.dart`, `klimmeck_guide_app.dart` and `insecure_transport_screen.dart`. A new production file under `lib/bootstrap/` joins neither gate unless someone remembers (plan 04 had to add the screen by hand).
**Suggested fix:** derive the list: in the test, `Directory('lib/bootstrap').listSync()` minus `dev_auth_composition.dart`; in the script, `for f in lib/main.dart $(ls lib/bootstrap/*.dart | grep -v dev_auth_composition)`. A test that the directory contains exactly one dev file keeps the carve-out explicit.

### B-IN-02: `EnvConfig.isDebug` and `EnvConfig.enableLogging` are dead

**File:** `lib/config/env_config.dart:113-116, 131-134`
**Issue:** no reader remains in `lib/` (`appLog` uses `kReleaseMode`, not `enableLogging`). They are two `--dart-define` switches (`DEBUG`, `ENABLE_LOGGING`) that suggest a control which does nothing: `--dart-define=ENABLE_LOGGING=false` in debug does not silence `appLog`.
**Suggested fix:** delete both (Boy Scout), or route `appLog` through `EnvConfig.enableLogging` if the switch is wanted.

### B-IN-03: Gradle prints the debug-keys warning on every build of every variant, and a half-filled `key.properties` fails opaquely

**File:** `android/app/build.gradle.kts:62-68, 50-58`
**Issue:**
- (a) The `release { signingConfig = if (...) else { logger.quiet(...) } }` block runs at configuration time, so the WARNING is printed for debug and dev builds too, whenever `key.properties` is missing (the normal developer state).
- (b) If `key.properties` exists but lacks `storeFile`, `file(releaseKeystore.getProperty("storeFile"))` throws an unhelpful exception instead of naming the missing key.
**Suggested fix:** (a) emit the warning from a `gradle.taskGraph.whenReady { if (hasTask(":app:assembleRelease"...)) }` or `afterEvaluate` check. (b) `requireNotNull(releaseKeystore.getProperty("storeFile")) { "key.properties: storeFile missing" }` for the four keys.

### B-IN-04: `.gitignore` covers `*.jks` but not `*.keystore`

**File:** `.gitignore:74-75`
**Issue:** Android keystores are often named `*.keystore` and would be committed by a `git add .`. `key.properties` and `*.jks` are covered.
**Suggested fix:** add `*.keystore` next to `*.jks`.

### B-IN-05: the workflow uses the default token permissions and tag-pinned actions

**File:** `.github/workflows/ci.yml:1-12`
**Issue:** no `permissions:` block (a push-triggered run gets the repository default, possibly write), actions pinned by tag (`@v4`, `@v2`) and no `concurrency` group (a `push` to a `refactor/**` branch plus the PR run duplicate builds).
**Suggested fix:** add `permissions: { contents: read }` at the top and `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`. Pin by SHA if the repo policy requires it.

### B-IN-06: `hardening_check.sh` changes directory before resolving a relative APK path, and its credential grep can false-positive

**File:** `tool/hardening_check.sh:4, 20, 23`
**Issue:**
- (a) `cd "$(dirname "$0")/.."` runs before `apk="$1"`, so a relative APK path given from another directory is reported as «not found».
- (b) `grep -rn -A3 '(appLog|debugPrint)\('` then matches any line in the three lines after a log call, for example an unrelated `final x = '$token'`, and makes CI red without a real leak.
**Suggested fix:** (a) resolve with `apk="$(realpath "$1")"` before the `cd`. (b) match only within the call, or document the limitation and keep multi-line messages away from credential-looking names.

### B-IN-07: `loadTestEnv` leaves `dotenv` populated and is `async` without awaiting

**File:** `test/helpers/fixtures/dev_auth_env.dart:10-30`
**Issue:** the tear-down resets `EnvConfig` overrides but not `dotenv.env`, so the dev token (`DEV_AUTH_ACCESS_TOKEN`) stays in the global `dotenv` for the rest of the test file. `DevAuthTokenService` reads `dotenv` directly. The function has no `await` and returns `Future<void>` for no reason.
**Suggested fix:** `addTearDown(() { EnvConfig.resetRuntimeOverrides(); dotenv.clean(); });` and make the function synchronous (`void`), updating the callers.

### B-IN-08: `SplashCubit` is the only gameplay-adjacent cubit without `SafeEmit`

**File:** `lib/screens/splash/cubit/splash_cubit.dart:16, 49-63`
**Issue:** `getImages` emits after several awaits (warm-up of folder and lore images). If the cubit is closed mid-flight, `emit(SplashData())` throws `StateError`, the `catch` runs `emit(SplashError(...))`, which throws again, unhandled. `SplashCubit` lives for the process today so it is unreachable, but every sibling cubit in this group uses the mixin precisely for this (`safe_emit.dart` doc).
**Suggested fix:** `class SplashCubit extends Cubit<SplashState> with SafeEmit<SplashState>`.

---

_Reviewed: 2026-11-09T18:34:15Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_

### Group C

### C-IN-01: `quest_result_notice.dart` uses a `_ => null` default over a failure enum

**File:** `lib/screens/mainScreen/questResultsCubit/quest_result_notice.dart:28-33`
**Issue:** The other four notice switches (`travel`, `abandon`, `acceptance`, `character_creation_messages`) list every value, so a new enum value fails compilation. This one ends with `_ => null`, so a future `QuestResultFailure` value would be silently muted. The silence is by design for network errors, but it is implicit.
**Suggested fix:** List `connection || timedOut || malformed || unknown || unauthenticated => null` explicitly. The existing `quest_result_notice_test` silent-set loop already covers the behaviour.

### C-IN-02: `badUserInputCode` lives in `spell_equip_failure.dart`, imported by ten unrelated files

**File:** `lib/repository/character_creation_failure.dart:3-4` (and nine siblings)
**Issue:** The shared constant is declared in `spell_equip_failure.dart` and imported via `show badUserInputCode` by all the other classifiers. Eight of them also carry a second `show unauthenticatedCode` import from `auth_api_exception.dart`. `graphql_error_code.dart` already hosts the sibling shared codes `forbiddenCode` and `notFoundCode`.
**Suggested fix:** Move `badUserInputCode` (and, in a later boy-scout step, `unauthenticatedCode`) next to `forbiddenCode` in `graphql_error_code.dart`, and drop the cross-feature import lines. Mechanical, no behaviour change.

### C-IN-03: Classification shift for HTTP 5xx answers that carry a parsed error code is not pinned

**File:** `lib/repository/services/graphql/graphql_error_code.dart:19-23`
**Issue:** Reading `parsedResponse.errors` means a 5xx whose body is a GraphQL or Nest error with a code (for example `INTERNAL_SERVER_ERROR`) now yields `code != null`, and every classifier returns `unknown`. Before, it returned `connection`. For acceptance and travel this changes the banner from «Connessione assente, riprova» to «Qualcosa è andato storto, riprova». It is arguably more truthful, and no retry or terminal logic changes for push (both are retryable). The tests pin only `ServerException(statusCode: 500)` with no parsed response, which stays `connection`. The coded-5xx outcome is unpinned.
**Suggested fix:** Add one test in `graphql_error_code_test.dart` (or one classifier test) for `ServerException(statusCode: 500, parsedResponse: errors [INTERNAL_SERVER_ERROR])` expecting `unknown`, so the intended behaviour is recorded.

### C-IN-04: `WorldMapCubit` keeps the raw exception text in state, and the field is never rendered

**File:** `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart:25`
**Issue:** The `print` was correctly replaced by `appLog` with `runtimeType`. But `WorldMapError(e.toString())` still stores the full exception string. `OperationException.toString()` can embed server message text, and nothing renders `errorMessage` (no consumer in `lib/`). It is dead data that would become a leak the moment a screen displays it. The formatter reflow of the class header is a harmless, untouched-member change.
**Suggested fix:** Make `WorldMapError` carry no text (or a fixed copy). Optionally add `appLog` with `runtimeType` only. Test first: `loadLoreData` throwing yields `WorldMapError` without the exception text.

### C-IN-05: `CityType.size` (pixels) and `City.size` (`CitySizeType`) share a name

**File:** `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart:36,50`
**Issue:** `_calculateMarkerScale(zoom, city.type!.size)` and `_isVisibleAt(city.size, zoom)` read two different `size` properties on the same object graph. This is the direct cost of the D-13c veto (keep pixel sizes). It is legal and covered by tests, but easy to misread. The `0.2`, `0.1` and `0.08` constants are pre-existing magic numbers.
**Suggested fix:** Optional, future: rename the enum field to `markerSize` (a veto on the values, not the name). Not needed for this phase.

### C-IN-06: Visibility now depends on backend data for three types that were classed `capital` in the enum

**File:** `lib/models/enums/city_type.dart:13-15`, `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart:54-59`
**Issue:** The old `cityClass` marked `ferrionCity`, `necrorianCity` and `talmvereVillage` as capitals even though their names suggest otherwise. The visibility now follows the backend `City.size`. If the DB serves `city` or `village` for them, their markers appear at zoom 2.5 or 3.2 instead of always. That is the intended D-13c source of truth, but it is a visible change that FE tests cannot prove. The layer tests do cover all three sizes with the zoom boundaries, `null` size hidden, and `null` type hidden.
**Suggested fix:** Add a check to the device UAT or gate plan (12-16/12-17): compare the three cities' `size` in the DB with the previous behaviour.
