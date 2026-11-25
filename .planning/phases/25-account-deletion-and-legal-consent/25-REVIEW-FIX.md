---
phase: 25-account-deletion-and-legal-consent
fixed_at: 2026-11-25T09:24:13Z
review_path: .planning/phases/25-account-deletion-and-legal-consent/25-REVIEW.md
iteration: 1
findings_in_scope: 11
fixed: 9
not_needed: 0
deferred: 2
skipped: 0
status: partial
suite: 5694 green
analyzer: 47 issues found
---

# Phase 25: Code Review Fix Report

**Fixed at:** 2026-11-25T09:24:13Z
**Source review:** `.planning/phases/25-account-deletion-and-legal-consent/25-REVIEW.md` (0 critical, 3 warnings, 8 info)
**Branch:** `feat/25-account-deletion-and-legal-consent`, from `85301ad9` to `dcad1478` (14 commits), plus the docs commit of this report.
**Iteration:** 1. Scope: all 11 findings, following the orchestrator's ruling for each one.

`status: partial` is there only because IN-05 and part of IN-06 go to the device UAT, as the ruling asks. Every warning is fixed.

## Summary

| Finding | Outcome | RED | GREEN / refactor |
|---------|---------|-----|------------------|
| WR-01 «Esci» live during the account deletion | fixed | `08d2a2cc` | `548b32d1` |
| WR-02 consent forgotten only by the lazy `create` | fixed | `69a5a502` | `6ba0ddd5` |
| WR-03 innkeeper dialog dismissible while deleting | fixed | `64117f5a` | `79c82816` |
| IN-01 dead switch `accountDeletionEnabled` | fixed | not expressible (see below) | `1843d657` |
| IN-02 `restore()` overwrites an earlier tap | fixed | `d53e3c34` | `e7e92ddb` |
| IN-03 `withdraw()` = `forget()` | fixed | not expressible | `cf061477` |
| IN-04 `disabledOpacity`, literal `16` | fixed | not expressible | `0d6d1be5` |
| IN-05 global `checkboxTheme` with a parchment border | deferred to UAT | — | — |
| IN-06 login button semantics / consent sentence read twice | deferred to UAT (both parts; (b) was tried and reverted) | — | — |
| IN-07 copy written in several places, spinner copied | fixed (copy and label); spinner left as is, as the ruling allows | not expressible | `795f41f3` |
| IN-08 directory name not matching the file | fixed | not expressible (rename) | `58de50ba` + `dcad1478` |

I did WR-01 after IN-01 on purpose. The review itself says to drop the switch first, and doing it in that order meant the WR-01 test did not have to pass a parameter that was about to disappear. WR-02 builds on IN-02: the consent cubit now lives as long as the gate, and IN-02 is what makes a `forget()` win over a `restore()` that is still reading the store.

## Fixed issues

### WR-01: «Esci» stays live while the account deletion is in flight

**Files:** `lib/screens/mainScreen/tabs/settings/components/account_section.dart`, `test/.../components/account_section_test.dart`
**Commits:** `08d2a2cc` (RED), `548b32d1` (fix)
**Change:** `AccountSection` reads `context.select<AccountDeletionCubit, bool>((c) => c.state.isDeleting)`. While it is true, «Esci» (`ElevatedButton.onPressed`) and «Elimina personaggio» get `onPressed: null`, so `AuthCubit.logout()` cannot start and win over `terminateSession(accountDeleted)`. The «Elimina account» button already had its own spinner and disabled state. `_DestructiveOutlinedButton.onPressed` is now nullable.
**Scope (orchestrator ruling):** I kept it narrow. A **character** deletion in flight still leaves «Esci» and «Elimina account» enabled, because the section never disabled them for it before and the finding does not need that change.
**Test:** «while the account deletion runs Esci and Elimina personaggio are inert: no logout can race the deletion (D-06, WR-01)». With `isDeleting: true`, both `onPressed` are null, tapping either opens no dialog, and `logout` / `deleteCharacter` are never called. The RED failed on `Expected: null, Actual: Closure`. The RED version used `pumpAndSettle` on a spinner that never stops, and the fix commit changes that to a single `pump()`; the commit message says so.

### WR-02: forgetting the consent depended on the lifetime of the sign-in provider

