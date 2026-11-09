---
phase: 12-hardening
group: B
reviewed: 2026-11-09T18:34:15Z
depth: standard
files_reviewed: 43
files_reviewed_list:
  - .github/workflows/ci.yml
  - .gitignore
  - CLAUDE.md
  - android/app/build.gradle.kts
  - env/dev.json
  - env/prod.json
  - lib/bootstrap/app_bootstrap.dart
  - lib/bootstrap/auth_composition.dart
  - lib/bootstrap/dev_auth_composition.dart
  - lib/bootstrap/insecure_transport_screen.dart
  - lib/bootstrap/klimmeck_guide_app.dart
  - lib/bootstrap/session_auth_composition.dart
  - lib/config/env_config.dart
  - lib/config/insecure_transport_error.dart
  - lib/main.dart
  - lib/main_dev.dart
  - lib/repository/cache/image_warmer.dart
  - lib/repository/services/push/data_message_handler.dart
  - lib/repository/services/push/local_notifications_startup.dart
  - lib/repository/services/push/notification_tap_router.dart
  - lib/repository/services/push/push_bootstrap.dart
  - lib/repository/services/push/push_registration_coordinator.dart
  - lib/repository/services/push/url_launcher_link_opener.dart
  - lib/repository/services/rest/rest.dart
  - lib/repository/services/rest/rest_client_provider.dart
  - lib/repository/services/sync/sync_watchdog.dart
  - lib/screens/mainScreen/characterCubit/character_cubit.dart
  - lib/screens/mainScreen/cubit/main_screen_cubit.dart
  - lib/screens/mainScreen/questCubit/quest_cubit.dart
  - lib/screens/mainScreen/tabs/journal/cubit/journal_cubit.dart
  - lib/screens/mainScreen/tabs/journal/journal.dart
  - lib/screens/mainScreen/tabs/library/cubit/library_cubit.dart
  - lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart
  - lib/screens/mainScreen/tabs/settings/permissionCubit/notification_permission_cubit.dart
  - lib/screens/splash/cubit/splash_cubit.dart
  - lib/shared/components/cached_svg.dart
  - lib/utils/app_log.dart
  - pubspec.yaml
  - test/helpers/fakes/fake_graphql_ws_server_test.dart
  - test/helpers/fixtures/dev_auth_env.dart
  - tool/hardening_check.sh
findings:
  critical: 0
  warning: 4
  info: 8
  total: 12
status: issues_found
---

# Phase 12 (Hardening) - Code Review Report, group B

**Reviewed:** 2026-11-09T18:34:15Z
**Depth:** standard
**Files reviewed:** 43 (plus the matching tests under `test/bootstrap`, `test/config`, `test/utils`, `test/repository/services/push`)

## Summary

Bootstrap, release build, logging and CI infrastructure are in good shape. Verified clean:

- `lib/main.dart` is production-pure. `main_dev.dart` asserts the flavor before `dotenv.load`.
- The dev factory falls back to the session factory.
- `secureTransportBlocker` runs before push and before any client.
- The barrel no longer exports the dev service.
- `EnvConfig` precedence (override, then dart-define, then default) and blank-override handling are correct.
- Scheme comparison is case-insensitive.
- The debug branch logs key names only.
- `InsecureTransportError` carries key names only.
- No credential, `$e` or `error.toString()` is interpolated in any of the 59 `appLog` call sites. Every site uses `${e.runtimeType}`.
- The `pubspec` default-flavor plus flavored `.env` asset, the Gradle signing and flavor configuration, `.gitignore` for `env/*.local.json` and `key.properties`, and `ci.yml` (pinned Flutter, `--no-fatal-infos`, timeout, no secrets, guard before and after the build) all match the CONTEXT decisions.
- The `FakeGraphQlWsServer` tests wait on real signals with 2 s timeouts, with no `Future.delayed`.

There are no criticals. The findings are:

- one race in the push registration lifecycle that the tests do not cover (B-WR-01);
- one untested critical-class wiring point, the blocker call site (B-WR-02);
- two guard-script weaknesses that fail open or are trivially bypassed (B-WR-03, B-WR-04);
- eight info items.

## Warning

### B-WR-01: an overlapped registration attempt can outlive `unregister()` and re-create the device row after logout

**File:** `lib/repository/services/push/push_registration_coordinator.dart:112-125, 135-140, 157-166`
**Issue:** `_attemptInFlight` holds only the latest attempt (`_trackAttempt` overwrites it). `_register` is called again by every `tokenRefreshes` event, every foreground retry and every login. The generation counter only cancels an older attempt BEFORE `_repository.register`. Older attempt A can already be past that check and awaiting the network when a token refresh starts B. `_attemptInFlight` then points to B, and `unregister()` drains only B (which returns at once, cancelled). A's `register` is still in flight and `unregister` sends the removal. If A lands on the BE after the removal, it upserts the same `deviceId` row again.
**Why it matters:** after logout the device keeps receiving pushes for the logged-out user (Pitfall 5, WR-01 of Phase 5, which the single-slot design only half closes). This is the same single-flight gap as in the previous phases' reviews. The window is narrow (token refresh while a register is in flight, then logout), but it is user-visible and privacy relevant, and no test covers overlapping attempts. The existing test at line 344 covers only a single in-flight attempt.
**Suggested fix:** track every in-flight attempt, not the last one: `final Set<Future<void>> _attemptsInFlight = {};`, add in `_trackAttempt`, remove in `whenComplete`, and in `_drainAttemptInFlight` do `await _guarded('registration drain', () => Future.wait(_attemptsInFlight.toList()).timeout(registrationDrainTimeout))`. RED test first in `push_registration_coordinator_test.dart`: log in with a `register` that blocks on a Completer, emit a token refresh so a second attempt starts, call `unregister()`, release the first completer, and assert that no `register` completes after `unregister` was sent (the fake backend ends with no row), or that `unregister` waited for both.

