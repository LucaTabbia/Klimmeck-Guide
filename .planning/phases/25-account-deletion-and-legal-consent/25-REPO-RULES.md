# Phase 25 — common rules for the executors

Part of the context of EVERY `25-NN-PLAN.md` (cited with `@`). Written by the orchestrator on 2026-11-24 after the two researches and the user's rulings. Where this file and `25-RESEARCH.md` disagree, this file wins; above both stands `25-CONTEXT.md`.

## Inherited rules

The general sections of `.planning/phases/22-companion-defeat-rest-and-recovery/22-REPO-RULES.md` and the «Inherited rules» of `.planning/phases/24-participants-stories-and-innkeeper-wounds/24-REPO-RULES.md` (analyzer gate command, format, full-suite command, bookkeeping task, trailer check) apply verbatim — read them — with these differences:

- Branch `feat/25-account-deletion-and-legal-consent`, already checked out, off `develop`. Never switch or create branches, never push, never `gh`.
- EVERY Bash command starts with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && `.
- BE repo `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE`: READ-ONLY (`git -C <BE> show <ref>:<path>`, `log`, `ls-tree`; never fetch, checkout, pull, edit). BE phase directory: `.planning/phases/26-eliminazione-account-e-consenso/`.
- Docs scope `docs(phase-25)`. Code scopes: `auth`, `signIn`, `settings`, `innkeeper`, `graphql`, `repository`, `models`, `shared`, `test`. Subjects in English, ≤ 72 characters (shorten BEFORE committing; never rewrite history). **No attribution trailer, ever.**
- Baselines: analyzer **«47 issues found»**; suite: measured by 25-01 Task 1 on this branch and written into `25-VALIDATION.md`.
- `dart format` only on touched files, one by one, never on a directory.
- No executor marks a requirement complete before the last plan.
- Never read or print `.env` or `env/*.json`. No device, no app launch, no real database.
- STATE.md only with the Edit tool or python3 UTF-8, never `sed -i`.

## Wire contract (BE research of Phase 26; final only at the BE merge — the gate plan re-checks every name on the merged SDL)

| What | Wire | FE reading |
|------|------|-----------|
| Own deletion (D-20) | `deleteMyAccount: Boolean!`; errors `INNKEEPER_ACCOUNT_PROTECTED`, `UNAUTHENTICATED` | a failure enum with a message per code, as the character deletion |
| Innkeeper deletion (D-15, D-20) | `deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!`, `DeletedAccount { twitchId: String! }`; errors `TWITCH_USER_NOT_FOUND`, `ACCOUNT_NOT_FOUND`, `INNKEEPER_ACCOUNT_PROTECTED`, `TWITCH_UNAVAILABLE` | innkeeper failure mapping |
| Revocation (D-18) | refresh → `SESSION_REVOKED` with `extensions.reason = "accountDeleted"`; WS close 4409 | `UnauthenticatedReason.accountDeleted` → `SignInNotice.accountDeleted` |
| Consent (D-19) | `termsVersion` query parameter on `GET /auth/twitch/start`, format `^[A-Za-z0-9][A-Za-z0-9._-]{0,31}$`; refusal = redirect with `?error=terms_not_accepted` | `login({required String acceptedLegalVersion})`; a new `SignInFailure` |
| Cancelled started quest (D-13, D-23) | existing `questCancelled` push, `characterUpdated`, `questUpdated`; no SDL change | existing reactive paths, proven by tests |
| Schema check | registry 55 → **57** documents | the count pinned in the test files changes only in the gate plan |

## Hard rules

- **Gated selection:** the two new mutation documents are registered and selected ONLY in the gate plan (after the BE merge). Before it, repositories are built against an abstract API with fakes; nothing new reaches today's BE except the `termsVersion` parameter, which today's BE ignores.
- **Rule 4 (backend is the truth):** the app never decides who may be deleted; hiding the button for the innkeeper (D-16) is UX, the BE refuses anyway.
- **Rule 2 (no blocking loading in session):** the only spinner is on the tapped button; nothing else blocks.
- **Deletion teardown (D-06):** after `deleteMyAccount` succeeds the app makes NO further BE call (no push unregister, no logout mutation): local teardown through `SessionTerminator.terminateSession(UnauthenticatedReason.accountDeleted)`, then the consent memory is forgotten. A plain logout and every other revocation keep the consent memory.
- **Race (research, Pitfall 1):** a refresh or a socket close arriving while the deletion is in flight must not turn the landing into «sessione scaduta»: the deletion path wins. One test pins it.
- **Consent (D-07..D-12):** the sentence is exactly «Accetto i Termini di servizio e l'Informativa sulla privacy», the two wordings are the tappable parts (accessible: each link reachable and announced on its own, the checkbox toggled by its own target); the two footer links are removed; the login button is disabled while unticked. The memory is device-only, keyed by the version constant: a different constant starts unticked. The version constant has a provisional date value (user: he sets the real one at the launch) — one constant, one file, next to the two URLs.
- **Links (D-08):** external browser through `LinkOpener`, moved out of `push/` in its own commit (D-21, imports only).
- **Settings (D-01, D-02, D-17):** «Elimina account» is the last of the Account section, under «Esci», detached, red outline; one dialog through `showDestructiveConfirmation`; hidden for the innkeeper; nothing is added to the character-creation screen.
- **Innkeeper action (D-15):** in the innkeeper section an entry opens a dialog with the Twitch username field (never a field inline in the tab: the tab does not resize for the keyboard), then the confirmation; failures inline in the dialog. The typed username is never logged nor stored.
- **No party list, no placeholder wording** (D-13): nothing draws companions by name.
- Copy (provisional, reviewed at the UAT): «Elimina account»; notice «Il tuo account è stato eliminato.»; checkbox sentence as above; dialog title/body written by the planner within D-05 (what is lost: every character including the archived ones, the points balance, the portrait; converted channel points are not given back; irreversible). No other new copy without listing it in the plan.
- Never `appLog`, `print` or `debugPrint` a Twitch username or a token.

## Legal repo (D-22)

The two privacy lines are written in `~/Personale/Code/klimmeck-guide-legal/privacy.md` by the ORCHESTRATOR at the close of the phase (public repo, personal git identity): no executor touches that repo.
