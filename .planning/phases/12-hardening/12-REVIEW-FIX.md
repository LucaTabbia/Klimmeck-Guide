---
phase: 12-hardening
fixed: 2026-11-09T18:57:49Z
source: 12-REVIEW.md
review_path: .planning/phases/12-hardening/12-REVIEW.md
rulings_path: .planning/phases/12-hardening/12-REVIEW-RULINGS.md
iteration: 1
fix_scope: all
findings_total: 25
findings_in_scope: 25
fixed_count: 21
skipped_count: 0
not_needed_count: 3
deferred_count: 1
status: all_fixed
---

# Phase 12: Code Review Fix Report

**Fixed at:** 2026-11-09T18:57:49Z
**Source review:** `.planning/phases/12-hardening/12-REVIEW.md` (group reports `12-REVIEW-A/B/C.md`)
**Rulings:** `.planning/phases/12-hardening/12-REVIEW-RULINGS.md`
**Iteration:** 1
**Branch:** `refactor/12-hardening` (no push). Start `b467aa0`, final code HEAD `945b580`.

**Summary:**
- Findings in the review: 25 (0 critical, 5 warning, 20 info)
- Fixed: 21, in TDD (RED test committed first) or, for pure refactors/infrastructure, proven by the command the ruling names
- Not needed: 3 (A-IN-06, B-IN-02, C-IN-05), plus the NOT_NEEDED halves of B-IN-05 (SHA pinning) and B-IN-06 (b)
- Deferred: 1 (C-IN-06, to the 12-17 UAT brief). Skipped: 0.

## Outcomes

