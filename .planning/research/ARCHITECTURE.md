# Architecture Research

**Domain:** Flutter BLoC/repository app — feature integration for v1.0 Core Loop
**Researched:** 2026-04-10
**Confidence:** HIGH (based on direct codebase analysis + established Flutter BLoC patterns)

---

## System Overview

The existing app is a well-structured BLoC app. The new features extend it without changing the layer contract: repositories own data access, cubits own state, screens own presentation. The only structural shifts are: (1) a top-level AuthBloc that wraps MaterialApp and gates everything else, (2) a global GraphQL link layer that reads auth tokens, and (3) a notification routing service that bridges Firebase callbacks to navigator state.

```
┌─────────────────────────────────────────────────────────────────┐
│  MaterialApp                                                      │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  AuthBloc (top-level — governs unauthenticated/auth state) │  │
│  │  ┌──────────────────────────────────────────────────────┐  │  │
│  │  │  MultiBlocProvider (all feature BLoCs/Cubits)        │  │  │
│  │  │  ┌────────────────────────────────────────────────┐  │  │  │
│  │  │  │  MainScreen / 6-tab shell                      │  │  │  │
│  │  │  │  ┌──────┬────────┬────────┬───┬──────┬──────┐  │  │  │  │
│  │  │  │  │Board │Journal │Library │Map│Shop  │Profile│  │  │  │  │
│  │  │  │  └──────┴────────┴────────┴───┴──────┴──────┘  │  │  │  │
│  │  │  └────────────────────────────────────────────────┘  │  │  │
│  │  └──────────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘

Services Layer (singletons, not in widget tree):
  AuthTokenService  ──► GraphQL AuthLink  ──► KlimmeckGraphQl
  NotificationService ──► NavigationService (GlobalKey<NavigatorState>)
  FirebaseMessaging
```

---

## Feature Integration Map

### 1. Auth — AuthBloc + AuthRepository + AuthTokenService

**Placement:** Top-level, above MaterialApp's child navigator, below MaterialApp itself.

The `AuthBloc` must live above the `MultiBlocProvider` that holds all other BLoCs. This way:
- Any screen can call `context.read<AuthBloc>()` to trigger logout.
- When `AuthBloc` emits `AuthUnauthenticated`, the root widget swaps to the sign-in screen unconditionally (all other BLoCs are torn down with the subtree).
- `main.dart` changes from its current `MultiBlocProvider` root to:

```
BlocProvider<AuthBloc>(
  create: (_) => AuthBloc(authRepository)..add(AuthStarted()),
  child: BlocListener<AuthBloc, AuthState>(
    listener: (ctx, state) { /* redirect on logout */ },
    child: MaterialApp(
      home: BlocBuilder<AuthBloc, AuthState>(
        builder: (ctx, state) => state is AuthAuthenticated
            ? MultiBlocProvider(providers: [...], child: MainScreen())
            : SignInScreen(),
      ),
    ),
  ),
)
```

The `MultiBlocProvider` subtree is created only after authentication — this prevents any feature BLoC from running unauthenticated queries.

**Token flow — how other features get the auth token for GraphQL:**

Do NOT pass tokens through BLoC constructors or repository constructors. Instead:

1. Create `AuthTokenService` — a simple singleton that holds the current access token in memory and exposes a synchronous getter:

```dart
class AuthTokenService {
  String? _accessToken;
  void setToken(String token) => _accessToken = token;
  void clear() => _accessToken = null;
  String? get token => _accessToken;
}
```

2. `AuthBloc` calls `authTokenService.setToken(token)` on every successful auth/refresh and `authTokenService.clear()` on logout.

3. `KlimmeckGraphQl` (the existing GraphQL client wrapper) is initialized with an `AuthLink` that reads from `AuthTokenService` at request time — not at initialization time:

```dart
final authLink = AuthLink(
  getToken: () async => 'Bearer ${authTokenService.token ?? ""}',
);
final link = authLink.concat(httpLink);
```

