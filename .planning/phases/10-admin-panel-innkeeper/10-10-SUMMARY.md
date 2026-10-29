---
phase: 10-admin-panel-innkeeper
plan: 10
subsystem: admin
tags: [admin, teleport, map, shell, panel, landing, tdd]
requires: [10-05, 10-07, 10-09]
provides:
  - TeleportModeLanding (lib/screens/mainScreen/components/teleport_mode_landing.dart) mounted in MainScreen around the PageView
  - MainScreen.onPageChanged cancels the teleport mode on any page other than the Map
  - «Teletrasporta» on every queue row (ParticipantRow.teleportLabel / teleportKeyFor) with inline progress
  - openInnkeeperPanel hands the shell TeleportModeCubit to the panel route
affects: [10-11]
tech-stack:
  added: []
  patterns: [single owner of the hand-off: the panel only calls prepare(), the shell landing pops the root routes, jumps to the Map and re-pushes the panel]
key-files:
  created:
    - lib/screens/mainScreen/components/teleport_mode_landing.dart
    - test/screens/mainScreen/components/teleport_mode_landing_test.dart
  modified:
    - lib/screens/mainScreen/main_screen.dart
    - lib/screens/innkeeper/innkeeper_panel_route.dart
    - lib/screens/innkeeper/components/participant_row.dart
    - lib/screens/innkeeper/components/request_card_view.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - test/screens/mainScreen/main_screen_test.dart
    - test/screens/mainScreen/main_screen_quest_results_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
    - test/screens/innkeeper/innkeeper_panel_route_test.dart
    - test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart
key-decisions:
  - "TeleportModeLanding is the single owner of the panel → Map → panel hand-off: the panel only calls TeleportModeCubit.prepare; no jumpToPage under lib/screens/innkeeper"
  - "The landing calls acknowledgeSuccess() before openInnkeeperPanel(context) and listens only to the transition into TeleportSucceeded (one panel per success, T-10-37)"
  - "MainScreen.onPageChanged cancels the mode for page != worldMapPageIndex; the landing's own jump to the Map fires onPageChanged(0) and never cancels (P3)"
  - "ParticipantRow name and state ellipsize (Expanded + Flexible flex 2) so the action fits; the greyed Opacity wraps only name and state"
requirements-completed: []
duration: 12min
completed: 2026-10-29
---

# Phase 10 Plan 10: Teleport hand-off Summary

The GM can now teleport a queued character end to end: «Teletrasporta» on a queue row reads the character (inline progress on that row, the other rows locked), the shell-level `TeleportModeLanding` closes the panel and jumps to the Map in teleport mode, a page change away from the Map or a lost innkeeper role cancels the mode, and after a successful drop the landing acknowledges the success and pushes the panel again (its new subscription brings a fresh snapshot). ADMIN-04 is functionally closed; its traceability is recorded by plan 10-11.

## What was built

- `TeleportModeLanding({pageController, child})` — `MultiBlocListener` with three listeners: into `TeleportActive` → `Navigator.of(context, rootNavigator: true).popUntil(isFirst)` + `jumpToPage(NotificationIntentLanding.worldMapPageIndex)` (guarded by `hasClients`); into `TeleportSucceeded` → `acknowledgeSuccess()` then `unawaited(openInnkeeperPanel(context))`; `AuthCubit` innkeeper → not innkeeper → `cancel()`.
- `MainScreen`: `NotificationIntentLanding(child: TeleportModeLanding(child: PageView(...)))`; `onPageChanged(page)` calls `context.read<TeleportModeCubit>().cancel()` when `page != worldMapPageIndex`.
- `openInnkeeperPanel` reads `TeleportModeCubit` from the caller and wraps the route in `BlocProvider<TeleportModeCubit>.value`.
- `ParticipantRow({participant, serverNow, required onTeleport, required isPreparingTeleport})`: `teleportLabel` = 'Teletrasporta', `teleportKeyFor(characterId)` → `ValueKey('innkeeper.teleport.$id')`; while preparing a `CircularProgressIndicator(strokeWidth: 2)` in a `SizedBox.square(spacingMd)`.
- `RequestCardView({..., required onTeleport, required preparingCharacterId})`: rows locked (`onTeleport: null`) while any character is being read.
- `InnkeeperPanelScreen`: `BlocSelector<TeleportModeCubit, TeleportModeState, String?>` around the list, `onTeleport` → `prepare(characterId:, name:)`, listener on `TeleportPreparationFailed` → SnackBar `teleportUnavailableMessage` = 'Impossibile aprire la mappa per il teletrasporto'.

