# Phase 22 — Fixes from the device UAT

## UF-01 Unknown companion: black silhouette, no details (2026-11-15)

User request (verbatim): «Se non hai ancora ottenuto la lore corrispondente, il foglio non si deve aprire per dare il dettaglio e l'immagine deve essere nera (come succede per gli enemies).»

**Contract (BE, same cycle, additive SDL):** `type Pet { known: Boolean! }` resolved per viewer by the BE. It is `true` when the viewer has unlocked the companion's lore, or when the companion has no lore. The FE computes nothing.

**What changed**

- `Pet.known` (`lib/models/pet.dart`) is read leniently: absent or non-boolean → `true`, so an older BE hides nothing. It is in `toJson`, `copyWith` and props.
- `PetFragment` selects `known`, after `rarity`. This covers every `Pet` drawn as a card or in the details: character (equipped + owned), shop, quest prizes and innkeeper mission queries. The result sheet's `pet { id name }` is text and stays unchanged. The registry stays at 55 documents. The schema check against the new SDL is left to the orchestrator.
- `CompanionCard` passes `pet.known` to `EnemyPortrait`. So an unknown companion is the same black silhouette as an unknown enemy (`silhouetteFilter`, label «Sagoma del nemico»). The name stays visible, as an unknown enemy's name does on the quest and result sheets. Every surface drawing the companion goes through this card: Journal list and slot, shop rows and basket, quest prize, innkeeper prize rows and catalogue, potion targets, details frame.
- One rule decides the long press: `companionDetailsGesture(Pet, VoidCallback?)` in `lib/shared/components/cards/companion_details_gesture.dart`. It is applied where `onLongPress` is decided: `CompanionRow` (shop list, basket, innkeeper prize rows and catalogue), the quest-sheet prize, `CompanionSlot` and `OwnedCompanionRow` (Journal).
  - A known companion keeps its opener.
  - An unknown companion keeps a long press that opens nothing. Without that recognizer, the hold falls through to `onTap` on release, which would equip or select the companion.
  - The short tap is unchanged.

**Commits**

| Commit | Subject |
| ------ | ------- |
| 6e3a0336 | test(models): expect Pet.known read leniently from the wire |
| 376e8edf | feat(models): read Pet.known, absent or malformed as known |
| 293e6371 | test(graphql): expect PetFragment to select known |
| 321d773c | feat(graphql): select known on every companion through PetFragment |
| e747645a | test(shared): expect unknown companions as silhouettes with no details |
| a0614862 | fix(shared): black silhouette and no details for an unknown companion |

**Tests (+14)**

- `test/models/pet_test.dart` +3: read, lenient default, round trip / props / copyWith.
- `test/graphql/shop_documents_test.dart` +1, and the exact PetFragment pin updated.
- `test/shared/components/cards/companion_details_gesture_test.dart` +3 (new file).
- `test/shared/components/cards/companion_card_test.dart` +2: silhouette with name; known keeps the picture. The second was green at its first run, because it pins today's behaviour.
- `test/shared/components/companion_row_test.dart` +1.
- `test/shared/components/popup/quest_info_sheet_test.dart` +1: prize silhouette, no details.
- `test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart` +1: buy list, no details request, tap still selects.
- `test/screens/mainScreen/tabs/journal/components/owned_companion_row_test.dart` +1.
- `test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart` +1: list and slot, no sheet, tap still toggles.
- The «details open when known» cases already existed for the Journal, the shop and the quest prize, and they stay green.

**Gates:** `flutter analyze` 47 info / 0 warning / 0 error. Full suite `flutter test` → 5041 green.

**Deviation:** in the RED commit, the gesture unit test expected `null` for an unknown companion. In GREEN, the widget tests showed that a missing long-press recognizer turns the hold into a tap. The rule now returns a no-op instead, and the unit test was corrected in the GREEN commit.

**Open point:** the innkeeper's prize rows and catalogue select `known` too, through the shared fragment. If the BE resolves it for the streamer's own viewer, prize companions whose lore the streamer has not unlocked show as silhouettes and open no details in the innkeeper wizard.
