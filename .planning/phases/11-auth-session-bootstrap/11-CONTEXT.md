# Phase 11: Auth & Session Bootstrap - Context

**Gathered:** 2026-04-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Twitch OAuth identity end-to-end: login via system browser (PKCE, no WebView), encrypted token storage, transparent silent refresh, hard logout that fully tears down session state, account-switch guarantee, and detection of external token revocation. Outcome: an `AuthTokenService` exposed above the BLoC tree, ready for downstream phases (subscriptions, character creation, settings, notifications) to consume.

Out of scope for this phase: character creation flow, settings screen, notification permission flow, GraphQL subscription content. Only the *auth substrate* and the *sign-in utility screen*.

</domain>

<decisions>
## Implementation Decisions

### AuthTokenService — shape & placement
- **D-01:** `AuthTokenService` is a singleton exposed via `RepositoryProvider` placed above the `BlocProvider` tree (mirrors the existing `KlimmeckGraphQl` pattern — see `lib/repository/services/graphql/`).
- **D-02:** Public surface: `Stream<AuthState>` (Authenticated / Unauthenticated / Bootstrapping), `Future<String?> getAccessToken()` (returns the current valid access token, performs a refresh first if it knows the token is near/past expiry), `Future<void> login()`, `Future<void> logout()`, `Future<void> handleRevocation()`.
- **D-03:** `dio` interceptor and `graphql_flutter` link consume the service through the same provider — no service locator, no static globals.

### Token refresh strategy (AUTH-06)
- **D-04:** **Refresh must never block UI in an active session** (project-wide rule, see `feedback_no_blocking_loading_in_session.md`). No spinners, no overlays during in-session refresh.
- **D-05:** Strategy is **proactive scheduled refresh** based on `expires_in` (refresh ~60s before expiry, recomputed on each successful refresh), with a **reactive on-401 fallback** for missed firings (background app, clock skew).
- **D-06:** Concurrent in-flight requests during a refresh are serialized via a **single-flight mutex** (a shared `Completer<String>`): the first 401 triggers the refresh, all subsequent 401s await the same Completer and retry with the new token. Exactly one network refresh per refresh cycle.
- **D-07:** After a successful refresh, the new access token must be propagated to the **WebSocket `connection_init` payload** so live subscriptions remain authorized. Implementation detail (push to existing `WebSocketLink` initialPayload or recreate the link) is researcher/planner discretion; the contract is that the next subscription event must travel on a connection authorized with the fresh token.

### Revocation detection (AUTH-07)
- **D-08:** Cold start always calls Twitch `https://id.twitch.tv/oauth2/validate` *before* declaring the session valid. Result decides splash → main vs splash → sign-in.
- **D-09:** In-session detection: a refresh that fails with HTTP 400/401 + `error=invalid_grant` is treated as revocation → trigger logout teardown (D-10..D-15) and route to sign-in. Transient failures (5xx, network) do not trigger logout — retry with backoff inside the proactive refresh.
- **D-10:** Cold-start revocation message is neutral: "La sessione è scaduta, accedi di nuovo." (no accusation of explicit revocation — the cause may be natural refresh-token expiry).

### Logout teardown (AUTH-04, AUTH-05)
- **D-11:** Logout always asks for explicit user confirmation via dialog ("Sei sicuro di voler uscire?"). No silent logouts initiated by the user.
- **D-12:** Teardown order is fixed and atomic from the user's perspective: (1) revoke token on Twitch (best-effort, see D-13), (2) cancel all active GraphQL subscriptions, (3) **dispose and recreate the entire `GraphQLClient` + `WebSocketLink`** (not `store.reset()` — full client recreation guarantees zero listener leaks and a clean `connection_init` for the next session), (4) clear `flutter_secure_storage` of access + refresh + user_id, (5) emit `Unauthenticated` and route to sign-in.
- **D-13:** Step 1 (Twitch revoke `https://id.twitch.tv/oauth2/revoke`) is **best-effort with a 3–5s timeout**. Failure (offline, 5xx) is logged as a warning but does NOT block the rest of the teardown — the user must be able to log out even with no network. The token will expire naturally server-side.
- **D-14:** Switching account (AUTH-05) reuses the same logout teardown, then re-enters the OAuth flow with `force_verify=true` (see D-16).