This way `KlimmeckGraphQl` never needs to know about the BLoC tree. No `navigatorKey.currentContext` needed for auth headers (which removes the existing fragile pattern flagged in CONCERNS.md).

**New components:**
- `lib/repository/auth/auth_repository.dart` — Twitch OAuth, token refresh, token revoke
- `lib/repository/auth/auth_token_service.dart` — in-memory token holder singleton
- `lib/screens/auth/cubit/auth_bloc.dart` + `auth_state.dart` + `auth_event.dart` (use Bloc not Cubit — it has events for `AuthStarted`, `AuthLoginRequested`, `AuthLogoutRequested`, `AuthTokenRefreshed`, `AuthTokenExpired`)
- `lib/repository/storage/secure_storage_service.dart` — wraps `flutter_secure_storage` for refresh token persistence

**Modified components:**
- `lib/main.dart` — restructure MultiBlocProvider to nest inside AuthBloc
- `lib/repository/services/graphql/graphql_client_provider.dart` — inject AuthLink
- `lib/screens/signIn/cubit/sign_in_cubit.dart` — delegate to `AuthBloc`, may be absorbed entirely

**Token persistence:** Refresh token in `flutter_secure_storage` (add package). Access token in `AuthTokenService` memory only — short-lived, refreshed on app resume via `AuthStarted` event.

---

### 2. GraphQL Subscription Lifecycle — UserBloc

**Scope:** The user subscription should be open for the entire authenticated session — not per-screen. User state (channel points, coins, character status, travel state) is consumed across all 6 tabs. Keeping it per-screen would require re-subscribing on every tab switch and lose events in the gap.

**Structure:**

```dart
class UserBloc extends Bloc<UserEvent, UserState> {
  StreamSubscription? _sub;

  UserBloc(this._userRepository) : super(UserInitial()) {
    on<UserSubscriptionStarted>(_onSubscriptionStarted);
    on<UserSubscriptionUpdated>(_onUpdated);
    on<UserSubscriptionError>(_onError);
    on<UserSubscriptionReconnect>(_onReconnect);
  }

  Future<void> _onSubscriptionStarted(event, emit) async {
    _sub = _userRepository.watchUser().listen(
      (user) => add(UserSubscriptionUpdated(user)),
      onError: (e) => add(UserSubscriptionError(e.toString())),
      onDone: () => add(UserSubscriptionReconnect()),
    );
  }
}
```

**Re-subscribe on reconnect/app resume:**

Add `AppLifecycleObserver` (a `WidgetsBindingObserver`) that emits `UserSubscriptionReconnect` when the app returns to the foreground (`AppLifecycleState.resumed`). The `_onReconnect` handler cancels the old subscription, waits a brief backoff, then calls `_onSubscriptionStarted` again.

The `graphql_flutter` WebSocket link handles its own connection, but it does NOT automatically re-subscribe to user-defined subscriptions when the socket reconnects. You must cancel and re-subscribe manually. The `onDone` callback of the stream triggers `UserSubscriptionReconnect` for server-side disconnects.

**Link layer with auth header:**

The WebSocket link also needs the auth token. Use `WebSocketLink` from `graphql_flutter` with a custom `initialPayload` that reads from `AuthTokenService`:

```dart
final wsLink = WebSocketLink(
  EnvConfig.graphqlWsUrl,
  config: SocketClientConfig(
    initialPayload: () async => {
      'Authorization': 'Bearer ${authTokenService.token ?? ""}',
    },
  ),
);
final link = Link.split(
  (request) => request.isSubscription,
  wsLink,
  authLink.concat(httpLink),
);
```

**New components:**
- `lib/screens/mainScreen/userBloc/user_bloc.dart` + `user_state.dart` + `user_event.dart`
- `lib/repository/user/user_repository.dart` — wraps the GraphQL user subscription + user queries
- `lib/utils/app_lifecycle_observer.dart` — `WidgetsBindingObserver` that fires reconnect events

