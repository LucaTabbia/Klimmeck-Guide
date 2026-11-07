---
status: in-progress
phase: 16-travel-ambushes
device: Android (USB, adb reverse tcp:3000)
be_ref: 9103440
date: 2026-11-07
verdict:
---

# Phase 16 — Device E2E (travel ambushes)

App on the Android phone against the local BE from `develop` (`9103440`, merge of PR #24 `feat/15-imboscate-in-viaggio`, BE Phase 15 merged). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "AmbushReport"` → `2`; the `fetch` was skipped (the SSH agent is dead in this session; the orchestrator aligned `origin/develop` to `9103440` over HTTPS). Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 15 merged running locally; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); ambushes forced by the orchestrator at DB following the BE handoff (internal `activeTravel.ambush { at, km }` moved into the past — or seeded whole when the departure draw did not hit — then the ambush sweep; `status.currentLifePoints` seeded low to force a defeat, HP never below 1; reports held until the arrival, so a travel is closed with coherent `startTime`/`endTime` — shifting only `endTime` is invalid); never printed. Reference (BE CONTEXT D-01): ~0,2 %/km by day, ~0,6 %/km by night, no draw under 10 km.

### Session data (known on 2026-11-07)

- The BE runs the merged `develop` (`9103440`) from its `dist/` on port **3001**, rebuilt and started by the orchestrator; tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`).
- Redis is NOT running on this machine (the BE warns `Redis non raggiungibile`): the Bull jobs are only triggers; the ambush and travel sweeps (`TRAVEL_SWEEP_INTERVAL_MS`, default 60 000 ms) resolve every seeded ambush with `at ≤ now` and every expired travel, so every forced step waits ≤ 60 s.
- Test character: the user's legend — level 20, HP 38 700 / 40 000, two injuries, worn equipment on head / chest / legs, 2 active spells. City of departure: Chargate.
- Nearest city by road from Chargate: Voxhold, 20.95 km / 4.19 h (≥ 10 km: a valid free travel for the seeded ambush of step 1).
- Chargate open quests with a road marker: «Caccia: Vespa gigante» (7.18 km, open slots — shorter than the 10 km the BE handoff §6(a) names for a seeded ambush) and «Minaccia: 2 Gnoll» (11.07 km, adventurer-only slot: not acceptable by a legend). Step 2 needs an acceptable hunt/enemy quest with a road travel: the orchestrator picks it (or seeds the ambush on the Vespa travel if the BE resolves it) at session time.
- Enemies for the level-20 band [394, 803] xp (BE handoff §3): 17 non-legendary singles in band, 148 weaker enemies for packs; `all` fallback pool when the zone pool is not composable.
- Field names for the orchestrator's seeds (BE Phase 15 handoff on BE `origin/develop`, §6 «Dati per la UAT», and `16-07-SUMMARY.md` §5):
  - forced ambush: `status.activeTravel.ambush = { at: <past Date between startTime and now>, km: <integer, 1 ≤ km < road.distance>, attempts: 0 }`, seeded whole on a real in-progress travel of ≥ 10 km; the ambush point is the planar fraction `km / distance` of the polyline (not derived from `at`);
  - forced defeat: empty `assets.wearedEquipment` (object: head / chest / arms / legs / foots / leftHand / rightHand / firstAccessory / secondAccessory → null) and `assets.activeSpells` (array → []) → power 0 → certain defeat; restored afterwards; a low `status.currentLifePoints` makes the HP bar visible (HP never below 1); a victory is never guaranteed (`power / (power + enemies' HP)`): keep weapons and spells and repeat if needed;
  - two ambushes: a second seed after the first resolution with a larger `km` and a later `at` (still in the past), or two entries in `status.activeTravel.ambushReports[]` with the travel `endTime` in the past;
  - closing a travel with held reports: coherent `status.activeTravel.startTime`/`endTime` shift (shifting only `endTime` is invalid), then the completion sweep; or the GM teleport (`teleportCharacter`, refused with `QUEST_IN_PROGRESS` while the standard lane is busy — free after a defeat);
  - expected DB after a defeat: `status.activeTravel.startTime = at`, `to` = city marker, no `ambush`, `kind: free`, `quests.pendingQuest = null`; food not refunded;
  - delivered reports (`questresults`): `kind: 'ambush'`, `quest: null`, `ambush.at = resolvedAt`; on a defeat `ambush.reachedCity` set, `rewards.coins` and `xpGained` zero; effects (HP, injuries, coins, xp) arrive at once on `characterUpdated` (BE D-17), the report at the arrival.
- BE log lines to watch: `Imboscata <jobId> risolta: won` / `Imboscata <jobId> risolta: lost verso <città>` / `… skipped (<motivo>)`.
- GraphQL probe (owner bearer, orchestrator): `{ unacknowledgedQuestResults { id kind outcome resolvedAt quest { title } ambush { at nearCity { name } reachedCity { name } } } }`.
- Review notes to look at (not failures): a lone quest sheet after a carousel of N ambushes reads «N+1 di N+k» (D-11, review IN-03); offline a queued carousel waits for the in-flight silent retry to give up (~2 min), no spinner (review IN-01).
- BE observation to route in `BACKEND-NOTES.md` §5: at km 16 of the BE test world the detour polyline walks back to the snapped graph node before heading to the city (graph snapping, BE handoff §8(a), research C7) — check on the device whether the pawn visibly backtracks after a defeat.

### Session notes (2026-11-07)

_Filled by Task 3 from the session run by the orchestrator with the user._

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | AMBUSH-02, AMBUSH-03 | D-04, D-05, D-06 | Won ambush on a free travel: start a travel ≥ 10 km, force a won ambush → no push, no banner, the pawn keeps going on the same route; Journal «Punti vita» decreased; at arrival `travelEnd` push/banner, then on the free Map a one-page carousel (no «k di N») with «Vittoria», «Imboscata presso <città>», the enemies, the HP bar, «Ricompense» (coins) and «Esperienza»; no «Missione conclusa» banner (AMBUSH-02, AMBUSH-03; D-04, D-05, D-06). | | |
| 2 | AMBUSH-01 | D-02, D-03, D-10 | Lost ambush on a quest travel: accept a hunt/enemy quest with a road marker, force a defeat → push «Imboscata!» / «Sei stato sconfitto: la via torna verso <città>» with the app in background, the in-app banner with the same text in foreground; tap → Map centred on the pawn restarting from the ambush point with a new dashed route and remaining time towards that city; the Board quest lane is free (AMBUSH-01; D-02, D-03, D-10). | | |
| 3 | AMBUSH-02 | D-04, D-05, D-13 | Arrival after the defeat: at the nearest city the carousel shows «Sconfitta», «Imboscata presso <città>», the HP bar down to the BE value, «Ferite», «Portato a <città>», no «Ricompense», no «Esperienza»; «Continua» closes; a cold restart shows nothing again (AMBUSH-02; D-04, D-05, D-13). | | |
| 4 | AMBUSH-02 | D-05, D-11, D-12 | Two ambushes on one travel: win one, force a second (won or lost) → at arrival one carousel «1 di 2», swipe → «2 di 2», chronological; «Continua» on page 1 closes and acknowledges both; a cold restart shows nothing again (AMBUSH-02; D-05, D-11, D-12). | | |
| 5 | AMBUSH-01 | D-02, D-10 | Toggle «Imboscate» off in Settings, force a defeat → no push, no banner; the pawn still restarts towards the nearest city and the carousel still opens at arrival; toggle back on (AMBUSH-01; D-02, D-10). | | |
| 6 | AMBUSH-03 | D-07, D-17 | Before a travel that will be ambushed: the confirmation sheet shows exactly «Distanza, Durata, Arrivo, Cibo, Vita» and the quest «Viaggio» line is as in Phase 15 — no ambush wording anywhere (AMBUSH-03; D-07, D-17). | | |
| 7 | AMBUSH-02 (optional) | D-06; BE D-13 | (optional) GM teleport mid-travel with a held report → after the teleport the carousel opens on the free Map (AMBUSH-02; D-06; BE D-13). | | |

Requirement ↔ step map: AMBUSH-01 (2, 5), AMBUSH-02 (1, 3, 4), AMBUSH-03 (1, 6); step 7 optional. The merge of two travels' unacknowledged reports into one carousel (D-16) and the live batch race (D-12) have no reliable device path: covered by the 16-04/16-05 tests («a live ambush during an in-flight read chains exactly one more read (D-12)», «a live ambush waits for the settling read and opens with its batch (D-12)»).

## Verdict

_Pending the device session (Task 2); written by Task 3 from the user's words._
