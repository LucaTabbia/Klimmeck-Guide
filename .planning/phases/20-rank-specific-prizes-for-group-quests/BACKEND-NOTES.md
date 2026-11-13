# Phase 20 (FE) — Backend notes

Written pre-gate by plan 20-02; §3 is completed by plan 20-04 after the device E2E.

Frontend companion of the BE Phase 21 («Premi per rango e soccorsi»). Branch `feat/20-rank-specific-prizes`. English text, Italian UI copy verbatim. No ids of real users or characters, no secrets, no URIs, no environment values in this file.

## 1. Contract consumed by the FE

```graphql
# QuestFragment (quests and OnQuestUpdated) — selection UNCHANGED in this phase
noEffect
prizes {
  prizeCoins { …CoinsFragment.fields }
  xpPrize
  randomLoot { quantity item { … } }
  prizeItem { quantity item { … } }
  pet { id name }
  cure { lifePointsShare canHeal }
}

# QuestResultFragment.fields — added by plan 20-03 once the BE PR is merged,
# right after `stagesCleared stagesTotal`
turnsTotal
turnsCompleted
lastTurn
lastTurnKind
```

- `Quest.prizes` is read as **the viewer's block**: the FE never chooses, merges, scales or falls back between blocks (the D-18 fallback lives only in the BE). No `spell` is selected under `prizes`.
- `Quest.rankPrizes` is **NOT selected** in this phase (FE Phase 21 / BE Phase 22 will read it for the innkeeper's prize step).
- `QuestResult.turnsTotal`, `turnsCompleted`, `lastTurn` (`Int`) and `lastTurnKind` (`DungeonTurnKind { exploration fight }`) are parsed leniently: a missing or non-number count is `null`; an unknown or non-string kind is `null` and the line simply carries no kind. A malformed turn field never drops the result.
- `stagesCleared` / `stagesTotal` stay selected: they are the fallback line when the BE sends no turns.
- Registry: 46 documents, no new operation (the schema check against the merged BE runs in plan 20-03).

## 2. FE behaviours proved by tests

- Quest sheet (plan 20-01): the sheet prints the served `prizes` block on Board and Map whatever the viewer's title, and ignores a `rankPrizes` key present on the payload; no spell row on the quest sheet.
- Mixed boss (plan 20-01, BE D-23): paladin ×2 + adventurer ×1 seats with `minTitle` adventurer render one seat line per title; registration and fullness are per title; the party counter shows on every seat.
- Result sheet (plan 20-02): one turn line takes the slot of the stages line (right after the enemies) for a dungeon and a dungeon aid. Copy:

| Situation (served fields only) | Line |
|--------------------------------|------|
| `turnsTotal` null or ≤ 0 | no turn line → «Esplorazione: tappa N di M» (or nothing when `stagesTotal` is null) |
| `outcome` = `rescued`, `death` or `gmCompleted` | no turn line (fallback as above), even with the turn fields filled |
| `success`, quest type ≠ `aid` (dungeon cleared) | «Piani superati: C su T» |
| `success`, quest type = `aid`, `lastTurn` present (rescuer saved the wounded) | «Soccorso effettuato al raggiungimento del L° piano su T» |
| `failure`, `lastTurn` present, `lastTurnKind` = `exploration` | «Caduto al L° piano su T, in esplorazione» |
| same, `lastTurnKind` = `fight` | «Caduto al L° piano su T, in uno scontro» |
| same, `lastTurnKind` null or unknown | «Caduto al L° piano su T» |
| `lastTurn` absent where the rows above need it | «Piani superati: C su T» |

  `L` = `lastTurn` as served (the FE **never adds 1**), `T` = `turnsTotal`, `C` = `turnsCompleted ?? 0`. Copy amended by the user during the device UAT (2026-11-13, `20-UAT-FIX-02.md`): «piano» replaces «turno» in every line.
- No «prize in proportion» line: the reduced prize of a dungeon aid shows only under «Ricompense» (D-20, D-21).
- Against the BE of today the four turn fields are absent and the sheet is identical to before.

## 3. UAT outcome (FE Phase 20, 2026-11-13)

BE ref: the session ran on `develop` `7f3506ac` (BE Phase 21 merged), then on the quick-task branch `feat/quick-aid-locks-source-quest`; both are now on `develop` `697d40a1` (PR #37). Gate re-run on `697d40a1`: `GATE_OK`, 46 × OK, full FE suite 4339 green. Record: `20-HUMAN-UAT.md` (12 executed steps, all pass). Results relevant to the BE:

- **Block per title on HTTP.** Mixed boss seeded with seats hero ×1 + mage ×1 and two blocks (hero: 5 gold, 500 xp, 2 «Radice Curativa»; mage: 1 gold, 100 xp, 1 «Datteri»): the mage character saw the mage block, the legend saw the hero block. Pass.
- **Fallback block (D-18).** No legend block was seeded: the legend read the hero block (highest block not above its rank). Pass.
- **Change of title.** Checked by switching identity between two characters of different title (no title change at DB on an open sheet); the FE reread on a title change stays pinned by its tests. Per-subscriber resolution on `questUpdated` was not isolated on the device.
- **Mixed boss `minTitle`.** «Titolo minimo: Mago» (lowest seat) and one seat line per title. A FE defect found here (a legend on a hero seat counted on no line) was fixed on the FE (`20-UAT-FIX-01.md`, mirror of BE 13.1 D-08); no BE change.
- **Boss win by block (D-08, optional step run).** DB: the mage received 1 gold + 1 «Datteri», xp 125; the legend on the hero seat 5 gold + 2 «Radice Curativa»; log «Boss … risolto per 2 partecipanti». Pass.
- **Turn counters.** Dungeon of 4 groups (8 turns) lost at the 2nd turn: result `turnsTotal` 8 / `turnsCompleted` 1 / `lastTurn` 2 / `fight`, line «Caduto al 2° piano su 8, in uno scontro». Rescuer's result: 8 / 2 / 2 / `fight`, line «Soccorso effettuato al raggiungimento del 2° piano su 8». Cleared dungeon (8 floors): 8 / 8 / 8 / `fight`, line «Piani superati: 8 su 8». All pass. The wounded's `rescued` result checked at DB only (no turn fields). Note: the aid born from the second fall carried `rescue.turn {1, fight, 8}`, consistent with the 0-based turn index of §4 and `lastTurn` 2 on the fall and on the rescuer.
- **Aid share on the sheet.** The aid sheet showed 25 silver, 20 xp, 1 «Radice» = the share the BE wrote (a quarter of the 1 gold / 80 xp / 4 «Radice» dungeon); after the quick-task additions also the enemies actually faced (one «Arbusto Maligno» instead of four) and «Tempo richiesto: 8 secondi» (7500 ms of 30000). Pass.
- **Wounded freed.** After the rescue the source dungeon was whole and acceptable again and the aid gone. Pass.
- **Lost fight without rescue (D-19).** Artificial job with enemies (no real job has enemies): defeat, life 1, no awaiting rescue, lane free, no aid. Pass.
- **Not run on the device:** the archiver release (D-16 — covered by the BE suite, BE D-27) and the spell for a non-caster (D-05b, BE suite); a defeat in an exploration turn (BE D-29 placeholder never fails an exploration).
- **New user rules born in the UAT, all on the BE quick `261113-aql` (merged):** the source hunt / dungeon of an open aid is locked for everyone until the aid closes (supersedes D-15); the aid lists the enemies actually faced; the aid time is scaled with the same share as the prize; the dungeon order (strongest group last) is reported at boot (data reordered at DB by the orchestrator).
- **Open, for the user (not blocking):** the banner copy shown on a refused locked quest (today the shared «Missione non disponibile, avvisa il locandiere»); `Quest.rankPrizes` is readable by every authenticated user.

## 4. Questions and notes for the BE

1. `Quest.prizes` must stay **non-null for every viewer and on every path that returns a `Quest`**, including the `PendingQuest.quest` parent (BE §Q7: empty prize) — a null drops the «Ricompense» area of the quest sheet.
2. Per-subscriber resolution on `questUpdated` (memo per viewer inside the event key, BE «trappola Phase 16»): the FE cannot detect a wrong block, only the two-title device step of plan 20-04 can.
3. Mixed boss: `minTitle` = lowest seat title and seats ordered own rank first (BE D-23). The FE gates on `minTitle` before the seats.
4. `lastTurn` semantics as fixed: 1-based, the last turn played; `turnsTotal` on a cleared dungeon. On a success of a non-aid dungeon the FE ignores `lastTurnKind`.
5. Turn fields on the rescued character's result (`outcome: rescued`) and on the wounded character's `death` result: does the BE fill the turn fields on `death`? The FE prints no turn line for `rescued`, `death` or `gmCompleted` anyway.
6. D-19: which `outcome` does a lost fight without aid write (the FE header reads «Sconfitta» for `failure`), and is `awaitingAid` left null so no «In attesa di soccorso» appears?
7. D-24: a refused group quest with a null-title seat returns `QUEST_NOT_ACCEPTABLE`, already mapped by the FE (`lib/repository/quest_acceptance_failure.dart`).
8. D-27: the archiver path sends the same `questCancelled` push as the timeout (category already handled by the FE).

Planned on BE branch `feat/21-…` (BE plans 21-08..21-10, not yet merged), turn fields per result as the FE expects them — `turnsTotal`, `turnsCompleted`, `lastTurn`, `lastTurnKind`:

- dungeon won: T, T, T, `fight`;
- dungeon lost at turn i: T, i, i+1, kind of turn i (i, s, f read as 0-based turn indices, so `lastTurn` = i+1 is the 1-based last turn played; the FE prints the served value and never adds 1 itself);
- rescuer who wins the dungeon aid: T, s+1, s+1, kind of the saved turn s;
- rescuer who loses at turn f: T, f, f+1, kind of turn f;
- `rescued`: all null;
- `death` of the wounded (lost rescue or timeout): T, s, s+1, kind of the saved turn — the FE prints no line on `death` by ruling (answers question 5);
- every other result (`gmCompleted`, lost fight without aid, ambush, non-dungeon quests): all null;
- a lost fight without aid (D-19) carries outcome `failure`, the same value as a lost guard encounter (answers the first half of question 6; `awaitingAid` still open).

Da riportare nella UAT della BE Phase 21 a cura del lato BE (questo repo non modifica il BE).

## Update 2026-11-13 — quick 261113-aql

User rule (2026-11-13), verbatim: «Quando un personaggio attiva una aid a partire da una hunt o da un dungeon (quindi le uniche quest ripetibili che possono creare una aid) la quest che le ha generate deve risultare strappata e quindi non accettable, finché il soccorso non va a buon fine.» Locked for everyone; free again whenever the aid closes (rescue done, wounded dead by timeout, wounded archived); a lost rescue opens a new aid from the same quest and the lock continues. **Supersedes D-15.**

What the app consumes (BE twin `feat/quick-aid-locks-source-quest`):

- `Quest.awaitingRescue: Boolean!` — selected in `QuestFragment` (`quests` and `OnQuestUpdated`); `true` → the sheet is torn for every viewer, not acceptable, reason «Soccorso in corso: la missione riapre quando il soccorso si conclude.» (amended after the review, IN-03 of `20-REVIEW-UAT.md`). The same value for every viewer; never null (the FE reads absent/malformed as `false`).
- `acceptQuest` on a locked quest → `QUEST_NOT_ACCEPTABLE` (already mapped to `QuestAcceptanceFailure.notAcceptable`; no new code).
- `questUpdated` must republish the source quest **when the aid is born and when it closes** (every closing path: rescue done, timeout death, archiver): the FE has no other trigger to lift the lock (it never reads the aid quests and does not reread `quests` for this).
- Correction after the review (WR-01, `20-REVIEW-UAT-FIX.md`): `questUpdated(questId)` is one subscription per quest id and the app follows only the viewer's own lane quest, so the lock is **not live on an open Board**. It shows at the next read of `quests` (Board opening, scope change of the viewer, map reread) or right after a refused accept: `QUEST_NOT_ACCEPTABLE` now triggers a silent reread of `quests`.
- Schema check run after the BE merge (`697d40a1`, PR #37): `awaitingRescue` present, 46 × OK.
- Schema check (46 documents) to be run by the orchestrator after the BE twin is merged on `develop`: until then the FE fragment selects a field the BE SDL does not have.
