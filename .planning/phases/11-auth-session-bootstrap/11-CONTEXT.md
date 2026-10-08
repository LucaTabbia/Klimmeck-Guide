# Phase 11: Auth & Session Bootstrap - Context

**Gathered:** 2026-04-13
**Amended:** 2026-10-06 (auto-mode update — see "Amendment 2026-10-06" below)
**Status:** Ready for re-planning (the five April plans are superseded)

<amendment>
## Amendment 2026-10-06 — why this context changed

Three facts invalidated part of the April decisions:

1. **Twitch has no PKCE and requires `client_secret` for the authorization code grant** (verified 2026-10-06 on `dev.twitch.tv/docs/authentication/getting-tokens-oauth/`). The April design — the app exchanging the code itself as a PKCE public client — cannot work.
2. **The backend decided on its own session JWT** (BE Phase 2, `Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/02-CONTEXT.md`). The backend mediates the Twitch OAuth dance, keeps the client secret, and hands the app a first-party session (short-lived access JWT + rotating refresh token). The app never sees a Twitch token.
3. **User directive (2026-10-06):** *"Per quanto riguarda cosa come la login su Twitch (di cui non abbiamo ancora le chiavi) per adesso inizia l'implementazione, ma permetti di bypassare il tutto finché non si ha tutto il necessario."* The Twitch keys do not exist yet: the real login must be implemented now, and the whole thing must stay bypassable until the keys arrive.

Decisions keep their original D-numbers (11-UI-SPEC.md references them). Amended ones are marked **(amended)**; new ones start at D-23.
</amendment>

<domain>
## Phase Boundary

Session identity end-to-end against the backend's session contract: login through the system browser (Twitch OAuth mediated by the backend, no WebView), encrypted storage of the session refresh token, transparent silent refresh, hard logout that fully tears down session state, account-switch guarantee, detection of server-side session revocation, and a **dev bypass that keeps the app fully usable without Twitch keys**. Outcome: a real `AuthTokenService` implementation that lives next to `DevAuthTokenService` behind the unchanged contract, selected at the composition root.

Out of scope for this phase: character creation flow, settings screen, notification permission flow, GraphQL subscription content. Only the *auth substrate*, the *sign-in utility screen*, the *splash gate* and the *logout dialog*.

</domain>

<decisions>
## Implementation Decisions

### AuthTokenService — shape & placement
- **D-01:** `AuthTokenService` is a singleton exposed via `RepositoryProvider` placed above the `BlocProvider` tree (already wired in Phase 1 — keep).
- **D-02:** Public surface is the Phase 1 contract, unchanged: `initialize()`, `Stream<AuthState> authStateStream`, `Future<String?> getAccessToken()`, `login()`, `logout()`, `handleRevocation()`, `dispose()`. `getAccessToken()` returns the current valid **backend session JWT**, refreshing first if it knows the token is near/past expiry.
- **D-03:** `dio` interceptor and `graphql_flutter` link consume the service through the same provider — no service locator, no static globals.

### Token refresh strategy (AUTH-06)
- **D-04:** **Refresh must never block UI in an active session** (project-wide rule). No spinners, no overlays during in-session refresh.
- **D-05 (amended):** **Proactive scheduled refresh** based on the session's `accessTokenExpiresAt` returned by the backend (refresh ~60s before expiry, recomputed on each successful refresh), with a **reactive fallback** when a request comes back unauthenticated (GraphQL `extensions.code == UNAUTHENTICATED`, or HTTP 401 on REST) for missed firings (background app, clock skew). Refresh = backend mutation `refreshSession(refreshToken)`; the refresh token **rotates on every call** and the new one must be persisted before the old one is forgotten.
- **D-06:** Concurrent in-flight requests during a refresh are serialized via a **single-flight mutex** (a shared `Completer<String>`): exactly one network refresh per refresh cycle. This matters doubly now — the backend applies reuse detection on rotated refresh tokens (any token retired less than 30 s before the request is answered with the same current token — backend decision D-35, option A chosen by the user on 2026-10-06; older retired tokens revoke the session), so a duplicated or late refresh beyond that window could kill the session.
- **D-07 (amended):** The backend **closes the WebSocket when the access JWT expires** (close code `4401`, reason `Token expired`) and rejects a connection with a missing/invalid token with close code `4403`. The contract on the app side: every (re)connection must send the **current** token in the `connection_init` payload (`{ "Authorization": "Bearer <jwt>" }`) — never a value captured once at boot — a `4401`/`4403` close must go through a refresh before reconnecting, reconnect attempts must be bounded (no hot loop with a dead token), and the whole thing must be silent. Mechanism (async `initialPayload` reading `getAccessToken()` on each reconnect vs recreating the link after refresh) is researcher/planner discretion — pick whichever is verified to carry the new token.

