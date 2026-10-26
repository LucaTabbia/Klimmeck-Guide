---
phase: quick-261026-prt
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/graphql/fragments/quest_fragment.dart
  - lib/graphql/fragments/fragments.dart
  - lib/graphql/queries/quest_queries.dart
  - lib/graphql/subscriptions/quest_subscriptions.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/repository/quest_board_repository.dart
  - lib/screens/mainScreen/questCubit/quest_cubit.dart
  - lib/screens/mainScreen/components/party_waiting_refresh_listener.dart
  - lib/screens/mainScreen/main_screen.dart
  - tool/schema_check/schema_check_documents.dart
  - test/graphql/quest_documents_test.dart
  - test/graphql/travel_documents_test.dart
  - test/repository/services/graphql/graphql_quest_subscription_test.dart
  - test/screens/mainScreen/questCubit/quest_cubit_test.dart
  - test/screens/mainScreen/components/party_watch_listener_test.dart
  - .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md
  - .planning/STATE.md
autonomous: true
requirements: [QUEST-07]

must_haves:
  truths:
    - "While the standard lane waits for the party, the app subscribes to questUpdated(questId) and the quest in QuestCubit's list is replaced by every emitted Quest (snapshot first, then one event per acceptance/abandon/disband/start), so 'In attesa del gruppo k/N' changes the moment someone accepts; when the lane starts or empties the subscription is cancelled"
    - "The subscription document selects the same quest fields as the quests query through one shared QuestFragment; the schema-check registry has 34 documents; the quests list is no longer reread for the counter"
    - "A stream error never breaks the board: the cubit keeps its state and logs; closing the cubit cancels the subscription; flutter analyze has 0 errors and the full flutter test suite is green"
  artifacts:
    - path: "lib/graphql/subscriptions/quest_subscriptions.dart"
      provides: "OnQuestUpdated subscription document"
      contains: "questUpdated(questId: \\$questId)"
    - path: "lib/screens/mainScreen/questCubit/quest_cubit.dart"
      provides: "watchQuest(questId) / unwatchQuest()"
      contains: "watchQuest"
  key_links:
    - from: "lib/screens/mainScreen/components/party_waiting_refresh_listener.dart"
      to: "lib/screens/mainScreen/questCubit/quest_cubit.dart"
      via: "watchQuest on entering the waiting state, unwatchQuest on leaving it"
      pattern: "watchQuest\\("
    - from: "tool/schema_check/schema_check_documents.dart"
      to: "lib/graphql/subscriptions/quest_subscriptions.dart"
      via: "'OnQuestUpdated': QuestSubscriptions.questUpdated"
      pattern: "QuestSubscriptions\\.questUpdated"
---

<objective>
User decision of 2026-10-26 (verbatim): "il counter degli avventurieri mancanti deve aggiornarsi nel momento in cui qualcuno accetta la missione, non quando arriva sul marker." The BE (Phase 9 plan 09-20, running in parallel) adds `questUpdated(questId: String!): Quest!` to `type Subscription`: a snapshot of the quest on subscribe, then one event with the populated `Quest` on every update of the document (registration, abandon, disband, start, freed seat); a concluded or unknown quest answers `NOT_FOUND`; no auth beyond the bearer.

Today (quick 261025-grp) the k/N counter reads `registeredAdventurers` from the quests list and `PartyWaitingRefreshListener` rereads the list once when the lane enters the waiting state. Replace that with a live subscription: the cubit watches the quest while the lane waits and stops when it leaves. k = registered adventurers (acceptances), N = total seats — unchanged.

