---
phase: 25-account-deletion-and-legal-consent
plan: 02
subsystem: auth
tags: [auth, revocation, sign-in, consent, account-deletion]
requires: [25-01]
provides:
  - UnauthenticatedReason.accountDeleted
  - sessionRevokedReasonAccountDeleted = 'accountDeleted' (wire constant)
  - SignInNotice.accountDeleted (text «Il tuo account è stato eliminato.»)
  - LegalConsentCubit.forget()
  - AuthGate._consentFor(reason, store) — accountDeleted → forget, every other reason → restore
affects: [25-03, 25-04, 25-08]
tech-stack:
  added: []
  patterns:
    - one function over the reason picks the consent entry point (no boolean flag)
key-files:
  created: []
  modified:
    - lib/repository/services/auth/auth_token_service.dart
    - lib/repository/services/auth/auth_api_exception.dart
    - lib/repository/services/auth/session_auth_token_service.dart
    - lib/screens/signIn/sign_in_screen.dart
    - lib/screens/auth/auth_gate.dart
    - lib/screens/signIn/consentCubit/legal_consent_cubit.dart
    - test/repository/services/auth/session_auth_token_service_revocation_test.dart
    - test/repository/services/auth/session_auth_token_service_terminate_test.dart
    - test/repository/services/auth/dev_auth_token_service_transitions_test.dart
    - test/repository/services/auth/dual_session_revocation_test.dart
    - test/screens/signIn/consentCubit/legal_consent_cubit_test.dart
    - test/screens/signIn/sign_in_screen_test.dart
    - test/screens/auth/auth_gate_test.dart
decisions:
  - "The consent entry point is chosen by AuthGate._consentFor(reason, store): accountDeleted → forget(), every other reason → restore()"
  - "D-18 fallback kept: after the BE's 15-minute window (or a BE restart) the refusal reads SESSION_EXPIRED → session-expired notice, consent memory kept; no client workaround"
metrics:
  duration: ~15 min
  completed: 2026-11-25
  tasks: 3
  files: 13
---

# Phase 25 Plan 02: The account-deleted landing Summary

`UnauthenticatedReason.accountDeleted` read from a refresh refused with `SESSION_REVOKED` + `extensions.reason = "accountDeleted"` (HTTP refresh and WebSocket closed with 4409 alike) and reachable through `terminateSession(accountDeleted)` (local teardown, no backend call); the sign-in shows «Il tuo account è stato eliminato.» above the login, and only that landing forgets the device's consent memory (the box starts unticked). Nothing new reaches today's BE.

## Tasks

| Task | Commits |
|------|---------|
| 1 `accountDeleted` reason (HTTP, WS 4409, local teardown) | `fc72ba15` test(auth): expect the accountDeleted revocation reason; `40c5a394` feat(auth): read the accountDeleted revocation reason |
| 2 Notice + consent forgotten only on that landing | `52771bd3` test(signIn): expect the account-deleted notice and the forgotten consent; `a69ebf39` feat(signIn): land a deleted account with its notice, forget the consent |
| 3 Bookkeeping | `docs(phase-25): record plan 02 progress` |

## RED failures

- Task 1: compile failure — `Member not found: 'accountDeleted'` (`UnauthenticatedReason`) and `Undefined name 'sessionRevokedReasonAccountDeleted'` in the four auth test files.
- Task 2: compile failure — `The method 'forget' isn't defined for the type 'LegalConsentCubit'`, `Member not found: 'accountDeleted'` (`SignInNotice`). With the Task 1 placeholder row (`accountDeleted => SignInNotice.sessionExpired`) the AuthGate cases would also have failed on the notice and on the remembered consent.

Cases green at the first run once compiling (existing behaviour, pinned for this phase): «a logout keeps the consent: the box starts ticked (D-10)» and «a session expired keeps the consent (D-10)» — `restore()` was already the entry point for every reason; the existing «unknown or missing reason → sessionExpired» cases (HTTP and WS) stayed green untouched. «a second terminateSession after accountDeleted is a no-op» is green from the existing guard in `terminateSession` (not authenticated → no-op).

## Fallback (D-15, D-18)

After the BE's 15-minute window, or after a BE restart inside it, the refresh answers `SESSION_EXPIRED`: the player reads the session-expired notice and the consent memory is kept (harmless: the next login sends the version again and the BE records it). Accepted by CONTEXT D-18; no client-side workaround.

## Verification

- `flutter test test/repository/services/auth test/screens/auth` → `+369: All tests passed!` (after Task 1)
- `flutter test test/screens/signIn test/screens/auth` → `+231: All tests passed!` (after Task 2)
- Analyzer after each code task: «47 issues found.» `ANALYZE_GATE_OK`
- Acceptance greps: wire constant 1, mapping row 1, notice literal 1 (only in its constant), `accountDeleted => SignInNotice.accountDeleted` 1, `.forget()` outside the consent Cubit and the AuthGate: none.
- `lib/graphql` untouched.

## Deviations from Plan

**1. [Commit subject] RED subject of Task 2 is 73 characters**
- `52771bd3` «test(signIn): expect the account-deleted notice and the forgotten consent» is one over the 72-character limit; the count was done after the commit. History is never rewritten, so it stays as is.

**2. [Formatting] Mapping row split by the formatter**
- In `session_auth_token_service.dart` the formatter wrapped `sessionRevokedReasonAccountDeleted =>` / `UnauthenticatedReason.accountDeleted,` over two lines; the plan's grep (`sessionRevokedReasonAccountDeleted` count 1) is unaffected.

**3. [Rule 3 - Test harness] One extra pump in the AuthGate consent cases**
- The lazy `LegalConsentCubit` reads the store one frame after the sign-in appears (known from 25-01): `landWith` pumps once more after the landing, with a one-line comment. App behaviour unaffected.

**4. Extra assertion**
- The terminate case also asserts `verifyNever(() => api.refreshSession('r1'))` (no backend call at all, D-06); the sign-in case also asserts the notice sits above the login button.

## Known Stubs

None.

## Threat Flags

None beyond the plan's register: T-25-10 (HTTP and WS revocation tests), T-25-12 (consent forgotten on the landing), T-25-13 (the only exhaustive switches on the enum are `_noticeFor` and `_consentFor`, both covered).

## For the next plans

- 25-03 ends the own deletion with `SessionTerminator.terminateSession(UnauthenticatedReason.accountDeleted)`: the AuthGate then forgets the consent by itself (`AuthAuthenticated` → `AuthUnauthenticated(accountDeleted)` always creates a new provider element). There is no need to call `LegalConsentStore.forget()` from the deletion path; doing it as well is harmless.
- `terminateSession` is a no-op once unauthenticated: a refresh or socket close landing after the teardown cannot overwrite the reason; the race while the deletion is still in flight (Pitfall 1) is 25-03's job.

## Self-Check: PASSED

Commits `fc72ba15`, `40c5a394`, `52771bd3`, `a69ebf39` present in `git log`; all modified files exist.
