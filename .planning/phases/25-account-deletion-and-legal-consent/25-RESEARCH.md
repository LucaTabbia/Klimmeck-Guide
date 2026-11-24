# Phase 25: Account Deletion and Legal Consent - Research

**Researched:** 2026-11-24
**Domain:** Flutter auth/session teardown, Settings utility actions, login consent, GraphQL contract gating (↔ BE Phase 26)
**Confidence:** HIGH for the FE code paths (read and tested on this branch); MEDIUM for the BE-dependent parts (contract not written yet)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Carried forward (not re-asked)
- The backend is the source of truth (rule 4): the app only asks for the deletion and reacts. Settings and login are utility screens (chrome allowed).
- What is deleted and what stays is fixed by the roadmap goal and by `elimina-account.md`: user (Twitch ID, points balance), every character including the archived ones (progress, items, spells, companions, unlocked lore), portrait on Cloudinary, sessions, push devices; the innkeeper's action log (TTL 90 days) and the DB backups (30 days) stay until their TTL.
- Deletion is immediate and the player leaves the app at the confirmation (legal page, verbatim: «L'account viene eliminato subito e, alla conferma, esci dall'App»).
- Seats in lanes and requests are freed as the character archive does today (BE `CharacterArchiver`, `seat-release.ts`).
- Non-additive SDL changes are declared in the BE handoff; FE plans that select new fields are gated on the BE merge. One-off migrators leave the repo; no content file in either repo.

#### Confirmation and exit
- **D-01 (user, «Dialog semplice»):** one destructive dialog, same component and weight as «Elimina personaggio» (`showDestructiveConfirmation`): title, body, Annulla / Elimina. No typed word, no second dialog (the recommended typed word was rejected).
- **D-02 (user):** the «Elimina account» button is the last of the Account section, under «Esci», detached, red outline (order: Elimina personaggio → Esci → Elimina account).
- **D-03 (user):** after a successful deletion the player lands on the login with an inline notice above the login button, like the existing `SignInNotice` lines: «Il tuo account è stato eliminato.»
- **D-04 (user):** the same Twitch account may log in again at once and starts from zero (balance 0, no character, creation from scratch). The BE keeps no trace of the deleted Twitch ID and applies no wait.
- **D-05 (technical default):** the dialog text is written in-world by Claude and lists what is lost (all characters including the archived ones, the points balance, the portrait) and that converted channel points are not given back; it must not contradict `elimina-account.md`.
- **D-06 (technical default):** the local teardown after the deletion is the logout one (tokens, push registration, caches) plus the consent memory of D-10. A failed deletion keeps the player in Settings with an inline error under the button, as the character deletion does; the spinner on the button is an explicit user action (rule 2 respected).

#### Legal consent on the login
- **D-07 (user, «Frase con link, senza età»):** above the login button, one checkbox with the sentence «Accetto i Termini di servizio e l'Informativa sulla privacy», the two wordings tappable; the two links at the bottom of the login disappear. No mention of the minimum age in the sentence. The login button is disabled while the box is empty.
- **D-08:** «Termini di servizio» opens https://lucatabbia.github.io/klimmeck-guide-legal/termini and «Informativa sulla privacy» opens https://lucatabbia.github.io/klimmeck-guide-legal/privacy, in the external browser through the existing `LinkOpener` (technical default).
- **D-09 (user, «Sì, versione e data»):** the BE records on the user the accepted version of the documents and the date of the acceptance. The login carries the accepted version; a login without it is refused by the BE (the checkbox is not only a client-side gate). The privacy page must then mention this datum (a line in the legal repo, to be done with the phase).
- **D-10 (user, «Ricordata sul dispositivo»):** once accepted, the device remembers it: at the next logins on that phone the box starts already ticked. The memory is cleared when the account is deleted (technical default) and holds for one version of the documents: a new version starts unticked again.
- **D-11 (user, verbatim):** «Non è pubblicata l'app, caso impossibile» — there are no existing users with a live session to handle: no migration, no in-session acceptance page, no forced logout. The acceptance fields are simply required from this phase on (dev/test users in the DB are the orchestrator's concern at the real boot).
- **D-12 (technical default):** the version of the documents is one constant in the app, sent with the login; the BE stores what it receives with its own clock. No endpoint serving the current version, no re-acceptance flow (deferred).

#### Traces for the other players
- **D-13 (user, «Segnaposto anonimo»):** when the deleted player's character sits in a group quest already started, the seat stays occupied until the quest concludes, as for the archive, but with no name and no portrait: the party shows a fixed in-world wording («Un avventuriero scomparso»). The quest resolves with today's rules. Since the character document is really deleted, the placeholder must not depend on it.
- **D-14 (technical default):** everything else follows the archive: unstarted seats freed, GM requests of the character deleted, the wounded removed from open aid quests, rescuers released; a guided mission the innkeeper is running loses that participant as it would for an archived character. Quest results are one per character and per user: the deleted player's own are deleted, the others' carry no name of his (verified on `quest-result.model.ts`).

#### Deletion by the innkeeper and the innkeeper's own account
- **D-15 (user, «Azione nel pannello oste»):** in Settings → innkeeper section, a field for the Twitch username plus a confirmation; the BE resolves the username to the Twitch ID (it stores only the numeric ID) and runs the very same deletion, written in the innkeeper's action log. A player deleted while online goes back to the login with the notice of D-03 (technical default; if the revocation cannot tell the reason, the planner states the fallback). Unknown username or no account → an inline error, nothing deleted.
- **D-16 (user, «No, pulsante nascosto»):** the innkeeper cannot delete his own account from the app: «Elimina account» does not appear for the innkeeper role and the BE refuses the request (own mutation and the innkeeper action aimed at an innkeeper). The innkeeper's account is removed only by hand.

### Claude's Discretion
- Exact in-world wording of dialog, notice, errors and placeholder (within D-03, D-05, D-07, D-13 verbatim strings).
- Cubit/repository split, mutation and field names, error codes, where the consent memory is stored (`shared_preferences` is the natural place).
- Layout details of the checkbox row and of the innkeeper action (retouched on the device at UAT, as usual).

### Deferred Ideas (OUT OF SCOPE)
- Re-acceptance when terms or privacy change (the recorded version of D-09 is its base).
- A wait before the same Twitch account may register again.
- A stronger confirmation (typed word) for the deletion.
- Data export / portability from the app.
</user_constraints>

<phase_requirements>
## Phase Requirements

`REQUIREMENTS.md` has no IDs for Phase 25 yet and the ROADMAP says «Requirements: TBD» [VERIFIED: grep]. The IDs below are **proposals** for the planner/orchestrator to adopt or rename.

| ID (proposed) | Description | Research Support |
|----|-------------|------------------|
| ACCT-01 | «Elimina account» in Settings → Account (last, detached, red outline), hidden for the innkeeper; one destructive dialog; spinner and inline error on failure | Architecture §1, Pattern 1, Pattern 2; C1 |
| ACCT-02 | A successful deletion (own, or by the innkeeper while online) lands on the login with «Il tuo account è stato eliminato.»; local teardown without push unregister / BE logout; consent memory cleared | Architecture §2, Pattern 3, Pitfalls 1–3; C3 |
| ACCT-03 | Innkeeper action in Settings → «Locanda»: Twitch username + confirmation, distinct inline errors, success line | Architecture §4, Pattern 5; C5 |
| LEGAL-01 | Checkbox sentence with two tappable wordings opening the public pages; footer links removed; login disabled while unticked; device memory per document version | Architecture §3, Pattern 4 |
| LEGAL-02 | The login carries the accepted version (where the BE decides); the BE refusal is mapped; dev bypass behaviour stated | Architecture §3, «What the FE needs from the BE contract» |
| GATE-25 | Schema gate on the merged BE Phase 26 SDL (new documents + changed login document), registry count, schema check, full suite, device E2E, FE `BACKEND-NOTES.md` updated, legal repo line (D-09) | §6 Schema check, Validation Architecture |
</phase_requirements>

## Summary

