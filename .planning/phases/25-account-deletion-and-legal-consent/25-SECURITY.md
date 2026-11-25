---
phase: 25
slug: account-deletion-and-legal-consent
status: secured-pre-uat
audited: 2026-11-25
scope: plans 01-07 and the code review fixes (plan 08, device UAT, not executed yet)
asvs_level: 1
block_on: high
head: 3cbda46c
threats_total: 36
threats_closed: 32
threats_open: 0
threats_gated: 4
unregistered_flags: 0
unregistered_findings: { high: 0, medium: 0, low: 1, info: 8 }
---

# Phase 25 Security Audit (plans 01-07, after the review fixes)

Read-only audit of `git diff 5c0b1b80..HEAD -- lib tool` at HEAD `3cbda46c` (the code after `25-REVIEW-FIX.md`). No source file touched, no `.env` or `env/*.json` read, no app launch, BE repo read only (`git status --short` empty).

`asvs_level` and `block_on` are not in `.planning/config.json` nor in the brief: the values of the last FE audit (`22-SECURITY.md`: L1, block on high) are kept.

What was run:
- `bash tool/hardening_check.sh` -> `hardening_check: OK`.
- One foreground `flutter test` over 12 files (account section, innkeeper dialog and its cubit, deletion flow and repository, `terminateSession`, auth gate, sign-in screen, login callback, login service, legal documents, consent store): `+149: All tests passed!`.
- A `dart run` probe outside the repo on `Uri.replace(queryParameters:)` with five hostile `termsVersion` values (see U-6).

Everything else is evidence by reading: `file:line` of the source and the test that pins the behaviour (tests not in the list above were read by name and line, not re-run; their green is the one declared by `25-REVIEW-FIX.md`, full suite 5694).

Verdicts: CLOSED = mitigation found in the code (or accepted / transferred as declared, with its entry below). GATED = belongs to plan 25-08 (device UAT), which has no SUMMARY yet.

The six SUMMARY files with a `## Threat Flags` section (01, 02, 03, 04, 05, 07; 06 has none) all declare «none beyond the plan's register»: no unregistered flag.

## Threat verification

