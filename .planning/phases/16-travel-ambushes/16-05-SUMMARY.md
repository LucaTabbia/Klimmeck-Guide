---
phase: 16-travel-ambushes
plan: 05
subsystem: results
tags: [flutter, dart, widget, presenter, quest-result, ambush, carousel]

requires:
  - phase: 16-03
    provides: QuestResultSheet ambush header and «Portato a» line, position/total counter
  - phase: 16-04
    provides: QuestResultsState.presentable / showingGroup / isSettlingAmbushes, group-wide presented/closed/dismissedExternally
provides:
  - AmbushReportCarousel (PageView of QuestResultSheet, one page per ambush, «k di N», swipe only)
  - QuestResultPresenter group presentation (carousel for an ambush head, single sheet otherwise), settling wait, no «Missione conclusa» banner for ambush arrivals
affects: [16-07, 16-08]

tech-stack:
  added: []
  patterns:
    - "One presentation = one group: a single showGeneralDialog and one pop(true) for the whole ambush run"
    - "Carousel without PageController: pages are browsed only by swiping (D-05 veto)"

key-files:
  created:
    - lib/shared/components/popup/ambush_report_carousel.dart
    - test/shared/components/popup/ambush_report_carousel_test.dart
  modified:
    - lib/screens/mainScreen/components/quest_result_presenter.dart
    - test/screens/mainScreen/components/quest_result_presenter_test.dart

key-decisions:
  - "The carousel counter is group-local (`index + 1` of `results.length`), as the plan's skeleton and tests prescribe: a batch [a1, a2, q] shows «1 di 2» on the carousel and «3 di 3» on the following quest sheet"
  - "D-05 veto implemented: «Continua» on any page calls the one onContinue → pop(true) → closed(head.id); no animateToPage / nextPage / PageController in the carousel"

requirements-completed: []

duration: 6min
completed: 2026-11-06
---

# Phase 16 Plan 05: Ambush report carousel and presenter branch Summary

**The ambush reports of an arrival open as one `AmbushReportCarousel` (a swipe-only `PageView` of result sheets) inside the existing transparent dialog, after the batch has settled, without a «Missione conclusa» banner, and «Continua» on any page closes and acknowledges the whole group.**

## Accomplishments

- `lib/shared/components/popup/ambush_report_carousel.dart`: `class AmbushReportCarousel extends StatelessWidget`, `const AmbushReportCarousel({super.key, required List<QuestResult> results, required VoidCallback onContinue})`, `static const Key pagesKey = ValueKey('ambushReportCarousel.pages')`. Builds `PageView(key: pagesKey, children: [QuestResultSheet(key: ValueKey('ambushReportCarousel.page.<id>'), result, position: index + 1, total: results.length, onContinue)])`. No `PageController`: the D-05 veto is implemented (no `animateToPage`, no `nextPage`); a single ambush has `total == 1`, so no counter.
- `quest_result_presenter.dart`:
  - `_announceArrival`: `if (arrival.isAmbush) return;` right after `_handledArrival = state.arrivalSerial;` (no publish, no suppress for ambushes, D-06). `_announceNotice` untouched.
  - `_canPresent()`: `_isShowingSheet || state.presentable.isEmpty || state.isSettlingAmbushes` → false (D-12).
  - `_tryPresent()` → `_present(_results.state.presentable)`; `_present(List<QuestResult> group)` takes `head = group.first`, calls `presented(head.id)`, opens the same `showGeneralDialog<bool>` with `PopScope(canPop: false, child: head.isAmbush ? _AmbushReportRoute(results: group) : _QuestResultRoute(...))`, then `closed(head.id)` on `pop(true)` or `dismissedExternally(head.id)` otherwise.
  - New private `_AmbushReportRoute({required List<QuestResult> results})`: `Material(transparency) → AmbushReportCarousel(onContinue: () => Navigator.of(context).pop(true))`. `_QuestResultRoute` (death path) unchanged. No read of `NotificationPreferences` / `ambushDefeat` (D-10).

