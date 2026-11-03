---
status: in-progress
phase: 13-city-shops
device: Android (USB, adb reverse tcp:3000)
be_ref: 0585b2e
date: 2026-11-03
---

# Phase 13 — Device E2E (city shops)

App on the Android phone against the local BE from `develop` (`0585b2e`, merge of PR #18 `feat/12-negozi-per-citta`, BE Phase 12 merged) with the data of plan 13-11 `user_setup`. Gate re-checked before this file was written: `git -C <BE> show origin/develop:src/schema.gql | grep -c "cityShop"` → `3`. Results are recorded only from the tester's words; notes carry no ids of real users, no tokens, no Mongo URIs.

## Setup

Setup: BE `develop` with Phase 12 merged running locally (the pools, `Pet.sellable` and `ownedPets` were already written on the real DB on 2026-11-03 from the BE branch, BE D-25; the boot only logs the WARN report); Samsung via USB with `adb reverse tcp:3000 tcp:3000`; the device account is innkeeper (Locanda teleport); the test character has ≥ 2 oro (DB seed by the user, placeholders only, never printed).

From the BE Phase 12 handoff (`.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md` on BE `origin/develop`, §9): a city's pool lives in the three fields `shopEquipment`, `shopLoot`, `shopPets` of the city document (catalogue ids); a curation is served at the next shop open, without a restart. Step 10 removes an item from one of those fields. §7 of the same handoff lists the four sellable companions and the cities that sell them.

Device notes (user memory): `flutter run` may lose the device in background (relaunch from the phone); the «bad base-64» secure-storage log is benign; airplane mode does not simulate offline.

## Steps

| Step | Requirements | Decisions | Expected | Result | Note |
|------|--------------|-----------|----------|--------|------|
| 1 | SHOP-02 | — | Cold start → the satchel opens; on a city marker with a shop the Shop cell is enabled (SHOP-02). | | |
| 2 | SHOP-02, SHOP-04 | D-02 | Teleport to a **village** (Talmvere, `talmvereVillage`) → open the shop → only common/uncommon items, «Compagni» shows Cavallo da viaggio with price and «Velocità ×2»; no city name anywhere (SHOP-02, D-02, SHOP-04). | | |
| 3 | SHOP-04 | D-08 | Buy the Cavallo da viaggio → bubble success; the Journal «Compagno» slot stays empty (buying never equips, D-08); the buy list no longer shows it (D-08). | | |
| 4 | SHOP-04 | D-10, D-11 | Journal → tap «Compagno» → the owned list shows Cavallo da viaggio → tap → slot shows it immediately (optimistic) and stays after the subscription (SHOP-04). | | |
| 5 | SHOP-02 | D-01, D-03 | Teleport to a **city** (e.g. a `*City` of the same region) → different pool, up to rare, no legendary (SHOP-02). | | |
| 6 | SHOP-02, SHOP-04 | D-01, D-07 | Teleport to a **capital** (Valantar) → different pool incl. ultrarare, no legendary; «Compagni» lists Cavallo leggero and Cammello (SHOP-02/04). | | |
| 7 | SHOP-03, SHOP-04 | D-08, D-14 | In Valantar sell the Cavallo da viaggio (marked equipped in the sell sheet) with a wallet below 50 ag if possible (Pitfall 4) → success; the Journal slot empties through the subscription (D-08). | | |
| 8 | SHOP-03 | D-09 | Sell an owned legendary item, if the character has one (D-09; otherwise record «not available»). | | |
| 9 | SHOP-02 | D-04 | Teleport to **Necrorian** → the Shop cell is disabled, the Board cell is not (D-04). | | |
| 10 | SHOP-03 | D-03, D-05 | (optional) Optional `ITEM_NOT_IN_SHOP`: with the shop page open, the user removes a listed item from that city's pool in the DB (field name from the BE handoff), then buys it → bubble «Questa merce non la tratto», the row disappears after the reload (SHOP-03). | | |
| 11 | SHOP-04 | D-10 | (optional) Optional: equip / unequip during a travel works (D-10). | | |

Requirement ↔ step map: SHOP-02 (1, 2, 5, 6, 9), SHOP-03 (7, 8, 10), SHOP-04 (2, 3, 4, 6, 7). Tick a requirement only when all its mandatory steps pass.

(Note for the user, research C2: a character that already rides the Cavallo da viaggio — BE D-16 migration — shows it in the slot for the first time. The marked-equipped label in the sell sheet reads «Al tuo fianco».)
