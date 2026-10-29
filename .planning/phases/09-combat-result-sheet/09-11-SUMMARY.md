---
phase: 09-combat-result-sheet
plan: 11
subsystem: app wiring
tags: [flutter, cubit, combat, quest-result, shell, notifications, main-screen]

# Dependency graph
requires:
  - phase: 09-03
    provides: "`QuestResultRepository`, null-object ports `NoPendingQuestResults` / `NoQuestResultAcknowledger`, `MockQuestResultRepository`"
  - phase: 09-05
    provides: "`ConnectionRestoredEvents` from `SessionSyncScope`"
  - phase: 09-06
    provides: "`QuestResultsCubit` (`start()`, `requestFromTap`) + fakes"
  - phase: 09-08
    provides: "`CharacterUnavailable` (MainScreen stays on its loader)"
  - phase: 09-09
    provides: "`MapAvailabilityCubit` in the shell"
  - phase: 09-10
    provides: "`QuestResultPresenter`"
provides:
  - "`AuthenticatedShell` provides `QuestResultsCubit` (`lazy: false`, `..start()`) with the null-object 9.2 ports"
  - "`defaultNotificationPopups[NotificationCategory.questEnd] = requestQuestResult` → `QuestResultsCubit.requestFromTap(intent.id)`"
  - "`MainScreen.build` returns `QuestResultPresenter(child: _buildScreen(context))` (loader included)"
  - "`MockQuestResultsCubit` in `test/helpers/mocks.dart`"
  - "End-to-end widget test `test/screens/mainScreen/main_screen_quest_results_test.dart`"
affects: [09-12, 09-13]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "MainScreen end-to-end harness: real `QuestResultsCubit` (lazy, started before `pumpWidget` like the shell) + real `MapAvailabilityCubit` + real `NotificationIntentCubit`; `MainScreenCubit` mock fed by a broadcast controller to move from loader to pages; `pagesBuilder` stubs; seeds = satchel entries + pouch + the 7 sheet SVGs"

key-files:
  created:
    - test/screens/mainScreen/main_screen_quest_results_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/components/notification_popup_registry.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/mainScreen/components/notification_intent_landing_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/helpers/mocks.dart

key-decisions:
  - "The presenter wraps the whole `MainScreen` tree through an extracted `_buildScreen(context)` (the former body of `build`), instead of re-indenting the 100-line builder inline: same tree, smaller diff"
  - "No routing hold (D-13 wins over RESEARCH): the death sheet opens over the cold-start loader of a `CharacterUnavailable` character; the creation page arrives only via the user refresh after the acknowledgement"

patterns-established:
  - "Any test that mounts `MainScreen` must provide `TravelCubit` (BlocListener in the presenter), `QuestResultsCubit`, `NotificationPreferencesCubit` and `InAppNotificationsCubit` in addition to the previous set"

requirements-completed: []

# Metrics
duration: 25min
completed: 2026-10-28
---

# Phase 9 Plan 11: App Wiring of the Quest Result Delivery Summary

**The shell now starts `QuestResultsCubit` for the whole character session (subscription + resume/reconnect refetch, 9.2 ports still null objects), a `questEnd` tap lands on the Map and feeds `requestFromTap(intent.id)`, and `MainScreen` wraps its whole tree — cold-start loader included — in `QuestResultPresenter`, proven end to end: pending result on the Map, live result off the Map (banner, then sheet on return), death sheet over the loader of a `CharacterUnavailable` character.**

## Performance

- **Duration:** ~25 min
- **Completed:** 2026-10-28
- **Tasks:** 2 (4 commits)
- **Files:** 8 (3 lib, 5 test)

## Accomplishments

- `AuthenticatedShell` (D-09, C4): `BlocProvider<QuestResultsCubit>(lazy: false, create: … QuestResultsCubit(characterId, repository: QuestResultRepository(graphQl: graphQl), pending: const NoPendingQuestResults(), acknowledger: const NoQuestResultAcknowledger(), lifecycle/connectionRestored/userRefresh from context)..start())`, right after `MapAvailabilityCubit`; closed with the keyed shell (T-9-40).
- `notification_popup_registry.dart` (D-06, D-11): `questEnd: requestQuestResult`; the popup forwards only `intent.id` (already filtered upstream, re-filtered by `validBackendIdentifier` in the cubit) — T-9-39.
- `MainScreen` (D-06, D-07, D-13 b): `build` → `QuestResultPresenter(child: _buildScreen(context))`, so the presenter also covers the loader and the error screen.

