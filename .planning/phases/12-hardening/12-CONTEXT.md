# Phase 12: Hardening - Context

**Gathered:** 2026-11-09 (interactive discuss from this repo, joint with the BE Phase 17 «Autorizzazione e sessioni», inserted the same day as the BE companion; branch `refactor/12-hardening` from `develop` `ac75702`, the merge of PR #44; BE `develop` at `31dba96`, the merge of BE PR #26)
**Status:** Ready for planning — no UI phase, no UI-SPEC (the only new visuals are two sign-in notices and a fail-fast screen, provisional and user-reviewed on the device). The plans that consume the BE Phase 17 contract (`SESSION_REVOKED` + `extensions.reason`, the dedicated WS close code for a revoked session) and the dual-device UAT are **gated by the BE Phase 17 merge** on BE `develop` (pattern 13-10 / 14-10 / 15-08 / 16-07 / 17-09); every other plan runs before it. Contract names are technical defaults to be fixed in the BE `17-REPO-RULES.md` before the research (pattern 15/16/17).

<domain>
## Phase Boundary

Close v1.0 with an intensive pass on bugs, security and concurrency so the shipped app survives real users and real streams without leaking state, double-refreshing or breaking under multi-device pressure. Concretely: the production entry point carries no dev bypass and no `.env`, the release build is signed with the user's keystore, talks only TLS and logs nothing; the session layer is proven end to end (atomic logout, single-flight refresh, no retained subscriptions or cubits after logout, with a leak-tracking test and a DevTools snapshot); the same Twitch account logging in on a second device replaces the first one cleanly («l'ultimo login caccia l'altro», a BE Phase 17 rule) with a specific sign-in notice, and every identity transition rebuilds the whole shell; the follow-ups parked here since Phases 8, 10 and 13 are closed; a cross-cutting review by area fixes what it finds; a GitHub Actions pipeline guards all of it on every PR.

Out of scope: new gameplay or UI capabilities, the heal mechanics of `canHeal` (its own future phase, quick tasks 261109-inj/inj2), «esci da tutti i dispositivi» (BE backlog), a diagnostics badge for the WS connection (rejected in Phase 3 D-17 and again here), per-request session lookups on the BE (the JWT stays stateless), iOS release work (Android only in v1.0), store listing and publication, the accessibility pass (FUT-04).

</domain>

<decisions>
## Implementation Decisions

### Dev bypass, `.env` and the release build (criterion 6, HARDEN-01, HARDEN-07, HARDEN-08)
- **D-01 (user decision, «Entry point separato»):** the dev bypass moves to a dedicated entry point **`lib/main_dev.dart`**, which composes `DevAuthTokenService`, loads `.env` through `flutter_dotenv` and keeps today's dev behaviour (D-23..D-30 of Phase 11: `DEV_AUTH_*` knobs, instant login, `DEV_AUTH_START_SIGNED_OUT`). **`lib/main.dart` becomes production-pure**: no `DevAuthTokenService`, no `DEV_AUTH_*`, no `flutter_dotenv` import; `_buildAuth` composes only `SessionAuthTokenService`. The two entry points share one composition module (no duplicated wiring: the dev file only swaps the auth factory). Device UATs run with `flutter run -t lib/main_dev.dart`; the gate is a grep that proves `lib/main.dart` and the release bundle contain neither `DevAuthTokenService` nor the string `DEV_AUTH_`.
- **D-02 (user decision, «Niente .env in release»):** the release build ships **no `.env`**. Backend URLs come from **`--dart-define-from-file=env/<ambiente>.json`** (URLs only, no secret: the file can live in the repo; `EnvConfig` already reads `String.fromEnvironment` as the second priority). `.env` + `flutter_dotenv` stay a convenience of the dev entry point only. Mechanism to keep the asset out of the release bundle (pubspec asset `flavors:` with a `dev` flavor, a build-time copy, or another verified option) is **researcher/planner discretion**; the truth is the gate: the built release APK contains no `.env` entry and no `DEV_AUTH_` string.
- **D-03 (user decision, «Tutto in scope»):** release readiness is part of this phase: (a) **signing** — the release build reads the keystore from **`android/key.properties`** (already in `.gitignore` with `*.jks`); **the user generates the keystore and the properties file** (exact `keytool` command and the four keys documented in the handoff); when the file is missing the build **falls back to the debug keys with a visible warning**, so CI and `flutter run --release` keep working; (b) **TLS only** — in release the app refuses cleartext `http://` / `ws://` backend URLs (fail fast at startup with a clear, non-gameplay screen; copy and shape Claude's discretion), closing AR-03 of the Phase 3 security audit; `EnvConfig.isDebug` / `enableLogging` default to `false` in release; (c) **no logging in release** — `debugPrint` calls are routed through one logger that is silent under `kReleaseMode` (or stripped), and the token-hygiene grep proves no token or bearer value ever reaches a log statement.
- **D-04 (user decision, «Tunnel TLS verso il BE locale»):** the release build is exercised on the device through a **TLS tunnel to the local BE** (`cloudflared tunnel` or `ngrok`), with `--dart-define-from-file` pointed at the tunnel host; the real Twitch login runs through it. Prerequisite for the user: the tunnel's public URL must be an allowed redirect URI of the Twitch application (or a stable named tunnel is used), written in the UAT sheet. Nothing new is deployed.

### Test harnesses and CI (HARDEN-01, HARDEN-03, HARDEN-04, HARDEN-05, HARDEN-09)
- **D-05 (user decision, «Test automatico + DevTools in UAT»):** HARDEN-05 is proven twice: (a) a **leak-tracking widget test** (`leak_tracker_flutter_testing`, already in the lock through `flutter_test`, Flutter 3.35.5) that pumps the authenticated shell with its cubits and subscriptions, logs out, and **fails on any not-disposed / not-GCed object** (cubits, `StreamSubscription`s, the WS link); (b) a **DevTools memory snapshot before/after logout** as a step of the device UAT, documented with screenshots.
- **D-06 (user decision, «Telefono + emulatore Android»):** the dual-device UAT uses the **Samsung over USB plus an Android emulator**, both logged in with the **same real Twitch account**; the cases of revocation and conflict are also covered by an **in-process test with two `SessionAuthTokenService` instances** against the fake backend helpers (`FakeGraphQlWsServer.dropWith(<close code>)`, fake HTTP adapter). Protocol in `12-HUMAN-UAT.md`.
- **D-07 (user decision, «Completa con build release»):** a **GitHub Actions workflow on PR → `develop`** (the FE repo has none today): `flutter analyze` with **0 error / 0 warning** (info baseline tolerated), `flutter test`, the **guard greps** (no `SharedPreferences` in the auth/storage layer for tokens, no token/bearer value in any log statement, no `DEV_AUTH_` / `DevAuthTokenService` / `flutter_dotenv` in `lib/main.dart`), then **`flutter build apk --release`** with the dart-define file and a **grep of the bundle** for `.env` and `DEV_AUTH_`. The BE `.github/workflows/ci.yml` is the reference for shape; the schema check tool (`tool/schema_check`, needs the BE SDL) stays local.
- **D-08 (technical default, stated in the discuss):** HARDEN-03 and HARDEN-04 are **verified, not reinvented**: the existing suites (`session_auth_token_service_{refresh,logout,revocation,terminate,bootstrap}_test.dart`, `auth_cubit_test.dart`, `auth_token_service_contract_test.dart`) are audited against the two criteria and completed where a step is missing: one **end-to-end logout flow test** (backend `logout` best-effort, subscriptions cancelled, `GraphQLClient` + `WebSocketLink` recreated, secure storage cleared, `Unauthenticated` emitted, sign-in shown — Phase 11 D-12/D-36 in one flow) and one **concurrency test** (two simultaneous `UNAUTHENTICATED` / 401 responses → exactly one `refreshSession` call, no silent logout — Phase 11 D-06).

### Multi-device and identity transitions (HARDEN-06, HARDEN-02 evidence)
- **D-09 (user decision, «L'ultimo login caccia l'altro», BE Phase 17 D-02/D-03/D-04):** a login on a second device **revokes the other sessions of the user on the BE**, which **closes their WebSocket connections at once** with a dedicated close code; the access JWT of the replaced device stays valid until its natural expiry (15 min, stateless, no per-request lookup). On the FE the replaced device reacts to the close as it does to `4401` today (refresh before reconnect, Phase 11 D-07/D-37): the refresh is refused with `SESSION_REVOKED` + `reason`, the session is torn down (same path as a revocation, D-09 of Phase 11) and the sign-in screen shows the **specific notice** (D-12). Bounded reconnects, no hot loop, no blocking UI (rule 2).
- **D-10 (user decision, «Solo quel device»):** logout keeps closing **only the current session** (Phase 11 D-12 step 1); the other device stays logged in. «Esci da tutti i dispositivi» stays in the BE backlog (deferred).
- **D-11 (user decision, «Reset totale della shell»):** identity transitions rebuild the whole shell by construction — **already the design**: `AuthGate` keys the authenticated subtree on `user.id` and `SessionHome` on `character:<id>`, root-Navigator dialogs and sheets are closed on both changes (Phase 3 D-10, Phase 11 D-26). This phase **proves it** with tests (account switch on the same device; character deleted or recreated from the other device → creation screen, then a fresh shell for the new id) and fixes any gap found (a cubit or listener surviving the key change, a push intent routed to a stale character). No «refetch in place» variant.
- **D-12 (user decision, «Specifico quando il BE lo dice», BE Phase 17 D-05):** the refresh refusal keeps the code `SESSION_REVOKED` and adds **`extensions.reason`** (enum, names fixed in the BE `17-REPO-RULES.md`; technical defaults `newLogin`, `roleChanged`, `reuseDetected`, `userLogout`); the same string travels in the reason of the dedicated WS close. The FE parses it **leniently** (unknown or missing → the neutral Phase 11 D-10 notice «La sessione è scaduta, accedi di nuovo.») and shows dedicated copy for **`newLogin`** («Hai effettuato l'accesso da un altro dispositivo.», copy Claude's discretion) and **`roleChanged`** («Il tuo ruolo è cambiato, accedi di nuovo.»). Implementation: new `UnauthenticatedReason` and `SignInNotice` values; `SessionRejected` carries the reason. Gated plan (BE contract).

### Bug-fix pass (HARDEN-10)
- **D-13 (user decision, three of four follow-ups folded):** (a) **`BAD_USER_INPUT`** (BE Phase 10) is mapped in **every** existing failure classifier (`lib/repository/*_failure.dart`: transaction, travel, quest acceptance/abandon/result, pet equip, innkeeper, character creation/deletion, push device; `SpellEquipFailure` already maps it) with an in-world message, never the generic error; (b) **`IMAGE_REJECTED` / `IMAGE_MODERATION_UNAVAILABLE`** (BE Phase 10 BE-HARD-05) are mapped in `CharacterCreationFailure`: rejected portrait → dedicated message and a new pick; moderation unavailable → dedicated message and retry, the draft kept; (c) **`CityType.cityClass` is removed** in favour of **`City.size`** served by the BE (Phase 13 deferred item): marker sizes derive from `City.size`, the FE map goes away, the `cities` query selects `size` (already on the wire since BE Phase 12).
- **D-14 (user decision, «Sì, review per aree + fix»):** the «intensive bug-fix pass» of the ROADMAP is a **cross-cutting code review by three parallel reviewers** (session/WS and auth, cubits and subscriptions lifecycle, models and tolerant parsing), an orchestrator ruling, then a fixer in TDD; findings outside the phase boundary are recorded as deferred, not fixed here. Pipeline of the previous phases (review → ruling → fix → verify → security).
- **D-15 (user decision):** the **diagnostics badge** for the WS connection stays **out** (rejected in Phase 3 D-17, not revived).

### Claude's Discretion
- Copy of the two new sign-in notices and of the fail-fast screen for cleartext URLs in release; whether the fail-fast is a screen or a hard assertion at startup.
- The mechanism that keeps `.env` out of the release bundle (asset flavors vs other), the shape of the shared composition module between the two entry points, the name of the dart-define file(s).
- The logger seam for `debugPrint` in release; the exact guard-grep patterns and where they run (CI job vs a `tool/` script invoked by CI).
- Gradle wiring for `key.properties` (property names, fallback warning text); which Android emulator image the UAT uses.
- Test structure of the leak-tracking test (one shell-level test vs per-cubit), the in-process dual-session harness, and how the phase splits plans before/after the BE Phase 17 gate.

</decisions>

<specifics>
## Specific Ideas

- User, on the areas: all four selected; every recommended option taken except two product rules chosen against the default — **«L'ultimo login caccia l'altro»** instead of independent sessions, and **a specific revocation message when the BE says why** instead of the neutral one; and **a full BE mini-phase (17)** for HARDEN-02 instead of a quick task.
- The dev account used by every UAT so far is the innkeeper: the dev entry point must keep that workflow untouched (same `.env`, same knobs).
- The release build must be installable from the store at the end of v1.0: signing, TLS and silent logs are not «later».
- The UAT of the release build runs against the local BE through a TLS tunnel; the user adds the tunnel URL to the Twitch application's redirect URIs.

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 12: Hardening" — goal, HARDEN-01..10, success criteria 1–10 (amended 2026-11-09), backend prerequisite BE Phase 17; §"Backend Prerequisites" (HARDEN-02 / HARDEN-06 bullet).
- `.planning/REQUIREMENTS.md` §"Hardening" — HARDEN-01..10 (HARDEN-02/05/06 amended, HARDEN-07..10 added 2026-11-09); §"Out of Scope".
- `.planning/PROJECT.md` §"Key Decisions" — dev bypass kept beside the real auth until Phase 12; `refactor/` prefix for hardening phases.

### BE companion (Phase 17)
- `../Klimmeck-Guide-BE/.planning/phases/17-autorizzazione-e-sessioni/17-CONTEXT.md` — D-01 (table-driven authorization matrix = HARDEN-02 evidence), D-02..D-04 (last login wins, immediate WS close, JWT stateless until expiry), D-05 (`SESSION_REVOKED` + `extensions.reason`, same string in the WS close reason), D-06 (role change → revocation), D-07 (logout unchanged), D-09 (handoff for this phase).
- `../Klimmeck-Guide-BE/.planning/phases/17-autorizzazione-e-sessioni/17-REPO-RULES.md` — contract names (reason enum values, close code), written at BE plan time before the research: the FE gated plans read the names there.
- `../Klimmeck-Guide-BE/test/app.int-spec.ts` — `EXPECTED_INNKEEPER_HANDLERS` (11) and `EXPECTED_OWNERSHIP_HANDLERS` (19): the lists the BE matrix iterates.
- `../Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/02-CONTEXT.md` D-08 (one session per device, rotation, reuse detection), D-35 (30 s reuse window) and `BACKEND-NOTES.md` §3 — the session contract this phase hardens on the client.
- `../Klimmeck-Guide-BE/.planning/phases/03-autorizzazione-ownership-ruoli-audit/03-CONTEXT.md` D-09 (innkeeper bypass audited), D-12 (`@Roles`).

### Prior FE decisions carried forward
- `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md` — D-05/D-06 (proactive + single-flight refresh), D-07/D-37 (WS close `4401`/`4403` → refresh before reconnect, link never recreated mid-session), D-09/D-10 (revocation detection and neutral notice), D-11/D-12/D-14/D-36 (logout confirmation and teardown order, account switch), D-23/D-30 (dev bypass kept, release stripping deferred here), D-26 (shell rebuilt when the user gets a character), D-34 (native prerequisites: AGP, `allowBackup=false`).
- `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` — §dev bypass («Rimozione prevista in Phase 12»), §3 reuse window.
- `.planning/phases/03-real-time-sync-foundation/03-CONTEXT.md` — D-10 (root dialogs closed on character change), D-15 (sync watchdog → `syncLost`), D-17 (diagnostics badge rejected).
- `.planning/phases/03-real-time-sync-foundation/03-SECURITY.md` — AR-03 / T-03-05-06: cleartext `ws://` transferred to this phase (D-03b closes it).
- `.planning/phases/10-admin-panel-innkeeper/10-SECURITY.md` — T-10-19 (stale JWT role) → BE Phase 17 D-06 + FE notice `roleChanged`.
- `.planning/phases/08-spells-section-journal-tab/08-CONTEXT.md` §Deferred — `BAD_USER_INPUT` mapping in every classifier (D-13a).
- `.planning/phases/13-city-shops/13-CONTEXT.md` §Deferred — drop of `CityType.cityClass` for `City.size` (D-13c).
- `.planning/phases/02-character-creation/02-CONTEXT.md` and `02-SECURITY.md` AR-01 — portrait moderation deferred to the BE Phase 10 → codes mapped here (D-13b).
- `.planning/phases/05-notifications-infrastructure/05-CONTEXT.md` D-08 — push device unregister before logout (2 s cap), part of the logout flow test.

### Rules
- `docs/rules/workflow.md` — `refactor/` prefix for hardening, PR to `develop`, Conventional Commits, no formatter sweeps.
- `docs/rules/testing.md`, `docs/rules/state-management.md`, `docs/rules/architecture.md`, `docs/rules/graphql.md` — TDD, cubit lifecycle, layer placement (composition root), document registry rules (the `cities` selection change of D-13c touches a document).
- `../Klimmeck-Guide-BE/.github/workflows/ci.yml` — shape reference for the FE workflow (D-07).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/main.dart` — `main()` loads `.env` (`dotenv.load`), bootstraps push, builds the auth through `_buildAuth({onSessionTeardown})` (the only reader of `EnvConfig.devAuthEnabled`), wires `GraphQLClientHolder` (with `reset()` as the teardown hook), `RestClient`, stores and `KlimmeckGuideApp`; D-01 extracts this into a shared composition module used by both entry points.
- `lib/config/env_config.dart` — runtime `.env` value → `--dart-define` → built-in default, for `BASE_URL`, `GRAPHQL_HTTP_URL`, `GRAPHQL_WS_URL`; `devAuthEnabled` read at runtime; `isDebug` / `enableLogging` compile-time flags (default `true`): the seam for D-02/D-03.
- `lib/repository/storage/session_store.dart` — `SecureSessionStore`: only the refresh token is persisted (Keychain/Keystore, `first_unlock_this_device`, `resetOnError`), a non-secret first-launch marker in `shared_preferences`; the access JWT lives in memory. `lib/repository/storage/storage_manager.dart`, `active_user_store.dart`, `device_identity_store.dart`, `notification_preferences_store.dart`, `library_bookmarks_store.dart` are the other `SharedPreferences` users (guard grep of HARDEN-01 must prove none holds a token).
- `lib/repository/services/auth/session_auth_token_service.dart` — single-flight refresh (`_refreshInFlight` `Completer<String>`), proactive timer, `_endSession(UnauthenticatedReason)`, `terminateSession`, logout-only refresh (Phase 11 D-36); `auth_api_exception.dart` maps `SESSION_EXPIRED` / `SESSION_REVOKED` to `SessionRejected(code)` (D-12 adds the reason); `auth_token_service.dart` holds `UnauthenticatedReason { signedOut, sessionExpired, syncLost }`.
- `lib/screens/auth/auth_gate.dart` — `KeyedSubtree(key: ValueKey(user.id))`, `_noticeFor(reason)` → `SignInNotice`; `lib/screens/auth/session_home.dart` — `KeyedSubtree(key: 'character:<id>')`, creation screen when `currentCharacter` is null (D-11 proves these); `lib/screens/signIn/sign_in_screen.dart` — the neutral notice string.
- `lib/screens/auth/authenticated_shell.dart` — `MultiBlocProvider` with every gameplay cubit (`CharacterCubit`, `QuestCubit`, `TransactionCubit`, `MainScreenCubit`, `WorldMapCubit`, `ShopCubit`, `LibraryCubit`, `JournalCubit`, notification cubits, `QuestResultsCubit`, `InnkeeperRepository`…): the object graph the leak-tracking test of D-05 must see disposed.
- `lib/screens/auth/cubit/auth_cubit.dart` — `logout()` = push unregister (2 s cap) then `AuthTokenService.logout()`.
- `lib/repository/*_failure.dart` — 11 failure enums with their classifiers (D-13a); `lib/repository/character_creation_failure.dart` (D-13b); `lib/models/enums/city_type.dart` (`cityClass`, `CitySizeType`, marker `size`) and the `cities` document (D-13c).
- Test helpers: `test/helpers/fakes/fake_graphql_ws_server.dart` (`dropWith(4401|4403|1001)`, real loopback server, `test(...)` only), `fake_http_client_adapter.dart`, `test/helpers/test_app.dart`, `auth_session_fixtures.dart`, `auth_fixtures.dart`; existing auth suites listed in D-08.
- `tool/schema_check/` — document registry vs BE SDL (local gate, not CI).
- Android: `android/app/build.gradle.kts` (release signed with debug keys, `googleServices` WARN strategy), `android/app/src/main/AndroidManifest.xml` (`allowBackup="false"` already), `.gitignore` (`android/key.properties`, `*.jks`, `.env*`).

### Established Patterns
- Composition root reads `EnvConfig` once (Phase 11 D-23); services behind interfaces (`AuthTokenService`, `SessionTerminator`, `UnauthorizedRecovery`); teardown recreates the whole GraphQL client (Phase 11 D-12).
- Lenient parsing of wire enums (`asNameMap`, unknown dropped) — reuse for `extensions.reason` (D-12).
- Failure classifiers: one enum per operation with a `classify` from the GraphQL/REST error codes, routed to bubble/banner by the screen (Phase 9 routing rules).
- Gate greps are literal and must not be tripped by docs or skeletons (orchestration lesson: keep `DEV_AUTH_` literals out of `lib/main.dart` comments too).
- Formatter baseline is not clean: `dart format` only on touched files (Phase 11 D-38).

### Integration Points
- New `lib/main_dev.dart` + shared composition module; `pubspec.yaml` assets (`.env` removal/flavoring); `env/*.json` dart-define files; `.github/workflows/ci.yml` (new).
- `EnvConfig` (TLS refusal in release, logging flags), a logger seam replacing direct `debugPrint` in the session layer.
- `auth_api_exception.dart` / `session_auth_token_service.dart` / `auth_gate.dart` / `sign_in_screen.dart` for the revocation reason and notices (gated plan).
- `android/app/build.gradle.kts` for `key.properties`.
- `city_type.dart`, `City` model and `cities` document, map marker widgets for `City.size`.
- Failure classifiers and the character-creation cubit for the BE Phase 10 codes.

</code_context>

<deferred>
## Deferred Ideas

- **«Esci da tutti i dispositivi»** (Settings entry + BE mutation revoking every session of the user) — BE backlog since Phase 2; not needed once the last login wins.
- **Diagnostics badge / dedicated sync logs** in the dev entry point — rejected again (D-15).
- **Per-request session validation on the BE** (kick the replaced device from HTTP at once) — rejected in the BE Phase 17 discuss (JWT stays stateless, 15 min window accepted).
- **Heal mechanics** (`LootItem.canHeal` in use: potions curing specific injuries, partial heal quests) — dedicated FE/BE phase pair after v1.0 Hardening (quick tasks 261109-inj/inj2).
- **iOS release readiness, store publication, accessibility pass (FUT-04)** — post-v1.0.
- «Failed host lookup: 'localhost'» seen in the Phase 10 UAT — explained by the device setup (Doze with the screen off, adb tunnel lost on USB reconnection); no app defect, nothing to do here.

</deferred>

---

*Phase: 12-hardening*
*Context gathered: 2026-11-09*
