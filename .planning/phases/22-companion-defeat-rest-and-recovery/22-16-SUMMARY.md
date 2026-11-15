---
phase: 22-companion-defeat-rest-and-recovery
plan: 16
subsystem: graphql / config
tags: [schema-gate, graphql, companion, switch]
requires: ["22-15", "BE Phase 23 merged on BE develop (PR #42)"]
provides: ["ownedPets companion state, level and own max selected", "PetFragment.recoveryTime", "QuestResult.companion and AmbushReport.onFoot selected", "mission outcome companion and companionLifeAfter selected", "UseItem($itemId, $petId)", "companionCareEnabled = true"]
affects: ["22-17 (device E2E needs a BE running Phase 23)"]
tech-stack:
  added: []
  patterns: ["block-anchored SDL gate before any selection", "target variable and feature switch in one commit"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/fragments/pet_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/graphql/fragments/mission_draft_fragment.dart
    - lib/graphql/mutations/character_mutations.dart
    - lib/config/companion_care.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/shop_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/graphql/mission_documents_test.dart
    - test/graphql/use_item_document_test.dart
    - test/config/companion_care_test.dart
    - test/screens/mainScreen/tabs/journal/journal_companion_details_test.dart
    - test/screens/innkeeper/missionCompletion/steps/fight_step_test.dart
decisions:
  - "Selection order follows the model fields (plan default)"
  - "SDL read from the BE working tree file, not from origin/develop via git (caller forbade git in the BE repo)"
  - "No widget test relied on the switch default OFF: none needed an explicit false"
metrics:
  duration: ~50 min
  completed: 2026-11-15
---

# Phase 22 Plan 16: Schema gate Summary

The gate passed against the merged BE Phase 23 SDL, so the phase is now live on the wire. Every companion field the parsers read is now selected, each in one place per type. `UseItem` declares and passes `$petId`, and `companionCareEnabled` is `true` in the same commit. Together these turn on companion potions and the three rename entry points. V-01 of the verification is fixed. The innkeeper correction resends the simulated `companionLifeAfter` (BE A-08), now pinned at the step level. Schema check: 55 × OK. Full suite: 5024 green. **From this plan on, the branch needs a BE with Phase 23.**

## Tasks

| Task | Name | Commits |
| ---- | ---- | ------- |
| 1 | Schema gate, contract proof, handoff, gated selections | c069c5b2 (RED), 4762e99a (GREEN) |
| 2 | UseItem target, switch on, schema check, full suite | ee520d46 (RED), 80dd3ca7 (GREEN) |
| — | V-01 (verification gap) | 000d2e4b |
| — | A-08 correction pin (orchestrator request) | dd68db7d |
| 3 | Bookkeeping | this commit |

## Gate

SDL source: `/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE/src/schema.gql`, read from the working tree and copied outside the repo. sha256 `5de70ef233e931f34782ea54d74f2f4777e690d584d383a549bf1accca634330`. The orchestrator stated that BE PR #42 is merged on `develop` and that the fix branch now checked out does not change the SDL. The BE handoff confirms it («`src/schema.gql` invariato dai fix»). Every block-anchored check of the plan passed: **`GATE_OK`**. The same file was compared byte for byte again before the schema check (unchanged).

### Contract proof

```graphql
type OwnedPet { currentLifePoints: Int!  defeated: Boolean!  fullLifeAt: DateTime  level: Int!  lifeAsOf: DateTime  maxLifePoints: Int!  name: String  pet: Pet!  potionRecoveryUntil: DateTime  xp: Int! }
type Pet { attack: Damages!  buyPrice: Coins!  defense: Damages!  id: ID!  imagePath: String!  maxLifePoints: Int!  maxXp: Int!  name: String!  rarity: RarityType  recoveryTime: Int  relatedLore: [Lore!]!  sellPrice: Coins!  sellable: Boolean  speedModifier: Float }
type CompanionOutcome { defeated: Boolean!  fullLifeAt: DateTime  lifeBefore: Int!  lifePoints: Int!  maxLifePoints: Int!  name: String! }
type AmbushReport { at: DateTime!  nearCity: AmbushCity!  onFoot: Boolean!  reachedCity: AmbushCity }
type MissionCompanion { lifeBefore: Int!  maxLifePoints: Int!  name: String!  pet: ID! }
type MissionFightOutcome { character: ID!  companion: MissionCompanion  consumablesAvailable: [MissionItemUsage!]!  corrected: MissionFightEffects  hpBefore: Int!  injuriesBefore: [InjuryType!]!  simulated: MissionFightEffects  spellsAvailable: [MissionSpellUsage!]! }
type MissionFightEffects { companionLifeAfter: Int  consumablesUsed: [MissionItemUsage!]!  hpAfter: Int!  injuriesAdded: [InjuryType!]!  spellsUsed: [MissionSpellUsage!]! }
input ParticipantOverrideInput { characterId: ID!  companionLifeAfter: Int  consumablesUsed: [ItemUsageInput!]  hpAfter: Int  injuries: [InjuryType!]  spellsUsed: [SpellUsageInput!] }
input RenamePetRequest { id: String!  name: String  petId: String! }
enum PushEventType { ambush ambushDefeat missionStart petRecovered prisonRelease questCancelled questEnd streamerLive travelEnd }
QuestResult:  companion: CompanionOutcome
Mutation:     renamePet(request: RenamePetRequest!): CommonResponse!
              useItem(itemId: ID!, petId: ID): UseItemResult!
```

**Names confirmed**: every name, type and nullability matches the final wire of 22-REPO-RULES (§Final wire + D-37/D-38). No deviation.

### BE handoff (names and answers only, for 22-17)

- Key: the catalogue pet id everywhere (`equipPet`, `useItem.petId`, `RenamePetRequest.petId`, `MissionCompanion.pet`, the `id` of the `petRecovered` push). There is no `OwnedPet.id`.
- Refusal precedence (left to right):
  - `equipPet`: `BAD_USER_INPUT` → ownership guard → `MISSION_IN_PROGRESS` → `NOT_FOUND` → `PET_NOT_OWNED` → `PET_DEFEATED`.
  - `useItem(itemId, petId)`: `AWAITING_AID` → `MISSION_IN_PROGRESS` → `ITEM_NOT_OWNED` → `ITEM_NOT_USABLE` → `PET_NOT_OWNED` → `PET_DEFEATED` → `PET_POTION_RECOVERING` (`extensions.recoveryUntil`) → `ITEM_NO_EFFECT`.
  - `renamePet`: `BAD_USER_INPUT` (also when `name` is omitted) → `FORBIDDEN` → `PET_NAME_INVALID` → `NOT_FOUND` / `PET_NOT_OWNED`; never `MISSION_IN_PROGRESS`.
  - Guided correction outside `1..max`: `OUTCOME_OVERRIDE_INVALID`.
  - These match the codes the FE maps (`PET_DEFEATED`, `PET_POTION_RECOVERING`, `ITEM_NO_EFFECT`, `PET_NAME_INVALID`, `FORBIDDEN`).
- Pushes: `ambush` → `data.type` `ambush`, `id` = the ambush `QuestResult` id, one per ambush (won or lost); `ambushDefeat` is no longer sent. `petRecovered` → `id` = the catalogue pet id; title «Di nuovo in forze». The B-01 question is answered: the id is the pet id.
- DB field names for the 22-17 seeds:
  - `assets.ownedPets[]`: `pet`, `xp`, `currentLifePoints`, `name`, `level`, `lifeAsOf`, `defeatedUntil` (internal, never on the wire), `potionRecoveryUntil`.
  - Catalogue: `pets.recoveryTime` (ms; when missing, recovery is instant). `status.activeTravel.mount` (internal).
  - Sweeper: claims within at most 60 s. A legacy entry (no `level`, no `lifeAsOf`) is served at full life.
- Innkeeper `characters` query: it must not select companions (W-1, W-3). Checked: the FE `characters` documents do not use `CharacterFragment`. Only `character` and `characterUpdated` carry `ownedPets`.
- A-08: correcting a participant replaces all its effects, and an omitted field returns to its start-of-fight value. The FE resends `companionLifeAfter`: `FightStep` seeds every correction with `MissionCorrection.fromEffects(effective)`, which copies the served value. This is now pinned by `fight_step_test` «correcting the hero resends the simulated companion life (D-33, BE A-08)». The test was green at first run; removing the copy in `fromEffects` makes it fail. It stays correct if the BE moves to «omitted = simulated». Nothing was removed.

## RED failures

- Task 1: 18 failures in `flutter test test/graphql`, all on the new or updated pins:
  - shop 3;
  - mission 3;
  - quest result 9 (ambush pin + 4 documents × 2);
  - character 3.
- Task 2: 2 failures: the `UseItem` petId pin and the switch pin.

## Tests

- New tests: +14 in total.
  - character_fragment +2;
  - shop_documents +1;
  - quest_result_documents +8;
  - mission_documents +1;
  - journal_companion_details +1 (V-01 split);
  - fight_step +1 (A-08).
- Retargeted pins:
  - the `ownedPets` exact pin;
  - the cityShop `recoveryTime` case;
  - the PetFragment equality pin;
  - the ambush pin;
  - the mission outcome and simulated/corrected pins;
  - `UseItem` «does not declare petId» → «declares the optional petId and passes it (D-23, Pitfall 2)»;
  - companion care → «on after the gate».
- Switch probe: before RED, the switch was flipped locally and test/screens, test/shared, test/app and test/bootstrap were run: 2456 green. No test relied on the default OFF, so none needed an explicit `false`. The probe was reverted before the RED commit.
- Targeted runs:
  - after Task 1, graphql + models + screens/mainScreen + innkeeper + shared + tool: 3440 green;
  - after Task 2, graphql + config + screens + shared + repository + tool: 3657 green.

### Schema check

`dart run tool/schema_check/dump_documents.dart` → **dumped 55 documents**. `validate_documents.js` against the gate SDL → **55 × OK**, exit 0. Among them: `UseItem`, `RenamePet`, `GetQuestResult`, `ListUnacknowledgedQuestResults`, `OnQuestResultReceived`, the mission draft operations, `character` and `characterUpdated`.

### Full suite

`flutter test -r expanded` → `02:02 +5024: All tests passed!`. That is the baseline of 5010 plus the 14 new tests.

### Analyzer

`47 issues found` (info only), `ANALYZE_GATE_OK` after each code task and at the end.

## Acceptance

- `grep -cE "^ +lifeAsOf$" character_fragment.dart` = 1.
- level/maxLifePoints after `ownedPets {` = 2.
- `recoveryTime` = 1.
- `lifeBefore` = 1.
- `onFoot` = 1.
- `companionLifeAfter` in mission_draft_fragment = 2.
- `grep -cF 'petId: $petId' character_mutations.dart` = 1.
- `companionCareEnabled = ` only in `lib/config/companion_care.dart` with `true`.
- Trailer check 0 on every commit.

## Deviations from Plan

1. **[Caller constraint] The SDL was read from the BE working tree, not with `git -C <BE> show origin/develop:src/schema.gql`.** The orchestrator forbade any git command in the BE repo, and the attempt was also denied by the permission system. As a result the plan's `git -C <BE> log origin/develop` sha and the before/after `git -C <BE> status --short` are not in this SUMMARY. The provenance is the file's sha256 plus the orchestrator's statement (PR #42 merged; the fix branch does not touch the SDL). Nothing was written in the BE repo: only a read of `src/schema.gql`, `BACKEND-NOTES.md` and `node_modules` through `NODE_PATH`.
2. **[Verification V-01] Fixed in its own test-only commit (000d2e4b).** The switch test was split into two tests, each with a fresh pump. The switch-on case asserts that no sheet is open before the long press. The hit-test warning is gone (0 occurrences). The likely cause of the missed gesture is that the re-pump's header tap folded the «Compagno» section. This is inferred, not traced.
3. **[Orchestrator request] A-08 pin added** in `fight_step_test.dart` (dd68db7d), outside `files_modified`.
4. The ROADMAP/STATE progress format follows the orchestrator's k/N (`Plan: 16 of 17`, `16/17`). The VALIDATION frontmatter `wave_0_complete` is now `true` (`nyquist_compliant` was already `true`).

## Known Stubs

None. With the switch on and the selections live, every pre-gate lenient model now receives served data.

## Threat surface

Mitigations as planned:
- T-22-51: the gate ran before any selection.
- T-22-52: names confirmed, no rename.
- T-22-53: the BE was read-only, and no git command was run there.
- T-22-54: the switch was flipped only after the SDL showed `useItem(petId)` and `renamePet`; ownership is guarded on the BE.
- T-22-55: only names were copied from the handoff.

No new surface.

## For 22-17 (device UAT)

- BE running Phase 23.
- The recovery-time table written to `pets.recoveryTime`.
- The judgements deferred to the device: A-05, A-09, the satchel overflow in `deferred-items.md`, A-03, and the B-09 pawn jump-back.
- The push texts are provisional and need review with the user.

## Self-Check: PASSED

Commits c069c5b2, 4762e99a, ee520d46, 80dd3ca7, 000d2e4b, dd68db7d are present on the branch. The modified files exist.
