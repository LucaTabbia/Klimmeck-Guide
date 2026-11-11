# Phase 19: Model Review (frontend companion) - Context

**Gathered:** 2026-11-09 (joint interactive discuss with the BE Phase 19 «Revisione dei modelli», from this repo, in the same session as the Phase 18; branch `feat/19-model-review` stacked on `feat/18-heal-quests-by-size` because the shared planning documents change in both and the 19 follows the 18; worktree `Klimmeck-Guide-wt18`)
**Status:** Ready for planning — no UI phase. The BE Phase 19 changes the SDL in a **non-additive** way (fields removed and renamed): every plan that selects or parses the changed names is **gated by the BE Phase 19 merge** on BE `develop` (pattern 14-10: `infos.enemies` replaced `infos.enemy`); the FE-only fixes (fragile parsers) run before it. Names are technical defaults to be fixed in the BE `19-REPO-RULES.md`. **Executes after Phase 18** (D-10).

<domain>
## Phase Boundary

The backend cleans its models (BE Phase 19) and the app follows the new shapes without changing what the player sees, with one visible addition decided by the user: the equipped companion earns a share of the combat xp, so the owned companions carry xp and life on the character and the result sheet says how much the companion gained. Everything else is shape: `Enemy.weaknesses { base, energy }` instead of two lists, enemy spells by reference (same wire shape), `assets.ownedPets` as entries `{ pet, xp, currentLifePoints }` (the catalogue `Pet` keeps the bases and `maxXp`, and replaces `damages` with flat `attack` and `defense`), `wornEquipment` with the `feet` slot, one list of spell states with `active` replacing `status.spells` + `assets.activeSpells`, no `PointOfInterest.quest`, `Lore.imagePath`. On the FE side the phase also fixes the fragile parsers found during the review (`PointOfInterest.type` builds an `Iterable` where a `List` is declared).

