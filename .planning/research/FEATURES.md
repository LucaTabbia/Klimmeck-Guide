# Feature Landscape

**Domain:** Flutter mobile RPG + Twitch-integrated live app (Klimmeck Guide v1.0 Core Loop)
**Researched:** 2026-04-10
**Confidence note:** Web access unavailable this session. All findings from training data (cutoff Aug 2025). Twitch API specifics labeled MEDIUM confidence; Flutter/mobile UX patterns labeled HIGH confidence from well-established community practice.

---

## 1. Twitch OAuth Login + Settings Screen

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| PKCE flow via system browser | OAuth on mobile must use external browser (not in-app WebView — Twitch and Google explicitly disallow WebView auth for security) | Medium | Use `url_launcher` to open Twitch authorization URL; handle redirect via deep link / custom scheme |
| Deep link redirect back to app | User expects to return to app seamlessly after browser auth | Medium | Register custom URI scheme (e.g. `klimmeck://auth/callback`) in Android `AndroidManifest.xml` and iOS `Info.plist` |
| Refresh token persistence | User expects to stay logged in across sessions; re-login every launch is unacceptable | Medium | Store access token + refresh token in `flutter_secure_storage` (not `shared_preferences` — unencrypted) |
| Logout action | User must be able to log out; required for account switching | Low | Revoke token at Twitch endpoint, clear local storage, route to sign-in screen |
| Account switch | Expected in Twitch-ecosystem apps — streamers often manage multiple accounts | Medium | Logout + re-trigger OAuth; no need for multi-account simultaneous storage in v1 |
| Token revocation handling | If user revokes app in Twitch settings, the app must recover gracefully | Medium | Validate token on app resume; catch 401 from backend, redirect to sign-in |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| "Welcome back, [username]" splash state | Personal touch; shows Twitch avatar if cached | Low | Cache display_name and profile_image_url locally |
| Settings screen: per-type notification toggle | Viewers may not want all notification types; granularity increases retention | Low | Store bitmask or individual bools in shared_preferences |
| Sign-in screen with Twitch branding | Trust signal for OAuth; users recognize Twitch purple CTA | Low | Use Twitch brand color #9146FF for CTA button |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| In-app WebView for OAuth | Twitch TOS prohibits it; phishing risk; also broken on some devices because WebView lacks saved Twitch session | Open system browser via `url_launcher` |
| Storing tokens in shared_preferences | Unencrypted; extractable on rooted devices | Use `flutter_secure_storage` (Keychain on iOS, EncryptedSharedPreferences on Android) |
| Silently refreshing expired token without surfacing auth error to user | Can create "ghost sessions" where user thinks they're logged in but RPG state is stale | Show a non-blocking banner "Session refreshed" or force re-login on unrecoverable 401 |
| Exposing access token in logs | Debug logs containing tokens leak credentials | Never log raw tokens; log token prefix at most |

### Edge Cases

- **Token revocation mid-session:** User revokes in Twitch settings → next API call returns 401. Backend should propagate this; app must catch it and redirect to sign-in with a message explaining what happened.
- **Refresh token expiry:** Twitch refresh tokens do NOT expire on a fixed schedule by themselves, but they do expire if unused for 30+ days (MEDIUM confidence — Twitch docs state tokens expire after a period of inactivity). App must handle `invalid_grant` response from token refresh endpoint.
- **Twitch refresh token rotation:** As of Twitch's 2022+ auth changes, each use of a refresh token issues a new refresh token. App must replace stored refresh token on every refresh, not just the access token.
- **First install, no account:** Deep link scheme must be registered before auth; test that returning from browser works on both fresh install and cold start.
- **Multiple tabs returning from browser:** On Android, the browser may create a new task. Ensure `launchMode="singleTop"` or `singleTask` on the MainActivity to prevent duplicate navigation.

### Accessibility

- OAuth uses system browser — accessibility is handled by the OS browser; no special treatment needed.
- Settings screen toggles must have semantic labels for screen readers.

---

