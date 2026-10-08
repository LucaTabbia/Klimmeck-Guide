# Phase 2: Character Creation - Context

**Gathered:** 2026-10-08
**Status:** Ready for planning

<domain>
## Phase Boundary

A signed-in user whose `User.currentCharacter == null` lands on a **character creation page right after login**, instead of the main tab shell. The page has a **provisional layout** (the user's words: "layout provvisorio") where the player enters sex, name, pronoun, race, class, age (bounded by the chosen race), an optional short background story, and may optionally pick a portrait from the device gallery/camera. On "Crea" the portrait (if any) is uploaded to Cloudinary through the existing authenticated REST endpoint, then a new backend mutation creates the character server-side and populates `User.currentCharacter`; the app then enters the main tab shell.

**This phase also delivers the backend side** (user directive 2026-10-08: *"Lavora anche sul BE seguendo il piano presente anche là. Hai accesso alla directory."*). The backend today has **no character-creation mutation** and **no race/age table**: both are built in the backend repo through its own GSD workflow (see D-20..D-24), and the frontend consumes the resulting contract.

Out of scope for this phase (explicitly deferred by the user, see `<deferred>`): curated portrait set, NSFW pre-screen (on-device or server), multi-step wizard, final polished layout.

</domain>

<decisions>
## Implementation Decisions

### Routing & transition (CHAR-01, CHAR-07)
- **D-01:** The `currentCharacter == null` branch lives where `AuthGate` hands over to the authenticated subtree (`main.dart` `authenticatedBuilder`): `user.currentCharacter == null` → the character creation screen; otherwise → `AuthenticatedShell` as today. No new routing table, no logic inside `AuthGate` itself (ui-ux rule: guards are widgets, not scattered logic).
- **D-02:** After a successful creation the app enters the main shell **directly** — no welcome/intermediate screen. The transition is driven by the same state that routed into the page: `AuthCubit`'s authenticated `User` gains a populated `currentCharacter` and the gate rebuilds into `AuthenticatedShell`. The mutation returns the updated `User` (D-21) so no extra round trip is needed. Exact mechanism (an `AuthCubit` method that replaces the current user vs re-running `me`) is Claude's discretion; constraints: no polling, no re-login, no blocking overlay.
- **D-03:** The dev bypass is unchanged: the backend dev user is born with `currentCharacter: null`, so in dev the creation page shows at cold start until a character exists. This is the intended manual test path (no extra `DEV_AUTH_*` knob).

### Page structure & style (CHAR-08, utility screen)
- **D-04:** **Single scrollable page**, not a wizard. The app is landscape-only: portrait column on the left, fields on the right. CHAR-08 ("back navigation preserves data") is satisfied trivially: there is one page and entered data is never discarded on validation or submit errors.
- **D-05:** **No confirmation dialog.** A single "Crea" button at the bottom, enabled only when every required field is valid. While submitting, the button shows its own inline progress and the form locks; nothing full-screen.
- **D-06:** Style: **"scheda personaggio" on parchment** — parchment background, Cinzel titles, fields laid out as rows of a game character sheet. All colors/typography/spacing from `lib/theme/kg_theme.dart` (tokens listed in `11-UI-SPEC.md`), never inline. Chrome is allowed (creation is a utility screen) but the sheet look wins over stock Material where they conflict. It is still a *provisional* layout: aim for coherent and clean, not pixel-perfect.
- **D-07:** An **"Esci" action in the top bar** lets the user log out / switch account from this page. It reuses `AuthCubit.logout()` and the existing `LogoutConfirmationDialog` (both tested, today unreachable from the game).

### Fields & validation (CHAR-02, CHAR-03, CHAR-04)
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

### Portrait (CHAR-05)
- **D-14:** Portrait is **optional**. When absent, the default image is the bundled asset **`assets/images/placeholders/silhouette.jpeg`** — shown as the sheet's portrait preview and wherever a character image is rendered with `imagePath == null` (the backend's `imagePath` is already nullable). Introduce one place that resolves "imagePath or silhouette" rather than sprinkling the fallback.
- **D-15:** Source: **device gallery / camera upload only**. No curated set in this phase (deferred). Picker package (`image_picker` or equivalent) and platform setup (iOS `Info.plist` usage descriptions, Android photo picker) are researcher/planner decisions and explicit Wave 0 tasks, as in Phase 11 D-34.
- **D-16:** **Upload happens at submit**, not at pick time: the picked file stays local (preview from file) until "Crea". Submit sequence: (1) if a file was picked, `POST /cloudinary/uploadImage` → URL (the endpoint exists, authenticated, folder `characters_profile`); (2) `createCharacter` mutation with `imagePath = URL` (or null). Upload failure → inline error, mutation not sent, data preserved. Mutation failure after a successful upload → inline error, keep the URL in memory so a retry does not re-upload. Orphaned Cloudinary files are accepted for now.
- **D-17:** **No NSFW filter in this phase** — neither on-device nor server-side. CHAR-06 is explicitly deferred by the user (see `<deferred>`); the first plan must mark CHAR-06 as deferred in `.planning/REQUIREMENTS.md` and `ROADMAP.md` so verification does not count it against this phase.