| Threat | Disp. | Mitigation found | Evidence | Verdict |
|---|---|---|---|---|
| T-25-01 | mitigate | only the two constant URIs reach the opener | `lib/config/legal_documents.dart:10-18` (https constants); `sign_in_cubit.dart:38-40`; the only `launchUrl` in `lib` is `url_launcher_link_opener.dart:14` (`LaunchMode.externalApplication`); the three callers of `LinkOpener.open` pass `TwitchChannel.uri`, `termsUri`, `privacyUri` only; tests `legal_documents_test.dart:5,12`, `sign_in_cubit_test.dart:58,66`, `sign_in_screen_test.dart:162,173` | CLOSED |
| T-25-02 | transfer | the checkbox is UX; the BE refuses a login without a well-formed `termsVersion` | BE `26-SECURITY.md` T-26-04, T-26-05, T-26-06 (CLOSED) | CLOSED (transferred) |
| T-25-03 | accept | a version string only, under one key | `legal_consent_store.dart:21-33`; accepted risk A-1 | CLOSED (accepted) |
| T-25-04 | mitigate | the move is imports only | commit `5ca43ba3`: 2 renames, 5 import lines, and the path string of `push_boundaries_test.dart`; no behaviour line | CLOSED |
| T-25-10 | mitigate | the app ends on the refusal, HTTP and WS alike | `session_auth_token_service.dart:383-386,396-410`; WS 4409 goes through the same recovery (`ws_reconnect_policy.dart:8,36`); tests `session_auth_token_service_revocation_test.dart:359`, `dual_session_revocation_test.dart`; BE T-26-09, T-26-10 | CLOSED |
| T-25-11 | accept | the reason is read only from the BE's refresh answer; unknown -> `sessionExpired` | `auth_api_exception.dart:100-103`, `session_auth_token_service.dart:408`; test `..._revocation_test.dart:384,410`; accepted risk A-2 | CLOSED (accepted) |
| T-25-12 | mitigate | consent forgotten when the `accountDeleted` reason arrives, sign-in already shown or not (WR-02 fix) | `auth_gate.dart:47-50,60-64,90-97`; `legal_consent_cubit.dart:26-30,40-44`; tests `auth_gate_test.dart:265,273,298,307`, `legal_consent_cubit_test.dart:116` (re-run, green) | CLOSED |
| T-25-13 | mitigate | the only exhaustive switch on the enum has the new arm; the service switch has a default | `auth_gate.dart:99-109`, `session_auth_token_service.dart:402-409`; analyzer at its baseline (REVIEW-FIX) | CLOSED |
| T-25-20 | mitigate | one destructive dialog, not barrier-dismissible, Annulla deletes nothing, single flight | `destructive_confirmation_dialog.dart:61-71`; `account_section.dart:108-112`; `account_deletion_cubit.dart:20`; tests `account_section_test.dart:280,290,318`, `account_deletion_cubit_test.dart:69` | CLOSED |
| T-25-21 | mitigate | after success the repository only calls the terminator; the teardown is local | `account_deletion_repository.dart:23-26`; `session_auth_token_service.dart:561-567` (no API call), `app_bootstrap.dart:45` (`graphQlHolder.reset()`), `push_registration_coordinator.dart` (`AuthUnauthenticated` -> local end only); tests `account_deletion_repository_test.dart:43`, `session_auth_token_service_terminate_test.dart:84,105`. See U-1 for the one path that still reaches the BE | CLOSED |
| T-25-22 | mitigate | first reason wins, one terminal state, both orders | `session_auth_token_service.dart:558-559` (`_endInFlight`); tests `account_deletion_flow_test.dart:65,82` (re-run, green); «Esci» inert during the deletion (WR-01 fix) `account_section.dart:30-32,40-42,49`, test `account_section_test.dart:344`. See U-1 | CLOSED |
| T-25-23 | transfer | hidden button is UX (`account_section.dart:80-83`, live `BlocSelector` on the role); the BE refuses | BE T-26-21, T-26-30 (role read from the DB in the transaction); code mapped `account_deletion_failure.dart:37`; test `account_section_test.dart:273` | CLOSED (transferred) |
| T-25-24 | mitigate | codes only, fixed Italian lines | `account_deletion_failure.dart:28-40`, `player_account_deletion_failure.dart:35-50`, the two `*_messages.dart`; `getGenericErrorMessage` is not on these paths; tests `account_deletion_failure_test.dart`, `player_account_deletion_failure_test.dart:14-42` | CLOSED |
| T-25-25 | mitigate | the two documents were registered only in the gate plan | `schema_check_documents.dart:88-89`, `schema_check_documents_test.dart:34` (57); the switch was removed after the gate (IN-01, `1843d657`). Gate ref = BE branch at `df22b017`, to re-run on BE `develop` (25-08) | CLOSED |
| T-25-30 | mitigate | the confirmation names the trimmed username, and the very same value is sent | `player_account_deletion_dialog.dart:138-143` (captured before the modal confirmation), `delete_player_account_confirmation_dialog.dart:11-15`; tests `player_account_deletion_dialog_test.dart:108,127,139`; BE audit log T-26-40 | CLOSED |
| T-25-31 | transfer | the entry is visible only to the innkeeper role (`innkeeper_section.dart:24-27`, UX); `FORBIDDEN` reads the generic line | BE T-26-38 (`@Roles(innkeeper)`, refusal before any resolution) | CLOSED (transferred) |
| T-25-32 | transfer | `INNKEEPER_ACCOUNT_PROTECTED` mapped (`player_account_deletion_failure.dart:46-47`) | BE T-26-21, T-26-39 | CLOSED (transferred) |
| T-25-33 | mitigate | the text lives in the dialog's controller only | controller owned and disposed `player_account_deletion_dialog.dart:42-48`; state without a username `player_account_deletion_state.dart:4-17`; exception prints the failure name `player_account_deletion_failure.dart:24-32` (test `..._failure_test.dart:87`); `performMutation` is `FetchPolicy.noCache` over an `InMemoryStore` and logs nothing (`graphql.dart:100-111,750-757`); zero `appLog/print/debugPrint` added by the phase diff; no crash-reporting package in `pubspec.yaml`; no store write, no route argument. See U-5 | CLOSED |
| T-25-34 | accept | trimmed only; the BE validates (`^[A-Za-z0-9_]{1,25}$`, cap 64, BE T-26-35) | `player_account_deletion_dialog.dart:138`; accepted risk A-3 | CLOSED (accepted) |
| T-25-35 | transfer | — | BE T-26-40 (admin audit log, arguments redacted, target = Twitch ID, 90 days) | CLOSED (transferred) |
| T-25-40 | transfer | the refusal is mapped to its own line | BE T-26-04..06; `session_auth_token_service.dart:277-278`, `sign_in_cubit.dart:29-30`; tests `sign_in_cubit_test.dart:110`, `sign_in_screen_test.dart:304` | CLOSED (transferred) |
| T-25-41 | mitigate | the parser is total; scheme and host checked; only the known code maps to the new exception, every other code stays opaque | `login_callback.dart:51-66`; `session_auth_token_service.dart:269-280`; `sign_in_cubit.dart:31-33` (never rendered, never logged); tests `login_callback_test.dart:39,47,55`, `session_auth_token_service_login_test.dart:289` (re-run, green). See U-4 | CLOSED |
| T-25-42 | accept | the version is a public constant; no logging added; every auth log prints `runtimeType` only | `session_auth_token_service.dart:319,331,416,470,526,573,581`; accepted risk A-4 | CLOSED (accepted) |
| T-25-43 | mitigate | the BE under test accepts the parameter; an older BE ignores it | `BACKEND-NOTES.md` §1 C-4 (gate `df22b017`); test `session_auth_token_service_login_test.dart:151` | CLOSED |
| T-25-50 | mitigate | no computation added: plan 06 touched no `lib` file outside tests | `git diff 5c0b1b80..HEAD --stat -- lib/screens/mainScreen lib/models` lists only the Settings files of plans 03-04 | CLOSED |
| T-25-51 | mitigate | no party list, no placeholder; the push body is the BE's | `grep -rniE "avventuriero scomparso|partyMembers" lib` empty; tests `foreground_push_events_test.dart:85`, `in_app_notifications_cubit_test.dart:207` | CLOSED |
| T-25-52 | accept | router unchanged: known categories, one constant URI | `notification_tap_router.dart:21-29`, `push_event.dart:26-41`; accepted risk A-5 | CLOSED (accepted) |
| T-25-60 | mitigate | the gate ran first (25-07 SUMMARY), on the BE branch as a sanctioned deviation | `BACKEND-NOTES.md` §1; `25-REVIEW-FIX.md` «Final numbers» (57 x OK) | CLOSED |
| T-25-61 | mitigate | no rename: FE documents equal the contract | `account_mutations.dart:4-17` vs CONTEXT D-20 | CLOSED |
| T-25-62 | mitigate | BE working tree untouched | `git -C <BE> status --short` empty at this audit | CLOSED |
| T-25-63 | mitigate | names only | secrets grep over the phase directory (URIs with credentials, JWTs, bearer values, API keys): empty | CLOSED |
| T-25-64 | transfer | the app ends on the refusal (T-25-10) | BE T-26-09, T-26-10 | CLOSED (transferred) |
| T-25-70..73 | mitigate | plan 25-08 (device UAT, `mark-complete`) not executed | the requirements are still `Pending` in `REQUIREMENTS.md` (correct for T-25-71) | GATED |

