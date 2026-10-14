---
phase: 02-character-creation
plan: 01
subsystem: tooling
tags: [image_picker, flutter-3.35.5, android, ios, test-helpers, dio]
requires: []
provides:
  - CHAR-06 recorded as Deferred (D-17) in REQUIREMENTS and ROADMAP
  - image_picker 1.2.2 locked, toolchain pinned to Flutter 3.35.5
  - Android minSdk 24 (flutter.minSdkVersion), iOS 13.0 with camera/photo usage strings
  - Shared test helpers (ScriptedHttpClientAdapter, useLandscapePhone, buildTestUserWithCharacter)
affects: [02-02, 02-03, 02-04, 02-05, 02-06, 02-07, 02-08, 02-09, 02-10, 02-11]
tech-stack:
  added: [image_picker 1.2.2]
  patterns: [scripted dio adapter with JSON bodies and failures]
key-files:
  created:
    - test/helpers/landscape.dart
    - test/helpers/fakes/scripted_http_client_adapter.dart
    - test/helpers/fakes/scripted_http_client_adapter_test.dart
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .fvmrc
    - android/app/build.gradle.kts
    - ios/Runner.xcodeproj/project.pbxproj
    - ios/Flutter/AppFrameworkInfo.plist
    - ios/Podfile
    - ios/Runner/Info.plist
    - pubspec.yaml
    - pubspec.lock
    - test/helpers/auth_fixtures.dart
    - .planning/phases/02-character-creation/02-VALIDATION.md
key-decisions:
  - "CHAR-06 deferred (D-17); CHAR-05 ships upload only (D-15); CHAR-08 satisfied by single page (D-04)"
requirements-completed: []  # CHAR-06 deferred (D-17); CHAR-05 completes with the picker plans
duration: 15min
completed: 2026-10-09
---

# Phase 2 Plan 01: Wave 0 prerequisites Summary

Documented the CHAR-06 deferral, landed the image_picker 1.2.2 dependency with Android/iOS native targets, and added the shared test helpers later plans depend on.

## Commits
- 122f7bc docs(phase-2): record the CHAR-06 deferral and the single-page scope
- 920e429 chore(character-creation): add image_picker and raise the native targets
- ab5e2be test(character-creation): add failing tests for the scripted dio adapter (RED)
- 0a7e74d test(character-creation): add shared helpers for landscape tests and scripted uploads (GREEN)

## Verification
- `flutter test`: 287 passed (283 baseline + 4 new)
- `flutter analyze lib test`: 12 issues (unchanged baseline)
- `plutil -lint` OK on both plists; `flutter build apk --debug` succeeded
- iOS build / pod install not attempted

## Deviations from Plan

None in scope. Execution notes:
- While removing the duplicate `.env` asset I first deleted the wrong line (`assets/images/placeholders/`) because line numbers shifted after `pub add`; restored before commit, final diff only removes the second `.env`.
- `dart format` on `auth_fixtures.dart` and the helper test also reflowed a few pre-existing lines in those touched files (formatting only).
- A Co-Authored-By trailer was briefly added to commit 920e429 by mistake and removed by amend before any further work; no trailer exists on any commit.

## Known Stubs
None.

## Self-Check: PASSED
