---
phase: quick-261025-grp
reviewed: 2026-10-25T14:45:31Z
depth: standard
files_reviewed: 45
files_reviewed_list:
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/mutations/quest_mutations.dart
  - lib/models/notification_category.dart
  - lib/models/pending_quest.dart
  - lib/models/quest/quest_state_label.dart
  - lib/models/request/abandon_quest_request.dart
  - lib/repository/quest_abandon_failure.dart
  - lib/repository/quest_abandon_repository.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/screens/mainScreen/components/quest_abandon_outcome_listener.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_state.dart
  - lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - tool/schema_check/schema_check_documents.dart
  - test/graphql/character_fragment_test.dart
  - test/graphql/travel_documents_test.dart
  - test/helpers/fixtures/quest_fixtures.dart
  - test/helpers/mocks.dart
  - test/models/notification_category_test.dart
  - test/models/pending_quest_test.dart
  - test/models/push_event_test.dart
  - test/models/quest/quest_state_label_test.dart
  - test/models/request/abandon_quest_request_test.dart
  - test/repository/quest_abandon_failure_test.dart
  - test/repository/quest_abandon_repository_test.dart
  - test/repository/services/graphql/graphql_quest_abandon_test.dart
  - test/repository/storage/notification_preferences_store_test.dart
  - test/screens/mainScreen/components/quest_abandon_outcome_listener_test.dart
  - test/screens/mainScreen/questAbandonCubit/quest_abandon_cubit_test.dart
  - test/screens/mainScreen/questAbandonCubit/quest_abandon_notice_test.dart
  - test/screens/mainScreen/tabs/map/components/abandon_party_sheet_test.dart
  - test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart
  - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
  - test/screens/mainScreen/tabs/settings/components/notification_preferences_section_test.dart
  - test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart
  - test/screens/mainScreen/tabs/settings/settings_test.dart
  - test/shared/components/popup/quest_info_sheet_test.dart
findings:
  critical: 0
  warning: 2
  info: 8
  total: 10
status: issues_found
---

# Quick 261025-grp: Code Review Report

**Reviewed:** 2026-10-25T14:45:31Z
**Depth:** standard
**Files Reviewed:** 45
**Status:** issues_found

## Summary

Scope: `git diff feat/07-travel..HEAD` (7 commits, HEAD `3e0a848`) in the `Klimmeck-Guide-party` worktree. Every `lib/` and `tool/` file in the diff was read in full together with its neighbours (`quest_acceptance_*`, `travel_confirmation_sheet.dart`, `push_event.dart`, `notification_tap_router.dart`, `notification_intent_landing.dart`, `in_app_notifications_cubit.dart`, `notification_preferences_store.dart`, `board.dart`); the test files were checked for coverage of the main branches and for vacuous patterns.

The implementation is a faithful mirror of the Phase 6/7 patterns and respects the repo rules:

- **Label and getters (point 1).** `isTravelling = startDate == null && arrivedAt == null`, `isWaitingForParty = startDate == null && arrivedAt != null`; a started lane (with or without `arrivedAt`, so legacy documents included) falls through to the per-type switch, and the GM lanes never select `arrivedAt`, so story/worldMission keep "per tipo". The label tests cover travelling (every type), waiting with k/N, waiting without quest/seats, started without `arrivedAt` and started with `arrivedAt`.
- **Abandon flow (point 2).** `UI → QuestAbandonCubit → QuestAbandonRepository → KlimmeckGraphQl`; errors mapped from `extensions.code` only; `abandonQuest` builds no state from `CommonResponse`. Double submit is blocked twice (cubit guard on `QuestAbandoning`, buttons disabled). The confirmation is a `PaperSheetModal` on the root navigator with `BlocProvider.value` (the cubit is not closed with the route), `PopScope` + drag `NotificationListener` while in flight, self-closing on `QuestAbandoned`/`QuestAbandonFailed` with the `isCurrent` guard. The shell listener resets after every outcome; the map listener reverses the overlay on `QuestAbandoned` and the dismissed status clears `_selectedQuest`/`_selectedOnAbandon`. No listener leaks (sheet listener dies with the route, shell and map listeners live with their widgets).
- **`questCancelled` (point 3).** `isPersonal` true (id read through `validBackendIdentifier`, dedup `questCancelled|<id>`), tap → `NotificationTapRouter` → intent sink → Map tab with no popup (`defaultNotificationPopups[category]?.call` is a no-op), storage key `quest_cancelled`, `readAll` iterates `values`, defaults and Settings label updated, every enumerative test (category, push event, store, section, settings, cubit helper) extended.
- **Fragment and registry (point 4).** `arrivedAt` appears once in `questsFields`, on `pendingQuest` only (asserted by regex in the fragment test); `fullFields` feeds both `GetCharacter` and `characterUpdated`. `schemaCheckDocuments` has 33 entries and `test/tool/schema_check_documents_test.dart` enforces completeness by scanning `lib/graphql`.
- **Rules (point 5).** No `AlertDialog`, no `AppBar` (asserted in the sheet test), confirmation before the destructive action, theme tokens only, domain-named sealed states, `context.read` only for actions, provisional copy accepted.

