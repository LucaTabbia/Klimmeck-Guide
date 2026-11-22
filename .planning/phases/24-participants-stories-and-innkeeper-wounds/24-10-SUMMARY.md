---
phase: 24-participants-stories-and-innkeeper-wounds
plan: 10
subsystem: graphql
tags: [schema-gate, fragments, innkeeper-wounds, background-additions, switch]
requires: ["24-09"]
provides:
  - "MissionDraftFragment selects backgroundAdditions, innkeeperInjuriesBefore and, on both effects, injuriesRemoved and innkeeperInjuries"
  - "CharacterFragment.statusFields selects innkeeperInjuries (character, me.currentCharacter, characterUpdated)"
  - "QuestResultFragment selects injuriesRemoved and backgroundEntryAdded"
  - "storyAndWoundCorrectionsEnabled = true: the last page and the wound removal are live"
affects: [24-11]
tech-stack:
  added: []
  patterns: ["block-anchored schema gate on the merged BE SDL before any selection and before the switch flip"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/mission_draft_fragment.dart
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - lib/config/story_and_wound_corrections.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/mission_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
    - test/config/story_and_wound_corrections_test.dart
decisions:
  - "names confirmed on the merged SDL: no rename, no deviation from the REPO-RULES wire contract"
  - "Q1 (additions merged per character) and Q7 (absent = none, explicit [] accepted) need no FE change: backgroundAdditionsInputOf and fightsInputWithCorrections stay as written"
  - "D-19 (a carried wound proposed again is ignored) needs no FE change: the app sends served lists back unrepaired and marks only served origins"
  - "the switch constant stays in the code after the flip; retiring it is a later cleanup"
metrics:
  duration: "~25 min"
  completed: 2026-11-22
---

# Phase 24 Plan 10: The gate Summary

The schema gate passed on the merged BE Phase 25 SDL (`origin/develop` 95582457), the Phase 25 fields are selected in exactly three fragments, the switch is on, all 55 documents validate against the merged SDL and the full suite is green (5495).

**From this plan on the branch needs a BE with Phase 25** (the selections fail on an older BE). **The switch stays in the code** (as `companionCareEnabled` after Phase 22).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the Phase 25 fields selected and the switch on | a4b34629 |
| 1 RED (cont.) | Move the neighbour pins to the Phase 25 selection order | e2ff076b |
| 1 GREEN | Select the story additions and the wound origins, turn the switch on | ba2bfa21 |
| 2 | Schema check on the merged SDL and full suite (no commit) | — |
| 3 | Bookkeeping | (this docs commit) |

## Gate (Task 1)

BE `git status --short` before: empty. After: empty. Only `show` / `log` / `ls-tree` on `origin/develop` were run on the BE repo.

Gate block output: `GATE_OK` (all 17 checks, `Spell.origin` and `CharacterInfos.background` included).

```
95582457 Merge pull request #49 from LucaTabbia/feat/25-storie-dei-partecipanti-e-ferite-dell-oste
68e8198e docs(phase-25): add the code review fix report
3e557f38 docs(phase-25): align the handoff with the merged additions and D-19
ed9b0f42 refactor(gameRules): read the background addition limit from the constant
4ffc4a02 refactor(quests): share one removalsOf for the absent removals key
```

### Contract proof — names confirmed

Compared line by line with `24-REPO-RULES.md` §Wire contract: every name, type and nullability matches. Addition entry types: `MissionBackgroundAddition` / `MissionBackgroundAdditionInput`.

```
## type CharacterStatus
  injuries: [InjuryType!]!
  innkeeperInjuries: [InjuryType!]!
## input ParticipantOverrideInput
  characterId: ID!
  companionLifeAfter: Int
  consumablesUsed: [ItemUsageInput!]
  hpAfter: Int
  injuries: [InjuryType!]
  injuriesRemoved: [InjuryType!]
  spellsUsed: [SpellUsageInput!]
## type MissionFightOutcome
  character: ID!
  companion: MissionCompanion
  consumablesAvailable: [MissionItemUsage!]!
  corrected: MissionFightEffects
  hpBefore: Int!
  injuriesBefore: [InjuryType!]!
  innkeeperInjuriesBefore: [InjuryType!]!
  simulated: MissionFightEffects
  spellsAvailable: [MissionSpellUsage!]!
## type MissionFightEffects
  companionLifeAfter: Int
  consumablesUsed: [MissionItemUsage!]!
  hpAfter: Int!
  injuriesAdded: [InjuryType!]!
  injuriesRemoved: [InjuryType!]!
  innkeeperInjuries: [InjuryType!]!
  spellsUsed: [MissionSpellUsage!]!
## type MissionDraft
  backgroundAdditions: [MissionBackgroundAddition!]!
  fights: [MissionFight!]!
  id: ID!
  participants: [MissionParticipant!]!
  place: ID
  prizes: [MissionPrize!]!
  quest: ID!
  questType: String!
  startedAt: DateTime!
  step: MissionDraftStep!
  updatedAt: DateTime!
## enum MissionDraftStep
  fights
  prizes
  recap
  stories
  teleport
## input SaveMissionDraftInput
  backgroundAdditions: [MissionBackgroundAdditionInput!]
  fights: [MissionFightInput!]
  pendingQuestId: ID!
  place: ID
  prizes: [MissionPrizeInput!]
  step: MissionDraftStep
## type MissionBackgroundAddition
  character: ID!
  text: String!
## input MissionBackgroundAdditionInput
  characterId: ID!
  text: String!
## type QuestResult (grep)
  backgroundEntryAdded: Boolean!
  injuriesHealed: [InjuryType!]!
  injuriesRemoved: [InjuryType!]!
## type Mutation
  completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!
```

(`type CharacterStatus` shortened to the two wound lines; the other blocks are whole.)

### BE handoff answers (names and answers only)

Source: `origin/develop:.planning/phases/25-storie-dei-partecipanti-e-ferite-dell-oste/BACKEND-NOTES.md` (updated after the BE review).

- **Q1 — additions on the save:** MERGED per character (like `prizes`). Section absent or `null` = untouched; in a present section each entry replaces only its character's addition; an omitted participant keeps theirs (`[]` changes nothing); a text empty after trim is accepted on the wire and clears that character's saved addition (omitting does not clear). Cap of 50 entries per call. **FE unchanged:** `backgroundAdditionsInputOf` sends one entry per participant, the empty ones included — the same result under merge as under replace.
- **Q2 — `BACKGROUND_ADDITION_TOO_LONG`:** raised at the save (normal case) and, in defence, at the completion (the whole completion refused, nothing written); `extensions` carries only `code`. Other refusals at the save, in order: `OUTCOME_NOT_PARTICIPANT` (character outside the draft) → `OUTCOME_OVERRIDE_INVALID` (same character twice) → the cap. `BAD_USER_INPUT` for a text over 8000 UTF-16 units or more than 50 entries.
- **Q3 — step value:** `stories`, final.
- **Q4 — a wound already carried proposed again (D-19):** ignored, always: not added, no refusal, no error, no change of origin, at save and at completion. The simulation leaves it out of `simulated.injuriesAdded`; the save leaves it out of `corrected.injuriesAdded`. The FE may send the simulated effect back unchanged. Remove-and-re-add in the same correction is the way to make it an innkeeper wound (D-16). **FE unchanged.**
- **Q5 — `characterUpdated` on an origin flip:** confirmed, published with identical `status.injuries` and updated `status.innkeeperInjuries`.
- **Q6 — `quests` / `noEffect`:** confirmed, a heal's `noEffect` follows the origin and is computed at every read; `QUEST_NO_EFFECT`, `ITEM_NO_EFFECT` and `injuriesHealed` ignore innkeeper wounds.
- **Q7 — absent `injuriesRemoved`:** absent, `null` and `[]` all mean «no removal» (not «unchanged»); the explicit empty list is accepted. A correction sent without a removal already saved cancels it and resets the following fights. **FE unchanged:** `fightsInputWithCorrections` keeps sending `[]` explicitly.
- **Q8:** drafts simulated before the deploy serve empty lists on the three new draft fields until the fight is simulated again.
- **Q9–Q11:** noted; no BE work. Q11: the BE appends an addition identical to an existing entry anyway — use a fresh text in the UAT.
- Further facts for 24-11: `removalsOf` accepts only wounds of that fight's `injuriesBefore` (another → `OUTCOME_OVERRIDE_INVALID`); `simulated.injuriesRemoved` and `simulated.innkeeperInjuries` are always empty; a correction changing only the removals resets the following fights; a remove-and-re-add leaves no trace on the result sheet (neither added nor removed); `completePendingRequest` never writes a background; the draft is born with the rank prize, cure included (check or remove the cure in the wound steps of the UAT).
- **DB field names for the UAT seeds:** `characters.status.injuries`, `characters.status.innkeeperInjuries`, `characters.infos.background`, `missiondrafts.backgroundAdditions`, `missiondrafts.fights.outcomes` (`innkeeperInjuriesBefore`, `corrected.injuriesRemoved`; `corrected.innkeeperInjuries` is derived, not stored), `questresults` (`injuriesRemoved`, `backgroundEntryAdded`). **Trap:** `innkeeperInjuries` is served raw — a DB script that removes a wound from `status.injuries` must remove it from `status.innkeeperInjuries` in the same update; to seed an innkeeper wound, `$set` both lists together. No migrator is needed on the BE.

### Re-check of Q1 / Q4 / Q7 against the two facts decided after the plans

- (a) merged additions: `backgroundAdditionsInputOf` and its tests assume «one entry per participant, empty included, empty clears» — true under the merge. No change.
- (b) D-19: no FE code or test assumes a refusal for a re-proposed carried wound (`grep` on `lib` and `test`: `OUTCOME_OVERRIDE_INVALID` appears only as the generic mapping to `InnkeeperFailure.overrideInvalid`, still raised for a removal of a wound not carried). The chips already disable a carried wound that is not removed. No change.

## Selections

- `mission_draft_fragment.dart`: `innkeeperInjuriesBefore` after `injuriesBefore`; `injuriesRemoved innkeeperInjuries` after `injuriesAdded` in `simulated` and `corrected`; `backgroundAdditions { character text }` after the prizes line.
- `character_fragment.dart`: `innkeeperInjuries` after `injuries` in `statusFields`.
- `quest_result_fragment.dart`: `injuriesRemoved` after `injuriesHealed`; `backgroundEntryAdded` after `spellResearchFailed`.
- `story_and_wound_corrections.dart`: `const bool storyAndWoundCorrectionsEnabled = true;`.
- No query, mutation or subscription file touched; no other place in `lib/graphql` names the four fields; `storyAndWoundCorrectionsEnabled` is read in tests only by its config pin.

## Verification

- Targeted run after GREEN (`test/graphql test/config test/models test/screens/innkeeper test/screens/mainScreen/components test/shared/components/popup`): `+2371: All tests passed!` — the flip broke no test outside this plan's files.
- Analyzer: `47 issues found.` → `ANALYZE_GATE_OK`. Trailer check `0` on every commit.
- Schema check against the merged SDL: `dumped 55 documents`, 55 × `OK`, exit 0.
- Full suite (`flutter test -r failures-only`): `+5495: All tests passed!` (5489 at the end of 24-09, +6 net pins of this plan).
- `bash tool/hardening_check.sh`: `hardening_check: OK`.

## Deviations from Plan

**1. [Rule 1 - test pins] A second test commit before GREEN.** The first GREEN run showed three older adjacency pins of the same test files failing because the new fields sit between their neighbours («served bounds of each fight», «verdict, simulated and corrected», «lore unlocked by the outcome»). They were moved to the new order in their own test commit (e2ff076b) before the GREEN commit; one more («arrested … after injuriesHealed») had been moved in the RED commit. All inside `files_modified`.

**2. Full-suite command.** Run as the orchestrator asked (`flutter test -r failures-only`, final line read) instead of the REPO-RULES `-r expanded` filter.

No SDL deviation. No change by the Q1 / Q7 rules.

## Known Stubs

None.

## Self-Check: PASSED

Commits a4b34629, e2ff076b, ba2bfa21 exist; the eight files of `files_modified` are committed; `git status --short` clean before the bookkeeping commit.