### B-WR-02: nothing proves `bootstrapApp` actually runs the secure-transport blocker first

**File:** `lib/bootstrap/app_bootstrap.dart:34-39` (tests: `test/bootstrap/insecure_transport_screen_test.dart`, `entry_points_test.dart`)
**Issue:** the tests cover `secureTransportBlocker` and `EnvConfig.requireSecureTransport` in isolation. No test covers the call site: `if (blocker != null) return runApp(blocker);` placed before `bootstrapPush()` and before `GraphQlBackendAuthApi.forEndpoint` / the holder / `RestClient`. Deleting that line, or moving it after the client construction, keeps the whole suite green, and the CI APK greps do not detect it either (they grep for dev markers, not cleartext).
**Why it matters:** this is the one place where a release that talks cleartext is prevented (HARDEN-01, D-03b). D-01/D-16 already protect the neighbouring ordering (`flavorAssert < dotenvLoad`) with a source-order test; this ordering has none.
**Suggested fix:** add to `test/bootstrap/entry_points_test.dart`, mirroring the D-16 test: read `lib/bootstrap/app_bootstrap.dart` and assert `indexOf('secureTransportBlocker(isRelease: isRelease)') < indexOf('bootstrapPush()')` and `< indexOf('GraphQlBackendAuthApi.forEndpoint')`, plus `contains('return runApp(blocker)')`. A sturdier option is to inject `bootstrapPush` into `bootstrapApp` (a defaulted parameter) and assert with `isRelease: true` plus cleartext overrides that the push, auth and client factories are never invoked.

### B-WR-03: the bundle greps in `hardening_check.sh` fail open when `unzip` cannot read the APK

**File:** `tool/hardening_check.sh:22-31`
**Issue:** the three checks compare the output of `unzip ... | grep -c ...` with `"0"`. If `unzip` fails (not installed, a truncated or 0-byte file that still passes `[ -f ]`, a corrupt archive), `grep -c` prints `0` and every check passes. `pipefail` does not help because only the printed count is tested, not the status of the command substitution.
**Why it matters:** the whole point of the script is a negative proof («no `DEV_AUTH_` in the release bundle»). A guard that is green on an unreadable artifact proves nothing, and the CI runner and local gate (12-16) rely on «hardening_check: OK».
**Suggested fix:** validate the archive once and fail closed:
```bash
if [ -f "$apk" ] && unzip -tq "$apk" >/dev/null 2>&1; then
  ...existing three checks...
else
  fail "$apk not found or not a readable archive"
fi
```
Also assert a positive control, for example `unzip -l "$apk" | grep -q 'lib/.*libapp.so'`, so a grep over an empty stream cannot pass.

### B-WR-04: the «SharedPreferences write mentions a token» grep is blind to the formatter's multi-line calls

**File:** `tool/hardening_check.sh:17` (and the allow-list at line 15)
**Issue:** line 17 greps `\.set(String|StringList)\(` and then filters for `token|jwt|bearer|secret` on the SAME line. `dart format` puts the arguments of any longer call on the following lines (see `library_bookmarks_store.dart:44-47`), so `prefs.setString(\n  _refreshTokenKey,\n  value,\n)` is not detected. The allow-list (line 15) includes `session_store.dart`, which already imports `shared_preferences` and sits next to the secure-storage code, so it is exactly the file where a later plan could write a token this way. The same one-line limitation applies to the credential grep at line 20 (`-A3` helps there, line 17 has no context).
**Why it matters:** D-18's token-hygiene claim («no SharedPreferences write of a token») is one of the three reasons the script exists, and a formatter-shaped diff bypasses it.
**Suggested fix:** use context like line 20: `grep -rn -A3 -E '\.set(String|StringList)\(' lib --include='*.dart' | grep -iE 'token|jwt|bearer|secret' && fail "..."`. Optionally restrict the allow-list entry for `session_store.dart` to `setBool` with a dedicated check. RED check: a scratch copy of the script run against a file containing the multi-line `setString(\n _tokenKey, v)` form must exit 1.

## Info

### B-IN-01: the production-graph file lists are hand-maintained in two places and have already drifted

