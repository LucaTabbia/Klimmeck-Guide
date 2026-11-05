---
phase: quick-261105-scp
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/screens/mainScreen/components/quest_scope_listener.dart
  - lib/screens/mainScreen/main_screen.dart
  - test/screens/mainScreen/components/quest_scope_listener_test.dart
  - test/screens/mainScreen/main_screen_test.dart
  - .planning/phases/14-quest-generation/BACKEND-NOTES.md
autonomous: true
requirements: [QUEST-BOARD-01]

must_haves:
  truths:
    - "When characterUpdated changes status.location, status.title or a lane's quest the quest list is reread in silence with the current city"
    - "Mounting, an unrelated character change or a lane that keeps its quest do not reread"
    - "The listener sits in the MainScreen session chain"
  artifacts:
    - path: "lib/screens/mainScreen/components/quest_scope_listener.dart"
      contains: "class QuestScopeListener"
    - path: "lib/screens/mainScreen/main_screen.dart"
      contains: "QuestScopeListener("
---

# Quick 261105-scp: rilettura delle quest al cambio di area

Dal BE 13.1 (D-05) la query `quests` restituisce solo le quest dell'area del personaggio corrente, le `story` del suo titolo e le quest delle sue corsie. All'arrivo di un viaggio la Mappa rileggeva solo il personaggio: i segnalini restavano quelli dell'area di partenza finché non si apriva il Tabellone. Il handoff della fase BE (§2) chiede di rileggere `quests` quando `characterUpdated` cambia `status.location`, `status.title` o una delle tre corsie.

## Task
1. RED `test/screens/mainScreen/components/quest_scope_listener_test.dart` (harness di `party_watch_listener_test.dart`): arrivo in un'altra città ⇒ `refreshQuests(cityId: <città>)`; uscita dalla città ⇒ `cityId: null`; nuovo titolo ⇒ rilettura; corsia che si riempie, si svuota o passa ad altra quest ⇒ rilettura; montaggio, corsia che tiene la stessa quest, cambio estraneo (quest completate) e stato non caricato ⇒ nessuna rilettura. `main_screen_test.dart`: il listener sta nella catena della sessione.
2. GREEN `QuestScopeListener` (`BlocListener<CharacterCubit>` con `listenWhen` su un record di posizione, titolo e id delle quest in corsia; rilettura silenziosa via `QuestCubit.refreshQuests` con `currentCityOf`), montato in `MainScreen` sotto `QuestAcceptanceOutcomeListener`.
3. Docs: nota nel handoff FE Phase 14 (`quests` per area dal BE 13.1, filtro FE ridondante ma mantenuto).
4. Gate: test di `test/screens/mainScreen` e `test/models`, `flutter analyze` alla baseline, `dart format` sui soli file toccati.