Totals: 32 closed (20 mitigated, 7 transferred, 5 accepted), 0 open, 4 gated.

## Accepted risks log

| ID | Threat | Risk | Why it is acceptable |
|---|---|---|---|
| A-1 | T-25-03 | The device keeps `klimmeck.legal.acceptedVersion` = the version string, in plain `SharedPreferencesAsync`. | Not personal, not a secret: a public constant. The file is on the `tool/hardening_check.sh` allow-list (line 20) and the token grep of the same script passes. Fail-closed read: an unreadable store or another version starts unticked (`legal_consent_cubit.dart:26-30,46-52`). |
| A-2 | T-25-11 | A forged reason could choose the notice. | The reason is read only from the refresh answer of the BE over TLS; the WS close code carries no reason into the app (it only triggers the refresh). The notice reveals nothing and an unknown value is «sessione scaduta». |
| A-3 | T-25-34 | The app sends whatever the innkeeper typed, trimmed, with no length cap. | Rule 4: the BE validates shape and length before any outbound call (BE T-26-35) and the refusals are mapped. GraphQL variable, never concatenated into the document (`graphql.dart:752-755`). |
| A-4 | T-25-42 | The version travels in a URL (browser history, proxies). | Public constant; no token travels in that URL (`challenge` is the PKCE challenge, not the verifier). |
| A-5 | T-25-52 | A push could try to steer the tap. | A data-only push with a known `type`; personal types land on the Map, the only URL ever opened is `TwitchChannel.uri`. Title and body are rendered as plain `Text` (`kg_notification_banner.dart:57-73`) and as the plain strings of the system notification (`flutter_local_notifications_adapter.dart:54-60`): no link, no markup. |
| A-6 | D-18 fallback | After the BE's 15-minute window (or a BE restart inside it) the deleted player lands on «sessione scaduta» and the device keeps the consent memory. | Declared in `BACKEND-NOTES.md` §4 and BE R-3; the memory is not personal data; the next login is a new account that must carry the version anyway. |

