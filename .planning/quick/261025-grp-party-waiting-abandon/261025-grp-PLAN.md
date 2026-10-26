---
phase: quick-261025-grp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/pending_quest.dart
  - lib/models/quest/quest_state_label.dart
  - lib/graphql/fragments/character_fragment.dart
  - lib/graphql/mutations/quest_mutations.dart
  - lib/models/request/abandon_quest_request.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/quest_abandon_repository.dart
  - lib/repository/quest_abandon_failure.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_state.dart
  - lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart
  - lib/screens/mainScreen/components/quest_abandon_outcome_listener.dart
  - lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart
  - lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart
  - lib/screens/mainScreen/tabs/map/world_map.dart
  - lib/shared/components/popup/quest_info_sheet.dart
  - lib/screens/auth/authenticated_shell.dart
  - lib/models/notification_category.dart
  - lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart
  - lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart
  - tool/schema_check/schema_check_documents.dart
  - test/models/pending_quest_test.dart
  - test/models/quest/quest_state_label_test.dart
  - test/graphql/character_fragment_test.dart
  - test/repository/quest_abandon_repository_test.dart
  - test/screens/mainScreen/questAbandonCubit/quest_abandon_cubit_test.dart
  - test/screens/mainScreen/tabs/map/components/abandon_party_sheet_test.dart
  - test/screens/mainScreen/tabs/map/layers/quest_paper_layer_test.dart
  - test/shared/components/popup/quest_info_sheet_test.dart
  - test/models/notification_category_test.dart
  - test/models/push_event_test.dart
  - test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart
  - test/helpers/fixtures/quest_fixtures.dart
  - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
  - .planning/STATE.md
autonomous: true
requirements: [QUEST-07, QUEST-02]

must_haves:
  truths:
    - "A standard-lane pending quest with startDate null and arrivedAt set is labelled 'In attesa del gruppo k/N' (k = registered adventurers, N = total seats of the quest); startDate null and arrivedAt null still reads 'In viaggio'; a started quest keeps the per-type label"
    - "While waiting for the party (startDate null, arrivedAt set), the sheet opened from the quest paper on the Map offers 'Abbandona il gruppo'; a parchment confirmation sheet with 'Abbandona' / 'Resta' precedes the abandonQuest mutation; the sheet never appears for a started quest, a travelling one or a quest opened from a marker"
    - "abandonQuest success builds no state: the lane empties via characterUpdated and the Map closes the open sheet; a rejection becomes an in-app notice from the error code only (QUEST_NOT_WAITING, NOT_FOUND, FORBIDDEN, connection, timeout)"
    - "The push type questCancelled is a NotificationCategory (storage key quest_cancelled, personal, with id): it shows as banner/system notification, has a Settings toggle 'Missione annullata', and its tap lands on the Map tab like the other personal types"
    - "Every GraphQL document is registered in tool/schema_check (33 documents); the character fragment selects arrivedAt only on pendingQuest; flutter analyze has 0 errors and the full flutter test suite is green; dart format only on touched files"
  artifacts:
    - path: "lib/models/quest/quest_state_label.dart"
      provides: "questStateLabel(lane, quest) with the waiting label"
      contains: "In attesa del gruppo"
    - path: "lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart"
      provides: "parchment confirmation with Abbandona / Resta driven by QuestAbandonCubit"
      contains: "class AbandonPartySheet"
    - path: "lib/repository/quest_abandon_repository.dart"
      provides: "abandon({characterId, questId}) mapping every error to QuestAbandonException"
      contains: "class QuestAbandonRepository"
    - path: "lib/graphql/mutations/quest_mutations.dart"
      provides: "AbandonQuest mutation document"
      contains: "mutation AbandonQuest"
  key_links:
    - from: "lib/screens/mainScreen/tabs/map/world_map.dart"
      to: "lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart"
      via: "showModalBottomSheet(PaperSheetModal(child: AbandonPartySheet(...))) only when lane.isWaitingForParty"
      pattern: "AbandonPartySheet\\("
    - from: "lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart"
      to: "lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart"
      via: "context.read<QuestAbandonCubit>().abandon(...) on 'Abbandona'"
      pattern: "QuestAbandonCubit"
    - from: "tool/schema_check/schema_check_documents.dart"
      to: "lib/graphql/mutations/quest_mutations.dart"
      via: "'AbandonQuest': QuestMutations.abandonQuest"
      pattern: "QuestMutations\\.abandonQuest"
