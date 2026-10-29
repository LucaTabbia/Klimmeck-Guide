---
phase: 09-combat-result-sheet
plan: 07
subsystem: ui
tags: [flutter, widget, parchment, animation, combat, quest-result, theme]

# Dependency graph
requires:
  - phase: 09-01
    provides: "`QuestResult` family, `QuestOutcome.label`, `QuestType.label`, quest result fixtures"
  - phase: 06-quest-accept-info-sheets
    provides: "`QuestInfoSheet` parchment language (`emptySheet`, aspect 315/375, padding fractions, enemy `Image.asset` path)"
provides:
  - "`QuestResultSheet` — pure parchment widget for the five outcomes (D-01..D-05, D-14)"
  - "`HpDeltaBar` — token-based life bar + «hp / max» value with loss/gain/neutral ink"
  - "`KlimmeckGuideTheme.healGreen` token (provisional, D-19)"
affects: [09-10, 09-11]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Skippable implicit animation: tap flips `_isSkipped`, the `TweenAnimationBuilder` is rebuilt under `ValueKey<bool>(_isSkipped)` with `begin == end`, so it paints the final value on its first frame and starts no ticker"
    - "Sections as `List<Widget>` builders that return `const []` when they have no data (D-04)"

key-files:
  created:
    - lib/shared/components/hp_delta_bar.dart
    - lib/shared/components/popup/quest_result_sheet.dart
    - test/shared/components/hp_delta_bar_test.dart
    - test/shared/components/popup/quest_result_sheet_test.dart
  modified:
    - lib/theme/kg_theme.dart
    - test/theme/kg_theme_test.dart

key-decisions:
  - "The parchment fits the available height (LayoutBuilder) instead of screen height × 1.5, with the scrollable content above a fixed footer (counter, ack error, button): the single dismissal button is always on screen in landscape"
  - "Tap on the HP block skips the animation (D-02 «Claude's call»); the button is enabled from the first frame"
  - "Outcome inks: success/gmCompleted darkBronze, failure royalCrimson, rescued mysticBlue, death deepNight; button darkWood (deepNight on death)"

patterns-established:
  - "QuestResultSheet keys (`questResult.*`) for presenter tests"

requirements-completed: []

# Metrics
duration: 15min
completed: 2026-10-28
---

# Phase 9 Plan 07: Quest Result Sheet Summary

**Pure, token-based `QuestResultSheet` on the `emptySheet` parchment for all five outcomes, with an animated, tap-to-skip `HpDeltaBar`, the D-03 sections built only when they have data, the death identity and acknowledgement states, a «k di N» counter and one explicit button; plus the new `healGreen` ink.**

## Performance

- **Duration:** ~15 min
- **Completed:** 2026-10-28
- **Tasks:** 2 (4 commits, TDD)
- **Files modified:** 6 (4 created, 2 edited)

## Accomplishments

- `KlimmeckGuideTheme.healGreen = Color(0xFF2E6B30)` next to `bloodRed` (research F7).
- `HpDeltaBar(hp, max, isLoss, isGain)`: parchment track with `darkWood` border and `radius`, `FractionallySizedBox` fill (`max <= 0` → 0, clamped `0..1`), `'${hp.round()} / $max'`; ink `bloodRed` / `healGreen` / `darkWood` (T-9-20).
- `QuestResultSheet`: header (outcome label in the outcome ink, quest title, `QuestType.label` only when known, `resolvedAt.toLocal()` as `dd/MM HH:mm`), death identity (name only when given, `Titolo · Livello n`), enemy (Phase 6 `Image.asset` + `errorBuilder`, then the name), HP block (not on rescued/death), Ferite (`InjuryTypeExtension.label`), Consumabili usati (`ItemRow`), Magie usate («Magia sconosciuta» for a null spell), Ricompense (`CoinsDisplay` row when coins > 0 + `ItemRow`), XP / level / title / spell learned / rescued count lines only when meaningful; footer with counter, ack error, button.
- Pure widget: no `flutter_bloc`, no route, no `Dismissible`, no AppBar, no barrier handler (T-9-21, T-9-22).

## Task Commits

1. **Task 1 RED: expect the life bar of the result sheet** - `f064a37` (test)
2. **Task 1 GREEN: add the life bar and the heal ink** - `d0d240a` (feat)
3. **Task 2 RED: expect the quest result sheet per outcome** - `85325e4` (test)
4. **Task 2 GREEN: add the quest result sheet** - `0bbb3c2` (feat)

## TDD evidence

