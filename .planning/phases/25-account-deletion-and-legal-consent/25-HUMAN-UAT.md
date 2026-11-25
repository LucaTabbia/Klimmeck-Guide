---
status: complete
phase: 25-account-deletion-and-legal-consent
device: Android (Samsung SM-S938B, USB, adb reverse tcp:3000 tcp:3001 — BE on port 3001)
be_ref: "BE branch origin/feat/26-eliminazione-account-e-consenso 9321434a (BE Phase 26, BE PR #53, not merged yet: the schema check is to be rerun on BE develop after the merge)"
fe_ref: "feat/25-account-deletion-and-legal-consent 2f0defd2 at the end of the session (FE PR #59, draft)"
gate: "GATE_OK — re-checked by plan 25-08 on origin/feat/26-eliminazione-account-e-consenso 9321434a, 2026-11-25; schema check 57 × OK on the same SDL"
date: 2026-11-25
verdict: "Steps 1-11 passed in the user's words; steps 7 and 10 passed as variants (step 7 in two halves, the started quest cancelled by the innkeeper's deletion; step 10 with the innkeeper's side played by the orchestrator, one phone only); step 9 passed after a fix; the Settings layout of step 5 was changed by the user after its pass (D-02 amended); a second physical device, TalkBack (IN-06) and the checkbox border (IN-05) were not run or not judged — open, non blocking"
completed: 2026-11-25
---

# Phase 25 — Device E2E (account deletion and legal consent)

App of `feat/25-account-deletion-and-legal-consent` on the Android phone against the local BE booted by the orchestrator from the BE branch `feat/26-eliminazione-account-e-consenso` (BE Phase 26; the BE PR is not merged). Gate re-checked by plan 25-08 on `origin/feat/26-eliminazione-account-e-consenso` of the BE repo at `9321434a` (read-only `git show` after one `fetch` ordered by the orchestrator): `CharacterStatus.innkeeperInjuries` still there, `deleteMyAccount: Boolean!`, `deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!`, `DeletedAccount.twitchId: String!`, `exchangeLoginTicket` unchanged → `GATE_OK`. This record was written after the session, from the facts recorded by the orchestrator, who ran it one step per message; results are only the tester's words as relayed by the orchestrator, and DB readings and DB writes are the orchestrator's. No ids of real users or characters, no usernames, no secrets, no URIs, no identity values in this file (field names only).

## Setup

