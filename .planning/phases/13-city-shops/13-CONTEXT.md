# Phase 13: City Shops - Context

**Gathered:** 2026-11-02 (interactive discuss held together with the BE Phase 12 discuss, same session; branch `feat/13-city-shops` from `develop` `b6eb4d4`)
**Status:** Ready for planning (**no UI phase**, same rule as Phases 4, 6–10: every visual Claude builds is provisional). The plans that select the BE Phase 12 contract (`cityShop`, `City.size` / `City.hasShop`, `assets.ownedPets`, `petAssets`, `equipPet` / `unequipPet`) and the device E2E run after the BE Phase 12 PR merges on BE `develop` (gate pattern 08-12 / 09-12 / 10-11); the model, classifier and widget work can start on stubs now.

<domain>
## Phase Boundary

The shop a player opens on a city marker lists only **that city's pool** as served by the backend (BE Phase 12): equipment, loot and **companions** (pets), with the city size, the pool and every refusal owned by the server. The frontend adapts the existing shop to the new contract — user: «Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma» — and adds the two things the pets require: a third list «Compagni» in the buy/sell sheets and a «Compagno» slot in the Journal equipment section that equips one of the **owned** pets (`assets.ownedPets`, new) into the **equipped** slot (`assets.pet`, the one the travel speed already uses). Selling stays possible in every city, stock is infinite, prices are the catalogue's; the frontend never filters by rarity, size or price itself.

Out of scope: any pool curation UI (the user curates the pools in the database), pet rewards from quests (BE Phase 13 / FE Phase 14 to decide), pet growth or combat, a companion portrait on the Profile, new Cloudinary assets, iOS.

</domain>

<decisions>
## Implementation Decisions

### The shop call (SHOP-02)
- **D-01 (user decision, verbatim: «Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma»):** `ShopCubit.getData` calls the BE Phase 12 query `cityShop(cityId)` for the city whose marker the character stands on, instead of `equipmentAssetsQuantity(sellable: true)` + `lootAssetsQuantity`. The response carries `equipment` and `loot` as `AssetQuantity` lists (same model, same `ShopModal`, same filters of Phase 8 D-23) plus `pets: [Pet]`; the two global catalogue queries leave the FE (the BE deprecates them). The city id comes from the cities loaded at cold start (`isOnCityMarker` already matches `status.location` to a `City.markerLocation`).
- **D-02 (user decision — «Sì, ma senza il nome della città»):** **no visual change** for the city: no sign on the shop page, no title with the city name on the sheets. ROADMAP SC1 «the shop sheet names the city» is dropped.
- **D-03 (technical default):** the pool is refetched **every time the shop opens** and whenever the character's city changes while the page is alive (the `Shop` page is a `PageView` child that stays mounted: today `getData` runs once in `initState`); no cache across cities; the loading state stays the existing one (explicit user action, rule 2 holds).
- **D-04 (user decision — Necrorian has no shop, «pagina chiusa come fuori città»):** when the marker's city has `City.hasShop == false` (BE D-04: pool empty, Necrorian by rule, any city the user empties by hand) the Shop satchel cell is **disabled exactly like off-city / travel / awaiting aid** (`disabledSatchelPages` gets the city flag; Phase 7 D-12, Phase 9 D-16). `City.hasShop` and `City.size` join the `cities` query and the `City` model; the FE never derives the size itself (the existing `CityType.cityClass` map stays only for marker rendering — it classifies Ferrion as a capital while the BE says city).