### Error display (CHAR-09)
- **D-18:** Errors are **inline on the page** using the `errorText` style (same as `SignInScreen`, Phase 11 D-22): field-level validation under the field; submit errors (upload failed, name taken, age out of range, generic server error) in a notice next to the "Crea" button. Copy in Italian and in the game's voice (the "shop pattern" the requirement refers to is: domain-language message, non-blocking, never a technical string). Entered data is always preserved.
- **D-19:** Backend errors are mapped by **stable `extensions.code`** values (D-22), never by message text.

### Backend work (user directive — built in this effort)
- **D-20:** The backend part is delivered in the backend repo (`/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`) **through its own GSD workflow**: insert a decimal phase **02.1 "Character Creation Contract"** between BE Phase 2 (complete) and BE Phase 3 (not started) — done 2026-10-09, branch `feat/02.1-character-creation-contract` per the BE template `feat/{phase}-{slug}`, discuss → plan → execute → PR to `develop`. The answers captured here are carried into the BE 2.1 context so the user is not asked twice. The FE plans that touch the network depend on that contract (locally runnable BE is enough; staging is not required for this phase).
- **D-21:** Proposed contract (fixed in the BE 2.1 context; `src/schema.gql` wins once generated): mutation **`createCharacter(input: CreateCharacterInput!): User!`** acting on the **authenticated identity** (no `userId` argument; one character per user — a second call while `currentCharacter` is set fails). Input: `name`, `sex`, `pronoun`, `race`, `classType`, `age`, `background` (optional), `imagePath` (optional URL). Returns the updated `User` with `currentCharacter { id … }`. Query **`raceTraits`** (D-11). Initial character state is **backend business**, decided in the BE 2.1 discuss (2026-10-09): level 1, title `rookie`, 0 XP, 100/100 HP, 5 silver, no equipment/items/spells; starting location = the `markerLocation` of the race's home city (elf → `elfCapital`; gnome/dwarf/tiefling → `motherCapital`; halfling → `liberiaCapital`; aarakocra → `aarakocraVillage`; dragonborn → `mountainVillage`; human/halfelf → random among `drusteaCapital`, `valanCapital`, `mirwaCapital`, `liberiaCapital`). The app never computes any of this.
- **D-22:** Stable error codes in `errors[0].extensions.code`, mirrored by the app: `CHARACTER_NAME_INVALID`, `CHARACTER_NAME_TAKEN`, `CHARACTER_AGE_OUT_OF_RANGE`, `CHARACTER_ALREADY_EXISTS`, `STARTING_LOCATION_UNAVAILABLE` (no home city seeded for the race), plus the generic validation failure. Fixed in the BE 2.1 context (`Klimmeck-Guide-BE/.planning/phases/02.1-character-creation-contract/02.1-CONTEXT.md` D-04); `src/schema.gql` wins once generated.
- **D-23:** Server-side validation duplicates nothing the client "owns": the backend is authoritative for every rule (name charset/length/uniqueness, age-by-race, background length, enum membership). The client's live validation is UX only.
- **D-24:** The existing REST upload (`POST /cloudinary/uploadImage`, bearer required since BE Phase 2) is reused as-is; an upload size limit / client-side downscale is Claude's discretion.

### Formatting discipline (carried from Phase 11 D-38)
- **D-25:** Never run `dart format` on directories; format only files a task creates or modifies and verify with `dart format --output=none --set-exit-if-changed <files>`. Same caution in the BE: `npx prettier --write <file>` + `npx eslint <file>` on touched files only (never `npm run lint`).

