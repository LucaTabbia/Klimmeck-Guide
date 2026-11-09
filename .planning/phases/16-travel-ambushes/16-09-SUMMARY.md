---
phase: 16-travel-ambushes
plan: 09
subsystem: results
tags: [flutter, dart, widget, carousel, ambush, affordance, page-view]

requires:
  - phase: 16-05
    provides: AmbushReportCarousel (swipe-only PageView of QuestResultSheet pages, «k di N»)
  - phase: 16-07
    provides: gate passed on the merged BE schema (the device E2E runs on this branch)
provides:
  - AmbushReportCarousel with peeking pages (PageController viewportFraction 0.62 with several reports, 1.0 with one)
  - one bounded opening nudge (translate 28 px out and back, 520 ms) with several reports, none with one
  - D-19 pins (8 titles) next to the 8 D-05 pins; the 16-05 «no programmatic paging» grep narrowed to page-turning calls
affects: [16-08]

tech-stack:
  added: []
  patterns:
    - "Peek by PageController(viewportFraction) only; the sheet keeps centring its 315/375 parchment in the slot"
    - "Opening hint as a one-shot TweenAnimationBuilder + Transform.translate over the PageView (clipBehavior none), never the scroll position: a scroll animation ignores pointers"

key-files:
  created: []
  modified:
    - lib/shared/components/popup/ambush_report_carousel.dart
    - test/shared/components/popup/ambush_report_carousel_test.dart
    - test/screens/mainScreen/components/quest_result_presenter_test.dart
    - .planning/phases/16-travel-ambushes/16-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "peekViewportFraction 0.62, not the planned 0.86: the sheet centres a 315/375 parchment (0.39 of the width in landscape) in its slot, so at 0.86 the neighbour parchment starts beyond the screen edge (909.6 px on a 780 px viewport) and nothing peeks; 0.62 shows about 7% of the width, the planner's intended peek"
  - "The nudge translates the pages instead of animating the scroll position: during a PageController.animateTo the Scrollable's RenderIgnorePointer swallows taps and «Continua» tapped during the nudge did nothing (observed); the translate keeps hit testing and drags alive and never changes page (D-05)"
  - "Tests pin the geometry black-box (page slot and parchment rects), not the controller offset: the same assertions hold for either nudge mechanism"

requirements-completed: []

duration: 12min
completed: 2026-11-09
---

# Phase 16 Plan 09: Carousel affordance (D-19) Summary

**The ambush carousel now reads as a carousel: with several reports each page slot takes 0.62 of the viewport so the neighbour parchment peeks in (about 7% of the width, right on page 1, left on later pages), and at opening the pages slide forward up to 28 px and back in 520 ms; one report fills the width and does not move; still swipe-only, «Continua» works at any moment.**

## Accomplishments

- `lib/shared/components/popup/ambush_report_carousel.dart`: `AmbushReportCarousel` is a `StatefulWidget`; the state owns `PageController(viewportFraction: results.length > 1 ? peekViewportFraction : 1.0)` (disposed) and passes it to the `PageView` (`clipBehavior: Clip.none`). Constants on the widget: `peekViewportFraction = 0.62`, `nudgeDistance = 28`, `nudgeOut = 240 ms`, `nudgeBack = 280 ms`. With several reports the `PageView` is wrapped in a one-shot `TweenAnimationBuilder<double>(0 → 1, nudgeOut + nudgeBack)` whose builder applies `Transform.translate(Offset(-travel, 0))`, `travel` = `TweenSequence` 0 → 28 (easeOut, weight 240) → 0 (easeIn, weight 280). Keys, children, `position`/`total`, `onContinue` unchanged; no `animateToPage`/`nextPage`/`previousPage`/`jumpToPage`.
- `test/shared/components/popup/ambush_report_carousel_test.dart`: two new groups (`affordance (D-19)`, `opening nudge (D-19)`, 6 tests) and helpers `_page`, `_parchmentOf` (first `CachedSvg` of the page = the parchment background), `_continueOf`, `_viewportWidth`, `_pumpUnsettled`; the D-05 group keeps its 7 titles with finders scoped to one page (two pages are live with the peek).
- `test/screens/mainScreen/components/quest_result_presenter_test.dart`: «Continua on page 1 closes and acks all (D-05)» taps `_continueOfPage('a1')` (descendant of the carousel page key) instead of the bare `continueKey`, which now matches two buttons.
- Bookkeeping: VALIDATION rows 16-09-01/02 `✅ green`, 16-05-01 text «no programmatic page turn (D-19 allows the controller for the peek and the nudge)», plan 9 note under the legend; ROADMAP `[x] 16-09-PLAN.md` and `| 16. Travel Ambushes | 8/9 | In Progress | - |`; STATE `Plan: 8 of 9` and the Status sentence.

