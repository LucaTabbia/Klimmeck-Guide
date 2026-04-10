# Domain Pitfalls

**Domain:** Brownfield Flutter mobile RPG — adding auth, real-time GraphQL subscriptions, push notifications, gesture UI, travel timers, admin panel, and concurrency hardening to an existing BLoC app backed by NestJS + MongoDB
**Researched:** 2026-04-10

---

## Critical Pitfalls

Mistakes that cause rewrites, data leaks, or broken game state.

---

### Pitfall 1: OAuth Tokens Stored in SharedPreferences

**What goes wrong:** The existing `storage_manager.dart` already uses `shared_preferences` for cached URLs. If the new auth flow stores the Twitch OAuth access token and refresh token in the same `StorageManager`, they are written to an unencrypted platform-specific key-value store. On rooted Android devices and unencrypted iOS backups the values are readable in plaintext.

**Why it happens:** SharedPreferences is the path of least resistance. The pattern is already established in the codebase and is tempting to reuse.

**Consequences:** Token exfiltration → attacker impersonates the user against both the game backend and the Twitch API. Losing refresh token = permanent session loss for the user.

**Prevention:**
- Add `flutter_secure_storage` to `pubspec.yaml`.
- Create a `SecureStorageManager` alongside the existing `StorageManager`. Store ONLY tokens and sensitive identity data there.
- Keep non-sensitive data (cached Cloudinary URLs, UI prefs) in `shared_preferences` — that is fine.
- On first run after update, migrate any existing token from SharedPreferences to SecureStorage then delete the insecure copy.

**Detection signal:** Search for `SharedPreferences` / `StorageManager.save` calls with keys matching `token`, `access_token`, `refresh_token`, `account_id`. Any hit is a bug.

**Phase:** Auth implementation phase. Do not accept the auth PR without this in place.

---

### Pitfall 2: Token Refresh Race Condition

**What goes wrong:** Two concurrent GraphQL operations (e.g., CharacterCubit subscription reconnect + a mutation from QuestCubit) each receive a 401. Both independently call the token refresh endpoint. The first call succeeds and stores a new access token. The second call uses the now-invalidated old refresh token → Twitch returns an error → user is silently logged out mid-session.

**Why it happens:** No synchronisation primitive guards the refresh flow. Each Cubit or the GraphQL client wrapper acts independently.

**Consequences:** Random mid-session logouts, especially on unstable connections where re-auth is frequent.

**Prevention:**
- Implement a single `AuthRepository` with a `Mutex` (use the `mutex` Dart package) around the refresh call.
- Before refreshing: acquire lock, check if token was already refreshed by another caller (compare stored token with the one that triggered the 401). If it already changed, release lock and retry with the new token. If not, perform refresh, store result, release lock.
- Expose a single `Future<String> getValidAccessToken()` method that all network layers call — never read the token directly from storage in Cubits.

**Detection signal:** Two simultaneous requests both return 401 and one triggers a logout. Reproduced by throttling the network to force a very slow refresh and firing two mutations simultaneously.

**Phase:** Auth implementation phase. Critical before enabling any background subscription reconnect logic.

---

### Pitfall 3: Stale Data on Logout / Account Switch

**What goes wrong:** User logs out (or switches Twitch account). The CharacterCubit, JournalCubit, ShopCubit, WorldMapCubit all hold in-memory state for the previous user. The GraphQL `InMemoryStore` cache (currently unbounded per CONCERNS.md) also retains previous user's queries. If the same device is used by a second person (e.g., at a LAN party), they see the first person's character data before the next fetch completes.

**Why it happens:** Logout is often implemented as "clear tokens and navigate to sign-in", without explicitly resetting BLoC state or flushing the GraphQL cache.

**Consequences:** Data leakage between accounts. Potentially corrupted game state if the second user's actions are sent with stale identity.

**Prevention:**
- Create a `LogoutUseCase` that performs in order: (1) revoke Twitch token via API, (2) clear `SecureStorageManager` tokens, (3) clear `SharedPreferences` cached URLs (if user-specific), (4) call `graphqlClient.cache.store.reset()` to flush InMemoryStore, (5) close all active subscriptions, (6) call `close()` on all Cubits that hold user-specific state (or emit their initial/empty state), (7) navigate to sign-in.
- Register this sequence centrally (e.g., in `AuthRepository`) so no caller can skip a step.
- Test with two different Twitch accounts on the same device.

**Detection signal:** After logout, `CharacterCubit.state` still contains the previous user's character name or coins.

**Phase:** Auth implementation phase. Also revisited in hardening phase via audit checklist.

---

### Pitfall 4: Deep Link Hijacking During OAuth Callback

**What goes wrong:** Twitch's OAuth redirect returns to a custom URL scheme (e.g., `klimmeck://oauth/callback?code=...`). On Android, any app can register the same scheme. A malicious app installed on the device intercepts the callback before Klimmeck Guide and steals the `code` parameter, then exchanges it for tokens.

**Why it happens:** OAuth callback via custom scheme is the standard mobile pattern but it lacks origin verification without PKCE.

**Consequences:** Complete account takeover if the attacker's app exchanges the code first.