**Modified components:**
- `lib/repository/services/graphql/graphql_client_provider.dart` — split link for subscription vs. query/mutation
- `lib/main.dart` — register `UserBloc` in `MultiBlocProvider`, add `WidgetsBindingObserver`
- Existing `CharacterCubit` — may be partially merged into `UserBloc` or become a thin consumer of it (see section 10)

---

### 3. Push Notification Routing

**Strategy:** Use `NavigationService` with a `GlobalKey<NavigatorState>` for push-triggered navigation. Do NOT use go_router for this milestone — the existing app has manual route transitions (`createSlideRoute`, `createFadeRoute`) and no router package. Introducing go_router would be a significant refactor orthogonal to the v1.0 goals.

**Why not go_router deep links:** go_router is the right long-term answer but it requires rethinking the entire navigation structure. The current tab-based shell navigation is not expressed as a route tree, so adding go_router to fix notification routing would pull in a larger refactor than warranted.

**Pattern:**

```dart
// lib/services/navigation_service.dart
class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  void navigateTo(String route, {Object? arguments}) {
    navigatorKey.currentState?.pushNamed(route, arguments: arguments);
  }

  void switchToTab(int index) {
    // Use a GlobalKey on MainScreen's scaffold or expose a tab controller
    mainScreenKey.currentState?.setTab(index);
  }
}
```

**Notification payload routing:**

```dart
// lib/services/notification_service.dart
class NotificationService {
  Future<void> initialize() async {
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _handleNotificationTap(initial);
  }

  void _handleNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    switch (type) {
      case 'travel_complete':
        navigationService.switchToTab(TabIndex.map);
      case 'quest_complete':
        navigationService.switchToTab(TabIndex.board);
      case 'combat_result':
        navigationService.switchToTab(TabIndex.board);
        // Then show combat result sheet — trigger via BLoC event
        userBloc.add(CombatResultNotificationReceived(message.data));
      case 'streamer_live':
        // In-app banner only, no navigation
    }
  }
}
```

The `NavigationService.navigatorKey` is passed to `MaterialApp(navigatorKey: ...)`.

**FCM initialization:** Firebase was already added as a dependency but disabled. The first task of this feature is completing Firebase initialization in `main.dart` (add `await Firebase.initializeApp()`, add `GoogleService-Info.plist` / `google-services.json`).

**New components:**
- `lib/services/navigation_service.dart`
- `lib/services/notification_service.dart`

**Modified components:**
- `lib/main.dart` — Firebase init, register `NotificationService`, pass `navigatorKey` to `MaterialApp`
- `lib/screens/mainScreen/main_screen.dart` — expose tab-switching via a `GlobalKey` or callback

---

### 4. Travel Timer State

**Single source of truth: the server.** Rationale: travel duration is calculated server-side based on distance and road speed. The server emits travel start timestamp and ETA. The client displays a countdown derived from those values.

**Pattern:**

```dart
class TravelState {
  final DateTime? travelStartedAt;   // from server (UTC)
  final DateTime? travelEta;         // from server (UTC)
  Duration get remaining => travelEta == null
      ? Duration.zero
      : travelEta!.difference(DateTime.now().toUtc());
}
```

`TravelBloc` holds the authoritative timestamps from the server. A `Timer.periodic(1.second)` in the **widget** (not in the BLoC) calls `setState` or uses a `Stream.periodic` in the view to recompute `remaining` every second from the immutable BLoC state. The BLoC itself does not tick — it only updates when the server emits a new travel event.

**On app resume / app killed mid-travel:**

When the app resumes (via `AppLifecycleObserver`), `TravelBloc` receives `TravelSyncRequested`. It fetches the current travel status from the server (query, not subscription). If `travelEta` is already past, the travel is over — emit `TravelCompleted`. If still in progress, re-emit `TravelInProgress` with the server timestamps, and the UI countdown resumes correctly without any stored local state.

If the app was killed mid-travel: on next launch `SplashCubit` (or the initial data fetch) queries travel status from the backend as part of the character/user state fetch.