## Task Commits

1. Task 1 RED — `58a33de` test(popup): pin the peeking pages of the ambush carousel (D-19)
2. Task 1 GREEN — `458bd4e` feat(popup): let the ambush carousel pages peek in from the edges
3. Task 2 RED — `92dc689` test(popup): pin the opening nudge of the ambush carousel (D-19)
4. Task 2 GREEN — `6b57b6e` feat(popup): nudge the ambush carousel once at opening
5. Task 3 — docs(phase-16): record plan 9 progress (this SUMMARY, VALIDATION, ROADMAP, STATE)

## RED failures observed

- Task 1 (`+7 -3`): «with several reports the next page peeks in from the right edge (D-19)» — `tester.getRect(_page(_lost))` threw: page 2 is not built without the peek (test line 163); «on a later page the previous one peeks in from the left edge (D-19)» — `tester.getRect(_page(_won))` threw after the swipe: page 1 is not kept alive (line 183); «every page is the result sheet with the ambush header (D-04, D-05)» — `Expected: exactly 2 matching candidates, Actual: Found 1 widget with text "Imboscata presso Andogan"` (pin updated to the two live pages). **Green at the first run:** «a single report fills the viewport and nothing peeks in (D-19)» (regression pin, the page already filled the width) and the other six D-05 titles (the scoped finders and `hitTestable()` hold without the peek too).
- Task 2 (`+12 -1`): «opening with several reports nudges forward and settles back on the first page (D-19)» — `Expected: a value greater than <0>, Actual: <0.0>` (the shift of page 1 at 120 ms). **Green at the first run:** «a single report does not move at opening (D-19)» and «Continua during the nudge still closes (D-05, D-19)» — there was no nudge yet; the second one went RED against the plan's `animateTo` implementation (see Deviations) and is green against the shipped one.

## Geometry asserted

Test viewport 780×360 logical (`useLandscapePhone`, dpr 3). `f = 0.62`, edge `(1 − f)/2 = 0.19`.

| Measure | Expected | Pixels on 780 |
|---------|----------|---------------|
| page slot width (two reports) | `0.62 w` ± 1 | 483.6 |
| page 1 slot left on page 1 | `0.19 w` ± 1 | 148.2 |
| page 2 slot left on page 1 | `0.81 w` ± 1, `< w` | 631.8 |
| page 2 parchment left on page 1 | `> w/2`, visible strip `w − left ≥ 0.05 w` | ≈ 722.4 → 57.6 px visible (7.4%) |
| page 2 slot left on page 2 | `0.19 w` ± 1 | 148.2 |
| page 1 slot right on page 2 | `0.19 w` ± 1, `> 0` | 148.2 |
| page 1 parchment right on page 2 | `< w/2`, `≥ 0.05 w` | ≈ 57.6 |
| single report slot | width `w` ± 1, left 0 ± 1 | 780 / 0 |
| nudge at 120 ms (two reports) | page 1 left shifted by `(0, 29)` px | ≈ 19 |
| after `pumpAndSettle` | page 1 left `0.19 w` ± 0.5, page 2 left `0.81 w` ± 0.5, «1 di 2» | at rest |
| single report at 120 ms and settled | left 0 ± 0.5 | 0 |

With the planned `0.86` the page 2 slot would start at 725.4 but its parchment at 725.4 + (670.8 − 302.4)/2 = 909.6 > 780: no visible peek in landscape. In general the parchment peeks only for `f < 0.5 + parchment/(2 w)` (≈ 0.69 on a 2.17:1 phone).

## SVG seeds

None added: the seed list of 16-05 already covers both pages (the swipe tests rendered page 2 before this plan).

## Gates and acceptance greps

