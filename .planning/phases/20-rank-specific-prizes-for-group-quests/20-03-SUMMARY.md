---
phase: 20-rank-specific-prizes-for-group-quests
plan: 03
subsystem: graphql
tags: [graphql, schema-gate, quest-results, dungeon, turns]
requires: [20-02]
provides:
  - "QuestResultFragment selects turnsTotal turnsCompleted lastTurn lastTurnKind right after stagesCleared stagesTotal (D-22)"
  - "document pins: turn adjacency, lastTurnKind in the three result documents, QuestFragment keeps prizes and never selects the rank blocks"
  - "phase gate proof on BE origin/develop 7f3506ac (46/46 OK, full suite 4291 green)"
affects: [20-04]
tech-stack:
  added: []
  patterns: ["gated selection: a new name is selected only after the BE that serves it is merged (Phase 18 pattern)"]
key-files:
  created: []
  modified:
    - lib/graphql/fragments/quest_result_fragment.dart
    - test/graphql/quest_result_documents_test.dart
    - test/graphql/board_documents_test.dart
decisions:
  - "Merged SDL matches the contract table of 20-REPO-RULES.md exactly: names confirmed, no deviation"
metrics:
  duration: "~15 min"
  completed: 2026-11-13
---

# Phase 20 Plan 03: Schema gate and dungeon turn selection Summary

Schema gate passed on the merged BE Phase 21 SDL (BE `origin/develop` `7f3506ac`); `QuestResultFragment` now selects `turnsTotal turnsCompleted lastTurn lastTurnKind` right after the stages, so the turn line of plan 20-02 receives data in the three result documents; 46/46 documents OK, full suite 4291 green.

**From commit `d6d02407` on, the branch selects names that exist only on a BE with Phase 21: no device run against an older BE (the server would refuse the three result documents).**

## Task 1 — Schema gate, contract proof, BE handoff

BE `git status --short` before: empty. After: empty (only `show` / `log` / `ls-tree` on `origin/develop`, no fetch).

Gate output: `GATE_OK`. BE ref:

```
7f3506ac Merge pull request #36 from LucaTabbia/feat/21-premi-per-rango-e-soccorsi
54018925 docs(phase-21): add verification and security audit reports
3a28976b docs(phase-21): record the user answer on the archive push text
1fb15127 docs(phase-21): align the D-26 case of the validation map
e465d15b docs(phase-21): record plan 14 progress
```

Contract proof:

```
## type Quest
type Quest {
  id: ID!
  infos: QuestInfos!
  noEffect: Boolean!
  prizes: QuestPrizes!
  rankPrizes: [QuestRankPrizes!]!
  registeredAdventurers: [QuestRegistration!]!
  requirements: QuestRequirements!
}
## type QuestRankPrizes
type QuestRankPrizes {
  prizes: QuestPrizes!
  title: String!
}
## type QuestPrizes
type QuestPrizes {
  cure: QuestCure
  pet: Pet
  prizeCoins: Coins
  prizeItem: AssetQuantity
  randomLoot: [AssetQuantity!]!
  spell: Spell
  xpPrize: Int
}
## enum DungeonTurnKind
enum DungeonTurnKind {
  exploration
  fight
}
  lastTurn: Int
  lastTurnKind: DungeonTurnKind
  rewards: QuestRewards!
  stagesCleared: Int
  stagesTotal: Int
  turnsCompleted: Int
  turnsTotal: Int
```

**Names confirmed**: every name, type and nullability equals the contract table of `20-REPO-RULES.md`.

### BE handoff (`.planning/phases/21-premi-per-rango-e-soccorsi/BACKEND-NOTES.md` on `origin/develop`, names only)

- Headings: 0. TL;DR per il FE; 1. SDL aggiunto (verbatim); 2. Premi per titolo sul foglio; 3. Dungeon a turni, esiti e quota; 4. Aid, sconfitte e boss; 5. Comportamenti provati; 6. Dati a DB e piano di UAT su device (Prerequisiti, Dati da seminare, Passi 1-6, Diagnosi suggerita); 7. Domande aperte e deviazioni.
- **No migrator, no seeder, no one-off, no new env var, no new dependency (BE D-28).** The 12 legacy bosses stay single-prize, read as the block of their `minTitle`.
- Answers to our `BACKEND-NOTES.md` §4 (BE §7, «Domande per la FE: nessuna»):
  1. `Quest.prizes` non-null on every path; a parent without loaded prizes gets an empty block (null fields, `randomLoot` `[]`), never an error.
  2. Per-subscriber resolution on `questUpdated`: proven by a two-subscriber spec; UAT step 1 confirms on device.
  3. Mixed boss: `minTitle` = lowest seat title, seats `[rank, lower]` (D-23). Confirmed.
  4. `lastTurn` 1-based, last turn played; `turnsTotal` on a cleared dungeon. Confirmed.
  5. On `death` of the wounded of a dungeon aid the turn fields ARE filled (T, s, s+1, kind of s); on `rescued` they are null. The FE prints no turn line on either (ruling W2): no conflict.
  6. Defeat without aid (D-19): `outcome` = `failure`, `status.awaitingAid` absent.
  7. D-24: `QUEST_NOT_ACCEPTABLE`, existing code.
  8. D-27: the archiver sends the same `questCancelled` as the party timeout, after the commit, best-effort (push text of the timeout, confirmed by the user).
