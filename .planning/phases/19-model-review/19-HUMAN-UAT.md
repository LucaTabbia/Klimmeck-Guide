---
status: complete
phase: 19-model-review
device: Android (USB, adb reverse tcp:3000)
be_ref: 48b20701
date: 2026-11-11
verdict: steps 1–11 pass (step 7 on the second attempt, after a defeat that correctly paid nothing to the companion), optional steps 12–14 skipped; extra checks A, B, C pass; finding F1 fixed by the quick task 261111-enm on both repos, finding F2 fixed at DB (pet shops by size); MODEL-01..04 complete
completed: 2026-11-11
---

# Phase 19 — Device E2E (model review, frontend companion)

App on the Android phone against the local BE from `develop` (`48b20701`, merge of BE PR #33 `feat/19-revisione-dei-modelli`). Gate re-checked before this file was written: `type Weaknesses`, `type OwnedPet`, `petXpGained`, `wornEquipment`, `feet`, `attack: Damages!` present; `energyWeaknesses`, `baseWeaknesses`, `wearedEquipment`, `foots`, `activeSpells` absent; block-anchored checks on `SpellState.active`, `CharacterAssets.ownedPets: [OwnedPet!]!`, `Pet.defense`, `Pet.rarity`, `SlotType.feet` passed → `GATE_OK` on `origin/develop:src/schema.gql`. Results are recorded only from the tester's words. Notes carry no ids of real users, no secrets, no Mongo URIs and no identity values (field names only).

## Setup

Setup: BE `develop` with Phase 19 merged, booted by the orchestrator with the one-off migrator (BE runbook: backup, first boot, second boot at zero); pet content written at DB right after the boot (BE D-25: `maxXp` and a non-empty `defense` for all 44 pets; BE D-26: the pet lore linked from each pet); Samsung via USB with `adb reverse tcp:3000 tcp:3000` (or `tcp:3000 tcp:3001` when the BE runs on 3001); APK of `feat/19-model-review` (it selects `wornEquipment`, `feet`, `spellStates.active`, `ownedPets { xp currentLifePoints pet }`, `attack`, `defense`, `maxXp`, `rarity`, `petXpGained`, `Lore.imagePath` and must never run against a BE without Phase 19). **Nobody owns a pet at DB today** (BE inventory of 2026-11-11): the companion of the test character is bought in step 1 or seeded by the orchestrator in the entry shape. The test character has at least two known spells, boots in the inventory and coins for one pet. Every seed (coins, pet entry, spells, boots, quest and travel times) is the orchestrator's job, done outside the repo and never printed. The shop and the Board are opened only in a city, never in travel.

## State of the BE on this machine (2026-11-11)

Facts given by the orchestrator and by the BE Phase 19 handoff (section «Esito del boot reale (2026-11-11)»); nothing here was read from the database by the executor.

- The BE runs the Phase 19 code on port **3001** (device tunnel `adb reverse tcp:3000 tcp:3001`) with the MIGRATED data and the pet content; the one-off migrator is already out of the build (third real boot from `7ca680fa`, no migration line).
- 44 pets with `maxXp` (from 100 to 2350), a non-empty `defense`, a `rarity` (13 common, 8 uncommon, 8 rare, 12 ultrarare, 3 legendary) and their lore linked.
- «Molosso da guerra» is now sold (uncommon, 60 silver) in the 7 cities that sell the Mastino: Fineglen, Shadmus, Cliffbreak, Croce Marina, Valantar, Bellport, Talmvere.
- «Cavallo da viaggio» has its own image and a new lore page; it has NO attack: its rows show only «Difesa: …».
- Nobody owns a pet yet: the first steps buy one. Prefer a cheap pet with a visible attack AND defense (a cat or a dog); every pet has a rarity today, so the «pet without rarity» fallback of step 1 cannot be seen on the device (covered by tests).
- Characters at DB: one has 8 known spells with 2 equipped, one has 1 spell equipped; two characters wear boots, which must still show on the mannequin in the `feet` slot after the migration.
- **The local Redis is NOT reachable:** timed jobs (quest resolution, travel arrival) are covered by the periodic sweeps, so an outcome can arrive up to one sweep interval late. In steps 7 and 8 wait for the sweep before reporting a missing result.
- The companion gains 10 % of the enemies' xp, rounded, after the `maxXp` cap: weak enemies may give 0 or 1, and with 0 no line is shown. The fight of step 7 must have enemies totalling at least 10 xp (the BE handoff names no quest: the orchestrator picks one on the Board of the city).

## Prerequisites owned by the orchestrator

| Prerequisite | Done |
|--------------|------|
| BE Phase 19 merged on BE `develop` (PR #33, `48b20701`; local ref `origin/develop` points there) | done (orchestrator, 2026-11-11) |
| BE booted with the migrator following the runbook of the BE handoff (backup, first boot, second boot at zero; never pre-19 code on the migrated database); now running without the migrator on port 3001 | done (orchestrator, 2026-11-11); for the last three checks (A, B, C) the BE was rebuilt and restarted from the BE quick-task branch `fix/enemy-quests-single-player` |
| Pet content at DB: `maxXp`, non-empty `defense`, `rarity` and the pet lore for all 44 pets (BE D-25, D-26, D-27) | done (orchestrator, 2026-11-11); the shop pools were then narrowed during the UAT (finding F2) |
| Debug APK of `feat/19-model-review` installed on the Android phone; `adb reverse tcp:3000 tcp:3001` re-applied after every USB reconnection | done (orchestrator, 2026-11-11): debug APK of the dev flavor built from this branch on a Samsung SM-S938B; rebuilt and reinstalled after the quick task 261111-enm |
| A companion bought in step 1 or seeded in the entry shape `{ pet, xp, currentLifePoints }` (nobody owns a pet at DB today) | done: bought in step 1 («Gatto soriano»), nothing seeded |
| Test character: at least 2 known spells (states), boots in the inventory (or worn), coins for one pet, standing in a city that sells pets | done (2026-11-11): the character stood at Valantar; the boots of step 6 were bought in the shop during the step |
| Step 5: every spell slot taken and at least one known spell left out | met on the device (step 5 passed) |
| Steps 7 and 8: a short combat quest on the Board whose enemies total at least 10 xp; quest times shortened | done (orchestrator, 2026-11-11): 18 enemy xp in step 7; travel and quest timers moved back at DB, outcomes resolved by the 60 s sweeps (see steps 7 and 8) |

## Session data (known on 2026-11-11)

Field names only, from the BE Phase 19 handoff (§1, «Note per la UAT della FE») and `19-10-SUMMARY.md`; no ids, no secrets. Every seed is a script of the orchestrator outside the repo, with the same write shapes as the BE; the characters change stream re-emits `characterUpdated` on every update.

- Owned companions: `assets.ownedPets[] { pet, xp, currentLifePoints }` (a bought pet is appended as a whole entry with `xp` 0 and full life); equipped companion `assets.pet` (its state is the `ownedPets` entry with the same pet id).
- Pet catalogue (collection `pets`): `maxXp`, `maxLifePoints`, `attack`, `defense`, `rarity`, `relatedLore`, `enemy`, `sellable`; shop pool `cities.shop.pets`.
- Spells: `status.spellStates[] { spell, usages, recoveries, active }` (list order = learning order; equip / unequip write only `active`), `status.maxActiveSpells`.
- Equipment: `assets.wornEquipment.feet` and the other eight slots; `assets.ownedEquipments`.
- Lore: `status.unlockedLore` (the lore of a pet enters it when the pet is obtained), `lore.imagePath`.
- Coins: `status.coins`.
- Quest and travel times: as in the Phase 18 UAT (`pendingquests` start / arrival dates; `status.activeTravel.startTime` / `status.activeTravel.endTime` shifted together).
- Results at DB: `questresults.petXpGained` (the effective gain after the cap; 0 without an equipped companion, without enemies, on a defeat, at the cap).

## Steps

Results from the user's words during the run of 2026-11-11; the DB readings and the seeds in the notes are the orchestrator's.

| Step | Requirements | Decisions | Expected | Result | Source | Note |
|------|--------------|-----------|----------|--------|--------|------|
| 1 | MODEL-02 | D-03, D-12, D-13, D-20 | Shop — pets and purchase. Character in a city with a shop that sells pets. The pet rows show the name, the price and, under them, «Attacco: …» for every pet that has an attack («Cavallo da viaggio» has none: no «Attacco» line) and «Difesa: …» for every pet (BE D-25); the speed line only on riding pets; the NAME of a pet with a rarity is drawn in the colour of that rarity, the same colours the item cards use (D-20; a pet without rarity keeps the usual ink). Buy one pet: the purchase goes through as before and the pet leaves the buy list («già posseduto» still filtered) and appears in the sell list (MODEL-02; D-03, D-12, D-13, D-20). | pass | user | User: «Sì ad entrambe le domande» (the «Attacco» / «Difesa» lines are legible; the name of a common pet is distinguishable and «Molosso da guerra», uncommon, is in a different colour). City: Valantar; bought «Gatto soriano». DB after the purchase (orchestrator): an owned entry with `xp` 0 and `currentLifePoints` 200, the pet lore unlocked in the same write. Content finding raised here: F2 (pet pools too broad), fixed at DB during the UAT. |
| 2 | MODEL-02 | BE D-26 | Library — pet lore. Right after the purchase, open the Library: the lore page of the pet just bought is there with the «Nuovo» bookmark (BE D-26, Phase 17 flow on `unlockedLore`; no FE code in this phase) (MODEL-02; BE D-26). | pass | user | User: «pass», with the remark that this character (Reavor) has every lore unlocked: it is the innkeeper rule (Phase 16: the innkeeper sees all), so the step is not conclusive on this character. Re-checked with a non-innkeeper character in check A (pass). |
| 3 | MODEL-02 | D-03, D-13, D-18, D-20 | Journal — «Compagno». Open the Journal «Compagno» dropdown: the owned row of the bought pet is a parchment with its name in the colour of its rarity as in the shop (D-20) (and speed if riding), «Attacco: …» when it has one and «Difesa: …» on the parchment, and next to it «Esperienza: 0 / <maxXp>» with the `maxXp` written at DB; no life is shown anywhere. Tap the row: the pet goes to the slot with the fade, the row shows «Al tuo fianco» above the experience line; tap again: it leaves the slot. Leave it equipped (MODEL-02; D-03, D-13, D-18, D-20). | pass | user | User: «pass». The row read «Esperienza: 0 / 100»; equip and unequip worked. |
| 4 | MODEL-03 | D-05, D-14 | Journal — «Magie imparate», the single list. Every known spell is listed; the equipped ones are in the slots with their usages (and the countdown of a spent use, as before). Unequip one and equip it again: optimistic fade, no spinner, the state confirmed by the stream. With two or more equipped spells, the slots are in the order in which the spells appear in the known list (learning order), and a spell equipped last takes its place in that order instead of the last slot (MODEL-03; D-05, D-14). | pass | user | User: «pass». Single list, slots in learning order, usages and recovery. |
| 5 | MODEL-03 | D-05 | Journal — slots full. With every slot taken, tap a non-equipped spell: the refusal of the full slots as before, nothing changes (MODEL-03; D-05). | pass | user | User: «pass». Refusal of the full slots as before. |
| 6 | MODEL-03 | D-04, D-19 | Mannequin — boots. In the Journal equipment, equip the boots from the inventory: they appear on the feet of the mannequin; unequip them: the slot is empty again and the boots are back in the list. As a control, equip and unequip an item of another slot (MODEL-03; D-04, D-19). | pass | user | User: «pass». The boots were bought at the Valantar shop during the step («Stivali del Boscaiolo») instead of coming from the inventory: worn, removed, worn again; a control slot too. |
| 7 | MODEL-02 | D-03 | Fight with the companion. With the companion equipped (step 3), accept a combat quest in the city and win it (time shortened by the orchestrator): the result sheet shows the character xp line and right after it «Il tuo compagno guadagna N PE» with N above 0; back in the Journal the owned row reads «Esperienza: N / <maxXp>» (grown by exactly N) (MODEL-02; D-03). | pass (second attempt) | user | First attempt, «Caccia: Formiche giganti assassine nei dintorni di Voxhold» (18 enemy xp): DEFEAT — the placeholder combat is probabilistic and Reavor carries heavy injuries; no companion line, `petXpGained` 0, the character awaiting aid (rescued by hand by the orchestrator with the BE's own update). Second attempt with the enemy's life temporarily set to 1 at DB (restored to 2500 afterwards): VICTORY, the sheet shows «Il tuo compagno guadagna 2 PE» (screenshot read by the orchestrator: the line sits in the rewards block); DB `petXpGained` 2 and the cat 0 → 2; user «pass» on «Esperienza: 2 / 100». Difference from the expected text, as designed: Reavor is a legend at the xp cap, so the sheet has no character xp line and the companion line shows alone. Timers (travel and quest) moved back at DB by the orchestrator, outcomes resolved by the 60 s sweeps (local Redis not reachable). Prerequisite note: the innkeeper teleport needs an accepted story / world mission (user: «Non posso fare teleport se il personaggio non ha accettato una quest story o worldMission»), so the orchestrator moved the character with the BE's teleport update at DB. Finding raised here: F1 (enemy quests and seats). |
| 8 | MODEL-02 | D-03 | Fight without the companion. Unequip the companion and win another short combat quest: no «Il tuo compagno guadagna» line on the sheet; the experience of the owned row is unchanged (MODEL-02; D-03). | pass | user | User: «pass». Victory without the companion: no companion line, `petXpGained` 0, the cat stays at 2 / 100. |
| 9 | MODEL-01, MODEL-04 | D-06, D-08 | Map untouched. Open the Map: the city markers, the quest pawns and the character pawn are where they were; open a city sheet and start a travel preview: the confirmation sheet shows the city image; nothing looks different from before the phase (MODEL-01; D-06, D-08). | pass | user | User: «pass». |
| 10 | MODEL-01 | D-06 | Library — images. Open two or three lore pages with an image (a city, a creature): the images load; a book opens and closes as before (MODEL-01; D-06). | pass | user | User: «pass». |
| 11 | MODEL-01 | D-01, D-02 | Result of a fight — enemies. On the result sheet of step 7 or 8 the enemy portrait and name are shown as before (the enemy model changed shape, nothing visible) (MODEL-01; D-01, D-02). | pass | user | User: «pass». |
| 12 | MODEL-03 (optional) | D-05 | (optional) Innkeeper form. If the user's account is the innkeeper: a completion form of a participant lists the equipped spells of that character (same single list) (MODEL-03; D-05). | skipped (optional) | — | Not run. |
| 13 | MODEL-02 (optional) | D-03 | (optional) Sell the pet. In the shop sell the bought pet (not equipped): it leaves the sell list and the Journal «Compagno» list (MODEL-02; D-03). | skipped (optional) | — | Not run. |
| 14 | MODEL-02 (optional) | BE D-28 | (optional) Pet as a quest prize. BE D-28: generated quests can now offer a pet linked to the quest's enemy or zone. If one is on the Board, open its sheet: the pet prize is shown as before (no FE code in this phase); if it is won, the pet appears among the owned companions with its lore in the Library (MODEL-02; BE D-28). | skipped (optional) | — | Not run: no pet prize seen on the device. |

Requirement ↔ step map: MODEL-01 (9, 10, 11), MODEL-02 (1, 2, 3, 7, 8), MODEL-03 (4, 5, 6), MODEL-04 (9 for the POI parsing on the real data, plus the gates of 19-10 / 19-12: schema gate and 46 × OK); steps 12, 13 and 14 optional. Not on the device, covered by tests: the lenient parsers and entry boundaries (19-01..19-03), the «hidden when empty» fallback of the attack / defense lines and the missing-`maxXp` case (19-05), the lenient `petXpGained` (19-06), the cap of the companion experience (BE rule: the row prints the served numbers).

## Device guide — one step at a time

The orchestrator reads one step per message. Each step: what to do, what to expect (copy verbatim), what to report back if it differs.

**Step 1 — Shop: pets and purchase**
- Do: in a city that sells pets (one of the seven above also has «Molosso da guerra»), open the Shop from the satchel and scroll the pets to buy. Then buy a cheap pet with both lines (a cat or a dog).
- Expect: under name and price, «Attacco: …» and «Difesa: …» (format «Attacco: tagliente 12, fuoco 5», «Difesa: contundente 4»); «Cavallo da viaggio», where sold, shows only «Difesa: …»; the speed line only on riding pets; each name in the colour of its rarity, as on the item cards. After the purchase the pet leaves the buy list and appears in the sell list.
- Report if different: a pet without «Difesa», a pet whose name has the wrong or no rarity colour, a missing «Molosso da guerra» in one of the seven cities, a purchase that fails or leaves the pet in the buy list. **Review item:** is the name of a COMMON pet readable as «coloured»? (the common colour is close to the normal ink) — say what you see.

**Step 2 — Library: the lore of the pet**
- Do: right after the purchase open the Library and the book that holds the pet's page.
- Expect: the page of the pet just bought, with the «Nuovo» bookmark.
- Report if different: no page, no «Nuovo» bookmark, or a page that needs an app restart to appear.

**Step 3 — Journal: «Compagno»**
- Do: open the Journal, the «Compagno» dropdown; look at the row, tap it, tap it again, then tap once more to leave the pet equipped.
- Expect: a parchment with the name in the rarity colour, «Attacco: …» and «Difesa: …» on it, and next to it «Esperienza: 0 / <maxXp>»; no life anywhere. Tap: the pet goes to the slot with the fade and the row shows «Al tuo fianco» above the experience line. Second tap: it leaves the slot.
- Report if different: a missing or different experience line, a life value shown, a spinner, a tap that does nothing. **Review item:** with a pet that has a long «Attacco: …» line (two or more damage types) the text shrinks to fit — is it still legible on the parchment? Say the pet and what you see.

**Step 4 — Journal: «Magie imparate», the single list**
- Do: with the character that has several known spells (8 known, 2 equipped at DB), open «Magie imparate»; unequip one spell and equip it again; then equip a spell that was learned BEFORE one already equipped.
- Expect: every known spell listed; the equipped ones in the slots with their usages and, for a spent use, the recovery countdown; fade, no spinner; the slots in LEARNING order (the order of the known list), the newly equipped spell taking its place in that order and not the last slot.
- Report if different: a known spell missing, slots in equip order, usages or countdown missing, a slot that jumps back after the server confirms.

**Step 5 — Journal: slots full**
- Do: with every slot taken, tap a known spell that is not equipped.
- Expect: the refusal of the full slots as before; nothing changes.
- Report if different: the spell replaces another one, a crash, no feedback at all.

**Step 6 — Mannequin: boots**
- Do: in the Journal equipment equip the boots, then unequip them; repeat with an item of another slot. On a character that wore boots before the migration, just open the mannequin first.
- Expect: the boots on the feet of the mannequin; after the unequip the slot is empty and the boots are back in the list; boots worn before the migration are still on the feet.
- Report if different: boots that do not appear on the feet, an error on equip, boots worn before the migration no longer shown.

**Step 7 — Fight with the companion**
- Do: companion equipped (step 3). In the city open the Board, accept the combat quest picked by the orchestrator (enemies totalling at least 10 xp) and wait for the result. **The outcome can arrive up to one sweep interval late** (the local Redis is not reachable, the periodic sweep resolves the quest): wait before reporting it missing.
- Expect: on a won fight, the character's «Esperienza: …» line and right under it «Il tuo compagno guadagna N PE» with N above 0 (10 % of the enemies' xp); back in the Journal the row reads «Esperienza: N / <maxXp>».
- Report if different: no companion line on a won fight (say the quest, so the enemies' xp can be checked), a line elsewhere on the sheet, a Journal row that did not grow by N, a defeat (no line is expected then: the step is repeated).

**Step 8 — Fight without the companion**
- Do: unequip the companion, accept and win another short combat quest (same sweep delay).
- Expect: no «Il tuo compagno guadagna» line; the row of the companion keeps the experience of step 7.
- Report if different: the line shown anyway, or the experience changed.

**Step 9 — Map untouched**
- Do: open the Map; look at city markers, quest pawns and the character pawn; open a city sheet and start a travel preview (do not confirm unless asked).
- Expect: everything where it was; the confirmation sheet shows the city image.
- Report if different: a missing marker or pawn, a city without image, anything that looks different from before the phase.

**Step 10 — Library: images**
- Do: open two or three lore pages with an image (a city, a creature, the new «Cavallo da viaggio» page if unlocked); open and close a book.
- Expect: the images load; the book opens and closes as before.
- Report if different: a page without its image (say which), a broken book animation.

**Step 11 — Result sheet: enemies**
- Do: on the result sheet of step 7 or 8 look at the enemies.
- Expect: portrait and name of each enemy as before.
- Report if different: a missing portrait or name.

**Step 12 (optional) — Innkeeper form**
- Do: only with the innkeeper account: open the completion form of a participant.
- Expect: the equipped spells of that character listed.
- Report if different: an empty list for a character with equipped spells.

**Step 13 (optional) — Sell the pet**
- Do: with the pet NOT equipped, sell it in the shop.
- Expect: it leaves the sell list and the Journal «Compagno» list.
- Report if different: the pet still listed in either place.

**Step 14 (optional) — Pet as a quest prize**
- Do: if a Board quest generated after the content pass offers a pet, open its sheet.
- Expect: the pet prize shown as before; if won, the pet among the owned companions with its lore in the Library.
- Report if different: a sheet that does not open or shows no prize.

## Review items for the device (from the code review and the plans)

- Legibility of a long «Attacco: …» line on the companion parchment: the text shrinks (review IN-08) — step 3.
- The ink of a common pet's name: the common rarity colour is close to the normal ink — steps 1 and 3.
- Provisional visuals to confirm: the experience as text under «Al tuo fianco» (no bar), attack / defense as two parchment labels and two shop row texts, rarity as the colour of the name like the item cards.

Outcome of the review items (user, step 1: «Sì ad entrambe le domande»): the «Attacco» / «Difesa» lines are legible and the common ink is distinguishable. Both stay points to keep an eye on (a long «Attacco» line shrinks; the common ink is close to the normal ink). The provisional visuals were not objected to.

## Findings and extra checks

Born during the run of 2026-11-11. They map to no MODEL requirement: F1 is closed by its own quick task, F2 by a content change at DB.

### Findings

- **F1 — enemy quests are single-player with a minimum rank (user rule, step 7).** User: «Non posso accettare né boss né enemy, il mio rango non va bene. Perché la enemy ha uno slot però? Le enemy non dovrebbero avere slot, possono essere prese solo dal giocatore e solo se il rango è adatto (più alto o uguale a quello richiesto)». Fixed during the UAT by the quick task `261111-enm` on both repos: BE branch `fix/enemy-quests-single-player` (commits `1ff1cbe1`, `d3daf25d`, `ea581880`), FE on this branch (`a29360bd`, `169daeda`, `73530a5f`; record in `.planning/quick/261111-enm-enemy-quests-single-player/`). The 155 open `enemy` quests were aligned at DB by the orchestrator (one rank-free seat). BE rebuilt and restarted from the fix branch, APK rebuilt and reinstalled; verified by checks B and C. `boss` keeps its rank-exact seats (unchanged, user choice).
- **F2 — pet pools too broad (user, step 1, content).** User: «Valantar non dovrebbe vendere tutti quei pet. Andrebbero contestualizzati…». New user rule, applied at DB by the orchestrator during the UAT: a village sells ONE pet, a city at most 2, a capital at most 3 and always at least one; «Cavallo leggero» only in the Valan; «Cavallo da viaggio» at Cliffbreak and Bellport; the camel only in one desert village; no cat at Ko Shaeras. 53 cities sell pets now (10 capitals, 12 cities, 31 villages). The pool described above in «State of the BE on this machine» («Molosso da guerra» in seven cities) is the state BEFORE this change.

### Extra checks

| Check | Origin | Expected | Result | Source | Note |
|-------|--------|----------|--------|--------|------|
| A | step 2 (innkeeper sees every lore) | With a non-innkeeper character the Library does not show every page; after buying a pet its lore page appears with «Nuovo». | pass | user | Character «gianni» (rookie, at Portonuovo; identity switched on the BE process by the orchestrator, 20 silver seeded): the Library did not show every page; bought «Gatto nero» → its page appeared with «Nuovo»; DB unlocked lore 13 → 14. |
| B | F1, quick 261111-enm | A «Minaccia» above the viewer's rank is drawn torn with «Titolo minimo: …» in red and no seat. | pass | user | gianni (rookie): the two «Minaccia» of Portonuovo (minimum title Avventuriero and Eroe) drawn torn, «Titolo minimo: …» in red, no seat drawn. |
| C | F1, quick 261111-enm | A «Minaccia» at or below the viewer's rank is whole and acceptable with no seat; a boss keeps its rank-exact seats. | pass (visual, not accepted) | user | Reavor (legend, at Valantar): «Minaccia: Cockatrice presso Valantar» (minimum title Recluta) whole and acceptable, no seat drawn; «Boss: Troll» still not acceptable (rank-exact seats, unchanged). |

### Fixes made during the UAT (branch `feat/19-model-review`)

| Commit | Subject | Origin |
|--------|---------|--------|
| `a29360bd` | test(quick-261111-enm): pin single-player enemy quests by minimum rank | F1 |
| `169daeda` | fix(quick-261111-enm): judge enemy quests with one rank-free seat | F1 |
| `73530a5f` | docs(quick-261111-enm): record single-player enemy quests | F1 |

Gates after the fixes (orchestrator, last full run after the quick task): full FE suite `+4239 All tests passed!` (4216 + 23), analyzer 47 info / 0 warning / 0 error, `hardening_check` OK.

### Open notes (not blockers)

- The three unregistered flags of the security audit (UF-19-01..03, `19-SECURITY.md`) are accepted as they are.
- Device look to keep an eye on: long «Attacco» lines shrink; the common ink is close to the normal ink — the user found both fine.
- The innkeeper's «every lore» makes step 2 inconclusive on Reavor; covered by check A.
- Reavor carries two more injuries from this UAT (`missingLeftHand`, `brokenRightLeg`).
- Pets as quest prizes (step 14) were not seen on the device.
- The abandon button of the map sheet may flash next to «In combattimento…» for a solo quest (pre-existing).

## Verdict

**complete** — steps 1–11 pass, optional 12–14 skipped; approved by the user step by step («pass» on every step). Requirements by the map: MODEL-01 (9, 10, 11), MODEL-02 (1, 2, 3, 7, 8), MODEL-03 (4, 5, 6), MODEL-04 (9 + the gates of 19-10 / 19-12) — all mandatory steps pass, MODEL-01..04 complete. Step 7 passed on the second attempt (the first fight was lost, and a defeat pays nothing to the companion, as the BE rules say); step 2 is completed by check A. Findings F1 and F2 were fixed during the UAT; the open notes above are not gaps.
