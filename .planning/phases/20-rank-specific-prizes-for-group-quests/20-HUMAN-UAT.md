---
status: complete
phase: 20-rank-specific-prizes-for-group-quests
device: Android (USB, adb reverse tcp:3000)
be_ref: 697d40a1
date: 2026-11-13
verdict: executed steps 1–12 pass (step 3 after the fix 20-UAT-FIX-01; steps 7, 8, 10 with findings fixed during the UAT), covering planned steps P1, P2, P4, P5, P6, P7 (rescuer side), P9, P10 and the optional P11; P3 (Map) not executed and P8 (result without turns) not observed, both covered by tests; P7 wounded side DB only; P12, P13 not executed (BE suite); RANKP-01..04 complete by the orchestrator's closing ruling
completed: 2026-11-13
---

# Phase 20 — Device E2E (rank-specific prizes for group quests, frontend companion)

App on the Android phone against the local BE. BE `origin/develop` is now `697d40a1` (merge of BE PR #37, quick `261113-aql`, on top of the BE Phase 21 merge `7f3506ac`). Gate re-checked before this file was written, block-anchored on `origin/develop:src/schema.gql`: `Quest.prizes: QuestPrizes!`, `Quest.rankPrizes: [QuestRankPrizes!]!`, `Quest.awaitingRescue: Boolean!`, `QuestRankPrizes { title prizes }`, the six `QuestPrizes` fields the FE selects, `QuestResult.turnsTotal / turnsCompleted / lastTurn / lastTurnKind / stagesCleared / stagesTotal / rewards`, `enum DungeonTurnKind { exploration fight }` → `GATE_OK`; schema check «dumped 46 documents», 46 × OK. Results are recorded only from the tester's words (quoted verbatim, in Italian); the DB readings are the orchestrator's. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names and character names only).

**Where the session ran.** The device session ran on BE `develop` `7f3506ac` (= the BE Phase 21 branch) on port 3001, with the dev identity switched by the orchestrator between the two test characters; from step 7 on the BE was rebuilt and restarted from the BE quick-task branch `feat/quick-aid-locks-source-quest` (later merged as `697d40a1`, the `be_ref` above). App: `flutter run --flavor dev` of this branch from HEAD `cbab61ef`, reinstalled after each fix made during the session.

## Setup

Setup: BE `develop` with Phase 21 merged, booted by the orchestrator (no migrator, BE D-28); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); APK of `feat/20-rank-specific-prizes` (it selects `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind` and must never run against a BE without Phase 21). Every seed (mixed boss with two rank blocks, title changes, dungeon, low life, the rescuer character, quest times) is the orchestrator's job, done with DB scripts outside the repo with the BE's own write shapes, and never printed. The Board is opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 21 merged on BE `develop` and booted from it (no migrator, BE D-28) | done (orchestrator, 2026-11-13): `7f3506ac` on port 3001; later the quick-task branch, then `develop` `697d40a1` after the UAT |
| Mixed boss seeded with two rank blocks | done: seats hero ×1 + mage ×1; hero block 5 gold, 500 xp, 2 «Radice Curativa»; mage block 1 gold, 100 xp, 1 «Datteri»; at the POI of the city of Valantar |
| Title changes of the test character (plan steps 2 and 4) | replaced: two characters of different title instead of a title change at DB — the legend «Reavor» and «gianni» brought to mage level 13 at Valantar (no weapons, no spells; backup kept outside the repo) |
| Dungeon with a known number of groups and the test character's life low enough to fall | done: dungeon of 4 groups (8 turns; 1 gold, 80 xp, 4 «Radice»), lost by the mage |
| Rescuer character in the same city | done: the legend at Valantar |
| A second dungeon the test character can clear (plan step 9) | seeded (2 groups, 50 silver, 40 xp); the user accepted «Sterpaglia di Valantar» (8 floors) instead |
| A heal or job quest with enemies the test character will lose (plan step 10, D-19) | done: an artificial job with «Drago d'ombra anziano» (no real job has enemies, 166 / 166) |
| Shortened quest times | done: `timeToComplete` 30 s on every seeded quest |

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

