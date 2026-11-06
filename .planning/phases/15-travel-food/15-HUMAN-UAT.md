---
status: complete
phase: 15-travel-food
device: Android (USB, adb reverse tcp:3000)
be_ref: b492a46
date: 2026-11-06
completed: 2026-11-06
verdict: steps 1–8 pass (step 5 service-with-line and story halves skipped: not reproducible on this DB, covered by tests; step 7 teleport run through the BE mutation)
---

# Phase 15 — Device E2E (travel food)

App on the Android phone against the local BE from `develop` (`b492a46`, merge of PR #23 `feat/14-viaggio-e-cibo`, BE Phase 14 merged). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "TravelFoodItem"` → `2`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 14 merged running locally; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); food (hunger `LootItem`s) in `assets.ownedItems` of the test character as `{itemType: 'LootItem', item: <ObjectId>, quantity}` and, for the refusal steps, a lowered `status.currentLifePoints` — seeded by the orchestrator with scripts outside the repo following the BE handoff (never printed); reference numbers (BE CONTEXT specifics): nearest city ≈ 55 power / 16 km, any city median ≈ 700 / 204 km; 16 uncovered km cost 136 HP.

### Session data (known on 2026-11-06)

- The BE runs the merged `develop` from its `dist/` on port **3001**, started by the orchestrator; tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`).
- Test character: the user's legend — HP 38 700 / 40 000, no pet, two injuries. City of departure: Chargate (`valanSeaCity`).
- Nearest city by road from Chargate: Voxhold, 20.95 km / 4.19 h / 84 power. Adehr: 31.55 km / 151 power. The farthest cities (Murnborim, 399 km) cost more than 60 000 HP without food → refusal even at full HP.
- Chargate has 7 open standard-lane quests: 5 at the city marker (service: instant jump → `questTravelPreview` is `null` → no «Viaggio» line BY DESIGN, D-01), 1 hunt and 1 enemy quest with a road marker.
- This DB has NO open story/worldMission quest and NO open service quest with a marker off its city marker anywhere (167 cities checked).
- Field names for the orchestrator's seeds (from the BE Phase 14 handoff on BE `origin/develop`, §7 «Dati per la UAT»):
  - `assets.ownedItems`: entries `{ itemType: 'LootItem', item: <ObjectId of a LootItem with effect 'hunger'>, quantity: <n> }` (`item` as ObjectId, never a string), keeping the existing entries (potions, ammunition, …);
  - `status.currentLifePoints`: integer between 1 and `status.maxLifePoints`;
  - catalogue food named by the BE: «Razione da viaggio» (`power` 100), «Pane di Elfo» (`power` 200); partial coverage needs small food (`power` 5–20);
  - a finished travel is shortened with coherent `status.activeTravel.startTime`/`endTime` (shifting only `endTime` is invalid).

### Session notes (2026-11-06)

- Debug APK of HEAD `e1b1d1f` installed with `adb install -r`; BE `develop` `b492a46` from `dist/` on port 3001, `adb reverse tcp:3000 tcp:3001`.
- All seeds by the orchestrator with scripts outside the repo (same `$set` shapes as the BE): `assets.ownedItems` (Manzo Essiccato, Cosciotto di pollo, Razione da viaggio), `status.currentLifePoints`; finished travels closed by shifting `startTime` and `endTime` together so the sweep landed the character; the standard lane freed by shifting `pendingquests.startDate/arrivedAt` so the resolution sweep concluded the quest.
- After the UAT the orchestrator restored the character (Chargate, 38 700 HP, 2x Manzo Essiccato).

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | FOOD-01, FOOD-04 | D-02, D-07 | Trip fully covered: enough food, drag the pawn to a near city → the sheet shows «Cibo: 1x <nome>» (BE order, «Nx nome») and «Vita: nessuna perdita»; «Parti» → the pawn leaves; Journal «Oggetti» shows the food decreased and «Punti vita» unchanged; no banner after the departure (FOOD-01, FOOD-04; D-02, D-07). | pass | User: «pass». Chargate → Voxhold (20.95 km / 4.19 h / 84 power) with 2x Manzo Essiccato (50) in the inventory: the sheet showed «Cibo: 2x Manzo Essiccato» and «Vita: nessuna perdita»; after «Parti» the DB showed both Manzo gone, HP 38 700 unchanged, travel active; the orchestrator closed the travel (coherent `startTime`/`endTime` shift) and the sweep landed the character at Voxhold. |
| 2 | FOOD-01, FOOD-04 | D-02, D-11 | Trip partially covered: little food, a farther city → «Vita: −N HP» (minus sign) and the food it will eat; «Parti» → Journal: that food gone and «Punti vita» reduced by N; no banner (FOOD-01, FOOD-04; D-02, D-11). | pass | User: «pass». Voxhold → Chargate (84 power) with 1x Cosciotto di pollo (50): the sheet showed «Vita: −45 HP»; after «Parti» the Cosciotto was gone and HP went 38 700 → 38 655; no banner; the sweep landed the character at Chargate. |
| 3 | FOOD-01 | D-02, D-10 | Trip refused at the preview: no food (or low HP), a far city → the «Vita» row is red «Non hai cibo a sufficienza per il viaggio» (no number), «Cibo» still lists what would be eaten (or «nessuno»), «Parti» disabled; «Resta» closes the sheet (FOOD-01; D-02, D-10). | pass | User: «pass». No food, HP 38 655, target Murnborim (399 km, 68 635 HP without food): red «Non hai cibo a sufficienza per il viaggio», «Cibo: nessuno», «Parti» disabled, «Resta» closed the sheet. |
| 4 | FOOD-03 | D-03, D-06 | Starving refusal at the departure: open the sheet with enough food, then (orchestrator) remove the food / lower the HP at DB, tap «Parti» → banner «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio»; the sheet stays open, the dashed route stays, the rows refresh to the red phrase with «Parti» disabled; «Resta» closes it (FOOD-03; D-03, D-06). | pass | User: «foglio aperto», then, after the orchestrator removed 1x Razione da viaggio and set HP 100 at DB: «pass». «Parti» → banner «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio», the sheet stayed open with the route, the rows refreshed to red, «Parti» disabled, «Resta» closed it. DB after the refusal: HP 100, no food, no travel (nothing written). |
| 5 | FOOD-02 | D-04 | Quest line: a combat quest and a service quest whose marker is not the character's position, opened from the Board with the swipe available → one line «Viaggio: <cibo> · <vita>» in the costs block; a story sheet, a non-acceptable quest and the map overlay show no «Viaggio» line (FOOD-02; D-04). | pass (combat line and «no line» cases) / skipped (service-with-line and story halves) | User about «Minaccia: 2 Gnoll presso Chargate»: «Non è accettabile ( sono di rango troppo alto) e l'unico slot presente è da avventuriero»; then to the four checks: «pass». «Caccia: Vespa gigante» (7.18 km / 29 power, 1x Razione) → «Viaggio: 1x Razione da viaggio · nessuna perdita»; «Minaccia: 2 Gnoll» (non-acceptable: a legend cannot fill an adventurer-only slot) → no line; «Lavori di bottega a Chargate» (service at the city marker, instant jump, D-01) → no line; the Vespa sheet opened from the map marker → no line. The «service quest with a line» and «story sheet shows no line» halves: skipped (not reproducible on this DB; covered by tests) — this DB has no open story/worldMission quest and no open service quest with a marker off its city marker (167 cities checked); covered by the 15-06/15-07 tests («a sheet without a preview shows no travel line (D-04)», narrative family → no line). The user was told before the step and answered «pass»; orchestrator ruling: FOOD-02 complete. |
| 6 | FOOD-02, FOOD-03 | D-04, D-05, D-06 | Quest starving: with no food (or low HP) the «Viaggio» line is red «Viaggio: Non hai cibo a sufficienza per il viaggio» and the paper resists the swipe; then with food at the sheet opening, remove it at DB and tear the sheet → banner «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio», the sheet recomposes and its line turns red (FOOD-02, FOOD-03; D-04, D-05, D-06). | pass | User: «resiste» (no food, HP 20: red «Viaggio: Non hai cibo a sufficienza per il viaggio», the paper resisted the swipe); then «foglio aperto» (sheet reopened with 1x Razione da viaggio: normal line) and, after the orchestrator removed the Razione at DB: «pass» → banner «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio», the sheet recomposed, the line turned red. DB after: hunt quest with no registered adventurer, no travel, channel points 5000 unchanged. |
| 7 | FOOD-04 | BE D-13 | Teleport unaffected: the innkeeper teleports the test character (Locanda → queue → Map) → Journal «Oggetti» and «Punti vita» unchanged (FOOD-04, ROADMAP criterion 4; BE D-13). | pass | User: «Non posso sportarlo così. Avrei bisogno di una missione story da accettare. a quel punto sarei in coda e potrei spostarmi.» The Locanda teleport is reachable only with a story quest in the queue and this DB has none, so the orchestrator performed the teleport through the BE mutation `teleportCharacter` with the development innkeeper identity (Chargate → Voxhold), with 1x Razione da viaggio and HP 38 655 in place. User then: «pass» — pawn at Voxhold, Journal «Oggetti» 1x Razione da viaggio and «Punti vita» 38 655 unchanged, no banner. BE path exercised; the FE Locanda path was not reachable on this DB. |
| 8 | — (extra, review fix WR-01, no requirement) | D-04 | Open a hunt sheet while the standard lane is busy, free the lane → the «Viaggio» line appears without reopening the sheet; once shown, the line stays until the sheet closes even if the quest stops being acceptable. | pass | The user accepted «Lavori di bottega a Chargate» (lane busy), opened «Caccia: Vespa gigante» (no line, not acceptable) and said «foglio aperto»; the orchestrator freed the lane through the resolution sweep (shifted `pendingquests.startDate/arrivedAt`); user: «pass» — the line «Viaggio: 1x Razione da viaggio · nessuna perdita» appeared with the sheet still open and the swipe came back. No requirement. |

Requirement ↔ step map: FOOD-01 (1, 2, 3), FOOD-02 (5, 6), FOOD-03 (4, 6), FOOD-04 (1, 2, 7). The instant jump (no road) and a `null` acceptance preview have no device path the user can force reliably: covered by the 15-02/15-07 tests («returns null when the acceptance involves no travel (D-01)», «a sheet without a preview shows no travel line (D-04)»). Step 8 is extra (review fix WR-01) and never blocks a requirement.

## Verdict

- FOOD-01: steps 1, 2, 3 pass → complete.
- FOOD-02: step 5 pass on the device for the combat line and the non-acceptable / instant-jump / map-overlay «no line» cases, the service-with-line and story halves skipped (not reproducible on this DB; covered by tests); step 6 pass → complete by the orchestrator's ruling.
- FOOD-03: steps 4, 6 pass → complete.
- FOOD-04: steps 1, 2, 7 pass (step 7 through the BE `teleportCharacter` mutation: the Locanda path needs a story quest in the queue and this DB has none) → complete.
- Step 8 (extra, WR-01): pass.

No gaps.
