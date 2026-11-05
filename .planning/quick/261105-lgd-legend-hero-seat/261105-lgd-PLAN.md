---
phase: quick-261105-lgd
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/quest/quest_capacity.dart
  - test/models/quest/quest_capacity_test.dart
  - test/models/quest/quest_availability_test.dart
autonomous: true
requirements: [QUEST-ACCEPT-01]

must_haves:
  truths:
    - "A legend takes a free hero seat; the legend seats fill before the hero seats"
    - "A legend sitting on a hero seat counts before the wildcard seats"
    - "No other title scales onto a seat of another rank"
  artifacts:
    - path: "lib/models/quest/quest_capacity.dart"
      contains: "_foldedCountsOf"
    - path: "test/models/quest/quest_capacity_test.dart"
      contains: "legend on hero seats (BE 13.1 D-08)"
---

# Quick 261105-lgd: i legend sui posti hero

Regola del BE 13.1 D-08 (handoff `BACKEND-NOTES.md` §3 bis della fase BE): un personaggio `legend` occupa un posto `hero` dopo gli eventuali posti `legend`; nessun altro titolo scala; un legend su un posto hero si conta prima dei posti jolly. La FE specchia la regola dei posti a titolo esatto (BE Phase 8 D-32) in `canRegisterWithTitle`: senza l'aggiornamento nasconderebbe lo swipe di accettazione a un legend su una quest hero che il BE accetta.

## Task
1. RED `test/models/quest/quest_capacity_test.dart`: i quattro casi del BE (`lets a legend take a hero seat`, `fills the legend seats before the hero seats`, `counts a legend on a hero seat before the wildcards`, `scales no other title`); `quest_availability_test.dart`: un legend vede `available` su un boss con un posto hero, un hero vede `full` quando quel posto è preso da un legend.
2. GREEN `quest_capacity.dart`: conteggi ripiegati (i legend oltre i posti legend contano sui posti hero) e posto proprio del titolo (legend → hero a posti legend esauriti), come `foldedCountsOf`/`seatTitleOf` del BE.
3. Gate: test dei modelli, `flutter analyze` alla baseline, `dart format` sui soli file toccati.
