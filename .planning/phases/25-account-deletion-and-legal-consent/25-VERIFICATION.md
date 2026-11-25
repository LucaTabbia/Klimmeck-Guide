---
phase: 25-account-deletion-and-legal-consent
verified: 2026-11-25T09:01:19Z
status: human_needed
score: 5/6 roadmap success criteria verified in code and tests (SC 6 closes only with plan 25-08); 8/8 requirements implemented in code, 0/8 closed (device E2E pending)
overrides_applied: 0
head: 5e45e8e9
human_verification:
  - test: "Real Twitch login with the consent checkbox and the two links"
    expected: "Login disabled while unticked; «Termini di servizio» and «Informativa sulla privacy» open the two public pages in the external browser without ticking; after the login the BE user carries acceptedTermsVersion = 2026-11-24 and termsAcceptedAt"
    why_human: "Real browser, real Twitch OAuth, DB read by the orchestrator"
  - test: "Remembered tick"
    expected: "After a logout (and after an app restart) the box starts ticked; after an account deletion it starts unticked"
    why_human: "Real SharedPreferencesAsync on the device across process restarts"
  - test: "Own deletion and landing"
    expected: "Settings → Account → «Elimina account» → dialog → Elimina: landing on the login with «Il tuo account è stato eliminato.», never «sessione scaduta»; BE has no user, characters, sessions, push devices; same Twitch account logs in again from zero"
    why_human: "Real BE transaction, real 4409 vs HTTP ordering, DB read"
  - test: "Second device with the same account"
    expected: "The other device lands on the same notice (4409 or refused refresh) within the 15-minute window"
    why_human: "Two devices, live sockets"
  - test: "Innkeeper deletion by username with each refusal"
    expected: "Each of TWITCH_USER_NOT_FOUND, ACCOUNT_NOT_FOUND, INNKEEPER_ACCOUNT_PROTECTED, TWITCH_UNAVAILABLE reads its own line inside the dialog with the text kept and nothing deleted; a real deletion closes the dialog, shows «Account eliminato.», and the online player lands on the account-deleted notice"
    why_human: "Real Twitch lookup, two identities, BE environment manipulation"
  - test: "Started group quest cancelled by a companion's deletion"
    expected: "The remaining member gets the questCancelled push with the BE text verbatim, the quest paper leaves the Map, the pawn is in the city of departure with food, points and life back, the quest is on the Board again, not started"
    why_human: "Real FCM, two devices, a full party at the place"
  - test: "Username dialog with the keyboard in landscape"
    expected: "Field and both buttons visible and usable, no overflow, inline refusal readable"
    why_human: "Real keyboard and real device geometry"
---

# Phase 25: Account Deletion and Legal Consent — Verification Report

**Phase Goal:** the player deletes his own account from Settings with an in-world confirmation and the backend removes everything; on the login the terms and privacy wordings open the public pages and a mandatory checkbox enables the login (ROADMAP Phase 25, companion of BE Phase 26).
**Verified:** 2026-11-25T09:01:19Z — branch `feat/25-account-deletion-and-legal-consent`, HEAD `5e45e8e9`, plans 25-01..25-07 executed, 25-08 (device E2E) not run.
**Status:** human_needed
**Re-verification:** No — initial verification.

**Verdict:** everything that code and tests can prove is in place and wired; no gap found in code or tests. The phase is not closed: the device E2E of plan 25-08 has not run, so nothing below is an observation of the app on a device or against a real backend.

## What was checked, and how

