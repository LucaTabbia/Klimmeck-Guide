---
phase: quick-261026-prt
plan: 01
subsystem: quest
tags: [quest, party, subscription, graphql, map]
requirements: [QUEST-07]
requires:
  - BE Phase 9 plan 09-20: questUpdated(questId: String!): Quest! (snapshot on subscribe, one event per quest update, NOT_FOUND for a concluded or unknown quest)
  - quick 261025-grp: waiting-for-party label k/N read from QuestCubit
provides:
  - QuestFragment.fields shared by the quests query and OnQuestUpdated
  - KlimmeckGraphQl.subscribeToQuest / QuestBoardRepository.watchQuest
  - QuestCubit.watchQuest / unwatchQuest
  - PartyWatchListener (replaces PartyWaitingRefreshListener, WR-02 of 261025-grp)
affects: [quest board data, map waiting label, schema-check registry]
key-files:
  created:
    - lib/graphql/fragments/quest_fragment.dart
    - lib/graphql/subscriptions/quest_subscriptions.dart
    - lib/screens/mainScreen/components/party_watch_listener.dart
    - test/graphql/quest_documents_test.dart
    - test/repository/services/graphql/graphql_quest_subscription_test.dart
    - test/screens/mainScreen/components/party_watch_listener_test.dart
  modified:
    - lib/graphql/fragments/fragments.dart
    - lib/graphql/queries/quest_queries.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/repository/quest_board_repository.dart
    - lib/screens/mainScreen/questCubit/quest_cubit.dart
    - lib/screens/mainScreen/main_screen.dart
    - tool/schema_check/schema_check_documents.dart
    - test/graphql/travel_documents_test.dart
    - test/screens/mainScreen/questCubit/quest_cubit_test.dart
    - test/screens/mainScreen/main_screen_test.dart
    - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
    - .planning/STATE.md
  deleted:
    - lib/screens/mainScreen/components/party_waiting_refresh_listener.dart
    - test/screens/mainScreen/components/party_waiting_refresh_listener_test.dart
decisions:
  - PartyWatchListener is a StatefulWidget so a lane already waiting when MainScreen mounts (cold start, app restart) is watched too, and the watch stops when the screen leaves
  - a malformed or missing questUpdated payload becomes a FormatException (_questFrom), the same way _characterFrom guards characterUpdated
  - the stream is listened with cancelOnError; an error or a completed stream forgets the watch, so the next watchQuest for the same id subscribes again
  - the Map still rereads the list when the paper of a waiting lane is opened (world_map._refreshPartyCount, 261025-grp WR-02): left in place as a resync fallback after a dropped watch, outside this plan's file list
commits:
  - 5de55b3 test(quest): questUpdated document and stream
  - 6aa7dc1 feat(quest): subscribe to questUpdated through a shared fragment
  - 6f709be test(quest): watch the awaited party quest over the wire
  - 073c39f feat(quest): update the party counter live from questUpdated
  - 2a11258 docs(quick): record the live party counter
completed: 2026-10-26
---

# Quick 261026-prt: live party counter Summary

"In attesa del gruppo k/N" now moves the moment another adventurer accepts the quest. While the standard lane waits for the party, the app subscribes to `questUpdated(questId)` and every Quest it receives replaces the one in the QuestCubit list, so k/N updates live.

## What changed
- **Fragment:** `QuestFragment.fields` holds the selection that used to be inline in `QuestQueries.getAllQuests`, from `id` to the end of `prizes`, unchanged. The quests query and the new subscription both use it, so there is one shape and one parser.
- **Document:** `QuestSubscriptions.questUpdated` is `subscription OnQuestUpdated($questId: String!) { questUpdated(questId: $questId) { ...fields } }`. It is in the schema-check registry, which now has 34 documents.
- **Service:** `KlimmeckGraphQl.subscribeToQuest(questId)` mirrors `subscribeToCharacter`. Failures become `SubscriptionStreamException(operation: 'questUpdated', code)`, and a missing or malformed payload becomes a `FormatException`.
- **Repository:** `QuestBoardRepository.watchQuest(questId)` exposes that stream.
- **Cubit:** `QuestCubit.watchQuest(id)` keeps one private `StreamSubscription<Quest>`.
  - Calling it again with the same id does nothing. A different id cancels the old subscription and starts a new one.
  - Each Quest replaces the quest with the same id in `QuestLoaded`, or is appended if missing. `cityId` and `cityPointIds` are kept. Events that arrive while the list is not loaded are ignored.
  - On an error the cubit logs `Quest watch failed (<type>)`, keeps its state and forgets the watch.
  - `unwatchQuest()` cancels the subscription, and `close()` cancels it too.
