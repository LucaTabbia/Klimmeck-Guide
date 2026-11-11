---
phase: 19-model-review
plan: 10
subsystem: models
tags: [schema-gate, rename, equipment, lore, graphql, tdd]
requires: ["19-09"]
provides:
  - "Schema gate GATE_OK on the merged BE SDL (BE origin/develop 48b20701), contract names confirmed"
  - "CharacterAssets.wornEquipment, Equipment.feet, SlotType.feet (wire value of the equip request), WornEquipmentFragment with the feet slot"
  - "Lore.imagePath in model, lore and city documents, readers and fixtures"
affects: [19-11, 19-12, 19-13]
tech-stack:
  added: []
  patterns: ["absence assertion on a removed wire name built from two adjacent string literals"]
key-files:
  created:
    - test/models/request/equip_item_request_test.dart
  modified:
    - lib/models/equipment.dart
    - lib/models/enums/slot_type.dart
    - lib/models/character/character_assets.dart
    - lib/screens/mainScreen/tabs/journal/components/equipment_mannequin.dart
    - lib/screens/mainScreen/tabs/journal/journal.dart
    - lib/graphql/fragments/equipment_fragment.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/queries/character_queries.dart
    - lib/models/lore.dart
    - lib/graphql/queries/lore_queries.dart
    - lib/graphql/queries/city_queries.dart
    - lib/screens/splash/cubit/splash_cubit.dart
    - lib/screens/mainScreen/tabs/library/components/lore_card.dart
    - lib/screens/mainScreen/tabs/map/components/city_modal.dart
    - lib/screens/mainScreen/tabs/map/components/travel_confirmation_sheet.dart
    - test/helpers/journal_harness.dart
    - test/helpers/fixtures/lore_fixtures.dart
    - test/helpers/fixtures/travel_fixtures.dart
    - test/models/equipment_test.dart
    - test/models/character/character_assets_test.dart
    - test/models/lore_test.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/lore_documents_test.dart
    - test/graphql/travel_documents_test.dart
decisions:
  - "The fixture builders keep their Dart parameter `image` and write the wire key `imagePath` (no caller changes), as the plan says"
  - "Lore.copyWith parameter renamed to imagePath with the field (no caller in lib or test)"
metrics:
  duration: "~25 min"
  completed: 2026-11-12
  tasks: 3
  files: 25
---

# Phase 19 Plan 10: Schema gate, `wornEquipment` / `feet`, `Lore.imagePath` — Summary

The schema gate is green on the merged BE SDL and the two pure renames reached model, documents and wire value together: the worn equipment with its `feet` slot (also the `SlotType` value sent by the equip request) and the lore `imagePath`, each as one atomic commit after its RED commit.

**Pitfall 10 — from commit `e70a1022` on, this branch selects names that exist only on a BE with Phase 19: never run it on a device against an older BE.** The documents are NOT all valid yet: `character_fragment.dart` still selects `spells { … }`, the equipped-spell list and `ownedPets { …pet fields }` (fragment flip = 19-11), so the `character` / `characterUpdated` documents are refused by the merged BE until 19-11. The document validation of `tool/schema_check` was not run (the plan does not ask for it; 19-11 / 19-12 do).

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `72399632` | test(models): expect the feet slot and the worn equipment |
| 2 | `e70a1022` | refactor(models): rename the worn equipment and the feet slot |
| 3 | `ff7a1eae` | test(models): expect the lore imagePath |
| 4 | `d55aa5a8` | refactor(models): rename the lore image to imagePath |

Trailer check after every commit: `0`. Task 1 made no commit (gate green, nothing parked).

## Task 1 — schema gate

BE ref: `origin/develop` = `48b20701` (read with `git -C <BE> show`, never fetched). SDL saved outside the repo (session scratchpad instead of `mktemp -d`, so the file survives between Bash calls).

```
type Weaknesses -> 1
type OwnedPet -> 1
petXpGained -> 1
wornEquipment -> 1
feet -> 2
attack: Damages! -> 1
energyWeaknesses -> 0
baseWeaknesses -> 0
wearedEquipment -> 0
foots -> 0
activeSpells -> 0
GATE_OK
48b20701 Merge pull request #33 from LucaTabbia/feat/19-revisione-dei-modelli
5498e0b6 docs(phase-19): record the third real boot without the migrator
7ca680fa docs(phase-19): record the executed human steps and mitigations
08d7c1d1 docs(phase-19): close the phase in requirements, roadmap and state
22a96577 docs(phase-19): record the real boot and the migrator removal
```

No `FAIL …` line from the block-anchored checks (`Lore.imagePath` present and no `image:` line, `SpellState.active`, no `CharacterStatus.spells`, `SlotType.feet`, `ownedPets: [OwnedPet!]!`, `Pet.defense`, `Pet.rarity`). One extra check added to the plan's block: `enum SlotType` has no old boots value — passed.

