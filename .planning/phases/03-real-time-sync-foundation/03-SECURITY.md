---
phase: 3
slug: real-time-sync-foundation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-10-14
---

# Phase 3 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Source: `<threat_model>` blocks of plans 03-01..03-09. Audit state: HEAD `388ad7c` (includes review fixes `b103310`, `88aecdb`, `6126bff`). E2E evidence: 03-HUMAN-UAT.md (approved, Samsung SM S938B, Android 16, 2026-10-14, steps 1-11 pass).

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Test tooling -> loopback | Fake graphql-ws server for tests, bound to `127.0.0.1` only | Fake fixtures, no real tokens |
| FE schema-check tooling -> BE repo | `dump_documents.dart` + `validate_documents.js` only read the BE `schema.gql`; dumps go to a caller-supplied temp dir | GraphQL documents, SDL schema |
| FE <-> BE contract | Documents and wire shapes (`userUpdated`, `characterUpdated`, FORBIDDEN/NOT_FOUND codes) must match the regenerated BE schema | Operation names, error codes |
| App <-> BE WebSocket (graphql-ws) | `connection_init` carries the bearer, re-read per connect; keep-alive ping/timeouts; close 4401/4403 | Access JWT, user/character state |
| Subscription event -> session state | Every `userUpdated` event enters the session through `adoptUser` (id guard) | User/character payloads |
| Sync watchdog -> session termination | Sustained degradation (3 min) ends the session locally via `SessionTerminator` | Session lifecycle, local storage |
| Session subtree lifetime | `SessionSyncScope` under AuthGate `ValueKey(user.id)`; shell keyed by `character:<id>` | Streams, timers, listeners per identity |
| Logs / diagnostics | `debugPrint` / `developer.log` of sync code | Error codes and `runtimeType` only |
| Production transport | `GRAPHQL_WS_URL` scheme | Cleartext vs TLS (transferred to Phase 12) |
| FE merge ordering | FE PR vs BE PR (D-04) | Contract compatibility |

---

## Threat Register

Verification: all `mitigate` threats confirmed by reading the cited code and tests (green per 03-VERIFICATION.md). Review-fix strengthening is noted where it applies.

