---
phase: 11-auth-session-bootstrap
plan: 10
subsystem: auth
tags: [auth-gate, splash, composition-root, dev-bypass, bloc]
requires: [11-09]
provides:
  - SplashCubit bootstrap watch (SplashNetworkDelayed after 10 s) + SplashScreen(watchConnection, onManualSignIn)
  - AuthGate (state-driven routing, user.id-keyed session subtree, root navigator teardown)
  - AuthenticatedShell (gameplay cubits + post-auth SVG preload + MainScreen)
  - main.dart composition root (DevAuthTokenService | SessionAuthTokenService, recovery wired, holder teardown)
affects: [11-11]
tech-stack:
  added: []
  patterns: [state-driven auth gate, KeyedSubtree per session, late final holder to break wiring cycle, record-typed composition helper]
key-files:
  created:
    - lib/screens/auth/auth_gate.dart
    - lib/screens/auth/authenticated_shell.dart
    - test/screens/splash/cubit/splash_cubit_test.dart
    - test/screens/splash/splash_screen_test.dart
    - test/screens/auth/auth_gate_test.dart
    - test/screens/auth/auth_gate_dev_bypass_test.dart
    - test/screens/auth/authenticated_shell_test.dart
  modified:
    - lib/screens/splash/cubit/splash_cubit.dart
    - lib/screens/splash/cubit/splash_state.dart
    - lib/screens/splash/splash_screen.dart
    - lib/main.dart
    - lib/routes/routes.dart
    - test/helpers/mocks.dart
key-decisions:
  - "SvgCacheManager in SplashCubit made lazy (late final) so the cubit is constructible without platform channels"
  - "The global SplashCubit is shared by the cold-start gate and the shell preload; the gate splash resets SplashNetworkDelayed on dispose"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 10: AuthGate, splash cold-start gate and composition root Summary

State-driven `AuthGate` (Splash / SignIn / user-keyed `AuthenticatedShell`), splash with a 10 s non-blocking "Accedi manualmente" hint, gameplay cubits scoped to the session, post-auth Cloudinary preload, and a `main.dart` composition root choosing `DevAuthTokenService` or `SessionAuthTokenService` without blocking the first frame.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | c25916d | test(phase-11): add splash bootstrap watch specs |
| T1 GREEN | ccd20b9 | feat(phase-11): turn splash into cold start gate with connection hint |
| T2 RED | 71f0df2 | test(phase-11): add auth gate, dev bypass and authenticated shell specs |
| T2 GREEN | 7fd44ab | feat(phase-11): add auth gate and authenticated shell, wire session composition root |

## Results

- `flutter test`: 247 tests, all passed (baseline 220; +27: 5 splash cubit, 5 splash screen, 10 gate, 3 dev bypass, 4 shell)
- `flutter analyze lib test`: 11 issues (baseline 14). Disappeared: `splash_cubit.dart` `depend_on_referenced_packages` (bloc), `depend_on_referenced_packages` (meta), `avoid_print`. Zero issues in plan files.
- `flutter build apk --debug`: success (`build/app/outputs/flutter-apk/app-debug.apk`). The build rewrote `android/app/build.gradle.kts` (`minSdk = 23` → `flutter.minSdkVersion`); the line was restored by hand and the file was NOT committed.
- `dart format --output=none --set-exit-if-changed` on the 12 created/rewritten .dart files by explicit path: exit 0. `lib/routes/routes.dart` excluded: pre-existing non-formatter-clean file where only lines were removed.
- Acceptance greps: no `UnimplementedError` / `.initialize();` in `lib/main.dart`; one `SessionAuthTokenService(` and one `DevAuthTokenService(`; `onSessionTeardown: () => graphQlHolder.reset()` present; `GraphQLProvider(` before `MaterialApp(`; no `BlocProvider<CharacterCubit>` in main; consumers (`auth_link`, `auth_interceptor`, `auth_cubit`, `sign_in_cubit`, `auth_gate`) have 0 references to concrete services; no route helpers left in `lib`.

## Modal audit (T-11-49)

`grep` of `shop.dart` / `world_map.dart`: the three `showModalBottomSheet` builders (shop modal, transaction modal, city info) do not read any Cubit from their own context. `_onConfirm` uses the `State.context` of `Shop` (inside the shell providers). `world_map.dart` reads `CharacterCubit` only from its own State context. `LogoutConfirmationDialog`'s `confirmLogout` reads `AuthCubit`, which lives above `MaterialApp`. No `BlocProvider.value` wrapping needed.

## Deviations from Plan

1. **[Rule 3 - Blocking] Lazy `SvgCacheManager` in `SplashCubit`.** `SplashCubit(MockKlimmeckRest())` crashed in plain unit tests because `SvgCacheManager()` touches `path_provider` in its constructor. Changed `final svgCacheManager` to `late final svgCacheManager` (created on first `getImages`). Commit ccd20b9.
2. **[Test fix] Spy provider `lazy: false` in `auth_gate_test.dart`.** The spy cubit in the test's `authenticatedBuilder` was never created because `BlocProvider` is lazy; the one-line test fix was committed with the GREEN commit 7fd44ab.
3. **Formatter layout.** `KeyedSubtree(key: ValueKey<String>(user.id), ...)` is split over lines by `dart format`, so the single-line acceptance grep matches `key: ValueKey<String>(user.id),` on its own line; the splash copy lives in file-level constants (`_connectionHintText`, `_manualSignInLabel`). Semantics unchanged.
4. **Extra tests (beyond plan list):** gate `sessionExpired → signedOut ends on final state`, gate `late successful bootstrap still enters the session` (D-18), splash `does not preload images on its own`, shell `provides gameplay cubits and closes them on removal`.

## Known Stubs

None introduced. (`MainScreen` still loads a hard-coded character id; pre-existing, out of scope.)

## Threat Flags

None beyond the plan's threat model (T-11-44..49 mitigated as planned).

## Notes for 11-11

- Wiring: `main()` builds `late final GraphQLClientHolder graphQlHolder` → `_buildAuth(onSessionTeardown: () => graphQlHolder.reset())` → holder `connect` and `RestClient` both receive `auth.recovery` (null for the dev stub, the service itself for `SessionAuthTokenService`). `AuthCubit` is created `lazy: false` with `..start()` above `MaterialApp`; `SplashCubit` is global (above `MaterialApp`), `GraphQLProvider` stays above `MaterialApp`.
- The tree: `RepositoryProvider<AuthTokenService>` → `BlocProvider<AuthCubit>` → `BlocProvider<SplashCubit>` → `GraphQLProvider` → `AnnotatedRegion` → `MaterialApp(home: Builder → AuthGate(authenticatedBuilder: AuthenticatedShell))`.
- The 9 gameplay cubits now live in `AuthenticatedShell`; anything opened with `showDialog`/`showModalBottomSheet`/`Navigator.push` on the root navigator must get cubits via `BlocProvider.value`.
- Stale docs outside this plan's files: `DevAuthTokenService.initialize()` dartdoc still says "Da chiamare … da `main.dart` prima di `runApp`" and `AuthTokenService.authStateStream` dartdoc mentions `SplashCubit` as a listener. Worth a Boy Scout touch if 11-11 edits those files.
- No logout button was added to gameplay screens (Phase 4 owns it).
- The user's uncommitted `test/repository/services/auth/auth_token_service_contract_test.dart` was left untouched.

## Self-Check: PASSED

All 9 created files exist; commits c25916d, ccd20b9, 71f0df2, 7fd44ab present in `git log`.