No critical issues. Two warnings, both about the Map keeping a snapshot instead of following the live lane: the opened quest sheet freezes label and "Abbandona il gruppo" at open time (WR-01), and k/N is read from the Board's quest list, which has no refresh path on the Map (WR-02). The schema check against the BE is still deferred: `src/schema.gql` in the BE repo has 0 occurrences of `abandonQuest` and `arrivedAt` at review time (IN-01).

## Warnings

### WR-01: The quest sheet opened from the paper does not follow the lane

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:397-406` (and `:124-131`, `:187-190`, `:435-440`)
**Issue:** `_openFromPaper` computes `_selectedStateLabel` and `_selectedOnAbandon` once; the paper underneath (`QuestPaperLayer`) is reactive, the open sheet is not. While the sheet is open:
- `characterUpdated` moves the lane from waiting to started (the party fills up) → the sheet still reads "In attesa del gruppo k/N" and still offers "Abbandona il gruppo"; tapping it ends in `QUEST_NOT_WAITING` and the notice, with the sheet still showing the button;
- the lane empties (abandon from another device, 24 h `questCancelled`) → same stale sheet, `NOT_FOUND` on tap;
- after `QuestAbandonFailed(notWaiting | notFound)` nothing closes or refreshes the sheet, so the affordance that just failed stays on screen.
Phase 6 already snapshotted the label, but the only transition then was travelling → started with no action attached; the abandon button makes the stale snapshot an actionable one.
**Fix:** keep the lane instead of its derived values and follow `CharacterCubit`:
```dart
// _WorldMapState
PendingQuest? _selectedLane; // null = opened from a marker

void _openFromPaper(Quest quest, PendingQuest lane) {
  setState(() {
    _selectedQuest = quest;
    _selectedLane = lane;
  });
  _questAnimationController.forward();
}

// in _buildMap()
QuestInfoOverlay(
  animationController: _questAnimationController,
  selectedQuest: _selectedQuest,
  stateLabel: _selectedLane == null ? null : questStateLabel(_selectedLane!, _selectedQuest!),
  onAbandon: _selectedLane?.isWaitingForParty == true
      ? () => _confirmAbandon(_selectedQuest!)
      : null,
),

// in _buildListeners()
BlocListener<CharacterCubit, CharacterState>(
  listenWhen: (previous, current) =>
      _standardLaneOf(previous) != _standardLaneOf(current),
  listener: (_, state) => _followLane(_standardLaneOf(state)),
),

static PendingQuest? _standardLaneOf(CharacterState state) =>
    state is CharacterLoaded ? state.character.quests?.pendingQuest : null;