Everything the phase needs on the FE already has a precedent in the code: the character deletion (`CharacterDeletionCubit` + `CharacterDeletionRepository` + `characterDeletionFailureFrom` + `showDestructiveConfirmation`) is the exact model for the own-account deletion; the revocation path (`SessionAuthTokenService._endSession(reason)` → `AuthUnauthenticated(reason)` → `AuthGate._noticeFor` → `SignInNotice`) is the exact model for the «account deleted» landing; `SessionTerminator.terminateSession(reason)` already gives a local teardown with a chosen reason and no backend call; the stores under `lib/repository/storage/` (all on `SharedPreferencesAsync`, faked by `FakeSharedPreferencesAsync`) are the model for the consent memory; `LinkOpener` is already injected into `SignInCubit`.

The single hard problem is a **race on the notice**. When the BE deletes the account it revokes every session and (by the BE Phase 17 design) closes the user's WebSocket with 4409. The app does not read the close reason: 4409 goes through `UnauthorizedRecovery` → refresh → rejection → `_endSession(<reason of the rejection>)`, and `_endSession` is single-flight, first reason wins. So the WS close may land the player on «La sessione è scaduta» before the mutation response lets the app call `terminateSession(accountDeleted)`. The robust fix is on the BE: a refresh after a deletion must be rejected as `SESSION_REVOKED` with `extensions.reason = "accountDeleted"` (today a refresh whose user is gone gives `sessionRevoked()` with no reason, and an unknown token gives `SESSION_EXPIRED` [VERIFIED: BE `auth-session.service.ts:62-65`, `auth-session.service.int-spec.ts:447`]). The same mechanism serves the innkeeper path (D-15) for free. If the BE cannot keep that record, the fallback is the session-expired notice for the innkeeper path, and an FE-side guard for the own path (see Pitfall 1).

The D-13 placeholder has **no FE surface today**: the app never draws a registrant's name or portrait; Board and quest sheet show only per-title counts (`2/3`), and quest results are one per character. What matters for the FE is that the seat keeps counting: if the BE keeps `QuestRegistration.character: ID!` as a dangling id, the FE changes nothing; if it sends `null`, `RegisteredAdventurer.from` drops the entry today and the seat silently disappears.

**Primary recommendation:** six plans — two against today's BE (consent UI + device memory; the `accountDeleted` reason/notice wiring), three that wait for the BE contract and are proved at a gate on the merged BE Phase 26 SDL (own deletion, innkeeper deletion, version carried by the login), one gate + device E2E.

## Contradictions with the CONTEXT

| # | CONTEXT says | Code says | Consequence for the plan |
|---|--------------|-----------|--------------------------|
| C1 | «Elimina account» lives in Settings (D-02); legal page: «Impostazioni → Elimina account» | Settings is a tab of `MainScreen`, mounted only by `AuthenticatedShell`, which `SessionHome` builds only when `user.currentCharacter != null` (`session_home.dart:25-27`). A user with no character (new account, or after «Elimina personaggio») sees only `CharacterCreationScreen`, whose AppBar has «Esci» and nothing else (`character_creation_screen.dart:58-80`) [VERIFIED: code] | Such a user cannot delete the account from the app, which the legal pages promise. **Product-owner question Q-PO1.** Recommendation: a second AppBar action «Elimina account» on the creation screen (utility screen, chrome allowed), same dialog and same cubit (the cubit then must be provided above `SessionHome`, not in the shell) |
| C2 | D-13: «the party shows a fixed in-world wording («Un avventuriero scomparso»)» | No FE widget lists registrants by name/portrait: `QuestSheetDetails.slotLines` and `questStateLabel` count `registeredAdventurers` per title (`quest_sheet_details.dart:99-105,204-236`, `quest_state_label.dart:46`); `RegisteredAdventurer` holds only `characterId` + `title` (`registered_adventurer.dart`); quest results carry only the owner's character. The only names of other characters are the innkeeper guided-mission participants (BE snapshot `participants { character name … }`), which D-14 says lose the deleted participant [VERIFIED: grep] | The wording is not rendered anywhere unless a new party list is wanted (out of scope by default). FE duty = keep the seat counted. If the BE sends `character: null`, `RegisteredAdventurer.from` (`{'character': final String characterId}` pattern) returns `null` and `listFrom` drops it → «2/3», `canRegisterWithTitle` says a seat is free while the BE refuses. **Q-PO2** (confirm no party list) + **Q-BE4** (keep `character: ID!` dangling) |
| C3 | D-06: «the local teardown after the deletion is the logout one (tokens, push registration, caches)» | `AuthCubit.logout()` first calls `PushSessionCleanup.unregister()` (an authenticated `unregisterPushDevice` mutation) and then `SessionAuthTokenService.logout()`, whose step 1 calls the BE `logout` mutation with the bearer (`auth_cubit.dart:55-58`, `session_auth_token_service.dart:174-179,507-515`). After a deletion both hit a dead session; the unregister's 401 enters `recoverFromUnauthorized` → refresh → rejection → `_endSession(sessionExpired)`, which **wins** the single-flight and shows the wrong notice | Use `SessionTerminator.terminateSession(UnauthenticatedReason.accountDeleted)`: same local teardown (GraphQL holder reset → WS disposed, secure store cleared, `AuthUnauthenticated` makes `PushRegistrationCoordinator._endSession` clear the active user and the tray), no unregister, no BE logout. The BE deletes the push devices itself (CONTEXT «Established Patterns»). Same intent as D-06, not the literal logout call |
| C4 | D-09/D-12: the login carries the accepted version | `AuthTokenService.login()` takes no argument and `login_exception.dart:3` documents «la firma `Future<void> login()` non cambia (D-02)» (Phase 11 D-02) [VERIFIED: code] | The contract changes to `login({required String acceptedLegalVersion})`: `SessionAuthTokenService`, `DevAuthTokenService`, `SignInCubit`, and 9 test files that stub `.login()` [VERIFIED: grep -l = 10 files incl. the doc comment]. Update the doc comment (Boy Scout) |
| C5 | D-15: «in Settings → innkeeper section, a field for the Twitch username» | The Settings tab has no Scaffold (pinned by `settings_test.dart` «has no AppBar nor Scaffold») and sits in `MainScreen`'s `Scaffold(resizeToAvoidBottomInset: false)` (`main_screen.dart:219-227`): an inline `TextField` in the tab stays under the keyboard in landscape (the trap recorded in the FE 21 UAT lessons) | The section keeps a button; the field lives in a dialog on the root Navigator (dialogs inset themselves above the keyboard), followed by the destructive confirmation naming the username. Result line inline in the section |
| C6 | D-09: «the privacy page must mention this datum (a line)»; D-10: memory survives logout | `privacy.md` §10 says the device data «si cancellano con il logout (i token) o disinstallando l'App» and lists only tokens, notification preferences, image cache; both pages carry `_Ultimo aggiornamento: [DATA DI PUBBLICAZIONE]_` [VERIFIED: legal repo] | The legal edit is two lines, not one: §2 (version + date of acceptance on the account) and §10 (accepted version remembered on the device until the account is deleted or the app uninstalled). The document version constant needs a real value → **Q-PO3** |

## Standard Stack

### Core (already in `pubspec.yaml`, nothing to add)
| Library | Resolved version | Purpose | Why |
|---------|------------------|---------|-----|
| `flutter_bloc` | 9.1.1 | Cubits for account deletion, innkeeper deletion, consent | project standard [VERIFIED: pubspec.lock] |
| `graphql_flutter` | 5.2.1 | new mutations via `KlimmeckGraphQl.performMutation` | project standard [VERIFIED: pubspec.lock] |
| `shared_preferences` | 2.5.3 (`SharedPreferencesAsync`) | consent memory, same pattern as `ActiveUserStore`, `NotificationPreferencesStore` | every store in `lib/repository/storage/` except the legacy `storage_manager.dart`/`cache_expiry.dart` uses `SharedPreferencesAsync` [VERIFIED: grep] |
| `url_launcher` | 6.3.2 | via `UrlLauncherLinkOpener` (external app) | already wired [VERIFIED: pubspec.lock] |
| Flutter SDK | 3.35.5 (fvm) | `Checkbox.semanticLabel`, `TextSpan` + `TapGestureRecognizer` link semantics, `tester.tapOnText` | [VERIFIED: fvm source `checkbox.dart:404`, `paragraph.dart:1346-1351` sets `isLink`/`onTap` per recognizer span, `flutter_test/controller.dart:1064`] |
| `bloc_test` 10.0.0, `mocktail` 1.0.5 | tests | project standard [VERIFIED: pubspec.lock] |

