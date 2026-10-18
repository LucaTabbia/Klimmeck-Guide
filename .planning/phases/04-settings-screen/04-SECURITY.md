---
phase: 4
slug: settings-screen
status: verified
threats_open: 0
asvs_level: 1
created: 2026-10-18
---

# Phase 4 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.
> Source: `<threat_model>` blocks of plans 04-01..04-07 (29 threats). Audit state: HEAD `24478b6` on `feat/04-settings-screen` (includes review fixes `17691ab`, `4f790a6`, `5a4da3a`, `3525f8f`, `82a5213`, `2bcfcb8`). E2E evidence: 04-HUMAN-UAT.md (approved by the user, physical Android device, 2026-10-18, steps 1-10 pass). Targeted `flutter test` over the Phase 4 suites: all passed.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| Layout table <-> PageView | Page indices emitted by the satchel menu must exist in `MainScreen._buildPages` | Page indices |
| App <-> Cloudinary CDN | Settings icon SVG fetched by URL | Public asset |
| User tap <-> destructive action | Deletion and logout pass an explicit confirmation dialog on the root Navigator | bool result |
| App <-> device storage | Notification preferences in plain `SharedPreferencesAsync` (non-secret UI state) | Per-user boolean toggles |
| Account A <-> account B (same device) | Preference keys isolate users | Key namespace `klimmeck.notifications.<userId>.*` |
| Session teardown <-> preferences | Logout/sync-lost clear secure storage only, never preferences | Lifecycle |
| App -> backend GraphQL | `deleteCharacter` carries the session bearer; BE is the authority on identity | Bearer, no arguments |
| Backend response -> app | Payload and `extensions.code` are untrusted, parsed at one boundary | User payload, error codes |
| Mutation response -> session state | Only `adoptUser` (id-guarded) may change the session user | User |
| Session subtree lifetime | Settings cubits live and die with the authenticated shell | Cubit lifetime |
| FE documents <-> BE schema / FE PR <-> BE PR | Contract drift and merge ordering | Operation documents |

---

## Threat Register

Verification: every `mitigate` threat confirmed by reading the cited code and tests (all green in the targeted run). Review-fix strengthening is noted where it applies.

