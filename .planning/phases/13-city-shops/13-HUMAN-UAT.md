---
status: complete
phase: 13-city-shops
device: Android (USB, adb reverse tcp:3000)
be_ref: 0585b2e
date: 2026-11-03
completed: 2026-11-03
verdict: steps 1–10 pass (10 optional, run), step 11 skipped; step 4 failed on the first build and passed after D-17
---

# Phase 13 — Device E2E (city shops)

App on the Android phone against the local BE from `develop` (`0585b2e`, merge of PR #18 `feat/12-negozi-per-citta`, BE Phase 12 merged) with the data of plan 13-11 `user_setup`. Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "cityShop"` → `3`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 12 merged running locally (the pools, `Pet.sellable` and `ownedPets` were already written on the real DB on 2026-11-03 from the BE branch, BE D-25; the boot only logs the WARN report); Samsung via USB with `adb reverse tcp:3000 tcp:3000`; the device account is innkeeper (Locanda teleport); the test character has ≥ 2 oro (DB seed by the user, placeholders only, never printed).

### Actual setup (2026-11-03)

- BE built from `develop` `0585b2e` (same code as the merged PR #18), run from `dist/` on port **3001** because port 3000 of the Mac was taken by a dev server of another project; tunnel `adb reverse tcp:3000 tcp:3001` (the phone still talks to `localhost:3000`). Redis **not** running locally: travel jobs do not close (step 11 skipped for this reason).
- Samsung SM-S938B (Android 16) over USB, debug build. Device account = innkeeper. Initial wallet of the test character: 98 oro 88 ag 9 ra.
- The test character was moved between the city markers by the orchestrator with a DB script writing the same `$set` as the BE `teleportCharacter` service (`status.location` = the city's POI marker, `status.activeTravel` null), because the mutation path was not available in the session.
- Before step 1 the Cavallo da viaggio already equipped by the BE D-16 migration (`OwnedPetsMigrator`) was removed at DB from `assets.pet` and `assets.ownedPets`, so that step 3 could run as written (backup kept outside the repo). The research C2 case (migrated horse shown in the slot at the first open) was therefore not observed.
- The app was reinstalled once during the run (after the D-17 fix, see step 4). No ids of real users, no character id, no URI, no secret in this file.

From the BE Phase 12 handoff (`.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md` on BE `origin/develop`, §9): a city's pool lives in the three fields `shopEquipment`, `shopLoot`, `shopPets` of the city document (catalogue ids); a curation is served at the next shop open, without a restart. Step 10 removes an item from one of those fields. §7 of the same handoff lists the four sellable companions and the cities that sell them.

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; airplane mode does not simulate offline.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | SHOP-02 | — | Cold start → the satchel opens; on a city marker with a shop the Shop cell is enabled (SHOP-02). | pass | Cold start on the Talmvere marker, Shop cell enabled. User: «pass» (steps 1–4 reported together after the D-17 rebuild). |
| 2 | SHOP-02, SHOP-04 | D-02 | Teleport to a **village** (Talmvere, `talmvereVillage`) → open the shop → only common/uncommon items, «Compagni» shows Cavallo da viaggio with price and «Velocità ×2»; no city name anywhere (SHOP-02, D-02, SHOP-04). | pass | Talmvere pool (village): common/uncommon only, Cavallo da viaggio under «Compagni» with price and «Velocità ×2», no city name. User: «pass». |
| 3 | SHOP-04 | D-08 | Buy the Cavallo da viaggio → bubble success; the Journal «Compagno» slot stays empty (buying never equips, D-08); the buy list no longer shows it (D-08). | pass | Purchase confirmed at DB by the orchestrator: oro 98 → 97, `ownedPets` = [Cavallo da viaggio], `pet` null. User's first words: «La sezione compagno non mostra il cavallo dopo l'acquisto» — expected (D-08, buying never equips). User: «pass». |
| 4 | SHOP-04 | D-10, D-11, D-17 | Journal → tap «Compagno» → the owned list shows Cavallo da viaggio → tap → slot shows it immediately (optimistic) and stays after the subscription (SHOP-04). | pass (after D-17) | **Failed on the first build:** the tap on the «Compagno» slot did not open the owned sheet on the device. User: «La sezione compagno non è apribile. Tutto ok?», then the product rule, verbatim: «Ma che scelta di merda che hai fatto. Ma fai una roba in stile sezione Magie Imparate. Dropdown, con lista dentro le pergamene e che si possono cliccare per equipaggiare il pet in uno slot» → recorded as D-17 in `13-CONTEXT.md` and fixed in TDD on the branch during the UAT (`8ac0ede` test, `e26c72a` feat, `6cda912` docs); app reinstalled.<br>**Pass after D-17:** step redone with the dropdown — the horse's parchment card tapped → in the slot, red bookmark and «Al tuo fianco», kept after the subscription. User: «pass» (steps 1–4). |
| 5 | SHOP-02 | D-01, D-03 | Teleport to a **city** (e.g. a `*City` of the same region) → different pool, up to rare, no legendary (SHOP-02). | pass | Blu Minore (`drusteaSeaCity`, size `city`): a different pool, up to rare, no legendary. User: «pass». |
| 6 | SHOP-02, SHOP-04 | D-01, D-07 | Teleport to a **capital** (Valantar) → different pool incl. ultrarare, no legendary; «Compagni» lists Cavallo leggero and Cammello (SHOP-02/04). | pass | Valantar (capital): a different pool incl. ultrarare, no legendary; «Compagni» with Cavallo leggero and Cammello. User: «pass su tutti i punti» (steps 6–8). |
| 7 | SHOP-03, SHOP-04 | D-08, D-14 | In Valantar sell the Cavallo da viaggio (marked equipped in the sell sheet) with a wallet below 50 ag if possible (Pitfall 4) → success; the Journal slot empties through the subscription (D-08). | pass | Horse marked «Al tuo fianco» in the sell sheet, sold (+50 ag); the Journal slot emptied through the subscription; DB after: `pet` null, `ownedPets` []. The «wallet below 50 ag» condition was not available (wallet at 88 ag), so the D-14 net-positive case with a short wallet was not exercised on the device (covered by the 13-07 widget test). User: «pass su tutti i punti». |
| 8 | SHOP-03 | D-09 | Sell an owned legendary item, if the character has one (D-09; otherwise record «not available»). | pass | One owned legendary item sold in Valantar. Wallet at DB after steps 6–8: 102 oro 63 ag 9 ra. User: «pass su tutti i punti». |
| 9 | SHOP-02 | D-04 | Teleport to **Necrorian** → the Shop cell is disabled, the Board cell is not (D-04). | pass | Necrorian: Shop cell disabled, Board cell enabled. User: «pass». |
| 10 | SHOP-03 | D-03, D-05 | (optional) Optional `ITEM_NOT_IN_SHOP`: with the shop page open, the user removes a listed item from that city's pool in the DB (field name from the BE handoff), then buys it → bubble «Questa merce non la tratto», the row disappears after the reload (SHOP-03). | pass (optional, run) | With the Talmvere shop page open the orchestrator removed «Cuffia imbottita» (common) from `shopEquipment` at DB (10 → 9); the user tried to buy it: bubble «Questa merce non la tratto», the row gone after the reload, wallet unchanged at DB. Item put back in the pool right after. User: «pass». |
| 11 | SHOP-04 | D-10 | (optional) Optional: equip / unequip during a travel works (D-10). | skipped | Reason recorded: «Redis non in esecuzione in locale: un viaggio avviato non si chiuderebbe». Interaction during a travel stays covered by the 13-09 widget test (no travel gate on the section). |

Requirement ↔ step map: SHOP-02 (1, 2, 5, 6, 9), SHOP-03 (7, 8, 10), SHOP-04 (2, 3, 4, 6, 7). Tick a requirement only when all its mandatory steps pass.

(Note for the user, research C2: a character that already rides the Cavallo da viaggio — BE D-16 migration — shows it in the slot for the first time. The marked-equipped label in the sell sheet reads «Al tuo fianco».)

## Verdict

Steps 1–9 pass, optional step 10 pass, optional step 11 skipped → `status: complete` (2026-11-03).

- **SHOP-02** — steps 1, 2, 5, 6 and 9: all pass → complete.
- **SHOP-03** — steps 7, 8 and 10: all pass (step 10 run, so the device proof of `ITEM_NOT_IN_SHOP` is real, not only the unit/widget coverage of 13-03 / 13-05) → complete.
- **SHOP-04** — steps 2, 3, 4, 6 and 7: all pass (step 4 after D-17) → complete.

## Not observed

- Step 4, first build: the pre-D-17 bottom sheet of the owned companions never opened on the device; the behaviour was replaced, not debugged.
- Step 7: the «wallet below 50 ag» condition of D-14 (wallet at 88 ag).
- Step 11: equip / unequip during a travel (no Redis locally).
- Research C2: the migrated horse shown in the slot at the first open (removed at DB before step 1 on purpose).
- Review-fix note WR-02 of `13-REVIEW-FIX.md` (a pet bought or sold while still in a selection, lost response or second device): not reported in this run.

## Fix during the UAT (D-17)

TDD on `feat/13-city-shops`, between the Task 1 gate of 13-10 and this record:

| Commits | User rule implemented |
|---------|-----------------------|
| `8ac0ede` (test) + `e26c72a` (feat) + `6cda912` (docs) | «Compagno» section as a `Dropdown` like «Magie imparate»: `CompanionSlot` on top, owned companions as `CompanionCard` parchment cards in `OwnedCompanionRow` (red bookmark and «Al tuo fianco» on the one in the slot); a tap equips, a tap on the one in the slot unequips, a tap during a pending operation does nothing; `CardLabel` extracted from `SpellCard`, `PaperSheetModal` out of the Journal (D-17) |

Gates after the fix (run by plan 13-11, 2026-11-03): full `flutter test` 3031 passed in 72 s; `flutter analyze` 50 issues / 0 error / 0 warning (`ANALYZE_GATE_OK`); `flutter test test/screens/mainScreen/tabs/journal test/shared/components/cards` 185 passed; trailers 0 over 79 commits of the branch.

## Session notes

- BE log during the UAT: no ERROR/WARN from the app traffic. Five `INTERNAL_SERVER_ERROR` lines came from GraphQL reads run by the orchestrator (not by the app) and reveal a latent BE defect: under `me.currentCharacter` the nested refs are not populated (`status.location.id`, `assets.pet.id` and, through `character(id)`, `status.location.city.id` come out as a Buffer object, «ID cannot represent value»; `status.location.location` is null). No impact on the app, which selects only `currentCharacter { id }` and reads the character through `character(id)` / `characterUpdated`. Routed to the BE in `BACKEND-NOTES.md` §5.
- UAT data: one innkeeper account, one test character moved between Talmvere, Blu Minore, Valantar and Necrorian; one common item removed from and restored to the Talmvere `shopEquipment`; the migrated horse removed before step 1 (backup outside the repo). No ids, no secrets.
