# Phase 25: Account Deletion and Legal Consent - Context

**Gathered:** 2026-11-24 (interactive discuss, joint with the BE Phase 26 «Eliminazione account e consenso»; this file is authoritative for both, same numbering D-01..D-16)
**Amended:** 2026-11-24 after the two researches (`25-RESEARCH.md`, BE `26-RESEARCH.md`) and the user's rulings of the same day: D-13 replaced, D-06/D-12/D-15 revised, D-17..D-23 added.
**Status:** Ready for planning — branch `feat/25-account-deletion-and-legal-consent` off `develop`; BE branch `feat/26-eliminazione-account-e-consenso` off `develop`.

<domain>
## Phase Boundary

1. **Account deletion by the player:** «Elimina account» in Settings, one confirmation, the backend permanently deletes the account and everything tied to it, the player lands on the login.
2. **Account deletion by the innkeeper:** an action in the innkeeper section of Settings that deletes a player's account from the Twitch username (the «senza l'App» path of the legal pages, requested by email).
3. **Legal consent on the login:** the terms and privacy wordings open the public pages, a mandatory checkbox enables the login, the backend records the accepted version and its date.

The public legal pages (repo `LucaTabbia/klimmeck-guide-legal`, local clone `~/Personale/Code/klimmeck-guide-legal`) already promise all of this: until this phase ships they are not true.

Out of scope: data export/portability, a re-acceptance flow when the documents change, a cool-down before re-registration, age verification, iOS, any change to the legal texts beyond what D-08 requires.

</domain>

<decisions>
## Implementation Decisions

### Carried forward (not re-asked)
- The backend is the source of truth (rule 4): the app only asks for the deletion and reacts. Settings and login are utility screens (chrome allowed).
- What is deleted and what stays is fixed by the roadmap goal and by `elimina-account.md`: user (Twitch ID, points balance), every character including the archived ones (progress, items, spells, companions, unlocked lore), portrait on Cloudinary, sessions, push devices; the innkeeper's action log (TTL 90 days) and the DB backups (30 days) stay until their TTL.
- Deletion is immediate and the player leaves the app at the confirmation (legal page, verbatim: «L'account viene eliminato subito e, alla conferma, esci dall'App»).
- Seats in lanes and requests are freed as the character archive does today (BE `CharacterArchiver`, `seat-release.ts`).
- Non-additive SDL changes are declared in the BE handoff; FE plans that select new fields are gated on the BE merge. One-off migrators leave the repo; no content file in either repo.

### Confirmation and exit
- **D-01 (user, «Dialog semplice»):** one destructive dialog, same component and weight as «Elimina personaggio» (`showDestructiveConfirmation`): title, body, Annulla / Elimina. No typed word, no second dialog (the recommended typed word was rejected).
- **D-02 (user):** the «Elimina account» button is the last of the Account section, under «Esci», detached, red outline (order: Elimina personaggio → Esci → Elimina account).
  - **Amended in the device UAT (user, 2026-11-25):** «Nella sezione impostazioni metterei i tasti pericolosi (eliminazione personaggio e account) dentro una dropdown. Già che ci siamo raggruppiamo le cose sotto diverse dropdown, lasciando il tasto esci in fondo alla pagina» and «Usa le dropdown dell'app, sempre». As built: the sheet is three closed app `Dropdown`s («Notifiche», «Locanda» for the innkeeper, «Azioni irreversibili» with «Elimina personaggio» then «Elimina account») and «Esci» last on the sheet. The name «Azioni irreversibili» and the innkeeper's «Elimina un account» staying under «Locanda» are the orchestrator's choices, shown to the user on the device.
- **D-03 (user):** after a successful deletion the player lands on the login with an inline notice above the login button, like the existing `SignInNotice` lines: «Il tuo account è stato eliminato.»
- **D-04 (user):** the same Twitch account may log in again at once and starts from zero (balance 0, no character, creation from scratch). The BE keeps no trace of the deleted Twitch ID and applies no wait.
- **D-05 (technical default):** the dialog text is written in-world by Claude and lists what is lost (all characters including the archived ones, the points balance, the portrait) and that converted channel points are not given back; it must not contradict `elimina-account.md`.
- **D-06 (technical default, revised after the research, C3):** the local teardown after the deletion is NOT `AuthCubit.logout()` (it would unregister the push device and call the BE logout with a dead token, landing on «sessione scaduta»): it is the local teardown of a revocation with the new reason `accountDeleted` (`SessionTerminator.terminateSession`), plus the consent memory of D-10. The app makes no call to the BE after the deletion succeeded; the BE removes the push devices itself. A failed deletion keeps the player in Settings with an inline error under the button, as the character deletion does; the spinner on the button is an explicit user action (rule 2 respected).