**Prevention:**
- Use PKCE (Proof Key for Code Exchange) unconditionally. Generate a cryptographically random `code_verifier` per login attempt (43–128 chars from `[A-Za-z0-9\-._~]`). Derive `code_challenge = BASE64URL(SHA256(code_verifier))`. Use `S256` challenge method — never `plain`.
- Store `code_verifier` in memory only (not SharedPreferences, not SecureStorage) for the duration of the login flow. Discard after use; never reuse.
- On Android, prefer `https://` App Links (verified domain) over custom schemes if Twitch's OAuth supports it — this eliminates scheme hijacking entirely because only the domain owner can receive the callback.
- Validate that the `state` parameter in the callback matches the one sent in the initial redirect.

**Detection signal:** Attempted login using a previously used `code_verifier` should be rejected by the backend. Test by replaying a captured callback URL.

**Phase:** Auth implementation phase.

---

### Pitfall 5: GraphQL Subscriptions Not Closed on Logout

**What goes wrong:** `CharacterCubit` opens a subscription stream to receive real-time character updates. On logout the Cubit is not closed, or its subscription `StreamSubscription` is not cancelled. The WebSocket remains connected. The new user logs in and a second subscription is opened for their account — but the old subscription is still delivering events for the previous account into the (now-reset) CharacterCubit, causing ghost state updates.

**Why it happens:** The existing `CONCERNS.md` already flags "Fire-and-Forget Delayed Emissions" in Cubits. The same pattern will appear for subscription streams.

