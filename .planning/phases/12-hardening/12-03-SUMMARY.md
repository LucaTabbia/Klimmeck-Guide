---
phase: 12-hardening
plan: 03
subsystem: build, release, config
tags: [hardening, release, flavors, signing, dart-define]
requires: ["12-02"]
provides:
  - "env/prod.json (.invalid TLS placeholders) and env/dev.json (localhost) dart-define files, URL-only"
  - "env/*.local.json gitignored (UAT tunnel file)"
  - "pubspec.yaml: default-flavor prod, .env asset only for the dev flavor, leak_tracker ^11.0.2 + leak_tracker_flutter_testing ^3.0.10 dev deps"
  - "android/app/build.gradle.kts: flavorDimensions env, productFlavors dev/prod, key.properties release signing with logger.quiet debug fallback"
affects: [12-04, 12-07, 12-08, 12-16, 12-17]
tech-stack:
  added: ["leak_tracker ^11.0.2 (dev, was transitive)", "leak_tracker_flutter_testing ^3.0.10 (dev, was transitive)"]
  patterns:
    - "Flutter asset flavors + Android product flavors in one commit; release = prodRelease"
    - "optional signing config created only when android/key.properties exists"
key-files:
  created:
    - env/dev.json
    - env/prod.json
  modified:
    - .gitignore
    - pubspec.yaml
    - pubspec.lock
    - android/app/build.gradle.kts
    - CLAUDE.md
decisions:
  - "The release APK is build/app/outputs/flutter-apk/app-prod-release.apk and never bundles .env (D-02)"
  - "Release signing reads android/key.properties; without it the build falls back to the debug keys with a visible logger.quiet WARNING (D-03a)"
  - "flutter run alone now runs the prod entry point; the dev run is flutter run --flavor dev -t lib/main_dev.dart (D-16)"
metrics:
  duration: "~10 min"
  completed: 2026-11-09
---

# Phase 12 Plan 03: Release build infrastructure Summary

Flavored `.env` asset with `default-flavor: prod`, Android `dev`/`prod` product flavors, `key.properties` release signing with a visible debug-key fallback, URL-only dart-define files and the leak tracker dev deps; a scratch release build proves the APK ships no `.env` and no dev bypass.

## Tasks

| Task | Commit | Files |
|------|--------|-------|
| 1. Dart-define files + gitignore | 649a466 | env/dev.json, env/prod.json, .gitignore |
| 2. Flavors, flavored .env, signing (one commit) | 6ffd639 | pubspec.yaml, pubspec.lock, android/app/build.gradle.kts |
| 2. Dev run command in CLAUDE.md (separate docs commit) | a7e34c4 | CLAUDE.md |

## Task 1 checks

- `python3 -c "import json; ..."` → `JSON_OK`; `grep -c "env/\*.local.json" .gitignore` → `1`
- `grep -c "DEV_AUTH_" env/dev.json env/prod.json` → `env/prod.json:0`, `env/dev.json:0`
- prod: `https://api.klimmeck.invalid/` = 2, `wss://api.klimmeck.invalid/api/graphql` = 1; dev: `http://localhost:3000/` = 2, `ws://localhost:3000/api/graphql` = 1
- `git check-ignore` on `env/tunnel.local.json` → `IGNORED`; on `env/prod.json` → `TRACKED`; `ls env` → `dev.json`, `prod.json`

## Task 2 scratch proof (logs in the session scratchpad, not the repo)

Release: `flutter build apk --release --dart-define-from-file=env/prod.json`
- `exit=0`, 97 s wall clock (`Running Gradle task 'assembleProdRelease'... 94,6s`), `✓ Built build/app/outputs/flutter-apk/app-prod-release.apk (118.7MB)`
- `APK_OK`
- `unzip -l <apk> | grep -c 'flutter_assets/\.env$'` → `0`
- `unzip -p <apk> | grep -a -c DEV_AUTH_` → `0`
- `unzip -p <apk> | grep -a -c DevAuthTokenService` → `0`
- `unzip -p <apk> | grep -a -c 'api.klimmeck.invalid'` → `9` (prod defines compiled in)
- `android/key.properties` absent (expected locally) → `grep -c "WARNING: android/key.properties not found"` in the build log → `1`

Dev flavor (`.env` present on disk, content never read): `flutter build apk --debug --flavor dev -t lib/main_dev.dart` → `exit=0`, 46 s (`assembleDevDebug 42,4s`); `unzip -l app-dev-debug.apk | grep -c 'flutter_assets/\.env$'` → `1`.

pubspec.lock: only `leak_tracker` and `leak_tracker_flutter_testing` changed from `transitive` to `"direct dev"` (versions 11.0.2 / 3.0.10 unchanged).

Acceptance greps: `default-flavor: prod` 1, `path: .env` 1, bare `- .env` 0, both leak tracker lines 1; `create("dev")` 1, `create("prod")` 1, `flavorDimensions += "env"` 1, `applicationIdSuffix` 0, `rootProject.file("key.properties")` 1, `logger.quiet(` 1, `logger.warn(` 0. CLAUDE.md: new dev run line 1, `dart-define-from-file=env/prod.json` 1, old `flutter run  # dev run` line 0.

Tests: `flutter test test/config test/bootstrap test/utils` → 114 tests, All tests passed. Analyzer: 50 issues, all info, 0 error, 0 warning.

## Note (D-16)

`flutter run` alone now resolves the `prod` flavor and runs `lib/main.dart` (production entry point, real session only). The dev run with the bypass and `.env` is `flutter run --flavor dev -t lib/main_dev.dart` (documented in CLAUDE.md §Comandi essenziali). The user-generated `android/key.properties` must use an ABSOLUTE `storeFile` path (a relative one resolves from `android/app/`): for the plan 17 handoff.

## Deviations from Plan

None - plan executed exactly as written. The plan's `<verify>` command (a second identical release build) was not re-run: the scratch proof above ran the same build and the same three greps on the same tree.

## Known Stubs

None (no Dart code).

## Self-Check: PASSED

- FOUND: env/dev.json, env/prod.json, .planning/phases/12-hardening/12-03-SUMMARY.md
- FOUND commits: 649a466, 6ffd639, a7e34c4