---

<objective>
Consume the BE Phase 9 rules decided by the user on 2026-10-25 (BE plan 09-19, PR #13): a registered standard quest (boss, aid, enemy) starts only when the party is complete and on the marker; until then every PendingQuest has `startDate: null` and `arrivedAt` set; whoever waits on the marker may abandon the quest (`abandonQuest(request: AbandonQuestRequest { id, questId }): CommonResponse!`, code `QUEST_NOT_WAITING` otherwise); a party not filled within 24 hours is disbanded for everyone with the data-only push `questCancelled` (`data.id` = quest id).

Today the FE labels every lane with `startDate == null` as "In viaggio" (Phase 6 D-15), has no abandon action and drops unknown push types. Output: waiting label with k/N, abandon flow (sheet action → parchment confirmation → mutation → notice on failure), `questCancelled` category, fragment and schema-check registry updated, Phase 6 D-15/D-07 amended, STATE quick-task row.

Design decisions (provisional copy, no UI phase): the waiting label is `In attesa del gruppo k/N` (compact on the paper, same string in the sheet); the abandon action is a text button under the state label of the opened sheet (Map only), confirmation on parchment like the Phase 7 travel sheet (ui-ux.md: "azioni distruttive (annulla quest) richiedono conferma", never `AlertDialog`); no undo. The `questCancelled` banner needs no popup: the lane is already empty when it arrives.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
Project root (WORKTREE): /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party — prefix EVERY shell command with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party &&`. Branch `feat/party-waiting` (created from `feat/07-travel`, stay on it; never checkout other branches, never touch /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide which hosts the user's device UAT). `flutter pub get` already ran. `.env` and `android/app/google-services.json` are absent in the worktree: tests must not need them; if a test fails only for a missing `.env`, copy it with `cp /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide/.env .env` and never print it.

Rules: CLAUDE.md, docs/rules/testing.md (TDD red first, bloc_test for cubits, widget tests with keys), docs/rules/state-management.md (sealed states named by domain, UI → Cubit → Repository, BlocListener for side effects), docs/rules/graphql.md (repositories map OperationException to domain failures by `extensions.code` only; mutations never build state from CommonResponse), docs/rules/ui-ux.md (no app chrome, parchment sheets, confirmation for destructive actions), docs/rules/workflow.md (Conventional Commits, subjects ≤ 72 chars, NO `Co-Authored-By`/`Generated with` trailers, stage explicit paths, no history rewriting). `dart format` ONLY on the files you touched (never on directories: the baseline is not formatter-clean). `flutter analyze` must report 0 errors (infos baseline ~54). Full `flutter test` at the end. No push, no PR.

BE contract (BE repo is READ-ONLY, path /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE; BE plan 09-19 may still be running while you work): `PendingQuest.arrivedAt: DateTime` nullable; `QuestRegistration.registeredAt: DateTime` nullable (not needed here); `abandonQuest(request: AbandonQuestRequest!): CommonResponse!` with `input AbandonQuestRequest { id: String!, questId: String! }`; errors as `extensions.code`: `QUEST_NOT_WAITING`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`; push `data.type = 'questCancelled'`, `data.id` = quest id, title 'Missione annullata'. Schema check: run `dart run tool/schema_check/dump_documents.dart <dir>` then `NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules node tool/schema_check/validate_documents.js /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql <dir>` ONLY IF `grep -c "abandonQuest" /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` is ≥ 1; otherwise skip it and write in the SUMMARY that the orchestrator runs it once the BE schema lands (do not fail the task for that).

<interfaces>
```dart
// lib/models/pending_quest.dart
final DateTime? arrivedAt; // arrivo sul marker (BE Phase 9, 09-19): startDate resta nullo finché il gruppo non è completo
bool get isTravelling => startDate == null && arrivedAt == null;
bool get isWaitingForParty => startDate == null && arrivedAt != null;

// lib/models/quest/quest_state_label.dart — signature change (the layer has the Quest)
String questStateLabel(PendingQuest lane, Quest? quest);
// started → per-type label as today (type = quest?.infos?.type); travelling → 'In viaggio';
// waiting → 'In attesa del gruppo $k/$n' with k = quest.registeredAdventurers.length, n = totalSlots(quest.requirements?.requiredAdventurers ?? const []) (lib/models/quest/quest_capacity.dart); n == 0 or quest == null → 'In attesa del gruppo'

// lib/graphql/fragments/character_fragment.dart — only the standard lane gains arrivedAt
//   pendingQuest { id startDate arrivedAt waitingTime pointsSpent quest { id } }   (GM lanes unchanged)

// lib/graphql/mutations/quest_mutations.dart
static const String abandonQuest = r''' mutation AbandonQuest($request: AbandonQuestRequest!) { abandonQuest(request: $request) { successful } } ''';
// lib/models/request/abandon_quest_request.dart — AbandonQuestRequest(id, questId) Equatable with toJson, mirror of AcceptQuestRequest
// lib/repository/services/graphql/graphql.dart — Future<void> abandonQuest(AbandonQuestRequest request): same shape as acceptQuest (FormatException when not successful)

// lib/repository/quest_abandon_failure.dart
const String questNotWaitingCode = 'QUEST_NOT_WAITING';
enum QuestAbandonFailure { notWaiting, notFound, forbidden, unauthenticated, connection, timedOut, unknown }
class QuestAbandonException implements Exception { final QuestAbandonFailure failure; }
QuestAbandonFailure questAbandonFailureFrom(OperationException exception); // extensions.code only, like questAcceptanceFailureFrom
// lib/repository/quest_abandon_repository.dart — QuestAbandonRepository({required KlimmeckGraphQl graphQl, Duration timeout = 15 s}); Future<void> abandon({required String characterId, required String questId})

// lib/screens/mainScreen/questAbandonCubit — QuestAbandonCubit(QuestAbandonRepository) with SafeEmit; states: QuestAbandonIdle, QuestAbandoning(questId), QuestAbandoned(questId), QuestAbandonFailed(questId, failure); abandon({characterId, questId}) ignores calls while QuestAbandoning; reset() like QuestAcceptanceCubit
// quest_abandon_notice.dart — KGNotification? questAbandonNoticeFor(QuestAbandonFailure): notWaiting 'La missione è già cominciata: non puoi più abbandonarla', notFound 'Non sei più in questa missione', forbidden/unauthenticated null (handled elsewhere), connection/timedOut/unknown 'Impossibile abbandonare ora, riprova'
// components/quest_abandon_outcome_listener.dart — BlocListener<QuestAbandonCubit>: on QuestAbandonFailed publishNotice(dedupKey 'quest-abandon|<failure>|<questId>') then reset(); on QuestAbandoned just reset()

// lib/shared/components/popup/quest_info_sheet.dart — new optional `VoidCallback? onAbandon`; when non-null renders a TextButton (key QuestInfoSheet.abandonKey = ValueKey('questSheet.abandon')) labelled 'Abbandona il gruppo' under the state label, styled with the parchment theme (no app chrome)
// lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart — new optional `VoidCallback? onAbandon` forwarded to QuestInfoSheet
// lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart — onOpen: void Function(Quest quest, PendingQuest lane) (the label is computed where needed with questStateLabel(lane, quest))
// lib/screens/mainScreen/tabs/map/world_map.dart — _openFromPaper(quest, lane): _selectedStateLabel = questStateLabel(lane, quest); _selectedOnAbandon = lane.isWaitingForParty ? () => _confirmAbandon(quest) : null; _confirmAbandon shows showModalBottomSheet(backgroundColor transparent, isScrollControlled, useSafeArea false, BlocProvider.value(context.read<QuestAbandonCubit>()) → PaperSheetModal(child: AbandonPartySheet(quest: quest, characterId: ...))) like the travel sheet; a BlocListener<QuestAbandonCubit> in the map closes the quest overlay (_questAnimationController.reverse(), _selectedQuest = null) on QuestAbandoned
// lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart — AbandonPartySheet({quest, characterId}): title = quest title, body 'Vuoi abbandonare il gruppo? Il tuo posto sarà liberato.', actions 'Abbandona' (key party.abandon → cubit.abandon) / 'Resta' (key party.stay → pop); PopScope canPop while not QuestAbandoning; closes itself on QuestAbandoned/QuestAbandonFailed (pattern of TravelConfirmationSheet)
// lib/screens/auth/authenticated_shell.dart — BlocProvider<QuestAbandonCubit>(create: (_) => QuestAbandonCubit(QuestAbandonRepository(graphQl: graphQl))) next to QuestAcceptanceCubit; QuestAbandonOutcomeListener wrapped like QuestAcceptanceOutcomeListener

// lib/models/notification_category.dart — questCancelled('quest_cancelled', 'questCancelled') appended after questEnd; isPersonal stays `this != streamerLive`
// settings: _labelOf(questCancelled) => 'Missione annullata'; NotificationPreferencesState.defaults gains the entry
// tool/schema_check/schema_check_documents.dart — 'AbandonQuest': QuestMutations.abandonQuest
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: arrivedAt, waiting label and the questCancelled category</name>
  <files>lib/models/pending_quest.dart, lib/models/quest/quest_state_label.dart, lib/graphql/fragments/character_fragment.dart, lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart, lib/screens/mainScreen/tabs/map/world_map.dart, lib/models/notification_category.dart, lib/screens/mainScreen/tabs/settings/components/notification_preferences_section.dart, lib/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_state.dart, test/models/pending_quest_test.dart, test/models/quest/quest_state_label_test.dart, test/graphql/character_fragment_test.dart, test/screens/mainScreen/tabs/map/layers/quest_paper_layer_test.dart, test/models/notification_category_test.dart, test/models/push_event_test.dart, test/screens/mainScreen/tabs/settings/notificationCubit/notification_preferences_cubit_test.dart, test/helpers/fixtures/quest_fixtures.dart</files>
  <read_first>
    - lib/models/pending_quest.dart, lib/models/quest/quest_state_label.dart (+ test), lib/models/quest/quest_capacity.dart (totalSlots), test/helpers/fixtures/quest_fixtures.dart (laneJson, quest fixtures with registeredAdventurers/requiredAdventurers)
    - lib/graphql/fragments/character_fragment.dart (+ test: the three lanes share one expectation today), lib/screens/mainScreen/tabs/map/layers/quest_paper_layer.dart (+ existing test, if any: `ls test/screens/mainScreen/tabs/map/layers/`), lib/screens/mainScreen/tabs/map/world_map.dart (_openFromPaper)
    - lib/models/notification_category.dart (+ test), lib/models/push_event.dart (+ test), settings section and preferences state (+ cubit test), lib/screens/mainScreen/components/notification_popup_registry.dart (no entry needed for questCancelled)
  </read_first>
  <behavior>
    - `PendingQuest.fromJson` reads `arrivedAt` (null when absent); `toJson`/`copyWith`/`props` include it; `isTravelling`/`isWaitingForParty` as in the interfaces; `laneJson` fixture gains an optional `arrivedAt`.
    - `questStateLabel(lane, quest)`: travelling → 'In viaggio' for every type; waiting with a boss quest of 3 seats and 2 registered → 'In attesa del gruppo 2/3'; waiting with no quest or no seats → 'In attesa del gruppo'; started → per-type labels as today (table of the existing test kept, now passing a Quest fixture of each type).
    - Fragment test: `pendingQuest { id startDate arrivedAt waitingTime pointsSpent quest { id } }`; the two GM lanes keep `{ id startDate waitingTime pointsSpent quest { id } }`.
    - Quest paper layer: the compact label under the paper shows the waiting text when the lane waits (widget test with CharacterCubit/QuestCubit fakes as the existing map layer tests do; if no test exists for the layer, create one following test/screens/mainScreen/tabs/map conventions); `onOpen` receives the lane.
    - `NotificationCategory.values` = [travelEnd, streamerLive, questEnd, questCancelled]; storage key 'quest_cancelled', wire type 'questCancelled', personal; `PushEvent.tryParse` of a `questCancelled` payload with `id` yields the category and the id; preferences defaults contain the new category (cubit test helper `loaded(...)` gains `questCancelled = true`); settings label 'Missione annullata'.
  </behavior>
  <action>
1. RED: tests above (new and updated) fail. Commit `test(quest): waiting-for-party label and questCancelled category` (≤ 72).
2. GREEN: model, label, fragment, paper layer + world_map (`_openFromPaper(quest, lane)` computes the label; the abandon callback stays null in this task), category + settings + defaults. `flutter analyze` 0 errors; `dart format` on touched files only; run `flutter test test/models test/graphql test/screens/mainScreen/tabs/map test/screens/mainScreen/tabs/settings`. Commit `feat(quest): label a quest waiting for its party, add questCancelled` (≤ 72).
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test test/models test/graphql test/screens/mainScreen/tabs/map test/screens/mainScreen/tabs/settings && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "arrivedAt" lib/graphql/fragments/character_fragment.dart && grep -q "In attesa del gruppo" lib/models/quest/quest_state_label.dart && grep -q "questCancelled" lib/models/notification_category.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "arrivedAt" lib/graphql/fragments/character_fragment.dart` = 1 (only the standard lane)
    - `grep -n "isWaitingForParty" lib/models/pending_quest.dart` ≥ 1
    - `grep -n "quest_cancelled" lib/models/notification_category.dart` = 1 line
  </acceptance_criteria>
  <done>The Map tells the player they are waiting for the party (and how many are in), and a disbanded party reaches them as a notification.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: abandon flow — repository, cubit, sheet action, parchment confirmation</name>
  <files>lib/graphql/mutations/quest_mutations.dart, lib/models/request/abandon_quest_request.dart, lib/repository/services/graphql/graphql.dart, lib/repository/quest_abandon_repository.dart, lib/repository/quest_abandon_failure.dart, lib/screens/mainScreen/questAbandonCubit/quest_abandon_cubit.dart, lib/screens/mainScreen/questAbandonCubit/quest_abandon_state.dart, lib/screens/mainScreen/questAbandonCubit/quest_abandon_notice.dart, lib/screens/mainScreen/components/quest_abandon_outcome_listener.dart, lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart, lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart, lib/screens/mainScreen/tabs/map/world_map.dart, lib/shared/components/popup/quest_info_sheet.dart, lib/screens/auth/authenticated_shell.dart, tool/schema_check/schema_check_documents.dart, test/repository/quest_abandon_repository_test.dart, test/screens/mainScreen/questAbandonCubit/quest_abandon_cubit_test.dart, test/screens/mainScreen/tabs/map/components/abandon_party_sheet_test.dart, test/shared/components/popup/quest_info_sheet_test.dart</files>
  <read_first>
    - lib/repository/quest_acceptance_repository.dart, lib/repository/quest_acceptance_failure.dart, lib/screens/mainScreen/questAcceptanceCubit/* (cubit, state, notice), lib/screens/mainScreen/components/quest_acceptance_outcome_listener.dart and their tests (`ls test/repository test/screens/mainScreen/questAcceptanceCubit`) — mirror them
    - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart (+ test) and world_map.dart `_showTravelConfirmation`/`PaperSheetModal` usage — the confirmation pattern (PopScope while in flight, self-closing on settle)
    - lib/shared/components/popup/quest_info_sheet.dart (+ test), lib/screens/mainScreen/tabs/map/layers/quest_info_overlay.dart, lib/screens/auth/authenticated_shell.dart (providers and outcome listeners)
    - tool/schema_check/schema_check_documents.dart (+ the document count asserted anywhere: `grep -rn "32" tool test/tool 2>/dev/null`)
  </read_first>
  <behavior>
    - Repository test (fake KlimmeckGraphQl as the acceptance repository test does): success completes; OperationException with code QUEST_NOT_WAITING → `QuestAbandonFailure.notWaiting`; NOT_FOUND → notFound; FORBIDDEN → forbidden; link exception → connection; timeout → timedOut; anything else → unknown.
    - Cubit (bloc_test): Idle → Abandoning → Abandoned on success; → Failed(failure) on QuestAbandonException; a second abandon while Abandoning is ignored; reset returns to Idle.
    - QuestInfoSheet: without `onAbandon` no button (key absent); with `onAbandon` the button is rendered and tapping it calls the callback.
    - AbandonPartySheet: shows quest title, body and the two actions; 'Resta' pops; 'Abbandona' calls `abandon(characterId, questId)` once; while Abandoning the sheet cannot be popped and the buttons are disabled; on Abandoned or Failed the sheet pops itself.
    - world_map: opening from the paper of a waiting lane passes `onAbandon`; from a marker (`_selectQuest`) or a started lane it passes null (widget test only if the existing world_map tests make it cheap; otherwise cover the decision with a pure helper `abandonActionFor(lane)` unit-tested).
    - Outcome listener: QuestAbandonFailed(notWaiting) publishes the notice with dedupKey 'quest-abandon|notWaiting|<questId>' and resets.
  </behavior>
  <action>
1. RED: tests above fail. Commit `test(quest): abandon a quest while waiting for the party` (≤ 72).
2. GREEN: mutation document + request model + `KlimmeckGraphQl.abandonQuest`; failure + repository; cubit + state + notice; outcome listener wired in `authenticated_shell.dart` next to the acceptance one; `QuestInfoSheet.onAbandon` + `QuestInfoOverlay.onAbandon`; `AbandonPartySheet`; world_map wiring (`_selectedOnAbandon`, `_confirmAbandon`, BlocListener closing the overlay on QuestAbandoned); schema-check registry entry (and the document count if asserted). `flutter analyze` 0 errors; `dart format` on touched files only; run `flutter test test/repository test/screens test/shared`. Commit `feat(quest): let the player abandon a party they are waiting for` (≤ 72).
3. Schema check: if the BE schema already contains `abandonQuest`, run dump + validate as described in the context and report the count (33 documents); otherwise note it for the orchestrator.
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test test/repository test/screens test/shared && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "mutation AbandonQuest" lib/graphql/mutations/quest_mutations.dart && grep -q "'AbandonQuest': QuestMutations.abandonQuest" tool/schema_check/schema_check_documents.dart && grep -q "class AbandonPartySheet" lib/screens/mainScreen/tabs/map/components/abandon_party_sheet.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -n "AbandonPartySheet(" lib/screens/mainScreen/tabs/map/world_map.dart` = 1 line; `grep -n "isWaitingForParty" lib/screens/mainScreen/tabs/map/world_map.dart` ≥ 1
    - `grep -n "QUEST_NOT_WAITING" lib/repository/quest_abandon_failure.dart` = 1 line
    - `grep -n "QuestAbandonCubit" lib/screens/auth/authenticated_shell.dart` ≥ 1
  </acceptance_criteria>
  <done>A waiting adventurer can leave the party with an explicit confirmation; rejections become domain notices.</done>
</task>

<task type="auto">
  <name>Task 3: gate, Phase 6 context amendment and bookkeeping</name>
  <files>.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md, .planning/STATE.md</files>
  <read_first>
    - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md D-07 and D-15 (the quick task 261022-qkx amended D-06 in place: same style), .planning/STATE.md "Quick Tasks Completed" table and the Phase 7 "Status:" line (do NOT change the Phase 7 lines)
  </read_first>
  <action>
1. Full gate: `flutter test` (whole suite, report the count vs the Phase 7 baseline 1671), `flutter analyze` (0 errors; infos count reported). Fix anything red inside this task (TDD applies to code changes).
2. 06-CONTEXT.md: D-15 → add «**Amended 2026-10-25 (quick 261025-grp, BE Phase 9 plan 09-19):** `startDate == null && arrivedAt == null` → "In viaggio"; `startDate == null && arrivedAt != null` → "In attesa del gruppo k/N" (k registered, N total seats): a registered quest starts only when the party is complete and on the marker (user decision 2026-10-25: "per poterle cominciare il party dev'essere al completo, quindi tutti restano in attesa").»; D-07 → add «**Amended 2026-10-25:** while the lane waits for the party the sheet opened from the paper offers "Abbandona il gruppo" with a parchment confirmation (`abandonQuest`); a party not filled within 24 hours is disbanded by the BE (push `questCancelled`, lane emptied via `characterUpdated`).»
3. STATE.md: append to "Quick Tasks Completed" the row `| 261025-grp | waiting-for-party label (k/N), abandonQuest with parchment confirmation, questCancelled push category (BE 09-19 contract; branch feat/party-waiting from feat/07-travel) | 2026-10-25 | <hash of the Task 2 GREEN commit> | [261025-grp-party-waiting-abandon](./quick/261025-grp-party-waiting-abandon/) |`; in "Open Questions / Blockers" add «**feat/party-waiting:** stacked on feat/07-travel; PR to develop only after the Phase 7 PR and the BE PR #13 merge (the schema check needs `abandonQuest`/`arrivedAt` in BE develop).» Edit tool or python3 UTF-8 only.
4. Commit `docs(quick): record the party-waiting label and abandon flow` (≤ 72). Then write `.planning/quick/261025-grp-party-waiting-abandon/261025-grp-SUMMARY.md` (frontmatter like 261022-qkx: phase, plan, requirements, commits list; sections What changed / Gates / Deviations / Schema check status) and commit `docs(quick): add 261025-grp summary` (≤ 72).
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "261025-grp" .planning/STATE.md && grep -q "In attesa del gruppo" .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md && test -f .planning/quick/261025-grp-party-waiting-abandon/261025-grp-SUMMARY.md && test -z "$(git status --short)"</automated>
  </verify>
  <acceptance_criteria>
    - `git log --format=%B feat/07-travel..HEAD | grep -c -E "Co-Authored-By|Generated with"` = 0
    - `git log --format=%s feat/07-travel..HEAD | awk 'length > 72' | wc -l` = 0
    - working tree clean, branch feat/party-waiting, no push
  </acceptance_criteria>
  <done>Everything green, documented and recorded; the branch waits for the two upstream merges.</done>
</task>

</tasks>

<verification>
- `flutter test` green (full suite), `flutter analyze` 0 errors
- schema check against the BE branch schema once it contains `abandonQuest` (executor if available, otherwise orchestrator)
- commits without trailers, subjects ≤ 72, tree clean, no push
</verification>

<success_criteria>
- Waiting label with k/N, abandon flow with confirmation and domain notices, `questCancelled` category with Settings toggle
- Fragment, registry, Phase 6 context and STATE updated
</success_criteria>

<output>
After completion, create `.planning/quick/261025-grp-party-waiting-abandon/261025-grp-SUMMARY.md`
</output>