BE `git status --short` before: empty. After: empty. (T-19-35)

### Contract proof (verbatim from the merged SDL)

```graphql
type Weaknesses {
  base: [DamageType!]!
  energy: [EnergyType!]!
}
type Enemy {
  damages: Damages!
  id: ID!
  imagePath: String!
  legendary: Boolean!
  lifePoints: Int!
  locations: [PoiType!]!
  name: String!
  relatedLore: [Lore!]!
  spells: [Spell!]!
  weaknesses: Weaknesses!
  xp: Int!
}
type Pet {
  attack: Damages!
  buyPrice: Coins!
  defense: Damages!
  id: ID!
  imagePath: String!
  maxLifePoints: Int!
  maxXp: Int!
  name: String!
  rarity: RarityType
  relatedLore: [Lore!]!
  sellPrice: Coins!
  sellable: Boolean
  speedModifier: Float
}
type OwnedPet {
  currentLifePoints: Int!
  pet: Pet!
  xp: Int!
}
type CharacterAssets {
  ownedEquipments: [AssetQuantity!]!
  ownedItems: [AssetQuantity!]!
  ownedPets: [OwnedPet!]!
  pet: Pet
  wornEquipment: Equipment!
}
type CharacterStatus {
  activeTravel: ActiveTravel
  awaitingAid: AwaitingAid
  coins: Coins!
  currentLifePoints: Int!
  imprisonedUntil: DateTime
  injuries: [InjuryType!]!
  level: Int!
  location: PointOfInterest!
  maxActiveSpells: Int!
  maxLifePoints: Int!
  potionRecoveryUntil: DateTime
  spellStates: [SpellState!]!
  title: String!
  unlockedLore: [ID!]!
  xp: Int!
}
type SpellState {
  active: Boolean!
  recoveries: [DateTime!]!
  spell: Spell!
  usages: Int!
}
type Equipment {
  arms: EquipmentItem
  chest: EquipmentItem
  feet: EquipmentItem
  firstAccessory: EquipmentItem
  head: EquipmentItem
  leftHand: EquipmentItem
  legs: EquipmentItem
  rightHand: EquipmentItem
  secondAccessory: EquipmentItem
}
enum SlotType {
  arms
  chest
  feet
  firstAccessory
  head
  leftHand
  legs
  rightHand
  secondAccessory
}
type PointOfInterest {
  city: City
  id: ID!
  location: [Float!]!
  type: [PoiType!]!
}
type Lore {
  description: String!
  id: ID!
  imagePath: String
  name: String!
  relatedLore: [Lore!]!
  type: String!
}
input EquipItemRequest {
  id: String!
  itemId: String
  slotType: SlotType!
}
enum RarityType {
  common
  legendary
  rare
  ultrarare
  uncommon
}
```

`blk 'type QuestResult' | grep -F petXpGained` → `  petXpGained: Int!`
`grep -F 'equipment(id'` → `  equipment(id: String!): Equipment!` (research assumption A1 confirmed, with `EquipItemRequest.slotType: SlotType!`).

**Names confirmed.** Every block matches the contract table of the REPO-RULES and the expected shapes of the plan; no deviation. Notes that are not differences from the contract: `Pet.relatedLore: [Lore!]!` is additive and the FE does not select it; `enum RarityType` has the value `ultrarare` (lowercase, one word) — 19-11 must check that the FE rarity reader of `Pet` accepts that name.

### BE handoff (`BACKEND-NOTES.md` of BE Phase 19)

