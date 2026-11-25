---
phase: 25-account-deletion-and-legal-consent
plan: 04
subsystem: settings
tags: [account-deletion, innkeeper, settings, dialog, privacy]
requires: [25-03]
provides:
  - PlayerAccountDeletionFailure + PlayerAccountDeletionException + playerAccountDeletionFailureFrom (twitchUserNotFoundCode, accountNotFoundCode, twitchUnavailableCode)
  - PlayerAccountDeletionRepository.deletePlayerAccount (AccountDeletionApi.deleteAccountByTwitchLogin)
  - PlayerAccountDeletionCubit / PlayerAccountDeletionState (deletePlayer, reset)
  - PlayerAccountDeletionFailureMessage extension
  - showPlayerAccountDeletionDialog + PlayerAccountDeletionDialog (fieldKey)
  - showDeletePlayerAccountConfirmation
  - InnkeeperSection.isAccountDeletionEnabled
  - MockPlayerAccountDeletionRepository, MockPlayerAccountDeletionCubit
affects: [25-07]
tech-stack:
  added: []
  patterns:
    - dialog on the root Navigator owning its TextEditingController, Cubit passed with BlocProvider.value
    - reverse SingleChildScrollView keeps the field in sight with the keyboard in landscape
key-files:
  created:
    - lib/repository/player_account_deletion_failure.dart
    - lib/repository/player_account_deletion_repository.dart
    - lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart
    - lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_state.dart
    - lib/screens/mainScreen/tabs/settings/components/player_account_deletion_messages.dart
    - lib/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart
    - lib/shared/components/modal/delete_player_account_confirmation_dialog.dart
    - test/repository/player_account_deletion_failure_test.dart
    - test/repository/player_account_deletion_repository_test.dart
    - test/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit_test.dart
    - test/screens/mainScreen/tabs/settings/components/player_account_deletion_messages_test.dart
    - test/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog_test.dart
  modified:
    - lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart
    - test/helpers/mocks.dart
    - test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart
    - test/screens/mainScreen/tabs/settings/settings_test.dart
decisions:
  - "Dedicated PlayerAccountDeletionRepository / PlayerAccountDeletionFailure instead of growing InnkeeperRepository / InnkeeperFailure; FORBIDDEN reads the generic line"
  - "The success state carries no username: the section reads «Account eliminato.» and the typed text lives only in the dialog's controller"
  - "The dialog title sits inside a reverse scroll with the field, so the keyboard in landscape scrolls the title away, never the field"
  - "No shell provider for PlayerAccountDeletionCubit before 25-07; settings_test already provides an idle mock"
metrics:
  duration: ~25 min
  completed: 2026-11-25
  tasks: 3
  files: 16
---

# Phase 25 Plan 04: Innkeeper's account deletion by Twitch username Summary

The innkeeper can delete a player's account from the Twitch username, behind `accountDeletionEnabled = false`: «Elimina un account» (red outline, under «Apri la Locanda») opens a dialog on the root Navigator with the «Nome utente Twitch» field, «Avanti» enabled only for a non-blank trimmed text, then the destructive confirmation naming the trimmed username, then `PlayerAccountDeletionCubit.deletePlayer` → `PlayerAccountDeletionRepository` → `AccountDeletionApi.deleteAccountByTwitchLogin` (fake until the gate). Each BE code reads its own Italian line inside the dialog with the text kept for a correction; a success closes the dialog and the section reads «Account eliminato.».

## Tasks

| Task | Commits |
|------|---------|
| 1 Failure mapping, repository, Cubit, messages | `def3fcd4` test(innkeeper): expect the player account deletion by username; `f0f0836c` feat(innkeeper): delete a player account by Twitch username |
| 2 Dialog, confirmation, «Locanda» entry | `560ca621` test(innkeeper): expect the username dialog and the Locanda entry; `2f636233` feat(innkeeper): username dialog and Locanda entry to delete an account |
| 3 Bookkeeping | `docs(phase-25): record plan 04 progress` |

## RED failures

- Task 1: compile failure — `lib/repository/player_account_deletion_failure.dart`, `player_account_deletion_repository.dart` and `player_account_deletion_cubit.dart` missing (`Undefined name 'PlayerAccountDeletionFailure'`, types missing in `mocks.dart`).
- Task 2: compile failure — `player_account_deletion_dialog.dart` missing (`Undefined name 'PlayerAccountDeletionDialog'`), `No named parameter with the name 'isAccountDeletionEnabled'` on `InnkeeperSection`.

Green at first GREEN run: every case except the landscape keyboard one (below). The settings_test cases stayed green (only the idle provider was added; the switch is off).

## Copy as written (provisional, reviewed at the UAT)

