---
status: in-progress
phase: 18-heal-quests-by-size
device: Android (USB, adb reverse tcp:3000)
be_ref: 66df2ef2
date: 2026-11-11
verdict:
---

# Phase 18 — Device E2E (heal quests by city size)

App on the Android phone against the local BE from `develop` (`66df2ef2`, merge of BE PR #31 `feat/18-quest-heal-per-taglia`, BE Phase 18 merged with the quick tasks 261110-cgd, 261110-mag and 261110-prp). Gate re-checked before this file was written: the seven names `type QuestCure`, `injuriesHealed`, `noEffect`, `type LootRecovery`, `potionRecoveryUntil`, `useItem(`, `type UseItemResult` are all present in `origin/develop:src/schema.gql` → `GATE_OK`. Results are recorded only from the tester's words (device steps) and the orchestrator's words (the GraphQL probe of step 12). Notes carry no ids of real users, no tokens, no Mongo URIs and no identity values (environment variable names only).

## Setup

Setup: BE `develop` with Phase 18 merged, restarted by the orchestrator; content written at DB by the orchestrator after the user's review (heals by city size, `recovery` on the heal potions, lore «Il limite del corpo» linked from the potions); **player identity** switched on as described in the BE Phase 18 handoff; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); APK of `feat/18-heal-quests-by-size` (it selects `cure`, `noEffect`, `injuriesHealed`, `recovery`, `potionRecoveryUntil` and must never run against a BE without Phase 18); every seed (injuries, HP, inventory, quest and travel times, recovery end) and the GraphQL probe are the orchestrator's job, done outside the repo and never printed. The Board is opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 18 merged on BE `develop` (PR #31, `66df2ef2`; local ref `origin/develop` points there) | done (orchestrator, 2026-11-11) |
| BE restarted from `develop` (port 3001, device tunnel `adb reverse tcp:3000 tcp:3001`) | done (orchestrator, 2026-11-11) |
| Content written at DB and re-read: 166 heals by size (98 villages share 0.5 / 2 h, 58 cities 0.8 / 5 h, 10 capitals 1 / 8 h), `recovery` on the 28 heal potions, lore «Il limite del corpo» linked from the potions, crime (rookie) and guard (paladin, 4 h) ranks and prizes, the new `magic` quest at Valantar | done (orchestrator, 2026-11-11) |
| Debug APK of `ea7995f` (`feat/18-heal-quests-by-size`) installed on the Android phone | done (orchestrator, 2026-11-11) |
| Player identity switched on the BE process (see «Player identity») | done (orchestrator, 2026-11-11) |
| Seeds per step | |
| GraphQL probe of step 12 | |

Note: the BE handoff runbook (§3 c) announced 98 villages / 59 cities / 9 capitals; the orchestrator's re-read after the content script counted 98 / 58 / 10 (166 in total in both). Recorded as reported, not a finding of this UAT.

## Player identity

- Mechanism (BE Phase 18 handoff `origin/develop:.planning/phases/18-quest-heal-per-taglia/BACKEND-NOTES.md` §3 b «Identità di test»: dev bypass with a test twitch id distinct from the real one, one single BE process; the handoff writes only a placeholder for the id): environment variables of the BE **process** (never the `.env` file), set by the orchestrator at the restart — `DEV_AUTH_TWITCH_ID` (the twitch id of the owner of the test character) and `DEV_AUTH_ROLE` (the player role). Values never written here.
- Rule: every HEAL step runs as the player. `useItem` acts on the current character of the bearer (BE D-21), so the probe of step 12 uses the same player bearer.

## Session data (known on 2026-11-11)

Field names only, from the BE Phase 18 handoff (§1.5, §1.6, §3) and `18-12-SUMMARY.md`; no ids, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE; the characters change stream re-emits `characterUpdated` on every update.

- Heals by size (collection `quests`): `prizes.cure.lifePointsShare` (0.5 / 0.8 / 1), `prizes.cure.canHeal` (the injury list of the size), `infos.timeToComplete` (2 h / 5 h / 8 h before shortening), `infos.description`, `infos.type`; `requirements.minTitle` for the crime (rookie), guard (paladin) and `magic` quests.
- Character vitals: `currentLifePoints`, `maxLifePoints`, `status.injuries` (injuries in and out of the size lists for steps 1, 3, 4, 7; empty for steps 6 and 13).
- Character position and travel: `status.location` (village, city, capital of steps 1–7), `status.activeTravel.startTime` / `status.activeTravel.endTime` shifted together (step 14 and quest/travel shortening); arrivals via a real travel or the GM teleport as in earlier UATs.
- Potions: the herb stack in the character inventory (same write shape as `useItem`), `recovery { time, turns }` on the potion item, `relatedLore` towards «Il limite del corpo» (type `knowledge`), `status.potionRecoveryUntil` (cleared to `null` before steps 9, 13, 14), `status.unlockedLore` (without «Il limite del corpo» before step 9, so the lore line appears).
- Awaiting aid (step 15, optional): `status.awaitingAid`.
- Prison (extra checks): `status.imprisonedUntil` (a date in the future; the BE sweep sets it back to `null` within about one `QUEST_SWEEP_INTERVAL_MS` after expiry and sends the data-only push `type: prisonRelease`).
- Results at DB: `questresults.injuriesHealed`, `questresults.arrested`, `questresults.coinsLost`, `questresults.guardEncounter`.
- GraphQL probe (step 12, player bearer): `useItem(itemId)` during the recovery → expected `extensions.code` `POTION_RECOVERING` with `extensions.recoveryUntil`; inventory and HP unchanged.

## Steps

| Step | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|-----------|----------|--------|--------|------|
| 1 | HEAL-01, HEAL-03 | D-03, D-04 | Village — sheet. Character in a village with HP below half and two seeded injuries, one in the village list (e.g. «contusione») and one not (e.g. «cecità»). On the Board open the temple heal: the announcement paper with its description and «Tempo richiesto» of the village; «Cura le tue ferite: contusione» (only the listed one, lowercase) and «Vita: almeno il 50%» (HEAL-01, HEAL-03; D-03, D-04). | | user | |
| 2 | HEAL-02, HEAL-03 | D-06 | Village — result. Accept it (time shortened by the orchestrator): the result sheet shows the HP bar rising in green to half of the maximum and «Guarite: contusione» between the bar and the injuries; in the Journal the unlisted injury is still there and the HP is at 50 % (HEAL-02, HEAL-03; D-06). | | user | |
| 3 | HEAL-01, HEAL-02, HEAL-03 | D-03 | City. Character moved to a city with HP below 80 % and two seeded injuries (one in the city list, one only in the capital list): the sheet shows the cure line with the listed one and «Vita: almeno l'80%»; the result shows HP to 80 % and «Guarite: …» with that injury only (HEAL-01, HEAL-02, HEAL-03). | | user | |
| 4 | HEAL-01, HEAL-02, HEAL-03 | D-03 | Capital. Character moved to a capital with several seeded injuries and low HP: the sheet lists every injury of the character and «Vita: al massimo»; the result shows HP full and «Guarite: …» with all of them; the Journal shows no injury (HEAL-01, HEAL-02, HEAL-03). | | user | |
| 5 | HEAL-01 | D-05 | No cure, no rows. In the same city open a quest without a cure (a hunt or a job): neither «Cura le tue ferite» nor «Vita» (HEAL-01; D-05). | | user | |
| 6 | HEAL-06 | D-20 | Useless heal torn. The character is now healthy (HP full, no injury) in a city: the temple sheet is still in its place on the Board but drawn torn; open it: it says «Il tempio non può fare nulla per te adesso», the swipe does nothing and nothing is accepted (HEAL-06; D-20). | | user | |
| 7 | HEAL-06 | D-20 | Whole again. With the Board open, the orchestrator seeds an injury of that temple's list (or lowers the HP): without leaving the Board and without any spinner the temple sheet is whole again; it can be opened and torn to accept (HEAL-06; D-20). | | user | |
| 8 | HEAL-05 | D-13, D-17 | «Ricarica» rows. In the shop of a city and in the Journal «Oggetti» the heal potions show «Cura: …» and under it «Ricarica: …» (the field herb: «Ricarica: 30 min»); the other items show no such line (HEAL-05; D-13, D-17). | | user | |
| 9 | HEAL-04 | D-11, D-18 | Drink a field herb. Character with HP below the maximum and one injury the herb cures, no recovery in course. Journal «Oggetti»: tap the herb parchment → a parchment sheet «Bevi <nome>?» with its «Cura: …» and «Ricarica: …» lines and the actions «Bevi» / «Non ora»; «Non ora» closes it and nothing changes; tap again and «Bevi»: no spinner, the same sheet shows the HP bar rising in green, «Guarite: …» and «Conoscenza appresa: Il limite del corpo»; «Continua» closes it; in the Journal the HP and the stack are updated without any reload (HEAL-04; D-11, D-18). | | user | |
| 10 | HEAL-05 | D-12 | Countdown. Right after step 9 every heal parchment of «Oggetti» is dimmed with «pronta fra …» (about 30 min) and a tap on any of them does nothing; send the app to the background and back: the countdown is coherent (HEAL-05; D-12). | | user | |
| 11 | HEAL-04 | D-16 | Lore. Library: the «Conoscenze» book has the «Nuovo» bookmark and the page «Il limite del corpo» (HEAL-04; D-16). | | user | |
| 12 | HEAL-05 | D-12, D-19 | Second potion — orchestrator's probe. During the countdown the orchestrator sends `useItem` for a heal potion with the player's bearer: the answer is a refusal with `extensions.code` `POTION_RECOVERING` and an `extensions.recoveryUntil` equal to the recovery end; inventory and HP unchanged. Recorded from the orchestrator's words (the disabled parchment never sends the call, D-19) (HEAL-05; D-12, D-19). | | orchestrator probe | |
| 13 | HEAL-04 | D-11 | No effect. The orchestrator clears the recovery end and leaves the character with full HP and no injury the herb cures: tap the herb → «Bevi» → the sheet closes and the parchment banner «Pozione non bevuta» says «Questa pozione non ti farebbe nulla adesso»; the stack is unchanged and no countdown starts (HEAL-04; D-11). | | user | |
| 14 | HEAL-04 | D-11 | In travel. With the recovery end cleared, HP below the maximum and a travel in course (started by the orchestrator's seed or by the user from the Map): from the Journal the herb can be drunk exactly as in step 9 (HEAL-04; D-11). | | user | |
| 15 | HEAL-04 (optional) | D-11 | (optional) Awaiting aid. With the character awaiting aid (seeded): the heal parchments are not tappable and show no countdown (HEAL-04; D-11). | | user | |

Requirement ↔ step map: HEAL-01 (1, 3, 4, 5), HEAL-02 (2, 3, 4), HEAL-03 (1, 2, 3, 4 and the gate of 18-12), HEAL-04 (9, 11, 13, 14), HEAL-05 (8, 10, 12), HEAL-06 (6, 7); step 15 optional. Not on the device, covered by tests: the `POTION_RECOVERING` banner with the server's remaining time (18-08 «the remaining time of a recovery refusal comes from the server date on the server clock (D-11, D-19)»), the lenient parsers (18-01, 18-02), the `QUEST_NO_EFFECT` notice on a stale list (18-11).

## Extra checks — prison, guard, sheet families (quick 261110-cgd / 261110-prp / 261110-shs2)

User's rules added to the phase by the quick tasks 261110-cgd (crime arrest, guard encounter, prison), 261110-prp (prison release push) and the sheet families per quest type. They map to no HEAL requirement; a failing row becomes a gap of its quick task, not of the phase requirements.

| Check | Quick | Expected | Result | Source | Note |
|-------|-------|----------|--------|--------|------|
| E1 | 261110-cgd | Prison seeded by the orchestrator (`status.imprisonedUntil` in the future): the marker «In prigione per: <tempo>» over the pawn, counting down. | | user | |
| E2 | 261110-cgd | In prison the Board and the Shop of the satchel are closed and a travel cannot start. | | user | |
| E3 | 261110-cgd | In prison the Journal opens and a potion can be drunk. | | user | |
| E4 | 261110-cgd, 261110-prp | At the release instant the marker disappears and Board/Shop reopen with no spinner; with the app in background the push «Di nuovo libero» arrives (category «Uscita di prigione» in the settings). | | user | |
| E5 | 261110-shs2, 261110-cgd | Board: crime, guard, hunt, job, heal, magic and study quests each on the paper of their own family; crime and study/job open to a rookie, guard requires paladin. | | user | |
| E6 | 261110-cgd | (if it happens or seeded) Result sheet of a crime with an arrest («Sei stato arrestato.», «Monete confiscate») or of a guard with an encounter («Scontro durante la guardia: …»). | | user | |