**Do not use `Timer.periodic` inside the BLoC.** BLoC state should be data only, not time-driven side effects. The display layer owns the rendering tick.

**New components:**
- `lib/screens/mainScreen/tabs/map/travelBloc/travel_bloc.dart` + states + events
- Travel-related GraphQL queries/mutations in `lib/graphql/mutations/travel_mutations.dart`

**Modified components:**
- `lib/screens/mainScreen/tabs/map/world_map.dart` — add travel overlay with countdown widget
- `lib/screens/mainScreen/tabs/map/cubit/world_map_cubit.dart` — integrate with `TravelBloc` or partially replace

---

### 5. Quest Info Sheets Per Type

**Recommendation: widget factory pattern** (not a single widget with conditional sections).

A single widget with 10 conditional `if questType == X` branches becomes unreadable and untestable at scale. The factory pattern is marginally more file overhead but each quest type widget is independently editable and testable.

```dart
// lib/shared/components/quest/quest_info_sheet_factory.dart
abstract class QuestInfoSheet extends StatelessWidget {
  const QuestInfoSheet({super.key, required this.quest});
  final Quest quest;
}

class QuestInfoSheetFactory {
  static QuestInfoSheet create(Quest quest) {
    return switch (quest.type) {
      QuestType.hunt     => HuntQuestInfoSheet(quest: quest),
      QuestType.boss     => BossQuestInfoSheet(quest: quest),
      QuestType.dungeon  => DungeonQuestInfoSheet(quest: quest),
      QuestType.heal     => HealQuestInfoSheet(quest: quest),
      QuestType.story    => StoryQuestInfoSheet(quest: quest),
      QuestType.worldMission => WorldMissionQuestInfoSheet(quest: quest),
      // ... remaining types
      _ => DefaultQuestInfoSheet(quest: quest),
    };
  }
}
```

Quest types that share structure (hunt/enemy/boss are all combat-oriented) can share a `BaseCombatQuestInfoSheet` with override points. This avoids both the monolith and full duplication.

The swipe gesture ("strappa foglio") triggers `QuestInfoSheetFactory.create(quest)` shown as a bottom sheet in `BoardPage`, then a confirmation calls `QuestBloc.add(QuestAccepted(quest.id))`.

**New components:**
- `lib/shared/components/quest/quest_info_sheet_factory.dart`
- `lib/shared/components/quest/sheets/hunt_quest_info_sheet.dart` (and one file per distinct type)
- `lib/shared/components/quest/sheets/base_combat_quest_info_sheet.dart` (shared base for combat types)

**Modified components:**
- `lib/screens/mainScreen/tabs/board/` — add swipe gesture detector on quest list items
- Existing `QuestBloc` (or equivalent cubit) — add `QuestAccepted` event/handler

---

### 6. Admin Panel Gating

**Pattern: role-based navigation item visibility + route guard, not a separate route tree.**

A separate route tree is overkill for a single-streamer app. The admin panel is one feature that only one person uses. The cleanest approach:

1. `UserBloc` / the user entity exposes `bool isAdmin` (derived from a role flag on the user model from the backend).
2. In `MainScreen`, the navigation bar conditionally shows an admin item (7th tab or a floating button) only when `context.watch<UserBloc>().state.user?.isAdmin == true`.
3. The admin route itself has a guard: if somehow navigated to while `!isAdmin`, it redirects to the board tab.

```dart
// In MainScreen build:
BlocBuilder<UserBloc, UserState>(
  buildWhen: (prev, curr) => prev.user?.isAdmin != curr.user?.isAdmin,
  builder: (ctx, state) {
    final isAdmin = state.user?.isAdmin ?? false;
    return BottomNavigationBar(
      items: [
        ...standardTabs,
        if (isAdmin) adminTab,
      ],
    );
  },
)
```

Do NOT implement feature flags from a separate config service for this. The role comes from the authenticated user entity — that is the source of truth. No additional propagation mechanism needed beyond what `UserBloc` already provides.