| Threat ID | Category | Component | Sev | Disposition | Mitigation evidence | Status |
|-----------|----------|-----------|-----|-------------|---------------------|--------|
| T-04-01-01 | Denial of service | overlay on narrow screens | low | mitigate | `cellWidth` = `min(maxCellWidth, (w - closeColumnWidth)/columns)` lib/screens/mainScreen/components/satchel_layout.dart:98-99; tests satchel_layout_test.dart:82 (shrinks on narrow), :119 (last column fits 667x375) | closed |
| T-04-01-02 | Tampering | menu/page/icon drift | low | mitigate | Single table `SatchelLayout.entries` satchel_layout.dart:45-96; tests satchel_layout_test.dart:13 (pageIndex 0..6), :54 (cell occupancy), :69 (asset mapping); `assert(pages.length == SatchelLayout.entries.length)` lib/screens/mainScreen/main_screen.dart:144-145 | closed |
| T-04-01-03 | Information disclosure | Settings asset path | low | accept | AR-01 (public CDN asset) | closed |
| T-04-02-01 | Tampering | accidental destructive action | med | mitigate | `barrierDismissible: false` lib/shared/components/modal/destructive_confirmation_dialog.dart:57; 'Annulla' first (:25-33), confirm second (:34-43); tests destructive_confirmation_dialog_test.dart:32 (order), :44 (barrier tap keeps dialog open), :54 (Annulla -> false), :64 (confirm -> true) | closed |
| T-04-02-02 | EoP / DoS | dialog reading shell cubit | low | mitigate | Dialog imports only `material.dart` and the theme, returns `bool` (destructive_confirmation_dialog.dart:1-2,49-64); the caller reads the cubit before the await (account_section.dart:68); dialog tests pump without any provider (destructive_confirmation_dialog_test.dart:32-76) | closed |
| T-04-02-03 | Information disclosure | character name in dialog | low | accept | AR-02 (name of the caller's own character) | closed |
| T-04-03-01 | Information disclosure | toggles leaking across accounts | med | mitigate | `keyFor` = `klimmeck.notifications.<userId>.<storageKey>` lib/repository/storage/notification_preferences_store.dart:28-31; tests notification_preferences_store_test.dart:19 (key), :83 (users do not share toggles); cubit test notification_preferences_cubit_test.dart:65 (ignores other users) | closed |
| T-04-03-02 | Tampering / Repudiation | prefs wiped by logout/teardown | med | mitigate | Namespace distinct from `klimmeck.session.`; interface exposes only `isEnabled`/`readAll`/`setEnabled`, no clear/remove (notification_preferences_store.dart:7-17); test notification_preferences_store_test.dart:29 (outside session namespace); shell test authenticated_shell_test.dart:176 (cubits closed on removal, store kept); UAT steps 3-4 (logout/login keeps toggles) | closed |
| T-04-03-03 | Information disclosure | logging user id / values | low | mitigate | Only `error.runtimeType` is logged notification_preferences_cubit.dart:32,50-52; `_userId` is never interpolated in any log (grep on settings/ and store: no match). Strengthened by `3525f8f` (rollback to last persisted value, WR-02, no new logging) | closed |
| T-04-03-04 | Tampering | locally tampered wrong-type value | low | mitigate | `getBool` TypeError propagates from the store (notification_preferences_store.dart:37-39); test notification_preferences_store_test.dart:103; cubit catch falls back to defaults notification_preferences_cubit.dart:31-34, test notification_preferences_cubit_test.dart:84 | closed |
| T-04-03-05 | Tampering | stale value in another isolate | low | mitigate | `SharedPreferencesAsync` notification_preferences_store.dart:2,26,34; no `SharedPreferences.getInstance` in the store or settings code (grep clean) | closed |
| T-04-04-01 | EoP / Spoofing | deleting another user's character | high | mitigate | Document `mutation DeleteCharacter { deleteCharacter { ...UserFields } }` has no arguments/variables lib/graphql/mutations/character_mutations.dart:15-23; `deleteCharacter()` sends no variables lib/repository/services/graphql/graphql.dart:414-418; tests graphql/character_deletion_document_test.dart:16,22, graphql_character_deletion_test.dart:39. Identity from the bearer only (BE 03.1 contract, BACKEND-NOTES:52) | closed |
| T-04-04-02 | Information disclosure | server message text shown/logged | med | mitigate | Mapping reads only `graphQlErrorCode` lib/repository/character_deletion_failure.dart:29-42; test character_deletion_failure_test.dart:47 (never reads message text); UI copy is fixed (character_deletion_messages.dart:4-13); no payload logging (grep: no print/debugPrint in the deletion path) | closed |
| T-04-04-03 | DoS (self) / Tampering | double tap / retry storm | med | mitigate | `if (isClosed \|\| state.isDeleting) return;` lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart:20; tests character_deletion_cubit_test.dart:147 (second call in flight ignored), :168 (closed cubit does not call the repository); notFound handled as refetch :45-51, test :57. Strengthened by WR-01 (`17691ab` test, `4f790a6` fix) and account_section.dart:73 `!cubit.isClosed`, test account_section_test.dart:111 | closed |
| T-04-04-04 | Tampering | malformed response payload | low | mitigate | `_userFrom` -> FormatException graphql.dart:434-440 (`_userFrom` boundary); repository maps FormatException to `unknown` character_deletion_repository.dart:23-25; tests graphql_character_deletion_test.dart:74,83, character_deletion_repository_test.dart:54 | closed |
| T-04-04-05 | Tampering | FE/BE contract drift | high | mitigate | `'DeleteCharacter': CharacterMutations.deleteCharacter` tool/schema_check/schema_check_documents.dart:34; suite-enforced by test/tool/schema_check_documents_test.dart (completeness, passes) and graphql/character_deletion_document_test.dart:37; graphql-js validation 25/25 OK against BE `origin/develop` @ `d578ad2` (04-07-SUMMARY.md:25) | closed |
| T-04-04-06 | DoS | cubit stuck in `isDeleting` | low | mitigate | Catch-all -> `unknown` character_deletion_cubit.dart:39-42; refetch failure/wrong state -> `unknown` :48-60; tests character_deletion_cubit_test.dart:75,90,109,123 | closed |
| T-04-05-01 | Spoofing | response of another identity adopted | high | mitigate | Hand-over only through `AuthCubit.adoptUser` lib/screens/auth/authenticated_shell.dart:117-123; guard `user.id != _user?.id` -> false session_auth_token_service.dart:198-200 (dev service dev_auth_token_service.dart:104-107); refusal -> `handoverRejected` (shell test authenticated_shell_test.dart:237; cubit test character_deletion_cubit_test.dart:197); regression tests session_auth_token_service_adopt_user_test.dart, dev_auth_token_service_transitions_test.dart | closed |
| T-04-05-02 | Information disclosure | late deletion response in a new session | med | mitigate | Cubits created in the shell's `MultiBlocProvider` (authenticated_shell.dart:89-99), shell keyed `ValueKey(user.id)` auth_gate.dart:51 and `character:<id>` session_home.dart:28; closed on removal, test authenticated_shell_test.dart:176-201; `SafeEmit` + `isClosed` guards, tests character_deletion_cubit_test.dart:168,178 | closed |
| T-04-05-03 | Information disclosure | preferences cubit bound to wrong user | med | mitigate | `userId: userId` passed from the session user into the shell and cubit authenticated_shell.dart:50,89-94; test authenticated_shell_test.dart:152 (preferences loaded for the user) | closed |
| T-04-05-04 | DoS | hand-over lost on Settings dispose | low | mitigate | `BlocListener<CharacterDeletionCubit>` at shell level, not in the PageView page authenticated_shell.dart:101-109; test authenticated_shell_test.dart:227 (hands the user over once); `userUpdated` backup (Phase 3, 03-SECURITY.md T-03-03-01); UAT step 10 (userUpdated backup path, pass) | closed |
| T-04-06-01 | Tampering | accidental / repeated deletion | high | mitigate | Confirmation before `deleteCharacter` account_section.dart:67-74; `onPressed: null` while `isDeleting` :24-26; tests account_section_test.dart:82 (cancel does not delete), :100 (once), :136 (disabled with progress, `onPressed` null :145); outlined style distinct from 'Esci', above it (:22-23,51-53; test :62). Strengthened by WR-01 (`17691ab`, `4f790a6`): cubit guard :20 and `!cubit.isClosed` :73, tests account_section_test.dart:111, character_deletion_cubit_test.dart:168 | closed |
| T-04-06-02 | Information disclosure | technical error text inline | med | mitigate | `CharacterDeletionFailureMessage` fixed Italian copy character_deletion_messages.dart:4-13; account_section.dart:42-49 renders `failure.message` only; `OperationException` absent from settings/ (grep clean); tests account_section_test.dart:173,183 | closed |
| T-04-06-03 | Spoofing / Repudiation | logout bypassing confirmation | low | mitigate | 'Esci' -> `confirmLogout(context)` account_section.dart:53; test account_section_test.dart:192 (logout only after dialog confirm); logout dialog tests test/shared/components/modal/logout_confirmation_dialog_test.dart (pass). `82a5213` removed only the dead `LogoutConfirmationDialog` class; `showLogoutConfirmationDialog`/`confirmLogout` kept | closed |
| T-04-06-04 | DoS (UX rule 2) | blocking spinner while preferences load | low | mitigate | Switches inert until loaded, no progress indicator: test notification_preferences_section_test.dart:104; the cubit emits no loading state (notification_preferences_cubit.dart:22-35); only spinner is the in-button progress after explicit deletion (account_section.dart:27-34, test :136) | closed |
| T-04-07-01 | Tampering | FE/BE contract drift | high | mitigate | graphql-js validation of all 25 documents against `origin/develop:src/schema.gql` @ `d578ad2`, `deleteCharacter: User!` at line 289 (04-07-SUMMARY.md:19,25; 04-VERIFICATION.md SC5, BACKEND-NOTES §6) | closed |
| T-04-07-02 | EoP | FE merged before the backend | high | mitigate | Gate confirmed on BE `origin/develop` (Merge PR #6, feat/03.1-character-deletion-contract) before E2E (04-07-SUMMARY.md:25,60); FE PR not opened by this plan (opened by the user) | closed |
| T-04-07-03 | Information disclosure | UAT/notes content | med | mitigate | Grep of 04-HUMAN-UAT.md and BACKEND-NOTES.md for JWT/`Bearer <value>`/connection strings/secret: no values found (only the word "bearer" in prose) | closed |
| T-04-07-04 | DoS | archived names still reserved | med | mitigate | UAT prerequisite checks the BE boot log for the legacy index drop (04-HUMAN-UAT.md:13); UAT step 9 "same-name recreate" pass (04-HUMAN-UAT.md:65-68); step 8 Mongo archive pass. Production Mongo privilege remains a BE deploy concern (BE notes §9) | closed |

*Status: open · closed*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*

### Informational notes

- Unregistered threat flags: none. Summaries 03, 04, 05 report "None"; 06 reports "None" with the mitigations T-04-06-01..04 implemented; the remaining summaries have no Threat Flags section.
- Review fixes: WR-01 (`17691ab`, `4f790a6`) strengthens T-04-04-03 and T-04-06-01; WR-02 (`5a4da3a`, `3525f8f`) strengthens T-04-03-03's neighbouring write-failure path (UI cannot diverge from the stored value). IN-02 (`2bcfcb8`) single default, IN-01 (`82a5213`) dead-code removal: no control weakened.
- Deferred/accepted review items (no register impact): IN-03 (unexpected errors not forwarded to `addError`), IN-04 (failed preferences read shows all-on by design, D-12).
- Residuals recorded in the plans: BE-side ownership enforcement (BE 03.1 tests), real-device isolate behaviour of `SharedPreferencesAsync` verified in Phase 5, screens narrower than 552 px not supported, UAT optional steps 11-12 not reported.

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-01 | T-04-01-03 | `settings_linee3.svg` is a public CDN asset (HTTP 200 verified); `CachedSvg` shows an empty box if missing. Residual: none | User via phase plan 04-01 | 2026-10-18 |
| AR-02 | T-04-02-03 | The character name shown in the confirmation dialog is the caller's own, already on screen. Residual: none | User via phase plan 04-02 | 2026-10-18 |

*Accepted risks do not resurface in future audit runs.*

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-10-18 | 29 | 29 | 0 | gsd-security-auditor (sonnet) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-10-18
