# Phase 2: Character Creation - Research

**Researched:** 2026-10-09
**Domain:** Flutter form screen (landscape, BLoC/Cubit), device image picking, authenticated multipart upload (dio), GraphQL mutation with stable error codes, auth-state hand-off into the main shell
**Confidence:** HIGH (codebase and package sources verified in this session); MEDIUM for the backend contract (BE 2.1 has a CONTEXT but no code or `schema.gql` yet)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Routing & transition (CHAR-01, CHAR-07)
- **D-01:** The `currentCharacter == null` branch lives where `AuthGate` hands over to the authenticated subtree (`main.dart` `authenticatedBuilder`): `user.currentCharacter == null` → the character creation screen; otherwise → `AuthenticatedShell` as today. No new routing table, no logic inside `AuthGate` itself (ui-ux rule: guards are widgets, not scattered logic).
- **D-02:** After a successful creation the app enters the main shell **directly** — no welcome/intermediate screen. The transition is driven by the same state that routed into the page: `AuthCubit`'s authenticated `User` gains a populated `currentCharacter` and the gate rebuilds into `AuthenticatedShell`. The mutation returns the updated `User` (D-21) so no extra round trip is needed. Exact mechanism (an `AuthCubit` method that replaces the current user vs re-running `me`) is Claude's discretion; constraints: no polling, no re-login, no blocking overlay.
- **D-03:** The dev bypass is unchanged: the backend dev user is born with `currentCharacter: null`, so in dev the creation page shows at cold start until a character exists. This is the intended manual test path (no extra `DEV_AUTH_*` knob).

#### Page structure & style (CHAR-08, utility screen)
- **D-04:** **Single scrollable page**, not a wizard. The app is landscape-only: portrait column on the left, fields on the right. CHAR-08 ("back navigation preserves data") is satisfied trivially: there is one page and entered data is never discarded on validation or submit errors.
- **D-05:** **No confirmation dialog.** A single "Crea" button at the bottom, enabled only when every required field is valid. While submitting, the button shows its own inline progress and the form locks; nothing full-screen.
- **D-06:** Style: **"scheda personaggio" on parchment** — parchment background, Cinzel titles, fields laid out as rows of a game character sheet. All colors/typography/spacing from `lib/theme/kg_theme.dart` (tokens listed in `11-UI-SPEC.md`), never inline. Chrome is allowed (creation is a utility screen) but the sheet look wins over stock Material where they conflict. It is still a *provisional* layout: aim for coherent and clean, not pixel-perfect.
- **D-07:** An **"Esci" action in the top bar** lets the user log out / switch account from this page. It reuses `AuthCubit.logout()` and the existing `LogoutConfirmationDialog` (both tested, today unreachable from the game).

#### Fields & validation (CHAR-02, CHAR-03, CHAR-04)
- **D-08:** Fields, in this order of the user's request: **sex** (`SexType` male/female), **portrait** (optional, D-14), **name**, **pronoun** (`PronounType` he/she/them — independent from sex), **race** (`RaceType`, included per CHAR-03 even though the user's list omitted it — confirmed), **class** (`ClassType`), **age**, **background**. Enum labels: reuse the existing Italian `label` extensions (`RaceType`, `ClassType`, `PronounType`); `SexType` has none yet → add one.
- **D-09:** **Name:** required; 2–20 characters after trim; letters (Unicode letters incl. accented), spaces, apostrophes and hyphens only; **unique server-side** (case-insensitive) with a dedicated error ("Nome già in uso"). Client validates length/charset live; uniqueness is only the backend's verdict.
- **D-10:** **Age:** integer whose allowed range **depends on the chosen race**; the age field is **disabled until a race is selected** and re-validated when the race changes (out-of-range after a race change → show the validation error, never silently clamp). Race table **aligned to the game lore** (amended 2026-10-09 in the BE 2.1 discuss — it supersedes the D&D-inspired table first accepted on 2026-10-08; the backend is the source of truth, see D-11):

  | Race | min | max | lore |
  |---|---|---|---|
  | human (Umano) | 16 | 200 | 60–70 normally, mages beyond 200 |
  | elf (Elfo) | 100 | 9999 | infinite life |
  | halfelf (Mezzelfo) | 16 | 130 | 120–130 |
  | dwarf (Nano) | 40 | 140 | 130–140 |
  | gnome (Gnomo) | 16 | 60 | ~60 |
  | halfling | 16 | 70 | ~70 |
  | dragonborn (Draconide) | 16 | 180 | 150–180 |
  | tiefling | 16 | 120 | 100–120 |
  | aarakocra | 3 | 40 | 30–40 |

- **D-11:** The race/age table **lives in the backend as the single source of truth** and is **exposed to the app via a query** (e.g. `raceTraits { race minAge maxAge }`). The backend validates `createCharacter` against it; the app reads it to enable and bound the age field. No hardcoded copy in `lib/` (test fixtures may mirror it).
- **D-12:** **Background:** optional, max 500 characters, multiline with a live counter. Empty background → the backend stores an empty string (today `background: String!`) or makes the field nullable — backend's call (D-23).
- **D-13:** No preselected enum values: the player picks sex, pronoun, race and class explicitly (Claude may revisit if the sheet reads badly empty).

#### Portrait (CHAR-05)
- **D-14:** Portrait is **optional**. When absent, the default image is the bundled asset **`assets/images/placeholders/silhouette.jpeg`** — shown as the sheet's portrait preview and wherever a character image is rendered with `imagePath == null` (the backend's `imagePath` is already nullable). Introduce one place that resolves "imagePath or silhouette" rather than sprinkling the fallback.
- **D-15:** Source: **device gallery / camera upload only**. No curated set in this phase (deferred). Picker package (`image_picker` or equivalent) and platform setup (iOS `Info.plist` usage descriptions, Android photo picker) are researcher/planner decisions and explicit Wave 0 tasks, as in Phase 11 D-34.
- **D-16:** **Upload happens at submit**, not at pick time: the picked file stays local (preview from file) until "Crea". Submit sequence: (1) if a file was picked, `POST /cloudinary/uploadImage` → URL (the endpoint exists, authenticated, folder `characters_profile`); (2) `createCharacter` mutation with `imagePath = URL` (or null). Upload failure → inline error, mutation not sent, data preserved. Mutation failure after a successful upload → inline error, keep the URL in memory so a retry does not re-upload. Orphaned Cloudinary files are accepted for now.
- **D-17:** **No NSFW filter in this phase** — neither on-device nor server-side. CHAR-06 is explicitly deferred by the user (see `<deferred>`); the first plan must mark CHAR-06 as deferred in `.planning/REQUIREMENTS.md` and `ROADMAP.md` so verification does not count it against this phase.

#### Error display (CHAR-09)
- **D-18:** Errors are **inline on the page** using the `errorText` style (same as `SignInScreen`, Phase 11 D-22): field-level validation under the field; submit errors (upload failed, name taken, age out of range, generic server error) in a notice next to the "Crea" button. Copy in Italian and in the game's voice (the "shop pattern" the requirement refers to is: domain-language message, non-blocking, never a technical string). Entered data is always preserved.
- **D-19:** Backend errors are mapped by **stable `extensions.code`** values (D-22), never by message text.

