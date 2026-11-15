---
status: complete
phase: 22-companion-defeat-rest-and-recovery
device: Android (USB, adb reverse tcp:3000)
be_ref: "fix/23-dungeon-xp-and-innkeeper-corrections HEAD 3d2e1f1e (BE PR #43, draft, not merged yet) on top of develop 5ff0bdb9 (BE PR #42, Phase 23, merged); SDL = develop + one line (Pet.known)"
date: 2026-11-15
verdict: "Steps 1-9 passed; the gap of step 8 (unknown companion silhouette, long press in the shop buy list) was closed on the device on 2026-11-15 with a second character on a player identity"
completed: 2026-11-15
---

# Phase 22 — Device E2E (companion defeat, rest and recovery)

App on the Android phone against the local BE. BE PR #42 (Phase 23 «Sconfitta, riposo e recupero dei compagni») is merged on BE `develop`, ref `5ff0bdb9`. The SDL of `origin/develop` has the same sha256 as the file read by the gate of 22-16 (`5de70ef2…4330`, verified by the orchestrator). Gate re-checked by plan 22-17 before this file was written, block-anchored on the BE `src/schema.gql` (read as a file from the BE working tree, no git command in the BE repo; byte-identical to the 22-16 copy): `OwnedPet.fullLifeAt: DateTime`, `CompanionOutcome.lifeBefore: Int!`, `Mutation.renamePet(request: RenamePetRequest!): CommonResponse!` → `GATE_OK`. Gate of 22-16 on the same SDL: 55 × OK, full suite 5024 green, analyzer 47 info / 0 warning / 0 error. Results are recorded only from the tester's words (quoted verbatim, in Italian); the DB readings are the orchestrator's. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names and character / companion names only).

**BE actually under test (recorded up front):** the UAT runs on BE branch `fix/23-dungeon-xp-and-innkeeper-corrections` = `develop` `5ff0bdb9` + BE PR #43 (SDL unchanged). It carries two rules decided by the user on 2026-11-15: (a) a companion that falls before the last fight of a sequence (dungeon, guided mission) gets the xp of the fights it actually fought only, the fight of the fall included; (b) in an innkeeper correction an omitted or null field takes the simulated value and an explicit value wins (BE A-08).

## Setup

