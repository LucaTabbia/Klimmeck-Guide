---
phase: 11-auth-session-bootstrap
fixed_at: 2026-10-06T19:12:23Z
review_path: .planning/phases/11-auth-session-bootstrap/11-REVIEW.md
iteration: 1
findings_in_scope: 8
fixed: 8
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-10-06T19:12:23Z
**Source review:** .planning/phases/11-auth-session-bootstrap/11-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 8 (WR-01..WR-05; IN-04, IN-06 and part of IN-09, as chosen by the orchestrator)
- Fixed: 8 (WR-01 and WR-02 change concurrency logic: **fixed, needs a human check**)
- Skipped: 0
- Out of scope / accepted: IN-01, IN-02, IN-03, IN-05, IN-07, IN-08
- Follow-ups recorded: 1 (the WR-05 D-12 teardown window). The second one, the ghost character subscription, was fixed later in 53ef293.

**Gates (after the last commit):**
- `flutter analyze lib test`: **11 issues**. These are the same 11 issues as the baseline: same files, same rules, none new.
- `flutter test`: **273 passed** (baseline 247, +26, including the 2 CharacterCubit specs from 53ef293).
- The 5 session-service spec files (bootstrap, refresh, login, revocation, logout) ran 5 times in a row: 63/63 passed every time. All timing uses `fake_async`.
- Every fix followed TDD: the regression test was written first and seen failing for the right reason, then the fix made it pass. Each commit holds the test and the fix for one finding.
- `dart format` was run only on new files and on phase files that were already formatter-clean, always by explicit path. The pre-existing gameplay Cubits got minimal one-line edits (checked with `git diff`). The 7 Cubits that were already formatter-clean are still clean.
- `git status` shows only the user's own ` M test/repository/services/auth/auth_token_service_contract_test.dart`.

## Fixed Issues

### WR-01: a caller of the old session could get the new session's token, and a slow logout could revoke the new session

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `lib/repository/services/auth/unauthorized_recovery.dart` (dartdoc), `test/.../session_auth_token_service_logout_test.dart`, `test/.../session_auth_token_service_revocation_test.dart`
**Commit:** 9581226
**Status:** fixed: needs a human check (concurrency logic)
**Applied fix:**
- `getAccessToken()` saves the session epoch when it is called. On success, on a transient error or on `_superseded`, it returns `null` if the epoch changed in the meantime. It never returns the next session's token.
- `recoverFromUnauthorized()` also checks the epoch after a forced refresh. **Deviation from the guidance (wider fix):** the service now keeps `_issuedAccessTokens`, the set of access tokens issued to the current session including rotations. The set is cleared in `_supersedeSession()`. Recovery returns `null` when the rejected token was not issued to the current session.
  - Why the epoch check alone is not enough: a request sent by session A can get its `UNAUTHENTICATED` after session B logged in, and only then call recovery. The old code saw `current != rejectedToken` and returned B's token. Also, the dio `AuthInterceptor` retry calls `getAccessToken()` again in `onRequest`, so only a `null` from recovery stops a cross-session retry.
  - `rejectedToken: null` now also returns `null`. Before, it returned the current token. The only caller that can pass `null` is the WebSocket after a connect without a token. It now waits for the normal backoff instead of the 500 ms quick retry, and still reads the current token on the next connect.
- The best-effort backend logout skips `api.logout` once its session is no longer current. In WR-02 this became "bound to the session being logged out" (see below).
- Changed an existing spec: "returns the current token without a refresh when it already rotated" used a token the service had never issued (`'stale-access'`). It now rotates for real first. A new spec checks that a foreign token gets `null`.
- New specs, as asked:
  - (a) Logout with a hung refresh, 4 s timeout, immediate new login, then the old refresh completes late (one test where it succeeds, one where it fails). `api.logout` is never called with session B's token, and B stays `Authenticated` with its storage and token intact.
  - (b) A `getAccessToken()` caller that is suspended while the session is replaced gets `null`.
  - (c) Recovery with a token from an earlier session gets `null` and no refresh is made.

