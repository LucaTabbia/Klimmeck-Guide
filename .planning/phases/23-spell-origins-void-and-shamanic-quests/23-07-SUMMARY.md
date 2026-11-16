---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 07
subsystem: graphql
tags: [schema-gate, spell, origin, minimum-level, selection]
requires: ["23-06"]
provides:
  - "SpellFragment.fields selects origin (after description) and minLevelToLearn (after maxUsages)"
  - "SpellFragment.simpleFields and the inline addedSpell of EquipmentFragment.fields select origin (after name)"
  - "Schema gate proof on the BE Phase 24 SDL; schema check 55 x OK"
affects: [23-08]
tech-stack:
  added: []
  patterns: []
key-files:
  created: []
  modified:
    - lib/graphql/fragments/spell_fragment.dart
    - lib/graphql/fragments/equipment_fragment.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/mission_documents_test.dart
    - test/graphql/shop_documents_test.dart
decisions:
  - "Gate run on the BE branch of PR #44 (feat/24-origini-magie-quest-void-shamanic, draft, not merged); to be re-run on merged develop by the orchestrator (orchestrator ruling)"
  - "Spell.relatedLore not selected (D-24): the unlock reaches the app through status.unlockedLore and QuestResult.loreUnlocked, confirmed by the BE handoff (W-7)"
  - "Both prize-spell pins target GetMissionPrizeOptions (block spell + catalogue spells): GetMissionDraft carries spell ids only"
metrics:
  duration: "~25 min"
  completed: 2026-11-15
---

# Phase 23 Plan 07: Schema gate and gated spell selections Summary