### Claude's Discretion
- Exact `AuthCubit` mechanism to adopt the post-creation `User` (D-02).
- Picker package, image downscale/compression and max upload size (D-15, D-24); whether to show a simple square-cropped preview (`BoxFit.cover`) — no crop tool required.
- Backend: `background` nullable vs empty string; initial character defaults; whether `raceTraits` is a plain query or enum metadata.
- Behaviour details when the race changes after an age was typed (D-10 fixes "show error, don't clamp").
- Feature folder/class names per `docs/rules/naming.md` (e.g. `lib/screens/characterCreation/` + `CharacterCreationScreen` + `CharacterCreationCubit`); the unused `lib/screens/onBoarding/` placeholder is left alone (onboarding is a deferred Phase 11 idea).
- Whether a light `02-UI-SPEC.md` is produced for the provisional layout (recommended: yes, short, tokens only).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract (source of truth once it exists)
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` — generated GraphQL schema. Today it has **no** `createCharacter`; `CharacterInfos` is `{ age: Int!, background: String!, classType: String!, imagePath: String, name: String!, pronoun: String!, race: String!, sex: String! }`. **Wins over anything written here once BE 2.1 lands.**
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02.1-character-creation-contract/02.1-CONTEXT.md` — the BE phase this context asks for (inserted 2026-10-09; decisions D-01..D-15: contract, validation, lore-aligned age table, starting state). Its plans and `BACKEND-NOTES.md` land in the same directory.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/02-auth-identity-foundation/BACKEND-NOTES.md` — bearer on GraphQL HTTP, REST (Cloudinary included) and WS; dev bypass; error-code conventions.
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/rest/cloudinary/cloudinary.controller.ts` and `cloudinary.service.ts` — `POST /cloudinary/uploadImage` (multipart field `file`, folder `characters_profile`, returns `{ url }`).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/models/character/character-infos.model.ts`, `character.model.ts`, `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/users/users.service.ts` — current shapes and the user upsert (`currentCharacter: null` at birth).
- `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/CLAUDE.md`, `.planning/ROADMAP.md`, `.planning/config.json` — BE rules, phase list (Phase 3 next, not started), branch template `feat/{phase}-{slug}`.

### This phase (frontend)
- `.planning/phases/02-character-creation/BACKEND-NOTES.md` — the handoff for the BE agent: proposed contract, flows, error codes, open questions.
- `.planning/REQUIREMENTS.md` §"Character Creation" (CHAR-01..09; CHAR-06 deferred by D-17) and §"Domain Model Reference".
- `.planning/ROADMAP.md` §"Phase 2: Character Creation".
- `.planning/PROJECT.md` — vision, constraints, key decisions.

### Project rules
- `docs/rules/architecture.md`, `docs/rules/naming.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/workflow.md`, `docs/rules/assets.md`.

### Prior phases
- `.planning/phases/11-auth-session-bootstrap/11-CONTEXT.md` — D-01/D-03 (providers, no service locator), D-22 (inline errors on utility screens), D-24/D-29 (dev bypass behaviour), D-34 (native prerequisites as Wave 0 tasks), D-38 (formatting discipline).
- `.planning/phases/11-auth-session-bootstrap/11-UI-SPEC.md` — design tokens (fonts, colors, spacing) to reuse for the sheet.
- `.planning/phases/01-dev-auth-stub/01-CONTEXT.md` — dev stub contract.

### Codebase maps
- `.planning/codebase/STRUCTURE.md`, `CONVENTIONS.md`, `ARCHITECTURE.md`, `TESTING.md`, `INTEGRATIONS.md`, `CONCERNS.md`.

### User-rule references (cross-session memory)
- `feedback_no_app_ui_chrome.md` — creation is a utility screen: chrome allowed.
- `feedback_no_blocking_loading_in_session.md` — no full-screen loading; submit progress stays on the button.
- `feedback_backend_handoff_per_phase.md` — keep this phase's `BACKEND-NOTES.md` current.
- `project_dart_format_baseline.md`, `feedback_commit_phase_scope.md`, `feedback_no_coauthored_by.md`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/auth/auth_gate.dart` — `AuthGate(authenticatedBuilder: (context, user) => …)`: the hook for D-01; `main.dart` is the only caller.
- `lib/screens/auth/cubit/auth_cubit.dart` — `logout()` (D-07) and the authenticated `User` to update after creation (D-02).
- `lib/shared/components/modal/logout_confirmation_dialog.dart` — reuse for "Esci".
- `lib/repository/services/rest/rest.dart` — `KlimmeckRest.uploadImage(File) → Future<String?>` already posts multipart to `uploadImage` and returns the URL (D-16). Note: the path is `uploadImage` relative to the dio base URL — verify it resolves to `/cloudinary/uploadImage`.
- `lib/repository/services/graphql/graphql.dart` — `KlimmeckGraphQl` facade: add `createCharacter` and `raceTraits`; documents go in `lib/graphql/mutations/character_mutations.dart` / `lib/graphql/queries/character_queries.dart`.
- `lib/models/character/character_infos.dart` + `lib/models/enums/{sex,pronoun,race,class}_type.dart` — fields and Italian `label` extensions (missing on `SexType`); `SexType.pawnPath` exists but D-14 uses the silhouette asset instead.
- `lib/models/user.dart` — `User.copyWith(currentCharacter: …)` already exists.
- `lib/shared/components/dropdown.dart`, `section.dart`, `text_section.dart`, `kg_error.dart` — candidates for the sheet rows.
- `lib/screens/onBoarding/components/on_boarding_card.dart` — fade-in card pattern (optional inspiration; the screen itself is a `Placeholder`).
- `assets/images/placeholders/silhouette.jpeg` — the default portrait (D-14); `assets/images/background.png`/`boardBackground.png` for parchment textures.
- `lib/screens/signIn/sign_in_screen.dart` — utility-screen reference: `Scaffold` + `AppBar`, inline `errorText` notices.
- Tests: `test/helpers/fakes/`, `test/helpers/fixtures/`, `bloc_test` + `mocktail` already in `dev_dependencies`; `test/screens/auth/` shows how the gate is tested with fakes.

