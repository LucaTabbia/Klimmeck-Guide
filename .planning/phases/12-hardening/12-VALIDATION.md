---
phase: 12
slug: hardening
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-11-09
---

# Phase 12 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (Flutter 3.35.5) + bloc_test ^10.0.0 + mocktail ^1.0.5 + fake_async ^1.3.3 (pubspec.yaml); leak tracking through `leak_tracker_flutter_testing` (transitive of flutter_test) — declared in `dev_dependencies` as `leak_tracker: ^11.0.2` + `leak_tracker_flutter_testing: ^3.0.10`; cubits reach leak_tracker through the Wave 0 `LeakTrackingBlocObserver`, GC proofs through `WeakReference` + `forceGC` (RESEARCH F6) |
| **Config file** | none — shared helpers in `test/helpers/` (`test_app.dart`, `mocks.dart`, `auth_fixtures.dart`, `auth_session_fixtures.dart`, `fakes/fake_graphql_ws_server.dart`, `fakes/fake_http_client_adapter.dart`) |
| **Quick run command** | `flutter test <touched test paths>` (the `<automated>` command of the task) |
| **Full suite command** | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, Bash timeout ≥ 300000 ms) |
| **Estimated runtime** | ~86 s full suite (3565 tests, 336 files, measured 2026-11-09); ~10–20 s per task subset; release build 55–103 s locally |

---

## Sampling Rate