**Files:** `lib/screens/auth/auth_gate.dart`, `test/screens/auth/auth_gate_test.dart`
**Commits:** `69a5a502` (RED), `6ba0ddd5` (fix)
**Change:** this is the cleaner alternative from the review. The `LegalConsentCubit` is now provided by `AuthGate` itself (`..restore()` once) instead of the lazy `create` of the sign-in branch, so the branch only provides `SignInCubit`. A second gate-level `BlocListener<AuthCubit, AuthState>` with `listenWhen: _arrivesWithAccountDeleted` calls `context.read<LegalConsentCubit>().forget()`. That clears the store **and** the visible box, whether the sign-in screen is already showing or not. `_consentFor` is gone. A plain logout and every other reason keep the memory, and the existing gate tests for `signedOut` and `sessionExpired` still pass. The class comment explains the new lifetime.
**Test:** «a sign-in already shown with the box ticked forgets the consent when the account-deleted reason arrives (D-10, WR-02)». This is the review's scenario. The store holds the current version; the splash shows «Accedi manualmente», which is tapped; the box starts ticked; then `AuthUnauthenticated(accountDeleted)` arrives. Expected: the notice «Il tuo account è stato eliminato.», the box unticked, `store.acceptedVersion == null`. The RED failed on `isTicked` (`Expected: false, Actual: true`) while the notice was already correct. The existing test «the account-deleted landing forgets the consent» still passes.

### WR-03: the innkeeper dialog could be dismissed and reopened during a deletion

**Files:** `lib/.../components/player_account_deletion_dialog.dart`, `lib/.../playerAccountDeletionCubit/player_account_deletion_cubit.dart`, and their two tests
**Commits:** `64117f5a` (RED), `79c82816` (fix)
**Change:** the dialog body is wrapped in `PopScope(canPop: !state.isDeleting)`, and «Annulla» gets `onPressed: null` while a deletion is running. `barrierDismissible: false` was already set in every state. `PlayerAccountDeletionCubit.reset()` does nothing while `isDeleting`. The build method was split into `_buildDialog(state)`.
**Tests:**
- «Annulla and the back button cannot close the dialog»: Annulla's `onPressed` is null, and after a tap plus `binding.handlePopRoute()` the dialog is still there.
- «a failure arriving reads in the still-open dialog»: after the attempts to close it, `twitchUnavailable` shows its line inside the dialog and Annulla works again.
- Cubit: «a reset while deleting keeps the deletion in flight: no second deletion can start (WR-03)». Sequence: `deletePlayer` is in flight → `reset()` → a second `deletePlayer`. The states are exactly `[deleting, deleted]` and only the first username reaches the repository.

The REDs failed for the right reasons: Annulla not null, the failure line missing because the dialog had already closed, and an extra clean state emitted at index 1.

### IN-01: `accountDeletionEnabled` was always `true`

**Files:** deleted `lib/config/account_deletion.dart` and `test/config/account_deletion_test.dart`; `account_section.dart`, `innkeeper_section.dart` and their two tests
**Commit:** `1843d657`
**Change:** the constant, the two `isAccountDeletionEnabled` parameters, the dead branches and the stale class comments are removed. The tests now simply mount the sections. The two «switch off» tests are gone. Two older account-section tests used `find.byType(OutlinedButton)`, which now matches two buttons, so they use `.first` (the character button).
**RED:** I could not write a failing test for this. Behaviour in production does not change, since the switch was already on, and a test that stops passing the parameter passes against the old code too. The suite was green before and after: 177 targeted tests.

### IN-02: `restore()` could overwrite a tap made before the store answered

**Files:** `lib/screens/signIn/consentCubit/legal_consent_cubit.dart`, its test
**Commits:** `d53e3c34` (RED), `e7e92ddb` (fix)
**Change:** a private `_hasExplicitChoice` is set by `accept` and `forget` (and by `withdraw`, until IN-03 removed it). `restore()` does not emit if a choice arrived while it was waiting for the read.
**Tests:** these use a store whose read is a `Completer`. «a tick made while the read is pending is kept»: state ticked and version stored. «a forget made while the read is pending stays unticked»: state unticked and store empty; WR-02 needs this one. Both REDs failed on the state.

### IN-03: `withdraw()` and `forget()` had the same body

**Files:** `legal_consent_cubit.dart`, `lib/screens/signIn/components/legal_consent_row.dart`, the cubit test
**Commit:** `cf061477`
**Change:** I kept `forget()`, because the name reads right in both places it is called: the row (untick) and the gate (account deleted). The row now calls `forget()`. The `withdraw` test is merged into the `forget` test. RED not expressible: this only removes duplicated code.

### IN-04: `disabledOpacity` duplicated a theme value; a literal `16` in the sign-in

**Files:** `lib/theme/kg_theme.dart`, `lib/screens/signIn/sign_in_screen.dart`
**Commit:** `0d6d1be5`
**Change:** `disabledOpacity` is removed. The login button and the disabled background of `destructiveButtonStyle` now use the existing `pendingInkOpacity` (0.5). That was the third way of writing «half opacity», and it is the colour «Esci» shows when WR-01 disables it. The constant's comment now names both uses. The two `SizedBox(height: 16)` in the login column and the button's `horizontal: 16` padding use `spacingMd`. `minHeight: 44` stays because the theme has no tap-target constant. RED not expressible: the values are identical.