- Read in the code, not in the summaries: every file under `lib/` and `tool/` changed on the branch (`git diff develop..HEAD`), plus the tests named below.
- Re-run by this verification (foreground, targeted, not the full suite):
  - 619 tests green: `test/config`, `test/tool`, `test/graphql/account_documents_test.dart`, the five deletion repository/failure/flow files, `test/repository/services/account`, `test/repository/services/auth`, `test/repository/storage/legal_consent_store_test.dart`, `test/screens/signIn`, `test/screens/auth`, `test/screens/mainScreen/tabs/settings`.
  - 346 tests green: the cancelled-quest paths of plan 25-06 (`characterCubit`, the two Map layer files, the four listeners, `satchel_availability_test.dart`, `quest_availability_test.dart`, `test/repository/services/push`, `inAppNotificationsCubit`).
  - `flutter analyze --no-fatal-infos`: «47 issues found», 0 errors or warnings (baseline).
  - `bash tool/hardening_check.sh`: `hardening_check: OK`.
  - Schema check: 57 documents dumped, 57 × `OK`, exit 0, against `src/schema.gql` of the BE branch `feat/26-eliminazione-account-e-consenso` at `df22b017`, read with `git show` only (no fetch, checkout or edit; output in the session scratchpad).
- Not re-run: the full suite (5691 green is the claim of the gate 25-07, not confirmed here, by policy) and `dart format`.
- Not possible here: anything on a device, a real BE, Twitch, FCM, the browser.

## Goal Achievement

### Observable Truths (roadmap success criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Checkbox with the verbatim sentence above the login button, two wordings open the public pages, footer links gone, login disabled until ticked; acceptance remembered per document version, forgotten only on account deletion | VERIFIED in code and tests; browser and persistence on device pending | `lib/screens/signIn/components/legal_consent_row.dart:8-12,56`; `lib/screens/signIn/sign_in_screen.dart:89,94,181`; no `_LegalFooter` left in `lib/` or `test/`; `lib/screens/signIn/cubit/sign_in_cubit.dart:38-40`; `lib/config/legal_documents.dart:8-14`; `lib/screens/signIn/consentCubit/legal_consent_cubit.dart:24`; `lib/screens/auth/auth_gate.dart:89`. Tests: `test/screens/signIn/sign_in_screen_test.dart` (13 new cases), `test/screens/auth/auth_gate_test.dart` group «consent memory on landing» |
| 2 | Login carries `termsVersion` on `/auth/twitch/start`; the BE refusal reads as its own line | VERIFIED in code and tests; the BE recording version and date is BE-side and device-only | `lib/repository/services/auth/session_auth_token_service.dart:254,277`; `lib/repository/services/auth/login_callback.dart` (`termsNotAcceptedError`); `lib/screens/signIn/cubit/sign_in_cubit.dart:29`; `lib/screens/signIn/sign_in_screen.dart:280`. Tests: `session_auth_token_service_login_test.dart:151,289`, `login_callback_test.dart:39`, sign-in screen «a terms refusal reads its own line» |
| 3 | Own deletion from Settings → Account, last under «Esci», hidden for the innkeeper, one in-world dialog, landing with the notice, no BE call after success, a racing refresh or socket close never lands on «sessione scaduta» | VERIFIED in code and tests; real landing pending | `account_section.dart:56,80,94,109`; `lib/shared/components/modal/delete_account_confirmation_dialog.dart`; `lib/repository/account_deletion_repository.dart:25`; `session_auth_token_service.dart:191,558` (first reason wins, single flight); teardown hook is local only (`lib/bootstrap/app_bootstrap.dart:45`, GraphQL holder reset); the push unregister lives only in `AuthCubit.logout` (`lib/screens/auth/cubit/auth_cubit.dart:56`), which the deletion path never calls. Tests: `test/repository/account_deletion_flow_test.dart:65` (race, both orders, 0 logout calls), `account_section_test.dart` group «Elimina account» |
| 4 | Innkeeper deletes by Twitch username in «Locanda» (dialog with the field, confirmation naming the username, refusals inline); a player deleted while online lands on the same notice | VERIFIED in code and tests; real Twitch lookup pending | `innkeeper_section.dart:52,70`; `player_account_deletion_dialog.dart:92,120,131`; `delete_player_account_confirmation_dialog.dart`; `lib/repository/player_account_deletion_failure.dart`; `session_auth_token_service.dart:406`; `auth_gate.dart:103`. Tests: `player_account_deletion_dialog_test.dart` (9 cases), `innkeeper_section_test.dart`, `dual_session_revocation_test.dart:188` (WS 4409 → `accountDeleted`), `session_auth_token_service_revocation_test.dart:359` |
| 5 | Cancelled started quest: companions back in the city, lane free, refunds as served, quest back on the Board, push with the BE text; no party list, no computation | VERIFIED by tests on the existing reactive paths; no `lib/` change was needed outside Settings | Branch diff touches no file in `lib/screens/mainScreen` or `lib/models` outside `tabs/settings`. Tests tagged D-13/D-23 in `character_cubit_test.dart`, `quest_paper_layer_test.dart`, `character_marker_layer_test.dart`, the four listener files, `quest_availability_test.dart`, `foreground_push_events_test.dart`, `notification_tap_router_test.dart`, `in_app_notifications_cubit_test.dart`. No «avventuriero scomparso» in `lib/` |
| 6 | Schema check green on the merged BE SDL (57 documents), full suite green, device E2E passed, privacy lines in the legal repo | NOT YET — closes with 25-08 | 57 × OK reproduced here on the BE branch `df22b017`, not on BE `develop` (the branch is not an ancestor of the local BE `develop`); full suite green is the gate's claim, not re-run; device E2E not run; D-22 lines are the orchestrator's closing item |

