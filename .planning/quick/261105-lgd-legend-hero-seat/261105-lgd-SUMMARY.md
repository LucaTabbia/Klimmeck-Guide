---
phase: quick-261105-lgd
plan: 01
subsystem: quests
tags: [quest, capacity, legend, acceptance]
requirements: [QUEST-ACCEPT-01]
key-files:
  modified:
    - lib/models/quest/quest_capacity.dart
    - test/models/quest/quest_capacity_test.dart
    - test/models/quest/quest_availability_test.dart
commits:
  - { message: "test(quest): expect a legend on the hero seats (BE 13.1 D-08)" }
  - { message: "feat(quest): fold the extra legends onto the hero seats (BE 13.1 D-08)" }
---

# Quick 261105-lgd: i legend sui posti hero

`canRegisterWithTitle` specchia la regola BE 13.1 D-08: i legend oltre i posti `legend` contano sui posti `hero` (conteggi ripiegati) e un legend chiede un posto hero quando i posti legend sono esauriti; l'overflow verso i jolly si calcola sui conteggi ripiegati, così un legend su un posto hero si conta prima dei jolly. Nessun altro titolo scala. `isFullFor`, lo stato `full` e il foglio strappato seguono senza modifiche.

## Modifiche
- `quest_capacity.dart`: `_foldedCountsOf` e `_seatTitleOf` (specchio di `foldedCountsOf`/`seatTitleOf` di `src/quests/acceptance/quest-capacity.ts` del BE), `canRegisterWithTitle` li usa; `min` importato da `dart:math`.
- Test: gruppo «legend on hero seats (BE 13.1 D-08)» con i quattro casi del BE (RED confermato su tre: `Expected: true, Actual: false`; `scales no other title` verde al primo colpo perché il codice vecchio non scalava nessun titolo, tenuto come guardia); `quest_availability_test.dart`: «a legend takes the hero seat of a boss» (RED: `full` invece di `available`).

## Gate
- `flutter test test/models test/screens/mainScreen`: 1482 verdi.
- `flutter analyze`: 50 info, 0 errori, 0 warning (baseline di develop: 50 info).
- `dart format` sui 3 file toccati.

## Deviazioni
Nessuna.
