---
phase: 22-companion-defeat-rest-and-recovery
plan: 12
subsystem: shared / shop / quests / journal
tags: [companion, name, parchment, keyboard, switch]
requires: ["22-11"]
provides: ["CompanionNameSheet", "showCompanionNameSheet", "name prompts after purchase and prize", "Journal rename action"]
affects: ["22-16 (flips companionCareEnabled)", "22-17 (device E2E of the name prompt)"]
tech-stack:
  added: []
  patterns: ["root modal sheet padded by viewInsets", "entry points take isCompanionNamingEnabled = companionCareEnabled"]
key-files:
  created:
    - lib/shared/components/popup/companion_name_sheet.dart
    - test/shared/components/popup/companion_name_sheet_test.dart
    - .planning/phases/22-companion-defeat-rest-and-recovery/deferred-items.md
  modified:
    - lib/screens/mainScreen/tabs/shop/shop.dart
    - lib/screens/mainScreen/components/quest_result_presenter.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - test/screens/mainScreen/tabs/shop/shop_test.dart
    - test/screens/mainScreen/components/quest_result_presenter_test.dart
    - test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart
    - test/helpers/journal_harness.dart
decisions:
  - "Name sheet is its own content-high parchment (bottomEmptySheet behind a SingleChildScrollView), not PaperSheetModal: its DraggableScrollableSheet would sit at half of the height left by the keyboard and hide the field (Pitfall 6)"
  - "Shop takes the bought companions when signing (_petsInFlight), not from _toBuy at TransactionDone: characterUpdated can arrive first and prune them from the basket"
  - "QuestResultPresenter keeps _isPresenting true while the prize name prompt is open, so the next sheet waits for it"
metrics:
  duration: ~40 min
  completed: 2026-11-14
---

# Phase 22 Plan 12: Companion name prompt and its entry points Summary

A parchment name prompt (`showCompanionNameSheet`) with the character's form rules, the inline refusal, retry and skip, keyboard-safe in landscape, opened after a purchase (one per companion, in turn), after a result with a prize companion (before the next sheet) and from «Dai un nome» / «Cambia nome» in the Journal details. All three entry points sit behind `companionCareEnabled` (still off).

## Tasks

| Task | Commits | Result |
|------|---------|--------|
| 1 Name sheet | 7ea297e1 test(shared): expect the companion name prompt · c4414abf feat(shared): add the companion name prompt | 12 tests green |
| 2 Entry points | c4d53bed test(shop): expect the companion name prompts · 4c0167ac feat(shop): ask a name for new companions | shop +4, presenter +6, journal +2 net |
| 3 Bookkeeping | docs(phase-22): record plan 12 progress | — |

### RED failures
- Task 1: `companion_name_sheet_test.dart` did not compile (`Undefined name 'CompanionNameSheet'`, `showCompanionNameSheet`).
- Task 2: the three files did not compile (`No named parameter with the name 'isCompanionNamingEnabled'` on `Shop`, `QuestResultPresenter`, `Journal` via `journal_harness.dart`).
- Cases that pass by absence once compiling (no prompt for ambush / named / other character / switch off / no `rewards.pet`, items-only purchase): they guard the conditions of the new entry points (T-22-38, T-22-39) and were RED only through compilation.

## What was built
- `lib/shared/components/popup/companion_name_sheet.dart`
  - `Future<void> showCompanionNameSheet(BuildContext context, {required String characterId, required String petId, required String species, String? initialName})`: calls `CompanionNameCubit.reset()`, then `showModalBottomSheet(useRootNavigator: true, isScrollControlled: true, enableDrag: false, elevation: 0, transparent)` with the cubit by `.value`.
  - `CompanionNameSheet` (keys `fieldKey`, `errorKey`, `refusalKey`, `confirmKey`, `skipKey`): `BlocConsumer` pops on `CompanionNameSaved` for its pet; `PopScope(canPop: state is! Submitting)`; `Padding(bottom: MediaQuery.viewInsetsOf(context).bottom)`; parchment = Stack[bottomEmptySheet cover, Padding(h width/7, v 4) > SingleChildScrollView > Column[Row[title (AutoSizeText 2 lines), TextField 250 wide «Nome» (themed, autofocus, words capitalisation, done → confirm)], error line, refusal line, Row[«Più tardi», «Chiamalo così»]]]. Editing after a refusal calls `reset()`. No Scaffold / AppBar / dialog.