## 2. Real-Time User Sync via GraphQL Subscription

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Subscription auto-starts after login | User expects character data (currency, HP, status) to reflect live state | Medium | Subscribe in CharacterCubit after auth; use `graphql_flutter` subscription stream |
| Loading state while connecting | Without initial data, show skeleton or loader — blank screen is jarring | Low | Emit a loading state before first subscription event arrives |
| Reconnect on WebSocket drop | Network hiccups are common on mobile; silently reconnecting is expected behavior | High | graphql_flutter's WebSocket link has reconnect options; supplement with app lifecycle listener |
| Data refresh on foreground resume | App backgrounded → WebSocket may be killed by OS; on resume, data must not be stale | Medium | In `AppLifecycleState.resumed`, if subscription is dead, re-subscribe and optionally fire a one-shot query to get current state |
| Character state correctness | Currency balance, HP, quest status shown must match server truth | High | Subscription is the live channel; backend is source of truth; never calculate client-side |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Animated currency counter on update | "Points ticking up" is viscerally satisfying for viewer engagement | Medium | Tween animation on currency value change |
| Stale indicator when subscription is disconnected | Shows users connection quality; honest about data freshness | Low | Show a subtle "Reconnecting…" chip; clear it when subscription resumes |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Polling as primary sync mechanism | Polling at sub-5s interval hammers backend and drains battery | Use subscription; fall back to a single query on reconnect |
| Applying subscription deltas client-side | Risk of desync if an event is missed during reconnect gap | Apply full state snapshots from server, not incremental diffs |
| Never re-querying after reconnect | Subscription gap during reconnect means events are missed | After reconnect, always fire one query to get current state, then resume subscription |

### Edge Cases

- **App backgrounded on iOS:** iOS aggressively kills WebSocket connections after ~30 seconds in background. On `AppLifecycleState.resumed`, treat subscription as potentially dead regardless of stream status.
- **Android Doze mode:** Doze can suspend network after extended backgrounding. Same pattern as iOS.
- **Subscription initial data vs live events:** The first event from subscription may be an initial snapshot or the next delta — this depends on backend implementation. Document expected contract clearly.
- **WebSocket and JWT expiry:** If the WebSocket connection is alive when the access token expires, the server may close the connection with a 4401 close code. App must handle WebSocket close codes and trigger token refresh + reconnect.
- **Multiple subscription instances:** If the user navigates quickly and triggers re-subscribe without properly closing the old one, duplicate events can arrive. Cubit must cancel the previous stream subscription before creating a new one.

### Accessibility

No specific accessibility concerns beyond general loading state labeling.

---

## 3. Swipe-Left "Tear a Paper" Gesture to Accept Quests

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Swipe gesture triggers quest acceptance | Core mechanic; must work reliably | High | Custom GestureDetector or Dismissible; see below |
| Visual affordance that swipe is available | Users unfamiliar with the gesture need a hint (e.g. a peek animation on load) | Low | Brief slide-in animation on card entrance to show left edge |
| Haptic feedback on acceptance | "Paper tear" feel requires tactile feedback | Low | `HapticFeedback.mediumImpact()` on gesture completion |
| Confirmation after swipe | User must know their currency was spent; show brief outcome toast | Low | Show currency deducted; success/failure state |
| Disabled swipe when insufficient currency | Prevent gesture if user cannot afford the quest | Medium | Show "can't afford" shake animation instead of accept |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Paper tear sound effect | Completes the tactile metaphor | Low | Short audio clip via `audioplayers` or `just_audio` |
| Tear animation on swipe (ripped edge transition) | Distinctive animation that becomes a signature interaction | High | Custom RenderObject or shader; significant complexity for a differentiator |
| Swipe velocity sensitivity | Slow deliberate swipe = "careful reading"; fast flick = "confident accept" | Medium | Can tweak velocity threshold |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Flutter's `Dismissible` widget as-is | Dismissible dismisses from the list (removes the item); the quest card should remain until explicitly closed; also Dismissible swipe direction semantics conflict with the "accept" concept | Custom GestureDetector with drag extent threshold; keep card in place, trigger mutation on threshold |
| Irreversible swipe with no undo | Accidental swipes are common, especially for users with motor difficulties | Either require a velocity threshold OR provide a brief "undo" window (3 seconds) before sending mutation |
| Requiring swipe for quest acceptance only | Excludes users who cannot perform swipe gestures | Provide a tap-based fallback: long-press opens action sheet with "Accept" option |