Out of scope (user decisions of 2026-11-09): merging `ownedEquipments` and `ownedItems` (not chosen), spell `damages`/`requiredLearnTime` (separate session on how spells are learned), any combat rule (the user's engine), new screens.

</domain>

<decisions>
## Implementation Decisions

### Contract consumed (MODEL-01, MODEL-02, MODEL-03)
- **D-01 (BE D-01, user):** `Enemy.weaknesses: Weaknesses! { base: [DamageType!]!, energy: [EnergyType!]! }` replaces `energyWeaknesses`/`baseWeaknesses`; the FE `Enemy` model gets a `Weaknesses` value (lenient: unknown enum names dropped, missing → empty lists) and the single file that reads the two lists today (8 lines) switches to it; fragments updated.
- **D-02 (BE D-02):** `Enemy.spells` keeps its wire shape (`[Spell!]!`, now populated from references): no FE change beyond fixtures.
- **D-03 (BE D-03/D-04, user):** `CharacterAssets.ownedPets: [OwnedPet!]!` with `OwnedPet { pet: Pet!, xp: Int!, currentLifePoints: Int! }` replaces `[Pet!]!`; `assets.pet: Pet` (the equipped companion, catalogue) is unchanged; the FE `CharacterAssets` model parses the entries (lenient: malformed entry dropped), the «Compagni» list and the «Compagno» slot keep working on the catalogue `Pet` inside the entry; the owned companion row shows «Esperienza: 40 / 300» from `xp` and the catalogue `maxXp` (display only). `QuestResult.petXpGained: Int!` (default 0) joins the result fragment and the result sheet shows «Il tuo compagno guadagna N PE» after the character xp line when it is above 0 (copy at Claude's discretion). The catalogue `Pet` loses `xp` and `currentLifePoints` on the wire: the FE model drops them (today parsed, shown nowhere meaningful).
- **D-12 (BE D-15, user — «attack: Damages e defense: Damages»):** `Pet.damages` leaves the wire, replaced by `Pet.attack: Damages!` and `Pet.defense: Damages!` (each `{ base, energy }` as today); the FE `Pet` model and `pet_fragment.dart` follow; the companion card/rows that print the pet damages today print the attack, and show the defense as a second line when it is not empty (copy at Claude's discretion; `defense` starts empty at DB until the user curates it).
- **D-04 (BE D-06, user):** `CharacterAssets.wearedEquipment` → `wornEquipment`, slot `foots` → `feet` (fragment, `Equipment` model, `SlotType` enum, the Journal mannequin and the equip request): names only, no visual change.
- **D-05 (BE D-07/D-08, user):** `CharacterStatus.spellStates: [SpellState!]!` gains `active: Boolean!` and becomes the only source: `CharacterStatus.spells` and `CharacterAssets.activeSpells` leave the wire; the Journal spells section (Phase 8: owned list, equipped slots, usages and recovery) reads known spells = all states, equipped = `active` ones, usages/recoveries from the same entry; `maxActiveSpells` stays on the wire (computed by the BE): no change. Optimistic rollback of equip/unequip (Phase 8) adapts to the single list. This is the largest FE plan: last in the gated wave.
- **D-06 (BE D-09/D-11, user):** `PointOfInterest.quest` leaves the model and the fragment (the Map resolves quests by `markerLocation`, never by the back-link); `Lore.image` → `imagePath` in the lore fragment and model (438 lore with an image).
- **D-07 (BE D-10):** `City.shop` is Mongoose-only: `CityShop` on the wire is unchanged, no FE work.

### FE-only fixes (MODEL-04)
- **D-08 (user, «FE: parser fragili»):** `PointOfInterest.fromJson` builds `type` with `?.map(...)` (an `Iterable` where `List<PoiType>?` is declared) and reads `json["location"][0]` without a null guard; the phase fixes these and sweeps the models for the same pattern (`dynamic` chains, `byName` on unknown names) with tests pinning each fixed case; lenient where the entity can be dropped, strict only where the Phase 6 board rules require it (D-20 C6). Runs before the gated plans.

### Gating, order, out of scope
- **D-09 (pattern 14-10):** a schema gate (`grep -cF` of the new names and absence of the removed ones on the merged BE SDL) precedes the gated plans; the device E2E after the BE merge: Journal (companions with xp line, spells section with the single list, mannequin with `feet`), a fight with the equipped companion → «Il tuo compagno guadagna N PE», Map untouched, Library images.
- **D-10 (user, «Coppia 19 dopo la 18»):** executes after Phase 18 (and the BE Phase 19 merge); branch stacked on `feat/18-heal-quests-by-size`, PR after the Phase 18 PR; reconcile the shared planning docs at the merges.
- **D-11 (user):** out of scope as listed in the boundary.

### After the research (2026-11-11)
- **D-13 (user, «Diario e negozio»):** pet attack and defense shown on the owned companion (Journal) and on the shop pets: «Attacco: tagliente 12, fuoco 5», «Difesa: contundente 4», each hidden when empty (new copy: no widget printed pet damages before).
- **D-14 (user, «Ordine di apprendimento»):** equipped spell slots follow the order of `spellStates`.
- **D-15 (Claude):** window strategy — plain pre-gate model changes where nothing is on the wire; legacy readers only for `ownedPets` and the three spell lists, deleted at the gate; `wornEquipment`/`feet` and `Lore.imagePath` as atomic gated commits.
- **D-16 (Claude):** MODEL-04 covers all 12 rows of the research sweep (entry dropped at the list boundary).
- **D-17 (Claude):** POI `location` absent → `null`, malformed → strict.
- **D-18 (Claude):** `OwnedPet.currentLifePoints` selected and parsed, not displayed.
- **D-19 (Claude):** schema gate with block-anchored checks; `SlotType.feet` is a wire value.
- Corrections from the research: weaknesses, `PointOfInterest.quest`/`type` and the catalogue pet stats are selected by no FE document («fragments updated» in D-01/D-06 = nothing to update); the spells section widgets do not change (the change is in `Spellbook`, `SpellsCubit._matches`, models, fragment).
- **BE D-25 (user, 2026-11-11):** the BE phase also writes the pet content at DB (`maxXp` and a non-empty `defense` for all 44 pets) after its real boot: at the device E2E every pet shows both «Attacco» (when it has one) and «Difesa»; the «hidden when empty» rule stays as the lenient fallback.- **BE D-26 (user, 2026-11-11):** the BE adds `Pet.relatedLore` (additive, NOT selected by the FE) and unlocks a pet's lore when the pet is obtained: the Library shows it through the Phase 17 flow (`unlockedLore` change → silent refetch → «Nuovo» bookmark). No FE code; one more step in the device E2E (buy a pet → its page appears in the Library).
### Claude's Discretion
- Copy of the companion xp lines; whether the companion row shows a small bar or text; fixture reshaping order; whether the spells section refactor lands as one plan or two (model + UI).

</decisions>

<canonical_refs>
## Canonical References

### BE contract (companion phase)
- `../Klimmeck-Guide-BE/.planning/phases/19-revisione-dei-modelli/19-CONTEXT.md` — D-01..D-14 (table of SDL changes old → new in the handoff `BACKEND-NOTES.md` after the BE phase)
- `../Klimmeck-Guide-BE/.planning/phases/19-revisione-dei-modelli/19-REPO-RULES.md` — contract names (written at BE plan time)

### Prior FE decisions carried forward
- `.planning/phases/08-spells-section-journal-tab/` — spells section, equip/unequip with optimistic rollback, usages + recovery display (the main reader of D-05)
- `.planning/phases/13-city-shops/` — «Compagni» list, «Compagno» slot, `ownedPets` vs `pet`
- `.planning/phases/14-quest-generation/` — pattern of a non-additive contract consumed with gated plans (`infos.enemies`)
- `.planning/phases/09-combat-result-sheet/` — result sheet lines (xp line precedes the companion line)

### Code
- `lib/models/enemy.dart`, `lib/graphql/fragments/damage_fragment.dart` and the enemy selections in `quest_fragment.dart`/`quest_result_fragment.dart` — weaknesses
- `lib/models/character/character_assets.dart`, `lib/models/pet.dart`, `lib/graphql/fragments/character_fragment.dart`, `lib/graphql/fragments/pet_fragment.dart` — owned pets, pet `attack`/`defense`, worn equipment, active spells
- `lib/models/character/character_status.dart`, `lib/models/spell/` (spell states), `lib/screens/mainScreen/tabs/journal/sections/spells_section.dart`, `lib/screens/mainScreen/tabs/journal/spellsCubit/`, `lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/` — the single spell list
- `lib/models/equipment.dart`, `lib/models/enums/slot_type.dart`, `lib/screens/mainScreen/tabs/journal/components/equipment_mannequin.dart`, `lib/models/request/equip_item_request.dart` — `wornEquipment`, `feet`
- `lib/screens/mainScreen/tabs/journal/components/owned_companion_row.dart`, `lib/shared/components/companion_row.dart`, `lib/shared/components/cards/companion_card.dart` — companion xp line
- `lib/models/point_of_interest.dart`, `lib/graphql/fragments/location_fragment.dart` — `quest` back-link removal, `type`/`location` parsing
- `lib/models/lore.dart` and the lore selections — `imagePath`
- `lib/shared/components/popup/quest_result_sheet.dart`, `lib/models/quest_result/` — `petXpGained`

### Rules
- `CLAUDE.md` rule 4 (backend as truth), `docs/rules/graphql.md`, `docs/rules/testing.md`, `docs/rules/naming.md`

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- Tolerant enum parsing (`asNameMap()`), `tryFromJson` boundaries, fixture builders per model (Phase 17 `questEnemyJson` pattern).
- Schema gate scripts of 14-10 / 17-09 (`grep -cF` on the merged SDL).
- Result sheet line insertion points («Magia appresa», «Conoscenza appresa», «Guarite» from Phase 18).

### Established Patterns
- One fragment per entity shared by query and subscription; a renamed field is changed in one place.
- Non-additive contract: FE plans before the merge on fixtures with the names from the BE REPO-RULES, gated plans after.

### Integration Points
- Journal spells section (largest change), Journal companions, mannequin, Map POI parsing, Library lore images, result sheet.

</code_context>

<specifics>
## Specific Ideas

- User verbatim: «Un'altra fase vorrei che fosse di revisione dei modelli, per ottimizzarli»; «una percentuale degli xp ottenuti in un combattimento vengono dati anche al pet» → 10 % of the enemies' xp, capped at the catalogue `maxXp`, companion equipped only.
- Measured FE impact (lib): `foots` 13 lines / 4 files, `wearedEquipment` 11 / 3, `activeSpells` 9 / 4, `spellStates` 9 / 3, `maxActiveSpells` 11 / 4 (unchanged on the wire), weaknesses 8 / 1 each, `ownedPets`/`.pet` 16 files, `maxXp` 7 / 1.

</specifics>

<deferred>
## Deferred Ideas

- **Companion life in combat** and damage scaling with xp: the user's engine.
- **`ownedEquipments` + `ownedItems` merge**: not chosen.
- **Spell `damages` / `requiredLearnTime`**: separate session.

</deferred>

---

*Phase: 19-model-review*
*Context gathered: 2026-11-09*