**New components:**
- `lib/screens/mainScreen/tabs/admin/admin_screen.dart`
- `lib/screens/mainScreen/tabs/admin/cubit/admin_bloc.dart` + states + events
- `lib/repository/admin/admin_repository.dart`

**Modified components:**
- `lib/screens/mainScreen/main_screen.dart` — conditional admin tab
- User model — add `isAdmin` field

---

### 7. Settings Persistence

**Split by sensitivity:**

| Setting | Storage | Rationale |
|---------|---------|-----------|
| Notification preferences (per type) | `shared_preferences` | Non-sensitive, device-local, survives logout |
| Auth refresh token | `flutter_secure_storage` | Sensitive — encrypted keychain/keystore |
| FCM device token | `shared_preferences` | Non-sensitive, backend also stores it |
| Account ID (Twitch) | `shared_preferences` | Non-sensitive display cache |
| Logout action | `AuthBloc` event | Not a stored preference — triggers auth state change |

The Settings screen calls `AuthBloc.add(AuthLogoutRequested())` for logout — it does not directly touch storage. The `AuthRepository` handles clearing secure storage on logout.

For notification preferences, a `PreferencesRepository` wraps `SharedPreferences` with typed getters/setters. The Settings screen reads from `PreferencesCubit` (a simple cubit that loads/saves preferences) and pushes changes to both local storage and the backend (so the server can gate which push types to send).

**New components:**
- `lib/screens/mainScreen/tabs/settings/settings_screen.dart`
- `lib/screens/mainScreen/tabs/settings/cubit/preferences_cubit.dart` + state
- `lib/repository/preferences/preferences_repository.dart`

**Modified components:**
- `lib/screens/mainScreen/main_screen.dart` — add settings tab or modal trigger in profile tab
- `lib/repository/storage/storage_manager.dart` — extend with notification pref keys

---

### 8. Combat Result Trigger

**Recommended: subscription event + optional push notification as fallback.**

The backend already has WebSocket subscriptions. The cleanest pattern is a `combatResult` subscription that emits when combat resolves. `CombatResultBloc` subscribes to this stream for the duration of the authenticated session (same lifecycle as `UserBloc`).

When the app is in the foreground: the subscription fires → `CombatResultBloc` emits `CombatResultReceived` → a `BlocListener` in `BoardPage` (or wherever the result sheet lives) triggers the modal.

When the app is in background: the backend sends an FCM push notification (type `combat_result`) → user taps it → `NotificationService._handleNotificationTap` fires `CombatResultNotificationReceived` event on `CombatResultBloc` with the result ID from the notification payload → `CombatResultBloc` fetches the full result via query and shows the sheet.

**Do NOT poll.** Polling with 1-5 second intervals is simpler to implement but creates unnecessary load and worse UX. The subscription is already wired infrastructure.

```
Combat resolves on server
    ├─► WebSocket subscription event → CombatResultBloc (foreground)
    └─► FCM push notification → NotificationService → CombatResultBloc (background)
```

**New components:**
- `lib/screens/mainScreen/combatResultBloc/combat_result_bloc.dart` + states + events
- `lib/repository/combat/combat_repository.dart`
- `lib/shared/components/combat/combat_result_sheet.dart`
- `lib/graphql/subscriptions/combat_subscriptions.dart`

---

### 9. Spells Section in Journal

Straightforward extension of the existing journal pattern. `JournalCubit` currently handles equipment; spells are a separate domain with their own lifecycle (cooldown, uses remaining, equip slots).

**New components:**
- `lib/screens/mainScreen/tabs/journal/spellsBloc/spells_bloc.dart` + states + events
- `lib/repository/spells/spells_repository.dart`
- `lib/screens/mainScreen/tabs/journal/components/spells_tab.dart` (tab within journal)
- `lib/graphql/queries/spells_queries.dart` + mutations