## Beyond the register: what was checked

- **Twitch username typed by the innkeeper.** Path: `TextEditingController` (dialog state) -> `trim()` -> confirmation dialog (plain `Text`) -> `PlayerAccountDeletionCubit.deletePlayer` (argument, never in the state) -> repository -> GraphQL variable. Not logged anywhere on the path (`grep twitchLogin lib`: 20 hits, all parameters or the variable map); the two exceptions carry an enum only; `OperationException` is caught in the repository and never printed; `noCache` keeps the variable out of the GraphQL store; no `RouteSettings.arguments`; the success line is «Account eliminato.» without the name (`innkeeper_section.dart:74-91`). The controller is disposed with the dialog, which closes on success, on «Annulla» and on any session end (`auth_gate.dart:53-59`, `popUntil`). `autocorrect: false`, `enableSuggestions: false`; the keyboard's «done» action does not submit (no `onSubmitted`).
- **Session material around the own deletion.** `terminateSession(accountDeleted)` -> `_performEndSession`: epoch bumped, timers cancelled, in-memory access and refresh tokens dropped, `onSessionTeardown` (`graphQlHolder.reset()`: socket disposed, new client and store), `SessionStore.clear()`, then the terminal state. No API call in that sequence. No token is ever logged (every `appLog` of the service prints a type name). The push coordinator reacts to `AuthUnauthenticated` with a local end only.
- **Consent.** One caller of `AuthTokenService.login` in `lib` (`sign_in_cubit.dart:21`), one caller of `signInWithTwitch` (`sign_in_screen.dart:96`), reached only through `InkWell.onTap`, which is `null` while unticked or loading (`:181`); the wrapping `Semantics` has `excludeSemantics: true` and no `onTap`, so no accessibility action bypasses it. The value passed is `LegalDocuments.version` (`:98`), pinned to the BE format by `legal_documents_test.dart:19`. No deep link, push or route starts a login. The dev bypass ignores the version and is kept out of release builds by `hardening_check.sh`.
- **`termsVersion` on the wire.** Built with `Uri.replace(queryParameters: {...})` (`session_auth_token_service.dart:249-256`), which percent-encodes each value: no parameter injection even with a hostile value (probe, U-6). The start URL host comes from the injected `backendBaseUrl`, never from input.
- **Callback.** `parseLoginCallback` accepts only `klimmeck://auth`, never throws; `error=terms_not_accepted` yields one fixed Italian line, any unknown code yields the connection line; the code is never rendered, logged or used to build a URL; nothing in the callback is opened or navigated (no open redirect on the app side; the BE side is T-26 «Consenso»). A ticket is useless without the PKCE verifier held in memory by the login in flight.
- **Legal links.** Two `static const` https URLs, parsed once, opened with `LaunchMode.externalApplication`; the cubit methods take no argument.
- **Client-side-only protections and the BE rule behind each.** Hidden «Elimina account» for the innkeeper -> BE T-26-21/30 (role read from the DB inside the transaction). «Elimina un account» visible only to the innkeeper -> BE T-26-38 (`@Roles(innkeeper)`) and T-26-39 (innkeeper target refused). Disabled login while unticked -> BE T-26-04/06 (version mandatory and pattern-checked, on the start and on the signed state). Both deletions are `@Throttled` on the BE; the app has no client-side limit and needs none.
- **Push body of `questCancelled`.** Parsed as a non-empty `String`, shown verbatim in two plain `Text` widgets (2 lines, ellipsis) and in the system notification; the only `TextSpan` users in `lib` are the consent row, the splash and `healed_injuries_text.dart`, none fed by a push.
- **Accidental or racing destructive actions.** Own deletion: modal confirmation, `barrierDismissible: false`, spinner disables the button, cubit single flight, «Esci» and «Elimina personaggio» inert while it runs (WR-01, test re-run green). Innkeeper deletion: «Avanti» disabled while blank or deleting, modal confirmation naming the user, `PopScope(canPop: !isDeleting)`, «Annulla» inert in flight, `reset()` a no-op in flight (WR-03, three tests re-run green). The confirmed name cannot change between confirmation and send (captured before the modal dialog). WR-02 holds (test re-run green). One residual race: U-1.