- Task 1: `flutter test test/shared/components/popup/ambush_report_carousel_test.dart` 10/10; `flutter test test/shared/components/popup test/screens/mainScreen/components` +274 all passed (after the presenter finder fix; before it `+273 -1` «Continua on page 1 closes and acks all (D-05)» — `Too many elements` on `continueKey`).
- Task 2: carousel file 13/13; `flutter test test/shared/components/popup test/screens/mainScreen/components test/screens/mainScreen/main_screen_test.dart` +310 all passed.
- `flutter analyze 2>&1 | grep -cE '^ *(error|warning) •'` → `0` after each task (50 info-level issues, baseline).
- `dart format` one by one on `ambush_report_carousel.dart`, `ambush_report_carousel_test.dart`, `quest_result_presenter_test.dart` (0 changed each time).
- Widget greps: `peekViewportFraction` 2, `viewportFraction` 1, `StatefulWidget` 1, `PageController` 1, `nudgeDistance` 3, `TweenAnimationBuilder` 1, `animateToPage|nextPage|previousPage|jumpToPage` 0, `addPostFrameCallback` 0 and `hasClients` 0 (see Deviations 2). Test greps: `D-19)` 8 (≥ 6), `D-05)` 8 (≥ 7).
- Task 3 verify: ROADMAP `^- \[x\] 16-09-PLAN.md` 1, STATE `Plan: 8 of 9` 1, VALIDATION `^\| 16-09-0[12] .*✅ green` 2, progress row `| 16. Travel Ambushes | 8/9 | In Progress | - |` 1.
- Commit subjects 64 / 65 / 64 / 54 bytes; trailer check 0 on every commit.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `peekViewportFraction` 0.62 instead of 0.86**
- **Found during:** Task 1 (reading `quest_result_sheet.dart` before the RED test)
- **Issue:** the plan measures the page slot, but the sheet centres a parchment of `min(maxWidth, maxHeight × 315/375)` in it: in landscape the parchment is ≈ 0.39 of the width, so at 0.86 the neighbour parchment lies entirely beyond the screen (909.6 px on 780) and the user would see no peek — the slot-only assertions of the plan would have passed anyway.
- **Fix:** constant 0.62 (the neighbour shows ≈ 7% of the width, the peek the planner intended at 0.86 for a full-slot page), slot assertions at 0.19/0.81, plus parchment-level assertions (`> w/2` and `≥ 5%` visible) so the pin fails if the parchment ever stops peeking. Tunable in one constant if the device re-check asks for more or less.
- **Files modified:** `ambush_report_carousel.dart`, `ambush_report_carousel_test.dart`
- **Commit:** `58a33de`, `458bd4e`

**2. [Rule 1 - Bug] The nudge translates the pages instead of `PageController.animateTo`**
- **Found during:** Task 2 GREEN, first implemented exactly as the plan's skeleton (`addPostFrameCallback` + two `animateTo` guarded by `mounted`/`hasClients`)
- **Issue:** `flutter test` on that variant: `+12 -1`, «Continua during the nudge still closes (D-05, D-19)» `Expected: <1> Actual: <0>` with the warning that the tap offset «would not hit test on the specified widget» — the hit test stops at the Scrollable's `RenderIgnorePointer`: a `DrivenScrollActivity` ignores pointers for its whole duration, so for 520 ms after opening «Continua» (and any tap) is swallowed, against the plan's truth and T-16-25.
- **Fix:** one-shot `TweenAnimationBuilder` + `Transform.translate` over the `PageView` (`clipBehavior: Clip.none` so the neighbour strip grows into the freed edge); the scroll position is never animated, taps and drags stay alive, the page never changes. Consequence: the plan's acceptance greps `addPostFrameCallback` = 1 and `hasClients` ≥ 2 print 0 — they pinned the discarded mechanism; `nudgeDistance`, `nudgeOut`, `nudgeBack` keep the plan's names and values. The `dart:async`/`unawaited` import is not needed.
- **Files modified:** `ambush_report_carousel.dart`
- **Commit:** `6b57b6e`

**3. [Rule 3 - Blocking] D-05 finders scoped to one page (two test files)**
- **Found during:** Task 1 RED/GREEN
- **Issue:** with the peek both pages are live at open, so `find.byKey(QuestResultSheet.continueKey)` matches two buttons (`Too many elements` in the carousel tests and in `quest_result_presenter_test.dart` «Continua on page 1 closes and acks all (D-05)»), `find.byType(QuestResultSheet)` and «Imboscata presso Andogan» find two, and «Sconfitta» is in the tree (off-screen).
- **Fix:** `_continueOf(result)` / `_continueOfPage(id)` descendants of the page key; «every page is the result sheet» pins `findsNWidgets(2)`; «opens on the first report» asserts `find.text('Sconfitta').hitTestable()` finds nothing (the lost header peeks but is not readable). The presenter test file is outside the plan's `files_modified`.
- **Files modified:** `ambush_report_carousel_test.dart`, `quest_result_presenter_test.dart`
- **Commit:** `58a33de`, `458bd4e`

### Not done on purpose

- ROADMAP line of `16-09-PLAN.md` still says `PageController(viewportFraction: 0.86)`: the brief limits the ROADMAP edits to the checkbox and the Progress Table row; left for the orchestrator.
- `requirements mark-complete` not run (16-08 Task 3 owns it); `16-HUMAN-UAT.md`, `16-08-*`, `REQUIREMENTS.md` untouched.

## Known Stubs

None.

## Threat Flags

None. T-16-25 mitigated by the bounded one-shot animation (520 ms, no controller to leak, the `PageController` is disposed) and the three nudge tests; T-16-26 by the page-turn grep at 0 and the «settles back on the first page» pin.

## Self-Check: PASSED

- Files exist: the three code/test files and this SUMMARY; commits 58a33de, 458bd4e, 92dc689, 6b57b6e present in `git log`.
