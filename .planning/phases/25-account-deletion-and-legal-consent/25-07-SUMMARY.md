---
phase: 25-account-deletion-and-legal-consent
plan: 07
subsystem: graphql
tags: [account-deletion, gate, schema-check, graphql, settings, shell]
requires:
  - 25-03 (AccountDeletionApi, AccountDeletionRepository, AccountDeletionCubit)
  - 25-04 (PlayerAccountDeletionRepository, PlayerAccountDeletionCubit)
  - BE Phase 26 on the BE branch feat/26-eliminazione-account-e-consenso df22b017 (not yet merged)
provides:
  - the two deletion documents, registered (registry 55 -> 57)
  - GraphQlAccountDeletionApi over KlimmeckGraphQl
  - both deletion Cubits provided by the shell; accountDeletionEnabled = true
  - BACKEND-NOTES.md with the confirmed contract
affects: [25-08]
tech-stack:
  added: []
  patterns:
    - the GraphQL implementation of an abstract API tested on a real KlimmeckGraphQl over a recording Link (operation name and variables proven)
key-files:
  created:
    - lib/graphql/mutations/account_mutations.dart
    - lib/repository/services/account/graphql_account_deletion_api.dart
    - test/graphql/account_documents_test.dart
    - test/repository/services/account/graphql_account_deletion_api_test.dart
  modified:
    - tool/schema_check/schema_check_documents.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/services/account/account_deletion_api.dart
    - lib/screens/auth/authenticated_shell.dart
    - lib/bootstrap/klimmeck_guide_app.dart
    - lib/config/account_deletion.dart
    - test/tool/schema_check_documents_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/travel_documents_test.dart
    - test/graphql/loot_fragment_test.dart
    - test/repository/account_deletion_failure_test.dart
    - test/repository/player_account_deletion_failure_test.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/auth/authenticated_shell_leak_test.dart
    - test/config/account_deletion_test.dart
    - .planning/phases/25-account-deletion-and-legal-consent/BACKEND-NOTES.md
decisions:
  - "Gate run on the BE branch feat/26-eliminazione-account-e-consenso at df22b017 instead of origin/develop (orchestrator's sanctioned deviation: BE PR draft until the real boot); the schema check must be re-run on BE develop after the merge"
  - "TOO_MANY_REQUESTS (both deletions are @Throttled) reads the generic failure line: the app has no throttling message elsewhere"
  - "The switch accountDeletionEnabled stays in the code after the flip; retiring it is a later cleanup"
metrics:
  duration: ~35 min
  completed: 2026-11-25
  tasks: 4
  files: 21
---

# Phase 25 Plan 07: The gate — account deletion live against BE Phase 26 Summary

Gate passed on BE `feat/26-eliminazione-account-e-consenso` `df22b017` (sanctioned stand-in for the not-yet-merged BE `develop`). All wire names checked and confirmed. `DeleteMyAccount` and `DeleteAccountByTwitchLogin` are registered: the registry goes 55 → 57 and all 57 validate OK. `GraphQlAccountDeletionApi` delegates to two new `KlimmeckGraphQl` methods. The shell provides `AccountDeletionCubit` (with the session terminator) and `PlayerAccountDeletionCubit`, and `accountDeletionEnabled` is now `true`. The full suite has 5691 tests, all green. **From this plan on the branch needs a BE with Phase 26.**

## Tasks

| Task | Commits |
|------|---------|
| 1 Schema gate, contract proof, handoff, documents, GraphQL API | `08bb91ca` test(graphql): expect the two account deletion documents; `e90e3bf5` feat(graphql): account deletion documents and their GraphQL API |
| 2 Deletion Cubits in the shell, switch on | `bb9860f9` test(settings): expect the deletion cubits in the shell, the switch on; `85af1b73` feat(settings): wire the account deletion cubits, turn the switch on |
| 3 Schema check, full suite, hardening, BACKEND-NOTES | `6e36328b` docs(phase-25): record the confirmed contract in the backend notes |
| 4 Bookkeeping | `docs(phase-25): record plan 07 progress` |

## Gate (Task 1)

BE `git status --short` before and after: empty, nothing modified. The BE repo was only read (`show`, `log`, `grep` on the ref), with no fetch or checkout.

BE ref: `feat/26-eliminazione-account-e-consenso` at **`df22b017`**:

```
df22b017 docs(phase-26): record the security audit fixes
70c57a64 fix(auth): close a WS connect of a deleted account with 4409 (U-04)
4daee384 test(auth): expect a WS connect of a deleted account to get 4409
dc728e6a fix(users): remove devices registered in the deletion race (U-02)
b01d9c2b test(users): expect devices registered in the race to be removed
```

Gate block (with `origin/develop` replaced by that ref): **`GATE_OK`**. Five checks passed: `innkeeperInjuries` still on `CharacterStatus`, `deleteMyAccount`, `deleteAccountByTwitchLogin`, `DeletedAccount.twitchId` and `exchangeLoginTicket` unchanged.

Contract proof (SDL lines):