### Revocation detection (AUTH-07)
- **D-08 (amended):** Cold start always proves the session against the **backend** before declaring it valid: load the refresh token from secure storage → `refreshSession` → `Authenticated` with the user returned by the backend. Result decides splash → main vs splash → sign-in. No call to Twitch from the app, ever.
- **D-09 (amended):** In-session detection: a refresh rejected with `SESSION_REVOKED` or `SESSION_EXPIRED` is treated as revocation → logout teardown (D-12) and route to sign-in. Transient failures (5xx, network, timeout) do **not** trigger logout — retry with backoff inside the proactive refresh. _(Note added 2026-10-06 after code review: this holds when the backend did not process the failed request, and for short outages. If the backend DID rotate the token but the response was lost, and the retry reaches it more than 30s later, the backend answers `SESSION_REVOKED` and the user must log in again. Backend decision D-35 (option A, chosen 2026-10-06) narrows this to the lost-response-then-no-retry-within-30-s case: any token retired within the last 30 s is answered with the same current token. See `BACKEND-NOTES.md` §3.)_
- **D-10:** Cold-start revocation message is neutral: "La sessione è scaduta, accedi di nuovo." (no accusation of explicit revocation).

### Logout teardown (AUTH-04, AUTH-05)
- **D-11:** Logout always asks for explicit user confirmation via dialog ("Sei sicuro di voler uscire?"). No silent logouts initiated by the user.
- **D-12 (amended):** Teardown order is fixed and atomic from the user's perspective: (1) invalidate the session on the **backend** (`logout` mutation, best-effort, see D-13), (2) cancel all active GraphQL subscriptions, (3) **dispose and recreate the entire `GraphQLClient` + `WebSocketLink`** (not `store.reset()` — full recreation guarantees zero listener leaks and a clean `connection_init` for the next session), (4) clear secure storage of every session artifact, (5) emit `Unauthenticated` and route to sign-in.
- **D-13 (amended):** Step 1 is **best-effort with a 3–5s timeout**. Failure (offline, 5xx) is logged as a warning but does NOT block the rest of the teardown — the user must be able to log out with no network. The server-side session then dies by its own expiry. The access JWT stays technically valid server-side until it expires (≤ 15 min): the app must discard it immediately.
- **D-14:** Switching account (AUTH-05) reuses the same logout teardown, then re-enters the login flow. The backend always sends `force_verify=true` to Twitch, so the system browser's SSO state cannot silently reuse the previous account.

### Login flow (AUTH-01, AUTH-05)
- **D-15 (amended):** Login is **`flutter_web_auth_2` + system browser + `klimmeck://auth` deep link**, pointed at the **backend**: the app generates a one-time `code_verifier` and its S256 `code_challenge`, opens `GET {BASE_URL}auth/twitch/start?challenge=<S256>`, and receives `klimmeck://auth?ticket=<ticket>` (or `?error=<code>`). It then redeems the ticket with the mutation `exchangeLoginTicket(ticket, codeVerifier)` and gets the session (`AuthSession { accessToken, accessTokenExpiresAt, refreshToken, user }`). The S256 pair is **our own binding between app and backend** (an intercepted deep link is useless without the verifier) — it is not Twitch PKCE. No WebView (Twitch TOS).
- **D-16 (amended):** `force_verify=true` is added by the backend on every login. Nothing to do in the app beyond D-14.

### Bootstrap & Splash UX
- **D-17:** Reuse the existing `lib/screens/splash/splash_screen.dart` (and its `SplashCubit`) as the cold-start gate. The auth resolve is its **first action**.
- **D-18:** Cold-start network/timeout handling: **retry the session resolve indefinitely** in the background, but **after 10 seconds** the splash surfaces a non-blocking message: *"Connessione instabile, attendere o accedere manualmente"* with a button that routes to the sign-in screen. If the retry eventually succeeds and the user has not pressed the button, the app proceeds to the main shell. *(Wording amended: the app no longer talks to Twitch directly, so the message no longer names Twitch.)*
- **D-19:** No refresh token in storage → splash routes immediately to sign-in (no onboarding, no intermediate screen).