### Legal consent on the login
- **D-07 (user, «Frase con link, senza età»):** above the login button, one checkbox with the sentence «Accetto i Termini di servizio e l'Informativa sulla privacy», the two wordings tappable; the two links at the bottom of the login disappear. No mention of the minimum age in the sentence. The login button is disabled while the box is empty.
- **D-08:** «Termini di servizio» opens https://lucatabbia.github.io/klimmeck-guide-legal/termini and «Informativa sulla privacy» opens https://lucatabbia.github.io/klimmeck-guide-legal/privacy, in the external browser through the existing `LinkOpener` (technical default).
- **D-09 (user, «Sì, versione e data»):** the BE records on the user the accepted version of the documents and the date of the acceptance. The login carries the accepted version; a login without it is refused by the BE (the checkbox is not only a client-side gate). The privacy page must then mention this datum (a line in the legal repo, to be done with the phase).
- **D-10 (user, «Ricordata sul dispositivo»):** once accepted, the device remembers it: at the next logins on that phone the box starts already ticked. The memory is cleared when the account is deleted (technical default) and holds for one version of the documents: a new version starts unticked again.
- **D-11 (user, verbatim):** «Non è pubblicata l'app, caso impossibile» — there are no existing users with a live session to handle: no migration, no in-session acceptance page, no forced logout. The acceptance fields are simply required from this phase on (dev/test users in the DB are the orchestrator's concern at the real boot).
- **D-12 (technical default; value by the user, verbatim: «Non è importante, non è ancora pubblicata. Quando arriverà il momento modificherò la data mettendo quella reale»):** the version of the documents is one constant in the app, a date string with a provisional value the user will replace at the launch together with the `[DATA DI PUBBLICAZIONE]` placeholder of the legal pages (not touched by this phase), sent with the login; the BE stores what it receives with its own clock. No endpoint serving the current version, no re-acceptance flow (deferred).