- **Listener:** `PartyWatchListener` replaces `PartyWaitingRefreshListener` at the same place in `MainScreen`, and no longer needs `cities`.
  - It reacts when the awaited quest id changes, meaning the quest id of a lane in `isWaitingForParty`.
  - When there is an awaited quest it calls `watchQuest(id)`, otherwise it calls `unwatchQuest()`.
  - It also watches on mount when the lane is already waiting, and unwatches on dispose.
  - It never rereads the quest list.
- **Docs:** 06-CONTEXT D-15 is amended with the user decision quoted verbatim. STATE.md has the quick-task row, and the `feat/party-waiting` blocker note now says the schema check also needs `questUpdated`.

## Gates
- Full `flutter test`: 1778 passed, 0 failed (baseline 1755, +23).
- `flutter analyze`: 54 issues, all baseline, 0 errors.
- `dart format` was run only on the touched files, one by one.
- No `Co-Authored-By` or `Generated with` trailers. Every subject is 72 characters or fewer.

## Schema check status
- Deferred. `grep -c "questUpdated"` on the BE `src/schema.gql` returned 0, because BE plan 09-20 has not regenerated the schema yet. Once it has, the orchestrator should run `dart run tool/schema_check/dump_documents.dart <dir>` and then `validate_documents.js` against the BE schema. 34 documents are expected. The dumped `quests.graphql` is unchanged apart from whitespace.

## Deviations
- **[Rule 3 - Blocking] `main_screen_test.dart` updated.** It was not in the plan's file list, but its mount check read `PartyWaitingRefreshListener.cities`. It now asserts that one `PartyWatchListener` is mounted. This was part of the Task 2 RED commit, 6f709be.
- **[Rule 2 - Correctness] Watch on mount and unwatch on dispose.** A `BlocListener` does not fire for the initial state. Without this, a lane that was already waiting at cold start would never be watched. This is why the listener is a StatefulWidget. It reads `QuestCubit` eagerly in `initState`, because a lazy read in `dispose` raised "deactivated widget's ancestor" during the first GREEN run. Fixed before commit 073c39f.
- **[Rule 2] `_questFrom` guard** on the subscription payload, the same as `_characterFrom`. The plan only said `Quest.fromJson`.
- **Not changed:** `world_map._refreshPartyCount`, which rereads the list when a waiting paper is opened, stays as a resync fallback because world_map.dart was outside the plan's file list. It can go in a later cleanup once the live watch has been checked on a device.

## How to verify on the device (needs BE 09-20)
1. Device A accepts a boss, aid or enemy quest that needs 2 or more adventurers, and travels to the marker. The paper reads "In attesa del gruppo 1/N".
2. Device B accepts the same quest. On device A, k goes up straight away, while B is still travelling.
3. If B abandons, k goes back down. When the party is complete and on the marker, the lane starts, the label changes to the per-type label and the watch stops.

## Self-Check: PASSED

## Schema check (orchestratore, 2026-10-26)

Eseguito dall'orchestratore contro lo schema del branch BE `feat/09-combat-result-admin-outcomes` dopo il piano 09-20 (commit 4fa5208, `questUpdated` rigenerato dal boot reale): `dump_documents` = 34 documenti, `validate_documents.js` = 34/34 OK, exit 0. Da ripetere contro `origin/develop` del BE dopo il merge della PR #13.