**Modified components:**
- `lib/screens/mainScreen/tabs/journal/journal.dart` — add spells tab (likely a `TabBar` within journal, alongside equipment tab)

---

### 10. Existing Components That Need Modification

| Component | Modification | Why |
|-----------|-------------|-----|
| `lib/main.dart` | Add `AuthBloc` as outer provider, Firebase init, `NavigationService.navigatorKey` to `MaterialApp`, `AppLifecycleObserver`, `UserBloc` in `MultiBlocProvider` | Foundation for all features |
| `lib/repository/services/graphql/graphql_client_provider.dart` | Add `AuthLink`, split link for subscriptions vs. HTTP | Auth header injection, subscription support |
| `lib/screens/signIn/cubit/sign_in_cubit.dart` | Delegate to `AuthBloc`; may be replaced | Sign-in is now auth-bloc driven |
| `lib/screens/mainScreen/main_screen.dart` | Conditional admin tab, settings access, tab-switching API for `NavigationService` | Multiple features need to manipulate navigation |
| `lib/screens/mainScreen/tabs/map/world_map.dart` | Travel overlay with countdown display | Travel timer UI |
| `lib/screens/mainScreen/tabs/board/` (quest list) | Swipe gesture + `QuestInfoSheetFactory` integration | Quest accept flow |
| `lib/screens/mainScreen/tabs/journal/journal.dart` | Add spells tab | Spells section |
| User/Character model | Add `isAdmin`, travel status fields, spells fields | New data from subscription |
| `lib/config/env_config.dart` | Remove hardcoded IP defaults (CONCERNS.md debt), add Twitch OAuth env vars | Security + auth |

---

## Data Flow: Auth → GraphQL Headers → Subscriptions → BLoCs → UI

```
App launch
    │
    ▼
AuthBloc (AuthStarted event)
    │── checks SecureStorage for refresh token
    │── if found: calls AuthRepository.refreshToken()
    │        └── on success: AuthTokenService.setToken(accessToken)
    │                          emit AuthAuthenticated(user)
    │── if not found: emit AuthUnauthenticated
    │
    ▼ (authenticated branch)
MultiBlocProvider instantiated
    │
    ├─► UserBloc (UserSubscriptionStarted)
    │       │── UserRepository.watchUser()
    │       │       └── KlimmeckGraphQl.subscribe(userSubscription)
    │       │               └── WebSocketLink reads AuthTokenService.token
    │       └── emits UserState with user data
    │
    ├─► CombatResultBloc (subscribed to combat events)
    ├─► TravelBloc (fetches travel status on init)
    └─► SpellsBloc, AdminBloc (load data on demand)

Feature BLoC needs data
    │
    ▼
Repository method
    │
    ▼
KlimmeckGraphQl.query / .mutate
    │
    ▼
AuthLink.getToken() → AuthTokenService.token (synchronous read)
    │
    ▼
HTTP/WS request with Authorization header
    │
    ▼ (401 response)
AuthBloc.add(AuthTokenExpired)
    │── AuthRepository.refreshToken()
    │       └── on success: AuthTokenService.setToken(newToken), retry
    │       └── on failure: AuthTokenService.clear(), emit AuthUnauthenticated
    └── All BLoCs torn down (MultiBlocProvider subtree rebuilt on next auth)

Push notification arrives (background)
    │
    ▼
FirebaseMessaging.onMessageOpenedApp
    │
    ▼
NotificationService._handleNotificationTap(message)
    │
    ├─► NavigationService.switchToTab(targetTab)
    └─► BLoC.add(NotificationEvent(payload))
            └── BLoC fetches data → emits state → UI shows sheet
```

---

## Suggested Build Order

Dependencies drive this order. Each tier unblocks the next.

### Tier 1 — Foundation (everything else depends on these)

1. **Auth (AuthBloc + AuthRepository + AuthTokenService + SecureStorage)**
   - Enables authenticated GraphQL requests
   - Enables UserBloc subscription
   - Enables Admin gating
   - Enables Settings/logout
   - **Blocks everything that needs a user identity**