### Edge Cases

- **Swipe during mutation in-flight:** If the user swipes and the backend is slow, a second swipe could trigger a duplicate mutation. Debounce/disable the gesture until the mutation resolves.
- **Swipe during subscription event:** Currency update arrives mid-swipe. If new balance makes quest unaffordable mid-gesture, cancel gesture and show insufficient funds.
- **Multi-finger gesture conflicts:** flutter_map may intercept horizontal gestures on the map tab; in the board tab (quest list), ensure GestureDetector has proper hit-testing priority.
- **Landscape mode:** Swipe target area should scale with screen width; test on tablets.

### Accessibility

- **Screen reader users:** VoiceOver and TalkBack users cannot perform swipe gestures within the app (system gestures conflict). Implement long-press → action sheet pattern with "Accept Quest" action. Semantics label on each quest card must indicate availability and cost.
- **Motor accessibility:** Consider a configurable "tap-to-accept" mode in Settings for users who cannot perform gestures reliably.

---

## 4. Quest Info Sheets with Layout Variations per Type

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Modal bottom sheet presentation | Standard mobile pattern for contextual detail overlays | Low | DraggableScrollableSheet for tall content |
| Type-specific layout sections | Hunt vs Dungeon vs Story all have different relevant fields (enemy, reward, narrative) | Medium | Separate widget per quest type or a slot-based layout system |
| Cost display before accepting | Users will not accept without knowing the currency cost | Low | Prominent display near CTA |
| Quest unavailability indicator | Quests that cannot currently be accepted (wrong class, traveling, insufficient currency) need clear disabled state | Low | Grey out CTA + explanatory text |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Themed visuals per quest type | Hunt sheets look dangerous; Aid sheets look supportive | Medium | Custom header colors/icons from existing design tokens |
| Expandable lore section on story/worldMission | Story quests have narrative; players want to read it | Low | Expandable tile |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Full-screen nav push for quest info | Breaks the browsing flow; user loses list context | Bottom sheet or page overlay preserving list behind |
| Using a single generic layout for all types | Hunt quest showing "Aid target" label looks broken; type-specific layouts signal intent | Use type enum to select layout variant |

### Edge Cases

- **Very long quest names or descriptions:** Auto-scrollable sheet; never truncate lore text.
- **Story/worldMission pending approval:** Sheet must clearly communicate "awaiting GM approval" state after accept.

---

## 5. Travel Confirmation UI + Live Countdown Timer

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| ETA and currency cost confirmation dialog | User expects a "are you sure?" before committing travel | Low | Bottom sheet or dialog with ETA + cost |
| Countdown timer on map during travel | Core gameplay: watching remaining travel time | Medium | Timer widget; see clock strategy below |
| Cancel travel CTA (with penalty if applicable) | Users may want to abort; cancel mechanic is table stakes | Low | Depends on game rules; if no penalty, simple cancel mutation |
| Travel completion event | App must notify user when travel ends (even if app is closed) | Medium | Push notification (FCM/APNs) handles background case |

### Timer Strategy

**Server-authoritative approach (STRONGLY RECOMMENDED):**

Never run the countdown purely on device clock. Instead:

1. Backend stores `travelStartTime` (UTC) and `travelDurationSeconds` in travel record.
2. App computes `remaining = (travelStartTime + duration) - now()` using device clock only for display.
3. On app resume, re-fetch travel state to recalculate remaining time against server timestamps.
4. Server fires the "travel complete" event via subscription; client treats this as authoritative — never auto-complete travel based on client timer alone.

