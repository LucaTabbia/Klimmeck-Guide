---
status: in-progress
phase: 21-innkeeper-mission-completion-flow
device: Android (USB, adb reverse tcp:3000)
be_ref: 4aed73bb
date: 2026-11-14
verdict:
---

# Phase 21 — Device E2E (innkeeper mission completion flow)

App on the Android phone against the local BE. BE `origin/develop` is `4aed73bb` (merge of BE PR #40, a fix that deletes the story / worldMission requests of archived characters, no SDL change; on top of the BE Phase 22 merge `f82ab278`, PR #39). Gate re-checked before this file was written, block-anchored on `origin/develop:src/schema.gql`: `CharacterStatus.guidedMissionInProgress: Boolean!`, `PendingRequest.missionDraftStartedAt: DateTime`, `Mutation.completeGuidedMission(pendingQuestId: ID!): [QuestResult!]!` → `GATE_OK`. Gates of 21-16 / 21-17 on `f82ab278`: 54 × OK, full suite 4678 green, analyzer 47 info / 0 warning / 0 error. Results are recorded only from the tester's words (quoted verbatim, in Italian); the DB readings are the orchestrator's. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names and character names only).

## Setup

Setup: BE `develop` with Phase 22 merged, booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/21-innkeeper-mission-completion` (never against a BE without Phase 22). The innkeeper's own character and a second account's character are both on the seeded worldMission; the innkeeper's character also holds the seeded story. The second character's refusals are proved by the orchestrator's GraphQL probes with that account's bearer (never printed). Every seed and every time shortening is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board is opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

Seeded by the orchestrator before this file was written (names only). **Adaptation of the plan:** the two test characters are a rookie (the second account) and a legend (the innkeeper's own character), so the worldMission seats and rank blocks are `rookie` and `legend` instead of the plan's mage and paladin.

| Prerequisite | Done |
|--------------|------|
| BE Phase 22 merged on BE `develop` and booted from it (`4aed73bb`) | |
| worldMission «UAT 21 — La cripta di Valantar» with one `rookie` seat and one `legend` seat and two rank blocks: `rookie` (pet, cure, no spell) and `legend` (spell, no pet, no cure); accepted by the legend (innkeeper's own character) and by the rookie (second account, through the real mutation via the orchestrator's probe) | |
| Story «UAT 21 — Il giuramento della leggenda» (`requirements.minTitle` legend) for the innkeeper's character | |
| Legendary enemies whose `locations` match the inner POI chosen for step 2 (already live on the graveyard place near Valantar) | |
| A normal hunt for step 10 | |
| Shortened quest times | |
| The second account's bearer, used by the probes of step 1 (held by the orchestrator, never printed) | |

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
| 1 | GMFLOW-02, GMFLOW-07 | D-11, D-13, D-16, D-23, D-28, D-30 | Start and lock. Locanda → «Completa» on the worldMission → «Inizia la missione» (start note shown) → the draft exists. Leave the Locanda: the own pawn reads «Missione in corso» and cannot be dragged; the Journal armour, companion, spells and heal potions show «Missione in corso» and do nothing; the shop page is closed; the Board shows «Missione in corso: aspetta l'esito» on every quest (a story too). The orchestrator's probes with the second character: `travelPreview`, `startTravel`, `acceptQuest`, `doTransaction`, `equipItem`, `useItem` → `MISSION_IN_PROGRESS`. | | user | |
| 2 | GMFLOW-01 | D-01, D-17, D-28, D-29 | Teleport on an inner POI and return. Reopen the Locanda: the card reads «Riprendi» → the wizard resumes at «Luogo» with «<tipo> presso <città>» per participant → «Teletrasporta il gruppo» → the Map in Locanda mode shows the inner places as dots and the chip «Trascina Gruppo · 2 su una città o un luogo» → drop the pawn next to an inner POI → the Locanda reopens and the wizard of the same request is back at «Luogo» with the new place for both participants; on the players' Map both pawns stand on the POI. | | user | |
| 3 | GMFLOW-01 | D-01 | Stay. On «Luogo» with the group together, «Resta qui» opens «Scontri». | | user | |
| 4 | GMFLOW-03 | D-02, D-03, D-19 | Encounters. The list is the BE's default for the place and the rank (the seeded legendary appears for the worldMission); «Cerca» filters by name; «Mostra tutti» shows the whole bestiary; build two fights with quantities; the quantity stepper stops at 20, «Aggiungi scontro» stops at 10 fights, a fight takes at most 10 enemy entries (BE caps) → «Avanti». | | user | |
| 5 | GMFLOW-04 | D-04, D-05, D-06, D-14, D-21, D-24 | Simulation and corrections. «Scontro 1 di 2»: «Simula» (loader) → «Vittoria»/«Sconfitta» on the fight and «PV a → b» per character; «Rilancia» gives a new served outcome; correct: slider, remove an injury the fight added, the injuries the character already had are selected and locked — and on fight 2 so are the injuries fight 1 added (the lock is per fight, D-14: to remove one, go back and correct fight 1, which voids fight 2, D-24) —, add an injury, consumables and spells steppers stop at the served availability → «Avanti» → «Scontro 2 di 2» «Simula»: the orchestrator confirms at DB that fight 2 starts from fight 1's corrected state; «Cambia nemici» on fight 1, change an enemy → «Avanti»: fights 1 and 2 read «Da simulare». | | user | |
| 6 | GMFLOW-02 | D-09, D-18 | Resume. Close the app, reopen, Settings → Locanda → «Riprendi»: the wizard opens at the served step with the served fights. | | user | |
| 7 | GMFLOW-05 | D-07, D-15, D-22 | Prizes. «Premi»: each character starts from the whole block of their rank (rookie and legend differ: the rookie's block has pet and cure, the legend's has the spell); set coins and xp above the block; remove one entry; add a pet from the catalogue and, for the legend, a spell (the rookie's spells tab holds only what the BE serves for its rank) → «Avanti». *(Adapted: the plan said mage and paladin.)* | | user | |
| 8 | GMFLOW-06, GMFLOW-07 | D-08, D-23, D-25 | Completion. «Riepilogo» lists fights, PV, injuries and prizes → «Completa» → «Completa la missione» confirmation → the results recap of the Locanda; both players get the result sheet with the enemies faced; without touching the phone the pawn label disappears and the Journal, shop and Board unlock. | | user | |
| 9 | GMFLOW-02, GMFLOW-07 | D-11 | Discard. On the story: «Completa» → «Inizia la missione» → lock visible → «Scarta la bozza» → «Scartare la bozza?» → confirm: the lock is released live and the character stays where the teleport left it. | | user | |
| 10 | GMFLOW-07 | D-12, D-13, D-16 | Normal mission lock (D-12). The innkeeper's character accepts the seeded hunt and arrives (time shortened): during the waiting time the Journal shows «Missione in corso» and refuses, the Board shows the line, the pawn has NO «Missione in corso» label; at the result everything unlocks. | | user | |
| 11 | — (optional) | D-24 | (optional) Narrative story with zero fights: «Scontri» → «Avanti» with no fight → «Premi» → «Completa». | | user | |
| 12 | — (optional) | D-09, D-18 | (optional) Second device: the innkeeper opens the same draft from another device and sees the same served step. | | user | |

Requirement ↔ step map: GMFLOW-01 (2, 3), GMFLOW-02 (1, 6, 9), GMFLOW-03 (4), GMFLOW-04 (5), GMFLOW-05 (7), GMFLOW-06 (8), GMFLOW-07 (1, 8, 9, 10), GMFLOW-08 (the gates of 21-16 and 21-17 — schema gate, 54 × OK, full suite — and steps 1–10 all passed); steps 11–12 optional. Not on the device, covered by tests: every classifier row (21-01..21-05), lenient parsing (21-10), invalidation edge cases (21-12, 21-14), the drop radius (21-08).

Device notes (user memory, run by the user or the orchestrator, never by the executor): `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`.

## Findings and new rules born during the UAT

Filled by plan 21-18 (Task 3).

## Verdict

Filled by plan 21-18 (Task 3).
