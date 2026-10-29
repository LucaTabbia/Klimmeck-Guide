---
phase: 10-admin-panel-innkeeper
plan: 05
subsystem: admin-panel
tags: [admin, innkeeper, settings, root-route, widget, tdd]
requires: [10-01, 10-02, 10-03]
provides:
  - presenceLabelOf (lib/screens/innkeeper/components/presence_label.dart)
  - ParticipantRow + ParticipantRow.keyFor (lib/screens/innkeeper/components/participant_row.dart)
  - RequestCardView + RequestCardView.keyFor + busyParticipantNote (lib/screens/innkeeper/components/request_card_view.dart)
  - InnkeeperPanelScreen (title, emptyTitle, emptyNote, unavailableMessage)
  - isInnkeeperSession (lib/screens/innkeeper/innkeeper_access.dart)
  - openInnkeeperPanel + closeInnkeeperPanel (lib/screens/innkeeper/innkeeper_panel_route.dart)
  - RepositoryProvider<InnkeeperRepository> in AuthenticatedShell (lazy)
  - KlimmeckGuideTheme.primaryButtonStyle
  - InnkeeperSection (Settings, between Notifiche and Account)
affects: [10-07, 10-10]
tech-stack:
  added: []
  patterns: [root route fed with .value from the caller's shell context, route-scoped cubit started in create, MultiBlocListener self-close on FORBIDDEN / lost role, BlocSelector role gate]
key-files:
  created:
    - lib/screens/innkeeper/components/presence_label.dart
    - lib/screens/innkeeper/components/participant_row.dart
    - lib/screens/innkeeper/components/request_card_view.dart
    - lib/screens/innkeeper/innkeeper_panel_screen.dart
    - lib/screens/innkeeper/innkeeper_access.dart
    - lib/screens/innkeeper/innkeeper_panel_route.dart
    - lib/screens/mainScreen/tabs/settings/components/innkeeper_section.dart
    - test/screens/innkeeper/components/presence_label_test.dart
    - test/screens/innkeeper/innkeeper_panel_screen_test.dart
    - test/screens/innkeeper/innkeeper_panel_route_test.dart
    - test/screens/mainScreen/tabs/settings/components/innkeeper_section_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/tabs/settings/settings.dart
    - lib/theme/kg_theme.dart
    - test/screens/mainScreen/tabs/settings/settings_test.dart
key-decisions:
  - "The FORBIDDEN close captures the root ScaffoldMessenger before closeInnkeeperPanel, so the SnackBar lands on the screen beneath (default per veto, D-04/C8)"
  - "The lost-role close is silent and fires only on an innkeeper -> non-innkeeper transition (isInnkeeperSession(previous) && !isInnkeeperSession(current))"
  - "InnkeeperSection carries its own bottom spacing (spacingXl), so a non-innkeeper Settings layout is pixel-identical to before"
  - "InnkeeperRepository is a lazy shell provider: only an innkeeper opening the panel creates it"
requirements-completed: []
duration: 25min
completed: 2026-10-29
---

# Phase 10 Plan 05: Innkeeper panel, root route and Settings section Summary

Role-gated «Locanda» section in Settings opening a root-Navigator utility route (`openInnkeeperPanel`) whose route-scoped `PendingRequestsCubit` renders the live queue as per-quest cards with greyed travellers and hidden busy participants, closing itself on `FORBIDDEN` (SnackBar, veto default) or a lost role (silent).

## Tasks

| Task | Name | RED | GREEN |
| ---- | ---- | --- | ----- |
| 1 | Panel screen content (loader, empty state, cards, rows) | 52eadd7 | 2f58d05 (+ b095bec fix) |
| 2 | Root route, shell provider, FORBIDDEN / lost-role close | 87436ab | 73979cf |
| 3 | Role-gated «Locanda» section in Settings | 068d092 | e7ccbf9 |

## RED evidence

- Task 1: compile failure — `Error when reading 'lib/screens/innkeeper/components/presence_label.dart': No such file or directory`, `Method not found: 'presenceLabelOf'`.
- Task 2: compile failure — `Error when reading 'lib/screens/innkeeper/innkeeper_access.dart'` / `innkeeper_panel_route.dart`, `Method not found: 'isInnkeeperSession'`, `'openInnkeeperPanel'`.
- Task 3: compile failure of `innkeeper_section_test.dart` (`Method not found: 'InnkeeperSection'`) and `settings_test.dart` «an innkeeper sees «Locanda» between Notifiche and Account» failing (`[E]`); all pre-existing Settings tests stayed green with the `AuthCubit` stubbed as adventurer.

## Verification

- `presence_label_test.dart` 5/5, `innkeeper_panel_screen_test.dart` 10/10, `innkeeper_panel_route_test.dart` 7/7, `innkeeper_section_test.dart` 5/5, `settings_test.dart` 8/8 (2 new).
- `flutter test test/screens/innkeeper test/screens/auth/authenticated_shell_test.dart`: 74 green; `flutter test test/screens/mainScreen/tabs/settings test/screens/innkeeper`: 121 green.
- Full suite: 2681 tests green (2627 after 10-03, plus 10-04 and this plan).
- Analyzer gate (repo-wide): 51 issues, all `info`, gate exit 0.
- Acceptance greps: no `Color(0x` / `TextStyle(` / `twitchId` / `pointsSpent` under `lib/screens/innkeeper`; «default per veto» in `request_card_view.dart` (1) and `innkeeper_panel_screen.dart` (1); `rootNavigator: true` = 1; `RepositoryProvider<InnkeeperRepository>` = 1 in the shell; `primaryButtonStyle` = 1 in the theme; `InnkeeperSection()` = 1 in Settings; satchel files unchanged vs `develop`; every touched file is `dart format`-clean (all touched existing files were clean before editing).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Unused import committed in the Task 1 GREEN commit**
- **Found during:** Task 1 (analyzer check right after the commit)
- **Issue:** `request_card_view.dart` imported `quest_type.dart` but `QuestType.label` resolves without it (analyzer `warning • unused_import`).
- **Fix:** import removed in a separate commit (history is never rewritten).
- **Commit:** b095bec `fix(admin): drop an unused import from the request card`

**2. [Rule 3 - Blocking] Live-role section test needed `pumpAndSettle`**
- **Found during:** Task 3 GREEN
- **Issue:** with a broadcast `StreamController` behind `whenListen`, the second role emission was not rebuilt after a single `pump()` (the event is delivered after the frame); the RED test used `pump()`.
- **Fix:** both role transitions in «the section follows the session role live» use `pumpAndSettle()`; assertions unchanged. Included in the GREEN commit e7ccbf9; three repeated runs green.

**3. Test harness detail** — the null-role cases build `User(role: null)` directly through a local `_sessionAs(RoleType?)` helper, because `buildTestUser({RoleType role})` cannot express a null role.

## Known Stubs

None. `KGLoader` is the existing project loader (renders a placeholder text today); it is shown only until the first snapshot, as the plan requires.

## Threat Flags

None beyond the plan's threat model (T-10-18..T-10-21 covered: UX-only gate with BE `FORBIDDEN` pop, route-scoped subscription closed on pop — tested, cards show name + state only — D-08 test).

## Self-Check: PASSED

- All created files exist; commits 52eadd7, 2f58d05, b095bec, 87436ab, 73979cf, 068d092, e7ccbf9 are in `git log`.
