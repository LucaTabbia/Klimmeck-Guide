---
phase: 04-settings-screen
fixed_at: 2026-10-18T00:00:00Z
review_path: .planning/phases/04-settings-screen/04-REVIEW.md
iteration: 1
findings_in_scope: 4
fixed: 4
skipped: 0
status: all_fixed
---

# Phase 4: Code Review Fix Report

**Source review:** .planning/phases/04-settings-screen/04-REVIEW.md
**Iteration:** 1

Gates: `flutter test` is green with 762 tests (baseline 759). `flutter analyze` stays at 57 issues, all pre-existing and none in touched files. Every touched Dart file passes `dart format --set-exit-if-changed`.

## Fixed Issues

### WR-01: Deletion confirmed after the shell was torn down still fires the mutation

**Files modified:** `lib/screens/mainScreen/tabs/settings/deletionCubit/character_deletion_cubit.dart`, `lib/screens/mainScreen/tabs/settings/components/account_section.dart`
**Commits:** test 17691ab, fix 4f790a6
**Tests added:** a cubit test "a closed cubit does not call the repository", and a widget test "confirming after the cubit was closed does not delete". Both were red first.
**Applied fix:** `deleteCharacter()` now returns early on `isClosed || state.isDeleting`. `_confirmDeletion` also checks `!cubit.isClosed` after the dialog resolves. The account section test stubs `isClosed` on the mock cubit.

### WR-02: Optimistic rollback in `toggle` can leave the UI diverging from storage

**Files modified:** `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit.dart`
**Commits:** test 5a4da3a, fix 3525f8f
**Test added:** two quick taps on the same category with every write failing. The final state must equal the stored value. It was red first (the state ended OFF while storage held ON).
**Applied fix:** I did not apply the review's suggestion literally. Capturing `previous` at tap time breaks in the double-fail scenario: the second tap's `previous` is the first tap's optimistic value, so the UI would end OFF again. The cubit now keeps `_persisted`, the last value known to be stored. It is filled on `load()` and updated after each successful write. On failure the cubit rolls back to `_persisted[category]`, and only if the state still holds the optimistic value (otherwise a newer tap owns the state).

### IN-01: `LogoutConfirmationDialog` is dead code

**Files modified:** `lib/shared/components/modal/logout_confirmation_dialog.dart`
**Commit:** 82a5213
**Applied fix:** A grep showed the class had no usages in `lib` or `test`. I deleted the class and kept the constants, `showLogoutConfirmationDialog` and `confirmLogout`, which are used. No new test was needed; the existing dialog tests still pass.

### IN-02: Notification default `true` is defined in three places

**Files modified:** `lib/models/notification_category.dart`, `lib/repository/storage/notification_preferences_store.dart`, `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart`, `test/helpers/fakes/in_memory_notification_preferences_store.dart`
**Commit:** 2bcfcb8
**Applied fix:** There is now a single `NotificationCategory.defaultEnabled` constant. The store, `NotificationPreferencesState.defaults` and `isEnabled`, and the in-memory test fake all reference it. The store's own `defaultEnabled` is removed. Behaviour is unchanged, so no new test; the existing suite covers it.

## Accepted / deferred (not fixed, out of scope)

- **IN-03** (unexpected errors swallowed without `addError`): deferred. It is an observability improvement, not a defect, and it changes the BlocObserver surface, so it needs a decision.
- **IN-04** (failed preferences read shows "all on"): accepted. The behaviour is deliberate under 04-CONTEXT D-12: no error UI, the switch state is the whole feedback. D-14 only requires a Flutter-free store. A comment documenting the trade-off can be added later.
- **IN-05** (formatting churn in `cloudinary_assets.dart`): accepted. It is a deliberate `style(assets)` commit of the phase.
- **IN-06** (magic numbers in layout code): deferred to a separate refactor PR. It is layout-wide, touches `profile.dart` and the satchel geometry, and is out of scope here (Boy Scout limit).
- **Pre-existing section** (`menu_item.dart`, `paper_sheet_modal.dart`, 57 repository-wide analyzer infos): not touched. These files are not part of the phase diff.

---

_Fixed: 2026-10-18_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
