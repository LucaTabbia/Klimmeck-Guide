---
phase: 25-account-deletion-and-legal-consent
reviewed: 2026-11-25T00:00:00Z
depth: deep
diff_base: 5c0b1b80
head: 5e45e8e9
files_reviewed: 41
files_reviewed_list:
  - lib/bootstrap/klimmeck_guide_app.dart
  - lib/config/account_deletion.dart
  - lib/config/legal_documents.dart
  - lib/graphql/mutations/account_mutations.dart
  - lib/repository/account_deletion_failure.dart
  - lib/repository/account_deletion_repository.dart
  - lib/repository/player_account_deletion_failure.dart
  - lib/repository/player_account_deletion_repository.dart
  - lib/repository/services/account/account_deletion_api.dart
  - lib/repository/services/account/graphql_account_deletion_api.dart
  - lib/repository/services/auth/auth_api_exception.dart
  - lib/repository/services/auth/auth_token_service.dart
  - lib/repository/services/auth/dev_auth_token_service.dart
  - lib/repository/services/auth/login_callback.dart
  - lib/repository/services/auth/login_exception.dart
  - lib/repository/services/auth/session_auth_token_service.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/services/links/link_opener.dart
  - lib/repository/services/links/url_launcher_link_opener.dart
  - lib/repository/services/push/notification_tap_router.dart
  - lib/repository/storage/legal_consent_store.dart
  - lib/screens/auth/auth_gate.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_cubit.dart
  - lib/screens/mainScreen/tabs/settings/accountDeletionCubit/account_deletion_state.dart
  - lib/screens/mainScreen/tabs/settings/components/account_deletion_messages.dart
  - lib/screens/mainScreen/tabs/settings/components/account_section.dart
  - lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart
  - lib/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart
  - lib/screens/mainScreen/tabs/settings/components/player_account_deletion_messages.dart
  - lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart
  - lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_state.dart
  - lib/screens/signIn/components/legal_consent_row.dart
  - lib/screens/signIn/consentCubit/legal_consent_cubit.dart
  - lib/screens/signIn/consentCubit/legal_consent_state.dart
  - lib/screens/signIn/cubit/sign_in_cubit.dart
  - lib/screens/signIn/cubit/sign_in_state.dart
  - lib/screens/signIn/sign_in_screen.dart
  - lib/shared/components/modal/delete_account_confirmation_dialog.dart
  - lib/shared/components/modal/delete_player_account_confirmation_dialog.dart
  - lib/theme/kg_theme.dart
findings:
  critical: 0
  warning: 3
  info: 8
  total: 11
status: issues_found
---

# Phase 25: Code Review Report

**Reviewed:** 2026-11-25
**Depth:** deep (cross-file)
**Scope:** `git diff 5c0b1b80..HEAD -- lib test tool` (99 files; the 41 `lib` files read in full as diff, plus `tool/`; the tests read selectively, see "How this review was done")
**Status:** issues_found

## Summary

The core of the phase holds. The paths I traced end to end and found sound:

