# Phase 23 (FE) — Backend notes

Written by plan 23-08 (Task 1) after the research block gate (23-14); §3 is completed by plan 23-08 (Task 3) after the device E2E.

Frontend companion of the BE Phase 24 («Origini delle magie, quest void e shamanic», with its research and learning block, BE plans 24-13..24-18). Branch `feat/23-spell-origins-void-and-shamanic-quests`. English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file. BE ref: branch `feat/24-origini-magie-quest-void-shamanic` (BE PR #44, draft, not merged on BE `develop` yet), gate of 23-07 at `b8241604`, gate of 23-14 at `f3313bd2`, device E2E at `3f82fa50` (SDL identical to `f3313bd2`). The schema check must be re-run on BE `develop` after the merge of PR #44.

## 1. Contract consumed by the FE

Names, types and nullability confirmed on the BE branch SDL by the gates of 23-07 and 23-14 (`GATE_OK`, no deviation from `23-REPO-RULES.md`) and re-checked by 23-08 (`GATE_OK` on `3f82fa50`). Schema check: registry of **55** documents (`tool/schema_check/schema_check_documents.dart`, unchanged by this phase), 55 × OK.

- **W-1** `Spell.origin: String!` (wire `void` / `arcane` / `shamanic`; Dart `SpellOrigin.theVoid` / `arcane` / `shamanic` through `wireName` / `fromWire`) selected in `SpellFragment.fields`, `SpellFragment.simpleFields` and the inline `addedSpell` of `EquipmentFragment.fields` (`lib/graphql/fragments/spell_fragment.dart`, `equipment_fragment.dart`). Absent or unknown → null, the spell stays and no origin icon is drawn.
- **W-2** `Spell.minLevelToLearn: Int!` in `SpellFragment.fields`; `minXpToLearn` selected nowhere (it is gone from the SDL). The app prints «Per impararla: Livello N» and compares nothing; a level ≤ 0 or absent prints no line.
- **W-3** `CityType` + `aarakocraCapital`, `dragonbornCapital`, `dragonbornVillage` (`lib/graphql/queries/city_queries.dart`; visibility from the served `City.size`, marker size per type in `lib/models/enums/city_type.dart`: the two capitals 46 after the UAT, `dragonbornVillage` 30; `aarakocraVillage` re-pointed to its new file).
- **W-4** quest `type` strings `arcane` (legacy `magic` still read as `arcane`, never written), `shamanic`, `void` on `QuestInfos.type`, on the quest of a `QuestResult`, on pending requests and on `MissionDraft.questType`; the quest type crosses the wire only through `QuestType.wireName` / `fromWire`.
- **W-5** no refusal code for the level gate reaches the FE (the BE simply does not teach a spell above the level; the innkeeper re-validation keeps `OUTCOME_OVERRIDE_INVALID`).
- **W-6** `spellLearned { id name }` of the result stays text.
- **W-7** origin lore (D-24): the FE selects NO `Spell.relatedLore`; it needs the unlocked lore id in `status.unlockedLore` (via `characterUpdated`) and the lore entry in `QuestResult.loreUnlocked` of the result that taught the spell (the learning-end sheet for a drawn spell).
- **W-8** the origin lore entries use the lore type `knowledge`, already known by the FE (`lib/models/enums/lore_type.dart`).
- **W-9** `PendingQuest.learningSpell: Spell` selected as `learningSpell { id name origin requiredLearnTime }` on the standard lane only (`CharacterFragment.questsFields` → `pendingQuest`; GM lanes select nothing, D-30); the end of the learning is read as `startDate + waitingTime` on the server clock.
- **W-10** `QuestPrizes.spellDraw: Boolean!` selected in `QuestFragment.fields` (`quests`, `questUpdated`), read from the board quest, never from the lane (the lane keeps `quest { id infos { type } }`).
- **W-11** `QuestResult.spellFound: Spell` (`{ id name origin requiredLearnTime }`) and `spellResearchFailed: Boolean!` in `QuestResultFragment.fields` (`GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, `CompleteGuidedMission`).
- **W-12** `PushEventType.spellResearchSucceeded` / `spellResearchFailed` handled as `questEnd` (same «Fine quest» toggle, tap = `questResult(id)`, dedup key `questEnd|<result id>`): the FE relies on `id` being a QuestResult id for both.
- **W-13** `Spell.requiredLearnTime` read only on `spellFound` (result sheet and banner), printed nowhere on a spell card (D-28).

## 2. FE behaviours proved by tests

- **Wire boundary:** the quest type and the origin cross the wire only through `wireName` / `fromWire` (Dart `theVoid` ↔ wire `void`); the legacy wire `magic` reads `arcane` and is never written; an unknown quest type drops only that quest; unknown origin, level and city types are lenient (null, nothing drawn).
- **Learn line by level only:** «Per impararla: Livello N» without the learn time, no level comparison, no line without a served positive level.
- **Rites like the arcane quest at every site:** labels «Magia» / «Rito sciamanico» / «Rito del Vuoto», whole and torn sheets by constant, torn until the rank, no registration; city markers by constant with their sizes.
- **Origin icon first:** origin → use → energy on `SpellCard` and `SpellInfo` («Origine: …» row), three icons that never overflow at 48 px (and, after the UAT, the infused spell card of the equipment details sized to its room); a spell without origin drawn as before.
- **Nothing selected before the gate:** guards that flipped in 23-07 (origin, level) and 23-14 (research fields); each research field selected only in the documents that embed its home fragment.
- **Research rule:** `isSpellResearchQuest` = a school type (`arcane`, `shamanic`, `theVoid`) or a board quest with `prizes.spellDraw`; label «Ricercando…» on paper, pawn and overlay; `study` without the draw keeps «Studiando…».
- **Learning part:** label «Apprendimento…» on the paper, «Imparando «<nome>»: <tempo>» on pawn and overlay from the served lane, countdown on the server clock to `startDate + waitingTime` (`SpellLearningCubit`, owned by the Map, closed in dispose), «Imparando «<nome>»…» once over until the BE frees the lane; no loader.
- **Three result sheets of a draw quest:** spell found («Magia scoperta: …» + «Tempo di apprendimento: …» from `spellFound.requiredLearnTime`), research failed («La ricerca non ha rivelato alcuna magia»), learning end (`isLearningEnd` inferred: learned spell, `spellFound` null, no xp, no enemies, life unchanged → no life bar; empty blocks vanish).
- **Research pushes as quest ends:** both wire types accepted by the `questEnd` category, same toggle, tap and dedup key; banner copy by outcome («Ricerca riuscita» / «Ricerca conclusa» / «Missione conclusa»); an unknown push type is dropped.

## 3. UAT outcome (FE Phase 23)

Filled by plan 23-08.

## 4. Questions and notes for the BE

1. `minXpToLearn` is removed from the SDL (not deprecated) and kept at DB for rollback: the orchestrator `$unset`s it from `spells` after both merges. Nothing on the FE reads it.
2. The legacy read of the quest type `magic` (FE `fromWire`) can be dropped once BE `develop` is booted with the Phase 24 migrator and no stored quest or result carries `magic` any more (orchestrator check at DB after the merge).
3. `cities` before the BE boot served the three cities without a known type (fail-closed); after the boot it serves `aarakocraCapital` / `dragonbornCapital` (size `capital`) and `dragonbornVillage` (size `village`) additively.
4. The learning-end sheet has no discriminator: the FE infers it (`isLearningEnd`: learned spell, `spellFound` null, no xp, no enemies, `hpBefore == hpAfter`). A future explicit field would remove the inference.
5. Duration wording: the BE push says «30 minuti», the in-app banner «30 min» (`formatGameDuration`); whichever arrives first is shown (dedup on `questEnd|<result id>`).
6. Open BE note (from the BE handoff): a `knowledge` origin lore may also come from the study-lore pool before the first spell of that origin (user decision).
