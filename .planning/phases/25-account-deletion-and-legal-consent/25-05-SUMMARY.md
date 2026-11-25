---
phase: 25-account-deletion-and-legal-consent
plan: 05
subsystem: auth
tags: [consent, legal, login, terms-version]
requires:
  - 25-01 (LegalDocuments.version, consent checkbox gating the login)
provides:
  - AuthTokenService.login({required String acceptedLegalVersion})
  - termsVersion query parameter on GET /auth/twitch/start
  - termsNotAcceptedError ('terms_not_accepted') in login_callback.dart
  - LoginTermsNotAcceptedException
  - SignInFailure.termsNotAccepted and its line under the login button
  - SignInCubit.signInWithTwitch({required String acceptedLegalVersion})
affects: [25-07, 25-08]
tech-stack:
  added: []
  patterns:
    - wire name of the query parameter as a private constant (_termsVersionParameter)
key-files:
  created: []
  modified:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - lib/repository/services/auth/dev_auth_token_service.dart
    - lib/repository/services/auth/login_exception.dart
    - lib/repository/services/auth/login_callback.dart
    - lib/screens/signIn/cubit/sign_in_cubit.dart
    - lib/screens/signIn/cubit/sign_in_state.dart
    - lib/screens/signIn/sign_in_screen.dart
    - test/repository/services/auth/session_auth_token_service_login_test.dart
    - test/repository/services/auth/session_auth_token_service_logout_test.dart
    - test/repository/services/auth/session_auth_token_service_adopt_user_test.dart
    - test/repository/services/auth/dual_session_revocation_test.dart
    - test/repository/services/auth/dev_auth_token_service_test.dart
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
    - test/repository/services/auth/login_callback_test.dart
    - test/repository/account_deletion_flow_test.dart
    - test/screens/signIn/cubit/sign_in_cubit_test.dart
    - test/screens/signIn/sign_in_screen_test.dart
decisions:
  - "The sign-in screen sends the constant LegalDocuments.version (not the consent cubit's version); the login button is disabled while unticked, so the version only leaves when ticked"
  - "Dev bypass: login({required String acceptedLegalVersion}) => _signIn(); the version never travels (BE dev strategy exempt, D-19)"
  - "Mocktail stubs go through one local helper per test file (anyLogin) instead of repeating any(named: 'acceptedLegalVersion')"
metrics:
  duration: ~15 min
  completed: 2026-11-25
  tasks: 3
  files: 18
---

# Phase 25 Plan 05: The login carries the accepted legal version Summary

`login({required String acceptedLegalVersion})` on the whole auth contract: the real session opens `<base>/auth/twitch/start?challenge=<S256>&termsVersion=<version>`, the dev bypass accepts the version and sends nothing, the sign-in screen sends `LegalDocuments.version`; a callback `error=terms_not_accepted` becomes `LoginTermsNotAcceptedException` → `SignInFailure.termsNotAccepted` → «Accetta i Termini di servizio e l'Informativa sulla privacy per entrare.» under the login button, never the connection line.

## Tasks

| Task | Commits |
|------|---------|
| 1 Contract + version on the start URL | `79043e82` test(auth): expect the accepted legal version on the login; `511ba414` feat(auth): carry the accepted legal version on the login |
| 2 `terms_not_accepted` end to end | `781cdb97` test(signIn): expect the terms refusal mapped to its own line; `e509098e` feat(signIn): map the terms refusal of the login |
| 3 Bookkeeping | `docs(phase-25): record plan 05 progress` |

## RED failures

- Task 1: compile failure across the auth tests — `No named parameter with the name 'acceptedLegalVersion'` (session, dev, cubit and screen call sites), and in `dual_session_revocation_test.dart` the `_Device.login(String)` wrapper no longer matching the `Future<void> Function()` tear-off.
- Task 2: compile failure — `Undefined name 'termsNotAcceptedError'`, `Couldn't find constructor 'LoginTermsNotAcceptedException'`, `Member not found: 'termsNotAccepted'`.

No case was green at the first run (every touched test file failed to compile).

## Stub files changed (signature only)

`session_auth_token_service_logout_test.dart` (6 calls), `session_auth_token_service_adopt_user_test.dart` (helper), `dev_auth_token_service_transitions_test.dart` (2), `dual_session_revocation_test.dart` (`_Device.login(String acceptedLegalVersion)`, call sites `deviceA.login('v-test')` / `deviceB.login('v-test')`, and the two `deviceB.login` tear-offs became `() => deviceB.login('v-test')`), `account_deletion_flow_test.dart` (1). `auth_token_service_contract_test.dart` needed no change (it only checks `service.login` is a function). `session_auth_token_service_login_test.dart` funnels every login through `runLogin`, which now passes `acceptedLegalVersion: 'v-test'`; the start URL pin was rewritten in place.

## Verification

- `flutter test test/repository/services/auth test/screens/signIn test/screens/auth test/repository/account_deletion_flow_test.dart` → 426 green (after Task 1); after Task 2 `test/repository/services/auth test/screens/signIn` → 243 green, `test/screens/auth` + account deletion flow → 187 green.
- Analyzer after each code task: «47 issues found.» `ANALYZE_GATE_OK`.
- `grep -rn "\.login()" lib test` empty; `termsVersion` ×2 in the session service; «non cambia» ×0 in `login_exception.dart`; `LegalDocuments.version` on one line of the screen; `terms_not_accepted` ×1 in `login_callback.dart`; «per entrare.» ×1 in the screen; `git diff --stat 5c0b1b80 -- lib/graphql` empty.
- Trailer check `0` after each commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `test/repository/account_deletion_flow_test.dart` also called `service.login()`**
- **Found during:** Task 1 RED (the `grep -rn "\.login(" test lib` re-check)
- **Fix:** passes `acceptedLegalVersion: 'v-test'`; file outside `files_modified` (added by 25-03 after the plan was written).
- **Commit:** `79043e82`

**2. [Rule 1 - Bug, test] New dev case expected the first emission**
- **Found during:** Task 1 GREEN
- **Issue:** «the dev login accepts the version and behaves as before (D-19)» used `emits(isA<AuthAuthenticated>())`, but the auth channel replays the current `AuthUnauthenticated(signedOut)` to a new listener.
- **Fix:** `emitsThrough(...)`; the test change went into the GREEN commit `511ba414` (whole verification set re-run before committing).

**3. Doc-only renames** — two test titles/messages that said `login()` (`'login() after logout aligns with me again'`, `'login() did not settle'`) now say `login`, consistent with the doc-comment convention of the plan.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: the version is a public constant, no new logging; `parseLoginCallback` stays total and only the known code maps to the new exception (T-25-41).

## For the next plans

- Today's BE ignores `termsVersion`; the BE Phase 26 branch refuses a login without it (`?error=terms_not_accepted`, at the start and at the callback). The gate plan re-checks the parameter name and the code on the merged BE.
- `SignInCubit.signInWithTwitch` now requires `acceptedLegalVersion`; widget tests through the real `AuthGate` still need one `pump()` after the sign-in screen appears (25-01).
- `_Device.login` in `dual_session_revocation_test.dart` takes a positional version (no default).

## Self-Check: PASSED

Commits `79043e82`, `511ba414`, `781cdb97`, `e509098e` present in `git log`; all modified files exist.