#### Backend work (user directive — built in this effort)
- **D-20:** The backend part is delivered in the backend repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) **through its own GSD workflow**: insert a decimal phase **02.1 "Character Creation Contract"** between BE Phase 2 (complete) and BE Phase 3 (not started) — done 2026-10-09, branch `feat/02.1-character-creation-contract` per the BE template `feat/{phase}-{slug}`, discuss → plan → execute → PR to `develop`. The answers captured here are carried into the BE 2.1 context so the user is not asked twice. The FE plans that touch the network depend on that contract (locally runnable BE is enough; staging is not required for this phase).
- **D-21:** Proposed contract (fixed in the BE 2.1 context; `src/schema.gql` wins once generated): mutation **`createCharacter(input: CreateCharacterInput!): User!`** acting on the **authenticated identity** (no `userId` argument; one character per user — a second call while `currentCharacter` is set fails). Input: `name`, `sex`, `pronoun`, `race`, `classType`, `age`, `background` (optional), `imagePath` (optional URL). Returns the updated `User` with `currentCharacter { id … }`. Query **`raceTraits`** (D-11). Initial character state is **backend business**, decided in the BE 2.1 discuss (2026-10-09): level 1, title `rookie`, 0 XP, 100/100 HP, 5 silver, no equipment/items/spells; starting location = the `markerLocation` of the race's home city (elf → `elfCapital`; gnome/dwarf/tiefling → `motherCapital`; halfling → `liberiaCapital`; aarakocra → `aarakocraVillage`; dragonborn → `mountainVillage`; human/halfelf → random among `drusteaCapital`, `valanCapital`, `mirwaCapital`, `liberiaCapital`). The app never computes any of this.
- **D-22:** Stable error codes in `errors[0].extensions.code`, mirrored by the app: `CHARACTER_NAME_INVALID`, `CHARACTER_NAME_TAKEN`, `CHARACTER_AGE_OUT_OF_RANGE`, `CHARACTER_ALREADY_EXISTS`, `STARTING_LOCATION_UNAVAILABLE` (no home city seeded for the race), plus the generic validation failure. Fixed in the BE 2.1 context (`Klimmeck-Guide-BE/.planning/phases/02.1-character-creation-contract/02.1-CONTEXT.md` D-04); `src/schema.gql` wins once generated.
- **D-23:** Server-side validation duplicates nothing the client "owns": the backend is authoritative for every rule (name charset/length/uniqueness, age-by-race, background length, enum membership). The client's live validation is UX only.
- **D-24:** The existing REST upload (`POST /cloudinary/uploadImage`, bearer required since BE Phase 2) is reused as-is; an upload size limit / client-side downscale is Claude's discretion.

#### Formatting discipline (carried from Phase 11 D-38)
- **D-25:** Never run `dart format` on directories; format only files a task creates or modifies and verify with `dart format --output=none --set-exit-if-changed <files>`. Same caution in the BE: `npx prettier --write <file>` + `npx eslint <file>` on touched files only (never `npm run lint`).

### Claude's Discretion
- Exact `AuthCubit` mechanism to adopt the post-creation `User` (D-02).
- Picker package, image downscale/compression and max upload size (D-15, D-24); whether to show a simple square-cropped preview (`BoxFit.cover`) — no crop tool required.
- Backend: `background` nullable vs empty string; initial character defaults; whether `raceTraits` is a plain query or enum metadata.
- Behaviour details when the race changes after an age was typed (D-10 fixes "show error, don't clamp").
- Feature folder/class names per `docs/rules/naming.md` (e.g. `lib/screens/characterCreation/` + `CharacterCreationScreen` + `CharacterCreationCubit`); the unused `lib/screens/onBoarding/` placeholder is left alone (onboarding is a deferred Phase 11 idea).
- Whether a light `02-UI-SPEC.md` is produced for the provisional layout (recommended: yes, short, tokens only).

### Deferred Ideas (OUT OF SCOPE)
- **Curated portrait set** (Cloudinary folder or bundled assets) — CHAR-05 "pick from a curated set" half is deferred; only upload ships now.
- **NSFW pre-screen on-device and authoritative server check (CHAR-06)** — explicitly deferred by the user ("Nessun filtro per ora"). Candidates: BE Phase 10 (Hardening) with Cloudinary AI moderation, FE Phase 12. The first FE plan marks CHAR-06 as deferred in REQUIREMENTS/ROADMAP (D-17).
- **Multi-step wizard** with back navigation — replaced by the single page (D-04).
- **Final, non-provisional layout** for the creation sheet — later polish pass.
- **Dev reset of the character** to re-run the flow without touching Mongo by hand.
- **Welcome screen after creation** — rejected for now (D-02).
- **Onboarding screens before sign-in** — already deferred in Phase 11.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CHAR-01 | `currentCharacter == null` routes to creation instead of the main shell | Branch in `main.dart` `authenticatedBuilder` (extract a tiny testable widget); **`AuthGate._shouldRebuild` must also rebuild when `currentCharacter` changes** (Pitfall 1) |
| CHAR-02 | Name, required, validated client + server | Unicode regex `RegExp(r"^[\p{L}'’\- ]+$", unicode: true)` verified in Dart 3.9.2; trim + collapse whitespace, 2–20 UTF-16 units; server codes `CHARACTER_NAME_INVALID` / `CHARACTER_NAME_TAKEN` |
| CHAR-03 | sex, pronoun, race, classType, age from the enums | Existing enums + `label` extensions (`SexType.label` to add); age bounded by `raceTraits`; enum variables sent as `enum.name` strings (valid GraphQL variable coercion) |
| CHAR-04 | Free-text background, bounded | Multiline `TextField` with `maxLength: 500` counter; note grapheme vs UTF-16 counting (Pitfall 6) |
| CHAR-05 | Portrait upload from gallery/camera (curated half deferred) | `image_picker 1.2.2` behind a `PortraitPicker` interface; downscale 1024px / quality 85; **`KlimmeckRest.uploadImage` is broken today (wrong path + 201 vs 200)** — must be fixed (Pitfall 2) |
| CHAR-06 | NSFW pre-screen | **DEFERRED (D-17)** — first plan marks it deferred in REQUIREMENTS.md + ROADMAP.md |
| CHAR-07 | Mutation creates the character, app enters the main shell | `createCharacter` returns `User`; `AuthCubit.adoptUser` → `AuthTokenService.adoptUser` re-emits `AuthAuthenticated`; gate rebuild fix; **`MainScreen` hardcodes the character id** (Pitfall 3) |
| CHAR-08 | Back navigation preserves data | Satisfied by single page (D-04): state lives in one cubit, never reset on error |
| CHAR-09 | Errors inline, data preserved | Pure `OperationException` → `CharacterCreationFailure` mapper reading `extensions.code` from `graphqlErrors` **and** `ServerException.parsedResponse.errors` (HTTP 400 path) |
</phase_requirements>

## Project Constraints (from CLAUDE.md and docs/rules)

- **Layering:** UI → Cubit → Repository → Service. UI never calls services; Cubit has no Flutter imports and receives dependencies by constructor; no service locator, no singletons inside cubits.
- **State:** immutable, `Equatable`, full `props`, `copyWith`; errors as state (with a code for the UI); one `Loaded`-style state with flags (`isSubmitting`) preferred over class explosion. Gameplay-adjacent cubits use the `SafeEmit` mixin.
- **Cubit must not call another Cubit**; cross-cubit orchestration goes through the UI via `BlocListener`.
- **GraphQL documents** only under `lib/graphql/{queries,mutations,fragments}`, named operations (`GetRaceTraits`, `CreateCharacter`), files `character_queries.dart` / `character_mutations.dart`.
- **Never propagate raw `OperationException` to the UI**; map to domain failures in Repository/Cubit.
- **Theme:** no inline hex / `TextStyle(fontSize:)`; new tokens go into `lib/theme/kg_theme.dart`.
- **Chrome:** allowed on the creation screen (utility screen); **no blocking loading in session** — submit progress stays on the button.
- **Tap targets ≥ 44×44**; interactive elements need semantic labels.
- **TDD mandatory:** test first (Red → Green → Refactor); `bloc_test` for every non-trivial cubit; models need `fromJson`/`toJson`/Equatable tests first; `mocktail`; no `Future.delayed` sync.
- **Boy Scout Rule** on touched files (in scope only).
- **Branch + PR:** work on `feat/character-creation` (already current), PR to `develop`; commit scope `phase-2` (e.g. `feat(phase-2): …`); **no `Co-Authored-By` trailer** (user memory overrides the default attribution).
- **`flutter analyze` must not add issues** (baseline below); **`dart format` only on touched files**, never directories.
- **No secrets in repo**; backend is source of truth (no age table, starting state or validation authority in `lib/`).