**Score:** 5/6. SC 6 cannot pass before plan 25-08 and is not a code gap.

### Required Artifacts

| Artifact | Provides | Status | Wiring |
|----------|----------|--------|--------|
| `lib/config/legal_documents.dart` | version constant (provisional `2026-11-24`) and the two URLs, one file | VERIFIED | used by `SignInCubit`, `SignInScreen:98`, `AuthGate:88` |
| `lib/repository/storage/legal_consent_store.dart` | `SharedPreferencesAsync` memory under `klimmeck.legal.acceptedVersion` | VERIFIED | built in `klimmeck_guide_app.dart:83`, passed to `AuthGate` at `:240`; allow-listed in `tool/hardening_check.sh:20` |
| `lib/screens/signIn/consentCubit/legal_consent_cubit.dart` | restore / accept / withdraw / forget | VERIFIED | provided by `AuthGate` on every sign-in screen |
| `lib/screens/signIn/components/legal_consent_row.dart` | checkbox, sentence, two links | VERIFIED | in the tree at `sign_in_screen.dart:89` |
| `lib/repository/services/links/` (`link_opener.dart`, `url_launcher_link_opener.dart`) | `LinkOpener` out of `push/` (D-21) | VERIFIED | pure rename (100 % and 89 % similarity); no `services/push/*link_opener` import left in `lib/` or `test/` |
| `lib/repository/services/account/account_deletion_api.dart`, `graphql_account_deletion_api.dart` | abstract API and its GraphQL implementation | VERIFIED | built in `klimmeck_guide_app.dart:281`, delegates to `graphql.dart:741,750` |
| `lib/graphql/mutations/account_mutations.dart` | `DeleteMyAccount`, `DeleteAccountByTwitchLogin` | VERIFIED | registered at `tool/schema_check/schema_check_documents.dart:88-89`; match the BE SDL (below) |
| `lib/repository/account_deletion_repository.dart`, `account_deletion_failure.dart` | own deletion with the silent teardown, code mapping | VERIFIED | provided through the shell (`authenticated_shell.dart:238`) |
| `lib/repository/player_account_deletion_repository.dart`, `player_account_deletion_failure.dart` | innkeeper deletion, four codes | VERIFIED | `authenticated_shell.dart:246` |
| `accountDeletionCubit/`, `playerDeletionCubit/` | the two Cubits | VERIFIED | provided by the shell, read by `AccountSection` and `InnkeeperSection`, both in `settings.dart:53-54` |
| `player_account_deletion_dialog.dart`, the two confirmation dialogs | username dialog, destructive confirmations | VERIFIED | opened from `innkeeper_section.dart:70` and `account_section.dart:109` |
| `lib/config/account_deletion.dart` | switch | VERIFIED | `accountDeletionEnabled = true`, default of both sections |

### Key Link Verification