/// The sheet opened from the paper follows the lane; gone or another quest → it closes.
void _followLane(PendingQuest? lane) {
  final quest = _selectedQuest;
  if (quest == null || _selectedLane == null) return;
  if (lane == null || lane.quest?.id != quest.id) return _closeQuestSheet();
  setState(() => _selectedLane = lane);
}
```
Clear `_selectedLane` where `_selectedQuest` is cleared (`_onQuestAnimationStatusChanged`, `_selectQuest`). Add to `world_map_travel_test.dart` group "abandon the waiting party": push a `characterLoaded(pendingQuest: laneJson(startDate: ..., arrivedAt: arrival))` on `characterStates` while the sheet is open and expect `QuestInfoSheet.abandonKey` to disappear and the label to read "In combattimento…"; push `pendingQuest: null` and expect the sheet to close.

### WR-02: k/N counts the Board snapshot, which never refreshes while on the Map

**File:** `lib/models/quest/quest_state_label.dart:23-30`; `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:36-44`
**Issue:** `k = quest.registeredAdventurers.length` comes from the `Quest` held by `QuestCubit` (`QuestLoaded.quests`). That list is loaded by `MainScreen` at mount (`loadQuest()`), refreshed by the Board on city change and by `QuestAcceptanceOutcomeListener` after a stale-list rejection, and by nothing else: there is no quest subscription and `characterUpdated` selects only `quest { id }` on the lane. So "In attesa del gruppo 1/3" stays 1/3 while other players register, until the player happens to reopen the Board (which also has to be for the marker's city). The label promises a live count and shows a stale one; when the party completes, the lane switches to "In combattimento…" (lane-driven) while k/N never reached N.
**Fix (FE, cheap):** refresh the list when the lane enters the waiting state and when the Map is shown again, in `_buildListeners()`:
```dart
BlocListener<CharacterCubit, CharacterState>(
  listenWhen: (previous, current) =>
      _standardLaneOf(previous)?.isWaitingForParty != true &&
      _standardLaneOf(current)?.isWaitingForParty == true,
  listener: (context, state) => context.read<QuestCubit>().refreshQuests(
    cityId: currentCityOf(
      widget.cities,
      (state as CharacterLoaded).character.status?.location,
    )?.id,
  ),
),
```
This still leaves gaps between registrations. **Fix (contract):** record in `BACKEND-NOTES.md` for BE Phase 9 that the FE needs either `registeredCount` (or `registeredAdventurers { character }`) on `PendingQuest` (then `_waitingLabel` reads the lane, not the Board) or a `characterUpdated` emission to every party member on each registration. Until one of the two lands, consider dropping the count ("In attesa del gruppo") so the paper never shows a wrong number.

## Info

### IN-01: Schema check deferred; the branch cannot run against the current BE

**File:** `lib/graphql/fragments/character_fragment.dart:94`; `tool/schema_check/schema_check_documents.dart:51`
**Issue:** At review time `grep -c` on the BE `src/schema.gql` returns 0 for both `abandonQuest` and `arrivedAt` (BE plan 09-19 has not regenerated the schema yet). `arrivedAt` sits in `fullFields`, i.e. in `GetCharacter` and `characterUpdated`: against a BE without the field, the whole character load fails with a validation error at cold start, not just the abandon mutation. The STATE.md blocker note already records that the PR waits for BE PR #13; the summary defers the schema check to the orchestrator.
**Fix:** keep the branch stacked and unmerged; once the BE schema contains both symbols run `dart run tool/schema_check/dump_documents.dart <dir>` and `validate_documents.js` (33 documents expected) and record the result in the SUMMARY. Do not point a device UAT at this branch before that. (Side note: the "registers 33 documents" count in `test/graphql/travel_documents_test.dart:110` is redundant with `test/tool/schema_check_documents_test.dart`, which already enforces completeness; it only adds a line to touch on every new document.)

### IN-02: No test for the marker-opened sheet and for drag-dismiss while abandoning

**File:** `test/screens/mainScreen/tabs/map/world_map_travel_test.dart:601-661`
**Issue:** The must-have says the abandon action "never appears for ... a quest opened from a marker". The group covers paper-waiting (button present), paper-started (absent) and close-on-`QuestAbandoned`, but not `_selectQuest` (marker tap → `_selectedOnAbandon = null`). The travel flow has "dragging the sheet down cannot dismiss a start in flight" (`:502`); the `NotificationListener` in `_confirmAbandon` (`world_map.dart:422-423`) has no equivalent.
**Fix:** add "a quest opened from a marker offers no abandon action" (tap a `QuestMarkersLayer` marker with a waiting lane in the character, expect `QuestInfoSheet.abandonKey` absent) and "dragging the confirmation down cannot dismiss an abandon in flight" (push `QuestAbandoning('e-1')` on `abandonStates`, reuse `dragSheetDown`, expect `AbandonPartySheet` still found).

### IN-03: Shell test does not cover the new provider and listener

**File:** `test/screens/auth/authenticated_shell_test.dart:175-183`; `lib/screens/auth/authenticated_shell.dart:165-168, 198`
**Issue:** The shell test reads `QuestAcceptanceCubit` from the tree but nothing asserts that `QuestAbandonCubit` is provided or that `QuestAbandonOutcomeListener` wraps the body. A future refactor of the provider list could drop either without a red test (the Map tests inject a mock cubit, so they would stay green).
**Fix:** in the same test, `context.read<QuestAbandonCubit>()` and `expect(find.byType(QuestAbandonOutcomeListener), findsOneWidget)`.

### IN-04: Selection state cleared in two different shapes

**File:** `lib/screens/mainScreen/tabs/map/world_map.dart:124-131, 197, 388-394`
**Issue:** `_onQuestAnimationStatusChanged` clears `_selectedQuest` and `_selectedOnAbandon` but not `_selectedStateLabel`; the `GestureDetector.onTap` at `:197` clears only `_selectedQuest`; `_selectQuest` resets all three. Harmless today because both entry points reassign every field, but the three-field tuple is easy to desynchronise (see WR-01).
**Fix:** one `_clearSelection()` used by the status listener and the gesture handler (or the single `_selectedLane` field proposed in WR-01, which removes two of the three fields).

### IN-05: Abandon button styles the colour twice

**File:** `lib/shared/components/popup/quest_info_sheet.dart:132-147`
**Issue:** `TextButton.styleFrom(foregroundColor: bloodRed)` and `Text(style: theme.bodyLarge.copyWith(color: bloodRed))` set the same colour; the explicit text style also discards the button's pressed/disabled colour handling. `Semantics(label, button: true)` around a `TextButton` whose child is a `Text` duplicates the semantics the button already exposes (same pattern as `travel_confirmation_sheet.dart`, kept for consistency).
**Fix:** keep `foregroundColor` and pass `theme.bodyLarge` (without the colour) through `textStyle:` in `styleFrom`, or drop the `copyWith`.

### IN-06: Notice title contradicts the `notFound` body

**File:** `lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart:4, 12`
**Issue:** "Gruppo non abbandonato" + "Non sei più in questa missione" tells the player two opposite things (the lane is in fact gone). Provisional copy, accepted; noted so the UI phase does not inherit it.
**Fix:** a neutral title ("Abbandono") or a per-failure title map, as the body already is.

### IN-07: Hand-written defaults map duplicates `NotificationCategory.values`

**File:** `lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart:9-14`
**Issue:** `defaults` lists every category by hand; this quick task had to add the fourth line, and nothing fails when a fifth category forgets it (the store's `readAll` already iterates `values`, so the two can diverge silently).
**Fix:** `static final Map<NotificationCategory, bool> defaults = {for (final c in NotificationCategory.values) c: NotificationCategory.defaultEnabled};` (or `Map.unmodifiable` of it) and keep the existing test as the guard.

### IN-08: The waiting label widens the paper column

**File:** `lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart:53-73`
**Issue:** "In attesa del gruppo 2/3" at `bodyLarge` is roughly twice the 110 px paper; the `Column` grows to the text width and the paper is centred over it, so the paper shifts right compared with "In viaggio"/"In combattimento…". No overflow (loose constraints), purely cosmetic, provisional copy accepted.
**Fix:** constrain the label to the paper (`SizedBox(width: _paperSize, child: AutoSizeText(label, maxLines: 1, textAlign: TextAlign.center))`) or use a compact form on the paper ("Gruppo 2/3") and the full string in the sheet, as the plan allowed.

---

_Reviewed: 2026-10-25T14:45:31Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