## Unregistered findings

No finding of severity high or medium.

| ID | Severity | Finding | Recommendation |
|---|---|---|---|
| U-1 | low | **The mirror of WR-01 is still open: a logout already in flight does not disable «Elimina account».** `AuthCubit.logout()` (`auth_cubit.dart:55-58`) first waits for the push unregister (up to 2 s) and then for the BE logout (up to 4 s); Settings stays on screen with every button live, because nothing exposes «logout in flight» to `AccountSection` (`account_section.dart:30-32` watches only the account deletion). If the player confirms «Esci» and then, inside that window, taps and confirms «Elimina account»: (a) the deletion answers during the push-unregister step -> the landing is `accountDeleted`, then `logout()` still runs `_endSession(signedOut)` (`session_auth_token_service.dart:175-180`) and the notice «Il tuo account è stato eliminato.» is replaced by none; (b) it answers during the BE logout step -> `terminateSession` is a no-op (`:192`), the landing is a plain logout, the consent memory is **kept**, and the BE logout may be sent with a bearer the deletion has just killed (the call D-06 forbids; the BE refuses it). In both cases the account is deleted as the player asked: no data leak, no unintended deletion, only a wrong landing (D-03, D-10). Needs two confirmation dialogs within about 6 s. Derived from the control flow, not reproduced in a test. | Either expose a logout-in-flight flag (for example a `bool` state around `confirmLogout` in the section, or a getter on `AuthCubit`) and give all three buttons `onPressed: null` while it is set; or make the end of `logout()` keep an `accountDeleted` terminal state that arrived meanwhile (`_performLogout`: skip `_endSession(signedOut)` when the channel is already `AuthUnauthenticated`). A widget test like the WR-01 one. Otherwise accept. <br>Closed after the audit (2026-11-25): `a288021c` (session: a logout keeps a session already ended as `accountDeleted`; tests `6d813673`) and `cdf90d97` (Account buttons inert while a logout runs; test `9da45886`). |
| U-2 | info | **The consent memory belongs to the device, not to the account, and a logout keeps it (D-10).** A second person who logs in with another Twitch account on the same phone finds the box already ticked, and the BE records version and date for an account whose owner never ticked it. | User decision (D-10); state it in the privacy page line of D-22. A stricter variant (forget on every logout) is a one-line change in `AuthGate` if ever wanted. |
| U-3 | info | **The consent gate lives in the widget only.** `SignInCubit.signInWithTwitch` does not consult `LegalConsentCubit`; today its single caller is the gated button. The BE cannot tell a ticked box from a client that just sends a well-formed string (BE U-05). | None; keep the single-caller property in mind when adding any other login entry point. |
| U-4 | info | **`klimmeck://auth` is a custom scheme (pre-existing, `AndroidManifest.xml:31-42`, not changed by the phase).** While a login is pending, any app or web page on the phone can deliver a crafted callback, or register the same scheme. With `error=terms_not_accepted` the only effect is the inline line «Accetta i Termini…»; with a ticket the redemption fails without the PKCE verifier; a hijacking app receives a ticket it cannot redeem. | None for this phase. Android App Links (verified https) would remove the class, if ever wanted. |
| U-5 | info | **What the app cannot control about the typed username.** The system keyboard may still learn the text despite `autocorrect`/`enableSuggestions` off; the confirmation dialog shows it on screen (screenshots, recents); the string lives in memory until collected. No length cap in the field (the BE caps at 64, `TWITCH_USER_NOT_FOUND`). | Optional: `maxLength`/`inputFormatters` matching the Twitch shape, purely UX. |
| U-6 | info | **No test pins the encoding of `termsVersion`.** The only pinned URL uses a harmless value (`session_auth_token_service_login_test.dart:151`). Probe run for this audit: `a&role=innkeeper`, `x#frag`, `a b?c=d`, `é%26&challenge=evil` all come out as one encoded `termsVersion` value with exactly two parameters and round-trip intact. The production value is a constant matching `^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$`. | Optional one-line test with a value containing `&` and `=`. <br>Closed after the audit (2026-11-25): `2d8c7188` (two hostile values pinned as one encoded `termsVersion`). |
| U-7 | info | **The schema gate ran on the BE branch, not on BE `develop`** (sanctioned deviation, `BACKEND-NOTES.md` §1). If the merged SDL differed, both deletions would fail with a validation error (fail-closed: nothing is deleted). | Re-run the schema check on BE `develop` after the BE merge (already planned in 25-08, T-25-73). |
| U-8 | info | **The legal promise is not complete yet.** `LegalDocuments.version` is the provisional `2026-11-24` (D-12) and the two privacy lines of D-22 (version and date stored on the account; acceptance remembered on the device and kept by a logout) are still to be written by the orchestrator. | Before the public release: real date in the constant and in the pages, D-22 lines published. |
| U-9 | info | **BE findings that touch what the app shows.** BE U-03 (deletion by name is irreversible; a mistyped name that matches another player deletes the wrong account): the FE confirmation naming the typed user is the only guard, there is no resolve-then-confirm step. BE R-5: a demoted innkeeper keeps the action for up to 15 minutes (the FE section hides live on `userUpdated`, UX only). | Decide with the BE whether an `expectedTwitchId` / two-step flow is wanted; otherwise accept with an innkeeper procedure. |

## Counts

- Threats: 36. Closed 32 (mitigated and verified in the code 20, transferred to the BE and documented there 7, accepted with a log entry 5). Open 0. Gated on plan 25-08: 4 (T-25-70..73).
- Accepted risks in the log: 6 (A-1..A-5 for the five `accept` threats, A-6 for the declared D-18 fallback).
- Unregistered findings: high 0, medium 0, low 1 (U-1), info 8.
- Verdict: **SECURED (pre-UAT)** at ASVS L1, nothing blocking. U-1 is to fix or to accept knowingly; T-25-70..73 close with plan 25-08.