### Account switch & OAuth URL (AUTH-05, AUTH-01)
- **D-15:** OAuth flow is **`flutter_web_auth_2` + system browser + `klimmeck://auth` deep link + PKCE** (locked from research/STACK.md). No WebView (Twitch TOS).
- **D-16:** The auth URL ALWAYS includes `force_verify=true` — even on first login. This guarantees account-swap pulizia regardless of system-browser SSO state. The minor cost (one extra confirmation tap on first login) is accepted for AUTH-05 correctness.

### Bootstrap & Splash UX
- **D-17:** Reuse the existing `lib/screens/splash/splash_screen.dart` (and its `SplashCubit`) as the cold-start gate. The splash performs the auth resolve as its **first action**: load token from secure storage → call Twitch validate → emit Authenticated / Unauthenticated.
- **D-18:** Cold-start network/timeout handling: **retry the validate/refresh indefinitely** in the background, but **after 10 seconds** the splash surfaces a non-blocking message: *"Connessione a Twitch instabile, attendere o accedere manualmente"* with a button that routes to the sign-in screen. The retry loop continues in the background — if it eventually succeeds and the user has not pressed the button, the app proceeds to main shell.
- **D-19:** No token in storage → splash routes immediately to sign-in (no onboarding, no intermediate screen).

### Sign-in screen (utility screen — chrome allowed)
- **D-20:** Layout: Klimmeck logo + tagline + Twitch-branded "Login con Twitch" button + footer with TOS/Privacy links. Per memory rule, this is a utility screen so app-style chrome is acceptable here.
- **D-21:** OAuth user-cancel handling: `flutter_web_auth_2` raises `PlatformException(CANCELED)` → catch silently, leave the sign-in screen untouched. No snackbar, no error — cancellation is a legitimate action.
- **D-22:** OAuth network/server errors: show inline error on the sign-in screen ("Errore di connessione, riprova"), keep the button enabled for retry.

### Claude's Discretion
- Exact dialog widget for logout confirmation (use existing app dialog pattern if one exists in `lib/shared/`).
- TOS/Privacy URLs (placeholders are fine for v1; real URLs to be supplied later).
- Twitch button styling specifics (color, icon) — pick something coherent with both Twitch brand guidelines and the app theme in `lib/theme/`.
- Choice of mutex primitive (Completer-based vs `synchronized` package) — both acceptable; prefer no new package if Completer is sufficient.
- Whether to recreate the `WebSocketLink` after refresh vs hot-update its initialPayload — pick whichever is verified to actually carry the new token to the backend's `connection_init`.
- Storage keys naming and a small `SecureStorage` wrapper if it improves testability.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project-level
- `.planning/PROJECT.md` — Vision, constraints (single Twitch channel, OAuth-only identity).
- `.planning/REQUIREMENTS.md` — AUTH-01..07 acceptance criteria.
- `.planning/ROADMAP.md` §"Phase 11: Auth & Session Bootstrap" — phase goal, success criteria, dependencies.
- `.planning/STATE.md` — Open questions including OAuth flow choice (now resolved here).

### Research (already produced for v1.0)
- `.planning/research/STACK.md` §1 (Twitch OAuth) and §2 (Secure Token Storage) — package choices and platform setup checklists for `flutter_web_auth_2` and `flutter_secure_storage`. **Read this before adding packages.**
- `.planning/research/STACK.md` §4 (GraphQL Subscriptions) — confirms `WebSocketLink` is already wired and notes the `connection_init` auth concern relevant to D-07.
- `.planning/research/PITFALLS.md` — read for known auth/session pitfalls.
- `.planning/research/ARCHITECTURE.md` — read for layering and provider patterns.

### Codebase maps
- `.planning/codebase/STRUCTURE.md` — directory layout (signIn screen lives at `lib/screens/signIn/`, splash at `lib/screens/splash/`).
- `.planning/codebase/CONVENTIONS.md` — BLoC/Cubit + Repository conventions to follow for `AuthTokenService` and `AuthCubit`.
- `.planning/codebase/INTEGRATIONS.md` — existing GraphQL + dio integration points the new service must hook into.
- `.planning/codebase/CONCERNS.md` — pre-existing concerns (Firebase init incomplete is unrelated to this phase).