| Threat ID | Category | Component | Disposition | Mitigation evidence | Status |
|-----------|----------|-----------|-------------|---------------------|--------|
| T-03-01-01 | Information disclosure | fake WS server | mitigate | `HttpServer.bind(InternetAddress.loopbackIPv4, 0)` test/helpers/fakes/fake_graphql_ws_server.dart:18; `stop()` :82; `tearDown(server.stop)` fake_graphql_ws_server_test.dart:52 | closed |
| T-03-01-02 | Tampering | FE-BE contract drift | mitigate | Completeness test test/tool/schema_check_documents_test.dart:28-30; plan 09 graphql-js run 24/24 OK against BE `schema.gql` @ 62890b6 (BACKEND-NOTES §5) | closed |
| T-03-01-03 | Information disclosure | fixtures | mitigate | test/helpers/fixtures/sync_event_fixtures.dart contains no token/Authorization/.env reference (grep clean) | closed |
| T-03-01-04 | Tampering | BE repo via tooling | mitigate | tool/schema_check/dump_documents.dart:10-12 writes only to the caller-supplied dir; validate_documents.js has no fs write calls; BE path appears only in a usage comment (validate_documents.js:6) | closed |
| T-03-02-01 | DoS (forced sign-out) | SyncWatchdog | mitigate | Degraded-only clock sync_watchdog.dart:34-36,59,85-92; suspend/resume :63-73; latch :104-112. Tests sync_watchdog_test.dart:37 (idle healthy never expires), :153 (suspend/resume fresh window), :190 (fires once). Real devices: UAT steps 6-8 pass | closed |
| T-03-02-02 | DoS (server hot loop) | terminated stream | mitigate | `markTerminated` only sets a condition, never schedules a retry (sync_watchdog.dart:49,80-83); degraded only without a healthy stream :34-40; tests sync_watchdog_test.dart:100,110,121 | closed |
| T-03-02-03 | DoS (self) | silentRetry | mitigate | `maxAttempts` 8, capped `exponentialBackoff`, `isCancelled` before each attempt/after each wait: lib/utils/silent_retry.dart:5,23-34; tests silent_retry_test.dart:22,61,85,130,151 | closed |
| T-03-02-04 | Repudiation / Info disclosure | logging | accept | AR-01. Fact check: sync_health.dart, silent_retry.dart, user_refresh_requests.dart, app_lifecycle_events.dart log nothing; the only log is sync_watchdog.dart:109 (added by `b103310`), which emits `error.runtimeType` only, no payload/token | closed |
| T-03-03-01 | Spoofing | `userUpdated` of another user | mitigate | Subscription has no arguments (user_subscriptions.dart:4-8), identity from bearer; FE guard `adoptUser` id check session_auth_token_service.dart:195-197 (+ dev :96-99); consumed via `_adopt` session_sync_cubit.dart:119-125; test cubit 'an event of another identity is dropped' :121 | closed |
| T-03-03-02 | Information disclosure | foreign character id | mitigate | `_throwIfStreamFailed` -> `SubscriptionStreamException(code)` graphql.dart:111-116 (error, no data path); tests graphql_sync_test.dart:130,142; UAT step 9 (FORBIDDEN: errors, no data, `complete`) | closed |
| T-03-03-03 | Information disclosure | payload/token in logs | mitigate | `toString()` prints operation + code only graphql_sync_exceptions.dart:9,24; test graphql_sync_test.dart:195-196 | closed |
| T-03-03-04 | Tampering / DoS | malformed event | mitigate | `_userFrom` graphql.dart:425-433 and `_characterFrom` :118-126 convert any parse failure to `FormatException`; tests graphql_sync_test.dart:90,154; cubit 'a malformed event follows the silent backoff path' :217 | closed |
| T-03-03-05 | Tampering | contract drift | mitigate | `OnUserChanged` in schemaCheckDocuments and validated 24/24 OK, `userUpdated: User!` in BE schema (BACKEND-NOTES §5) | closed |
| T-03-04-01 | Information disclosure | teardown on sync loss | mitigate | `terminateSession` -> `_endSession` (supersede, forget, `_onSessionTeardown`, store clear, emit) session_auth_token_service.dart:188-195,524-531; dev_auth_token_service.dart:96-99,142-144; tests session_auth_token_service_terminate_test.dart:60; dev_auth_token_service_transitions_test.dart. UAT step 11 (socket closed, no further traffic) | closed |
| T-03-04-02 | DoS (double terminal state) | termination during logout | mitigate | Guard `_logoutInFlight != null || not AuthAuthenticated` + `_terminationInFlight` single-flight session_auth_token_service.dart:189-193; tests terminate_test.dart:78,93,115 | closed |
| T-03-04-03 | Elevation of privilege | stale sheet | mitigate | AuthGate `_changesCharacter` -> `popUntil(isFirst)` auth_gate.dart:34-38,77-79; tests auth_gate_test.dart:369,381,393 (gain/loss/swap), :405 (points-only keeps dialogs) | closed |
| T-03-04-04 | Spoofing (notice misuse) | SignIn notice | accept | AR-02. Fact check: sign_in_screen.dart:9-10,20,28-31 fixed Italian strings chosen by `SignInNotice` enum; no server text reaches the widget | closed |
| T-03-04-05 | Repudiation | Phase 2 security evidence | mitigate | 02-SECURITY.md row T-02-02-03 updated in the phase diff to the new auth_gate test names and D-10 supersession | closed |
| T-03-05-01 | Spoofing | token in `connection_init` | mitigate | `initialPayload: policy.buildInitialPayload` evaluated per connect graphql_client_provider.dart:96; test ws_resubscribe_integration_test.dart:85 (rotated token on second init, same link). UAT step 5 (fresh token after JWT expiry) | closed |
| T-03-05-02 | Information disclosure | stream leak across logout | mitigate | `holder.reset()` disposes link then installs new client graphql_client_holder.dart:37-50; tests ws_resubscribe_integration_test.dart:162; graphql_client_holder_test.dart:65,78,91 | closed |
| T-03-05-03 | DoS | half-open socket | mitigate | `pingInterval` 25 s, `connectTimeout` 10 s via `connectWithKeepAlive` graphql_client_provider.dart:57-82; env_config.dart:71-79; tests ws_resubscribe_integration_test.dart:220,225,238 (peer not answering pings closed). UAT steps 4, 7 on radio | closed |
| T-03-05-04 | DoS | `connectOrReconnect` killing live streams | mitigate | Monitor creates client only when absent; test socket_connection_monitor_test.dart:73 (live subscription survives `watch()`) | closed |
| T-03-05-05 | Tampering | supply chain `web_socket_channel` | mitigate | pubspec.yaml:49 `^3.0.3`; pubspec.lock:1696-1703 version 3.0.3, same sha256, only `dependency` kind changed to direct main (git diff) | closed |
| T-03-05-06 | Information disclosure | cleartext `ws://` in production | transfer | AR-03. Transferred to Phase 12 Hardening (ROADMAP.md Phase 12). Fact: only dev default `ws://` in env_config.dart:36, overridable via `GRAPHQL_WS_URL` | closed |
| T-03-06-01 | Spoofing / Info disclosure | late event of previous identity | mitigate | All events pass `_adopt` -> `adoptUser` session_sync_cubit.dart:119-125; close cancels subscriptions :243-257; tests cubit :121, :290 (late event after close adopts nothing) | closed |
| T-03-06-02 | DoS (server hot loop) | FORBIDDEN on user stream | mitigate | `_terminateUserStream` sets flag, cancels, one forced `refreshUser`; `onDone` skips resubscribe when terminated; refetch `shouldRetry: !isAccessDeniedError` session_sync_cubit.dart:133-153,95-100,196-201; tests :232 (10 simulated min), :373. Strengthened by `6126bff` (forced single-flight refetch after rejection, :86-94) and `88aecdb` (`_isSessionEnding` guard on done/resubscribe, :129-131,170-172; tests :187,:202) | closed |
| T-03-06-03 | Tampering (stale overwrite) | resume refetch vs live event | mitigate | `_eventCount` compare session_sync_cubit.dart:193-208; tests :335, :447 (terminal recovery never adopts older in-flight `me`, added with `6126bff`) | closed |
| T-03-06-04 | Information disclosure | logs | mitigate | Only fixed text and code/`runtimeType`: session_sync_cubit.dart:122,152 | closed |
| T-03-06-05 | DoS (forced sign-out) | watchdog feeding | mitigate | Per-source marks :60-65; background `suspend`, foreground `resume` :66-71; tests cubit :250,:264 (idle), :386, :472 (expires once). UAT steps 6-8 | closed |
| T-03-06-06 | Information disclosure | listener leak | mitigate | `close()` releases sources and cancels 5 subscriptions + timer session_sync_cubit.dart:243-257; test :273 | closed |
| T-03-07-01 | Information disclosure | foreign character id | mitigate | character_cubit.dart `_terminateStream` (cancel, `markTerminated`, one `requestUserRefresh`) :138-147; tests character_cubit_test.dart:279; UAT step 9 | closed |
| T-03-07-02 | DoS (server hot loop) | FORBIDDEN/NOT_FOUND resubscribe | mitigate | `_isStreamTerminated` stops `_onStreamDone`/`_scheduleResubscribe` character_cubit.dart:121-132,150-158; refetch `shouldRetry: !isAccessDeniedError` :82-90; tests :279 (10 min), :381 | closed |
| T-03-07-03 | DoS (blank UI) | CharacterError/Loading in session | mitigate | Only `loadCharacter` emits Loading/Error (character_cubit.dart:61-72); `refreshCharacter` and stream paths never do; tests character_cubit_test.dart:208,254,266,329 assert state kept | closed |
| T-03-07-04 | Tampering (stale overwrite) | resume refetch | mitigate | `_eventCount` + `_refreshGeneration` character_cubit.dart:76-97; tests :344, :410 | closed |
| T-03-07-05 | Information disclosure | stream/timer leak after close | mitigate | `close()` cancels timer, bumps generation, releases source, cancels stream and lifecycle listener character_cubit.dart:166-176; tests :102-146, :299, :317, :432 | closed |
| T-03-07-06 | Information disclosure | logs | mitigate | Only code logged character_cubit.dart:138-147 | closed |
| T-03-08-01 | Information disclosure | leak into next session | mitigate | session_sync_scope.dart:12-16,34-56 (watchdog/bus disposed, cubit closed with subtree) under `ValueKey(user.id)` auth_gate.dart:51; tests session_sync_scope_test.dart:134,149 | closed |
| T-03-08-02 | Information disclosure | two live character streams | mitigate | `ValueKey('character:<id>')` session_home.dart:28; tests session_home_test.dart:100,183,201 | closed |
| T-03-08-03 | DoS (forced sign-out) | watchdog wiring | mitigate | Expiry only via `terminator.terminateSession(syncLost)` session_sync_scope.dart:36-41; bridge uses `onPause`/`onRestart` app_lifecycle_bridge.dart:24-26; tests session_sync_scope_test.dart:109,124 (idle), app_lifecycle_bridge_test.dart:45,61. UAT steps 6-8 | closed |
| T-03-08-04 | DoS | `connectOrReconnect` per session | mitigate | `openConnectionStream()` called once in cubit `create` session_sync_scope.dart:50-53; test session_sync_scope_test.dart:70 | closed |
| T-03-08-05 | Elevation of privilege | session-wide watchdog on creation page | accept | AR-04 (D-15 / Open Question 3). Fact: scope wraps the whole authenticated subtree (session_sync_scope.dart:12-16), so the creation form is covered | closed |
| T-03-09-01 | Tampering | contract drift | mitigate | graphql-js validation 24/24 OK, no pre-existing drift (BACKEND-NOTES §5) | closed |
| T-03-09-02 | Information disclosure | foreign character data | mitigate | UAT step 9 pass: FORBIDDEN `next{errors}` + `complete`, one log, one `GetMe`, no loop (BACKEND-NOTES §5 "Forma FORBIDDEN osservata") | closed |
| T-03-09-03 | Information disclosure | UAT/notes content | mitigate | 03-HUMAN-UAT.md:16 rule; grep of UAT and BACKEND-NOTES finds no token/JWT values (only the `Bearer <jwt>` placeholder, BACKEND-NOTES:63) | closed |
| T-03-09-04 | Elevation of privilege | merge before backend | mitigate | 03-09-SUMMARY.md:95 states the FE PR is opened by the user only after the BE PR is merged (D-04); no PR opened in this phase | closed |
| T-03-09-05 | DoS | watchdog false positive in field | mitigate | UAT steps 6 (background), 7 (radio loss < 3 min), 8 (BE down > 3 min) pass on a physical device | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Informational notes

