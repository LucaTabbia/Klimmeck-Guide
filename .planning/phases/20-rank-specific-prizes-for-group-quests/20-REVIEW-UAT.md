---
phase: 20-rank-specific-prizes-for-group-quests
reviewed: 2026-11-13
depth: standard
scope: work after the pre-gate review (plan 20-03, UAT fixes 01-03, quick 261113-aql), diff c8e92a1b..HEAD on lib and test
status: issues_found
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
---

---
phase: 20-rank-specific-prizes-for-group-quests
scope: post-pre-gate work (plan 20-03, UAT-FIX-01/02/03, quick 261113-aql)
reviewed: 2026-11-13
depth: deep
diff: c8e92a1b..HEAD -- lib test (25 files)
files_reviewed: 25
files_reviewed_list:
  - lib/graphql/fragments/quest_fragment.dart
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/models/quest/quest.dart
  - lib/models/quest/quest_availability.dart
  - lib/models/quest/quest_blocked_reason.dart
  - lib/models/quest/quest_capacity.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/screens/mainScreen/tabs/board/board.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/utils/game_duration_format.dart
  - lib/utils/quest_outcome_lines.dart
  - lib/utils/utils.dart
  - test/graphql/board_documents_test.dart
  - test/graphql/quest_result_documents_test.dart
  - test/helpers/fixtures/quest_fixtures.dart
  - test/helpers/fixtures/quest_result_fixtures.dart
  - test/models/quest/quest_availability_test.dart
  - test/models/quest/quest_blocked_reason_test.dart
  - test/models/quest/quest_sheet_details_test.dart
  - test/models/quest/quest_test.dart
  - test/screens/mainScreen/tabs/board/board_test.dart
  - test/shared/components/popup/quest_info_sheet_test.dart
  - test/shared/components/popup/quest_result_sheet_test.dart
  - test/utils/game_duration_format_test.dart
  - test/utils/quest_outcome_lines_test.dart
findings:
  critical: 0
  warning: 4
  info: 4
  total: 8
status: issues_found
---

# FE Phase 20 — review of the work added after the pre-gate review

Read-only review. Nothing in the repo was modified, no test, analyzer, formatter or build was run, `.env` was never read. The BE repo was read only through `git -C <BE> show / log / grep / branch` (no fetch, no checkout).

Also read outside the diff, to trace the call chains: `quest_viewer.dart`, `registered_adventurer.dart`, `adventurer_slot.dart`, `quest_lane.dart`, `board_policy.dart` (grep), `tearable_paper.dart`, `quest_cubit.dart`, `party_watch_listener.dart`, `quest_scope_listener.dart`, `quest_acceptance_outcome_listener.dart`, `quest_acceptance_failure.dart`, `quest_acceptance_notice.dart`, `quest_subscriptions.dart`, `quest_result.dart` (`_countFrom`), BE `src/quests/acceptance/quest-capacity.ts` (origin/develop), BE `src/schema.gql` (origin/develop and local branch `feat/quick-aid-locks-source-quest`), BE commit `54692c61` (`sharedTimeOf`).

## Summary

The four code changes do what their documents say and the model work is clean: `awaitingRescue` is in `fromJson` / `toJson` / `copyWith` / `props` with a lenient read, the seat rule now lives in one copy that matches the BE helper line by line, the old duration helper is gone with no caller left, the copy matches the amended table.

No critical finding. The main problem is not in a line of the diff but in an assumption the quick task rests on: the lock is said to appear and disappear live through `questUpdated`, and the app does not receive `questUpdated` for a Board quest. Two further warnings need a decision rather than a patch (the two-legend highlight, the minutes truncated in the new duration wording), and one is a merge-order gate.

## Warnings

### WR-01: The rescue lock is not live on the Board — `questUpdated` is never subscribed for a listed hunt or dungeon, and the refusal neither rereads the list nor names the reason

**Files:**
- `lib/screens/mainScreen/components/party_watch_listener.dart:56-63` (the only caller of `QuestCubit.watchQuest`)
- `lib/screens/mainScreen/questCubit/quest_cubit.dart:118-135` («Una sola quest seguita alla volta»)
- `lib/graphql/subscriptions/quest_subscriptions.dart` (`questUpdated(questId: String!)`)
- `lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart` (`_staleListFailures`, about lines 29-35)
- `lib/screens/mainScreen/questAcceptanceCubit/quest_acceptance_notice.dart` (`notAcceptable` text)
- `test/screens/mainScreen/tabs/board/board_test.dart` (test «when questUpdated clears the lock the sheet is whole and tearable again»)