```
type DeletedAccount {
  twitchId: String!
}
  deleteAccountByTwitchLogin(twitchLogin: String!): DeletedAccount!
  deleteMyAccount: Boolean!
  exchangeLoginTicket(codeVerifier: String!, ticket: String!): AuthSession!
```

Names loop (non-spec BE files on the ref):

```
INNKEEPER_ACCOUNT_PROTECTED src/account/deletion/account-deletion-error-code.enum.ts src/account/deletion/account-deletion.exception.ts
TWITCH_USER_NOT_FOUND       src/account/deletion/account-deletion-error-code.enum.ts src/account/deletion/account-deletion.exception.ts
ACCOUNT_NOT_FOUND           src/account/deletion/account-deletion-error-code.enum.ts src/account/deletion/account-deletion.exception.ts
TWITCH_UNAVAILABLE          src/account/deletion/account-deletion-error-code.enum.ts src/account/deletion/account-deletion.exception.ts
accountDeleted              src/auth/session/session-revocation.service.ts src/auth/session/session-revoke-reason.enum.ts src/auth/session/session.service.ts
termsVersion                src/auth/twitch/oauth-state.service.ts src/auth/twitch/twitch-auth.controller.ts src/auth/twitch/twitch-login.service.ts
terms_not_accepted          src/auth/twitch/twitch-login-error-code.enum.ts
TOO_MANY_REQUESTS           src/throttling/too-many-requests.exception.ts
4409                        src/auth/ws/ws-close-codes.ts (WS_SESSION_REVOKED_CLOSE_CODE = 4409)
```

**Names confirmed.** Every name matches REPO-RULES §Wire contract and the app's constants: `innkeeperAccountProtectedCode`, `twitchUserNotFoundCode`, `accountNotFoundCode`, `twitchUnavailableCode`, `sessionRevokedReasonAccountDeleted = 'accountDeleted'`, `_termsVersionParameter = 'termsVersion'`, `termsNotAcceptedError = 'terms_not_accepted'` and `wsSessionRevokedCloseCode = 4409`. There was no contract mismatch, so no rename and no fix commit. The one addition since the REPO-RULES were written is `@Throttled()` on both mutations (`TOO_MANY_REQUESTS`). The app has no throttling message anywhere, so the code falls to the generic line. Two pins prove it (see Deviations).

### BE handoff: names and answers for 25-08

From `<BE>/.planning/phases/26-eliminazione-account-e-consenso/BACKEND-NOTES.md` at `df22b017`:

- **Socket after a deletion:** the BE closes every socket of the user with **4409**, reason `accountDeleted`, right after the commit. This includes sessions born from a login racing the deletion, and a reconnection inside the window. For the **own** deletion the 4409 normally arrives **before** the HTTP `true`. The app treats both as the same exit, which is the race pin of 25-03.
- **Window:** 15 minutes. Inside it a refresh gets `SESSION_REVOKED` + `accountDeleted`. HTTP with a live access token gets `UNAUTHENTICATED`. After the window, or after a BE restart for plain HTTP, the fallback is `SESSION_EXPIRED` and the app shows the session-expired notice. The switch to `SESSION_EXPIRED` happens 15–16 minutes after the deletion (Mongo TTL monitor).
- **Dev bypass and `termsVersion`:** the bypass carries no version, writes none and is never refused. If the bypass user deletes himself, his live socket gets no 4409. A reconnection inside the window does. Until a BE restart the bypass keeps pointing at the deleted id (`me` → `NOT_FOUND`). This is dev only.
- **DB field names for the UAT:** `users.acceptedTermsVersion`, `users.termsAcceptedAt`, `users.twitchPoints`. On `pendingquests`: `pointsSpent`, `travelFoodSpent`, `travelHungerLifeLost`. On `quests`: `startedAt`, `concludedAt`, `registeredAdventurers`. On `sessions`: `revokedAt`, `revokeReason`, `expiresAt`. On `characters`: `user`, `status.location`, `status.currentLifePoints`, `quests.pendingQuest`, `assets.ownedItems`. Also the collections `push_devices`, `portrait_deletions` (`attempts`) and `admin_audit_logs` (`action`, `target`, `outcome`).
- **Consent write rule (vetoable on the BE):** version and date are written when the user is created, and after that only when the version changes. A second login with the same version keeps the date.
- **Body of the cancellation push (provisional, BE copy):** title «Missione annullata», body «Un compagno ha lasciato il mondo: la missione è annullata e sei tornato in città, con cibo, punti e vita restituiti.»
- **Orchestrator items before the UAT (BE side):** boot from the branch, with no migrator in the repo. Two orphan dev characters have no `user` field (D-24). The innkeeper deletion needs the Twitch login credentials in the BE environment, otherwise it always answers `TWITCH_UNAVAILABLE`. The FCM topic IAM permission must be granted for the `streamer-live` unsubscription.

## Schema check (Task 3)

On the SDL of BE `df22b017` (re-read with `git show` in the same call):

```
dumped 57 documents
57 × "OK <name>.graphql", 0 other lines, exit 0
OK DeleteAccountByTwitchLogin.graphql
OK DeleteMyAccount.graphql
```