- Unregistered threat flags: none. SUMMARY plans 01, 02, 04, 05, 08 report "None"; 03, 06, 07, 09 have no Threat Flags section.
- Review fix WR-02 (`88aecdb`) note from 03-REVIEW-FIX.md: the guard covers the watchdog-triggered teardown; other teardown paths (logout, revocation) unmount the scope, which closes the cubit (`isClosed` checks), so no resubscribe survives. No open gap.
- UAT step 12 (iOS physical device) was optional and not run; the platform quirk residual (A4) is tracked outside this phase's blocking scope.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-03-02-04 | Watchdog, health, retry and event-bus classes do not log payloads or tokens; the single log line emits `error.runtimeType` only. Residual: none | Luca Tabbia (D-15 / plan dispositions) | 2026-10-14 |
| AR-02 | T-03-04-04 | The SignIn notice is a fixed Italian string chosen by an enum; no server-provided text reaches the screen. Residual: none | Luca Tabbia (D-15 / plan dispositions) | 2026-10-14 |
| AR-03 | T-03-05-06 | Cleartext `ws://` only as dev default; production `GRAPHQL_WS_URL` must be `wss://`, enforced in Phase 12 Hardening (transfer). Residual until Phase 12 | Luca Tabbia (D-15 / plan dispositions) | 2026-10-14 |
| AR-04 | T-03-08-05 | Session-wide watchdog also runs on the character-creation page (D-15, Open Question 3): offline > 3 min there ends the session with the notice, the draft is lost. Mentioned in the PR | Luca Tabbia (D-15 / plan dispositions) | 2026-10-14 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-14 | 46 | 46 | 0 | gsd-security-auditor (sonnet) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-14
