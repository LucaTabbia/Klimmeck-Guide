---
phase: 14-quest-generation
plan: 10
subsystem: graphql
tags: [schema-gate, cross-repo, graphql, validation, qgen-01, qgen-02, qgen-03, qgen-05, qgen-06]
requires:
  - 14-09 (phase branch, post-review fixes, resume commit 3490c04)
  - BE Phase 13 merged on BE develop (162c1f5, PR #19)
provides:
  - "Every agreed contract name proven on the merged BE SDL (origin/develop 162c1f5)"
  - "Cross-repo schema check: 44 documents dumped, 44 × OK"
  - "14-VALIDATION.md complete except the 14-11 device rows; wave_0_complete: true"
affects: [14-11]
tech-stack:
  added: []
  patterns: []
key-files:
  created:
    - .planning/phases/14-quest-generation/14-10-SUMMARY.md
  modified:
    - .planning/phases/14-quest-generation/14-VALIDATION.md
    - .planning/ROADMAP.md
    - .planning/STATE.md
decisions:
  - "Names confirmed on the merged SDL: no document or model alignment, no code commit"
metrics:
  duration: ~10 min
  completed: 2026-11-05
  tasks: 2
  commits: 2
---

# Phase 14 Plan 10: Schema gate against the merged BE Phase 13 Summary

The BE Phase 13 is merged on BE `develop` (`162c1f5`, merge of PR #19). Every contract name the FE documents use (`QuestEnemy`, `QuestInfos.enemies`/`description`, `QuestResult.enemies`/`stagesCleared`/`stagesTotal`, `QuestPrizes.pet`, `QuestRewards.pet`, `AccessoryUseType`, `EquipmentItem.accessoryUseTypes`, `generateQuests: GenerateQuestsResult!` with `created: Int!`) appears on the merged SDL exactly as agreed. Neither `QuestInfos` nor `QuestResult` has an `enemy:` field any more. The cross-repo check validates all 44 FE documents against the merged schema. The full suite has 3180 passing tests, the analyzer is at its baseline (50 info, 0 error, 0 warning), the 15 new Dart files of the phase are format-clean and no commit on the branch carries a trailer. Because no name differed, there was no alignment and no code commit.

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | BE gate, contract proof, alignment, schema check 44/44 | none (names confirmed, no code change) |
| 2 | Full gates and the completed validation strategy | a9b5ee7 |
| — | Bookkeeping | `docs(phase-14): record plan 10 progress` |

## Task 1 — gate and contract proof

`git -C <BE> fetch -q origin develop` succeeded over SSH (FETCH_OK). BE ref: `origin/develop` = `162c1f5`.

```
QuestEnemy count:
3
162c1f5 Merge pull request #19 from LucaTabbia/feat/13-generazione-quest
4131373 docs(phase-13): record the first real boot and the one-off removal
f5d8134 refactor(migrations): drop the one-off migrators after their run
bdbf6bc test(migrations): expect only the enemies step at the maintenance boot
a446b13 docs(phase-13): record the push and the draft PR #19
--- type QuestEnemy
type QuestEnemy {
  enemy: Enemy!
  quantity: Int!
}
--- type QuestInfos
type QuestInfos {
  description: String
  enemies: [QuestEnemy!]!
  markerLocation: PointOfInterest!
  relatedLore: [Lore!]!
  timeToComplete: Int
  title: String!
  type: String!
}
--- type QuestResult
type QuestResult {
  acknowledgedAt: DateTime
  character: ID!
  consumablesUsed: [AssetQuantity!]!
  enemies: [QuestEnemy!]!
  hpAfter: Int!
  hpBefore: Int!
  id: ID!
  injuriesAdded: [InjuryType!]!
  levelAfter: Int!
  levelBefore: Int!
  maxLifePoints: Int!
  outcome: QuestOutcome!
  quest: QuestResultQuest!
  rescuedCharacters: [ID!]!
  resolvedAt: DateTime!
  rewards: QuestRewards!
  spellLearned: Spell
  spellsUsed: [SpellUsage!]!
  stagesCleared: Int
  stagesTotal: Int
  titleAfter: String!
  titleBefore: String!
  user: ID!
  xpAfter: Int!
  xpBefore: Int!
  xpGained: Int!
}
--- type QuestPrizes
type QuestPrizes {
  pet: Pet
  prizeCoins: Coins
  prizeItem: AssetQuantity
  randomLoot: [AssetQuantity!]!
  spell: Spell
  xpPrize: Int
}
--- type QuestRewards
type QuestRewards {
  coins: Coins!
  items: [AssetQuantity!]!
  pet: Pet
}
--- enum AccessoryUseType
enum AccessoryUseType {
  attack
  defense
}
--- type GenerateQuestsResult
type GenerateQuestsResult {
  created: Int!
}
--- EquipmentItem
2:  accessoryUseTypes: [AccessoryUseType!]
--- generateQuests
371:  generateQuests: GenerateQuestsResult!
--- Enemy
6:  imagePath: String!
13:  xp: Int!
--- Pet
5:  id: ID!
9:  name: String!
```

Outcome: **names confirmed**. Every field matches the FE selections of 14-03/14-07/14-09. `generateQuests` takes no argument. The enum values are unchanged.

BE handoff (`origin/develop:.planning/phases/13-generazione-quest/BACKEND-NOTES.md` §5): `generateQuests` is innkeeper-only. Other roles get `FORBIDDEN`, a request without a session gets `UNAUTHENTICATED` (the global guard, as for every operation) and an internal error comes back as a generic GraphQL error. `UNAUTHENTICATED` is the only code besides `FORBIDDEN`. It already goes through the existing session handling and the generic SnackBar (A5), so no code change was needed. The BE also documents single-flight concurrency (a call made while a run is in flight gets that run's result) and `created = 0` once the world is full.

Schema check:

```
dumped 44 documents
exit=0
OK lines: 44
non-OK lines: 0
```

`flutter test test/graphql test/tool test/models` → `+702: All tests passed!`

## Task 2 — full gates

- Full suite `flutter test` (foreground): `01:10 +3180: All tests passed!` (≥ 3180 expected)
- Analyzer: `50 issues found. (ran in 3.5s)`; err/warn `0`; `ANALYZE_GATE_OK`
- Format gate: no `UNFORMATTED` line (15 new Dart files in `develop...HEAD`)
- Trailers: `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` → `0`
- Sanity greps (all empty):
  - `[1]` `Image.asset` in quest_info_sheet / quest_result_sheet → nothing
  - `[2]` `infos.enemy` / `result.enemy` / `_result.enemy` in lib → nothing
  - `[3]` `relatedLore` in quest_result_fragment.dart → nothing
  - `[4]` `package:flutter/` in lib/models → nothing
  - `[5]` `package:flutter/material.dart` in questGenerationCubit → nothing
  - `[6]` `accessoryUseTypes` in item_row.dart / filter_values.dart → nothing
- `14-VALIDATION.md`: `wave_0_complete: true` count 1; the `✅ green` rows 14-01..14-10 count is 26; no `- [ ]` left in Wave 0; the rows 14-11-01..03 are still `⬜ pending`; the sign-off line «Gate passed on BE `162c1f5`: 44/44 OK, full suite 3180 green, analyzer 50 info» was added.

## Deviations from Plan

1. **[Rule 1 - Bookkeeping] Wave 0 checkbox for 14-04 was unticked.** The `enemy_portrait_url_test.dart` / `enemy_portrait_test.dart` line was still `[ ]` even though both files exist and 14-04-01/02 are green. I ticked it as Task 2 step 6 requires (commit a9b5ee7).
2. **Acceptance grep `grep -c "nyquist_compliant: true"` prints 2, not 1.** The second match is the sign-off checklist line that was already in the file from planning («- [x] `nyquist_compliant: true` set in frontmatter», line 110). The frontmatter has exactly one `nyquist_compliant: true` key. I left the planning line as it is.
3. Task 1 has no commit because no name differed (the plan allows this).

## Known Stubs

None.

## Self-Check: PASSED

- `.planning/phases/14-quest-generation/14-VALIDATION.md` changed in a9b5ee7 (FOUND)
- commit a9b5ee7 exists on the branch (FOUND)