| Finding | Sev | Outcome | Commits |
|---------|-----|---------|---------|
| A-IN-01 `_endSession` single-flight | info | fixed: `_endInFlight` shared by rotation refusal, `terminateSession`, `handleRevocation`; first reason wins. RED: syncLost during a blocked newLogin teardown gave 2 teardowns | `cbe8021` test, `e9857b0` fix |
| A-IN-02 reason only on `SESSION_REVOKED` | info | fixed: `_unauthenticatedReasonOf` returns `sessionExpired` for any other code. RED: `SESSION_EXPIRED` + `newLogin` ended `replacedByNewLogin` | `22b628e` test, `6f7a974` fix |
| A-IN-03 stale dev-stub docs | info | fixed (docs only): both headers say the stub is composed only by `lib/main_dev.dart` via `buildDevAuthComposition` (Phase 12 D-01) | `1de2616` |
| A-IN-04 logout flow proves too little | info | fixed (test only): old stream proven live before logout; after it exactly 2 `connection_init` frames and 2 sockets. Green at first run (behaviour holds); 3 consecutive green runs | `a38b251` |
| A-IN-05 redundant `kDebugMode` | info | fixed: guard and `foundation` import dropped; existing interceptor and `app_log` tests green | `784fbc8` |
| A-IN-06 `handleRevocation()` no production caller | info | not_needed: explicit-revocation hook of the Phase 11 contract (D-09), implemented by both services and used by the dev stub and tests; removing an interface member is outside the hardening scope | — |
| B-WR-01 overlapped push registration | warning | fixed: `Set<Future<void>> _attemptsInFlight`, drain awaits `Future.wait` under the drain timeout. RED: unregister was sent while the first register was still blocked | `78b3b79` test, `88a86c8` fix |
| B-WR-02 blocker call site untested | warning | fixed (test): source-order test in `entry_points_test.dart` (D-03). Green at first run; a scratch mutation removing `return runApp(blocker)` turned it red (reverted with `git checkout`) | `99a2005` |
| B-WR-03 guard fails open on unreadable APK | warning | fixed: `unzip -tq` validation + `libapp.so` positive control (with `grep -c`, since `grep -q` + `pipefail` failed on SIGPIPE against the real APK). Before: 0-byte file → `hardening_check: OK`; after: exit 1 «not found or not a readable archive»; zip without `libapp.so` → exit 1; real `app-prod-release.apk` → OK | `90d962d` |
| B-WR-04 multi-line token write | warning | fixed: `-A3` on the SharedPreferences token grep. Scratch copy of `lib/` (scratchpad) with a 3-line `setString(_tokenKey, value)` in `session_store.dart`: OK before, exit 1 after; real tree OK | `29b1669` |
| B-IN-01 hand-maintained file lists | info | fixed: test derives `lib/bootstrap/*.dart` minus `dev_auth_composition.dart` and asserts exactly one bootstrap file mentions the dev bypass; script loops `lib/main.dart $(ls lib/bootstrap/*.dart \| grep -v dev_auth_composition)`. Scratch copy with a dev marker in `klimmeck_guide_app.dart` → exit 1 (the old list missed it); tree OK | `ac257ce` test, `7dbe8c3` script |
| B-IN-02 `isDebug`/`enableLogging` unread | info | not_needed: the state CONTEXT D-03c (revised after the research) records explicitly; they stay compile-time flags | — |
| B-IN-03 Gradle warning on every variant | info | fixed: (a) warning from `gradle.taskGraph.whenReady` only when a `Release` task is in the graph; (b) `requireNotNull` with `key.properties: <key> missing` for the four keys. Scratch builds (no `key.properties` on disk): dev debug 0 WARNING lines, prod release exactly 1. (b) not exercised: agents never create `key.properties` | `945b580` |
| B-IN-04 `*.keystore` not ignored | info | fixed: `*.keystore` next to `*.jks`; `git check-ignore -v probe.keystore` at the repo root matches `.gitignore:76` (the commit body cites an `android/` probe, which `android/.gitignore` already covered) | `e75e6ed` |
| B-IN-05 workflow token/concurrency | info | fixed: `permissions: contents: read`, `concurrency: ci-${{ github.ref }}` with cancel-in-progress (YAML parsed with ruby). SHA pinning: not_needed (no SHA policy) | `adfe9e7` |
| B-IN-06 relative APK path / credential grep | info | (a) fixed: APK path made absolute before the `cd`; from `build/app/outputs` the old script reported «not found», the new one OK; from root (CI form) OK. (b) not_needed: over-approximation kept, documented by a comment | `6783d3b` |
| B-IN-07 `loadTestEnv` leaves dotenv | info | fixed: tear-down resets overrides and `dotenv.clean()`. Kept `Future<void>`: 19 `await` call sites would be churn. RED: new `dev_auth_env_test.dart` saw dotenv still populated in the next test | `55f3bb2` test, `86d928a` fix |
| B-IN-08 `SplashCubit` without `SafeEmit` | info | fixed: `with SafeEmit<SplashState>`, the manual `isClosed` check in the watch timer dropped. RED: close during the warm-up surfaced a `StateError` | `91065cd` test, `78d1e9b` fix |
| C-WR-01 stale moderation banner | warning | fixed: successful `pickPortrait` and `removePortrait` set `submitFailure: null` (the `_unset` sentinel already allowed null). RED: both new tests (D-13) failed | `9f67514` test, `b6be749` fix |
| C-IN-01 wildcard in quest result notice | info | fixed: silent values listed explicitly, no `_`; existing silent-set test green | `7519e89` |
| C-IN-02 `badUserInputCode` location | info | fixed: moved to `graphql_error_code.dart`; the ten `show badUserInputCode` imports removed (the ruling's «eleven» counts the defining file); `grep -l "badUserInputCode =>" lib/repository/*_failure.dart \| wc -l` = 11 | `668da9a` |
| C-IN-03 coded HTTP 500 unpinned | info | fixed (test only): coded 500 → `INTERNAL_SERVER_ERROR`, acceptance classifier `unknown`; uncoded 500 → `connection` (D-13). Green at first run, records current behaviour | `52f27e0` |
| C-IN-04 raw exception text in `WorldMapError` | info | fixed: `e.runtimeType.toString()`, class shape kept. RED: new `world_map_cubit_test.dart` found the server message in the state | `8e09e83` test, `31733fe` fix |
| C-IN-05 two `size` properties | info | not_needed: consequence of the user veto D-13c; a rename is optional and out of scope | — |
| C-IN-06 visibility now from backend data | info | deferred: the orchestrator adds the DB check of `size` for `ferrionCity`, `necrorianCity`, `talmvereVillage` to the 12-17 UAT brief. No code | — |

## Gate output

- `flutter analyze`: `47 issues found.` — 0 error, 0 warning (info baseline unchanged)
- `bash tool/hardening_check.sh`: `hardening_check: OK`
- `bash tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk` (rebuilt for B-IN-03 with `--dart-define-from-file=env/prod.json`): `hardening_check: OK`
- Full suite, foreground: `01:28 +3704: All tests passed!`
- `git status --short`: empty
- Every commit: trailer grep printed `0`

## Notes for the device UAT

- **Character creation (C-WR-01):** after «Immagine non ammessa, scegline un'altra.» the banner disappears as soon as a new image is picked; after «Controllo dell'immagine non disponibile: riprova o procedi senza immagine.» it disappears when the portrait is removed. A cancelled pick leaves it.
- **Revocation notice (A-IN-01, A-IN-02):** a sync-lost termination landing during a new-login teardown no longer replaces «Hai effettuato l'accesso da un altro dispositivo.» with «Connessione persa»; a `SESSION_EXPIRED` carrying a reason always shows the neutral expiry notice.
- **Push after logout (B-WR-01):** logout now waits (within the existing drain budget) for every register in flight, so a token refresh just before logout cannot leave the device subscribed to the old user.
- **Map (C-IN-04):** no visible change (`WorldMapError` has no consumer).
- **Builds (B-IN-03):** dev/debug builds no longer print the debug-keys WARNING; the release build still prints it once when `android/key.properties` is absent. A `key.properties` missing a key now fails the build with `key.properties: <key> missing`.
- **Guard (B-WR-03, B-IN-06):** `tool/hardening_check.sh` now fails on a missing, empty or non-Flutter APK and accepts a relative path from any directory.
- **Not changed by any fix:** the copy, the reason enum, `4409`, the two notices, the CityType pixel sizes.

---

_Fixed: 2026-11-09T18:57:49Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