2. **GraphQL link layer (AuthLink + WebSocket split)**
   - Must be done alongside Auth so subscription and query both carry the token
   - Fixes the existing `navigatorKey.currentContext!` fragility in `graphql.dart`

### Tier 2 — User Sync (unblocks UI features that display user data)

3. **UserBloc + UserRepository + AppLifecycleObserver**
   - Real-time sync of channel points, coins, character status
   - `isAdmin` flag becomes available → Admin panel can be conditionally shown
   - Travel status is part of user state → TravelBloc can initialize correctly
   - **Unblocks: Admin panel, Travel display, Combat result (user HP delta)**

### Tier 3 — Notification Infrastructure

4. **Firebase initialization + NotificationService + NavigationService**
   - Must come before travel notifications and quest notifications
   - Can be built in parallel with Tier 2 (no dependency)
   - Finalizing FCM token registration requires an authenticated user, so complete after Tier 1

### Tier 4 — Core Loop Features (can be built in parallel after Tier 2+3)

5. **Settings screen + PreferencesRepository** (quick win, unlocks logout in-app)
6. **Quest swipe gesture + QuestInfoSheetFactory** (pure UI, uses existing QuestBloc data)
7. **Travel system — TravelBloc + Map UI** (depends on UserBloc for initial state, NotificationService for arrival push)
8. **Spells section in Journal — SpellsBloc + SpellsRepository** (isolated, parallel to travel)

### Tier 5 — Complex/Event-Driven Features

9. **Combat result sheet — CombatResultBloc + CombatRepository** (depends on subscription infrastructure from Tier 2, NotificationService from Tier 3)
10. **Admin panel — AdminBloc + AdminRepository** (depends on isAdmin from UserBloc)

### Tier 6 — Hardening

11. **Bug fixing, security audit, concurrency** — after all features are functionally complete

---

## Anti-Patterns to Avoid

### Anti-Pattern 1: Feature BLoCs owning the user subscription

**What people do:** Each BLoC that needs user data opens its own subscription.
**Why it's wrong:** Multiple WebSocket subscriptions to the same feed, reconnect logic duplicated, race conditions between updates.
**Do this instead:** One `UserBloc` owns the subscription and emits canonical `UserState`. Feature BLoCs read from `UserBloc` via `context.read<UserBloc>().state` or react to `UserBloc` state changes via `BlocListener`.

### Anti-Pattern 2: AuthBloc at feature level

**What people do:** Each screen individually checks if the token is valid and redirects.
**Why it's wrong:** Inconsistent gating, logout from one screen doesn't affect others, unauthenticated requests leak through.
**Do this instead:** `AuthBloc` at the root — when it emits `AuthUnauthenticated`, the entire authenticated subtree is removed from the widget tree, tearing down all feature BLoCs simultaneously.

### Anti-Pattern 3: Timer.periodic inside BLoC for travel countdown

**What people do:** `TravelBloc` runs a `Timer.periodic(1.second)` and emits a new state every second.
**Why it's wrong:** BLoC emitting 1 state/second for potentially 30+ minutes creates 1800+ state objects; all `BlocBuilder`s on `TravelBloc` rebuild every second across the whole app.
**Do this instead:** BLoC holds only the server timestamps. The travel countdown widget owns a local `Timer.periodic` that recomputes from the immutable timestamps and calls `setState` on itself only — no BLoC event.

### Anti-Pattern 4: Passing BuildContext into repositories

**What people do:** Repositories accept `BuildContext` to read BLoC state or navigate.
**Why it's wrong:** Tight coupling, untestable, breaks when context is null (the existing `navigatorKey.currentContext!` bug).
**Do this instead:** `AuthTokenService` singleton for token access, `NavigationService` singleton for navigation. Repositories depend on neither the widget tree nor BLoC state.

### Anti-Pattern 5: Per-type widget with nested if/switch inside one file

