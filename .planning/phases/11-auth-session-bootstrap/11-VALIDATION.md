---
phase: 11
slug: auth-session-bootstrap
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-13
updated: 2026-10-06
---

# Phase 11 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.
> Rewritten 2026-10-06 from 11-RESEARCH.md §Validation Architecture (rev. 2) for the backend-mediated session design; the April PKCE-based map is obsolete.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` + `bloc_test 10.0.0` + `mocktail 1.0.5` + `fake_async 1.3.3` (dev, declared in 11-01) |
| **Config file** | none (`analysis_options.yaml` = `flutter_lints`) |
| **Quick run command** | `flutter test test/repository/services/auth test/network test/screens` |
| **Full suite command** | `flutter test` (baseline before the phase: 20 tests green) |
| **Lint** | `flutter analyze lib test` — baseline 14 pre-existing issues (3 warning, 11 info); gate = no new issue; after 11-10 ≤ 11 |
| **Format** | `dart format --output=none --set-exit-if-changed <files touched by the task>` — NEVER on directories (D-38) |
| **Native build** | `flutter build apk --debug` (AGP 8.9.1, from 11-01) |
| **Estimated runtime** | ~30–45 s test suite; ~3–5 min Android debug build |

Widget tests use `buildTestApp()` (`test/helpers/test_app.dart`), which sets `GoogleFonts.config.allowRuntimeFetching = false`. Tests that bundle assets need the local, git-ignored `.env` file.

---

## Sampling Rate

- **After every task commit:** `flutter test <test files of the task>` + `flutter analyze <files touched>` + targeted `dart format --output=none --set-exit-if-changed <files>`
- **After every plan wave:** `flutter test` (full suite)
- **Native config changes (11-01, 11-10, 11-11):** `flutter build apk --debug`
- **Before `/gsd-verify-work`:** full suite green + `flutter analyze lib test` ≤ 11 issues + `flutter build apk --debug` OK
- **Max feedback latency:** 60 seconds (build excluded)

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 11-01-01 | 01 | 1 | AUTH-01, AUTH-02 | T-11-01..05 | INTERNET + allowBackup=false + CallbackActivity `klimmeck`; no Twitch key in `.env.example` | build + grep | `flutter pub get && flutter build apk --debug && flutter test` | ✅ (config files) | ⬜ pending |
| 11-01-02 | 01 | 1 | AUTH-01 | — | shared mocks / themed test app | widget | `flutter test test/app` | ❌ W0 (`test/helpers/mocks.dart`, `test/helpers/test_app.dart`) | ⬜ pending |
| 11-02-01 | 02 | 2 | AUTH-01, AUTH-06 | T-11-07, T-11-09 | S256 = RFC 7636 vector; tokens never in `toString`; refresh floor 30 s | unit | `flutter test test/models/auth test/repository/services/auth/access_token_lifetime_test.dart` | ❌ W0 | ⬜ pending |
| 11-02-02 | 02 | 2 | AUTH-01 | T-11-06, T-11-10 | callback scheme checked, total parse; `CANCELED` → cancelled; no WebView | unit | `flutter test test/repository/services/auth/login_callback_test.dart test/repository/services/auth/browser_authenticator_test.dart` | ❌ W0 | ⬜ pending |
| 11-02-03 | 02 | 2 | AUTH-07 | T-11-07 | `AuthUnauthenticated.reason` additive; replaying state channel | unit | `flutter test test/repository/services/auth` | ❌ W0 (`auth_state_test.dart`, `auth_state_channel_test.dart`) | ⬜ pending |
| 11-03-01 | 03 | 3 | AUTH-02 | T-11-11..13 | refresh token only in secure storage; read failure → clear; first-launch wipe | unit | `flutter test test/repository/storage/session_store_test.dart` | ❌ W0 | ⬜ pending |
| 11-03-02 | 03 | 3 | AUTH-01, AUTH-03, AUTH-07 | T-11-14..16 | dedicated client (no auth link loop); error codes → domain exceptions; on refresh ONLY SESSION_EXPIRED/SESSION_REVOKED are terminal (UNAUTHENTICATED/BAD_REQUEST/401 → transient, no wipe); no logging | unit | `flutter test test/repository/services/auth/graphql_backend_auth_api_test.dart` | ❌ W0 | ⬜ pending |
| 11-04-01 | 04 | 4 | AUTH-04, DEV-AUTH-04 | T-11-17, T-11-18 | dev stub login/logout/revocation transitions, start signed out | unit | `flutter test test/repository/services/auth` | ❌ W0 (`dev_auth_token_service_transitions_test.dart` replaces `_noop_test`) | ⬜ pending |
| 11-04-02 | 04 | 4 | AUTH-05 | T-11-19 | dev identity aligned via `me`, `.env` fallback | unit | `flutter test test/repository/services/auth/dev_auth_token_service_test.dart` | ✅ extended | ⬜ pending |
| 11-05-01 | 05 | 5 | AUTH-03, AUTH-06, AUTH-07 | T-11-21..24 | cold start resolve; persist-before-forget; single-flight (1 network refresh for N callers); proactive refresh exp−60 s with floor; transient (incl. UNAUTHENTICATED/BAD_REQUEST on refresh) never wipes or logs out; revocation → sessionExpired | unit (fakeAsync) | `flutter test test/utils/backoff_test.dart test/repository/services/auth/session_auth_token_service_bootstrap_test.dart test/repository/services/auth/session_auth_token_service_refresh_test.dart` | ❌ W0 | ⬜ pending |
| 11-05-02 | 05 | 5 | AUTH-01 | T-11-20, T-11-25 | start URL with S256 challenge; ticket redeemed with verifier; cancel/denied silent; `twitch_not_configured` distinct; cancelled/failed login keeps the stored-session background retry alive (old session invalidated only after a successful exchange) | unit | `flutter test test/repository/services/auth/session_auth_token_service_login_test.dart` | ❌ W0 | ⬜ pending |
| 11-06-01 | 06 | 6 | AUTH-06, AUTH-07 | T-11-30 | recovery reuses rotated token, else single-flight; revocation without backend call | unit | `flutter test test/repository/services/auth/session_auth_token_service_revocation_test.dart` | ❌ W0 | ⬜ pending |
| 11-06-02 | 06 | 6 | AUTH-04, AUTH-05 | T-11-26..29 | teardown order D-12 (`verifyInOrder`); 4 s timeout; offline ok; epoch guard vs zombie session; account switch A→B | unit (fakeAsync) | `flutter test test/repository/services/auth` | ❌ W0 | ⬜ pending |
| 11-07-01 | 07 | 7 | AUTH-06 | T-11-31, T-11-32 | GraphQL UNAUTHENTICATED / 401 → one retry with fresh token, never a loop | unit | `flutter test test/network/graphql_auth_link_test.dart` | ✅ extended | ⬜ pending |
| 11-07-02 | 07 | 7 | AUTH-06 | T-11-31, T-11-33, T-11-34 | REST 401 → one retry (FormData cloned), plain `Interceptor` | unit (fake adapter) | `flutter test test/network` | ✅ extended | ⬜ pending |
| 11-08-01 | 08 | 8 | AUTH-06 | T-11-35..37 | WS init payload = current token, never throws; 4401/4403 → recovery; capped backoff | unit | `flutter test test/repository/services/graphql/ws_reconnect_policy_test.dart` | ❌ W0 | ⬜ pending |
| 11-08-02 | 08 | 8 | AUTH-04 | T-11-38 | holder reset disposes WS link and installs a new client | unit | `flutter test test/repository/services/graphql` | ❌ W0 | ⬜ pending |
| 11-09-01 | 09 | 9 | AUTH-04, AUTH-07 | — | AuthCubit mirrors service, start() → initialize(), showSignIn(), logout() | bloc_test | `flutter test test/screens/auth/cubit/auth_cubit_test.dart` | ❌ W0 | ⬜ pending |
| 11-09-02 | 09 | 9 | AUTH-01, AUTH-07 | T-11-41..43 | sign-in states D-21/D-22/D-27, session-expired notice D-31; Twitch glyph fetched from Simple Icons (pinned version + sha256 in SUMMARY) and `SvgPicture` pumps without exceptions, or text-only button fallback | bloc_test + widget | `flutter test test/screens/signIn` | ❌ W0 | ⬜ pending |
| 11-09-03 | 09 | 9 | AUTH-04 | T-11-40 | non-dismissible logout confirmation; confirm → logout | widget | `flutter test test/shared/components/modal/logout_confirmation_dialog_test.dart` | ❌ W0 | ⬜ pending |
| 11-10-01 | 10 | 10 | AUTH-03, AUTH-07 | T-11-48 | splash connection hint after 10 s, manual sign-in, no chrome | bloc_test (fakeAsync) + widget | `flutter test test/screens/splash` | ❌ W0 | ⬜ pending |
| 11-10-02 | 10 | 10 | AUTH-03, AUTH-04, AUTH-05 | T-11-44..47, T-11-49 | gate routing; shell keyed on user.id (no bleed); modals closed on sign-out; dev bypass end-to-end; composition root selects real service | widget + build | `flutter test && flutter build apk --debug` | ❌ W0 (`auth_gate_test.dart`, `auth_gate_dev_bypass_test.dart`, `authenticated_shell_test.dart`) | ⬜ pending |
| 11-11-01 | 11 | 11 | AUTH-01..07 | T-11-51 | contract aligned with BE BACKEND-NOTES/schema.gql; phase gate | full suite + lint + build | `flutter test && flutter analyze lib test; flutter build apk --debug` | ✅ | ⬜ pending |
| 11-11-02 | 11 | 11 | AUTH-01..07 | T-11-50, T-11-52 | handoff without secrets; pending UAT list | grep | `grep -q DEV_AUTH_START_SIGNED_OUT .planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` | ❌ (created by task) | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `pubspec.yaml`: `flutter_web_auth_2 ^5.1.0`, `flutter_secure_storage ^10.3.4`, `crypto ^3.0.7`, dev `fake_async ^1.3.3` (11-01-01)
- [ ] AGP 8.9.1 in `android/settings.gradle.kts`; main manifest with `INTERNET`, `allowBackup="false"`, `CallbackActivity` scheme `klimmeck`; `flutter build apk --debug` OK (11-01-01)
- [ ] `.env.example` without `TWITCH_CLIENT_ID`, with `DEV_AUTH_START_SIGNED_OUT=false` (11-01-01)
- [ ] `test/helpers/mocks.dart` (single `MockAuthTokenService`, then extended per plan), `test/helpers/test_app.dart` (11-01-02)
- [ ] `test/helpers/auth_session_fixtures.dart` (11-02-01), `test/helpers/fakes/in_memory_session_store.dart` (11-03-01), `test/helpers/fakes/fake_http_client_adapter.dart` (11-07-02)
- [ ] Rewrite `test/repository/services/auth/dev_auth_token_service_noop_test.dart` → `dev_auth_token_service_transitions_test.dart` (11-04-01)
- [ ] New contract tests go in `auth_state_test.dart`, never in `auth_token_service_contract_test.dart` (holds the user's uncommitted one-line edit)

---

## Manual-Only Verifications (pending UAT — D-28, not a blocking checkpoint)

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real Twitch login through the system browser and `klimmeck://` return | AUTH-01 | Twitch keys do not exist yet; needs a real OS browser and device | With BE keys configured and a reachable `BASE_URL` (https tunnel on LAN devices, `adb reverse` on the Android emulator): tap "Login con Twitch" → complete on Twitch → app lands in the main shell |
| Browser cancel (back / close) and consent denial | AUTH-01 | Real AuthTab / Custom Tabs / ASWebAuthenticationSession behaviour | Cancel or deny → sign-in unchanged, no message |
| `twitch_not_configured` from a real BE | AUTH-01 | Requires BE running without keys | Tap login → "Login con Twitch non ancora disponibile." |
| Cold-start resume after force-kill | AUTH-03 | Real process kill + Keychain/Keystore | Login → kill app → relaunch → main shell with no prompt |
| WS 4401 silent reconnect after 15 min | AUTH-06 | Real BE socket expiry | Keep a subscription open > 15 min → no visible interruption, events resume |
| Account switch with Twitch SSO | AUTH-05 | Real Twitch session in the system browser | Logout → login with account B → B's identity, nothing from A; if Twitch reuses A, switch `preferEphemeral` to `true` |
| Server-side session revocation | AUTH-07 | Requires BE-side revocation | Revoke the session on the BE → next refresh returns to sign-in with "La sessione è scaduta, accedi di nuovo." |
| iOS reinstall / Android backup restore | AUTH-02 | Platform storage behaviour | Reinstall → no stale session; restore → no crash, sign-in shown |

Full checklist: `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` §Checklist UAT pendente (created by 11-11-02).

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 60s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