| From | To | Via | Status |
|------|----|-----|--------|
| `_TwitchLoginButton` | `LegalConsentCubit` | `isEnabled: consent.isAccepted`, `onTap` null while disabled (`sign_in_screen.dart:94,181`) | WIRED |
| Link taps | external browser | recognizers → `SignInCubit.openTerms/openPrivacy` → `LinkOpener.open(LegalDocuments.*Uri)`; real opener `UrlLauncherLinkOpener` at `auth_gate.dart:63` | WIRED |
| Login button | `/auth/twitch/start?termsVersion=` | `signInWithTwitch(acceptedLegalVersion: LegalDocuments.version)` → `login` → `_openLoginPage` | WIRED |
| `?error=terms_not_accepted` | inline line | `_ticketFrom` → `LoginTermsNotAcceptedException` → `SignInFailure.termsNotAccepted` → `_LoginOutcome` | WIRED |
| «Elimina account» | BE mutation | `AccountDeletionCubit` → `AccountDeletionRepository` → `GraphQlAccountDeletionApi` → `KlimmeckGraphQl.deleteMyAccount` | WIRED (shell test «the deletion cubits reach the given API…») |
| Deletion success | login notice | `terminateSession(accountDeleted)` → `AuthUnauthenticated(accountDeleted)` → `SignInNotice.accountDeleted` + `cubit..forget()` | WIRED |
| Refused refresh / WS 4409 | same notice | `_unauthenticatedReasonOf` case `accountDeleted`; 4409 goes through `UnauthorizedRecovery` (`ws_reconnect_policy.dart`) | WIRED |
| «Elimina un account» | BE mutation | dialog → confirmation → `PlayerAccountDeletionCubit.deletePlayer(trimmed)` → repository → API with `{twitchLogin}` | WIRED |
| Two documents | schema check registry | `schema_check_documents.dart:88-89`; `test/tool/schema_check_documents_test.dart:34` pins 57 and equality with every operation declared in `lib/graphql` | WIRED |

### Schema check against the BE branch

| Check | Result |
|-------|--------|
| BE ref | `feat/26-eliminazione-account-e-consenso` = `df22b017`; not merged into the local BE `develop` |
| SDL | `type DeletedAccount { twitchId: String! }` (lines 260-262); `deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!` (582); `deleteMyAccount: Boolean!` (584) |
| FE documents | `mutation DeleteMyAccount { deleteMyAccount }`; `mutation DeleteAccountByTwitchLogin($twitchLogin: String!) { deleteAccountByTwitchLogin(twitchLogin: $twitchLogin) { twitchId } }` — match |
| Registry | 57 documents dumped, 57 × OK, 0 other lines, exit 0 |

### Requirements Coverage

All eight stay unchecked in `REQUIREMENTS.md` by design (25-08 marks them). «Code» = implemented, wired and tested.

| Requirement | Code | Evidence | Still needs the device |
|-------------|------|----------|------------------------|
| ACCOUNT-01 | SATISFIED | order and red outline `account_section.dart:40-56`, innkeeper hidden `:80`, dialog body lists characters incl. archived, balance, portrait, points not given back; spinner on the button only, failure inline, codes from `extensions.code` only; nothing on the creation screen («Elimina account» and `AccountDeletionCubit` appear nowhere outside `tabs/settings` and the shell) | look and copy review |
| ACCOUNT-02 | SATISFIED | repository, terminator, race pin, notice, WS 4409 and HTTP refresh mapping (truths 3, 4) | real landing, second device, restart from zero |
| ACCOUNT-03 | SATISFIED | dialog-only field, confirmation naming the trimmed username, four refusal lines; no username in a Cubit state, in an exception (`toString` prints the outcome only) or in a log (no `appLog`/`print`/`debugPrint` in the new files; the GraphQL service logs no variables) | each refusal against the real BE |
| ACCOUNT-04 | SATISFIED | 346 tests green on the existing paths; no party list, no placeholder | real cancelled quest with the push |
| ACCOUNT-05 | PARTIAL by design | registry 57, switch on, schema check on the BE branch, analyzer, hardening, `BACKEND-NOTES.md` §1-§2-§4 written | schema check on BE `develop` after PR #53, device E2E, D-22 lines |
| CONSENT-01 | SATISFIED | sentence verbatim, checkbox labelled with the sentence, each link its own semantics node (test «announced on their own»), footer gone, login disabled | real browser |
| CONSENT-02 | SATISFIED | `SharedPreferencesAsync`, one constant, restore equals constant only, forget only on `accountDeleted` (gate tests for logout and session expired) | persistence across restarts |
| CONSENT-03 | SATISFIED | `login({required String acceptedLegalVersion})`, query parameter, own failure and line, dev bypass ignores it (`dev_auth_token_service.dart:87`) | BE writing version and date |