### Sign-in screen (utility screen — chrome allowed)
- **D-20:** Layout: Klimmeck logo + tagline + Twitch-branded "Login con Twitch" button + footer with TOS/Privacy links.
- **D-21:** User-cancel handling: `flutter_web_auth_2` raises `PlatformException(CANCELED)` → catch silently, leave the sign-in screen untouched. The backend's `?error=access_denied` (user denied consent on Twitch) is treated the same way: silent, no banner.
- **D-22:** Network/server errors: inline error on the sign-in screen ("Errore di connessione, riprova"), button stays enabled for retry.

### Dev bypass — Twitch keys not available yet (user directive)
- **D-23:** The bypass is **`DevAuthTokenService`, kept and selected by `DEV_AUTH_ENABLED=true`** in `.env`, exactly as in Phase 1. The real implementation fills the `else` branch of the composition root (today an `UnimplementedError`). Both live side by side behind the same contract; removing the stub stays a Phase 12 (Hardening) item as already written in the roadmap.
- **D-24:** In dev mode the cold start goes **straight to the main shell** (the stub emits `Authenticated` immediately) — "bypassare il tutto". To keep the new UI testable without keys, the stub stops being a pure no-op: `logout()` emits `Unauthenticated` (the sign-in screen appears) and `login()` emits `Authenticated` again (the "Login con Twitch" button logs in instantly with the dev identity, no browser). This amends DEV-AUTH-04.
- **D-25:** The stub sends `Authorization: Bearer <DEV_AUTH_ACCESS_TOKEN>` as today; the backend (with its own `DEV_AUTH_ENABLED=true`) resolves it to a real dev user. The stub **aligns its `User` with the backend through the `me` query** (best-effort; falls back to the `.env` values when the backend is unreachable), because the backend creates the dev user by `DEV_AUTH_TWITCH_ID` and owns its id.
- **D-26:** **The app holds no Twitch key at all.** `TWITCH_CLIENT_ID` disappears from `EnvConfig`, from `.env.example` and from every plan: client id and secret live only on the backend.
- **D-27:** When the backend has no Twitch keys yet, a real login attempt comes back as `klimmeck://auth?error=twitch_not_configured`. The sign-in screen shows a dedicated inline message ("Login con Twitch non ancora disponibile.") instead of the generic network error.
- **D-28:** Everything is covered by automated tests with fakes (injectable browser-auth wrapper, mocked GraphQL/dio, in-memory secure storage). The real end-to-end login on a device **cannot be verified until the keys exist**: it is recorded as a pending human UAT item, not as a blocking checkpoint of this phase.

### Post-research refinements (2026-10-06, auto-accepted — see 11-RESEARCH.md)

