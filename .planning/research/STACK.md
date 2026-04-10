# Technology Stack — v1.0 Core Loop Additions

**Project:** Klimmeck Guide
**Researched:** 2026-04-10
**Scope:** NEW package additions for v1.0 Core Loop only. Existing stack (graphql_flutter, flutter_bloc, flutter_map, dio, etc.) is not re-researched or replaced.

---

## Findings from Codebase Audit

Before recommending additions, facts established from reading pubspec.yaml, pubspec.lock, and graphql_client_provider.dart:

**Already in pubspec — no need to add:**
- `firebase_core ^3.15.1` — present, just needs initialization in main.dart
- `firebase_messaging ^15.2.9` — present, just needs initialization
- `flutter_local_notifications ^19.3.0` — present, just needs wiring
- `url_launcher ^6.1.7` — present, can assist OAuth redirect
- `firebase_auth ^5.6.2` — present but DO NOT USE for Twitch OAuth (see below)

**GraphQL subscriptions — already wired:**
`graphql_client_provider.dart` already configures a `WebSocketLink` with `GraphQLProtocol.graphqlTransportWs` and `Link.split` routing subscriptions to WebSocket. A `character_subscriptions.dart` file already exists. No new package needed.

**Missing and must add:**
- `flutter_secure_storage` — no encrypted storage exists; `shared_preferences` is unencrypted
- `flutter_web_auth_2` — no OAuth package exists at all; `firebase_auth` is wrong approach for Twitch

---

## Package Additions Required

### 1. Twitch OAuth — `flutter_web_auth_2`

**Package:** `flutter_web_auth_2: ^4.0.0`
**Confidence:** MEDIUM (version from training data; verify on pub.dev before adding)

**Why this package, not the alternatives:**

- `flutter_appauth` wraps AppAuth SDK (iOS/Android native). AppAuth requires OAuth server to support PKCE and a `.well-known/openid-configuration` discovery endpoint. Twitch's OAuth 2.0 does support PKCE but the AppAuth iOS/Android native flow requires custom URL scheme registration in advance and brings a heavier native dependency (CocoaPods pod, Android intent filter). For Twitch specifically, the simpler web-auth flow is well-established community practice.
- `oauth2` (Dart package) handles token exchange but does NOT open a browser — it requires manual browser launch + deep link capture. You'd need to combine it with `url_launcher` and `app_links`. That's three packages doing what `flutter_web_auth_2` does in one.
- `url_launcher` alone cannot receive the redirect callback URI — it launches the URL but your app has no way to intercept the `?code=` redirect.
- `flutter_web_auth_2` is the direct successor to `flutter_web_auth` (which is deprecated). It opens an in-app web view (ASWebAuthenticationSession on iOS, Chrome Custom Tab on Android), captures the redirect, returns the authorization code. Exactly the Twitch PKCE flow: launch `https://id.twitch.tv/oauth2/authorize?...&redirect_uri=klimmeck://auth`, capture code, POST to `https://id.twitch.tv/oauth2/token`. No native SDK dependency.

**Why NOT `firebase_auth` for Twitch:**
`firebase_auth` is already in pubspec but it supports Twitch only via custom OAuth provider which requires additional Firebase project config, adds latency, and routes tokens through Firebase — unnecessary indirection when Twitch's API can be called directly. Keep `firebase_auth` disabled or remove it.

**Platform setup required:**

*Android — `android/app/src/main/AndroidManifest.xml`:*
```xml
<activity
  android:name="com.linusu.flutter_web_auth_2.CallbackActivity"
  android:exported="true">
  <intent-filter android:label="flutter_web_auth_2">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="klimmeck" android:host="auth" />
  </intent-filter>
</activity>
```

*iOS — `ios/Runner/Info.plist`:*
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>klimmeck</string>
    </array>
  </dict>
