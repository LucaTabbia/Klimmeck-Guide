---
status: in-progress
phase: 07-travel
device: Android (USB, adb reverse tcp:3000)
be_ref: 3df1b37
fe_ref: feat/07-travel @ 4d7e57e (gate passed)
created: 2026-10-24
---

# Phase 7 — Device E2E (human UAT)

Backend: local BE from `origin/develop` (3df1b37 or newer) on `/api/graphql`, UAT data of BE `08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §11 a–c prepared by the user. GraphQL calls by hand (steps 8, 9) run in the user's own client; no token or real-user id is recorded here.

Results are filled in only from the user's verdict (pass / fail / skipped + note). Step 12 is an observation, not a pass/fail gate.

| # | Step | Expected | Result | Note |
|---|------|----------|--------|------|
| 1 | Preview + C1 probe (BE §11 d.1, D-03/D-04, C1) | Drag the pawn from a city marker onto another city: the parchment sheet shows the city name (and image if the lore has one) at once, then distance (km), duration ("2 h 40 min" style) and arrival ("oggi/domani alle HH:mm"); no cost line. Behind the sheet the DASHED route STARTS EXACTLY ON THE PAWN and ends on the destination marker (if it starts elsewhere or looks mirrored → FAIL), the camera fits both ends. "Resta": route gone, pawn back on its city. | pending | |
| 2 | Same city (D-02) | Drag and release the pawn on its own city → it springs back, no sheet, no banner. | pending | |
| 3 | Start (D-05, D-06, D-08, D-12) | Drag again, tap "Parti". The notification permission prompt appears only now (only if the OS has not decided yet). The pawn leaves along the route; the travelled part has a different tone; above the pawn floats only the remaining time. Satchel: Bacheca and Negozio dark and inert; Profilo, Diario, Libreria, Impostazioni open; tapping a city still opens its lore sheet; tapping the pawn does nothing. | pending | |
| 4 | Server time (BE §11 d.2, D-07) | Move the phone clock ±2 h, return to the app → pawn at the same point of the route, remaining time unchanged (within a minute). | pending | |
| 5 | Kill mid-travel (BE §11 d.3, D-09, D-11, TRAVEL-04) | Swipe the app away, relaunch → after the cold start the pawn is on the route at the right point, the camera frames it once, the label shows the remaining time; free panning does not snap back. | pending | |
| 6 | Arrival (BE §11 d.4, D-10, D-15, D-16) | At the end the label reads "In arrivo…" and the pawn waits on the last point. App in background/killed: push "Viaggio completato"; tap → Map centred on the pawn, no popup. Short travel in foreground: pawn snaps to the new city and the in-app banner "Viaggio completato" appears (tap → Map). | pending | |
| 7 | Automatic quest travel (BE §11 d.5, D-13, D-17) | Accept a standard-lane quest whose marker is not the current position → Map with route, moving pawn and label like a free travel; quest paper says "In viaggio". At arrival the pawn snaps, the paper label switches to the per-type label, NO push and no FE banner. | pending | |
| 8 | Rejections (BE §11 d.6, D-14) | Sheet open on a destination; by hand start a travel or accept a standard quest for the same character; tap "Parti" → sheet closes, pawn springs back, banner "Sei già in viaggio" (TRAVEL_IN_PROGRESS) or "Non puoi partire durante una missione in corso" (QUEST_IN_PROGRESS), never technical text. Pawn not draggable during a travel nor while a standard quest is pending. | pending | |
| 9 | Teleport by hand (BE §11 d.7) | As innkeeper `teleportCharacter` on a character in a free travel → route disappears, pawn snaps to the new POI, no push; on a character with a `pendingQuest` the answer is `QUEST_IN_PROGRESS`. | pending | |
| 10 | Pet (BE §11 d.8) | With the `speedModifier: 2` pet equipped (`assets.pet` ObjectId) the preview duration for the same pair of cities is half of the one without the pet. | pending | |
| 11 | Board/Shop off a city (D-12) | With the character on a quest POI (after step 7), Bacheca and Negozio are dark and do nothing. | pending | |
| 12 | Nearest-city rule (Pitfall 10, observation) | At low zoom release the pawn between cities where a village is hidden; note which city the sheet names (D-01 keeps "nearest city"; "Resta" is the escape). | pending (observation) | |
