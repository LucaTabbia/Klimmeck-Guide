---
phase: 12-hardening
plan: 04
subsystem: config, bootstrap
tags: [hardening, tls, release, fail-fast]
requires: ["12-03"]
provides:
  - "EnvConfig.requireSecureTransport({bool isRelease = kReleaseMode}): throws InsecureTransportError in release on non-https/wss backend URLs, logs key names via appLog otherwise"
  - "InsecureTransportError(List<String> offendingKeys): key names only, never URLs"
  - "InsecureTransportScreen utility screen with the D-19 copy (insecureTransportMessage)"
  - "secureTransportBlocker(isRelease:) as the first step of bootstrapApp({buildAuth, isRelease = kReleaseMode})"
affects: [12-07, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "Dart-side TLS refusal (dart:io ignores the Android cleartext policy)"
    - "@visibleForTesting blocker function returning a Widget? before any client is built"
key-files:
  created:
    - lib/config/insecure_transport_error.dart
    - lib/bootstrap/insecure_transport_screen.dart
    - test/config/env_config_secure_transport_test.dart
    - test/bootstrap/insecure_transport_screen_test.dart
  modified:
    - lib/config/env_config.dart
    - lib/bootstrap/app_bootstrap.dart
    - test/bootstrap/entry_points_test.dart
decisions:
  - "A release build with any cleartext backend URL (including the built-in 192.168.0.20 defaults) shows only InsecureTransportScreen; no push, auth or client is built (D-03b)"
  - "Scheme check is Uri.tryParse(url)?.scheme.toLowerCase(): https for BASE_URL/GRAPHQL_HTTP_URL, wss for GRAPHQL_WS_URL (a swapped scheme is refused too)"
metrics:
  duration: "~10 min"
  completed: 2026-11-09
---

# Phase 12 Plan 04: TLS only in release Summary

`EnvConfig.requireSecureTransport` refuses `http://`/`ws://` backend URLs in release by throwing `InsecureTransportError` with the offending key names only, logs them through `appLog` outside release, and `bootstrapApp` runs the check first, replacing the app with the button-less `InsecureTransportScreen` (D-03b, D-19; closes AR-03).

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | EnvConfig.requireSecureTransport and InsecureTransportError | e9eff25 (test), 38755ca (feat) |
| 2 | InsecureTransportScreen and the gate first in bootstrapApp | d84db2e (test), 149f0a6 (feat) |

## RED failures observed

- Task 1: `flutter test test/config/env_config_secure_transport_test.dart` failed to compile: `Error when reading 'lib/config/insecure_transport_error.dart'`, `Method not found: 'InsecureTransportError'`, missing `EnvConfig.requireSecureTransport`.
- Task 2: `flutter test test/bootstrap/insecure_transport_screen_test.dart` failed to compile: `Error when reading 'lib/bootstrap/insecure_transport_screen.dart'`, `Couldn't find constructor 'InsecureTransportScreen'`, `Undefined name 'insecureTransportMessage'`, `Method not found: 'secureTransportBlocker'`.
- No case green at the first run.

## Names and signatures created

- `lib/config/insecure_transport_error.dart`: `class InsecureTransportError extends Error { InsecureTransportError(List<String> offendingKeys); final List<String> offendingKeys; toString() => 'InsecureTransportError(<keys joined by ", ">)' }`
- `lib/config/env_config.dart` (section `// ============== Transport (D-03b) ==============` between the URL overrides and Timeouts): `static void requireSecureTransport({bool isRelease = kReleaseMode})`, private `_cleartextKeys()` (order BASE_URL, GRAPHQL_HTTP_URL, GRAPHQL_WS_URL), `_hasScheme(String url, String scheme)`. New imports: `insecure_transport_error.dart`, `utils/app_log.dart`. Debug log line: `[EnvConfig] cleartext backend URLs outside release: <keys>`.
- `lib/bootstrap/insecure_transport_screen.dart`: `const String insecureTransportMessage`, `class InsecureTransportScreen extends StatelessWidget` (const ctor, own `MaterialApp`, `getBackgroundDecoration()` gradient, `titleMedium`, `spacingLg` padding).
- `lib/bootstrap/app_bootstrap.dart`: `@visibleForTesting Widget? secureTransportBlocker({required bool isRelease})`; `Future<void> bootstrapApp({required AuthCompositionFactory buildAuth, bool isRelease = kReleaseMode})`.

## Line-order proof

```
35:  final blocker = secureTransportBlocker(isRelease: isRelease);
39:  final push = await bootstrapPush();
```

## Verification

- `flutter test test/bootstrap test/config`: 34 tests, All tests passed (7 new in test/config, 5 new in test/bootstrap).
- `flutter analyze`: `50 issues found.` (all info), error/warning count 0.
- Acceptance greps: all as required (requireSecureTransport signature 1 line, throw 1, class 1, `D-03)` ×7 in the config test, `D-03` ×4 and `D-19)` ×2 in the screen test, no button/AppBar literal, `requireSecureTransport(isRelease: isRelease)` 1).
- `dart format` run on each touched file one by one: no reflow (none of the touched files is in the known-dirty list).
- Theme: `KlimmeckGuideTheme.getBackgroundDecoration()` is a pure gradient (no network image), used as planned.
- Full `flutter test` not run (not required by the plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing critical] InsecureTransportScreen added to the dev-marker gate**
- **Found during:** Task 2
- **Issue:** the new production-graph file under `lib/bootstrap/` was not covered by `_sharedCompositionFiles` of `test/bootstrap/entry_points_test.dart` (plan 02 note: every new prod-graph bootstrap file joins it).
- **Fix:** added `lib/bootstrap/insecure_transport_screen.dart` to the list.
- **Files modified:** test/bootstrap/entry_points_test.dart
- **Commit:** 149f0a6

## Known Stubs

None.

## Threat mitigations

- T-12-12: release refusal tested on both branches (Task 1) and the blocker precedes every client (Task 2, line-order proof).
- T-12-13: error and log carry key names only (tests «the error never carries a URL (D-03)», «debug only logs the cleartext URLs (D-03)»).
- T-12-14: lower-cased scheme via `Uri.tryParse`; https/wss acceptance tested.

## Self-Check: PASSED

- Files exist: lib/config/insecure_transport_error.dart, lib/bootstrap/insecure_transport_screen.dart, test/config/env_config_secure_transport_test.dart, test/bootstrap/insecure_transport_screen_test.dart.
- Commits exist: e9eff25, 38755ca, d84db2e, 149f0a6.
