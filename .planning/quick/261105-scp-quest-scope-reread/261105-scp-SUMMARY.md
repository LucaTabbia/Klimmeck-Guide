---
phase: quick-261105-scp
plan: 01
subsystem: board
tags: [quests, board, map, characterUpdated, reread]
requirements: [QUEST-BOARD-01]
key-files:
  created:
    - lib/screens/mainScreen/components/quest_scope_listener.dart
    - test/screens/mainScreen/components/quest_scope_listener_test.dart
  modified:
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/main_screen_test.dart
    - .planning/phases/14-quest-generation/BACKEND-NOTES.md
commits:
  - { message: "test(board): expect a quest reread when the viewer scope changes" }
  - { message: "feat(board): reread the quests when the viewer scope changes" }
---

# Quick 261105-scp: rilettura delle quest al cambio di area

`QuestScopeListener` ascolta `CharacterCubit` e, quando fra due `CharacterLoaded` cambiano posizione, titolo o l'id della quest di una delle tre corsie, rilegge la lista con `QuestCubit.refreshQuests(cityId: currentCityOf(...))`: nessun loading (regola 2), l'ultima rilettura vince, i dati precedenti restano su errore. Montato in `MainScreen` sotto `QuestAcceptanceOutcomeListener`, sopra `PartyWatchListener`.

## Modifiche
- `quest_scope_listener.dart` (nuovo): record `_QuestScope` (posizione, titolo, id delle quest in corsia) confrontato in `listenWhen`; nessuna rilettura al montaggio, su stati non caricati, su campi estranei o su una corsia che tiene la stessa quest (i tick di viaggio non rileggono).
- `main_screen.dart`: il listener nella catena della sessione.
- Test: 9 casi del listener (RED per compilazione: file assente), 1 caso in `main_screen_test.dart` (RED per compilazione).
- Handoff FE Phase 14 `BACKEND-NOTES.md` §3: `quests` è per area dal BE 13.1; il filtro client resta come difesa.

## Note
- All'accettazione rileggono sia `QuestAcceptanceOutcomeListener` (esito della mutation) sia questo listener (corsia nuova su `characterUpdated`): due letture, l'ultima vince; tenuta la prima perché copre anche i rifiuti che rendono stantia la lista.
- Il viaggio verso un'altra città: `_claimArrivalReread` della Mappa rilegge il personaggio, il nuovo `status.location` passa da qui e i segnalini cambiano senza aprire il Tabellone.

## Gate
- `flutter test test/screens/mainScreen test/models`: 1482 verdi.
- `flutter analyze`: 50 info, 0 errori, 0 warning (baseline di develop: 50 info).
- `dart format` sui 4 file Dart toccati.

## Deviazioni
Nessuna.