### IN-07: copy written in several places

**Files:** new `lib/utils/failure_lines.dart`; `account_deletion_messages.dart`, `player_account_deletion_messages.dart`, `character_deletion_messages.dart`, `character_creation_messages.dart`, `sign_in_screen.dart`, `player_account_deletion_dialog.dart`, `innkeeper_section.dart`
**Commit:** `795f41f3`
**Change:** «Errore di connessione, riprova» is now `connectionFailureLine` and «Impossibile eliminare l'account, riprova» is `accountDeletionFailedLine`, both defined once in `lib/utils/failure_lines.dart`, next to the other `*_lines.dart` copy files. The connection line was in five places, not three: besides the three named in the review, the character deletion and character creation messages had it too. I moved those two as well under the Boy Scout rule; the text is identical. «Elimina un account» is `PlayerAccountDeletionDialog.title`, read by the dialog title and by the innkeeper's button. The **spinner** is unchanged: the two copies live in different sections (Account vs the Locanda dialog), and the ruling only asks to merge them when they share a section. RED not expressible: the copy is unchanged and the existing tests check it word for word.

### IN-08: `playerDeletionCubit/` did not match `player_account_deletion_cubit.dart`

**Files:** `lib/.../settings/playerDeletionCubit/` → `playerAccountDeletionCubit/` (and the same in `test/`); imports in `authenticated_shell.dart`, `innkeeper_section.dart`, `player_account_deletion_dialog.dart`, `test/helpers/mocks.dart` and five test files
**Commits:** `58de50ba` (the moves), `dcad1478` (the imports)
**Change:** imports only. **One slip:** a `git add` with a stale pathspec aborted, so `58de50ba` contains only the three moves and does not build on its own. `dcad1478` adds the nine import updates, and its message says so. Together the two commits are the rename. I did not rewrite history. The older `deletionCubit/character_deletion_cubit.dart` keeps its name because it is outside this phase.

## Deferred to the device UAT

### IN-05: the global `checkboxTheme` draws a parchment border

**File:** `lib/theme/kg_theme.dart:214-218`
**Reason:** deferred to UAT. Nothing is broken today: the login is the only `Checkbox` in the app. Whether to move the border onto `LegalConsentRow` is a visual call to make with the screen in front of you.

### IN-06: login button semantics and the consent sentence read twice

**Files:** `lib/screens/signIn/sign_in_screen.dart:165-169`, `lib/screens/signIn/components/legal_consent_row.dart:53-65`
**Reason (a):** deferred to UAT. Check with TalkBack whether a double tap on the «Login con Twitch» node, which uses `excludeSemantics` and has no `onTap`, still reaches the `InkWell`. If it does not, the fix is one line: `onTap` on the `Semantics`.
**Reason (b):** deferred to UAT. It turned out not to be a small change. I tried `semanticsLabel: ''` on the two plain `TextSpan`s, with a `find.semantics` test. It removes the duplicate nodes, but `toPlainText()` includes semantics labels, so the visible sentence no longer matches `find.text` and `tapOnText` (2 existing tests went red). I reverted it before committing anything; there is no commit for this. To fix it properly the sentence has to be restructured (separate link nodes over excluded text), and the result needs to be checked by ear with TalkBack.

## From the verification notes

`25-VALIDATION.md` changes, committed together with this report:
- Frontmatter: `wave_0_complete: true`.
- The Wave 0 mocks line is ticked (the four mocks exist in `test/helpers/mocks.dart`).
- The schema-check row names the BE branch `feat/26-eliminazione-account-e-consenso` at `df22b017`, to re-run on BE `develop` after the BE merge.
- The rows and Wave 0 lines that pointed at the removed switch test or the old `playerDeletionCubit/` path are updated.

## Final numbers (foreground, after all fixes)

- Full suite: `02:05 +5694: All tests passed!`. That is 5691 before this round, minus 4 removed tests (two «switch off» tests, the switch's config test, the `withdraw` test merged into `forget`), plus 7 new ones (WR-01: 1, WR-02: 1, WR-03: 3, IN-02: 2).
- `flutter analyze --no-fatal-infos`: «47 issues found», `ANALYZE_GATE_OK`. The count did not change.
- `bash tool/hardening_check.sh | tail -1`: `hardening_check: OK`.
- Schema check (BE repo read-only; `git -C <BE> status --short` printed nothing): `dumped 57 documents`, 57 × `OK`, nothing else, exit 0, against `src/schema.gql` of `df22b017`. The BE branch tip has since moved to `58ccd402` with one docs-only commit (`docs(phase-26): record the real boot from the branch`) and no SDL change. The check against that tip is also 57 × OK.
- Every commit was checked: subject ≤ 72 characters, counted before committing, and the trailer grep printed `0`.

---

_Fixed: 2026-11-25T09:24:13Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