### Alternatives Considered
| Instead of | Could use | Tradeoff |
|------------|-----------|----------|
| `TextSpan` + `TapGestureRecognizer` links inside the checkbox sentence | `Wrap` of `Text` + two `TextButton`s | buttons break the sentence flow and its line wrapping; recognizer spans get their own semantics node with `isLink` and `onTap` (verified in the framework source), which is the accessible inline-link idiom |
| consent memory written on tick | written after a successful login | write-on-tick needs no cross-cubit coordination (the `SignInCubit` is closed by `AuthGate` when the login succeeds); the tick is the user's act of acceptance on this device; untick removes it |
| own deletion through `AuthCubit` | a shell-level `AccountDeletionCubit` like `CharacterDeletionCubit` | the shell cubit mirrors the existing pattern; the teardown is done by the repository through `SessionTerminator`, so the cubit closing with the shell is harmless (`SafeEmit`) |
| `flutter_secure_storage` for the consent memory | `SharedPreferencesAsync` | the accepted version is not a secret; CONTEXT names `shared_preferences` as the natural place |

**Installation:** none.

## Architecture Patterns

### 1. Own deletion today's model: «Elimina personaggio» (D-01, D-02, D-05, D-06, D-16)

- UI: `AccountSection` (`settings/components/account_section.dart`) — `BlocBuilder<CharacterDeletionCubit>`; `OutlinedButton(style: KlimmeckGuideTheme.destructiveOutlinedButtonStyle)`; spinner `SizedBox.square(spacingMd)` + `CircularProgressIndicator(bloodRed)` while `isDeleting`; inline `failure.message` in `errorText` under the button; then `spacingLg` and «Esci» (`destructiveButtonStyle`, `confirmLogout`). The dialog lives on the root Navigator: **the cubit is read before the `await`** (`_confirmDeletion`).
- Dialog: `showDestructiveConfirmation(context, title, body, confirmLabel)` (`destructive_confirmation_dialog.dart`) → `AlertDialog`, Annulla / red ElevatedButton, `barrierDismissible: false`, returns `bool`. `delete_character_confirmation_dialog.dart` is a 15-line wrapper — mirror it as `delete_account_confirmation_dialog.dart`.
- Cubit: `CharacterDeletionCubit` with `SafeEmit`, state `{isDeleting, failure, deletedUser}`; the double-tap guard `if (isClosed || state.isDeleting) return`; catch-all → `unknown` («garanzia anti-spinner infinito»).
- Repository: `CharacterDeletionRepository._guard` maps `OperationException` → `CharacterDeletionException(characterDeletionFailureFrom(e))`, `FormatException` → `unknown`.
- Failures: `character_deletion_failure.dart` — enum + exception + mapper reading only `extensions.code` via `graphQlErrorCode`; `code == null && linkException != null` → `connection`. Messages: `character_deletion_messages.dart` extension `.message` («Errore di connessione, riprova» / generic).
- Provider: `AuthenticatedShell` creates `CharacterDeletionCubit(CharacterDeletionRepository(graphQl: graphQl))` (`authenticated_shell.dart:219-223`).
- Role: `isInnkeeperSession(AuthState)` (`screens/innkeeper/innkeeper_access.dart`) used through `BlocSelector<AuthCubit, AuthState, bool>` in `InnkeeperSection` and `settings.dart`. **D-16 = the same selector around the new button** (hidden, not disabled).
- Service: `KlimmeckGraphQl.deleteCharacter()` → `_dataOrThrow(await performMutation(query: CharacterMutations.deleteCharacter))` (`graphql.dart:731-736`); the client has `queryRequestTimeout` (`graphql_client_provider.dart:48`), so no client-side timeout is needed (same as the character deletion).

### 2. Teardown and landing (D-03, D-06, D-15)

End to end, today:
- `AuthCubit.logout()` → `PushSessionCleanup.unregister()` (≤ 2 s) → `AuthTokenService.logout()`.
- `SessionAuthTokenService.logout()` → `_detachSession()` → BE `logout` (bearer, ≤ 4 s) → `_endSession(signedOut)`.
- `_endSession(reason)` (single-flight `_endInFlight`, first reason wins) → `_supersedeSession()` + `_forgetSession()` → `_onSessionTeardown()` = `GraphQLClientHolder.reset()` (disposes the WS link, recreates the client; `app_bootstrap.dart:44-47`) → `SessionStore.clear()` (secure storage) → emit `AuthUnauthenticated(reason)`.
- `terminateSession(reason)` = `_endSession(reason)` without backend call; no-op if not authenticated or a logout is in flight (`session_auth_token_service.dart:190-197`). `DevAuthTokenService` implements it too (`dev_auth_token_service.dart:99-104`). The composition returns it as `terminator` (`session_auth_composition.dart:21`, `dev_auth_composition.dart:26`); `KlimmeckGuideApp` has it as `widget.sessionTerminator` and hands it today only to `SessionSyncScope`.
- On any `AuthUnauthenticated`, `PushRegistrationCoordinator._endSession()` clears the active user (`klimmeck.push.activeUserId`) and the notification tray; no network (`push_registration_coordinator.dart:93-95,192-200`).
- `AuthGate` rebuilds on the type change, pops the root Navigator to the first route (dialogs closed), builds `SignInScreen(notice: _noticeFor(reason))` (`auth_gate.dart:40-72`).
- Reasons today: `signedOut`, `sessionExpired`, `replacedByNewLogin`, `roleChanged`, `channelAccessLost`, `syncLost`. HTTP: the auth link / dio interceptor on 401 → `recoverFromUnauthorized` → refresh. WS: close 4401/4403/4409 → same recovery, **the close reason is not read** (`ws_reconnect_policy.dart:17-21`). The reason reaches the app only through the refresh rejection: `SESSION_REVOKED` + `extensions.reason` mapped by `_unauthenticatedReasonOf` (`newLogin`, `roleChanged`, `accessLost`; anything else → `sessionExpired`) (`session_auth_token_service.dart:385-397`, `auth_api_exception.dart:12-14`).
- Device-only stores and what a logout does to them: secure session store (cleared), active user (cleared), notification preferences per user, library bookmarks per character, new-entries per character (untouched by design — «Non è un artefatto di sessione», `notification_preferences_store.dart:5-7`). D-06 adds only the consent memory; the per-user/per-character orphan keys of a deleted account stay (harmless; not in D-06).

What changes:
1. `UnauthenticatedReason.accountDeleted` + `SignInNotice.accountDeleted` + `_noticeFor` row + `_Notice` text «Il tuo account è stato eliminato.» (same style as the other notices: `errorText` in parchment, above the button).
2. `sessionRevokedReasonAccountDeleted = 'accountDeleted'` in `auth_api_exception.dart` and one row in `_unauthenticatedReasonOf`. Safe today: an unknown reason already maps to `sessionExpired`.
3. Own deletion success → repository calls `terminator.terminateSession(UnauthenticatedReason.accountDeleted)`. **Never** `AuthCubit.logout()` (C3).
4. Consent memory forgotten when the sign-in screen is built for `accountDeleted` (covers the own path and the innkeeper path in one place, Pattern 4).

What a player deleted by the innkeeper while online sees **today's code + a BE that only deletes**: the WS is closed only if the BE revokes through `WsSessionRegistry` (4409) → refresh → user gone → `SESSION_REVOKED` without reason (or `SESSION_EXPIRED` if the session row is deleted) → «La sessione è scaduta, accedi di nuovo.» If the BE does not close the socket, the access JWT (≤ 15 min) keeps HTTP working until a request is refused or the proactive refresh fails. Hence Q-BE2.

### 3. Login flow and where the version can travel (D-07..D-12)

