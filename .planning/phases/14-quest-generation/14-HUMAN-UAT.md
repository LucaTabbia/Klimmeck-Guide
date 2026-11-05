---
status: complete
phase: 14-quest-generation
device: Android (USB, adb reverse tcp:3000)
be_ref: 162c1f5
date: 2026-11-05
completed: 2026-11-05
verdict: steps 1–8 pass (step 8 Cloudinary half skipped by the user's decision), optional step 9 and the pet part of step 3 run and pass
---

# Phase 14 — Device E2E (quest generation)

App on the Android phone against the local BE from `develop` (`162c1f5`, merge of PR #19 `feat/13-generazione-quest`, BE Phase 13 merged). Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "QuestEnemy"` → `3`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 13 merged running locally, restarted by the user following the BE handoff runbook (boot migrations `enemy` → `enemies`, dungeon enrichment, jewels' `accessoryUseTypes`); Samsung via USB with `adb reverse tcp:3000 tcp:3000`; the device account is innkeeper (Locanda); optional DB data written by the user with placeholders only (never printed): a boss with `prizes.pet`, an enemy with a Cloudinary `imagePath`, a result with `rewards.pet`.

### Session notes (2026-11-05)

- The user's BE already runs the merged code from `dist/` on port **3001** (first real boot 2026-11-05; boot migrations applied: 167 generated quests, 40 dungeons staged, 22 legendary, 42 jewels). No BE restart was needed for this session.
- Samsung SM-S938B over USB with the tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`).
- The board already held ~167 generated quests (target = number of cities): «Genera missioni» answers «Nessuna missione da generare» (`created = 0`) unless a generated quest was concluded first. New generated quests appear only when the board tab is reopened (no subscription event, BE D-18).
- The optional DB data (steps 3-pet, 8, 9) and the other session seeds were written by the orchestrator with read/write scripts at the user's request, using the BE's own write shapes, never by the executor. Field names (from the BE Phase 13 handoff on BE `origin/develop`, §3 and §9):
  - quest enemies: `infos.enemies[]` = `{enemy, quantity}` (for dungeons the list order = the stage order);
  - an enemy is generable only with `Enemy.legendary: false`;
  - companion prize / reward: `prizes.pet` (quest) and `rewards.pet` (result) = the ObjectId of a pet with `sellable: false`;
  - portrait: `Enemy.imagePath` = an `https://…` URL or a Cloudinary `v<n>/…` path (all enemies carry `assets/images/…` placeholders today, hidden by D-03).
- Fields actually written at DB during the session: `concludedAt` (one generated quest, the aid quest), `infos.enemies[].quantity`, `prizes.pet`, `assets.ownedEquipments[]`, `status.activeTravel.startTime/endTime`, `rewards.pet`, `status.location`, `status.awaitingAid`. No `imagePath` was changed (step 8, user's decision).

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; screen off → `adb shell svc power stayon usb`; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | QGEN-03 | D-08, D-09 | Settings → Locanda: «Genera missioni» is visible at the top, above the queue (also with «Nessuna richiesta in attesa»). Tap → dialog «Generare nuove missioni nel mondo?» → «Annulla»: nothing happens. Tap again → «Genera» → the button is disabled while the call runs → SnackBar «Generate N missioni» / «Generata 1 missione» / «Nessuna missione da generare» (QGEN-03; D-08, D-09). | pass | User: «pass». Before the step the orchestrator concluded one generated quest at DB (`concludedAt`, same write as the outcome path) because the world was full at 167/167, so the SnackBar could read «Generata 1 missione». Orchestrator's server-side checks: BE log `Generatore: 1 missioni create (target 167)` at 08:47:17; audit `generateQuests` outcome `ok`, target `QuestGeneration`; open generated quests back to 167/167. |
| 2 | QGEN-01, QGEN-05 | D-02, D-04, D-05 | Board (reopen the tab, BE D-18) → a generated `enemy` quest: the sheet shows the announcement under the title (italic), the portrait only if the enemy has a Cloudinary path, the «Nx nome» lines (e.g. «3x Goblin», «1x Capo goblin») in the order of the title, «Consigliati» when the quest has recommended loot, one slot line of the rank; nothing marks it as generated (QGEN-01, QGEN-05; D-02, D-04, D-05). | pass | User: «pass». Quest «Minaccia: Picchiatore presso Talmvere» (generated `enemy`, rookie). The orchestrator set `infos.enemies[0].quantity` to 3 at DB so the line read «3x Picchiatore» (a lone 1x enemy shows the bare name by the FE rule). No portrait (placeholder `assets/images/…`, D-03), announcement shown, «Consigliati», one rank slot line, no «generated» mark. |
| 3 | QGEN-01 | D-06 | A generated `boss` quest → the enemy name (bare, quantity 1), party slot lines (2–6 seats of the rank); optional: «Compagno in premio: <nome>» when the user set `prizes.pet` at DB (QGEN-01; D-06). The pet part is optional. | pass | User: «indica 2 posti disponibili rango mago, pass». Quest «Boss: Treant presso Talmvere» (generated `boss`, mage). Optional pet part **run**: the orchestrator set `prizes.pet` to a `sellable: false` pet (Worg) before the step → «Compagno in premio: Worg» next to the coins in the prize row (WR-01 layout). |
| 4 | QGEN-01, QGEN-04 | — | A fixed dungeon (enriched, 2–4 stages) → combat family, lines in stage order, «Consigliati» (QGEN-01, QGEN-04). | pass | User: «pass. Ho accettato la quest perché non posso farlo al di fuori della città». Quest «Dungeon: Ankheg presso Talmvere» (fixed, adventurer, 4 stages: 1x Ankheg, 6x Bandito, 1x Quasit, 1x Bugbear). Accepted from the city marker; the automatic travel to the dungeon POI started. |
| 5 | QGEN-02 | D-07 | Resolve that dungeon (accept + resolution, or GM completion from the Locanda) → the result sheet lists the enemies fought («Nx nome») and «Esplorazione: tappa k di N»; a victory shows all the stages (QGEN-02; D-07). | pass | User: «Ho superato 0 tappe di 4. Non è un problema, l'algoritmo devo rivederlo io. pass». To avoid waiting, the orchestrator shifted `status.activeTravel.startTime/endTime` four hours into the past; the BE travel sweeper closed the travel and the resolution sweeper resolved the dungeon: `outcome: failure`, `stagesCleared: 0`, `stagesTotal: 4`, enemies 1+6+1+1, HP 40000 → 38700, rewards empty. The sheet showed the enemies fought and «Esplorazione: tappa 0 di 4». A legend level-20 character lost at the first stage: the placeholder resolver is the user's to revise (BE D-10/D-11), not a FE defect. The defeat put the character in `awaitingAid` with the aid quest «Soccorso: Dungeon: Ankheg presso Talmvere» (Phase 9 behaviour). |
| 6 | QGEN-04, QGEN-05 | D-11 | A fixed `crime` or `guard` quest sheet → service family (no enemy column) with its announcement; no alignment anywhere (QGEN-04, QGEN-05; D-11). | pass | User: «pass». Quests «Turno di guardia a Chargate» (`guard`) and «Affari loschi a Chargate» (`crime`). First the user reported: «Sono ancora in attesa di soccorso, non posso aprire il tabellone» — the awaiting-aid state from the step-5 defeat blocks the board (Phase 9 behaviour, not a Phase 14 defect; the BE's only exits are a rescue or the 7-day timeout ending in death), so the orchestrator cleared it at DB with the BE's write shapes (`status.awaitingAid: null`, `concludedAt` on the aid quest). Talmvere has no crime/guard quest: the orchestrator teleported the character to Chargate's city marker (same `status.location` write as the GM teleport). |
| 7 | QGEN-06 | D-12 | Journal → tap a ring and a necklace (owned or worn) → «Uso: attacco» / «Uso: difesa» / «Uso: attacco e difesa»; a helm shows no «Uso» line; the same in the shop item sheet if a jewel is on sale (QGEN-06; D-12). | pass | User: «pass» (answered together with step 9). The orchestrator added to `assets.ownedEquipments` the ring «Anello dal volto mutevole» (`["attack"]`) and the necklace «Medaglione del Vulcano» (`["attack","defense"]`) (same `{itemType, item, quantity}` shape): the Journal showed «Uso: attacco» and «Uso: attacco e difesa»; helms without the line. The Talmvere shop sells «Collana di Mirwa» / «Anello di ferro» (`["defense"]`) for the «Uso: difesa» variant (offered, not reported separately). |
| 8 | QGEN-01 | D-03 | Portrait: an enemy whose `imagePath` the user set to a Cloudinary path/URL shows its portrait on the quest sheet; an enemy still on the placeholder `assets/images/…` shows only the name (QGEN-01; D-03). | pass (placeholder half) / skipped (Cloudinary half) | User: «Il ritratto non mi serve, il resto facciamolo». Placeholder half **pass**, observed in step 2 (the enemy on `assets/images/…` showed only the name, no portrait). Cloudinary half **skipped by the user's decision** (no enemy was given a Cloudinary path); covered by the 14-04 widget tests of `EnemyPortrait` / `enemyPortraitUrl`. By the user's decision this does not block QGEN-01 (steps 2, 3, 4 passed and the D-03 placeholder behaviour was seen). |
| 9 | QGEN-02 | D-07 | Optional: a result with `rewards.pet` shows «Compagno ottenuto: <nome>» (QGEN-02; D-07). | pass | User: «pass» (answered together with step 7). The orchestrator set `rewards.pet` to a `sellable: false` pet (Alce) on the unacknowledged dungeon result; the user killed and reopened the app; the result sheet reappeared with «Compagno ottenuto: Alce» (rewards block shown on a failure outcome too), then was acknowledged. |

Requirement ↔ step map: QGEN-01 (2, 3, 4, 8), QGEN-02 (5), QGEN-03 (1), QGEN-04 (4, 6), QGEN-05 (2, 6), QGEN-06 (7). Steps 3-pet and 9 are optional and never block a requirement. `FORBIDDEN` (non-innkeeper) is not reachable on the device: covered by the 14-08 widget tests.

## Verdict

- QGEN-01: steps 2, 3, 4 pass; step 8 placeholder half pass, Cloudinary half skipped by the user's decision → complete.
- QGEN-02: step 5 pass (optional step 9 pass) → complete.
- QGEN-03: step 1 pass → complete.
- QGEN-04: steps 4, 6 pass → complete.
- QGEN-05: steps 2, 6 pass → complete.
- QGEN-06: step 7 pass → complete.

No gaps. Both optional companion lines («Compagno in premio», «Compagno ottenuto») were exercised on the device.

### Things looked at during the run (from the review fixes)

- Boss sheet with coins + companion (step 3): the WR-01 prize row layout (coins column narrowed, «Compagno in premio» line beside it).
- A named enemy next to an unnamed DB entry shows «1x <nome>» instead of the bare name (IN-04) — not exercised.
- With TalkBack the «Ritratto del nemico» label is announced only once a raster portrait is shown (IN-01) — not exercised (no portrait on the device).
