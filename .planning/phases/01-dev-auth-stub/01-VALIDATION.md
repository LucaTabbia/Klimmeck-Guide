---
phase: 1
slug: dev-auth-stub
status: draft
nyquist_compliant: true
wave_0_complete: true
created: 2026-04-14
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail |
| **Config file** | `pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter test test/repository/services/auth/` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/repository/services/auth/`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green + `flutter analyze` clean
- **Max feedback latency:** 20 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | Wave 0 | — | N/A | setup | `flutter pub get` | ❌ W0 | ⬜ pending |
| 1-02-01 | 02 | 1 | DEV-AUTH-01 | — | Contratto pubblico invariato | unit | `flutter test test/repository/services/auth/auth_token_service_contract_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-02 | 02 | 1 | DEV-AUTH-02 | — | Legge `.env` al cold start | unit | `flutter test test/repository/services/auth/dev_auth_token_service_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-03 | 02 | 1 | DEV-AUTH-03 | — | `DEV_AUTH_ROLE` produce User con role | unit | `flutter test test/repository/services/auth/dev_auth_token_service_role_test.dart` | ❌ W0 | ⬜ pending |
| 1-02-04 | 02 | 1 | DEV-AUTH-04 | — | `login()`/`logout()` no-op (log warning) | unit | `flutter test test/repository/services/auth/dev_auth_token_service_noop_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-01 | 03 | 2 | DEV-AUTH-05 | — | `RepositoryProvider<AuthTokenService>` sopra `MultiBlocProvider` | widget | `flutter test test/app/app_wiring_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-02 | 03 | 2 | DEV-AUTH-05 | — | `dio` interceptor chiama `getAccessToken()` | unit | `flutter test test/network/auth_interceptor_test.dart` | ❌ W0 | ⬜ pending |
| 1-03-03 | 03 | 2 | DEV-AUTH-05 | — | GraphQL client consuma `getAccessToken()` | unit | `flutter test test/network/graphql_auth_link_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pubspec.yaml` — add `flutter_dotenv: ^6.0.0` (runtime), `bloc_test`, `mocktail` (dev)
- [ ] `pubspec.yaml flutter.assets` — include `.env` (pitfall A4)
- [ ] `.env.example` — document `DEV_AUTH_ENABLED`, `DEV_AUTH_ACCESS_TOKEN`, `DEV_AUTH_USER_ID`, `DEV_AUTH_TWITCH_ID`, `DEV_AUTH_ROLE`
- [ ] `test/repository/services/auth/` — directory con stub test file per DEV-AUTH-01..04
- [ ] `test/app/`, `test/network/` — directory per wiring test DEV-AUTH-05
- [ ] `test/helpers/auth_fixtures.dart` — shared fixtures (test user, test token)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Cold start emits `Authenticated` immediatamente (no splash prolungato) | DEV-AUTH-02 | UX percettiva non misurabile deterministicamente in widget test | `flutter run`, osservare che non ci sia splash prolungato prima della main screen |
| Contract parity con Phase 11 | DEV-AUTH-01 | Phase 11 non ancora implementata — diff manuale vs `11-CONTEXT.md` D-01..D-03 | Diff interfaccia pubblica di `AuthTokenService` con il contratto canonico in `11-CONTEXT.md` |

---

## Validation Sign-Off

- [x] All tasks have `<automated>` verify or Wave 0 dependencies
- [x] Sampling continuity: no 3 consecutive tasks without automated verify
- [x] Wave 0 covers all MISSING references
- [x] No watch-mode flags
- [x] Feedback latency < 20s
- [x] `nyquist_compliant: true` set in frontmatter

**Approval:** approved
