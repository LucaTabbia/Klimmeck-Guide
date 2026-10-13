---
phase: 2
slug: character-creation
status: verified
threats_open: 0
asvs_level: 1
created: 2026-10-13
---

# Phase 2 - Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| repo to VCS | Config files committed must carry no secrets | `.env` (git-ignored), `.env.example` placeholders only |
| device OS to app | Photo/camera access via OS usage descriptions | user photo (local file) |
| user input to request | Name, background, age, enum picks become mutation variables | free text, PII-light |
| app to backend REST | Multipart portrait upload with session bearer | user image, bearer token |
| app to GraphQL API | `createCharacter` / `me` / `raceTraits` over authenticated client | variables map, error codes |
| backend response to app | `url`, `User`, error payloads enter state/session | Cloudinary URL, User |
| remote URL / device file to image decoder | Portrait decode | image bytes |
| session user to routing/gameplay | `currentCharacter` decides creation vs shell | character id |
| app contract to backend schema | Names of fields/enums/codes must match | schema |

---

## Threat Register

| Threat ID | Category | Component | Disposition | Mitigation / Evidence | Status |
|-----------|----------|-----------|-------------|-----------------------|--------|
| T-02-01-01 | Info disclosure | pubspec/.env, Info.plist | mitigate | `.env` ignored (`git check-ignore .env` = match); only `.env.example` tracked, placeholder values only (`.env.example`); `.env` declared once in pubspec.yaml:82; no token/key patterns in lib/test/phase docs (grep) | closed |
| T-02-01-02 | Elev. of privilege | iOS usage descriptions | mitigate | ios/Runner/Info.plist:48-51 only NSCameraUsageDescription + NSPhotoLibraryUsageDescription, single-purpose Italian copy; no PhotoLibraryAdd; no STORAGE/READ_MEDIA in AndroidManifest | closed |
| T-02-01-03 | Tampering | dependency supply chain | mitigate | pubspec.yaml:54 `image_picker: ^1.2.2`; pubspec.lock:819-826 hosted pub.dev, version 1.2.2 with sha256 | closed |
| T-02-01-04 | Repudiation | CHAR-06 deferred | accept | Accepted risk AR-01; REQUIREMENTS.md CHAR-06 marked DEFERRED (line 55, 204) | closed |
| T-02-02-01 | Spoofing | `adoptUser` | mitigate | session_auth_token_service.dart:183-190 (authenticated AND `user.id == _user?.id`); dev_auth_token_service.dart:92-101; covered by test/screens/auth + test/repository suites (green) | closed |
| T-02-02-02 | Tampering | token on re-emit | mitigate | `adoptUser(User)` takes no token; dev service re-emits `current.accessToken` (dev_auth_token_service.dart:98); session service `_emitAuthenticated()` reuses held token | closed |
| T-02-02-03 | DoS (stuck UI) | `AuthGate._shouldRebuild` | mitigate | auth_gate.dart:66-76 `_changesCharacter` in rebuild rule; test auth_gate_test.dart "character gained gaining a character keeps root dialogs open" (green) | closed |
| T-02-02-04 | Info disclosure | logging | mitigate | No new debugPrint in adoptUser/creation code; remaining debugPrint in auth services are pre-existing and log `runtimeType` only | closed |
| T-02-03-01 | Tampering | `toJson` | mitigate | create_character_request.dart toJson returns variables map with enum `.name` and int age; no document interpolation | closed |
| T-02-03-02 | Elev. of privilege | client validation | accept | Accepted risk AR-03 (UX only, BE authoritative D-23) | closed |
| T-02-03-03 | DoS | oversized background | mitigate | character_draft.dart:45-47 `isBackgroundTooLong` on UTF-16 `trim().length`; blocks `isCompleteFor` (line 82) | closed |
| T-02-03-04 | Info disclosure | race table | mitigate | grep `9999` in lib: no race table authority copy (only unrelated aspect ratios); traits come from `raceTraits` query | closed |
| T-02-04-01 | DoS | `CharacterPortrait` decode | mitigate | character_portrait.dart:33-37 `errorBuilder` falls back to silhouette asset | closed |
| T-02-04-02 | Info disclosure | image error display | mitigate | errorBuilder renders no text; no debugPrint in character_portrait.dart | closed |
| T-02-04-03 | Tampering | remote image source | accept | Accepted risk AR-04 (backend Cloudinary URLs only; host allowlist is BE debt) | closed |
| T-02-05-01 | Spoofing | upload identity | mitigate | rest.dart upload via `RestClient.dio`; rest_client_provider.dart:25 adds AuthInterceptor; auth_interceptor.dart:46 sets `Authorization: Bearer`; test/repository/services/rest/rest_upload_test.dart | closed |
| T-02-05-02 | DoS / cost | unbounded file size | mitigate | image_picker_portrait_picker.dart:14-15,26-28 maxWidth/maxHeight 1024, imageQuality 85 | closed |
| T-02-05-03 | Info disclosure | EXIF/GPS | mitigate | image_picker_portrait_picker.dart:29 `requestFullMetadata: false` plus re-encode via imageQuality | closed |
| T-02-05-04 | Tampering | malformed upload response | mitigate | rest.dart:67-69 non-empty String `url` else `ImageUploadException`; rest_upload_test "throws ImageUploadException on a 2xx failure body / empty url / DioException on a 500" | closed |
| T-02-05-05 | Info disclosure | logs | mitigate | grep debugPrint in services/rest/rest.dart, services/image, repository, characterCreation: none | closed |
| T-02-05-06 | DoS | hanging upload | mitigate | rest.dart:48,63-64 30 s send/receive timeout | closed |
| T-02-05-07 | Repudiation | activity killed on camera | accept | Accepted risk AR-05 (documented in class doc) | closed |
| T-02-06-01 | Tampering | GraphQL documents | mitigate | character_mutations.dart static const document with `$input`; graphql.dart:384 `variables: {'input': request.toJson()}` | closed |
| T-02-06-02 | Info disclosure | error display | mitigate | character_creation_failure.dart:42-63 reads only `extensions.code`; unknown maps to `unknown`; no `.message` in mapper | closed |
| T-02-06-03 | Spoofing | mutation identity | mitigate | Input has no userId (create_character_request.dart); BE `CreateCharacterInput` (schema.gql:155-164) has none; call via authenticated client | closed |
| T-02-06-04 | DoS | unknown race from newer BE | mitigate | graphql.dart:370-376 `whereType<Map>().map(RaceTraits.tryFromJson).whereType<RaceTraits>()` skips unknown | closed |
| T-02-06-05 | Repudiation | `getMe` re-read | accept | Accepted risk AR-06 (read-only own identity) | closed |
| T-02-07-01 | Info disclosure | error propagation | mitigate | character_creation_repository.dart `_guard`/`uploadPortrait` emit only `CharacterCreationException(failure)`; cubit catch-all maps to `unknown`; state holds enums only | closed |
| T-02-07-02 | DoS | `loadRaceTraits` | mitigate | character_creation_cubit.dart:27-38 generic catch ends in `failed` | closed |
| T-02-07-03 | Tampering | pick-time upload | mitigate | `pickPortrait` (cubit) only stores local path; upload only inside `submit` via `_uploadedPortraitUrl`; verifyNever(uploadPortrait) test in test/screens/characterCreation (green) | closed |
| T-02-07-04 | Elev. of privilege | client validation | accept | Accepted risk AR-03 | closed |
| T-02-08-01 | DoS (stuck) | `submit` / ALREADY_EXISTS | mitigate | cubit `_createCharacter` catch-all, `_handleSubmitFailure`, `_existingCharacterOwner` (any failure -> notice), `_failSubmit` sets `isSubmitting: false`; plus `handoverRejected()` (WR-01); cubit tests green | closed |
| T-02-08-02 | Tampering | stale upload URL | mitigate | cubit `_uploadedPortraitUrl` reuses URL only if `uploaded.localPath == localPath` | closed |
| T-02-08-03 | Spoofing | adopting foreign user | mitigate | `createdUser` only from mutation / `me`; session guard (T-02-02-01) | closed |
| T-02-08-04 | DoS | double submit | mitigate | character_creation_state.dart:49-50 `canSubmit` false while submitting or after `createdUser`; submit_bar.dart `onPressed` gated | closed |
| T-02-08-05 | Info disclosure | error state | mitigate | state carries `CharacterCreationFailure` enums only | closed |
| T-02-08-06 | Repudiation | orphaned Cloudinary uploads | accept | Accepted risk AR-07 (D-16) | closed |
| T-02-09-01 | Info disclosure | error rendering | mitigate | widgets use enum `.message` extension (character_creation_messages.dart); grep shows no exception text in screen/components | closed |
| T-02-09-02 | Spoofing | adoptUser handover | mitigate | character_creation_screen.dart:50-56 `_handOverCreatedUser`; rejection calls `handoverRejected()` (WR-01 fix) | closed |
| T-02-09-03 | DoS (UX lock) | submit | mitigate | Progress only inside Crea button (submit_bar.dart); `canExit` (state:54) keeps Esci reachable once `createdUser` exists; 44 px target (WR-03) | closed |
| T-02-09-04 | Elev. of privilege | logout path | mitigate | character_creation_screen.dart:70 reuses `confirmLogout` (confirmation dialog) | closed |
| T-02-09-05 | Tampering | age input | mitigate | character_creation_screen.dart:224-225 `digitsOnly` + `LengthLimitingTextInputFormatter`; BE re-validates | closed |
| T-02-10-01 | Info disclosure | hardcoded character id | mitigate | session_home.dart:20-22 uses `user.currentCharacter.id`; grep for 24-hex ids / CHARACTER_ID in lib: none | closed |
| T-02-10-02 | Elev. of privilege | other user's character | transfer | Ownership checks are BE Phase 3 work (Transfer Log TR-01); app requests only own id | closed |
| T-02-10-03 | DoS (stuck page) | creation to shell swap | mitigate | SessionHome re-evaluates per build; AuthGate rebuilds on character change (auth_gate.dart:66-76) | closed |
| T-02-10-04 | Info disclosure | composition root secrets | mitigate | lib/main.dart only loads `.env` via dotenv; no inline keys/tokens (grep); IN-03 removed main.dart import from facade (grep `import.*main.dart` in lib: none) | closed |
| T-02-10-05 | DoS | profile portrait | mitigate | profile_image.dart:23 renders only through `CharacterPortrait`; no Image.network/CachedNetworkImage in profile or characterCreation | closed |
| T-02-11-01 | Tampering | contract drift | mitigate | Checked against BE src/schema.gql: `CreateCharacterInput` fields (155-164), `raceTraits`/`RaceTraits` (401, 439), `createCharacter` (288), enums Sex/Pronoun/Race/Class match app names | closed |
| T-02-11-02 | DoS (stuck) | ALREADY_EXISTS code | mitigate | `CHARACTER_ALREADY_EXISTS` and the other 4 codes exist in BE `CharacterCreationErrorCode`; recovery covered by cubit tests | closed |
| T-02-11-03 | Info disclosure | UAT notes | mitigate | 02-HUMAN-UAT.md records outcomes only; no tokens/signed URLs (grep) | closed |
| T-02-11-04 | Info disclosure | error copy | mitigate | UAT steps 3, 4, 7 passed (Italian domain messages); enum-only mapping verified in code | closed |
| T-02-11-05 | Elev. of privilege | merge before BE | mitigate | Process control: PR not opened in this phase (D-33); no evidence of a push or PR in repo state (clean tree, branch feat/character-creation) | closed |