### Refusals (SHOP-03)
- **D-05 (user decision):** `ITEM_NOT_IN_SHOP` (an item outside the pool, a legendary or a `sellable: false` item slipped into a purchase — a race after a DB curation) goes to the **shopkeeper bubble** like every transaction refusal except `SHOP_NOT_IN_CITY` (Phase 9 D-16: only the off-city refusal is a banner). ROADMAP SC2 «mapped on the in-app banner» is amended. After the refusal the shop reloads the pool (D-03) so the stale row disappears.
- **D-06 (technical default):** `transaction_failure.dart` gains `itemNotInShop`, `petAlreadyOwned`, `petNotOwned`; `equipPet` / `unequipPet` get their own classifier (`pet_equip_failure.dart`, same shape as `spell_equip_failure.dart`) mapping `PET_NOT_OWNED`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`, connection. Bubble copy is Claude's discretion («Questa merce non la tratto», «Hai già questo compagno»).

### Companions in the shop (SHOP-04)
- **D-07 (user decision — «Terza lista nello stesso foglio»):** the buy sheet shows, under equipment and loot, a section **«Compagni»** with the pets of the city pool: name, buy price, speed only when `speedModifier != null` (a cat or a dog is a companion, not a mount); the sell sheet shows the **owned** pets (`assets.ownedPets`) with the equipped one marked. Selection and confirmation flow unchanged (`TransactionModal` totals include the pets; `TransactionItems.petAssets` with quantity 1 on both sides).
- **D-08 (user decision — «niente sella automatica», «lo stesso pet non si compra due volte»):** buying never equips; the buy list hides the pets already owned (the BE still refuses duplicates with `PET_ALREADY_OWNED`, mapped to the bubble). Selling an owned pet removes it; if it was the equipped one the BE empties `assets.pet` in the same transaction and the Journal slot follows through the subscription.
- **D-09 (user decision — legendary items can be sold):** the sell sheet keeps listing every owned item including legendary ones; no FE filter on `sellable`.

### «Compagno» slot in the Journal (SHOP-04)
- **D-10 (user decision, verbatim: «Bisogna distinguere il pet equipaggiato dai pet posseduti»; title: «il pet non essendo necessariamente un animale da sella (può essere un gatto o un cane) deve avere un titolo diverso, cavalcatura non va bene» → «Compagno»):** the Journal equipment section gets a **«Compagno» slot** next to the equipment slots: it shows the equipped pet (`assets.pet`, name and speed if any, empty state when none); tapping it opens the list of the **owned** pets; tapping a pet calls `equipPet`, tapping the equipped one calls `unequipPet` (Phase 8 spells pattern: optimistic overlay with rollback on refusal, FIFO of the mutations). The slot is read-only during a travel? **No** — the BE allows equipping during a travel without effect on the current travel (BE D-15), so the slot stays interactive everywhere the Journal is readable.
- **D-11 (technical default):** the owned list and the equipped pet come only from the `Character` subscription (`assets { pet { … } ownedPets { … } }` added to the character fragment); the FE never computes the speed, it only prints `speedModifier` as served.

### Backend prerequisite and gate (SHOP-02/03/04)
- **D-12:** the schema-gated plans select `cityShop`, `City.size`, `City.hasShop`, `assets.ownedPets`, `TransactionItems.petAssets`, `Pet.sellable`, `equipPet`, `unequipPet` and the codes `ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED`; they run after the BE Phase 12 PR merges on BE `develop` (schema check against `origin/develop:src/schema.gql`). The device UAT visits a village, a city and a capital (Locanda teleport of the test character), sees three different pools with no legendary item, buys a companion where it is sold (e.g. Talmvere → Cavallo da viaggio), equips it in the Journal, sells it elsewhere, and sees the Shop cell disabled on Necrorian.
- **D-13:** **no UI phase, no UI-SPEC** (Phase 6–10 D-19 carried forward): provisional visuals, token-based (`kg_theme.dart`), existing parchment assets only, no new Cloudinary assets.

### Claude's Discretion
- Layout of the «Compagni» section and of the «Compagno» slot (within the existing `ShopModal` / `equipment_area.dart` patterns), empty-slot copy, bubble copy.
- How the current city id reaches `ShopCubit` (parameter from the page vs a selector on `CharacterCubit` + `MainScreenCubit`).
- Test harness shape for the gated documents (stubbed `cityShop` until the BE lands).

</decisions>

<specifics>
## Specific Ideas

- User, 2026-11-02: «Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma» (FE 13 = adaptation).
- User, 2026-11-02: «SI, terzo tipo nel pool. In questo caso però i pet sono posizionati in base alla lore … In vendita ci sono: cavallo leggero, cavallo da viaggio, cammello del mar sabbioso, tartaruga gigante delle isole» (placement is a BE seed constant, BE 12 D-10).
- User, 2026-11-02: «Bisogna distinguere il pet equipaggiato dai pet posseduti».
- User, 2026-11-02: «cavalcatura non va bene» → «Compagno» / «Compagni».

</specifics>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Backend contract (BE Phase 12)
- `../Klimmeck-Guide-BE/.planning/phases/12-negozi-per-citta/12-CONTEXT.md` — D-01..D-21: `City.size` derived from `CityType`, `City.hasShop`, pool seeded at boot and curated in the DB, `cityShop(cityId)` shape, `ITEM_NOT_IN_SHOP`, pets (owned vs equipped, `equipPet` / `unequipPet`, `petAssets`, `PET_ALREADY_OWNED` / `PET_NOT_OWNED`), deprecations.
- `../Klimmeck-Guide-BE/.planning/phases/12-negozi-per-citta/BACKEND-NOTES.md` — the handoff the BE phase will write (SDL, codes, UAT data); until it exists, `git -C ../Klimmeck-Guide-BE show origin/develop:src/schema.gql` is the gate.
- `../Klimmeck-Guide-BE/.planning/phases/11-popolamento-del-mondo/BACKEND-NOTES.md` §2, §5 — inventory (167 cities, 13 pets with prices and `speedModifier`), Phase 12 notes.

### Prior FE decisions carried forward
- `.planning/phases/07-travel/07-CONTEXT.md` D-12 — Board and Shop disabled off a city marker and during a travel (`disabledSatchelPages`).
- `.planning/phases/09-combat-result-sheet/09-CONTEXT.md` D-16 — Shop disabled while awaiting aid; only `SHOP_NOT_IN_CITY` is a banner, the other refusals stay in the shopkeeper bubble.
- `.planning/phases/08-spells-section-journal-tab/08-CONTEXT.md` D-22/D-23/D-26 — shop filters only on present types, loot row line, Journal equip pattern (optimistic with rollback, FIFO).
- `.planning/phases/06-quest-accept-info-sheets/06-CONTEXT.md` D-04 — in-app banner pattern (`InAppNotificationsCubit.publish`).

### Rules
- `docs/rules/architecture.md`, `docs/rules/state-management.md`, `docs/rules/graphql.md`, `docs/rules/ui-ux.md`, `docs/rules/testing.md`, `docs/rules/naming.md`.
- `.planning/ROADMAP.md` §Phase 13, `.planning/REQUIREMENTS.md` SHOP-02/03/04 (amended 2026-11-02).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `lib/screens/mainScreen/tabs/shop/shop.dart`, `components/shop_modal.dart`, `components/transaction_modal.dart`, `shopCubit/shop_cubit.dart`, `transactionCubit/*` — the whole shop flow; `ShopLoadData(equipmentItems, lootItems)` grows a `pets` list.
- `lib/screens/mainScreen/components/satchel_availability.dart` (`disabledSatchelPages`, `isOnCityMarker`) — the gate to extend with `City.hasShop`.
- `lib/repository/transaction_failure.dart`, `spell_equip_failure.dart` — failure classifier pattern (codes only).
- `lib/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice.dart` — banner vs bubble routing (only `shopNotInCity` → banner).
- `lib/screens/mainScreen/tabs/journal/components/equipment_area.dart`, `equipment_box.dart`, `equipment_mannequin.dart`, `cubit/journal_cubit.dart` (`equipItem`) — the slot UI and the equip pattern for the «Compagno» slot; `sections/spells_section.dart` for the optimistic/rollback list.
- `lib/models/pet.dart`, `lib/models/character/character_assets.dart` (`pet`), `lib/models/city.dart`, `lib/models/enums/city_size_type.dart` (`CitySizeType { capital, city, village }`, today only used by `CityType.cityClass`).
- `lib/models/request/transaction_request.dart` (`TransactionItems { equipAssets, lootAssets }`) — add `petAssets`.
- `lib/graphql/queries/city_queries.dart`, `equipment_item_queries.dart`, `loot_item_queries.dart`, `lib/graphql/fragments/fragments.dart`, `lib/repository/services/graphql/graphql.dart` — documents and service methods to replace/add; the schema-check registry of the gate plans.

### Established Patterns
- Cubit per concern, `SafeEmit`, failures as enums from `extensions.code`; UI never networks.
- Gated plans: documents aligned to `origin/develop:src/schema.gql` of the BE, device E2E recorded in `NN-HUMAN-UAT.md`, VALIDATION approved.
- Analyzer gate repo-wide `0 error/warning` (baseline info only); `dart format` only on touched files (baseline not formatter-clean).

### Integration Points
- `ShopCubit.getData` ← city id of the marker; `Shop` page lifecycle (refetch on open / city change).
- `MainScreen.disabledSatchelPages` ← `City.hasShop`.
- Journal equipment section ← «Compagno» slot + `equipPet` / `unequipPet` in `JournalCubit` (or a dedicated `CompanionCubit`).
- Character fragment ← `assets.ownedPets`.

</code_context>

<deferred>
## Deferred Ideas

- **Pet rewards from quests** (the 9 quest-only pets) — BE Phase 13 / FE Phase 14 discuss.
- **Companion on the Profile tab** (portrait, HP) and pet growth/combat — future phase.
- **Pool curation from the Locanda** — the user curates in the DB; future idea.
- **Drop of the FE `CityType.cityClass` map** in favour of `City.size` everywhere (marker sizes) — Phase 12 Hardening or a quick task.

</deferred>

---

*Phase: 13-city-shops*
*Context gathered: 2026-11-02*