- Aid of a dungeon on results: `QuestResult.quest.type == aid` + non-null turn fields is the correct reading (BE §3).
- Field NAMES for the 20-04 DB seeds: boss `requirements.requiredAdventurers` (`title`, `count`, order `[rank, lower]`), `requirements.minTitle`, `prizes.rankPrizes` (blocks `{ title, … }` with `prizeCoins`, `xpPrize`, `prizeItem`, `randomLoot`, `pet`, `spell`, `cure`; today's `prizes` fields equal to the top-rank block); dungeon `enemies` (4 groups = 8 turns); aid `rescue.turn` (born from a real defeat, not seeded); results: turn fields and `rewards`; character `status.awaitingAid`. Boot log line to watch: `Premi per titolo: …`.

No code change, no commit in Task 1 (not parked).

## Task 2 — Turn fields in `QuestResultFragment`

RED (`47cd912f`): `flutter test test/graphql/quest_result_documents_test.dart test/graphql/board_documents_test.dart` → `+38 -2`:
- «selects the four turn fields right after the stages (D-22)» failed: substring `stagesCleared stagesTotal turnsTotal turnsCompleted lastTurn lastTurnKind rescuedCharacters` missing.
- «every result document carries the turn fields (D-22)» failed: `lastTurnKind` missing in `OnQuestResultReceived`.
- Green at first run (expected): «the quest fragment keeps the served prizes and does not select rankPrizes (D-07, D-22)» — nothing selects the rank blocks; pin against a future selection. Literal built from `'rank' 'Prizes'` so the `grep -rn rankPrizes` gates stay meaningful.
- The existing pin `… stagesCleared stagesTotal` stays green (new names come after `stagesTotal`).

GREEN (`d6d02407`): four names added after `stagesTotal`, before `rescuedCharacters`, one per line; `QuestFragment` untouched (`git diff HEAD~2 --stat -- lib/graphql/fragments/quest_fragment.dart` empty).
`flutter test test/graphql test/tool test/models/quest_result test/shared/components/popup test/screens/mainScreen/main_screen_quest_results_test.dart` → `+469: All tests passed!` (registry still 46).

Schema check on the merged SDL:

```
dumped 46 documents
46 × OK, 0 FAIL (exit 0), among them:
OK GetQuestResult.graphql
OK ListUnacknowledgedQuestResults.graphql
OK OnQuestResultReceived.graphql
OK OnQuestUpdated.graphql
OK quests.graphql
```

Acceptance greps: each of `^ +turnsTotal$`, `^ +turnsCompleted$`, `^ +lastTurn$`, `^ +lastTurnKind$` = 1 in the fragment; `grep -rn rankPrizes lib` empty; `D-22` count 2 in `quest_result_documents_test.dart`, 1 in `board_documents_test.dart`. Format: the result test unchanged, `board_documents_test.dart` reflowed by `dart format` (long title), fragment unchanged.

## Task 3 — Phase gate

1. Full suite (foreground, alone): `01:32 +4291: All tests passed!` (4288 after the pre-gate fixes + 3 new pins).
2. Analyzer: `47 issues found. (ran in 5.6s)` → `ANALYZE_GATE_OK` (47 info / 0 warning / 0 error).
3. Format of the 19 `.dart` files of `develop...HEAD` under `lib` / `test`: nothing printed.
4. Trailers over `develop..HEAD`: `0`. Subjects > 72 over `91551b93..HEAD`: none.
5. Product-rule greps: `grep -rn "rankPrizes" lib`, `grep -rnE "lastTurn *\+ *1" lib`, added `AppBar|CircularProgressIndicator|KgLoader` in `lib`, diff stat of `quest_fragment.dart` / `quest.dart` / `quest_prizes.dart` / `quest_info_sheet.dart`: all empty.
6. `bash tool/hardening_check.sh` → `hardening_check: OK`.

`git status --short` clean after each task.

## Deviations from Plan

None - plan executed exactly as written. (Bookkeeping uses the progress `3/4` given by the orchestrator, with the em dash of the existing row.)

## Known Stubs

None.

## Self-Check: PASSED

- FOUND: lib/graphql/fragments/quest_result_fragment.dart, test/graphql/quest_result_documents_test.dart, test/graphql/board_documents_test.dart
- FOUND commits: 47cd912f, d6d02407