## Task Commits

1. **Task 1 RED** — `510bf45` test(combat): expect the quest results cubit in the shell
2. **Task 1 GREEN** — `a32cf3b` feat(combat): start the quest result delivery with the shell
3. **Task 2 RED** — `f761d14` test(combat): expect result sheets in the main screen
4. **Task 2 GREEN** — `dbad990` feat(combat): mount the quest result presenter

## TDD Evidence

- Task 1 RED (`flutter test test/screens/auth …/notification_intent_landing_test.dart`): 3 failures
  ```
  Error: Could not find the correct Provider<QuestResultsCubit> above this BlocBuilder<SplashCubit, …   (shell test)
  a questEnd tap lands on the map and asks the queue for it [E]                                         (no popup)
  Expected: Set:[travelEnd, questEnd]  Actual: Set:[NotificationCategory.travelEnd]                   (registry)
  ```
- Task 2 RED (`flutter test …/main_screen_quest_results_test.dart …/main_screen_test.dart`): the 3 new tests fail, the 19 existing MainScreen tests stay green with the extended harness
  ```
  Expected: exactly one matching candidate
    Actual: _TypeWidgetFinder:<Found 0 widgets with type "QuestResultSheet": []>   (pending / death)
  No matching calls (actually, no calls at all).                                    (live: publish)
  ```

## Verification

- `flutter test test/screens/auth test/screens/mainScreen/components/notification_intent_landing_test.dart` — green (166)
- `flutter test test/screens/mainScreen/main_screen_quest_results_test.dart test/screens/mainScreen/main_screen_test.dart` — green (22)
- Full suite: 2427 → **2432** tests, all passed (+1 shell, +1 landing, +3 end-to-end; the registry test was renamed)
- `flutter analyze`: **52 issues** (baseline 53), 0 errors
- `dart format --set-exit-if-changed` clean on all 8 files (all were formatter-clean before editing); acceptance greps: `QuestResultsCubit(` = 1, `NoPendingQuestResults()` = 1 (shell); `NotificationCategory.questEnd` = 1, `requestFromTap(` = 1 (registry); `Phase 7 registers only the travelEnd popup` = 0; `QuestResultPresenter(` = 1 (main_screen); `CharacterUnavailable` = 1 (e2e test)
- `lib/graphql/` untouched (registry stays 36); no REQUIREMENTS.md change

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `TravelCubit` and `InAppNotificationsCubit` added to the first MainScreen test**
- **Found during:** Task 2 RED
- **Issue:** `loads exactly the character of the session` provided only Character/Quest/MainScreen/MapAvailability; the presenter's `BlocListener<TravelCubit, …>` needs a provider.
- **Fix:** harness-only — mock `TravelCubit` (`TravelIdle`), `MockInAppNotificationsCubit`, plus the plan's `MockQuestResultsCubit` / `MockNotificationPreferencesCubit`. No production change. **Commit:** `f761d14`

**2. [Boy Scout] Shell class doc**
- The `SyncHealth`/`UserRefreshRequests` paragraph now also names `ConnectionRestoredEvents` and was re-wrapped to 80 columns. **Commit:** `a32cf3b`

**3. Mount through `_buildScreen`**
- The plan said "wrap the whole tree returned by `build`"; done by moving the former body into `_buildScreen(context)` and returning `QuestResultPresenter(child: _buildScreen(context))` — identical tree, no re-indentation of the builder. **Commit:** `dbad990`

**Total deviations:** 3 (none on scope).

## Known Stubs

- `lib/screens/auth/authenticated_shell.dart:192-193` — `pending: const NoPendingQuestResults()`, `acknowledger: const NoQuestResultAcknowledger()`: intentional until the BE 9.2 PR is merged; plan 09-12 (gated) swaps both for the `QuestResultRepository`. Until then results arrive only via the subscription and the tap, and nothing is acknowledged.

## Threat Flags

None — the new surfaces are T-9-39 (tap → `requestFromTap`, landing test), T-9-40 (subscription closed with the shell, shell test) and T-9-41 (death over the loader, end-to-end test).

## Self-Check: PASSED

- FOUND: test/screens/mainScreen/main_screen_quest_results_test.dart
- FOUND: lib/screens/auth/authenticated_shell.dart, lib/screens/mainScreen/components/notification_popup_registry.dart, lib/screens/mainScreen/main_screen.dart
- FOUND commits: 510bf45, a32cf3b, f761d14, dbad990