Setup: BE with Phase 26 booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/25-account-deletion-and-legal-consent` with the REAL Twitch login (the dev bypass recreates the dev user, so it cannot show a deletion). Identities: the innkeeper, player A (to be deleted), player B (the companion left behind) — two devices, or one device switching identity as in the Phase 21 UAT. Every seed, character move and DB read is the orchestrator's job, with scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

**As run (2026-11-25):** one phone (Samsung SM-S938B) on USB with `adb reverse tcp:3000 tcp:3001`; the BE on port 3001, booted by the orchestrator from the BE branch (restarted at 14:28 local time after the morning process lost its database connection; 0 ERROR lines for the whole session). App entry point `lib/main.dart`, flavor dev, with the REAL Twitch login. The identities were switched by logging out and in on the one phone: the innkeeper (the user's own Twitch account, with his character), a NEW real Twitch account created by the user for the test (player A, recreated four times), and the dev adventurer (no Twitch account, never deleted). The companion left behind of steps 7 and 11 was the innkeeper's character.

Device notes (user memory): `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`. These commands are run by the user or the orchestrator, never by the executor.

## Session data

Field names only, from the BE handoff as copied in `25-07-SUMMARY.md`; no ids, no values, no secrets.

- Users: `users.acceptedTermsVersion`, `users.termsAcceptedAt`, `users.twitchPoints`.
- Quests: `quests.startedAt`, `quests.concludedAt`, `quests.registeredAdventurers`; on `pendingquests`: `pointsSpent`, `travelFoodSpent`, `travelHungerLifeLost`.
- Characters: `characters.user`, `status.location`, `status.currentLifePoints`, `quests.pendingQuest`, `assets.ownedItems`.
- Sessions and the rest: `sessions.revokedAt`, `sessions.revokeReason`; the collections `push_devices` and `admin_audit_logs` (`action`, `target`, `outcome`).

## Copy to confirm with the user

Copy to confirm with the user during the session (REPO-RULES «Copy»): «Elimina account», the dialog title and body, «Elimina un account», «Nome utente Twitch», «Avanti», «Eliminare l'account di <nome>?» and its body, the four innkeeper refusals, «Account eliminato.», «Impossibile eliminare l'account, riprova», «L'oste non può eliminare il proprio account dall'App», «Accetta i Termini di servizio e l'Informativa sulla privacy per entrare.». A change asked by the user is fixed in TDD during the UAT in its own commit and recorded.

**Outcome:** every FE string of the list was confirmed by the user («le altre pass»; on the consent error line: «Il testo va bene com'è»), together with the two strings born in the session, «Azioni irreversibili» and «Nome Twitch dell'account da eliminare» (which replaces «Nome utente Twitch» of the list). Changed by the user, on the BE: the body of the push of a cancelled started quest, now «Un membro del party ha lasciato il mondo: Missione annullata, ciò che hai consumato è stato rimborsato.» (BE commits `056995f8` test, `8d753909` fix, `9321434a` notes).

## Steps

| N | step | requirement | result | user's words |
|---|------|-------------|--------|--------------|
| 1 | Login screen. Above «Login con Twitch» one checkbox with «Accetto i Termini di servizio e l'Informativa sulla privacy»; the two links at the bottom are gone; the login button is disabled until the box is ticked (CONSENT-01; D-07). | CONSENT-01 | pass | «pass» |
| 2 | Links. «Termini di servizio» opens the termini page in the external browser, «Informativa sulla privacy» the privacy page; tapping them does not tick the box; tapping the rest of the sentence does (CONSENT-01; D-07, D-08). | CONSENT-01 | pass | «pass» (the same message as step 1). |
| 3 | Consent recorded. Tick and log in as player A with Twitch: the session opens; the orchestrator reads on player A's user the accepted version equal to the app constant and a date of today (field names from the handoff) (CONSENT-03; D-09, D-19). | CONSENT-03 | pass | «pass». Run twice: first with the innkeeper (an existing user: the version and the acceptance date were written at this login), then with the new Twitch account of player A (the user is born with version and date). The orchestrator read both on the DB: `users.acceptedTermsVersion` equal to the app constant (`2026-11-24`) and `users.termsAcceptedAt` of the day. |
| 4 | Memory. «Esci» from Settings: the login screen shows the box already ticked; log in again (CONSENT-02; D-10). | CONSENT-02 | pass | «pass». The box was still ticked after «Esci»; after an account deletion the box was unticked (seen by the orchestrator in a screenshot). |
| 5 | Settings. As player A, Settings → Account reads «Elimina personaggio», «Esci», and last, detached, in red outline, «Elimina account»; as the innkeeper the button is absent and nothing new appears on the character-creation screen of a user with no character (ACCOUNT-01; D-02, D-16, D-17). | ACCOUNT-01 | pass (layout then changed by the user, D-02 amended) | «pass» on the layout of the script. Later in the session the user asked for a new layout: «Nella sezione impostazioni metterei i tasti pericolosi (eliminazione personaggio e account) dentro una dropdown. Già che ci siamo raggruppiamo le cose sotto diverse dropdown, lasciando il tasto esci in fondo alla pagina», then «Usa le dropdown dell'app, sempre» (`8766a865`, `de141943`, `c446b7e2`; D-02 amended, `2f0defd2`). On the result: «pass». The script row keeps its original text. |
| 6 | Dialog. «Elimina account» opens one dialog «Eliminare l'account?» with the body listing every character including the archived ones, the points balance, the portrait, and that converted channel points are not given back; «Annulla» closes it and nothing happens (ACCOUNT-01; D-01, D-05). | ACCOUNT-01 | pass | «pass» («Annulla» first, then the confirmation). |
| 7 | Own deletion with a started quest. The orchestrator puts A and B in a group quest that has effectively started (seats full, both on the place, food spent on the trip and some life lost to hunger recorded by the BE). On A's phone «Elimina account» → «Elimina»: a spinner on the button only, then the login with «Il tuo account è stato eliminato.» above the button and the box unticked. On B's phone, without restarting: the push «questCancelled» with the BE's text, the pawn back in the city the quest was taken from, the quest paper gone from the map, food, points and life refunded as served, and the quest back on the Board of that city, not started and acceptable (ACCOUNT-02, ACCOUNT-04, CONSENT-02; D-03, D-06, D-10, D-13, D-23). | ACCOUNT-02, ACCOUNT-04, CONSENT-02 | pass, as a variant (two halves, see «Run differently from the script») | Started-quest half, run as the INNKEEPER deleting player A (the companion) by username while the phone showed the companion left behind (the innkeeper's character): a started boss quest seeded with both on the place, the companion left behind with 30 points, 2 food items and 500 life recorded as spent. DB after: points +30, life +500, items +2, the character on the city marker, `quests.pendingQuest` null, the quest back with 0 registrations and `startedAt` null, the account and the character of player A gone; the audit row without the typed login. The user: «pass», and later «confermo la notifica» (the push arrived). Own-deletion half, run separately: player A deleted their own account from Settings and landed on the login with «Il tuo account è stato eliminato.», the box unticked; BE log: 1 character, 1 session revoked, 1 device. «pass» |
| 8 | From zero. Player A logs in again with the same Twitch account (box ticked again by hand): the character-creation screen, balance 0 (ACCOUNT-02; D-04). | ACCOUNT-02 | pass | «pass» / «pronto». Player A logged in again four times with the same Twitch account: the character creation each time, balance 0. |
| 9 | Innkeeper's refusals. As the innkeeper, Settings → «Locanda» → «Elimina un account»: a dialog with «Nome utente Twitch» and «Avanti» disabled while empty; in landscape with the keyboard open the field stays visible; an unknown username → «Nessun utente Twitch con questo nome»; a Twitch user with no account → «Questo utente non ha un account nella Guida»; the innkeeper's own username → «Non puoi eliminare l'account di un oste»; each line inside the dialog, the text kept, nothing deleted (ACCOUNT-03; D-15, D-16). | ACCOUNT-03 | pass after fix | First: «La visualizzazione del campo e del messaggio di errore non è ideale. Fai uno screenshot» → the dialog redesigned in TDD (`816b6fea`, `af18857d`: anchored at the top, field and buttons on one row, the refusal whole under the field; the separate title is gone and the field label is «Nome Twitch dell'account da eliminare»). Then: «pass». The script row keeps its original text («Nome utente Twitch»). |
| 10 | Innkeeper's deletion of an online player. Player A (recreated in step 8) is online on the other device; the innkeeper types A's username → «Avanti» → «Eliminare l'account di <nome>?» → «Elimina»: the dialog closes, the section reads «Account eliminato.»; A's phone lands on the login with «Il tuo account è stato eliminato.» without any tap (ACCOUNT-03, ACCOUNT-02; D-15, D-18). | ACCOUNT-03, ACCOUNT-02 | pass, with the innkeeper's side played by the orchestrator | One phone only: player A online on the map; the orchestrator called `deleteAccountByTwitchLogin` as the innkeeper (the BE's dev credential, never printed). Four seconds later the phone was on the login with «Il tuo account è stato eliminato.» and the box unticked, with no tap (orchestrator's screenshot). BE: 1 session revoked, 1 device. The innkeeper's own dialog on the phone was used for the deletions of steps 7 and 11. |
| 11 | Not-started quest. The orchestrator puts B and a third player C (or A recreated) in a group quest NOT started (one still travelling or waiting on the marker); C's account is deleted (innkeeper path): B keeps waiting, the label «In attesa del gruppo k/N» drops by one, no push of cancellation, no refund (ACCOUNT-04; D-13). | ACCOUNT-04 | pass | «…per il resto è tutto pass» (in the same message the user reported an overflow, fixed in TDD: `31cd392a`, `c88f537a`). A boss needing 3, seeded with the innkeeper's character and player A registered and on the place (2/3, not started); the innkeeper deleted A from the phone. DB: the quest still not started with 1 registration, the companion still there with his pending quest, points and life unchanged (no refund). |

Result values: `pass`, `fail`, `pass after fix`, `not run`. The user answered «pass» to each step unless noted; the user's words are written as relayed by the orchestrator. The step texts are the script of the plan, verbatim, also where the session changed what they describe (steps 5 and 9).

## Deviations from the script

Run differently from the script, recorded as run:

- **Step 7 passed as a variant, in two halves.** The started quest was cancelled by the INNKEEPER's deletion of player A by username (not by player A's own deletion), with the phone showing the companion left behind; player A's own deletion from Settings, with its landing and the unticked box, was run separately, without a started quest. The script's single run (own deletion that cancels the started quest, seen on a second phone) was not done.
- **Step 10 passed with the innkeeper's side played by the orchestrator.** With one phone only, the phone showed player A online and the orchestrator called `deleteAccountByTwitchLogin` as the innkeeper; the landing without any tap was seen in the orchestrator's screenshot. The innkeeper's dialog itself was used on the phone for the deletions of steps 7 and 11.
- **Step 3** was run with two identities (the innkeeper, an existing user, and the new account of player A), not with player A only.
- **Step 5:** the layout of the script passed, then the user changed it (D-02 amended): three closed app dropdowns («Notifiche», «Locanda» for the innkeeper, «Azioni irreversibili» with «Elimina personaggio» then «Elimina account») and «Esci» last on the sheet.
- **Step 9:** the dialog was redesigned during the step; the field label is now «Nome Twitch dell'account da eliminare» and the separate title is gone.

Not run on the device (open, non blocking):

| Part | Why | Status |
|------|-----|--------|
| A second physical device (steps 7 and 10 as written, two phones side by side) | one phone only in the session; identities switched by logging out and in, step 10 simulated as above | open, non blocking |
| TalkBack on the consent row (IN-06) | not judged by the user | open, non blocking |
| The border of the checkbox (IN-05) | not judged by the user | open, non blocking |

Not on the device by design, covered by tests (plan): the `terms_not_accepted` refusal (25-05), the race between the deletion answer and the socket close (25-03), the consent kept by every other revocation (25-02), every failure code of both deletions (25-03, 25-04), the D-18 fallback after the window.

## Orchestrator's mistake during the session (not a product defect)

The first seed of step 7 had a due date in the past, so the BE resolved the boss by itself in 12 seconds: the user saw a victory, and the innkeeper's character, who was already awaiting aid from the day before, still awaiting aid. The orchestrator restored the data from the backup, removed the two spurious results and seeded again with the right dates. At the end of the session the innkeeper's character, the innkeeper's balance and the quest were restored from the backup taken for this UAT.

## Changes made during the UAT

FE commits (each change test-first, in its own commits):

| Change | Asked at | Commits |
|--------|----------|---------|
| The innkeeper's deletion dialog was cut by the landscape keyboard: anchored at the top, field and buttons on one row, the refusal whole under the field; no separate title, field label «Nome Twitch dell'account da eliminare» | step 9 | `816b6fea` (test), `af18857d` (fix) |
| Overflow when the confirmation opened above the keyboard — «Quando apro e chiudo la tastiera c'è un overflow di qualche tipo (vedo le barre gialle e nere per un attimo)»: the shared destructive confirmation dialog scrolls | step 11 | `31cd392a` (test), `c88f537a` (fix) |
| Settings sheet grouped in closed dropdowns with «Esci» last, then built on the app's shared `Dropdown` — «Usa le dropdown dell'app, sempre» | after step 5 | `8766a865` (test), `de141943` (feat), `c446b7e2` (fix); D-02 amended in `25-CONTEXT.md` (`2f0defd2`) |

BE (branch `feat/26-eliminazione-account-e-consenso`): the body of the push of a cancelled started quest dictated by the user — `056995f8` (test), `8d753909` (fix), `9321434a` (notes).

## Decisions taken during the UAT (user)

- **D-02 amended (Settings layout):** «Nella sezione impostazioni metterei i tasti pericolosi (eliminazione personaggio e account) dentro una dropdown. Già che ci siamo raggruppiamo le cose sotto diverse dropdown, lasciando il tasto esci in fondo alla pagina» and «Usa le dropdown dell'app, sempre». On the result: «pass». The name «Azioni irreversibili» and the innkeeper's «Elimina un account» staying under «Locanda» are the orchestrator's choices, shown to the user on the device (`25-CONTEXT.md`).
- **Innkeeper's dialog (step 9):** «La visualizzazione del campo e del messaggio di errore non è ideale. Fai uno screenshot» → redesigned, then «pass».
- **Push body of the cancelled started quest (BE copy):** «Un membro del party ha lasciato il mondo: Missione annullata, ciò che hai consumato è stato rimborsato.»
- **Copy confirmed:** «le altre pass»; on the consent error line «Il testo va bene com'è».

## D-22 privacy lines (orchestrator's closing item)

Orchestrator's closing item (not the executor's): the two lines of D-22 in `~/Personale/Code/klimmeck-guide-legal/privacy.md` (§2: the accepted version and its date stored on the account; §10: the acceptance remembered on the device, which a logout no longer clears); the `[DATA DI PUBBLICAZIONE]` placeholder stays (D-12). The executor records whether it was done and its commit, as told by the orchestrator.

**Done** and published by the orchestrator on the user's go («Via su tutto»): legal repo commit `0659dc4` — privacy §2 (the accepted version and its date), §10 (the acceptance remembered on the device, cleared by the account deletion), and the deletion path updated to Impostazioni → «Azioni irreversibili» → «Elimina account» in privacy §7, in the termini page and in the elimina-account page. No executor touched the legal repo.

## Closing gates (final tree, 2026-11-25)

- Gate re-check on BE `origin/feat/26-eliminazione-account-e-consenso` `9321434a` (plan 25-08): `GATE_OK`.
- Schema check of the registered documents against that SDL (plan 25-08): «dumped 57 documents», 57 × OK, 0 other lines, exit 0. **To rerun on BE `develop` after the merge of BE PR #53.**
- `flutter analyze` (plan 25-08): «47 issues found» (the baseline), `ANALYZE_GATE_OK`.
- Full suite, rerun by the orchestrator after the UAT fixes: `+5706: All tests passed!`; `tool/hardening_check.sh`: `hardening_check: OK`.
- BE, run by the orchestrator: unit 326 suites / 4880 tests, `account-deletion.resolver.int-spec` 32 tests, `tsc` clean. Both branches pushed (FE PR #59, BE PR #53, drafts).

## Requirement ↔ step map

Requirement ↔ step map: CONSENT-01 (1, 2), CONSENT-02 (4, 7), CONSENT-03 (3), ACCOUNT-01 (5, 6), ACCOUNT-02 (7, 8, 10), ACCOUNT-03 (9, 10), ACCOUNT-04 (7, 11), ACCOUNT-05 (the gate of 25-07 — schema gate, 57 × OK, full suite — steps 1–11 all passed or explicitly waived by the user, and the orchestrator's privacy lines of D-22 committed in the legal repo). Not on the device, covered by tests: the `terms_not_accepted` refusal (25-05), the race between the deletion answer and the socket close (25-03), the consent kept by every other revocation (25-02), every failure code of both deletions (25-03, 25-04), the D-18 fallback after the window.

A requirement is marked complete only by plan 25-08 Task 3 and only when all its mandatory steps passed; a failing step leaves it `In Progress (gaps: steps …)`.

**Outcome (2026-11-25):** every mandatory step passed in the user's words, so CONSENT-01, CONSENT-02, CONSENT-03, ACCOUNT-01, ACCOUNT-02, ACCOUNT-03, ACCOUNT-04 and ACCOUNT-05 are marked complete. ACCOUNT-01 is complete as amended by D-02 (dropdown layout, «Esci» last on the sheet). Steps 7 and 10 count as passed in the variants described above. ACCOUNT-05: the gate and the schema check hold on the BE branch (the BE PR is not merged yet), and the D-22 lines are committed in the legal repo (`0659dc4`).
