---
phase: 25-account-deletion-and-legal-consent
plan: 06
subsystem: shared
tags: [account-deletion, cancelled-quest, reactive-paths, push, pins]
requires:
  - 25-05 (branch state; no code dependency)
provides:
  - pins proving that a quest cancelled by an account deletion (D-13, D-23) is drawn by today's reactive paths for the members left behind
affects: [25-07, 25-08]
tech-stack:
  added: []
  patterns:
    - a stream-driven widget case seeds whenListen with a StreamController and settles with pumpAndSettle (two microtask hops through the mock's broadcast stream)
key-files:
  created: []
  modified:
    - test/screens/mainScreen/characterCubit/character_cubit_test.dart
    - test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
    - test/screens/mainScreen/components/travel_outcome_listener_test.dart
    - test/screens/mainScreen/components/quest_abandon_outcome_listener_test.dart
    - test/screens/mainScreen/components/party_watch_listener_test.dart
    - test/screens/mainScreen/components/quest_scope_listener_test.dart
    - test/models/quest/quest_availability_test.dart
    - test/repository/services/push/foreground_push_events_test.dart
    - test/repository/services/push/notification_tap_router_test.dart
    - test/screens/auth/inAppNotificationsCubit/in_app_notifications_cubit_test.dart
decisions:
  - "The Board and shop availability case lives in satchel_availability_test.dart: disabledSatchelPages decides it, while MapAvailabilityCubit only gates result sheets on the Map and never reads the character"
  - "Points are refunded on User.twitchPoints (userUpdated), not on the character: the character case pins lane, place, food and life only"
metrics:
  duration: ~25 min
  completed: 2026-11-25
  tasks: 3
  files: 12
---

# Phase 25 Plan 06: Cancelled started quest drawn by the existing reactive paths Summary

Twelve pins prove that a member sent back by a quest cancelled after a companion's deletion (D-13, D-23) is drawn from served values only. One `characterUpdated` empties the lane and puts him in the city with food and life refunded: the quest paper leaves the Map, the pawn stands free on the city marker, Board and shop reopen, the Board of that city is reread in silence, the quest served back can be accepted again. No travel, abandon or result outcome fires. The `questCancelled` push body comes out verbatim and routes as every personal push. **Every case was green at the first run: no `lib/` change, no fix commit.**

## Tasks

| Task | Commits |
|------|---------|
| 1 The member's side: character stream, map and silent listeners | `8f40cf64` test(shared): pin the jump back of a cancelled quest on the map |
| 2 The quest back on the Board and the push of the cancellation | `a4c36347` test(shared): pin the quest back on the board and the cancel push |
| 3 Bookkeeping | `docs(phase-25): record plan 06 progress` |

## Cases: all green at the first run (pins)

| Case | File | Path that already draws it |
|------|------|----------------------------|
| a member sent back by a cancelled quest reads the served lane, place, food and life (D-13, D-23) | character_cubit_test | `CharacterCubit` re-emits the whole served character (SYNC-07) |
| the paper of a started quest leaves the map when the lane is emptied (D-23) | quest_paper_layer_test | `QuestPaperLayer` draws only from `quests.pendingQuest`; null lane → `SizedBox.shrink` |
| the pawn stands in the city after the jump back, with no travel drawn (D-13, D-23) | character_marker_layer_test | pawn at `status.location`, no `activeTravel` → no travel label, drag free, tap opens the city (`currentCityOf`) |
| the Board and the shop of the city are available again after the jump back (D-13, D-23) | satchel_availability_test (see deviation 1) | `disabledSatchelPages`: city marker, no travel, `missionInProgress` false → nothing disabled |
| the jump back of a cancelled quest shows no outcome (D-23) | travel_outcome_listener_test | listener reacts only to `TravelCubit` flows; a character change while idle resets nothing, publishes nothing |
| the jump back of a cancelled quest shows no outcome (D-23) | quest_abandon_outcome_listener_test | listener reads only `QuestAbandonCubit`; no notice, no reset, no reread |
| a member of a not-started quest keeps following the served count when a seat is freed (D-13) | party_watch_listener_test | `PartyWatchListener` keeps the watch while the lane waits; `questStateLabel` reads `registeredAdventurers.length` of the served quest (2/3 → 1/3); replacement by `questUpdated` already pinned in quest_cubit_test |
| the jump back to the city rereads the Board of that city in silence (D-13, D-23) | quest_scope_listener_test | `QuestScopeListener`: location and lane change → `refreshQuests(cityId: 'city-1')` once, no loader |
| a quest served back on the Board, not started and without registrations, can be accepted again (D-13, D-23) | quest_availability_test | `standingOf` → `available`, not torn; `boardQuestsFor` lists it |
| a questCancelled push carries the backend body verbatim (D-23) | foreground_push_events_test | `PushEvent.tryParse` copies `body`; `notification.description` = body |
| the cancellation banner shows the served title and body (D-23) | in_app_notifications_cubit_test | the stream event becomes `state.current`; its `KGNotification` is the served title and body |
| tapping a questCancelled push routes as today (D-23) | notification_tap_router_test | `questCancelled` is personal → offered to the `NotificationIntentSink` (Map tab), no link opened |

No case was RED in production. Two first drafts failed for test mechanics only and were corrected before the commit (never committed RED): the paper case needed `pumpAndSettle` after the stream event (the mock's broadcast stream adds a microtask hop), the Board reread case used `verifyNoMoreInteractions` on a mock whose `stream` getter counts as an interaction (replaced by `captureAny` → `['city-1']`).

## Deviations from Plan

1. **[Rule 1 - plan error] Board/shop case moved from `map_availability_cubit_test.dart` to `satchel_availability_test.dart`.** `MapAvailabilityCubit` is the «Map visible and free» signal for the result sheets (page, routes, quest sheet, drag, teleport); it never reads the character and has nothing to do with the Board or the shop of a city. The availability of Board and shop is `disabledSatchelPages` (`lib/screens/mainScreen/components/satchel_availability.dart`), fed by `MainScreen` from the served character. The case is there; `map_availability_cubit_test.dart` is untouched, so the acceptance grep «D-23 in each of the seven files» lists `satchel_availability_test.dart` in its place.
2. **Points not in the character case.** The character carries no points balance: the refund of `pendingQuest.pointsSpent` lands on `User.twitchPoints` through `userUpdated` (AuthCubit), already a reactive path today. The case title says «lane, place, food and life».

## Known Stubs

None.

## Notes for 25-07 and the device UAT

- Plans 25-01..25-06 run against today's BE; 25-07 waits for the BE Phase 26 merge.
- On the device (25-08) the cancellation needs two players on a STARTED group quest and one of them deleting his account: check that the other one sees the BE's `questCancelled` banner verbatim, the paper leaving the Map, the pawn in the city with food, points and life back, and the quest on the Board again (accepted again if wished). A third player with the Board open sees the quest at the next silent reread only (declared scope, no new subscription).
- No SDL change, no new document, no new copy in this plan.

## Self-Check: PASSED

- 12 modified test files present; commits `8f40cf64` and `a4c36347` in `git log`.
- `git diff --stat 5c0b1b80 -- lib/graphql` empty; no `lib/` file touched by this plan.
- `grep -rn "Un avventuriero scomparso" lib` prints nothing.
- Analyzer «47 issues found» (`ANALYZE_GATE_OK`); trailer check `0` on both commits.
