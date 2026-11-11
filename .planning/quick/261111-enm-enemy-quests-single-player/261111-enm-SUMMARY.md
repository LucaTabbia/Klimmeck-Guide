---
quick: 261111-enm
title: Enemy quests are single-player with a minimum rank
date: 2026-11-11
branch: feat/19-model-review
commits: [a29360bd, 169daeda]
status: complete
---

# Quick task 261111-enm — enemy quests are single-player

**Trigger (user, device UAT of 2026-11-11), verbatim:**

- «Non posso accettare né boss né enemy, il mio rango non va bene. Perché la enemy ha uno slot però? Le enemy non dovrebbero avere slot, possono essere prese solo dal giocatore e solo se il rango è adatto (più alto o uguale a quello richiesto)»

BE twin: `261111-enm` on the BE repo (not touched from here).

## Where the rule lives

`lib/models/quest/quest_capacity.dart`:

```dart
bool isSinglePlayerQuest(QuestType? type) => type == QuestType.enemy;

List<AdventurerSlot> questSlotsOf(
  QuestType? type,
  List<AdventurerSlot> wireSlots,
) => isSinglePlayerQuest(type) ? _soloSlots : wireSlots;
```

`_soloSlots` is one seat `{ title: null, count: 1 }`. For an `enemy` the title and the number of the wire seats are ignored (mirror of the BE `questSlotsOf`); every other type is judged with its wire seats.

Readers (no path reads the wire seats of an enemy for capacity any more):

- `quest_availability.dart` `_isFullForViewer` → `QuestAvailability.full` and the torn state (`_failsOwnRequirements`), so the Board and the quest sheet (`QuestSheetDetails.of` → `standingOf`) agree. A legend takes a rookie «Minaccia»; once one player is registered every rank sees it full and torn.
- `quest_state_label.dart` `_isSolo` / `_seatsOf` → an enemy lane on the marker reads «In combattimento…», never «In attesa del gruppo k/N».
- `pending_request.dart` `PendingRequestQuest.totalSeats` → one seat for an enemy in the GM queue.
- `quest_sheet_details.dart` `_drawsSeats` → `slotLines` empty for a single-player quest.

The minimum rank is unchanged and stays a display / pre-check (the backend decides): `isTitleEligible` (rank >= `minTitle`, exact only for `story`). A rookie still sees a paladin «Minaccia» as `titleMismatch`, torn, with the reason «Serve almeno il titolo Paladino».

Not changed on purpose: `_isCatalogueDefect` still reads the raw wire seats (an enemy with an empty rank-shape list stays not acceptable, as on the BE); fragments and wire models (the seat still travels); `boss` (rank-exact seats, legends falling on hero seats).

## What the sheet of an enemy quest shows now

No seats row («Recluta: 0 / 1» / «Qualsiasi rango: 0 / 1» gone) and no party counter. The rank is the existing line of every min-title quest, the same a `hunt` shows: **«Titolo minimo: <rango>»** (e.g. «Titolo minimo: Paladino»), red when the viewer is below it. No new copy.

## Pinned tests updated (GREEN commit)

- `test/screens/mainScreen/tabs/map/quest_paper_layer_test.dart` and `world_map_travel_test.dart` («the open sheet counts the party from the current list»): the fixture of the waiting party was a three-seat `enemy`; it is now a `boss` (same assertions, «In attesa del gruppo 2/3»). Found by the post-GREEN run, not RED-first.

## New tests (23, all titled `(quick 261111-enm)`)

- `quest_capacity_test.dart` (5): one rank-free seat on both wire shapes; count ignored (and empty list); every other type and `null` keep the wire seats; a legend takes the rookie seat of an enemy, never of a boss; full for every rank once one is registered.
- `quest_availability_test.dart` (7): legend on a rookie enemy available and whole (both shapes); full and torn for every rank once taken (both shapes); rookie on a paladin enemy `titleMismatch` torn; hand-written three-seat enemy full after one; boss pin (legend never takes a paladin seat, a paladin does).
- `quest_sheet_details_test.dart` (3), `quest_info_sheet_test.dart` (2): no seats for enemy on both shapes with «Titolo minimo: Paladino»; boss still «Paladino: 1 / 2» / «Paladino: 0 / 2».
- `quest_state_label_test.dart` (2), `pending_request_test.dart` (2), `board_test.dart` (2: enemy whole for a higher rank on both shapes, torn above the rank, torn once taken; boss with a seat of another rank still torn).

## TDD

- RED `a29360bd`: `Method not found: 'questSlotsOf'` (capacity file) plus 7 failing tests in the other six files; the title-mismatch, already-rank-free and boss cases were green in RED (non-regression guards).
- GREEN `169daeda`.

## Gates

- Targeted (`test/models`, sheet popups, board, map, innkeeper): 1600 passed.
- Full suite: **`+4239: All tests passed!`** (4216 + 23).
- `flutter analyze --no-fatal-infos`: 47 info, 0 warning, 0 error (baseline).
- `sh tool/hardening_check.sh`: OK.
- `git status --short`: only ` M pubspec.lock`.

## Notes

- The abandon action of the map sheet still follows `lane.isWaitingForParty` (unchanged): for an enemy that state is the instant between the arrival and the BE start.
- DB step of the orchestrator (seat title → `null` on the open enemy quests) is cosmetic for the FE: both shapes behave the same.
