# Phase 15 (FE) — Backend notes

Frontend companion of the BE Phase 14 (travel and food). Branch `feat/15-travel-food`; contract proved on BE `origin/develop` `b492a46` (merge of BE PR #23). English text, user quotes verbatim in Italian. No ids of real users, no tokens, no URIs in this file.

## 1. Contract consumed by the FE

```graphql
# TravelPreviewFragment (lib/graphql/fragments/travel_preview_fragment.dart)
distance
duration
road { coordinates distance }
food { quantity item { id name } }
hpLost
arrivesAlive

query GetTravelPreview($request: TravelRequest!) {
  travelPreview(request: $request) { …TravelPreviewFragment fields }
}

query GetQuestTravelPreview($request: AcceptQuestRequest!) {
  questTravelPreview(request: $request) { …TravelPreviewFragment fields }
}
```

- The fragment is shared by both documents (interpolated, not a GraphQL fragment spread).
- `questTravelPreview` is read as nullable: `null` = the acceptance involves no travel (instant jump, story/worldMission) → no «Viaggio» line. The request is `{ id: <characterId>, questId }`, the viewer's own character only.
- Schema check: 45 documents, 45/45 OK on BE `b492a46` (plan 15-08).
- Never more than `id name` under a food item (populate depth 1).

## 2. Error codes read

The FE reads only `extensions.code`, never the message.

- `TRAVEL_STARVING` on `startTravel` → banner «Viaggio non partito» / «Non hai cibo a sufficienza per il viaggio»; the confirmation sheet stays open (state `TravelRequoting`), the route and the pawn stay, the preview is re-requested and the rows turn red with «Parti» disabled.
- `TRAVEL_STARVING` on `acceptQuest` → banner «Missione non accettata» / «Non hai cibo a sufficienza per il viaggio»; the quest sheet recomposes, the preview of that sheet is refreshed (its line turns red, the swipe resists); no board reread.
- `questTravelPreview` failures (`FORBIDDEN`, `NOT_FOUND`, `QUEST_NOT_IN_CITY`, `QUEST_NOT_ACCEPTABLE`, timeout 15 s, link errors) → no line, the swipe behaves as before, no banner.

## 3. FE behaviour the BE should know

- Food is shown in the BE order, as «Nx nome» joined with commas («Cibo: nessuno» on the confirmation sheet when the list is empty).
- «−N HP» (U+2212) is printed from `hpLost`; `hpLost <= 0` prints «nessuna perdita».
- `arrivesAlive: false` disables «Parti» and the quest swipe and prints the user phrase instead of the number; nothing else is computed on the client (no food need, no selection, no uncovered km, no HP).
- A malformed food entry (missing item, id or name, empty name, quantity not a number or below 1) is dropped; missing `food` / `hpLost` / `arrivesAlive` read as `[]` / `0` / `true` (an older BE never blocks the FE).
- The quest preview is requested only for acceptable standard-lane quests (combat and service families) opened from the Board; when a sheet becomes acceptable while open (lane freed) it is requested once then (review fix WR-01). Read-only sheets and the map overlay never ask.
- The Map shows no HP; the Journal («Oggetti», «Punti vita») is the HP and inventory surface, updated only through `characterUpdated`. No feedback after the departure (no banner, no toast).

## 4. E2E outcome (FE Phase 15, 2026-11-06)

BE `develop` `b492a46` from `dist/` on port 3001, Android phone over USB (`adb reverse tcp:3000 tcp:3001`), debug APK of FE `e1b1d1f`. Test character: the user's legend (HP 38 700 / 40 000, no pet, two injuries), start city Chargate. Food and HP seeded by the orchestrator at DB with the BE's own write shapes (`assets.ownedItems`, `status.currentLifePoints`); finished travels closed by shifting `startTime` and `endTime` together; the standard lane freed by shifting `pendingquests.startDate/arrivedAt`. Steps 1–8 pass (`15-HUMAN-UAT.md`).

- **Food consumption, covered trip:** Chargate → Voxhold (20.95 km / 4.19 h / 84 power) with 2x Manzo Essiccato (50): preview «Cibo: 2x Manzo Essiccato», «Vita: nessuna perdita»; after the departure both Manzo gone, HP 38 700 unchanged, travel active. User: «pass».
- **HP loss, partial trip:** Voxhold → Chargate (84 power) with 1x Cosciotto di pollo (50): preview «Vita: −45 HP»; after the departure the Cosciotto gone and HP 38 700 → 38 655. User: «pass».
- **Refusal at the preview:** no food, HP 38 655, Murnborim (399 km, 68 635 HP without food): `arrivesAlive: false`, «Cibo: nessuno», «Parti» disabled. User: «pass».
- **Starving refusal on `startTravel`:** sheet opened with food, then 1x Razione da viaggio removed and HP set to 100 at DB → `TRAVEL_STARVING`; DB after the refusal: HP 100, no food, no travel (nothing written). User: «foglio aperto», then «pass».
- **Quest line (`questTravelPreview`):** «Caccia: Vespa gigante» (7.18 km / 29 power) with 1x Razione → «Viaggio: 1x Razione da viaggio · nessuna perdita»; a service quest at the city marker (instant jump) → `null`, no line. User: «pass».
- **Starving refusal on `acceptQuest`:** no food and HP 20 → red line, swipe resisted (User: «resiste»); then food at the sheet opening removed at DB and the sheet torn → `TRAVEL_STARVING`; DB after: hunt quest with no registered adventurer, no travel, channel points 5000 unchanged. User: «pass».
- **Teleport:** run through the BE mutation `teleportCharacter` with the development innkeeper identity (Chargate → Voxhold) because the Locanda path needs a story quest in the queue (see §5): 1x Razione da viaggio and HP 38 655 unchanged. User: «pass».
- **Lane freed with the sheet open (WR-01):** the «Viaggio» line appeared without reopening the sheet after the resolution sweep concluded the busy-lane quest. User: «pass».

After the UAT the orchestrator restored the character (Chargate, 38 700 HP, 2x Manzo Essiccato).

## 5. Questions for the BE

1. Is `food[].item.name` always populated? A nameless entry is dropped by the FE and the «Cibo» row under-reports (research A5).
2. Is `questTravelPreview` always present in `data` (possibly `null`), also when the call fails with a coded error?
3. Does a story/worldMission acceptance ever travel? The FE never asks the preview for them.
4. Any code besides `TRAVEL_STARVING` new in Phase 14? (15-08 found none in the handoff.)
5. A legend alone cannot accept «Minaccia: 2 Gnoll presso Chargate» because its only slot is `adventurer` (user: «Non è accettabile ( sono di rango troppo alto) e l'unico slot presente è da avventuriero»): is this intended by the generation of the BE Phase 13?
6. The Locanda teleport is reachable only with a story quest in the queue, and the development DB has no open story/worldMission quest, so the FE teleport path could not be exercised on the device (the BE mutation was). A content/product question, not a Phase 15 gap.

Da riportare nella UAT della BE Phase 14 a cura del lato BE (questo repo non modifica il BE).
