---
phase: 1
slug: auth-session-bootstrap
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test + bloc_test + mocktail |
| **Config file** | none — Wave 0 installs test deps in pubspec dev_dependencies |
| **Quick run command** | `flutter test test/unit` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test test/unit` (plus `flutter analyze`)
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite + `flutter analyze` must be green
- **Max feedback latency:** 60 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 1 | AUTH-01..07 | — | — | wave-0 stubs | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

*Full per-task map will be populated by the planner during PLAN.md creation (one row per task, mapping to AUTH-01..07 and threat model entries).*

---

## Wave 0 Requirements

- [ ] `test/unit/auth/auth_token_service_test.dart` — stubs for AUTH-02, AUTH-03, AUTH-06
- [ ] `test/unit/auth/auth_cubit_test.dart` — stubs for AUTH-01, AUTH-04, AUTH-05, AUTH-07
- [ ] `test/unit/auth/session_teardown_test.dart` — stubs for AUTH-04 (logout cleanup)
- [ ] `test/widget/auth/sign_in_screen_test.dart` — stubs for AUTH-01 (UI flow)
- [ ] `test/helpers/mocks.dart` — shared mocks (SecureStorage, graphql_flutter client, AuthApi, flutter_web_auth_2)
- [ ] Add dev deps: `bloc_test`, `mocktail` (if missing)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Twitch OAuth in real system browser + deep-link return | AUTH-01 | Requires real OS browser + deep-link registration (no in-process emulation) | Run on device: tap Sign-in → complete on Twitch in Chrome/Safari → app resumes authenticated |
| Cold-start resume after force-kill | AUTH-03 | Requires actual OS process kill | Login → swipe-kill app → relaunch → expect Home with no sign-in prompt |
| External Twitch revocation detection | AUTH-05 | Requires Twitch dashboard action outside the app | Login → revoke app at twitch.tv/settings/connections → next request returns user to sign-in with clear message |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