The plan's thirteen steps, kept as the reference. The orchestrator ran the device session with its own numbering (1–12, table below); each executed step names the planned step(s) it covers. **Sanctioned deviation:** the plan's check «13 step rows» does not apply; the record holds one row per executed step (12) and maps each to P1–P13.

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
| 1 | P1, P4 | RANKP-01, RANKP-02 | D-03, D-07, D-18, D-25 | Mixed boss sheet seen by the legend test character: seat lines «Eroe: 0 / 1» and «Mago: 0 / 1», «Titolo minimo: Mago», the hero block under «Ricompense» | pass | user | User: «pass». Seen: seats Eroe 0/1 and Mago 0/1, «Titolo minimo» Mago, hero block (5 gold + «Radice Curativa» ×2), no mage block. No legend block was seeded, so the legend reading the hero block is the D-18 fallback (P4) on the device; the «torn as full» half of P4 was not part of this step. Seats hero/mage instead of the plan's paladin/adventurer. |
| 2 | P1, P2 | RANKP-02 | D-02, D-03, D-25 | The legend accepts the boss: «Eroe» seat taken, «In attesa del gruppo 1/2», no travel | pass | user | User: «pass». Seen: Eroe 1/1, «In attesa del gruppo 1/2», no travel. |
| 3 | P1, P2 | RANKP-01, RANKP-02 | D-04, D-07, D-25 | The same sheet seen by the mage character with the legend registered: «Eroe: 1 / 1», «Mago: 0 / 1», the mage block under «Ricompense» | pass (after the fix 20-UAT-FIX-01) | user | First attempt — user: «vedo Eroe 0/1» (the legend registered on the hero seat was not counted on the hero line: `_slotLinesOf` counted identical titles without folding legends onto hero seats, BE 13.1 D-08). Fixed in TDD during the UAT (`42883521`, `baae07b8`, `3694085b`, `20-UAT-FIX-01.md`), app reinstalled. Repeated — user: «pass». Seen: Eroe 1/1, Mago 0/1, mage block (1 gold + «Datteri» ×1). P2's title change at DB on an open sheet was replaced by the identity switch between two characters of different title (orchestrator); the silent reread on a title change stays pinned by `quest_scope_listener_test.dart`. |
| 4 | P11 | — (optional) | D-04, D-08 | The mage accepts, party full, boss won; each participant paid with the block of their seat | pass | user | User: «pass». DB (orchestrator): the mage received 1 gold + «Datteri» ×1, xp 125; the legend (on the hero seat) received 5 gold + «Radice Curativa» ×2; BE log «Boss … risolto per 2 partecipanti». The legend's result sheet with the hero block was seen at step 7. |
| 5 | P10 | RANKP-04 | D-09, D-19 | Lost fight in a quest that opens no rescue: defeat, life 1, no «In attesa di soccorso», Board free, no aid | pass | user | User question before the step: «Perché il lavoro finisce in una sconfitta? Il lavoro non ha possibilità di fallire, puoi solo ottenere una vittoria» — the job was artificial (no real job has enemies, 166 / 166); the user chose to run the step anyway and to leave the BE as it is (content decides). Result — user: «pass» (defeat, life 1, no awaiting rescue, Board free, no «Soccorso»). |
| 6 | P5 | RANKP-03 | D-12, D-21, D-24 | Dungeon (4 groups, 8 turns) lost at the 2nd turn: the fall line, no stages line, «In attesa di soccorso» | pass | user | User: «Pass su tutto». Line in the copy of the time (before `20-UAT-FIX-02`). DB fall result: `turnsTotal` 8 / `turnsCompleted` 1 / `lastTurn` 2 / `fight`. User then asked: «Ci conviene aspettare che finisca anche l'esecutore della nuova aggiunta, così vediamo la quest dungeon bloccata sul tabellone.» |
| 7 | P6, P11 | RANKP-01, RANKP-03 | D-08, D-14, D-20 | Source dungeon torn with the rescue lock line; aid sheet with the share; boss result of the legend with the hero block | pass (finding F-A) | user | After the quick task `261113-aql` was deployed — user, from the legend: «L'app è riavviata, è comparsa la quest aid e la quest dungeon non può essere accettata». Step — user: «pass su tutto, ma nella quest aid vedo 4 arbusto maligno. Non dovrei vederne solo 1?» (finding F-A, fixed on the BE). DB aid share: 25 silver, 20 xp, 1 «Radice». |
| 8 | P7 | RANKP-03 | D-12, D-20, D-21 | Rescue won by the legend: the rescuer line, the rewards as served, the dungeon whole again, the aid gone | pass (copy amended: UAT-FIX-02) | user | User: «invece di scrivere "«Ferito raggiunto al turno 2 di 8" scriviamo "Soccorso effettuato al raggiungimento del 2° piano su 8"»; asked about the other lines: «Sì, tutte con «piano»» → `20-UAT-FIX-02` (`2f619639`, `b42e4f11`, `8a71b280`). Confirmations (rewards 25 silver + «Radice» ×1; dungeon whole and acceptable again, «Soccorso» gone) — user: «pass tutto il resto+». DB rescuer result: 8 / 2 / 2 / `fight`. The wounded's `rescued` result was verified at DB only (no turn fields), not on the phone. The rescue was resolved on the quick-task BE before the BE additions (user: «Ho accettato per sbaglio la quest di soccorso»). |
| 9 | P5 | RANKP-03 | D-12, D-21, D-24 | Second fall of the mage with the «piano» copy: «Caduto al 2° piano su 8, in uno scontro», awaiting rescue, dungeon torn | pass | user | User: «pass». Seen: «Caduto al 2° piano su 8, in uno scontro», awaiting rescue, dungeon torn with the rescue lock line. |
| 10 | P6 | RANKP-01, RANKP-03 | D-14, D-20 | Aid sheet after the BE additions: one enemy, the share, «Tempo richiesto» in proportion | pass (finding F-C) | user | User: «Su Tempo richiesto vedo ",7" secondi» (finding F-C: leading commas in the duration wording, never seen before because quests lasted whole hours) → `20-UAT-FIX-03` (`2d3ceb9c`, `bf1d2e78`, `92d661a5`; rounding amended after the review, `4dd1d4af`, `331cf53c`, `0af419f7`). Rest (one «Arbusto Maligno» among the aid enemies, 25 silver + «Radice» ×1, dungeon torn) — user: «Tutto il resto pass». DB aid: 25 silver, 20 xp, 1 «Radice»; duration 7500 ms of 30000; `rescue.turn` `{1, fight, 8}`. |
| 11 | P7 | RANKP-03 | D-12, D-20, D-21 | «Tempo richiesto: 8 secondi»; rescue won with the rescuer line, rewards as served, dungeon whole again, aid gone | pass | user | User: «pass». Seen: «Tempo richiesto: 8 secondi», «Soccorso effettuato al raggiungimento del 2° piano su 8», 25 silver + «Radice» ×1, dungeon whole again, aid gone. Afterwards the user replaced the «Arbusto Maligno» asset (user: «Ho sostituito l'asset dell'arbusto maligno con questo: …», a Cloudinary SVG); `imagePath` updated at DB on the enemy and its linked lore. |
| 12 | P9 | RANKP-03 | D-21, D-24 | Dungeon won: «Piani superati: M su M», no stages line, rewards as on the quest sheet | pass | user | User: «Ho accettato Sterpaglia di Valantar invece della missione che hai chiesto tu. Vedo l'asset nuovo. pass per i piani e ricompense (è quella mostrata dal foglio della quest)». DB result: 8 / 8 / 8 / `fight` (8 floors). |