Design: `QuestFragment.fields` extracted from `QuestQueries.getAllQuests` and reused by the subscription (one selection, one parser); `KlimmeckGraphQl.subscribeToQuest(id)` mirrors `subscribeToCharacter`; `QuestBoardRepository.watchQuest(id)` exposes the stream; `QuestCubit.watchQuest/unwatchQuest` keep a single `StreamSubscription` (idempotent for the same id, replaced for a new id, cancelled in `close()`), each `Quest` replaces the one with the same id in `QuestLoaded.quests` (or is appended if absent); errors are logged with `debugPrint` and the state is kept; `PartyWaitingRefreshListener` becomes `PartyWatchListener` (same mount point in `MainScreen`): entering waiting ⇒ `watchQuest(lane.quest.id)`, leaving waiting (started, emptied, other quest) ⇒ `unwatchQuest()`; no list refresh anymore.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
Project root (WORKTREE): /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party — prefix EVERY shell command with `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party &&`. Branch `feat/party-waiting` (HEAD bbb1dd2, stay on it; never touch /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide, the user's device-UAT tree). `.env` is already in the worktree (ignored, never print it). Previous quick task on this branch: `.planning/quick/261025-grp-party-waiting-abandon/` (PLAN, SUMMARY, REVIEW, REVIEW-FIX) — read its SUMMARY and REVIEW-FIX (WR-02) first.

Rules: CLAUDE.md, docs/rules/testing.md, docs/rules/state-management.md (subscription kept as a private field, cancelled in close()), docs/rules/graphql.md (streams map failures the way `subscribeToCharacter` does; never OperationException to the UI), docs/rules/naming.md, docs/rules/workflow.md (Conventional Commits, subjects ≤ 72, NO `Co-Authored-By`/`Generated with` trailers). `dart format` ONLY on touched files, never directories. `flutter analyze` 0 errors (baseline 54 issues). Full `flutter test` at the end (now 1755). No push, no PR.

Schema check: run `dart run tool/schema_check/dump_documents.dart <dir>` then `NODE_PATH=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/node_modules node tool/schema_check/validate_documents.js /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql <dir>` ONLY IF `grep -c "questUpdated" /Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql` ≥ 1; otherwise note it for the orchestrator (do not fail). The BE repo is READ-ONLY.

<interfaces>
```dart
// lib/graphql/fragments/quest_fragment.dart — static const/get String fields = the selection currently inline in QuestQueries.getAllQuests (from `id` to the end of `prizes`), unchanged; getAllQuests becomes 'query quests { quests { ${QuestFragment.fields} } }' (same document text modulo whitespace: the dumped quests.graphql must still validate)
// lib/graphql/subscriptions/quest_subscriptions.dart
class QuestSubscriptions { static String get questUpdated => r'''subscription OnQuestUpdated($questId: String!) { questUpdated(questId: $questId) { ''' + QuestFragment.fields + ''' } }'''; } // keep the $ unescaped the way character_subscriptions.dart does
// lib/repository/services/graphql/graphql.dart — Stream<Quest> subscribeToQuest(String questId): performSubscription(QuestSubscriptions.questUpdated, variables: {'questId': questId}).map(...) with _throwIfStreamFailed(result, operation: 'questUpdated') and Quest.fromJson(result.data?['questUpdated'])
// lib/repository/quest_board_repository.dart — Stream<Quest> watchQuest(String questId) => _graphQl.subscribeToQuest(questId)
// lib/screens/mainScreen/questCubit/quest_cubit.dart
void watchQuest(String questId); // same id already watched ⇒ no-op; different id ⇒ cancel and resubscribe; each Quest ⇒ emit QuestLoaded with the quest replaced (by id) or appended, cityId/cityPointIds kept; stream error ⇒ debugPrint('Quest watch failed (<runtimeType>)'), state kept, subscription dropped
void unwatchQuest(); // cancels and forgets
// close() cancels the subscription
// lib/screens/mainScreen/components/party_watch_listener.dart (rename of party_waiting_refresh_listener.dart) — BlocListener<CharacterCubit>: listenWhen on a change of (isWaitingForParty, lane.quest?.id); listener: waiting && id != null ⇒ watchQuest(id), otherwise unwatchQuest(); `cities` no longer needed
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: shared quest fragment, questUpdated document, service and repository streams</name>
  <files>lib/graphql/fragments/quest_fragment.dart, lib/graphql/fragments/fragments.dart, lib/graphql/queries/quest_queries.dart, lib/graphql/subscriptions/quest_subscriptions.dart, lib/repository/services/graphql/graphql.dart, lib/repository/quest_board_repository.dart, tool/schema_check/schema_check_documents.dart, test/graphql/quest_documents_test.dart, test/graphql/travel_documents_test.dart, test/repository/services/graphql/graphql_quest_subscription_test.dart</files>
  <read_first>
    - lib/graphql/queries/quest_queries.dart, lib/graphql/fragments/fragments.dart (barrel), lib/graphql/subscriptions/character_subscriptions.dart, lib/repository/services/graphql/graphql.dart (`performSubscription`, `subscribeToCharacter`, `_throwIfStreamFailed`), lib/repository/quest_board_repository.dart, tool/schema_check/schema_check_documents.dart, test/graphql/travel_documents_test.dart (33-document assertion), existing graphql service tests for subscriptions (`grep -rln "subscribeToCharacter" test`)
  </read_first>
  <behavior>
    - `quest_documents_test.dart`: `QuestQueries.getAllQuests` and `QuestSubscriptions.questUpdated` parse as single operations (`gql` parser), the subscription selects `registeredAdventurers { character title }` and `requirements { requiredAdventurers { title count } }`, both use `QuestFragment.fields`; the registry has 34 documents including `'OnQuestUpdated'`.
    - `graphql_quest_subscription_test.dart`: with a fake client/link as the character subscription test does, `subscribeToQuest('q-1')` maps a `questUpdated` payload to a `Quest`, forwards errors as the character stream does.
    - Repository: `watchQuest` returns the service stream (trivial, tested through the cubit).
  </behavior>
  <action>
1. RED: tests above fail. Commit `test(quest): questUpdated document and stream` (≤ 72).
2. GREEN: fragment extraction + barrel export, subscription document, service and repository methods, registry entry. `flutter analyze` 0 errors; `dart format` on touched files only; `flutter test test/graphql test/repository`. Commit `feat(quest): subscribe to questUpdated through a shared fragment` (≤ 72).
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test test/graphql test/repository && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "'OnQuestUpdated': QuestSubscriptions.questUpdated" tool/schema_check/schema_check_documents.dart && grep -q "QuestFragment.fields" lib/graphql/queries/quest_queries.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -c "QuestFragment.fields" lib/graphql/queries/quest_queries.dart lib/graphql/subscriptions/quest_subscriptions.dart` = 1 each
    - `grep -n "subscribeToQuest" lib/repository/services/graphql/graphql.dart` ≥ 1
  </acceptance_criteria>
  <done>The app can listen to one quest over the wire with the same shape it lists.</done>
</task>

<task type="auto" tdd="true">
  <name>Task 2: QuestCubit.watchQuest and the party watch listener</name>
  <files>lib/screens/mainScreen/questCubit/quest_cubit.dart, lib/screens/mainScreen/components/party_waiting_refresh_listener.dart, lib/screens/mainScreen/main_screen.dart, test/screens/mainScreen/questCubit/quest_cubit_test.dart, test/screens/mainScreen/components/party_watch_listener_test.dart</files>
  <read_first>
    - lib/screens/mainScreen/questCubit/quest_cubit.dart (+ existing test), lib/screens/mainScreen/components/party_waiting_refresh_listener.dart (+ its test from 261025-grp: `ls test/screens/mainScreen/components/`), lib/screens/mainScreen/main_screen.dart (mount point), lib/screens/mainScreen/characterCubit (CharacterLoaded shape), test helpers/fixtures for quests and lanes
  </read_first>
  <behavior>
    - Cubit (bloc_test with a fake repository exposing a `StreamController<Quest>`): `watchQuest('q-1')` on a `QuestLoaded` with quests [q-1(k=1), q-2] ⇒ an emitted quest q-1(k=2) replaces it ⇒ `QuestLoaded([q-1(k=2), q-2])` with cityId/cityPointIds kept; an emitted quest not in the list is appended; `watchQuest('q-1')` twice ⇒ one subscription; `watchQuest('q-2')` after `q-1` ⇒ the first is cancelled; `unwatchQuest()` cancels (no more emissions); `close()` cancels; a stream error keeps the state and logs; an event while the state is not `QuestLoaded` is ignored.
    - Listener (widget test with CharacterCubit/QuestCubit fakes or mocks): lane enters waiting with quest id ⇒ `watchQuest(id)` once; lane starts (`startDate` set) ⇒ `unwatchQuest()`; lane emptied ⇒ `unwatchQuest()`; same waiting state re-emitted ⇒ no second call; no `refreshQuests` call anymore.
  </behavior>
  <action>
1. RED: tests fail. Commit `test(quest): watch the awaited party quest over the wire` (≤ 72).
2. GREEN: cubit methods, listener renamed to `PartyWatchListener` (file `party_watch_listener.dart`, old file removed, old test removed or rewritten), mount in `main_screen.dart` without `cities`. `flutter analyze` 0 errors; `dart format` on touched files; `flutter test test/screens/mainScreen`. Commit `feat(quest): update the party counter live from questUpdated` (≤ 72).
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test test/screens/mainScreen && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "watchQuest" lib/screens/mainScreen/questCubit/quest_cubit.dart && test ! -f lib/screens/mainScreen/components/party_waiting_refresh_listener.dart && grep -q "PartyWatchListener" lib/screens/mainScreen/main_screen.dart</automated>
  </verify>
  <acceptance_criteria>
    - `grep -rn "refreshQuests" lib/screens/mainScreen/components/party_watch_listener.dart` vuoto
    - `grep -n "StreamSubscription" lib/screens/mainScreen/questCubit/quest_cubit.dart` ≥ 1 and `close()` cancels it
  </acceptance_criteria>
  <done>The counter moves the moment another adventurer accepts.</done>
</task>

<task type="auto">
  <name>Task 3: gate, context amendment, bookkeeping, schema check</name>
  <files>.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md, .planning/STATE.md</files>
  <read_first>
    - 06-CONTEXT.md D-15 (amended by 261025-grp), STATE.md "Quick Tasks Completed" table and the `feat/party-waiting` blocker note
  </read_first>
  <action>
1. Full gate: `flutter test` (report the count vs 1755), `flutter analyze` (0 errors). Schema check as described in the context if the BE schema already has `questUpdated` (34 documents expected); otherwise note it.
2. 06-CONTEXT.md D-15: append «**Amended 2026-10-26 (quick 261026-prt):** the k/N counter follows the acceptances in real time through `questUpdated(questId)` (BE 09-20) while the lane waits for the party (user: "il counter degli avventurieri mancanti deve aggiornarsi nel momento in cui qualcuno accetta la missione, non quando arriva sul marker").»
3. STATE.md: quick-task row `| 261026-prt | live party counter: questUpdated subscription watched while the lane waits for the party (BE 09-20) | 2026-10-26 | <hash of the Task 2 GREEN commit> | [261026-prt-party-counter-live](./quick/261026-prt-party-counter-live/) |`; the `feat/party-waiting` blocker note mentions that the schema check now needs `questUpdated` too.
4. Commit `docs(quick): record the live party counter` (≤ 72). Then `261026-prt-SUMMARY.md` (same format as 261025-grp-SUMMARY.md) and commit `docs(quick): add 261026-prt summary`.
  </action>
  <verify>
    <automated>cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide-party && flutter test && flutter analyze 2>&1 | grep -c "error •" | grep -q "^0$" && grep -q "261026-prt" .planning/STATE.md && grep -q "questUpdated" .planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md && test -f .planning/quick/261026-prt-party-counter-live/261026-prt-SUMMARY.md && test -z "$(git status --short)"</automated>
  </verify>
  <acceptance_criteria>
    - `git log --format=%B bbb1dd2..HEAD | grep -c -E "Co-Authored-By|Generated with"` = 0; `git log --format=%s bbb1dd2..HEAD | awk 'length > 72' | wc -l` = 0
    - working tree clean, branch feat/party-waiting, no push
  </acceptance_criteria>
  <done>Everything green and recorded; the branch still waits for the upstream merges.</done>
</task>

</tasks>

<verification>
- `flutter test` green, `flutter analyze` 0 errors; schema check 34/34 once the BE schema has `questUpdated` (executor if available, otherwise orchestrator)
- commits without trailers, subjects ≤ 72, tree clean, no push
</verification>

<success_criteria>
- Live k/N via `questUpdated` while waiting; shared quest fragment; registry at 34; context and STATE updated
</success_criteria>

<output>
After completion, create `.planning/quick/261026-prt-party-counter-live/261026-prt-SUMMARY.md`
</output>