**What people do:** `QuestInfoSheet` widget with `if (quest.type == QuestType.hunt) ... else if (quest.type == QuestType.boss) ...` for 10 types.
**Why it's wrong:** 300+ line widget, impossible to modify one type without risk of breaking others, no way to add a new type cleanly.
**Do this instead:** Factory pattern with one file per quest type. Common layout goes in `BaseQuestInfoSheet`.

---

## New Components Summary

| Component | Path | Type | Depends On |
|-----------|------|------|------------|
| `AuthBloc` | `lib/screens/auth/cubit/auth_bloc.dart` | Bloc | AuthRepository, AuthTokenService |
| `AuthRepository` | `lib/repository/auth/auth_repository.dart` | Repository | KlimmeckRest (Twitch OAuth), SecureStorageService |
| `AuthTokenService` | `lib/repository/auth/auth_token_service.dart` | Service singleton | — |
| `SecureStorageService` | `lib/repository/storage/secure_storage_service.dart` | Service | flutter_secure_storage |
| `UserBloc` | `lib/screens/mainScreen/userBloc/user_bloc.dart` | Bloc | UserRepository |
| `UserRepository` | `lib/repository/user/user_repository.dart` | Repository | KlimmeckGraphQl |
| `AppLifecycleObserver` | `lib/utils/app_lifecycle_observer.dart` | Observer | UserBloc, TravelBloc |
| `NavigationService` | `lib/services/navigation_service.dart` | Service singleton | GlobalKey<NavigatorState> |
| `NotificationService` | `lib/services/notification_service.dart` | Service | FirebaseMessaging, NavigationService |
| `TravelBloc` | `lib/screens/mainScreen/tabs/map/travelBloc/travel_bloc.dart` | Bloc | TravelRepository |
| `TravelRepository` | `lib/repository/travel/travel_repository.dart` | Repository | KlimmeckGraphQl |
| `QuestInfoSheetFactory` | `lib/shared/components/quest/quest_info_sheet_factory.dart` | Widget factory | Quest model |
| Quest sheet widgets (×10) | `lib/shared/components/quest/sheets/` | StatelessWidgets | Quest model |
| `CombatResultBloc` | `lib/screens/mainScreen/combatResultBloc/combat_result_bloc.dart` | Bloc | CombatRepository |
| `CombatRepository` | `lib/repository/combat/combat_repository.dart` | Repository | KlimmeckGraphQl |
| `CombatResultSheet` | `lib/shared/components/combat/combat_result_sheet.dart` | Widget | — |
| `SpellsBloc` | `lib/screens/mainScreen/tabs/journal/spellsBloc/spells_bloc.dart` | Bloc | SpellsRepository |
| `SpellsRepository` | `lib/repository/spells/spells_repository.dart` | Repository | KlimmeckGraphQl |
| `AdminBloc` | `lib/screens/mainScreen/tabs/admin/cubit/admin_bloc.dart` | Bloc | AdminRepository |
| `AdminRepository` | `lib/repository/admin/admin_repository.dart` | Repository | KlimmeckGraphQl |
| `PreferencesCubit` | `lib/screens/mainScreen/tabs/settings/cubit/preferences_cubit.dart` | Cubit | PreferencesRepository |
| `PreferencesRepository` | `lib/repository/preferences/preferences_repository.dart` | Repository | SharedPreferences, KlimmeckGraphQl |

---

## Sources

- Direct codebase analysis: `.planning/codebase/ARCHITECTURE.md`, `STRUCTURE.md`, `INTEGRATIONS.md`, `STACK.md`, `CONCERNS.md`
- Flutter BLoC pattern: established community convention for top-level auth BLoC placement (bloc library docs)
- `graphql_flutter` AuthLink pattern: package documentation for auth header injection
- Firebase Messaging lifecycle: `onMessageOpenedApp` vs `getInitialMessage` pattern (Firebase docs)

---

*Architecture research for: Klimmeck Guide v1.0 Core Loop feature integration*
*Researched: 2026-04-10*
