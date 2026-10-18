---
phase: 04-settings-screen
reviewed: 2026-10-18T00:00:00Z
depth: standard
files_reviewed: 39
files_reviewed_list:
  - lib/config/cloudinary_assets.dart
  - lib/graphql/mutations/character_mutations.dart
  - lib/main.dart
  - lib/models/notification_category.dart
  - lib/repository/character_deletion_failure.dart
  - lib/repository/character_deletion_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/storage/notification_preferences_store.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/components/menu_background.dart
  - lib/screens/mainScreen/components/menu_item.dart
  - lib/screens/mainScreen/components/menu_section.dart
  - lib/screens/mainScreen/components/satchel_layout.dart
  - lib/screens/mainScreen/components/satchel_menu.dart
  - lib/screens/mainScreen/main_screen.dart
  - lib/screens/mainScreen/tabs/settings/components/account_section.dart
  - lib/screens/mainScreen/tabs/settings/components/character_deletion_messages.dart
  - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
  - lib/screens/mainScreen/tabs/settings/components/settings_section.dart
  - lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart
  - lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_state.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart
  - lib/screens/mainScreen/tabs/settings/settings.dart
  - lib/shared/components/modal/delete_character_confirmation_dialog.dart
  - lib/shared/components/modal/destructive_confirmation_dialog.dart
  - lib/shared/components/modal/logout_confirmation_dialog.dart
  - lib/theme/kg_theme.dart
  - tool/schema_check/schema_check_documents.dart
  - test/helpers/fakes/fake_shared_preferences_async.dart
  - test/helpers/fakes/in_memory_notification_preferences_store.dart
  - test/helpers/mocks.dart
  - test/repository/character_deletion_repository_test.dart
  - test/repository/storage/notification_preferences_store_test.dart
  - test/screens/auth/authenticated_shell_test.dart
  - test/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit_test.dart
  - test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart
  - test/screens/mainScreen/tabs/settings/components/account_section_test.dart
  - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
findings:
  critical: 0
  warning: 2
  info: 6
  total: 8
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-10-18
**Depth:** standard
**Files Reviewed:** 39 (`flutter analyze` reports nothing in phase files)
**Status:** issues_found

## Summary

The phase is well built. Layering follows the project rules:

- The UI never touches the network. `AccountSection` talks only to `CharacterDeletionCubit`.
- The repository wraps every `OperationException` and `FormatException` into a domain exception and does not know `BuildContext`.
- Server message text is never shown or logged. Only `extensions.code` is used, and `debugPrint` logs `error.runtimeType` only.
- The deletion hand-over is sound:
  - `listenWhen` (`deletedUser: null -> non-null`) fires exactly once per delivery.
  - The `notFound` recovery is single-shot and double taps are blocked by `isDeleting`.
  - `adoptUser` checks the session and the same user id, so a stale or foreign user is rejected.
  - A rejected hand-over unlocks the button through `handoverRejected()`.
  - `SafeEmit` makes emit-after-close safe.

No critical issues. There are two warnings, both edge cases with a small blast radius, and a handful of info items.

## Warnings

### WR-01: Deletion confirmed after the shell was torn down still fires the mutation

**File:** `lib/screens/mainScreen/tabs/settings/components/account_section.dart:67-74` (and `lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart:19-24`)

**Issue:** The confirmation dialog is non-dismissible and lives on the root Navigator, outside the shell. This is documented in the shell comments.

If the session ends while the dialog is open (watchdog `terminateSession`, revoked refresh token), `AuthGate` removes the shell and closes `CharacterDeletionCubit`. The dialog stays on screen.

On "Elimina", `cubit.deleteCharacter()` runs on a closed cubit:

1. `state.isDeleting` is false.
2. `emit` is silently swallowed by `SafeEmit`.
3. `_repository.deleteCurrentCharacter()` still sends the `deleteCharacter` mutation through `resolveClient: () => widget.graphQlClient.value`, which is the current client.

Today this most likely ends in UNAUTHENTICATED, but if a new session has already been opened the identity comes from whichever bearer the client holds. That is a destructive, irreversible mutation triggered from a dead scope, with no UI to show the outcome.

**Fix:** Guard on the cubit lifecycle before and after the dialog.

```dart
Future<void> _confirmDeletion(BuildContext context) async {
  final cubit = context.read<CharacterDeletionCubit>();
  final confirmed = await showDeleteCharacterConfirmation(
    context,
    characterName: characterName,
  );
  if (confirmed && !cubit.isClosed) await cubit.deleteCharacter();
}
```

Better still, make it an invariant of the cubit by adding `if (isClosed || state.isDeleting) return;` at the top of `deleteCharacter()`. Add a cubit test for "closed cubit does not call the repository". Optionally, pop the dialog when the shell is disposed.

### WR-02: Optimistic rollback in `toggle` can leave the UI diverging from storage

**File:** `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart:41-55`

**Issue:** The rollback restores `!enabled`, not the value held before the tap, and it does so unconditionally.

Two quick taps on the same category, with both writes failing:

1. Stored value is `true`.
2. `toggle(false)` emits false and starts write A.
3. `toggle(true)` emits true and starts write B.
4. A fails and emits `!false = true`. This is harmless.
5. B fails and emits `!true = false`.
6. The UI shows OFF while storage still holds ON.