- `SignInScreen` (Scaffold + AppBar, utility) → `BlocBuilder<SignInCubit>`: `_Notice` → `_TwitchLoginButton` (InkWell, gradient, `Semantics(button, label)`, `onTap: null` while loading) → `_LoginOutcome`; then `_LegalFooter` with two `TextButton(onPressed: () {})` (`sign_in_screen.dart:94-95,323-343`) — removed by D-07.
- `SignInCubit(AuthTokenService, LinkOpener)`; `signInWithTwitch()` maps `LoginCancelled` → idle, `LoginUnavailable` → `twitchNotConfigured`, `LoginNotFollowing` → `notFollowingChannel`, anything else → `connection`. Constructed in `AuthGate` (`auth_gate.dart:48-51`) and two tests.
- `SessionAuthTokenService.login()`:
  1. `_openLoginPage`: browser to `<baseUrl>/auth/twitch/start?challenge=<S256>` (`session_auth_token_service.dart:244-258`) — **step A** (a query parameter; the BE controller reads `@Query('challenge')`, `twitch-auth.controller.ts:24-30`).
  2. BE callback creates the user (`findOrCreateByTwitchId`) and redirects `klimmeck://auth?ticket=…|error=…` (`twitch-login.service.ts:124-133`); `parseLoginCallback` maps `error=<code>` → `LoginRejectedByBackend(code)` → `LoginFailedException(code)`.
  3. `_redeemTicket` → `exchangeLoginTicket(ticket, codeVerifier)` on the auth-only GraphQL client (`graphql_backend_auth_api.dart:27-37`, `auth_mutations.dart:4-12`) — **step B** (a GraphQL argument). An unknown error code there becomes `TransientAuthFailure(code)` → `LoginFailedException('network')` → «Errore di connessione» (`session_auth_token_service.dart:282-286`): a consent refusal would be mislabelled unless mapped.
