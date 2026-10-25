---
phase: quick-261025-grp
fixed_at: 2026-10-25T15:13:04Z
review_path: .planning/quick/261025-grp-party-waiting-abandon/261025-grp-REVIEW.md
iteration: 1
findings_in_scope: 9
fixed: 9
not_needed: 0
skipped: 0
deferred_out_of_scope: 1
status: all_fixed
findings:
  WR-01: { status: "fixed: requires human verification", commits: [fd90a5e, 0b1f041, 7c4b627, ffb8eff] }
  WR-02: { status: "fixed (FE part, best-effort)", commits: [1987cad, 6598817] }
  IN-01: { status: deferred, reason: "schema check handled by the orchestrator once BE PR #13 lands" }
  IN-02: { status: fixed, commits: [3bbdf26] }
  IN-03: { status: fixed, commits: [34c2758] }
  IN-04: { status: fixed, commits: [0b1f041] }
  IN-05: { status: fixed, commits: [2a87ab6] }
  IN-06: { status: fixed, commits: [c90e44e, e228c9d] }
  IN-07: { status: fixed, commits: [11bf09d] }
  IN-08: { status: fixed, commits: [fe03b0f, 1d53e58] }
---

# Quick 261025-grp: Code Review Fix Report

**Fixed at:** 2026-10-25T15:13:04Z
**Source review:** .planning/quick/261025-grp-party-waiting-abandon/261025-grp-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 9 (WR-01, WR-02, IN-02..IN-08)
- Fixed: 9
- Skipped: 0
- Not in scope: IN-01 (schema check, owned by the orchestrator)

Verification: `flutter test` 1755 passed (was 1734, +21); `flutter analyze` 54 issues, all baseline (52 info + 2 warning), 0 errors. `dart format` only on the files touched, one at a time.

## Fixed Issues

### WR-01: The quest sheet opened from the paper does not follow the lane

**Files modified:** `lib/screens/mainScreen/tabs/map/world_map.dart`, `lib/screens/mainScreen/components/quest_abandon_outcome_listener.dart`, `test/screens/mainScreen/tabs/map/world_map_travel_test.dart`, `test/screens/mainScreen/components/quest_abandon_outcome_listener_test.dart`
**Commits:** fd90a5e (test), 0b1f041 (fix), 7c4b627 (test), ffb8eff (fix)
**Applied fix:** `_WorldMapState` now keeps `_selectedQuest` + `_selectedLane` (null = opened from a marker). Label and abandon action are derived at build time inside a `BlocBuilder<QuestCubit>` from the followed lane and the current quest in the list. A `BlocListener<CharacterCubit>` (on pending-lane change) updates `_selectedLane`, or closes the sheet when the lane empties or holds another quest. On top of that, `QuestAbandonOutcomeListener` rereads the character silently after `notWaiting`/`notFound`, so the sheet catches up even when the live event was missed. Tests: party sets off while open ⇒ no button, label "In combattimento…"; lane emptied ⇒ sheet closed; lane on another quest ⇒ sheet closed; stale failures ⇒ `refreshCharacter()`, connection failure ⇒ none.
**Status:** fixed: requires human verification (state-following logic).

### WR-02: k/N counts the Board snapshot, which never refreshes while on the Map

**Files modified:** `lib/screens/mainScreen/components/party_waiting_refresh_listener.dart` (new), `lib/screens/mainScreen/main_screen.dart`, `lib/screens/mainScreen/tabs/map/world_map.dart`, `test/screens/mainScreen/components/party_waiting_refresh_listener_test.dart` (new), `test/screens/mainScreen/main_screen_test.dart`, `test/screens/mainScreen/tabs/map/world_map_travel_test.dart`
**Commits:** 1987cad (test), 6598817 (fix)
**Applied fix:** new session listener `PartyWaitingRefreshListener` (mounted in `MainScreen` with the loaded cities) calls `QuestCubit.refreshQuests(cityId: currentCityOf(...)?.id)` on the not-waiting → waiting transition of the pending lane; the Map does the same when the paper of a waiting lane is opened. No polling. Because the open sheet reads the current quest from `QuestCubit` (WR-01), a refreshed list updates k/N live (tested: "2/3" after a list update).
**Best-effort:** the k/N count is best-effort: it only refreshes on entering the waiting state and on opening the sheet, so registrations in between stay invisible until the BE puts the count on the lane or emits `characterUpdated` to each member (follow-up recorded in the BE handoff).

