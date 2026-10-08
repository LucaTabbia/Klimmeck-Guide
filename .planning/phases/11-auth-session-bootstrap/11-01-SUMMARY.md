---
phase: 11-auth-session-bootstrap
plan: 01
subsystem: auth
tags: [flutter_web_auth_2, flutter_secure_storage, agp, android-manifest, test-infra]
requires: []
provides:
  - auth dependencies resolved (flutter_web_auth_2 5.1.0, flutter_secure_storage 10.3.4, crypto, fake_async)
  - Android callback setup for scheme klimmeck (CallbackActivity), INTERNET, allowBackup=false
  - shared test helpers (MockAuthTokenService, buildTestApp)
affects: [11-02, 11-03, 11-04, 11-05, 11-06, 11-07]
tech-stack:
  added: [flutter_web_auth_2, flutter_secure_storage, crypto, fake_async]
  patterns: [shared mocks in test/helpers/mocks.dart, themed test app without runtime font fetching]
key-files:
  created: [test/helpers/mocks.dart, test/helpers/test_app.dart]
  modified: [pubspec.yaml, pubspec.lock, android/settings.gradle.kts, android/app/src/main/AndroidManifest.xml, .env.example, test/app/app_wiring_test.dart]
key-decisions:
  - "AGP bumped to 8.9.1; Kotlin and Gradle wrapper untouched"
  - "iOS untouched (ASWebAuthenticationSession needs no CFBundleURLTypes)"
requirements-completed: []
duration: ~15min
completed: 2026-10-06
---

# Phase 11 Plan 01: Native and test prerequisites Summary

Wave 0: auth dependencies, AGP 8.9.1, Android manifest callback/INTERNET/allowBackup, `.env.example` realigned, and shared test infrastructure.

## Tasks

| Task | Commit | Result |
|------|--------|--------|
| 1 Dependencies, AGP, manifest, .env.example | e7bfed5 | pub get OK, `flutter build apk --debug` OK (app-debug.apk built) |
| 2 Shared mocks and test app builder | 7ca4ba8 | `flutter test test/app` green (2 tests) |

## Results

- `flutter analyze lib test`: 14 issues (baseline 14, no new). The three new/changed Dart files: No issues found.
- `flutter test`: 21 tests, all passed (20 baseline + 1 smoke test).
- Android debug build: success (AGP 8.9.1).
- `dart format --set-exit-if-changed` on the 3 Dart files: exit 0 (explicit paths only).

## Deviations from Plan

**1. [Rule 3 - Blocking/side effect] Flutter tool auto-edited android/app/build.gradle.kts**
- During `flutter build apk --debug` the tool printed "Upgrading build.gradle.kts" and replaced `minSdk = 23` with `minSdk = flutter.minSdkVersion`.
- Out of plan scope; restored `minSdk = 23` by hand. File is back to its committed state (not in git status). Note: a future `flutter build` may re-apply this rewrite; harmless but will show as a modification.

No other deviations.

## Notes for next plans

- Add new mocks to `test/helpers/mocks.dart`; `test/network/auth_interceptor_test.dart` and `graphql_auth_link_test.dart` still hold local `MockAuthTokenService` copies (migration planned in 11-07).
- Use `buildTestApp(home: ...)` for widget tests that use the theme.

## Known Stubs

None.

## Self-Check: PASSED

- test/helpers/mocks.dart, test/helpers/test_app.dart: FOUND
- Commits e7bfed5, 7ca4ba8: FOUND
