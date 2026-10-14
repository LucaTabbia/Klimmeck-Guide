---
phase: 3
slug: real-time-sync-foundation
status: approved
nyquist_compliant: true
wave_0_complete: true
created: 2026-10-14
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 (all already in `pubspec.yaml`) |
| **Config file** | none — shared mocks in `test/helpers/mocks.dart`, fakes in `test/helpers/fakes/`, fixtures in `test/helpers/fixtures/` (Wave 0 adds the fake graphql-ws server and sync fixtures) |
| **Quick run command** | `flutter test <the task's test file(s)>` |
| **Full suite command** | `flutter test` (baseline 481 tests) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>` |
| **Estimated runtime** | quick ~3–8 s per file; full ~25 s |

---

## Sampling Rate

- **After every task commit:** run the task's `<verify><automated>` command (targeted test files)
- **After every plan wave:** `flutter test test/repository/services/sync test/repository/services/graphql test/screens/auth test/screens/mainScreen/characterCubit test/graphql test/utils test/helpers test/tool`
- **Before `/gsd-verify-work`:** full `flutter test` green, analyze ≤ 57 issues with none in Phase 3 files, schema check green (plan 09)
- **Max feedback latency:** ~10 s per task (real-socket integration tests included)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | SYNC-03, SYNC-06 | T-03-01-01 | fake server bound to loopback only | unit (self-test) | `flutter test test/helpers/fakes/fake_graphql_ws_server_test.dart` | ✅ | ✅ green |
| 3-01-02 | 01 | 1 | SYNC-01..07 (D-04) | T-03-01-02 | every document listed for the schema check | unit | `flutter test test/helpers/fixtures/sync_event_fixtures_test.dart test/tool/schema_check_documents_test.dart` | ✅ | ✅ green |
| 3-01-03 | 01 | 1 | SYNC-05 | — | N/A (docs) | grep | `! grep -n "admin-swap" .planning/REQUIREMENTS.md` | ✅ | ✅ green |
| 3-02-01 | 02 | 1 | SYNC-03 | T-03-02-01, T-03-02-02 | idle healthy socket never ejects; FORBIDDEN never retried | unit (fakeAsync) | `flutter test test/repository/services/sync/sync_watchdog_test.dart` | ✅ | ✅ green |
| 3-02-02 | 02 | 1 | SYNC-03 | — | N/A | unit | `flutter test test/repository/services/sync/app_lifecycle_events_test.dart test/repository/services/sync/user_refresh_requests_test.dart` | ✅ | ✅ green |
| 3-02-03 | 02 | 1 | SYNC-03 | T-03-02-03 | bounded retry (8 attempts, 60 s cap) | unit (fakeAsync) | `flutter test test/utils/silent_retry_test.dart` | ✅ | ✅ green |
| 3-03-01 | 03 | 2 | SYNC-01 | T-03-03-01 | `userUpdated` has no arguments | unit (document) | `flutter test test/graphql/user_subscription_documents_test.dart test/tool/schema_check_documents_test.dart` | ✅ | ✅ green |
| 3-03-02 | 03 | 2 | SYNC-01, SYNC-02 | T-03-03-02, T-03-03-03 | FORBIDDEN/NOT_FOUND recognised; no payload in toString | unit | `flutter test test/repository/services/graphql/graphql_error_code_test.dart` | ✅ | ✅ green |
| 3-03-03 | 03 | 2 | SYNC-01, SYNC-02 | T-03-03-04 | malformed events become FormatException | unit (Link.function) | `flutter test test/repository/services/graphql test/graphql` | ✅ | ✅ green |
| 3-04-01 | 04 | 1 | SYNC-03, SYNC-04 | T-03-04-01, T-03-04-02 | teardown clears storage; one terminal state | unit (fakeAsync) | `flutter test test/repository/services/auth` | ✅ | ✅ green |
| 3-04-02 | 04 | 1 | SYNC-03 | T-03-04-04 | fixed notice text only | widget | `flutter test test/screens/signIn/sign_in_screen_test.dart test/screens/auth/auth_gate_test.dart` | ✅ | ✅ green |
| 3-04-03 | 04 | 1 | SYNC-05 | T-03-04-03 | root dialogs closed on character change | widget | `flutter test test/screens/auth` | ✅ | ✅ green |
| 3-05-01 | 05 | 2 | SYNC-03, SYNC-06 | T-03-05-01, T-03-05-03 | rotated token on reconnect; keep-alive ping | integration (real socket, plain test) | `flutter test test/repository/services/graphql` | ✅ | ✅ green |
| 3-05-02 | 05 | 2 | SYNC-03, SYNC-04 | T-03-05-02, T-03-05-04 | reset closes the socket; no leak to the new client | integration | `flutter test test/repository/services/graphql` | ✅ | ✅ green |
| 3-06-01 | 06 | 3 | SYNC-01, SYNC-04, SYNC-07 | T-03-06-01, T-03-06-02, T-03-06-06 | foreign identity dropped; FORBIDDEN terminal + one `me` | cubit (bloc_test + fakeAsync) | `flutter test test/screens/auth/syncCubit/session_sync_cubit_test.dart test/screens/auth/cubit/auth_cubit_test.dart` | ✅ | ✅ green |
| 3-06-02 | 06 | 3 | SYNC-03 | T-03-06-03, T-03-06-05 | stale refetch discarded; idle never expires | cubit (fakeAsync + Completer) | `flutter test test/screens/auth/syncCubit/session_sync_cubit_test.dart` | ✅ | ✅ green |
| 3-07-01 | 07 | 3 | SYNC-02, SYNC-03, SYNC-07 | T-03-07-01..03 | no CharacterError in session; FORBIDDEN terminal | cubit (fakeAsync) | `flutter test test/screens/mainScreen/characterCubit/character_cubit_test.dart` | ✅ | ✅ green |
| 3-07-02 | 07 | 3 | SYNC-03 | T-03-07-04, T-03-07-05 | resume refetch silent, no overwrite | cubit (Completer) | `flutter test test/screens/mainScreen/characterCubit/character_cubit_test.dart` | ✅ | ✅ green |
| 3-07-03 | 07 | 3 | SYNC-05, SYNC-07 | T-03-07-05 | cubit closed with the shell | widget | `flutter test test/screens/auth/authenticated_shell_test.dart test/screens/mainScreen` | ✅ | ✅ green |
| 3-08-01 | 08 | 4 | SYNC-01, SYNC-03, SYNC-04 | T-03-08-01, T-03-08-03, T-03-08-04 | unmount removes listeners; expiry → syncLost once | widget | `flutter test test/screens/auth/session_sync_scope_test.dart` | ✅ | ✅ green |
| 3-08-02 | 08 | 4 | SYNC-05 | T-03-08-02 | never two live character streams | widget | `flutter test test/screens/auth/session_home_test.dart` | ✅ | ✅ green |
| 3-08-03 | 08 | 4 | SYNC-03 | T-03-08-03 | onPause/onRestart only | widget + full suite | `flutter test test/screens/auth/app_lifecycle_bridge_test.dart && flutter test` | ✅ | ✅ green |
| 3-09-01 | 09 | 5 | SYNC-01..07 (D-04) | T-03-09-01 | documents valid against the regenerated BE schema | schema check + full suite | `grep -q "userUpdated: User!" <BE>/src/schema.gql && flutter test` + `tool/schema_check/*` | ✅ (tooling from 3-01-02) | ✅ green |
| 3-09-02 | 09 | 5 | SYNC-01..07 | T-03-09-02, T-03-09-05 | E2E on real BE | manual | see Manual-Only below | — | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/fakes/fake_graphql_ws_server.dart` + self-test — real `SocketClient` integration tests (plan 01 task 1)
- [x] `test/helpers/fixtures/sync_event_fixtures.dart` — `userJson`, `characterJson`, `dataResponse`, `errorCodeResponse` (plan 01 task 2)
- [x] `tool/schema_check/{schema_check_documents.dart,dump_documents.dart,validate_documents.js}` + completeness test (plan 01 task 2)
- [x] `test/helpers/fakes/recording_sync_health.dart` — `SyncHealth` fake for cubit tests (plan 02 task 1)
- [x] `MockSessionTerminator` in `test/helpers/mocks.dart` (plan 04 task 1)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Snapshot at connect, live twitchPoints/role/status from Mongo edits | SYNC-01, SYNC-02, SYNC-07 | needs the real BE change streams | 03-09 Task 2 steps 1–3 |
| Recovery after airplane mode / wifi→cellular, 4401 cycle | SYNC-03, SYNC-06 | real radio + real JWT expiry; dart:io answers pings itself in tests | 03-09 Task 2 steps 4, 5, 7 |
| Resume refetch on a real device lifecycle | SYNC-03 | platform lifecycle sequences (A4) | 03-09 Task 2 step 6 (and 12 on iOS) |
| Sync-lost notice after BE down > 3 min | SYNC-03, SYNC-04 | real socket failure timing | 03-09 Task 2 steps 8, 11 |
| FORBIDDEN wire shape and no retry loop | SYNC-02 | backend authorization on a foreign id | 03-09 Task 2 step 9 |
| Deletion path (`currentCharacter → null`) | SYNC-05 | Mongo edit on the real BE | 03-09 Task 2 step 10 |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 10s per task
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved 2026-10-14