The BE Phase 24 contract is proven on the BE SDL, and `origin` / `minLevelToLearn` are now selected in exactly one place per shape: `SpellFragment.fields` (character, characterUpdated, full-spell equipment), `SpellFragment.simpleFields` (innkeeper prize spells and catalogue) and the inline `addedSpell` of `EquipmentFragment.fields` (shop and equipment lists). The origin icon, the «Origine: …» row and «Livello N» go live with no other code change. **From this plan on the branch needs a BE with Phase 24** (today's `develop` BE rejects `origin` / `minLevelToLearn`, and the BE Phase 24 rejects nothing the FE selects).

## Orchestrator ruling

**Gate run on the BE branch of PR #44; to be re-run on merged develop by the orchestrator.** BE Phase 24 is pushed as draft PR #44 and the device UAT happens before its merge (as in Phases 19 and 22), so the SDL was read with `git -C <BE> show feat/24-origini-magie-quest-void-shamanic:src/schema.gql` instead of `origin/develop`. That branch is stacked on BE PR #43 (merged), so it holds both `Pet.known` and the Phase 24 fields. Only `show` / `log` / `ls-tree` were used on the BE repo; its `git status --short` was empty before and after.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 gate | Schema gate, contract proof, handoff | (no commit: outputs below) |
| 1 RED | Expect the spell origin and level selected | 136b50d9 |
| 1 GREEN | Select the spell origin and the minimum level | 7f3dd791 |
| 2 | Schema check 55 x OK, full suite | (no commit) |
| 3 | Bookkeeping | (this docs commit) |

## Gate

BE ref `feat/24-origini-magie-quest-void-shamanic` at `b8241604` (log: `b8241604 docs(phase-24): record the review fixes`, `d392f085 docs(phase-24): add the migrator log and Necrorian checks`, `bcedad48`, `55791a45`, `13b994c9`).

- Every check of the gate block passed → `GATE_OK` (`Pet.known: Boolean!`, `Spell.origin: String!`, `Spell.minLevelToLearn: Int!`, `Spell.useType: String!`, `Spell.requiredLearnTime: Int!`, the four `CityType` values, `City.type: CityType!`, `City.size: CitySize!`, `QuestInfos.type: String!`).
- Informational line: `  relatedLore: [Lore!]!` — `Spell.relatedLore` exists; `minXpToLearn` is gone from the SDL (not even deprecated). Neither is selected by the FE.
- **Names confirmed**: no difference from the REPO-RULES contract (no rename, no SDL enum for the origin, `minLevelToLearn` non-null).

Contract proof:

```graphql
type Spell {
  description: String!
  energyDamage: EnergyDamage!
  id: ID!
  maxUsages: Int!
  minLevelToLearn: Int!
  name: String!
  origin: String!
  recoveryTime: Int!
  relatedLore: [Lore!]!
  requiredLearnTime: Int!
  useType: String!
}
enum CityType {
  aarakocraCapital
  aarakocraVillage
  desertVillage
  dragonbornCapital
  dragonbornVillage
  drusteaCapital
  drusteaCity
  drusteaSeaCity
  drusteaVillage
  elfCapital
  ferrionCity
  flameCenterCapital
  flameCity
  flameNorthCapital
  flameSouthCapital
  flameVillage
  forestVillage
  liberiaCapital
  liberiaCity
  liberiaVillage
  mirwaCapital
  mirwaCity
  mirwaSeaCity
  mirwaVillage
  motherCapital
  motherCity
  motherVillage
  mountainVillage
  necrorianCity
  northVillage
  talmvereVillage
  tropicalVillage
  valanCapital
  valanCity
  valanSeaCity
  valanVillage
}
type City {
  area: [[Float!]!]!
  hasShop: Boolean!
  id: ID!
  markerLocation: PointOfInterest!
  name: String!
  pointsOfInterest: [PointOfInterest!]
  relatedLore: Lore
  size: CitySize!
  type: CityType!
}
type QuestInfos {
  description: String
  enemies: [QuestEnemy!]!
  markerLocation: PointOfInterest!
  relatedLore: [Lore!]!
  timeToComplete: Int
  title: String!
  type: String!
}
```

`type Pet` → `  known: Boolean!`

## BE handoff (names and answers only, for 23-08)

Source: `.planning/phases/24-origini-delle-magie-quest-void-e-shamanic/BACKEND-NOTES.md` on the BE branch.

- **Origin wire values:** `void`, `arcane`, `shamanic` (`Spell.origin: String!`, TypeScript enum only). The migrator writes `origin: 'arcane'` on every existing spell; real origins are DB content of the orchestrator.
- **Quest type wire values:** `arcane`, `shamanic`, `void`; `magic` no longer exists after the migrator (`quests.infos.type` and `questresults.quest.type` rewritten `magic` → `arcane`). `QuestInfos.type` stays `String!`.
- **`minXpToLearn`:** removed from the SDL (not deprecated). It stays in the DB after the migrator for rollback and is `$unset` from `spells` by the orchestrator after both merges. FE `develop` is rejected by a Phase 24 BE: BE restart and Phase 23 FE build go together.
- **`cities`:** serves the three new types additively (Murnborim, Thengran, Veg Faldir), `aarakocraCapital` / `dragonbornCapital` size `capital`, `dragonbornVillage` size `village`; `aarakocraVillage` stays valid.
- **Level gate refusal code:** no new code. Quests simply do not teach a spell above the level after the outcome; the innkeeper offers only reachable spells and re-validates on save and completion with the existing `OUTCOME_OVERRIDE_INVALID`.
- **Origin lore unlock:** learning a spell by any path adds its `relatedLore` to `status.unlockedLore` (character subscription, new entries only) and to `QuestResult.loreUnlocked` (W-7: yes). Origin lore entries are of type `knowledge` (W-8). Open BE note: a `knowledge` origin lore may also come from the study lore pool before the first spell of that origin (user decision).
- **DB field names for the 23-08 seeds:** collection `spells`: `origin`, `minLevelToLearn` (integer 1..20), `relatedLore` (list of lore ids), `name`, `description`, `useType`, `energyDamage { type, power }`, `requiredLearnTime`, `maxUsages`, `recoveryTime`; characters: `status.unlockedLore`, `spellStates`; quests: `infos.type`, `requirements.minTitle` (`mage` for school quests), `prizes.spellDraw: true`, `prizes.spell`; results: `questresults.loreUnlocked`, `questresults.quest.type`. Boot log contexts: `SpellOriginsBoot`, `SpellCatalogueReporter`.

## TDD

- **RED (136b50d9):** `flutter test test/graphql` → `+225 -4`, the four expected failures:
  - «SpellFragment.fields selects origin after description and minLevelToLearn after maxUsages (D-01, D-07)»: actual `id name description useType maxUsages recoveryTime …`
  - «character and characterUpdated carry origin and minLevelToLearn (D-01, D-07)»: no `origin` in `character`
  - «the prize spells select their origin (D-05)»: `spell { id name useType …`
  - «the infused spell of an equipment selects its origin (D-05)»: `addedSpell { id name useType …`
- **Green at the first run:**
  - «a recorded characterUpdated payload parses the origin and the minimum level of its spells (D-01, D-07)»: the parser was already in place from 23-02; the case pins the recorded payload, which now carries `origin` / `minLevelToLearn` (`void` → `SpellOrigin.theVoid`, `6`; `shamanic`, `1`).
  - «no document selects minXpToLearn or the spell's relatedLore (D-07, D-24)»: a guard on an absence that must survive the GREEN.
- The 23-02 pin «origin and minLevelToLearn are not selected before the gate» was removed (flipped) in the RED commit.
- **GREEN (7f3dd791):** `flutter test test/graphql test/models test/shared test/screens/mainScreen test/screens/innkeeper` → **3519 passed**.

## Verification

- Acceptance greps: `^ +origin$` = 2 and `^ +minLevelToLearn$` = 1 in `spell_fragment.dart`; `^ +origin$` = 1 in `equipment_fragment.dart`; `minXpToLearn` in `lib` → nothing; `relatedLore` in the two fragments → nothing; `origin` / `minLevelToLearn` lines elsewhere in `lib/graphql` → nothing.
- Schema check against the BE branch SDL: `dumped 55 documents`, validator exit 0, **55 × OK** (no failing line).
- Whole suite: `02:04 +5107: All tests passed!` (5102 after 23-06 + 5 net: 6 new cases, 1 flipped pin removed).
- Formatter: run one file at a time on the five touched files; only `character_fragment_test.dart` was reflowed (after the edits); the two lib files were already clean.
- Analyzer: `47 issues found. (ran in 5.7s)` → 47 info / 0 warning / 0 error → `ANALYZE_GATE_OK`.
- Trailer check `0` on both code commits. BE `git status --short` empty before and after.

## Deviations from Plan

1. **[Orchestrator ruling] Gate source.** The SDL and the handoff were read from the BE branch `feat/24-origini-magie-quest-void-shamanic` (draft PR #44), not from `origin/develop`. To be re-run on merged develop by the orchestrator.
2. **[Rule 1 - plan fact] Prize spell pin target.** The plan named `GetMissionDraft` for the prize spells, but `MissionDraftFragment` selects spell ids only (`prizes { … spell }`, `spellsUsed { spell usages }`). Both pins (`spell { id name origin useType` and `spells { id name origin useType`) target `GetMissionPrizeOptions`, which holds both `SpellFragment.simpleFields` uses.
3. The gate block was run from a bash script in the scratchpad: zsh rejected the inline `awk "/^$1 /,/^}/"` with «bad substitution». Same checks, same output.

## Notes

- Legacy read of the wire value `magic` (23-03) still in place: the orchestrator decides after the real boot and the DB migration.
- `spellLearned { id name }` of the result fragment, `quest_fragment.dart` and `city_queries.dart` untouched, as planned.

## Self-Check: PASSED