### WR-02: logout could emit `sessionExpired` and then `signedOut`, and run the teardown twice

**Files modified:** `lib/repository/services/auth/session_auth_token_service.dart`, `test/.../session_auth_token_service_logout_test.dart`, `test/helpers/fakes/in_memory_session_store.dart` (`clears` counter), `BACKEND-NOTES.md`
**Commit:** 5576f7a
**Status:** fixed: needs a human check (concurrency logic)
**Applied fix:**
- There is no boolean parameter or flag. `logout()` now:
  1. `_detachSession()`: saves the session's credentials (access token, whether it is fresh, refresh token) and calls `_supersedeSession()`. That bumps the epoch, cancels the timers and detaches any refresh in flight, so its outcome, including a `SessionRejected`, is dropped as `_superseded`. It also sets `_refreshToken = null`, so nothing can start a new refresh.
  2. `_invalidateBackendSession(closing)`: gets the token for the backend call through `_backendLogoutToken`. This is a logout-only refresh step that calls `api.refreshSession` directly, outside the single-flight. A rejection skips the backend call instead of ending the session. A transient error falls back to the previous access token. The rotated refresh token is not persisted, because storage is cleared right after. The call is skipped if `closing.epoch != _epoch` (timeout already passed, or a newer session started).
  3. `_endSession(signedOut)`, exactly once.
- Result: one `AuthUnauthenticated(signedOut)`, one teardown and one `clear()`. This holds even when a proactive or reactive refresh that was already in flight gets rejected during the logout (extra spec).
- During the backend step (at most 4 s) the access token can still be read, so the shell's requests keep their bearer. It is just no longer renewed.
- **Deviation from CONTEXT D-36:** D-36 says the backend logout "uses the normal `getAccessToken()` path". It no longer does. What the backend sees is the same (`refreshSession` first if the token expired, then `logout`), with one exception: if a refresh is already in flight at logout time, the same refresh token is sent twice within a few seconds. That is inside the backend's 30 s grace window. This is documented in BACKEND-NOTES §2 and §6. `11-CONTEXT.md` was not edited; consider amending D-36.
- New specs:
  - The refresh inside logout answers `SessionRejected`: the stream shows exactly `[signedOut]`, teardown runs once, `clears == 1`, and `api.logout` is never called.
  - A proactive refresh that is rejected during logout: the stream shows exactly `[signedOut]`, teardown runs once, `clears == 1`.

### WR-03: a transient read error of the encrypted storage deleted a valid session

**Files modified:** `lib/repository/storage/session_store.dart`, `test/repository/storage/session_store_test.dart`, `BACKEND-NOTES.md`
**Commit:** 576be8a
**Applied fix:**
- `readRefreshToken()` now returns `null` when the read fails ("no session available now"), logs only the error's `runtimeType`, and deletes nothing. A later successful login overwrites the key anyway. The wipe on first launch (iOS reinstall keeps the Keychain) is unchanged.
- **`resetOnError` (flutter_secure_storage 10.3.4, installed source in the pub cache):**
  - Where the plugin wipes:
    - (a) `handleKeyMismatch` during init. This happens only on `BadPaddingException` / `InvalidKeyException` / `IllegalBlockSizeException` while unwrapping the stored AES key: the Keystore key was lost or invalidated, or the data came from a backup or device transfer. The plugin first tries to migrate, then calls `deleteAllDataAndKeys`.
    - (b) `handleStorageError` in `read`/`write`/`readAll`. With our default ciphers (RSA-OAEP key wrapping + AES-GCM storage), the AES key is already unwrapped in memory after init. So a failure here can only mean a value that no longer decrypts, which is permanent. The plugin deletes that one key and retries.
    - (c) A catch-all in the plugin calls `deleteAll()` only if the operation still fails after (b).
  - Transient Keystore errors during init (`KeyStoreException`, `ProviderException`, …) go to the generic `catch (Exception e) → callback.onError` path and never wipe.
  - Setting `resetOnError: false` would be worse. After a lost Keystore key, the init would fail on every call, including write and delete after a new login. The storage would stay unusable for good, and the user would have to log in at every cold start.
  - So the option is now **set explicitly to `true`** (`SecureSessionStore.defaultStorage`), with a dartdoc explaining why, and a spec pins it.
  - iOS has no such option. Its real transient case, `errSecInteractionNotAllowed` before the first unlock, is now covered by the Dart-side fix above.