- **§1 matches** the blocks above (§1.2 verbatim blocks identical to the merged SDL).
- **A2 (every known spell has a state):** yes. The real boot migrated the spell lists of every character and the check against the backup found order, active set, usages and recoveries identical; a spell learned later is born as a state, not equipped, at the end of the list. A state whose spell was deleted from the catalogue is not served.
- **A3 (learning order, an equip does not reorder):** yes. The equipped spells are the entries of `spellStates` with `active` true, in list order = learning order; `equipSpell` / `unequipSpell` write only the flag of the entry.
- **A4 (`OwnedPet.pet` populated; order):** `pet` is always populated on the wire (`Pet!`): an orphan entry (pet no longer in the catalogue, or unreadable) is removed from the response, the character is never nulled; `xp` / `currentLifePoints` are normalised to valid ints. The order of `ownedPets` is not stated by the handoff (array order at DB; a bought or won pet is appended as a whole entry). State of the equipped companion = the `ownedPets` entry with the same `pet.id`.
- **A5 (`petXpGained` on ambush results):** yes. It arrives in the `QuestResult` of `kind: ambush` created at the arrival; `AmbushReport` does not change; reports held before the deploy deliver 0. It is the effective gain after the `maxXp` cap; 0 without an equipped companion, without enemies, on defeat, at the cap.
- **Other facts for the FE:** `equipItem` with the old boots value is refused with `BAD_USER_INPUT`; `Pet.rarity` may be `null` (also for an out-of-enum value at DB, with a partial error on the `rarity` path only); the lore of a pet unlock when the pet is obtained (`status.unlockedLore` on `characterUpdated`, `QuestResult.loreUnlocked` for a prize pet); a generated `enemy` quest may now carry `prizes.pet`.
- **UAT notes of the handoff** (section «Note per la UAT della FE», bullet titles): Identità di test · Pet con lore · Xp al compagno · Slot `feet` · Sezione Magie · Rarità sul compagno · Pet in premio.
- **Field names for the DB seeds of 19-13** (names only): `assets.ownedPets[] { pet, xp, currentLifePoints }`, `assets.pet`, `assets.wornEquipment.feet`, `status.spellStates[] { spell, usages, recoveries, active }`, `status.unlockedLore`; catalogue `pets { maxXp, maxLifePoints, attack, defense, rarity, relatedLore, enemy, sellable }`; `cities.shop.pets`; `lore.imagePath`. Per the handoff the BE on this machine already runs the Phase 19 code with migrated data and the pet content.

## Task 2 — `wornEquipment` / `feet`

RED (`72399632`): `flutter test test/models/equipment_test.dart test/models/request/equip_item_request_test.dart test/models/character/character_assets_test.dart test/graphql/character_fragment_test.dart` → `+39 -7: Some tests failed.`

Red (7): «sends the feet slot name on the wire (D-04, D-19)» (`byName('feet')` throws) · «parses the boots from the feet key (D-04)» · «SlotType has the feet member and not the old boots name (D-04, D-19)» · «parses the worn equipment from the wornEquipment key (D-04)» · «assetsFields selects wornEquipment with the feet slot (D-04)» · «the equipment query selects the feet slot (D-04)» · «no document selects the old equipment names (D-04)».

Green at the first run (3), with the reason:
- «every SlotType name is a key of Equipment.toJson (D-04)» — before the rename enum name and `toJson` key agreed on the old name; the case pins the invariant across the rename (T-19-38), as the plan predicted.
- «sends a null item to unequip (D-04)» — pins the request shape of today.
- «the old assets key is no longer read (D-04)» — before the rename `toJson` had no `wornEquipment` key at all (vacuous); it is a real pin only after the GREEN.

GREEN (`e70a1022`, one commit, 9 files): the seven steps of the plan, including the Boy Scout rename `WearedEquipmentFragment` → `WornEquipmentFragment` (`name` → `'WornEquipmentFields'`). `lib/models/request/equip_item_request.dart` needed no edit (it sends `slotType.name`).

`flutter test test/models test/graphql test/tool test/screens/mainScreen/tabs/journal test/screens/mainScreen/main_screen_test.dart` → `+1358: All tests passed!` (registry still 46).

Acceptance: leftover `grep -rnE "wearedEquipment|foots" lib test tool` nothing · `WearedEquipment` nothing · `"feet": feet?.id` 1 · `^  feet\(` 1 · `'feet',` 1 · `wornEquipment {` 1 · `final Equipment? wornEquipment` 1 · `WornEquipmentFragment` in 3 files · commit stat 9 files (≥ 9) · `D-04` 3 (equipment test) / 2 (request test) · `D-04)` 3 (fragment test) · key link `equipmentMap[slot.name]` at `journal.dart:320`.

## Task 3 — `Lore.imagePath`

RED (`ff7a1eae`): `flutter test test/models/lore_test.dart test/graphql/lore_documents_test.dart test/graphql/travel_documents_test.dart` → `+34 -4: Some tests failed.`

Red (4): «parses the image from the imagePath key (D-06)» · «selects the lore fields with imagePath and without unlocked (BE Phase 11, D-25; D-06)» twice (the pin runs for the `lores` and the `lore` documents) · «selects the lore imagePath for the confirmation sheet (D-06)».

Green at the first run (1): «the old image key is no longer read (D-06)» — vacuous before the rename (`toJson` had no `imagePath` key), a real pin after it.

GREEN (`d55aa5a8`, one commit, 9 files): model (ctor, field, `fromJson`, `toJson`, `copyWith`, `props`), the two selections, the five reads in four files, the two fixture builders (key `imagePath`, Dart parameter still `image`), and the doc comment of `lore_fixtures.dart`.

`flutter test test/models test/graphql test/tool test/screens/splash test/screens/mainScreen/tabs/library test/screens/mainScreen/tabs/map` → `+1422: All tests passed!`

