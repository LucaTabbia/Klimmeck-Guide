---
phase: 23-spell-origins-void-and-shamanic-quests
plan: 10
subsystem: models
tags: [research, learning, pending-quest, quest-result, lenient]
requires: ["23-09"]
provides:
  - "PendingQuest.learningSpell (Spell?), isLearning, learningEndsAt (startDate + waitingTime, only while learning)"
  - "QuestPrizes.spellDraw (bool, true only for wire true)"
  - "QuestResult.spellFound (Spell?), spellResearchFailed (bool), isLearningEnd (display-only inference)"
  - "Guard test: no registered document selects learningSpell / spellDraw / spellFound / spellResearchFailed (flipped by 23-14)"
affects: [23-11, 23-12, 23-13, 23-14]
tech-stack:
  added: []
  patterns: ["lenient map guard before Spell.fromJson; bools read with == true"]
key-files:
  created: []
  modified:
    - lib/models/pending_quest.dart
    - lib/models/quest/quest_prizes.dart
    - lib/models/quest_result/quest_result.dart
    - test/models/pending_quest_test.dart
    - test/models/quest/quest_test.dart
    - test/models/quest_result/quest_result_test.dart
    - test/helpers/fixtures/quest_result_fixtures.dart
    - test/graphql/character_fragment_test.dart
decisions:
  - "isLearningEnd is inferred from served facts (spellLearned set, spellFound null, xpGained 0, no enemies, hpBefore == hpAfter); used only to hide the life bar in 23-13"
  - "PendingQuest.toJson writes learningSpell as its id; QuestResult.toJson writes spellFound as {id, name, origin (wire name), requiredLearnTime}"
metrics:
  duration: "~20 min"
  completed: 2026-11-16
---

# Phase 23 Plan 10: Research and learning models (lenient, unselected) Summary

The research and learning contract of BE plans 24-13..24-18 is modelled leniently and selected nowhere: the app keeps working on today's BE, and 23-14 turns the selections on.

## Names for 23-11..23-14

| Model | Member | Meaning |
|-------|--------|---------|
| `PendingQuest` | `learningSpell` (`Spell?`) | spell being learned; null outside the learning part, also for an absent / null / non-map value |
| `PendingQuest` | `isLearning` (`bool`) | `learningSpell != null` |
| `PendingQuest` | `learningEndsAt` (`DateTime?`) | `startDate + waitingTime` ms, only while learning and with both dates; no `DateTime.now` |
| `QuestPrizes` | `spellDraw` (`bool`, default `false`) | `json['spellDraw'] == true` |
| `QuestResult` | `spellFound` (`Spell?`) | spell discovered at the end of the research (D-31) |
| `QuestResult` | `spellResearchFailed` (`bool`, default `false`) | `json['spellResearchFailed'] == true` (D-29) |
| `QuestResult` | `isLearningEnd` (`bool`) | small sheet at the end of the learning (display-only) |

Fixture: `questResultJson(spellFound: …, spellResearchFailed: …)`, keys written only when non-null (default payload = today's BE shape). `laneJson` was not changed: the pending-quest tests add `learningSpell` / `waitingTime` on top of it.

## Tasks

| Task | Name | Commit |
|------|------|--------|
| 1 RED | Expect the learning spell and the spell draw | 0957470a |
| 1 GREEN | Model the learning spell and the spell draw | 5af14b60 |
| 2 RED | Expect the spell found and the failed research | a34d8d8d |
| 2 GREEN | Model the spell found and the failed research | 2731cc46 |
| 3 | Bookkeeping | (this docs commit) |

## RED failures (expected compile failures)

- `test/models/pending_quest_test.dart:89:19: Error: The getter 'learningSpell' isn't defined for the type 'PendingQuest'.` (and `isLearning`, `learningEndsAt`)
- `test/models/quest/quest_test.dart:433:62: Error: The getter 'spellDraw' isn't defined for the type 'QuestPrizes'.`
- `test/models/quest_result/quest_result_test.dart:955:21: Error: The getter 'spellFound' isn't defined for the type 'QuestResult'.` (and `spellResearchFailed`, `isLearningEnd`)

Green at the first run: `no document selects the research and learning fields before the gate (D-26, D-31)` in `character_fragment_test.dart` — a guard on an absence, green by design; it iterates over every entry of `schemaCheckDocuments` (55 documents). 23-14 flips it.

## Verification

- `flutter test test/models test/graphql test/shared/components/popup test/screens/mainScreen/components`: `+1801: All tests passed!`.
- `grep -rnE "learningSpell|spellDraw|spellFound|spellResearchFailed" lib/graphql` prints nothing.
- Analyzer `47 issues found`, `ANALYZE_GATE_OK`.
- Full suite: `+5122: All tests passed!` (5107 + 15).

## Deviations from Plan

None in behaviour. Minor: `isLearningEnd` sits with the other derived getters (`isDeath`, `hasRewards`, …) instead of next to `_spellFrom`; the `learningSpell` equality case also checks `toJson()['learningSpell'] == 's-1'`.

## Known Stubs

None (the fields are read by 23-11..23-13; selected in 23-14 by design).

## Self-Check: PASSED

- Commits 0957470a, 5af14b60, a34d8d8d, 2731cc46 present in `git log`; the three model files modified as listed.