- Task 1 RED: `test/theme/kg_theme_test.dart:155:31: Error: Member not found: 'healGreen'.` (and the missing `hp_delta_bar.dart` import).
- Task 2 RED: `quest_result_sheet_test.dart:9:8: Error: Error when reading 'lib/shared/components/popup/quest_result_sheet.dart': No such file or directory`; `Error: Method not found: 'QuestResultSheet'.`
- Task 2 first GREEN run: 22/23 — the skip test found `hasRunningAnimations == true` after the skip; the running tickers were the `AnimatedPencilText` quantities (400 ms) of the item cards, not the HP tween. Fixed in the test (see deviations).

## Verification

- `flutter test test/theme test/shared/components/hp_delta_bar_test.dart`: green.
- `flutter test test/shared/components/popup`: green (23 new sheet tests).
- Full suite: 2293 → 2323 green (+30).
- `flutter analyze`: 52 issues (baseline 53), 0 errors; the new files analyze clean.
- `dart format --set-exit-if-changed` clean on all six files (`kg_theme.dart` and `kg_theme_test.dart` were clean before the edit).
- Acceptance greps: `healGreen` = 1, `class HpDeltaBar` = 1, `Color(0x` in hp_delta_bar = 0, `class QuestResultSheet` = 1, `TweenAnimationBuilder<double>` = 1, `Magia sconosciuta` = 1, `Riposa in pace` = 1, `AppBar|Dismissible|Color\(0x|TextStyle\(` = 0, `flutter_bloc` = 0.

## Public API (for plan 09-10)

- `QuestResultSheet({required QuestResult result, required VoidCallback onContinue, String? characterName, int position = 1, int total = 1, bool isAcknowledging = false, bool hasAcknowledgeFailed = false})`
- Keys: `headerKey`, `questTypeKey`, `deadNameKey`, `enemyKey`, `hpKey`, `injuriesKey`, `consumablesKey`, `spellsKey`, `rewardsKey`, `xpKey`, `levelKey`, `titleKey`, `spellLearnedKey`, `rescuedKey`, `counterKey`, `continueKey`, `acknowledgeErrorKey` (all `ValueKey('questResult.<name>')`); `hpAnimationDuration = 1200 ms`.
- Button (`continueKey`, `TextButton`): «Continua», «Riposa in pace» on death; `onPressed: isAcknowledging ? null : onContinue`.
- `HpDeltaBar({required double hp, required int max, bool isLoss = false, bool isGain = false})`, keys `HpDeltaBar.barKey`, `HpDeltaBar.valueKey`.
- The sheet sizes itself to the incoming height constraint (centered, width = height × 315/375 clamped to the width): mount it in a bounded box (dialog/`Scaffold` body).

## Decisions Made

See `key-decisions` in the frontmatter.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Parchment sized to the available height instead of screen height × 1.5**
- **Found during:** Task 2 GREEN
- **Issue:** the `QuestInfoSheet` sizing (screen height × 1.5) relies on a scrolling parent; a full-screen sheet with a bottom button would push the only dismissal off screen in landscape (360 dp).
- **Fix:** `LayoutBuilder` → sheet height = available height, width = height × 315/375 clamped; content in a `SingleChildScrollView`, footer (counter, ack error, button) fixed below it. Same padding fractions and `emptySheet` asset.
- **Files modified:** lib/shared/components/popup/quest_result_sheet.dart
- **Commit:** 0bbb3c2

**2. [Rule 1 - Bug] Skip test isolated from the item cards' own animation**
- **Found during:** Task 2 GREEN
- **Issue:** `hasRunningAnimations` was true after the skip because `ItemRow` cards run a 400 ms `AnimatedPencilText` on mount.
- **Fix:** the skip test uses `questResultJson(consumablesUsed: [], rewardItems: [])`; the assertions (tap at 100 ms, one `pump()`, exactly `640 / 1200`, no running animation, second tap no-op) are unchanged. Committed with the GREEN, noted in the commit body.
- **Files modified:** test/shared/components/popup/quest_result_sheet_test.dart
- **Commit:** 0bbb3c2

### Additions (no behaviour change to the plan's contract)

- Two extra keys, `questTypeKey` and `deadNameKey`, used by the «no type line» and «no name line» tests.
- A death with an unknown `titleAfter` reads `Livello n` instead of ` · Livello n`.
- Extra tests: resolvedAt format, header ink on success and death, ack failure keeps the button enabled, fling/scrim-area taps do not dismiss.

## Known Stubs

None. Copy and inks are provisional by design (D-19).

## Self-Check: PASSED
