# Phase 19: Model Review (frontend companion) - Research

**Researched:** 2026-11-11
**Domain:** Flutter consumer of a **non-additive** GraphQL contract change (BE Phase 19): renamed and removed fields on `Enemy`, `Pet`, `CharacterAssets`, `CharacterStatus`, `Equipment`, `SlotType`, `PointOfInterest`, `Lore`; one additive field (`QuestResult.petXpGained`); FE-only hardening of fragile `fromJson` parsers
**Confidence:** HIGH for code facts (file:line read this session on `feat/19-model-review` at `b0b6d41`; one throwaway probe file with 55 parser probes, run and deleted; analyzer, full suite, formatter and schema check run); MEDIUM for the BE names (fixed in the two `19-REPO-RULES.md`, not on BE `origin/develop` `bc92fb6f`: every new name counts 0, every old name is still there)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
Copied by reference, authoritative text in `19-CONTEXT.md` §Implementation Decisions (do not paraphrase in plans):
- **D-01** `Enemy.weaknesses: Weaknesses! { base: [DamageType!]!, energy: [EnergyType!]! }` replaces `energyWeaknesses`/`baseWeaknesses`; FE `Weaknesses` value, lenient (unknown names dropped, missing → empty lists).
- **D-02** `Enemy.spells` keeps its wire shape: no FE change beyond fixtures.
- **D-03** `CharacterAssets.ownedPets: [OwnedPet!]!` with `OwnedPet { pet: Pet!, xp: Int!, currentLifePoints: Int! }`; `assets.pet: Pet` unchanged; lenient (malformed entry dropped); «Compagni» list and «Compagno» slot on the entry's catalogue pet; owned companion row «Esperienza: 40 / 300» (display only); `QuestResult.petXpGained: Int!` (default 0) → result line «Il tuo compagno guadagna N PE» after the character xp line when above 0; catalogue `Pet` loses `xp` and `currentLifePoints`.
- **D-12** `Pet.damages` → `Pet.attack: Damages!` and `Pet.defense: Damages!`; companion card/rows print the attack and a second «Difesa» line when not empty.
- **D-04** `wearedEquipment` → `wornEquipment`, slot `foots` → `feet` (fragment, `Equipment` model, `SlotType`, mannequin, equip request): names only.
- **D-05** `CharacterStatus.spellStates` gains `active: Boolean!` and becomes the only source; `CharacterStatus.spells` and `CharacterAssets.activeSpells` leave the wire; known = all states, equipped = `active`; `maxActiveSpells` unchanged; optimistic rollback adapted. Largest FE plan, last in the gated wave.
- **D-06** `PointOfInterest.quest` leaves model and fragment; `Lore.image` → `imagePath`.
- **D-07** `City.shop` is Mongoose-only: no FE work.
- **D-08** FE-only: `PointOfInterest.fromJson` (`type` Iterable, `location` guard) fixed and the models swept for the same patterns, a pinned test per fix; lenient where the entity can be dropped, strict only where the Phase 6 board rules require it (D-20 C6). Runs before the gated plans.
- **D-09** schema gate (`grep -cF` on the merged BE SDL) before the gated plans; device E2E: Journal (companions with xp line, spells with the single list, mannequin with `feet`), a fight with the equipped companion → «Il tuo compagno guadagna N PE», Map untouched, Library images.
- **D-10** executes after Phase 18 and the BE Phase 19 merge. **D-11** out of scope as listed in the boundary.

### Claude's Discretion
Copy of the companion xp lines (since fixed in `19-REPO-RULES.md`); whether the companion row shows a small bar or text (REPO-RULES: text only); fixture reshaping order; whether the spells section refactor lands as one plan or two.

### Deferred Ideas (OUT OF SCOPE)
Companion life in combat and damage scaling with xp; `ownedEquipments` + `ownedItems` merge; spell `damages` / `requiredLearnTime`.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MODEL-01 | `Enemy.weaknesses`, `Lore.imagePath`, no `PointOfInterest.quest` | F1 (weaknesses: model only, nothing selected), F7 (lore: 2 documents, 5 readers), F8 (POI: nothing selected) |
| MODEL-02 | `ownedPets` entries, «Esperienza: N / maxXp», `Pet.attack`/`defense`, result line from `petXpGained` | F2 (pets map, C2: no pet damages printed today), F3 (result sheet insertion `quest_result_sheet.dart:187`) |
| MODEL-03 | `wornEquipment`/`feet`; single `spellStates` list with `active` | F4 (rename is atomic and reaches the wire through the equip request), F5 (`Spellbook` is the single funnel; UI untouched) |
| MODEL-04 | Fragile parsers fixed with a pinned test each; schema gate; device E2E | F8 + §MODEL-04 sweep table (probes P01–P95), F9 (gate), F10 (E2E) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)
- Clean Code, SoC (models Flutter-free; UI no networking; Cubit no `BuildContext`), TDD red → green → refactor, Boy Scout rule.
- Rule 1 no app chrome on gameplay (Journal, sheets). Rule 2 no blocking loading in session (optimistic spell equip stays). Rule 3 branch `feat/19-model-review`, PR → `develop`. Rule 4 backend is the source of truth (`active`, companion xp, cap, `maxActiveSpells` are read, never computed). Rule 5 no secrets.
- `flutter analyze --no-fatal-infos`: **baseline measured this session `47 issues found.`, 47 info / 0 warning / 0 error** [VERIFIED: analyzer run].
- `docs/rules/graphql.md`: documents only in `lib/graphql/`, one fragment per entity. `docs/rules/state-management.md`: `Equatable` states with full `props`, immutable lists. `docs/rules/naming.md`: `snake_case.dart`, booleans `isX/hasX`. `docs/rules/testing.md`: new model → `fromJson`/`toJson`/`Equatable` test first; bugfix → regression test that failed before.
- `19-REPO-RULES.md`: contract names, FE names (`Weaknesses`, `OwnedPet`, `attack`/`defense`, `petXpGained`, `wornEquipment`, `feet`, `active`, `imagePath`), fixed copy, gate rule «every fragment/document change is gated», `dart format` per file, no commit trailers.

## Summary