## Task Commits

1. Task 1 RED — `7dc1b4f` test(results): expect the ambush report carousel
2. Task 1 GREEN — `d05e516` feat(results): add the ambush report carousel
3. Task 2 RED — `2cac446` test(results): expect the presenter to open ambush carousels
4. Task 2 GREEN — `ffb1ef2` feat(results): present ambush reports in one carousel

## Tests added

- `test/shared/components/popup/ambush_report_carousel_test.dart`: group `'AmbushReportCarousel (D-05)'`, 7 tests with the plan's titles; file-level `_won`/`_lost` (default `ambushWon/LostResultJson()`), `_pump(tester, results, {onContinue})` (landscape + `buildTestApp` + `pumpAndSettle`), `_swipe(tester, dx)` (`fling` on `pagesKey`, velocity 1000). `setUp` seeds `emptySheet, emptyCardSheet, healEffect, helmetType, goldCoin, silverCoin, copperCoin`.
- `quest_result_presenter_test.dart`: file-level `_won(id)` (resolvedAt 11:20) and `_lost(id)` (11:40), `final Finder _carousel = find.byType(AmbushReportCarousel)`; group `'QuestResultPresenter ambush carousel (D-05, D-06, D-12)'`, 9 tests with the plan's titles (last group of the file).

## RED failures observed

- Task 1: compilation failure, the import `ambush_report_carousel.dart` does not exist (whole file failed to load).
- Task 2: 8 of 9 new tests failed (`AmbushReportCarousel` not found because the single sheet opened; the off-map arrival published the questEnd banner; the free-map arrival suppressed `questEnd|a1`; the live-batch, travel-flow, external-pop and toggle tests found a single sheet instead of the carousel). **Green at the first run:** «Continua on page 1 closes and acks all (D-05)» — the 16-04 cubit already moves the whole ambush run into `showingGroup` on `presented` and acknowledges it on `closed`, so the old single-sheet presenter popping `true` already acked `['a1', 'a2']` and the next quest sheet showed «3 di 3». The test still pins the group acknowledgement through the carousel.

## Gates

- `flutter test test/shared/components/popup`: +125 all passed (Task 1).
- `flutter test test/screens/mainScreen/components test/screens/mainScreen/questResultsCubit test/screens/mainScreen/main_screen_test.dart test/shared/components/popup`: +388 all passed (Task 2).
- Plan verification `flutter test test/screens/mainScreen test/shared/components/popup`: +1105 all passed.
- `flutter analyze`: 0 error, 0 warning (baseline infos only).
- `dart format` run one by one on the four touched files.
- Acceptance greps: carousel `class AmbushReportCarousel` 1, `PageView(` 1, `QuestResultSheet(` 1, `animateToPage|nextPage|PageController` 0, `D-05)` 8, `emptyCardSheet` 1; presenter `AmbushReportCarousel(` 1, `isSettlingAmbushes` 1, `if (arrival.isAmbush) return;` 1, `state.presentable` 2, `ambushDefeat` 0; presenter test `D-(05|06|10|12))` 9. Trailer check 0 on every commit.
- The hit-test warning printed by `flutter test test/shared/components/popup` comes from the pre-existing «dismissal tapping anywhere else calls nothing» sheet test, not from the carousel tests.

## Deviations from Plan

None - plan executed exactly as written. (The D-06 comment added in `_announceArrival` was wrapped over two lines to stay within 80 columns; the doc comment of `_canPresent` likewise.)

## Known Stubs

None.

## Threat Flags

None (T-16-13 mitigated by «waits for the travel flow» / «waits for the settling read»; T-16-14 by «publishes no quest-end banner off the map»; T-16-12 accepted per the user veto).

## Self-Check: PASSED

- Files exist: `lib/shared/components/popup/ambush_report_carousel.dart`, `test/shared/components/popup/ambush_report_carousel_test.dart`; commits 7dc1b4f, d05e516, 2cac446, ffb1ef2 present in `git log`.
