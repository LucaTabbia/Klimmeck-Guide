---
status: complete
phase: 21-innkeeper-mission-completion-flow
device: Android (USB, adb reverse tcp:3000 → 3001)
be_ref: "feat/mission-start-push (BE PR #41, not merged yet; local tip 6dbfd9df = develop 4aed73bb + mission-start push + POI city fix + lane quest type)"
date: 2026-11-14
completed: 2026-11-14
verdict: approved — mandatory steps 1–10 passed, optional step 11 passed, optional step 12 not run (user's choice)
---

# Phase 21 — Device E2E (innkeeper mission completion flow)

App on the Android phone against the local BE. BE `origin/develop` is `4aed73bb` (merge of BE PR #40, a fix that deletes the story / worldMission requests of archived characters, no SDL change; on top of the BE Phase 22 merge `f82ab278`, PR #39). Gate re-checked before this file was written, block-anchored on `origin/develop:src/schema.gql`: `CharacterStatus.guidedMissionInProgress: Boolean!`, `PendingRequest.missionDraftStartedAt: DateTime`, `Mutation.completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` → `GATE_OK`. Gates of 21-16 / 21-17 on `f82ab278`: 54 × OK, full suite 4678 green, analyzer 47 info / 0 warning / 0 error. Results are recorded only from the tester's words (quoted verbatim, in Italian); the DB readings are the orchestrator's. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names and character names only).

**BE actually under test (recorded honestly):** the UAT did NOT run on `origin/develop`. It ran on BE branch `feat/mission-start-push` (BE PR #41, not merged at the time of recording), which is `develop` `4aed73bb` plus three changes born during this UAT: the `missionStart` push to the participants, the city served on each place of `pointOfInterests` (BE defect found at step 2), and the quest type served on the lanes of a character (`pendingQuest.quest.infos.type`, for the activity label of step 10). Booted by the orchestrator on port 3001 (`adb reverse tcp:3000 tcp:3001`); a second instance on 3002 with the second account's dev bearer (never printed) served the probes of step 1. The gate above was read on `origin/develop` before the UAT and was not re-run on the PR #41 branch; the FE now needs PR #41 (merge order in `BACKEND-NOTES.md` §4).

## Setup

Setup: BE `develop` with Phase 22 merged, booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/21-innkeeper-mission-completion` (never against a BE without Phase 22). The innkeeper's own character and a second account's character are both on the seeded worldMission; the innkeeper's character also holds the seeded story. The second character's refusals are proved by the orchestrator's GraphQL probes with that account's bearer (never printed). Every seed and every time shortening is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board is opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

Seeded by the orchestrator before this file was written (names only). **Adaptation of the plan:** the two test characters are a rookie (the second account) and a legend (the innkeeper's own character), so the worldMission seats and rank blocks are `rookie` and `legend` instead of the plan's mage and paladin.

| Prerequisite | Done |
|--------------|------|
| BE Phase 22 merged on BE `develop` and booted from it (`4aed73bb`) | done — booted from `feat/mission-start-push` (BE PR #41 on top of `4aed73bb`) on port 3001 |
| worldMission «UAT 21 — La cripta di Valantar» with one `rookie` seat and one `legend` seat and two rank blocks: `rookie` (pet, cure, no spell) and `legend` (spell, no pet, no cure); accepted by the legend (innkeeper's own character) and by the rookie (second account, through the real mutation via the orchestrator's probe) | done — both characters on the worldMission (step 0) |
| Story «UAT 21 — Il giuramento della leggenda» (`requirements.minTitle` legend) for the innkeeper's character | done — the legend also on the story (step 0) |
| Legendary enemies whose `locations` match the inner POI chosen for step 2 (already live on the graveyard place near Valantar) | done — legendary listed on the graveyard at step 4 |
| A normal hunt for step 10 | done — «UAT 21 — Caccia al cimitero di Valantar» (3 min wait) |
| Shortened quest times | done — travel of step 10 shortened at DB, 3 min wait |
| The second account's bearer, used by the probes of step 1 (held by the orchestrator, never printed) | done — second BE instance on 3002 with the second account's dev bearer (never printed) |

## Session data

Field names only, from the BE Phase 22 handoff as copied in `21-16-SUMMARY.md`; no ids, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE.

- worldMission in `quests`: `infos { title, type: 'worldMission', markerLocation, enemies, timeToComplete, relatedLore, description }`, `requirements { minTitle, requiredAdventurers [{ title, count }], requiredPoints, recommendedLoot }`, `prizes { prizeCoins { gold, silver, copper }, xpPrize, prizeItem { itemType, item, quantity }, randomLoot, spell, pet, cure }`, `rankPrizes` [{ title, prizeCoins, xpPrize, prizeItem, randomLoot, spell, pet, cure { lifePointsShare, canHeal } }], `registeredAdventurers`, `concludedAt`, `startedAt`, `generated`.
- Story: `infos.type: 'story'`, `requirements.minTitle` = the exact title of the test character, single `prizes`.
- Legendary enemy: `legendary: true` with concrete `locations` matching the inner POI types (or `city`).
- Diagnosis: collection `missiondrafts`; `missionDraftStartedAt` on the PendingQuests; `QuestResult` (`gmCompleted`, merged `enemies`).
- Character flags (served, never seeded): `status.missionInProgress`, `status.guidedMissionInProgress`.
- Players' refusal code: `MISSION_IN_PROGRESS` (`extensions.code` only).

## Copy to review

Proposed strings the user may amend at the UAT (amendments become gaps, no code change in this plan):

- The 29 POI labels (`PoiType.label`, used as «<tipo> presso <città>»): battleground «Campo di battaglia», all «Ovunque», vulcano «Vulcano», ruins «Rovine», dungeon «Sotterraneo», city «Città», graveyard «Cimitero», swamp «Palude», oasis «Oasi», harkenIsland «Isola di Harken», hills «Colline», minnelyForest «Foresta di Minnely», farNorth «Estremo Nord», drusteaPlains «Pianure di Drustea», undergroundLamstone «Sottosuolo di Lamstone», mountainLamstone «Monte Lamstone», glounet «Glounet», desert «Deserto», liberiaIsland «Isola di Liberia», valanPlains «Pianure di Valan», belleholmLake «Lago di Belleholm», belleholmIsland «Isola di Belleholm», temistosLake «Lago di Temistos», undergroundTemistos «Sottosuolo di Temistos», ladows «Ladows», delants «Delants», mountainTemistos «Monte Temistos», forest «Foresta», demonicPortal «Portale demoniaco» (21-06).
- «Equipaggiamento non cambiato» (title of the equipment refusal banner, 21-03).
- «Leggendario» (trailing text of a legendary enemy row) and «PE n · PV n» (enemy row subtitle, «–» when not served) (21-14).
- «Rimuovi» (tooltip of the prize remove buttons) and «Compagni» (catalogue tab) (21-15).
- «Aggiungi cura» (prizes step, review fix B-03) and «Operazione rifiutata: controlla scontri, correzioni e premi» (wizard refusal for `OUTCOME_OVERRIDE_INVALID`, review fix B-09).

## Product notes to review

No code change; recorded so the user can rule on them at the UAT:

- Two POIs of the same type near the same city get the same label («<tipo> presso <città>»).
- POI dots are purple, untappable, visible from `MapConstants.cityVisibleZoom`; drop radius 32 px; below the city zoom a drop near a hidden place resolves to the city as in Phase 10 (review fix A-01). A place with no known type is not a destination (A-02).
- «Resta qui» is enabled only when the whole group shares one place.
- The shop refusal is a banner (the satchel shop page is closed while on mission).
- The D-14 injury lock is per fight: injuries the character had before the fight (including those added by an earlier fight) are selected and not removable; to remove one, go back and correct the earlier fight, which voids the later ones (D-24).
- The wizard caps (10 fights, 10 enemy entries per fight, quantity 1..20, prize item 1..99, coins / xp at most 7 digits) come from the BE.
- The bookmark ribbon of the equipment info sheet looks active but is inert under the lock, as the spell sheet today (review A-03, not fixed by ruling).
- A teleport read started from the panel card that fails while a dialog is open over the panel shows no notice (corner case, 21-16).

## Steps

| Step | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|-----------|----------|--------|--------|------|
| 1 | GMFLOW-02, GMFLOW-07 | D-11, D-13, D-16, D-23, D-28, D-30 | Start and lock. Locanda → «Completa» on the worldMission → «Inizia la missione» (start note shown) → the draft exists. Leave the Locanda: the own pawn reads «Missione in corso» and cannot be dragged; the Journal armour, companion, spells and heal potions show «Missione in corso» and do nothing; the shop page is closed; the Board shows «Missione in corso: aspetta l'esito» on every quest (a story too). The orchestrator's probes with the second character: `travelPreview`, `startTravel`, `acceptQuest`, `doTransaction`, `equipItem`, `useItem` → `MISSION_IN_PROGRESS`. | pass | user | DB: draft for 2 participants. Probes of the second character: travelPreview, startTravel, acceptQuest, doTransaction, equipItem, useItem → all `MISSION_IN_PROGRESS`. First attempt ran on a stale build (old Phase 10 form): the orchestrator reinstalled the app from the branch. The `missionStart` push (category «Inizio missione») confirmed by the user here. |
| 2 | GMFLOW-01 | D-01, D-17, D-28, D-29 | Teleport on an inner POI and return. Reopen the Locanda: the card reads «Riprendi» → the wizard resumes at «Luogo» with «<tipo> presso <città>» per participant → «Teletrasporta il gruppo» → the Map in Locanda mode shows the inner places as dots and the chip «Trascina Gruppo · 2 su una città o un luogo» → drop the pawn next to an inner POI → the Locanda reopens and the wizard of the same request is back at «Luogo» with the new place for both participants; on the players' Map both pawns stand on the POI. | pass | user | Finding (BE defect): `pointOfInterests { city { id name } }` failed (city not populated) → no «tipo presso città» and no place dots → fixed in BE PR #41. Findings fixed in the FE: inn-mode badge/instruction font 30 → 16; instruction names the group («Trascina Gruppo · 2 …»); a tap on a place dot shows all its types and the city on a second line; after «Annulla» on the Map the wizard reopens on «Luogo» (after a successful teleport it reopens on the served step, accepted by the user); the Inn queue no longer flashes between the Map and the wizard (curtain). User decision: the demonic portal near Flushhelm stays linked to Tinemoor («Lascia stare il portale demoniaco»). |
| 3 | GMFLOW-01 | D-01 | Stay. On «Luogo» with the group together, «Resta qui» opens «Scontri». | pass | user | «Resta qui» opens «Scontri». |
| 4 | GMFLOW-03 | D-02, D-03, D-19 | Encounters. The list is the BE's default for the place and the rank (the seeded legendary appears for the worldMission); «Cerca» filters by name; «Mostra tutti» shows the whole bestiary; build two fights with quantities; the quantity stepper stops at 20, «Aggiungi scontro» stops at 10 fights, a fight takes at most 10 enemy entries (BE caps) → «Avanti». | pass | user | Legendary listed on the graveyard; two fights saved at DB. Findings fixed: compact wizard buttons (30 → 16), enemy search beside the step counter, all buttons on one row at the bottom, keyboard overflow on «Scontri». |
| 5 | GMFLOW-04 | D-04, D-05, D-06, D-14, D-21, D-24 | Simulation and corrections. «Scontro 1 di 2»: «Simula» (loader) → «Vittoria»/«Sconfitta» on the fight and «PV a → b» per character; «Rilancia» gives a new served outcome; correct: slider, remove an injury the fight added, the injuries the character already had are selected and locked — and on fight 2 so are the injuries fight 1 added (the lock is per fight, D-14: to remove one, go back and correct fight 1, which voids fight 2, D-24) —, add an injury, consumables and spells steppers stop at the served availability → «Avanti» → «Scontro 2 di 2» «Simula»: the orchestrator confirms at DB that fight 2 starts from fight 1's corrected state; «Cambia nemici» on fight 1, change an enemy → «Avanti»: fights 1 and 2 read «Da simulare». | pass | user | DB: fight 2 starts from fight 1's corrected state. «Rilancia» returns the same numbers: accepted by the user (placeholder engine; the real engine comes later); the draft `rev` grows at every rerun. Findings fixed: verdict on top and centred; each character folded under «Nome · PV a → b». |
| 6 | GMFLOW-02 | D-09, D-18 | Resume. Close the app, reopen, Settings → Locanda → «Riprendi»: the wizard opens at the served step with the served fights. | pass | user | After closing the app the wizard reopens on the served step. |
| 7 | GMFLOW-05 | D-07, D-15, D-22 | Prizes. «Premi»: each character starts from the whole block of their rank (rookie and legend differ: the rookie's block has pet and cure, the legend's has the spell); set coins and xp above the block; remove one entry; add a pet from the catalogue and, for the legend, a spell (the rookie's spells tab holds only what the BE serves for its rank) → «Avanti». *(Adapted: the plan said mage and paladin.)* | pass | user | Blocks differ per rank; the rookie's spell tab is empty (correct for the user). Findings fixed: prizes folded per character; with the keyboard open the step counter and the button row hide so the field stays visible; no overflow. |
| 8 | GMFLOW-06, GMFLOW-07 | D-08, D-23, D-25 | Completion. «Riepilogo» lists fights, PV, injuries and prizes → «Completa» → «Completa la missione» confirmation → the results recap of the Locanda; both players get the result sheet with the enemies faced; without touching the phone the pawn label disappears and the Journal, shop and Board unlock. | pass | user | DB: two `gmCompleted` results with the 3 enemies of the two fights, draft and requests gone, mission concluded, cure applied. Finding fixed: a «Richiesta non più disponibile» snackbar instead of the results recap (the queue update arrived before the completion answer) → a call in flight now decides the exit. |
| 9 | GMFLOW-02, GMFLOW-07 | D-11 | Discard. On the story: «Completa» → «Inizia la missione» → lock visible → «Scarta la bozza» → «Scartare la bozza?» → confirm: the lock is released live and the character stays where the teleport left it. | pass | user | DB: marker cleared, request back in the queue. |
| 10 | GMFLOW-07 | D-12, D-13, D-16 | Normal mission lock (D-12). The innkeeper's character accepts the seeded hunt and arrives (time shortened): during the waiting time the Journal shows «Missione in corso» and refuses, the Board shows the line, the pawn has NO «Missione in corso» label; at the result everything unlocks. | pass | user | Hunt accepted, travel shortened at DB, 3 min wait. User request implemented: the pawn names the activity («Cacciando…» etc.), 5 px over the pawn at every zoom; needs the quest type on the lanes (BE PR #41). |
| 11 | — (optional) | D-24 | (optional) Narrative story with zero fights: «Scontri» → «Avanti» with no fight → «Premi» → «Completa». | pass | user | — |
| 12 | — (optional) | D-09, D-18 | (optional) Second device: the innkeeper opens the same draft from another device and sees the same served step. | not run | user | User: «passo 12 credo sia futile, dovremmo aver testato che alla login su un altro dispositivo, la sessione aperta su quello precedente si chiude». |

Requirement ↔ step map: GMFLOW-01 (2, 3), GMFLOW-02 (1, 6, 9), GMFLOW-03 (4), GMFLOW-04 (5), GMFLOW-05 (7), GMFLOW-06 (8), GMFLOW-07 (1, 8, 9, 10), GMFLOW-08 (the gates of 21-16 and 21-17 — schema gate, 54 × OK, full suite — and steps 1–10 all passed); steps 11–12 optional. Not on the device, covered by tests: every classifier row (21-01..21-05), lenient parsing (21-10), invalidation edge cases (21-12, 21-14), the drop radius (21-08).

Device notes (user memory, run by the user or the orchestrator, never by the executor): `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`.

## Findings and new rules born during the UAT

Source: the user on the Samsung phone; DB readings by the orchestrator. Every FE fix below landed on the branch during the UAT, RED-first, by the orchestrator (commits listed in `21-18-SUMMARY.md` «UAT fixes»).

- **Step 0 (prep):** accepting a story / worldMission left the torn sheet open on the Board → fixed: the sheet closes with the notice «Missione accettata» / «L'oste è stato avvisato: la missione comincerà quando la avvia»; the other quest types now go to the Map when the torn sheet has left the screen, with «In preparazione…» over the pawn.
- **Step 1:** a first attempt ran on a stale build (old Phase 10 form); the app was reinstalled from the branch.
- **Step 2 (BE defect):** `pointOfInterests { city { id name } }` failed (city not populated) → no «tipo presso città» and no place dots → fixed in BE PR #41. FE fixes: inn-mode badge / instruction font 30 → 16; the instruction names the group («Trascina Gruppo · 2 …»); a tap on a place dot shows all its types and the city on a second line (this supersedes the «untappable» product note above); after «Annulla» on the Map the wizard reopens on «Luogo» (after a successful teleport it reopens on the served step, accepted by the user); the Inn queue no longer flashes between the Map and the wizard (curtain). User decision: the demonic portal near Flushhelm stays linked to Tinemoor («Lascia stare il portale demoniaco»).
- **Step 4:** compact wizard buttons (30 → 16), enemy search beside the step counter, all buttons on one row at the bottom, keyboard overflow on «Scontri» fixed.
- **Step 5:** «Rilancia» returns the same numbers — accepted by the user (placeholder engine; the real engine comes later); the draft `rev` grows at every rerun. Verdict on top and centred; each character folded under «Nome · PV a → b».
- **Step 7:** prizes folded per character; with the keyboard open the step counter and the button row hide so the field stays visible; no overflow.
- **Step 8:** a «Richiesta non più disponibile» snackbar appeared instead of the results recap (the queue update arrived before the completion answer) → a call in flight now decides the exit of the wizard.
- **Step 10 (user request):** the pawn names the activity of a running mission («Cacciando…» etc.), 5 px over the pawn at every zoom; needs the quest type on the lanes (BE PR #41).
- **Other user requests implemented on the branch:** push `missionStart` to the participants when the innkeeper starts the mission (BE PR #41; FE category «Inizio missione», tap = pawn on the Map; confirmed at step 1); «Teletrasporta» removed from the request card of the Inn (the teleport lives only in the wizard); an arrow (asset `arrowDown`) points at the own pawn when it is off the screen, ~50 px from the edge (added last, **not yet confirmed by the user on the device**).
- **Outside this phase:** new FE Phase 22 / BE Phase 23 «Companion defeat, rest and recovery» added to the roadmaps; BE PR #40 (merged) deletes the story / worldMission requests of an archived character.
- **Copy written by the orchestrator, still open to the user's review** (gaps for review, no code change here): «Missione accettata» / «L'oste è stato avvisato: la missione comincerà quando la avvia»; push «La missione comincia» / «L'oste ha dato inizio a «titolo»»; preference «Inizio missione»; «In preparazione…»; activity labels (Cacciando…, Esplorando…, Combattendo…, Soccorrendo…, Studiando…, In cura…, Lavorando…, Tramando…, Di guardia…). The proposed strings of «Copy to review» above were not amended by the user.
- **Merge order:** BE PR #41 must be merged BEFORE the FE PR (the FE selects `pendingQuest.quest.infos.type` and reads `pointOfInterests.city`).

## Verdict

**Approved (2026-11-14).** Mandatory steps 1–10 all `pass`; optional step 11 `pass`; optional step 12 `not run` by the user's choice. Requirements GMFLOW-01..08 complete (map above). At the end the full FE suite read `+4722: All tests passed!` and `flutter analyze` 47 info / 0 warning / 0 error (orchestrator's run). Open: the off-screen pawn arrow awaits the user's look on the device; the orchestrator's copy listed above awaits review.

## Final confirmation (2026-11-14, after the record)

The user closed the phase with «Confermo tutto, chiudi la fase». This confirms what the record above left open:
- the copy written by the orchestrator during the UAT (acceptance notice, `missionStart` push, «Inizio missione», «In preparazione…», the activity labels over the pawn);
- the arrow towards the own pawn when it is off the screen, enlarged to 60 px on the user's request and drawn with the asset `arrowMap` (thicker border) the user provided; `arrowDown` stays for the dropdowns.

Nothing is left to review for this phase. Merge order unchanged: BE PR #41 first, then the FE PR #51.