- entry «Elimina un account»; dialog title «Elimina un account»; field label «Nome utente Twitch»; buttons «Annulla» / «Avanti»
- confirmation title «Eliminare l'account di <nome>?»; body «Tutti i personaggi di <nome>, anche quelli archiviati, il saldo dei punti e il ritratto andranno perduti per sempre. L'azione è irreversibile.»; confirm «Elimina», Annulla from the shared dialog
- failures: twitchUserNotFound «Nessun utente Twitch con questo nome»; accountNotFound «Questo utente non ha un account nella Guida»; innkeeperProtected «Non puoi eliminare l'account di un oste»; twitchUnavailable «Twitch non risponde, riprova più tardi»; connection «Errore di connessione, riprova»; unknown «Impossibile eliminare l'account, riprova»
- success line «Account eliminato.»

## Verification

- `flutter test test/repository/player_account_deletion_failure_test.dart test/repository/player_account_deletion_repository_test.dart test/screens/mainScreen/tabs/settings/playerDeletionCubit test/screens/mainScreen/tabs/settings/components/player_account_deletion_messages_test.dart` → `+25: All tests passed!`
- `flutter test test/screens/mainScreen/tabs/settings` → `+122: All tests passed!`
- Analyzer after each code task: «47 issues found.» `ANALYZE_GATE_OK`
- Greps: `'INNKEEPER_ACCOUNT_PROTECTED'` in the new failure file 0 (the 25-03 constant is reused); `appLog|print(|debugPrint` in repository and Cubit 0; `TextField|TextFormField` in `innkeeper_section.dart` 0; `dispose` in the dialog 3; `appLog|print(|debugPrint|SharedPreferences` in dialog and section 0; `PlayerAccountDeletionCubit` in `authenticated_shell.dart` 0; `git diff -- lib/graphql` empty.
- `grep -rln "const Settings()\|InnkeeperSection(" test` → only `settings_test.dart` (now with the idle provider) and `innkeeper_section_test.dart` (passes the switch explicitly).

## Deviations from Plan

**1. [Rule 1 - Layout] The dialog title moved into a reverse scroll with the field**
- Found during: Task 2 GREEN, landscape keyboard case.
- Issue: with `AlertDialog(scrollable: true, title: …)` and the keyboard open, title and field share a 72 px scroll viewport starting at the title; the field fell under the clip (not hit-testable), and the focused field's caret reveal did not scroll it in the test.
- Fix: `title` left empty; the title text, a spacer, the field and the failure line live in `content` inside a `SingleChildScrollView(reverse: true)`, with compact `contentPadding` / `actionsPadding` and a `spacingSm` vertical inset: the bottom (field + failure) stays in sight, the title scrolls away when space is short. Visible result without the keyboard is unchanged in shape.
- Files: `player_account_deletion_dialog.dart`. Commit `2f636233`.

**2. [Test value] Keyboard height in the C5 case**
- The plan asks «`viewInsets` bottom ≥ 300»; the test uses `FakeViewPadding(bottom: 600)` physical = 200 logical on the 360 logical landscape phone (a typical landscape keyboard). 300 logical (the companion-sheet convention) leaves 60 px, where no AlertDialog with a fixed actions row fits. If the UAT shows a taller keyboard, the retouch is in the dialog layout (research A2 allows it).

**3. Extra cases**
- Dialog: «Annulla closes the dialog and deletes nothing»; section: «Elimina un account opens the username dialog (D-15)» (reads the Cubit and calls `reset`), «no success line before a deletion»; failure test pins `PlayerAccountDeletionException.toString()` (only `failure.name`); Cubit test adds «nothing happens after close».

## Known Stubs

None. The entry is intentionally behind `accountDeletionEnabled = false` with no shell provider; the gate 25-07 adds the GraphQL `AccountDeletionApi` (both mutations), the providers (`PlayerAccountDeletionRepository`, `PlayerAccountDeletionCubit` above the Settings page) and flips the switch.

## Threat Flags

None beyond the plan's register: T-25-30 (confirmation names the trimmed username; tests), T-25-31/32 (codes mapped, `FORBIDDEN` generic), T-25-33 (controller owned and disposed by the dialog, no username in the Cubit state, no log, no store; greps), T-25-34 (trim only).

## For the next plans

- 25-07: provide `PlayerAccountDeletionRepository(api: <GraphQL AccountDeletionApi>)` and `PlayerAccountDeletionCubit` in the shell above Settings (the innkeeper section reads the Cubit only when the switch is on); `settings_test.dart` already provides idle mocks of both deletion Cubits. The GraphQL implementation of `deleteAccountByTwitchLogin` should ignore the `DeletedAccount { twitchId }` payload (the API returns `void`) and must not log the variable.
- The dialog's `PlayerAccountDeletionDialog.fieldKey` is the handle for any later widget test.

## Self-Check: PASSED

Commits `def3fcd4`, `f0f0836c`, `560ca621`, `2f636233` present in `git log`; all created files exist.
