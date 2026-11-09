---
phase: 16-travel-ambushes
reviewed: 2026-11-06T18:52:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - lib/graphql/fragments/quest_result_fragment.dart
  - lib/models/notification_category.dart
  - lib/models/quest_result/ambush_city.dart
  - lib/models/quest_result/ambush_report.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/quest_result/quest_result_kind.dart
  - lib/screens/mainScreen/components/notification_popup_registry.dart
  - lib/screens/mainScreen/components/quest_result_presenter.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart
  - lib/screens/mainScreen/questResultsCubit/quest_results_state.dart
  - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
  - lib/shared/components/popup/ambush_report_carousel.dart
  - lib/shared/components/popup/quest_result_sheet.dart
findings:
  critical: 0
  warning: 0
  info: 3
  total: 3
status: issues_found
---

# Phase 16: Code Review Report

## Summary

Plans 16-01..16-06 reviewed at standard depth (16-07 and 16-08 are gated on the BE merge and out of scope). The implementation matches CONTEXT D-01..D-13 including the user's D-05 veto.

Verified clean:
- Parsing: `fromWire` is tolerant; ambush without `ambush` block and quest without `quest` are dropped item by item by `tryFromJson`; `toJson` round trips; the only `quest` read in `lib/` is null-aware (`quest_result_sheet.dart:206`), no `!` on `quest`.
- Contract: the fragment adds exactly `kind` and `ambush { at nearCity reachedCity }`, no other document changed, no `@client`. `ambushDefeat('ambush_defeat','ambushDefeat')` is personal. All exhaustive switches have the new arm. `PushEvent` unchanged, no FE copy of the defeat text.
- Queue: `presentable`, `presented`, `closed`, `dismissedExternally` (position floor 0) and `_isKnown` (covers `showingGroup`) are correct. `closed` adds all ids to `_closedIds` synchronously, so a concurrent read cannot re-admit them. Failed acks go to `_pendingAcks` and are retried.
- Settling: the live ambush emits `inFlight` together with the merged queue. At most one chained read. The final emit of a read keeps `inFlight` when chained. The gap between that emit and `_onRefetchSettled` is microtask-only, so no lost emit or stuck `inFlight`. No timer.
- Presenter: `group` is captured at presentation. `showingGroup` can only change through `presented`/`closed`/`dismissedExternally`, all gated by `_isPresenting` and the pop, so the captured value stays valid. `_announceArrival` returns early for ambushes without suppress/publish. The only `NotificationPreferencesCubit` read is the pre-existing questEnd path.
- Carousel: no `PageController`, `nextPage` or `animateToPage`. Every page calls the same `onContinue`. Keys are stable per id. Material is transparent. No chrome.
- Sheet: header order (outcome, title, type, date) is unchanged for quests. The ambush line replaces title and type. "Portato a" follows "Ferite" only when `reachedCity != null`. There is no client branch on outcome or kind for rewards or XP.

No critical or warning findings. Three quality notes follow.

## Critical

None.

## Warning

None.

## Info

### IN-01: `isSettlingAmbushes` also blocks the carousel during unrelated reads

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_state.dart:55`
**Issue:** The getter is `head.isAmbush && pendingRefetch == inFlight`. `_performRefetch` (`quest_results_cubit.dart:228`) sets `inFlight` for every read (foreground, reconnection, character-unavailable). An ambush head already queued and ready (for example one waiting only for the Map to be free) is therefore held for the whole read. That includes the pending-ack retries (up to 15 s each) and the silent retry (about 2 minutes offline) before the read gives up. The CONTEXT D-12 wording is narrower: the head waits for the read of a live arrival.
**Why it matters:** No data is lost and the carousel opens once the read settles, but with no network the user sees nothing for about 2 minutes after resume. There is no spinner, so rule 2 is respected, but the delay is unexplained.
**Suggested fix:** Either accept it and document it in the getter's doc comment, or track a dedicated `settlingAmbush` flag set in `_accept` and cleared when the chained read finishes. If you take the second route, write the RED test first: queue an ambush head, call `refetchPending()` with a never-completing fetch, and assert `isSettlingAmbushes` is false.

### IN-02: A malformed `quest` block or an empty city name drops a whole ambush report

**File:** `lib/models/quest_result/quest_result.dart:118-120`, `lib/models/quest_result/ambush_city.dart:13`
**Issue:** For an ambush, `_questOrNull` still calls `QuestResultQuest.fromJson` on any map. If the BE sent a half-filled `quest` object, the report would be dropped by `tryFromJson` for a block the FE never uses. An empty `name` in `nearCity` or `reachedCity` has the same effect (strictness chosen by D-14).
**Why it matters:** A dropped report is never acknowledged, so it is re-read on every refetch and never shown. The player was already rerouted by the BE and learns nothing about it. This only happens on a BE contract violation, so the risk is low.
**Suggested fix:** For `isAmbush`, ignore `quest` entirely (`quest: isAmbush ? null : QuestResultQuest.fromJson(...)`). Keep the strictness on the city names only if that is intended. RED test first: an ambush JSON with `quest: {}` parses with `quest == null`.

### IN-03: The "k di N" counter of a quest sheet keeps the carousel's size

**File:** `lib/screens/mainScreen/questResultsCubit/quest_results_cubit.dart:148`
**Issue:** `presented` advances `position` by `group.length` (this is the specified D-11 behaviour). After a carousel of N and with `k` quests left in the queue, the first quest sheet shows "N+1 di N+k". With one quest left it shows e.g. "4 di 4", although the carousel has its own group-local counter.
**Why it matters:** This is cosmetic, but the counter reads oddly when a lone quest follows a carousel.
**Suggested fix:** Confirm with the user in UAT (plan 16-08). If it is unwanted, `closed` could reset `position` to 0 when the closed group was an ambush group, with a RED test in `quest_results_queue_test.dart`.

---

_Reviewed: 2026-11-06T18:52:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
