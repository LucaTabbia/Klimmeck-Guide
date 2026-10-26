---
status: complete
phase: 07-travel
device: Android (Samsung SM-S938B, USB, adb reverse tcp:3000)
be_ref: feat/09-combat-result-admin-outcomes @ c4582b9 (local BE; contains origin/develop 3df1b37 + BE Phase 9, PR #13)
fe_ref: feat/07-travel @ 596e6c7
created: 2026-10-24
completed: 2026-10-26
---

# Phase 7 — Device E2E (human UAT)

Backend: local BE from the branch `feat/09-combat-result-admin-outcomes` @ c4582b9 (it contains `origin/develop` 3df1b37 plus the BE Phase 9, PR #13), not `origin/develop`, on `/api/graphql`; UAT data of BE `08-travel-lifecycle-travel-01/BACKEND-NOTES.md` §11 a–c prepared in the development DB (see «Note di esecuzione»). GraphQL calls by hand (steps 8, 9) ran outside the transcript; no token or real-user id is recorded here.

Results come only from the user's verdict (pass / fail / skipped + note); quotes are verbatim. Step 12 is an observation, not a pass/fail gate.

**Outcome:** steps 1–11 pass, step 12 observed. Status `complete`.

| # | Step | Expected | Result | Note |
|---|------|----------|--------|------|
| 1 | Preview + C1 probe (BE §11 d.1, D-03/D-04, C1) | Drag the pawn from a city marker onto another city: the parchment sheet shows the city name (and image if the lore has one) at once, then distance (km), duration ("2 h 40 min" style) and arrival ("oggi/domani alle HH:mm"); no cost line. Behind the sheet the DASHED route STARTS EXACTLY ON THE PAWN and ends on the destination marker (if it starts elsewhere or looks mirrored → FAIL), the camera fits both ends. "Resta": route gone, pawn back on its city. | pass | First try: «Ho premuto parti, ma tutto il resto ha funzionato» (pressed "Parti" instead of "Resta"). "Resta" and the lore image on the sheet verified afterwards in Mirwen: «2 e 1 sono pass». C1 (route starting on the pawn): no anomaly reported («tutto il resto ha funzionato»). |
| 2 | Same city (D-02) | Drag and release the pawn on its own city → it springs back, no sheet, no banner. | pass | «2 e 1 sono pass» |
| 3 | Start (D-05, D-06, D-08, D-12) | Drag again, tap "Parti". The notification permission prompt appears only now (only if the OS has not decided yet). The pawn leaves along the route; the travelled part has a different tone; above the pawn floats only the remaining time. Satchel: Bacheca and Negozio dark and inert; Profilo, Diario, Libreria, Impostazioni open; tapping a city still opens its lore sheet; tapping the pawn does nothing. | pass | «Posso confermare che funziona il tap sulle città con la lore, il tratteggio diventa linea unica, funzionato il cambio ora e il kill dell'app Sono tutti pass». At first glance (9 h travel, 1% done): «Non riesco inoltre a verificare che la linea cambi (dovrei aver percorso più strada) ma la pedina si sposta. Cambierei il colore del tratteggio al colore oro principale»; with the travel moved to half way in the DB the travelled part rendered as a solid line. Gold dash colour → follow-up quick task. |
| 4 | Server time (BE §11 d.2, D-07) | Move the phone clock ±2 h, return to the app → pawn at the same point of the route, remaining time unchanged (within a minute). | pass | «funzionato il cambio ora» |
| 5 | Kill mid-travel (BE §11 d.3, D-09, D-11, TRAVEL-04) | Swipe the app away, relaunch → after the cold start the pawn is on the route at the right point, the camera frames it once, the label shows the remaining time; free panning does not snap back. | pass | «kill dell'app» (… «Sono tutti pass») |
| 6 | Arrival (BE §11 d.4, D-10, D-15, D-16) | At the end the label reads "In arrivo…" and the pawn waits on the last point. App in background/killed: push "Viaggio completato"; tap → Map centred on the pawn, no popup. Short travel in foreground: pawn snaps to the new city and the in-app banner "Viaggio completato" appears (tap → Map). | pass | 6a (background, push "Viaggio completato", tap → Map): «pass». 6b (foreground): «pass» on the second, coherent attempt (pawn almost at the end and moving, "In arrivo…", snap and banner); the first attempt is not valid (orchestrator error, see «Note di esecuzione»). |
| 7 | Automatic quest travel (BE §11 d.5, D-13, D-17) | Accept a standard-lane quest whose marker is not the current position → Map with route, moving pawn and label like a free travel; quest paper says "In viaggio". At arrival the pawn snaps, the paper label switches to the per-type label, NO push and no FE banner. | pass | «passpass su 8, 11 e 7» |
| 8 | Rejections (BE §11 d.6, D-14) | Sheet open on a destination; by hand start a travel or accept a standard quest for the same character; tap "Parti" → sheet closes, pawn springs back, banner "Sei già in viaggio" (TRAVEL_IN_PROGRESS) or "Non puoi partire durante una missione in corso" (QUEST_IN_PROGRESS), never technical text. Pawn not draggable during a travel nor while a standard quest is pending. | pass | Pawn not draggable with a quest in progress: «passpass su 8, 11 e 7». Sub-cases by hand (orchestrator, BE dev bypass bound to the user's identity): sheet open + `acceptQuest` of the hunt → "Parti" → banner "Non puoi partire durante una missione in corso": «pass»; sheet open + `startTravel` to Bellport → "Parti" → "Sei già in viaggio": «pass». |
| 9 | Teleport by hand (BE §11 d.7) | As innkeeper `teleportCharacter` on a character in a free travel → route disappears, pawn snaps to the new POI, no push; on a character with a `pendingQuest` the answer is `QUEST_IN_PROGRESS`. | pass | 9B: teleport (by hand) with a quest in progress → `QUEST_IN_PROGRESS` ("Non puoi muoverti durante una missione in corso"). 9A: teleport during the free travel to Bellport → travel cancelled on the BE; on the device: «pass 9A». |
| 10 | Pet (BE §11 d.8) | With the `speedModifier: 2` pet equipped (`assets.pet` ObjectId) the preview duration for the same pair of cities is half of the one without the pet. | pass | «pass» after the second preview without the horse. Expected 9 h 4 min with the pet (`speedModifier: 2`), doubled without; the user did not report the numbers read. |
| 11 | Board/Shop off a city (D-12) | With the character on a quest POI (after step 7), Bacheca and Negozio are dark and do nothing. | pass | «passpass su 8, 11 e 7» |
| 12 | Nearest-city rule (Pitfall 10, observation) | At low zoom release the pawn between cities where a village is hidden; note which city the sheet names (D-01 keeps "nearest city"; "Resta" is the escape). | observed | «12: Ulby» (the city named by the sheet at low zoom). |

## Note di esecuzione

- **Backend usato:** BE locale dal branch `feat/09-combat-result-admin-outcomes` @ c4582b9 (contiene `origin/develop` 3df1b37 più la BE Phase 9, PR #13), non `origin/develop`. Il contratto travel consumato è quello di `origin/develop` (schema check 32/32 nel Task 1).
- **Dati preparati dall'orchestratore nel DB di sviluppo** (nessun id di utenti reali né segreti):
  - pet "Cavallo da viaggio" con `speedModifier: 2` inserito ed equipaggiato (`assets.pet` come ObjectId);
  - registrazioni fantasma di personaggi non attivi rimosse da `enemy` e `boss`;
  - 12 lore delle capitali collegate alle città omonime (`relatedLore`), per l'immagine sul foglio;
  - viaggi accorciati nel DB con `startTime`/`endTime` coerenti (durata intatta) per arrivare a metà strada o quasi in fondo (passi 3 e 6);
  - hunt chiusa retrodatando `startDate` (sweep del BE).
- **Chiamate a mano (passi 8, 9):** eseguite dall'orchestratore con il bypass di sviluppo del BE legato all'identità dell'utente; nessun token registrato.
- **Passo 6b, primo tentativo non valido:** l'orchestratore aveva accorciato solo `endTime` nel DB. L'app calcola la posizione da `startTime` + `duration` e il tempo residuo da `endTime`; l'utente ha visto: «Ho visto 1 min. poi 0 min. Poi banner con scritto viaggio completato. La pedina era ferma al punto di partenza, all'arrivo del banner la pedina si è teletrasportata». Rifatto con accorciamento coerente (`startTime` e `endTime`, durata intatta): «pass». Osservazione: in gioco `endTime` è sempre `startTime + duration`, quindi nessun difetto del FE.
- **Follow-up:** colore del tratteggio della rotta all'oro principale (richiesta dell'utente al passo 3) → quick task successivo, fuori da questo piano.
