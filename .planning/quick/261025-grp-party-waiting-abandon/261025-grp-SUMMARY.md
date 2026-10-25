---
phase: quick-261025-grp
plan: 01
subsystem: quest
tags: [quest, map, party, abandon, push, settings]
requirements: [QUEST-07, QUEST-02]
requires:
  - BE Phase 9 plan 09-19 (PR #13): PendingQuest.arrivedAt, abandonQuest + QUEST_NOT_WAITING, push questCancelled
provides:
  - waiting-for-party label "In attesa del gruppo k/N"
  - abandon flow (sheet action, parchment confirmation, QuestAbandonCubit, domain notices)
  - NotificationCategory.questCancelled with its Settings toggle
affects: [map, quest sheet, settings, push, schema-check registry]
key-files:
  created:
    - lib/models/request/abandon_quest_request.dart
    - lib/repository/quest_abandon_failure.dart
    - lib/repository/quest_abandon_repository.dart
    - lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart
    - lib/screens/mainScreen/questAbandonCubit/quest_abandon_state.dart
    - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
    - lib/screens/mainScreen/components/quest_abandon_outcome_listener.dart
    - lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart
  modified:
    - lib/models/pending_quest.dart
    - lib/models/quest/quest_state_label.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/mutations/quest_mutations.dart
    - lib/repository/services/graphql/graphql.dart
    - lib/models/notification_category.dart
    - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
    - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart
    - lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart
    - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/shared/components/popup/quest_info_sheet.dart
    - lib/screens/auth/authenticated_shell.dart
    - tool/schema_check/schema_check_documents.dart
    - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
    - .planning/STATE.md
decisions:
  - questStateLabel takes the Quest (not the type) so the waiting label can count k/N from registeredAdventurers and totalSlots
  - QuestAbandonOutcomeListener wraps the shell body in authenticated_shell.dart (it only needs QuestAbandonCubit and InAppNotificationsCubit)
  - the map closes the quest sheet on QuestAbandoned by reversing the overlay animation; the dismissed status clears the quest and the abandon callback
  - the abandon notice title is "Gruppo non abbandonato" (provisional copy)
commits:
  - faea40f test(quest): waiting-for-party label and questCancelled category
  - b7360ac feat(quest): label a quest waiting for its party, add questCancelled
  - fbf901e test(quest): abandon a quest while waiting for the party
  - ea882b8 test(notifications): expect questCancelled in the stored preferences
  - 4633b3f feat(quest): let the player abandon a party they are waiting for
  - b04ef12 docs(quick): record the party-waiting label and abandon flow
completed: 2026-10-25
---

# Quick 261025-grp: party waiting and abandon Summary

A standard quest waiting for its party now reads "In attesa del gruppo k/N" on the Map. The sheet opened from the quest paper offers "Abbandona il gruppo", with a parchment confirmation before `abandonQuest`. The BE push `questCancelled` is now a personal notification category with its own Settings toggle.

## What changed
- **Model:** `PendingQuest.arrivedAt` (fromJson/toJson/copyWith/props), `isTravelling` (no startDate, no arrivedAt) and `isWaitingForParty` (no startDate, arrivedAt set).
- **Label:** `questStateLabel(lane, quest)`. A travelling lane reads 'In viaggio'. A waiting lane reads 'In attesa del gruppo k/N', with k = registered adventurers and N = `totalSlots(requiredAdventurers)`. The count is dropped when the quest is missing or has 0 seats. A started lane keeps its per-type label.
- **Fragment:** only `pendingQuest` selects `arrivedAt`. The GM lanes are unchanged.
- **Paper layer:** `onOpen(quest, lane)`. `world_map` computes the label and sets `onAbandon` only when `lane.isWaitingForParty`. A quest opened from a marker never gets it.
- **Abandon flow:**
  - `QuestMutations.abandonQuest` (selects `successful`), `AbandonQuestRequest`, and `KlimmeckGraphQl.abandonQuest` (FormatException when not successful).
  - `QuestAbandonFailure` and `questAbandonFailureFrom`, which reads `extensions.code` only.
  - `QuestAbandonRepository`, with a 15 s timeout that fails as `timedOut`.
  - `QuestAbandonCubit` (Idle/Abandoning/Abandoned/Failed, SafeEmit). A second call while one is in flight is ignored, and reset is guarded the same way.
  - `questAbandonNoticeFor`. forbidden and unauthenticated produce no notice.
  - `QuestAbandonOutcomeListener` in the shell, with dedupKey `quest-abandon|<failure>|<questId>`.
  - `QuestInfoSheet.onAbandon`: a TextButton keyed `questSheet.abandon`, blood-red, at least 44 px, with semantics.
  - `QuestInfoOverlay.onAbandon`.
  - `AbandonPartySheet`: keys `party.abandon` and `party.stay`. A PopScope blocks closing while the call is in flight, and the sheet closes itself on success or rejection.
  - `world_map._confirmAbandon` opens the confirmation the same way as the travel sheet: root navigator, PaperSheetModal, and drag-dismiss blocked while the call is in flight.
- **Push:** `NotificationCategory.questCancelled('quest_cancelled', 'questCancelled')` (personal), added to the defaults, with the Settings label 'Missione annullata'. The tap goes to the Map tab like the other personal categories. No popup registry entry, since the lane is already empty when the push arrives.
- **Registry:** `'AbandonQuest': QuestMutations.abandonQuest`, 33 documents. The `travel_documents_test` count went from 32 to 33.
- **Docs:** Phase 6 06-CONTEXT D-07 and D-15 amended in place. STATE gets the quick-task row and a blocker note about the stacked branch.

## Gates
- Full `flutter test`: 1734 passed, 0 failed (Phase 7 baseline 1671, +63).
- `flutter analyze`: 54 issues (52 info, 2 baseline warnings), 0 errors. Same as baseline.
- `dart format` was run only on the touched files, one by one.
- No `Co-Authored-By` or `Generated with` trailers. Every subject is 72 characters or fewer.

## Schema check status
- Deferred. `grep -c "abandonQuest"` on the BE `src/schema.gql` returned 0, and `arrivedAt` is also absent: BE plan 09-19 has not regenerated the schema yet. The orchestrator should run `dart run tool/schema_check/dump_documents.dart <dir>` and then `validate_documents.js` against the BE schema once it contains `abandonQuest` and `arrivedAt`. 33 documents are expected.

## Deviations
- **[Rule 1 - Bug] Store test not updated in Task 1.** Adding `questCancelled` broke two expectations in `test/repository/storage/notification_preferences_store_test.dart`, which the Task 1 test scope did not cover. Fixed in its own commit, ea882b8.
- **[Rule 3 - Blocking] Overflow in the confirmation buttons.** The AbandonPartySheet action row overflowed by 34 px in landscape, because "Abbandona" is longer than the travel sheet's "Parti". Each action is now Flexible with an `AutoSizeText` label (maxLines 1). Fixed before commit 4633b3f.
- **[Rule 3 - Blocking] Missing `.env` in the worktree.** `flutter test` would not build the asset bundle without it. Copied from the main tree as the orchestrator allowed. It is ignored by git, was never printed and never committed.
- **Formatter reflowed existing lines.** `dart format` on the touched files also reformatted lines that were already there in `world_map.dart` and `character_fragment.dart`, because the baseline is not formatter-clean. This was accepted under the rule "format only the touched files" (Boy Scout). There is no behaviour change.
- **Extra tests beyond the plan's file list:**
  - `test/models/request/abandon_quest_request_test.dart`
  - `test/repository/quest_abandon_failure_test.dart`
  - `test/repository/services/graphql/graphql_quest_abandon_test.dart`
  - `test/screens/mainScreen/questAbandonCubit/quest_abandon_notice_test.dart`
  - `test/screens/mainScreen/components/quest_abandon_outcome_listener_test.dart`
  - a world_map widget group, "abandon the waiting party", in `world_map_travel_test.dart`, reusing its harness and adding a QuestAbandonCubit provider. This replaces the optional pure helper `abandonActionFor`.
  - 'Missione annullata' assertions in the settings tests.

## How to verify on the device (needs BE 09-19)
1. Accept a boss, aid or enemy quest whose party is not full, and travel to the marker. The paper reads "In attesa del gruppo 1/N".
2. Tap the paper. The sheet shows the label and "Abbandona il gruppo". Tap it, and a parchment sheet with "Abbandona" and "Resta" appears. "Resta" closes it.
3. Tap "Abbandona". The sheet closes, the quest sheet slides away and the paper disappears when `characterUpdated` arrives.
4. If the party fills in the meantime, "Abbandona" shows the notice "La missione è già cominciata: non puoi più abbandonarla".
5. Settings shows the "Missione annullata" toggle. A disbanded party (24 h) arrives as a banner or system notification.

## Self-Check: PASSED
