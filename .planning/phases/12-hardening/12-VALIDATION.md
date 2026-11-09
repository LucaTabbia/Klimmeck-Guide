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
| 12-01-01 | 01 | 1 | HARDEN-07 | T-12-01 / — | {expected secure behavior} | unit | `{command}` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/helpers/leak_tracking_bloc_observer.dart` — dispatching observer (HARDEN-05)
- [ ] `test/helpers/fakes/fake_session_backend.dart` — shared in-memory BE for the dual-session test (HARDEN-06)
- [ ] `test/helpers/fakes/fake_graphql_ws_server.dart` — `closeSocket(ws, code, reason)` + `onConnectionInit` hook (HARDEN-06)
- [ ] `test/utils/app_log_test.dart`, `test/config/env_config_secure_transport_test.dart`, `test/bootstrap/insecure_transport_screen_test.dart` (HARDEN-01, HARDEN-08)
- [ ] `test/repository/services/auth/logout_flow_test.dart`, `concurrent_unauthorized_refresh_test.dart` (HARDEN-03, HARDEN-04)
- [ ] `test/repository/services/auth/dual_session_revocation_test.dart` (HARDEN-06)
- [ ] `test/screens/auth/authenticated_shell_leak_test.dart`, `test/screens/auth/identity_transitions_test.dart` (HARDEN-05, HARDEN-06)
- [ ] `pubspec.yaml` `dev_dependencies`: `leak_tracker: ^11.0.2`, `leak_tracker_flutter_testing: ^3.0.10`
- [ ] `tool/hardening_check.sh`, `env/dev.json`, `env/prod.json`, `.github/workflows/ci.yml` (HARDEN-07, HARDEN-09)

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