Five facts shape the plan. **(1) Half of the «wire» changes are not on the FE wire at all.** No FE document selects `Enemy.energyWeaknesses`/`baseWeaknesses`, `PointOfInterest.quest`, `PointOfInterest.type`, `Pet.damages`, `Pet.xp`, `Pet.currentLifePoints` or `Pet.maxXp`: `PetFragment.fields` is `id name speedModifier sellable buyPrice sellPrice` and `LocationFragment.fields` is `id location`. So D-01, the POI part of D-06 and the model side of D-12/D-03 (catalogue pet) are **pure model changes with no gate**; the gated work is only what the FE really selects: `wearedEquipment`/`foots` (2 documents + the equip request enum), `spells`/`activeSpells`/`spellStates`, `ownedPets`, `Lore.image` (3 documents), plus the new selections (`attack`, `defense`, `maxXp`, `xp`, `currentLifePoints`, `active`, `petXpGained`). **(2) Two statements of CONTEXT/REPO-RULES do not match the code** (C1, C2): nothing prints the pet damages today (no «line of today» to switch to `attack` — both lines are new copy), and the gate greps `imagePath ≥ 1` / `feet ≥ 1` are vacuous or fragile as written (`imagePath` already counts 4 on today's SDL). **(3) D-05 is smaller than feared on the UI side:** every reader of the three spell lists goes through the pure view `Spellbook.of` (5 call sites) plus one direct read in `SpellsCubit._matches`; `SpellbookContent`, the rows, the info sheet and `SpellRecoveryCubit` read only `Spellbook`. The cost is in the tests (15 files carry the old shapes, `spellbook_test.dart` alone 23 references) and in one semantic change: the slot order becomes the learning order (the equip order no longer exists on the BE). **(4) The `feet` rename reaches the wire through `EquipItemRequest.toJson` (`slotType.name`, `SlotType` is an SDL enum with `foots` today) and through `journal.dart:318-321`, which matches `Equipment.toJson()` keys against `SlotType.name`** — model, enum, request and fragment must move in one commit, in the gated wave. **(5) The parser sweep found one real, larger class of crash than the POI case:** enum fields typed `String!` on the SDL (`effect`, `rarity`, `equipType`, damage `type`, `title`) are parsed with `byName`, and a single unknown name inside the character payload makes the whole character unloadable (probes P20, P50–P58, P63, P66). After this phase `Pet.attack`/`defense` join that path.

**Primary recommendation:** FE-only parser fixes and the unselected model changes first (no window problem), then pets and spells behind **one small legacy reader each** at the parsing boundary so every consumer moves to the new shape before the gate, then one gated wave that flips the fragments, performs the two pure renames (D-04, `Lore.imagePath`) atomically, deletes the two legacy readers RED-first, and ends with `schema_check` 46 × OK; the device E2E is the last human-checkpoint plan.

## Standard Stack (all already in `pubspec.yaml`, no new dependency)

| Library | Use in this phase | Source |
|---------|-------------------|--------|
| `equatable` | `Weaknesses`, `OwnedPet`, reshaped `SpellState` | [VERIFIED: codebase] |
| `flutter_bloc` / `bloc_test ^10.0.0` / `mocktail ^1.0.5` | `SpellsCubit` (33 cases in `spells_cubit_test.dart`), `MockCubit`s in `test/helpers/mocks.dart` | [VERIFIED: codebase] |
| `graphql_flutter 5.2.1`, `gql` (`parseString` in document tests) | fragments and document tests | [VERIFIED: codebase] |
| Dart `Enum.values.asNameMap()` | lenient enum reads (pattern `injuryTypesFrom`, `injury_type.dart:198-202`; `_accessoryUseTypesFrom`, `equipment_item.dart:105-111`) | [VERIFIED: codebase] |
| Node v22.12.0 + BE `node_modules/graphql` | `tool/schema_check/validate_documents.js` | [VERIFIED: run, 46 × OK on BE `bc92fb6f`] |

## Architecture Patterns

### Recommended files
```
lib/models/weaknesses.dart                    # NEW Weaknesses (base, energy), lenient fromJson, toJson, props
lib/models/enemy.dart                         # weaknesses replaces the two lists; locations lenient List
lib/models/owned_pet.dart                     # NEW OwnedPet (pet, xp, currentLifePoints), tryFromJson
lib/models/pet.dart                           # attack, defense; xp, currentLifePoints, damages removed
lib/models/character/character_assets.dart    # ownedPets: List<OwnedPet>; (gated) wornEquipment; activeSpells removed
lib/models/character/character_status.dart    # spellStates only source; spells removed; title lenient
lib/models/character/character.dart           # (window only) legacy spell lists → states, deleted at the gate
lib/models/spell/spell_state.dart             # + Spell spell (full), + bool active
lib/models/spell/spellbook.dart               # Spellbook.of on the single list (public API unchanged)
lib/models/active_spell.dart                  # DELETED (only CharacterAssets and Spellbook use it)
lib/models/point_of_interest.dart             # type lenient List, location guard, quest removed
lib/models/lore.dart                          # (gated) imagePath
lib/models/equipment.dart, enums/slot_type.dart, request/equip_item_request.dart   # (gated) feet
lib/models/damages.dart, base_damage.dart, energy_damage.dart, loot_item.dart, equipment_item.dart,
lib/models/asset_quantity.dart, city.dart, city_shop.dart          # MODEL-04 boundaries (sweep table)
lib/models/quest_result/quest_result.dart     # + int petXpGained (lenient → 0)
lib/utils/item_lines.dart                     # + companionXpLine, companionXpGainedLine, attack/defense lines
lib/screens/mainScreen/tabs/journal/sections/companion_section.dart, components/companion_content.dart,
lib/screens/mainScreen/tabs/journal/components/owned_companion_row.dart          # entries + xp line
lib/shared/components/cards/companion_card.dart, lib/shared/components/companion_row.dart   # attack / «Difesa»
lib/shared/components/popup/quest_result_sheet.dart                # companion line after the xp line
lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart  # _matches on spellStates.active
(gated) lib/graphql/fragments/character_fragment.dart, pet_fragment.dart, equipment_fragment.dart,
        quest_result_fragment.dart, lib/graphql/queries/lore_queries.dart, city_queries.dart
```

### F1. D-01 weaknesses — model only [VERIFIED: codebase]
- The two names appear on **16 lines of 1 file**, `lib/models/enemy.dart` (ctor :15-16, fields :29-30, `fromJson` :43-52, `toJson` :70-71, `copyWith` :84-85, :96-97, `props` :112-113). `grep -rnE "energyWeaknesses|baseWeaknesses" lib test tool` finds nothing else: **no reader, no fragment, no test, no fixture**. The only enemy selections on the wire are `enemy { id name imagePath xp }` (`quest_fragment.dart:26-31`, `quest_result_fragment.dart:106-111`).
- `Enemy(` is constructed only inside the model. There is no `test/models/enemy_test.dart` (Wave 0).
- Today's parser uses `byName` (probe P12: an unknown name throws `ArgumentError`); a payload with the new `weaknesses` object is silently ignored (P13).
- Plan: `Weaknesses` in `lib/models/weaknesses.dart` (`base: List<DamageType>`, `energy: List<EnergyType>`, both unmodifiable, `Weaknesses.fromJson(Object?)` that never throws: non-map → empty value, non-list → `[]`, unknown names dropped through `asNameMap()`), `Enemy.weaknesses` non-null. **Not gated, no dual shape** (nothing is selected; recommendation: do not start selecting it — no reader exists).
- D-02: `Enemy.spells` is never selected either; no fixture carries enemy spells → nothing to do.

### F2. D-03 / D-12 pets [VERIFIED: codebase]
**Wire today.** `PetFragment.fields` (`pet_fragment.dart:5-17`): `id name speedModifier sellable buyPrice {…} sellPrice {…}`. Users: `character_fragment.dart:99-104` (`pet { … }`, `ownedPets { … }`), `shop_queries.dart:29-31` (`pets { … }`). The inline `pet { id name }` of `quest_fragment.dart:94-97` and `quest_result_fragment.dart:82-85` do not use it and do not change.

**Model.** `lib/models/pet.dart`: `damages` :9/:25/:42/:65/:81/:97/:112, `xp` :12/:29/:40/:63/:85/:101/:116, `currentLifePoints` :15/:30/:50/:68/:86/:103/:118, `maxXp` :13/:28/:41/:64/:84/:100/:115 (7 lines, this file only — matches the CONTEXT). None of the four is selected, so on the wire they are always `null` today. `Pet(` is constructed only inside the model; `Pet.tryFromJson` :58-61 (map with a string `id`) is the lenient boundary used by prizes and rewards.

**Readers of `ownedPets` (lib: 22 lines / 5 files) and of the type `Pet` (16 files — matches the «16 files» of the CONTEXT).**

| File:line | What it reads | Change |
|-----------|---------------|--------|
| `character_assets.dart:14, :24, :47-53, :62, :72` | `List<Pet> ownedPets`, strict per entry (`Pet.fromJson(x as Map)`, probe P61 throws) | `List<OwnedPet>`, `OwnedPet.tryFromJson` per entry, malformed dropped |
| `journal/sections/companion_section.dart:14-15, :18-25, :46` | `_ownedPetsOf` → `List<Pet>`; `_displayedPet` looks in the owned list, then `assets.pet` | entries; the displayed pet stays a catalogue `Pet` (`entry.pet`) |
| `journal/components/companion_content.dart:20, :50-58` | `owned: List<Pet>`, one `OwnedCompanionRow` per pet | `List<OwnedPet>`; row gets the entry |
| `journal/components/owned_companion_row.dart:20, :38-53` | `Pet pet`; card + «Al tuo fianco» in an `Expanded` shown only when displayed | + xp line (see below) |
| `journal/components/companion_slot.dart:17, :39-47` | `Pet? pet` → `CompanionCard` | unchanged type |
| `journal/companionCubit/companion_cubit.dart:174`, `companion_state.dart:55` | `assets.pet?.id` only | none |
| `tabs/shop/shop.dart:170, :177, :369, :377, :395-399` | `_ownedPetsOf` → `List<Pet>` for `purchasablePets`, the sell stock, the prune listeners, the id set | one line (`:395-396`) if `CharacterAssets` exposes the catalogue pets of the entries (e.g. a getter `ownedCatalogPets`); everything downstream stays `List<Pet>` |
| `models/shop/trade_selection.dart:16-107`, `shop/components/shop_modal.dart:36, :217-283`, `transaction_modal.dart:245-272` | catalogue `Pet` lists and ids | none |
| `models/city_shop.dart:24-28` | `pets` of the pool: catalogue `Pet` | none (gets `attack`/`defense`/`maxXp` through the fragment) |
| `shared/components/companion_row.dart:23, :60-77` | name, speed line, equipped mark (shop buy/sell, transaction) | + attack / «Difesa» lines |
| `shared/components/cards/companion_card.dart:23, :40-46` | name and speed as `CardLabel`s | + attack / «Difesa» labels (C2, OQ1) |
| `utils/item_lines.dart:25-39` | `companionEquippedMark`, `noOwnedCompanionsLine`, `companionSpeedLabel(Pet)` | + the new helpers |
| `models/quest/quest_prizes.dart`, `quest_result/quest_rewards.dart` | `Pet.tryFromJson` on `{ id name }` | none |

- **Where the pet damages are printed today: nowhere** (`grep -n damages` on the three companion widgets, the section and `item_lines.dart` → empty). `CompanionCard` prints name + `companionSpeedLabel`; `CompanionRow` prints name, speed, «Al tuo fianco». `Pet.damages` is parsed and never read (C2).
- **Where the new lines go.** «Esperienza: N / maxXp»: `owned_companion_row.dart:44-53` — today the right-hand `Expanded` exists only `if (isDisplayed)`; it becomes a column that holds the equipped mark (when displayed) and the xp line (when `companionXpLine` is not null). «Attack» and «Difesa»: `companion_card.dart:42-45` (two more `CardLabel`s: each is `cardSize / 6` high, so name + speed + attack + defense = 4/6 of the card — it fits, a fifth label would not) and `companion_row.dart:66-76` (two more `Text`s with keys `companion-attack-<id>` / `companion-defense-<id>`, pattern :69).
- **`Pet.xp` / `currentLifePoints`**: parsed at `pet.dart:40, :50`, written by `toJson` :63/:68, used by no widget, no cubit, no test assertion outside `test/models/pet_test.dart`. Dropping them is free.
- `companionXpLine(xp, maxXp)` must return `null` when `maxXp` is null or ≤ 0 (before the gate `maxXp` is not selected → no line; never «Esperienza: 0 / null»).
- New selections (gated): `PetFragment.fields` + `maxXp attack { ${DamagesFragment.fields} } defense { ${DamagesFragment.fields} }`; `ownedPets { xp currentLifePoints pet { ${PetFragment.fields} } }`. `DamagesFragment.fields` exists (`damage_fragment.dart:31-40`; the file is formatter-dirty but needs no edit).

### F3. Result sheet and `petXpGained` [VERIFIED: codebase]
- Model `lib/models/quest_result/quest_result.dart`: `xpGained` ctor :35, field :92, strict parse :164 (`(json['xpGained'] as num).toInt()`), `toJson` :237, `props` :281; the lenient additive precedents are `injuriesHealed` :50/:152 and `arrested` :51/:153. Add `this.petXpGained = 0`, parse `json['petXpGained'] is num ? … : 0` (a negative value → 0, state it in the test title), write it in `toJson` (the fixture round trip of `quest_result_test.dart` iterates the fixtures), add it to `props`. `QuestResult(` is never constructed outside the model.
- Fragment `quest_result_fragment.dart:87-89` `xpBefore xpGained xpAfter`: add `petXpGained` right after `xpAfter` (:89). No pin constrains that neighbourhood (`grep -rn "xpGained\|xpBefore" test/graphql` → nothing); the pinned adjacencies are `injuriesAdded injuriesHealed` (`quest_result_documents_test.dart:91`), `injuriesHealed arrested coinsLost {…} guardEncounter` (:95-103), `resolvedAt acknowledgedAt` (:106), `spellLearned { id name } loreUnlocked { id name type }` (:126). The fragment feeds three documents (`questResultReceived`, `questResult`, `unacknowledgedQuestResults`).
- **Insertion point in the sheet:** `lib/shared/components/popup/quest_result_sheet.dart` `_content()` :160-195 — `..._line(_xpText(), QuestResultSheet.xpKey),` is **line 187**; insert `..._line(companionXpGainedLine(_result.petXpGained), QuestResultSheet.companionXpKey),` as the next line, before `_levelText()` (:188). `_line` (:435) returns `[]` for a null text. New key next to `xpKey` (:56): `ValueKey('questResult.companionXp')`. The companion line does **not** depend on `_xpText()` (which is null when `xpGained ≤ 0`, :467-471).
- Helper file: `lib/utils/item_lines.dart` holds the companion strings (:25-39); the outcome lines `arrestLine` / `guardEncounterLine` live in `lib/utils/quest_outcome_lines.dart:12-23`. Put `companionXpLine` in `item_lines.dart` and `companionXpGainedLine` in `quest_outcome_lines.dart` (or both with the companion strings — planner's choice, one file each is enough).
- Tests: `test/shared/components/popup/quest_result_sheet_test.dart:116` (`'Esperienza: 200 → 260 (+60)'`), :465, :920-929 are the xp cases to sit next to; fixture `test/helpers/fixtures/quest_result_fixtures.dart:71-131` `questResultJson` (add `int petXpGained = 0` → `'petXpGained': petXpGained`). The ambush carousel reuses the sheet: the line shows there too when the BE sends it (BE D-04: an ambush won counts).

### F4. D-04 `wornEquipment` / `feet` [VERIFIED: codebase + BE SDL]
- **`foots`: 13 lines / 4 files** (CONTEXT confirmed): `equipment.dart:9, :21, :32, :52, :63, :74, :88, :103`; `enums/slot_type.dart:93`; `journal/components/equipment_mannequin.dart:70, :75, :103`; `graphql/fragments/equipment_fragment.dart:96` (the slot list of `WearedEquipmentFragment`, :84-105). No test, no fixture, no tool file contains `foots`.
- **`wearedEquipment`: 11 lines / 3 files** (confirmed): `character_assets.dart:10, :19, :43-44, :60, :69`; `journal.dart:175, :278, :316, :381`; `character_fragment.dart:74`. Tests: 1 line (`test/helpers/journal_harness.dart:61`).
- **Two documents carry the slot list**, not one: `CharacterFragment.assetsFields` (`character_fragment.dart:74-76`) and `CharacterQueries.getEquipment` (`character_queries.dart:23-30`, registry key `equipment`, used by `JournalCubit` through `graphql.dart:474-490`). Both read `WearedEquipmentFragment.slots`, so one edit covers both.
- **The slot name goes on the wire in a request:** `EquipItemRequest.toJson` (`equip_item_request.dart:14-18`) sends `"slotType": slotType.name`; BE SDL today: `input EquipItemRequest { id: String!, itemId: String, slotType: SlotType! }`, `enum SlotType { arms chest firstAccessory foots head leftHand legs rightHand secondAccessory }`. Renaming the Dart member before the BE merge makes «equip boots» fail against today's BE → **the enum rename is gated**.
- **Hidden coupling:** `journal.dart:315-326` `_findEquippedSlot` matches `equipment.toJson()[slot.name]` for every `SlotType` → the key written by `Equipment.toJson` (`equipment.dart:52`) and the enum member name must change **in the same commit**, or unequipping boots silently does nothing (`targetSlot == null`, :346-349).
- There is no `test/models/equipment_test.dart`, no `equip_item_request_test.dart`, no `slot_type` test (Wave 0: pin `'slotType': 'feet'` and the `toJson` key ↔ `SlotType.name` agreement for all nine slots).
- Optional Boy Scout in the same commit: class `WearedEquipmentFragment` → `WornEquipmentFragment` (4 references: `equipment_fragment.dart:84-85`, `character_fragment.dart:75`, `character_queries.dart:27`); its `name` constant `'WearedEquipmentFields'` is unused on the wire.

### F5. D-05 the spells map [VERIFIED: codebase]
**How it works today.**
- Wire (`character_fragment.dart:57-66, :85-90`): `status.spells { SpellFragment.fields }` (the full catalogue data of every known spell), `status.spellStates { usages recoveries spell { id } }` (state by id), `assets.activeSpells { usages spell { SpellFragment.fields } }`.
- Models: `CharacterStatus.spells: List<Spell>?` (`character_status.dart:16, :37, :71-73`), `CharacterStatus.spellStates: List<SpellState>?` (`:25, :47, :83, :90-95`; `null` = field absent), `SpellState { spellId, usages, recoveries }` (`spell/spell_state.dart:5-47`, `tryFromJson` boundary), `CharacterAssets.activeSpells: List<ActiveSpell>?` (`character_assets.dart:12, :20, :38-42`), `ActiveSpell { spell, usages }` (`models/active_spell.dart`).
- **Single funnel:** `Spellbook.of(character, {pending})` (`spell/spellbook.dart:73-128`). Known spells = `status.spells` (:77); slot count = `maxActiveSpells` (:78); states by id (:79-83); server-active map from `assets.activeSpells` **in the BE order** (`_serverActiveById` :158-166); optimistic active = server − pending unequips + pending equips appended **in tap order** (`_optimisticActiveById` :170-186); usages fallback table `state?.usages ?? active?.usages ?? spell.maxUsages` (`_usagesOf` :189-190); recoveries from the state (:121); `intentFor` :146-155.
- Readers of `Spellbook.of`: `spells_section.dart:92` (countdown inputs), `:108` (use-type chips), `:131` (section), `:187` (details sheet); `spells_cubit.dart:53` (`toggle`); `models/request/participant_draft.dart:95` (innkeeper completion form: the filled slots become `SpellLine`s). `SpellRecoveryCubit.inputsOf(Spellbook)` (`spell_recovery_cubit.dart:30-38`) reads entries only.
- **The only direct read of a raw list outside `Spellbook`:** `SpellsCubit._matches` (`spells_cubit.dart:228-239`) builds the server-active id set from `character.assets?.activeSpells` to close a pending operation in `sync` (:74-84) and `_succeed` (:149-157).
- Optimistic flow: `toggle` (:51-71) computes the intent on the optimistic view, `_start` (:98-119) records a token + settle timer and emits `pending[spellId] = operation`, mutations are drained one at a time (:121-127), `sync` closes what the new character reflects, `_fail`/`_close` (:175-204) drop the pending entry and emit a `SpellOutcome` (the «rollback» is simply the pending entry disappearing: the view falls back to the server state). **None of this stores spell lists**: the cubit state is `{pending, outcome}` (`spells_state.dart:39-55`).
- Other readers of «spells» that are NOT this model: `QuestResult.spellsUsed` (`SpellUsage`, its own class), `spellLearned`, the innkeeper `draft.spells` lines (built from `Spellbook` slots). Quest requirements and combat previews read no spell list. `maxActiveSpells`: 11 lines / 4 files, 2 of them an error-code constant (`spell_equip_failure.dart:8, :58`) — unchanged.

**What the single list changes.**
1. `SpellState` must carry the **full `Spell`** (today only the id): after the merge `status.spells` is gone, so the catalogue data can only come from `spellStates { usages recoveries active spell { ${SpellFragment.fields} } }`. Keep `String get spellId => spell.id` so the 19 references of `spell_state_test.dart` and the readers stay readable. `SpellState.spell: Spell!` is non-null on the SDL already today (`type SpellState { recoveries spell usages }`).
2. `active: bool` (lenient → `false`) on `SpellState`; `CharacterStatus.spells` and `CharacterAssets.activeSpells` leave the model; `ActiveSpell` is deleted (its only users are `character_assets.dart` and `spellbook.dart`).
3. `Spellbook.of`: known = states in list order; active(entry) = `pending == equip || (state.active && pending != unequip)`; slots = the active entries **in list order**; usages = `state.usages` (the three-step fallback table disappears with its tests, `spellbook_test.dart:149-176, :255-273`).
4. `SpellsCubit._matches`: `character.status?.spellStates.any((s) => s.spellId == id && s.active)`.
5. `CharacterStatus.spellStates` should become non-null (`const []` when absent): «null = pre-9.1 payload» has no meaning once it is the only source. Pins to move RED first: `character_status_test.dart:110-113, :138-143, :528`.
6. **Ordering (visible, OQ2):** today the slot row follows `assets.activeSpells` (equip order) and a pending equip is appended last; after BE 19 the equip order no longer exists (one list in learning order, BE D-07), so the confirmed slot order is the learning order. The optimistic view must use the same rule or the card jumps slot when `characterUpdated` arrives. Tests that pin the old rule: `spellbook_test.dart:79, :103, :116, :198, :225`.

**Proposed split.** Model plan (S/M): `SpellState` + `spell` + `active`, non-null `spellStates`, legacy reader (window, §Window), fixtures in the new shape, old fields still present. View/cubit plan (M): `Spellbook.of` + `_matches` on the single list, `status.spells` / `assets.activeSpells` / `ActiveSpell` removed from the models, the 15 test files reshaped. **No UI plan**: `SpellbookContent`, `known_spell_row.dart`, `spell_slot_row.dart`, `SpellInfoSheet`, `spells_section.dart` and `SpellRecoveryCubit` consume `Spellbook`, whose public API does not change (their tests change only through the fixtures).

### F6. Fixtures and harness that carry the old shapes [VERIFIED: codebase]
- **Spells — 15 test files**, 12 of them through one funnel: `test/helpers/fixtures/spell_fixtures.dart` `activeSpellJson` :31-35, `spellStateJson` :37-48 (`'spell': {'id': spellId}`), `spellbookCharacterJson` :51-65 and `spellbookCharacter` :67-81 (parameters `spells`, `activeSpells`, `spellStates`). Callers by weight: `models/spell/spellbook_test.dart` (23 `activeSpells` + 6 `spellStates`), `models/character/character_status_test.dart` (25), `models/spell/spell_state_test.dart` (19), `graphql/character_fragment_test.dart` (recorded payload :182-221), `journal/sections/spells_section_test.dart`, `journal/components/spellbook_content_test.dart`, `journal/journal_spells_test.dart`, `journal/spellsCubit/spells_cubit_test.dart:23-28` (local `_character(active:)`), `journal/spellRecoveryCubit/spell_recovery_cubit_test.dart:47`, `mainScreen/components/spell_outcome_listener_test.dart:29`, `helpers/fixtures/pending_request_fixtures.dart:110-136` (innkeeper character: `spells`, `spellStates`, `activeSpells`), `screens/innkeeper/components/completion_form_test.dart`, `models/request/participant_draft_test.dart`.
- **Pets — 6 files with `ownedPets`** (`models/character/character_assets_test.dart:8-32`, `journal/companionCubit/companion_cubit_test.dart:22`, `journal/sections/companion_section_test.dart:42`, `tabs/shop/shop_test.dart:61-65, :225, :238`, `mainScreen/components/companion_outcome_listener_test.dart:24`, `graphql/character_fragment_test.dart:142`) and 16 files using `petJson` / `catPetJson` (`test/helpers/fixtures/shop_fixtures.dart:8-31`: no `damages`, no `xp` → add `maxXp`, `attack`, `defense` parameters and an `ownedPetJson({pet, xp, currentLifePoints})` builder).
- **Lore image — 13 files**: builders `test/helpers/fixtures/lore_fixtures.dart:8, :14` (`'image': image`) and `travel_fixtures.dart:99, :107`; 6 call sites pass `image:` to `loreJson`/`travelCityJson`, the others pass `image: null` to local helpers; `test/models/lore_test.dart:13`.
- **POI `quest:` — 6 files** construct `PointOfInterest(… quest: null)`: `screens/innkeeper/innkeeper_panel_screen_test.dart:44`, `mainScreen/main_screen_test.dart:652`, `tabs/map/world_map_availability_test.dart:201`, `tabs/map/world_map_teleport_test.dart:40`, `tabs/map/teleport_pawn_layer_test.dart:45`, `mainScreen/components/teleport_mode_landing_test.dart:32`.
- **Harness:** `test/helpers/journal_harness.dart` `journalCharacter` :38-65 spreads a `spellbookCharacterJson` map into `status` and `assets` (:46, :49, :60) and writes `'wearedEquipment': <String, dynamic>{}` (:61); `pumpJournalPage` :115-… needs **no new provider** in this phase (no new cubit). `test/helpers/spells_harness.dart` is SVG seeding only. `journalCharacter` has no pets parameter: the companion tests build their own character (`companion_section_test.dart:42`).

### F7. D-06 `Lore.imagePath` [VERIFIED: codebase]
- Wire: `lore_queries.dart:5` (`_LoreFields.full`, documents `lores` and `lore`) and `city_queries.dart:19` (`relatedLore { id description image }`, document `cities`). The lore refs of quests, results and `useItem` select `id name [type|description]` only.
- Model `lore.dart`: ctor :6, field :16, `fromJson` :29, `toJson` :62, `copyWith` :66/:74, `props` :84. `Lore(` is constructed only inside the model.
- Readers (lib): `screens/splash/cubit/splash_cubit.dart:81` (image warmer), `tabs/library/components/lore_card.dart:66, :70`, `tabs/map/components/city_modal.dart:24` (twice; **formatter-dirty file**), `tabs/map/components/travel_confirmation_sheet.dart:89`.
- Pins: `test/graphql/lore_documents_test.dart:14` (`'id image type name description relatedLore { id name }'`), `test/graphql/travel_documents_test.dart:170-174` (`'relatedLore { id description image }'`).
- `imagePath` already appears on 101 lines of 46 lib files (`Enemy`, `CharacterInfos`, enum getters): acceptance greps must be anchored (`lore.imagePath`, `json['imagePath']` inside `lore.dart`), never a bare count.

### F8. POI model [VERIFIED: codebase + probes]
- `lib/models/point_of_interest.dart`: `type` :27, `location` :28-30, `quest` ctor :15, field :22, parse :32, `toJson` :43, `copyWith` :51/:58, `props` :63 (imports `quest.dart` :2 — a model cycle that disappears with the field).
- **Nothing selects `type`, `quest` or `city` on a POI**: `LocationFragment.fields` = `id location` (`location_fragment.dart:11-14`; used by `character_fragment.dart:38`, `quest_fragment.dart:17`, `city_queries.dart:14`); `GetCity` selects `markerLocation { id } pointsOfInterest { id }` and is parsed by hand (`graphql.dart:347-362`), not with `City.fromJson`.
- Probes: P01 a valid `type: ['city']` throws `_TypeError` (and P06: even `type: []`), so the field has never been parsed successfully; P02/P03 a POI without `location` throws `NoSuchMethodError`; P04/P05 a short list throws `RangeError`; P08 non-numbers throw `_TypeError`; P07 `{id, location:[a,b]}` is the only shape that parses. The BE enum `PoiType` has `demonicPortal`, the FE enum does not (script diff this session) → the lenient list must drop unknown names.
- `latLngFromWire` (`wire_lat_lng.dart:8-12`) is documented as strict on purpose («un POI rotto è un difetto di dati che deve emergere»). Recommended reading of D-08 «guards `location`»: **absent or null → `location: null`; present → the strict helper as today** (OQ4).
- Existing test: `test/models/point_of_interest_test.dart` (2 cases on the location order only).
- **Removal of `quest` is not gated** (never selected): model field + the 6 test constructors of F6.

### F9. `tool/schema_check` and the gate [VERIFIED: run]
- Registry `tool/schema_check/schema_check_documents.dart:42-90`: **46 entries, and it stays 46** (no new operation). The four count pins (`test/tool/schema_check_documents_test.dart:32-34`, `test/graphql/shop_documents_test.dart:128`, `travel_documents_test.dart:178-179`, `loot_fragment_test.dart:124-125`) do not move.
- Baseline this session: `dart run tool/schema_check/dump_documents.dart <dir>` → «dumped 46 documents»; `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` → 46 × OK against BE `origin/develop` `bc92fb6f`.
- Dumped documents that contain a removed name today (the ones the flip must change): `character`, `characterUpdated`, `equipment`, `cities`, `lore`, `lores`. Documents that only gain selections: `GetCityShop` (through `PetFragment`), `questResultReceived`, `questResult`, `unacknowledgedQuestResults`.
- BE SDL today (`bc92fb6f`, read-only): `Enemy { baseWeaknesses: [String!]! … energyWeaknesses: [String!]! }`, `Pet { buyPrice currentLifePoints damages id imagePath maxLifePoints maxXp name sellPrice sellable speedModifier xp }`, `CharacterAssets { activeSpells ownedEquipments ownedItems ownedPets: [Pet!]! pet wearedEquipment }`, `CharacterStatus { … spellStates: [SpellState!]! spells: [Spell!]! … }`, `SpellState { recoveries spell: Spell! usages }`, `Equipment { … foots … }`, `PointOfInterest { city id location quest: ID type }`, `Lore { description id image name relatedLore type }`, `QuestResult` without `petXpGained`. `grep -cF`: `type Weaknesses` 0, `type OwnedPet` 0, `petXpGained` 0, `wornEquipment` 0, `feet` 0, `attack: Damages!` 0, **`imagePath` 4**; `energyWeaknesses` 1, `baseWeaknesses` 1, `wearedEquipment` 1, `foots` 2, `activeSpells` 1.
- **The gate list of the REPO-RULES needs block-anchored checks (C1):** `imagePath ≥ 1` is already true today; the absence of `CharacterStatus.spells` cannot be grepped (`Enemy.spells: [Spell!]!` stays); `active: Boolean!` and `ownedPets: [OwnedPet!]!` are not in the list. Use `awk '/^type <T> /,/^}/'` per type: `Lore` contains `imagePath` and no `image:` line; `SpellState` contains `active: Boolean!`; `CharacterStatus` has no `spells:` line; `CharacterAssets` contains `ownedPets: [OwnedPet!]!` and `wornEquipment`, no `activeSpells`; `Equipment` and `enum SlotType` contain `feet`, no `foots`; `Pet` contains `attack: Damages!`, `defense: Damages!`, `maxXp`, no `damages:`/`xp:`/`currentLifePoints:`; `OwnedPet { currentLifePoints pet xp }`; `QuestResult` contains `petXpGained: Int!`; `PointOfInterest` has no `quest:`; `Weaknesses { base energy }`; `input EquipItemRequest` still has `slotType: SlotType!`; `equipment(id: String!): Equipment!` still exists.

### F10. Device E2E shape (last plan, human checkpoint)
Pattern 18-13: `autonomous: false`, re-check the gate, `19-HUMAN-UAT.md`, results only from the user's words, `requirements mark-complete` per passed id, FE `BACKEND-NOTES.md`. Prerequisites owned by the orchestrator after the BE merge: BE boot with the one-off migrator, `maxXp` of the 44 pets written at DB (BE D-05, else every row reads «… / 100»), optionally one pet with a curated `defense` (else the «Difesa» line cannot be seen), a test character with an owned and equipped companion, ≥ 2 known spells and boots in the inventory. Steps (CONTEXT D-09): (1) Journal «Compagno»: owned rows with «Esperienza: N / maxXp», slot and «Al tuo fianco» as before, equip/unequip; (2) companion card/rows: attack line, «Difesa» when present, shop buy/sell lists unchanged, «già posseduto» still filtered; (3) Journal «Magie imparate»: every known spell listed, equipped ones in the slots, usages and countdown as before, equip/unequip with the optimistic fade, slots-full refusal, the order of the slots (OQ2); (4) mannequin: equip and unequip boots (`feet` on the wire), another slot as control; (5) a won fight with the companion equipped → «Il tuo compagno guadagna N PE» after the xp line, the Journal row grows by N; a fight without companion → no line; (6) Map: markers, quest pawns, travel, city sheet image; (7) Library: lore images load (438 lore with an image), a book opens; (8) innkeeper completion form lists the equipped spells (same `Spellbook`).

### Anti-Patterns to Avoid
- Selecting `weaknesses`, `PointOfInterest.type`/`quest` or `Enemy.locations` «because the model has them»: nothing reads them (`quest_result_documents_test.dart:86-88` pins «never selects enemy locations»).
- Renaming `SlotType.foots` or the `Equipment.toJson` key alone (F4 coupling).
- Deriving `active` on the FE from another list, or computing the companion xp / cap (rule 4).
- A lenient parse that returns a `null` enum where widgets use `!` (`lootItem.effect!` `loot_item_card.dart:43`, `equipType!` `equipment_item_card.dart:88`, `equipment_box.dart:38`, `equipment_name.dart:21`, `rarity!` `:30`, `city.type!` `city_marker.dart:26-28`, `city_markers_layer.dart:36, :53`): it moves the crash from the parser to the build. Drop the entry at the list boundary instead (§MODEL-04).
- Leaving a legacy reader in the tree after the gated wave.
- A bare-count acceptance grep on `imagePath`, `image`, `spells`, `pet` (hundreds of unrelated hits).

## The window problem — recommended sequencing per area

**Precedent (Phase 14, `infos.enemies`):** models (14-01, 14-02) and fragments (14-03) were switched together **before** the gate, with no dual shape; 14-03 states «from this commit the app can no longer talk to BE `develop` before the BE Phase 13 merge: no device run until 14-11». The gate plan 14-10 only proved the names on the merged SDL and ran the schema check. The branch was unusable against the old BE in between; `develop` was safe because the PR merged after the phase. Phase 18 (additive) instead kept every fragment selection for the gated plan. `19-REPO-RULES.md` chose the stricter rule («every fragment/document change is gated»), so the choice here is between **(a)** a model that reads both shapes during the window and **(b)** model + fragment together in the gated wave.

| Area | Selected today? | Recommendation | Why |
|------|-----------------|----------------|-----|
| Weaknesses (D-01) | no | **plain pre-gate model change**, no dual shape, no fragment | nothing on the wire (F1) |
| `PointOfInterest.quest` (D-06) | no | **plain pre-gate removal** | nothing on the wire (F8) |
| Catalogue `Pet`: `attack`/`defense`, no `xp`/`currentLifePoints`/`damages` (D-12, D-03) | no | **plain pre-gate model change**; `attack`/`defense`/`maxXp` selections in the gated flip | absent keys parse to `null` today and tomorrow (probe P65) |
| `ownedPets` entries (D-03) | yes (`ownedPets { PetFragment }`) | **(a)**: `OwnedPet.tryFromJson` accepts the entry `{ pet: {…}, xp, currentLifePoints }` and, during the window only, a bare pet map (`id` string, no `pet` key) → `OwnedPet(pet, xp: 0, currentLifePoints: 0)`; gated wave flips the fragment and deletes the branch RED-first | one branch of ~3 lines; the 9 consumer files and the fixtures move before the gate; no wrong line can show because `maxXp` is not selected yet (`companionXpLine` → null) |
| `wornEquipment` / `feet` (D-04) | yes + **request enum** | **(b)**: one atomic gated commit (model, enum, request, mannequin, `journal.dart`, fragment slot list, harness) | the enum value is sent on the wire (F4); a dual read would need a wire-name indirection on `SlotType` to be deleted later; it is a 24-line mechanical rename with no consumer to prepare |
| `spellStates.active`, no `spells`/`activeSpells` (D-05) | yes (three lists) | **(a)**: the new model (`SpellState { spell, usages, recoveries, active }`, single non-null list) lands pre-gate; during the window **one pure legacy reader at `Character.fromJson`** builds that list from today's three wire lists (known = `status.spells` order; state by id from `status.spellStates`, else `usages = activeSpells usages ?? maxUsages`, `recoveries = []`; `active` = id present in `assets.activeSpells`) whenever the payload still has `status.spells`; `Spellbook`, `SpellsCubit` and the 15 test files move pre-gate on new-shape fixtures; gated wave flips the fragment and deletes the reader + its tests | the riskiest refactor (optimistic view, ordering) is done and reviewed before the BE merge; the gated step shrinks to a selection change. Note: it needs both `status` and `assets` JSON, hence `Character.fromJson`, not `CharacterStatus.fromJson`. During the window the slot order is already the learning order (OQ2) |
| `Lore.imagePath` (D-06) | yes (3 documents) | **(b)**: atomic gated rename (model + 2 query files + 5 readers + 2 fixture builders + 2 pins) | a `json['imagePath'] ?? json['image']` dual read is possible but buys nothing: 7 lib lines, no logic |
| `petXpGained` (D-03) | additive | **model, line and sheet pre-gate** (lenient → 0, line hidden); selection in the gated flip | Phase 18 pattern |
| FE-only parser fixes (D-08) | — | **pre-gate, first** | no wire dependency |

Alternative to put to the orchestrator (OQ3): **(c) the Phase 14 way** — no legacy readers at all, model + fragment + consumers switched pre-gate on the branch, the branch not runnable against today's BE until the merge. It removes ~40 lines of temporary code and two RED-first deletions, but contradicts the REPO-RULES sentence and blocks any device use of the branch before the BE merge.

## MODEL-04 — parser sweep (D-08)

Scope: every `fromJson` under `lib/models/` (`byName`: 24 call sites in 15 files; `?.map(` assigned to a `List`: 2; unguarded index on a JSON value: 1; strict per-entry casts in lists). Classified by **blast radius**: a throw inside the character payload reaches `KlimmeckGraphQl.getCharacter` (`graphql.dart:452-471`, no boundary → `CharacterCubit.loadCharacter` emits `CharacterError`, `character_cubit.dart:67-83`) or `_characterFrom` (`graphql.dart:275-284`, `FormatException` → the live event is lost): **the whole character is unusable**. The SDL types these fields as free `String`s (`LootItem.effect: String!`, `rarity: String`, `EquipmentItem.equipType: String!`, `BaseDamage.type: String!`, `EnergyDamage.type: String!`, `CharacterStatus.title: String!`), and the content is curated by hand at DB.

### Real crash risks (the MODEL-04 plan)

| # | File:line | Pattern | Probe | Blast radius | Proposed fix | Test exists? |
|---|-----------|---------|-------|--------------|--------------|--------------|
| 1 | `point_of_interest.dart:27` | `json["type"]?.map(…byName…)`: an `Iterable` where `List<PoiType>?` is declared | P01, P06 `_TypeError` on ANY non-null `type` | latent (never selected); every POI the day it is | lenient list: `is List` → names through `PoiType.values.asNameMap()`, unknown dropped (BE has `demonicPortal`, FE not); else `null` | `point_of_interest_test.dart` (no `type` case) |
| 2 | `point_of_interest.dart:28-30` | `json["location"][0]` with no null guard | P02, P03 `NoSuchMethodError` | character (`status.location`), all cities (`markerLocation`), a quest (dropped by its boundary) | absent/null → `location: null`; present → strict `latLngFromWire` as today (OQ4) | same file (order only) |
| 3 | `enemy.dart:40-42` | `json["locations"]?.map(…byName…)`: same `Iterable` bug | P10 `_TypeError` | latent, fenced by the «never selects enemy locations» pin | same lenient list as #1 (share one helper for `List<PoiType>`) | none (`enemy_test.dart` missing) |
| 4 | `enemy.dart:43-52` | `byName` on the two weakness lists | P12 `ArgumentError` | latent | replaced by `Weaknesses` (D-01, F1) | none |
| 5 | `base_damage.dart:11`, `energy_damage.dart:12`, `damages.dart:12-19` | `byName` on a `String!` wire type; `json['base'].map` on a non-list (P56) | P54, P55 `ArgumentError` | **character** (`wornEquipment`, `ownedEquipments`; from this phase also `pet.attack`/`defense` on `assets.pet` and every owned pet), the whole shop pool, the equipment catalogue | `Damages.fromJson`: `is List` guards and **drop the entry** with an unknown or missing `type` (readers index `base![i].type!`, `equipment_info_sheet.dart:153-262`) | none (`damages` / `base_damage` / `energy_damage` have no test) |
| 6 | `spell.dart:34-36` → `energy_damage.dart:12` | `byName` on the spell's `energyDamage.type` | P58 `ArgumentError` | **character** (every known spell; `addedSpell` of worn/owned equipment) | unknown type → `energyDamage: null` (readers are null-safe: `spell_info.dart:27`, `spell_card.dart:32`) | none for this case |
| 7 | `character_status.dart:78-80` | `TitleType.values.byName(json['title'])`, wire `String!` | P20, P95 `ArgumentError` | **character** | `asNameMap()[…]` → `null` (field already nullable; readers `quest_viewer.dart:24`, `quest_scope_listener.dart:68` use `?.title`) | `character_status_test.dart` (no unknown-title case) |
| 8 | `loot_item.dart:46-51` | `byName` on `effect` (`String!`) and `rarity` (`String`) | P50, P51, P63 `ArgumentError` | **character** (`ownedItems`), the whole shop pool, the loot catalogue | keep `LootItem.fromJson` strict (widgets use `effect!`); add a lenient **entry boundary**: `AssetQuantity.tryFromJson` (malformed or unknown item → `null`) used by `CharacterAssets.ownedItems` / `ownedEquipments` (`character_assets.dart:28-37`) and `CityShop._assets` (`city_shop.dart:38-42`): the entry is dropped, the character and the shop survive | `loot_item_test.dart`, `character_assets_test.dart`, `city_shop_test.dart` (no unknown case) |
| 9 | `equipment_item.dart:37-39, :49-51` | `byName` on `equipType` (`String!`) and `rarity` | P52, P53, P57 `ArgumentError` | **character** (owned and worn), shop, catalogue | same boundary as #8 for the lists; for the worn slots (`equipment.dart:28-44`) a malformed item → slot `null` (`EquipmentItem.tryFromJson`), probe P66 | `equipment_item_test.dart` (no unknown case); no `equipment_test.dart` |
| 10 | `city.dart:35`, `graphql.dart:318` | `CityType.values.byName` (SDL enum, 33 = 33 today) inside `citiesData.map(City.fromJson)` with no per-entry boundary; also `area` points indexed unguarded (`city.dart:36-46`, P43, not selected) | P40 `ArgumentError`, P41 | **every city of the map at cold start** the day the BE gains a city type before the app (it happened with `talmvereVillage`) | `City.tryFromJson` + `getCities` keeps the cities that parse (drop the one city; widgets use `city.type!`) | `city_test.dart` (no unknown case) |
| 11 | `character_assets.dart:47-53` | `Pet.fromJson(x as Map)` per owned pet | P61 `_TypeError` | character | covered by `OwnedPet.tryFromJson` (D-03) | `character_assets_test.dart` |
| 12 | `city_shop.dart:24-28` | `Pet.fromJson(x as Map)` per pool pet (a pet with unknown damage types after D-12) | P64 | the whole shop pool | `Pet.tryFromJson` per entry, dropped (after #5 the damage types no longer throw) | `city_shop_test.dart` |

### Looked at and left strict on purpose (not in the plan)
- `quest_infos.dart:34`, `quest_requirements.dart:37-39`, `adventurer_slot.dart:16` (`byName` on quest type / titles): behind `Quest.tryFromJson` (`quest.dart:38-45`), the Phase 6 board rule D-20 C6 — an unknown type or title drops that quest only (probes P83–P85). `CharacterQuests` parses `{ id }`-only quests with `Quest.fromJson` safely (P80, P82).
- `quest_result.dart` reward/consumable items (`:201`): behind `QuestResult.tryFromJson`; an unknown item drops the result (existing behaviour, not a crash).
- `user.dart:28` `RoleType.byName` (SDL enum): boundary at `graphql.dart:807-815` (`FormatException`, by design).
- `character_infos.dart:31-41` (`sex`, `race`, `classType`, `pronoun`, wire `String!`; P30–P33): written only by the BE-validated creation flow; a lenient `null` would crash `journal.dart:174` (`infos!.sex!`). Low probability, not recommended here (OQ5 if the orchestrator wants them).
- `pending_quest.dart` `DateTime.parse` (P81): the wire type is the `DateTime` scalar. `lore.dart` `_typeFrom`, `spell.dart` `useType`, `city.dart` `size`: already `asNameMap()`.
- `race_traits.dart:16`, `spell_state.dart`, `awaiting_aid.dart`, `active_travel.dart`, `quest_cure.dart`, `loot_recovery.dart`: already behind `tryFromJson`.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Lenient enum lists | a `try { byName } catch` per field | `Enum.values.asNameMap()` + `nonNulls` (pattern `injuryTypesFrom`, `injury_type.dart:198-202`) | 2 precedents already; one helper for `List<PoiType>` shared by POI and enemy |
| Entry boundaries | nullable enums + `!` in widgets | `tryFromJson` returning `null` + `whereType`/`nonNulls` at the list (pattern `SpellState.tryFromJson`, `character_status.dart:90-95`) | widgets keep their non-null assumptions |
| Spell view logic | new derivations in widgets or the cubit | `Spellbook.of` (the only funnel) | 5 call sites already agree on it |
| Damages selection | a new inline `base { type power } …` | `DamagesFragment.fields` (`damage_fragment.dart:31-40`) | one place |
| Schema validation | a new script | `dump_documents.dart` + `validate_documents.js` (Phase 18 gate) | 46 documents already registered |
| Companion strings | literals in widgets | pure helpers in `lib/utils/item_lines.dart` next to `companionSpeedLabel` | file doc: every item/companion line lives there |

## Conflicts (CONTEXT / REPO-RULES vs the code)

- **C1 — gate greps.** `imagePath ≥ 1` is satisfied by today's SDL (4 matches: `Enemy`, `Pet`, `CharacterInfos`, input); `activeSpells = 0` is fine but the removal of `CharacterStatus.spells` and the arrival of `SpellState.active`, `ownedPets: [OwnedPet!]!` and `defense: Damages!` are not checked. Recommendation: block-anchored `awk` checks per type (F9) in the gate plan, in addition to the listed greps.
- **C2 — «the companion card/rows that print the pet damages today print the attack» (CONTEXT D-12) / «the line of today prints `attack`» (REPO-RULES).** No widget prints pet damages and `PetFragment` has never selected `damages`. Both the attack line and «Difesa: …» are **new visible copy** with no existing text format to copy (the only damages rendering in the app is the icon grid of `equipment_info_sheet.dart:130-270`). Needs the orchestrator's format ruling (OQ1).
- **C3 — «the single file that reads the two lists today (8 lines)» (D-01), «fragments updated».** The 8 lines are the model itself; there is no reader and no fragment selection (F1). «Fragments updated» = nothing to update.
- **C4 — «`PointOfInterest.quest` leaves the model and the fragment» (D-06).** It is in no fragment; `lib/graphql/fragments/location_fragment.dart` (canonical ref) needs no change. Same for `lib/graphql/fragments/damage_fragment.dart` cited for the weaknesses.
- **C5 — «`foots` … (fragment, `Equipment` model, `SlotType` enum, the Journal mannequin and the equip request): names only».** True, with two additions: a second document (`equipment`, `character_queries.dart:23-30`) and the `journal.dart:318-321` coupling between `Equipment.toJson` keys and `SlotType.name`.
- **C6 — D-05 «the Journal spells section … adapts».** The section and its widgets do not change; the change is in `Spellbook`, `SpellsCubit._matches`, the models and the fragment. One more reader not listed in the CONTEXT: the innkeeper completion form (`participant_draft.dart:95`).
- **C7 — measured impact.** Confirmed: `foots` 13 / 4, `wearedEquipment` 11 / 3, `activeSpells` 9 / 4, `spellStates` 9 / 3, `maxActiveSpells` 11 / 4, weaknesses 8 / 1 each, `maxXp` 7 / 1, `Pet` type in 16 files. To add: `ownedPets` itself is 22 lines / 5 files; `Lore.image` 12 lines / 5 lib files + 2 query files; `PointOfInterest.quest` 7 lines / 1 file + 6 test constructors; tests carry the old spell shapes in 15 files.

## Common Pitfalls

### Pitfall 1: `Equipment.toJson` keys are matched against `SlotType.name`
`journal.dart:315-326`. Rename the key (`equipment.dart:52`), the field, the enum member (`slot_type.dart:93`) and the fragment slot (`equipment_fragment.dart:96`) in one commit; pin it with a test «every `SlotType` name is a key of `Equipment.toJson()`».

### Pitfall 2: `SlotType.name` is a wire value
`equip_item_request.dart:17`. `feet` before the BE merge = `equipItem` refused for boots. The whole D-04 rename is gated.

### Pitfall 3: `SpellState` without the full spell
Removing `status.spells` while `spellStates` still selects `spell { id }` leaves the Journal with names, damages and `maxUsages` all null. The fragment flip must change `spell { id }` to `spell { ${SpellFragment.fields} }` in the same commit that drops `spells { … }`; the two pins `character_fragment_test.dart:65, :112` move RED first.

### Pitfall 4: slot order
After the single list the equipped order is the list order. An optimistic overlay that still appends a pending equip last makes the card jump when the subscription confirms. One rule for server and optimistic view (F5 point 6).

### Pitfall 5: a legacy reader that outlives the gate
Each window branch (`OwnedPet` bare pet, legacy spell lists) is deleted in the gated wave with a RED test first («a bare pet map is dropped (D-03)», «a payload with `status.spells` and no `active` yields no legacy states (D-05)»). The gate plan greps `grep -rn "activeSpells\|wearedEquipment\|foots" lib test tool` → nothing.

### Pitfall 6: lenient `null` + `!`
See Anti-Patterns: drop entries, do not null enums that widgets dereference.

### Pitfall 7: `Character.fromJson` is called without a boundary in `getCharacter`
`graphql.dart:471`. Whatever the legacy spell reader does, it must not throw on a partial payload (tests build characters with `status` only, `assets` only, or neither: `spell_fixtures.dart:57-65`, `companion_cubit_test.dart:22`, `character_status_test.dart:527-528`).

### Pitfall 8: `props` and `toJson` completeness
`CharacterAssets.props` :66-73, `CharacterStatus.props` :158-175, `Pet.props` :109-122, `QuestResult.props` :261 onwards, `SpellState.props` :46: a field missing from `props` makes `BlocSelector<CharacterCubit, …, Character?>` (`companion_section.dart:38`, `spells_section.dart:121`) swallow the update — `active` and the owned pet `xp` are exactly the values that change alone. `CharacterStatus.copyWith` :125-155 carries six fields by hand (:148-153): keep `spellStates` there.

### Pitfall 9: fixture funnel signature
`spellbookCharacterJson(spells:, activeSpells:, spellStates:)` is called from 12 files. Changing its signature and its callers in the same plan as `Spellbook` keeps every intermediate commit compiling; a half-migrated builder that emits both shapes hides bugs in the legacy reader.

### Pitfall 10: pre-gate vs post-gate builds
Before the gated wave the branch runs against today's BE (nothing new is selected; legacy readers active). After it the branch works only against a BE with Phase 19: say it in the SUMMARY of the gated plan; no device run in between.

### Pitfall 11: formatter-dirty files
`city_modal.dart` is the only dirty file that must be edited (`lore.image` :24): formatting it reflows the file — note it in the SUMMARY. Do not edit `damage_fragment.dart`, `location_fragment.dart`, `damage_type.dart`, `energy_type.dart`, `equip_type.dart`, `asset_item.dart` unless a fix needs them (the MODEL-04 boundaries can live in `asset_quantity.dart`, `damages.dart`, `base_damage.dart`, `energy_damage.dart`, all clean).

### Pitfall 12: the companion card has four label rows at most
`CardLabel` is `cardSize / 6` high (`card_label.dart:15`); name + speed + attack + defense fit, the xp line does not belong on the card (it goes to the row, F2).

## Code Examples

### Lenient weaknesses (pattern `injuryTypesFrom`, `injury_type.dart:198-202`)
```dart
factory Weaknesses.fromJson(Object? json) {
  if (json is! Map<String, dynamic>) return const Weaknesses();
  return Weaknesses(
    base: _namesFrom(json['base'], DamageType.values.asNameMap()),
    energy: _namesFrom(json['energy'], EnergyType.values.asNameMap()),
  );
}

static List<T> _namesFrom<T>(Object? json, Map<String, T> byName) =>
    json is List
    ? List<T>.unmodifiable(json.map((name) => byName[name]).nonNulls)
    : const [];
```

### Owned pet entry with the window branch (pattern `Pet.tryFromJson`, `pet.dart:58-61`)
```dart
static OwnedPet? tryFromJson(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  final pet = Pet.tryFromJson(json['pet']);
  final xp = json['xp'];
  final life = json['currentLifePoints'];
  if (pet != null && xp is num && life is num) {
    return OwnedPet(pet: pet, xp: xp.toInt(), currentLifePoints: life.toInt());
  }
  // window only (BE before Phase 19): a bare catalogue pet; deleted at the gate
  final bare = Pet.tryFromJson(json);
  return bare == null ? null : OwnedPet(pet: bare, xp: 0, currentLifePoints: 0);
}
```

### Active rule of the single list (replaces `_serverActiveById` / `_optimisticActiveById`, `spellbook.dart:158-186`)
```dart
bool isActive(SpellState state) => switch (pending[state.spellId]) {
  SpellOperation.equip => true,
  SpellOperation.unequip => false,
  null => state.active,
};
final active = [for (final state in states) if (isActive(state)) state];
```

### Gate, block-anchored (addition to the REPO-RULES greps)
```bash
awk '/^type Lore /,/^}/' "$SCRATCH/schema.gql"            # imagePath: String   and no «image:» line
awk '/^type SpellState /,/^}/' "$SCRATCH/schema.gql"      # active: Boolean!
awk '/^type CharacterStatus /,/^}/' "$SCRATCH/schema.gql" | grep -c '^  spells:'   # 0
awk '/^enum SlotType /,/^}/' "$SCRATCH/schema.gql"        # feet, no foots
```

## State of the Art

| Old | New | Impact |
|-----|-----|--------|
| three spell lists joined on the FE (`Spellbook._usagesOf` fallback table) | one list, `active` per entry | join and fallbacks deleted; slot order = learning order |
| owned pets = catalogue pets | entries with state on the character | first per-character pet state on the FE |
| non-additive contract consumed by switching the branch pre-gate (Phase 14) | gated fragments + legacy readers during the window (REPO-RULES of this phase) | the branch stays runnable against today's BE until the gated wave |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The merged BE keeps `equipment(id: String!): Equipment!` and `EquipItemRequest.slotType: SlotType!` with the member `feet` [CITED: BE `19-REPO-RULES.md` «membro `feet`», «le mutation esistenti tengono nome, argomenti»] | F4, F9 | the `equipment` document or the equip request fails validation at the gate (caught by the schema check, not on the device) |
| A2 | After the BE migrator every known spell has a `spellStates` entry [CITED: BE CONTEXT D-07 «per ogni magia di `spells` la voce di `spellStates`»] | F5 | a known spell without a state would vanish from the Journal (visible in the E2E) |
| A3 | The BE serves `spellStates` in learning order and confirms an equip without reordering [CITED: BE D-07 «nell'ordine di apprendimento»] | F5, Pitfall 4 | the optimistic slot order differs from the confirmed one (a one-frame jump) |
| A4 | `OwnedPet.pet` is populated and non-null on the wire; `ownedPets` keeps the purchase order [CITED: contract table `pet: Pet!`] [ASSUMED: order] | F2 | an entry with a null pet is dropped by the lenient parser; a different order only changes the list order |
| A5 | `QuestResult.petXpGained` is present on ambush results too [CITED: BE D-04 «imboscata vinta»; BE REPO-RULES flags it as a possible open question] | F3 | no companion line on the ambush carousel (lenient → 0) |
| A6 | A negative or non-numeric `petXpGained` is «malformed» → 0 [ASSUMED] | F3 | none visible (line hidden) |
| A7 | `maxXp` of the 44 pets is written at DB before the device E2E [CITED: BE D-05, content outside the repo] | F10 | rows read «Esperienza: N / 100» for every pet |

## Open Questions

1. **OQ1 = C2 — format and place of the attack / «Difesa» lines (new visible copy).** Nothing prints pet damages today. Proposal: text helpers in `item_lines.dart`, one line each, base then energy, lowercase type label + power — «Attacco: tagliente 12, fuoco 5» and «Difesa: contundente 4» — hidden when the list is empty; on `CompanionCard` as two `CardLabel`s and on `CompanionRow` (shop and transaction lists) as two `Text`s. Needs the label of the first line («Attacco: …» is not in the fixed copy) and a yes/no on showing them in the shop rows. User/orchestrator.
2. **OQ2 — slot order of the equipped spells.** After BE 19 the slots follow the learning order (the equip order is gone from the BE); with the recommended window strategy this is visible as soon as the pre-gate spell plan lands. It is a visible difference the CONTEXT does not list. Accept (recommended: it is the only order the BE can confirm), or ask the BE for an explicit order.
3. **OQ3 — window strategy.** Recommended mix: legacy readers for pets and spells, gated atomic renames for `feet`/`wornEquipment` and `Lore.imagePath`. Alternatives: (b) everything of D-03/D-05 in the gated wave (no temporary code, but the largest refactor waits for the BE merge), or (c) the Phase 14 way (switch the branch pre-gate, no device until the merge; contradicts the REPO-RULES sentence).
4. **OQ4 — `PointOfInterest.location` guard.** Recommended: absent/null → `null`, present-but-malformed → strict as today (documented contract of `latLngFromWire`). Alternative: fully lenient (`tryLatLngFromWire`, which also applies the map bounds).
5. **OQ5 — breadth of MODEL-04.** The table proposes 12 rows (two plans). Rows 5–10 and 12 go beyond the «same pattern as the POI» wording of D-08 (they are `byName` on free-string wire fields inside the character payload). Confirm the scope, or keep rows 1–4 + 11 only and file the rest as a follow-up. `CharacterInfos` enums are left out unless asked.
6. **OQ6 — select `OwnedPet.currentLifePoints`?** The contract and the FE model carry it; nothing displays it (companion life in combat is deferred). Recommended: select and parse it (model fixed by the REPO-RULES), display nothing.
7. **OQ7 — gate list amendment (C1).** Add the block-anchored checks of F9 to the «Gate» paragraph of the REPO-RULES.

## Formatter state of the candidate files [VERIFIED: `dart format --output=none --set-exit-if-changed <file>`, one by one, 76 lib/tool + 67 test files]

**Dirty (7, all in `lib/`):** `lib/models/asset_item.dart`, `lib/models/enums/damage_type.dart`, `lib/models/enums/energy_type.dart`, `lib/models/enums/equip_type.dart`, `lib/graphql/fragments/damage_fragment.dart`, `lib/graphql/fragments/location_fragment.dart`, `lib/screens/mainScreen/tabs/map/components/city_modal.dart`. Only `city_modal.dart` must be edited (Pitfall 11).

**Clean:** every model the phase touches (`enemy`, `pet`, `equipment`, `slot_type`, `character*`, `spell_state`, `spellbook`, `active_spell`, `point_of_interest`, `lore`, `city`, `city_shop`, `damages`, `base_damage`, `energy_damage`, `loot_item`, `equipment_item`, `asset_quantity`, `quest_result`, `trade_selection`, `equip_item_request`, `participant_draft`), the five fragment/query files to flip (`character_fragment`, `pet_fragment`, `equipment_fragment`, `quest_result_fragment`, `lore_queries`, `city_queries`, `character_queries`), `journal.dart`, the mannequin and equipment widgets, every companion and spells widget/cubit, `shop.dart`, `quest_result_sheet.dart`, `splash_cubit.dart`, `lore_card.dart`, `travel_confirmation_sheet.dart`, `item_lines.dart`, `quest_outcome_lines.dart`, `graphql.dart`, `schema_check_documents.dart`, and all 67 test/helper files that carry the old shapes.

## F11. Pinned tests to update RED first [VERIFIED: codebase]

| File:line | Pin | Change | Wave |
|-----------|-----|--------|------|
| `test/graphql/character_fragment_test.dart:54-68` | `'spellStates { usages recoveries spell { id } }'` | → `usages recoveries active spell { <SpellFragment.fields> }` | gated |
| `test/graphql/character_fragment_test.dart:109-114` | `'spellStates { usages recoveries spell { id } } unlockedLore }'` | re-anchor (`… } unlockedLore }` with the new block); new «statusFields no longer selects spells (D-05)» | gated |
| `test/graphql/character_fragment_test.dart:132-144` | `'pet { $pet }'`, `'ownedPets { $pet }'` | → `'ownedPets { xp currentLifePoints pet { $pet } }'` | gated |
| `test/graphql/character_fragment_test.dart:70-85, :182-221` | recorded `characterUpdated` payload in the old shape | passes through the legacy reader during the window; rewritten in the new shape when the reader is deleted | gated |
| new in the same file | — | «assetsFields selects wornEquipment with the feet slot (D-04)», «assetsFields no longer selects activeSpells (D-05)» | gated |
| `test/graphql/shop_documents_test.dart:83-91` | exact `PetFragment.fields` string | + `maxXp attack { … } defense { … }` (position after `sellable` or at the end: fix it in the test first) | gated |
| `test/graphql/shop_documents_test.dart:77-81` | `'pets { $petFields }'`, no `imagePath` in `GetCityShop` | unchanged (follows the fragment) | — |
| `test/graphql/lore_documents_test.dart:14` | `'id image type name description relatedLore { id name }'` | → `imagePath` | gated |
| `test/graphql/travel_documents_test.dart:170-174` | `'relatedLore { id description image }'` | → `imagePath` | gated |
| `test/graphql/quest_result_documents_test.dart` | adjacency pins :91, :95-103, :106, :126 | unchanged; new «selects petXpGained after xpAfter (D-03)» | gated |
| registry count 46 (4 places, F9) | — | unchanged | — |
| `test/models/character/character_status_test.dart:103-177, :527-528` | `spellStates` null semantics, `assets.activeSpells` empty | non-null list, `active`, full spell; `activeSpells` assertion removed | pre-gate (spell model) |
| `test/models/spell/spell_state_test.dart` (19 refs) | `'spell': {'id': …}`, `toJson` «writes the spell as an id object» :72 | full spell + `active`; lenient `active` cases | pre-gate |
| `test/models/spell/spellbook_test.dart` (:79-190 join, :198-273 overlay, :276-340 intent) | old three-list join, fallback table, append order | rewritten on the single list; order rule (OQ2) | pre-gate |
| `test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart:23-28` | `_character(active:)` through `activeSpells` | through `spellStateJson(active:)`; the 33 cases keep their expectations | pre-gate |
| `test/helpers/fixtures/spell_fixtures.dart:31-81` | builders | new shape (`spellStateJson({spellId, usages, recoveries, active, spell})`, `spellbookCharacterJson({maxActiveSpells, spellStates})`); `activeSpellJson` deleted | pre-gate |
| `test/helpers/fixtures/pending_request_fixtures.dart:110-136` | innkeeper character with the three lists | new shape | pre-gate |
| `test/models/character/character_assets_test.dart:8-32` | `ownedPets: [petJson(), catPetJson()]`, `.ownedPets.map((p) => p.id)` | entries; malformed entry dropped; (window) bare pet accepted, then dropped at the gate | pre-gate / gated |
| `test/models/pet_test.dart` (12 refs) | `xp`, `currentLifePoints`, `damages` | `attack`, `defense`; the three removed | pre-gate |
| `test/helpers/fixtures/shop_fixtures.dart:8-31` | `petJson` | + `maxXp`, `attack`, `defense`; + `ownedPetJson` | pre-gate |
| `test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart:42`, `companionCubit/companion_cubit_test.dart:22`, `components/companion_outcome_listener_test.dart:24`, `tabs/shop/shop_test.dart:61-65, :225, :238` | `ownedPets` as bare pets | entries (`ownedPetJson`) | pre-gate |
| `test/shared/components/cards/companion_card_test.dart`, `test/shared/components/companion_row_test.dart` | name / speed / mark | + attack and «Difesa» cases (hidden when empty) | pre-gate |
| `test/shared/components/popup/quest_result_sheet_test.dart:116, :465, :920-929` | xp line cases | + «the companion line sits right after the xp line (D-03)», hidden at 0, shown without character xp | pre-gate |
| `test/helpers/fixtures/quest_result_fixtures.dart:71-131` | `questResultJson` | + `petXpGained` (default 0) | pre-gate |
| `test/helpers/journal_harness.dart:46-61` | spreads `status`/`assets` of the spell fixture; `'wearedEquipment'` | follows the fixture shape; `'wornEquipment'` | pre-gate / gated |
| `test/helpers/fixtures/lore_fixtures.dart:14`, `travel_fixtures.dart:107`, `test/models/lore_test.dart:13` | `'image'` key | `'imagePath'` (keep or rename the `image:` parameter: 6 call sites) | gated |
| 6 files of F6 | `PointOfInterest(… quest: null)` | parameter removed | pre-gate |
| `test/models/point_of_interest_test.dart` | 2 cases | + `type` list (known, unknown dropped, non-list), `location` absent / null | pre-gate |

No golden-image tests exist for these widgets (text/tree assertions only).

## Suggested plan breakdown

Sequential (REPO-RULES). Sizes: S ≤ 2 tasks / ≤ 6 files, M ≤ 3 tasks / ≤ 15 files, L more.

**Pre-gate (fixtures, no wire change):**
1. **19-01 POI and enemy parsers (M)** — `PointOfInterest`: lenient `type` list, `location` guard, `quest` removed (+ 6 test constructors); shared lenient `List<PoiType>` reader; `Weaknesses` + `Enemy.weaknesses`, `Enemy.locations` lenient. New `enemy_test.dart`, `weaknesses_test.dart`. MODEL-01, MODEL-04 (rows 1–4).
2. **19-02 Entry boundaries (M)** — `Damages` entry drop, spell energy type, `title`, `AssetQuantity.tryFromJson` in `CharacterAssets` and `CityShop`, worn-slot boundary, `City.tryFromJson` in `getCities`, pool pets. MODEL-04 (rows 5–10, 12; subject to OQ5).
3. **19-03 Pet models (M)** — `Pet.attack`/`defense`, removal of `xp`/`currentLifePoints`/`damages`; `OwnedPet` (+ window branch); `CharacterAssets.ownedPets` as entries + catalogue-pet getter; `shop.dart` one-liner; companion section/content compile through on `entry.pet`; fixtures `petJson` / `ownedPetJson`; the 6 `ownedPets` test files. MODEL-02.
4. **19-04 Companion lines and widgets (M)** — `companionXpLine`, attack / defense helpers (OQ1), `OwnedCompanionRow` xp line, `CompanionCard` and `CompanionRow` lines. MODEL-02.
5. **19-05 Companion xp on the result (S)** — `QuestResult.petXpGained`, `companionXpGainedLine`, sheet line after :187, fixture. MODEL-02.
6. **19-06 Spell state model (M)** — `SpellState` with full `spell` + `active`, non-null `spellStates`, legacy reader at `Character.fromJson` (window), new fixture builders; old fields still on the models so everything compiles. MODEL-03.
7. **19-07 Spellbook and cubit on the single list (M/L)** — `Spellbook.of`, `SpellsCubit._matches`, order rule (OQ2), removal of `CharacterStatus.spells`, `CharacterAssets.activeSpells`, `ActiveSpell`; `spellbook_test`, `spells_cubit_test`, section/content/journal/draft/innkeeper tests reshaped. MODEL-03.

**Gated on the BE Phase 19 merge:**
8. **19-08 Gate proof and the two renames (M)** — schema gate (REPO-RULES greps + block-anchored checks, BE handoff read), then D-04 atomically (model, enum, request, mannequin, `journal.dart`, slot list, harness; new `equipment_test.dart`, `equip_item_request_test.dart`) and `Lore.imagePath` atomically (model, 2 query files, 5 readers, fixtures, 2 pins). MODEL-01, MODEL-03.
9. **19-09 Wire flip and legacy removal (M)** — pins RED first; `character_fragment` (`ownedPets` entries, `spellStates { usages recoveries active spell { full } }`, no `spells`, no `activeSpells`), `pet_fragment` (`maxXp attack defense`), `quest_result_fragment` (`petXpGained`); delete the bare-pet branch and the legacy spell reader with their tests; recorded payload rewritten. MODEL-02, MODEL-03.
10. **19-10 Schema check and full gates (S)** — `dump_documents` 46 + `validate_documents.js` 46 × OK, full suite, analyzer, format of the added files, trailer grep, leftover-name grep (Pitfall 5), `19-VALIDATION.md`. MODEL-04.
11. **19-11 Device E2E (human checkpoint)** — F10 steps, `19-HUMAN-UAT.md`, FE `BACKEND-NOTES.md`, requirements closed. MODEL-01..04.

Dependencies: 01 → 02; 03 → 04 → 05 (05 only shares `item_lines.dart`); 06 → 07; 08 after 01–07 and the BE merge; 09 → 10 → 11. If OQ3 is ruled (b), plans 03, 06 and 07 move after 08 and lose their window branches; if (c), plans 08–09 collapse into the pre-gate plans and 10 stays the gate.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK / `flutter test` / `flutter analyze` | all plans | ✓ | Flutter 3.35.5; analyzer 47 info, 0 warning / 0 error | — |
| Node + BE `node_modules/graphql` | `validate_documents.js` (gated plans) | ✓ | Node v22.12.0; 46 × OK on `bc92fb6f` | — |
| BE `origin/develop` with Phase 19 | gated plans | ✗ (new names 0, old names present at `bc92fb6f`) | — | park the gated plans (D-09) |
| BE `BACKEND-NOTES.md` (Phase 19: SDL table, boot runbook, UAT notes) | gate and UAT plans | ✗ (BE phase not executed: only CONTEXT, DISCUSSION-LOG, REPO-RULES exist) | — | read at the gate |
| Android device + local BE after the migrator + `maxXp` content at DB | UAT plan | human checkpoint | — | — |

**Missing dependencies with no fallback:** none for plans 01–07. **Missing with fallback (park):** the BE merge and its handoff for plans 08–11.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (Flutter 3.35.5) + `bloc_test ^10.0.0` + `mocktail ^1.0.5` + `fake_async ^1.3.3` |
| Config file | none beyond `pubspec.yaml` / `analysis_options.yaml`; helpers in `test/helpers/` (`test_app.dart`, `landscape.dart`, `svg_cache_seed.dart`, `mocks.dart`, `journal_harness.dart`, `spells_harness.dart`, `fakes/`, `fixtures/`) |
| Quick run command | `flutter test <touched test files>` |
| Full suite command | `flutter test -r expanded 2>&1 \| tr '\r' '\n' \| grep -E '\[E\]\|All tests passed\|Some tests failed'` — **measured this session: 4031 tests, all passed, 1 min 36 s** (foreground, gate plans only; keep the Bash timeout ≥ 300 000 ms and run it as the only command of the call, or the tool moves it to the background) |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| MODEL-01 | `Weaknesses` lenient parse, `toJson`, props | unit | `flutter test test/models/weaknesses_test.dart` | ❌ Wave 0 |
| MODEL-01 | `Enemy.weaknesses`, lenient `locations` | unit | `flutter test test/models/enemy_test.dart` | ❌ Wave 0 |
| MODEL-01 | `PointOfInterest` without `quest` | unit | `flutter test test/models/point_of_interest_test.dart` | ✅ (add cases) |
| MODEL-01 | `Lore.imagePath` parsed and read (model, Library card, city sheet, travel sheet, warmer) | unit + widget | `flutter test test/models/lore_test.dart test/screens/splash/cubit/splash_cubit_test.dart test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/map/travel_confirmation_sheet_test.dart` | ✅ |
| MODEL-01 | lore and cities documents select `imagePath` | unit | `flutter test test/graphql/lore_documents_test.dart test/graphql/travel_documents_test.dart` | ✅ (pins) |
| MODEL-02 | `OwnedPet` entry, malformed dropped | unit | `flutter test test/models/owned_pet_test.dart test/models/character/character_assets_test.dart` | ❌ Wave 0 / ✅ |
| MODEL-02 | `Pet.attack`/`defense`, no `xp`/`currentLifePoints`/`damages` | unit | `flutter test test/models/pet_test.dart` | ✅ (rewrite) |
| MODEL-02 | `companionXpLine`, attack / defense lines, `companionXpGainedLine` | unit | `flutter test test/utils/item_lines_test.dart` | ✅ (add groups) |
| MODEL-02 | owned row «Esperienza: N / maxXp»; slot and list on the entry's pet | widget | `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart` | ✅ (add cases) |
| MODEL-02 | card / row attack and «Difesa» (hidden when empty) | widget | `flutter test test/shared/components/cards/companion_card_test.dart test/shared/components/companion_row_test.dart` | ✅ (add cases) |
| MODEL-02 | shop «already owned» and sell list on entries | widget | `flutter test test/screens/mainScreen/tabs/shop/shop_test.dart test/models/shop/trade_selection_test.dart` | ✅ |
| MODEL-02 | `petXpGained` lenient, round trip; line after the xp line, hidden at 0 | unit + widget | `flutter test test/models/quest_result/quest_result_test.dart test/shared/components/popup/quest_result_sheet_test.dart` | ✅ (add cases) |
| MODEL-02 | fragments: `ownedPets` entries, `PetFragment` with `maxXp attack defense`, `petXpGained` | unit | `flutter test test/graphql/character_fragment_test.dart test/graphql/shop_documents_test.dart test/graphql/quest_result_documents_test.dart` | ✅ (pins) |
| MODEL-03 | `Equipment.feet`, `toJson` keys = `SlotType` names, `wornEquipment` | unit | `flutter test test/models/equipment_test.dart test/models/character/character_assets_test.dart` | ❌ Wave 0 / ✅ |
| MODEL-03 | equip request sends `feet` | unit | `flutter test test/models/request/equip_item_request_test.dart` | ❌ Wave 0 |
| MODEL-03 | `SpellState` with `spell` + `active`; single non-null list | unit | `flutter test test/models/spell/spell_state_test.dart test/models/character/character_status_test.dart` | ✅ (rewrite groups) |
| MODEL-03 | (window) legacy three lists → states | unit | `flutter test test/models/character/character_test.dart` | ❌ Wave 0 (deleted at the gate) |
| MODEL-03 | `Spellbook`: known = all, equipped = active, usages/recoveries from the entry, optimistic overlay, order | unit | `flutter test test/models/spell/spellbook_test.dart` | ✅ (rewrite) |
| MODEL-03 | `SpellsCubit` equip/unequip, sync, rollback, timeout on `active` | cubit | `flutter test test/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit_test.dart` | ✅ (fixture only) |
| MODEL-03 | Journal section, rows, countdown, innkeeper draft unchanged | widget + unit | `flutter test test/screens/mainScreen/tabs/journal test/models/request/participant_draft_test.dart test/screens/innkeeper/components/completion_form_test.dart` | ✅ (fixture only) |
| MODEL-03 | fragment: `spellStates … active spell { full }`, no `spells`, no `activeSpells`, `wornEquipment`, `feet` | unit | `flutter test test/graphql/character_fragment_test.dart` | ✅ (pins) |
| MODEL-04 | POI `type` list, `location` guard | unit | `flutter test test/models/point_of_interest_test.dart` | ✅ (add cases) |
| MODEL-04 | damages entry drop, spell energy type, title | unit | `flutter test test/models/damages_test.dart test/models/character/character_status_test.dart` | ❌ Wave 0 / ✅ |
| MODEL-04 | owned item / equipment / worn slot / shop / city boundaries | unit | `flutter test test/models/character/character_assets_test.dart test/models/equipment_test.dart test/models/city_shop_test.dart test/models/city_test.dart` | ✅ (add cases) / ❌ |
| MODEL-04 | merged-schema validation 46 × OK | gate | `dump_documents.dart` + `validate_documents.js` | ✅ (gated plan) |
| MODEL-04 | device E2E | manual | `19-HUMAN-UAT.md` | ❌ (UAT plan) |

### Sampling Rate
- **Per task commit:** the touched test files + repo-wide `flutter analyze --no-fatal-infos` (0 warning / 0 error, baseline 47 info) + trailer check.
- **Per plan:** the plan's test directories (`test/models`, `test/graphql`, `test/screens/mainScreen/tabs/journal`, …).
- **Phase gate:** full suite foreground (4031 + the new cases), analyzer, format of the touched files one by one, trailer grep, schema check 46 × OK, leftover-name grep.

### Wave 0 Gaps
- [ ] `test/models/weaknesses_test.dart`, `test/models/enemy_test.dart`
- [ ] `test/models/owned_pet_test.dart`
- [ ] `test/models/damages_test.dart` (base and energy entries)
- [ ] `test/models/equipment_test.dart`, `test/models/request/equip_item_request_test.dart`
- [ ] `test/models/character/character_test.dart` (legacy spell reader; removed in the gated wave)
- [ ] Fixtures: `ownedPetJson` and the `maxXp` / `attack` / `defense` parameters of `petJson` (`shop_fixtures.dart`), new-shape `spellStateJson` / `spellbookCharacterJson` (`spell_fixtures.dart`), `petXpGained` in `questResultJson`
- No framework install, no new mock, no harness provider needed.

### Manual-only
Device E2E (`19-HUMAN-UAT.md`): the migrated data of the real character (states in learning order, owned entries), the slot order on equip, the companion xp growing after a real fight and its cap, boots on the mannequin through the real mutation, lore images from the migrated `imagePath` — BE data and timing cannot be reproduced in widget tests.

## Security Domain

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2/V3 Authentication/Session | no (unchanged) | — |
| V4 Access Control | yes (unchanged: equip mutations act on the bearer's character) | the FE sends ids and a slot name only; never xp, `active`, a cap or a slot count |
| V5 Input Validation | yes | lenient parsers that never throw on a list entry (`Weaknesses`, `OwnedPet`, `SpellState`, the MODEL-04 boundaries); strict only behind an existing boundary (`Quest.tryFromJson`, `QuestResult.tryFromJson`) |
| V6 Cryptography | no | — |

| Threat | STRIDE | Mitigation |
|--------|--------|-----------|
| One malformed or unknown catalogue value making the character, the shop or the map unloadable | DoS | entry-level `tryFromJson` boundaries with a pinned test per malformed shape (MODEL-04) |
| FE deciding `active`, the slot count or the companion xp | Tampering | values read from the wire only; product-rule greps in the gate plan |
| Documents ahead of the BE (selection refused → every character read fails) | DoS | fragments only in the gated wave; schema check 46 × OK before the device run |
| A legacy reader left in the tree accepting a shape the BE no longer sends | Tampering (stale contract) | RED-first deletion in the gated wave + leftover-name grep |
| Executor touching the BE repo or reading secrets | Information disclosure | read-only `git -C <BE> show origin/develop:…`; no `.env*` read (REPO-RULES) |

## Sources

### Primary (HIGH confidence)
- Codebase files cited by path:line (read this session at `b0b6d41`); probe `test/_probe_phase19_test.dart` (55 probes P01–P95, deleted; `git status --short` back to ` M pubspec.lock`).
- `flutter analyze --no-fatal-infos` → 47 info, 0 warning, 0 error; `flutter test` → 4031 passed in 1 min 36 s; `dart format --output=none --set-exit-if-changed` on 143 files; `dump_documents.dart` + `validate_documents.js` → 46 × OK.
- BE `origin/develop:src/schema.gql` at `bc92fb6f` (read with `git show`, no fetch): type and enum blocks quoted in F9; FE ↔ BE enum diff by script (`PoiType`: BE has `demonicPortal`; all other SDL enums equal).

### Secondary (MEDIUM confidence)
- BE `.planning/phases/19-revisione-dei-modelli/19-CONTEXT.md` D-01..D-15 and `19-REPO-RULES.md` (contract names, migrator, handoff shape; not executed yet).
- `.planning/phases/14-quest-generation/14-0{1,2,3}-PLAN.md`, `14-10-PLAN.md` (non-additive precedent), `.planning/phases/18-heal-quests-by-size/18-RESEARCH.md`, `18-12-PLAN.md` (gate shape).

### Tertiary (LOW confidence)
- None.

## Metadata
**Confidence breakdown:** readers/writers, pinned tests, formatter state, baselines HIGH (code read + tools); window strategy MEDIUM-HIGH (a recommendation between three viable options, OQ3); MODEL-04 table HIGH on the crash facts (probes), MEDIUM on scope (OQ5); BE contract MEDIUM (agreed, unmerged); copy of the attack/defense lines LOW until OQ1 is ruled.
**Research date:** 2026-11-11 — **Valid until:** the BE Phase 19 merge (re-check the names, the SDL blocks and `BACKEND-NOTES.md` in the gate plan).

## For 19-REPO-RULES

- **Not on the FE wire (no gate, no fragment change):** `Enemy` weaknesses (16 lines, `lib/models/enemy.dart` only), `PointOfInterest.quest`/`type`, `Pet.damages`/`xp`/`currentLifePoints`/`maxXp`. `PetFragment.fields` = `id name speedModifier sellable buyPrice sellPrice`; `LocationFragment.fields` = `id location`. Do not start selecting weaknesses, POI `type` or enemy `locations`.
- **Gated selections:** `character_fragment.dart` (:57-66 `spells` + `spellStates`, :74-76 `wearedEquipment`, :85-90 `activeSpells`, :102-104 `ownedPets`), `pet_fragment.dart`, `equipment_fragment.dart:96` (slot list shared by `character`/`characterUpdated` and by the `equipment` query, `character_queries.dart:23-30`), `quest_result_fragment.dart:89` (`petXpGained` after `xpAfter`), `lore_queries.dart:5`, `city_queries.dart:19`. `spellStates` must select `usages recoveries active spell { ${SpellFragment.fields} }` in the same commit that drops `spells { … }`.
- **`feet` is a wire value and a map key:** `EquipItemRequest.toJson` sends `slotType.name` (SDL enum `SlotType`), and `journal.dart:318-321` matches `Equipment.toJson()` keys against `SlotType.name`. `Equipment` field + `toJson` key, `SlotType` member, request, mannequin (:70, :75, :103), fragment slot and `journal_harness.dart:61` change in ONE gated commit.
- **Insertion points verified:** result sheet `quest_result_sheet.dart:187` (`..._line(_xpText(), QuestResultSheet.xpKey),`) → the companion line is the next entry, key `ValueKey('questResult.companionXp')`, independent of `_xpText()`; owned row `owned_companion_row.dart:44-53` (the right-hand `Expanded`, today only when displayed) hosts «Esperienza: N / maxXp»; `companion_card.dart:42-45` and `companion_row.dart:66-76` host the attack / «Difesa» lines; helpers in `lib/utils/item_lines.dart` next to `companionSpeedLabel` (:32). `companionXpLine` returns `null` when `maxXp` is null or ≤ 0.
- **No widget prints pet damages today**: the attack line is new copy like «Difesa» — format and first label to be ruled (research OQ1) before plan 19-04.
- **Spells:** `Spellbook.of` (`spellbook.dart:73-128`) is the only funnel (call sites `spells_section.dart:92, :108, :131, :187`, `spells_cubit.dart:53`, `participant_draft.dart:95`); the only other raw read is `SpellsCubit._matches` (`spells_cubit.dart:228-239`). `Spellbook`'s public API does not change; no widget of the section is edited. One rule for the active order (server and optimistic): the order of `spellStates` (research OQ2).
- **Window:** legacy readers allowed ONLY in `OwnedPet.tryFromJson` (bare pet map) and at `Character.fromJson` (three spell lists → states); both deleted RED-first in the gated wave; after it `grep -rnE "activeSpells|wearedEquipment|foots|energyWeaknesses|baseWeaknesses" lib test tool` prints nothing.
- **Pinned tests to move RED first:** `character_fragment_test.dart:54-68, :109-114, :132-144` (+ recorded payload :182-221), `shop_documents_test.dart:83-91`, `lore_documents_test.dart:14`, `travel_documents_test.dart:170-174`; model pins `character_status_test.dart:103-177, :527-528`, `spell_state_test.dart:72`, `spellbook_test.dart:79-273`, `character_assets_test.dart:8-32`, `pet_test.dart`. The registry stays at **46** documents (four count pins untouched).
- **Fixture funnels:** `spell_fixtures.dart:31-81` (12 caller files; 15 files carry the old spell shapes), `shop_fixtures.dart:8-31` (`petJson`, add `ownedPetJson`; 6 files write `ownedPets`), `lore_fixtures.dart:14` + `travel_fixtures.dart:107` (13 files), 6 files construct `PointOfInterest(… quest: null)`. Change a builder and its callers in the same plan. `pumpJournalPage` needs no new provider.
- **MODEL-04 rule:** drop the malformed ENTRY at the list boundary (`tryFromJson` → `null`), never return a `null` enum that a widget dereferences with `!` (`effect!`, `equipType!`, `rarity!`, `city.type!`). Quest and result parsers stay strict behind `Quest.tryFromJson` / `QuestResult.tryFromJson` (D-20 C6). `PoiType` on the BE has `demonicPortal`, the FE enum does not: the lenient list drops it.
- **Gate:** add block-anchored checks (`awk '/^type <T> /,/^}/'`) to the listed greps — `imagePath ≥ 1` is already true on today's SDL (4), and `CharacterStatus.spells`, `SpellState.active`, `ownedPets: [OwnedPet!]!`, `defense: Damages!` are not covered. Schema check = `dart run tool/schema_check/dump_documents.dart <dir>` («dumped 46 documents») + `NODE_PATH=<BE>/node_modules node tool/schema_check/validate_documents.js <schema> <dir>` (46 × OK).
- **Acceptance greps:** never a bare count of `imagePath`, `image`, `spells`, `pet` (101 lines / 46 lib files contain `imagePath`); anchor to `lore.imagePath`, `json['imagePath']` in `lore.dart`, `spellStates`, `ownedPets`.
- **Formatter-dirty among the touched candidates (7):** `lib/models/asset_item.dart`, `lib/models/enums/damage_type.dart`, `energy_type.dart`, `equip_type.dart`, `lib/graphql/fragments/damage_fragment.dart`, `location_fragment.dart`, `lib/screens/mainScreen/tabs/map/components/city_modal.dart` — only `city_modal.dart` must be edited (reflow noted in the SUMMARY); all 67 candidate test/helper files are clean.
- **Baselines (2026-11-11, `b0b6d41`):** analyzer 47 info / 0 warning / 0 error; full suite 4031 tests green in 1 min 36 s (run it alone in the Bash call, timeout ≥ 300 000 ms); schema check 46 × OK on BE `bc92fb6f`; BE gate today: every new name 0, every old name present.
- **zsh:** a variable holding several paths is not split — loop over an array (`FILES=(a b); for f in "${FILES[@]}"`) for the per-file `dart format` checks.

## RESEARCH COMPLETE
