---
phase: 12-hardening
plan: 01
subsystem: config, shared utils
tags: [hardening, env-config, logging, release]
requires: []
provides:
  - "EnvConfig.installRuntimeOverrides(Map<String, String>) / @visibleForTesting EnvConfig.resetRuntimeOverrides()"
  - "EnvConfig.isDebug / enableLogging defaulting to !kReleaseMode"
  - "lib/utils/app_log.dart: appLog(String), appLogWith(message, isRelease:, sink:), typedef AppLogSink"
affects: [12-02, 12-05, 12-06, 12-16]
tech-stack:
  added: []
  patterns:
    - "runtime-override seam installed by the entry point instead of a package import in config"
    - "pure logging seam with injected build mode and sink"
key-files:
  created:
    - lib/utils/app_log.dart
    - test/utils/app_log_test.dart
  modified:
    - lib/config/env_config.dart
    - lib/main.dart
    - test/config/env_config_backend_urls_test.dart
    - test/config/env_config_test.dart
    - test/config/env_config_uninitialized_test.dart
    - test/helpers/fixtures/dev_auth_env.dart
    - test/repository/services/rest/rest_upload_test.dart
decisions:
  - "EnvConfig reads only installed overrides, then --dart-define, then the built-in default; no flutter_dotenv import (D-01, D-02)"
  - "isDebug / enableLogging default to !kReleaseMode (D-03c)"
  - "appLog is the single log entry point, silent under kReleaseMode (D-03c); no call site routed yet"
metrics:
  duration: "~10 min"
  completed: 2026-11-09
  tasks: 2
  files: 9
---

# Phase 12 Plan 01: EnvConfig runtime-override seam and appLog Summary

`EnvConfig` no longer imports `flutter_dotenv`: backend URLs and `devAuthEnabled` read an immutable runtime-override map installed by the entry point (today `lib/main.dart` right after `dotenv.load`), with `--dart-define` and the built-in default behind it; `isDebug`/`enableLogging` follow the build mode; `appLog`/`appLogWith` is the pure logging seam silent in release.

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | EnvConfig runtime-override seam, flags following the build mode, pinned config tests rewritten | 7932906 (test), 7324684 (refactor) |
| 2 | appLog seam silent in release | f0f46fc (test), 5889da0 (feat) |

## Names and signatures created

- `lib/config/env_config.dart`:
  - `static Map<String, String> _runtimeOverrides = const {};`
  - `static void installRuntimeOverrides(Map<String, String> values) => _runtimeOverrides = Map.unmodifiable(values);`
  - `@visibleForTesting static void resetRuntimeOverrides() => _runtimeOverrides = const {};`
  - `static String? _runtimeValue(String key)` (trimmed, empty = null; no try/catch any more)
  - `static const bool isDebug = bool.fromEnvironment('DEBUG', defaultValue: !kReleaseMode);`
  - `static const bool enableLogging = bool.fromEnvironment('ENABLE_LOGGING', defaultValue: !kReleaseMode);`
  - only import: `package:flutter/foundation.dart`; all public getters/constants unchanged
- `lib/main.dart`: `EnvConfig.installRuntimeOverrides(dotenv.env);` right after `await dotenv.load(fileName: '.env');` (transitional, plan 02 moves both lines to `lib/main_dev.dart`)
- `lib/utils/app_log.dart`: `typedef AppLogSink = void Function(String message);`, `void appLog(String message)`, `@visibleForTesting void appLogWith(String message, {required bool isRelease, required AppLogSink sink})`
- `test/helpers/fixtures/dev_auth_env.dart`: `loadTestEnv(...)` keeps `dotenv.loadFromString` (for `DevAuthTokenService`) and adds `EnvConfig.installRuntimeOverrides(dotenv.env); addTearDown(EnvConfig.resetRuntimeOverrides);` — must be called inside a test or `setUp` (uses `addTearDown`)

## RED failures observed

- Task 1: `flutter test test/config test/repository/services/rest/rest_upload_test.dart` failed to compile: `Error: Member not found: 'EnvConfig.installRuntimeOverrides'` / `Member not found: 'resetRuntimeOverrides'` in `env_config_backend_urls_test.dart`, `dev_auth_env.dart` (hence `env_config_test.dart`) and `rest_upload_test.dart`.
- Task 2: `flutter test test/utils/app_log_test.dart` failed to compile: `Error when reading 'lib/utils/app_log.dart': No such file or directory`, `Method not found: 'appLogWith'` / `'appLog'`.
- The case «isDebug and enableLogging follow the build mode (D-03)» could not run at RED only because its file failed to compile through the fixture; on its own it would have been green at the first run: under `flutter test` `kReleaseMode` is false and the old const default `true` equals `!kReleaseMode`. The change only matters in a release build.
- `env_config_uninitialized_test.dart` is a rename only (title + comment «without runtime overrides»): its assertions were and stay green.

## Verification

- `flutter test test/config test/repository/services/rest/rest_upload_test.dart test/repository/services/auth test/screens/auth` → 335 tests, All tests passed
- `flutter test test/utils/app_log_test.dart` → 3 tests, All tests passed
- Plan verification `flutter test test/config test/utils test/repository/services/rest test/repository/services/auth test/screens/auth` → 427 tests, All tests passed
- `flutter analyze` → `50 issues found.` (all info, 0 error, 0 warning — unchanged baseline), ANALYZE_GATE_OK after each code task
- Acceptance greps: `flutter_dotenv` in `env_config.dart` = 0; `defaultValue: !kReleaseMode` = 2; `installRuntimeOverrides(dotenv.env)` in `main.dart` = 1; `D-02)` in the URL test = 6; `D-03)` in `app_log_test.dart` = 3
- Formatted one by one: all 9 touched files; only `test/config/env_config_uninitialized_test.dart` changed (the renamed title exceeded 80 columns), the rest were already clean.

## Deviations from Plan

None in behaviour. Notes:
- The old URL case «treat an empty .env value as absent» (`GRAPHQL_WS_URL=`) was replaced by the plan's «ignore empty override values (D-02)» (`BASE_URL` = `'   '`), keeping six titled cases.
- Bookkeeping uses the orchestrator's `1/17` / `Plan: 1 of 17` instead of the plan's `01/17` (brief: orchestrator number wins).
- `requirements mark-complete` not run (forbidden by the brief: traceability belongs to 12-17).

## Known Stubs

None.

## Threat surface

T-12-01 (no dotenv import in `env_config.dart`), T-12-02 (`appLog` silent in release, test «stays silent in release (D-03)»), T-12-03 (flags `!kReleaseMode`) mitigated as planned. No new surface.

## Self-Check: PASSED