### Planned steps not executed or not observed on the device

| Plan step | Status | Coverage |
|-----------|--------|----------|
| P3 (Map sheet of the same quest) | not executed | the served block on the Map sheet is pinned by plan 20-01 (`quest_info_overlay_test.dart`, D-07) |
| P4, «torn as full» half | not executed | the fallback block itself was seen in step 1; the fullness per title is pinned by plan 20-01 (`quest_capacity_test.dart`, `quest_availability_test.dart`) |
| P7, wounded side («Sei stato salvato», label gone, Board again) | DB only | the `rescued` result checked at DB by the orchestrator (no turn fields); no turn line on `rescued` pinned by plan 20-02 and the pre-gate review fixer |
| P8 (a result without turns) | not observed | no result without turns was generated during the session; the fallback «Esplorazione: tappa N di M» and the unchanged sheet without turn fields are pinned by plan 20-02 (`quest_result_sheet_test.dart`, `quest_outcome_lines_test.dart`) |
| P12 (optional, archiver release, D-16) | not executed | covered by the BE suite (BE D-27) |
| P13 (optional, non-caster spell, D-05b) | not executed | covered by the BE suite |

## Chiusura della UAT (orchestrator, summary)

- Map of the executed steps on the plan's steps: rank block on the sheet (1, 3) → pass; reread on a change of identity / title (the mage vs the legend) → pass; mixed boss, seats per title and party counter (2, 3, 4) → pass after 20-UAT-FIX-01; boss win with the block of each title (4, the legend's result at 7) → pass; dungeon lost with the floor line (6, 9) → pass; dungeon aid sheet with the real share (7, 10) → pass; rescue won with the rescuer line (8, 11) → pass; result without turns falling back to the stages line → NOT observed on the device (no such result generated): covered by tests; dungeon won «Piani superati» (12) → pass (on «Sterpaglia di Valantar», 8 floors, by the user's choice); defeat without rescue D-19 (5) → pass on an artificial job; optional steps (the `rescued` result seen by the mage on the phone, the archiver release D-16, a spell for a non-caster D-05b) → NOT executed: covered by the BE suite.
- DB checks by the orchestrator at every step: prize blocks received (mage 1 gold + «Datteri» ×1; legend 5 gold + «Radice» ×2), turns on the results (8/1/2 `fight` for the fall; 8/2/2 `fight` for the rescuer; 8/8/8 `fight` for the cleared dungeon), aid share (25 silver, 20 xp, 1 «Radice»; duration 7500 ms of 30000), `rescue.turn {1, fight, 8}`.
- Cleanup: the mage character restored from the backup (rookie level 1); six test quests, ten results and their references removed; no aid left at DB; the legend keeps the test earnings. Content data changed on the user's order: dungeon order (strongest group last, backup outside the repo), the «Arbusto Maligno» image on the enemy and its lore.
- After the UAT: review of the fixes (FE 8 findings: 6 fixed, 2 by ruling, `20-REVIEW-UAT.md` / `20-REVIEW-UAT-FIX.md`; BE quick 10 findings closed), BE quick merged into `develop` (PR #37, `697d40a1`), BE rebuilt and restarted from `develop`.
- Declared limit (told to the user): the «Soccorso in corso» lock does not reach live a viewer whose Board is already open; it shows at the next list read or right after a refused accept.
- Questions left to the user, not blocking: the banner copy on a refused locked quest; `Quest.rankPrizes` readable by every authenticated user.

## Findings and new rules born during the UAT

| Id | Origin | What | Closed by |
|----|--------|------|-----------|
| UAT-FIX-01 | step 3 | legend registered on a hero seat drawn as «Eroe 0/1» | FE `42883521`, `baae07b8`, `3694085b` (`20-UAT-FIX-01.md`); highlight by registration order after the review (WR-03, `1e665ade`, `a7d2a27c`) |
| Rule R-1 (quick `261113-aql`) | between steps 3 and 6 | user, verbatim: «Quando un personaggio attiva una aid a partire da una hunt o da un dungeon (quindi le uniche quest ripetibili che possono creare una aid) la quest che le ha generate deve risultare strappata e quindi non accettable, finché il soccorso non va a buon fine.» — for everyone; free again when the aid closes; supersedes D-15 | FE `2ba13273`, `5ded49b4`, `2a7effcd`, `f106ba29`, `93cb09fd`, `4b624753`; review fixes `6596807b`, `5e8536b4`, `fee3690a`, `9c10ff00`, `2c1e0714`, `a30195c1`, `f13a542e`, `c0ebdd4b`; BE PR #37 |
| F-A | step 7 | four «Arbusto Maligno» on the aid instead of the enemies actually faced | BE quick `261113-aql` (enemies faced on the dungeon aid) |
| Rule R-2 | step 7 | user, verbatim: «Naturalmente anche il tempo richiesto per il soccorso dev'essere corretto in base a quanto dungeon è stato completato. Se sei al secondo turno su 8, allora dev'essere un quarto. 1 ora dungeon completo -> 15 minuti aid» | BE quick `261113-aql` (aid time scaled at birth with the prize share); seen in steps 10 and 11 |
| UAT-FIX-02 | step 8 | «piano» copy for every turn line | FE `2f619639`, `b42e4f11`, `8a71b280` (`20-UAT-FIX-02.md`) |
| Rule R-3 | after step 8 | user, verbatim: «Nelle quest boss e dungeon vorrei che il nemico presnete sul foglio della quest fosse il nemico più forte. Nel caso del dungeon bisogna anche asssicurarsi che il nemico più forte sia presente nell'ultimo turno di combattimento (come un boss di un dungeon)» — sheet «Va già bene com'è»; order «Riordino i dati a DB» | data at DB (strongest group last) + BE boot report of the dungeon order (quick `261113-aql`); no FE change |
| UAT-FIX-03 | step 10 | «Tempo richiesto» with a leading «,7» | FE `2d3ceb9c`, `bf1d2e78`, `92d661a5` (`20-UAT-FIX-03.md`); rounding up to the minute after the review (WR-04, `4dd1d4af`, `331cf53c`, `0af419f7`) |

Gates after the fixes and the BE merge (2026-11-13, plan 20-04 Task 1): `GATE_OK` on `697d40a1`, schema check 46 × OK, full FE suite `+4339: All tests passed!`, analyzer 47 info / 0 warning / 0 error, `hardening_check` OK.

## Verdict

**complete** — the twelve executed steps pass (step 3 after 20-UAT-FIX-01; steps 7, 8 and 10 with findings fixed during the UAT). Planned steps covered on the device: P1, P2 (by identity switch), P4 (fallback block), P5, P6, P7 (rescuer side), P9, P10 and the optional P11. Not on the device: P3 (Map) not executed and P8 not observed — both covered by the tests of plans 20-01 / 20-02; P7 wounded side checked at DB only; optional P12 and P13 not executed (BE suite). By the orchestrator's closing ruling RANKP-01..04 are complete: RANKP-01 (P1, P2, P4, P6 on the device; P3 by test), RANKP-02 (P1, P2), RANKP-03 (P5, P6, P7, P9 on the device; P8 by test), RANKP-04 (P10 + the gates of 20-03 re-run here on the merged BE).