A background reader (Phase 5, D-14) would then deliver notifications the user sees as disabled. Concurrent `setBool` calls also have no ordering guarantee between them.

**Fix:** Capture the previous value and roll back only if the state is still the optimistic one. Optionally serialize the writes per category.

```dart
final previous = state.isEnabled(category); // == !enabled given the guard
emit(state.withCategory(category, enabled: enabled));
try {
  await _store.setEnabled(_userId, category, enabled: enabled);
} catch (error) {
  debugPrint('[NotificationPreferences] write failed: ${error.runtimeType}');
  if (state.isEnabled(category) == enabled) {
    emit(state.withCategory(category, enabled: previous));
  }
}
```

## Info

### IN-01: `LogoutConfirmationDialog` is dead code after the refactor

**File:** `lib/shared/components/modal/logout_confirmation_dialog.dart:11-20`

**Issue:** `showLogoutConfirmationDialog` now goes through `showDestructiveConfirmation` and no longer instantiates the `LogoutConfirmationDialog` widget. Nothing in `lib/` or `test/` references the class. Its title, body and label constants are the only link to the helper.

**Fix:** Delete the class and keep the three constants and the two functions (Boy Scout rule).

### IN-02: Notification default `true` is defined in three places

**File:** `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart:9-18`, `lib/repository/storage/notification_preferences_store.dart:29`

**Issue:** The default is encoded in three places:

- `NotificationPreferencesState.defaults`
- `enabled[category] ?? true`
- `SharedPreferencesNotificationPreferencesStore.defaultEnabled`

Changing one silently disagrees with the others.

**Fix:** Derive the state defaults from `NotificationPreferencesStore.defaultEnabled` (or move the constant to `NotificationCategory`). Use `enabled[category] ?? SharedPreferencesNotificationPreferencesStore.defaultEnabled`.

### IN-03: Unexpected errors are swallowed without reaching the `BlocObserver`

**File:** `lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart:39-41, 57-59`

**Issue:** The two `catch (_)` blocks give a correct anti-spinner guarantee, but a genuine programming error (cast failure, `StateError`) is lost with no trace. `AuthCubit.start` already uses `addError` for the equivalent case.

**Fix:** `catch (error, stackTrace) { addError(error, stackTrace); return CharacterDeletionFailure.unknown; }`.

### IN-04: A failed preferences read silently shows "all on"

**File:** `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart:33-36`

**Issue:** On a read failure the cubit emits `isLoaded: true` with the defaults (all enabled). A user who had disabled a category sees it ON, and the first tap writes the inverse of what is really stored. This is consistent with D-12 (no error UI), but it is worth documenting or testing the intended behaviour.

**Fix:** Keep the behaviour, but add a one-line comment on the trade-off. Alternatively, keep the switches inert (`isLoaded: false`) after a failed read.

### IN-05: Unrelated formatting churn in `cloudinary_assets.dart`

**File:** `lib/config/cloudinary_assets.dart` (about 25 reformatted lines)

**Issue:** The functional change is one line (`settings`). The rest is line-wrapping and whitespace rewrites of existing constants, which is noise in the PR. This is the baseline-not-formatter-clean case: the file was formatted wholesale instead of only the touched lines.

**Fix:** Revert the unrelated hunks and keep only the `settings` constant.

### IN-06: Magic numbers in the new layout code

**File:** `lib/screens/mainScreen/components/menu_background.dart:44`, `lib/screens/mainScreen/tabs/settings/settings.dart:14-15`, `lib/screens/mainScreen/components/menu_item.dart:55-65`

**Issue:** There are several unnamed constants:

- `size.height / 2 + 60` in `menu_background.dart`.
- The `25`, `50` and `+100` apex offsets in `menu_item.dart`. These were present before, but the start point and apex are recomputed on every animation frame.
- `_satchelClearance = 120` and `_sheetHorizontalMargin = 50` in `settings.dart`. These duplicate the literals `50.0` and `120` in `profile.dart`, so the two sheets can drift apart.

**Fix:** Promote the shared sheet constants to `KlimmeckGuideTheme` (or `SatchelLayout`) and name the flight geometry in `SatchelLayout`.

## Pre-existing issues (not counted)

- `lib/screens/mainScreen/components/menu_item.dart` calls `MediaQuery.of(context).size` twice inside the `AnimatedBuilder` on every frame, and the file still uses `double x0 = ...` style locals and an untyped `AnimatedContainer(duration: Duration(...))` without `const`. Using `MediaQuery.sizeOf` would avoid rebuilds on unrelated MediaQuery changes.
- `lib/shared/components/modal/paper_sheet_modal.dart` has several `MediaQuery.of(context).size` calls and magic numbers (`0.5`, `0.3`, `20`). It is not touched by the phase.
- `flutter analyze` reports 57 infos repository-wide (`avoid_print` in `tools/svg_tool.dart`, `depend_on_referenced_packages` for `rxdart` in `lib/utils/notification.dart`, and others). None are in phase files.

## Verdict

No blocking issues. Fix WR-01 (guard on `cubit.isClosed`, a one-line change) and WR-02 (conditional rollback) before merge if time allows. Neither one is a regression of the verified 5/5 truths. The info items can be folded into the same PR under the Boy Scout rule (IN-01 and IN-05 are the cheapest).

---

_Reviewed: 2026-10-18_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