- The old spec "a throwing read means no session and wipes the storage" became "… no session now and wipes nothing" (`deleteAll` and `delete` are never called). The spec "throwing read + throwing wipe" was removed because there is no wipe any more.

### WR-04: `initialize()` could throw and leave the cold start stuck on `AuthBootstrapping`

**Files modified:** `lib/repository/storage/session_store.dart`, `lib/repository/services/auth/session_auth_token_service.dart`, `lib/screens/auth/cubit/auth_cubit.dart`, tests (`session_store_test`, `session_auth_token_service_bootstrap_test`, `auth_cubit_test`), `test/helpers/mocks.dart` (`MockSharedPreferences`), `test/helpers/fakes/in_memory_session_store.dart` (`readFailure`)
**Commit:** 70a77ec
**Applied fix:**
- Store: the first-launch check is now `_markFirstLaunchDone()`, which never throws. If the preferences cannot be read or written (or `setBool` returns `false`), it counts as "not a first launch" and nothing is wiped.
  - The marker is now saved **before** the wipe. A marker that cannot be saved would otherwise repeat the wipe, and so log the user out, on every launch.
  - `_firstLaunchChecked` is still set before the await on purpose: one attempt per process. A second attempt in the same process could wipe a session written in the meantime. The next cold start tries again.
- Service: `initialize()` reads storage through `_readStoredRefreshToken()`, which never throws. Any failure resolves to `AuthUnauthenticated()` (signedOut, so the user lands on sign-in) with no network call and no wipe.
- `AuthCubit.start()` catches any `initialize()` failure, which covers any `AuthTokenService` implementation. It reports the error with `addError` (to the BlocObserver, without Flutter dependencies) and calls `showSignIn()`. That only acts while still `AuthBootstrapping`, so a state the service already resolved is kept.
- Specs:
  - store: preferences cannot be read → token returned, no wipe; marker cannot be saved → no wipe.
  - service: `readFailure` → `[Bootstrapping, Unauthenticated]`, no throw, storage kept.
  - cubit: failing `initialize` → `[AuthUnauthenticated()]` plus the error is reported; a late failure after the state is already `Authenticated` → no extra emission.

### WR-05: gameplay Cubits closed at logout still emitted after `close()`

**Files modified:** `lib/shared/bloc/safe_emit.dart` (new), `test/shared/bloc/safe_emit_test.dart` (new), `test/screens/mainScreen/questCubit/quest_cubit_test.dart` (new), `test/helpers/mocks.dart` (`MockKlimmeckGraphQl`), `lib/screens/auth/authenticated_shell.dart` (dartdoc), and one-line `with SafeEmit<…>` plus import in `character_cubit.dart`, `quest_cubit.dart`, `transaction_cubit.dart`, `main_screen_cubit.dart`, `world_map_cubit.dart`, `shop_cubit.dart`, `library_cubit.dart`, `journal_cubit.dart`
**Commit:** 5719931
**Applied fix:**
- New mixin `SafeEmit<S> on BlocBase<S>`: an `emit` after `close()` does nothing. It is applied to the 8 Cubits from `AuthenticatedShell` that emit after an `await`. No method was rewritten.
- `TransactionCubit` is included. The review said it was already safe, but that is wrong: `doTransaction` emits `TransactionDone` / `TransactionError` after the `await` without a guard. Only the delayed resets were guarded.
- `StorageCubit` never emits and was left untouched.
- `world_map_cubit.dart` was not formatter-clean before, so it was edited by hand without formatting; `git diff` shows only the import line and the class line.
- Specs:
  - the mixin: emits normally while open; an emit after close does nothing.
  - `QuestCubit` closed while `getQuests` is pending: a late response or a late error completes with no error. Before the fix both failed with `Bad state: Cannot emit new states after calling close`.
