---
phase: 11-auth-session-bootstrap
fixed_at: 2026-10-06T19:31:40Z
review_path: .planning/phases/11-auth-session-bootstrap/11-REVIEW-2.md
iteration: 2
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report, iteration 2

**Fixed at:** 2026-10-06T19:31:40Z
**Source review:** .planning/phases/11-auth-session-bootstrap/11-REVIEW-2.md
**Iteration:** 2

**Summary:**
- Findings in scope: 5, as chosen by the orchestrator: WR-N1, IN-N1, IN-N2 and IN-N3 (code), IN-N7 (documentation only).
- Fixed: 5. WR-N1 and IN-N2 change concurrency logic: **fixed, needs a human check**.
- Skipped: 0.
- Not fixed / accepted: IN-N4, IN-N5, IN-N6 (see below).

**Gates (after the last commit):**
- `flutter analyze lib test`: **11 issues**, the same as the baseline. None are new.
- `flutter test`: **278 passed** (baseline 273, plus 5 new specs).
- The 5 session-service spec files (bootstrap, refresh, login, revocation, logout) ran 5 times in a row: **68/68 passed every time**. All timing uses `fake_async`, with no real sleeps.
- `test/screens/auth/auth_gate_dev_bypass_test.dart` passes.
- `dart format` was run only on the 3 touched files, each by explicit path. `--set-exit-if-changed` reports 0 changes.
- `git status` shows only the user's own ` M test/repository/services/auth/auth_token_service_contract_test.dart`.
- TDD: every regression spec was written first and failed for the expected reason before the fix. Each commit holds one finding's spec and fix.

## Fixed Issues

### WR-N1: `logout()` was not re-entrant

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `test/repository/services/auth/session_auth_token_service_logout_test.dart`
**Commit:** 92f46de
**Status:** fixed: needs a human check (concurrency logic)
**Applied fix:**
- `logout()` is now `_logoutInFlight ??= _performLogout().whenComplete(() => _logoutInFlight = null)`. Overlapping calls await the same logout. That means one detach, one backend step, one teardown, one `clear()` and one `signedOut`.
- `login()` now awaits `_logoutInFlight` after the ticket is redeemed and before `_startSession`. The new session is installed only after the logout has ended, so the end of that logout cannot touch the new session. The browser flow and the redemption are not delayed. Only the install waits, for at most the 4 s logout timeout plus the local teardown. In practice the sign-in screen appears only after `signedOut`, so the wait is normally zero.
- **Deviation from the suggested guidance (`if (closing.epoch != _epoch) return;` before `_endSession`):** that guard was not added, for two reasons:
  1. The required spec (b) says the teardown runs exactly once, for A, and never after B started. With the guard, A's teardown would be skipped completely. Its subscriptions and GraphQL client would never be reset.
  2. During a logout, the only other thing that moves the epoch is `dispose()`. With the guard, a logout followed by `dispose()` inside the 4 s window would skip `clear()`, and A's refresh token would survive to the next cold start.
  So the ending step is bound to the session being closed by ordering instead: no newer session can exist until the logout has finished.
- New specs (`overlapping logout` group):
  - (a) Two overlapping `logout()` calls with an expired access token and a backend that hangs. Checks: one `refreshSession('r1')`, `api.logout` captured only once with A's rotated token, teardown once, `clears == 1`, exactly `[signedOut]` emitted, and both futures complete. Before the fix, `api.logout` was also called with the stale `a1`.
  - (b) A logout whose backend hangs, then a login that completes inside the 4 s window. After the timeout, the state is `AuthAuthenticated(B)`, the store holds `login-refresh-b`, `getAccessToken()` returns B's token, teardown ran once, and the event order is `[teardown, session B]`. Before the fix, the state ended as `signedOut`.

