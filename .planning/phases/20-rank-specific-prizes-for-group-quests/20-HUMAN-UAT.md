---
status: in-progress
phase: 20-rank-specific-prizes-for-group-quests
device: Android (USB, adb reverse tcp:3000)
be_ref: 697d40a1
date: 2026-11-13
verdict:
---

# Phase 20 — Device E2E (rank-specific prizes for group quests, frontend companion)

App on the Android phone against the local BE. BE `origin/develop` is now `697d40a1` (merge of BE PR #37, quick `261113-aql`, on top of the BE Phase 21 merge `7f3506ac`). Gate re-checked before this file was written, block-anchored on `origin/develop:src/schema.gql`: `Quest.prizes: QuestPrizes!`, `Quest.rankPrizes: [QuestRankPrizes!]!`, `Quest.awaitingRescue: Boolean!`, `QuestRankPrizes { title prizes }`, the six `QuestPrizes` fields the FE selects, `QuestResult.turnsTotal / turnsCompleted / lastTurn / lastTurnKind / stagesCleared / stagesTotal / rewards`, `enum DungeonTurnKind { exploration fight }` → `GATE_OK`; schema check «dumped 46 documents», 46 × OK. Results are recorded only from the tester's words. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names only).

## Setup

Setup: BE `develop` with Phase 21 merged, booted by the orchestrator (no migrator, BE D-28); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); APK of `feat/20-rank-specific-prizes` (it selects `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind` and must never run against a BE without Phase 21). Every seed (mixed boss with two rank blocks, title changes, dungeon, low life, the rescuer character, quest times) is the orchestrator's job, done with DB scripts outside the repo with the BE's own write shapes, and never printed. The Board is opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 21 merged on BE `develop` and booted from it (no migrator, BE D-28) | |
| Mixed boss seeded with two rank blocks | |
| Title changes of the test character (plan steps 2 and 4) | |
| Dungeon with a known number of groups and the test character's life low enough to fall | |
| Rescuer character in the same city | |
| A second dungeon the test character can clear (plan step 9) | |
| A heal or job quest with enemies the test character will lose (plan step 10, D-19) | |
| Shortened quest times | |

## Session data

Field names only, from the BE Phase 21 handoff as copied in `20-03-SUMMARY.md`; no ids, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE.

- Mixed boss: `requirements.requiredAdventurers` (`title`, `count`, order `[rank, lower]`), `requirements.minTitle` (lowest seat title).
- Prize blocks: `prizes.rankPrizes` (blocks `{ title, prizeCoins, xpPrize, prizeItem, randomLoot, pet, spell, cure }`); today's `prizes` fields equal to the top-rank block.
- Dungeon: `enemies` (4 groups = 8 turns); quest time `timeToComplete`.
- Dungeon aid: `rescue.turn` (born from a real defeat, never seeded).
- Results: `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind`, `stagesCleared`, `stagesTotal`, `rewards`.
- Character: `status.awaitingAid`.
- Source quest lock (quick `261113-aql`): `Quest.awaitingRescue` (served, never seeded).
- Boot log line: `Premi per titolo: …`.

## Planned steps (plan 20-04, verbatim)

The plan's thirteen steps, kept as the reference. The orchestrator ran the device session with its own numbering (1–12, table below); each executed step names the planned step(s) it covers.

