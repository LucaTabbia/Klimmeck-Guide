---
phase: 25-account-deletion-and-legal-consent
plan: 03
subsystem: settings
tags: [account-deletion, settings, repository, session, race]
requires: [25-02]
provides:
  - AccountDeletionApi (abstract, both deletions: deleteMyAccount, deleteAccountByTwitchLogin)
  - AccountDeletionFailure + AccountDeletionException + accountDeletionFailureFrom (innkeeperAccountProtectedCode)
  - AccountDeletionRepository.deleteOwnAccount (terminateSession(accountDeleted) only)
  - AccountDeletionCubit / AccountDeletionState
  - AccountDeletionFailureMessage extension
  - showDeleteAccountConfirmation
  - accountDeletionEnabled = false (lib/config/account_deletion.dart)
  - AccountSection.isAccountDeletionEnabled
  - FakeAccountDeletionApi + operationExceptionWithCode (test helpers)
  - MockAccountDeletionRepository, MockAccountDeletionCubit
affects: [25-04, 25-07]
tech-stack:
  added: []
  patterns:
    - repository on an abstract API with a fake until the gate (REPO-RULES «Gated selection»)
    - local teardown through SessionTerminator after an irreversible BE action
key-files:
  created:
    - lib/repository/services/account/account_deletion_api.dart
    - lib/repository/account_deletion_failure.dart
    - lib/repository/account_deletion_repository.dart
    - lib/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit.dart
    - lib/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_state.dart
    - lib/screens/mainScreen/tabs/settings/components/account_deletion_messages.dart
    - lib/shared/components/modal/delete_account_confirmation_dialog.dart
    - lib/config/account_deletion.dart
    - test/helpers/fakes/fake_account_deletion_api.dart
    - test/repository/account_deletion_failure_test.dart
    - test/repository/account_deletion_repository_test.dart
    - test/repository/account_deletion_flow_test.dart
    - test/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit_test.dart
    - test/screens/mainScreen/tabs/settings/components/account_deletion_messages_test.dart
    - test/config/account_deletion_test.dart
  modified:
    - lib/screens/mainScreen/tabs/settings/components/account_section.dart
    - test/helpers/mocks.dart
    - test/screens/mainScreen/tabs/settings/components/account_section_test.dart
    - test/screens/mainScreen/tabs/settings/settings_test.dart
decisions:
  - "One AccountDeletionApi carries both deletions; deleteAccountByTwitchLogin returns nothing to the app"
  - "After a successful own deletion the only call is terminateSession(accountDeleted); the consent is forgotten by AuthGate (25-02)"
  - "The Cubit's last emission on success keeps isDeleting: true (AuthGate replaces the tree)"
  - "No shell provider for AccountDeletionCubit before 25-07: with the switch off the entry is never built"
metrics:
  duration: ~25 min
  completed: 2026-11-25
  tasks: 4
  files: 19
---

# Phase 25 Plan 03: Own account deletion behind the switch Summary

The player's own deletion is complete against an abstract `AccountDeletionApi` (fake in the tests, GraphQL only at the gate 25-07): failures read only `extensions.code`, a success ends the session locally through `SessionTerminator.terminateSession(UnauthenticatedReason.accountDeleted)` with no other backend call, a flow test on the real `SessionAuthTokenService` pins one terminal `accountDeleted` state under the race with an in-flight revocation, and «Elimina account» sits last in Settings → Account (under «Esci», detached, red outline, hidden for the innkeeper) behind `accountDeletionEnabled = false`.

## Tasks

| Task | Commits |
|------|---------|
| 1 API, failure mapping, repository, race test | `7cbc5d9f` test(repository): expect the own account deletion and its teardown; `2ec41092` feat(repository): delete the own account and end the session locally |
| 2 Cubit, messages, dialog | `1c5dff88` test(settings): expect the account deletion cubit and messages; `35dafd40` feat(settings): account deletion cubit, messages and dialog |
| 3 «Elimina account» behind the switch | `977c099e` test(settings): expect Elimina account under Esci behind the switch; `a6c0d704` feat(settings): Elimina account under Esci, behind the switch |
| 4 Bookkeeping | `docs(phase-25): record plan 03 progress` |

## RED failures

- Task 1: compile failure — `lib/repository/account_deletion_failure.dart` and `lib/repository/services/account/account_deletion_api.dart` missing (`Type 'AccountDeletionApi' not found`, `Method not found: 'accountDeletionFailureFrom'`).
- Task 2: compile failure — `account_deletion_cubit.dart` missing (`Type 'AccountDeletionState' not found` in `mocks.dart`).
- Task 3: compile failure — `lib/config/account_deletion.dart` missing (`Undefined name 'accountDeletionEnabled'`), and the `isAccountDeletionEnabled` parameter did not exist.

