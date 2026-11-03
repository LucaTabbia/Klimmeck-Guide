# Phase 13 (FE) — Backend notes

- **FE phase:** 13-city-shops (SHOP-02, SHOP-03, SHOP-04 as amended on 2026-11-02; decisions D-01..D-17 in `13-CONTEXT.md`).
- **Date:** 2026-11-03 — written by plan 13-11 after the device E2E against the merged BE Phase 12 (BE `develop` `0585b2e`, merge of PR #18 `feat/12-negozi-per-citta`). **Status: outcome.** The contract is the one of `src/schema.gql` on BE `develop`; this document records what the FE consumes, how it behaves and what the device run showed. Nothing is requested from the BE: the merged names matched the FE assumptions (A1/A2/A3 confirmed in 13-10, 43/43 documents OK).
- **Source of the consumed contract:** BE `.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md` §1–§7 on BE `origin/develop`.
- **Literals rule:** Mongo operators and GraphQL literals only in code spans or code blocks; no URI, host, database name nor real id of the database — placeholders only (`<character id>`, `<pet id>`, `<city id>`).

---

## 0. TL;DR for the BE

1. **Consumed as merged:** `cities { size hasShop }`, `cityShop(cityId)`, the character fragment with `assets.pet` / `assets.ownedPets`, `doTransaction` with `petAssets`, `equipPet` / `unequipPet`, the codes `ITEM_NOT_IN_SHOP` / `PET_ALREADY_OWNED` / `PET_NOT_OWNED`. The two global catalogue queries are no longer selected by the FE (§1).
2. **Device E2E 2026-11-03, all pass:** three pools by size (village / city / capital, no legendary), a companion bought in Talmvere, equipped in the Journal, sold in Valantar with `assets.pet` emptied in the same event, Necrorian with the Shop cell closed, `ITEM_NOT_IN_SHOP` after a live DB curation (§4).
3. **One latent BE defect seen from the orchestrator's GraphQL reads, not from the app:** nested refs under `me.currentCharacter` are not populated (§5.1). No impact on the app.
4. **Questions** on `hasShop` liveness, the removal of the deprecated queries, the idempotence of `equipPet` and `City.size` for the markers (§5).

---

## 1. Contract consumed by the FE

Documents registered in the FE schema check (43 documents, all OK on `0585b2e`); fragments by name, selections as in `lib/graphql/`:

```graphql
query cities {
  cities { id type name size hasShop markerLocation { ...LocationFields } relatedLore { id description image } }
}

query GetCityShop($cityId: ID!) {
  cityShop(cityId: $cityId) {
    city { id }                                   # only the id: no city name on the sheets (D-02)
    equipment { quantity item { ... on EquipmentItem { ...EquipmentFields } } }
    loot      { quantity item { ... on LootItem      { ...LootFields } } }
    pets      { ...PetFields }
  }
}

# PetFields = `PetFragment.fields`: never imagePath (D-11, D-13)
id name speedModifier sellable buyPrice { ...Coins } sellPrice { ...Coins }

# character fragment (query character(id) and subscription characterUpdated)
assets { … pet { ...PetFields } ownedPets { ...PetFields } }

mutation EquipPet($request: EquipPetRequest!)     { equipPet(request: $request)   { response successful } }
mutation UnequipPet($request: UnequipPetRequest!) { unequipPet(request: $request) { response successful } }
# variables: { request: { id: "<character id>", petId: "<pet id>" } } and { request: { id: "<character id>" } }

mutation doTransaction($request: TransactionRequest!) { doTransaction(request: $request) { response successful } }
# TransactionItems on both sides: equipAssets, lootAssets, petAssets: [{ item: "<pet id>", quantity: 1 }] (one entry per companion)
```

Facts the FE relies on:

- `User` is read through `UserFragment` with `currentCharacter { id }` only; the character comes from `character(id)` and `characterUpdated` (both populate `status.location` and `assets.pet`, see §5.1).
- `City.size` is parsed (`village | city | capital`, unknown value → null) but not used for rendering: the marker sizes still come from the FE `CityType.cityClass` map (CONTEXT D-04, deferred idea in §5.4). `City.hasShop` defaults to `true` when absent from a JSON (D-15); on the wire it is non-null.
- `equipPet` / `unequipPet` are sent through the shared `_successfulMutation` helper (same path as `equipSpell` / `unequipSpell`): a `successful: false` answer is a declined outcome, a coded error is classified (§2).
- **No longer used by the FE:** `equipmentAssetsQuantity(sellable:)` and `lootAssetsQuantity` (FE D-01 / D-15: documents and service methods removed, 45 → 43 registered documents). The BE may remove them under its D-20 once no released app selects them: this FE release is the trigger.

---

## 2. Error codes read

The FE reads `extensions.code` only, never the message.

| Operation | Code | FE behaviour |
| --- | --- | --- |
| `doTransaction` | `ITEM_NOT_IN_SHOP` | shopkeeper bubble «Questa merce non la tratto», then the pool is reloaded (D-05, D-03) |
| `doTransaction` | `PET_ALREADY_OWNED` | shopkeeper bubble «Hai già questo compagno» (D-06, D-08) |
| `doTransaction` | `PET_NOT_OWNED` | shopkeeper bubble (D-06) |
| `doTransaction` | `SHOP_NOT_IN_CITY`, `AWAITING_AID` | in-app banner (Phase 9 D-16: the only transaction refusals that are banners) |
| `doTransaction` | other codes (`INSUFFICIENT_FUNDS`, `TRANSACTION_TOTAL_MISMATCH`, `INSUFFICIENT_ITEM_QUANTITY`, …) | shopkeeper bubble as in Phases 8/9 |
| `equipPet` / `unequipPet` | `PET_NOT_OWNED`, `NOT_FOUND` | stale view: silent re-read of the character, optimistic overlay rolled back, no banner (D-06) |
| `equipPet` / `unequipPet` | `FORBIDDEN`, `BAD_USER_INPUT`, connection error, 15 s timeout | Journal in-app banner through the outcome listener (Phase 8 pattern), overlay rolled back |
| `equipPet` / `unequipPet` | `UNAUTHENTICATED` | session flow (refresh / re-login), no banner |

---

## 3. FE behaviour the BE should know

1. **Pool reload.** `cityShop(cityId)` is called every time the shop page opens (the off-screen tab is disposed), whenever `status.location.id` changes while the page is shown, and after an `ITEM_NOT_IN_SHOP` refusal; responses are last-request-wins (an out-of-order answer is dropped). No cache across cities.
2. **`hasShop` from the cold-start snapshot.** The Shop cell is disabled from the `cities` loaded at cold start: a pool emptied in the DB mid-session keeps the cell enabled and shows an empty shop until the next cold start (and every purchase there is refused by the BE). See §5.2.
3. **Buying never equips** (D-08): the shop never calls `equipPet`; pets already in `ownedPets` are hidden from the buy list, the BE guard `PET_ALREADY_OWNED` stays the authority.
4. **Net-positive sales are signable with any wallet** (D-14): the FE checks the wallet only when the net total is a cost; funds are checked by the BE (`INSUFFICIENT_FUNDS`).
5. **Journal «Compagno» section** (D-10, D-17): a dropdown with the equipped companion in a slot on top and the owned ones as cards below; a tap on a card sends `equipPet`, a tap on the one in the slot (card or slot) sends `unequipPet`; one operation in flight, a tap during a pending operation does nothing; the optimistic overlay is settled only by `characterUpdated` (15 s timeout → rollback + banner). The FE never sends `equipPet` for the pet already in the slot.
6. **Interactive during a travel** (BE D-15): no FE gate on the section; not exercised on the device (step 11 skipped, §4).
7. **Sell sheet:** every owned item including legendary ones (D-09), the equipped companion marked «Al tuo fianco»; no FE filter on `sellable`.
8. **Travel speed** is never computed by the FE: `speedModifier` is printed as served («Velocità ×2», «×2,5»; nothing for a non-mount).

---

## 4. E2E outcome (FE Phase 13, 2026-11-03)

Device E2E on Android (Samsung SM-S938B, Android 16, USB, debug build) against the BE built from `develop` `0585b2e` and run from `dist/` on port 3001 (port 3000 of the Mac was taken by another project; `adb reverse tcp:3000 tcp:3001`). Redis not running locally. Device account = innkeeper. The test character was moved between the city markers by a DB script writing the same `$set` as the BE `teleportCharacter` service (`status.location` = POI marker, `status.activeTravel` null) because the mutation path was not available in the session. Before step 1 the Cavallo da viaggio pre-equipped by the BE D-16 migration (`OwnedPetsMigrator`) was removed at DB from `assets.pet` and `assets.ownedPets` so that the purchase step could run as written (backup outside the repo). Initial wallet 98 oro 88 ag 9 ra. Full record: `13-HUMAN-UAT.md` (steps 1–10 pass, 11 skipped).

### 4.1 Step outcomes relevant to the BE

- **Pools per size (A2 / BE D-01):** Talmvere (`talmvereVillage`) → common/uncommon only, «Compagni» = Cavallo da viaggio with «Velocità ×2»; Blu Minore (`drusteaSeaCity`, size `city`) → a different pool up to rare; Valantar (`valanCapital`) → a different pool incl. ultrarare, «Compagni» = Cavallo leggero and Cammello. No legendary item in any pool; the four pools served matched BE §7. User: «pass», «pass su tutti i punti».
- **Purchase of a companion:** Cavallo da viaggio bought in Talmvere → at DB oro 98 → 97, `ownedPets` = [Cavallo da viaggio], `pet` null — buying never equips, as agreed. User's first words: «La sezione compagno non mostra il cavallo dopo l'acquisto» (expected, D-08).
- **`equipPet`:** the horse's card tapped in the Journal dropdown (after D-17, §4.3) → in the slot at once and kept after `characterUpdated`.
- **Sale of the equipped companion + a legendary item:** in Valantar the horse (marked «Al tuo fianco») sold for +50 ag and one owned legendary item sold → at DB `pet` null, `ownedPets` [], wallet 102 oro 63 ag 9 ra; the Journal slot emptied through the subscription, confirming that the BE empties `assets.pet` in the same transaction and one event. The «wallet below 50 ag» condition of D-14 was not available (88 ag).
- **Necrorian:** Shop cell disabled, Board cell enabled (`hasShop: false`).
- **`ITEM_NOT_IN_SHOP` (optional step, run):** with the Talmvere shop page open, «Cuffia imbottita» (common) removed from the city's `shopEquipment` at DB (10 → 9); purchase attempted → bubble «Questa merce non la tratto», row gone after the reload, wallet unchanged at DB. Item put back right after. The curation was served at the next open without a restart (BE §9c confirmed).
- **Not run:** equip / unequip during a travel (step 11): Redis not running locally, a started travel would not close.

### 4.2 BE log during the UAT

No ERROR/WARN from the app traffic. Five `INTERNAL_SERVER_ERROR` lines came from GraphQL reads run by the orchestrator (not by the app): §5.1.

### 4.3 FE rule changed during the UAT (D-17, no contract change)

Step 4 failed on the first build: the tap on the «Compagno» slot did not open the owned sheet on the device. User (verbatim): «Ma che scelta di merda che hai fatto. Ma fai una roba in stile sezione Magie Imparate. Dropdown, con lista dentro le pergamene e che si possono cliccare per equipaggiare il pet in uno slot» → D-17, fixed in TDD on the branch (`8ac0ede` test, `e26c72a` feat, `6cda912` docs). The same `equipPet` / `unequipPet` calls; only the Journal widget changed.

### 4.4 UAT data actually used

One innkeeper account on the device; one test character moved between Talmvere, Blu Minore, Valantar and Necrorian (DB script replicating the teleport write); the migrated Cavallo da viaggio removed before step 1 (backup out of the repo); one common item removed from and restored to the Talmvere `shopEquipment`. No ids of real users, no character id, no secrets recorded here.

---

## 5. Questions for the BE

### 5.1 Latent defect: nested refs not populated under `me.currentCharacter`

Observed from the orchestrator's GraphQL reads during the UAT (the five `INTERNAL_SERVER_ERROR` lines of §4.2): selecting `me { currentCharacter { status { location { id } } assets { pet { id } } } }` returns `status.location.id` and `assets.pet.id` as a Buffer object (`{ type: "Buffer" }`, GraphQL error «ID cannot represent value») and `status.location.location` as null; through `character(id)` the same shape appears on `status.location.city.id`. **No impact on the app:** the FE selects only `currentCharacter { id }` (`lib/graphql/fragments/user_fragment.dart`) and reads the character from `character(id)` / `characterUpdated`, which populate `status.location` and `assets.pet`. Worth a populate (or an `id` resolver that serialises an unpopulated ref) on the `User.currentCharacter` path and on `PointOfInterest.city`; related to the «list queries on unpopulated ids» note of the FE Phase 10 handoff §6.4 and to BE Phase 12 §13 C-IN-02.

### 5.2 Should `City.hasShop` changes reach the client live?

Today the FE reads `hasShop` from the cold-start `cities` snapshot (§3.2): a pool emptied or filled by hand mid-session is seen only at the next cold start. Is a live path wanted (a `cities` re-emit or a subscription), or is the cold start enough for a DB-curated rule? The FE does not depend on it.

### 5.3 Removal timeline of `equipmentAssetsQuantity` / `lootAssetsQuantity`

The FE no longer selects them from this release (§1). When does the BE plan to remove the two deprecated queries (BE D-20)?

### 5.4 `equipPet` on the already-equipped pet

BE §5 states that `equipPet` re-sent on the same pet is an idempotent success. The FE never sends it (a tap on the pet in the slot unequips), so nothing depends on it — is the idempotence meant to stay part of the contract?

### 5.5 `City.size` for the marker rendering

Any plan to let the FE drop its `CityType.cityClass` map (which draws Ferrion as a capital while the BE says `city`) in favour of `City.size` everywhere? Deferred FE idea (CONTEXT §Deferred), no action needed now.

Da riportare nella UAT della BE Phase 12 a cura del lato BE (questo repo non modifica il BE).
