# Phase 3: Real-Time Sync Foundation - Context

**Gathered:** 2026-10-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Live GraphQL subscriptions on the session's `User` and on its current `Character`, open for the whole authenticated session, so that every downstream feature (quests, travel, spells, combat, admin) consumes authoritative backend state reactively and never polls. The phase delivers the **plumbing**, not new gameplay UI:

- a `User` stream (`twitchPoints`, `role`, `currentCharacter { id }`) feeding the session state that `AuthGate` / `SessionHome` already route on;
- the `Character` stream (`infos`, `status`, `quests`, `assets`) consolidated on the existing `CharacterCubit` path with a clean teardown whenever the character changes;
- silent recovery: on every WebSocket reconnect and on every app resume the full payload is recovered, with no indicator in the UI; a ~3-minute sync-health watchdog ends the session on prolonged failure;
- clean teardown on logout (already Phase 11 D-12) and on character deletion, with no stream leaking into the next session or identity;
- `connection_init` carrying the current token (already Phase 11 D-07/D-37 — verified, not rebuilt).

Out of scope: any new screen or widget (SYNC-07 is satisfied by the `Character.status` values already on screen plus tests for the `User`), the new schema fields that later BE phases add (`activeTravel`, `activeStoryQuest`, `activeWorldMissionQuest` — Phases 6/7 extend `CharacterFragment` when BE Phases 7/8 ship), notification banners (Phase 5), settings/logout entry point (Phase 4), combat result hold on death (Phase 9), admin role gating (Phase 10).

**Backend prerequisite (lockstep):** the backend has no `User` subscription today and `characterUpdated` is filtered only by the client-supplied id. Both land in **BE Phase 3 "Autorizzazione: Ownership, Ruoli, Audit"** (user decision 2026-10-14, no decimal companion phase). This phase proposes the contract in `BACKEND-NOTES.md`, builds against it with fakes, and stays open until the BE ships: schema check against the regenerated `src/schema.gql` and manual E2E happen **before** the FE PR; the BE PR merges first (same discipline as Phase 2 D-33).

</domain>

<decisions>
## Implementation Decisions