### External (Twitch)
- Twitch OAuth Authorization Code Flow with PKCE: `https://dev.twitch.tv/docs/authentication/getting-tokens-oauth/#authorization-code-grant-flow`
- Twitch token validate endpoint: `https://dev.twitch.tv/docs/authentication/validate-tokens/`
- Twitch token revoke endpoint: `https://dev.twitch.tv/docs/authentication/revoke-tokens/`

### User-rule references (cross-session memory)
- Memory: `feedback_no_blocking_loading_in_session.md` — refresh / WS reauth / validate must never block UI in an active session.
- Memory: `feedback_no_app_ui_chrome.md` — sign-in is a utility screen, chrome allowed; gameplay screens stay immersive.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/splash/splash_screen.dart` + `SplashCubit` — repurpose as the cold-start auth gate (D-17, D-18).
- `lib/screens/signIn/sign_in_screen.dart` + `SignInCubit` (currently a stub holding `KlimmeckGraphQl`) — extend / replace cubit body to drive the OAuth flow and consume `AuthTokenService`.
- `lib/repository/services/graphql/` (`KlimmeckGraphQl`, `graphql_client_provider.dart`) — pattern to follow for `AuthTokenService`; also the place that must be refactored so the GraphQL client can be torn down + recreated on logout (D-12).
- `dio` is already a dependency — used for the OAuth token exchange (POST to `id.twitch.tv/oauth2/token`) and for any REST call interceptors.
- `firebase_messaging` and `firebase_core` are present in pubspec (irrelevant to this phase, but do not let bootstrap accidentally initialize them — that belongs to a later phase).

### Established Patterns
- BLoC/Cubit with Repository layer (no service locator, no GetIt, no Provider/ChangeNotifier).
- `RepositoryProvider` placed above the `BlocProvider` tree for app-wide singletons.
- GraphQL client configured in `graphql_client_provider.dart` with `WebSocketLink` (`graphql-transport-ws`) and `Link.split` for HTTP/WS routing — this is the surface the auth service interacts with.

### Integration Points
- `main.dart` — must initialize `AuthTokenService` (read storage, attempt refresh) before runApp's first frame, OR initialize it lazily and let `SplashCubit` await it. Either works; planner picks one.
- `graphql_client_provider.dart` — needs to (a) source the access token from `AuthTokenService` for both HTTP headers and `WebSocketLink` initialPayload, and (b) expose a way to dispose + recreate the client on logout (D-12).
- `lib/routes/routes.dart` — splash → (signin | main) routing depends on `AuthTokenService` state stream.

### New Code Required
- `AuthTokenService` (repository service, lives in `lib/repository/services/auth/`).
- `AuthCubit` (or substantially extended `SignInCubit`) — handles the OAuth call, error UX, cancel handling.
- Logout dialog widget (or reuse if a generic confirmation dialog exists in `lib/shared/`).
- `dio` interceptor for 401 + retry (D-06).

</code_context>

<specifics>
## Specific Ideas

- Cold-start "instabile" message wording (D-18): *"Connessione a Twitch instabile, attendere o accedere manualmente"* with an explicit button to sign-in.
- Cold-start revocation message wording (D-10): *"La sessione è scaduta, accedi di nuovo."* (neutral, not accusatory).
- Sign-in CTA wording: "Login con Twitch".
- Logout dialog wording: "Sei sicuro di voler uscire?" with confirm/cancel.

</specifics>

<deferred>
## Deferred Ideas

- Onboarding screens before sign-in — out of scope for v1; can be added later if first-install conversion is a problem.
- Persistent retry queue for failed Twitch revoke (offline logout) — over-engineered for v1; D-13 best-effort + natural server-side expiry is the agreed trade-off.
- Multi-device / multi-session identity policies — Phase 11 (Hardening) territory.
- Biometric gate on app open (FaceID / fingerprint before reaching session) — not in v1 requirements.
- Refresh-on-resume from `AppLifecycleState` (validate Twitch when app comes back from background) — can be added if revocation detection in-session proves insufficient; not required by AUTH-07.

</deferred>

---

*Phase: 11-auth-session-bootstrap*
*Context gathered: 2026-04-13*
