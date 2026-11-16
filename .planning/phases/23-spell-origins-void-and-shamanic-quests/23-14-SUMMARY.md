---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 14
subsystem: graphql
tags: [gate, schema-check, research, learning, selections]
requires: ["23-13"]
provides:
  - "pendingQuest { … learningSpell { id name origin requiredLearnTime } … } on the standard lane of CharacterFragment.questsFields"
  - "prizes { … xpPrize spellDraw … } in QuestFragment.fields"
  - "spellFound { id name origin requiredLearnTime } and spellResearchFailed in QuestResultFragment.fields"
  - "Guard: each research/learning field selected only in the documents that embed its home fragment"
affects: [23-08]
tech-stack:
  added: []
  patterns: ["gated selection after an SDL gate on the BE branch ref"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/character_fragment.dart
    - lib/graphql/fragments/quest_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - test/graphql/character_fragment_test.dart
    - test/graphql/quest_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
decisions:
  - "learningSpell selected only on pendingQuest (D-30: GM lanes have no learning part)"
  - "The lane's quest { id infos { type } } is not widened with prizes { spellDraw }: the draw is read from the board (BE §8.3)"
  - "spellFound selects id name origin requiredLearnTime (BE §8.6 suggested shape)"
metrics:
  duration: "~25 min"
  completed: 2026-11-16
---

# Phase 23 Plan 14: Research gate, selections, schema check Summary

The BE research block is proven on the BE branch SDL and the four new fields are selected, each in one fragment. The learning labels, the research sheets and the banner copy built in 23-10..23-13 are now live with no other code change. **From this plan on the branch needs a BE with the research block** (BE Phase 24 plans 24-13..24-18): against an older BE the character, the quest list and the results would be lost.

## Gate

- BE ref `feat/24-origini-magie-quest-void-shamanic` at `f3313bd23ffc970193e91847e448c3db195b1486` (`f3313bd2 docs(phase-24): record plan 18 progress`); the working-tree `src/schema.gql` is identical to the ref.
- Gate block output: `GATE_OK` (all eight checks, `Spell.requiredLearnTime: Int!` and `Spell.origin: String!` included). Handoff «## 8.» present (line 347).
- BE `git status --short` before and after: empty (nothing modified, built or run in the BE repo).

### Contract proof (SDL of the BE ref)

```graphql
type PendingQuest {
  arrivedAt: DateTime
  id: ID!
  learningSpell: Spell
  pointsSpent: Int!
  quest: Quest!
  startDate: DateTime
  waitingTime: Float!
}
type QuestPrizes {
  cure: QuestCure
  pet: Pet
  prizeCoins: Coins
  prizeItem: AssetQuantity
  randomLoot: [AssetQuantity!]!
  spell: Spell
  spellDraw: Boolean!
  xpPrize: Int
}
enum PushEventType {
  ambush
  ambushDefeat
  missionStart
  petRecovered
  prisonRelease
  questCancelled
  questEnd
  spellResearchFailed
  spellResearchSucceeded
  streamerLive
  travelEnd
}
type QuestResult {            # research lines only (block of 43 lines)
  spellFound: Spell
  spellLearned: Spell
  spellResearchFailed: Boolean!
}
```

**Names confirmed**: every name, type and nullability matches the must-haves (`learningSpell` and `spellFound` nullable `Spell`, `spellDraw` and `spellResearchFailed` non-null `Boolean!`). The handoff §8.2 states six added lines and none removed.

## BE handoff §8 — names and answers for 23-08

- **Lane states (`quests.pendingQuest`):** travelling/waiting `startDate: null`; research part `startDate` set, `learningSpell: null` (end = `startDate + waitingTime`); learning part same `id`, `startDate` = end of the research, `waitingTime` = learning duration (ms), `learningSpell` = the spell; finished `pendingQuest: null`. The character is «in missione» in both parts; the learning part cannot be abandoned (`QUEST_NOT_WAITING`). `learningSpell` is resolved on `PendingQuest` for `character`, `characterUpdated` and the innkeeper lists; null if the spell no longer exists. The re-arm republishes the character on `characterUpdated`.
- **Research with a spell found:** first sheet at once (`questResultReceived` / unacknowledged list) with all numbers, `spellLearned: null`, `spellFound` = the spell, `spellResearchFailed: false`, no spell lore; push `spellResearchSucceeded` with `id` = that QuestResult id; no `questEnd` then.
- **Research without a spell:** quest ends as today, sheet with `spellFound: null`, `spellResearchFailed: true`; push `spellResearchFailed` instead of `questEnd` (also for non-casters and no learnable spell at the level).
- **End of the learning:** spell in `status.spellStates`, its lore in `status.unlockedLore`, lane freed; SECOND small sheet, same `quest { id type title }`, different id: `spellLearned` = the spell, `loreUnlocked` = new origin lore, every gain zero/empty, before = after (`hpBefore == hpAfter`), `spellFound: null`, `spellResearchFailed: false`, `companion: null`; push `questEnd` with its id.
- **No discriminator on the second sheet:** recognised from served facts — matches the FE `QuestResult.isLearningEnd` of 23-10 (display-only).
- **Push `id`:** always the QuestResult id — matches 23-13 (the research pushes open the sheet like `questEnd`).
- **Immediate as before (D-30):** fixed prize spells, title-block spell, innkeeper prizes, guided missions, GM lanes, drawn spell with `requiredLearnTime` absent/0/invalid (single sheet with `spellLearned` and `questEnd`).
- **Groups:** each participant draws; all get the research sheet; only the finders stay in learning and get the second sheet.
- **Edge cases:** spell already known or removed from the catalogue at the end of the learning → lane freed, NO second sheet and NO push; character archived during the learning → no second sheet; board quest gone during the learning → no effect; lost job / restart → the missions sweep closes an expired learning.
- **Push copy (BE):** `Ricerca riuscita` / `Hai scoperto «<nome>»: l'apprendimento dura <durata>.`; `Ricerca conclusa` / `Nessuna magia scoperta: scopri com'è andata la missione.`; `Missione conclusa` for the second sheet.
- **DB field names for the 23-08 seeds/diagnosis:** `pendingquests.startDate`, `pendingquests.waitingTime`, `pendingquests.learningSpell`, `pendingquests.researchResult` (DB only, never on the wire), `spells.requiredLearnTime` (milliseconds; 0 or absent = immediate), `status.spellStates`, `status.unlockedLore`, `questresults.spellFound`, `questresults.spellLearned`, `questresults.spellResearchFailed` (two documents for the same `quest.id`). BE logs: `QuestResolutionService`, `SpellLearningService`. No migrator for this block.

### Deviations for the orchestrator

None: §8 agrees with the FE choices of 23-10..23-13 (push `id`, second-sheet inference, draw read from the board while the lane carries only `quest { id infos { type } }`). One open point listed by the BE itself (§8.1): an old FE ignores the two new push types — irrelevant for this build, which accepts them as `questEnd` (23-13).

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the research and learning fields selected | 0f045ee2 |
| 1 GREEN | Select the research and learning fields | ed3884f0 |
| 2 | Schema check and full suite (no code, no commit) | — |
| 3 | Bookkeeping | (this docs commit) |

## RED failures (9)

- `character_fragment_test.dart`: «the standard lane selects the spell being learned (D-26)», «character and characterUpdated carry the learning spell (D-26)», «the research and learning fields are selected only where the gate put them (D-26, D-31)» (flipped 23-10 guard: the embedding documents selected nothing).
- `quest_documents_test.dart`: «quest prizes select the spell draw (D-26)».
- `quest_result_documents_test.dart`: «$name selects the spell found and the failed research after the learned spell (D-29, D-31)» × 4 (GetQuestResult, ListUnacknowledgedQuestResults, OnQuestResultReceived, CompleteGuidedMission); «selects the lore unlocked by the outcome (D-04)» (order pin rewritten, see deviations).

Green at the first run (as foreseen): «the GM lanes select no learning spell (D-30)» (negative pin, nothing selected yet) and «a recorded characterUpdated payload parses the learning part (D-26)» (the parser exists since 23-10).

## Verification

- `flutter test test/graphql test/models test/shared test/screens/mainScreen test/screens/innkeeper` → `+3572: All tests passed!`
- Acceptance greps: `learningSpell {` 1, `spellDraw` 1, `spellFound {` 1, `spellResearchFailed` 1; no other `lib/graphql` file mentions the four names.
- Analyzer: `47 issues found.` + `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error). Trailer check `0` on both commits.
- Schema check against the BE ref SDL: `dumped 55 documents`, 55 × `OK …graphql`, exit 0 (no new document; registry stays 55).
- Full suite: `01:53 +5169: All tests passed!` (baseline 5161 + 8 new tests).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] zsh `:s` modifier in the gate block**
- **Found during:** Task 1 step 0
- **Issue:** `git -C $BE show $REF:src/schema.gql` fails in zsh with `bad substitution` (`$REF:s…` is read as the `:s` history modifier).
- **Fix:** brace the variable: `"${REF}:src/schema.gql"` (same for the handoff path). Output unchanged otherwise.

**2. [Rule 1 - Pin] Lore order pin of `quest_result_documents_test.dart`**
- **Found during:** Task 1 RED
- **Issue:** «selects the lore unlocked by the outcome (D-04)» pinned `spellLearned { id name } loreUnlocked { … }`, adjacent selections the plan splits.
- **Fix:** rewritten in the RED commit to `spellResearchFailed loreUnlocked { id name type }`; the new per-document test pins `spellLearned { id name } spellFound { … } spellResearchFailed`.

**3. Doc line wrapped**
- The class doc sentence «`spellFound` e `spellResearchFailed` sono della BE Phase 24 (23-CONTEXT D-29, D-31).» is wrapped on two `///` lines to stay within 80 columns like its neighbours (text unchanged).

## Threat surface

No new operation, argument or document; T-23-51..54 mitigated as planned (gate before selection, BE read-only with status before/after, names only from the handoff).

## Known Stubs

None.

## Self-Check: PASSED