**File:** `test/bootstrap/entry_points_test.dart:13-19`, `tool/hardening_check.sh:8`
**Issue:** the Dart gate lists five bootstrap files by name, the shell script lists only three (`main.dart`, `app_bootstrap.dart`, `session_auth_composition.dart`) and omits `auth_composition.dart`, `klimmeck_guide_app.dart` and `insecure_transport_screen.dart`. A new production file under `lib/bootstrap/` joins neither gate unless someone remembers (plan 04 had to add the screen by hand).
**Suggested fix:** derive the list: in the test, `Directory('lib/bootstrap').listSync()` minus `dev_auth_composition.dart`; in the script, `for f in lib/main.dart $(ls lib/bootstrap/*.dart | grep -v dev_auth_composition)`. A test that the directory contains exactly one dev file keeps the carve-out explicit.

### B-IN-02: `EnvConfig.isDebug` and `EnvConfig.enableLogging` are dead

**File:** `lib/config/env_config.dart:113-116, 131-134`
**Issue:** no reader remains in `lib/` (`appLog` uses `kReleaseMode`, not `enableLogging`). They are two `--dart-define` switches (`DEBUG`, `ENABLE_LOGGING`) that suggest a control which does nothing: `--dart-define=ENABLE_LOGGING=false` in debug does not silence `appLog`.
**Suggested fix:** delete both (Boy Scout), or route `appLog` through `EnvConfig.enableLogging` if the switch is wanted.

### B-IN-03: Gradle prints the debug-keys warning on every build of every variant, and a half-filled `key.properties` fails opaquely

**File:** `android/app/build.gradle.kts:62-68, 50-58`
**Issue:**
- (a) The `release { signingConfig = if (...) else { logger.quiet(...) } }` block runs at configuration time, so the WARNING is printed for debug and dev builds too, whenever `key.properties` is missing (the normal developer state).
- (b) If `key.properties` exists but lacks `storeFile`, `file(releaseKeystore.getProperty("storeFile"))` throws an unhelpful exception instead of naming the missing key.
**Suggested fix:** (a) emit the warning from a `gradle.taskGraph.whenReady { if (hasTask(":app:assembleRelease"...)) }` or `afterEvaluate` check. (b) `requireNotNull(releaseKeystore.getProperty("storeFile")) { "key.properties: storeFile missing" }` for the four keys.

### B-IN-04: `.gitignore` covers `*.jks` but not `*.keystore`

**File:** `.gitignore:74-75`
**Issue:** Android keystores are often named `*.keystore` and would be committed by a `git add .`. `key.properties` and `*.jks` are covered.
**Suggested fix:** add `*.keystore` next to `*.jks`.

### B-IN-05: the workflow uses the default token permissions and tag-pinned actions

**File:** `.github/workflows/ci.yml:1-12`
**Issue:** no `permissions:` block (a push-triggered run gets the repository default, possibly write), actions pinned by tag (`@v4`, `@v2`) and no `concurrency` group (a `push` to a `refactor/**` branch plus the PR run duplicate builds).
**Suggested fix:** add `permissions: { contents: read }` at the top and `concurrency: { group: ci-${{ github.ref }}, cancel-in-progress: true }`. Pin by SHA if the repo policy requires it.

### B-IN-06: `hardening_check.sh` changes directory before resolving a relative APK path, and its credential grep can false-positive

**File:** `tool/hardening_check.sh:4, 20, 23`
**Issue:**
- (a) `cd "$(dirname "$0")/.."` runs before `apk="$1"`, so a relative APK path given from another directory is reported as «not found».
- (b) `grep -rn -A3 '(appLog|debugPrint)\('` then matches any line in the three lines after a log call, for example an unrelated `final x = '$token'`, and makes CI red without a real leak.
**Suggested fix:** (a) resolve with `apk="$(realpath "$1")"` before the `cd`. (b) match only within the call, or document the limitation and keep multi-line messages away from credential-looking names.

### B-IN-07: `loadTestEnv` leaves `dotenv` populated and is `async` without awaiting

**File:** `test/helpers/fixtures/dev_auth_env.dart:10-30`
**Issue:** the tear-down resets `EnvConfig` overrides but not `dotenv.env`, so the dev token (`DEV_AUTH_ACCESS_TOKEN`) stays in the global `dotenv` for the rest of the test file. `DevAuthTokenService` reads `dotenv` directly. The function has no `await` and returns `Future<void>` for no reason.
**Suggested fix:** `addTearDown(() { EnvConfig.resetRuntimeOverrides(); dotenv.clean(); });` and make the function synchronous (`void`), updating the callers.

### B-IN-08: `SplashCubit` is the only gameplay-adjacent cubit without `SafeEmit`

**File:** `lib/screens/splash/cubit/splash_cubit.dart:16, 49-63`
**Issue:** `getImages` emits after several awaits (warm-up of folder and lore images). If the cubit is closed mid-flight, `emit(SplashData())` throws `StateError`, the `catch` runs `emit(SplashError(...))`, which throws again, unhandled. `SplashCubit` lives for the process today so it is unreachable, but every sibling cubit in this group uses the mixin precisely for this (`safe_emit.dart` doc).
**Suggested fix:** `class SplashCubit extends Cubit<SplashState> with SafeEmit<SplashState>`.

---

_Reviewed: 2026-11-09T18:34:15Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