- `Shop({required cities, isCompanionNamingEnabled = companionCareEnabled})`: `_onConfirm` stores `_petsInFlight = _toBuy.pets`; `TransactionDone` → `_askNamesAfterFrame(bought)` → post-frame `_askNames` awaits one sheet per pet while mounted with the loaded character's id; `TransactionError` clears `_petsInFlight`.
- `QuestResultPresenter({required child, isCompanionNamingEnabled = companionCareEnabled})`: after `_results.closed(head.id)` awaits `_askPrizeName(head)` (enabled, not ambush, `rewards.pet` non-null, `head.characterId == _lastLoadedCharacter.id`, owned entry absent or unnamed); `_isPresenting` stays true until it closes, then the post-frame `_tryPresent`.
- `Journal({isCompanionNamingEnabled = companionCareEnabled})`: `_buildCompanionSheet` passes `onRename: _renameActionOf(character, owned)` (null when off; never gated by `isOnMission`).

## Keyboard test numbers (Pitfall 6)
Surface 780x360 logical (2340x1080 at 3.0); keyboard `FakeViewPadding(bottom: 900)` physical = 300 logical (the plan's `bottom: 300` would be 100 logical at dpr 3). Field rect bottom must be <= 60: first run 62.5 (field 54.5 tall + 8 px top padding) → top padding reduced to `spacingXs` (4) → 58.5, no exception.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Name sheet without PaperSheetModal**
- **Found during:** Task 1
- **Issue:** `PaperSheetModal`'s `DraggableScrollableSheet` (initialChildSize 0.5) would take half of the 60 px left above a 300 px keyboard: the field ends ~80 px down, under the keyboard.
- **Fix:** own content-high parchment (same `bottomEmptySheet` art, horizontal padding width/7) inside the padded root sheet; title and field on one row so the field is the first thing in view.
- **Files:** lib/shared/components/popup/companion_name_sheet.dart · **Commit:** c4414abf

**2. [Rule 1 - Bug] Bought companions captured at signing**
- **Found during:** Task 2
- **Issue:** the plan's default (`_toBuy.pets` read on `TransactionDone`) misses companions when `characterUpdated` arrives before the mutation reply: `_pruneOnOwnedPets` removes them from `_toBuy` first (Phase 21 UAT race of the same kind).
- **Fix:** `_petsInFlight` set in `_onConfirm`, read and cleared on `TransactionDone`, cleared on `TransactionError`; extra test «a companion served with the character before the reply still gets its prompt (D-18)».
- **Commit:** 4c0167ac

**3. [Rule 3 - Blocking] Test harness changes**
- `test/helpers/journal_harness.dart` (outside files_modified): `pumpJournalPage` gains `CompanionNameCubit? companionNameCubit` and `bool isCompanionNamingEnabled = false` (Journal no longer const there).
- shop_test purchase group: character with coins (TransactionModal reads `status!.coins!`) and a 780x480 surface, because the shop satchel's `CoinsDisplay` overflows by 6 px with the test font when coins are shown (pre-existing, logged in `deferred-items.md`). These two test adjustments landed in the GREEN commit 4c0167ac.

### Other
- Extra tests: «the field starts from the current name (D-19)», «a refusal for another companion is not shown here (D-31)», the race test above.
- The plan's single title «no prompt for an ambush, an already named companion, another character's result or with the switch off» is split into four tests (one pump each), each titled with D-18 (switch-off one also Pitfall 3).
- The Journal pre-switch pin «the details sheet offers no rename before the switch» is folded into «the details offer «Dai un nome» or «Cambia nome» only with the switch on (D-19, Pitfall 3)».
- STATE uses `Plan: 12 of 17` (orchestrator format).

## Known Stubs
None. The entry points are intentionally off (`companionCareEnabled = false`) until 22-16.

## Threat Flags
None beyond the plan's register (T-22-37 form rules block confirm; T-22-38 own character only, tested; T-22-39 switch off by default, tested; T-22-40 confirm and pop blocked while submitting, drag disabled).

## Gates
- `flutter test test/shared/components/popup` +217 green; `flutter test test/screens/mainScreen` +1383 green.
- Analyzer 47 info, ANALYZE_GATE_OK. All touched files formatter-clean (they were clean before).
- Tests added: +24 (name sheet 12, shop 4, presenter 6, journal +2 net) → expected suite 4944 (full suite not run).

## Self-Check: PASSED