### IN-02: No test for the marker-opened sheet and for drag-dismiss while abandoning

**Files modified:** `test/screens/mainScreen/tabs/map/world_map_travel_test.dart`
**Commit:** 3bbdf26
**Applied fix:** "a quest opened from a marker offers no abandon action" (with a waiting lane in the character; no button, no state label) and "dragging the confirmation down cannot dismiss an abandon" (`QuestAbandoning('e-1')` + `dragSheetDown`). Checked that the drag test fails without the `QuestAbandoning` state, so it is not vacuous.

### IN-03: Shell test does not cover the new provider and listener

**Files modified:** `test/screens/auth/authenticated_shell_test.dart`
**Commit:** 34c2758
**Applied fix:** the gameplay-cubits test reads `QuestAbandonCubit`, asserts it closes on removal, and expects one `QuestAbandonOutcomeListener`.

### IN-04: Selection state cleared in two different shapes

**Files modified:** `lib/screens/mainScreen/tabs/map/world_map.dart`
**Commit:** 0b1f041 (with WR-01)
**Applied fix:** the three fields became `_selectedQuest` + `_selectedLane`. A single `_clearSelection()` is used by the dismissed-status listener and by the map `GestureDetector`.

### IN-05: Abandon button styles the colour twice

**Files modified:** `lib/shared/components/popup/quest_info_sheet.dart`, `test/shared/components/popup/quest_info_sheet_test.dart`
**Commit:** 2a87ab6
**Applied fix:** `foregroundColor` alone sets the colour; `theme.bodyLarge` moved to `styleFrom(textStyle:)`; child is `const Text(abandonLabel)`. A guard test pins the rendered colour (bloodRed) and the body font. `Semantics` kept for consistency with `travel_confirmation_sheet.dart`, as the review allows.

### IN-06: Notice title contradicts the `notFound` body

**Files modified:** `lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart`, `test/screens/mainScreen/questAbandonCubit/quest_abandon_notice_test.dart`
**Commits:** c90e44e (test), e228c9d (fix)
**Applied fix:** the title is now "Abbandono non riuscito" (provisional copy) and fits every body.

### IN-07: Hand-written defaults map duplicates `NotificationCategory.values`

**Files modified:** `notification_preferences_state.dart`, `notification_preferences_cubit.dart`, `notification_preferences_cubit_test.dart`, `settings_test.dart`, `notification_preferences_section_test.dart`
**Commit:** 11bf09d
**Applied fix:** `defaults` is a `static final Map.unmodifiable({for (c in NotificationCategory.values) c: defaultEnabled})`. A const map can't be built with a collection-for, so the constructor is no longer `const` (`enabled ?? defaults` in the initializer) and the `const` call sites drop it. New tests: defaults cover every category; defaults are unmodifiable.

### IN-08: The waiting label widens the paper column

**Files modified:** `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart`, `test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart`
**Commits:** fe03b0f (test), 1d53e58 (fix)
**Applied fix:** the label sits in a `SizedBox(width: _paperSize)` as a one-line centred `AutoSizeText`. Test: the paper column stays 110 px wide with the waiting label (was 534).

## Out of scope

### IN-01: Schema check deferred; the branch cannot run against the current BE

**File:** `lib/graphql/fragments/character_fragment.dart:94`
**Reason:** not in the fix list for this run. Keep the branch stacked until the BE schema has `abandonQuest` and `arrivedAt`, then run the schema check (33 documents) from the orchestrator. Until then, no device UAT on this branch.

---

_Fixed: 2026-10-25T15:13:04Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