### Traces for the other players
- **D-13 (user, 2026-11-24 — REPLACES the «Segnaposto anonimo» of the discuss, after the BE research showed that today's placeholder fights with the stats of a document that would no longer exist):** verbatim: «La missione viene annullata automaticamente e i giocatori vengono riportati gratuitamente alla città di partenza con una notifica. Vengono rimborsati del cibo speso per il tragitto» and «Con quest già avviata si intende che tutti i personaggi hanno già raggiunto il luogo della quest, gli slot erano pieni e quindi è effettivamente cominciata la quest. In caso contrario i giocatori attendono semplicemente che un nuovo utente riempia lo slot lasciato vuoto».
  - Quest effectively started (party full, everyone at the place): cancelled for everybody; the remaining members go back at once and for free to the city they left from for that quest, receive a push and are refunded **the food of the trip, the points spent to accept the quest and the life points lost to hunger on the way** (user, «Cibo, punti e vita persa per fame»); the quest **goes back on the board** not started, free for a new party (user, «Torna sul tabellone»).
  - Exception (user, «Si risolve come oggi»): an aid already started whose only wounded is the deleted character concludes with today's rules, no return and no refund for the rescuers.
  - Quest not effectively started: the seat is freed and the others keep waiting for a new player.
  - Only for the account deletion (own or by the innkeeper): «Elimina personaggio» keeps today's placeholder.
  - No party list exists in the app (only seat counts) and none is added: the wording «Un avventuriero scomparso» is dropped.
- **D-14 (technical default):** everything else follows the archive: unstarted seats freed, GM requests of the character deleted, the wounded removed from open aid quests, rescuers released; a guided mission the innkeeper is running loses that participant as it would for an archived character. Quest results are one per character and per user: the deleted player's own are deleted, the others' carry no name of his (verified on `quest-result.model.ts`).

### Deletion by the innkeeper and the innkeeper's own account
- **D-15 (user, «Azione nel pannello oste»; revised after the research, C5: the field lives in a dialog, since the Settings tab does not resize for the keyboard):** in Settings → innkeeper section, an action that opens a dialog with a field for the Twitch username, then the confirmation; the BE resolves the username to the Twitch ID (it stores only the numeric ID) and runs the very same deletion, written in the innkeeper's action log. A player deleted while online goes back to the login with the notice of D-03 (technical default; if the revocation cannot tell the reason, the planner states the fallback). Unknown username or no account → an inline error, nothing deleted.
- **D-16 (user, «No, pulsante nascosto»):** the innkeeper cannot delete his own account from the app: «Elimina account» does not appear for the innkeeper role and the BE refuses the request (own mutation and the innkeeper action aimed at an innkeeper). The innkeeper's account is removed only by hand.

### Added after the research
- **D-17 (user, «Solo in Impostazioni»):** a user with no character cannot reach Settings (they exist only with a character) and gets no «Elimina account» elsewhere: the creation screen keeps only «Esci». Such an account is deleted through the email path (D-15).
- **D-18 (BE research, N3):** new revocation reason `accountDeleted` → new `UnauthenticatedReason` and `SignInNotice` with the D-03 text. The BE answers a refresh with `SESSION_REVOKED` + `extensions.reason = "accountDeleted"` and closes the sockets with 4409 for 15 minutes after the deletion; afterwards (or after a BE restart) the fallback is the session-expired notice. This serves the player deleted by the innkeeper while online.
- **D-19 (BE research, N4):** the accepted version travels as the query parameter `termsVersion` on `GET /auth/twitch/start` (format `^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$`); a missing or bad one comes back as a redirect to the app with `?error=terms_not_accepted`, mapped to an inline login error. The dev bypass is exempt. The login signature becomes `login({required String acceptedLegalVersion})` (C4: the Phase 11 comment «the signature never changes» is updated; the stubs in the tests follow).
- **D-20 (BE research, N1/N2):** mutations `deleteMyAccount: Boolean!` (errors `INNKEEPER_ACCOUNT_PROTECTED`, `UNAUTHENTICATED`) and `deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!` with `DeletedAccount { twitchId: String! }` (errors `TWITCH_USER_NOT_FOUND`, `ACCOUNT_NOT_FOUND`, `INNKEEPER_ACCOUNT_PROTECTED`, `TWITCH_UNAVAILABLE`). Names final only at the BE merge: the selections are gated on the schema check (registry 55 → 57 documents).
- **D-21 (Boy Scout, in scope):** `LinkOpener` moves out of `repository/services/push/` (imports only, six files, its own commit).
- **D-22 (legal repo, with the phase):** two lines in `privacy.md` — the accepted version and its date stored on the account, and the acceptance remembered on the device, which a logout no longer clears. The publication date placeholder stays (D-12).
- **D-23 (BE research addendum):** for a cancelled started quest (D-13) the app receives the existing `questCancelled` push with a new body text written by the BE, `characterUpdated` for each member sent back (lane free, position in the city, food, points and life refunded) and `questUpdated` for the quest back on the board. No SDL change and no dangling registration: the FE work is to prove with tests that the existing reactive paths draw it (and fix what does not), not to build new UI.

### Claude's Discretion
- Exact in-world wording of dialog, notice, errors and placeholder (within D-03, D-05, D-07, D-13 verbatim strings).
- Cubit/repository split, mutation and field names, error codes, where the consent memory is stored (`shared_preferences` is the natural place).
- Layout details of the checkbox row and of the innkeeper action (retouched on the device at UAT, as usual).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Legal pages (the promise this phase keeps)
- `~/Personale/Code/klimmeck-guide-legal/elimina-account.md` — what is deleted, what stays and for how long, the in-app steps
- `~/Personale/Code/klimmeck-guide-legal/privacy.md` §6–§7 — retention table, deletion paths
- `~/Personale/Code/klimmeck-guide-legal/termini.md` — acceptance clause, «Elimina account» from Settings

### Project rules
- `CLAUDE.md` — non-negotiable rules 1–5
- `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/workflow.md`

### Handoff
- `.planning/phases/25-account-deletion-and-legal-consent/BACKEND-NOTES.md` — what the app expects from BE Phase 26
- BE repo `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/.planning/phases/26-eliminazione-account-e-consenso/26-CONTEXT.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/settings/components/account_section.dart` — Account section with «Elimina personaggio» (cubit, spinner, inline error) and «Esci»: the model for the new button.
- `lib/shared/components/modal/destructive_confirmation_dialog.dart`, `delete_character_confirmation_dialog.dart`, `logout_confirmation_dialog.dart` — the confirmation dialog of D-01.
- `lib/screens/mainScreen/tabs/settings/deletionCubit/` — `CharacterDeletionCubit`, the pattern for the account deletion cubit.
- `lib/screens/signIn/sign_in_screen.dart` — `SignInNotice` enum and `_Notice` (D-03), `_LegalFooter` with two empty `onPressed` (replaced by D-07), `_TwitchLoginButton`.
- `lib/repository/services/push/url_launcher_link_opener.dart` (`LinkOpener`) — external browser, already injected in `auth_gate.dart`.
- `lib/screens/auth/cubit/auth_cubit.dart`, `lib/repository/services/auth/session_terminator.dart`, `push_session_cleanup.dart` — logout teardown and `UnauthenticatedReason` (the reason feeds the notice).
- `lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart` — home of the innkeeper action (D-15).

### Established Patterns
- Push devices are unregistered before the logout (BE Phase 5 contract); the deletion removes them server-side, the app must not fail if the unregister finds nothing.
- Dialogs live on the root Navigator: the cubit is read before the `await`.
- Schema check on the merged BE SDL gates the FE plans that select new fields.

### Integration Points
- Login flow: the accepted version travels with the Twitch login mediated by the BE (browser + callback, login ticket) — where exactly is for the research on both sides.
- `AuthGate` maps the unauthenticated reason to the `SignInNotice`.

</code_context>

<specifics>
## Specific Ideas

- Notice, verbatim: «Il tuo account è stato eliminato.»
- Cancelled quest (D-13), verbatim in the two quotes of the decision.
- Checkbox sentence, verbatim: «Accetto i Termini di servizio e l'Informativa sulla privacy».

</specifics>

<deferred>
## Deferred Ideas

- Re-acceptance when terms or privacy change (the recorded version of D-09 is its base).
- A wait before the same Twitch account may register again.
- A stronger confirmation (typed word) for the deletion.
- Data export / portability from the app.
- A party list with the companions' names.
- «Elimina account» for a user with no character (creation screen).

</deferred>

---

*Phase: 25-account-deletion-and-legal-consent*
*Context gathered: 2026-11-24*