No orphaned requirement: the eight IDs mapped to Phase 25 are the eight above.

### Decisions D-01..D-23

| Decision | Status | Evidence |
|----------|--------|----------|
| D-01 one destructive dialog | VERIFIED | `showDestructiveConfirmation` in `delete_account_confirmation_dialog.dart`; no typed word |
| D-02 last, under «Esci», detached, red outline | VERIFIED | `account_section.dart:40-56,88-94`; test «Elimina account is the last button…» |
| D-03 notice verbatim | VERIFIED | `sign_in_screen.dart:17` |
| D-04 same account from zero | BE-side | device step |
| D-05 in-world body | VERIFIED | body text + test «the dialog lists what is lost…» |
| D-06 silent local teardown, failure inline | VERIFIED | `account_deletion_repository.dart:23-26`; flow test counts 0 logouts |
| D-07 sentence, links, disabled login | VERIFIED | truth 1 |
| D-08 URLs through `LinkOpener` | VERIFIED | `legal_documents.dart:10-14` |
| D-09 version sent, refusal handled | VERIFIED (FE side) | truth 2 |
| D-10 device memory, cleared on deletion | VERIFIED | `auth_gate.dart:83-92` |
| D-11 no migration | n/a | nothing built, as decided |
| D-12 one provisional constant | VERIFIED | `legal_documents.dart:8` |
| D-13 / D-23 cancelled started quest | VERIFIED by tests | truth 5 |
| D-14 follows the archive | BE-side | — |
| D-15 innkeeper action in a dialog | VERIFIED | truth 4 |
| D-16 hidden for the innkeeper, BE refuses | VERIFIED | `account_section.dart:80`; code mapped in both failure files |
| D-17 nothing on the creation screen | VERIFIED | grep above |
| D-18 `accountDeleted` reason, fallback | VERIFIED | `session_auth_token_service.dart:395-410`; unknown reason → `sessionExpired` test |
| D-19 `termsVersion`, `terms_not_accepted`, signature | VERIFIED | truth 2 |
| D-20 two mutations, 55 → 57 | VERIFIED on the BE branch | schema check table |
| D-21 `LinkOpener` moved | VERIFIED | `lib/repository/services/links/` |
| D-22 privacy lines | PENDING (orchestrator) | accepted, not a gap |

### Known and accepted (not gaps)

- Schema check on the BE branch `df22b017`, not `develop`: re-run after the BE merge of PR #53.
- Requirements unchecked until 25-08.
- D-22 lines in the legal repo.
- D-18 fallback to «sessione scaduta» after 15 minutes.
- No «Elimina account» on the character-creation screen (D-17); no party list (D-13).

### Anti-Patterns Found

None blocking. No TODO/FIXME/placeholder added in `lib/`, no empty handler, no attribution trailer in the 48 branch commits.

| File | Note | Severity |
|------|------|----------|
| `25-VALIDATION.md` (Wave 0 list) | the line «mocks in `test/helpers/mocks.dart`» is still unticked although the four mocks exist (`test/helpers/mocks.dart:201` and around) and are used; frontmatter `status: draft`, `wave_0_complete: false` | Info — bookkeeping |
| `25-VALIDATION.md` (schema check command) | still names `origin/develop` while the gate ran on the branch | Info |
| `player_account_deletion_dialog.dart:99` | «Annulla» stays enabled while the deletion is in flight: the dialog can be closed and the deletion still completes, with «Account eliminato.» appearing in the section. Not against any decision | Info — to look at during the UAT |
| `legal_consent_cubit.dart:29-37` | the version is remembered when the box is ticked, not when a login succeeds; unticking forgets it. Consistent with D-10 as written | Info |
| `lib/config/account_deletion.dart` | the switch stays in the code, now `true` | Info — declared later cleanup |
| ACCOUNT-04 points refund | no new test for the points: they return through `userUpdated` on the user, an existing path with its own earlier tests; the new character case pins lane, place, food and life | Info |