### Real-time contract with the backend (SYNC-01, SYNC-02, SYNC-06)
- **D-01:** The `User` stream is a new subscription **`userUpdated: User!` with no arguments**: the backend resolves the identity from the bearer carried by `connection_init` and emits the whole `User` (`id`, `twitchId`, `twitchPoints`, `role`, `currentCharacter { id }`) every time the authenticated user's document changes. The app selects it with the existing `UserFragment`. No client can subscribe to another user.
- **D-02:** `characterUpdated(id: String!)` **keeps its argument**; the backend adds the owner/innkeeper identity filter (BE-AUTHZ-03, BE Phase 3 SC#3). The app keeps passing `currentCharacter.id`; the GraphQL document is unchanged. *(Aligned with the backend 2026-10-14: a subscribe on an id that is not the caller's — and the caller is not innkeeper — is **rejected at subscribe time** with `extensions.code = FORBIDDEN`, delivered as a graphql-transport-ws `next` with errors followed by `complete`, never an `error` frame. The app treats it as terminal: no re-subscribe, one `me` refetch; see D-14.)*
- **D-03:** **Snapshot on subscribe:** the backend emits the current document immediately on every (re)subscription, for both subscriptions. The app treats the snapshot as an ordinary event. Because `graphql` 5.2.1 re-sends the live operations after a socket reconnect, the snapshot closes the event gap of every reconnect (network drop, 4401 JWT expiry every ~15 min, 4403) without any replay on the backend. The app still re-queries explicitly on resume (D-13), since a resume with a still-alive socket produces no re-subscription.
- **D-04:** Both contract changes ship inside **BE Phase 3** — no decimal companion phase (user decision, 2026-10-14, overriding the recommended 2.2 companion). The FE phase develops against the proposed contract with fakes/mocks; its last plan verifies the documents against the regenerated `Klimmeck-Guide-BE/src/schema.gql` and runs the manual E2E before the PR is opened; the BE PR merges first.
- **D-05:** Fields that do not exist in the schema yet (`activeTravel`, `activeStoryQuest`, `activeWorldMissionQuest`) are **not** added to the fragments in this phase. Phases 6/7 extend `CharacterFragment` when BE Phases 7/8 ship; the plumbing built here must make that a fragment-only change.
- **D-06:** The `connection_init` contract is Phase 11's (D-07, D-37, `WsReconnectPolicy`): the current token is read on every connect, 4401/4403 go through the refresh before reconnecting, the link is never recreated after a refresh and only at logout. SYNC-06 is **verified by tests in this phase, not re-implemented**.

### Live `User` in the session and routing (SYNC-01, SYNC-04, SYNC-05)
- **D-07:** `userUpdated` events (and the `me` refetch) enter the session through **`AuthTokenService.adoptUser(User)`**: `AuthAuthenticated.user` stays the single source of truth and `AuthGate` / `SessionHome` already route on `currentCharacter` changes (Phase 2 D-26). An event for another identity is refused by `adoptUser` (returns `false`) and dropped with a log line — a late event of a previous session never enters the next one.
- **D-08:** **There is no admin character swap.** The streamer cannot assign a different character to a user; admins only edit the details of the existing character (user clarification, 2026-10-14). SYNC-05 therefore reduces to *creation* (`null → id`, already D-26) and *deletion* (`id → null`). The planner records the amended wording of SYNC-05 in the phase docs (remove "admin-swap"). As structural insurance the gameplay subtree (`AuthenticatedShell` + its cubits) must be **keyed by `characterId`**, so that any id change recreates shell and cubits: the previous `Character` stream is cancelled before a new one starts, never two live at once, no stale per-character state in Quest/Journal/Shop cubits. Today `AuthenticatedShell` has no such key and `MainScreen.initState` is the only `loadCharacter` caller — this gap is closed here.
- **D-09:** `currentCharacter → null` mid-session routes to the **character creation page silently** (the `SessionHome` branch of Phase 2 D-01), no notice in this phase. Its only sources are: explicit deletion from Settings (Phase 4) and death in combat (Phase 9). On death the Combat Result Sheet must be shown **before** the transition: that hold is Phase 9's job; Phase 3 routes immediately when `currentCharacter` becomes `null`.
- **D-10:** On any character change (`id → null`, `null → id`, `id → id'`) the dialogs and sheets open on the root `Navigator` are popped to the first route, exactly as `AuthGate` already does when the session ends (`_leavesSession`): a sheet may reference the previous character's data or a closed cubit.
- **D-11:** Logout teardown is Phase 11 D-12 unchanged: `GraphQLClientHolder.reset()` disposes the `WebSocketLink` (both subscriptions die) and the session subtree is unmounted (every cubit closed, `SafeEmit` swallows late emissions). SYNC-04 is **verified by tests** (no listener survives into the next session; a second login after logout starts fresh streams against the new client).

### Reconnection, resume and refetch (SYNC-03)
- **D-12:** On every WebSocket reconnect the client's own re-subscription plus the backend snapshot (D-03) recover the gap. Whether to *also* re-run the queries on reconnect is Claude's discretion (one uniform mechanism is acceptable); whatever is chosen must be silent.
- **D-13:** **App resume (background → foreground): always re-query `me` and `character(currentCharacter.id)`**, regardless of the socket state and with no time threshold (two cheap queries per resume on a single channel; iOS kills background sockets anyway). Results are applied through the same paths as subscription events (`adoptUser`, `CharacterLoaded`). Lifecycle observation lives in a widget; the logic lives in testable, Flutter-free classes (state-management rule).
- **D-14:** **Transient failures are silent:** a failed refetch, a stream error or a malformed event, a socket that does not come back — the last known state stays on screen, no indicator, no `CharacterError` in a loaded session. Retry with bounded exponential backoff (reuse `lib/utils/backoff.dart` and the WS backoff 1 → 60 s of `WsReconnectPolicy`).
- **D-15:** **Sync-lost watchdog ≈ 3 minutes (degraded-time clock, clarified 2026-10-14 after research A3):** the clock runs **only while the sync is degraded** — the socket is not connected, or a subscription stream has failed/ended and is being re-established — never while a healthy socket is simply idle (events flow only when something changes, so "no data for 3 minutes" must not eject an idle player). It is reset by a successful connect, any subscription event or snapshot, or a successful refetch; it is suspended while the app is in background and guarded against a logout already in flight. If about three minutes of continuous degradation elapse, the sync is declared lost → **full session teardown as `handleRevocation()`** (client + link recreated, secure storage cleared, `AuthUnauthenticated`) → `SignInScreen` with the inline notice **"Connessione persa, accedi di nuovo."** via a new additive `UnauthenticatedReason` value (same mechanism as Phase 11 D-31/D-32). Any successful event, snapshot, refetch or connect resets the timer. This is a **deliberate departure** from Phase 11 D-09 ("transient failures never log out"), limited to this watchdog: D-09 still governs the refresh path. With the dev stub the watchdog must also lead to the sign-in screen (the stub's `logout()` already emits `AuthUnauthenticated`, D-24); planner verifies the stub's revocation path.
- **D-16:** Cold start is unchanged: `MainScreen` keeps its loader and the `KGError` + pull-to-refresh for a failed *first* `loadCharacter` (loading at cold start is allowed). Only in-session behaviour changes.
- **D-17:** **No QA tooling:** no debug overlay, no connection badge, no dedicated debug log facility (ordinary `debugPrint` / `BlocObserver` only). Verification = automated tests + the final manual E2E against the real backend.

### UI surface (SYNC-07)
- **D-18:** **No new UI.** `twitchPoints` and `role` travel live inside `AuthAuthenticated.user` and are covered by tests; their visual consumers arrive with Phase 6 (quest cost in channel points) and Phase 10 (admin gate on `role`). SYNC-07 is verified on the `Character.status` values already on screen (Profile, Journal, Map, Shop) plus tests for the `User` path.
- **D-19:** Emission granularity is unchanged: each event re-emits the whole `Character` as `CharacterLoaded`. Any rebuild optimisation (`BlocSelector`, `buildWhen`) is Claude's discretion, not a requirement.

### Claude's Discretion
- The component that owns the `userUpdated` subscription (name, Cubit vs plain controller) and its placement per `docs/rules/architecture.md`; it must live inside the session subtree keyed by `user.id` and be the **only** consumer of that stream (`docs/rules/graphql.md`).
- How to observe the socket state (`SocketConnectionState` of the `graphql` `SocketClient`, exposed through `WebSocketLink` or a small wrapper) and how to detect app resume (`AppLifecycleListener` vs `WidgetsBindingObserver`) — the app has neither today.
- Whether queries are also re-run on reconnect (D-12).
- The keying mechanism for the gameplay subtree by `characterId` (D-08) and how `loadCharacter` is re-triggered.
- Watchdog shape (one timer fed by both streams vs per-stream), its placement, and the exact teardown entry point on the `AuthTokenService` (reuse `handleRevocation()` with a reason vs a narrow additive interface, as Phase 11 D-32 did).
- Fake/stub strategy for `userUpdated` until BE Phase 3 ships (recorded `QueryResult` streams in tests; no production stub).
- `BlocSelector`/`buildWhen` optimisations (D-19).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` §"Phase 3: Real-Time Sync Foundation" — goal, success criteria 1–5, the two open questions (client choice → stays `graphql_flutter`; `connection_init` → Phase 11 contract).
- `.planning/REQUIREMENTS.md` — SYNC-01..SYNC-07 (SYNC-05 wording to be amended per D-08).
- `.planning/PROJECT.md` §"Key Decisions" — "Sync utente via GraphQL subscription", "Backend fonte di verità".

### Prior phase decisions this phase builds on
- `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md` — D-07/D-37 (token on every connect, link never recreated after refresh), D-09 (transient refresh failures never log out — D-15 here is the explicit exception), D-10/D-31/D-32 (`AuthUnauthenticated.reason`, inline notice on SignIn — reused for "Connessione persa"), D-12 (logout teardown order), D-33 (bootstrap after first frame), D-38 (never `dart format` whole directories).
- `.planning/phases/11-auth-session-bootstrap/BACKEND-NOTES.md` §4 "WebSocket" and §6 open question 1 — the reconnect gap this phase closes (snapshot on subscribe + refetch).
- `.planning/phases/02-character-creation/02-CONTEXT.md` — D-01 (`SessionHome` branch on `currentCharacter`), D-02/D-26 (`adoptUser`, `AuthGate._changesCharacter`), D-27 (real character id into the shell), D-33 (schema check before PR, BE PR first).
- `.planning/phases/02-character-creation/BACKEND-NOTES.md` — §1 step 5 (how the new character enters `characterUpdated`), §3 (identity from the bearer only).

### Backend (separate repo — contract and current implementation)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` — current schema: `type Subscription { characterUpdated(id: String!): Character! }`, `type User`, `Character*` types. **Wins over any document here once regenerated by BE Phase 3.**
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/characters/characters.resolver.ts` — current `@Subscription characterUpdated` with id-only filter.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/characters/characters.service.ts` — Mongo change stream (`update`/`replace` only → a deleted character emits nothing) → `pubSub.publish('characterUpdated')`.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/pubsub.module.ts` — `PUB_SUB` provider and `PubSubEvents` map (to be extended with `userUpdated`).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/ROADMAP.md` §"Phase 3: Autorizzazione: Ownership, Ruoli, Audit" — SC#3 "`characterUpdated` (e lo user stream) emette solo al proprietario/innkeeper".
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/REQUIREMENTS.md` — BE-AUTH-03 (WS `connection_init` contract, done), BE-AUTHZ-03 (identity-filtered subscriptions, pending).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md` — WS authentication contract (`Authorization: Bearer` in `connection_init`, close codes 4401/4403).
- `.planning/phases/03-real-time-sync-foundation/BACKEND-NOTES.md` — this phase's handoff: the proposed `userUpdated` / snapshot / filter contract and the open questions for the BE agent. Keep it updated during the phase.

### Project rules
- `docs/rules/graphql.md` — §Subscription (one consumer per stream, cancel in `close()`, invisible reconnection), §Error handling, document naming (`OnXxxChanged`).
- `docs/rules/state-management.md` — Cubit rules (no Flutter deps, `StreamSubscription` as private field, cancel in `close()`), `BlocListener` for side effects.
- `docs/rules/architecture.md` — where services, repositories and cubits live.
- `docs/rules/testing.md` — `bloc_test` for every non-trivial cubit, controlled streams instead of delays.
- `docs/rules/workflow.md` — branch `feat/real-time-sync-foundation` (created 2026-10-14), PR to `develop`, commit style.
- `CLAUDE.md` rule #2 (no blocking loading in an active session) and ROADMAP "UX Principles" (no reconnection banners, no status indicators in gameplay screens).

### Library behaviour to verify in research
- `~/.pub-cache/hosted/pub.dev/graphql-5.2.1/lib/src/links/websocket_link/websocket_client.dart` — `SocketConnectionState` (`notConnected/handshake/connecting/connected`), `_connectionStateController` (BehaviorSubject), `onConnectionLost` hook (already used by `WsReconnectPolicy`), and how live subscriptions are re-sent after reconnect. Confirm what `WebSocketLink` exposes publicly for observing connection state.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/characterCubit/character_cubit.dart` — already does query-then-subscribe (`loadCharacter` → `getCharacter` → `subscribeToCharacter`), holds one `StreamSubscription`, cancels it in `close()`, uses `SafeEmit`. Base for the Character side; today it emits `CharacterError` on stream errors (to change per D-14) and nobody re-subscribes on reconnect.
- `lib/repository/services/graphql/graphql.dart` (`KlimmeckGraphQl`) — `performSubscription`, `subscribeToCharacter(id)`, `getCharacter(id)`, `getMe()` (returns `User` via `_userFrom`, FormatException boundary). The `userUpdated` document and a `subscribeToUser()` method slot in here; `resolveClient` is injectable for tests.
- `lib/graphql/subscriptions/character_subscriptions.dart`, `lib/graphql/fragments/user_fragment.dart`, `lib/graphql/fragments/character_fragment.dart` — documents/fragments to extend (new `user_subscriptions.dart`); `CharacterFragment.fullFields` is what D-05 leaves untouched.
- `lib/repository/services/graphql/ws_reconnect_policy.dart` — token per connect, 4401/4403 recovery, bounded backoff; its dartdoc already says "il refetch-on-reconnect è responsabilità di Phase 3".
- `lib/repository/services/graphql/graphql_client_holder.dart` — `reset()` disposes the WS link and recreates client+link (logout teardown, D-11); `ValueNotifier<GraphQLClient>` consumed through a resolver.
- `lib/repository/services/graphql/graphql_client_provider.dart` — `buildGraphQLConnection` with `SocketClientConfig(autoReconnect: true, inactivityTimeout: EnvConfig.wsInactivityTimeoutSeconds, initialPayload, onConnectionLost)`; the natural place to surface connection state.
- `lib/repository/services/auth/auth_token_service.dart` — `adoptUser(User)` (D-07 entry point), `handleRevocation()` (D-15 teardown), `AuthUnauthenticated.reason` enum (additive value for "Connessione persa"). Both `SessionAuthTokenService` and `DevAuthTokenService` implement `adoptUser` with the same-id guard.
- `lib/screens/auth/auth_gate.dart` — `_shouldRebuild` / `_changesCharacter` / `_leavesSession` + `popUntil(isFirst)` listener: extend the listener to character changes (D-10).
- `lib/screens/auth/session_home.dart` — `currentCharacter == null` → creation, else `shellBuilder(context, character.id)` (D-09 already works through it).
- `lib/screens/auth/authenticated_shell.dart` — mounts all gameplay cubits; **no key on `characterId`**, `_ShellBody.initState` re-runs `SplashCubit.getImages('main')` (a rebuild must not re-show the splash — `SplashCubit` lives above `AuthGate`, its `SplashData` state persists). Target of D-08.
- `lib/screens/mainScreen/main_screen.dart` — `initState` is the only `loadCharacter` caller; `BlocListener<CharacterCubit>` gates `MainScreenCubit.loadData()` on the first `CharacterLoaded`.
- `lib/shared/bloc/safe_emit.dart` — late emissions after close are ignored (relevant to teardown tests).
- `lib/utils/backoff.dart` — `exponentialBackoff(attempt, max:)` for D-14.
- `lib/models/user.dart` — `User.fromJson` with `currentCharacter` parsed from `{ id }` only (as Phase 2 does), `copyWith`, Equatable.
- `lib/config/env_config.dart` — `graphqlWsUrl`, `wsInactivityTimeoutSeconds`, `queryTimeoutSeconds`.
- Tests: `test/helpers/` (`auth_fixtures.dart`, `fakes/`, `mocks.dart`, `test_app.dart`), `test/network/graphql_auth_link_test.dart`, `test/screens/auth/*` (AuthGate/AuthenticatedShell tests to extend), `test/repository/services/*`.

### Established Patterns
- BLoC/Cubit + repository layer, explicit DI through constructors, no service locator; `RepositoryProvider<AuthTokenService>` above the `BlocProvider` tree; gameplay cubits scoped to `AuthenticatedShell`.
- GraphQL documents as Dart strings in `lib/graphql/`, fragments composed by interpolation; `fetchPolicy: noCache` everywhere; errors mapped at the repository/service boundary (`FormatException`, typed failures), never raw `OperationException` in UI.
- Session state flows one way: `AuthTokenService` → `AuthCubit` → `AuthGate` → subtree keyed by `user.id`.
- Phase 11 conventions: additive interfaces instead of contract changes (`UnauthorizedRecovery`, `AuthUnauthenticated.reason`), single-flight for anything that may race, Flutter-free logic under `lib/repository/services/`.
- Tests with fakes and `bloc_test`; `dart format` only on touched files (D-38).

### Integration Points
- `lib/main.dart` — composition root: `buildGraphQLConnection`, `GraphQLClientHolder`, `AuthGate(authenticatedBuilder: SessionHome(...))`; the lifecycle observer and the User-stream owner are wired here / in the session subtree.
- `AuthenticatedShell` ↔ `MainScreen` — keying by `characterId` and `loadCharacter` re-trigger (D-08).
- `KlimmeckGraphQl` — new `subscribeToUser()`, reused `getMe()` / `getCharacter()` for refetch (D-13).
- `AuthTokenService` — `adoptUser` as the ingress for live `User` (D-07); revocation path with a new reason (D-15); `SignInScreen` notice text.
- Backend: `userUpdated` resolver + publisher, identity filter on `characterUpdated`, snapshot on subscribe (BE Phase 3) — see `BACKEND-NOTES.md`.

### Gaps found during scouting
- No `AppLifecycleListener` / `WidgetsBindingObserver` anywhere in `lib/` (needed for D-13).
- `CharacterError` / `CharacterLoading` are emitted but consumed by no widget.
- `twitchPoints` / `role` have no UI consumer (consistent with D-18).
- Mongo change stream on the BE matches only `update`/`replace`: a deleted character emits no `characterUpdated`; the app learns of deletion through `userUpdated.currentCharacter == null` (D-09).

</code_context>

<specifics>
## Specific Ideas

- "L'admin non può assegnare ad uno user un personaggio diverso. Può cambiare dettagli del personaggio e basta." — no swap scenario exists (D-08).
- "Il personaggio viene cancellato solo su richiesta esplicita dell'utente dalle impostazioni (cosa che lo riporterà alla creazione personaggio) o può essere ucciso durante uno scontro. In quel caso l'utente vede il risultato del combattimento e poi viene riportato alla schermata di creazione personaggio." — deletion sources and the Phase 9 ordering (D-09).
- "Retry silenzioso, se non ci si riesce a ricollegare allora schermata di errore e riporti l'utente alla login" — the surface chosen for that error is the `SignInScreen` inline notice after a full teardown (D-15), threshold ≈ 3 minutes.
- Stream errors are to be treated "come tutti gli altri errori": silent retry first, session end only when the watchdog expires (D-14/D-15).
- Notice text (Italian, inline on SignIn): **"Connessione persa, accedi di nuovo."**

</specifics>

<deferred>
## Deferred Ideas

- **Phase 9 (Combat Result):** when the character dies, the transition to the creation page must wait until the Combat Result Sheet is dismissed — a routing hold on `currentCharacter == null`. Phase 3 routes immediately (D-09); Phase 9 adds the hold.
- **Phase 4 (Settings):** explicit character deletion from Settings relies on `userUpdated` emitting `currentCharacter: null` → creation page (no extra wiring expected in Phase 4 beyond the mutation).
- **REQUIREMENTS SYNC-05 wording:** drop "admin-swap" (the admin never reassigns characters) — amend when the planner touches REQUIREMENTS traceability.
- **Profile tab channel-points line:** a live `twitchPoints` display in the Profile was considered and rejected for this phase (D-18); revisit with Phase 6 (quest cost) or a Profile UI phase.
- **Debug connection badge / dedicated sync logs:** rejected (D-17); could become a Phase 12 hardening/diagnostics item if QA needs it.
- **Backend replay/resume tokens:** not needed thanks to snapshot-on-subscribe; BE-FUT-02 (Redis PubSub for horizontal scaling) stays out of scope.
- **Snapshot-on-subscribe reuse:** the same backend pattern will serve Phase 10's admin pending-request subscription (BE-ADMIN-01).

</deferred>

---

*Phase: 03-real-time-sync-foundation*
*Context gathered: 2026-10-14*