### IN-N2: the epoch guard on the backend logout skipped a valid revocation

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `test/repository/services/auth/session_auth_token_service_logout_test.dart`, `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` (§2 Logout row)
**Commit:** 4e8e2a6
**Status:** fixed: needs a human check (concurrency logic)
**Applied fix:**
- `_invalidateBackendSession` no longer checks `closing.epoch != _epoch`. It skips the call only when there is no bearer. The bearer still comes only from `_backendLogoutToken(closing)`: the closed session's fresh access token, or the result of the logout-only refresh with its own refresh token. So a late call always carries the closed session's token and never a newer session's.
- The `epoch` field of `_ClosingSession` had no remaining readers, so it was removed (Boy Scout, same scope).
- New spec: an expired access token, with the logout-only refresh slower than the 4 s timeout. The user is signed out at the timeout, and B logs in. When the refresh finally returns, `api.logout` is captured exactly once with A's rotated token. B stays `Authenticated`, and its storage and token are intact. Before the fix, `api.logout` was never called.
- **Changed an existing spec:** "a cold-start refresh completing after logout is discarded" asserted `verifyNever(api.logout(any()))`. That assertion encoded the removed guard. A logout during a pending bootstrap now revokes the closed session with that session's own token, which is the intended behaviour. The spec now checks that `api.logout` is captured once with `_sessionA.accessToken`. The rest of the spec is unchanged: no storage write, no `Authenticated`, and the state is still `signedOut`.
- The WR-01 specs stay green: the two "hung logout refresh … never revokes the new session" specs, "recovery for a token of a previous session yields null", and "returns null for a token never issued".
- BACKEND-NOTES §2 now says the backend may receive this `logout` a few seconds after the app already shows sign-in, even after a new login. The call must stay idempotent and revoke only that bearer's `sid`. Overlapping logouts share one call.

### IN-N1: `_issuedAccessTokens` grew without limit

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `test/repository/services/auth/session_auth_token_service_refresh_test.dart`
**Commit:** cfc7aef
**Applied fix:**
- New named constant `SessionAuthTokenService.recognisedAccessTokenLimit = 4` (`@visibleForTesting`): the current token plus the previous three.
- `_issuedAccessTokens` is now a `List<String>`, oldest first. `_rememberIssuedAccessToken` removes a duplicate, appends the token and drops the oldest entry when the list is over the limit.
- New spec: 10 proactive rotations. After each rotation it checks, for every earlier token:
  - the last `limit − 1` previous tokens are recovered as the current token, with no refresh (so the immediately previous token is accepted right after a rotation);
  - every older token gets `null`.
  This shows the recognised window never grows past the limit. Exactly 11 refreshes happen. Before the fix, token 0 was still recognised after rotation 4.

### IN-N3: a rotation that changed the user did not clear the token set

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `test/repository/services/auth/session_auth_token_service_refresh_test.dart`
**Commit:** 221f279
**Applied fix:**
- `_applySession` clears `_issuedAccessTokens` when the incoming `session.user.id` differs from the current user, before it records the new token. This covers a rotation that changes the user. Login and bootstrap already start from an empty list.
- Supersede, end, logout and dispose already cleared the list through `_supersedeSession()`. That is unchanged.
- New spec: a rotation to another user, then a recovery with the first user's token, gets `null` and starts no extra refresh. Before the fix, it got the new user's token.

### IN-N7: a lost refresh response retried after 30 s revokes the session (documentation only)

**Files modified:** `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` (§3, refresh flow)
**Commit:** cec5de4
**Applied fix:**
- New §3 bullet. The backend rotates only the immediately previous refresh token within 30 s, and any other retired token revokes the session. A `refreshSession` that reached the backend but whose response was lost is retried with `r0`, also at cold start if the process died before `r1` was written. If that retry arrives more than 30 s later, the answer is `SESSION_REVOKED` and the user must log in again.
- So D-09 ("transient errors never log the user out") holds when the backend did not process the request, and for short outages (under about 30 s). It depends on backend decision D-26 on the grace window, which still needs the user's confirmation. A longer grace, or an idempotent `refreshSession(r0)` that returns the same `r1`, would reduce the problem.
- `11-CONTEXT.md` was not edited, as instructed. The orchestrator will amend D-09.

## Not fixed (accepted / pre-existing)

- **IN-N4:** pre-existing and not introduced by the fixes. `_startSession` keeps the previous session's credentials in memory while it persists the new one. No caller is active in that window today; the only real case is D-18 with a bootstrap in retry, when the shell is not mounted.
- **IN-N5:** accepted trade-off, documented in BACKEND-NOTES §3. Storage that is temporarily unreadable leads to sign-in for the life of the process. Proposed follow-up: retry the read on the first `resumed`.
- **IN-N6:** accepted, as the review says. The first-launch marker is saved before the wipe. A process kill in the few-millisecond gap skips the wipe, but the reverse order would log the user out on every launch.

## Notes for the human check

- WR-N1, out of scope and left as is: the review also mentions a user logout that overlaps an `_endSession(sessionExpired)` already running from a rejected refresh (teardown and clear run again, and a second terminal state is emitted). Shared logout does not cover that path. It was not in the orchestrator's scope.
- The refresh spec file gained a `recover(service, async, token)` helper, used by the IN-N1 and IN-N3 specs.

---

_Fixed: 2026-10-06T19:31:40Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 2_