## TDD evidence

**Task 1 RED** (`ea4f023`): `teleport_mode_landing_test.dart` failed to compile (`Error when reading 'lib/screens/mainScreen/components/teleport_mode_landing.dart': No such file or directory`, `Method not found: 'TeleportModeLanding'`); `main_screen_test.dart`: «another tab cancels the teleport mode» → `No matching calls (actually, no calls at all)`, «entering the mode from another tab lands on the map without cancelling it (P3)» → `Expected: <0> Actual: <3>`.
**Task 1 GREEN** (`c36ef2a`): `flutter test test/screens/mainScreen` → 803 passed.

**Task 2 RED** (`c4637ee`): `innkeeper_panel_screen_test.dart` failed to compile (`Member not found: 'teleportLabel'`, `Member not found: 'teleportUnavailableMessage'`); `innkeeper_panel_route_test.dart` «a row «Teletrasporta» reaches the shell teleport mode» failed (no `Teletrasporta` widget).
**Task 2 GREEN** (`2f4cde8`): `flutter test test/screens/innkeeper test/screens/mainScreen` → 941 passed.

Final: full suite 2820 tests green (2804 after 10-09, +16); `flutter analyze` 51 issues (all info), repo-wide gate exit 0.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | ea4f023 | test(admin): expect the teleport mode landing |
| 1 GREEN | c36ef2a | feat(admin): land on the map in teleport mode |
| 2 RED | c4637ee | test(admin): expect the teleport action on queue rows |
| 2 GREEN | 2f4cde8 | feat(admin): teleport a queued character from its row |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Row overflow with the new action**
- **Found during:** Task 2 GREEN
- **Issue:** with «Teletrasporta» beside them, name + «In viaggio · 12 min» overflowed the row (RenderFlex overflowed by 112 px in the landscape test harness).
- **Fix:** name in `Expanded`, state in `Flexible(flex: 2)`, both `maxLines: 1` + ellipsis; the greyed `Opacity` wraps only that block.
- **Files modified:** lib/screens/innkeeper/components/participant_row.dart
- **Commit:** 2f4cde8

**2. [Rule 3 - Blocking] RED test reached an off-screen card**
- **Found during:** Task 2 GREEN
- **Issue:** the RED test «every listed row has the action» put a worldMission card and an awaiting-aid story card in one queue; the second card sat outside the lazily-built `ListView` viewport, so its row was never built.
- **Fix:** split into «every listed row has the action» (present, travelling, arrived) and «an awaiting-aid row has the action too».
- **Files modified:** test/screens/innkeeper/innkeeper_panel_screen_test.dart
- **Commit:** 2f4cde8

### Other adjustments

- The SnackBar copy is a named constant `InnkeeperPanelScreen.teleportUnavailableMessage` (like `goneMessage`/`busyMessage`) instead of an inline literal; the row key is built by `ParticipantRow.teleportKeyFor` (same value as the plan's inline `ValueKey`).
- The existing D-08 test («a card shows only the quest, the rows and «Completa»») now also expects 'Teletrasporta' (D-19 adds the action to every row).
- The P3 rule is tested in `main_screen_test.dart` (where `onPageChanged` lives) as well as in the landing test: from page 3 the landing jump fires `onPageChanged(0)` and `cancel()` is never called.
- `main_screen_test.dart` provides `TeleportModeCubit`/`AuthCubit` in all three harness blocks; the panel test's FORBIDDEN-route block also gains the `TeleportModeCubit` provider.

## Threat surface

T-10-36 (mode survives demotion/another tab) mitigated and tested (landing lost-role test, main screen page-change tests); T-10-37 (re-push loop) mitigated: acknowledge first, transition-only listener (landing success test). No new network endpoint, document or auth path.

## Known Stubs

None.

## Self-Check: PASSED