- **Second half of the finding (teardown runs while the shell is still mounted): recorded as a follow-up, not restructured.** See the follow-ups below.

**Ghost character subscription (found while fixing WR-05, later explicitly authorized)**, commit **53ef293**:
- The problem: after its `await`, `CharacterCubit.loadCharacter` called `subscribeToCharacter(id)` even if the Cubit had been closed in the meantime. The subscription went through the **new** client (`KlimmeckGraphQl` resolves the client from context), so a subscription from the previous session outlived the logout.
- The fix: `if (isClosed) return;` right after the `await`. This one line is the whole diff of `character_cubit.dart`, which was not reformatted.
- `close()` already cancelled `_sub`; a spec now pins that.
- New `test/screens/mainScreen/characterCubit/character_cubit_test.dart`:
  - closed while `getCharacter` is pending, then the query completes: `subscribeToCharacter` is never called and nothing throws. Before the fix it failed with an unexpected `subscribeToCharacter(c1)` call.
  - an open subscription loses its listener on `close()`.
- **Same-pattern sweep** of the other Cubits from `AuthenticatedShell`, looking for a subscription, listener or timer started after an `await` without an `isClosed` check, or a `StreamSubscription`/`Timer` that `close()` does not cancel:
  - Quest: `_sub` is never assigned, and `close()` cancels it.
  - MainScreen, WorldMap, Shop, Library, Journal: no subscriptions, listeners or timers.
  - Storage: no async work at all.
  - Transaction: the 4 s `Future.delayed` resets start after the `await`, but each callback already checks `if (!isClosed)`. A delayed callback holds no resource, and `SafeEmit` covers it too, so nothing was changed.
  - `ProfileCubit` is not provided by the shell, and grep finds no such pattern in it.
  - Result: **no other occurrence**.
- Gates after this commit: `flutter analyze lib test` = 11 issues (same as the baseline); `flutter test` = **273 passed**.

### IN-04: the callback parser did not check the `auth` host

**Files modified:** `lib/repository/services/auth/login_callback.dart`, `test/repository/services/auth/login_callback_test.dart`, `android/app/src/main/AndroidManifest.xml`, `BACKEND-NOTES.md`
**Commit:** dbde7c5
**Applied fix:**
- `parseLoginCallback` now also requires `uri.host == 'auth'`. `klimmeck://other?…`, `klimmeck://evil?error=…` and `klimmeck:?ticket=…` all map to `invalid_callback`.
- The `CallbackActivity` intent-filter is now `<data android:scheme="klimmeck" android:host="auth" />`. The manifest passes `xmllint`; `flutter build` was not run, as instructed.
- BACKEND-NOTES §2 now says the backend redirect must be exactly `klimmeck://auth?…`, and the UAT item now names the intent as `klimmeck://auth`.

### IN-06: `GraphQLClientHolder.reset()` was not serialized

**Files modified:** `lib/repository/services/graphql/graphql_client_holder.dart`, `test/repository/services/graphql/graphql_client_holder_test.dart`
**Commit:** d661345
**Applied fix:**
- `reset()` now reuses a reset that is already running (`_resetInFlight ??= _recreate().whenComplete(...)`). Overlapping calls dispose the old link once and create a single new connection, so no replaced link is left without `dispose`. Every caller resumes only after the new client is installed, and that client is always created after their call.
- A later `reset()` recreates again.
- Specs:
  - two overlapping resets with a slow dispose → 2 connections in total, link 0 disposed once, the client is connection 1. Before the fix there were 3 connections, one never disposed.
  - an overlapping pair followed by a reset → 3 connections, link 1 disposed.

### IN-09 (orchestrator-selected parts): small cleanups