- Dev bypass: `DevAuthTokenService.login()` just re-emits the `.env` identity; no browser, no ticket; the BE dev strategy upserts the dev user on each request (`dev-auth.strategy.ts:29`). Nothing travels.
- FE cost is the same for A and B (one query parameter vs one variable + document change). B is schema-checked and unit-testable through `MockBackendAuthApi`; A binds the version to the user creation at the callback (atomic with D-11's «required from this phase on»). **The BE chooses (Q-BE3)**; the FE plan is written for both and finalised on the handoff.
- Consent memory: `lib/repository/storage/legal_consent_store.dart` — `LegalConsentStore { Future<String?> readAcceptedVersion(); Future<void> remember(String version); Future<void> forget(); }`, `SharedPreferencesLegalConsentStore(preferences: () => SharedPreferencesAsync())`, key `klimmeck.legal.acceptedVersion`. Not touched by logout (the session store is a different store). Instance created in `_KlimmeckGuideAppState` like the other stores and exposed with `RepositoryProvider<LegalConsentStore>.value` (or passed to `AuthGate`).
- `LinkOpener` (`push/link_opener.dart`, `push/url_launcher_link_opener.dart`) is used by the push tap router, `AuthGate`, `KlimmeckGuideApp`, `SignInCubit` and one test fake — 6 files [VERIFIED: grep]. **Moving it to `lib/repository/services/links/` is an in-scope Boy Scout fix**: the sign-in is a non-push consumer since Phase 12 and this phase adds two more links; it is mechanical (imports only), so one separate `refactor(phase-25)` commit at the start of the consent plan, no behaviour change.
- Constants: `lib/config/legal_documents.dart` beside `twitch_channel.dart` (same shape: `static const String termsUrl`, `privacyUrl`, `version`; `static final Uri termsUri`, `privacyUri`). Only constant URIs are opened (never from a payload), as `TwitchChannel` documents. The two URLs answer 200 [VERIFIED: curl 2026-11-24].

### 4. Innkeeper action (D-15, D-16)

- `InnkeeperSection` (Settings, «Locanda», innkeeper only via `isInnkeeperSession`) today has one button «Apri la Locanda».
- Innkeeper services: `InnkeeperRepository` (provided by the shell as `RepositoryProvider`, `authenticated_shell.dart:266-268`) with `_guard` → `InnkeeperException(innkeeperFailureFrom(e))`, 15 s timeout, `GraphQlAccessDeniedException`, `TimeoutException` → `timedOut`, `FormatException` → `malformed`. `innkeeperFailureFrom` reads only `extensions.code` (`innkeeper_failure.dart:57-75`). Messages per failure live with the screen that shows them (e.g. character deletion messages; the panel's own copies).
- Recommended split: `InnkeeperRepository.deletePlayerAccount(String twitchUsername)` + new `InnkeeperFailure` values (`twitchUserUnknown`, `accountNotFound`, `targetIsInnkeeper`, `twitchUnavailable`) with their codes from the BE handoff; a `PlayerAccountDeletionCubit` (`settings/playerDeletionCubit/`) with state `{isDeleting, failure, deletedUsername}`; provided by the shell next to `CharacterDeletionCubit`.
- UI (C5): «Elimina un account» (red outline) under «Apri la Locanda» → `showDialog` with a small stateful dialog owning a `TextEditingController` (or `SheetTextField`), «Avanti» disabled while the trimmed text is empty → `showDestructiveConfirmation(title: 'Eliminare l'account di <username>?', …)` → cubit. Result line under the button: success «Account di <username> eliminato.» or the failure message. Read the cubit before the first `await` (root Navigator).
- Client-side validation: trim only; the BE validates the form (rule 4). Never log the username (privacy §2 says the username is not saved).

### 5. Registrations of a quest and a null character (D-13, D-14)

- `QuestFragment` selects `registeredAdventurers { character title }`; SDL today `QuestRegistration { character: ID!, registeredAt: DateTime, title: String! }` (BE `src/schema.gql:870-874`) [VERIFIED].
- Parsing: `RegisteredAdventurer.listFrom` → `from` → `null` for a `character` that is not a `String` → `whereType` drops it.
- Uses: availability «already registered» (`quest_availability.dart:157`), slot lines and the viewer seat (`quest_sheet_details.dart`), capacity rules mirroring the BE (`quest_capacity.dart`), the «X/Y» label (`quest_state_label.dart:46`). All count or compare ids; none draws names.
- Archive precedent (BE): after the start the registration stays with `archivedAt` and the **same character id** (`seat-release.ts` `placeholderMarkOf`). If the deletion does the same, the id dangles and the FE is unaffected.
- Innkeeper guided mission: `MissionParticipantsCubit._read` does `Future.wait(characterIds.map(readCharacter))` — one deleted character (`NOT_FOUND`) fails the whole read (`MissionParticipantsFailed`) until the draft (served without that participant, D-14) is re-read. Request cards: `PendingRequest.tryFromJson` drops an entry with a null character; the BE deletes the GM requests anyway (D-14).

### 6. Schema check

- Registry: `tool/schema_check/schema_check_documents.dart` maps every named operation → document; `test/tool/schema_check_documents_test.dart` asserts it equals the operations declared in `lib/graphql` and **pins the count at 55** (also `test/graphql/shop_documents_test.dart:155`, `travel_documents_test.dart:196-197`, `loot_fragment_test.dart:124-125`) [VERIFIED: grep].
- Validation: `dart run tool/schema_check/dump_documents.dart <dir>` then `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema.gql> <dir>`, SDL from `git -C <BE> show origin/develop:src/schema.gql` into a `mktemp -d` directory (24-RESEARCH; node v22.12.0 and BE `node_modules/graphql` present [VERIFIED]).
- This phase: +2 documents (own deletion, innkeeper deletion) → 57, and `ExchangeLoginTicket` changes if the version travels at step B. All four pins move together.

### Recommended structure (new and touched files)

```
lib/config/legal_documents.dart                                   NEW  version + two URIs
lib/repository/services/links/{link_opener,url_launcher_link_opener}.dart   MOVED from push/ (Boy Scout)
lib/repository/storage/legal_consent_store.dart                   NEW
lib/repository/account_deletion_failure.dart                      NEW  enum + exception + mapper
lib/repository/account_deletion_repository.dart                   NEW  graphQl + SessionTerminator
lib/repository/innkeeper_failure.dart / innkeeper_repository.dart TOUCH (deletePlayerAccount + codes)
lib/repository/services/auth/{auth_token_service,session_auth_token_service,dev_auth_token_service,auth_api_exception,login_exception}.dart  TOUCH
lib/repository/services/auth/{backend_auth_api,graphql_backend_auth_api}.dart   TOUCH only if step B
lib/graphql/mutations/account_mutations.dart                      NEW  DeleteAccount, DeletePlayerAccount (names from BE)
lib/graphql/mutations/auth_mutations.dart                         TOUCH only if step B
lib/repository/services/graphql/graphql.dart                      TOUCH (two methods)
lib/screens/signIn/sign_in_screen.dart                            TOUCH (notice, checkbox row, footer removed)
lib/screens/signIn/consentCubit/legal_consent_{cubit,state}.dart  NEW
lib/screens/signIn/components/legal_consent_row.dart              NEW  (StatefulWidget owning the two recognizers)
lib/screens/signIn/cubit/sign_in_cubit.dart                       TOUCH (version argument, consent failure)
lib/screens/auth/auth_gate.dart                                   TOUCH (reason row, consent cubit restore/forget)
lib/screens/auth/authenticated_shell.dart                         TOUCH (two cubits, terminator param)
lib/bootstrap/klimmeck_guide_app.dart                             TOUCH (consent store, terminator to the shell)
lib/screens/mainScreen/tabs/settings/accountDeletionCubit/        NEW
lib/screens/mainScreen/tabs/settings/playerDeletionCubit/         NEW
lib/screens/mainScreen/tabs/settings/components/{account_section,innkeeper_section}.dart  TOUCH
lib/screens/mainScreen/tabs/settings/components/{account_deletion_messages,player_deletion_messages}.dart  NEW
lib/shared/components/modal/delete_account_confirmation_dialog.dart NEW
tool/schema_check/schema_check_documents.dart                     TOUCH (+2)
```

### Pattern 1: account deletion cubit (mirror of `CharacterDeletionCubit`)
State `AccountDeletionState {isDeleting, failure}`; `deleteAccount()` guarded against double tap and `isClosed`; success emits nothing (the repository has already asked the teardown; `AuthGate` removes the shell, `SafeEmit` ignores late emits); failure → `AccountDeletionState(failure: …)`; catch-all → `unknown`.

### Pattern 2: repository orchestrates mutation + teardown
```dart
// Mirrors CharacterDeletionRepository (lib/repository/character_deletion_repository.dart)
class AccountDeletionRepository {
  AccountDeletionRepository({required KlimmeckGraphQl graphQl, required SessionTerminator terminator})
    : _graphQl = graphQl, _terminator = terminator;

  final KlimmeckGraphQl _graphQl;
  final SessionTerminator _terminator;

  /// Success: the BE has deleted everything and revoked every session; the
  /// app tears down locally (no push unregister, no BE logout: C3).
  Future<void> deleteOwnAccount() async {
    await _guard(_graphQl.deleteAccount);
    await _terminator.terminateSession(UnauthenticatedReason.accountDeleted);
  }
  // _guard: OperationException → AccountDeletionException(accountDeletionFailureFrom(e)),
  //         FormatException → unknown
}
```
The consent memory is not cleared here: it is cleared once, where every `accountDeleted` path converges (Pattern 4).

### Pattern 3: the reason and the notice
```dart
// auth_gate.dart _noticeFor — one new row
UnauthenticatedReason.accountDeleted => SignInNotice.accountDeleted,
// session_auth_token_service.dart _unauthenticatedReasonOf — one new row
sessionRevokedReasonAccountDeleted => UnauthenticatedReason.accountDeleted,
```

### Pattern 4: consent row and memory (D-07, D-08, D-10)
- `LegalConsentCubit(LegalConsentStore)` with two entry points (no behaviour-switching boolean, CLAUDE.md): `restore()` (ticked iff stored == `LegalDocuments.version`) and `forget()` (store cleared, unticked); `accept()` writes the version, `withdraw()` removes it. State `{isAccepted}` (starts `false`; `restore` may flip it a frame later — acceptable on the login, an explicit utility screen).
- `AuthGate` (`AuthUnauthenticated(:final reason)`) provides it: `create: (_) => LegalConsentCubit(store)..(reason == UnauthenticatedReason.accountDeleted ? forget() : restore())` — expressed as two calls, not a flag.
- `_TwitchLoginButton` enabled iff `consent.isAccepted && state is! SignInInProgress`; `onPressed` → `signInCubit.signInWithTwitch(acceptedLegalVersion: LegalDocuments.version)`.
- Row: `Checkbox(value, onChanged, semanticLabel: 'Accetto i Termini di servizio e l'Informativa sulla privacy')` + `Expanded(GestureDetector(onTap: toggle, child: Text.rich(...)))` where the two wordings are `TextSpan(recognizer: TapGestureRecognizer()..onTap = () => cubit.openTerms())`. The recognizers belong to a `StatefulWidget` and are disposed in `dispose()`. The link span wins the gesture arena over the outer tap; elsewhere the sentence toggles the box. Colours/typography from `KlimmeckGuideTheme` (`lightText`/`bodyMedium` in parchment, links in `primaryGold` + underline); a `CheckboxThemeData` does not exist in the theme yet — add it to `kg_theme.dart` (no inline colours, ui-ux.md), tap target ≥ 44 (Checkbox default is 48 with `MaterialTapTargetSize.padded`).
- Link opening goes through the cubit (UI → Cubit → Service): `SignInCubit.openTerms()` / `openPrivacy()` next to the existing `openChannel()`.

### Pattern 5: innkeeper field in a dialog, then the confirmation
```dart
Future<void> _deletePlayer(BuildContext context) async {
  final cubit = context.read<PlayerAccountDeletionCubit>();       // before any await
  final username = await showPlayerUsernameDialog(context);       // root Navigator, field + «Avanti»
  if (username == null || cubit.isClosed) return;
  final confirmed = await showDeletePlayerAccountConfirmation(context, username: username);
  if (confirmed && !cubit.isClosed) await cubit.deletePlayer(username);
}
```

### Anti-Patterns to Avoid
- Calling `AuthCubit.logout()` after a deletion (C3: dead bearer, wrong notice, pointless network).
- Reading the server message text for any of the new errors: only `extensions.code` (every failure mapper in `lib/repository/`).
- A `TextField` inline in the Settings tab (C5).
- Opening any URL that is not a constant of `lib/config/`.
- Storing or logging the Twitch username.
- Selecting/sending fields or arguments the merged BE SDL does not have yet (schema check gate).

## Don't Hand-Roll

| Problem | Don't build | Use instead | Why |
|---------|-------------|-------------|-----|
| Local session teardown with a reason | a new teardown path | `SessionTerminator.terminateSession(reason)` | single-flight, epoch guard, holder reset, store clear, one terminal state — all already tested (`session_auth_token_service_terminate_test.dart`) |
| Destructive confirmation | a new dialog | `showDestructiveConfirmation` | D-01 «same component and weight» |
| Error-code extraction | parsing `message` | `graphQlErrorCode` | handles `graphqlErrors`, `ServerException.parsedResponse`, `SubscriptionError` |
| External link | `launchUrl` in a widget | `LinkOpener` via the cubit | already injected and faked (`RecordingLinkOpener`) |
| Device memory | `SharedPreferences.getInstance()` | `SharedPreferencesAsync` store + `FakeSharedPreferencesAsync` | no per-isolate cache, the project's store pattern |
| Accessible inline links | custom hit-testing | `TextSpan.recognizer` (`TapGestureRecognizer`) | the framework emits a link semantics node per span |
| Double-tap protection | ad-hoc flags in widgets | the cubit guard `if (isClosed || state.isDeleting) return` | same as character deletion |

## Common Pitfalls

### Pitfall 1: the notice race on the own deletion
**What goes wrong:** the BE closes the WS with 4409 as part of the revocation; the app's recovery refreshes, gets rejected, and `_endSession(sessionExpired)` wins before the mutation response triggers `terminateSession(accountDeleted)` (which is then a no-op, `AuthUnauthenticated` already current).
**How to avoid:** primary — BE rejects the refresh with `SESSION_REVOKED`/`accountDeleted` (Q-BE2), so every path carries the same reason. Fallback only if the BE refuses: an additive capability on the session service (like `UnauthorizedRecovery`/`SessionTerminator`), e.g. `AccountDeletionGuard.runDeletion(Future<void> Function() delete)`, that holds terminal rejections while the deletion is in flight and ends with `accountDeleted` on success or the held reason on failure. It touches the most delicate class: write it only if Q-BE2 is answered «no».
**Warning signs:** a widget test where the WS closes before the mutation completes shows «La sessione è scaduta».

### Pitfall 2: an authenticated call after the deletion
**What goes wrong:** any call with the dead bearer (push unregister, a sync refetch, a late registration retry) enters the recovery and can choose the notice.
**How to avoid:** no unregister, no BE logout (C3); the teardown runs immediately after the mutation succeeds; with Q-BE2 in place the reason is right anyway.

### Pitfall 3: the deletion succeeds but its response is lost
**What goes wrong:** timeout/network error after the BE committed: the button shows «Errore di connessione, riprova».
**How to avoid:** nothing extra on the FE: the WS close (4409) and the next refresh end the session; with Q-BE2 the player still lands on the D-03 notice. Document it in the UAT script; a retry tap would get an auth error, mapped to the generic message.

### Pitfall 4: tests pin the registry at 55 in four files
Move all four pins together (57, or whatever the gate settles) in the gate plan.

### Pitfall 5: `login()` signature change ripples through tests
9 test files stub `service.login()`; with a named argument use `when(() => service.login(acceptedLegalVersion: any(named: 'acceptedLegalVersion')))`. `auth_token_service_contract_test.dart` and `session_auth_token_service_login_test.dart:146` (start URL pinned as `…/auth/twitch/start?challenge=challenge-test`) change if step A is chosen.

### Pitfall 6: the keyboard in landscape (C5)
`MainScreen` does not resize for the keyboard; the field goes in a dialog. Test with `useLandscapePhone` (`test/helpers/landscape.dart`) and a simulated `viewInsets`.

### Pitfall 7: `MissionParticipantsCubit` fails as a whole on one deleted participant
`Future.wait` + `readCharacter` → `NOT_FOUND` → `MissionParticipantsFailed`. The draft re-read drops the participant (D-14). Recommendation: accept it (rare, innkeeper retries) and note it in the UAT; optionally tolerate `notFound` per id — a small change in the same cubit, only if the planner wants it.

### Pitfall 8: `SignInCubit` survives a reason change
`AuthGate` rebuilds the same `BlocProvider` element when only the reason changes (`Unauthenticated(a)` → `Unauthenticated(b)`), so `create` is not re-run. The account-deleted transition always comes from `AuthAuthenticated`, which creates a new element; still, put `restore()/forget()` in `create` and test the Authenticated → Unauthenticated(accountDeleted) path.

### Pitfall 9: dev bypass after a deletion
With `DEV_AUTH_ENABLED=true` the BE dev strategy upserts the dev user on the next request: the account «comes back» at once (by design of the bypass). The device E2E of the deletion must use the real Twitch login.

### Pitfall 10: format only touched files
Never `dart format` a directory (baseline not formatter-clean, STATE.md).

## Code Examples

### Failure mapper (shape copied from `character_deletion_failure.dart`)
```dart
enum AccountDeletionFailure { innkeeperRefused, unauthenticated, connection, unknown }

AccountDeletionFailure accountDeletionFailureFrom(OperationException exception) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) return AccountDeletionFailure.connection;
  return switch (code) {
    innkeeperAccountDeletionRefusedCode => AccountDeletionFailure.innkeeperRefused, // name from the BE handoff
    unauthenticatedCode => AccountDeletionFailure.unauthenticated,
    _ => AccountDeletionFailure.unknown,
  };
}
```

### Proposed copy (discretion, within D-03/D-05/D-07)
- Dialog title «Eliminare l'account?»; body «Il tuo nome sarà cancellato dai registri della Guida: tutti i tuoi personaggi, anche quelli archiviati, il saldo dei punti e il ritratto andranno perduti per sempre. I punti canale già convertiti non verranno restituiti. Uscirai subito dall'App.»; confirm «Elimina».
- Notice «Il tuo account è stato eliminato.» (verbatim).
- Own errors: connection «Errore di connessione, riprova»; generic «Impossibile eliminare l'account, riprova»; innkeeper refused (race only) «L'oste non può eliminare il proprio account dall'App».
- Innkeeper: dialog «Elimina un account» / field «Nome utente Twitch» / «Avanti»; confirmation «Eliminare l'account di <username>?» + the same loss list; errors «Nessun utente Twitch con questo nome», «Questo utente non ha un account nella Guida», «Non puoi eliminare l'account di un oste», «Twitch non risponde, riprova più tardi»; success «Account di <username> eliminato.»
- Consent refused by the BE (bug path only): «Accetta i Termini di servizio e l'Informativa sulla privacy per entrare.»

### Version on the login, both candidates
```dart
// Step A — query parameter on the browser start URL (session_auth_token_service.dart:_openLoginPage)
.replace(queryParameters: {'challenge': challenge.codeChallenge, '<bePARAM>': acceptedLegalVersion});
// refusal arrives as klimmeck://auth?error=<code> → map in _ticketFrom to a LoginConsentRequiredException

// Step B — GraphQL argument
//   mutation ExchangeLoginTicket($ticket: String!, $codeVerifier: String!, $<beArg>: String!) { ... }
// refusal arrives as extensions.code → map in mapAuthOperationException / _redeemTicket
```

## What the FE needs from the BE contract

| # | Need | Today | Blocks |
|---|------|-------|--------|
| N1 | Own deletion mutation: name, no argument, return type (a `Boolean!` is enough; nothing is read from it), error code for the innkeeper role (D-16) | — | ACCT-01 document, mapper |
| N2 | Innkeeper mutation: name, argument name/type for the username, return type, codes for unknown username / no account / target innkeeper / Twitch unavailable; `FORBIDDEN` for a non-innkeeper | — | ACCT-03 document, mapper |
| N3 | Refresh after deletion → `SESSION_REVOKED` with `extensions.reason = "accountDeleted"` (both paths), WS sockets closed (4409), an HTTP request with a still-valid JWT of a deleted user answered as auth failure (401 / `UNAUTHENTICATED`) | refresh with a missing user → `SESSION_REVOKED` without reason; unknown token → `SESSION_EXPIRED` | ACCT-02 correctness (fallback: session-expired notice) |
| N4 | Where the version travels (start query vs ticket exchange), parameter name, accepted format, the refusal code and its channel (callback `error=` vs `extensions.code`), and the dev bypass rule | `exchangeLoginTicket(codeVerifier: String!, ticket: String!)` | LEGAL-02 |
| N5 | Shape of a deleted character's registration in a started quest: keep `character: ID!` (dangling id, no SDL change) — or declare the non-additive change | `QuestRegistration.character: ID!` | D-13 (FE no-op if kept) |
| N6 | Push devices deleted server-side (the app does not unregister) | BE Phase 5 contract: unregister before logout | ACCT-02 |

## State of the Art

| Old approach | Current approach | When changed | Impact |
|--------------|------------------|--------------|--------|
| `SharedPreferences.getInstance()` | `SharedPreferencesAsync` | shared_preferences 2.3+ (project stores since Phase 5) | new store uses the async API |
| Inline links via custom gesture widgets | `TextSpan.recognizer` with framework link semantics (`isLink`) | Flutter 3.x | accessible without extra Semantics wrappers |
| `find.text` + `tap` on the paragraph centre | `tester.tapOnText(find.textRange.ofSubstring(...))` | flutter_test 3.22+ (present in 3.35.5) | tests can tap one span of the sentence |

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|-------|---------|---------------|
| A1 | The BE revocation at deletion closes the user's WS with 4409 (as `revokeAllForRoleChange`/`AccessLoss` do through `WsSessionRegistry`) | Summary, Pitfall 1 | if it does not, Pitfall 1 shrinks but the innkeeper path becomes slow (≤ 15 min) — Q-BE2 covers it |
| A2 | Dialogs on the root Navigator keep a one-line `TextField` visible above the keyboard in landscape on the Samsung used at UAT | Pattern 5 | layout retouch at UAT (CONTEXT allows) |
| A3 | Write-on-tick satisfies D-10 «once accepted» | Pattern 4 | if the PO means «once a login succeeded», move `accept()` after the login — one line |
| A4 | No new party list is wanted for D-13 | C2 | a new widget and a BE field would be needed — Q-PO2 |

## Open Questions (RESOLVED)

Resolved from the code:
1. **Where does Settings learn the role?** `AuthCubit` state through `isInnkeeperSession` + `BlocSelector` (as `InnkeeperSection`). Hide the button with the same selector.
2. **Which calls must not run after the deletion?** Push unregister and BE logout (C3). Use `terminateSession(accountDeleted)`.
3. **How does a revocation reason reach the app?** Only via the refresh rejection (`SESSION_REVOKED` + `extensions.reason`); WS close reasons are ignored by design. → Q-BE2.
4. **Where does the consent memory live and who clears it?** `SharedPreferencesAsync` store, key `klimmeck.legal.acceptedVersion`; cleared by the consent cubit when the sign-in screen is built for `accountDeleted`; untouched by logout because it is a separate store.
5. **Is moving `LinkOpener` in scope?** Yes, Boy Scout, one mechanical commit (6 files).
6. **How does the app react today to a null registration character?** It drops the seat (C2). If the BE keeps the id, nothing changes.
7. **Where does the innkeeper field go?** In a dialog (C5).
8. **Does the own deletion need a client timeout?** No: the GraphQL client has `queryRequestTimeout`; same as the character deletion.

Still open — product owner:
- **Q-PO1 (C1):** add «Elimina account» to the character-creation screen for a user with no character? Recommended: yes.
- **Q-PO2 (C2):** confirm that no party list with «Un avventuriero scomparso» is wanted (today nothing in the app shows other members' names).
- **Q-PO3 (C6):** the document version string (recommended: the publication date, e.g. `2026-11-24`, the same date written in place of `[DATA DI PUBBLICAZIONE]` on both pages) and the two privacy lines (§2 version + date on the account; §10 version remembered on the device).

Still open — BE contract: N1–N6 above (most important: **N3** and **N4**).

## Environment Availability

| Dependency | Required by | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Flutter (fvm) | build/tests | ✓ | 3.35.5 | — |
| Node | schema check | ✓ | v22.12.0 | — |
| BE `node_modules/graphql` | schema check (`NODE_PATH`) | ✓ | present | — |
| adb | device E2E | ✓ (not on PATH) | `~/Library/Android/sdk/platform-tools/adb` | — |
| Legal pages online | D-08 links | ✓ | `/termini`, `/privacy`, `/elimina-account` → 200 | — |
| Merged BE Phase 26 SDL | gated plans, gate, E2E | ✗ (BE branch has only planning docs) | — | none: plans 03–05 wait for the BE handoff, the gate for the merge |

## Validation Architecture

`workflow.nyquist_validation` is absent from `.planning/config.json` → enabled.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` 10.0.0 + `mocktail` 1.0.5 |
| Config file | none (`analysis_options.yaml` with `flutter_lints`) |
| Quick run command | `flutter test <paths of the task>` |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` (gate plan only, alone, timeout ≥ 300 000 ms) |
| Analyzer gate | `OUT=$(flutter analyze --no-fatal-infos 2>&1); echo "$OUT" \| tail -1; ! echo "$OUT" \| grep -qE '^ *(error\|warning) •' && echo ANALYZE_GATE_OK` — baseline **«47 issues found»** (info only) [VERIFIED: run 2026-11-24 on this branch] |
| Schema check | §6 above |
| Suite baseline | 5535 green recorded at the close of Phase 24 (STATE.md); PR #56 (`fix/ui-layout-review`) merged after it, so re-measure in Wave 0. The 154 tests of the touched areas pass today [VERIFIED: `flutter test test/screens/signIn test/screens/auth/auth_gate_test.dart test/screens/auth/cubit test/screens/mainScreen/tabs/settings test/tool …terminate_test.dart`] |

Helpers: `buildTestApp` (`test/helpers/test_app.dart`), `useLandscapePhone` (`landscape.dart`), `FakeSharedPreferencesAsync`, `RecordingLinkOpener`, `InMemorySessionStore`, `FakeSessionBackend`, `FakeGraphqlWsServer`; mocks `MockAuthTokenService`, `MockSessionTerminator`, `MockBackendAuthApi`, `MockKlimmeckGraphQl`, `MockInnkeeperRepository`, `MockAuthCubit`, `MockCharacterDeletionCubit` (pattern for the new mock cubits), `MockPushSessionCleanup` (`test/helpers/mocks.dart`).

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ACCT-01 | button last under «Esci», detached, red outline; hidden for the innkeeper; dialog Annulla does nothing, Elimina calls once; spinner while deleting; inline failure | widget | `flutter test test/screens/mainScreen/tabs/settings/components/account_section_test.dart` | ✅ extend |
| ACCT-01 | order in the tab and dialog text | widget | `flutter test test/screens/mainScreen/tabs/settings/settings_test.dart` | ✅ extend |
| ACCT-01 | cubit sequences: success (no failure, single call), each failure, catch-all → unknown, double tap ignored | bloc | `flutter test test/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit_test.dart` | ❌ Wave 0 |
| ACCT-01 | mapper by code only; repository terminates with `accountDeleted` only on success, never calls logout/unregister | unit | `flutter test test/repository/account_deletion_failure_test.dart test/repository/account_deletion_repository_test.dart` | ❌ Wave 0 |
| ACCT-01 | messages per failure | unit | `flutter test test/screens/mainScreen/tabs/settings/components/account_deletion_messages_test.dart` | ❌ Wave 0 |
| ACCT-02 | `SESSION_REVOKED`/`accountDeleted` → `AuthUnauthenticated(accountDeleted)`; unknown reason still `sessionExpired` | unit | `flutter test test/repository/services/auth/session_auth_token_service_revocation_test.dart` | ✅ extend |
| ACCT-02 | `terminateSession(accountDeleted)` → one teardown, one terminal state (session + dev services) | unit | `flutter test test/repository/services/auth/session_auth_token_service_terminate_test.dart test/repository/services/auth/dev_auth_token_service_transitions_test.dart` | ✅ extend |
| ACCT-02 | `AuthGate` maps the reason to the notice; screen shows «Il tuo account è stato eliminato.» only for it; consent forgotten on that path, restored on the others | widget | `flutter test test/screens/auth/auth_gate_test.dart test/screens/signIn/sign_in_screen_test.dart` | ✅ extend |
| ACCT-02 | WS closed before the mutation completes still ends on the D-03 notice (needs N3; else documents the fallback) | integration (fakes) | `flutter test test/repository/services/auth/dual_session_revocation_test.dart` (or a new `account_deletion_flow_test.dart`) | ✅ extend / ❌ Wave 0 |
| ACCT-03 | section: «Elimina un account» only for the innkeeper; dialog field + «Avanti» disabled when blank; confirmation names the username; success/failure lines; landscape with keyboard: no overflow | widget | `flutter test test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart` | ✅ extend |
| ACCT-03 | cubit sequences; repository method + new failure codes | bloc + unit | `flutter test test/screens/mainScreen/tabs/settings/playerDeletionCubit test/repository/innkeeper_failure_test.dart test/repository/innkeeper_repository_test.dart` | ❌ Wave 0 / ✅ extend |
| LEGAL-01 | store read/remember/forget on `FakeSharedPreferencesAsync`, key pinned | unit | `flutter test test/repository/storage/legal_consent_store_test.dart` | ❌ Wave 0 |
| LEGAL-01 | consent cubit: restore ticks only on the same version, a different version stays unticked, accept/withdraw write/remove, forget clears | bloc | `flutter test test/screens/signIn/consentCubit/legal_consent_cubit_test.dart` | ❌ Wave 0 |
| LEGAL-01 | sentence verbatim; footer gone; login disabled until ticked; tapping each wording opens its URI (`tapOnText`) without toggling; tapping the rest toggles; semantics: checkbox label + two link nodes | widget | `flutter test test/screens/signIn/sign_in_screen_test.dart` | ✅ rewrite cases |
| LEGAL-01 | `LegalDocuments` constants (URLs exact, version non-empty) | unit | `flutter test test/config/legal_documents_test.dart` | ❌ Wave 0 |
| LEGAL-02 | `signInWithTwitch(acceptedLegalVersion:)` forwards the version; consent refusal → its failure/message | bloc | `flutter test test/screens/signIn/cubit/sign_in_cubit_test.dart` | ✅ extend |
| LEGAL-02 | version on the start URL (A) or in the exchange variables (B); refusal mapped | unit | `flutter test test/repository/services/auth/session_auth_token_service_login_test.dart test/repository/services/auth/graphql_backend_auth_api_test.dart test/repository/services/auth/login_callback_test.dart` | ✅ extend |
| GATE-25 | documents pinned (names, variables, registry); 4 count pins moved | unit | `flutter test test/graphql test/tool` | ✅ extend / ❌ new document tests |
| GATE-25 | every document valid on the merged SDL | gate | schema check block | ✅ tooling |
| GATE-25 | device E2E: own deletion → login notice, re-login from zero; innkeeper deletes an online player → notice on the other phone; consent box, links, memory across logout, cleared after deletion | manual | orchestrator-guided UAT | — justified: real BE, real Twitch login, two devices/accounts |

### Sampling Rate
- **Per task commit:** the task's test paths + the analyzer gate.
- **Per wave merge:** the test directories named in the plan's `<verification>`.
- **Phase gate:** schema check all OK on the merged BE Phase 26 SDL, full suite green, analyzer at 47, `tool/hardening_check.sh` clean, before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/repository/storage/legal_consent_store_test.dart`
- [ ] `test/screens/signIn/consentCubit/legal_consent_cubit_test.dart`
- [ ] `test/config/legal_documents_test.dart`
- [ ] `test/repository/account_deletion_failure_test.dart`, `test/repository/account_deletion_repository_test.dart`
- [ ] `test/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit_test.dart`
- [ ] `test/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit_test.dart`
- [ ] message tests for both deletions
- [ ] `test/graphql/account_deletion_documents_test.dart` (gated)
- [ ] mocks in `test/helpers/mocks.dart`: `MockAccountDeletionRepository`, `MockAccountDeletionCubit`, `MockPlayerAccountDeletionCubit`, `MockLegalConsentStore` (or an `InMemoryLegalConsentStore` fake beside the other in-memory stores)
- [ ] re-measure the suite baseline

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | consent travels with the login; the BE refuses a login without it (D-09); session ends through the existing terminator |
| V3 Session Management | yes | all sessions revoked server-side; local teardown clears secure storage, resets the GraphQL client/WS; no reuse of a dead bearer (C3) |
| V4 Access Control | yes | innkeeper action enforced by the BE (`FORBIDDEN`, target-innkeeper refusal); the FE only hides (`isInnkeeperSession`), as everywhere in the app |
| V5 Input Validation | yes | username trimmed client-side, validated by the BE; version is a constant |
| V6 Cryptography | no | — |
| V7 Error handling / logging | yes | only `extensions.code`; no server text to the user; never log the username or tokens (`appLog` with runtime types only, as today) |
| V8 Data Protection | yes | consent memory is non-sensitive (`SharedPreferencesAsync`); privacy text updated (C6) |

### Known Threat Patterns for this phase
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Accidental self-deletion | Tampering (user error) | destructive dialog, `barrierDismissible: false` (D-01) |
| Innkeeper deletes the wrong player | Tampering | confirmation naming the username; BE audit log (D-15) |
| Repudiation of an innkeeper deletion | Repudiation | BE admin audit log, 90 days |
| Opening attacker-controlled URLs | Spoofing | only constants from `lib/config/legal_documents.dart` |
| Consent bypass by a modified client | Elevation | BE refuses a login without the version (D-09) |
| Stale session after deletion | Elevation | BE revokes every session and closes sockets (N3); local teardown |
| Username kept on the device / in logs | Information disclosure | not stored, not logged (privacy §2) |

## Project Constraints (from CLAUDE.md)

- Utility screens only for chrome: Settings and login (allowed); the gameplay tabs untouched.
- No blocking loading in an active session: the deletion spinner is on an explicit user action (D-06); the consent `restore()` is on the login screen, no spinner.
- Branch `feat/25-account-deletion-and-legal-consent` → PR to `develop`; commit scope `phase-25`; no `Co-Authored-By` trailer (user memory).
- Backend is the source of truth: no client-side deletion logic or consent validation beyond the button gate.
- No secrets in the repo; never print `.env` / `env/*.json`.
- Clean Code / SoC (UI → Cubit → Repository → Service), TDD red → green → refactor, Boy Scout (the `LinkOpener` move, the `login_exception.dart` doc comment).
- `flutter analyze` at baseline (47 info) before PR; `dart format` only on touched files, never a directory.
- Keep `.planning/phases/25-…/BACKEND-NOTES.md` up to date with the contract the FE consumes.

## Sources

### Primary (HIGH confidence)
- FE working tree on `feat/25-account-deletion-and-legal-consent` (files cited inline), `flutter analyze` and targeted `flutter test` runs on 2026-11-24.
- BE working tree (read-only, `feat/26-eliminazione-account-e-consenso` at `dd975cbf`): `src/schema.gql` (578, 584, 663, 816, 870-874), `src/auth/auth-session.service.ts`, `src/auth/session/session-revoke-reason.enum.ts`, `src/auth/ws/ws-session-registry.ts`, `src/auth/twitch/twitch-auth.controller.ts`, `src/auth/twitch/twitch-login.service.ts`, `src/auth/dev/dev-auth.strategy.ts`, `src/characters/deletion/seat-release.ts`, `character-archiver.ts`, `26-CONTEXT.md`.
- Flutter 3.35.5 framework source (fvm): `material/checkbox.dart`, `rendering/paragraph.dart`, `flutter_test/controller.dart`, `finders.dart`.
- Legal repo `~/Personale/Code/klimmeck-guide-legal` (`elimina-account.md`, `privacy.md`, `termini.md`); live URLs checked with curl.

### Secondary / Tertiary
- `.planning/phases/24-…/24-RESEARCH.md` (schema check commands, gate pattern); user memory notes on the FE 21 keyboard traps.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — nothing new, versions from `pubspec.lock`.
- Architecture: HIGH for FE paths; MEDIUM where the BE contract decides (N1–N6).
- Pitfalls: HIGH for C3/Pitfall 1 mechanics (read in code); MEDIUM for A1 (BE behaviour of the new revocation).

**Research date:** 2026-11-24
**Valid until:** the BE Phase 26 handoff (names, codes, version channel) — then refresh the gated plans.

### Suggested plans and gating
| Plan | Content | Gating |
|------|---------|--------|
| 25-01 | `LinkOpener` move (refactor commit); `LegalDocuments`; `LegalConsentStore`; `LegalConsentCubit`; checkbox row with links; footer removed; login disabled while unticked; `CheckboxThemeData` | today's BE (nothing sent) |
| 25-02 | `UnauthenticatedReason.accountDeleted`, `SignInNotice.accountDeleted`, `_noticeFor`, `_unauthenticatedReasonOf` row, consent `forget()` on that path; terminator made available to the shell | today's BE (an unknown reason stays harmless) |
| 25-03 | own deletion: document, service method, failure + repository (terminator), cubit, button hidden for the innkeeper, dialog, messages (+ creation-screen action if Q-PO1 = yes) | BE handoff (N1, N3, N6); proved at the gate |
| 25-04 | innkeeper deletion: document, `InnkeeperRepository` method + codes, cubit, «Locanda» dialog + confirmation + result line | BE handoff (N2) |
| 25-05 | login carries the version (contract change of `login`, step A or B, refusal mapping, dev bypass); D-13 parser only if N5 changes the shape | BE handoff (N4, N5) |
| 25-06 | gate on the merged BE Phase 26 SDL (schema check, pins 55 → 57, full suite, analyzer, hardening), FE `BACKEND-NOTES.md`, legal repo lines (C6), device E2E (human, last) | BE merge |
