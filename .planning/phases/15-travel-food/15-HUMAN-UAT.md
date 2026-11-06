---
status: in-progress
phase: 15-travel-food
device: Android (USB, adb reverse tcp:3000)
be_ref: b492a46
date: 2026-11-06
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

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | FOOD-01, FOOD-04 | D-02, D-07 | Trip fully covered: enough food, drag the pawn to a near city → the sheet shows «Cibo: 1x <nome>» (BE order, «Nx nome») and «Vita: nessuna perdita»; «Parti» → the pawn leaves; Journal «Oggetti» shows the food decreased and «Punti vita» unchanged; no banner after the departure (FOOD-01, FOOD-04; D-02, D-07). | | |
| 2 | FOOD-01, FOOD-04 | D-02, D-11 | Trip partially covered: little food, a farther city → «Vita: −N HP» (minus sign) and the food it will eat; «Parti» → Journal: that food gone and «Punti vita» reduced by N; no banner (FOOD-01, FOOD-04; D-02, D-11). | | |
| 3 | FOOD-01 | D-02, D-10 | Trip refused at the preview: no food (or low HP), a far city → the «Vita» row is red «Non hai cibo a sufficienza per il viaggio» (no number), «Cibo» still lists what would be eaten (or «nessuno»), «Parti» disabled; «Resta» closes the sheet (FOOD-01; D-02, D-10). | | |
| 4 | FOOD-03 | D-03, D-06 | Starving refusal at the departure: open the sheet with enough food, then (orchestrator) remove the food / lower the HP at DB, tap «Parti» → banner «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio»; the sheet stays open, the dashed route stays, the rows refresh to the red phrase with «Parti» disabled; «Resta» closes it (FOOD-03; D-03, D-06). | | |
| 5 | FOOD-02 | D-04 | Quest line: a combat quest and a service quest whose marker is not the character's position, opened from the Board with the swipe available → one line «Viaggio: <cibo> · <vita>» in the costs block; a story sheet, a non-acceptable quest and the map overlay show no «Viaggio» line (FOOD-02; D-04). | | Known before the run: this DB has no open story/worldMission quest and no open service quest with a marker off its city marker (167 cities checked), so the «service quest with a line» and «story sheet shows no line» halves are not reproducible on the device; they are covered by the 15-06/15-07 tests («a sheet without a preview shows no travel line (D-04)», narrative family → no line). On the device: the combat quests (hunt, enemy) with a road marker, a non-acceptable quest and the map overlay; the 5 Chargate service quests at the city marker show no line by design (instant jump, `null` preview, D-01). |
| 6 | FOOD-02, FOOD-03 | D-04, D-05, D-06 | Quest starving: with no food (or low HP) the «Viaggio» line is red «Viaggio: Non hai cibo a sufficienza per il viaggio» and the paper resists the swipe; then with food at the sheet opening, remove it at DB and tear the sheet → banner «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio», the sheet recomposes and its line turns red (FOOD-02, FOOD-03; D-04, D-05, D-06). | | |
| 7 | FOOD-04 | BE D-13 | Teleport unaffected: the innkeeper teleports the test character (Locanda → queue → Map) → Journal «Oggetti» and «Punti vita» unchanged (FOOD-04, ROADMAP criterion 4; BE D-13). | | |
| 8 | — (extra, review fix WR-01, no requirement) | D-04 | Open a hunt sheet while the standard lane is busy, free the lane → the «Viaggio» line appears without reopening the sheet; once shown, the line stays until the sheet closes even if the quest stops being acceptable. | | |

Requirement ↔ step map: FOOD-01 (1, 2, 3), FOOD-02 (5, 6), FOOD-03 (4, 6), FOOD-04 (1, 2, 7). The instant jump (no road) and a `null` acceptance preview have no device path the user can force reliably: covered by the 15-02/15-07 tests («returns null when the acceptance involves no travel (D-01)», «a sheet without a preview shows no travel line (D-04)»). Step 8 is extra (review fix WR-01) and never blocks a requirement.