**Consequences:** Memory leak (WebSocket + stream held open), potential data leak (receiving another user's events), unpredictable UI state.

**Prevention:**
- Every Cubit that holds a `StreamSubscription` must cancel it in `close()`.
- The `LogoutUseCase` (see Pitfall 3) must close the relevant Cubits before navigating away — not just let them get garbage-collected.
- `CharacterCubit.close()` override: cancel subscription, then call `super.close()`.
- Consider a `SubscriptionRegistry` singleton that tracks all active subscriptions and provides a `cancelAll()` method callable from logout.

**Detection signal:** After logout, the WebSocket connection remains open in network inspector. Or new user's CharacterCubit emits states with the old user's account_id.

**Phase:** Auth implementation phase + Real-time sync phase.

---

### Pitfall 6: Duplicate Subscriptions on Screen Re-entry

**What goes wrong:** User navigates away from the board tab and back. The board screen's Cubit (or the CharacterCubit provided at root) re-subscribes on each `initState` without checking if a subscription is already active. Each re-entry opens a new subscription. After five navigations there are five duplicate event streams; every update fires five times.

**Why it happens:** `initState` is the natural place to start a subscription in Flutter, and it is called every time a route is pushed back to the top.

**Consequences:** Duplicate state emissions, UI flickering, race conditions between five concurrent event handlers.

**Prevention:**
- Start subscriptions in the Cubit constructor or in a guard-gated method: `if (_subscription != null) return;`.
- For Cubits provided at `MultiBlocProvider` root (`main.dart`), the Cubit is created once per app lifetime — subscriptions belong there.
- For feature-scoped Cubits, start subscription in `BlocProvider` with `lazy: false` and cancel in `close()`.
- During development: add an assertion that counts active subscriptions and logs a warning if `> 1`.

**Detection signal:** Quest board shows the same update applied twice (e.g., coins deducted twice for one purchase). Also: multiple identical WebSocket messages in network logs.

**Phase:** Real-time sync implementation phase.

---

### Pitfall 7: WebSocket Auth Not Updated After Token Refresh

**What goes wrong:** `graphql_flutter` establishes a WebSocket for subscriptions with an `Authorization` header set at connection time. After the access token is refreshed (Pitfall 2), the HTTP layer uses the new token, but the already-open WebSocket still sends the old token in subscription payloads or `connection_init`. The backend's subscription auth middleware rejects events, or — worse — continues accepting the old token until it hard-expires.

**Why it happens:** WebSocket connections are long-lived; headers are set at connection time and `graphql_flutter` does not automatically reconnect when the token changes.

**Consequences:** Subscriptions silently fail to deliver updates after a token refresh. The user continues to see stale state with no error shown.

**Prevention:**
- After a successful token refresh, force-reconnect the WebSocket: `graphQLClient.link.dispose()` then reinitialise the `WebSocketLink` with the new token. This is disruptive but correct.
- A cleaner pattern: use the `connectionParams` callback form of `WebSocketLink` (supported in `graphql_flutter`) which is evaluated on each connection — token is read from `SecureStorageManager` at connect time, so a reconnect automatically picks up the refreshed token.
- Implement WebSocket reconnect as part of the token refresh success path.

**Detection signal:** After a forced token rotation, subscription events stop arriving but mutations succeed (mutations go over HTTP with the refreshed token).

**Phase:** Real-time sync phase. Re-tested in hardening phase.

---

### Pitfall 8: Missed Events During Subscription Reconnect Gap

**What goes wrong:** The WebSocket drops (network change, app background, server restart). `graphql_flutter` reconnects after a few seconds. During the gap, the server sent events (e.g., "quest completed", "HP changed"). The client receives no catch-up; it simply resumes from the reconnect point and shows stale state indefinitely.

**Why it happens:** GraphQL subscriptions are push-only with no built-in replay or catchup mechanism.

**Consequences:** Quest completion badge never appears. HP shown as incorrect. Coins display is stale. The user must manually refresh — but there is no "pull to refresh" in this app.

**Prevention:**
- On reconnect, always fire a full refresh query for the character state (a normal GraphQL query, not a subscription). Let the subscription handle deltas; use a query as the source of truth on reconnect.
- Pattern: `CharacterCubit._onSubscriptionReconnect() { await _loadCharacter(); }` — called from the subscription's `onError` or `onDone` handler before re-subscribing.
- Optional: the backend can support a `lastEventId` cursor-based subscription scheme, but that requires backend changes and is overkill for v1.

**Detection signal:** Put the app in airplane mode for 10 seconds during a backend event, then restore network. The event should appear within 2 seconds of reconnect. If it does not, the gap is unhandled.

**Phase:** Real-time sync phase. Tested in hardening phase.

---

### Pitfall 9: Optimistic UI Diverging from Server State

**What goes wrong:** Quest accept gesture triggers an optimistic UI update (quest moves to "active" state immediately). The mutation fails (insufficient coins, quest no longer available, user is mid-travel). The UI shows the quest as active; the server never confirmed it. With no rollback logic, the state is permanently wrong until the next subscription event overwrites it.

**Why it happens:** Optimistic updates are easy to add but rollback paths are typically forgotten.

**Consequences:** Broken game UI, user thinks quest was accepted when it was not.

**Prevention:**
- For this v1 RPG, prefer pessimistic UI for state-changing actions (quest accept, travel confirm, spell equip). Show a loading indicator; update state only on confirmed server response.
- If optimistic updates are used (for UX smoothness on gestures), always define the rollback case: `on mutation error → revert to previous state snapshot → show error toast`.
- Store a pre-mutation snapshot in the Cubit before applying the optimistic update; restore it on error.

**Detection signal:** Accept quest while offline or with 0 coins. The board should revert the swiped quest card to its original position with an error message.

**Phase:** Quest gesture implementation phase.

---

### Pitfall 10: Race — Mutation Response vs Subscription Event for Same Entity

**What goes wrong:** User accepts a quest (mutation). The server processes it and emits a subscription event. The mutation response arrives at ~200ms; the subscription event arrives at ~220ms. Both the mutation handler and the subscription handler in `CharacterCubit` update character state. The subscription event carries the authoritative post-mutation state; the mutation response may carry a partial intermediate state. If applied in the wrong order, the subscription's update overwrites a later local optimistic state, or vice versa.

**Why it happens:** Two asynchronous data streams write to the same Cubit state without coordination.

**Prevention:**
- Designate the subscription as the single source of truth for character state. The mutation handler should only inspect the response for errors; it should not update character state from the mutation result.
- Pattern: `onMutationSuccess(response) { if (response.hasErrors) { showError(); revertOptimistic(); } }` — no state update. Let the subscription event that follows carry the new state.
- This requires server-side guarantee that the subscription event arrives after the mutation completes — standard for NestJS GraphQL with MongoDB because the subscription fires from the database change.

**Phase:** Real-time sync phase. Architecture decision to document in CONVENTIONS.

---

### Pitfall 11: Push Notification Permission at Cold Start (iOS)

**What goes wrong:** Firebase Messaging permission is requested immediately at app start or sign-in. iOS shows the system permission dialog at a moment when the user has no context for why push notifications are needed. iOS tracks the prompt rate; if the user dismisses it, they cannot be re-prompted without manually going to Settings. The dismiss rate is higher when asked without context.

**Why it happens:** `firebase_messaging.requestPermission()` is called in `initState` of the first screen.

**Consequences:** Low notification opt-in rate. Travel end / quest completion / streamer-live notifications miss a large portion of users.

**Prevention:**
- Request permission only after the user has experienced the first event that makes notifications valuable — a natural "Abilita notifiche per sapere quando il tuo viaggio termina?" prompt during the first travel confirmation dialog.
- Use `firebase_messaging.getNotificationSettings()` first. If `authorizationStatus == AuthorizationStatus.notDetermined`, show an in-app explanation, then request.
- Never request on cold start.

**Phase:** Push notification implementation phase.

---

### Pitfall 12: FCM Token Stale After Reinstall or Device Migration

**What goes wrong:** User reinstalls the app or migrates to a new device. Firebase generates a new FCM registration token. The backend still has the old token stored against the user's account. All push notifications are sent to the old (invalid) token, silently dropped by Firebase. User never receives travel-end or quest notifications.

**Why it happens:** Token refresh handling is commonly forgotten in initial implementations.

**Prevention:**
- On every app launch after sign-in, call `FirebaseMessaging.instance.getToken()` and compare with the token stored in `SecureStorageManager`. If different, send an update mutation to the backend: `updateFcmToken(accountId, newToken)`.
- Subscribe to `FirebaseMessaging.instance.onTokenRefresh` stream and send updates reactively.
- Backend must replace the old token atomically — do not accumulate multiple tokens per user unless implementing multi-device support.

**Detection signal:** Reinstall app, sign in, trigger a server event that should produce a push notification. It should arrive within 30 seconds. Failure = stale token not refreshed.

**Phase:** Push notification implementation phase.

---

### Pitfall 13: Three-Way Notification Tap Handling (Killed / Background / Foreground)

**What goes wrong:** FCM delivers notifications differently depending on app state:
- **Killed:** `getInitialMessage()` returns the message when app opens via tap. Handler runs after `main()` completes — requires `WidgetsFlutterBinding.ensureInitialized()` before Firebase init.
- **Background:** `onBackgroundMessage` runs in a separate isolate (no Flutter widget tree, no BLoC access). Deep link navigation must be deferred until app is in foreground.
- **Foreground:** `onMessage` fires; the OS does not show a system notification on iOS — the app must show its own in-app banner via `flutter_local_notifications`.

Missing any one path = notifications that sometimes work, sometimes do nothing.

**Prevention:**
- Implement all three handlers. Centralise navigation logic in a `NotificationRouter` class so each handler calls the same `NotificationRouter.handleTap(payload)`.
- For background isolate: store the payload in `SharedPreferences`, then read and process it in `NotificationRouter` when the app returns to foreground (via `AppLifecycleState.resumed`).
- Test each path explicitly: killed → tap, background → tap, foreground → tap.

**Phase:** Push notification implementation phase.

---

### Pitfall 14: Notification Deep Link Target No Longer Exists

**What goes wrong:** Backend sends a push: "La tua quest Hunt è terminata!" with a payload `{ "questId": "abc123" }`. Between sending the notification and the user tapping it, the admin cancelled or archived the quest. The app tries to navigate to the quest detail screen for `abc123` — it does not exist — crash or empty screen.

**Prevention:**
- Always navigate defensively: check that the deep link target exists (query from backend or check local state) before navigating. If not found, navigate to the parent tab (board) instead and show a toast: "La quest non è più disponibile."
- The `NotificationRouter` should wrap all navigations in a try-catch with fallback.

**Phase:** Push notification implementation phase.

---

### Pitfall 15: Travel Timer Device Clock Manipulation

**What goes wrong:** The travel timer counts down based on a start timestamp and an ETA. If the client calculates arrival by `now >= startTime + duration`, a user who advances their device clock appears to arrive instantly. If there are game rewards tied to completing travel (items, XP from reaching a location), this is exploitable.

**Why it happens:** Client-side time is untrustworthy.

**Consequences:** Instant teleportation to any POI → bypass all travel-based game mechanics.

**Prevention:**
- Travel completion must be validated server-side. The backend records `travelStartedAt` and `estimatedArrivalAt`. Arrival is only confirmed when the server processes a `confirmArrival` mutation — and the server checks `serverTime >= estimatedArrivalAt`.
- The Flutter UI timer is cosmetic only: it counts down from the ETA received from the server. Even if the display shows "arrived", no rewards or state changes occur until the server confirms.
- The server should use its own clock for `estimatedArrivalAt`, not trust any client-provided timestamp.

**Detection signal:** Manually advance device clock by 10 hours. Travel should NOT complete until the real server-side ETA has passed.

**Phase:** Travel timer implementation phase. Must be included in hardening security audit.

---

### Pitfall 16: App Killed Mid-Travel — State Loss on Resume

**What goes wrong:** User starts a journey (POI A → POI B, 45-minute travel). OS kills the app. User reopens it. The `WorldMapCubit` starts in its initial state with no knowledge of the ongoing travel. The travel timer UI shows nothing. The user has no way to know their character is mid-travel unless the CharacterCubit's subscription brings the travel state.

**Prevention:**
- The subscription-based character sync (Pitfall 8 mitigation) naturally solves this: when the app reopens, a full character query fires, and the character model includes `travelState: { destination, startedAt, estimatedArrivalAt }`. `WorldMapCubit` must read this field on init and reconstruct the timer.
- Travel state must be a first-class field in the `Character` model and included in the CharacterCubit's initial load query.

**Phase:** Travel timer implementation phase.

---

### Pitfall 17: Multiple Travels Triggered by Race Condition (UI)

**What goes wrong:** User taps "Conferma viaggio" on the travel confirmation dialog. The mutation is slow (500ms). User taps again. Two `startTravel` mutations are sent. The backend creates two travel records or returns an error for the second — but only if it is protected with an idempotency check. Without it, the character might teleport twice.

**Prevention:**
- Disable the confirm button immediately on first tap (set `isSubmitting = true` in the Cubit, emit loading state, disable button in `BlocBuilder`). Re-enable only on error.
- Backend must enforce: if character already has an active travel, reject new travel requests.
- Use mutation idempotency key (e.g., a UUID generated client-side and passed to the mutation; backend deduplications by key).

**Detection signal:** Double-tap the confirm button as fast as possible. Backend logs should show exactly one `startTravel` call.

**Phase:** Travel timer implementation phase.

---

### Pitfall 18: Swipe Gesture Conflicts with Parent ScrollView / PageView

**What goes wrong:** The quest board tab uses a vertical scroll list. The swipe-left gesture to accept a quest (horizontal swipe) is implemented with a `GestureDetector` or `Dismissible`. On fast diagonal swipes, Flutter's gesture arena gives priority to the `ListView`'s vertical pan, and the horizontal swipe is never recognised.

**Prevention:**
- Use `Dismissible` widget with `direction: DismissDirection.startToEnd` or `endToStart` — Flutter's built-in implementation correctly handles the gesture arena for horizontal vs vertical disambiguation.
- If implementing a custom gesture recogniser, set `HorizontalDragGestureRecognizer` with a minimum horizontal velocity threshold before recognising, and explicitly reject the gesture if vertical velocity exceeds horizontal at gesture start.
- Test on real devices with both fast diagonal swipes and slow deliberate swipes.

**Phase:** Quest gesture implementation phase.

---

### Pitfall 19: No Undo for Swipe-Accept Quest

**What goes wrong:** User accidentally swipes a quest they did not intend to accept. The gesture immediately fires the `acceptQuest` mutation. Channel points are deducted. There is no undo.

**Prevention:**
- Add a 2–3 second window after swipe where an undo snackbar is shown: "Quest accettata — Annulla (3s)". Cancel the mutation if the user taps Undo within the window.
- Alternatively (and more aligned with the "strappa foglio" theme): show a bottom sheet confirmation after the swipe animation completes, before firing the mutation.
- Given channel points have real value (Twitch currency), the second option (confirmation step) is strongly preferred.

**Phase:** Quest gesture implementation phase.

---

### Pitfall 20: Swipe Inaccessible to Screen Readers

**What goes wrong:** VoiceOver (iOS) and TalkBack (Android) users cannot perform swipe gestures in the standard RPG sense. If swipe is the only way to accept a quest, the feature is completely inaccessible.

**Prevention:**
- `Dismissible` exposes a long-press action in accessibility mode by default. Verify it is enabled and labelled: `semanticsLabel: 'Accetta quest'`.
- Provide a visible tap target (an "Accetta" button within the quest card) that is shown on focus for screen readers.

**Phase:** Quest gesture implementation phase. Accessibility review in hardening phase.

---

### Pitfall 21: Admin Role Check Only Client-Side

**What goes wrong:** The admin panel is shown only to users whose character has an `isAdmin` flag set in their local state. There is no server-side authorisation check on admin mutations. An attacker who intercepts traffic and replays a `teleportCharacter` or `applyWounds` mutation with any `accountId` can execute admin actions.

**Why it happens:** "Only the admin knows about the admin panel" is not security.

**Consequences:** Any user can teleport characters, assign injuries, manipulate quest outcomes — game-breaking.

**Prevention:**
- Every NestJS resolver that serves admin functionality must be guarded by an `@Roles('admin')` decorator that verifies the JWT's role claim server-side.
- The Flutter app should use the `isAdmin` flag only to show/hide UI. The server must enforce.
- Confirm during hardening phase by calling an admin mutation from a non-admin account (via curl or Postman) and verifying it returns a 403.

**Detection signal:** Non-admin `accountId` successfully executes `teleportCharacter` mutation.

**Phase:** Admin panel implementation phase. Server enforcement is not optional — do it in the same phase, not deferred.

---

### Pitfall 22: No Admin Action Audit Log

**What goes wrong:** Admin teleports a character to the wrong location or applies wounds incorrectly. There is no record of who did what and when. Debugging requires asking the streamer to recall.

**Prevention:**
- Backend: every admin mutation writes to an `adminAuditLog` collection: `{ adminId, action, targetAccountId, payload, timestamp }`.
- Flutter admin panel: display recent audit entries per character (last 10 actions).
- This is low-effort server-side and prevents a lot of "what happened to my character?" support issues.

**Phase:** Admin panel implementation phase.

---

### Pitfall 23: Admin Action on Mid-Travel Character (Concurrent State Change)

**What goes wrong:** Admin executes "teleport to POI X" on a character who is currently in the middle of a 1-hour travel to POI Y. The teleport writes the character's location immediately. The travel timer on the user's device continues counting down to POI Y, and when it fires the `confirmArrival` mutation, the server places the character at POI Y even though admin just teleported them to X.

**Why it happens:** Two concurrent writes to the same character location field without conflict resolution.

**Consequences:** Admin's action is silently overwritten. Character ends up at a location neither the admin nor the user intended.

**Prevention:**
- Server must enforce: if a character has an `activeTravel` record, a teleport mutation must (1) cancel the active travel, (2) clear the `travelState` field, (3) set the new location atomically in a MongoDB transaction.
- Server rejects any `confirmArrival` mutation if the character's `activeTravel.id` does not match the one the client sent (the client captures `travelId` at travel-start and includes it in `confirmArrival`).
- Flutter: when the subscription delivers a state where `travelState` changed to null (admin cancelled), the travel timer Cubit detects this and stops the timer, showing: "Viaggio annullato dall'admin."

**Detection signal:** Start travel, admin teleports character while travel is active, wait for original ETA — character should be at admin's destination, not travel destination.

**Phase:** Travel timer + admin panel phases. Hardening phase concurrency audit must verify the MongoDB transaction boundary.

---

### Pitfall 24: Two Devices Same Twitch Account — Authoritative State

**What goes wrong:** A user logs into Klimmeck Guide on both their phone and a tablet (or a friend's phone at a LAN party). Both receive subscription events. Both can submit mutations (accept quest, equip spell, buy item). Which one wins when they conflict?

**Prevention:**
- Backend must be the authority. All mutations go through NestJS, which processes them serially (MongoDB single-document atomicity). If two `acceptQuest` mutations for the same quest arrive simultaneously, the first one succeeds, the second fails with "quest already accepted or insufficient funds."
- Flutter: handle mutation errors gracefully — they are expected in multi-device scenarios, not exceptional.
- Optionally: show a warning if the same `accountId` is already connected via WebSocket (detectable server-side) — "Connessione attiva su un altro dispositivo."
- Do not implement client-side "last write wins" logic. Server always decides.

**Phase:** Hardening phase concurrency audit.

---

### Pitfall 25: Spend Channel Points Race — Same Points Two Actions

**What goes wrong:** User has 500 coins. Buys an item for 500 (shop mutation) while simultaneously accepting a quest for 500 (quest accept mutation). Both arrive at the server within milliseconds. Without a transaction, both read the current balance (500), both check sufficiency (both pass), both deduct 500. Final balance: -500.

**Why it happens:** MongoDB does not have row-level pessimistic locking by default. Two reads before either write = both pass the balance check.

**Consequences:** Negative coin balance — game economy broken.

**Prevention:**
- NestJS must use MongoDB's `findOneAndUpdate` with an atomic conditional update for all coin deductions:
  ```
  db.characters.findOneAndUpdate(
    { _id: characterId, 'status.coins': { $gte: cost } },
    { $inc: { 'status.coins': -cost } },
    { returnDocument: 'after' }
  )
  ```
  If the document is not found (balance insufficient after another concurrent deduction), return an error.
- This is a single atomic operation; MongoDB guarantees it for single-document writes.
- Never implement a "read balance, check, then write" pattern in two separate operations.

**Detection signal:** Use two network clients simultaneously to fire two deductions that together exceed the balance. Only one should succeed.

**Phase:** Backend architecture decision (must be enforced from day one). Flutter hardening phase verifies by testing concurrent actions.

---

### Pitfall 26: Subscription Event Arriving Mid-Mutation (Stale Write)

**What goes wrong:** Flutter `CharacterCubit` fires a mutation (e.g., `equipSpell`). While awaiting the response, a subscription event arrives with character state that does NOT include the spell being equipped (e.g., it is a coin update from the Twitch API). The subscription handler calls `emit(CharacterUpdated(newCharacter))` where `newCharacter` has the old spell loadout. The mutation response then arrives confirming the equip — but `CharacterCubit` now holds the subscription's intermediate state and applies the mutation response on top of it. Result: inconsistent state depending on timing.

**Prevention:**
- Apply the "subscription is source of truth" principle (established in Pitfall 10): the mutation handler emits no state. It only reports errors.
- Ensure the server's subscription event for `equipSpell` is fired AFTER the MongoDB write for the equip operation. Then the subscription event that follows the mutation will already contain the equipped spell.
- If the subscription event arrives before the mutation write propagates (extremely unlikely but possible with eventual consistency), the next subscription event will self-correct.
- Do not merge partial states client-side. Always replace the full character model from the subscription event.

**Phase:** Real-time sync phase.

---

### Pitfall 27: BLoC Widget Rebuild Loops

**What goes wrong:** A `BlocBuilder<CharacterCubit, CharacterState>` is placed high in the widget tree (e.g., in the main screen scaffold). `CharacterCubit` emits a new state every time a subscription event arrives (potentially every few seconds during live stream with channel points changing). Every emission rebuilds the entire tab scaffold, including all six tab contents, even when only the coins display changed.

**Why it happens:** The existing architecture uses a `CharacterCubit` at root provided via `MultiBlocProvider` in `main.dart`. This is the right place for cross-cutting state but requires careful build scope.

**Consequences:** 60fps animations stutter, scroll positions reset, unnecessary widget rebuilds.

**Prevention:**
- Wrap only the widgets that actually display character state in `BlocBuilder`, not the root scaffold.
- Use `buildWhen: (prev, next) => prev.character?.coins != next.character?.coins` to restrict rebuilds.
- For the coins display widget, use a narrow `BlocSelector<CharacterCubit, CharacterState, int?>` that extracts only the coins value — this widget only rebuilds when coins change.
- Use Flutter DevTools' Widget Rebuild Tracker during development to verify only expected widgets rebuild on each subscription event.

**Detection signal:** Enable Flutter's "debugProfileBuildsEnabled = true". A subscription event should rebuild at most 2–3 widgets, not the entire screen.

**Phase:** Real-time sync phase. Can also be audited in hardening phase.

---

### Pitfall 28: App Backgrounding Kills Subscriptions Without UI Knowing

**What goes wrong:** User backgrounds the app (switches to another app, locks screen). On iOS, after ~30 seconds, the OS suspends the Dart isolate. The WebSocket TCP connection drops. When the user returns, the subscription stream's `onError` or `onDone` fires — but if the widget tree was not listening for this signal, the UI shows stale data with no reconnect attempt and no error indicator.

**Prevention:**
- Subscribe to `AppLifecycleState` changes in `CharacterCubit` (or a root `AppLifecycleCubit`):
  - `resumed` → fire a full character refresh query + re-establish subscription.
  - `paused` → optionally close the subscription cleanly to avoid orphaned server-side resources.
- The `WS_INACTIVITY_TIMEOUT_SECONDS` config (currently 30s per env_config) should be set to a value shorter than the app's expected background kill time to ensure clean disconnect before the OS drops the connection.
- Test on a physical iOS device (simulator does not apply background kill aggressively).

**Phase:** Real-time sync phase.

---

### Pitfall 29: Memory Leaks in Long-Running Subscriptions and Animations

**What goes wrong:** `WorldMapCubit` already has multiple `AnimationController`s without documented cleanup (flagged in CONCERNS.md). Adding travel timer animations and subscription streams adds more. If `dispose()` is not called on every controller and subscription, memory grows over a long session until the OS kills the app.

**Prevention:**
- Audit every `AnimationController`, `StreamSubscription`, `Timer`, and `ValueNotifier` created in Cubits and StatefulWidgets. Each must be cancelled/disposed in `close()` / `dispose()`.
- Use `flutter_lints` rule `cancel_subscriptions` and `close_sinks` — enable them in `analysis_options.yaml`.
- In the hardening phase, run the app for 30 minutes with Flutter DevTools Memory profiler open. Heap should reach a plateau, not grow continuously.

**Detection signal:** Heap size grows ~5MB per 10 minutes of use without user interaction.

**Phase:** Ongoing from each feature phase. Systematic audit in hardening phase.

---

### Pitfall 30: Dart Define Secrets in Build Logs

**What goes wrong:** Twitch OAuth `client_secret` or Firebase server keys are passed as `--dart-define` flags in CI/CD build commands. These appear in build logs, which are often accessible to all team members and potentially public in open-source CI configurations.

**Why it happens:** The existing `env_config.dart` pattern uses `dart-define` for all configuration. It is fine for non-sensitive values (API URLs, timeouts) but dangerous for secrets.

**Prevention:**
- `client_secret` must NEVER be embedded in the Flutter app (mobile OAuth flows use the public `client_id` only; PKCE replaces the client secret).
- Firebase server keys (for sending push notifications) belong on the NestJS backend, never in the Flutter app.
- The Flutter app only needs `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) — these contain app registration data, not server secrets. They should be provided via CI secrets as files, not `dart-define`.

**Phase:** Auth and push notification phases. Security audit in hardening phase.

---

## Moderate Pitfalls

---

### Pitfall 31: Combat Result Arriving While User Navigates Away

**What goes wrong:** A subscription event for `combatResult` arrives while the user is mid-navigation (e.g., leaving the board tab). The `BlocListener` for combat results tries to show a bottom sheet or navigate to the combat outcome screen, but the widget tree is in a transitional state. `Navigator.of(context).push(...)` fails or double-navigates.

**Prevention:**
- Use `BlocListener` at a stable point in the widget tree (main screen scaffold, not within a tab that can be unmounted).
- Guard navigation calls with `WidgetsBinding.instance.addPostFrameCallback` to ensure the frame is settled before navigating.
- Or: store the pending combat result in the Cubit state and show it via an overlay on next stable frame.

**Phase:** Combat UI implementation phase.

---

### Pitfall 32: Haptic Feedback Absent on Some Devices

**What goes wrong:** `HapticFeedback.mediumImpact()` is called on swipe confirmation. On older Android devices without a precision haptic motor (most budget devices use a simple vibration motor), the feedback feels wrong or absent.

**Prevention:**
- Wrap haptic calls in a try-catch.
- On Android, fall back to `HapticFeedback.vibrate()` if `mediumImpact` is unsupported.
- The gesture should work correctly without haptic — it is enhancement, not feedback.

**Phase:** Quest gesture implementation phase.

---

### Pitfall 33: Duplicate Notifications — FCM and In-App Banner

**What goes wrong:** When app is in foreground, FCM `onMessage` fires. The app shows an in-app banner via `flutter_local_notifications`. Simultaneously, if `FirebaseMessaging.setForegroundNotificationPresentationOptions` is set to show system notifications, the OS also shows a system banner. User sees two notifications for the same event.

**Prevention:**
- In foreground: set `FirebaseMessaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false)` to suppress OS-level notifications.
- Use only the in-app banner (via `flutter_local_notifications`) while the app is in foreground.
- In background/killed: rely on OS-level notification only; in-app banner is irrelevant as the app is not visible.

**Phase:** Push notification implementation phase.

---

### Pitfall 34: Admin Bulk Operations Without Confirmation

**What goes wrong:** Admin panel provides bulk actions (e.g., apply wounds to multiple characters from a dungeon result). One accidental tap applies them all. No undo.

**Prevention:**
- Always show a confirmation dialog for destructive or irreversible admin actions.
- For bulk actions, show a preview list: "Stai per applicare 3 ferite a: Luca, Marco, Sara — Conferma?"
- Consider a 5-second undo window for wound application.

**Phase:** Admin panel implementation phase.

---

### Pitfall 35: Notification Payload Exceeding iOS 4KB Limit

**What goes wrong:** A quest completion notification includes a full serialized quest object in the payload (items, rewards, description). The FCM/APNs payload exceeds 4KB on iOS. The notification is silently dropped by APNs.

**Prevention:**
- Keep notification payloads minimal: `{ type: 'questComplete', questId: 'abc123' }`. Fetch full data from the backend when the user taps the notification.
- Never embed full model objects in notification payloads.

**Phase:** Push notification implementation phase.

---

## Minor Pitfalls

---

### Pitfall 36: GlobalKey Navigator Force Unwrap (Existing Concern)

**What goes wrong:** `navigatorKey.currentContext!` in `graphql.dart` (lines 53, 67, 81 per CONCERNS.md) crashes if called before the widget tree is built. This already exists; adding auth and subscriptions increases the risk surface.

**Prevention:** Already documented in CONCERNS.md. Must be fixed before auth work begins — auth flows run on cold start where context may be null.

**Phase:** Prerequisite fix before auth phase.

---

### Pitfall 37: Hardcoded Dev URL in Production Builds (Existing Concern)

**What goes wrong:** Production build accidentally ships with `192.168.0.20:3000`. All API calls fail silently.

**Prevention:** Already documented in CONCERNS.md. Add a build-time assertion: `assert(EnvConfig.graphqlHttpUrl != 'http://192.168.0.20:3000/api/graphql', 'Production build must set GRAPHQL_HTTP_URL')`.

**Phase:** Hardening phase — CI/CD configuration.

---

### Pitfall 38: Timer Drift Over Long Travels

**What goes wrong:** A 3-hour travel timer (`DateTime.now()` polled every second) accumulates drift of several seconds due to device sleep, CPU throttling, and Flutter frame skips. Display shows incorrect remaining time.

**Prevention:**
- Always compute remaining time as `estimatedArrivalAt - DateTime.now()` on each tick, not by decrementing a counter. This is always accurate regardless of drift.
- The `estimatedArrivalAt` is provided by the server and stored in the Cubit on travel start.

**Phase:** Travel timer implementation phase.

---

## Phase-Specific Warnings

| Phase Topic | Likely Pitfall | Mitigation |
|---|---|---|
| Auth — OAuth flow | Deep link hijacking (P4), token storage (P1), refresh race (P2) | PKCE S256, flutter_secure_storage, Mutex |
| Auth — logout | Stale data leak (P3), open subscriptions (P5) | LogoutUseCase with full cleanup sequence |
| Auth — cold start | GlobalKey null crash (P36), Firebase not initialised | Fix GlobalKey pattern before auth phase |
| Real-time sync — subscription setup | Duplicate subscriptions (P6), WebSocket stale token (P7) | Guard-gated init, connectionParams callback |
| Real-time sync — reconnect | Missed events (P8), mutation/subscription race (P10) | Full refresh query on reconnect, server-as-authority |
| Real-time sync — BLoC integration | Widget rebuild loops (P27), app backgrounding (P28) | BlocSelector, AppLifecycle listener |
| Quest gesture | Gesture conflict (P18), accidental accept (P19), optimistic UI (P9) | Dismissible, confirmation step, pessimistic UI |
| Quest gesture | Accessibility (P20) | Semantics label + tap fallback |
| Travel timer | Clock manipulation (P15), state loss on resume (P16), race condition (P17) | Server-side validation, character model travel state, button disable |
| Travel timer — long travels | Timer drift (P38), admin concurrent teleport (P23) | `estimatedArrivalAt - now()` pattern, server atomic transaction |
| Push notifications — permission | iOS cold start penalty (P11) | Context-aware permission request during first travel |
| Push notifications — delivery | Stale FCM token (P12), three handler paths (P13), missing deep link target (P14) | Token refresh on login, all three handlers, defensive navigation |
| Push notifications — display | Duplicate system + in-app banner (P33), payload size (P35) | Suppress foreground OS notifications, minimal payload |
| Admin panel | Client-side role check only (P21), no audit log (P22), bulk action without confirm (P34) | Server-side @Roles guard, audit collection, confirmation dialogs |
| Admin panel — concurrency | Admin teleport mid-travel (P23) | MongoDB atomic transaction cancels travel |
| Hardening — concurrency | Two devices same account (P24), coin spend race (P25), stale write (P26) | Server authority, atomic `findOneAndUpdate`, server-as-subscription-truth |
| Hardening — memory | Long-running leaks (P29), SVG cache (existing CONCERNS.md) | Dispose audit, DevTools memory profiler |
| Hardening — security | Dart define secrets (P30), admin server enforcement (P21), clock manipulation (P15) | No client_secret in app, @Roles on every admin resolver, server-side ETA |
| Hardening — production | Hardcoded dev URL (P37), no crash reporting | Build-time assertion, integrate Firebase Crashlytics |

---

## Sources

- graphql_flutter WebSocketLink documentation and connectionParams callback: [pub.dev/packages/graphql](https://pub.dev/packages/graphql)
- flutter_secure_storage vs SharedPreferences security comparison: [pub.dev/packages/flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)
- PKCE RFC 7636: [tools.ietf.org/html/rfc7636](https://tools.ietf.org/html/rfc7636)
- Firebase Messaging three-state handling (Flutter): [firebase.flutter.dev/docs/messaging/notifications](https://firebase.flutter.dev/docs/messaging/notifications)
- MongoDB atomic single-document operations: [mongodb.com/docs/manual/core/write-operations-atomicity](https://www.mongodb.com/docs/manual/core/write-operations-atomicity/)
- Flutter BLoC pattern `buildWhen` / `BlocSelector` documentation: [bloclibrary.dev](https://bloclibrary.dev)
- iOS APNs payload size limits: [developer.apple.com/documentation/usernotifications](https://developer.apple.com/documentation/usernotifications)
- Existing codebase concerns: `.planning/codebase/CONCERNS.md` (2026-04-09)
- Project context: `.planning/PROJECT.md` (2026-04-10)