This handles:
- **Device clock skew:** Remaining time is always computed from server timestamps, not from "start timer when user tapped" which would be wrong if clocks differ.
- **App killed during travel:** On cold start, app fetches character state, sees `traveling: true` with server timestamps, reconstitutes the timer correctly.
- **Timer drift:** Device timer may drift over long travels (>30 min). Re-anchoring to server timestamps on resume fixes accumulated drift.

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Animated character marker moving on map during travel | Visual progress on map = engagement | High | Interpolate position on flutter_map between origin and destination |
| ETA in human-readable form | "~12 minutes" is more readable than a raw countdown at long durations | Low | Format: "X min Y sec" when < 1h; "Xh Ym" when longer |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Persisting timer start on client only (Timer.periodic) | Killed app, clock change, or restart breaks timer | Use server timestamps for all time calculations |
| Auto-completing travel on client timer expiry | Race condition with server; can create ghost state | Only mark travel complete when server subscription event arrives or query confirms it |

### Edge Cases

- **App backgrounded for entire travel duration:** On resume, subscription may deliver "travel complete" immediately or state already shows completed. Handle both sequences.
- **No network on resume:** Show last known state with "offline" indicator; do not show a stale timer as if it's live.
- **Multiple travels queued (future feature):** Architecture should store travel state as queue-aware even if v1 only allows single travel.

---

## 6. Push + In-App Notifications

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| FCM token registration on login | Required for push delivery | Low | Call `FirebaseMessaging.instance.getToken()` after auth; send token to backend |
| iOS notification permission prompt | iOS requires explicit user permission; no prompt = no notifications | Low | Best practice: ask in-context (e.g. "Get notified when your travel ends?") not at cold launch |
| Android notification channel setup | Android 8+ requires notification channels | Low | Create channels for: travel, quest, streamer-live |
| Background message handler | App may be killed when push arrives; must handle it | Medium | `FirebaseMessaging.onBackgroundMessage` top-level function (Dart isolate constraint) |
| Deep link from notification to relevant screen | Tapping a "travel ended" push should open map; "quest ended" should open result sheet | Medium | Parse notification payload `data` map; use Router/Navigator to push correct screen |
| Token refresh handling | FCM tokens rotate; stale tokens mean missed pushes | Low | Listen to `FirebaseMessaging.instance.onTokenRefresh`, update backend |

### In-App Notification Banners

**Pattern decision:**

| Option | When to Use | Notes |
|--------|------------|-------|
| `ScaffoldMessenger.showSnackBar` | Transient confirmations (mutation success) | Low; auto-dismiss; does not stack well |
| `ScaffoldMessenger.showMaterialBanner` | Important persistent states (subscription disconnected) | Persists until dismissed; only one at a time |
| Custom overlay widget | Multiple simultaneous banners, rich layouts, RPG-themed styling | High; but required for the Klimmeck visual theme |

**Recommendation:** Custom overlay widget using `OverlayEntry` in a dedicated `NotificationOverlayManager` singleton. Stack max 3 banners; auto-dismiss after 4 seconds; swipe-up to dismiss early. This pattern is used in Discord, Twitch mobile app, and most game companion apps.

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Per-notification-type toggle in Settings | Viewers who watch casually may not want streamer-live pings | Low | Map to per-channel FCM topic subscriptions or backend push filter |
| RPG-themed push notification icon | Recognizable icon in notification tray | Low | Android: set small icon to game icon in FCM payload; iOS: default app icon |
| "Streamer went live" push | Cross-app; drives viewer back to Twitch | Medium | Requires backend polling Twitch Helix EventSub or webhooks to know when streamer goes live |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Requesting notification permission at app cold launch (before any context) | iOS shows system alert before user understands the app's value; 60%+ dismissal rate | Ask permission in the first contextually relevant moment: travel confirmation screen |
| Using `flutter_local_notifications` for remote pushes | FCM handles remote push display natively on both platforms when app is background | Use FCM notification display; use `flutter_local_notifications` only for local (e.g. in-app triggered) banners |
| Showing push notification AND in-app banner simultaneously | Duplicate alerts for the same event are annoying | If app is in foreground when push arrives, suppress the system push and show in-app banner only (use `FirebaseMessaging.setForegroundNotificationPresentationOptions` to disable system alert in foreground) |