**Commits:** 6cb4e3d (env flag), 0afecb4 (AuthGate), 77a59d6 (route helpers)
**Applied fix:**
- `EnvConfig.devAuthEnabled` now does `trim().toLowerCase()`, the same as `DEV_AUTH_START_SIGNED_OUT`. New `test/config/env_config_test.dart`: `" true "` (quoted, with spaces) failed before the fix.
- `AuthGate` also pops routes on the root Navigator when the authenticated `user.id` changes (`listenWhen: _leavesSession`). A token rotation for the same user keeps dialogs open. Two new widget specs cover both cases. The repeated user-change check in `_shouldRebuild` now reuses `_changesUser`.
- `createSlideRoute` / `createFadeRoute` were removed. `grep` over `lib/`, `test/` and `integration_test/` found no references outside their own definitions. They were the only content of `lib/routes/routes.dart`, so the file was deleted (`git rm`).
  - `docs/rules/architecture.md` and `docs/rules/ui-ux.md` still describe `lib/routes/routes.dart` as the place for a future route table. That is still valid guidance, so they were not edited.
  - `.planning/codebase/STRUCTURE.md:15` still lists the removed helpers. It is a codebase map and was left untouched; refresh it on the next mapping pass.
- The dev bypass still works: `test/screens/auth/auth_gate_dev_bypass_test.dart` passes.

## Follow-ups (not fixed, analysed)

### WR-05 (b): teardown runs while the shell is still mounted

D-12 fixes the order as "teardown → clear storage → emit `Unauthenticated`", and the existing spec "emits signedOut only after teardown and storage clear" checks it. So `AuthGate` removes the shell only after `holder.reset()` and `store.clear()`. In that window, a few milliseconds of local work, a gameplay request starts without a bearer, because the memory was already forgotten.

What already limits it after these fixes:
- `AuthAuthLink` and `AuthInterceptor` never retry a request sent without a token.
- Recovery returns `null` for tokens that do not belong to the current session (WR-01).
- A response that arrives after the shell is gone is dropped by `SafeEmit`.
- During the logout backend step (at most 4 s) the access token still goes out (WR-02), so the window is now only the local teardown.

The only visible effect left: a Cubit can show its error state for the last frame before the sign-in.

A complete fix needs one of two things. Either emit `Unauthenticated` (or a new "closing" state the gate reacts to) **before** the client is recreated, which changes D-12 and its spec. Or tear down by unmounting the shell first. Both are larger changes to the D-12 contract, so neither was done here. Proposed for a later phase (or Phase 12 hardening), together with a D-12 amendment.


## Out of scope / accepted (not fixed, as decided by the orchestrator)

- **IN-01**: the refresh schedule uses `exp − iat` from the JWT. This is a documented choice that protects against clock skew. Left as is.
- **IN-02**: if persisting the rotation fails, storage keeps the old refresh token. Not addressed in this pass.
- **IN-03**: a login that replaces a running bootstrap does not close the old session on the backend. Not addressed in this pass.
- **IN-05**: the WebSocket "stable connection" is measured from the payload, and recovery is evaluated before the `_attempt == 0` check. Not addressed in this pass.
- **IN-07**: the dev stub has no epoch guard between `_signIn` and `_endSession`. Not addressed in this pass.
- **IN-08**: `allowBackup="false"` does not cover device-to-device transfer. Not addressed in this pass. With WR-03 kept, an undecryptable transferred blob is still wiped by the Android plugin, because `resetOnError` is `true`.

## Handoff (BACKEND-NOTES.md) changes

- §2 `Logout` row (WR-02): the bearer belongs to the session that is logging out. A dedicated `refreshSession` runs first if the token expired, outside the single-flight. A rejection skips the call. A refresh that finishes after the timeout never sends a newer session's bearer.
- §6: a note for reuse detection. The logout refresh can reuse the same refresh token within the 30 s grace window if another refresh is in flight.
- §3 (WR-03): if the encrypted storage cannot be read at cold start, the user goes to sign-in **without** wiping. The next launch retries the stored token.
- §2 login row and §7 UAT (IN-04): the redirect must be exactly `klimmeck://auth?…`. Android accepts only scheme `klimmeck` + host `auth`.

---

_Fixed: 2026-10-06T19:12:23Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
