# Phase 25: Account Deletion and Legal Consent - Context

**Gathered:** 2026-11-24 (interactive discuss, joint with the BE Phase 26 «Eliminazione account e consenso»; this file is authoritative for both, same numbering D-01..D-16)
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
- **D-03 (user):** after a successful deletion the player lands on the login with an inline notice above the login button, like the existing `SignInNotice` lines: «Il tuo account è stato eliminato.»
- **D-04 (user):** the same Twitch account may log in again at once and starts from zero (balance 0, no character, creation from scratch). The BE keeps no trace of the deleted Twitch ID and applies no wait.
- **D-05 (technical default):** the dialog text is written in-world by Claude and lists what is lost (all characters including the archived ones, the points balance, the portrait) and that converted channel points are not given back; it must not contradict `elimina-account.md`.
- **D-06 (technical default):** the local teardown after the deletion is the logout one (tokens, push registration, caches) plus the consent memory of D-10. A failed deletion keeps the player in Settings with an inline error under the button, as the character deletion does; the spinner on the button is an explicit user action (rule 2 respected).

### Legal consent on the login
- **D-07 (user, «Frase con link, senza età»):** above the login button, one checkbox with the sentence «Accetto i Termini di servizio e l'Informativa sulla privacy», the two wordings tappable; the two links at the bottom of the login disappear. No mention of the minimum age in the sentence. The login button is disabled while the box is empty.
- **D-08:** «Termini di servizio» opens https://lucatabbia.github.io/klimmeck-guide-legal/termini and «Informativa sulla privacy» opens https://lucatabbia.github.io/klimmeck-guide-legal/privacy, in the external browser through the existing `LinkOpener` (technical default).
- **D-09 (user, «Sì, versione e data»):** the BE records on the user the accepted version of the documents and the date of the acceptance. The login carries the accepted version; a login without it is refused by the BE (the checkbox is not only a client-side gate). The privacy page must then mention this datum (a line in the legal repo, to be done with the phase).
- **D-10 (user, «Ricordata sul dispositivo»):** once accepted, the device remembers it: at the next logins on that phone the box starts already ticked. The memory is cleared when the account is deleted (technical default) and holds for one version of the documents: a new version starts unticked again.
- **D-11 (user, verbatim):** «Non è pubblicata l'app, caso impossibile» — there are no existing users with a live session to handle: no migration, no in-session acceptance page, no forced logout. The acceptance fields are simply required from this phase on (dev/test users in the DB are the orchestrator's concern at the real boot).
- **D-12 (technical default):** the version of the documents is one constant in the app, sent with the login; the BE stores what it receives with its own clock. No endpoint serving the current version, no re-acceptance flow (deferred).

### Traces for the other players
- **D-13 (user, «Segnaposto anonimo»):** when the deleted player's character sits in a group quest already started, the seat stays occupied until the quest concludes, as for the archive, but with no name and no portrait: the party shows a fixed in-world wording («Un avventuriero scomparso»). The quest resolves with today's rules. Since the character document is really deleted, the placeholder must not depend on it.
- **D-14 (technical default):** everything else follows the archive: unstarted seats freed, GM requests of the character deleted, the wounded removed from open aid quests, rescuers released; a guided mission the innkeeper is running loses that participant as it would for an archived character. Quest results are one per character and per user: the deleted player's own are deleted, the others' carry no name of his (verified on `quest-result.model.ts`).

### Deletion by the innkeeper and the innkeeper's own account
- **D-15 (user, «Azione nel pannello oste»):** in Settings → innkeeper section, a field for the Twitch username plus a confirmation; the BE resolves the username to the Twitch ID (it stores only the numeric ID) and runs the very same deletion, written in the innkeeper's action log. A player deleted while online goes back to the login with the notice of D-03 (technical default; if the revocation cannot tell the reason, the planner states the fallback). Unknown username or no account → an inline error, nothing deleted.
- **D-16 (user, «No, pulsante nascosto»):** the innkeeper cannot delete his own account from the app: «Elimina account» does not appear for the innkeeper role and the BE refuses the request (own mutation and the innkeeper action aimed at an innkeeper). The innkeeper's account is removed only by hand.

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
- Checkbox sentence, verbatim: «Accetto i Termini di servizio e l'Informativa sulla privacy».
- Placeholder in the party: «Un avventuriero scomparso» (wording open to a better in-world line).

</specifics>

<deferred>
## Deferred Ideas

- Re-acceptance when terms or privacy change (the recorded version of D-09 is its base).
- A wait before the same Twitch account may register again.
- A stronger confirmation (typed word) for the deletion.
- Data export / portability from the app.

</deferred>

---

*Phase: 25-account-deletion-and-legal-consent*
*Context gathered: 2026-11-24*