### Edge Cases

- **Permission denied (iOS):** Track permission state; if denied, show a Settings-deep-link prompt explaining what the user is missing. Do not repeatedly ask.
- **FCM token unavailable at login:** Retry token fetch silently; do not block login on FCM token acquisition failure.
- **Background handler Dart isolate restrictions:** The `onBackgroundMessage` handler runs in a separate Dart isolate. It cannot access Blocs, Navigator, or Hive instances opened in the main isolate. Handler should only persist minimal data to shared_preferences for main isolate to pick up on resume.
- **APNs sandbox vs production:** iOS TestFlight and production use different APNs environments. Misconfiguring this causes pushes to silently fail. Use Firebase's automatic APNs env detection.

### Accessibility

- Notification banners must not obscure interactive elements permanently; dismissible by tap.
- Semantic label for banner content for screen readers.

---

## 7. Spells Section in Journal Tab

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| List of owned spells | User must be able to see what they have | Low | Simple list; cards with spell name, icon, type |
| Equip/disequip to 3 slots | Core spell management mechanic | Medium | 3 slot indicators at top; tap spell to assign; tap slot to unassign |
| Cooldown display | User must know when a spell can be used again | Low | "Ready" vs "X turns remaining" (cooldown is combat-turn-based, not real-time) |
| Remaining uses display | Finite spells need usage counter | Low | e.g. "3 / 5 uses" |
| Slot occupation indicator | Which slot a spell is already in | Low | Badge or slot highlight on the spell card |

### Equip UX Pattern

**Slot-based tap assignment (RECOMMENDED over drag-and-drop for mobile):**

1. Top of screen: 3 slot placeholders (Slot 1, Slot 2, Slot 3). Each shows equipped spell or empty state.
2. Below: scrollable list of owned spells.
3. Tapping an empty slot → prompts "select a spell" (activates selection mode on list).
4. Tapping a spell when a slot is in selection mode → assigns it.
5. Tapping an equipped spell card → action sheet: "Move to slot X", "Unequip".

**Optimistic UI vs confirmed mutation:**

Use **optimistic UI** with rollback:
- Immediately reflect the equip/disequip in local state.
- Fire mutation in background.
- On mutation error: roll back to previous state, show error banner.

This is the standard approach in games (Destiny companion app, Final Fantasy Record Keeper) because the latency between tap and server confirmation (100-500ms) makes waiting feel broken.

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Spell icon from Cloudinary | Visual richness; consistent with equipment art style | Low | Use CachedSvg pattern already in place |
| Slot animation on equip | Brief "snap into slot" animation | Low | Simple scale + position tween |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Drag-and-drop between list and slots | Difficult to implement correctly on mobile; small slot targets are hard to drop on | Tap-based assignment is faster and more accessible |
| Blocking UI during mutation | Makes the app feel slow | Optimistic UI with rollback |
| Showing spells user doesn't own (greyed out) | Creates "FOMO" and confusion about what requires what | Only show owned spells; backend controls unlock |

### Edge Cases

- **Spell in slot gets depleted (0 uses):** Slot should show depleted state, not hide the spell. User should explicitly disequip.
- **Backend rejects equip (slot count exceeded, spell already equipped):** Rollback optimistic update, show specific error.
- **Same spell in multiple slots:** Should be prevented by validation; if backend disallows it, handle the rejection gracefully with a clear message.

### Accessibility