*Status: open / closed*
*Disposition: mitigate (implementation required) / accept (documented risk) / transfer (third-party)*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-02-01-04 | NSFW pre-screen of portraits (CHAR-06) deferred; candidates BE Phase 10 (Cloudinary AI moderation) / FE Phase 12. Decision D-17 | user (Luca) | 2026-10-08 |
| AR-02 | (CHAR-05 curated half) | Curated portrait set deferred; users upload own photo or keep silhouette | user (Luca) | 2026-10-09 |
| AR-03 | T-02-03-02, T-02-07-04 | Client validation is UX only; backend re-validates (D-23) | plan decision | 2026-10-09 |
| AR-04 | T-02-04-03 | Remote image host allowlist is BE debt | plan decision | 2026-10-09 |
| AR-05 | T-02-05-07 | Android activity kill during camera, provisional layout | plan decision | 2026-10-09 |
| AR-06 | T-02-06-05 | Read-only `me` query | plan decision | 2026-10-09 |
| AR-07 | T-02-08-06 | Orphaned Cloudinary uploads accepted (D-16) | plan decision | 2026-10-09 |

## Transfer Log

| Ref | Threat | Transferred To | Documentation |
|-----|--------|----------------|---------------|
| TR-01 | T-02-10-02 | Backend Phase 3 ownership checks on `character(id)` | 02-10-PLAN.md threat model |

## Unregistered Flags

None. No `## Threat Flags` section in any 02-NN-SUMMARY.md (11 summaries checked).

## Observations (informational, not threats)

- graphql.dart:36-46 `getGenericErrorMessage` returns raw server/network text; pre-existing, not used by the character-creation path (which maps codes via `characterCreationFailureFrom`).
- DevAuth bypass logs a warning when active; ensure `DEV_AUTH_ENABLED=false` for release builds (pre-existing Phase 1 control).

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-13 | 52 | 52 | 0 | gsd-security-auditor (tests: characterCreation, repository, auth suites all green, 363 passed) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-13
