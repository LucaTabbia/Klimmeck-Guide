---
phase: 11-auth-session-bootstrap
plan: 09
subsystem: auth
tags: [auth-cubit, sign-in, logout-dialog, bloc, ui]
requires: [11-08]
provides:
  - AuthCubit (global session state mirrored from AuthTokenService.authStateStream)
  - SignInCubit / SignInState (Idle, InProgress, Failed(connection | twitchNotConfigured))
  - SignInScreen (utility screen, session-expired notice, Twitch CTA)
  - LogoutConfirmationDialog + showLogoutConfirmationDialog + confirmLogout
affects: [11-10, 11-11]
tech-stack:
  added: []
  patterns: [cubit mirrors service stream, sealed state with Equatable, switch expression for inline failure copy]
key-files:
  created:
    - lib/screens/auth/cubit/auth_cubit.dart
    - lib/shared/components/modal/logout_confirmation_dialog.dart
    - assets/icons/twitch_glitch.svg
    - test/screens/auth/cubit/auth_cubit_test.dart
    - test/screens/signIn/cubit/sign_in_cubit_test.dart
    - test/screens/signIn/sign_in_screen_test.dart
    - test/shared/components/modal/logout_confirmation_dialog_test.dart
  modified:
    - lib/screens/signIn/cubit/sign_in_cubit.dart
    - lib/screens/signIn/cubit/sign_in_state.dart
    - lib/screens/signIn/sign_in_screen.dart
    - lib/main.dart
key-decisions:
  - "Twitch glyph: branch A (verified Simple Icons download)"
  - "Logo uses a fixed 96 px height instead of 60% width (landscape viewport)"
requirements-completed: []
completed: 2026-10-06
---

# Phase 11 Plan 09: Auth presentation layer Summary

Global `AuthCubit` (subscribe-then-initialize, `showSignIn()`, `logout()`), real `SignInScreen` with `SignInCubit` (silent cancel, inline connection/not-configured errors, retryable button, optional session-expired notice) and a non-dismissible `LogoutConfirmationDialog` with `confirmLogout()`.

## Commits

| Step | Commit | Subject |
|------|--------|---------|
| T1 RED | 98e22ae | test(phase-11): add auth cubit state sequence specs |
| T1 GREEN | c703e27 | feat(phase-11): add global auth cubit |
| T2 RED | 5bcd61d | test(phase-11): add sign-in cubit and screen specs |
| T2 GREEN | 9bd845b | feat(phase-11): build sign-in screen with twitch login flow states |
| T3 RED | 6019690 | test(phase-11): add logout confirmation dialog specs |
| T3 GREEN | 285e15a | feat(phase-11): add logout confirmation dialog |

## Results

- `flutter test`: 220 tests, all passed (baseline 189)
- `flutter analyze lib test`: 14 issues (equal to baseline; zero in plan files)
- `dart format --output=none --set-exit-if-changed` on all 9 plan .dart files by explicit path: exit 0 (`lib/main.dart` only had lines removed; not format-checked as a whole file)

## Twitch glyph: branch A

- Source: `https://cdn.jsdelivr.net/npm/simple-icons@16.34.0/icons/twitch.svg` (version resolved via `data.jsdelivr.com` latest, Simple Icons, CC0)
- Version: simple-icons 16.34.0
- sha256 of `assets/icons/twitch_glitch.svg`: `1de489f30cc14b149f2fd28b7638c4ffce2e3571e2ea51a4d34dd3852aad71a4`
- Checks: single `<path>`, `viewBox="0 0 24 24"`, zero matches for `<script|<image|href=|foreignObject|fill`; only `role="img"` and `<title>` removed; `d` attribute verified byte-identical to the download.

## Deviations from Plan

1. **Logo height** (planned, documented): fixed `height: 96` instead of UI-SPEC 60% screen width, because landscape would overflow the viewport.
2. **[Rule 2] Button semantics**: `Semantics(excludeSemantics: true)` added on the CTA so the label is exposed as one node.
3. Tagline copy ("Accedi con Twitch per iniziare la tua avventura.") and footer `onPressed: () {}` are discretionary placeholders (URLs undefined in UI-SPEC).

## Known Stubs

- `lib/screens/signIn/sign_in_screen.dart`: footer "Termini di servizio" / "Privacy" buttons have empty `onPressed` (URLs not yet defined; UI-SPEC placeholder `#`).

## Notes for 11-10

- `lib/main.dart`: only the old `BlocProvider<SignInCubit>(... graphQl)` and its import were removed. `AuthCubit` and `SignInCubit(authTokenService)` must be provided by the gate; `SignInScreen` is not mounted by any route yet.
- Gate: call `AuthCubit.start()` once; build `SignInScreen(showSessionExpiredNotice: state.reason == UnauthenticatedReason.sessionExpired)` for `AuthUnauthenticated`; provide `BlocProvider(create: (_) => SignInCubit(service))` around it. Back-to-back `sessionExpired` then `signedOut` simply ends on the last state (notice disappears), as the cubit mirrors the stream without latching.
- Splash "Accedi manualmente" should call `AuthCubit.showSignIn()`.
- `confirmLogout(context)` reads `AuthCubit` from context: Settings (Phase 4) must be under its provider. No logout button was added anywhere.
- `android/app/build.gradle.kts` was not modified; the user's uncommitted `auth_token_service_contract_test.dart` was left untouched.

## Self-Check: PASSED

All created files exist; all six commits present in `git log`.