- Slot and spell cards must have semantic labels.
- Color-coded states (ready/cooldown) must have text labels too (don't rely on color alone).

---

## 8. Combat Result Sheet

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| HP before/after with delta | Core outcome visibility | Low | e.g. "75 HP → 42 HP (-33)" |
| Wounds received list | Critical to know the injury consequences | Low | List with wound name + icon |
| Consumables and spells used | Accountability for resources spent | Low | List with item names |
| Rewards received (items, gold) | Positive feedback for completing quest | Low | List with item icons |
| XP earned + level-up detection | Critical for progression satisfaction | Low | If level-up: animated fanfare; otherwise simple XP display |
| "Tap to continue" / dismiss pattern | User controls when to leave the result screen | Low | Tap anywhere or explicit button |

### Presentation Pattern

**Full-screen takeover (RECOMMENDED) over modal sheet:**

Combat results are a significant moment in an RPG. Presenting them as a bottom sheet (like a receipt) diminishes the weight of the event. Full-screen results with a deliberate "tap to continue" pattern are standard in mobile RPGs (Fire Emblem Heroes, Fate/GO, Final Fantasy Record Keeper).

Use a custom route with a dramatic fade-in or slide-up animation. Keep the background app underneath but dimmed (like a Modal).

**Sequence of revelation (differentiator):** Show sections sequentially with a brief delay between each (wounds → consumables → rewards → XP). This mimics RPG result screen convention and creates anticipation.

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Level-up animation | Dopamine hit for progression milestone | Medium | Full-screen flash / level number reveal |
| HP bar animated from old to new value | Visceral representation of damage taken | Low | Tween animation on HP bar |
| Sound effects for wounds/rewards | Completes the RPG feel | Low | Short audio clips |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Auto-dismissing result screen | Player may not have read all the outcome details | Require explicit tap to continue |
| Bottom sheet for combat results | Too casual for a significant game event | Full-screen overlay |
| Showing round-by-round log in v1 | Adds complexity without closing the loop; v2 feature | Show summary only; detailed log deferred |

### Edge Cases

- **Character death (0 HP after combat):** Special case presentation — distinct visual treatment (red tones, "defeated" state); automatically generate an Aid quest (backend responsibility); result sheet should acknowledge death state explicitly.
- **Result arrives while app backgrounded:** On resume, check pending result; show result sheet if unacknowledged. Backend must persist "unacknowledged result" state.
- **Multiple unacknowledged results (catching up after offline period):** Queue results and present them one at a time.

### Accessibility

- Screen reader must be able to read all result sections without visual animation dependency.
- "Tap to continue" must be an explicit accessible button, not just a GestureDetector on the whole screen.

---

## 9. Admin Panel for Streamer

### Access Control Pattern

**Role-gated section (RECOMMENDED) over separate build or hidden menu:**

Three patterns exist in mobile RPG apps:

| Pattern | Used By | Pros | Cons |
|---------|---------|------|------|
| Separate admin build | Some Tabletop RPG apps | Clean separation | Two codebases to maintain; streamer must install separate app |
| Hidden menu (secret tap sequence) | Many casual games | Single build | Security by obscurity; accidental trigger risk |
| Role-gated UI section | Most game companion apps (e.g. Roll20) | Single build; backend-enforced auth | Slightly increases app size; admin UI loaded for non-admins (unused) |

For this project, role-gated is correct: the app is single-channel, single-GM. The admin panel is a 7th section or a conditional tab that appears only when the logged-in Twitch user matches the streamer's ID (verified server-side, not just client-side).

**Security:** Backend must enforce admin role on all admin mutations. Client-side role check is UX only (hiding the UI), never security. A user who discovers and calls admin GraphQL mutations without the role must get a 403.

### Table Stakes

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Pending story/worldMission requests list | GM needs to review and act on requests | Medium | Subscription or polling for pendingRequest list |
| Approve / reject actions per request | Core GM workflow | Low | Mutation per request; confirmation dialog before reject |
| Instant teleport: pick character → pick POI | Fast GM tool during live session | Medium | Character picker + POI picker (from existing map data) |
| Monster/grade/rewards/wounds assignment per POI | GM customizes encounter difficulty | High | Multi-field form per POI; save to backend |
| Admin actions are reflected live in viewer subscriptions | GM changes must propagate immediately to affected users | Medium | Backend subscription broadcast; frontend receives via existing subscription |

### Differentiators

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Admin panel accessible during stream without alt-tabbing | Streamer can manage on phone while streaming on PC | Low | Core reason this is a mobile app |
| Visual confirmation of pending request count | Badge count on admin tab so streamer notices new requests during stream | Low | Standard mobile notification badge pattern |
| Bulk approve / bulk reject | During active live sessions, many requests may queue up | Low | Multi-select + bulk action |

### Anti-Features

| Anti-Feature | Why Avoid | What to Do Instead |
|--------------|-----------|-------------------|
| Client-side only role enforcement | Security vulnerability; any user who inspects the APK can call admin mutations | Always validate role on backend per mutation |
| Separate admin app build | Doubles maintenance burden for a solo developer | Role-gated tab in main app |
| Complex drag-and-drop POI assignment UI | Over-engineered for GM tools used by one person | Simple dropdowns and pickers |
| Requiring streamer to remember to refresh pending list | Streamer is busy during live; manual refresh leads to missed requests | Auto-refresh via subscription or periodic poll (30s) |

### Edge Cases

- **Streamer approves story request but viewer is already traveling:** Backend must validate state; reject with reason; admin panel should surface the reason back.
- **Two admins acting on same pending request simultaneously (future concern):** Idempotent mutations; last-write-wins with a stale state refresh in the UI.
- **Admin panel available offline:** Admin tools should gracefully degrade when network is unavailable; disable all write actions with "No connection" state; still show cached pending list.

### Accessibility

- Admin UI does not require special treatment beyond standard accessibility; the streamer is a specific known user, not a broad accessibility audience, but good practice still applies.

---

## Feature Dependencies

```
Twitch OAuth login
  → Real-time sync subscription (requires auth token for WebSocket connection)
  → Push notifications (requires user identity for FCM token registration)
  → All other features (all require authenticated session)

Real-time sync subscription
  → Currency display in travel confirmation (live balance required)
  → Spell slot availability (live character state)

Travel confirmation UI
  → Live countdown timer (timer state comes from travel record created by confirmation)

Push notifications (FCM setup)
  → Travel end notification
  → Quest end notification
  → Streamer-live notification

Spells section
  → Combat result sheet (shows spells used; references spell inventory)

Admin panel
  → Pending requests (requires quest accept gesture to create requests)
  → Monster/wound assignment (referenced in combat result sheet outcomes)
```

---

## MVP Recommendation

Prioritize in this order:

1. **Twitch OAuth + token persistence** — Blocks everything; nothing else works without auth.
2. **Real-time user sync subscription** — Blocks quest accept (need live currency balance) and travel timer (need live character state).
3. **Quest info sheets + swipe-to-accept** — Core engagement loop; the reason the app exists.
4. **Travel confirmation + countdown timer** — Closes the quest-initiation loop.
5. **Push notifications** — Without this, travel-end events are invisible when app is closed.
6. **Spells section** — Self-contained; can be built in parallel with travel.
7. **Combat result sheet** — Requires spells section data; builds on subscription.
8. **Admin panel** — Depends on everything else being in place; streamer needs to see real requests.

Defer: Round-by-round combat log (v2), pet/mount speed modifiers (v2).

---

## Sources

- Twitch authentication documentation (training data, MEDIUM confidence): https://dev.twitch.tv/docs/authentication/
- Flutter GraphQL subscription reconnect patterns (training data, HIGH confidence from community practice)
- Firebase Cloud Messaging Flutter setup (training data, HIGH confidence): https://firebase.google.com/docs/cloud-messaging/flutter/client
- Mobile OAuth PKCE best practices: RFC 7636 + OAuth 2.0 for Native Apps (RFC 8252) (HIGH confidence — IETF standard)
- iOS notification permission UX: Apple Human Interface Guidelines (HIGH confidence)
- Mobile RPG UX conventions: Derived from pattern analysis of Fire Emblem Heroes, Fate/GO, Final Fantasy Record Keeper, Roll20 companion app (MEDIUM confidence — training data observation)
- GraphQL WebSocket lifecycle on mobile: graphql_flutter GitHub documentation + community issues (MEDIUM confidence)