**VERIFIED by reading:**
- The subscription takes one `questId`. `watchQuest` is called only by `PartyWatchListener`, and only with the id of the viewer's own `pendingQuest` while it is travelling or waiting for its party. No other code subscribes.
- So a viewer who is looking at the Board never receives the republished source quest. The list changes only through `refreshQuests`: Board `initState` (`board.dart:69`), `QuestScopeListener` (a change of the viewer's own location, title or lanes), `world_map.dart:597`, and after an acceptance outcome listed in `_staleListFailures`.
- `_staleListFailures` is `{full, alreadyTaken, notFound, timedOut, noEffect}`. `notAcceptable` is not in it.
- The refusal text for `notAcceptable` is «Missione non disponibile, avvisa il locandiere».
- `261113-aql-SUMMARY.md` states «`questUpdated` republishes the source quest at aid birth and closing: the Board rereads its sheet from the list, so the lock appears and disappears live». The second half does not hold in the app as it is.

**Not verified:** that the BE refuses a locked quest with `QUEST_NOT_ACCEPTABLE` (taken from the SUMMARY; the BE acceptance code was not traced).

**Failure scenarios:**
1. Lock born while the Board is open. Viewer B has the Board open on a dungeon; viewer A falls in it and an aid opens. B's sheet stays whole and tearable. B swipes, the BE refuses, B reads «Missione non disponibile, avvisa il locandiere» — a message that sends the player to the game master for a normal game state. The list is not reread, so the sheet recomposes whole and B can repeat the swipe with the same result until the Board is closed and reopened.
2. Lock released while the Board is open. The rescue closes; B's sheet stays torn with «Soccorso in corso…» until the Board is reopened or B's own character changes scope. The device step «the lock disappears live» can only pass by reopening the Board.

**Why the suite is green:** the Board test named after `questUpdated` pushes a new `QuestLoaded` into the mocked cubit stream (`questStates.add(loaded([...]))`). It proves that the Board redraws when the list changes, not that the list changes. Nothing in the diff tests the path from the wire to the list for a quest the viewer has not accepted.

**Fix (needs an orchestrator ruling, the options differ in cost):**
- Minimum, no new subscription: add `QuestAcceptanceFailure.notAcceptable` to `_staleListFailures` so the refused swipe rereads the list and the sheet turns torn with the right reason on the spot. This closes scenario 1 after one refusal; scenario 2 stays as «visible at the next Board opening» and must be written as such in the SUMMARY and in the device steps.
- Live, as the SUMMARY promises: the Board needs a source of events for quests it lists (a subscription for the selected sheet while it is open, or a list-level event from the BE). That is a contract change, not a patch.
- In both cases rename the Board test to what it proves («when the list drops the lock…») and correct the sentence in the SUMMARY.

### WR-02: `awaitingRescue` is selected in `QuestFragment`, and the BE `origin/develop` schema does not have the field

**File:** `lib/graphql/fragments/quest_fragment.dart:63`

**VERIFIED by reading:** `git -C <BE> show origin/develop:src/schema.gql` has no `awaitingRescue` (it does have `turnsTotal` and `lastTurnKind`, so plan 20-03 is safe). The field exists only on the BE branch `feat/quick-aid-locks-source-quest`, which is local (no `remotes/origin/…` ref for it). `QuestFragment.fields` feeds both `quests` and `OnQuestUpdated`.

**Failure scenario:** this FE branch runs against a BE without the twin (BE `develop` today, or a production BE deployed before it). Both documents fail GraphQL validation. `refreshQuests` swallows the error and keeps the previous list, so on a cold start the Board, the map quest markers and the party k/N have no quests at all, with no visible error.

**Fix:** not a code change. Record it as a hard gate in the SUMMARY / PR description: the FE PR is not ready before the BE twin is on `develop`, and the 46-document schema check (declared «NOT run» in the SUMMARY) must run after that merge and before the PR leaves draft.

### WR-03: With two legends on a `[legend, hero]` quest both read the hero line as their own, and the first one's highlight moves when the second registers

**File:** `lib/models/quest/quest_sheet_details.dart:225-237` (`_viewerSeatTitleOf`)

**VERIFIED by reading:** the viewer's seat is `seatTitleOf(slots, others, title)` where `others` is every registration except the viewer's. Registration order is not used.

**Failure scenario:** boss with `[legend ×1, hero ×1]`.
- Legend A registers alone: `others = []`, A reads «Leggenda: 1 / 1» highlighted. Correct.
- Legend B registers: for A, `others = [B]`, one legend against one legend seat, so A's seat becomes hero. A's highlight jumps from the legend line to the hero line although A did nothing. For B, `others = [A]`, also hero. Both viewers see the hero line as theirs and nobody sees the legend line as theirs, while the counts read «Leggenda: 1 / 1», «Eroe: 1 / 1».

The counts and the acceptance rule are right; only the highlight is affected. No test covers a registered legend viewer next to another legend (the «is its own» case has the viewer alone).

**Hypothetical variant:** a viewer registered as hero who then becomes a legend is highlighted by the current title, not by the title stored on the registration; on `[legend ×1, hero ×1]` the highlight goes to the legend line while the registration counts on the hero line.

**Fix (ruling needed, because the BE assigns no individual seat, it only counts):** for a registered viewer, evaluate the seat against the registrations that precede the viewer's own in the list, and use the title stored on that registration:

```dart
final ownIndex = registered.indexWhere((r) => r.characterId == viewer.characterId);
final before = ownIndex < 0 ? registered : registered.sublist(0, ownIndex);
final title = ownIndex < 0 ? viewer.title : registered[ownIndex].title ?? viewer.title;
return title == null ? null : seatTitleOf(slots, before, title);
```

This assumes the BE serves `registeredAdventurers` in registration order; that was not verified. Add the two-legend case in both orders to the `legend on hero seats` group.

### WR-04: `formatQuestDuration` rounds seconds up and then drops them above one minute — the line can read up to 59 s less than the real time

**File:** `lib/utils/game_duration_format.dart:30-40`

**VERIFIED by reading:** `seconds` is a ceiling, `minutes = seconds ~/ 60` is a truncation. The doc comment says only «Arrotonda per eccesso al secondo». `20-UAT-FIX-03.md` writes the behaviour as an example («1 h 15 min 30 s → 1 ora, 15 minuti»); it is the executor's rule, the user's sentence only asked for the stray comma to go. The BE writes fractional times on purpose: `sharedTimeOf` (BE commit `54692c61`) rounds the share down to the millisecond.

**Failure scenario:** a dungeon aid worth 90 s reads «Tempo richiesto: 1 minuto»; one worth 119 s reads «1 minuto» as well (half the real wait). A 1 h dungeon with a 3/8 share is 22 min 30 s and reads «22 minuti». The sibling `formatGameDuration` in the same file rounds up to the minute for the stated reason that a time must never read shorter than it is; the two helpers now disagree on the direction.

**Fix (pick one, then pin it with a 61 s and a 119 s case, today absent):**
- round up to the minute from one minute on, like `formatGameDuration`: `final minutes = (ms / Duration.millisecondsPerMinute).ceil();` after the under-a-minute branch (90 s → «2 minuti»);
- or keep the seconds below one hour («1 minuto, 30 secondi»).
If the truncation is the wanted rule, say it in the doc comment, which today describes only the rounding up.

## Info

### IN-01: A lock that arrives during a drag leaves the sheet frozen half torn

**Files:** `lib/screens/mainScreen/tabs/board/board.dart:334`, `lib/shared/components/tear/tearable_paper.dart:85-123`

**Code path VERIFIED, trigger HYPOTHETICAL.** `isEnabled` false makes `_onDragUpdate` and `_onDragEnd` return at once, and `TearablePaper` has no `didUpdateWidget`. If the list is reread with `awaitingRescue: true` while the finger is on the sheet, the drag end is ignored and the pieces stay at the partial pose (no spring back) until the sheet is closed. `canTear` is already false for a locked quest through `standingOf`, and that path springs back correctly. The same holds for `noEffect` since Phase 18; the trigger is rare today because of WR-01 and becomes reachable if the lock is made live.

**Fix:** in `TearablePaperState.didUpdateWidget`, when `isEnabled` turns false and the sheet is not torn, call `_springBack(0)`; or leave `awaitingRescue` out of `isEnabled` and let `canTear` resist the swipe.

### IN-02: The precedence test has one viewer that proves nothing

**File:** `test/models/quest/quest_availability_test.dart`, test «the lock wins over the viewer-dependent refusals…»

**VERIFIED by reading:** `buildViewer(twitchPoints: 0)` on a `dungeon`: `_lacksPoints` is false for the standard lane (`quest_availability.dart:158-164`), so without the lock this viewer is `available`, not `insufficientPoints`. The other four viewers are real (busy lane, other city, unknown city, no title against the fixture default `minTitle: 'rookie'`). Hunt and dungeon are always standard lane, so the precedence over `insufficientPoints` cannot occur for the two source types; the item can simply go, or the SUMMARY sentence «the lock wins over … no points» can be corrected.

### IN-03: The reason line names one of the three ways the lock ends

**File:** `lib/models/quest/quest_blocked_reason.dart:10-11`

«Soccorso in corso: la missione riapre quando il ferito è stato raggiunto.» The SUMMARY records the user's answer as: free again whenever the aid closes (rescue done, wounded dead by timeout, wounded archived). The line is marked as the orchestrator's technical default, so this is only a note for the copy pass: «…riapre quando il soccorso si chiude» would cover the three cases.

### IN-04: The new doc comment of `anyRankOverflowOf` calls it a BE mirror, and the BE does not count unknown-rank registrations

**File:** `lib/models/quest/quest_capacity.dart:67-78`

**VERIFIED by reading:** BE `registeredCountsOf` skips a registration whose title is not a known title, so it adds nothing to the BE overflow nor to the BE `isFullForEveryone`. The FE adds `registered.where((r) => r.title == null).length` to the overflow and uses `registered.length` for the full check. Behaviour is unchanged by this diff (the expression was moved, not written), and the BE always stores a title today, so the difference is **hypothetical** (a legacy string registration or a title the app does not know). Worth one line in the comment, since the comment is new and the rule is «one copy, mirror of the BE».

## Checked and found correct

**Plan 20-03**
- The four fields are selected once, right after `stagesTotal`, in the shared fragment used by the subscription and both queries; names and order match the BE `origin/develop` SDL.
- The model already reads them leniently (`_countFrom`, `DungeonTurnKind.fromWire`), so an absent or malformed value cannot drop a result.

**UAT-FIX-01 (seats)**
- `foldedCountsOf`, `seatTitleOf`, `exactSeatsOf`, `anyRankOverflowOf` compared line by line with BE `quest-capacity.ts` (`foldedCountsOf`, `seatTitleOf`, `overflowOf`, `hasSeatFor`): same arithmetic, `seatTitleOf` on the raw legend count, overflow on the folded counts.
- `canRegisterWithTitle` is behaviour-identical to the removed inline version.
- One copy of the rule: `quest_sheet_details.dart` no longer has `exact` / `reg` / its own overflow, and the unused `max` import is gone.
- Walked by hand: zero legend seats (`[hero, mage]` + one legend → Eroe 1/1), one legend seat with one and two legends, legends beyond every exact seat going to the any-rank line, `[hero, any]` with hero + legend, no hero line at all (the extra legend only reaches the any-rank overflow), an unknown-title registration (any-rank line only), viewer with no title (no highlight), viewer absent (no highlight), `min` clamps so a line never reads above its count.
- `counts[title]!` cannot be null: the map is built over `TitleType.values`.
- `QuestViewer.characterId` is a non-null `String`, so the own-registration filter cannot match a legacy registration by accident.
- The six new tests fail for the right reason when the folding is removed, except the two declared as guards in the fix report.

**Quick 261113-aql (lock)**
- `Quest.awaitingRescue`: `== true` read (absent, `null`, `'true'`, `1`, `{}` → `false`, quest kept), present in `toJson`, `copyWith`, `props`; the test proves each of the four, including inequality through `props`.
- `QuestAvailability` is switched exhaustively in two places only (`isSheetTorn`, `questBlockedReasonOf`); both have the new value. No `default` branch hides it.
- Precedence: owner → prisoner → catalogue defect → lock → the rest. No more specific viewer reason is hidden for hunt and dungeon (`alreadyDone` and `full` cannot apply to them: neither is non-repeatable nor registered). `_failsOwnRequirements` needs no change because the lock precedes `laneBusy`.
- Accept entry points: `QuestAcceptanceCubit.accept` has one caller in `lib`, `board.dart:353`, reached only from `TearablePaper.onTorn`, which needs `canTear` (false through `standingOf`) and `isEnabled` (false). The map overlay (`quest_info_overlay.dart:54`) shows the sheet with no viewer and no action; the Inn has no quest sheet. No other path.
- `needsTravelPreview` goes through `canAccept`, so a locked sheet asks for no preview.
- The open sheet is read from the list at every build (`_selectedAmong`), so a reread list updates the open sheet with no stale copy; `Quest` is not cached on disk.
- `quest_fixtures.dart` omits the key when `null`, a shape the BE can send before the twin is merged; `true` / `false` are the `Boolean!` shapes.

**UAT-FIX-02 (copy)**
- The three strings match the amended table of `20-REPO-RULES.md` exactly; branch order and guards are untouched; no `+ 1`.
- No «turno» / «Turni» copy is left in `lib` (only field names and doc comments).
- «L°» with `lastTurn` 0 or above the total still prints as served («Caduto al 0° piano su 8»): same behaviour as before the copy change, already ruled `not_needed` in the pre-gate review (IN-01 there). `lastTurn` absent falls back to «Piani superati: C su T» and never prints «null°».

**UAT-FIX-03 (duration)**
- Boundaries by reading: 300 ms → «1 secondo», 7 500 ms → «8 secondi», 59 s → «59 secondi», 59.5 s and 60 s → «1 minuto», 3 600 000 ms → «1 ora», 1 h 0 min 30 s → «1 ora», 25 h → «25 ore», zero and negative → «0 minuti». The joined list can never be empty (from 60 s on, hours or minutes is positive). Singular and plural are right for the three units. No overflow: integer arithmetic on milliseconds.
- `getStringToShowFromDuration` has no reference left in `lib`, `test` or `docs`; `utils.dart` keeps its two imports in use; `quest_info_sheet.dart` no longer needs `utils.dart` and imports the new helper.
- `timeToComplete` absent prints no line, as before.

**Project rules**
- No game rule computed on the device beyond the mirrors that already existed; no new chrome, spinner, fetch, dependency or GraphQL operation; no `print` / `appLog` added; no secret.


## Orchestrator rulings (2026-11-13)

| Id | Ruling |
|----|--------|
| WR-01 | **FIX.** (a) After an `acceptQuest` refusal with `QUEST_NOT_ACCEPTABLE` the Board silently rereads `quests` (no spinner, no blocking loading), so the sheet turns torn with the real reason instead of leaving a stale acceptable sheet. (b) Live update: VERIFY first how `OnQuestUpdated` is scoped and what the Board already listens to; if the existing subscription can cover the listed quests at low cost (one subscription, not one per quest), wire it so a lock that starts or ends while the Board is open tears or restores the sheet; if it cannot without a new mechanism, do (a) only, keep the reread the Board already does when it opens, and state the limit in the report (the lock shows at the next list read). Rename or rewrite the Board test whose title claims `questUpdated` but only pushes a cubit state. |
| WR-02 | `not_needed` here: merge-order gate handled by the orchestrator (BE quick PR first, then schema check and full suite). |
| WR-03 | **FIX if `registeredAt` (or the wire order) is available on the registrations in the FE model**: with more legends than legend seats, the legends who registered first hold the legend seats and the later ones the hero seats; a registered viewer is highlighted on the seat it actually holds, a non-registered one on the seat it would take. If the order is not available on the wire, close `not_needed` with the evidence (cosmetic, needs two legends on a quest with both legend and hero seats). |
| WR-04 | **FIX.** From one minute up, the line rounds UP to the whole minute and never reads less than the real time (119 s → «2 minuti», 61 s → «2 minuti», 3 600 s → «1 ora», 3 601 s → «1 ora, 1 minuto»); under one minute it stays in seconds rounded up (7.5 s → «8 secondi», 59.5 s → «1 minuto»). Update the examples of `20-UAT-FIX-03.md`. |
| IN-01 | `not_needed` (hypothetical trigger; the next gesture or state settles the sheet). |
| IN-02 | **FIX (test)**: a viewer that really exercises the precedence. |
| IN-03 | **FIX (copy)**: «Soccorso in corso: la missione riapre quando il soccorso si conclude.» (true for every way the aid closes). Update the constant, its tests and the quick-task documents. |
| IN-04 | **FIX (comment)**: say exactly what mirrors the BE and what is FE-only tolerance. |