- **After every task commit:** Run the task's `<automated>` command + the analyzer gate (`OUT=$(flutter analyze 2>&1); ! echo "$OUT" | grep -qE '^ *(error|warning) •' && echo ANALYZE_GATE_OK`) + trailer check `git log -1 --format=%B | grep -ciE "co-authored-by|generated with|claude-session"` = 0
- **After every plan wave:** Run `flutter test test/config test/repository test/screens/auth test/screens/signIn test/models test/graphql test/tool` (one plan = one wave, linear chain) and `tool/hardening_check.sh` once it exists
- **Before `/gsd-verify-work`:** Full suite green, `flutter analyze` 0 error / 0 warning, `tool/hardening_check.sh` exit 0, release APK built and grepped (gate plan)
- **Max feedback latency:** 20 s per task subset

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 12-01-01 | 01 | 1 | HARDEN-07 | T-12-01, T-12-03 | `EnvConfig` reads installed overrides only, no `flutter_dotenv` import; flags `!kReleaseMode` | unit | `flutter test test/config test/repository/services/rest/rest_upload_test.dart test/repository/services/auth test/screens/auth` | ✅ (rewrite) | ✅ green |
| 12-01-02 | 01 | 1 | HARDEN-08, HARDEN-01 | T-12-02 | `appLog` silent under release, audible in debug | unit | `flutter test test/utils/app_log_test.dart` | ❌ W0 | ✅ green |
| 12-02-01 | 02 | 2 | HARDEN-07 | T-12-04 | session factory vs dev factory with fallback | unit | `flutter test test/bootstrap/auth_composition_test.dart` | ❌ W0 | ✅ green |
| 12-02-02 | 02 | 2 | HARDEN-07 | T-12-04, T-12-05, T-12-06 | `lib/main.dart` production-pure, barrel without dev export, `main_dev.dart` flavor assert | unit (source) | `flutter test test/bootstrap test/repository/services/push test/repository/services/auth test/screens/auth test/app` | ❌ W0 | ✅ green |
| 12-03-01 | 03 | 3 | HARDEN-07 | T-12-09 | dart-define files URL-only, `env/*.local.json` ignored | infra | `python3 -c "import json; [json.load(open(p)) for p in ('env/dev.json','env/prod.json')]; print('JSON_OK')" && grep -c "env/\*.local.json" .gitignore` | ❌ W0 | ✅ green |
| 12-03-02 | 03 | 3 | HARDEN-07, HARDEN-08 | T-12-08, T-12-10, T-12-11 | release APK without `.env` / dev bypass; key.properties signing with visible fallback | build + bundle grep | `flutter build apk --release --dart-define-from-file=env/prod.json` then the three `unzip` greps = 0 | n/a | ✅ green |
| 12-04-01 | 04 | 4 | HARDEN-08 | T-12-12, T-12-13 | release refuses `http://`/`ws://`, names keys only | unit | `flutter test test/config` | ❌ W0 | ✅ green |
| 12-04-02 | 04 | 4 | HARDEN-08 | T-12-12, T-12-14 | fail-fast screen first in `bootstrapApp` | widget + unit | `flutter test test/bootstrap test/config` | ❌ W0 | ✅ green |
| 12-05-01 | 05 | 5 | HARDEN-01, HARDEN-08 | T-12-15, T-12-16 | service logs only through `appLog` | unit (source guard) | `flutter test test/utils test/repository/services/auth test/repository/services/graphql test/repository/storage test/repository/services/sync test/repository/cache test/network` | ❌ W0 | ✅ green |
| 12-05-02 | 05 | 5 | HARDEN-01, HARDEN-08 | T-12-15, T-12-16 | push logs only through `appLog` | unit (source guard) | `flutter test test/utils test/repository/services/push` | ✅ | ✅ green |
| 12-06-01 | 06 | 6 | HARDEN-01, HARDEN-08 | T-12-17 | guard covers `lib/`; cubit/component logs routed | unit (source guard) | `flutter test test/screens/auth test/screens/splash test/shared` | ✅ | ✅ green |
| 12-06-02 | 06 | 6 | HARDEN-01, HARDEN-08 | T-12-17 | no direct log call left in `lib/` | unit (source guard) | `flutter test test/utils test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/map test/screens/mainScreen/tabs/settings` | ✅ | ✅ green |
| 12-07-01 | 07 | 7 | HARDEN-01, HARDEN-07 | T-12-18, T-12-19, T-12-21 | guard script OK on tree and on fresh APK | infra | `bash -n tool/hardening_check.sh && bash tool/hardening_check.sh` | ❌ W0 | ✅ green |
| 12-07-02 | 07 | 7 | HARDEN-09 | T-12-18, T-12-20 | CI on PR → develop with release + bundle guard | infra | `grep -c "flutter analyze --no-fatal-infos" .github/workflows/ci.yml` | ❌ W0 | ✅ green |
| 12-08-01 | 08 | 8 | HARDEN-03 | T-12-22, T-12-24 | atomic logout end to end over a real socket, old client GC'd | integration (loopback) | `flutter test test/repository/services/auth/logout_flow_test.dart` | ❌ W0 | ✅ green |
| 12-08-02 | 08 | 8 | HARDEN-04 | T-12-23, T-12-24 | two concurrent 401 → one refresh, no logout | integration | `flutter test test/repository/services/auth test/network test/screens/auth/cubit` | ❌ W0 | ✅ green |
| 12-09-01 | 09 | 9 | HARDEN-05 | T-12-25, T-12-28 | no cubit/subscription retained after logout | widget + leak_tracker | `flutter test test/screens/auth/authenticated_shell_leak_test.dart` | ❌ W0 | ✅ green |
| 12-09-02 | 09 | 9 | HARDEN-06 | T-12-26 | identity transitions rebuild the whole shell | widget | `flutter test test/screens/auth/identity_transitions_test.dart test/screens/auth/auth_gate_test.dart test/screens/auth/session_home_test.dart` | ❌ W0 | ✅ green |
| 12-09-03 | 09 | 9 | HARDEN-06 | T-12-27 | pending push tap dropped on a user change | unit (bloc) | `flutter test test/screens/auth test/repository/services/push` | ✅ | ✅ green |
| 12-10-01 | 10 | 10 | HARDEN-10 | T-12-30 | error codes read from HTTP ≥ 300 GraphQL answers | unit | `flutter test test/repository` | ✅ | ✅ green |
| 12-10-02 | 10 | 10 | HARDEN-10 | T-12-29, T-12-30 | `BAD_USER_INPUT` on travel and quest acceptance | unit | `flutter test test/repository test/screens/mainScreen/travelCubit test/screens/mainScreen/questAcceptanceCubit` | ✅ | ✅ green |
| 12-11-01 | 11 | 11 | HARDEN-10 | T-12-31 | `BAD_USER_INPUT` on shop transactions, generic bubble | unit | `flutter test test/repository/transaction_failure_test.dart test/screens/mainScreen/tabs/shop` | ✅ | ✅ green |
| 12-11-02 | 11 | 11 | HARDEN-10 | T-12-31 | `BAD_USER_INPUT` on quest abandon | unit | `flutter test test/repository/quest_abandon_failure_test.dart test/screens/mainScreen/questAbandonCubit` | ✅ | ✅ green |
| 12-11-03 | 11 | 11 | HARDEN-10 | T-12-31, T-12-32 | `BAD_USER_INPUT` on quest results, banner no longer silent | unit | `flutter test test/repository test/screens/mainScreen/questResultsCubit` | ✅ | ✅ green |
| 12-12-01 | 12 | 12 | HARDEN-10 | T-12-34 | moderation codes and `BAD_USER_INPUT` classified for creation | unit | `flutter test test/repository/character_creation_failure_test.dart test/screens/characterCreation` | ✅ | ✅ green |
| 12-12-02 | 12 | 12 | HARDEN-10 | T-12-33, T-12-35 | rejected portrait cleared, unavailable moderation keeps the draft | unit + bloc | `flutter test test/repository/character_creation_repository_test.dart test/screens/characterCreation` | ✅ | ✅ green |
| 12-12-03 | 12 | 12 | HARDEN-10 | T-12-31 | `BAD_USER_INPUT` on character deletion | unit | `flutter test test/repository/character_deletion_failure_test.dart test/screens/mainScreen/tabs/settings` | ✅ | ✅ green |
| 12-13-01 | 13 | 13 | HARDEN-10 | T-12-36 | innkeeper + push map `BAD_USER_INPUT`, push never retries it | unit | `flutter test test/repository test/screens/innkeeper test/repository/services/push test/screens/mainScreen/tabs/map/components` | ✅ | ✅ green |
| 12-13-02 | 13 | 13 | HARDEN-10 | T-12-37, T-12-38 | markers by `City.size`, `cityClass` gone | widget | `flutter test test/screens/mainScreen/tabs/map test/models test/graphql test/tool` | ✅ | ✅ green |
| 12-14-01 | 14 | 14 | HARDEN-06 | T-12-40, T-12-41 | revocation reason parsed only on `SESSION_REVOKED` | unit | `flutter test test/repository/services/auth` | ✅ | ✅ green |
| 12-14-02 | 14 | 14 | HARDEN-06 | T-12-39 | dedicated notices for new login and role change | widget | `flutter test test/screens/auth test/screens/signIn test/repository/services/auth` | ✅ | ✅ green |
| 12-14-03 | 14 | 14 | HARDEN-06 | T-12-39, T-12-42 | sign-out reason from the BE reason on every refresh path | unit (fakeAsync) | `flutter test test/repository/services/auth test/screens/auth` | ✅ | ✅ green |
| 12-15-01 | 15 | 15 | HARDEN-06 | T-12-44, T-12-46 | `4409` refreshes before reconnecting, bounded | unit | `flutter test test/repository/services/graphql` | ✅ | ⬜ pending |
| 12-15-02 | 15 | 15 | HARDEN-06 | T-12-43, T-12-45 | WS fake close hooks + session backend fake | unit (helpers) | `flutter test test/helpers/fakes test/repository/services/graphql` | ❌ W0 | ⬜ pending |
| 12-15-03 | 15 | 15 | HARDEN-06 | T-12-43, T-12-44, T-12-45 | last login replaces the other device (5 cases) | integration (loopback, two services) | `flutter test test/repository/services/auth/dual_session_revocation_test.dart` | ❌ W0 | ⬜ pending |
| 12-16-01 | 16 | 16 | HARDEN-02, HARDEN-06 | T-12-47, T-12-48, T-12-49 | contract names proven on merged BE Phase 17; 45/45 OK | gate | `git -C <BE> show origin/develop:src/auth/session/session-revoke-reason.enum.ts \| grep -c newLogin` + `flutter test test/repository/services test/screens/auth test/screens/signIn` | n/a | ⬜ pending |
| 12-16-02 | 16 | 16 | HARDEN-01, HARDEN-03, HARDEN-04, HARDEN-05, HARDEN-07, HARDEN-09, HARDEN-10 | T-12-50, T-12-51 | all automated gates green, bundle guard OK | gate | `bash tool/hardening_check.sh && flutter test` | n/a | ⬜ pending |
| 12-17-01 | 17 | 17 | HARDEN-05, HARDEN-06, HARDEN-07, HARDEN-08, HARDEN-09 | T-12-52, T-12-53 | UAT sheet with prerequisites, no secret written | doc | `grep -cE "^\| (1[01]\|[1-9]) \|" .planning/phases/12-hardening/12-HUMAN-UAT.md` | ❌ W0 | ⬜ pending |
| 12-17-02 | 17 | 17 | HARDEN-05, HARDEN-06, HARDEN-08, HARDEN-09 | T-12-55, T-12-56 | device E2E (release via tunnel, DevTools, dual device) | manual (checkpoint) | `test -f .planning/phases/12-hardening/12-HUMAN-UAT.md` | n/a | ⬜ pending |
| 12-17-03 | 17 | 17 | HARDEN-01..HARDEN-10 | T-12-52, T-12-54 | requirements ticked only on passed evidence; BE handoff | doc | `grep -q "## 3. UAT outcome" .planning/phases/12-hardening/BACKEND-NOTES.md` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [x] `test/helpers/leak_tracking_bloc_observer.dart` — dispatching observer (HARDEN-05)
- [x] `test/helpers/fakes/fake_session_backend.dart` — shared in-memory BE for the dual-session test (HARDEN-06)
- [x] `test/helpers/fakes/fake_graphql_ws_server.dart` — `closeSocket(ws, code, reason)` + `onConnectionInit` hook (HARDEN-06)
- [x] `test/utils/app_log_test.dart`, `test/config/env_config_secure_transport_test.dart`, `test/bootstrap/insecure_transport_screen_test.dart` (HARDEN-01, HARDEN-08)
- [x] `test/repository/services/auth/logout_flow_test.dart`, `concurrent_unauthorized_refresh_test.dart` (HARDEN-03, HARDEN-04)
- [x] `test/repository/services/auth/dual_session_revocation_test.dart` (HARDEN-06)
- [x] `test/screens/auth/authenticated_shell_leak_test.dart`, `test/screens/auth/identity_transitions_test.dart` (HARDEN-05, HARDEN-06)
- [x] `pubspec.yaml` `dev_dependencies`: `leak_tracker: ^11.0.2`, `leak_tracker_flutter_testing: ^3.0.10`
- [x] `tool/hardening_check.sh`, `env/dev.json`, `env/prod.json`, `.github/workflows/ci.yml` (HARDEN-07, HARDEN-09)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| DevTools memory snapshot before/after logout shows no retained cubit or subscription | HARDEN-05 | A profiler run on the device cannot be automated in `flutter test` | `12-HUMAN-UAT.md` step: DevTools › Memory, snapshot after login, logout, GC, snapshot: no `*Cubit`, `WebSocketLink`, `StreamSubscription` instances of the session remain; screenshots attached |
| Second login on the emulator replaces the phone session with the dedicated notice | HARDEN-06 | Needs two real Twitch logins on two devices against the merged BE Phase 17 | `12-HUMAN-UAT.md` steps: login on the Samsung, login on the emulator with the same account, the phone shows «Hai effettuato l'accesso da un altro dispositivo.» within a minute; no crash, no stale state |
| Release APK through the TLS tunnel: real login, play, logout | HARDEN-08 | Signed release build, TLS-only transport and the tunnel exist only on the device | `12-HUMAN-UAT.md` steps: `flutter build apk --release --dart-define-from-file=env/<tunnel>.json`, `adb install -r`, login via Twitch, one quest/travel round trip, logout |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 20 s per task subset
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