- **Own deletion, happy path and the 4409/refresh race.** `AccountDeletionRepository.deleteOwnAccount` calls the mutation and then `SessionTerminator.terminateSession(accountDeleted)`; `_endSession` is single-flight and the first reason wins, and nothing in `lib` calls `handleRevocation`, so a 4409 goes through `recoverFromUnauthorized` -> refresh -> `SESSION_REVOKED`/`accountDeleted`. Both orders end once as `accountDeleted`. The teardown is `graphQlHolder.reset()` only; `PushRegistrationCoordinator` on `AuthUnauthenticated` clears local state and makes no BE call. A lost answer after a real deletion self-heals on the next request (within the BE's 15 minutes).
- **Double tap / closed cubit / context.** Both cubits guard on `isClosed || state.isDeleting` and use `SafeEmit`; cubits are read before every `await`; no `BuildContext` crosses an async gap.
- **Consent gate.** The only caller of `AuthTokenService.login` is `SignInCubit.signInWithTwitch`, reached only from the button whose `InkWell.onTap` is `null` while unticked. A store read failure and a different remembered version both start unticked. Recognizers and the text controller are disposed.
- **Privacy.** The typed username is never in a Cubit state, an exception, a store or a log line; `performMutation` logs nothing; exceptions print only the failure name.
- **Error mapping.** Every code in the contract reaches the line listed in `BACKEND-NOTES.md` C-1/C-2; the innkeeper never sees «Elimina account» (live `BlocSelector` on the role); no client-side decision beyond hiding.
- **Rules 1 and 2.** No chrome outside Settings/login; the only spinners are on the tapped buttons.

No critical defect. Three warnings, all on edges of the two deletion flows and of the consent memory, and eight info items.

## How this review was done

Everything below comes from reading the code. **No test was run** and no finding was reproduced on a device or in a test; the failure scenarios are derived from the control flow and each one says which lines produce it. Test files were read where a finding or a claim depended on them (`account_deletion_flow_test`, `auth_gate_test`, `sign_in_screen_test`, `settings_test`, `account_deletion_test`, the fakes) and otherwise only by their test names; the tests of plan 25-06 (cancelled quest, 14 files) were not reviewed beyond their names.

## Warnings

### WR-01: «Esci» stays live while the account deletion is in flight and turns the landing into a plain logout

**File:** `lib/screens/mainScreen/tabs/settings/components/account_section.dart:46-48` (with `lib/repository/services/auth/session_auth_token_service.dart:192` and `lib/repository/account_deletion_repository.dart:23-26`)

**Issue:** While `AccountDeletionState.isDeleting` is true only the «Elimina account» button is disabled. «Esci» (and «Elimina personaggio») remain tappable. `terminateSession` is a deliberate no-op when `_logoutInFlight != null` or the session is no longer authenticated, so a logout started during the deletion wins over the deletion's own teardown.

**Failure scenario:** the player confirms «Elimina account»; the BE takes a couple of seconds (Cloudinary, seat release). Meanwhile the player taps «Esci» and confirms. `AuthCubit.logout()` runs `PushSessionCleanup.unregister()` and then `logout()` on the BE — two BE calls D-06 forbids, the second possibly with an already dead token — and the session ends as `signedOut`. When `deleteMyAccount` answers, `terminateSession(accountDeleted)` returns without doing anything. Result: the account is deleted, the login shows **no** «Il tuo account è stato eliminato.» and the consent memory is **kept** (D-03, D-10 broken). The window is short and needs a second confirmation dialog, so the probability is low; the outcome is exactly what the hard rule «the deletion path wins» excludes, and no test covers it (the race pin covers refresh/4409 only).

**Fix:** disable the other two actions while the account deletion runs, for example by lifting the `AccountDeletionCubit` selector to the section:

```dart
final isDeletingAccount = context.select<AccountDeletionCubit, bool>(
  (cubit) => cubit.state.isDeleting,
);
...
ElevatedButton(
  style: KlimmeckGuideTheme.destructiveButtonStyle,
  onPressed: isDeletingAccount ? null : () => confirmLogout(context),
```

(only when the entry is built, since with the switch off the cubit must not be read — or drop the switch first, IN-01). Add a widget test: while `isDeleting`, «Esci» and «Elimina personaggio» have `onPressed == null`. A service-level alternative (a logout that finds a deletion in flight waits for it) is heavier and not needed.

### WR-02: forgetting the consent is a side effect of the lazy `create` of the sign-in provider, so it is skipped when the sign-in is already mounted

**File:** `lib/screens/auth/auth_gate.dart:58-71, 83-91` (with `_shouldRebuild`, `auth_gate.dart:120-126`)

**Issue:** the consent memory is forgotten inside `BlocProvider.create` (`_consentFor`). `create` runs once per mounted provider. `_shouldRebuild` explicitly rebuilds on `AuthUnauthenticated(a)` -> `AuthUnauthenticated(b)`, and that rebuild updates the notice, but the `MultiBlocProvider` has no key: its element and the already created `LegalConsentCubit` are reused, so `forget()` never runs for the new reason.

**Failure scenario:** the innkeeper deletes a player's account while the player's app is closed. The player opens the app on a slow network, the splash offers «Accedi manualmente», he taps it: `AuthCubit.showSignIn()` emits `AuthUnauthenticated()` and the consent cubit is created with `restore()` (ticked). The bootstrap refresh then answers `SESSION_REVOKED`/`accountDeleted`: the notice becomes «Il tuo account è stato eliminato.» while the box stays ticked and the store keeps the version. D-10 («the memory is cleared when the account is deleted») is broken with the notice on screen saying the opposite. `auth_gate_test` already has the sibling case for the notice («sync lost then session expired re-renders the notice») but none for the consent.

A second, smaller consequence of the same design: the forgetting depends on the sign-in being built. REPO-RULES asks «local teardown through `terminateSession`, then the consent memory is forgotten»; today nothing in the deletion path itself forgets.

**Fix:** smallest change, key the provider by reason so a new reason builds a new cubit:

```dart
AuthUnauthenticated(:final reason) => MultiBlocProvider(
  key: ValueKey<UnauthenticatedReason>(reason),
  providers: [...],
```

(the `SignInCubit` is recreated too; acceptable, a login in progress on that screen is already superseded by the new state). Cleaner alternative: forget in a `BlocListener<AuthCubit, AuthState>` on `AuthUnauthenticated(reason: accountDeleted)` in `AuthGate`, independent of the provider's lifetime, and let the cubit only `restore()`. Add the test: bootstrapping -> manual sign-in with a remembered version -> `AuthUnauthenticated(accountDeleted)` => store empty, box unticked.

### WR-03: the innkeeper dialog can be dismissed and reopened while a deletion is in flight: lost outcome, a second concurrent deletion, a stray pop

**File:** `lib/screens/mainScreen/tabs/settings/components/player_account_deletion_dialog.dart:14, 54, 97-98` and `lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart:30`

**Issue:** «Annulla» (and the system back button; `barrierDismissible: false` does not stop it) close the dialog while `isDeleting` is true, the request keeps running in the shell-level cubit, and `showPlayerAccountDeletionDialog` calls `cubit.reset()` unconditionally on the next opening.

**Failure scenarios:**
1. *Silent failure.* The innkeeper confirms, then closes the dialog while the spinner turns. The BE answers `TWITCH_UNAVAILABLE`. The failure is in the cubit state but its only reader was the dialog: the section shows neither «Account eliminato.» nor an error, and reopening wipes it. For a deletion requested by email (the legal «senza l'App» path) the innkeeper believes it is done.
2. *Reset in flight.* He reopens while the first request is still running: `reset()` emits a clean state, `isDeleting` is false again, «Avanti» is enabled and a second `deletePlayer` can run concurrently (the `state.isDeleting` guard was just erased). When the first one succeeds, `hasDeleted` flips and the `listener` pops the reopened dialog with the second username half typed; if the first fails, its error line appears under a different username.

**Fix:** make the in-flight state non-dismissible and the reset safe:

```dart
// dialog
PopScope(
  canPop: !state.isDeleting,
  child: AlertDialog(
    ...
    TextButton(
      onPressed: state.isDeleting ? null : () => Navigator.of(context).pop(),

// cubit
void reset() {
  if (state.isDeleting) return;
  emit(const PlayerAccountDeletionState());
}
```

Tests: «Annulla» disabled while deleting; `reset` during a deletion keeps `isDeleting`.

## Info

### IN-01: `accountDeletionEnabled` is now a constant `true`: dead branches, stale comments, a test that cannot fail

**File:** `lib/config/account_deletion.dart:4`; `lib/screens/mainScreen/tabs/settings/components/account_section.dart:17-30, 56`; `lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart:15-27, 52`; `test/config/account_deletion_test.dart:5-7`

**Issue:** the switch existed to keep the selection off today's BE until the gate. With the gate passed the `false` branch can no longer run in production; the `isAccountDeletionEnabled` constructor parameters exist only so the tests can exercise it, and the helpers of `account_section_test.dart:41` and `innkeeper_section_test.dart:79` default to `false`, i.e. the default path of the tests is the dead one. `account_deletion_test.dart` asserts a constant equals itself. The file comment itself says «resta nel codice fino a una pulizia successiva».
**Fix:** remove the constant, the two parameters, the two «switch off» tests and `account_deletion_test.dart`; update the two class comments. If the switch must survive until the BE merge on `develop` (the gate ran on the BE branch), say so in the comment with the condition for its removal and at least flip the test helpers' default to `true`.

### IN-02: `LegalConsentCubit.restore()` can overwrite a tap made before the read completes

**File:** `lib/screens/signIn/consentCubit/legal_consent_cubit.dart:24-27`

**Issue:** `restore()` emits unconditionally after the `await`. If the user ticks the box before the platform read answers (first launch, nothing stored), `accept()` emits `true` and writes the version, then `restore()` emits `false` from the earlier read: the box unticks itself while the store says accepted. The window is a few milliseconds; the effect is a tick that visibly reverts once.
**Fix:** let a user action win: keep a `_hasUserActed` flag set by `accept`/`withdraw`/`forget` and skip the emit in `restore()` when it is set.

### IN-03: `withdraw()` and `forget()` are the same method twice

**File:** `lib/screens/signIn/consentCubit/legal_consent_cubit.dart:34-44`

**Issue:** identical bodies (emit empty state, guarded `store.forget`). Zero-duplication principle of `CLAUDE.md`.
**Fix:** keep one (`forget`) and call it from the row, or make `withdraw() => forget()` if the two names are wanted for readability.

### IN-04: `disabledOpacity` duplicates an existing value; raw `16`/`44` in the touched button code

**File:** `lib/theme/kg_theme.dart:22` (next to `pendingInkOpacity = 0.5` at line 18 and `bloodRed.withValues(alpha: 0.5)` at line 243); `lib/screens/signIn/sign_in_screen.dart:90` (`SizedBox(height: 16)`), plus the `minHeight: 44` and `horizontal: 16` of `_buttonBody`

**Issue:** three spellings of «disabled = half opacity» in the theme; the new constant is used once. The sign-in file keeps literal `16` where `KlimmeckGuideTheme.spacingMd` exists (the new line at 90 adds one more; the others are older but sit in the method the phase rewrote — Boy Scout).
**Fix:** use `disabledOpacity` in `destructiveButtonStyle` too (or reuse one name for both), and `spacingMd` for the new `SizedBox`.

### IN-05: the new `checkboxTheme` is global and draws a parchment border

**File:** `lib/theme/kg_theme.dart:214-218`

**Issue:** `side: BorderSide(color: parchment)` suits the dark login only. Today the login's is the only `Checkbox` in `lib`, so nothing is broken; the next checkbox on a parchment surface (most of the app) will have an invisible empty box.
**Fix:** move the three values onto the `Checkbox` of `LegalConsentRow`, or wrap the row in a local `CheckboxTheme`.

### IN-06: accessibility of the login button and of the consent sentence, to verify with TalkBack at the UAT

**File:** `lib/screens/signIn/sign_in_screen.dart:165-169`; `lib/screens/signIn/components/legal_consent_row.dart:53-65`

**Issue:** (a) the login button is `Semantics(button, enabled, label, excludeSemantics: true)` with no `onTap`: `excludeSemantics` drops the `InkWell`'s tap action, so the node announces a button but exposes no tap action of its own. The structure predates the phase (only `enabled` is new), but the phase makes the screen depend on a screen-reader user ticking the box and then activating this button. Whether TalkBack's double tap still reaches the `InkWell` on the target devices is not something I could establish from the code. (b) The sentence is announced twice: once as the checkbox label, then again as four text fragments («Accetto i», link, «e l'», link). The two links are correctly separate nodes (the rule is met); the plain fragments are noise.
**Fix:** (a) pass `onTap: isEnabled && !isLoading ? onPressed : null` to the `Semantics`; (b) optional, accept as is or exclude the plain fragments. Check both with TalkBack in the device UAT.

### IN-07: duplicated copy and a duplicated spinner

**File:** `lib/screens/mainScreen/tabs/settings/components/account_deletion_messages.dart:6, 9-10`; `.../player_account_deletion_messages.dart:14-16`; `lib/screens/signIn/sign_in_screen.dart:18`; `.../innkeeper_section.dart:68` and `.../player_account_deletion_dialog.dart:74` («Elimina un account»); `.../account_section.dart:147-153` and `.../player_account_deletion_dialog.dart:162-168` (the 16 px, stroke 2 spinner)

**Issue:** «Errore di connessione, riprova» is now spelled in three files and «Impossibile eliminare l'account, riprova» in two; the button label and the dialog title are two literals of the same string; the in-button spinner is copied with only the colour changed (and `strokeWidth: 2` is a bare number in both).
**Fix:** one shared constant per sentence (the two deletion message files can share a small private library), `InnkeeperSection`-style `static const` for the label, and one `ButtonSpinner(color:)` in `shared/components/`.

### IN-08: directory name does not follow `<feature>Cubit/<feature>_cubit.dart`

**File:** `lib/screens/mainScreen/tabs/settings/playerDeletionCubit/player_account_deletion_cubit.dart`

**Issue:** `docs/rules/state-management.md` pairs the directory with the file name; here the directory drops «Account» (`playerDeletionCubit/` vs `accountDeletionCubit/` for its sibling). The older `deletionCubit/character_deletion_cubit.dart` has the same drift, so this follows a precedent rather than the rule.
**Fix:** rename to `playerAccountDeletionCubit/` (imports only), or leave both and note the convention as accepted.

## Checked and found in order (no finding)

- Layering: UI -> Cubit -> Repository -> API; repositories know no `BuildContext`; no model or GraphQL document imports Flutter; both state classes are `Equatable` with complete `props`; the shell-level placement of the two deletion cubits matches `CharacterDeletionCubit`. `LegalConsentCubit` talks to a store directly, as `NotificationPreferencesCubit` already does.
- `termsVersion` is added next to `challenge` on the start URL; `terms_not_accepted` maps to its own exception, failure and line; the dev bypass ignores the version but the UI gate still applies.
- `TOO_MANY_REQUESTS`, `FORBIDDEN`, `UNAUTHENTICATED` and unknown codes read the generic line as `BACKEND-NOTES.md` states; a link failure without a code reads the connection line.
- D-17: nothing was added to the character-creation screen.
- `tool/hardening_check.sh`: the new store is in the allow-list and its key carries no token; the schema registry lists both documents.

---

_Reviewed: 2026-11-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: deep_