### Human Verification Required (plan 25-08)

Common setup: BE booted from `feat/26-eliminazione-account-e-consenso` (or `develop` after the merge) with the Twitch credentials in its environment, the FCM topic permission granted, the FE built from this branch; the orchestrator reads the DB.

1. **Real login with the checkbox and the two links.**
   Data: a Twitch account following the channel, no stored acceptance on the phone.
   Do: open the app; try the login unticked; tap each wording; tick; log in.
   Expect: button inert while unticked; each wording opens its page (`/termini`, `/privacy`) in the external browser and does not tick; after the login `users.acceptedTermsVersion = "2026-11-24"` and `users.termsAcceptedAt` set.

2. **Remembered tick.**
   Do: log out; kill and reopen the app.
   Expect: the box starts ticked both times.

3. **Own deletion and landing.**
   Data: a player with a character (ideally also an archived one and a portrait), points balance > 0, a registered push device.
   Do: Settings → Account → «Elimina account» → read the dialog → Annulla once, then Elimina.
   Expect: spinner only on the button; landing on the login with «Il tuo account è stato eliminato.» and the box unticked, never «sessione scaduta»; in the DB no user, no characters, no sessions for him, no `push_devices`, the portrait queued or removed; a new login with the same Twitch account starts from zero (balance 0, creation screen).

4. **Second device with the same account.**
   Data: the same account logged in on two devices (or one device plus a second live session, if the BE allows two).
   Do: delete from device A.
   Expect: device B lands on the same notice within the window (4409 or the next refresh).

5. **Innkeeper deletion by username, each refusal.**
   Data: the innkeeper session; a Twitch name that does not exist; a real Twitch user with no account in the app; the innkeeper's own username; a player with an account, online on a second device; a way to make Twitch unreachable for the BE (credentials left out or network cut).
   Do: Settings → «Locanda» → «Elimina un account» → type each name → Avanti → Elimina.
   Expect: «Nessun utente Twitch con questo nome», «Questo utente non ha un account nella Guida», «Non puoi eliminare l'account di un oste», «Twitch non risponde, riprova più tardi», each inside the dialog with the text kept and nothing deleted; the confirmation names the typed username; the real deletion closes the dialog, the section reads «Account eliminato.», the player's device lands on the account-deleted notice, `admin_audit_logs` has the action. The innkeeper sees no «Elimina account» in his own Account section.

6. **Started group quest cancelled by a companion's deletion.**
   Data: a group quest with the party full and every member at the place (`quests.startedAt` set), two devices; note for the remaining member, before the deletion: rations, life, points, city of departure, and `pendingquests.pointsSpent`, `travelFoodSpent`, `travelHungerLifeLost`.
   Do: one member deletes his account (or the innkeeper deletes him); the other keeps the app in foreground once and in background once if time allows.
   Expect: the `questCancelled` push/banner with the BE title and body verbatim; the quest paper leaves the Map; the pawn is in the city of departure; lane free (Board and shop open); rations, life and points back by the three amounts noted; the quest on the Board again with no registered adventurer, acceptable again. Also the not-started case: the seat is freed and the others keep waiting.

7. **Username dialog with the keyboard in landscape.**
   Do: rotate to landscape, open «Elimina un account», type, provoke one refusal.
   Expect: field, refusal line and both buttons visible and reachable, no overflow stripe.

### Gaps Summary

No gap in code or tests. What separates the phase from closed is entirely plan 25-08: the device E2E above, the schema check re-run on BE `develop` after the BE merge, the D-22 lines in the legal repo, and marking the requirements.

---

_Verified: 2026-11-25T09:01:19Z_
_Verifier: Claude (gsd-verifier)_