- P1. Mixed boss — paladin. Test character with title Paladino in the city of the seeded mixed boss. Open its sheet on the Board: two seat lines «Paladino: 0 / 2» (highlighted as the viewer's rank) and «Avventuriero: 0 / 1», no «Qualsiasi rango» line, «Titolo minimo: Avventuriero»; under «Ricompense» the coins (and the pet line, if that block has the pet) of the PALADIN block as seeded (RANKP-01, RANKP-02; D-03, D-07, D-25).
- P2. Mixed boss — adventurer. The orchestrator sets the test character's title to Avventuriero at DB (BE `$set`). Without reopening the app, the sheet switches silently to the ADVENTURER block (coins as seeded, pet line per that block), the highlight moves to «Avventuriero: 0 / 1», the sheet is intact (not torn) and no spinner appears (RANKP-01, RANKP-02; D-04, D-07, rule 2).
- P3. Map. Open the same quest from the Map (if its pawn is on the Map): the sheet shows the same block as the Board for the current title (RANKP-01; D-07).
- P4. Fallback block. The orchestrator sets the title to Eroe: the sheet shows the PALADIN block (highest block not above the viewer's rank, D-18) and is torn as full (no hero seat); then back to Paladino for the next steps (RANKP-01; D-18, D-25).
- P5. Dungeon defeat. The test character (life lowered by the orchestrator) accepts the seeded dungeon and loses (time shortened): the result sheet shows, right after the enemies, ONE line «Caduto al N° piano su M, in uno scontro» with N and M as the orchestrator reads them on the result at DB, and NO «Esplorazione: tappa …» line; on the Map the pawn shows «In attesa di soccorso» (RANKP-03; D-12, D-21, D-24).
- P6. Dungeon aid sheet. With the rescuer character (second account, in the same city) open the aid on the Board: one seat «Qualsiasi rango: 0 / 1»; under «Ricompense» the coins (and the prize item, if any) equal to the share the BE wrote on the aid (the orchestrator compares with the aid at DB: coins and xp already in proportion to the turn of the fall) (RANKP-01, RANKP-03; D-14, D-20).
- P7. Rescue won. The rescuer accepts the aid and wins (time shortened): the result sheet shows ONE line «Soccorso effettuato al raggiungimento del N° piano su M» in place of the stages line, «Hai salvato 1 avventuriero», and the rewards as written by the BE (no extra «proportion» line). Back on the first account: the result «Sei stato salvato», the «In attesa di soccorso» label is gone and the character can open the Board again (RANKP-03; D-12, D-15, D-20, D-21).
- P8. Old results. Any result sheet without turns (e.g. a hunt) looks as before, no turn line (RANKP-03; D-24).
- P9. Dungeon won. The test character (life restored by the orchestrator) accepts the second seeded dungeon and wins (time shortened): the result sheet shows ONE line «Piani superati: M su M» right after the enemies, NO «Esplorazione: tappa …» line (RANKP-03; D-21, D-24).
- P10. Lost fight without rescue. The test character accepts the seeded heal or job quest with enemies and loses (time shortened): life at 1, still in the city, the lane free (the Board accepts a new quest), NO «In attesa di soccorso» on the pawn and NO aid quest on the Board (RANKP-04; D-09, D-19).
- P11. (optional) Boss win by block. If the orchestrator can fill the mixed boss party (paladin and adventurer registered), win it: each participant's «Ricompense» on the result sheet shows the rewards of their own block (D-04, D-08).
- P12. (optional) Archiver release. The wounded is archived while a rescuer is registered and not started: the rescuer's lane is free again and a «quest annullata» push arrives (BE D-27, FE D-16; D-16 is covered by the BE suite).
- P13. (optional) Non-caster spell. A non-caster wins a magic quest: no «Magia appresa» line (D-05b).

Requirement ↔ step map: RANKP-01 (1, 2, 3, 4, 6), RANKP-02 (1, 2), RANKP-03 (5, 6, 7, 8, 9), RANKP-04 (10, plus the gates of 20-03 — schema gate, 46 × OK, full suite — and steps 1–10 all passed); steps 11–13 optional. D-16 (archiver release) is covered by the BE suite (BE D-27); its device step 12 is optional. Not on the device, covered by tests: the lenient turn parsing and the copy of every line (20-02), the defeat in an exploration turn (20-02 unit tests; BE D-29 placeholder never fails an exploration), the mixed-seat registration matrix (20-01).

The map above uses the planned step numbers (P1–P13).

## Steps (as executed on the device, orchestrator's numbering)

| Step | Plan step(s) | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|--------------|-----------|----------|--------|--------|------|
| 1 | P1, P4 | RANKP-01, RANKP-02 | D-03, D-07, D-18, D-25 | Mixed boss sheet seen by the legend test character: seat lines «Eroe: 0 / 1» and «Mago: 0 / 1», «Titolo minimo: Mago», the hero block under «Ricompense» | | user | |
| 2 | P1, P2 | RANKP-02 | D-02, D-03, D-25 | The legend accepts the boss: «Eroe» seat taken, «In attesa del gruppo 1/2», no travel | | user | |
| 3 | P1, P2 | RANKP-01, RANKP-02 | D-04, D-07, D-25 | The same sheet seen by the mage character with the legend registered: «Eroe: 1 / 1», «Mago: 0 / 1», the mage block under «Ricompense» | | user | |
| 4 | P11 | — (optional) | D-04, D-08 | The mage accepts, party full, boss won; each participant paid with the block of their seat | | user | |
| 5 | P10 | RANKP-04 | D-09, D-19 | Lost fight in a quest that opens no rescue: defeat, life 1, no «In attesa di soccorso», Board free, no aid | | user | |
| 6 | P5 | RANKP-03 | D-12, D-21, D-24 | Dungeon (4 groups) lost at the second group: the fall line, no stages line, «In attesa di soccorso» | | user | |
| 7 | P6, P11 | RANKP-01, RANKP-03 | D-08, D-14, D-20 | Source dungeon torn with the rescue lock line; aid sheet with the share; boss result of the legend with the hero block | | user | |
| 8 | P7 | RANKP-03 | D-12, D-20, D-21 | Rescue won by the legend: the rescuer line, the rewards as served, the dungeon whole again, the aid gone | | user | |
| 9 | P5 | RANKP-03 | D-12, D-21, D-24 | Second fall of the mage with the «piano» copy: «Caduto al 2° piano su 8, in uno scontro», awaiting rescue, dungeon torn | | user | |
| 10 | P6 | RANKP-01, RANKP-03 | D-14, D-20 | Aid sheet after the BE additions: one enemy, the share, «Tempo richiesto» in proportion | | user | |
| 11 | P7 | RANKP-03 | D-12, D-20, D-21 | «Tempo richiesto: 8 secondi»; rescue won with the rescuer line, rewards as served, dungeon whole again, aid gone | | user | |
| 12 | P9 | RANKP-03 | D-21, D-24 | Dungeon won: «Piani superati: M su M», no stages line, rewards as on the quest sheet | | user | |