## Summary

The phase is mostly well-trodden Flutter work (a form, a cubit, a mutation), but the research turned up **four latent defects in existing code that will silently break the flow if the planner treats them as "reuse as-is"**:

1. **`AuthGate` will not rebuild** when the authenticated `User` keeps the same `id` and only gains `currentCharacter` — `_shouldRebuild` only reacts to runtime-type changes, user-id changes, or unauthenticated-reason changes. Without a fix, a successful creation leaves the user staring at the creation page.
2. **`KlimmeckRest.uploadImage` cannot work today:** it posts to `'uploadImage'` (resolves to `http://host:3000/uploadImage`, a 404 — the Nest controller is `@Controller("cloudinary")` with no global prefix), and it only accepts `statusCode == 200` while a Nest `@Post` returns **201**. It also swallows every error into `null`, and the backend returns **201 with `{message, error}`** (no `url`) when Cloudinary fails. It has zero callers, so it can be fixed freely.
3. **`MainScreen.initState` hardcodes `loadCharacter("68c191de541d89c481b8322b")`.** After creating a character the shell would load someone else's (or a non-existent) character. The shell must receive `user.currentCharacter.id`.
4. **`KlimmeckGraphQl` flattens every GraphQL error into `Exception('Server error: …')`** and resolves its client through the global `navigatorKey`, so neither error codes nor the methods themselves are testable. New operations need a code-preserving mapper (pattern already exists in `mapAuthOperationException`) and an injectable client resolver.

For image picking, **`image_picker 1.2.2`** is the newest version that resolves on the project's Flutter 3.35.5 / Dart 3.9.2 (verified by a `flutter pub add --dry-run` on a scratch copy); 1.2.3+ need Dart ≥ 3.10. Android needs no manifest change (Photo Picker on API 33+, `flutter.minSdkVersion` = 24 meets the plugin's minSdk 24); iOS needs `NSPhotoLibraryUsageDescription` and `NSCameraUsageDescription` in `Info.plist`.

**Primary recommendation:** build a `CharacterCreationCubit` (single state with flags) over a thin `CharacterCreationRepository` (GraphQL facade + fixed REST upload + pure error mapper) and an injectable `PortraitPicker`; hand the returned `User` to `AuthCubit.adoptUser` → `AuthTokenService.adoptUser` via a `BlocListener`; fix `AuthGate._shouldRebuild`, `KlimmeckRest.uploadImage` and the hardcoded `MainScreen` character id as explicit tasks.

## Standard Stack

### Core (already in the project — verified in `pubspec.lock`)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| flutter_bloc | 9.1.1 | Cubit + `BlocListener` orchestration | Project standard [VERIFIED: pubspec.lock] |
| equatable | ^2.0.0 | State/model equality | Project standard [VERIFIED: pubspec.yaml] |
| graphql_flutter / graphql | 5.2.1 | `createCharacter` mutation, `raceTraits` query | Project standard; `OperationException.graphqlErrors[].extensions` exposes codes [VERIFIED: pub cache source] |
| dio | 5.8.0+1 | Multipart upload to `/cloudinary/uploadImage` | Project standard; `FormData` overrides the JSON `Content-Type` with `multipart/form-data; boundary=…` automatically [VERIFIED: dio_mixin.dart `_transformData`] |
| bloc_test | 10.0.0 | Cubit state-sequence tests | Project standard [VERIFIED: pubspec.lock] |
| mocktail | 1.0.5 | Mocks of repository / picker / service | Project standard [VERIFIED: pubspec.lock] |