### Established Patterns
- Cubit + Repository/Service, `SafeEmit` mixin, `RepositoryProvider` for app-wide singletons, no service locator.
- GraphQL documents as Dart strings under `lib/graphql/`; models are Flutter-free `Equatable` with manual `fromJson`/`toJson`.
- Utility screens use `Scaffold`/`AppBar` with theme tokens; gameplay screens never do.
- App is **landscape-only** (`SystemChrome.setPreferredOrientations` in `main.dart`).
- Inline, domain-language error copy; no snackbars with technical text.

### Integration Points
- `lib/main.dart` → `AuthGate.authenticatedBuilder`: branch on `user.currentCharacter` (D-01).
- `AuthCubit`: a way to adopt the `User` returned by `createCharacter` (D-02).
- `pubspec.yaml`: image picker dependency; `ios/Runner/Info.plist` usage descriptions; Android manifest only if the chosen picker needs it (Wave 0, D-15).
- Backend: new `createCharacter` mutation + `raceTraits` query + validation + stable error codes (BE Phase 2.1, D-20..D-23).

### New Code Required
- `CharacterCreationScreen` (+ cubit/state, components for sheet rows, portrait picker column) under `lib/screens/characterCreation/`.
- Models: `CreateCharacterInput`-like request model, `RaceTraits` model, `SexType.label`.
- `KlimmeckGraphQl.createCharacter`, `KlimmeckGraphQl.raceTraits`; picker wrapper injectable for tests.
- A single "portrait or silhouette" resolver used by the sheet (and reusable by profile later).

</code_context>

<specifics>
## Specific Ideas

- User directive (verbatim, 2026-10-08): *"Crea anche una pagina subito dopo la login con un layout provvisorio. L'utente può inserire sesso, caricare un'immagine (deve andare in store su cloudinary), nome, pronomi, tipo classe, anni e avere la possibilità di scrivere una breve storia di background."* Race added on confirmation.
- Default portrait: `assets/images/placeholders/silhouette.jpeg` (user-specified path).
- Button copy: "Crea". Top-bar action: "Esci" (reusing the "Sei sicuro di voler uscire?" dialog).
- Name-taken copy: "Nome già in uso".
- The sheet should read like a D&D character sheet on parchment, titles in Cinzel.

</specifics>

<deferred>
## Deferred Ideas

- **Curated portrait set** (Cloudinary folder or bundled assets) — CHAR-05 "pick from a curated set" half is deferred; only upload ships now.
- **NSFW pre-screen on-device and authoritative server check (CHAR-06)** — explicitly deferred by the user ("Nessun filtro per ora"). Candidates: BE Phase 10 (Hardening) with Cloudinary AI moderation, FE Phase 12. The first FE plan marks CHAR-06 as deferred in REQUIREMENTS/ROADMAP (D-17).
- **Multi-step wizard** with back navigation — replaced by the single page (D-04).
- **Final, non-provisional layout** for the creation sheet — later polish pass.
- **Dev reset of the character** to re-run the flow without touching Mongo by hand.
- **Welcome screen after creation** — rejected for now (D-02).
- **Onboarding screens before sign-in** — already deferred in Phase 11.

</deferred>

---

*Phase: 02-character-creation*
*Context gathered: 2026-10-08*
