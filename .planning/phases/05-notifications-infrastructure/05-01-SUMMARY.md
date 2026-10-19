---
phase: 05-notifications-infrastructure
plan: 01
subsystem: android-native-and-deps
tags: [android, gradle, google-services, fcm, pubspec, uuid, notifications]
requires: []
provides:
  - "Google Services Gradle plugin 4.5.0 with missingGoogleServicesStrategy = WARN (builds with or without google-services.json)"
  - "Explicit POST_NOTIFICATIONS permission"
  - "Notification small icon @drawable/ic_stat_klimmeck kept by res/raw/keep.xml"
  - "Dependency set of the phase: -firebase_auth, +uuid ^4.5.1 (direct)"
  - "Developer note on the local Firebase config (.env.example, README)"
affects: [05-02, 05-03, 05-04, 05-05, 05-06, 05-07, 05-08, 05-09]
tech-stack:
  added: ["com.google.gms.google-services 4.5.0 (Gradle plugin)", "uuid ^4.5.1 (promoted from transitive)"]
  removed: ["firebase_auth 5.6.2 (+ firebase_auth_platform_interface, firebase_auth_web)"]
  patterns: ["Firebase config file local-only; build degrades to a warning when it is absent"]
key-files:
  created:
    - android/app/src/main/res/drawable/ic_stat_klimmeck.xml
    - android/app/src/main/res/raw/keep.xml
  modified:
    - android/settings.gradle.kts
    - android/app/build.gradle.kts
    - android/app/src/main/AndroidManifest.xml
    - pubspec.yaml
    - pubspec.lock
    - .env.example
    - README.md
  deleted:
    - lib/utils/notification.dart
decisions:
  - "The plugin's missing-file warning is not visible through `flutter build apk` at default verbosity; it is proved by running `./gradlew :app:processDebugGoogleServices` without the JSON"
metrics:
  duration: "~15 min"
  completed: 2026-10-19
  tasks: 2
  files: 10
---

# Phase 5 Plan 01: Android native wiring and dependency groundwork Summary

Google Services Gradle plugin 4.5.0 wired with the `WARN` missing-file strategy (every checkout builds without the local `google-services.json`), explicit `POST_NOTIFICATIONS`, a white-on-transparent `ic_stat_klimmeck` small icon protected from resource shrinking, `firebase_auth` dropped and `uuid` promoted to a direct dependency, legacy `NotificationsBloc` deleted (analyzer 57 -> 56).

## Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Google Services plugin (WARN), POST_NOTIFICATIONS, small icon + keep rule, scratch builds A/C | 2b3cf8c | android/settings.gradle.kts, android/app/build.gradle.kts, AndroidManifest.xml, res/drawable/ic_stat_klimmeck.xml, res/raw/keep.xml |
| 2a | Dependency diff (-firebase_auth, +uuid) | ee4fbe7 | pubspec.yaml, pubspec.lock |
| 2b | Delete legacy NotificationsBloc | 94243e7 | lib/utils/notification.dart (deleted) |
| 2c | Local Firebase config notes | 023d3e9 | .env.example, README.md |

No TDD cycle: the plan has no Dart production logic (config, native, deletion); verification is the scratch builds, the analyzer and the full suite, as the plan prescribes.

## Verification evidence

**Scratch build A (JSON present):**
```
Running Gradle task 'assembleDebug'...                             16,7s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
$ unzip -p build/app/outputs/flutter-apk/app-debug.apk resources.arsc | grep -a -c google_app_id
1
```

**Scratch build C (JSON moved to the session scratchpad, `flutter clean` + `flutter pub get` + `flutter build apk --debug`):**
```
exit=0
RESTORED
-rw-r--r--@ 1 lucatabbia  staff  708 Oct 19 18:37 android/app/google-services.json
Running Gradle task 'assembleDebug'...                             25,8s
✓ Built build/app/outputs/flutter-apk/app-debug.apk
$ unzip -p ... resources.arsc | grep -a -c google_app_id
0
```
`grep -c "google-services.json is missing" build-c.log` returned `0`: Flutter does not forward Gradle warnings at default verbosity. The warning was then proved with the JSON again moved out and the Gradle task run directly (`JAVA_HOME` = Android Studio JBR):
```
$ ./gradlew :app:processDebugGoogleServices --rerun-tasks
exit=0
File google-services.json is missing.
Searched locations: .../android/app/src/debug/google-services.json, ..., .../android/app/google-services.json
BUILD SUCCESSFUL in 8s
```
JSON restored both times (708 bytes), never printed, never staged (`git check-ignore` OK, absent from every `git log --stat`).

**Static checks:** settings/build.gradle.kts greps all = 1; `id("com.google.gms.google-services")` on line 6, Flutter plugin on line 8; `#FFFFFFFF` = 1; `firebase_auth` count in pubspec.yaml / pubspec.lock = 0 / 0; `uuid` in lock: `dependency: "direct main"`, `version: "4.5.1"`; lock diff = only the three firebase_auth packages removed + uuid transitive -> direct main. `git diff --name-only HEAD~4 -- ios` empty.

**flutter analyze:** `56 issues found.` (0 errors; baseline 57, the `depend_on_referenced_packages` info on `lib/utils/notification.dart:1` is gone).

**flutter test:** `00:27 +762: All tests passed!`

VALIDATION rows 5-01-01 and 5-01-02 set to ✅ green.

## Deviations from Plan

1. **[Rule 3 - Blocking verification gap] Missing-file warning not visible through Flutter.** Build C succeeded (`exit=0`, `google_app_id` = 0) but the `google-services.json is missing` line is filtered out by `flutter build` at default verbosity, so the plan's grep returned 0. Proved the WARN path by running `./gradlew :app:processDebugGoogleServices --rerun-tasks` with the JSON moved out (warning present, `BUILD SUCCESSFUL`), then restored the JSON. No code change.
2. **Commit subject shortened.** The plan's Task 1 subject (`… and the push notification icon`) exceeds 72 characters; committed as `chore(android): wire the google-services plugin and the push icon`.

## Known Stubs

- `ic_stat_klimmeck.xml` is a placeholder shield glyph (intentional, per plan): replaceable by the final design asset keeping the same name.

## Threat Flags

None: no new surface beyond the plan's threat model (T-05-01-01..04 mitigated as planned).

## Self-Check: PASSED
