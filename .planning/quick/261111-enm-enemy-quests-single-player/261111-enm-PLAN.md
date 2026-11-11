---
phase: quick-261111-enm
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/models/quest/quest_capacity.dart
  - lib/models/quest/quest_availability.dart
  - lib/models/quest/quest_sheet_details.dart
  - lib/models/quest/quest_state_label.dart
  - lib/models/pending_request/pending_request.dart
autonomous: true

must_haves:
  truths:
    - "An enemy quest is judged with one rank-free seat whatever seats the wire carries (title null or a rank, any count)"
    - "A character of rank >= minTitle can take an enemy quest nobody has taken; a lower rank sees it torn; everyone sees it torn once one player is registered"
    - "The sheet of an enemy quest draws no seats row and no party counter, only «Titolo minimo: …»"
    - "Boss quests keep their rank-exact seats, drawn as before"
  artifacts:
    - path: "lib/models/quest/quest_capacity.dart"
      contains: "questSlotsOf"
---

# Quick 261111-enm: enemy quests are single-player with a minimum rank (FE)

**Trigger (user, device UAT of 2026-11-11), verbatim:**

- «Non posso accettare né boss né enemy, il mio rango non va bene. Perché la enemy ha uno slot però? Le enemy non dovrebbero avere slot, possono essere prese solo dal giocatore e solo se il rango è adatto (più alto o uguale a quello richiesto)»

BE twin: `261111-enm` on the BE repo (`questSlotsOf(type, …)` → one wildcard seat for `enemy`; `boss` unchanged; refusal codes unchanged). On the wire an `enemy` quest still carries `requirements.requiredAdventurers` with one seat: `title: null` for new quests, possibly a rank for the quests generated before the fix. The FE must behave the same with both shapes.

## Today (read first)

- `lib/models/quest/quest_capacity.dart`: `totalSlots`, `isFullForEveryone`, `canRegisterWithTitle`, `isFullFor` work on the wire seats; a legend on a rookie seat is «full».
- `lib/models/quest/quest_availability.dart` `_isFullForViewer` feeds both `QuestAvailability.full` and the torn state (`_failsOwnRequirements`); `isTitleEligible` already gives rank >= `minTitle` for every non-story type.
- `lib/models/quest/quest_sheet_details.dart`: `slotLines` for every `registeredQuestTypes` member (enemy included); `requiredTitleText` already reads «Titolo minimo: …» for every quest with a `minTitle`.
- `lib/models/quest/quest_state_label.dart`: «In attesa del gruppo k/N» for every waiting lane with seats.
- `lib/models/pending_request/pending_request.dart`: `totalSeats` of the GM queue.

## Tasks

1. RED: `questSlotsOf` (both wire shapes, any count, every other type untouched); availability for a higher rank, full once one is registered, title mismatch for a lower rank, boss pin; Board torn state; sheet details and sheet widget without seats for enemy and with seats for boss; state label; GM queue seats. Titles carry `(quick 261111-enm)`.
2. GREEN: `isSinglePlayerQuest` + `questSlotsOf` in `quest_capacity.dart`; `_isFullForViewer`, `_seatsOf` / `_isSolo`, `PendingRequestQuest.totalSeats` read it; `slotLines` empty for a single-player quest. No new copy.
3. Gates: targeted tests, `flutter analyze --no-fatal-infos` 0 warning / 0 error, `sh tool/hardening_check.sh`, full suite.

## Out of scope

Fragments and wire models (the seat still travels), the catalogue-defect check on the raw wire seats (an enemy without valid seats stays not acceptable, as on the BE), boss rules, DB content.