- **D-29:** Dev-only knob **`DEV_AUTH_START_SIGNED_OUT`** (default `false`) in `.env`: when `true` the stub starts `Unauthenticated`, so the sign-in screen is visible at cold start and "Login con Twitch" enters instantly with the dev identity. The logout entry point only arrives with the Settings screen (Phase 4); this knob is what makes the sign-in UI and the bypass reachable by hand until then. No production UI is added for it.
- **D-30:** The dev bypass keeps its Phase 1 behaviour in release builds (no `kReleaseMode` guard added here); stripping `DEV_AUTH_*` from release builds stays in Phase 12 as written in the roadmap. Rationale: the backend is the security boundary — it accepts the dev token only with its own `DEV_AUTH_ENABLED=true` outside production. The stub logs a loud warning at startup.
- **D-31 (amends the D-10 presentation):** the "session expired" message has **one** home: an inline notice on `SignInScreen` driven by `AuthUnauthenticated.reason`. The splash never shows it (no `SplashSessionExpired` state, no 1.5s delay). `11-UI-SPEC.md` updated accordingly.
- **D-32:** `AuthUnauthenticated` gains an optional `reason` (additive; default = plain signed-out). Forcing a refresh after an unauthenticated response goes through a narrow additive interface implemented only by the real service (`UnauthorizedRecovery`-style), not through a change to the `AuthTokenService` contract.
- **D-33:** `initialize()` is no longer awaited in `main()` before `runApp`: `AuthCubit` starts it after the first frame (no blocking cold start on a network call). Same signature; only the caller and the dartdoc change.
- **D-34:** Native/build prerequisites are explicit Wave 0 tasks, not details: raise **AGP to ≥ 8.9.1** (required by `flutter_web_auth_2` 5.x, verified by a scratch build), pin `flutter_secure_storage` to `^10.3.4` (11.x needs Dart ≥ 3.10), add the missing `INTERNET` permission to the main Android manifest, declare the `klimmeck` `CallbackActivity`, set `android:allowBackup="false"`, declare `crypto` and `fake_async` directly.
- **D-35:** The browser wrapper takes `preferEphemeral` as a parameter, default `false` (SSO kept; the backend's `force_verify=true` covers the account switch). Real-device account switch is part of the pending UAT (D-28).
- **D-36 (amended 2026-10-06 after code review, WR-01/WR-02):** Best-effort backend logout (D-12 step 1) first detaches the session being closed (no more renewals, in-flight refresh dropped) and resolves the bearer for the backend call **bound to that session**: the current access JWT if still fresh, otherwise a dedicated logout-only refresh whose rejection is reported to the logout path instead of ending the session a second time. If no bearer can be obtained (offline, revoked), step 1 is skipped and the teardown continues. A user logout therefore emits exactly one `signedOut`, and a late result of the old session can never be used against a newer session. _Original wording: "uses the normal `getAccessToken()` path" — replaced because that path could hand the logging-out caller the token of a session created in the meantime and could emit `sessionExpired` before `signedOut`._
- **D-37:** The WebSocket link is **not** recreated after a refresh (it would break live subscription streams): the current token is read on every connect, and a `4401`/`4403` close triggers a refresh before the client's own reconnect. The link is recreated only at logout. Events missed during the reconnect gap are a Phase 3 (Real-Time Sync) concern: recorded in this phase's `BACKEND-NOTES.md`.
- **D-38 (formatting discipline):** `dart format` **must never be run on whole directories** in this phase — the repository baseline is not formatter-clean and a directory-wide run rewrites ~77 unrelated files. Format only the files a task creates or modifies, and verify with `dart format --output=none --set-exit-if-changed <files>`.

### Claude's Discretion
- Exact dialog widget for logout confirmation (reuse an existing app dialog pattern from `lib/shared/` if one exists).
- TOS/Privacy URLs (placeholders are fine for v1).
- Twitch button styling specifics — coherent with Twitch brand guidelines and the app theme in `lib/theme/`.
- Mutex primitive (Completer-based vs `synchronized`) — prefer no new package.
- WebSocket re-auth mechanism (D-07).
- Storage key naming and the shape of the `SecureStorage` wrapper. The refresh token MUST be in encrypted platform storage; whether the short-lived access JWT is also persisted or only kept in memory is free.
- Name of the real implementation class (`SessionAuthTokenService` or similar — it is no longer an "OAuth" service from the app's point of view).
- Whether dev mode shows a small "modalità dev" hint on the sign-in screen.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract (source of truth for every name, shape and error code)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md` — the handoff written by BE Phase 2 (login flow, `AuthSession` shape, headers, `connection_init`, expiry/refresh behaviour, error codes, dev bypass variables). **If this file exists it wins over anything written here.**
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/02-CONTEXT.md` — the backend decisions (D-01..D-34) this context mirrors.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/02-RESEARCH.md` §"Contenuto minimo BACKEND-NOTES.md" and §Q2 — the contract summary and the verified behaviour of the Dart `graphql` WebSocket client on close codes.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` — generated GraphQL schema (after BE Phase 2 lands).

### Project-level
- `.planning/PROJECT.md` — vision, constraints (single Twitch channel, Twitch-only identity).
- `.planning/REQUIREMENTS.md` — AUTH-01..07 (amended 2026-10-06) and DEV-AUTH-01..05.
- `.planning/ROADMAP.md` §"Phase 11: Auth & Session Bootstrap" and §"Phase 1: Dev Auth Stub".
- `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`, `docs/rules/workflow.md`.

### Phase 1 (what already exists)
- `.planning/phases/01-dev-auth-stub/01-CONTEXT.md`, `01-03-SUMMARY.md`, `01-VERIFICATION.md` — the contract, the stub and the wiring this phase builds on.

### This phase
- `.planning/phases/11-auth-session-bootstrap/11-UI-SPEC.md` — design contract for Splash, SignIn and the logout dialog (still valid; copy for D-18 and the new D-27 message to be aligned).
- `.planning/phases/11-auth-session-bootstrap/11-RESEARCH.md` — April research. **Its OAuth/PKCE/Twitch-endpoint sections are obsolete**; package and platform-setup notes for `flutter_web_auth_2` / `flutter_secure_storage` must be re-verified.

### Research (v1.0)
- `.planning/research/STACK.md` §1–§2 and §4, `.planning/research/PITFALLS.md`, `.planning/research/ARCHITECTURE.md`.

### Codebase maps
- `.planning/codebase/STRUCTURE.md`, `.planning/codebase/CONVENTIONS.md`, `.planning/codebase/INTEGRATIONS.md`, `.planning/codebase/CONCERNS.md`.

### User-rule references (cross-session memory)
- `feedback_no_blocking_loading_in_session.md` — refresh / WS reauth must never block UI in an active session.
- `feedback_no_app_ui_chrome.md` — sign-in is a utility screen, chrome allowed; gameplay screens stay immersive.
- `feedback_backend_handoff_per_phase.md` — keep `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` updated with anything the backend must know.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/repository/services/auth/auth_token_service.dart` — the contract + sealed `AuthState` (`AuthBootstrapping` / `AuthAuthenticated` / `AuthUnauthenticated`). `AuthUnauthenticated` currently carries no reason: the neutral "session expired" message (D-10) needs one.
- `lib/repository/services/auth/dev_auth_token_service.dart` — the stub to extend per D-24/D-25.
- `lib/repository/services/graphql/auth_link.dart` (`AuthAuthLink`) and `lib/repository/services/rest/auth_interceptor.dart` (`AuthInterceptor`) — header injection already in place; this phase adds the reactive refresh-and-retry.
- `lib/repository/services/graphql/graphql_client_provider.dart` — `initGraphQLClient(authTokenService)`; the WS `initialPayload` reads the token **once at boot** (to be fixed per D-07) and there is no dispose/recreate path yet (D-12).
- `lib/screens/splash/splash_screen.dart` + `SplashCubit` — currently only preloads Cloudinary SVGs through REST; becomes the cold-start gate (D-17, D-18).
- `lib/screens/signIn/sign_in_screen.dart` (a `Placeholder`) + `SignInCubit` (stub holding `KlimmeckGraphQl`).
- `lib/config/env_config.dart` — `devAuthEnabled`, `baseUrl`, GraphQL URLs.
- Test scaffolding from Phase 1: `test/helpers/auth_fixtures.dart`, `test/helpers/fixtures/dev_auth_env.dart`, `bloc_test` + `mocktail` already in `dev_dependencies`.

### Established Patterns
- BLoC/Cubit with Repository layer (no service locator, no GetIt, no Provider/ChangeNotifier).
- `RepositoryProvider` above the `BlocProvider` tree for app-wide singletons.
- GraphQL client with `WebSocketLink` (`graphql-transport-ws`) and `Link.split` for HTTP/WS routing.

### Integration Points
- `lib/main.dart` — `_buildAuthTokenService()` composition root; `await authTokenService.initialize()` runs **before** `runApp`, which would block the first frame on a network call once the real service lands: the session resolve must move behind the splash (D-17, and the "no blocking loading" rule). The gameplay `MultiBlocProvider` sits at the root: it must move inside the authenticated subtree so logout disposes every gameplay cubit.
- `lib/routes/` — splash → (sign-in | main) routing depends on the auth state.

### New Code Required
- The real `AuthTokenService` implementation, the secure-storage wrapper, the S256 pair generator, the backend auth API (ticket exchange, refresh, logout, `me`), the browser-auth wrapper around `flutter_web_auth_2`.
- `AuthCubit`, `AuthGate`, the rebuilt `SignInCubit`/`SignInScreen`, the logout confirmation dialog.
- Refresh-and-retry in the GraphQL link and the dio interceptor.
- Platform setup for the `klimmeck://auth` callback (Android manifest, iOS `Info.plist`).

</code_context>

<specifics>
## Specific Ideas

- Cold-start "unstable" message (D-18): *"Connessione instabile, attendere o accedere manualmente"* with an explicit button to sign-in.
- Cold-start revocation message (D-10): *"La sessione è scaduta, accedi di nuovo."*
- Sign-in CTA: "Login con Twitch".
- Twitch-not-configured message (D-27): *"Login con Twitch non ancora disponibile."*
- Logout dialog: "Sei sicuro di voler uscire?" with confirm/cancel.

</specifics>

<deferred>
## Deferred Ideas

- Removing `DevAuthTokenService` and the `DEV_AUTH_*` flags from release builds — Phase 12 (Hardening), as already stated in the roadmap.
- Real-device end-to-end verification of the Twitch login — pending until the Twitch keys exist (D-28).
- Onboarding screens before sign-in.
- Multi-device / multi-session identity policies — Phase 12.
- Biometric gate on app open.
- Refresh-on-resume from `AppLifecycleState`.

</deferred>

---

*Phase: 11-auth-session-bootstrap*
*Context gathered: 2026-04-13 — amended 2026-10-06*
