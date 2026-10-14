# Phase 3: Real-Time Sync Foundation - Research

**Researched:** 2026-10-14
**Domain:** Flutter / `graphql` 5.2.1 WebSocket subscriptions (graphql-transport-ws), session-scoped sync lifecycle, BLoC teardown
**Confidence:** HIGH on library behaviour (read from installed source AND exercised against a local fake server), MEDIUM on device-level behaviour (real iOS/Android lifecycle, half-open sockets) and on the not-yet-implemented backend wire format.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Real-time contract with the backend (SYNC-01, SYNC-02, SYNC-06)**
- **D-01:** The `User` stream is a new subscription **`userUpdated: User!` with no arguments**: the backend resolves the identity from the bearer carried by `connection_init` and emits the whole `User` (`id`, `twitchId`, `twitchPoints`, `role`, `currentCharacter { id }`) every time the authenticated user's document changes. The app selects it with the existing `UserFragment`. No client can subscribe to another user.
- **D-02:** `characterUpdated(id: String!)` **keeps its argument**; the backend adds the owner/innkeeper identity filter (BE-AUTHZ-03, BE Phase 3 SC#3). The app keeps passing `currentCharacter.id`; the GraphQL document is unchanged. An id that is not the caller's simply receives nothing.
- **D-03:** **Snapshot on subscribe:** the backend emits the current document immediately on every (re)subscription, for both subscriptions. The app treats the snapshot as an ordinary event. Because `graphql` 5.2.1 re-sends the live operations after a socket reconnect, the snapshot closes the event gap of every reconnect (network drop, 4401 JWT expiry every ~15 min, 4403) without any replay on the backend. The app still re-queries explicitly on resume (D-13), since a resume with a still-alive socket produces no re-subscription.
- **D-04:** Both contract changes ship inside **BE Phase 3** — no decimal companion phase (user decision, 2026-10-14, overriding the recommended 2.2 companion). The FE phase develops against the proposed contract with fakes/mocks; its last plan verifies the documents against the regenerated `Klimmeck-Guide-BE/src/schema.gql` and runs the manual E2E before the PR is opened; the BE PR merges first.
- **D-05:** Fields that do not exist in the schema yet (`activeTravel`, `activeStoryQuest`, `activeWorldMissionQuest`) are **not** added to the fragments in this phase. Phases 6/7 extend `CharacterFragment` when BE Phases 7/8 ship; the plumbing built here must make that a fragment-only change.
- **D-06:** The `connection_init` contract is Phase 11's (D-07, D-37, `WsReconnectPolicy`): the current token is read on every connect, 4401/4403 go through the refresh before reconnecting, the link is never recreated after a refresh and only at logout. SYNC-06 is **verified by tests in this phase, not re-implemented**.

**Live `User` in the session and routing (SYNC-01, SYNC-04, SYNC-05)**
- **D-07:** `userUpdated` events (and the `me` refetch) enter the session through **`AuthTokenService.adoptUser(User)`**: `AuthAuthenticated.user` stays the single source of truth and `AuthGate` / `SessionHome` already route on `currentCharacter` changes (Phase 2 D-26). An event for another identity is refused by `adoptUser` (returns `false`) and dropped with a log line — a late event of a previous session never enters the next one.
- **D-08:** **There is no admin character swap.** The streamer cannot assign a different character to a user; admins only edit the details of the existing character (user clarification, 2026-10-14). SYNC-05 therefore reduces to *creation* (`null → id`, already D-26) and *deletion* (`id → null`). The planner records the amended wording of SYNC-05 in the phase docs (remove "admin-swap"). As structural insurance the gameplay subtree (`AuthenticatedShell` + its cubits) must be **keyed by `characterId`**, so that any id change recreates shell and cubits: the previous `Character` stream is cancelled before a new one starts, never two live at once, no stale per-character state in Quest/Journal/Shop cubits. Today `AuthenticatedShell` has no such key and `MainScreen.initState` is the only `loadCharacter` caller — this gap is closed here.
- **D-09:** `currentCharacter → null` mid-session routes to the **character creation page silently** (the `SessionHome` branch of Phase 2 D-01), no notice in this phase. Its only sources are: explicit deletion from Settings (Phase 4) and death in combat (Phase 9). On death the Combat Result Sheet must be shown **before** the transition: that hold is Phase 9's job; Phase 3 routes immediately when `currentCharacter` becomes `null`.
- **D-10:** On any character change (`id → null`, `null → id`, `id → id'`) the dialogs and sheets open on the root `Navigator` are popped to the first route, exactly as `AuthGate` already does when the session ends (`_leavesSession`): a sheet may reference the previous character's data or a closed cubit.
- **D-11:** Logout teardown is Phase 11 D-12 unchanged: `GraphQLClientHolder.reset()` disposes the `WebSocketLink` (both subscriptions die) and the session subtree is unmounted (every cubit closed, `SafeEmit` swallows late emissions). SYNC-04 is **verified by tests** (no listener survives into the next session; a second login after logout starts fresh streams against the new client).

**Reconnection, resume and refetch (SYNC-03)**
- **D-12:** On every WebSocket reconnect the client's own re-subscription plus the backend snapshot (D-03) recover the gap. Whether to *also* re-run the queries on reconnect is Claude's discretion (one uniform mechanism is acceptable); whatever is chosen must be silent.
- **D-13:** **App resume (background → foreground): always re-query `me` and `character(currentCharacter.id)`**, regardless of the socket state and with no time threshold (two cheap queries per resume on a single channel; iOS kills background sockets anyway). Results are applied through the same paths as subscription events (`adoptUser`, `CharacterLoaded`). Lifecycle observation lives in a widget; the logic lives in testable, Flutter-free classes (state-management rule).
- **D-14:** **Transient failures are silent:** a failed refetch, a stream error or a malformed event, a socket that does not come back — the last known state stays on screen, no indicator, no `CharacterError` in a loaded session. Retry with bounded exponential backoff (reuse `lib/utils/backoff.dart` and the WS backoff 1 → 60 s of `WsReconnectPolicy`).
- **D-15:** **Sync-lost watchdog ≈ 3 minutes:** if for about three minutes continuously neither subscription receives data (or reconnects) and no refetch succeeds, the sync is declared lost → **full session teardown as `handleRevocation()`** (client + link recreated, secure storage cleared, `AuthUnauthenticated`) → `SignInScreen` with the inline notice **"Connessione persa, accedi di nuovo."** via a new additive `UnauthenticatedReason` value (same mechanism as Phase 11 D-31/D-32). Any successful event, snapshot, refetch or connect resets the timer. This is a **deliberate departure** from Phase 11 D-09 ("transient failures never log out"), limited to this watchdog: D-09 still governs the refresh path. With the dev stub the watchdog must also lead to the sign-in screen (the stub's `logout()` already emits `AuthUnauthenticated`, D-24); planner verifies the stub's revocation path.
- **D-16:** Cold start is unchanged: `MainScreen` keeps its loader and the `KGError` + pull-to-refresh for a failed *first* `loadCharacter` (loading at cold start is allowed). Only in-session behaviour changes.
- **D-17:** **No QA tooling:** no debug overlay, no connection badge, no dedicated debug log facility (ordinary `debugPrint` / `BlocObserver` only). Verification = automated tests + the final manual E2E against the real backend.

**UI surface (SYNC-07)**
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

### Deferred Ideas (OUT OF SCOPE)
- **Phase 9 (Combat Result):** when the character dies, the transition to the creation page must wait until the Combat Result Sheet is dismissed — a routing hold on `currentCharacter == null`. Phase 3 routes immediately (D-09); Phase 9 adds the hold.
- **Phase 4 (Settings):** explicit character deletion from Settings relies on `userUpdated` emitting `currentCharacter: null` → creation page (no extra wiring expected in Phase 4 beyond the mutation).
- **REQUIREMENTS SYNC-05 wording:** drop "admin-swap" (the admin never reassigns characters) — amend when the planner touches REQUIREMENTS traceability.
- **Profile tab channel-points line:** a live `twitchPoints` display in the Profile was considered and rejected for this phase (D-18); revisit with Phase 6 (quest cost) or a Profile UI phase.
- **Debug connection badge / dedicated sync logs:** rejected (D-17); could become a Phase 12 hardening/diagnostics item if QA needs it.
- **Backend replay/resume tokens:** not needed thanks to snapshot-on-subscribe; BE-FUT-02 (Redis PubSub for horizontal scaling) stays out of scope.
- **Snapshot-on-subscribe reuse:** the same backend pattern will serve Phase 10's admin pending-request subscription (BE-ADMIN-01).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SYNC-01 | After login, a GraphQL subscription on the current `User` delivers live `twitchPoints`, `role`, `currentCharacter` | `OnUserChanged` document + `KlimmeckGraphQl.subscribeToUser()` + `SessionSyncCubit` (single consumer) feeding `AuthTokenService.adoptUser` (Patterns 1, 2) |
| SYNC-02 | After the current `Character` is known, a subscription delivers live `infos`, `status`, `quests`, `assets` | Existing `CharacterCubit` query-then-subscribe, hardened for silent resubscribe (Pattern 3); document unchanged (D-02/D-05) |
| SYNC-03 | Both subscriptions auto-reconnect silently after network drop or app resume and recover the full payload; no indicator | Verified: `SocketClient` re-sends live operations on the same stream after reconnect (probe P1); snapshot closes the gap; resume refetch via lifecycle events (Pattern 4); half-open-socket detection via `pingInterval` (Pitfall 2); error/done resubscribe with backoff (Pitfall 4) |
| SYNC-04 | Both subscriptions closed cleanly on logout; no leakage into the next session | `GraphQLClientHolder.reset()` + subtree unmount; verified dispose semantics (probe P4); leak tests via fake WS server (Validation Architecture) |
| SYNC-05 | Character subscription rebuilt against the new `currentCharacter.id` without leaking the previous stream (wording to be amended: creation/deletion only, no admin-swap) | `ValueKey('character:<id>')` in `SessionHome` + AuthGate pop on character change (Pattern 5) |
| SYNC-06 | WS `connection_init` carries the current token, updated after refresh, for both subscriptions | Already Phase 11 (`WsReconnectPolicy`); verified-not-rebuilt: integration test against the fake WS server (probe confirmed `initialPayload` is re-evaluated on every connect, `inits=2` after a 4401) |
| SYNC-07 | Displayed `twitchPoints` and `Character.status` update live | `AuthAuthenticated.user` carries live values; `CharacterLoaded` carries live status; tests at cubit/AuthCubit level + one status consumer widget test (D-18: no new UI) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

Treated with the same authority as locked decisions.

- **Principles always applied:** Clean Code, SoC (UI no networking, Cubit no widgets/BuildContext, Repository no BuildContext, Model no Flutter), **TDD (test written BEFORE the implementation, Red -> Green -> Refactor)**, Boy Scout Rule (fix small issues in touched files, same commit; massive refactors out of scope).
- **Inviolable rules:** (1) no UI chrome outside utility screens; (2) **no blocking loading in an active session** (refresh/validation/WS reconnect invisible; spinner only at cold start or explicit user action); (3) **branch + PR per GSD phase** (branch `feat/real-time-sync-foundation`, PR target `develop`, never push to `develop`/`main`); (4) the backend is the source of truth (the frontend is reactive, never computes progression/HP/etc.); (5) no secrets in the repo.
- **Commands:** `flutter pub get`, `flutter analyze` (must be clean before a PR), `flutter test`, `dart format` **only on touched files** (project memory + Phase 11 D-38: never on `lib`/`test` directories, the baseline is not formatter-clean; verify with `dart format --output=none --set-exit-if-changed <files>`).
- **Commit hygiene (project memory):** commit scope `phase-3` (not `03`); no `Co-Authored-By: Claude` trailer in commits; BE handoff notes kept in `.planning/phases/03-real-time-sync-foundation/BACKEND-NOTES.md`.
- **Rule files read:** `docs/rules/graphql.md` (one operation = one explicit name `OnXxxChanged`; documents only in `lib/graphql/`; one consumer per subscription; cancel in `close()`; never print full payloads), `state-management.md` (Cubit has no Flutter deps; private `StreamSubscription`; no cubit-calls-cubit; `BlocListener` for side effects), `architecture.md` (UI -> Cubit -> Repository -> Service), `testing.md` (bloc_test per cubit, mocktail, no `Future.delayed` to sync tests, fixtures in `test/helpers/fixtures/`), `naming.md`.
- **Baseline recorded for this research (2026-10-14, branch `feat/real-time-sync-foundation`):** `flutter test` = **481 tests pass in ~18 s**; `flutter analyze` = 57 pre-existing issues (0 errors, 4 warnings, rest infos). "Clean" in CLAUDE.md therefore means *no new issues in touched files*: run `flutter analyze <touched files>`.

## Summary

The `graphql` 5.2.1 `SocketClient` already does the heavy lifting. I read the installed source and then **exercised the real `WebSocketLink`/`SocketClient` against a local `dart:io` graphql-transport-ws server** (probe tests, deleted afterwards) to confirm the claims below. After a socket loss the client sets `_connectionWasLost`, reconnects (re-evaluating `initialPayload` each time), and re-invokes every live subscription's `onListen` callback, which re-sends `subscribe` **with the same operation id on the same Dart stream**: the consumer's `StreamSubscription` keeps emitting, and the backend snapshot (D-03) arrives as an ordinary event. `connection_init` was sent twice (token re-read per connect). What is *not* free: (a) `WebSocketLink` only creates its `SocketClient` lazily, so observing connection state needs `getSocketClient` (public) plus an early `connectOrReconnect()`; (b) a subscribe-time rejection (`FORBIDDEN`) surfaces in **one of two wire shapes** depending on the server, and in neither case does the stream reliably re-subscribe by itself, so each consumer must resubscribe with backoff; (c) in graphql-transport-ws mode the client sends a single ping per `inactivityTimeout` and **never detects a missing pong**, so a half-open socket (wifi to cellular, tunnel) stays `connected` forever unless the transport sets a `pingInterval`; (d) a literal reading of D-15 ("no data for ~3 minutes") would eject every idle player, because events only flow when something changes.

Recommended shape: one **`SessionSyncCubit`** (session subtree, `lazy: false`, keyed by `user.id` through `AuthGate`) is the single consumer of `userUpdated`, owns the resume refetch of `me`, observes the socket through a small `SocketConnectionMonitor`, and feeds a Flutter-free **`SyncWatchdog`**. `CharacterCubit` keeps owning `characterUpdated` (hardened: no `CharacterError` in a loaded session, silent resubscribe/refetch with backoff, reports to the same watchdog). Both react to a Flutter-free **`AppLifecycleEvents`** stream fed by one app-level `AppLifecycleListener` (`onPause`/`onRestart` pair = true background->foreground; `onResume` also fires for inactive blips and must not be used). The gameplay subtree is keyed by character id in `SessionHome`; `AuthGate` pops root routes on character change (this **inverts an existing Phase 2 test**, see Pitfall 8). The watchdog ends the session through a new narrow additive `SessionTerminator` interface (`terminateSession(UnauthenticatedReason)`) implemented by both `SessionAuthTokenService` and `DevAuthTokenService`, with a new `UnauthenticatedReason.syncLost` and the inline SignIn notice "Connessione persa, accedi di nuovo.".

**Primary recommendation:** Build `SyncWatchdog` + `AppLifecycleEvents` + `SocketConnectionMonitor` as small Flutter-free classes first (TDD, `fake_async`), then `SessionSyncCubit` and the `CharacterCubit` hardening on top of them, then wire the widgets; interpret D-15 as "continuous time in a *degraded* state (socket down or stream failing) without any proof of life", and confirm this interpretation with the user (Assumption A3) before executing.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `graphql` / `graphql_flutter` | 5.2.1 (locked in `pubspec.lock`; pub.dev latest are 5.2.4 / 5.3.0, published 2026-03-14) | `WebSocketLink`, `SocketClient`, `client.subscribe` | Locked by roadmap decision (client choice stays `graphql_flutter`). Changelog 5.2.2-5.2.3 has no WebSocket changes; 5.2.4/5.3.0 entries not visible. **Do not bump in this phase**: every behaviour below was verified on 5.2.1. [VERIFIED: pubspec.lock, pub.dev API, pub.dev changelog] |
| `flutter_bloc` / `bloc_test` / `mocktail` / `fake_async` | 9.1.1 / 10.0.0 / 1.0.5 / 1.3.3 | Cubits and tests | Already in the project. `fake_async` is already used by `session_auth_token_service_refresh_test.dart` and `ws_reconnect_policy_test.dart`. [VERIFIED: pubspec.yaml, test/] |
| `web_socket_channel` | 3.0.3 (resolved, currently transitive) | `IOWebSocketChannel.connect(pingInterval:, connectTimeout:)` for dead-socket detection | Needed by the `connectFn` in Pitfall 2. **Add as a direct dependency in `pubspec.yaml`** (`depend_on_referenced_packages` lint); no resolution change because 3.0.3 is already locked. [VERIFIED: pubspec.lock, source in `~/.pub-cache/hosted/pub.dev/web_socket_channel-3.0.3/lib/io.dart`] |
| Flutter / Dart | 3.35.5 / 3.9.2 | `AppLifecycleListener` (stable since 3.13) | [VERIFIED: `flutter --version`, `dart --version`] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `rxdart` | 0.28.0 (transitive via `graphql`) | `SocketClient.connectionState` is a `BehaviorSubject` stream (replays the last value) | Consume it as a plain `Stream<SocketConnectionState>`; do **not** add rxdart to the app. |
| Node 22.12 + BE `node_modules/graphql` 16.11.0 | local | Schema check (D-04): `buildSchema` + `validate` each FE document against `src/schema.gql` | Verified working in this session against today's schema (all 4 current documents `OK`). |
| `gql` (`parseString`) | any (already a dependency) | Document unit tests (operation name, args, fragment defined once) | Pattern already used in `test/graphql/character_creation_documents_test.dart`. |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `AppLifecycleListener` | `WidgetsBindingObserver` | Same underlying API; `AppLifecycleListener` gives named transition callbacks (`onPause`, `onRestart`) and takes an injectable `binding`. Use it. |
| Own `SocketClient` passed to the link | `link.getSocketClient` | `WebSocketLink` has no constructor parameter for a client, and its `_socketClient` is private; `getSocketClient` (public getter) is sufficient. Do not subclass or re-implement the link. |
| Per-stream watchdogs | One clock + `SyncHealth` interface | One clock matches D-15 ("neither subscription ... reset by any event") and is simpler. |
| Re-query on every reconnect (D-12) | Rely on snapshot-on-subscribe only | Recommended: **rely on the snapshot** (BE accepted D-03). One mechanism for reconnect (resubscribe), one for resume (refetch). Revisit only if the E2E shows a missing snapshot. |

**Installation:**
```bash
# only change to pubspec.yaml (already locked at 3.0.3, no new download):
#   dependencies:
#     web_socket_channel: ^3.0.3
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter pub get
```

**Version verification:** `graphql` 5.2.1 / `graphql_flutter` 5.2.1 / `web_socket_channel` 3.0.3 from `pubspec.lock`; latest from `https://pub.dev/api/packages/<name>` on 2026-10-14 (`graphql` 5.2.4, `graphql_flutter` 5.3.0, `web_socket_channel` 3.0.3).

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── graphql/subscriptions/user_subscriptions.dart     # NEW  OnUserChanged (uses UserFragment)
├── repository/services/
│   ├── graphql/
│   │   ├── graphql.dart                              # + subscribeToUser(); typed stream failure; no payload in messages
│   │   ├── graphql_client_holder.dart                # + watchConnection() -> Stream<bool>
│   │   ├── graphql_client_provider.dart              # + connectFn (pingInterval, connectTimeout)
│   │   └── socket_connection_monitor.dart            # NEW  link -> Stream<bool>
│   ├── auth/
│   │   ├── auth_token_service.dart                   # + UnauthenticatedReason.syncLost
│   │   └── session_terminator.dart                   # NEW  narrow additive interface (D-32 style)
│   └── sync/                                         # NEW  Flutter-free
│       ├── sync_health.dart                          # abstract interface SyncHealth { degrade/recover/touch }
│       ├── sync_watchdog.dart                        # implements SyncHealth, owns the 3-minute clock
│       └── app_lifecycle_events.dart                 # interface + AppLifecycleEventBus
├── utils/silent_retry.dart                           # NEW  retry with bounded backoff, cancellable (pure, no I/O)
├── screens/auth/
│   ├── syncCubit/session_sync_cubit.dart (+ _state)  # NEW  userUpdated owner, me refetch, socket + lifecycle wiring
│   ├── session_sync_scope.dart                       # NEW  provides SyncWatchdog + SessionSyncCubit around SessionHome
│   ├── session_home.dart                             # + ValueKey('character:<id>') on the shell
│   ├── auth_gate.dart                                # + pop on character change; notice mapping
│   └── authenticated_shell.dart                      # CharacterCubit gets SyncHealth + AppLifecycleEvents
├── screens/mainScreen/characterCubit/                # hardened (D-14)
├── screens/signIn/sign_in_screen.dart                # + "Connessione persa, accedi di nuovo." notice
└── main.dart                                         # AppLifecycleListener + bus, SessionSyncScope, terminator, watchConnection
tool/schema_check/                                    # NEW  dump_documents.dart + validate_documents.js (manual, pre-PR)
test/helpers/fakes/fake_graphql_ws_server.dart        # NEW  Wave 0
```

### Pattern 1: `OnUserChanged` document and the stream mapper (SYNC-01)
**What:** One named subscription reusing the existing fragment; the mapper turns a `QueryResult` into `User` or a typed failure.
**When to use:** `KlimmeckGraphQl.subscribeToUser()`. Never branch on the error code (a `FORBIDDEN` on `characterUpdated` is handled exactly like any other failure: degrade + backoff resubscribe); log only the code, never the payload (`docs/rules/graphql.md`).
```dart
// lib/graphql/subscriptions/user_subscriptions.dart  (no Flutter imports, same style as AuthQueries.getMe)
import '../fragments/user_fragment.dart';

class UserSubscriptions {
  static const String userUpdated =
      r'''
    subscription OnUserChanged {
      userUpdated { ...UserFields }
    }
  ''' +
      UserFragment.definition;
}
```
```dart
// KlimmeckGraphQl
Stream<User> subscribeToUser() => performSubscription(UserSubscriptions.userUpdated)
    .map((result) {
      if (result.hasException) throw SubscriptionStreamException(result.exception);
      return _userFrom(result.data?['userUpdated']);   // existing FormatException boundary
    });
```
`SubscriptionStreamException` (new, in `lib/repository/services/graphql/`) carries only an optional `code` extracted from `exception.graphqlErrors[*].extensions['code']` **or** from `exception.linkException?.originalException` when it is a `SubscriptionError` whose `payload` is a `List` of error maps (both shapes verified, see Pitfall 4). `toString()` must not include payloads.

### Pattern 2: `SessionSyncCubit` — single owner of `userUpdated` (SYNC-01, 03, 04)
**What:** A Cubit (states `SessionSyncLive`, `SessionSyncRecovering`, `SessionSyncLost`; Equatable; **no UI consumer by design (D-18)**, they exist to make the behaviour assertable with `bloc_test`). Lives in the session subtree: `BlocProvider(lazy: false, create: (_) => SessionSyncCubit(...)..start())` inside `SessionSyncScope`, which `main.dart` places around `SessionHome` inside `authenticatedBuilder`. `AuthGate` already wraps that builder in `KeyedSubtree(ValueKey(user.id))`, so logout, revocation and account change unmount it and call `close()`. `lazy: false` is mandatory (a lazy provider never reads the cubit and the stream would never open).

Responsibilities (all inside the cubit, nothing in widgets):
1. `start()`: open `api.subscribeToUser()`; listen to `Stream<bool> connection`; listen to `AppLifecycleEvents`.
2. User event -> `_watchdog.recover()`, `_auth.adoptUser(user)` (if `false`: `debugPrint('[Sync] dropped userUpdated of another identity')`, no throw, no state change).
3. Stream error or `onDone` -> `_watchdog.degrade()`, cancel the dead subscription, `Timer(exponentialBackoff(attempt, max: WsReconnectPolicy.maxReconnectDelay))` then resubscribe; the attempt counter resets on the next data event. A generation counter makes late timers harmless after `close()`.
4. `foregrounded` -> `_watchdog.resume()` and refetch `getMe()` with `silentRetry`; apply through `adoptUser` **only if no live event arrived while the query was in flight** (event counter compare, Pitfall 6); success -> `_watchdog.touch()`.
5. `backgrounded` -> `_watchdog.suspend()`.
6. `close()`: cancel the user subscription, connection subscription, lifecycle subscription, resubscribe timer, retry loop; `_watchdog` is disposed by its `RepositoryProvider.dispose`.

`AuthTokenService` (not `AuthCubit`) is injected: cubit-calls-cubit is forbidden by `state-management.md`, and the service is the D-07 single source of truth.

### Pattern 3: `CharacterCubit` hardening (SYNC-02, 03, 05, 07)
Keep `loadCharacter(id)` exactly as today for the cold start (D-16): `Loading -> Loaded | Error`, then subscribe. After the first `CharacterLoaded`:
- stream `onData` -> `emit(CharacterLoaded)`, `health.recover()`, reset the attempt counter, bump `_eventCount`;
- stream `onError` / `onDone` -> **no `CharacterError`** (every consumer in `lib/` renders only on `state is CharacterLoaded`, so any other state blanks the screen); `health.degrade()`, cancel, resubscribe after `exponentialBackoff`;
- `AppLifecycleEvents.foregrounded` -> `refreshCharacter()`: `api.getCharacter(_id)` via `silentRetry`, **never emits `CharacterLoading`**, applied only if `_eventCount` is unchanged, success -> `health.touch()`;
- `close()` cancels the subscription, the lifecycle subscription and every timer.
`close()` + the `ValueKey('character:<id>')` in `SessionHome` give the "never two live streams" guarantee of D-08 for free: a new id means a new shell means a new cubit.

### Pattern 4: Lifecycle -> Flutter-free events (D-13)
```dart
// lib/repository/services/sync/app_lifecycle_events.dart   (no Flutter import)
abstract interface class AppLifecycleEvents {
  Stream<void> get backgrounded;
  Stream<void> get foregrounded;
}

class AppLifecycleEventBus implements AppLifecycleEvents {
  final _backgrounded = StreamController<void>.broadcast();
  final _foregrounded = StreamController<void>.broadcast();
  @override Stream<void> get backgrounded => _backgrounded.stream;
  @override Stream<void> get foregrounded => _foregrounded.stream;
  void notifyBackgrounded() => _backgrounded.add(null);
  void notifyForegrounded() => _foregrounded.add(null);
  Future<void> close() => Future.wait([_backgrounded.close(), _foregrounded.close()]);
}
```
```dart
// _KlimmeckGuideAppState (one listener for the app's whole life)
late final _lifecycleBus = AppLifecycleEventBus();
late final AppLifecycleListener _lifecycleListener = AppLifecycleListener(
  onPause: _lifecycleBus.notifyBackgrounded,    // hidden -> paused
  onRestart: _lifecycleBus.notifyForegrounded,  // paused -> hidden: true "background -> foreground"
);
// dispose(): _lifecycleListener.dispose(); _lifecycleBus.close();
// build(): RepositoryProvider<AppLifecycleEvents>.value(value: _lifecycleBus, ...) above AuthGate
```
`onPause`/`onRestart` are an exact pair (`onPause` fires only on entering `paused`, `onRestart` only on leaving it). **Do not use `onResume`** (Pitfall 3).

### Pattern 5: Keying and routing on character change (SYNC-05, D-08/D-10)
```dart
// SessionHome.build
final character = user.currentCharacter;
if (character == null) return creationBuilder(context);
return KeyedSubtree(
  key: ValueKey<String>('character:${character.id}'),
  child: shellBuilder(context, character.id),
);
```
Today `id -> id'` would reuse the `AuthenticatedShell` `State` (same widget type and position) and the `BlocProvider(create:)` callbacks would not re-run; the key is what makes the cubits (and their streams) die. `null -> id` and `id -> null` already swap widget types. `SplashCubit` lives above `AuthGate` and keeps `SplashData`, so the re-mounted `_ShellBody.initState -> getImages('main')` re-emits an equal state (Equatable dedup, no splash flash).

`AuthGate`: `listenWhen: (p, c) => _leavesSession(p, c) || _changesCharacter(p, c)`. `_changesCharacter` compares only `currentCharacter?.id`, so a `twitchPoints`-only event never pops anything (add a test for this negative case).

### Pattern 6: Watchdog and teardown (D-15)
```dart
// lib/repository/services/sync/sync_health.dart
abstract interface class SyncHealth {
  void degrade();   // socket down / a stream failed: arm the window if not already armed
  void recover();   // socket connected / any event or snapshot: clear degradation, cancel
  void touch();     // a refetch succeeded (HTTP reachable): restart the window if still degraded
}

// lib/repository/services/sync/sync_watchdog.dart
class SyncWatchdog implements SyncHealth {
  SyncWatchdog({required Future<void> Function() onExpired, Duration window = const Duration(minutes: 3)});
  // degrade(): if (!_degraded) { _degraded = true; _arm(); }
  // recover(): _degraded = false; _timer?.cancel();
  // touch():   if (_degraded) _arm();                 // fresh window
  // suspend(): _timer?.cancel();                      // app paused: Dart timers may fire late on resume
  // resume():  if (_degraded) _arm();
  // timer fires -> latch _expired (once), _degraded = false, unawaited(onExpired())
  // dispose(): cancel + latch
}
```
Expiry calls `SessionTerminator.terminateSession(UnauthenticatedReason.syncLost)`:
```dart
// lib/repository/services/auth/session_terminator.dart
abstract interface class SessionTerminator {
  /// No-op unless the session is currently authenticated and no logout is in flight.
  Future<void> terminateSession(UnauthenticatedReason reason);
}
```
Both services already have a private `_endSession(reason)` doing exactly the D-12 teardown (`SessionAuthTokenService`: supersede session -> forget -> `onSessionTeardown` (= `holder.reset()`) -> clear store -> emit; `DevAuthTokenService`: teardown -> `_isSignedIn=false` -> emit). **Dev stub path verified by reading the code:** `handleRevocation()` -> `_endSession(sessionExpired)` -> `AuthUnauthenticated(reason)`, then `login()` re-signs in; so the watchdog works with the stub with no special case. `_buildAuth` in `main.dart` returns the terminator next to `recovery` (both are the same object, as `recovery` is today). The real service must guard `terminateSession` against `_logoutInFlight != null` and against a non-authenticated channel (otherwise a watchdog firing during an offline logout, which can wait up to `logoutTimeout`, emits a second terminal state).

SignIn: replace the boolean `showSessionExpiredNotice` with a small enum (`SignInNotice { none, sessionExpired, connectionLost }`) mapped from `UnauthenticatedReason` in `AuthGate`; add `const String _connectionLostNotice = 'Connessione persa, accedi di nuovo.';` next to `_sessionExpiredNotice`. This touches `sign_in_screen_test.dart` (one existing parameter) — acceptable and cleaner than a second bool (CLAUDE.md: no behaviour-switching boolean flags).

### Pattern 7: Observing the socket (Claude's-discretion item answered)
`WebSocketLink` exposes **`SocketClient? get getSocketClient`** publicly, and `SocketClient.connectionState` is a `Stream<SocketConnectionState>` backed by a `BehaviorSubject` (replays the last value, closes on dispose). The client is created **lazily**; `connectOrReconnect()` creates it eagerly (verified: connects immediately, `inits == 1`, a later `client.subscribe` reuses it). No wrapper link or own `SocketClient` is needed.
```dart
class SocketConnectionMonitor {
  SocketConnectionMonitor(this._link);
  final WebSocketLink _link;

  /// Call at most once per link: `connectOrReconnect()` DISPOSES an existing client
  /// (it would orphan live streams), so only create when absent.
  Stream<bool> watch() {
    if (_link.getSocketClient == null) _link.connectOrReconnect();
    return _link.getSocketClient!.connectionState
        .map((state) => state == SocketConnectionState.connected)
        .distinct();
  }
}
```
`GraphQLClientHolder` already owns the current link: add `Stream<bool> watchConnection() => SocketConnectionMonitor(_webSocketLink).watch();` and pass `graphQlHolder.watchConnection` to `KlimmeckGuideApp` (new `Stream<bool> Function() openConnectionStream` parameter). `holder.reset()` only runs at session end, so a per-session call always binds to the live link. Observed state sequence on a drop+reconnect: `connected, notConnected, connecting, handshake, connected`.

### Anti-Patterns to Avoid
- **Silence-based watchdog:** a healthy idle player produces no events for hours. Arm only on degradation.
- **`link.connectOrReconnect()` called a second time:** disposes the client and silently kills every live subscription stream.
- **Recreating the `WebSocketLink` to "refresh" subscriptions or the token:** Phase 11 D-37.
- **`onResume` as the resume trigger, `Future.delayed` to sequence tests, `Timer` in widgets:** see Pitfalls 3 and Validation Architecture.
- **Emitting `CharacterLoading`/`CharacterError` in a loaded session:** blanks every `state is CharacterLoaded` consumer and breaks CLAUDE.md rule 2.
- **A second consumer of `userUpdated`** (e.g. a widget reading the stream next to the cubit): `docs/rules/graphql.md`.
- **Cubit-to-cubit calls** for the resume refetch: use the shared `AppLifecycleEvents` stream.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Re-sending subscriptions after reconnect | Own resubscribe-on-reconnect machinery | `SocketClient` built-in (`_subscriptionInitializers`) | Verified: same operation id, same stream, snapshot arrives as a normal event (probe P1) |
| Reconnect backoff / 4401 refresh | New reconnect logic | `WsReconnectPolicy` (Phase 11) | Already token-per-connect, bounded, tested |
| Backoff arithmetic | New delay math | `exponentialBackoff(attempt, max:)` in `lib/utils/backoff.dart` | D-14 explicitly says reuse |
| Connection state stream | Polling `connectivity_plus`, custom pings | `SocketClient.connectionState` | Authoritative for *this* socket; connectivity plugins report the radio, not the socket |
| Dead-socket detection | App-level heartbeat query | `IOWebSocketChannel.connect(pingInterval:)` | OS-level ping/pong frames; closes with `goingAway`, which flows into `onConnectionLost` |
| Schema validation of FE documents | A hand-written SDL walker | `graphql-js` `buildSchema` + `validate` from the BE's `node_modules` | Verified working today; full validation rules for free |
| Lifecycle plumbing | `WidgetsBindingObserver` subclass with state-machine glue | `AppLifecycleListener(onPause:, onRestart:)` | Named transition callbacks, injectable `binding` |
| Test WS server mocks | Mocking `SocketClient` | Local `dart:io` `HttpServer` + `WebSocketTransformer` (30 lines) | `SocketClient`'s constructor connects immediately and cannot be instantiated without a transport; the real class is the thing under test |

**Key insight:** the transport is already correct; the missing pieces are all *policy at the edges* (what counts as unhealthy, when to resubscribe after a rejection, when to give up) and *structure* (keys, ownership, teardown). Keep each as a small Flutter-free class with an injectable clock (plain `Timer` + `fakeAsync`).

## Common Pitfalls

### Pitfall 1: Silence is not failure (D-15 wording)
**What goes wrong:** Implementing "no data for ~3 minutes" literally logs out every idle but healthy player (events only exist when the document changes; with snapshot-on-subscribe there is one event per connect, then possibly nothing for hours).
**Why it happens:** the decision text describes the failure scenario (everything down) not the trigger.
**How to avoid:** the clock runs only while *degraded* (socket not connected, or a stream failed/completed and has not recovered) and is reset by connect, any event/snapshot, or a successful refetch (`SyncHealth`, Pattern 6). **Needs user confirmation: Assumption A3.**
**Warning signs:** a test where the fake socket stays `connected` and no event arrives for 10 simulated minutes must NOT terminate the session.

### Pitfall 2: A half-open socket never shows as disconnected
**What goes wrong:** wifi->cellular switch, tunnel, captive portal: TCP has no FIN, the socket stays `connected`, no event ever arrives, no watchdog ever arms, the user sees stale state indefinitely.
**Why it happens:** [VERIFIED by probe P5 + source] in graphql-transport-ws mode `_enqueuePing()` sends one ping after `inactivityTimeout` and only re-arms on a received `pong`; the `_disconnectOnKeepAliveTimeout` guard exists only for the legacy `graphql-ws` protocol. With the server muted the client sent exactly 1 ping and the state stayed `[connected]` for 2 s of 300 ms timeouts. `defaultConnectPlatform` passes no `pingInterval`, and dart:io's `pingInterval` defaults to disabled.
**How to avoid:** in `buildGraphQLConnection` pass a `connectFn` built on `IOWebSocketChannel.connect(uri, protocols: protocols, pingInterval: Duration(seconds: 25), connectTimeout: Duration(seconds: 10))`. Per `web_socket_channel` 3.0.3 docs [VERIFIED: source], an unanswered ping closes the socket with `goingAway`; `SocketClient` then follows the normal `onConnectionLost` path (generic backoff in `WsReconnectPolicy`, since 1001 is not an auth code). `connectTimeout` also bounds a blackholed `WebSocket.connect` (otherwise `_connect()` can sit in `connecting` for the OS TCP timeout). Intervals 25 s / 10 s are suggestions (A5). Not unit-testable (dart:io answers pings itself): cover with the manual E2E (airplane mode on/off, wifi->cellular).
**Warning signs:** after toggling airplane mode the app shows no recovery until resume.

### Pitfall 3: `onResume` fires for inactive blips; background timers fire late
**What goes wrong:** (a) `AppLifecycleListener.onResume` also fires for `inactive -> resumed` (notification shade, system dialogs, image picker, permission prompts): [VERIFIED by widget probe] the sequence `inactive, resumed` logs `[inactive, resume]` while a real background round-trip logs `[inactive, hide, pause, restart, show, resume]`. (b) Dart timers are not guaranteed to tick while the app is suspended; on return an overdue 3-minute timer can fire *immediately*, ejecting a user who merely switched apps.
**How to avoid:** use `onPause` / `onRestart` (Pattern 4). `SessionSyncCubit` calls `watchdog.suspend()` on `backgrounded` and `watchdog.resume()` (fresh window) + refetch on `foregrounded`. In widget tests drive `tester.binding.handleAppLifecycleStateChanged(...)` through *legal* transitions only (the listener asserts them); `lifecycleState` is `null` initially in tests.
**Warning signs:** a spurious `syncLost` right after returning from background; refetch storms from system dialogs.

### Pitfall 4: A subscribe-time rejection has two wire shapes, and neither re-subscribes by itself
**What goes wrong:** BE contract says `characterUpdated` on a foreign id "fails immediately with `extensions.code = FORBIDDEN`", without specifying the frame. [VERIFIED by probes against the real client]:
- **Shape A** (`error` message, payload = array of GraphQL errors): the stream emits a `QueryResult` with `exception.linkException` = `UnknownException` whose `originalException` is a `SubscriptionError` (`payload: [{message, extensions:{code:FORBIDDEN}}]`), `graphqlErrors` is **empty**, and the stream **stays open** (the operation is dead server-side).
- **Shape B** (`next` with `errors`, then `complete`, what graphql-js `subscribe` + graphql-ws produce when the resolver throws during source-stream creation [ASSUMED]): a `QueryResult` with `data == null`, `graphqlErrors[0].extensions['code'] == 'FORBIDDEN'`, then the stream is **done**, and a later reconnect did **not** re-send the operation (only 1 `subscribe` frame in total).
**How to avoid:** handle `onError` **and** `onDone` identically: degrade, cancel, resubscribe after backoff (Pattern 2/3). Never rely on the client to retry a rejected operation. Treat `QueryResult.hasException` for both shapes in the mapper. The E2E must record which shape the real BE produces (Open Question 1).
**Warning signs:** a character stream that "works" in tests with mocks but is silent after a foreign-id race.

### Pitfall 5: `WebSocketLink` creates its client lazily; `getSocketClient` is `null` until the first request
**What goes wrong:** reading `link.getSocketClient!` at session start throws; calling `connectOrReconnect()` twice kills streams. [VERIFIED P1/P6]
**How to avoid:** `SocketConnectionMonitor.watch()` (Pattern 7), called once per session, creating the client only if absent. After `holder.reset()` the old link's `connectionState` closes (`onDone`); the cubit is already being disposed then.

### Pitfall 6: A slow refetch must not overwrite a newer live event
**What goes wrong:** resume fires `getCharacter(id)`; an `characterUpdated` event lands while the query is in flight; the older HTTP result then overwrites the newer state until the next event.
**How to avoid:** capture `_eventCount` before the query and apply the result only if unchanged (still call `health.touch()`). Same for `getMe()` -> `adoptUser`. Unit-test with two `Completer`s.

### Pitfall 7: Late/foreign `userUpdated` events
**What goes wrong:** (a) after account change an event of the previous identity could enter the new session; (b) right after `createCharacter` an older queued event with `currentCharacter: null` can arrive after the mutation response has been adopted and flip the UI back to creation until the next event; (c) dev stub fallback identity (`DEV_AUTH_USER_ID` from `.env`, used when `me` failed at login) may not match the backend id, so `adoptUser` refuses every event for the whole dev session.
**How to avoid:** (a) the `adoptUser` id guard (D-07) + the cubit is closed with the session subtree; (b) accept, converges on the next event (the creation itself emits one) — document, do not add versioning; (c) dev-only: a `debugPrint` per dropped event makes it visible; restart the app once the BE is up.

### Pitfall 8: Existing tests and docs contradict D-10
**What goes wrong:** `test/screens/auth/auth_gate_test.dart` -> group `character gained` -> `'gaining a character keeps root dialogs open'` asserts the *opposite* of D-10 for `null -> id` (it encodes Phase 2 plan 02-02: "no `popUntil` on character gain"). `.planning/phases/02-character-creation/02-SECURITY.md` line 42 cites that test by name as evidence for T-02-02-03 (the mitigation itself is the `_changesCharacter` rebuild rule, not dialog persistence).
**How to avoid:** the Red step of the AuthGate task rewrites that test (gain, loss and swap all pop root routes; points-only change does not), and the plan updates the 02-SECURITY.md reference text to the new test name. Do not leave the old test green by weakening D-10.

### Pitfall 9: Re-keying the shell re-runs cold-start side effects
**What goes wrong:** a new `AuthenticatedShell` re-runs `SplashCubit.getImages('main')` (cheap: cache valid, equal state deduped) and `MainScreen.initState` shows `KGLoader` until the first `CharacterLoaded` (`isFirstLoading`). Acceptable (D-16: loading at a cold-ish start is allowed; `null -> id` after creation is exactly this path today), and `id -> id'` does not occur in production (D-08).
**How to avoid:** do not "optimise" it away; just do not add new loaders.

### Pitfall 10: Real-socket tests need plain `test()`, not `testWidgets`
**What goes wrong:** my probes using `dart:io` `HttpServer` + `WebSocket.connect` ran fine under plain `test(...)` in `flutter test`. [ASSUMED: known `flutter_test` behaviour] `testWidgets` installs `HttpOverrides` that answer HTTP clients with 400, which would break `WebSocket.connect`.
**How to avoid:** put the fake-server integration tests in plain `test` files; keep widget tests on mocks/`StreamController`s.

### Pitfall 11: Terminating while a logout is in flight
See Pattern 6: guard `terminateSession` (`_logoutInFlight`, non-authenticated channel) and test "syncLost during a logout emits exactly one terminal state".

### Pitfall 12 (LOW, observation, out of scope): stale `closeCode` after a failed reconnect
In `SocketClient._connect` the `catch` calls `onConnectionLost(e)`, which reads `socketChannel?.closeCode` of the *previous* channel; after a 4401 followed by a failed (offline) reconnect, `WsReconnectPolicy` sees 4401 again and re-runs the refresh each attempt. Harmless (refresh fails fast offline, backoff still applies) but worth knowing if logs look noisy. Do not fix in this phase.

## Code Examples

### Fake graphql-transport-ws server (Wave 0 helper, shape verified by the probes)
```dart
// test/helpers/fakes/fake_graphql_ws_server.dart  (plain dart:io, no Flutter)
class FakeGraphQlWsServer {
  late HttpServer _http;
  final sockets = <WebSocket>[];
  final received = <Map<String, dynamic>>[];       // every client frame, decoded
  void Function(WebSocket ws, Map<String, dynamic> subscribe)? onSubscribe;

  Future<void> start() async {
    _http = await HttpServer.bind('127.0.0.1', 0);
    _http.listen((req) async {
      final ws = await WebSocketTransformer.upgrade(req, protocolSelector: (p) => p.first);
      sockets.add(ws);
      ws.listen((raw) {
        final msg = jsonDecode(raw as String) as Map<String, dynamic>;
        received.add(msg);
        switch (msg['type']) {
          case 'connection_init': ws.add(jsonEncode({'type': 'connection_ack'}));
          case 'ping': ws.add(jsonEncode({'type': 'pong'}));
          case 'subscribe': onSubscribe?.call(ws, msg);
        }
      });
    });
  }
  String get url => 'ws://127.0.0.1:${_http.port}/graphql';
  void emit(WebSocket ws, String id, Map<String, dynamic> data) =>
      ws.add(jsonEncode({'type': 'next', 'id': id, 'payload': {'data': data}}));
  Future<void> dropWith(int code) async => sockets.last.close(code, 'test');   // use 4401 / 1001, NOT 1006 (reserved, throws)
  List<Map<String, dynamic>> framesOf(String type) => received.where((m) => m['type'] == type).toList();
  Future<void> stop() => _http.close(force: true);
}
```

### Error-code extraction for both rejection shapes (logging only)
```dart
String? subscriptionErrorCode(OperationException exception) {
  for (final error in exception.graphqlErrors) {
    final code = error.extensions?['code'];
    if (code is String) return code;                              // shape B
  }
  final origin = exception.linkException?.originalException;
  if (origin is SubscriptionError && origin.payload is List) {    // shape A
    for (final item in origin.payload as List) {
      final extensions = item is Map ? item['extensions'] : null;
      if (extensions is Map && extensions['code'] is String) return extensions['code'] as String;
    }
  }
  return null;
}
```

### Silent bounded retry shared by both refetches (pure, cancellable)
```dart
// lib/utils/silent_retry.dart  (no Flutter, no I/O of its own)
Future<T?> silentRetry<T>(
  Future<T> Function() attempt, {
  required bool Function() isCancelled,
  Duration max = const Duration(seconds: 60),
}) async {
  for (var n = 0; !isCancelled(); n++) {
    try {
      return await attempt();
    } catch (_) {
      await Future<void>.delayed(exponentialBackoff(n, max: max));
    }
  }
  return null;
}
```
Callers pass `isCancelled: () => isClosed || generation != _generation` so a newer resume or `close()` ends the loop.

### Schema check (D-04), verified today against the current BE schema
```bash
# FE repo: dump each document to its own file (lib/graphql has no Flutter imports, so plain `dart run` works)
dart run tool/schema_check/dump_documents.dart /tmp/kg-docs   # one <OperationName>.graphql per document
# validate with the BE's own graphql-js (v16.11.0) against the regenerated schema
NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules \
  node tool/schema_check/validate_documents.js \
  /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql /tmp/kg-docs
```
`validate_documents.js` = `buildSchema(sdl)`, then for each file `validate(schema, parse(doc))`, print `OK` or the messages, exit 1 on any error. **One file per document** (a combined file trips "unique fragment name" on repeated `UserFields`). Today's run: `GetMe`, `character`, `CreateCharacter`, `characterUpdated` all `OK`; `OnUserChanged` is expected to fail until the BE lands `userUpdated` in its wave 1 (current `src/schema.gql` has only `characterUpdated`). Keep the document list in `dump_documents.dart` explicit and add a document test asserting that every operation parses.

### Document unit test for the new subscription
```dart
final op = operationOf(UserSubscriptions.userUpdated);
expect(op.type, OperationType.subscription);
expect(op.name?.value, 'OnUserChanged');
final field = op.selectionSet.selections.single as FieldNode;
expect(field.name.value, 'userUpdated');
expect(field.arguments, isEmpty);                       // D-01: no arguments
expect(userFieldsDefinitions(UserSubscriptions.userUpdated), 1);
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `WidgetsBindingObserver` boilerplate | `AppLifecycleListener` with per-transition callbacks | Flutter 3.13 (with the new `hidden` state) | Use `onPause`/`onRestart`; `AppLifecycleState` now has 5 values |
| Legacy `graphql-ws` subprotocol | `graphql-transport-ws` (`GraphQLProtocol.graphqlTransportWs`) | `graphql` 5.x | Project already uses it; note the keep-alive timeout guard exists only for the legacy protocol (Pitfall 2) |
| `graphql` 5.2.0 | fixed "duplicate events on socket reconnect", "SubscriptionComplete with graphql-transport-ws" | 5.2.0 | Already in 5.2.1; no WS changes found in 5.2.2-5.2.3 |

**Deprecated/outdated:** `SocketSubProtocol` (use `GraphQLProtocol`); `defaultConnectPlatform`'s lack of `pingInterval` is a gap, not a deprecation.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The BE's subscribe-time `FORBIDDEN` arrives as shape B (`next{errors}` + `complete`) when raised from a graphql-js subscribe resolver; shape A (`error`) if raised earlier (e.g. in `onSubscribe`). Not specified in the BE notes. | Pitfall 4 | Low: both shapes are handled identically (degrade + backoff resubscribe), verified on the real client. E2E records the actual one. |
| A2 | The BE's `ws`/graphql-ws server auto-answers WebSocket protocol-level ping frames with pong (RFC 6455 requirement, `ws` default). | Pitfall 2 | If wrong, `pingInterval` would close healthy sockets every 25 s (visible immediately in E2E as reconnect churn; remove the interval). |
| A3 | **D-15 is intended as "continuous *degraded* time without proof of life", not "no events for 3 minutes".** | Pitfall 1, Pattern 6 | HIGH if the literal reading was meant (idle players ejected). **Ask the user to confirm before execution.** |
| A4 | `onPause`/`onRestart` pair behaves as in the test binding on real iOS and Android (sequence `inactive, hidden, paused, hidden, inactive, resumed`). | Pattern 4 | Medium: if a platform skips `paused`, the watchdog is not suspended and the refetch not triggered; verify in manual E2E on both platforms. |
| A5 | `pingInterval` 25 s, `connectTimeout` 10 s, watchdog window 3 min, retry cap 60 s are sensible values. | Pitfall 2, Pattern 6 | Low: tunables. Window and cap come from D-14/D-15; ping/connect values are mine. |
| A6 | Real-socket tests must avoid `testWidgets` because of `HttpOverrides`. | Pitfall 10 | Low: plain `test` is verified to work, so the recommendation stands either way. |
| A7 | `SocketClient.dispose()` on a dead network completes promptly (it awaits `sink.close`, which for dart:io can wait for the peer's close frame up to a library timeout), so `holder.reset()` inside a watchdog teardown may take a few seconds. | Pattern 6 | Low: teardown order awaits it before clearing storage/emitting; the user sees nothing meanwhile. If it ever hangs, bound it with a timeout inside `_recreate`. |
| A8 | `userUpdated` payload `currentCharacter` is populated one level (`{ id … }`) as `me` does, so `UserFragment` (`currentCharacter { id }`) is sufficient. | Pattern 1 | Low: confirmed in BE CONTEXT D-01/BACKEND-NOTES; schema check verifies. |

## Open Questions

1. **Which frame carries the subscribe-time `FORBIDDEN` on the real backend?**
   - Known: the BE accepted "fails immediately with `extensions.code = FORBIDDEN`"; both shapes are handled and tested.
   - Unclear: shape A vs B.
   - Recommendation: record it in `BACKEND-NOTES.md` §5 during the E2E; no code change expected.

2. **Is the idle-player reading of D-15 acceptable (A3)?**
   - Recommendation: confirm with the user (one sentence) at the start of execution; the plan encodes the degraded-state semantics and the negative test "idle but connected for 10 minutes keeps the session".

3. **Watchdog while the creation form is on screen and the BE is down.**
   - Known: the User stream is session-wide, so a user typing for >3 minutes offline is ejected with the notice (and loses the draft).
   - Recommendation: accept per D-15 (the decision is session-wide); mention in the PR description.

4. **Stale `character(id)` refetch after a server-side deletion/death while backgrounded.**
   - Known: `character(id)` then answers `NOT_FOUND`/`FORBIDDEN`; the parallel `me` refetch returns `currentCharacter: null`, `adoptUser` flips to creation, the shell (and `CharacterCubit` with its retry loop) is closed.
   - Recommendation: keep the character retry silent and cancellable by `close()`; add a test "failing character refetch + `me` showing null ends with the cubit closed and no timers left".

5. **Does `SignInScreen` test churn matter?** Replacing `showSessionExpiredNotice` (bool) by a `SignInNotice` enum touches `sign_in_screen_test.dart` and `auth_gate_test.dart`; if the planner prefers zero churn, add a second named parameter instead (less clean).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | build/test | yes | 3.35.5 (stable, fvm) | — |
| Dart SDK | `dart run tool/...` | yes | 3.9.2 | — |
| Node.js | schema check script | yes | 22.12.0 | — |
| BE `node_modules/graphql` | schema check (`NODE_PATH`) | yes | 16.11.0 | `npm ci` in the BE repo if missing |
| BE repo checkout (read-only) | `src/schema.gql` | yes | commit `0cd22c1` (BE Phase 3 context only; `userUpdated` NOT in schema yet) | wait for BE wave 1 (D-04) |
| Running BE with Phase 3 wave 1 | manual E2E | not probed | — | none: E2E is a pre-PR gate; develop against the fake WS server until then |
| Twitch keys / real login on device | real-session E2E | no (known, STATE.md) | — | dev bypass (`DEV_AUTH_ENABLED=true`; `DEV_AUTH_ACCESS_TOKEN` must match the BE) |
| Physical iOS/Android device or simulator | lifecycle + airplane-mode E2E | not probed | — | simulator for lifecycle; real network toggling needs a device or Network Link Conditioner |

**Missing dependencies with no fallback:** BE Phase 3 wave 1 (blocks only the final schema check and E2E, not development).
**Missing dependencies with fallback:** real Twitch login -> dev bypass.

## Validation Architecture

(`.planning/config.json` has no `workflow.nyquist_validation: false`, so this section is required.)

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 + `fake_async` 1.3.3 |
| Config file | none (defaults); mocks centralised in `test/helpers/mocks.dart` (**add new mocks there, never in a test file** — header of that file) |
| Quick run command | `flutter test test/repository/services/sync test/repository/services/graphql test/screens/auth test/screens/mainScreen/characterCubit test/graphql test/utils` |
| Full suite command | `flutter test` (baseline 481 tests, ~18 s) + `flutter analyze <touched files>` + `dart format --output=none --set-exit-if-changed <touched files>` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SYNC-01 | `OnUserChanged` is one named subscription on `userUpdated` with no args, `UserFields` defined once | unit (document) | `flutter test test/graphql/user_subscription_documents_test.dart` | Wave 0 |
| SYNC-01 | `subscribeToUser()` maps data -> `User`; malformed -> failure; shape A and B -> `hasException` failure (Link.function terminal, StreamController) | unit | `flutter test test/repository/services/graphql/graphql_user_subscription_test.dart` | Wave 0 |
| SYNC-01 | event -> `adoptUser` once; foreign identity (`adoptUser == false`) dropped without state change; no `getMe` call without a resume (no polling) | cubit (`bloc_test`) | `flutter test test/screens/auth/syncCubit/session_sync_cubit_test.dart` | Wave 0 |
| SYNC-01/07 | `AuthCubit` state carries new `twitchPoints`/`role` after `adoptUser` (user path of SYNC-07) | cubit | `flutter test test/screens/auth/cubit/auth_cubit_test.dart` | exists, extend |
| SYNC-02 | `loadCharacter` -> `getCharacter` then exactly one `subscribeToCharacter(id)`; each event -> `CharacterLoaded` | cubit | `flutter test test/screens/mainScreen/characterCubit/character_cubit_test.dart` | exists, extend |
| SYNC-03 | user stream error AND done -> resubscribe after `exponentialBackoff`, attempt counter reset on data, no state loss | cubit + `fake_async` | `flutter test test/screens/auth/syncCubit/session_sync_cubit_test.dart` | Wave 0 |
| SYNC-03 | character stream error AND done -> **no `CharacterError`**, state stays `CharacterLoaded`, resubscribe with backoff | cubit + `fake_async` | `flutter test test/screens/mainScreen/characterCubit/character_cubit_test.dart` | extend |
| SYNC-03 | `foregrounded` -> `getMe` + `getCharacter` re-run, no `CharacterLoading`, silent retry on failure, stale result discarded when an event overtook it | cubit + `Completer` | same two files | extend / Wave 0 |
| SYNC-03 | `SyncWatchdog`: arms on degrade, cancels on recover, restarts on touch while degraded, `suspend` cancels, `resume` re-arms, fires once; **idle + connected for 10 simulated minutes never fires** | unit (`fakeAsync`) | `flutter test test/repository/services/sync/sync_watchdog_test.dart` | Wave 0 |
| SYNC-03 | watchdog expiry -> `SessionTerminator.terminateSession(UnauthenticatedReason.syncLost)` once (cubit wiring) | cubit | `session_sync_cubit_test.dart` | Wave 0 |
| SYNC-03 | `AppLifecycleListener` mapping: `pause`/`restart` -> bus events; `inactive -> resumed` blip emits nothing | widget | `flutter test test/app/app_lifecycle_wiring_test.dart` | Wave 0 |
| SYNC-03 | real `SocketClient`: server drop with 4401/1001 -> same Dart stream receives the second snapshot, `subscribe` frame re-sent with the same id, `connection_init` sent twice | integration (fake WS server, plain `test`) | `flutter test test/repository/services/graphql/ws_resubscribe_integration_test.dart` | Wave 0 |
| SYNC-03 | `SocketConnectionMonitor.watch()`: early `connectOrReconnect`, emits `true,false,true` across a drop, `distinct`, completes on dispose, never calls `connectOrReconnect` twice | integration | same file | Wave 0 |
| SYNC-03 | `UnauthenticatedReason.syncLost` -> SignIn shows "Connessione persa, accedi di nuovo." and not the expired notice | widget | `flutter test test/screens/signIn/sign_in_screen_test.dart test/screens/auth/auth_gate_test.dart` | exists, extend |
| SYNC-03 | `terminateSession`: real service emits `AuthUnauthenticated(syncLost)` after teardown, clears store, ignores calls when unauthenticated or logout in flight (exactly one terminal state); dev stub emits it and `login()` re-enters | unit | `flutter test test/repository/services/auth/session_auth_token_service_revocation_test.dart test/repository/services/auth/dev_auth_token_service_transitions_test.dart` | exist, extend |
| SYNC-04 | `SessionSyncCubit.close()` and `CharacterCubit.close()`: `StreamController.hasListener == false`, timers cancelled (`fakeAsync.pendingTimers.isEmpty`) | cubit | the two cubit test files | Wave 0 / extend (pattern at `character_cubit_test.dart:35`) |
| SYNC-04 | logout: `holder.reset()` closes the server-side socket, disposed link's stream emits nothing further, a second session on the new client opens fresh `connection_init` + `subscribe`, events of the old stream never reach the new cubit | integration | `ws_resubscribe_integration_test.dart` (+ `graphql_client_holder_test.dart` exists) | Wave 0 |
| SYNC-04 | `AuthGate` unmount on `AuthUnauthenticated`/account change closes `SessionSyncCubit` and re-mount creates a new one | widget | `flutter test test/screens/auth/session_sync_scope_test.dart` | Wave 0 |
| SYNC-05 | `SessionHome`: `id -> id'` disposes and recreates the shell subtree (spy cubit created twice, first closed), `null -> id` and `id -> null` swap creation/shell | widget | `flutter test test/screens/auth/session_home_test.dart` | exists, extend |
| SYNC-05 | `AuthGate` pops root dialogs on `null->id`, `id->null`, `id->id'`; **does not** pop on a points-only change (replaces the old "keeps root dialogs open" test) | widget | `flutter test test/screens/auth/auth_gate_test.dart` | exists, **rewrite one test** |
| SYNC-05 | never two live character streams: with one `StreamController` per id, after a swap only the new one `hasListener` | widget/cubit | `authenticated_shell_test.dart` / `session_home_test.dart` | extend |
| SYNC-06 | verify-not-rebuild: `buildInitialPayload` re-reads the token per connect (existing); end-to-end: after a 4401 drop the second `connection_init` carries the rotated token and the same `WebSocketLink`/client instance is still in use | unit + integration | `ws_reconnect_policy_test.dart` (exists) + `ws_resubscribe_integration_test.dart` | partly exists |
| SYNC-07 | `CharacterLoaded` carries each new `status` (coins/HP/xp/location) from successive events; one existing status consumer widget (e.g. Shop coins or Journal) rebuilds from a real `CharacterCubit` fed by a `StreamController` | cubit + widget | `character_cubit_test.dart` + a small widget test for the chosen consumer | extend / Wave 0 |
| D-04 | all FE documents validate against the regenerated BE schema | manual script (pre-PR gate) | `tool/schema_check/*` commands above | Wave 0 (tooling) |
| E2E | snapshot at connect, live `twitchPoints`/`role`/`status`, drop and recover (airplane mode, wifi->cellular), 4401 cycle, resume after background, logout leaves no traffic, watchdog notice | manual (real BE, simulator/device) | checklist recorded in `BACKEND-NOTES.md` §5 | manual-only: needs the real backend and radio toggling |

### Sampling Rate
- **Per task commit:** the targeted test file(s) of the task (`flutter test <file>`), plus `flutter analyze <touched files>` and `dart format --output=none --set-exit-if-changed <touched files>`.
- **Per wave merge:** the quick run command above.
- **Phase gate:** full `flutter test` green (>= 481 + new), `flutter analyze` showing no new issues vs the 57-issue baseline, schema check green against the regenerated BE schema, manual E2E checklist done, **before** the PR is opened (D-04; BE PR merges first).

### Wave 0 Gaps (scaffolding the plans need first, TDD)
- [ ] `test/helpers/fakes/fake_graphql_ws_server.dart` — the fake graphql-transport-ws server above (counters per frame type, `dropWith(code)`, scripted `onSubscribe`; use 4401/1001, never 1006). Needs its own tiny self-test like `scripted_http_client_adapter_test.dart` has.
- [ ] `test/helpers/fixtures/user_event_fixtures.dart` — `userJson(...)` (reuse the shape in `graphql_character_creation_test.dart`), `QueryResult` builders for: data, shape A (`UnknownException(SubscriptionError)`), shape B (`graphqlErrors` with `FORBIDDEN`), malformed payload.
- [ ] `test/helpers/mocks.dart` — add `MockSessionTerminator`, `MockSyncHealth`, `MockAppLifecycleEvents` (or use the real `AppLifecycleEventBus`, which is trivial and preferable), `MockSessionSyncCubit` (`MockCubit`).
- [ ] Update `buildTestApp` call sites that mount `AuthenticatedShell` (`authenticated_shell_test.dart`) to provide `SyncHealth` and `AppLifecycleEvents` (the shell now requires them).
- [ ] Failing-first tests (Red) for: `SyncWatchdog`, `AppLifecycleEventBus`, `silentRetry`, `SessionSyncCubit`, `CharacterCubit` additions, `SessionHome` key, `AuthGate` pop rewrite, `terminateSession` on both services, SignIn notice.
- [ ] `tool/schema_check/dump_documents.dart` + `validate_documents.js` (and a unit test that every listed document parses).
- [ ] REQUIREMENTS.md: amend SYNC-05 wording ("creation or deletion", no admin-swap) and map SYNC-01..07 to Phase 3 in the traceability table; BACKEND-NOTES.md §5 filled at the end.

## Security Domain

(`security_enforcement` is absent in `.planning/config.json`, therefore enabled.)

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (inherits Phase 11) | token per connect via `WsReconnectPolicy`; watchdog teardown clears secure storage through the existing `_endSession` |
| V3 Session Management | yes | session ends through the single teardown path; no stream or listener outlives the session subtree (`close()` everywhere, `SafeEmit`) |
| V4 Access Control | yes | identity comes only from the bearer (BE); client-side defence in depth: `adoptUser` refuses events whose `user.id` differs from the session; backend `FORBIDDEN` for foreign character ids handled as a failure, never as data |
| V5 Input Validation | yes | subscription payloads parsed at one boundary (`_userFrom` / `Character.fromJson`), malformed events become a silent failure (D-14), never an unhandled exception in a stream |
| V6 Cryptography | no | no new crypto; TLS is the transport's job |
| V7 Error handling & logging | yes | never log tokens or full payloads (`docs/rules/graphql.md`): log only the error *code* and operation names; `SubscriptionStreamException.toString()` carries no payload |
| V9 Communications | yes | production `GRAPHQL_WS_URL` must be `wss://` (defaults in `env_config.dart` are dev `ws://192.168...`) [ASSUMED outside this phase: Phase 12 hardening] |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Late event of a previous identity enters the new session | Spoofing / Info disclosure | `adoptUser` id guard + cubit closed with the session subtree + `holder.reset()` disposing the link (tests in SYNC-04) |
| Listener/stream leak across logout | Info disclosure | single consumer per stream, cancel in `close()`, tested with `hasListener == false` and a fresh second session |
| Foreign character id subscription | Info disclosure | BE `FORBIDDEN` (BE Phase 3); client treats it as failure, no data path |
| Reconnect hot loop with a dead token | DoS (self) | existing bounded backoff; resubscribe backoff capped at 60 s; watchdog ends the session after the window |
| Token/payload in logs | Info disclosure | log codes only; no `print` of payloads |
| Event flood causing UI churn | DoS | events are whole small documents; `Equatable` dedup; optional `BlocSelector` (D-19) |
| Forced sign-out loop (watchdog false positive) | DoS (availability) | degraded-only semantics, suspend while backgrounded, single-latch expiry, guard against concurrent logout |

## Sources

### Primary (HIGH confidence)
- Installed source, read in full: `~/.pub-cache/hosted/pub.dev/graphql-5.2.1/lib/src/links/websocket_link/websocket_client.dart` (SocketClient, reconnect, `subscribe`, `_enqueuePing`), `websocket_link.dart` (`getSocketClient`, `connectOrReconnect`, `dispose`), `websocket_messages.dart`, `core/query_manager.dart` (`subscribe`, `_wrapFailure`), `exceptions/exceptions.dart`, `utilities/platform_io.dart` (`defaultConnectPlatform`).
- Installed source: `web_socket_channel-3.0.3/lib/io.dart` (`IOWebSocketChannel.connect` `pingInterval`/`connectTimeout` docs); Flutter 3.35.5 `widgets/app_lifecycle_listener.dart` (transition table and assertions).
- **Empirical probes (this session, deleted afterwards):** a local `dart:io` graphql-transport-ws server driven by the real `WebSocketLink`/`GraphQLClient`: P1 reconnect re-send + state sequence + double `connection_init`; P2 `error` message shape; P3 `next{errors}`+`complete` shape and no re-send after completion; P4 dispose leaves the stream silent and `cancel()` safe; P5 muted pongs -> single ping, state stays `connected`; P6 early `connectOrReconnect`. Widget probe: lifecycle callback sequences. Node probe: schema validation of the 4 existing documents against the current BE schema.
- Project files: `03-CONTEXT.md`, `BACKEND-NOTES.md`, `REQUIREMENTS.md`, `STATE.md`, `11-CONTEXT.md`, `02-CONTEXT.md`, `CLAUDE.md`, `docs/rules/*`, all referenced `lib/` and `test/` files; BE `03-CONTEXT.md`, `BACKEND-NOTES.md`, `src/schema.gql`, `package.json` (graphql-ws 6.0.6, graphql 16.11.0).

### Secondary (MEDIUM confidence)
- `https://pub.dev/api/packages/{graphql,graphql_flutter,web_socket_channel}` (latest versions, 2026-10-14) and `https://pub.dev/packages/graphql/changelog` (5.2.0 WS fixes; no WS entries for 5.2.2/5.2.3; 5.2.4/5.3.0 entries not visible).

### Tertiary (LOW confidence)
- graphql-js/graphql-ws behaviour for a resolver throwing during source-stream creation (shape B) — from memory, flagged A1; will be settled by the E2E.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — everything already in the project; one transitive package promoted to direct.
- Architecture: HIGH for library-facing parts (probed), MEDIUM for the cubit/widget split (a design recommendation within the stated discretion areas).
- Pitfalls: HIGH for 1-6 (source + probes), MEDIUM for real-device lifecycle/network behaviour (A4) and backend wire shape (A1).

**Research date:** 2026-10-14
**Valid until:** 2026-11-13 (30 days; re-check if `graphql` is bumped or BE Phase 3 changes the contract, and re-verify Pitfall 4 after the BE wave 1 lands)