Green at first GREEN run, pin of Pitfall 1 (the reason comes from the BE answer, 25-02): the three `account_deletion_flow_test.dart` cases — «a revocation that lands while the deletion is in flight ends once as accountDeleted», «the deletion answer before the socket close ends once as accountDeleted» (`recoverFromUnauthorized` returns null, no second state), «a failed deletion leaves the session authenticated». None of them sees a backend logout.

## Copy as written (provisional, reviewed at the UAT)

- button «Elimina account»
- dialog title «Eliminare l'account?»; body «Il tuo nome sarà cancellato dai registri della Guida: tutti i tuoi personaggi, anche quelli archiviati, con progressi, oggetti, magie e compagni, il saldo dei punti e il ritratto andranno perduti per sempre. I punti canale già convertiti non verranno restituiti. L'azione è irreversibile: uscirai subito dall'App.»; confirm «Elimina», Annulla from the shared dialog (checked against `klimmeck-guide-legal/elimina-account.md`: no contradiction)
- failures: connection «Errore di connessione, riprova»; innkeeperProtected «L'oste non può eliminare il proprio account dall'App»; unauthenticated and unknown «Impossibile eliminare l'account, riprova»

## Verification

- `flutter test test/repository/account_deletion_failure_test.dart test/repository/account_deletion_repository_test.dart test/repository/account_deletion_flow_test.dart test/screens/mainScreen/tabs/settings test/config` → `+133: All tests passed!`
- Analyzer after each code task: «47 issues found.» `ANALYZE_GATE_OK`
- Greps: `abstract interface class AccountDeletionApi` 1; `PushSessionCleanup|logout|unregister` in the repository 0; `INNKEEPER_ACCOUNT_PROTECTED` in the failure file 1; switch literal 1; `accountDeletionEnabled` only in its file and `account_section.dart`; «Elimina account» in the character-creation screen 0; `AccountDeletionCubit` in `authenticated_shell.dart` 0; `git diff --stat 5c0b1b80 -- lib/graphql tool/schema_check lib/screens/characterCreation` empty.

## Deviations from Plan

**1. [Commit subject] Task 3 GREEN subject shortened**
- The plan's `feat(settings): Elimina account in the Account section, behind the switch` is 73 characters; committed as `feat(settings): Elimina account under Esci, behind the switch` (61).

**2. [Rule 3 - Test harness] `MockAccountDeletionCubit` added in Task 2 RED**
- The mock needs the Cubit type, so it lands with the Cubit's RED (Task 2) rather than in Task 1; `test/helpers/mocks.dart` is touched in Tasks 1 and 2.

**3. [Boy Scout] Shared private widgets in `AccountSection`**
- The two red outlined buttons (spinner while busy) and the two failure lines share `_DestructiveOutlinedButton` and `_FailureLine` instead of duplicating the «Elimina personaggio» shape. Behaviour unchanged; existing section tests green untouched.

**4. Extra cases**
- Failure test also pins `AccountDeletionException.toString()`; Cubit test adds «a failure arriving after close is harmless»; the section's failure case also asserts the line sits under the button; the AuthCubit state is now always stubbed in `pumpSection` (adventurer by default, innkeeper per case).

## Known Stubs

None. The entry is intentionally behind `accountDeletionEnabled = false` and has no shell provider; the gate 25-07 adds the GraphQL `AccountDeletionApi`, the providers (`AccountDeletionRepository` with the session service as `SessionTerminator`, `AccountDeletionCubit`) and flips the switch.

## Threat Flags

None beyond the plan's register: T-25-20 (Annulla / Elimina tests), T-25-21 (repository grep + `verifyNoMoreInteractions`), T-25-22 (flow test), T-25-24 (codes only), T-25-25 (no document, switch off, no provider).

## For the next plans

- 25-04 implements `deleteAccountByTwitchLogin` on the same `AccountDeletionApi` (the fake already records `deletedTwitchLogins` and throws `error` from both methods); `operationExceptionWithCode(code, {message})` lives in `test/helpers/fakes/fake_account_deletion_api.dart`.
- 25-07: when the switch flips, `settings_test.dart` already provides a `MockAccountDeletionCubit` (idle); `AccountSection` reads `AuthCubit` (role) and `AccountDeletionCubit` only when enabled. The shell must provide `AccountDeletionCubit` above the Settings page.

## Self-Check: PASSED

Commits `7cbc5d9f`, `2ec41092`, `1c5dff88`, `35dafd40`, `977c099e`, `a6c0d704` present in `git log`; all created files exist.