### New dependency
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| image_picker | **1.2.2** (resolves with image_picker_android 0.8.13+17, image_picker_ios 0.8.13+3, platform_interface 2.11.1, cross_file 0.3.5+2) | Gallery / camera pick with native downscale | The only picker the planner needs. 1.2.3 (needs Dart ^3.10 / Flutter ≥3.38) and 1.2.4 (Dart ^3.11) do **not** resolve on Dart 3.9.2 [VERIFIED: pub.dev API + `flutter pub add image_picker --dry-run` on a scratch copy] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| image_picker | file_picker / wechat_assets_picker | Heavier, no camera in one API, not first-party; no benefit for one optional portrait |
| image_picker downscale | flutter_image_compress | Extra native dep; `pickImage(maxWidth, maxHeight, imageQuality)` already downscales natively |
| Crop tool (image_cropper) | — | Explicitly not required (Claude's discretion says `BoxFit.cover` preview is enough) |

**Installation (Wave 0):**
```bash
flutter pub add image_picker   # resolves to 1.2.2 on Flutter 3.35.5 / Dart 3.9.2
```

**Version note:** `pubspec.lock` today records `flutter: ">=3.32.0"`; adding image_picker 1.2.2 raises the lock floor to `flutter >=3.35.0` / `dart >=3.9.0`. The machine runs 3.35.5 (FVM default), but **`.fvmrc` still pins `3.32.6`** — anyone running `fvm flutter` would fail to resolve. Recommend bumping `.fvmrc` to `3.35.5` in the same Wave 0 commit (see Open Questions).

## Architecture Patterns

### Recommended Project Structure
```
lib/
├── graphql/
│   ├── fragments/user_fragment.dart            # NEW: UserFields (id twitchId twitchPoints role currentCharacter { id }) — Boy Scout: today duplicated in GetMe + AuthSessionFields
│   ├── mutations/character_mutations.dart      # + CreateCharacter
│   └── queries/character_queries.dart          # + GetRaceTraits
├── models/
│   ├── character/race_traits.dart              # NEW: RaceTraits { race, minAge, maxAge } + contains(age)
│   ├── enums/sex_type.dart                     # + label ("Maschio"/"Femmina"), fix SextTypeExtension typo
│   └── request/create_character_request.dart   # NEW: CreateCharacterRequest.toJson() (enum.name strings, imagePath omitted when null)
├── repository/
│   ├── character_creation_repository.dart      # NEW: raceTraits(), uploadPortrait(path), createCharacter(req), currentUser()
│   ├── character_creation_failure.dart         # NEW: sealed/enum failure + pure mapper from OperationException / DioException
│   └── services/
│       ├── graphql/graphql.dart                # + getRaceTraits, createCharacter, getMe; injectable client resolver
│       ├── rest/rest.dart                      # FIX uploadImage (path, 201, url check, timeouts, typed throw)
│       └── image/portrait_picker.dart          # NEW: PortraitPicker interface + ImagePickerPortraitPicker
├── screens/
│   ├── auth/
│   │   ├── auth_gate.dart                      # FIX _shouldRebuild (currentCharacter change)
│   │   ├── authenticated_shell.dart            # receives characterId → MainScreen
│   │   └── cubit/auth_cubit.dart               # + adoptUser(User)
│   └── characterCreation/
│       ├── character_creation_screen.dart      # Scaffold + AppBar("Esci") + two-column sheet
│       ├── cubit/character_creation_cubit.dart
│       ├── cubit/character_creation_state.dart # part of cubit
│       ├── cubit/character_draft.dart          # pure validation (no Flutter)
│       └── components/                         # portrait_column.dart, sheet_row.dart, enum_choice_row.dart, age_field.dart, submit_bar.dart
└── shared/components/character_portrait.dart   # NEW: the single "imagePath | local file | silhouette" resolver (D-14)
```

### Pattern 1: Adopt the created User through the auth source of truth (D-02)
**What:** `AuthTokenService` gains `void adoptUser(User user)`; both implementations update their stored user and re-emit `AuthAuthenticated(user, currentToken)` through their `AuthStateChannel`. `AuthCubit.adoptUser(user)` delegates. The creation screen's `BlocListener<CharacterCreationCubit>` calls `context.read<AuthCubit>().adoptUser(state.createdUser!)` when the cubit reaches "created".
**Why not emit directly from `AuthCubit`:** the channel caches `_current` and replays it to new listeners; `SessionAuthTokenService` keeps `_user` and re-emits it on login/bootstrap; a cubit-only replacement leaves the service holding a stale `currentCharacter: null`, which would bounce the user back to creation on any future re-emit (e.g. when Phase 3 starts pushing user updates). [VERIFIED: `auth_state_channel.dart`, `session_auth_token_service.dart` `_emitAuthenticated`/`_announceIdentityChange`]
**Guard:** ignore `adoptUser` unless current state is `AuthAuthenticated` and `user.id` matches (prevents a late response from a previous session overriding a new one).
```dart
// SessionAuthTokenService
@override
void adoptUser(User user) {
  if (_channel.current is! AuthAuthenticated || user.id != _user?.id) return;
  _user = user;
  _emitAuthenticated();
}
```

### Pattern 2: Gate rebuild on character change (fix in `AuthGate`)
```dart
static bool _changesCharacter(AuthState previous, AuthState current) =>
    previous is AuthAuthenticated &&
    current is AuthAuthenticated &&
    previous.user.currentCharacter?.id != current.user.currentCharacter?.id;

static bool _shouldRebuild(AuthState previous, AuthState current) =>
    previous.runtimeType != current.runtimeType ||
    _changesUser(previous, current) ||
    _changesCharacter(previous, current) ||
    (/* existing unauthenticated-reason clause */);
```
Keep `_leavesSession` and the `KeyedSubtree(key: user.id)` untouched: the swap creation → shell happens under the same key, the creation screen (and its `BlocProvider`-owned cubit) is unmounted, the shell mounts its gameplay cubits for the first time. A `twitchPoints` change must **not** rebuild the shell (only character id is compared).

### Pattern 3: Branch in the authenticated builder (D-01), extracted for testability
`main.dart` keeps the decision point but delegates to a tiny widget so it can be widget-tested without booting `main()`:
```dart
// main.dart
authenticatedBuilder: (context, user) => SessionHome(
  user: user,
  creationBuilder: (context) => CharacterCreationScreen.withDependencies(graphQl: graphQl, rest: rest),
  shellBuilder: (context, characterId) => AuthenticatedShell(graphQl: graphQl, characterId: characterId),
),
// SessionHome.build: user.currentCharacter == null ? creationBuilder(context) : shellBuilder(context, user.currentCharacter!.id)
```
(`SessionHome` naming is a suggestion; it contains no logic beyond the null check, consistent with "guards are widgets".)

### Pattern 4: One cubit, one state with flags
```dart
// character_creation_state.dart (part of cubit)
enum CharacterCreationFailure { uploadFailed, nameInvalid, nameTaken, ageOutOfRange, alreadyExists, startingLocationUnavailable, connection, unknown }
enum PortraitPickFailure { permissionDenied, cameraUnavailable, unknown }
enum RaceTraitsStatus { loading, loaded, failed }

final class CharacterCreationState extends Equatable {
  final CharacterDraft draft;                 // sex, name, pronoun, race, classType, ageText, background
  final Map<RaceType, RaceTraits> raceTraits; // unmodifiable
  final RaceTraitsStatus raceTraitsStatus;
  final String? portraitPath;                 // local file, preview only
  final UploadedPortrait? uploadedPortrait;   // (localPath, url) — reused on retry ONLY if localPath == portraitPath
  final bool isSubmitting;
  final CharacterCreationFailure? submitFailure;
  final PortraitPickFailure? pickFailure;
  final User? createdUser;                    // non-null → listener adopts it
  bool get canSubmit => !isSubmitting && draft.isValidFor(raceTraits);
}
```
Submit sequence (D-16): guard `if (!state.canSubmit) return;` → `isSubmitting: true, submitFailure: null` → if `portraitPath != null && uploadedPortrait?.localPath != portraitPath` upload → on failure emit `uploadFailed` and stop → `createCharacter(request with imagePath = uploadedPortrait?.url)` → success emits `createdUser`; failure emits mapped code, keeps `uploadedPortrait`. Never touch `draft` on failure.

### Pattern 5: Error-code mapper (pure, mirrors `mapAuthOperationException`)
```dart
CharacterCreationFailure characterCreationFailureFrom(OperationException e) {
  final link = e.linkException;
  final errors = [
    ...e.graphqlErrors,
    if (link is ServerException) ...?link.parsedResponse?.errors, // Apollo returns HTTP 400 for BAD_USER_INPUT on variable coercion
  ];
  final code = errors.map((x) => x.extensions?['code']).whereType<String>().firstOrNull;
  if (code == null && link != null) return CharacterCreationFailure.connection;
  return switch (code) {
    'CHARACTER_NAME_INVALID' => CharacterCreationFailure.nameInvalid,
    'CHARACTER_NAME_TAKEN' => CharacterCreationFailure.nameTaken,
    'CHARACTER_AGE_OUT_OF_RANGE' => CharacterCreationFailure.ageOutOfRange,
    'CHARACTER_ALREADY_EXISTS' => CharacterCreationFailure.alreadyExists,
    'STARTING_LOCATION_UNAVAILABLE' => CharacterCreationFailure.startingLocationUnavailable,
    _ => CharacterCreationFailure.unknown, // BAD_USER_INPUT, UNAUTHENTICATED after failed recovery, unknown
  };
}
```
[VERIFIED: gql_http_link 1.1.0 throws `HttpLinkServerException(parsedResponse: …)` for status ≥ 300; `ServerException.parsedResponse` is a `Response` with `errors`]

### Pattern 6: Injectable picker (fakeable in cubit and widget tests)
```dart
// lib/repository/services/image/portrait_picker.dart — no Flutter types in the interface
enum PortraitSource { gallery, camera }
abstract interface class PortraitPicker {
  /// Local file path of the picked, downscaled image; null when the user cancels.
  /// Throws PortraitPickException(PortraitPickFailure) on denial / no camera.
  Future<String?> pick(PortraitSource source);
}

class ImagePickerPortraitPicker implements PortraitPicker {
  ImagePickerPortraitPicker([ImagePicker? picker]) : _picker = picker ?? ImagePicker();
  static const double maxSide = 1024;
  static const int quality = 85;
  final ImagePicker _picker;

  @override
  Future<String?> pick(PortraitSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source == PortraitSource.camera ? ImageSource.camera : ImageSource.gallery,
        maxWidth: maxSide, maxHeight: maxSide, imageQuality: quality,
        requestFullMetadata: false, // avoids the iOS photo-library permission prompt for gallery picks
      );
      return file?.path;
    } on PlatformException catch (e) {
      throw PortraitPickException(switch (e.code) {
        'photo_access_denied' || 'camera_access_denied' => PortraitPickFailure.permissionDenied,
        'no_available_camera' => PortraitPickFailure.cameraUnavailable,
        _ => PortraitPickFailure.unknown,
      });
    }
  }
}
```
[VERIFIED: image_picker 1.2.2 `pickImage` signature; error codes `photo_access_denied`, `camera_access_denied`, `no_available_camera`, `already_active`, `invalid_image` found in image_picker_ios 0.8.13+3 / image_picker_android 0.8.13+17 sources]

### Pattern 7: Landscape two-column sheet
```dart
Scaffold(
  // resizeToAvoidBottomInset: true (default) — keep it
  appBar: AppBar(automaticallyImplyLeading: false, actions: [TextButton(onPressed: isSubmitting ? null : () => confirmLogout(context), child: Text('Esci'))]),
  body: DecoratedBox(
    decoration: KlimmeckGuideTheme.getParchmentBackground(),
    child: SafeArea(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Flexible(flex: 2, child: PortraitColumn(...)),                 // fixed, not scrolling
        Flexible(flex: 5, child: SingleChildScrollView(                 // fields + background + notice + "Crea"
          padding: const EdgeInsets.all(24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(children: [...rows, SubmitBar(...)]),
        )),
      ]),
    ),
  ),
)
```
- `EditableText` already scrolls the focused field into view (`scrollPadding`), so no manual `Scrollable.ensureVisible` is needed for fields inside the `SingleChildScrollView`. [ASSUMED — standard Flutter behaviour, verify in the widget test with a simulated `viewInsets`]
- Android IME will not go fullscreen in landscape: Flutter's `TextInputPlugin` sets `IME_FLAG_NO_FULLSCREEN`. [VERIFIED: engine source `TextInputPlugin.java:329` in Flutter 3.35.5]
- Put "Crea" + the submit notice **at the end of the scrollable column** (not pinned): in landscape with the keyboard open only ~150 dp remain; a pinned bar would eat it.
- Wrap the `Row` in `SafeArea` (landscape notches/cutouts sit on the left/right edges).

### Pattern 8: Enum pickers
- **Sex (2), pronoun (3):** `Wrap` of `ChoiceChip`s (one visible tap, no overlay route, trivially findable in tests via `find.widgetWithText(ChoiceChip, 'Lei')`).
- **Race (9), class (12):** `ChoiceChip` `Wrap` as well is acceptable in landscape (labels are short) and keeps one interaction model; `DropdownButtonFormField` is the compact alternative. **Do not use `lib/shared/components/dropdown.dart`** — it is a collapsible accordion section (title + animated body), not a value selector. [VERIFIED: source read]
- `Section` (`lib/shared/components/section.dart`) gives the Cinzel title + bronze rule look — usable as the sheet row header, but it sizes via `LayoutBuilder` + `Row`/`Spacer`; check it does not overflow inside the scroll column before reusing.
- No `TextField` exists anywhere in `lib/` today: add an `inputDecorationTheme` to `KlimmeckGuideTheme.materialTheme` (parchment fill, `darkBronze` borders, `errorStyle: errorText`) rather than styling each field inline — it affects no existing screen. [VERIFIED: grep]

### Anti-Patterns to Avoid
- **Emitting a new `AuthAuthenticated` only inside `AuthCubit`:** service state goes stale (Pattern 1).
- **Calling `AuthCubit` from `CharacterCreationCubit`:** forbidden by state-management rules; use `BlocListener` in the screen.
- **Reusing `KlimmeckGraphQl.getGenericErrorMessage`:** loses `extensions.code`, emits technical strings.
- **Inline GraphQL enum literals or string-building variables:** always pass a `variables: {'input': request.toJson()}` map.
- **Uploading at pick time:** violates D-16 (orphan on every re-pick).
- **Reusing the cached upload URL after the user picked a different photo:** key the cache by local path.
- **A blocking overlay during submit:** progress lives in the "Crea" button only (D-05, rule #2).
- **Hard-coding the race/age table in `lib/`:** D-11 (fixtures in `test/` may mirror it).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Gallery/camera access, permissions, Android Photo Picker | Platform channels | `image_picker` | Handles Photo Picker (API 33+), scoped storage, iOS PHPicker, HEIC |
| Client-side downscale/compress | Custom decode/resize in Dart | `pickImage(maxWidth, maxHeight, imageQuality)` | Native, off the UI isolate |
| Multipart body / boundary | Manual body bytes | dio `FormData` + `MultipartFile.fromFile` | Sets `multipart/form-data; boundary` and content-length itself |
| 401 refresh + retry on upload | Retry logic in the repository | Existing `AuthInterceptor` (clones `FormData` on retry) | Already tested in Phase 11 |
| GraphQL 401/`UNAUTHENTICATED` recovery | Anything | Existing `AuthAuthLink` | Already tested |
| Logout confirmation | New dialog | `confirmLogout(context)` in `logout_confirmation_dialog.dart` | Exists, tested, reads cubit before the async gap |
| Background counter / length cap | Custom counter widget | `TextField(maxLength: 500)` (+ validation on code units, Pitfall 6) | Built-in counter, accessible |
| Digits-only age | Manual parsing on change | `FilteringTextInputFormatter.digitsOnly` + `LengthLimitingTextInputFormatter(4)` | Edge cases (paste, IME) |

**Key insight:** every hard part (picker, multipart, auth retry, logout) already has a battle-tested implementation; the phase's real risk is in the glue (gate rebuild, upload path/status, error-code extraction, shell character id).

## Runtime State Inventory

Not a rename/refactor phase — section omitted. Note for manual testing: in dev the BE dev user must have `currentCharacter: null` to see the page (D-03); re-testing requires clearing it in Mongo by hand (dev reset deferred).

## Common Pitfalls

### Pitfall 1: Gate does not rebuild after creation
**What goes wrong:** creation succeeds, `AuthCubit` emits a new `AuthAuthenticated` with the same `user.id`, but `BlocBuilder(buildWhen: _shouldRebuild)` returns false → the creation page stays.
**Why:** `_shouldRebuild` = runtime type change ∨ user id change ∨ unauthenticated reason change. [VERIFIED: `lib/screens/auth/auth_gate.dart`]
**How to avoid:** add `_changesCharacter` (Pattern 2) with a red test first in `auth_gate_test.dart`: same id, `currentCharacter` null → `Character(id: 'c1')` must swap the builder output.
**Warning signs:** cubit test green, manual run stuck on the sheet.

### Pitfall 2: The REST upload is broken in three ways
**What goes wrong:** (a) `dio.post('uploadImage')` with `baseUrl = http://localhost:3000/` hits `/uploadImage` → 404; the route is `/cloudinary/uploadImage` (`@Controller("cloudinary")`, no `setGlobalPrefix` in `main.ts`). (b) `if (response.statusCode == 200)` — Nest `@Post` answers **201** → always `null`. (c) On Cloudinary failure the BE still answers 201 with `{message, error}` and no `url` → `response.data['url'] as String` would throw a cast error (swallowed into `null`). [VERIFIED: `rest.dart`, BE `cloudinary.controller.ts`, BE `main.ts`, `.env` `BASE_URL=http://localhost:3000/`]
**How to avoid:** path `'cloudinary/uploadImage'` (like the sibling `cloudinary/getUrls`), accept any 2xx, require a non-empty `String url`, otherwise throw a typed `PortraitUploadException`; pass per-request `Options(sendTimeout: 30s, receiveTimeout: 30s)` — the client default `receiveTimeout` of 10 s also covers the wait for response headers while the BE streams to Cloudinary. [VERIFIED: dio io_adapter applies `receiveTimeout` to `request.close()`; `sendTimeout` unset = no limit]
**Warning signs:** "upload failed" every time in dev even with Cloudinary configured.

### Pitfall 3: Shell loads a hardcoded character
**What goes wrong:** `MainScreen.initState` calls `loadCharacter("68c191de541d89c481b8322b")`; a freshly created character is never shown. [VERIFIED: `lib/screens/mainScreen/main_screen.dart:51`]
**How to avoid:** `AuthenticatedShell` takes `characterId` (from `user.currentCharacter!.id` in the builder) and passes it to `MainScreen`; update `authenticated_shell_test.dart`. This is the minimal change that makes success criterion 4 observable; the live subscription rewiring stays in Phase 3 (SYNC-02/05).
**Warning signs:** after "Crea", the journal/profile shows another character's data or an error.

### Pitfall 4: Error codes lost on the HTTP 400 path
**What goes wrong:** Apollo Server 4 answers HTTP 400 for variable-coercion failures (`BAD_USER_INPUT`, e.g. an enum name the schema does not know); `gql_http_link` turns any status ≥ 300 into `HttpLinkServerException` and `graphqlErrors` stays empty → a naive mapper says "connection error". Codes thrown from resolvers (`CHARACTER_*`) arrive with HTTP 200 in `graphqlErrors`. [VERIFIED: gql_http_link 1.1.0 `link.dart:89`; Apollo status behaviour ASSUMED from Apollo Server 4 defaults]
**How to avoid:** Pattern 5 — read codes from both lists; only fall back to `connection` when no code exists and `linkException != null`.

### Pitfall 5: `CHARACTER_ALREADY_EXISTS` dead end
**What goes wrong:** double submit from two devices / a first submit whose response was lost: the BE already created the character, the retry gets `CHARACTER_ALREADY_EXISTS`, the user is stuck on the sheet forever (session user still has `currentCharacter: null`).
**How to avoid:** on `alreadyExists`, the cubit re-reads the user (`GetMe` through the authenticated client — add `KlimmeckGraphQl.getMe()` reusing `UserFields`) and, if it has a character, emits `createdUser` so the listener adopts it. Show "Hai già un personaggio" only if the refetch fails.
**Warning signs:** retry after a timeout never leaves the page.

### Pitfall 6: Length counted differently on client and server
**What goes wrong:** `TextField(maxLength: 500)` limits **grapheme clusters** (`text.characters.length`), while the BE (JS) almost certainly counts **UTF-16 code units** (`.length`). 500 emoji = 1000 code units → server rejects. [VERIFIED: Flutter 3.35.5 `LengthLimitingTextInputFormatter` uses `characters.length`; BE counting ASSUMED until BE 2.1 code exists]
**How to avoid:** the draft validator uses `trim().length` (Dart `String.length` = UTF-16 code units, same as JS) to enable "Crea"; the counter is UX only. Same for the 2–20 name rule (letters only, so graphemes ≈ code units except combining marks — `"é"` is 2 units and `́` is `\p{M}`, not `\p{L}`, so it fails both sides consistently). [VERIFIED: Dart regex run]

### Pitfall 7: Stale upload URL reused for a different photo
**What goes wrong:** upload OK → mutation fails (name taken) → user picks another photo → retry reuses the first URL.
**How to avoid:** store `UploadedPortrait(localPath, url)`; reuse only when `localPath == portraitPath`; clear when the portrait is removed/replaced.

### Pitfall 8: Android activity killed while the camera is open
**What goes wrong:** under memory pressure Android destroys `MainActivity` during the camera intent; the pick result is lost and the app restarts (the form state is lost too). [CITED: pub.dev/packages/image_picker — "retrieveLostData"]
**How to avoid:** accept for this provisional phase (the whole form is lost anyway, so `retrieveLostData()` alone adds little); document it in the plan as an accepted risk. `launchMode` is `singleTop` (not `singleInstance`), so the picker does return results normally. [VERIFIED: AndroidManifest.xml]

### Pitfall 9: Image.file in widget tests
**What goes wrong:** `FileImage` decoding does real I/O that never completes inside `testWidgets`' fake async zone; `pumpAndSettle` can time out if an animation waits on it.
**How to avoid:** in widget tests assert on the widget/`ImageProvider` type (`(tester.widget<Image>(…).image as FileImage).file.path`) rather than rendered pixels; avoid `pumpAndSettle` with a file preview mounted, use `pump()`; no goldens for this provisional layout.

### Pitfall 10: Splash flashes after "Crea"
**What goes wrong:** `AuthenticatedShell` mounts and calls `SplashCubit.getImages('main')`; until it settles the shell renders `SplashScreen` — a full-screen loader right after the user's action. [VERIFIED: `authenticated_shell.dart`]
**How to avoid:** acceptable under rule #2 (loader after an explicit user action; it is also the same path as after login). Ordering is unaffected because only the shell triggers the preload. Do **not** start the preload from the creation screen unless the planner wants to shave this (optional, out of scope).

### Pitfall 11: Global `navigatorKey` inside `KlimmeckGraphQl`
**What goes wrong:** `performQuery/performMutation` call `GraphQLProvider.of(navigatorKey.currentContext!)` — unit tests of new facade methods crash (`currentContext` null).
**How to avoid:** add an optional constructor parameter, e.g. `KlimmeckGraphQl({GraphQLClient Function()? resolveClient})` defaulting to the current lookup; tests pass a `GraphQLClient(link: Link.function(...))` exactly like `graphql_backend_auth_api_test.dart` does. Backward compatible (existing `KlimmeckGraphQl()` calls unchanged).

### Pitfall 12: Backend contract not built yet
**What goes wrong:** BE 2.1 has only a CONTEXT (no plans, no code, no `createCharacter` / `raceTraits` / `RaceTraits` in `src/schema.gql` as of today). Field names or return selection could drift. [VERIFIED: grep of BE `src/schema.gql`, BE git log]
**How to avoid:** order plans so pure/UI work (models, validator, cubit with mocked repository, screen, gate fix, upload fix with fake adapter) comes first; the GraphQL document task has a **checkpoint**: diff the documents against the regenerated `src/schema.gql` before merging. Note `SexType`, `PronounType`, `ClassType`, `RaceType` are all `registerEnumType`'d in the BE with values identical to the Dart enum names. [VERIFIED: BE `src/models/enums/*.enum.ts`]

## Code Examples

### GraphQL documents
```dart
// lib/graphql/fragments/user_fragment.dart
class UserFragment {
  static const String name = 'UserFields';
  static const String definition = '''
    fragment $name on User { id twitchId twitchPoints role currentCharacter { id } }
  ''';
}

// lib/graphql/mutations/character_mutations.dart (add)
static const String createCharacter = r'''
  mutation CreateCharacter($input: CreateCharacterInput!) {
    createCharacter(input: $input) { ...UserFields }
  }
''' + UserFragment.definition;

// lib/graphql/queries/character_queries.dart (add)
static const String getRaceTraits = r'''
  query GetRaceTraits { raceTraits { race minAge maxAge } }
''';
```
Enum variables as `enum.name` strings are valid: for JSON transport, GraphQL input coercion accepts a string variable value as the enum value of the same name. [CITED: spec.graphql.org — Enums, Input Coercion] Never inline `sex: "male"` as a literal in the document (string literals are rejected for enums).

### Request model
```dart
// lib/models/request/create_character_request.dart
Map<String, dynamic> toJson() => {
  'name': name, 'sex': sex.name, 'pronoun': pronoun.name, 'race': race.name,
  'classType': classType.name, 'age': age,
  if (background.isNotEmpty) 'background': background,
  if (imagePath != null) 'imagePath': imagePath,
};
```

### Fixed upload
```dart
Future<String> uploadImage(File file) async {
  final formData = FormData.fromMap({
    'file': await MultipartFile.fromFile(file.path, filename: file.uri.pathSegments.last),
  });
  final response = await _restClient.dio.post<Map<String, dynamic>>(
    'cloudinary/uploadImage',
    data: formData,
    options: Options(sendTimeout: _uploadTimeout, receiveTimeout: _uploadTimeout),
  );
  final url = response.data?['url'];
  if (url is! String || url.isEmpty) throw const PortraitUploadException();
  return url;
}
```
(dio already throws `DioException` for non-2xx with the default `validateStatus`; the repository maps both to `CharacterCreationFailure.uploadFailed`.)

### Portrait resolver (D-14)
```dart
// lib/shared/components/character_portrait.dart
class CharacterPortrait extends StatelessWidget {
  const CharacterPortrait({super.key, this.imagePath, this.localFilePath});
  static const String silhouetteAsset = 'assets/images/placeholders/silhouette.jpeg';
  ImageProvider get _image => switch ((localFilePath, imagePath)) {
    (final String path, _) => FileImage(File(path)),
    (_, final String url) => CachedNetworkImageProvider(url),
    _ => const AssetImage(silhouetteAsset),
  };
  @override
  Widget build(BuildContext context) => Image(image: _image, fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(silhouetteAsset, fit: BoxFit.cover));
}
```
(`cached_network_image` is already a dependency; `docs/rules/assets.md` requires it for remote rasters.)

### Landscape widget-test surface
```dart
void useLandscapePhone(WidgetTester tester) {
  tester.view.physicalSize = const Size(2340, 1080); // 780 x 360 logical at 3.0
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}
```
A `RenderFlex overflowed` error fails the test automatically, so a "renders without overflow at 780×360 with the keyboard open" test (set `tester.view.viewInsets = FakeViewPadding(bottom: 600)`) is a cheap layout guard.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `READ_EXTERNAL_STORAGE` / `requestLegacyExternalStorage` for gallery | Android Photo Picker (API 33+), no permission | image_picker_android 0.8.x | No manifest change needed |
| iOS `UIImagePickerController` + photo library permission | `PHPicker` (no permission when `requestFullMetadata: false`) | image_picker 0.8.6+ | Pass `requestFullMetadata: false` to avoid the prompt; keep the plist key (App Review) |
| `tester.binding.window.physicalSizeTestValue` | `tester.view.physicalSize` + `tester.view.reset` | Flutter 3.10 | Use the `view` API |

**Deprecated/outdated:** `WidgetTester.binding.window` test values (deprecated) — use `tester.view`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Apollo Server (Nest) answers HTTP 400 for variable-coercion `BAD_USER_INPUT`, 200 for resolver-thrown `CHARACTER_*` errors | Pitfall 4 | Low — mapper reads both paths anyway |
| A2 | BE 2.1 counts name/background length in UTF-16 code units (JS `.length`) | Pitfall 6 | Low — at worst a server `BAD_USER_INPUT` on emoji-heavy backgrounds, mapped to generic error |
| A3 | `EditableText` auto-scrolls the focused field into view inside the right-column `SingleChildScrollView` | Pattern 7 | Low — add `Scrollable.ensureVisible` on focus if the widget test shows otherwise |
| A4 | Italian copy: "Maschio"/"Femmina", "Caricamento del ritratto non riuscito, riprova", "Il mondo non è ancora pronto ad accoglierti, riprova più tardi", "Errore di connessione, riprova" (reused from sign-in), "Età non valida per la razza scelta" and "Hai già un personaggio" (from BE context) | Patterns / UI | Copy only — confirm in `02-UI-SPEC.md` |
| A5 | Downscale 1024×1024 at quality 85 is enough for a portrait (expected ~150–400 KB JPEG) | Pattern 6 | Low — tune constants |
| A6 | Selection set `currentCharacter { id }` in the `createCharacter` response is enough for the shell (it loads the full character by id) | Code Examples | Low — matches `GetMe` today |

## Open Questions

1. **`.fvmrc` pins Flutter 3.32.6 while the toolchain in use is 3.35.5.**
   - What we know: `which flutter` → FVM default 3.35.5; Phase 11 research verified on 3.35.5; image_picker 1.2.2 requires Flutter ≥ 3.35.0.
   - Unclear: whether anything (CI, another machine) uses `.fvmrc`.
   - Recommendation: bump `.fvmrc` to `3.35.5` in the Wave 0 dependency commit; if the user wants 3.32 compatibility, pin `image_picker: 1.2.1` instead.
2. **Is fixing the hardcoded `MainScreen` character id in scope?**
   - What we know: without it, criterion 4 ("enters the main shell with a valid `currentCharacter`") is technically met but the shell shows the wrong character.
   - Recommendation: in scope as a minimal constructor-parameter change (no subscription rework); confirm with the user during plan review.
3. **Uncommitted change in `android/app/build.gradle.kts` (`minSdk = 23` → `flutter.minSdkVersion`).**
   - What we know: it is in the working tree (not mine); `flutter.minSdkVersion` is 24 in Flutter 3.35.5, which image_picker_android 0.8.13+17 requires (minSdk 24). [VERIFIED: FlutterExtension.kt, plugin build.gradle]
   - Recommendation: the Wave 0 native task should commit it deliberately (or explicitly set `minSdk = 24`) — ask the user whether the change is theirs to keep.
4. **iOS deployment target is 12.0 in `project.pbxproj` / `AppFrameworkInfo.plist`, while image_picker_ios (and the existing firebase_core 3.15) require 13.0.**
   - Pre-existing mismatch (no `Podfile.lock`, so iOS has probably not been built recently). Recommendation: Wave 0 raises the target to 13.0 and adds `platform :ios, '13.0'` in the Podfile, verified with `flutter build ios --no-codesign --debug` if the user wants the iOS path exercised; otherwise flag it as a known gap.
5. **BE 2.1 delivery timing.** Plans touching `CreateCharacter`/`GetRaceTraits` documents need the regenerated schema; the rest can proceed in parallel (Pitfall 12).

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter / Dart | everything | ✓ | 3.35.5 / 3.9.2 (FVM default) | — |
| Xcode / CocoaPods | iOS build, `Info.plist` check | ✓ | 26.3 / 1.16.2 | — |
| Android SDK + Studio JBR | Android build | ✓ (licenses not all accepted; no `java`/`adb` on PATH, Flutter uses Studio's) | SDK 36.1.0 | `flutter doctor --android-licenses` |
| Backend (NestJS) on :3000 | manual E2E, schema checkpoint | ✓ process listening on :3000 | — | — |
| BE `createCharacter` / `raceTraits` | network tasks, manual E2E | ✗ (BE 2.1 not built) | — | Develop against mocks; checkpoint before merge |
| Cloudinary credentials in BE `.env` | real upload | unknown (keys not inspected) | — | Upload test via fake dio adapter; manual test without portrait |
| `mongosh` | manual reset of dev `currentCharacter` | ✗ | — | Mongo Compass or the BE dev tooling |

**Missing with no fallback:** none for planning; the BE contract blocks only manual end-to-end verification.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (Flutter 3.35.5) + bloc_test 10.0.0 + mocktail 1.0.5 |
| Config file | none (`analysis_options.yaml` for lints) |
| Quick run command | `flutter test test/screens/characterCreation test/screens/auth test/repository/character_creation_repository_test.dart` |
| Full suite command | `flutter test` (baseline: **283 tests, all green**, ~15 s) |
| Lint gate | `flutter analyze lib test` (baseline **12 issues**: 8 info + 4 warnings, all pre-existing; whole repo 57 incl. 45 `avoid_print` infos in `tools/`) — must not grow |
| Format gate | `dart format --output=none --set-exit-if-changed <touched files>` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CHAR-01 | `currentCharacter == null` → creation; non-null → shell with that `characterId` | widget | `flutter test test/screens/auth/session_home_test.dart` | ❌ Wave 0 |
| CHAR-01/07 | Gate rebuilds when same-id user gains `currentCharacter` (and not on `twitchPoints` change) | widget | `flutter test test/screens/auth/auth_gate_test.dart` | ✅ extend |
| CHAR-07 | `AuthCubit.adoptUser` delegates; services re-emit only for the same authenticated user | unit + bloc_test | `flutter test test/screens/auth/cubit/auth_cubit_test.dart test/repository/services/auth/` | ✅ extend |
| CHAR-07 | Shell passes `characterId` to `MainScreen` (no hardcoded id) | widget | `flutter test test/screens/auth/authenticated_shell_test.dart` | ✅ extend |
| CHAR-02 | Name validator: trim/collapse, 2–20, `\p{L}`/space/`'`/`’`/`-` | unit | `flutter test test/screens/characterCreation/cubit/character_draft_test.dart` | ❌ Wave 0 |
| CHAR-03 | Age disabled until race; out-of-range after race change shows error, no clamp; traits load failure keeps age disabled + retry | bloc_test + widget | `flutter test test/screens/characterCreation/` | ❌ Wave 0 |
| CHAR-03 | `RaceTraits.fromJson`, `CreateCharacterRequest.toJson` (enum names, optional fields omitted), `SexType.label` | unit | `flutter test test/models/` | ❌ Wave 0 |
| CHAR-04 | Background optional, counter visible, >500 code units disables "Crea" | unit + widget | as above | ❌ Wave 0 |
| CHAR-05 | Picker cancel keeps state; permission/camera failures → inline message; preview shows file, default silhouette | bloc_test + widget | as above + `flutter test test/shared/components/character_portrait_test.dart` | ❌ Wave 0 |
| CHAR-05 | Upload posts multipart to `cloudinary/uploadImage`, accepts 201, rejects missing `url`, bearer header present | unit (fake dio adapter) | `flutter test test/repository/services/rest/rest_upload_test.dart` | ❌ Wave 0 |
| CHAR-05/09 | Upload failure → no mutation, data kept; mutation failure → URL kept, retry skips upload; new pick invalidates URL | bloc_test | `flutter test test/screens/characterCreation/cubit/character_creation_cubit_test.dart` | ❌ Wave 0 |
| CHAR-09 | Mapper: each `CHARACTER_*` code, `STARTING_LOCATION_UNAVAILABLE`, `BAD_USER_INPUT` via HTTP 400 `parsedResponse`, network → connection | unit | `flutter test test/repository/character_creation_failure_test.dart` | ❌ Wave 0 |
| CHAR-09 | `alreadyExists` → refetch `me` → adopt when it has a character | bloc_test | cubit test above | ❌ Wave 0 |
| CHAR-07 | Facade: `CreateCharacter` sends `{'input': …}`, parses `User`; `GetRaceTraits` parses list (Link.function client) | unit | `flutter test test/repository/services/graphql/graphql_character_creation_test.dart` | ❌ Wave 0 |
| CHAR-08 / D-05 | Single page: "Crea" disabled until valid; during submit button shows inline progress, fields + "Esci" locked; errors never clear fields | widget | `flutter test test/screens/characterCreation/character_creation_screen_test.dart` | ❌ Wave 0 |
| D-07 | "Esci" opens `LogoutConfirmationDialog`, confirm calls `AuthCubit.logout()` | widget | screen test above | ❌ Wave 0 |
| Layout | No overflow at 780×360 logical, also with keyboard insets | widget | screen test above | ❌ Wave 0 |
| CHAR-06 | Deferred — no test; REQUIREMENTS/ROADMAP marked deferred | doc check | `grep -n "CHAR-06" .planning/REQUIREMENTS.md` | n/a |
| Manual | Dev E2E: cold start → sheet → create (with and without portrait) → shell shows the new character; gallery + camera on a real device | manual-only (needs BE 2.1 + device) | — | UAT file |

### Sampling Rate
- **Per task commit:** the quick command scoped to the touched test files + `flutter analyze lib test` + format check on touched files.
- **Per wave merge:** `flutter test` (full).
- **Phase gate:** full suite green, analyze ≤ baseline, manual UAT against BE 2.1 before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `flutter pub add image_picker` (→ 1.2.2); `.fvmrc` bump decision; remove the duplicated `- .env` asset line in `pubspec.yaml` while there (Boy Scout, keep one)
- [ ] `ios/Runner/Info.plist`: `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription` (Italian copy); iOS deployment target 13.0 decision
- [ ] Android: commit/settle `minSdk = flutter.minSdkVersion` (24); no manifest change
- [ ] `test/helpers/mocks.dart`: `MockPortraitPicker`, `MockCharacterCreationRepository`, `MockAuthCubit` (if the screen test needs it); keep "never redefine a mock in a single file"
- [ ] `test/helpers/fixtures/race_traits_fixture.dart` mirroring D-10 (fixtures may mirror the table)
- [ ] A scripted dio adapter that returns custom JSON bodies (the existing `FakeHttpClientAdapter` only returns `{"code":…}`) — extend it with optional bodies or add `ScriptedHttpClientAdapter`
- [ ] `test/helpers/landscape.dart` (`useLandscapePhone`)

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (reuses Phase 11) | — |
| V3 Session Management | yes (adopting a user into the session) | `adoptUser` only for the same authenticated `user.id`; no token handling in the creation feature |
| V4 Access Control | yes (server) | Mutation bound to bearer identity, no `userId` input (BE D-01) — app sends none |
| V5 Input Validation | yes | Client validation is UX only; BE authoritative (D-23); enums sent as names; no string-built documents |
| V12 Files & Resources | yes | Client downscale; upload only over the authenticated endpoint; never trust/display arbitrary URLs except the BE-returned `https` Cloudinary URL |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| GraphQL injection via string-built documents | Tampering | Variables map only (`{'input': request.toJson()}`) |
| Large/unbounded upload (DoS, cost) | DoS | Client downscale 1024 px; BE limit deferred to BE-HARD (accepted) |
| Explicit content in portraits | Info disclosure / abuse | **Accepted risk** — CHAR-06 deferred by user (D-17) |
| EXIF/GPS metadata leaking location | Info disclosure | Re-encoding via `maxWidth/imageQuality` drops most metadata on both platforms [ASSUMED]; `requestFullMetadata: false` |
| Logging tokens / payloads | Info disclosure | Log only `runtimeType` (existing convention), never URLs with tokens or request bodies |
| Late response adopting into a new session | Spoofing/Tampering | `adoptUser` guard on current state + id; cubit `SafeEmit` |

## Sources

### Primary (HIGH confidence)
- Codebase (read in this session): `lib/main.dart`, `lib/screens/auth/{auth_gate,authenticated_shell}.dart`, `auth_cubit.dart`, `lib/repository/services/auth/*`, `lib/repository/services/graphql/{graphql,auth_link,graphql_client_provider}.dart`, `lib/repository/services/rest/{rest,rest_client_provider,auth_interceptor}.dart`, `lib/config/env_config.dart`, `lib/models/{user,character/*,enums/*}.dart`, `lib/screens/mainScreen/main_screen.dart`, `lib/shared/components/*`, `lib/theme/kg_theme.dart`, `test/**`
- Backend repo: `src/rest/cloudinary/cloudinary.{controller,service}.ts`, `src/main.ts`, `src/models/enums/*.enum.ts`, `src/auth/format-auth-error.ts`, `src/schema.gql`, `.planning/phases/02.1-character-creation-contract/02.1-CONTEXT.md`
- pub.dev API (versions + SDK constraints) for image_picker, image_picker_android, image_picker_ios, image_picker_platform_interface
- Package sources downloaded from pub.dev archives: image_picker 1.2.2 (`pickImage` signature/docs), image_picker_android 0.8.13+17 (README Photo Picker, minSdk 24, error codes), image_picker_ios 0.8.13+3 (iOS 13.0, error codes)
- Pub cache sources: dio 5.8.0+1 (`_transformData`, io_adapter timeouts), gql_http_link 1.1.0, gql_link `ServerException`, graphql 5.2.1
- Flutter 3.35.5 SDK sources: `LengthLimitingTextInputFormatter`, `FlutterExtension.kt` (`minSdkVersion = 24`), engine `TextInputPlugin.java` (`IME_FLAG_NO_FULLSCREEN`)
- Commands: `flutter --version`, `flutter doctor`, `flutter analyze`, `flutter test`, `flutter pub add image_picker --dry-run` (scratch copy), Dart regex run

### Secondary (MEDIUM confidence)
- https://pub.dev/packages/image_picker/versions/1.2.2 — iOS plist keys, Android notes, `retrieveLostData`
- GraphQL spec (Enums — Input Coercion) for string variable values coerced to enums

### Tertiary (LOW confidence)
- Apollo Server 4 HTTP status for `BAD_USER_INPUT` (A1); BE length counting (A2)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — versions resolved against the actual SDK on a scratch copy
- Architecture: HIGH — every integration point read in source; the four defects reproduced by reading code paths
- Pitfalls: HIGH for 1–3, 7, 9–12 (code-verified); MEDIUM for 4–6, 8 (library behaviour verified, server behaviour assumed)
- Backend contract: MEDIUM — decided in BE 2.1 CONTEXT, not yet implemented

**Research date:** 2026-10-09
**Valid until:** 2026-11-08 (30 days; re-check image_picker resolution if Flutter is upgraded, and the BE schema once 2.1 lands)
