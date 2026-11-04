---
phase: 14-quest-generation
plan: 03
subsystem: graphql
tags: [graphql, fragments, enemies, dungeon, pet, announcement, tdd]
requires:
  - 14-01 (QuestInfos.enemies / description, QuestPrizes.pet parse the new keys)
  - 14-02 (QuestResult.enemies / stagesCleared / stagesTotal, QuestRewards.pet parse the new keys)
provides:
  - QuestFragment on the multi-enemy contract (description, enemies with xp, prizes.pet)
  - QuestResultFragment on the multi-enemy contract (enemies with xp, stagesCleared, stagesTotal, rewards.pet)
affects: [14-05, 14-06, 14-10, 14-11]
tech-stack:
  added: []
  patterns: [nested-enemy count equals enemies-block count as proof the old selection is gone]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/quest_fragment.dart
    - lib/graphql/fragments/quest_result_fragment.dart
    - test/graphql/board_documents_test.dart
    - test/graphql/quest_result_documents_test.dart
decisions:
  - "The old single-enemy selection was removed in the same commit that added enemies, in both fragments (c78bec7, d63eee3)"
metrics:
  duration: ~10 min
  completed: 2026-11-04
  tasks: 2
  commits: 4
---

# Phase 14 Plan 03: Fragments on the multi-enemy contract Summary

`QuestFragment` (quests board + `OnQuestUpdated`) now selects `infos.description`, `infos.enemies { quantity enemy { id name imagePath xp } }` and `prizes.pet { id name }`; `QuestResultFragment` (`questResult`, `unacknowledgedQuestResults`, `questResultReceived`, `CompletePendingRequest`) selects `enemies { quantity enemy { id name imagePath xp } }`, `stagesCleared`, `stagesTotal` and `rewards.pet { id name }`. The single-enemy selection is gone from both, each in the same commit that added `enemies`.

**Documents ahead of BE develop from commit c78bec7 (quest fragment) and d63eee3 (result fragment): no device run until 14-11.**

## Tasks

| Task | Name | Commits |
|------|------|---------|
| 1 | QuestFragment selects description, enemies with xp and the pet prize | 16ede9a (test), c78bec7 (feat) |
| 2 | QuestResultFragment selects enemies, stages and the pet reward | 8982b95 (test), d63eee3 (feat) |

## RED failures observed

- Task 1 (`flutter test test/graphql/board_documents_test.dart`): 4 failures. «selects the enemies with quantity and xp (D-01, D-02)» (Expected contains `enemies { quantity enemy { id name imagePath xp } }`), «carries no single enemy selection besides the nested one (D-01)» (Expected `<0>`, Actual `<1>`: one `enemy {`, zero `enemies {`), «selects the announcement under infos (D-05)», «selects the companion prize (D-06)».
- Task 2 (`flutter test test/graphql/quest_result_documents_test.dart`): 3 failures. «selects the enemies fought, the spells used and the rescued (D-07)», «carries no single enemy selection besides the nested one (D-01)» (Expected `<0>`, Actual `<1>`), «selects the companion reward inside rewards (D-07)» (Expected true, Actual false).
- Green at first run: «never selects lore or locations under an enemy (D-01)» (board). It is a regression guard: the old document had neither lore nor locations under the enemy, so the guard is green before and after; it protects against T-14-07.

## Tests

- After Task 1: `flutter test test/graphql test/tool test/models/quest` → 259 passed.
- After Task 2: `flutter test test/graphql test/tool test/models/quest_result test/repository/services/graphql` → 342 passed.
- Plan verification: `flutter test test/graphql test/tool test/models test/repository/services/graphql` → 847 passed.
- Analyzer after each code task: `50 issues found.` (all info), 0 error, 0 warning → `ANALYZE_GATE_OK`.
- Acceptance greps (quest_fragment.dart): `enemies {` 1, `^ *enemy \{` 1, nested block with `xp` 1, `^ *description$` 3 (≥ 1: infos, relatedLore, prizeItem loot), `^ *pet \{` 1, `locations` 0; `D-0[1256])` in board test 5.
- Acceptance greps (quest_result_fragment.dart): `enemies {` 1, `^ *enemy \{` 1, nested with `xp` 1, `stagesCleared` 1, `stagesTotal` 1, `pet {` 1; files in `lib/graphql` with a `^ *enemy \{` line: 2; `D-0[17])` in result test 3.
- `dart format` on the four touched files: the two test files reflowed the inserted tests only (written then formatted); the fragments 0 changed.

## Exact names / selections

- `QuestFragment.fields` `infos`: `… timeToComplete title type description enemies { quantity enemy { id name imagePath xp } } relatedLore { id name description }`; `prizes`: `… prizeItem { … } pet { id name }`.
- `QuestResultFragment.fields`: `rewards { coins { … } items { … } pet { id name } }`, `… spellLearned { id name } enemies { quantity enemy { id name imagePath xp } } stagesCleared stagesTotal rescuedCharacters`.
- Test titles (board, group 'quests document'): «selects the enemies with quantity and xp (D-01, D-02)», «carries no single enemy selection besides the nested one (D-01)», «selects the announcement under infos (D-05)», «selects the companion prize (D-06)», «never selects lore or locations under an enemy (D-01)».
- Test titles (result, group 'QuestResultFragment'): «selects the enemies fought, the spells used and the rescued (D-07)», «carries no single enemy selection besides the nested one (D-01)», «selects the companion reward inside rewards (D-07)»; «never selects enemy locations» kept.

## Deviations from Plan

None - plan executed exactly as written. The BE repo was not read at all (no schema check in this plan; the contract is the 14-REPO-RULES list). Bookkeeping uses the orchestrator's `3/11` and `Plan: 3 of 11` instead of the plan's `03/11`.

## Known Stubs

None.

## Self-Check: PASSED

- Files modified exist; commits 16ede9a, c78bec7, 8982b95, d63eee3 present in `git log`.