</array>
```
ASWebAuthenticationSession (iOS 12+) is used automatically — no extra configuration needed beyond the URL scheme.

**Integration with BLoC:**
Create `AuthCubit` (or extend `SignInCubit` which is currently a stub). The cubit calls `FlutterWebAuth2.authenticate(url: twitchAuthUrl, callbackUrlScheme: 'klimmeck')`, exchanges the returned code for tokens via `dio` (already present) POST to Twitch token endpoint, then stores tokens via `flutter_secure_storage`.

---

### 2. Secure Token Storage — `flutter_secure_storage`

**Package:** `flutter_secure_storage: ^9.2.2`
**Confidence:** MEDIUM (version from training data; verify on pub.dev)

**Why needed:**
`shared_preferences` uses unencrypted key-value storage (SharedPreferences on Android, NSUserDefaults on iOS). The Twitch refresh token must be stored encrypted: on Android this uses the Android Keystore, on iOS it uses the Keychain. `flutter_secure_storage` wraps both natively.

**Why this over alternatives:**
No viable alternative. The `hive` package with encryption extension is overkill for token storage. There is no other Flutter package that wraps Keystore + Keychain in a single API.

**Platform setup required:**

*Android — `android/app/build.gradle`:*
Minimum SDK 18+ is required (the project already targets 21+, so no change needed).

```groovy
android {
    compileSdkVersion 34
    defaultConfig {
        minSdkVersion 21  // already set, no change
    }
}
```

For Android 6+ (API 23+), the package uses EncryptedSharedPreferences backed by Android Keystore. No manifest changes needed.

*iOS:* Works out of the box with Keychain. No Info.plist changes required. Keychain access is available without entitlements for app-local storage.

**What to store:**
- Twitch `refresh_token` (encrypted)
- Twitch `access_token` (encrypted, short-lived)
- Twitch `user_id` — can stay in `shared_preferences` (not sensitive)

**What NOT to store in secure storage:**
Do not move all app state to secure storage — it is slower than shared_preferences and has a limited write throughput. Only tokens.

---

### 3. Firebase Push Notifications — Already in pubspec, needs initialization

**Packages already present:**
- `firebase_core: ^3.15.1`
- `firebase_messaging: ^15.2.9`
- `flutter_local_notifications: ^19.3.0`

**No new packages to add.** The concern noted in CONCERNS.md ("Firebase Integration Incomplete") is accurate — these are present but commented out in `main.dart`.

**What needs doing is initialization, not new packages:**

*Step 1 — Firebase project setup (one-time, outside Flutter):*
1. Create Firebase project at console.firebase.google.com
2. Add Android app with package name from `android/app/build.gradle` (`applicationId`)
3. Download `google-services.json` → place at `android/app/google-services.json`
4. Add iOS app with bundle ID from `ios/Runner.xcodeproj`
5. Download `GoogleService-Info.plist` → place at `ios/Runner/GoogleService-Info.plist`

*Step 2 — Android Gradle setup:*
`android/build.gradle` (project-level):
```groovy
dependencies {
    classpath 'com.google.gms:google-services:4.4.2'
}
```
`android/app/build.gradle` (app-level):
```groovy
apply plugin: 'com.google.gms.google-services'
```

*Step 3 — iOS APNs setup:*
- In Apple Developer portal: enable Push Notifications capability for your App ID
- Generate APNs Auth Key (`.p8` file) — preferred over APNs certificate (key doesn't expire)
- In Firebase Console → Project Settings → Cloud Messaging → iOS app: upload the `.p8` key with Team ID and Key ID
- In Xcode: add Push Notifications capability to Runner target

*Step 4 — `main.dart` initialization:*
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
FirebaseMessaging messaging = FirebaseMessaging.instance;
await messaging.requestPermission(); // iOS requires explicit permission
```
Run `flutterfire configure` CLI to auto-generate `firebase_options.dart` from the Firebase project.

**FCM in-foreground vs. `flutter_local_notifications`:**

FCM delivers background notifications natively (Android notification drawer, iOS notification center) without `flutter_local_notifications`. However, **in-foreground**, `firebase_messaging` does NOT display a notification banner by default on iOS — it only fires the `onMessage` stream. On Android, foreground notifications also require explicit handling.

`flutter_local_notifications` (already in pubspec) fills this gap: when `firebase_messaging.onMessage` fires while app is in foreground, create a local notification to show the banner. This is standard practice and the recommended FlutterFire pattern.

Concretely:
- Background/killed state notifications: handled by FCM natively — no extra work
- Foreground in-app banners (travel end, streamer live, quest end): wire `FirebaseMessaging.onMessage.listen(...)` → show local notification via `FlutterLocalNotificationsPlugin`
- Notification tap routing: handle via `FirebaseMessaging.onMessageOpenedApp` and `getInitialMessage()`

No additional packages needed beyond what is already in pubspec.

---

### 4. GraphQL Subscriptions — Already fully wired

**No package changes needed.**

Confirmed from `graphql_client_provider.dart`:
- `WebSocketLink` with `subProtocol: GraphQLProtocol.graphqlTransportWs` (matches NestJS backend protocol `graphql-transport-ws`)
- `Link.split((request) => request.isSubscription, wsLink, httpLink)` correctly routes subs to WebSocket
- `character_subscriptions.dart` already exists in `lib/graphql/subscriptions/`
- `autoReconnect: true` is set

The user subscription for real-time sync (channel points, currency, character state) can be implemented directly using the existing `KlimmeckGraphQl` service wrapper — no new packages or configuration required.

