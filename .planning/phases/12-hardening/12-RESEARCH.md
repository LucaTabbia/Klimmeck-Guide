# Phase 12: Hardening - Research

**Researched:** 2026-11-09
**Domain:** Flutter release hardening (entry-point split, Android flavors and signing, TLS-only and silent release logging), session-layer proofs (logout flow, single-flight refresh, leak tracking, dual-session revocation), CI, three parked follow-ups
**Confidence:** HIGH for the build/flavor/signing/leak mechanisms (each was probed on this machine with Flutter 3.35.5), HIGH for the codebase map (file:line), MEDIUM for the BE Phase 17 contract (fixed in the BE `17-REPO-RULES.md`, not merged yet: the gate file is absent on BE `origin/develop`)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
#### Dev bypass, `.env` and the release build (criterion 6, HARDEN-01, HARDEN-07, HARDEN-08)
- **D-01 (user decision, «Entry point separato»):** the dev bypass moves to a dedicated entry point **`lib/main_dev.dart`**, which composes `DevAuthTokenService`, loads `.env` through `flutter_dotenv` and keeps today's dev behaviour (D-23..D-30 of Phase 11: `DEV_AUTH_*` knobs, instant login, `DEV_AUTH_START_SIGNED_OUT`). **`lib/main.dart` becomes production-pure**: no `DevAuthTokenService`, no `DEV_AUTH_*`, no `flutter_dotenv` import; `_buildAuth` composes only `SessionAuthTokenService`. The two entry points share one composition module (no duplicated wiring: the dev file only swaps the auth factory). Device UATs run with `flutter run -t lib/main_dev.dart`; the gate is a grep that proves `lib/main.dart` and the release bundle contain neither `DevAuthTokenService` nor the string `DEV_AUTH_`.
- **D-02 (user decision, «Niente .env in release»):** the release build ships **no `.env`**. Backend URLs come from **`--dart-define-from-file=env/<ambiente>.json`** (URLs only, no secret: the file can live in the repo; `EnvConfig` already reads `String.fromEnvironment` as the second priority). `.env` + `flutter_dotenv` stay a convenience of the dev entry point only. Mechanism to keep the asset out of the release bundle (pubspec asset `flavors:` with a `dev` flavor, a build-time copy, or another verified option) is **researcher/planner discretion**; the truth is the gate: the built release APK contains no `.env` entry and no `DEV_AUTH_` string.
- **D-03 (user decision, «Tutto in scope»):** release readiness is part of this phase: (a) **signing** — the release build reads the keystore from **`android/key.properties`** (already in `.gitignore` with `*.jks`); **the user generates the keystore and the properties file** (exact `keytool` command and the four keys documented in the handoff); when the file is missing the build **falls back to the debug keys with a visible warning**, so CI and `flutter run --release` keep working; (b) **TLS only** — in release the app refuses cleartext `http://` / `ws://` backend URLs (fail fast at startup with a clear, non-gameplay screen; copy and shape Claude's discretion), closing AR-03 of the Phase 3 security audit; `EnvConfig.isDebug` / `enableLogging` default to `false` in release; (c) **no logging in release** — `debugPrint` calls are routed through one logger that is silent under `kReleaseMode` (or stripped), and the token-hygiene grep proves no token or bearer value ever reaches a log statement.
- **D-04 (user decision, «Tunnel TLS verso il BE locale»):** the release build is exercised on the device through a **TLS tunnel to the local BE** (`cloudflared tunnel` or `ngrok`), with `--dart-define-from-file` pointed at the tunnel host; the real Twitch login runs through it. Prerequisite for the user: the tunnel's public URL must be an allowed redirect URI of the Twitch application (or a stable named tunnel is used), written in the UAT sheet. Nothing new is deployed.

#### Test harnesses and CI (HARDEN-01, HARDEN-03, HARDEN-04, HARDEN-05, HARDEN-09)
- **D-05 (user decision, «Test automatico + DevTools in UAT»):** HARDEN-05 is proven twice: (a) a **leak-tracking widget test** (`leak_tracker_flutter_testing`, already in the lock through `flutter_test`, Flutter 3.35.5) that pumps the authenticated shell with its cubits and subscriptions, logs out, and **fails on any not-disposed / not-GCed object** (cubits, `StreamSubscription`s, the WS link); (b) a **DevTools memory snapshot before/after logout** as a step of the device UAT, documented with screenshots.
- **D-06 (user decision, «Telefono + emulatore Android»):** the dual-device UAT uses the **Samsung over USB plus an Android emulator**, both logged in with the **same real Twitch account**; the cases of revocation and conflict are also covered by an **in-process test with two `SessionAuthTokenService` instances** against the fake backend helpers (`FakeGraphQlWsServer.dropWith(<close code>)`, fake HTTP adapter). Protocol in `12-HUMAN-UAT.md`.
- **D-07 (user decision, «Completa con build release»):** a **GitHub Actions workflow on PR → `develop`** (the FE repo has none today): `flutter analyze` with **0 error / 0 warning** (info baseline tolerated), `flutter test`, the **guard greps** (no `SharedPreferences` in the auth/storage layer for tokens, no token/bearer value in any log statement, no `DEV_AUTH_` / `DevAuthTokenService` / `flutter_dotenv` in `lib/main.dart`), then **`flutter build apk --release`** with the dart-define file and a **grep of the bundle** for `.env` and `DEV_AUTH_`. The BE `.github/workflows/ci.yml` is the reference for shape; the schema check tool (`tool/schema_check`, needs the BE SDL) stays local.
- **D-08 (technical default, stated in the discuss):** HARDEN-03 and HARDEN-04 are **verified, not reinvented**: the existing suites (`session_auth_token_service_{refresh,logout,revocation,terminate,bootstrap}_test.dart`, `auth_cubit_test.dart`, `auth_token_service_contract_test.dart`) are audited against the two criteria and completed where a step is missing: one **end-to-end logout flow test** (backend `logout` best-effort, subscriptions cancelled, `GraphQLClient` + `WebSocketLink` recreated, secure storage cleared, `Unauthenticated` emitted, sign-in shown — Phase 11 D-12/D-36 in one flow) and one **concurrency test** (two simultaneous `UNAUTHENTICATED` / 401 responses → exactly one `refreshSession` call, no silent logout — Phase 11 D-06).

#### Multi-device and identity transitions (HARDEN-06, HARDEN-02 evidence)
- **D-09 (user decision, «L'ultimo login caccia l'altro», BE Phase 17 D-02/D-03/D-04):** a login on a second device **revokes the other sessions of the user on the BE**, which **closes their WebSocket connections at once** with a dedicated close code; the access JWT of the replaced device stays valid until its natural expiry (15 min, stateless, no per-request lookup). On the FE the replaced device reacts to the close as it does to `4401` today (refresh before reconnect, Phase 11 D-07/D-37): the refresh is refused with `SESSION_REVOKED` + `reason`, the session is torn down (same path as a revocation, D-09 of Phase 11) and the sign-in screen shows the **specific notice** (D-12). Bounded reconnects, no hot loop, no blocking UI (rule 2).
- **D-10 (user decision, «Solo quel device»):** logout keeps closing **only the current session** (Phase 11 D-12 step 1); the other device stays logged in. «Esci da tutti i dispositivi» stays in the BE backlog (deferred).
- **D-11 (user decision, «Reset totale della shell»):** identity transitions rebuild the whole shell by construction — **already the design**: `AuthGate` keys the authenticated subtree on `user.id` and `SessionHome` on `character:<id>`, root-Navigator dialogs and sheets are closed on both changes (Phase 3 D-10, Phase 11 D-26). This phase **proves it** with tests (account switch on the same device; character deleted or recreated from the other device → creation screen, then a fresh shell for the new id) and fixes any gap found (a cubit or listener surviving the key change, a push intent routed to a stale character). No «refetch in place» variant.
- **D-12 (user decision, «Specifico quando il BE lo dice», BE Phase 17 D-05):** the refresh refusal keeps the code `SESSION_REVOKED` and adds **`extensions.reason`** (enum, names fixed in the BE `17-REPO-RULES.md`; technical defaults `newLogin`, `roleChanged`, `reuseDetected`, `userLogout`); the same string travels in the reason of the dedicated WS close. The FE parses it **leniently** (unknown or missing → the neutral Phase 11 D-10 notice «La sessione è scaduta, accedi di nuovo.») and shows dedicated copy for **`newLogin`** («Hai effettuato l'accesso da un altro dispositivo.», copy Claude's discretion) and **`roleChanged`** («Il tuo ruolo è cambiato, accedi di nuovo.»). Implementation: new `UnauthenticatedReason` and `SignInNotice` values; `SessionRejected` carries the reason. Gated plan (BE contract).

#### Bug-fix pass (HARDEN-10)
- **D-13 (user decision, three of four follow-ups folded):** (a) **`BAD_USER_INPUT`** (BE Phase 10) is mapped in **every** existing failure classifier (`lib/repository/*_failure.dart`: transaction, travel, quest acceptance/abandon/result, pet equip, innkeeper, character creation/deletion, push device; `SpellEquipFailure` already maps it) with an in-world message, never the generic error; (b) **`IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE`** (BE Phase 10 BE-HARD-05) are mapped in `CharacterCreationFailure`: rejected portrait → dedicated message and a new pick; moderation unavailable → dedicated message and retry, the draft kept; (c) **`CityType.cityClass` is removed** in favour of **`City.size`** served by the BE (Phase 13 deferred item): marker sizes derive from `City.size`, the FE map goes away, the `cities` query selects `size` (already on the wire since BE Phase 12).
- **D-14 (user decision, «Sì, review per aree + fix»):** the «intensive bug-fix pass» of the ROADMAP is a **cross-cutting code review by three parallel reviewers** (session/WS and auth, cubits and subscriptions lifecycle, models and tolerant parsing), an orchestrator ruling, then a fixer in TDD; findings outside the phase boundary are recorded as deferred, not fixed here. Pipeline of the previous phases (review → ruling → fix → verify → security).
- **D-15 (user decision):** the **diagnostics badge** for the WS connection stays **out** (rejected in Phase 3 D-17, not revived).


### Claude's Discretion
- Copy of the two new sign-in notices and of the fail-fast screen for cleartext URLs in release; whether the fail-fast is a screen or a hard assertion at startup.
- The mechanism that keeps `.env` out of the release bundle (asset flavors vs other), the shape of the shared composition module between the two entry points, the name of the dart-define file(s).
- The logger seam for `debugPrint` in release; the exact guard-grep patterns and where they run (CI job vs a `tool/` script invoked by CI).
- Gradle wiring for `key.properties` (property names, fallback warning text); which Android emulator image the UAT uses.
- Test structure of the leak-tracking test (one shell-level test vs per-cubit), the in-process dual-session harness, and how the phase splits plans before/after the BE Phase 17 gate.


### Deferred Ideas (OUT OF SCOPE)
- **«Esci da tutti i dispositivi»** (Settings entry + BE mutation revoking every session of the user) — BE backlog since Phase 2; not needed once the last login wins.
- **Diagnostics badge / dedicated sync logs** in the dev entry point — rejected again (D-15).
- **Per-request session validation on the BE** (kick the replaced device from HTTP at once) — rejected in the BE Phase 17 discuss (JWT stays stateless, 15 min window accepted).
- **Heal mechanics** (`LootItem.canHeal` in use: potions curing specific injuries, partial heal quests) — dedicated FE/BE phase pair after v1.0 Hardening (quick tasks 261109-inj/inj2).
- **iOS release readiness, store publication, accessibility pass (FUT-04)** — post-v1.0.
- «Failed host lookup: 'localhost'» seen in the Phase 10 UAT — explained by the device setup (Doze with the screen off, adb tunnel lost on USB reconnection); no app defect, nothing to do here.

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| HARDEN-01 | No token in shared_preferences, logs or unencrypted disk (review + CI grep) | F5 (log inventory: 0 credential interpolations today), `tool/hardening_check.sh` (Code Examples, probed) with a SharedPreferences writer allow-list (7 files today, none writes a token) |
| HARDEN-02 | Admin endpoints 403 for non-innkeepers | Delivered by BE Phase 17 D-01 (matrix over `EXPECTED_INNKEEPER_HANDLERS` 11 / `EXPECTED_OWNERSHIP_HANDLERS` 19); FE only records the evidence in its handoff (F12 row) |
| HARDEN-03 | Atomic logout covered by automated test | F9 audit table: steps asserted per suite, missing = one end-to-end flow test over real `SessionAuthTokenService` + real `GraphQLClientHolder` + loopback WS + `AuthCubit` |
| HARDEN-04 | Single-flight refresh, no double refresh / silent logout | F9: service-level single-flight already pinned (`session_auth_token_service_revocation_test.dart:129`, `_refresh_test.dart:141`); missing = link-level test (two concurrent 401/`UNAUTHENTICATED` through `AuthAuthLink` + dio `AuthInterceptor`) |
| HARDEN-05 | No retained subscriptions/cubits after logout | F6 (probe P-L1..P-L6): `leak_tracker` does NOT see cubits by itself; a test-only `BlocObserver` dispatching `LeakTracking.dispatchObjectCreated/Disposed` makes unclosed cubits fail; `WeakReference` + `forceGC` proves GC; `StreamController.hasListener` proves cancelled subscriptions; WS link proven in the flow test (loopback) |
| HARDEN-06 | Second device login handled gracefully | F7 (code path `4409` → refresh → `SessionRejected(reason)` → `_endSession(mapped reason)` → `SignInNotice`), F8 (identity transitions, one gap candidate), dual-session harness design |
| HARDEN-07 | Production entry point pure; no `.env` / `DEV_AUTH_` in the release bundle | F1 (import graph to cut, incl. the `auth.dart` barrel), F2 (probes P-B1..P-B8: asset flavors + Android product flavors + `default-flavor: prod`; AOT tree-shaking removes `DEV_AUTH_` once `main.dart` stops importing the dev code) |
| HARDEN-08 | Signed release, TLS only, silent logs, tunnel UAT | F3 (Kotlin DSL wiring probed with a throwaway keystore and without the file), F4 (`requireSecureTransport`, dart:io ignores Android cleartext policy), F5 (`appLog`), F13 (tunnel/Twitch redirect prerequisites) |
| HARDEN-09 | GitHub Actions CI | F10 (workflow, runtimes measured: `flutter test` 86 s / 3565 tests locally, release build 55–103 s; `flutter analyze` exits 1 on infos → `--no-fatal-infos`) |
| HARDEN-10 | Follow-ups + review by area | F11 (11 classifiers, HTTP-400 blind spot of `graphQlErrorCode`, moderation codes verified in BE `src/moderation/image-moderation.exceptions.ts:3-4`, `City.size` table, 2 pinned map tests probed RED); D-14 review is orchestrator-run |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Flutter + BLoC/Cubit; layers per `docs/rules/architecture.md` (UI never does networking, repositories never see `BuildContext`, models Flutter-free).
- TDD red → green → refactor for every feature/bugfix; Boy Scout rule; Clean Code (small functions, no behaviour flags, early return).
- Rule 1: no app chrome outside utility screens (`InsecureTransportScreen` and the sign-in notices are utility surfaces).
- Rule 2: no blocking loading in an active session (revocation teardown and identity rebuild silent until the sign-in screen).
- Rule 3: branch + PR per phase (`refactor/12-hardening` → `develop`).
- Rule 4: backend is the source of truth (FE never decides a revocation).
- Rule 5: no secret in the repo (`.env`, `key.properties`, `*.jks`, `google-services.json` stay out; `env/*.json` hold URLs only).
- `flutter analyze` clean before PR; `dart format` only on touched files (baseline not formatter-clean; memory: never on a directory).
- Commit trailers: no `Co-Authored-By` / `Generated with` / `Claude-Session` (user rule, restated in `12-REPO-RULES.md`).

## Summary

Every mechanism the CONTEXT left open was settled by an experiment on this machine (Flutter 3.35.5, AGP 8.9.1, Gradle 8.12, JDK 21 from Android Studio). **`.env` out of the release bundle:** a pubspec asset entry `- path: .env` with `flavors: [dev]` is excluded from any build that does not pass `--flavor dev`, and the build succeeds even when `.env` is absent on disk (the CI case — today a checkout without `.env` fails with `No file or variants found for asset: .env`). Passing `--flavor dev` requires Android `productFlavors`; once they exist, every no-flavor command fails (`assembleRelease` builds `devRelease`, which needs `.env`; `flutter build apk --debug` "failed to produce an .apk"), and `default-flavor: prod` in the pubspec fixes that: plain `flutter build apk --release` builds `prodRelease`, ships no `.env`, compiles the `--dart-define-from-file` URLs in, and drops the `http://192.168.0.20` defaults. The cost is visible: the APK path becomes `build/app/outputs/flutter-apk/app-prod-release.apk` and the dev run becomes `flutter run --flavor dev -t lib/main_dev.dart` (Conflicts C-1, C-2).

**The bundle gate as written in the REPO-RULES does not work** (C-3): `grep -c -a DEV_AUTH_ <apk>` printed `0` on today's debug APK although `assets/flutter_assets/.env` (318 bytes, deflated) holds the `DEV_AUTH_*` keys, and `unzip -p <apk> 'assets/flutter_assets/AssetManifest*' | grep -c DEV_AUTH_` is always `0` (the manifest lists `.env`, never its content). The correct gate decompresses every entry: `unzip -p <apk> | grep -a -c DEV_AUTH_`. On today's release APK it prints 26 (7 per ABI `libapp.so` from `DevAuthTokenService` + the `.env`); on a probe build with `main.dart` no longer importing the dev code and the flavored asset it prints 0, even with `EnvConfig.devAuthEnabled` still declared (AOT tree-shaking). Signing: a Kotlin-DSL block reading `android/key.properties` was probed both ways (throwaway keystore → APK signed `CN=Probe Upload`; no file → `CN=Android Debug`); the fallback warning is only visible with `logger.quiet(...)` because the Flutter tool runs Gradle with `-q`.

On the session side the code is already shaped for the phase: `SessionRejected` is the single terminal path (`session_auth_token_service.dart:368-371`), `WsReconnectPolicy` routes auth close codes through the single-flight recovery (`ws_reconnect_policy.dart:29,63-72`), and the identity keys are in place (`auth_gate.dart:50-53`, `session_home.dart:27-30`). For HARDEN-05 the probes show `leak_tracker_flutter_testing` 3.0.10 sees only objects that dispatch creation/disposal events (a `ValueNotifier` leak fails; an unclosed `Cubit` passes silently), so the leak test needs a test-only `BlocObserver` that dispatches those events (probed: an unclosed cubit then fails with `notDisposed`), plus `WeakReference` + `forceGC` for retention (leak_tracker's `notGCed` did not fire in `testWidgets`), plus `StreamController.hasListener` for subscriptions; the real WS link cannot run under `testWidgets` (HttpOverrides) and is proven in the `test(...)` logout flow over `FakeGraphQlWsServer`.

**Primary recommendation:** asset flavors + Android `dev`/`prod` product flavors + `default-flavor: prod`, an injectable runtime-override seam in `EnvConfig` (no `flutter_dotenv` import), the decompressing bundle gate in `tool/hardening_check.sh`, and a leak test built from BlocObserver dispatch + WeakReference/forceGC + `hasListener`.

## Standard Stack (no new runtime dependency)

### Core (already in `pubspec.lock`)
| Library | Version | Purpose | Note |
|---------|---------|---------|------|
| Flutter / Dart | 3.35.5 / 3.9.2 (via fvm, `.fvmrc`) | SDK | `flutter --version` [VERIFIED: local] |
| flutter_dotenv | 6.0.0 | `.env` in the dev entry point only | `load({isOptional})` exists (`flutter_dotenv-6.0.0/lib/src/dotenv.dart:117-141`) [VERIFIED: pub-cache] |
| graphql / graphql_flutter | 5.2.1 | WS link passes `closeCode`/`closeReason` to `onConnectionLost(code, reason)` | `websocket_client.dart:373-404` [VERIFIED: pub-cache] |
| gql_http_link | 1.1.0 | status ≥ 300 → `HttpLinkServerException` with `parsedResponse` | `link.dart:89-95` [VERIFIED: pub-cache] |
| bloc / flutter_bloc | 9.0.0 / 9.1.1 | `BlocObserver.onCreate/onClose` for leak dispatch | [VERIFIED: pubspec.lock] |

### Test-only (transitive through `flutter_test`, to be declared in `dev_dependencies`)
| Library | Version | Import for | Note |
|---------|---------|------------|------|
| leak_tracker_flutter_testing | 3.0.10 | `LeakTesting.enable()`, `testWidgets(experimentalLeakTesting:)` | re-exports only `IgnoredLeaks, LeakReport, LeakTracking, LeakType, Leaks` from leak_tracker [VERIFIED: `leak_tracker_flutter_testing.dart:5-8`] |
| leak_tracker | 11.0.2 | `forceGC({timeout, fullGcCycles})` | NOT re-exported: import `package:leak_tracker/leak_tracker.dart` (probe P-L0 failed with `Method not found: 'forceGC'` until imported) [VERIFIED: probe] |

Declare both (`leak_tracker: ^11.0.2`, `leak_tracker_flutter_testing: ^3.0.10`) — otherwise `depend_on_referenced_packages` adds infos. Exact SDK pins resolve them; no `pub upgrade`.

### CI actions
| Action | Version | Source |
|--------|---------|--------|
| subosito/flutter-action | `@v2` (latest release v2.23.0, 2026-03-25) with `flutter-version: 3.35.5`, `channel: stable`, `cache: true` | [VERIFIED: GitHub API releases] |
| actions/checkout | `@v4` (BE uses v4; latest is v7.0.1) | [VERIFIED: GitHub API + BE `ci.yml`] |
| actions/setup-java | `@v4`, `distribution: temurin`, `java-version: '17'`, `cache: gradle` | [ASSUMED: v4 inputs; latest release tag is v6.2.0 — VERIFIED via GitHub API] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Asset flavors + product flavors | `.env` removed from assets, dev values via `--dart-define-from-file=.env` | Keeps `flutter run` flag-free, but dev knobs become compile-time constants and `main_dev.dart` no longer «loads `.env` through flutter_dotenv» (D-01 wording) — rejected |
| Asset flavors + product flavors | CI-only placeholder `.env` | The developer's own release build (D-04 UAT) would still ship the real `.env` — rejected |
| leak_tracker notGCed | `WeakReference` + `forceGC` | notGCed did not fire in `testWidgets` (probe P-L5); WeakReference is deterministic (P-L6) |

## Architecture Patterns

### Recommended files (names fixed by `12-REPO-RULES.md` in bold)
```
lib/
├── main.dart                                   # **prod entry**: `Future<void> main() => bootstrapApp(buildAuth: buildSessionAuthComposition);`
├── main_dev.dart                               # **dev entry**: dotenv.load → EnvConfig.installRuntimeOverrides(dotenv.env) → bootstrapApp(buildAuth: buildDevAuthComposition)
├── bootstrap/
│   ├── app_bootstrap.dart                      # **shared composition**: TLS gate, push, GraphQL holder, REST, SystemChrome, runApp
│   ├── auth_composition.dart                   # typedefs AuthComposition / AuthCompositionFactory (shared, no dev symbol)
│   ├── session_auth_composition.dart           # **prod auth factory**
│   ├── dev_auth_composition.dart               # **dev auth factory** (only dev-knob reader besides the dev service)
│   ├── klimmeck_guide_app.dart                 # KlimmeckGuideApp + navigatorKey moved out of main.dart (main.dart:125-372)
│   └── insecure_transport_screen.dart          # utility screen (D-03b)
├── config/env_config.dart                      # no flutter_dotenv; installRuntimeOverrides; requireSecureTransport; flags default !kReleaseMode
├── config/insecure_transport_error.dart        # (or inside env_config.dart) InsecureTransportError
└── utils/app_log.dart                          # **appLog(String)**, silent under kReleaseMode
android/app/build.gradle.kts                    # productFlavors dev/prod + key.properties signing
env/dev.json, env/prod.json                     # **dart-define files** (URLs only)
tool/hardening_check.sh                         # **guard script**
.github/workflows/ci.yml                        # **CI**
test/helpers/leak_tracking_bloc_observer.dart   # test-only dispatcher (Wave 0)
test/helpers/fakes/fake_session_backend.dart    # shared in-memory BE for the dual-session test (Wave 0)
```

### F1. Import graph to cut (D-01) [VERIFIED: codebase grep]
- `lib/main.dart:8` imports `flutter_dotenv`; `:50` `dotenv.load(fileName: '.env')`; `:16` imports the barrel `auth.dart`, which **re-exports `dev_auth_token_service.dart`** (`lib/repository/services/auth/auth.dart:7`) — cutting `main.dart`'s direct dev import is not enough, the barrel export must go (only `main.dart` imports the barrel in `lib/`; the tests that need the dev service already import its file directly: `dev_auth_token_service_{role,transitions,}_test.dart`, `auth_token_service_contract_test.dart`, `auth_gate_dev_bypass_test.dart`; none of the 9 barrel-importing tests uses `DevAuthTokenService` — grep `DevAuth` in them returns nothing).
- `lib/main.dart:104-123` `_buildAuth` = the only reader of `EnvConfig.devAuthEnabled` (`:108`) and the only `DevAuthTokenService(` constructor (`:109`).
- `lib/config/env_config.dart:1` imports `flutter_dotenv`; `_runtimeValue` (`:50-57`) reads `dotenv.env`; it is reached by `graphql_client_provider.dart:34,40` and `rest_client_provider.dart:19`, so today `flutter_dotenv` lands in the release `libapp.so` even after the entry split (probe P-B7: `flutter_dotenv` string count 2 per ABI with `main.dart` already clean) → the injectable override seam is required, not cosmetic.
- `DEV_AUTH_` literals in `lib/`: only `dev_auth_token_service.dart` (17 lines) and `env_config.dart:96-105` (`DEV_AUTH_ENABLED`). Tree-shaking removes the `env_config` one when nothing in the prod graph references `devAuthEnabled` (P-B7: `DEV_AUTH_` 0 in all three `libapp.so`).
- Other `EnvConfig` readers stay unchanged: `graphql_client_provider.dart:34,40,48,68,71,94`, `rest_client_provider.dart:19`, `cloudinary_assets.dart:221`.
- `KlimmeckGuideApp` (`main.dart:127-372`) and `navigatorKey` (`:125`) have no importer outside `main.dart` (grep: only a doc comment in `graphql.dart:54`); move them to `lib/bootstrap/klimmeck_guide_app.dart` so `main.dart` stays a 3-line file.

Proposed signatures:
```dart
// lib/bootstrap/auth_composition.dart
typedef AuthComposition = ({
  AuthTokenService service,
  UnauthorizedRecovery? recovery,
  SessionTerminator terminator,
});
typedef AuthCompositionFactory = AuthComposition Function({
  required BackendAuthApi api,
  required Future<void> Function() onSessionTeardown,
});

// lib/bootstrap/session_auth_composition.dart
AuthComposition buildSessionAuthComposition({
  required BackendAuthApi api,
  required Future<void> Function() onSessionTeardown,
}) { /* body of main.dart:115-122 */ }

// lib/bootstrap/dev_auth_composition.dart
AuthComposition buildDevAuthComposition({
  required BackendAuthApi api,
  required Future<void> Function() onSessionTeardown,
}) {
  if (!EnvConfig.devAuthEnabled) {
    return buildSessionAuthComposition(api: api, onSessionTeardown: onSessionTeardown);
  }
  final dev = DevAuthTokenService(meSource: api, onSessionTeardown: onSessionTeardown);
  return (service: dev, recovery: null, terminator: dev);
}

// lib/bootstrap/app_bootstrap.dart
Future<void> bootstrapApp({
  required AuthCompositionFactory buildAuth,
  bool isRelease = kReleaseMode,
}) async { /* main.dart:48-94 minus dotenv, plus the TLS gate first */ }
```
`api` = `GraphQlBackendAuthApi.forEndpoint(EnvConfig.graphqlHttpUrl)` built in `bootstrapApp` (today `main.dart:105-107`).

`EnvConfig` seam (replaces `env_config.dart:1,47-57`):
```dart
static Map<String, String> _runtimeOverrides = const {};

/// Dev entry point only (D-01): installs the `.env` values loaded by main_dev.dart.
static void installRuntimeOverrides(Map<String, String> values) =>
    _runtimeOverrides = Map.unmodifiable(values);

@visibleForTesting
static void resetRuntimeOverrides() => _runtimeOverrides = const {};

static String? _runtimeValue(String key) {
  final value = _runtimeOverrides[key]?.trim();
  return (value == null || value.isEmpty) ? null : value;
}
```
Tests change from `dotenv.loadFromString(...)` to `EnvConfig.installRuntimeOverrides({...})` + `tearDown(EnvConfig.resetRuntimeOverrides)`; the quoted-value case (`BASE_URL="  http://…  "`, `env_config_backend_urls_test.dart:22`) becomes a plain `'  http://…  '` value (dotenv strips the quotes before the map; the trim stays in `EnvConfig`). `test/helpers/fixtures/dev_auth_env.dart` keeps `dotenv.loadFromString` (the dev service reads `dotenv.env` directly) and additionally calls `EnvConfig.installRuntimeOverrides(dotenv.env)` so `devAuthEnabled` keeps working in `env_config_test.dart`.

### F2. `.env` out of the release bundle (D-02) — probes P-B1..P-B8 [VERIFIED: probe]
All probes ran on a `git archive HEAD` copy in the scratchpad (no `.env`, no `google-services.json`, no `key.properties`: the CI situation), except P-B1 which ran in the repo.

| Probe | Setup | Command | Outcome |
|-------|-------|---------|---------|
| P-B0 | today's debug APK in `build/` | `unzip -l`, `grep -c -a`, `unzip -p … \| grep -a -c` | `.env` entry 1 (318 B, `Defl:N`); raw `grep -a -c DEV_AUTH_` **0**; manifest grep **0**; `unzip -p <apk> \| grep -a -c DEV_AUTH_` **28** |
| P-B1 | repo, today | `flutter build apk --release` | exit 0, 103 s cold; `.env` entry 1; raw grep 21 (`libapp.so` is `Stored`: 7 per ABI); whole-content 26; `DevAuthTokenService` 2 per ABI |
| P-B2 | copy, no `.env` | `flutter build apk --release` | **exit 1 in 30 s: `No file or variants found for asset: .env.`** (CI breaks today) |
| P-B3 | copy, `- path: .env` + `flavors: [dev]`, dummy `.env` present, no Android flavors | `flutter build apk --release` | exit 0, 55 s; `.env` entries 0 |
| P-B3b | same, `.env` deleted | `flutter build apk --release` | exit 0, 13 s; `.env` entries 0 (a flavored asset may be missing on disk) |
| P-B3c | same | `flutter build apk --debug --flavor dev` | exit 1: `Task 'assembleDevDebug' not found … You cannot use the --flavor option.` |
| P-B4 | + `productFlavors { dev; prod }` (same `applicationId`) | `flutter build apk --release` (no flavor) | **exit 1**: `compileFlutterBuildDevRelease` → `Failed to bundle asset files` |
| P-B4b | same | `flutter build apk --release --flavor prod` | exit 0, 59 s → `app-prod-release.apk`, `.env` 0 |
| P-B4c | same, dummy `.env` | `flutter build apk --debug --flavor dev` | exit 0 → `app-dev-debug.apk`, `flutter_assets/.env` 1 |
| P-B4d | same | `flutter build apk --debug` (no flavor) | **exit 1**: "Gradle build failed to produce an .apk file" (two APKs) |
| P-B4e | + `default-flavor: prod`, `env/prod.json` (https/wss `probe-host.example.org`) | `flutter build apk --release --dart-define-from-file=env/prod.json` | exit 0, 55 s, task `assembleProdRelease` → `app-prod-release.apk`; `.env` 0; `probe-host.example.org` 3 per `libapp.so`; `192.168.0.20` **0** |
| P-B7 | + `main.dart` without dotenv/dev branch, barrel without dev export, `env_config.dart` unchanged | same | `DEV_AUTH_` 0, `DevAuthTokenService` 0 (whole APK); `flutter_dotenv` 2 per `libapp.so` (from `env_config.dart`) |
| P-B8 | `tool/hardening_check.sh` (Code Examples) on the P-B7 APK / on today's APK | script | P-B7 APK: bundle checks pass; today's APK: `.env bundled`, `DEV_AUTH_ found`, `DevAuthTokenService found` |

Commands the user and the CI use (with the recommended mechanism):
- Dev on device (today's workflow, innkeeper bypass): `flutter run --flavor dev -t lib/main_dev.dart` (add `--dart-define-from-file=env/dev.json` only when `.env` lacks the URL keys: `.env` wins over dart-defines, `env_config.dart:8-12`).
- Prod entry in debug: `flutter run` (default flavor prod, `lib/main.dart`, no `.env`; needs dart-defines or defaults).
- Release (CI and UAT): `flutter build apk --release --dart-define-from-file=env/prod.json` → `build/app/outputs/flutter-apk/app-prod-release.apk`; UAT via tunnel: `flutter build apk --release --dart-define-from-file=<tunnel json>` then `adb install -r`, or `flutter run --release --dart-define-from-file=<tunnel json>`.
- `flutter test` is unaffected by flavors (probe: `city_test.dart` + `app_wiring_test.dart` green in the flavored copy; `flutter analyze` clean on the new `main.dart`).
- `main_dev.dart` should assert the flavor so a forgotten `--flavor dev` fails loudly instead of with a dotenv asset error: `assert(appFlavor == 'dev', 'Run with --flavor dev')` (`appFlavor` from `package:flutter/services.dart`, documented as null when no flavor is set) [CITED: docs.flutter.dev/deployment/flavors].

### F3. Release signing (D-03a) [VERIFIED: probe P-S1..P-S3]
Probed Kotlin DSL (in the scratch copy; compiles under AGP 8.9.1 / Kotlin 2.1.0):
```kotlin
import java.util.Properties

val releaseKeystoreFile = rootProject.file("key.properties")   // = android/key.properties
val releaseKeystore = Properties().apply {
    if (releaseKeystoreFile.exists()) releaseKeystoreFile.inputStream().use(::load)
}
val hasReleaseKeystore = releaseKeystoreFile.exists()

android {
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(releaseKeystore.getProperty("storeFile"))
                storePassword = releaseKeystore.getProperty("storePassword")
                keyAlias = releaseKeystore.getProperty("keyAlias")
                keyPassword = releaseKeystore.getProperty("keyPassword")
            }
        }
    }
    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                logger.quiet("WARNING: android/key.properties not found: the release build is signed with the DEBUG keys and cannot be published.")
                signingConfigs.getByName("debug")
            }
        }
    }
}
```
- P-S1 no file: build exit 0; `apksigner verify --print-certs` → `CN=Android Debug`. With `logger.warn` the line appears only under `flutter build -v` (the tool passes `-q` to Gradle, `flutter_tools/lib/src/android/gradle.dart:493-498`); with `logger.quiet` it is printed in the normal output (P-S2).
- P-S3 throwaway keystore + `key.properties` with an absolute `storeFile`: APK signed `CN=Probe Upload, O=Probe, C=IT`. `file(...)` resolves a relative `storeFile` from `android/app/`; the handoff should tell the user to write an absolute path.
- `keytool -printcert -jarfile` prints nothing (no v1 signature with this minSdk); verify with `~/Library/Android/sdk/build-tools/36.1.0/apksigner verify --print-certs <apk>` (needs `JAVA_HOME` = Android Studio JBR, no system Java on this Mac).
- Handoff command (macOS, no system Java): `"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/klimmeck-upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload` [CITED: docs.flutter.dev/deployment/android, keytool line]; then `android/key.properties` with `storePassword=…`, `keyPassword=…` (same value: PKCS12 keystores ignore a distinct key password [ASSUMED]), `keyAlias=upload`, `storeFile=/Users/<user>/klimmeck-upload-keystore.jks`.
- The `else` branch runs at configuration time, so the warning also prints on debug builds [ASSUMED: not probed]; acceptable, or guard with `gradle.startParameter.taskNames.any { it.contains("Release") }`.

### F4. TLS only in release (D-03b) [VERIFIED: codebase; CITED for dart:io]
- dart:io sockets do not honour Android's cleartext policy: the "insecure HTTP disabled by default" change shipped in Flutter 2.0 and was reverted in 2.2 [CITED: docs.flutter.dev/release/breaking-changes/network-policy-ios-android]; consistent with today's dev runs over `http://localhost:3000` with no `usesCleartextTraffic` in `AndroidManifest.xml`. So the refusal must be Dart-side; a manifest attribute alone would not stop it.
- Run it first in `bootstrapApp`, before `bootstrapPush()` and before the auth/GraphQL composition (no client is ever built with a cleartext URL). URLs to check: `EnvConfig.baseUrl` (login page `session_auth_token_service.dart:243-245` and REST), `graphqlHttpUrl`, `graphqlWsUrl`; Cloudinary is a compile-time https constant (`env_config.dart:114-117`).
- Shape: `static void requireSecureTransport({bool isRelease = kReleaseMode})` → in release throws `InsecureTransportError(List<String> offendingKeys)` when a URL scheme is not `https`/`wss`; in debug/profile returns after `appLog`. `kReleaseMode` is a const, so tests pass `isRelease: true/false` and set URLs through `installRuntimeOverrides` (the same seam) — both branches testable without builds.
- `--dart-define` URLs are compile-time `String.fromEnvironment` (`env_config.dart:24-37`); with no dart-define the defaults are `http://192.168.0.20…` → a release built without the file shows the fail-fast screen instead of talking cleartext (good failsafe; keep the defaults).
- `InsecureTransportScreen`: utility surface, no gameplay chrome; minimal `MaterialApp(theme: KlimmeckGuideTheme…, home: …)` with a centred text, no buttons, no network. Copy (Claude's discretion per CONTEXT): proposal «Questa versione dell'app non può collegarsi al server in modo sicuro. Installa una versione aggiornata.» (Open Question 4).
- `isDebug`/`enableLogging` (`env_config.dart:83,107-110`) have **no reader** outside `env_config.dart` (grep): `defaultValue: !kReleaseMode` is a const expression and valid; add `import 'package:flutter/foundation.dart'`.

### F5. Logging seam (D-03c) [VERIFIED: codebase grep]
- Inventory: **53 `debugPrint(` in 25 files** (`session_auth_token_service.dart` 8, `library_cubit.dart` 4, `dev_auth_token_service.dart` 4, `data_message_handler.dart` 3, `main.dart` 3, 2 each in `splash_cubit`, `notification_permission_cubit`, `notification_preferences_cubit`, `journal.dart`, `quest_cubit`, `session_sync_cubit`, `session_store`, `push_registration_coordinator`, `push_bootstrap`, `local_notifications_startup`, `graphql.dart`; 1 each in `cached_svg`, `main_screen_cubit`, `character_cubit`, `auth_cubit`, `auth_interceptor`, `url_launcher_link_opener`, `notification_tap_router`, `graphql_client_holder`, `image_warmer`) + **3 `print(`** (`journal_cubit.dart:23,32`, `world_map_cubit.dart:24` — these are the 3 lib `avoid_print` infos) + **1 `developer.log(`** (`sync_watchdog.dart:109`). Total 57 call sites in 28 files.
- Credential exposure: **none** — no log interpolates a token/bearer/jwt/authorization identifier (grep with `-A3` over every call, 0 hits). Auth logs already print only `${error.runtimeType}`. Residual risk is `$e` of an `OperationException`/`DioException` (`library_cubit.dart:41,102,121,130`, `main_screen_cubit.dart:65`, `cached_svg.dart:61`, `main.dart:237,262`, the 3 `print`s): no header in their `toString`, but switch them to `${e.runtimeType}` while routing (Boy Scout). No `LogInterceptor` on dio (`rest_client_provider.dart:25` adds only the auth interceptor).
- `debugPrint` is NOT silent in release (only throttled), so routing is real work.
- Design (pure function testable on both branches):
```dart
// lib/utils/app_log.dart
typedef AppLogSink = void Function(String message);

void appLog(String message) =>
    appLogWith(message, isRelease: kReleaseMode, sink: debugPrint);

@visibleForTesting
void appLogWith(String message, {required bool isRelease, required AppLogSink sink}) {
  if (isRelease) return;
  sink(message);
}
```
- Guard (in `tool/hardening_check.sh`): no `debugPrint(`, bare `print(`, `developer.log(` outside `lib/utils/app_log.dart`; no `appLog(`/`debugPrint(` within 3 lines of a `${…token|bearer|jwt|authorization|password|secret}` interpolation (case-insensitive initial).

### F6. Leak test (D-05, HARDEN-05) — probes P-L0..P-L6 [VERIFIED: probe]
Probe file `test/_probes/leak_probe_test.dart` in the scratch copy, one test per run (`--plain-name`), `LeakTesting.enable()` in `main()`, `experimentalLeakTesting: LeakTesting.settings.withTrackedAll()`:

| Probe | Scenario | Result |
|-------|----------|--------|
| P-L0 | `forceGC` imported from `leak_tracker_flutter_testing` | compile error `Method not found: 'forceGC'` → import `package:leak_tracker/leak_tracker.dart` |
| P-L1 | `ValueNotifier` created in a `State`, never disposed | **FAIL** `notDisposed` ("contains leaks") — tracking works |
| P-L2 | `Cubit` never closed, no observer | **PASS** — cubits are invisible to leak_tracker |
| P-L3 | `Cubit` never closed, `BlocObserver` dispatching `LeakTracking.dispatchObjectCreated(library:, className:, object: bloc)` in `onCreate` and `dispatchObjectDisposed(object: bloc)` in `onClose` | **FAIL** `notDisposed` — mechanism works |
| P-L4 | same observer, cubit closed in `dispose` | PASS |
| P-L5 | closed cubit retained in a static list, `withTracked(experimentalAllNotGCed: true)` | PASS (notGCed not detected within `testWidgets`) → do not rely on it |
| P-L6 | `WeakReference` to a released closed cubit + one retained; `await tester.runAsync(() => forceGC(fullGcCycles: 3, timeout: 10 s))` | released `target == null`, retained `target != null` — deterministic |

Recommended mechanism for `test/screens/auth/authenticated_shell_leak_test.dart`:
1. `LeakTesting.enable()` in this file's `main()` only (no global `flutter_test_config.dart`: today none exists and enabling it suite-wide would turn every framework leak in 336 files into a failure).
2. `setUp`: save `Bloc.observer`, install `LeakTrackingBlocObserver` (Wave 0 helper); `tearDown`: restore it.
3. Pump `AuthGate` (real) driven by a `MockAuthCubit` + `StreamController<AuthState>` (`whenListen`), `authenticatedBuilder` → `SessionSyncScope` + `SessionHome` + `AuthenticatedShell` with `MockKlimmeckGraphQl` whose `subscribeTo*` return `StreamController.broadcast(onListen/onCancel)` streams, `FakePushMessagingPort`, and a `mainScreenBuilder` that records only `WeakReference`s of the cubits it reads (no strong refs in the test).
4. Emit `AuthUnauthenticated()` → pump → assert: every controller `hasListener == false` (subscriptions cancelled), SignInScreen shown, then `await tester.runAsync(() => forceGC(fullGcCycles: 3, timeout: …))` and every `WeakReference.target == null`; leak_tracker fails the test at its end on any cubit created and never closed.
5. WS link: **not** in this widget test — `FakeGraphQlWsServer` is `test(...)`-only (HttpOverrides of `testWidgets` block `WebSocket.connect`, see its doc `fake_graphql_ws_server.dart:5-9`). Proven in the logout flow test (F9): after `logout()` the server-side socket is closed, `holder.client.value` is a new instance, and a `WeakReference` to the old `GraphQLClient` is cleared after `forceGC`.
6. If a framework object shows up as a leak (none expected with the stub main screen), `withIgnored(classes: [...])` with a comment naming the class; never `withIgnoredAll()`.

### F7. Dual-session revocation (D-06, D-09, D-12) [VERIFIED: codebase]
Code path from the BE contract to the notice, and the exact edits:
1. WS close `4409` → `SocketClient.onConnectionLost` reads `closeCode`/`closeReason` (`graphql-5.2.1 …/websocket_client.dart:373-375`) → `WsReconnectPolicy.onConnectionLost(code, reason)` (`ws_reconnect_policy.dart:63-72`): add `wsSessionRevokedCloseCode = 4409` to `authRejectedCloseCodes` (`:29`). The close reason does not need parsing: the refresh refusal is authoritative.
2. `_recoverSession` → `recoverFromUnauthorized(rejectedToken: _lastSentToken)` (`session_auth_token_service.dart:217-229`): the revoked device's JWT is still the current one, so it reaches `_refreshSingleFlight()` (if a rotation raced the close, it returns the rotated token, the reconnect hits `4409` at `connection_init`, and the next round refreshes — converges).
3. BE answers `SESSION_REVOKED` + `extensions.reason` → `mapAuthOperationException` (`auth_api_exception.dart:59-74`) → `SessionRejected(code!)` (`:68`): parse `reason` from the **same** error that carried the code (today `_firstCode` `:76-82` returns only the string) → `SessionRejected(code, reason: …)`; add `reason` to `props` (null-reason equality keeps `graphql_backend_auth_api_test.dart:114-120` green). Honour `reason` only when `code == SESSION_REVOKED` (BE: `SESSION_EXPIRED` carries none).
4. `_rotateSession` catches `SessionRejected` and calls `_endSession(UnauthenticatedReason.sessionExpired)` (`session_auth_token_service.dart:368-371`) → map: `newLogin` → `replacedByNewLogin`, `roleChanged` → `roleChanged`, anything else/null → `sessionExpired`. Cold start (`_attemptBootstrap` `:309-322`) and proactive refresh (`:429-444`) go through the same `_rotateSession`, so a revoked device that was offline gets the notice too. `handleRevocation()` (`:181-182`) stays `sessionExpired`; `_backendLogoutToken` (`:504-517`) is outside the single flight and ignores reasons (logout wins).
5. `AuthUnauthenticated(reason:)` → `AuthGate._noticeFor` (`auth_gate.dart:59-64`, exhaustive switch: the new enum values are a compile error until mapped — good) → `SignInNotice` (`sign_in_screen.dart:20`) → copy (`:28-31`, new constants beside `:9-10`). `_shouldRebuild` (`auth_gate.dart:80-86`) already rebuilds on a reason change.
6. Teardown: `_endSession` → `onSessionTeardown` = `GraphQLClientHolder.reset()` (disposes the link, `graphql_client_holder.dart:43-54`) → no reconnect loop after the revocation.

Dual-session harness (`test/repository/services/auth/dual_session_revocation_test.dart`, `test(...)` only, real time, no `fakeAsync` because the loopback socket needs real IO):
- Wave 0 `FakeSessionBackend implements BackendAuthApi` (shared by both devices): `exchangeLoginTicket` creates session N for the user and revokes the others with `newLogin`, calling back `onRevoked(sessionId, reason)`; `refreshSession(revoked)` throws `SessionRejected(sessionRevokedCode, reason: 'newLogin')`; tokens from `buildTestJwt`/`buildAuthSession` (`test/helpers/auth_session_fixtures.dart`).
- Wave 0 `FakeGraphQlWsServer` extensions (today `dropWith(int code)` always closes `sockets.last` with reason `'test'`, `fake_graphql_ws_server.dart:77`): `closeSocket(WebSocket ws, int code, String reason)`, and an `onConnectionInit(ws, payload)` hook (today `connection_init` is always acked, `:37-38`) so the fake can map the bearer to a session and close a revoked `connection_init` with `4409`.
- Each device: `SessionAuthTokenService(api: backend, store: InMemorySessionStore(), browser: MockBrowserAuthenticator → 'klimmeck://auth?ticket=…', onSessionTeardown: holder.reset)` + a `GraphQLClientHolder(connect: …buildWebSocketLink(url: server.url, policy: WsReconnectPolicy(authService:, recovery:)))` + one live subscription.
- Cases: (a) device B logs in → server closes A's socket `4409 newLogin` → A emits `AuthUnauthenticated(replacedByNewLogin)` exactly once, A's store empty, A's holder recreated, B still authenticated and its socket open; (b) A offline at revocation, reconnects → `connection_init` closed `4409` → same end; (c) `roleChanged` → `roleChanged`; (d) unknown reason / no reason → `sessionExpired`; (e) no hot loop: count `connection_init` frames from A after the teardown (= 0). Await state streams with `emitsThrough`, never `Future.delayed` (testing rule).
- A service-level `fakeAsync` companion in `session_auth_token_service_revocation_test.dart` covers the HTTP-only path (proactive refresh refused with `newLogin` after 14 min).

### F8. Identity transitions (D-11) [VERIFIED: codebase]
Above the `user.id` key (`main.dart:268-371`, `_KlimmeckGuideAppState` fields `:152-182`): `AppLifecycleBridge`/`_lifecycleBus` (process-wide), `KlimmeckRest`/`KlimmeckGraphQl` (stateless; `graphQl` resolves `holder.client.value` each call), `notificationPreferencesStore`/`libraryBookmarksStore` (keyed by user/character id per call), `_pushCoordinator` (tracks `_sessionUserId`, handles a user change, `push_registration_coordinator.dart:89-91`), `NotificationIntentCubit`, `NotificationTapRouter`, `AuthCubit`, `SplashCubit` (image preload state, not per user), `GraphQLProvider`. Under the key: `SessionSyncScope` (per user), `SessionHome` keyed `character:<id>` → creation page or `AuthenticatedShell`.
- Gap candidate (for the D-14 reviewers, not fixed blindly): `NotificationIntentCubit._onAuthState` (`notification_intent_cubit.dart:37-43`) clears a pending tap only on `Authenticated → Unauthenticated` or on the creation page; a direct `Authenticated(A) → Authenticated(B)` (only reachable through a refresh that changes identity, `session_auth_token_service.dart:417-422`) keeps A's pending intent for B. Low likelihood; a one-line rule (`previous.user.id != next.user.id` → clear) with a test.
- Existing coverage: `auth_gate_test.dart:190` (account switch disposes subtree), `:207`, `:248`, `:303-405` (character change group), `session_home_test.dart:100,119,183,201`. Missing: the cross-device sequence through the real `SessionSyncCubit` (`userUpdated` with `currentCharacter: null` → creation page with a fresh `CharacterCreationCubit` → `userUpdated` with a new character id → new shell, previous cubits closed, root dialogs closed). New file `test/screens/auth/identity_transitions_test.dart`: `SessionSyncScope` + `AuthGate` + `SessionHome` over a fake `AuthTokenService` whose `adoptUser` re-emits `AuthAuthenticated` (the real path: `session_sync_cubit.dart:141`), a `StreamController` behind `MockKlimmeckGraphQl.subscribeToUser`, fixtures `buildTestUserWithCharacter()` / a user with `currentCharacter: null` / a user with a new character id (`test/helpers/auth_fixtures.dart`).

### F9. HARDEN-03/04 audit (D-08) [VERIFIED: codebase]
| Step (Phase 11 D-12/D-36, D-06) | Asserted today | Missing |
|---|---|---|
| Push unregister before logout, 2 s cap | `auth_cubit_test.dart:185,189,194,215,226` | — |
| Backend `logout` best-effort, bounded | `session_auth_token_service_logout_test.dart:132,172,186` | — |
| Expired access refreshed before backend logout (D-36) | `logout_test.dart:209,227,248,273` | — |
| Teardown (subscriptions, client) before storage clear, then `signedOut` | `logout_test.dart:149` (order with a mocked hook) | real hook: socket closed + client recreated |
| `GraphQLClient` + `WebSocketLink` recreated | `graphql_client_holder_test.dart:65,78,91,110,121` (isolated) | in the same flow as the logout |
| Secure storage cleared | `logout_test.dart:149` (`InMemorySessionStore`) | — |
| Cubits reset / subscriptions cancelled | `authenticated_shell_test.dart` "closes them on removal" groups (isolated, cubit `isClosed`) | after a real `AuthUnauthenticated` → F6 leak test |
| Navigation to sign-in | `auth_gate_test.dart:111` | in the flow → F6 leak test asserts `SignInScreen` |
| Overlapping logout shares one teardown | `logout_test.dart:292,324` | — |
| Single-flight refresh (service) | `session_auth_token_service_refresh_test.dart:141`, `_revocation_test.dart:129` | — |
| Two concurrent 401 through the links → 1 refresh, retries, no logout | not covered | `AuthAuthLink` + dio `AuthInterceptor` on one real service |

New tests: `test/repository/services/auth/logout_flow_test.dart` (`test(...)`, loopback): real `SessionAuthTokenService` (Mock `BackendAuthApi`, `InMemorySessionStore`), real `GraphQLClientHolder` on `FakeGraphQlWsServer`, real `AuthCubit(pushCleanup: MockPushSessionCleanup)`, one live subscription; a shared `events` list records `unregister`, `api.logout`, server-side socket close (`ws.done`), `store.clear`, state emissions; assert the order and that the subscription stream is done and `holder.client.value` changed. `test/repository/services/auth/concurrent_unauthorized_refresh_test.dart`: `MockBackendAuthApi.refreshSession` held on a `Completer`, one GraphQL request through `AuthAuthLink` and one dio request through `AuthInterceptor` both answered 401/`UNAUTHENTICATED` → complete → `verify(() => api.refreshSession(any())).called(1)`, both retried with the new token, no `AuthUnauthenticated` emitted.

### F10. CI (D-07) [VERIFIED: local measurements]
- Local: `flutter test` = **86 s, 3565 tests, 336 files, all green** (2026-11-09); release build 55–103 s (103 s with a warm Gradle cache but a new APK, 55 s in the copy); CI runners are slower — budget ~4 min tests + ~6 min first release build [ASSUMED].
- `flutter analyze` today: 0 error, 0 warning, 50 info (48 `avoid_print`: 45 in `tools/*.dart`, 3 in `lib/`; 2 `depend_on_referenced_packages` in `profile_cubit.dart`) and it **exits 1 on infos**; `flutter analyze --no-fatal-infos` exits 0 (probed). Use that (warnings stay fatal by default) instead of counting lines.
- CI has no `.env`, `google-services.json`, `key.properties`: P-B2..P-B4e show the release build then needs the flavored asset (else it fails), passes the missing `google-services.json` with the WARN strategy (`build.gradle.kts:48-50`, probe builds had no file) and signs with debug keys (P-S1).
- `FakeGraphQlWsServer` binds `127.0.0.1:0`: works on GitHub runners [ASSUMED]. Fonts: tests disable runtime fetching (`test/helpers/test_app.dart:10`), no network needed.
- `tool/schema_check` stays local (needs the BE SDL), per D-07.

### F11. Follow-ups (D-13) [VERIFIED: codebase + BE read]
(a) `BAD_USER_INPUT` — classifier per enum (function line / default `_ =>` line), message path:
| Enum (file) | Classifier | Already maps? | Message / reaction path |
|---|---|---|---|
| `TransactionFailure` (`transaction_failure.dart`) | `:47` / `:67` | no | `shop/transactionCubit/transaction_notice.dart` (`transactionNoticeFor` `:8-14`, `shopkeeperRefusalLine` `:22`) |
| `TravelFailure` (`travel_failure.dart`) | `:58` / `:74` | no | `travelCubit/travel_notice.dart:27`, `questTravelPreviewCubit` |
| `QuestAcceptanceFailure` | `:56` / `:77` | no | `questAcceptanceCubit/quest_acceptance_notice.dart:42` |
| `QuestAbandonFailure` | `:32` / `:42` | no | `questAbandonCubit/quest_abandon_notice.dart:15` |
| `QuestResultFailure` | `:28` / `:37` | no | `questResultsCubit/quest_result_notice.dart` (`_ => null`: silent today) |
| `PetEquipFailure` | `:42` / `:53` | **yes** (`:51`) | `companionCubit/companion_notice.dart:26` = generic «Qualcosa è andato storto, riprova» |
| `InnkeeperFailure` | `:43` / `:55` | no | `innkeeper/request_completion_screen.dart:86-88` (`_ => null`: stays in the form), teleport chip |
| `CharacterCreationFailure` | `:36` / `:56` (own parser incl. HTTP 400) | no | `characterCreation/components/character_creation_messages.dart:26-43` |
| `CharacterDeletionFailure` | `:30` / `:40` | no | `settings/components/character_deletion_messages.dart:11` |
| `PushDeviceFailure` | `:31` / `:40` | no | silent; **`isRetryable` (`:18`) treats `unknown` as retryable → today a `BAD_USER_INPUT` on register is retried with backoff forever** — mapping it to a non-retryable value is a real fix |
| `SpellEquipFailure` | `:51` / `:65` | **yes** (`:63`) | `spellsCubit/spell_notice.dart:39` = generic copy |

Blind spot: `graphQlErrorCode` (`graphql_error_code.dart:15-29`) reads `graphqlErrors` and WS `SubscriptionError`, **not** `ServerException.parsedResponse.errors`. A GraphQL error with HTTP status ≥ 300 (gql_http_link throws, `link.dart:89-95`) reaches the 10 classifiers as `code == null && linkException != null` → `connection`. `CharacterCreationFailure` already reads `parsedResponse` (`character_creation_failure.dart:39-43`, pinned by `character_creation_failure_test.dart:57-60` "HTTP 400 parsedResponse path"), i.e. the 400 shape was observed. The BE `BadUserInputException extends BadRequestException` with `statusCode: 400` in its body (`Klimmeck-Guide-BE/src/validation/bad-user-input.exception.ts`); whether the GraphQL HTTP status is 200 or 400 for resolver-thrown errors was not verified here → recommend teaching `graphQlErrorCode` the `parsedResponse` path once (one change, all classifiers benefit; keeps the `connection` fallback when no code is found) — Open Question 3.

(b) Moderation (exact BE strings, `src/moderation/image-moderation.exceptions.ts:3-4`): `IMAGE_REJECTED` = REST 422 `{statusCode, code: 'IMAGE_REJECTED', message: 'Immagine non ammessa', reasons}`; `IMAGE_MODERATION_UNAVAILABLE` = REST 503 `{statusCode, code, message}`; thrown by `POST /cloudinary/uploadImage` (`portrait-upload.service.ts:25`, `sightengine-image.moderator.ts:127-129`). FE path: `CharacterCreationCubit.submit` (`character_creation_cubit.dart:79-84`) → `_uploadedPortraitUrl` (`:114-128`) → `CharacterCreationRepository.uploadPortrait` (`character_creation_repository.dart:36-52`) which today maps every `DioException` to `uploadFailed` (`:44-47`): read `error.response?.data` (`Map` with `code`) there → `CharacterCreationFailure.imageRejected` / `.moderationUnavailable`. Cubit: on `imageRejected` clear `portraitPath` + `uploadedPortrait` (forces a new pick; draft kept); on `moderationUnavailable` keep everything (retry or remove the portrait — `imagePath` is optional). BE handoff copy (BE Phase 10 `BACKEND-NOTES.md:75-76`): «Immagine non ammessa, scegline un'altra», «Riprova o procedi senza immagine».

(c) `City.size` — usages of the FE map: `city_markers_layer.dart:51-60` (`city.type?.cityClass` → visibility per zoom), `:36` + `:64-66` (`city.type!.size` → scale), `city_marker.dart:27-28` (`type!.size` → width/height). `City.size` is parsed leniently (`city.dart:27,53`; `city_test.dart:7-25`), the `cities` document already selects it (registry unchanged). Today's pixel sizes by class (`city_type.dart:5-37`): capitals 39–70 (mean 55.5; `valanCapital` 70, `talmvereVillage` 39, `elfCapital` 46), cities 40–45 (mean 43.3), villages 30–34 (mean 30.9). Proposed table (keeps the per-class means): `CitySizeType.capital → 56`, `city → 43`, `village → 31`; `null` size → hidden (today a null type is hidden, `:58-59`). Visible deltas: `valanCapital` 70→56, `talmvereVillage` 39→56 (a "village" image with capital class), `elfCapital` 46→56 — Open Question 5. Probe P-M1: switching the visibility to `city.size` turns **2 tests RED** (`world_map_teleport_test.dart:110,122`) because the fixtures `cityA`/`cityB` (`world_map_travel_test.dart:47-56,58-67`) carry `'type'` but no `'size'`; fix = add `'size': 'capital'` to those fixtures (and `character_marker_layer_test.dart:36,47` for consistency).

### F12. Evidence-only items
- HARDEN-02: FE handoff/VERIFICATION cites the BE Phase 17 matrix spec path from the BE `BACKEND-NOTES.md` §2 (D-09) once merged.
- Gate today: `git -C <BE> show origin/develop:src/auth/session/session-revoke-reason.enum.ts` → `fatal: path … does not exist in 'origin/develop'` (2026-11-09): the contract-gated plans park, as planned.

### F13. Device UAT prerequisites (D-04, D-06) [VERIFIED: codebase/BE `.env.example`; tools probed]
- Login chain: app opens `EnvConfig.baseUrl` + `auth/twitch/start?challenge=…` (`session_auth_token_service.dart:242-256`) in the system browser (`flutter_web_auth_2`) → BE redirects to Twitch with `redirect_uri = TWITCH_REDIRECT_URI` (BE `.env.example:33`, default `http://localhost:3000/auth/twitch/callback`) → BE callback → `APP_AUTH_REDIRECT_URL=klimmeck://auth` (BE `.env.example:41`) → `CallbackActivity` (`AndroidManifest.xml:39`, scheme `klimmeck`, host `auth`). So for the release UAT the BE env `TWITCH_REDIRECT_URI` must become `https://<tunnel-host>/auth/twitch/callback`, the same URL must be in the Twitch app's OAuth Redirect URLs (Twitch accepts several), and the BE must be restarted; a quick tunnel changes host at every start → prefer a named tunnel (stable host). `klimmeck://auth` is host-independent.
- Through a tunnel every request comes from the tunnel process: the BE throttler keys by IP unless `THROTTLE_TRUST_PROXY` is set (BE `.env.example:112`); the two UAT devices share the limit [ASSUMED impact; note in the sheet].
- `cloudflared` and `ngrok` are **not installed** (`command -v` empty): `brew install cloudflared` is a user prerequisite. cloudflared tunnels carry WebSockets [ASSUMED].
- Emulator: AVDs `Medium_Phone` (API 36.1) and `Pixel_9`, system images `android-36` and `android-36.1` `google_apis_playstore` installed — use a Play Store image (Chrome Custom Tabs for the login, FCM). For the dev-flavor dual-device steps both devices can reach `localhost:3000` through `adb -s <serial> reverse tcp:3000 tcp:3000` (works for emulators too [ASSUMED]); the release steps use the tunnel. The FE `.env` must have `DEV_AUTH_ENABLED=false` for the real login with the dev entry point.
- DevTools memory snapshot needs a debug/profile build (not release): `flutter run --profile --flavor dev -t lib/main_dev.dart`, DevTools → Memory → snapshot before/after logout, screenshots.
- Same `applicationId` for dev and prod flavors (google-services.json has one client): switching between a debug-signed dev build and a release-signed prod build on the same phone fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE` → `adb uninstall it.lordreavor.klimmeckguide.klimmeck_guide` between them (secure storage wiped → re-login) [ASSUMED: standard Android behaviour].

### Anti-Patterns to Avoid
- Gating the bundle with `grep -a` on the compressed APK or on `AssetManifest*` (C-3): proves nothing for `.env`.
- Keeping `flutter_dotenv` in `env_config.dart` "because tree-shaking removes it": it does not (P-B7), the URL getters reach it.
- Enabling `LeakTesting` in a global `flutter_test_config.dart`.
- Proving subscription cancellation with `Future.delayed`; use `hasListener`/`onCancel` counters and `emitsThrough`.
- Inferring a revocation from a 401 (JWT stays valid 15 min): only `SESSION_REVOKED` on refresh or the `4409` close.
- Parsing the WS close reason into a notice: the refresh refusal is the single source.
- Adding `applicationIdSuffix ".dev"` to the dev flavor: google-services.json has no client for it (the google-services plugin fails on a package mismatch) [ASSUMED: plugin behaviour].
- Literal gate strings (`DEV_AUTH_`, `DevAuthTokenService`, `flutter_dotenv`) in comments of `lib/main.dart` / `lib/bootstrap/app_bootstrap.dart` / `session_auth_composition.dart`.

## Pinned tests to update RED first
| File:line | Pin | Change |
|---|---|---|
| `test/config/env_config_backend_urls_test.dart:1,8-18,22,28,36` | values via `dotenv.loadFromString` | RED once `EnvConfig` stops reading dotenv → `installRuntimeOverrides` + reset in `tearDown` |
| `test/config/env_config_test.dart:9,15,21` | `devAuthEnabled` via `loadTestEnv` (dotenv) | RED → `loadTestEnv` also installs overrides (`test/helpers/fixtures/dev_auth_env.dart:15-25`) |
| `test/config/env_config_uninitialized_test.dart:7-11` | defaults without dotenv | stays green; rename to "without runtime overrides" |
| `test/repository/services/rest/rest_upload_test.dart:4,18` | `dotenv.loadFromString(BASE_URL)` | stays green (asserts only the path `:45`); switch to overrides (Boy Scout) |
| `test/repository/services/push/push_boundaries_test.dart:45-49` | `_promptFreeFiles` = `lib/main.dart`, … | green but loses coverage when `KlimmeckGuideApp` moves → add `lib/main_dev.dart`, `lib/bootstrap/app_bootstrap.dart`, `lib/bootstrap/klimmeck_guide_app.dart` |
| `test/repository/character_creation_failure_test.dart:35-38,58-61` | "BAD_USER_INPUT maps to unknown" (GraphQL and HTTP 400) | RED under D-13a → maps to `badUserInput` |
| `test/screens/mainScreen/tabs/journal/spellsCubit/spell_notice_test.dart:47` | `badUserInput` → «Qualcosa è andato storto, riprova» | RED only if the in-world copy replaces the generic one (Open Question 2) |
| `test/screens/mainScreen/tabs/journal/companionCubit/companion_notice_test.dart:70-80` | same for `PetEquipFailure.badUserInput` | same |
| `test/screens/mainScreen/tabs/map/world_map_teleport_test.dart:110,122` | city markers visible with `type` only | **RED (probe P-M1)** → fixtures in `world_map_travel_test.dart:47-67` gain `'size': 'capital'` |
| `test/repository/services/auth/graphql_backend_auth_api_test.dart:114-120` | `SessionRejected(code)` equality | stays green (null reason); add reason cases |
| `test/screens/auth/auth_gate_test.dart`, `test/screens/signIn/sign_in_screen_test.dart:140` | exhaustive notice mapping | green; add cases for the two new notices |
| `test/repository/services/graphql/ws_reconnect_policy_test.dart:7-8,76,95` | 4401/4403 recovery | green; add 4409 |
| `test/helpers/fakes/fake_graphql_ws_server.dart:75-77` | doc "Usare 4401/4403/1001" | update with 4409 and the new `closeSocket` |

## Don't Hand-Roll
| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Excluding `.env` from release | build-time copy scripts / CI placeholder files | pubspec asset `flavors:` + Android product flavors + `default-flavor` | probed end to end; works on the developer's own release builds too |
| Detecting unclosed cubits | custom registries in production code | test-only `BlocObserver` → `LeakTracking.dispatchObjectCreated/Disposed` | leak_tracker reports, no production change |
| Detecting retention | sleeps + `isClosed` checks | `WeakReference` + `forceGC` (`leak_tracker`) | deterministic (P-L6) |
| Release signing | signing in CI secrets now | `key.properties` + debug fallback | D-03a; store upload is out of scope |
| Log silencing | `if (kDebugMode)` at 57 call sites | one `appLog` | single guard, single grep |

## Runtime State Inventory
| Category | Items Found | Action Required |
|----------|-------------|-----------------|
| Stored data | Secure storage refresh token + `shared_preferences` first-launch marker (`session_store.dart:85`); no key renamed by this phase | none |
| Live service config | Twitch app OAuth Redirect URLs and BE env `TWITCH_REDIRECT_URI` (outside git) must gain the tunnel URL for the release UAT | manual, user (UAT sheet) |
| OS-registered state | Installed app on the Samsung/emulator: same `applicationId`, different signing between dev-debug and prod-release builds | `adb uninstall` between them (UAT sheet) |
| Secrets/env vars | Developer `.env` keeps every key; it is no longer read by the prod entry; `android/key.properties` + keystore created by the user | handoff steps |
| Build artifacts | `build/app/outputs/flutter-apk/app-release.apk` path disappears (becomes `app-prod-release.apk`); IDE run configurations (`.idea/`) that launch `lib/main.dart` without a flavor now get the prod flavor | update any script/run config that expects the old path or runs the dev bypass without `--flavor dev` |

## Conflicts
- **C-1 (D-01 / REPO-RULES "Device UATs run with `flutter run -t lib/main_dev.dart`"):** with the only verified mechanism that keeps D-01's "loads `.env` through flutter_dotenv", the dev run needs `--flavor dev`: `flutter run --flavor dev -t lib/main_dev.dart`. Fix: amend the command in the REPO-RULES and the UAT sheet; `main_dev.dart` asserts `appFlavor == 'dev'`.
- **C-2 (REPO-RULES gate path `build/app/outputs/flutter-apk/app-release.apk`):** with product flavors the APK is `app-prod-release.apk` (P-B4b/P-B4e). Fix: gate and CI use `app-prod-release.apk`.
- **C-3 (REPO-RULES bundle gate):** `grep -c -a DEV_AUTH_ <apk>` misses deflated entries (P-B0: 0 with `.env` inside) and `unzip -p <apk> 'assets/flutter_assets/AssetManifest*' | grep -c DEV_AUTH_` is always 0. Fix: `unzip -l <apk> | grep -c 'flutter_assets/\.env$'` = 0, `unzip -p <apk> | grep -a -c DEV_AUTH_` = 0, `unzip -p <apk> | grep -a -c DevAuthTokenService` = 0 (do not gate `flutter_dotenv` on the APK: it stays a dependency of the dev entry, and the prod `libapp.so` sheds it only through the seam of F1 — gate it in the source instead).
- **C-4 (REPO-RULES "No other new copy without the orchestrator's go" vs D-13a/b):** in-world `BAD_USER_INPUT` lines for up to 11 enums and the two moderation messages are new copy. Fix: the orchestrator approves a copy table at plan time (Open Question 2); the BE handoff already suggests the moderation lines.
- **C-5 (D-05 / REPO-RULES "the leak test … fails on any retained … WS link"):** the WS link cannot be exercised in `testWidgets`. Fix: the leak test covers cubits and subscriptions; the WS link retention is asserted in `logout_flow_test.dart` (`test(...)`, loopback, `WeakReference` + `forceGC` on the old client/link).
- **C-6 (D-13a "SpellEquipFailure already maps it"):** `PetEquipFailure` maps it too (`pet_equip_failure.dart:51`), and both render the generic «Qualcosa è andato storto, riprova» — "never the generic error" is not met by the two "already done" enums. Fix: include them in the copy table (Open Question 2).
- **C-7 (REPO-RULES env files):** `env/prod.json` must hold https/wss URLs, but no production backend exists ("Nothing new is deployed", D-04). Fix: Open Question 1.

## Common Pitfalls
### Pitfall 1: Forgetting `--flavor dev`
**What goes wrong:** `flutter run -t lib/main_dev.dart` builds the prod flavor (default), `.env` is not bundled, `dotenv.load` throws at start. **Avoid:** `assert(appFlavor == 'dev')` first in `main_dev.dart`; UAT sheet commands with the flag.
### Pitfall 2: No-flavor Gradle tasks after adding product flavors
**What goes wrong:** without `default-flavor`, `flutter build apk --release` builds `devRelease` and fails without `.env` (P-B4); debug builds "fail to produce an .apk" (P-B4d). **Avoid:** `default-flavor: prod` in the same commit as `productFlavors`.
### Pitfall 3: Silent signing warning
**What goes wrong:** `logger.warn` is swallowed by `-q`. **Avoid:** `logger.quiet` (P-S2).
### Pitfall 4: Barrel re-export keeps the dev service in the prod graph
**Avoid:** drop `export 'dev_auth_token_service.dart'` from `auth.dart:7` in the entry-split commit; the guard script checks it.
### Pitfall 5: Global `Bloc.observer` bleeding across tests
**Avoid:** save/restore in `setUp`/`tearDown`; mocktail `MockCubit` never calls `onCreate`, real cubits do.
### Pitfall 6: Strong references kill the GC proof
**What goes wrong:** a `late CharacterCubit cubit` captured by the test keeps it alive → `WeakReference.target` never null. **Avoid:** capture only `WeakReference`s; no `Finder` results stored across the logout.
### Pitfall 7: `forceGC` inside the fake-async zone
**Avoid:** always `await tester.runAsync(() => forceGC(...))` in `testWidgets` (P-L6); a timeout bounds it.
### Pitfall 8: Reason honoured on `SESSION_EXPIRED`
**Avoid:** map `reason` only when `code == sessionRevokedCode`; unknown → `sessionExpired` (D-12 leniency).
### Pitfall 9: `flutter analyze` exit code in CI
**What goes wrong:** exits 1 on the 50 baseline infos. **Avoid:** `flutter analyze --no-fatal-infos`.
### Pitfall 10: Dual-session test flakiness
**What goes wrong:** real sockets + real timers; `authRetryDelay` 500 ms and backoff. **Avoid:** await `authStateStream` with `emitsThrough` and server-side `ws.done`; generous per-test `Timeout(Duration(seconds: 20))`; never `Future.delayed`.
### Pitfall 11: Formatter
Files this phase touches that already fail `dart format --set-exit-if-changed` (checked one by one, 2026-11-09): `lib/models/enums/city_type.dart`, `lib/screens/mainScreen/tabs/journal/journal.dart`, `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart`, `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart`. Every other candidate checked is clean (`main.dart`, `env_config.dart`, the auth files, `ws_reconnect_policy.dart`, `graphql_error_code.dart`, `auth_gate.dart`, `sign_in_screen.dart`, the 11 `*_failure.dart`, every other file with a `debugPrint`/`print` call, `city.dart`, `city_marker.dart`, `character_creation_repository.dart`, the creation cubit files, and the pinned tests above).
### Pitfall 12: Copy of `.env` keys into dart-define JSON
`env/*.json` must never receive `DEV_AUTH_*` keys (the prod bundle grep would catch a define compiled into a reachable getter, but not one compiled into an unreachable one) — keep them URL-only.

## Code Examples
### `tool/hardening_check.sh` (probed: syntax OK; on today's tree it reports 8 failures, on the P-B7 APK the bundle checks pass)
```bash
#!/usr/bin/env bash
# Phase 12 guard greps (HARDEN-01, HARDEN-07, D-03c). Usage: tool/hardening_check.sh [path/to/app-prod-release.apk]
set -uo pipefail
cd "$(dirname "$0")/.." || exit 2
failures=0
fail() { echo "FAIL: $1"; failures=$((failures + 1)); }

for f in lib/main.dart lib/bootstrap/app_bootstrap.dart lib/bootstrap/session_auth_composition.dart; do
  [ -f "$f" ] || { fail "$f missing"; continue; }
  grep -nE 'DEV_AUTH_|DevAuthTokenService|dev_auth_token_service|dev_auth_composition|flutter_dotenv' "$f" && fail "$f references the dev bypass"
done
grep -n "export 'dev_auth_token_service.dart'" lib/repository/services/auth/auth.dart && fail "the auth barrel re-exports the dev bypass"
grep -n 'flutter_dotenv' lib/config/env_config.dart && fail "env_config imports flutter_dotenv"

allowed='lib/repository/cache/cache_expiry.dart|lib/repository/storage/(storage_manager|active_user_store|device_identity_store|notification_preferences_store|library_bookmarks_store|session_store)\.dart'
grep -rlE '\.set(String|StringList|Bool|Int|Double)\(' lib --include='*.dart' | grep -vE "^($allowed)$" | while read -r f; do echo "FAIL: $f writes SharedPreferences outside the allow-list"; done | grep . && failures=$((failures + 1))
grep -rnE '\.set(String|StringList)\(' lib --include='*.dart' | grep -iE 'token|jwt|bearer|secret' && fail "a SharedPreferences write mentions a token"

grep -rnE '(^|[^A-Za-z_])(debugPrint|print)\(|developer\.log\(' lib --include='*.dart' | grep -v '^lib/utils/app_log.dart:' && fail "log call outside lib/utils/app_log.dart"
grep -rn -A3 -E '(appLog|debugPrint)\(' lib --include='*.dart' | grep -E '\$\{?[A-Za-z_.]*([Tt]oken|[Bb]earer|[Jj]wt|[Aa]uthorization|[Pp]assword|[Ss]ecret)' && fail "a log call interpolates a credential"

if [ $# -ge 1 ]; then
  apk="$1"
  if [ -f "$apk" ]; then
    [ "$(unzip -l "$apk" | grep -c 'flutter_assets/\.env$')" = "0" ] || fail ".env bundled in $apk"
    [ "$(unzip -p "$apk" | grep -a -c 'DEV_AUTH_')" = "0" ] || fail "DEV_AUTH_ found in $apk"
    [ "$(unzip -p "$apk" | grep -a -c 'DevAuthTokenService')" = "0" ] || fail "DevAuthTokenService found in $apk"
  else
    fail "$apk not found"
  fi
fi

[ "$failures" -eq 0 ] && { echo "hardening_check: OK"; exit 0; }
echo "hardening_check: $failures check(s) failed"; exit 1
```
(The `env_config` line was added after the probe run; it matches nothing once F1 lands.)

### pubspec (probed)
```yaml
flutter:
  default-flavor: prod
  uses-material-design: true
  generate: true
  assets:
    - path: .env
      flavors:
        - dev
    - assets/
    # … unchanged
```
### Android flavors (probed; same applicationId)
```kotlin
android {
    flavorDimensions += "env"
    productFlavors {
        create("dev") { dimension = "env" }
        create("prod") { dimension = "env" }
    }
}
```
### `.github/workflows/ci.yml` (shape; versions verified above)
```yaml
name: CI
on:
  pull_request:
    branches: [develop]
  push:
    branches: ['feat/**', 'fix/**', 'refactor/**']
jobs:
  flutter:
    runs-on: ubuntu-latest
    timeout-minutes: 30
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-java@v4
        with: { distribution: temurin, java-version: '17', cache: gradle }
      - uses: subosito/flutter-action@v2
        with: { flutter-version: '3.35.5', channel: stable, cache: true }
      - run: flutter pub get
      - name: Analyze (0 error / 0 warning, infos tolerated)
        run: flutter analyze --no-fatal-infos
      - run: flutter test
      - name: Guard greps
        run: bash tool/hardening_check.sh
      - name: Release build (no .env, no key.properties, no google-services.json)
        run: flutter build apk --release --dart-define-from-file=env/prod.json
      - name: Bundle greps
        run: bash tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk
```
### `SessionRejected` with reason
```dart
const String sessionRevokedReasonNewLogin = 'newLogin';
const String sessionRevokedReasonRoleChanged = 'roleChanged';

class SessionRejected extends AuthApiException {
  const SessionRejected(this.code, {this.reason});
  final String code;
  final String? reason;
  @override
  List<Object?> get props => [code, reason];
}
```

## State of the Art
| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| dart:io blocks cleartext on mobile | reverted; only platform-native stacks honour `usesCleartextTraffic` | Flutter 2.0 → reverted 2.2 | the TLS refusal is app code [CITED] |
| One asset list for all builds | pubspec `assets: - path:, flavors:` + `default-flavor` | Flutter ≥ 3.19 (flavors), `default-flavor` documented today | used here [CITED: docs.flutter.dev/tools/pubspec] |
| Manual leak hunting | `leak_tracker` in `testWidgets(experimentalLeakTesting:)` | Flutter 3.18+ | instruments only dispatching classes (probed) |

## Assumptions Log
| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `actions/setup-java@v4` inputs `distribution/java-version/cache: gradle` | Stack, CI | CI step edit |
| A2 | PKCS12 keystores ignore a key password distinct from the store password | F3 | user confusion at signing |
| A3 | The signing fallback message also prints on debug builds | F3 | cosmetic |
| A4 | CI runtimes (~4 min tests, ~6 min first release build) | F10 | timeout tuning |
| A5 | Loopback sockets work on GitHub runners | F10 | dual-session/logout-flow tests in CI |
| A6 | Through a tunnel the BE throttler sees one IP unless `THROTTLE_TRUST_PROXY` is set | F13 | UAT 429s |
| A7 | cloudflared tunnels carry WebSockets | F13 | UAT on WS |
| A8 | `adb reverse` works on the emulator | F13 | dev-flavor dual-device step |
| A9 | Switching signing on the same applicationId needs an uninstall | F13 | UAT step |
| A10 | google-services plugin fails on an `applicationIdSuffix` without a matching client | Anti-Patterns | only matters if someone adds a suffix |
| A11 | iOS `flutter run` with `default-flavor` needs Xcode schemes | (out of scope) | iOS dev runs break until schemes exist (iOS release is out of v1.0) |

## Open Questions (RESOLVED — orchestrator, 2026-11-09: all seven accepted as recommended; rulings in the CONTEXT D-01..D-13 revisions and D-16..D-20, and in the REPO-RULES «Completed after the research»; the copy of OQ2/OQ4 is fixed in D-19 subject to the user's veto)
1. **What does `env/prod.json` contain?** No production BE exists. *Recommend:* RFC 2606 placeholders `https://api.klimmeck.invalid/`, `https://api.klimmeck.invalid/api/graphql`, `wss://api.klimmeck.invalid/api/graphql` (TLS-valid shape, compiles in CI, unreachable), replaced when a host exists; the UAT uses a tunnel file outside the repo (e.g. `/tmp/klimmeck-tunnel.json`) or a gitignored `env/tunnel.json`.
2. **Copy for `BAD_USER_INPUT` (11 enums, incl. spell/pet) and the moderation lines (C-4, C-6).** *Recommend:* one in-world line reused where the surface is the same kind (e.g. «Le cronache non accettano questa richiesta, riprova» for bubbles/banners; Innkeeper panel stays in the form; `PushDeviceFailure` silent but non-retryable), moderation copy from the BE handoff («Immagine non ammessa, scegline un'altra» / «Riprova o procedi senza immagine»); table approved by the orchestrator before the plan.
3. **Teach `graphQlErrorCode` the HTTP-≥300 `parsedResponse` path?** *Recommend:* yes, in the D-13a plan (one helper change + tests), so a 400 `BAD_USER_INPUT` is not misreported as `connection`.
4. **`InsecureTransportScreen` copy/shape.** *Recommend:* static utility screen, the line in F4, no retry button (a rebuild is the only fix).
5. **`City.size` marker table.** *Recommend:* capital 56 / city 43 / village 31, `CityType.size` and `cityClass` both removed (`CityType` keeps only `imageId`); user eyeballs the three outliers in the device UAT.
6. **Leak test scope.** *Recommend:* one shell-level test (all providers of `authenticated_shell.dart:139-265`) plus the WS part in `logout_flow_test.dart` (C-5); no per-cubit leak tests.
7. **Plan split around the BE gate.** *Recommend:* pre-gate: entry split + flavors + env seam; signing + TLS + appLog; CI + guard script; logout flow + concurrency + leak tests; identity transitions; D-13 a/b/c; gated: reason/`4409`/notices + dual-session test; last: device UAT (dual-device, DevTools, release via tunnel) after the D-14 review fixes.

## Environment Availability
| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK (fvm) | all | ✓ | 3.35.5 / Dart 3.9.2 | — |
| Android SDK + build-tools | release build, apksigner | ✓ | SDK 36.1.0; build-tools 34/35/36.1 | — |
| JDK | Gradle, keytool | ✓ (Android Studio JBR only; no system Java) | OpenJDK 21.0.8 | `JAVA_HOME` = JBR for `apksigner`/`keytool` |
| `unzip`, `grep` | bundle gate | ✓ | macOS | — |
| `gh` | CI checks inspection | ✓ | — | — |
| cloudflared / ngrok | release UAT tunnel | ✗ | — | `brew install cloudflared` (user) |
| Android emulator images | dual-device UAT | ✓ | android-36, android-36.1 `google_apis_playstore`; AVDs Medium_Phone (36.1), Pixel_9 | — |
| BE Phase 17 on `origin/develop` | gated plans + UAT | ✗ (gate file absent) | — | park the gated plans |

## Validation Architecture
### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3`; new test-only: `leak_tracker 11.0.2`, `leak_tracker_flutter_testing 3.0.10` |
| Config file | none (`analysis_options.yaml` only; no `flutter_test_config.dart` — keep it that way) |
| Quick run command | `flutter test <paths>` |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (foreground, ~86 s, 3565 tests) |
| Gates | `flutter analyze --no-fatal-infos`; `bash tool/hardening_check.sh [apk]`; `flutter build apk --release --dart-define-from-file=env/prod.json` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| HARDEN-01 | no token in prefs/logs | grep gate + unit (`appLogWith`) | `bash tool/hardening_check.sh`; `flutter test test/utils/app_log_test.dart` | ❌ Wave 0 |
| HARDEN-02 | 403 matrix | BE int-spec (evidence only) | BE repo, after merge | BE |
| HARDEN-03 | atomic logout end to end | integration (`test`, loopback) | `flutter test test/repository/services/auth/logout_flow_test.dart` | ❌ Wave 0 |
| HARDEN-04 | two concurrent 401 → one refresh | integration | `flutter test test/repository/services/auth/concurrent_unauthorized_refresh_test.dart` | ❌ Wave 0 |
| HARDEN-05 | no retained cubit/subscription | widget + leak_tracker | `flutter test test/screens/auth/authenticated_shell_leak_test.dart` | ❌ Wave 0 |
| HARDEN-05 | DevTools snapshot before/after logout | manual-only (profile build on device) | — | UAT |
| HARDEN-06 | second login replaces the first | integration (`test`, loopback, two services) | `flutter test test/repository/services/auth/dual_session_revocation_test.dart` | ❌ Wave 0 (gated plan) |
| HARDEN-06 | reason → notice | unit/widget | `flutter test test/repository/services/auth/ test/screens/auth/auth_gate_test.dart test/screens/signIn/sign_in_screen_test.dart test/repository/services/graphql/ws_reconnect_policy_test.dart` | ✅ (extend) |
| HARDEN-06 | identity transitions rebuild the shell | widget | `flutter test test/screens/auth/identity_transitions_test.dart` | ❌ Wave 0 |
| HARDEN-06 | dual-device on Samsung + emulator | manual-only | — | UAT |
| HARDEN-07 | prod entry pure, bundle clean | grep gate + release build | `flutter build apk --release --dart-define-from-file=env/prod.json && bash tool/hardening_check.sh build/app/outputs/flutter-apk/app-prod-release.apk` | ❌ Wave 0 (script) |
| HARDEN-07 | `EnvConfig` overrides seam | unit | `flutter test test/config/` | ✅ (rewrite) |
| HARDEN-08 | TLS refusal both branches | unit + widget | `flutter test test/config/env_config_secure_transport_test.dart test/bootstrap/insecure_transport_screen_test.dart` | ❌ Wave 0 |
| HARDEN-08 | signing with/without `key.properties` | build + `apksigner` | scratch build (debug fallback expected locally) | n/a |
| HARDEN-08 | release on device via TLS tunnel, real Twitch login | manual-only | — | UAT |
| HARDEN-09 | CI green on the PR | CI run | `GH_TOKEN=… gh pr checks <n>` | ❌ Wave 0 (workflow) |
| HARDEN-10 | `BAD_USER_INPUT` per classifier | unit | `flutter test test/repository/*_failure_test.dart test/repository/services/graphql/graphql_error_code_test.dart` | ✅ (extend) |
| HARDEN-10 | moderation codes | unit + bloc | `flutter test test/repository/character_creation_repository_test.dart test/screens/characterCreation/` | ✅ (extend) |
| HARDEN-10 | `City.size` markers | widget | `flutter test test/screens/mainScreen/tabs/map/` | ✅ (2 RED, fixtures) |

### Sampling Rate
- **Per task commit:** the touched test files + `flutter analyze --no-fatal-infos`.
- **Per wave merge / gate plan:** full suite + `bash tool/hardening_check.sh` + one release build + bundle check.
- **Phase gate:** full suite green, CI green on the PR, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/helpers/leak_tracking_bloc_observer.dart` — dispatching observer (F6)
- [ ] `test/helpers/fakes/fake_session_backend.dart` — shared in-memory BE (F7)
- [ ] `test/helpers/fakes/fake_graphql_ws_server.dart` — `closeSocket(ws, code, reason)` + `onConnectionInit` hook (F7)
- [ ] `test/utils/app_log_test.dart`, `test/config/env_config_secure_transport_test.dart`, `test/bootstrap/insecure_transport_screen_test.dart`
- [ ] `test/repository/services/auth/logout_flow_test.dart`, `concurrent_unauthorized_refresh_test.dart`, `dual_session_revocation_test.dart`
- [ ] `test/screens/auth/authenticated_shell_leak_test.dart`, `test/screens/auth/identity_transitions_test.dart`
- [ ] `pubspec.yaml` `dev_dependencies`: `leak_tracker: ^11.0.2`, `leak_tracker_flutter_testing: ^3.0.10`
- [ ] `tool/hardening_check.sh`, `env/dev.json`, `env/prod.json`, `.github/workflows/ci.yml`

### Manual-only
- DevTools memory snapshot before/after logout (profile build, dev flavor) — screenshots in `12-HUMAN-UAT.md`.
- Dual-device run (Samsung + emulator, same real Twitch account): second login → first device's WS closed `4409`, sign-in with «Hai effettuato l'accesso da un altro dispositivo.», no state corruption; character deleted/recreated from the other device.
- Release APK through the TLS tunnel with a real Twitch login (signing per the user's keystore, no logs in `adb logcat` from the app tag).

## Security Domain
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | BE-mediated Twitch OAuth (unchanged); dev bypass out of the prod binary (F1/F2) |
| V3 Session Management | yes | single-flight refresh, revocation reasons, `4409` teardown, atomic logout (F7/F9) |
| V4 Access Control | yes (BE) | BE Phase 17 matrix (HARDEN-02 evidence) |
| V5 Input Validation | yes | lenient parsing of `extensions.reason` (unknown → neutral); `BAD_USER_INPUT` classified |
| V6 Cryptography | no new crypto | — |
| V7 Error handling & logging | yes | `appLog` silent in release; no credential interpolation (gate) |
| V9 Communications | yes | release refuses `http://`/`ws://` (Dart-side, F4) — closes AR-03 |
| V14 Configuration | yes | no `.env` in release; signing keys outside VCS; CI greps |

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dev bypass token shipped in release | Elevation | entry split + flavored asset + decompressing bundle gate |
| Cleartext MITM on backend calls | Tampering / Info disclosure | release fail-fast on non-TLS URLs |
| Token in logs | Info disclosure | `appLog` + grep gate |
| Replaced device keeps a live socket | Spoofing | BE `4409` + FE teardown; 15 min HTTP window accepted (BE D-04) |
| Hot reconnect loop with a revoked JWT | DoS | bounded backoff in `WsReconnectPolicy` + link disposed at teardown |

## Sources
### Primary (HIGH confidence)
- Codebase (file:line above), `pubspec.lock`, pub-cache sources: `graphql-5.2.1` `websocket_client.dart`, `gql_http_link-1.1.0` `link.dart`, `flutter_dotenv-6.0.0` `dotenv.dart`, `leak_tracker-11.0.2` `helpers.dart`, `leak_tracker_testing-3.0.2` `leak_testing.dart`, `leak_tracker_flutter_testing-3.0.10`, `flutter_tools/lib/src/android/gradle.dart` (Flutter 3.35.5).
- Probes on this machine (P-B0..P-B8, P-S1..P-S3, P-L0..P-L6, P-M1, full suite, analyzer, formatter).
- BE (read-only): `17-CONTEXT.md`, `17-REPO-RULES.md`, `src/auth/auth.exception.ts`, `src/moderation/image-moderation.exceptions.ts`, `src/validation/bad-user-input.exception.ts`, `.env.example`, `.github/workflows/ci.yml`, Phase 10 `BACKEND-NOTES.md`.
- https://docs.flutter.dev/tools/pubspec (assets `flavors`, `default-flavor`); https://docs.flutter.dev/deployment/flavors (`appFlavor`, product flavors).
- GitHub API: subosito/flutter-action releases (v2.23.0), actions/checkout, actions/setup-java latest tags.
### Secondary (MEDIUM confidence)
- https://docs.flutter.dev/release/breaking-changes/network-policy-ios-android (landed 2.0, reverted 2.2).
- https://docs.flutter.dev/deployment/android (keytool command, key.properties shape).
### Tertiary (LOW confidence)
- Items A1–A11 above.

## Metadata
**Confidence breakdown:**
- Standard stack: HIGH — versions from `pubspec.lock`/pub-cache, actions from the GitHub API.
- Architecture: HIGH — every mechanism probed; the gated contract MEDIUM until BE Phase 17 merges.
- Pitfalls: HIGH — most come from failing probes.

**Research date:** 2026-11-09
**Valid until:** 2026-12-09 (stable toolchain pinned by `.fvmrc`)

## RESEARCH COMPLETE

Probes run (all files deleted afterwards; only `build/` artifacts of the repo were touched): P-B0..P-B8 (bundle content today, CI-like build without `.env`, asset flavors with/without Android product flavors, `default-flavor: prod`, `--dart-define-from-file`, AOT tree-shaking of the dev code, guard script on two APKs), P-S1..P-S3 (signing fallback, warning visibility, throwaway keystore), P-L0..P-L6 (leak_tracker scope, BlocObserver dispatch, notGCed, WeakReference + forceGC), P-M1 (`City.size` visibility → 2 RED map tests), full `flutter test` (86 s, 3565 green), `flutter analyze` (0/0/50, exit 1 → `--no-fatal-infos` exit 0), per-file `dart format` check. Conflicts: C-1 dev run needs `--flavor dev`; C-2 APK path `app-prod-release.apk`; C-3 the REPO-RULES bundle greps cannot detect a deflated `.env` (use `unzip -p <apk> | grep -a -c`); C-4 new copy needs the orchestrator's go; C-5 WS link retention proven outside `testWidgets`; C-6 spell/pet `BAD_USER_INPUT` still show the generic copy; C-7 no production host for `env/prod.json`.