Setup: BE `develop` with Phase 23 merged, booted by the orchestrator; Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001`); app of `feat/22-companion-defeat-rest-and-recovery` (never against a BE without Phase 23). The recovery-time table reviewed by the user is at DB (D-25). Every seed, time shortening and date move is the orchestrator's job, with DB scripts outside the repo and the BE's own write shapes. The Board and the shop are opened only in a city, never in travel.

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 23 merged on BE `develop` (PR #42, `5ff0bdb9`) and booted by the orchestrator | done — booted from the branch under test (row below) |
| BE branch under test `fix/23-dungeon-xp-and-innkeeper-corrections` (= `develop` + PR #43) with the user's rules of 2026-11-15: (a) xp of a companion fallen mid-sequence = fights fought only; (b) innkeeper correction, omitted / null field = simulated value, explicit value wins. Grown during the UAT (see «BE changes made during the UAT») | done — HEAD 3d2e1f1e |
| Recovery-time table (44 pets) at DB in `pets.recoveryTime` (ms) after the user's review (D-25) | done — written by the orchestrator on 2026-11-15, 44/44 verified |
| A weak companion equipped (for the defeat of step 1) | done (orchestrator) |
| A hurt owned companion, unequipped or ready to be unequipped (rest of step 2; potion target of step 3) | done (orchestrator) |
| A mount (catalogue `speedModifier` > 1) for the ambush of step 5 | done (orchestrator) |
| Food for a travel (enough for step 5, scarce for the redirection) | done (orchestrator) |
| Shortened ambush and quest times | done (orchestrator) |
| A pet in a shop pool (purchase of step 4) | done (orchestrator) |
| A quest with a prize pet (step 4) | done (orchestrator; the prize is a 20 % roll of the BE, the won outcome was seeded) |
| A guided mission with a participant who owns a companion (step 7) | done (orchestrator) |
| A companion just below a level threshold (step 9) | done (orchestrator) |
| The test account's probe bearer (credential) for the GraphQL probes (`PET_DEFEATED`, `PET_POTION_RECOVERING`, `PET_NAME_INVALID`), held by the orchestrator, never printed | done (orchestrator) |

## Session data

Field names only, from the BE Phase 23 handoff as copied in `22-16-SUMMARY.md` (and the BE `BACKEND-NOTES.md` §6); no ids, no values, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE.

- Owned companions, `characters.assets.ownedPets[]`: `pet` (catalogue pet id, the only key: there is no owned id), `xp`, `currentLifePoints` (life at the anchor `lifeAsOf`), `name`, `level`, `lifeAsOf`, `defeatedUntil` (internal, never on the wire), `potionRecoveryUntil`. A legacy entry (no `level`, no `lifeAsOf`) is served at full life.
- Equipped companion: `characters.assets.pet`.
- Catalogue: `pets.recoveryTime` (ms; missing = instant recovery), `pets.speedModifier` (> 1 = a mount), `pets.maxLifePoints` (species base), `pets.maxXp` (xp ceiling of the ten levels).
- Travel: `status.activeTravel` with the internal `status.activeTravel.mount` (written at departure only for a pet with `speedModifier` > 1; travels without it are not recomputed).
- Ambush results: `QuestResult` with `kind: ambush`, `resolvedAt` = ambush instant, read mid-travel through `unacknowledgedQuestResults`.
- Sweeper of the «in forze» push: claims within at most 60 s after `defeatedUntil`.
- Seeds per step (shape of the BE handoff §6, names only):
  - step 1 — weak companion in `assets.pet` with a low `currentLifePoints`, `level` set; a hunt with a shortened time;
  - step 2 — hurt entry: `currentLifePoints` below its max, `level` set; unequip it on the phone (the BE writes `lifeAsOf`);
  - step 3 — heal potions in the inventory (integer `power`, short wait); a hurt companion equipped and one resting; for the probes a defeated entry (`currentLifePoints: 1`, `lifeAsOf` = `defeatedUntil − recoveryTime`, `defeatedUntil` a few minutes ahead, not in `assets.pet`) and an entry with a future `potionRecoveryUntil`;
  - step 4 — a pet in a city shop pool; a quest with `prizes.pet`; a named and an unnamed entry for the pushes;
  - step 5 — the mount equipped before departure; food in the inventory (enough / scarce); a weak `currentLifePoints` on the mount; ambush time shortened;
  - step 6 — a defeated entry whose `defeatedUntil` (and `lifeAsOf`) the orchestrator moves back;
  - step 7 — a guided mission (worldMission / story shapes of `21-HUMAN-UAT.md`) with a participant who owns an equipped companion;
  - step 9 — an entry whose `xp` is just below the next threshold of its species `maxXp` (BE write shape recomputes `level`).
- Refusal codes (`extensions.code` only): `PET_DEFEATED`, `PET_POTION_RECOVERING` (`extensions.recoveryUntil`), `ITEM_NO_EFFECT`, `PET_NAME_INVALID`.

## Copy to review

Proposed strings the user may amend at the UAT (amendments become gaps, no code change in this plan). Outcome: no string was amended; the push texts and the «Prosegui a piedi» line were not contested; the only change is the condition of «Prosegui a piedi» (step 5, fixed during the UAT).

- Journal parchment: «Vita: x / max», «A riposo: in forze fra …», «Sconfitto: torna fra …», «Pozione: pronta fra …», subtitle «<specie> · Livello N» (22-02, 22-03).
- Details sheet: «Recupero completo: …», «Livello N», «Dai un nome» / «Cambia nome» (22-02, 22-05).
- Potion sheet: «Dai a <nome>»; companion refusal title «Pozione non data»; lines «<nome> è sconfitto: solo il riposo lo rimette in forze», «<nome> non reggerebbe un'altra pozione: pronta fra …», «Questa pozione non farebbe nulla a <nome> adesso» (22-09, 22-10).
- Equip refusal (title «Compagno non equipaggiato», existing): «È ancora sconfitto: aspetta che torni in forze» (22-09).
- Name prompt: «Come chiamerai il tuo <specie>?», field «Nome», «Chiamalo così», «Più tardi» (22-02, 22-12).
- Rename refusals (inline in the name sheet): «Il nome non è accettato dalle cronache, scegline un altro», «Questo compagno non è più con te», «Connessione assente, riprova», «Il server non ha risposto in tempo, riprova», «Questo personaggio non può farlo», «Qualcosa è andato storto», «Qualcosa è andato storto, riprova» (22-11).
- Result sheet: «<nome>: x / max di vita», «<nome> è stato sconfitto: riposa e tornerà fra …», «<nome> guadagna N PE», «Prosegui a piedi» (22-13). Not contested at the UAT; amended in its condition at step 5 (printed only when the travel goes on, not when carried to a city).
- Settings: «Imboscate» (now every ambush), «Compagno in forze» (new) (22-14).
- Innkeeper: heading «Compagno: <nome>», «x / max», marker «Sconfitto» at the floor (22-15).
- Pushes (built by the BE, provisional; not contested at the UAT): «Imboscata!» with «Imboscata presso <città>: hai respinto gli assalitori» / «… <nome> è stato sconfitto[, prosegui a piedi]» / «…; la fame ti porta verso <città>» / «Sei stato sconfitto: la via torna verso <città>[. <nome> è stato sconfitto]»; «Di nuovo in forze» with «<nome> è di nuovo in forze».

## Product notes to review

No code change; recorded so the user can rule on them at the UAT:

- The companion card no longer prints attack and defense (speed stays on the card); the full stats live in the details sheet (long press) (22-04, 22-07).
- The live life rounds to the nearest point and stays capped one point below full until `fullLifeAt`; at that date the parchment is full and tappable again locally (22-02).
- Outside the Journal (shop, basket, quest sheet, innkeeper rows) the details open as a sliding route from the bottom, catalogue view: no bookmark, no rename, no level / xp / vitality (22-05, review A-09 deferred).
- A refused potion to a companion closes on the banner; the sheet's targets are a snapshot taken at opening (review A-05 deferred).
- The pawn may jump back to the ambush point when the sweep resolves the ambush late (BE limit B-09, to watch at step 5).
- The shop coin satchel overflow seen only on the 780x360 test surface (`deferred-items.md`): to check on the device.

## Steps

| Step | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|-----------|----------|--------|--------|------|
| 1 | PET-02, PET-06 | D-02, D-03, D-09, D-10, D-26, D-27 | Defeat in a fight. With a weak companion equipped, run a hunt (time shortened): the result sheet prints «<nome> è stato sconfitto: riposa e tornerà fra …» (duration = full-life date − resolution, unchanged if the sheet is reopened later); the slot is empty; the Journal parchment is faded, not tappable, «Sconfitto: torna fra …»; an equip probe answers `PET_DEFEATED` (PET-02, PET-06; D-02, D-03, D-09, D-10, D-26, D-27). | pass | user + orchestrator | «Se il pet viene sconfitto non ottiene xp. Li ottiene solo quando vince. pass su tutto il resto». Orchestrator: in the hunt the defeated companion had taken 1 xp and levelled up (old BE rule); the new rule (no xp from a fight the companion does not survive standing) was made in the BE during the UAT (bf812a33). Equip probe: `PET_DEFEATED`. |
| 2 | PET-01, PET-02 | D-04, D-09, D-24 | Rest. Unequip a hurt companion: «Vita: x / max» rises on screen without any loader and «A riposo: in forze fra …» counts down; re-equip it mid-way: it keeps the life reached and stops rising (PET-01, PET-02; D-04, D-09, D-24). | pass | user | «pass». |
| 3 | PET-01, PET-04 | D-05..D-08, D-32 | Potion on a companion. Open the potion sheet: «Bevi» and one «Dai a <nome>» per eligible companion (equipped and resting); give one: the outcome face shows the companion's life bar; its parchment and details show «Pozione: pronta fra …»; the character can still drink; during the character's own wait the row stays tappable and «Bevi» is disabled; a defeated companion and one in its own wait are not listed; probes answer `PET_DEFEATED` and `PET_POTION_RECOVERING` (PET-01, PET-04; D-05..D-08, D-32). | pass | user + orchestrator | «pass». Orchestrator probes: `PET_DEFEATED` on the defeated companion, `PET_POTION_RECOVERING` with `recoveryUntil` on the one in its wait. |
| 4 | PET-05 | D-18..D-21, D-31 | Names. Buy a companion in a shop: the prompt «Come chiamerai il tuo <specie>?» opens — skip once («Più tardi»), buy another and name it; win a quest with a prize companion: the prompt opens after «Continua»; rename from the Journal details («Cambia nome»), also during a mission; type «R2D2»: the confirm stays disabled; a server refusal (probe) shows «Il nome non è accettato dalle cronache, scegline un altro» and allows retry or skip; the name appears in «Dai a <nome>», on the card title with the species below, in the result lines, in the sell list and in the pushes (PET-05; D-18..D-21, D-31). | pass | user + orchestrator | «pass», after two defects reported and fixed during the UAT: «Quando si apre la tastiera, invece di spostarsi solo la bottomsheet, si sposta tutto, facendo vedere dietro la tastiera il background bianco» (fix 644a115c / c138fadf) and «Anche la bottomsheet è strana, La parte superiore risulta tagliata» (fix 91759384 / 8e07d31b). Then «Non ho ottenuto l'alce nella quest»: not a defect, the prize companion is a 20 % roll of the BE; the orchestrator seeded the won outcome and the step was confirmed. The server refusal of a name is not reachable from the phone (same form rules on the client): orchestrator probe `PET_NAME_INVALID`, message covered by tests. Rename during a mission tried at step 7. |
| 5 | PET-06, PET-07 | D-13..D-16, D-28..D-30 | Ambush mid-travel with a mount. Travel with the mount equipped; the ambush is won and the mount falls: the push «Imboscate» arrives; opening the app shows the carousel BEFORE the arrival with «<nome> è stato sconfitto…» and «Prosegui a piedi»; the pawn continues from the ambush point without jumping back and the arrival is later; with little food the character is redirected to the nearest city («Portato a <città>»); with the Map open the carousel opens and no push banner doubles it (PET-06, PET-07; D-13..D-16, D-28..D-30). | pass (one correction) | user + orchestrator | Defeat in an ambush (carried back to a city): «pass». Win with the mount fallen, on foot (arrival moved from 17:04 to 18:59): «pass». Map open: «non è comparso il banner, il foglio si è aperto da solo». Detour for little food (win, life 1, redirected to Valantar): «Sulla pergamento ho visto sia Portato a Valantar sia Prosegui a piedi, il resto pass» → fix 866a8148 / 6670a8c2 / 356fffec: «Prosegui a piedi» only when the travel goes on; covered by tests, not re-seen on the device. Orchestrator: the fight outcome is a roll, several attempts were needed; the pawn jump-back (B-09) was not reported. |
| 6 | PET-07 | D-11, D-24, D-30 | «In forze» push. After a defeated companion's wait (the orchestrator moves its dates back), within a minute the push «… è di nuovo in forze» arrives and the parchment is tappable again; in Settings «Compagno in forze» off suppresses it; «Imboscate» kept its previous choice (PET-07; D-11, D-24, D-30). | pass | user | «In forze» push arrived after the dates were moved back (BE sweep at 16:13): «pass». With the switch off: «Non è arrivata la notifica, Imboscate è rimasto attivo. pass». |
| 7 | PET-08 | D-12, D-17, D-33 | Innkeeper slider. In the guided completion of a mission whose participant owns a companion: «Simula» → the corrections show «Compagno: <nome>» with its slider; move it to the floor («Sconfitto») → complete: the participant's companion is out of the slot and resting, its result sheet prints the defeat line (PET-08; D-12, D-17, D-33). | pass | user + orchestrator | «pass». Orchestrator (DB): outcome `gmCompleted`, companion defeated and out of the slot, 0 xp to the companion (new rule). |
| 8 | PET-03 | D-19, D-22, D-34, D-35 | Details on long press. Long press on a companion in the Journal (list and slot), the shop buy list, the sell list, the basket, the quest-sheet prize and the innkeeper prize rows: the same details sheet with the image, life, rest, potion wait, «Recupero completo: …», attack, defense and speed; the tap still equips / selects (PET-03; D-19, D-22, D-34, D-35). | pass | user + orchestrator | First run (innkeeper identity): «Se non hai ancora ottenuto la lore corrispondente, il foglio non si deve aprire per dare il dettaglio e l'immagine deve essere nera (come succede per gli enemies). Non sono a Valantar, quindi non posso controllare il cammello nello shop. Il resto lo confermo, pass». The request was made during the UAT (BE `Pet.known` e4268b72, FE UF-01 in `22-UAT-FIXES.md`); two points were left to see on the device (unknown companion silhouette, long press in the shop buy list). **Re-run on 2026-11-15 after Task 3**, with the dev bypass identity changed on the user's authorization to a second character (a player, at Valantar, who knows only four companions). Passes given by the orchestrator: shop buy list — Levriero and Cammello as black silhouettes with the name visible, a long press opens nothing, a short tap selects; Cavallo leggero and Falco with image and details; sheet of the quest «UAT 22 — Il dono dell'Alce» with the prize Alce as a silhouette with no details; Journal with the character's own companions drawn as usual. User: «pass». Orchestrator probe: the BE served `known: true` only for the four companions whose lore was unlocked. |
| 9 | PET-10 | D-37, D-38 | Companion level up. The orchestrator raises a companion's xp past a threshold (BE write shape): without touching the phone its parchment reads «<specie> · Livello N+1», «Vita: x / max» shows the larger max with the current life unchanged, and the details sheet reads «Livello N+1»; a companion resting at full life stays full (PET-10; D-37, D-38). | pass | user + orchestrator | «pass» (Poldo level 2 at 1300 / 1329, Pippoi level 2 at 102 / 102, without touching the phone). |

Requirement ↔ step map: PET-01 (2, 3), PET-02 (1, 2), PET-03 (8), PET-04 (3), PET-05 (4), PET-06 (1, 5), PET-07 (5, 6), PET-08 (7), PET-10 (9), PET-09 (the gate of 22-16 — schema gate, 55 × OK, full suite — and steps 1–9 all passed, step 8 after its re-run as a player). Not on the device, covered by tests: every classifier row (22-09, 22-11), lenient parsing (22-01, 22-13, 22-15), the vitality rule edge clocks (22-02, 22-03), the switch-off paths (22-10, 22-12).

Device notes (user memory, run by the user or the orchestrator, never by the executor): `adb reverse` is lost at every USB reconnection; port 3000 busy → `PORT=3001` + `adb reverse tcp:3000 tcp:3001`; screen off → `adb shell svc power stayon usb`; topic/IAM traps of FCM in the orchestrator's memory.

## Fixes made during the UAT

FE (TDD, separate commits by the orchestrator's executors; suite after the fixes 5041 green, analyzer 47 info / 0 warning / 0 error):

| Step | User report | Commits |
|------|-------------|---------|
| 4 | keyboard moved the whole page, white background behind it | 644a115c (test), c138fadf (fix) |
| 4 | top of the name sheet cut | 91759384 (test), 8e07d31b (fix) |
| 5 | «Portato a Valantar» and «Prosegui a piedi» together | 866a8148 (test), 6670a8c2 (fix), 356fffec (test) |
| 8 | unknown companion: black image, no details (UF-01, `22-UAT-FIXES.md`) | 6e3a0336, 376e8edf, 293e6371, 321d773c, e747645a, a0614862 |

BE changes made during the UAT on `fix/23-dungeon-xp-and-innkeeper-corrections` (orchestrator): companion xp only from the fights it leaves standing (bf812a33); omitted innkeeper corrections = simulated (9106b66e); `Pet.known: Boolean!` (e4268b72); last HEAD 3d2e1f1e. SDL: one line added (`known`) against `develop`; FE schema check re-run by the orchestrator: 55 × OK.

## Gaps

None open.

- **Step 8 on the device — closed on 2026-11-15.** The two points left by the first run (the black silhouette and no details sheet of an unknown companion; the long press in the shop buy list) were seen by the user as a second character on a player identity at Valantar (step 8 row): «pass». PET-03 and therefore PET-09 are complete.

## Product notes and questions (not gaps of this phase)

- At the start the `adb reverse` tunnel had dropped: the app, not reaching the BE, showed the character creation instead of an offline state. Behaviour older than this phase, to review with the user.
- Innkeeper surfaces and `Pet.known`: if the BE resolves `known` for the streamer's own viewer, prize companions whose lore the streamer has not unlocked show as silhouettes and open no details in the innkeeper wizard (open point of UF-01).

## Operational notes

- The magic quest «Iniziazione arcana a Valantar» was missing from the DB and was put back from the backup at the user's request (orchestrator; not a matter of this phase).
- DB restored after the UAT by the orchestrator on the user's order («Ripristina tutto»): the three «UAT 22» quests, the day's results and the test companions removed; life, injuries, coins, items and position of the two characters and the companion list of the Valantar shop put back as they were. Kept at DB: the recovery times of the 44 companions and the magic quest put back above. The backup of the UAT state is kept by the orchestrator outside the repo.
- CI of BE PR #43 green on its last push (HEAD 3d2e1f1e), reported by the orchestrator.