**Re-run on BE `develop` after the BE merge** (25-08 re-check).

## Gates

- Full suite (alone, foreground): `01:48 +5691: All tests passed!` The baseline was 5549 before the phase; this plan adds 11 tests (3 document, 4 API, 2 rate-limit, 2 shell) and keeps every existing pin green.
- Analyzer after each code task: «47 issues found.» `ANALYZE_GATE_OK`.
- `bash tool/hardening_check.sh` → `hardening_check: OK`.
- Acceptance greps: `mutation DeleteMyAccount` ×1 and `mutation DeleteAccountByTwitchLogin` ×1 in `account_mutations.dart`. No other `lib/graphql` file names the two mutations. `const bool accountDeletionEnabled = true;` ×1. `GraphQlAccountDeletionApi(` ×1 in `klimmeck_guide_app.dart`. `AccountDeletionRepository(` ×1 in the shell. `git diff --name-only HEAD~2 -- test` after Task 2 lists only the three test files of the task. The secrets grep on `BACKEND-NOTES.md` is empty.
- Trailer check `0` after every commit. Subjects are 56, 63, 70, 68 and 66 characters.

## RED evidence

- Task 1 RED: `flutter test test/graphql test/tool test/repository/services/account …` gave `+262 -6`. Two files failed to load (the missing `account_mutations.dart` and `graphql_account_deletion_api.dart`) and the four count pins failed (55 ≠ 57).
- Task 2 RED: `flutter test test/screens/auth test/config` gave `-3`. Both shell test files failed to compile (no named parameter `accountDeletionApi`) and the switch pin failed (`false`).

## Deviations from Plan

1. **[Sanctioned by the orchestrator] Gate ref.** Every `origin/develop` became the local BE ref `feat/26-eliminazione-account-e-consenso` (`df22b017`). The BE Phase 26 PR is a draft until the real boot and the device UAT. The schema check must be re-run on BE `develop` after the merge.
2. **[Rule 2 - contract pin] `TOO_MANY_REQUESTS` cases.** Both deletions are now `@Throttled()` on the BE. One case was added in `account_deletion_failure_test.dart` and one in `player_account_deletion_failure_test.dart` («a rate-limit refusal falls back to the generic failure (D-20)»). Both files are outside `files_modified`. They were committed in the Task 1 RED commit and were **green at the first run** (the code already maps unknown codes to `unknown`), so no `lib/` change was needed.
3. **API test on a real `KlimmeckGraphQl`.** The plan suggested `MockKlimmeckGraphQl`. The test instead runs `GraphQlAccountDeletionApi` over a real `KlimmeckGraphQl` with a recording `Link`, in the shape of `graphql_character_deletion_test.dart`. This proves the operation names, the variables (`{}` / `{twitchLogin}`) and that error codes pass through unchanged, which covers the new `KlimmeckGraphQl` methods too.
4. **[Boy Scout] `account_deletion_api.dart` doc.** «Implementazione GraphQL solo dal gate 25-07» now names `GraphQlAccountDeletionApi` (one doc line, outside `files_modified`).
5. **Task 2 subject shortened.** The plan's `test(settings): expect the deletion cubits in the shell and the switch on` is 73 characters. It was committed as «… in the shell, the switch on» (70 characters).
6. **Extra shell case.** «the deletion cubits reach the given API and the own deletion ends through the session terminator (D-06, D-15)» proves the wiring end to end: one `deleteMyAccount`, the login forwarded, `terminateSession(accountDeleted)` called once.

The flip broke no test outside this plan's files. `settings_test.dart` and the section harnesses were green in `flutter test test/screens test/config test/repository` (3497) and in the full suite.

## Known Stubs

None. The switch stays in the code (now `true`) by design; retiring it is a later cleanup.

## Threat Flags

None beyond the plan's register:
- T-25-60: the gate ran first.
- T-25-61: no rename.
- T-25-62: the BE status was empty before and after, and only read commands were used.
- T-25-63: names only in `BACKEND-NOTES.md`, and the secrets grep is empty.

## For 25-08 (device UAT)

- **The BE must run from the Phase 26 branch (or `develop` after the merge).** With this FE, a BE without Phase 26 cannot run either deletion. With a BE that has Phase 26, an older FE build is refused at login (`terms_not_accepted`).
- Re-run the gate and the schema check on BE `develop` once PR #53 is merged (57 × OK expected).
- Own deletion: the 4409 usually beats the HTTP answer, and either way the landing must read «Il tuo account è stato eliminato.» with the box unticked. A second device with the same account must land the same way, through 4409 or the refresh.
- Innkeeper deletion: `TWITCH_UNAVAILABLE` is reachable only by cutting the BE's network or leaving out the Twitch credentials. A name longer than 64 characters reads «Nessun utente Twitch con questo nome».
- Cancelled started quest: the banner shows the BE body verbatim, and the points come back on the user (`userUpdated`), not on the character.
- Requirements are not marked complete here (25-08 only).

## Self-Check: PASSED