**One thing to verify before implementing:**
The current `initialPayload` on `WebSocketLink` is `() => <String, dynamic>{}` — an empty map. When Twitch auth is added, the WebSocket connection-init payload may need to carry an auth token so the NestJS backend can authorize subscription connections. This is a backend protocol concern, not a Flutter package concern. Verify with backend team whether `connection_init` should include `Authorization: Bearer <token>`.

---

### 5. Swipe Gesture for Quest Accept — Use Flutter's `Dismissible`, no new package

**Recommendation: Use Flutter's built-in `Dismissible` widget. No new package needed.**

**Why not a third-party swipe package:**
The ask is a custom "tear a paper" feel swipe-left gesture. Third-party packages like `flutter_slidable` add swipe-to-reveal action buttons (a different UX pattern). `flutter_swipe_action_cell` is similarly action-button oriented.

`Dismissible` gives full control over the swipe threshold, animation, and what happens on confirm/cancel. The "paper tear" aesthetic is achieved through:
1. Custom `background` widget inside `Dismissible` (a stylized card tearing effect)
2. `confirmDismiss` callback to intercept and trigger the quest-accept GraphQL mutation
3. `direction: DismissDirection.startToEnd` (left to right in LTR, which is swipe-right — or `endToStart` for swipe-left)
4. `resizeDuration: null` to disable the resize-on-dismiss animation if a custom animation is preferred

If the "tear" effect requires a custom fragment/particle shader that `Dismissible` cannot accommodate, a `GestureDetector` with manual drag tracking + `AnimationController` is the correct approach — still no new package needed.

**Verdict:** This is a pure Flutter animation/widget task. Add no package.

---

## Summary of pubspec.yaml Changes

```yaml
# ADD these to dependencies:

flutter_web_auth_2: ^4.0.0       # Twitch OAuth — browser-based PKCE flow
flutter_secure_storage: ^9.2.2   # Encrypted token storage (Keystore/Keychain)

# THESE ARE ALREADY PRESENT — only need initialization work, no version bump needed:
# firebase_core: ^3.15.1
# firebase_messaging: ^15.2.9
# flutter_local_notifications: ^19.3.0
```

**Packages explicitly NOT needed (and why):**
| Package | Why Not |
|---------|---------|
| `flutter_appauth` | Heavier AppAuth native SDK; `flutter_web_auth_2` is simpler for Twitch PKCE |
| `oauth2` (Dart) | No browser launch; would need manual redirect capture; more assembly required |
| `app_links` / `uni_links` | `flutter_web_auth_2` handles the callback internally — no separate deep-link listener needed for OAuth |
| `firebase_auth` | Wrong tool for Twitch OAuth; adds Firebase dependency to auth path; keep disabled |
| `flutter_slidable` | Wrong UX pattern; `Dismissible` is sufficient for swipe-to-accept |
| Any new GraphQL package | `graphql_flutter` already has WebSocket + subscriptions fully configured |

---

## Version Confidence Notes

Versions listed (`flutter_web_auth_2: ^4.0.0`, `flutter_secure_storage: ^9.2.2`) are from training data (cutoff August 2025). **Verify on pub.dev before adding to pubspec.yaml** — run `flutter pub add flutter_web_auth_2 flutter_secure_storage` to get the latest stable resolved versions, or check pub.dev directly.

The existing Firebase packages (`firebase_core ^3.15.1`, `firebase_messaging ^15.2.9`) are pinned in pubspec.lock and confirmed resolving correctly — do not bump their versions without running `flutter pub upgrade` and testing.

---

## Platform-Specific Setup Checklist

### Android
- [ ] Add `CallbackActivity` for `flutter_web_auth_2` in AndroidManifest.xml (scheme: `klimmeck`)
- [ ] Add `google-services.json` to `android/app/`
- [ ] Add `google-services` classpath to `android/build.gradle`
- [ ] Apply `com.google.gms.google-services` plugin in `android/app/build.gradle`
- [ ] Verify `minSdkVersion >= 21` (already set — no change)

### iOS
- [ ] Add `CFBundleURLSchemes: [klimmeck]` to `ios/Runner/Info.plist`
- [ ] Add `GoogleService-Info.plist` to `ios/Runner/` (via Xcode, not just file copy)
- [ ] Enable Push Notifications capability in Xcode target settings
- [ ] Upload APNs Auth Key (.p8) to Firebase Console
- [ ] Run `flutterfire configure` to generate `firebase_options.dart`
- [ ] Add `pod 'flutter_web_auth_2'` is handled automatically by CocoaPods via `ios/Podfile`

---

*Stack research: 2026-04-10*