Acceptance: `final String? imagePath` 1 · `final String? image;` 0 · `json["imagePath"]` 1 · `^ +image$` 0 / 0 in the two query files · `^ +imagePath$` 1 in `lore_queries.dart` · `lore.imagePath` 2 (`lore_card.dart`) / 1 (`splash_cubit.dart`) · `relatedLore?.imagePath` 1 · `D-06)` 2 / 1 / 1.

## Tests and gates

| Command | Result |
|---------|--------|
| Task 2 verify set (+ `main_screen_test.dart`) at `e70a1022` | `+1358: All tests passed!` |
| Task 3 verify set at `d55aa5a8` | `+1422: All tests passed!` |
| Extra guard, callers of the touched fixtures / harness outside the verify sets (`test/repository test/screens/mainScreen/components test/screens/mainScreen/cubit test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/tabs/board test/screens/mainScreen/tabs/shop test/screens/mainScreen/travelCubit test/shared test/utils`) at `d55aa5a8` | `+1728: All tests passed!` |
| `flutter analyze --no-fatal-infos` after `e70a1022` and after `d55aa5a8` | `47 issues found.` — info only, `ANALYZE_GATE_OK` |
| `sh tool/hardening_check.sh` | `hardening_check: OK` |

The full `flutter test` was not run (the plan does not ask for it; it is the gate of 19-12). `tool/schema_check` not run (see the Pitfall 10 note).

## Files formatted

`dart format` one by one on every touched file. Reflowed by the formatter:
- `lib/screens/mainScreen/tabs/map/components/city_modal.dart` (formatter-dirty in the research): only the edited line was reflowed (the `if (… != null) CachedSvg(…)` line split in two); no untouched member moved.
- `lib/screens/splash/cubit/splash_cubit.dart`: the edited `_warmer.warm(…)` line went over 80 columns and was split.
- `lib/models/lore.dart`: `props` split one per line (edited line over 80 columns).
- `test/models/request/equip_item_request_test.dart` (new file).

## Deviations from Plan

None under Rules 1–4. Inside the plan's latitude:

- **SDL saved in the session scratchpad** instead of `mktemp -d` (same «outside the repo» rule).
- **One gate check added:** `enum SlotType` has no old boots value (D-19 names it; the plan's block checked only the presence of `feet`).
- **Title of the lore document pin:** «selects the lore fields with imagePath and without unlocked (BE Phase 11, D-25; D-06)» — the old title plus the decision, ending in `D-06)` for the acceptance grep.
- **Bookkeeping in a commit separate from the SUMMARY commit** (orchestrator brief wins over the plan's `<output>` step 3).

## Notes for the next plans

- **19-11:** `character_fragment.dart` is the only document source still selecting removed names (`spells { … }`, the equipped-spell list, `ownedPets` as bare pets). Until its flip the `character` / `characterUpdated` documents fail validation against the merged BE: expect exactly those failures if `validate_documents.js` is run before the flip.
- **19-11:** `test/graphql/character_fragment_test.dart` has a new group `'worn equipment (BE Phase 19)'` placed before «the Journal assets select accessoryUseTypes…»; the pinned spell / pet selections and the recorded payload around it are still the pre-flip ones.
- **19-11:** `enum RarityType` on the wire: `common legendary rare ultrarare uncommon`; `Pet.rarity` nullable.
- **19-12:** leftover grep today — `wearedEquipment|foots` nothing in `lib test tool`; the equipped-spell list name remains only in the files listed by 19-09 («Residues left on purpose»), all leaving in 19-11. The old names in the new tests are built from two adjacent literals (`_oldBootsSlot`, `_oldWornKey`, and two local constants in the fragment test).
- **19-13:** the handoff's UAT bullets and the seed field names are listed above; boots already worn by two characters at DB must still show on the mannequin.
- `.planning/STATE.md`: only `Plan: 10 of 13` and the «Last activity» line were updated; the frontmatter `status: parked` and the «Current focus» / «Next step» lines still describe the park at 9/13 and are left to the orchestrator.

## Known Stubs

None.

## Threat Flags

None — no new surface. T-19-35 (BE status empty before and after, only `show` / `log` / `ls-tree`), T-19-36 (no `.env` read, names only from the handoff, SDL outside the repo), T-19-37 (gate green before any rename), T-19-38 (one atomic commit + the invariant case), T-19-39 (names confirmed, no rename decided here) are covered above.

## Self-Check: PASSED

- `test/models/request/equip_item_request_test.dart` exists; the 24 modified files exist.
- Commits `72399632`, `e70a1022`, `ff7a1eae`, `d55aa5a8` are in `git log`.
