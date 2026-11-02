# Phase 13: City Shops - Research

**Researched:** 2026-11-02
**Domain:** Flutter adaptation of the shop to a per-city backend pool (`cityShop`), companions (pets) in trade and in the Journal, optimistic equip with rollback
**Confidence:** HIGH for the FE code facts (read and run in this session); MEDIUM for the BE contract names (BE Phase 12 is not implemented yet: names come from `12-CONTEXT.md`, input type names of `equipPet`/`unequipPet` are not fixed)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### The shop call (SHOP-02)
- **D-01 (user decision, verbatim: «Non credo ci sia niente da discutere, bisogna solo chiamare la chiamata al BE per adattarla alla nuova forma»):** `ShopCubit.getData` calls the BE Phase 12 query `cityShop(cityId)` for the city whose marker the character stands on, instead of `equipmentAssetsQuantity(sellable: true)` + `lootAssetsQuantity`. The response carries `equipment` and `loot` as `AssetQuantity` lists (same model, same `ShopModal`, same filters of Phase 8 D-23) plus `pets: [Pet]`; the two global catalogue queries leave the FE (the BE deprecates them). The city id comes from the cities loaded at cold start (`isOnCityMarker` already matches `status.location` to a `City.markerLocation`).
- **D-02 (user decision — «Sì, ma senza il nome della città»):** **no visual change** for the city: no sign on the shop page, no title with the city name on the sheets. ROADMAP SC1 «the shop sheet names the city» is dropped.
- **D-03 (technical default):** the pool is refetched **every time the shop opens** and whenever the character's city changes while the page is alive (the `Shop` page is a `PageView` child that stays mounted: today `getData` runs once in `initState`); no cache across cities; the loading state stays the existing one (explicit user action, rule 2 holds).
- **D-04 (user decision — Necrorian has no shop, «pagina chiusa come fuori città»):** when the marker's city has `City.hasShop == false` (BE D-04: pool empty, Necrorian by rule, any city the user empties by hand) the Shop satchel cell is **disabled exactly like off-city / travel / awaiting aid** (`disabledSatchelPages` gets the city flag; Phase 7 D-12, Phase 9 D-16). `City.hasShop` and `City.size` join the `cities` query and the `City` model; the FE never derives the size itself (the existing `CityType.cityClass` map stays only for marker rendering — it classifies Ferrion as a capital while the BE says city).

#### Refusals (SHOP-03)
- **D-05 (user decision):** `ITEM_NOT_IN_SHOP` (an item outside the pool, a legendary or a `sellable: false` item slipped into a purchase — a race after a DB curation) goes to the **shopkeeper bubble** like every transaction refusal except `SHOP_NOT_IN_CITY` (Phase 9 D-16: only the off-city refusal is a banner). ROADMAP SC2 «mapped on the in-app banner» is amended. After the refusal the shop reloads the pool (D-03) so the stale row disappears.
- **D-06 (technical default):** `transaction_failure.dart` gains `itemNotInShop`, `petAlreadyOwned`, `petNotOwned`; `equipPet` / `unequipPet` get their own classifier (`pet_equip_failure.dart`, same shape as `spell_equip_failure.dart`) mapping `PET_NOT_OWNED`, `NOT_FOUND`, `FORBIDDEN`, `UNAUTHENTICATED`, connection. Bubble copy is Claude's discretion («Questa merce non la tratto», «Hai già questo compagno»).

#### Companions in the shop (SHOP-04)
- **D-07 (user decision — «Terza lista nello stesso foglio»):** the buy sheet shows, under equipment and loot, a section **«Compagni»** with the pets of the city pool: name, buy price, speed only when `speedModifier != null` (a cat or a dog is a companion, not a mount); the sell sheet shows the **owned** pets (`assets.ownedPets`) with the equipped one marked. Selection and confirmation flow unchanged (`TransactionModal` totals include the pets; `TransactionItems.petAssets` with quantity 1 on both sides).
- **D-08 (user decision — «niente sella automatica», «lo stesso pet non si compra due volte»):** buying never equips; the buy list hides the pets already owned (the BE still refuses duplicates with `PET_ALREADY_OWNED`, mapped to the bubble). Selling an owned pet removes it; if it was the equipped one the BE empties `assets.pet` in the same transaction and the Journal slot follows through the subscription.
- **D-09 (user decision — legendary items can be sold):** the sell sheet keeps listing every owned item including legendary ones; no FE filter on `sellable`.

#### «Compagno» slot in the Journal (SHOP-04)
- **D-10 (user decision, verbatim: «Bisogna distinguere il pet equipaggiato dai pet posseduti»; title: «il pet non essendo necessariamente un animale da sella (può essere un gatto o un cane) deve avere un titolo diverso, cavalcatura non va bene» → «Compagno»):** the Journal equipment section gets a **«Compagno» slot** next to the equipment slots: it shows the equipped pet (`assets.pet`, name and speed if any, empty state when none); tapping it opens the list of the **owned** pets; tapping a pet calls `equipPet`, tapping the equipped one calls `unequipPet` (Phase 8 spells pattern: optimistic overlay with rollback on refusal, FIFO of the mutations). The slot is read-only during a travel? **No** — the BE allows equipping during a travel without effect on the current travel (BE D-15), so the slot stays interactive everywhere the Journal is readable.
- **D-11 (technical default):** the owned list and the equipped pet come only from the `Character` subscription (`assets { pet { … } ownedPets { … } }` added to the character fragment); the FE never computes the speed, it only prints `speedModifier` as served.

#### Backend prerequisite and gate (SHOP-02/03/04)
- **D-12:** the schema-gated plans select `cityShop`, `City.size`, `City.hasShop`, `assets.ownedPets`, `TransactionItems.petAssets`, `Pet.sellable`, `equipPet`, `unequipPet` and the codes `ITEM_NOT_IN_SHOP`, `PET_ALREADY_OWNED`, `PET_NOT_OWNED`; they run after the BE Phase 12 PR merges on BE `develop` (schema check against `origin/develop:src/schema.gql`). The device UAT visits a village, a city and a capital (Locanda teleport of the test character), sees three different pools with no legendary item, buys a companion where it is sold (e.g. Talmvere → Cavallo da viaggio), equips it in the Journal, sells it elsewhere, and sees the Shop cell disabled on Necrorian.
- **D-13:** **no UI phase, no UI-SPEC** (Phase 6–10 D-19 carried forward): provisional visuals, token-based (`kg_theme.dart`), existing parchment assets only, no new Cloudinary assets.

### Claude's Discretion
- Layout of the «Compagni» section and of the «Compagno» slot (within the existing `ShopModal` / `equipment_area.dart` patterns), empty-slot copy, bubble copy.
- How the current city id reaches `ShopCubit` (parameter from the page vs a selector on `CharacterCubit` + `MainScreenCubit`).
- Test harness shape for the gated documents (stubbed `cityShop` until the BE lands).

### Deferred Ideas (OUT OF SCOPE)
- **Pet rewards from quests** (the 9 quest-only pets) — BE Phase 13 / FE Phase 14 discuss.
- **Companion on the Profile tab** (portrait, HP) and pet growth/combat — future phase.
- **Pool curation from the Locanda** — the user curates in the DB; future idea.
- **Drop of the FE `CityType.cityClass` map** in favour of `City.size` everywhere (marker sizes) — Phase 12 Hardening or a quick task.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SHOP-02 | On a city marker the shop lists only that city's pool (equipment, loot, companions) from `cityShop(cityId)`; size/hasShop/pool are BE-owned; no FE filter by rarity/size/price; no city name; Shop cell disabled where the city has no shop | F1 (lifecycle: Shop is re-created on every open, add only a city-change listener), F2 (`currentCityOf` in `board_policy.dart`, `Shop(cities:)` like `Board(cities:)`), F3 (`GetCityShop` document, `cities` gains `size hasShop`), F4 (`City.size`/`hasShop`, `CityShop`), F8 (`disabledSatchelPages` returns `{shop}` only when `hasShop == false`) |
| SHOP-03 | `ITEM_NOT_IN_SHOP` refused by BE, classified, shown in the bubble (only `SHOP_NOT_IN_CITY` is a banner), pool reloaded; selling everywhere incl. legendary; infinite stock; legendary never on sale | F7 (classifier + `shopkeeperRefusalLine`), F1 (reload via `ShopPoolLoader` listening to `TransactionError(itemNotInShop)`), D-09 (no change to sell list, lock with a test), Pitfall 4 (`canAfford` blocks net-positive sales today) |
| SHOP-04 | «Compagni» in buy (pool pets, speed only for mounts, owned hidden) and sell (owned, equipped marked) sheets; `petAssets` quantity 1; `PET_ALREADY_OWNED` in the bubble; Journal «Compagno» slot with `equipPet`/`unequipPet`, Phase 8 optimistic pattern; buying never equips | F4 (`Pet.speedModifier`, `CharacterAssets.ownedPets`, `TransactionItems.petAssets`), F5 (`TradeSelection` value object + `CompanionRow`), F6 (`CompanionCubit` shell-provided + `CompanionOutcomeListener` in `MainScreen` + `CompanionSection` in the Journal), F9 (text-only rows) |
</phase_requirements>

## Project Constraints (from CLAUDE.md)

- Flutter + `flutter_bloc` Cubits + `equatable`; `graphql_flutter` for GraphQL; documents only in `lib/graphql/**` (no inline strings in widgets/cubits).
- Layers UI → Cubit → Repository → Service; Cubit never knows `BuildContext`; models Flutter-free; theme tokens only (`kg_theme.dart`), no inline hex / `TextStyle(fontSize:)`.
- **Rule 1:** no app-style chrome on gameplay screens (shop, journal): no AppBar/bottom nav.
- **Rule 2:** no blocking loaders in an active session; loading only at cold start or on explicit user action (opening the shop qualifies).
- **Rule 3:** branch + PR per phase (already on `feat/13-city-shops`, PR target `develop`; executors never push).
- **Rule 4:** the backend is the source of truth: no FE computation of speed, prices, rarity filters, shop availability.
- **Rule 5:** no secrets in the repo; never print `.env`, `google-services.json`.
- TDD red → green → refactor; Boy Scout Rule in-scope; Clean Code (no boolean flags that change behaviour, early return).
- `flutter analyze` clean of errors/warnings (repo-wide gate; baseline has info only); `dart format` only on touched files.
- Naming: `snake_case.dart`, `XxxCubit`/`XxxState`, operations `GetXxx` / imperative mutations (`EquipPet`), booleans `isX/hasX/canX`.
- User memory: commit scope `phase-13` for docs, no `Co-Authored-By` trailer (REPO-RULES confirm: "No `Co-Authored-By` nor `Generated with` trailer"), BE repo read-only, subagents never print `.env`.
- `.planning/phases/13-city-shops/13-REPO-RULES.md` (written by the orchestrator during this research) binds every plan: sequential execution, scopes `shop|companion|journal|satchel|models|graphql`, gate grep `cityShop` ≥ 1 on BE `origin/develop`.

## Summary

The phase is a narrow adaptation plus one new interaction. The current shop is self-contained: `ShopCubit.getData()` calls two global catalogue queries and emits `ShopLoadData(equipment, loot)`; `Shop` copies the lists into widget state through a `BlocConsumer` listener; `ShopModal` (two `Dropdown`s with Phase 8 filters) and `TransactionModal` (totals via `getTotalAmount`, `canAfford`, signature) work on `List<AssetQuantity>`; `_onConfirm` splits assets by runtime type into `TransactionItems { equipAssets, lootAssets }`. None of this has a page-level or cubit-level test today (only `shop_modal_test.dart`, `transaction_cubit_test.dart`, `transaction_notice_test.dart`, `transaction_outcome_listener_test.dart`).

The most important finding contradicts D-03: the `Shop` page is **not** kept mounted. `MainScreen`'s `PageView` uses `cacheExtent: allowImplicitScrolling ? 1.0 : 0.0` (Flutter 3.35.5 `page_view.dart:975`, verified) and no tab uses `AutomaticKeepAliveClientMixin` (only `MainScreen` itself), so every jump to the Shop builds a fresh `_ShopState` and `initState` already runs on every open (Phase 8 research F3 found the same for the Journal). The planner therefore needs no `onPageChanged` hook: keep the load in `initState` (now with the city id) and add only a `CharacterCubit` listener for a city change while the page is on screen (innkeeper teleport). Because `ShopCubit` is shell-scoped (`authenticated_shell.dart:150`), its last `ShopLoadData` survives page disposal, so the state must carry the `cityId` and the cubit must drop out-of-order responses.

Companions need three additions with no existing support: the FE `Pet` model lacks `speedModifier` (present in the BE SDL today as `Float`), and **`assets.pet` is not selected at all** in `CharacterFragment.assetsFields` (so `CharacterAssets.pet` is always null in the app today); pets are not `AssetItem`s (making them one would crash `ItemRow`, which assumes equipment-or-loot), so the selection must carry pets beside the `AssetQuantity` lists. The Journal slot copies the Phase 8 shape: a shell-provided `CompanionCubit` (optimistic overlay, token per operation, FIFO queue, settle timeout, `sync` from the subscription) behind a `CompanionRepository` that maps `OperationException` to `PetEquipFailure`, with a `CompanionOutcomeListener` in `MainScreen` next to `SpellOutcomeListener`.

**Primary recommendation:** pass `cities` to `Shop` (same as `Board`), load `cityShop(currentCityOf(...).id)` from a small non-visual `ShopPoolLoader` (initState + city-change + `ITEM_NOT_IN_SHOP` reload), keep `ShopModal`/`TransactionModal` on `AssetQuantity` and add pets through a pure `TradeSelection` value object; build the Journal slot as a `CompanionSection` fed by a new shell-scoped `CompanionCubit` cloned from `SpellsCubit` but single-slot.

## Conflicts with CONTEXT

| # | CONTEXT text | Fact (evidence) | Recommendation |
|---|---|---|---|
| C1 | D-03: «the `Shop` page is a `PageView` child that stays mounted: today `getData` runs once in `initState`» | Off-screen `PageView` pages are disposed: Flutter 3.35.5 `packages/flutter/lib/src/widgets/page_view.dart:975` `cacheExtent: widget.allowImplicitScrolling ? 1.0 : 0.0`; `MainScreen` builds `PageView(physics: NeverScrollable…, controller, onPageChanged, children)` without `allowImplicitScrolling` (`main_screen.dart:164-170`); `grep AutomaticKeepAlive lib` finds only `MainScreen`. Phase 8 research F3 recorded the same for the Journal (`SpellsCubit` comment: «il PageView distrugge le tab fuori schermo, F3»). So `initState` → `getData` already runs on **every** open. | Amend D-03's parenthesis: «the `Shop` page is re-created on every open (PageView disposes off-screen tabs), so the load in `initState` covers "every open"; a `CharacterCubit` listener covers a city change while the page is shown». The behaviour D-03 asks for is unchanged; only the mechanism differs. No `onPageChanged` hook, no keep-alive. |
| C2 | D-11 / code_context: «`assets { pet { … } ownedPets { … } }` added to the character fragment» implies `pet` is already selected | `CharacterFragment.assetsFields` selects `wearedEquipment`, `ownedEquipments`, `activeSpells`, `ownedItems` only (`character_fragment.dart:69-100`): `CharacterAssets.pet` is always null today; the travel speed works only because the BE reads it server-side. | No decision change: plan 13-02 must add **both** `pet { …PetFields }` and `ownedPets { …PetFields }`. Note for the UAT: the character that already rides the Cavallo da viaggio (BE D-16) will show it in the slot for the first time. |
| C3 | (not a D-xx, but `13-REPO-RULES.md`: «`PET_NOT_OWNED` go to the shopkeeper bubble / inline») | The Journal has no shopkeeper bubble and no inline error surface; the Phase 8 pattern D-10 points to (spells) reports refusals with an in-app banner via `SpellOutcomeListener` → `InAppNotificationsCubit.publishNotice`. | Recommend the Phase 8 banner for `equipPet`/`unequipPet` refusals (`companionNoticeFor`), silent re-read for stale-view codes; `PET_NOT_OWNED` from **`doTransaction`** (selling a pet no longer owned) goes to the bubble. Orchestrator to confirm (listed in Open Questions as resolved with this default). |

No other contradiction found: D-01's «`isOnCityMarker` already matches `status.location` to a `City.markerLocation`» is true (`board_policy.dart:10-19`, `currentCityOf` returns the `City`); D-04's «`CityType.cityClass` classifies Ferrion as a capital» is true (`city_type.dart:14`; Necrorian and Talmvere are also `capital` in the FE map while the BE says city / village — relevant for the UAT, Talmvere is a **village** for the BE).

## Standard Stack

No new dependency. Everything is in `pubspec.yaml` already.

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK | 3.35.5 (Dart 3.9.2) [VERIFIED: `flutter --version`] | UI | Project SDK |
| flutter_bloc / bloc | as locked in `pubspec.lock` | `ShopCubit`, `CompanionCubit` | Project standard (state-management.md) |
| equatable | locked | `CityShop`, `TradeSelection`, `CompanionState` | Project standard |
| graphql_flutter | locked | `GetCityShop`, `EquipPet`, `UnequipPet` | Project standard; `performQuery` uses `FetchPolicy.noCache` (`graphql.dart:75-87`), so every open hits the network: matches D-03 «no cache across cities» |

### Supporting (tests)
| Library | Purpose | When to Use |
|---------|---------|-------------|
| bloc_test + mocktail | `blocTest` for `ShopCubit`, `CompanionCubit`; `MockKlimmeckGraphQl` (`test/helpers/mocks.dart:70`) | every cubit plan |
| gql (`parseString`) | document tests (`test/graphql/*_documents_test.dart` pattern) | 13-02 |
| `tool/schema_check/` (`dump_documents.dart` + `validate_documents.js`, BE `node_modules/graphql`) | cross-repo schema gate | 13-10 only |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Shop(cities:)` + `currentCityOf` in the page (recommended) | `ShopCubit` reading `CharacterCubit` + `MainScreenCubit` | Cubit-to-cubit calls are forbidden (state-management.md anti-pattern); `Board` already uses the page-parameter shape. |
| `CompanionCubit` (recommended) | extend `JournalCubit.equipItem` | `JournalCubit` is shell-scoped but legacy (`print`, `JournalError(String)`, no failures, no overlay); D-10 asks for the Phase 8 optimistic pattern, which lives in `SpellsCubit`. |
| `TradeSelection { assets, pets }` (recommended) | make `Pet` an `AssetItem` | `ItemRow` builds `EquipmentItemCard` or `LootItemCard(asLoot!)` (`item_row.dart:35-50`) → a pet would hit `asLoot!` null; `AssetItem.fromJson` dispatches on `equipType`; filters assume the two types. |

**Installation:** none.

## Architecture Patterns

### Recommended file layout (new files in bold)
```
lib/models/
  pet.dart                       # + speedModifier (double?), sellable (bool?)
  city.dart                      # + size (CitySizeType?), hasShop (bool, default true when absent)
  **city_shop.dart**             # CityShop { cityId, equipment, loot, pets }
  character/character_assets.dart# + ownedPets (List<Pet>, default [])
  request/transaction_request.dart # TransactionItems + petAssets
  **request/equip_pet_request.dart** # EquipPetRequest {id, petId}, UnequipPetRequest {id}
  **shop/trade_selection.dart**  # TradeSelection {assets, pets}: total, toTransactionItems, retainPurchasable
lib/graphql/
  **fragments/pet_fragment.dart**   # PetFragment.fields (export from fragments.dart)
  fragments/character_fragment.dart # assets { pet {…} ownedPets {…} }
  queries/city_queries.dart          # cities + size hasShop
  **queries/shop_queries.dart**      # ShopQueries.getCityShop (GetCityShop)
  mutations/character_mutations.dart # EquipPet, UnequipPet
  queries/equipment_item_queries.dart / loot_item_queries.dart # drop the *AssetsQuantity documents (13-05)
lib/repository/
  transaction_failure.dart       # + itemNotInShop, petAlreadyOwned, petNotOwned
  **pet_equip_failure.dart**     # PetEquipFailure + PetEquipException + petEquipFailureFrom
  **companion_repository.dart**  # equip/unequip with timeout, failure mapping
  services/graphql/graphql.dart  # + getCityShop, equipPet, unequipPet; - getAll*AssetsQuantity
lib/screens/mainScreen/
  components/satchel_availability.dart # hasShop rule
  **components/companion_outcome_listener.dart** # sync + banner + stale re-read
  main_screen.dart               # Shop(cities: cities); mount CompanionOutcomeListener
  tabs/shop/shop.dart            # TradeSelection, bubble line, ShopPoolLoader
  tabs/shop/shopCubit/*          # getData(cityId), ShopLoadData(cityId,…, pets)
  **tabs/shop/components/shop_pool_loader.dart** # non-visual: load on init / city change / ITEM_NOT_IN_SHOP
  tabs/shop/components/shop_modal.dart        # third Dropdown «Compagni»
  tabs/shop/components/transaction_modal.dart # pets in Acquisto/Vendita, totals, canAfford fix
  tabs/shop/transactionCubit/transaction_notice.dart # + shopkeeperRefusalLine
  tabs/journal/**companionCubit/** companion_cubit.dart, companion_state.dart, companion_notice.dart
  tabs/journal/**sections/companion_section.dart** # «Compagno» slot + owned-pets sheet
  tabs/journal/journal.dart      # insert CompanionSection after the Armatura dropdown
lib/shared/components/**companion_row.dart** # used by shop (2 sheets) and journal → shared (architecture.md ≥2 features)
lib/utils/item_lines.dart        # + companionSpeedLabel(Pet)
lib/screens/auth/authenticated_shell.dart # BlocProvider<CompanionCubit>
tool/schema_check/schema_check_documents.dart # -2 +3 entries
```

### Pattern 1: City id from the page, last-request-wins cubit (F1, F2)
**What:** `Shop` receives `cities` (like `Board(cities:)`, `main_screen.dart:196`); a non-visual `ShopPoolLoader` resolves `currentCityOf(cities, location)` and calls `ShopCubit.getData(cityId)` in `initState`, on a location change, and after `TransactionError(itemNotInShop)`. The cubit keeps the requested id and ignores stale responses.
**When:** every pool load.
```dart
// shop_cubit.dart — Source: pattern of QuestCubit.refreshQuests(cityId:) + SafeEmit
Future<void> getData(String cityId) async {
  _requestedCityId = cityId;
  emit(const ShopLoading());
  try {
    final pool = await graphQl.getCityShop(cityId);
    if (_requestedCityId != cityId) return;          // a newer city won
    emit(ShopLoadData(cityId: cityId, equipmentItems: pool.equipment,
        lootItems: pool.loot, pets: pool.pets));
  } on Object {
    if (_requestedCityId != cityId) return;
    emit(ShopError(cityId));                          // no raw message, no print (Boy Scout)
  }
}

// shop_pool_loader.dart — UI orchestration via BlocListener (state-management.md)
BlocListener<CharacterCubit, CharacterState>(
  listenWhen: (p, c) => _locationIdOf(p) != _locationIdOf(c),
  listener: (context, state) => _load(context, state),
  child: BlocListener<TransactionCubit, TransactionState>(
    listenWhen: (_, c) => c is TransactionError && c.failure == TransactionFailure.itemNotInShop,
    listener: (context, _) => _load(context, context.read<CharacterCubit>().state),
    child: child,
  ),
)
```
`Shop` reads the lists in its **builder** from `ShopLoadData` whose `cityId` equals the current city (not from the listener, which never fires for the state the page finds when it mounts), and prunes the buy selection with `TradeSelection.retainPurchasable(pool)` when a new pool arrives.

### Pattern 2: Satchel gate with the city flag (F8)
```dart
// satchel_availability.dart
const _boardAndShop = {SatchelLayout.boardPageIndex, SatchelLayout.shopPageIndex};
Set<int> disabledSatchelPages({required PointOfInterest? location, required List<City> cities,
    required bool isTravelling, bool isAwaitingAid = false}) {
  final city = currentCityOf(cities, location);
  if (city == null || isTravelling || isAwaitingAid) return _boardAndShop;
  return city.hasShop ? const {} : const {SatchelLayout.shopPageIndex};   // D-04: Board stays open on Necrorian
}
```
Consumers (`MainScreen` builder at `main_screen.dart:120` and `_isPageDisabled` at `:241`, `MenuBackground`, `SatchelMenu`) take a `Set<int>` and need no change. The `hasShop` comes from the cold-start `cities` snapshot; a pool emptied in the DB mid-session shows an empty shop until the next cold start (acceptable, BE refuses anyway).

### Pattern 3: Pets beside the asset lists (F5)
`TradeSelection` (Flutter-free, `lib/models/shop/`): `assets: List<AssetQuantity>`, `pets: List<Pet>`; `bool get isEmpty`; `Coins total({required bool isBuy})` = `getTotalAmount(assets, isBuy)` + Σ pet prices; `TransactionItems toTransactionItems()` (moves today's `_onConfirm.splitAssets` out of the widget, `petAssets` with quantity 1); `TradeSelection togglePet(Pet)`; `TradeSelection retainPurchasable(CityShop)` (drops bought assets/pets no longer in the pool). Plus a pure `purchasablePets(List<Pet> pool, List<Pet> owned)` hiding owned ids (D-08).
`ShopModal` gets `pets`, `selectedPets`, `onSelectPets`, `equippedPetId` (sell only) and renders a third `Dropdown(key: ValueKey('companions_dropdown'), sectionName: "Compagni")` **only when the list is non-empty** (most pools have no pets: 4 pets × 2 cities, BE D-10). The `maxHeight` math must divide by the number of open dropdowns (today hard-coded for two: `isEquipOpen && isItemOpen ? (h-223)/2 : h-223`). Tap with pencil adds (if absent), rubber removes; no quantity above 1.
`CompanionRow` (shared): name (`bodyMedium`), `CoinsDisplay` (buy or sell price, hidden in the Journal), `companionSpeedLabel(pet)` line only when `speedModifier != null`, an «equipaggiato» marker when `isEquipped`, selected highlight like `EquipmentBox` (`primaryGold.withAlpha(100)`). **Text-only, no image** (F9).

### Pattern 4: Single-slot optimistic companion (F6)
`CompanionCubit` (shell-provided like `SpellsCubit`, `authenticated_shell.dart:239`): state `CompanionState { CompanionOperation? pending, CompanionOutcome? outcome }` where `CompanionOperation` = `equip(petId)` | `unequip(petId)`; view helper `displayedPetId(Character)` = pending target if any else `assets.pet?.id`. Rules copied from `SpellsCubit`: token per operation, `Queue` drained one mutation at a time (FIFO), settle via `sync(Character)` (`equip` settles when `assets.pet?.id == petId`, `unequip` when `assets.pet == null`), settle timeout = `CompanionRepository.defaultTimeout` (15 s like `SpellsRepository`), success without `characterUpdated` → `settledByTimeout` + silent re-read, failure → rollback (pending cleared) + outcome with `PetEquipFailure`. Recommended simplification: **one operation in flight per slot**; a tap while pending returns `ignoredPending` (Phase 8's per-spell rule applied to the single slot) — FIFO is then trivially respected and the overlay never shows two targets. `toggle(character, petId)` → `equip` when `petId != displayed`, `unequip` when equal.
`CompanionOutcomeListener` in `MainScreen` (next to `SpellOutcomeListener`): `sync` on every `CharacterLoaded` change, banner via `companionNoticeFor(outcome)` (null for stale-view and unauthenticated), `refreshCharacter()` for stale-view failures (`petNotOwned`, `notFound`, `timedOut`, `settledByTimeout`).
`CompanionSection` in the Journal (after `_buildArmorSection`, before `_buildOwnedItemsSection`, `journal.dart:466-475`): a `Section(sectionName: "Compagno")` with a `CompanionRow(showCoins: false)` of the displayed pet or the empty copy «Nessun compagno al tuo fianco»; tap opens `showModalBottomSheet` + `PaperSheetModal` listing `assets.ownedPets` (equipped marked); tapping a row calls `toggle` and closes the sheet; empty owned list → the sheet shows «Non possiedi compagni». Interactive during travel (D-10).

### Anti-Patterns to Avoid
- **Hook on `onPageChanged` / keep-alive for the shop:** unnecessary (C1) and keep-alive would change memory/lifecycle of a heavy SVG page.
- **Copying the pool into widget state in a `BlocConsumer.listener`:** the listener never fires for the state present when the page mounts; with a shell-scoped cubit the page can mount on a stale `ShopLoadData` of another city. Read from the builder and match `cityId`.
- **Writing «query Xxx» / «mutation Xxx» in a doc comment of `lib/graphql/{queries,mutations,subscriptions}`:** the registry test regex (`schema_check_documents_test.dart:9`) would treat it as an operation (Phase 9 lesson, 10-RESEARCH).
- **Filtering the pool by `sellable`/rarity in the FE** (rule 4, D-09): the only FE list rule is hiding owned pets (D-08).
- **Equipping on purchase** (D-08) or touching `CompanionCubit` from the shop.
- **Showing `ShopError` as a blocking screen:** keep the shop usable (sell side still works); at most the bubble line.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Optimistic equip with rollback, FIFO, timeout | a new ad-hoc flag in the Journal state | copy the structure of `SpellsCubit` (`tabs/journal/spellsCubit/spells_cubit.dart`) | tokens, settle timeout, subscription settle and close() cleanup are already proven (618-line test) |
| Error code extraction | parsing `message` strings | `graphQlErrorCode(exception)` (`graphql_error_code.dart`) | handles `graphqlErrors` and `SubscriptionError` payloads |
| Current city of the marker | a new lookup | `currentCityOf(cities, location)` (`board_policy.dart:10`) | same rule as the Board and the satchel |
| Banner | custom overlay | `InAppNotificationsCubit.publishNotice(notice, dedupKey:)` | dedup, Phase 5/6 pattern |
| Bottom sheet | new modal | `showModalBottomSheet` + `PaperSheetModal` (`shared/components/modal/paper_sheet_modal.dart`) | existing parchment visual, D-13 |
| Coin totals | new arithmetic | `getTotalAmount` (`utils/utils.dart:8`) + `Coins` operators | copper-normalised |
| Schema validation | grep of the SDL | `tool/schema_check/dump_documents.dart` + `validate_documents.js` | validates every document against the real SDL (42/42 OK today) |

## Common Pitfalls

### Pitfall 1: stale pool after a city change or a slow response
**What goes wrong:** teleport A → B while `cityShop(A)` is in flight; A's response lands last and the page shows A's pool in B (purchase → `ITEM_NOT_IN_SHOP`).
**How to avoid:** `_requestedCityId` guard in the cubit; `ShopLoadData.cityId` compared with `currentCityOf(...)` in the builder; prune the buy selection on every new pool.
**Warning signs:** a `blocTest` with two `getData` calls and completers resolved in reverse order emits A's data.

### Pitfall 2: documents ahead of the BE break the app against the current BE
**What goes wrong:** from the commit that adds `size hasShop` to `cities` and `ownedPets` to the character fragment, the cold start and the `characterUpdated` subscription fail on any BE without Phase 12 (GraphQL validation error on unknown fields); `petAssets` makes every `doTransaction` fail too.
**How to avoid:** accepted by design (no device run until the gate plan); say it in plan 13-02's SUMMARY and in STATE; never run the app on device between 13-02 and 13-10 against an old BE.

### Pitfall 3: `City.hasShop` default breaks 18 test files
**What goes wrong:** 18 test files build `City.fromJson` without `hasShop` (`grep -rln "City.fromJson" test | wc -l` → 18); a strict default `false` would disable the Shop in all of them (and in `satchel_availability_test`'s «on a city marker nothing is disabled»).
**How to avoid:** parse `hasShop: json['hasShop'] as bool? ?? true` and name the test «a city without the flag keeps its shop (wire default, D-04)». The BE field is `Boolean!`, so absence only happens in fixtures.

### Pitfall 4: `canAfford` blocks net-positive sales (pre-existing bug)
**What goes wrong:** `transaction_modal.dart:71` checks `coins.canAfford(total)` where `total = |sell − buy|` regardless of the sign: a character with 10 ag cannot sign the sale of a Cavallo da viaggio (+50 ag). This hits the UAT step «sells it elsewhere» right after spending 1 oro on the purchase.
**How to avoid:** `canAfford = isPositive || coins.canAfford(total)`, with a regression test first (TDD bugfix rule). In scope: SHOP-03 «selling works in every city».

### Pitfall 5: `Dropdown` heights with three sections
**What goes wrong:** the third dropdown overflows or the first two keep half height when «Compagni» opens.
**How to avoid:** compute `available / openCount` (min 1) for every open dropdown; widget test opens all three in landscape (`test/helpers/landscape.dart`) without overflow exceptions.

### Pitfall 6: page-level shop tests need SVG seeding and network SVGs
**What goes wrong:** `Shop` uses `CachedSvg` with literal Cloudinary URLs (`shop.dart:68, 343, 357, 372`) and `EditPencilRubber` uses `SvgPicture.network` (no cache) → pumping `Shop` in a test is brittle.
**How to avoid:** test behaviour where it lives: `ShopCubit` (blocTest), `ShopPoolLoader` (non-visual widget test with `MockCharacterCubit`/`MockShopCubit`/`MockTransactionCubit`), `TradeSelection` (unit), `ShopModal`/`TransactionModal`/`CompanionRow` (widget, with `seedSvgCache`). Do not add a full `Shop` page test.

### Pitfall 7: registry and operation names
**What goes wrong:** `schema_check_documents_test` fails when a document exists without a registry entry or vice versa, and when the key differs from the operation name.
**How to avoid:** in the same commit add `GetCityShop`, `EquipPet`, `UnequipPet`; in 13-05 remove `equipmentAssetsQuantity` and `lootAssetsQuantity` together with their documents and service methods (only consumer: `shop_cubit.dart:19-22`, verified by grep). Expected dump count: 42 − 2 + 3 = **43**.

### Pitfall 8: equipPet/unequipPet input type names are not fixed
**What goes wrong:** the FE document declares `$request: EquipPetRequest!` but the BE names it differently → validation error.
**How to avoid:** write the agreed shape (`{ id, petId }` / `{ id }`) with the assumed names `EquipPetRequest` / `UnequipPetRequest` (A1); 13-10 starts by reading `awk '/^input .*Pet/,/^}/'` on the merged SDL and aligns names before the 43-OK run.

### Pitfall 9: dirty formatter baseline
`dart format` only on touched files; never on directories. Known dirty: `city_markers_layer.dart`, `character_marker_layer.dart`, `map_utils.dart` (none touched by this phase).

## Code Examples

### Pet fragment and cityShop document (F3)
```dart
// lib/graphql/fragments/pet_fragment.dart
class PetFragment {
  /// Campi del compagno: nessuna immagine (D-13), velocità solo stampata (D-11).
  static const String fields = '''
    id
    name
    speedModifier
    sellable
    buyPrice { gold silver copper }
    sellPrice { gold silver copper }
  ''';
}

// lib/graphql/queries/shop_queries.dart
class ShopQueries {
  static String get getCityShop => '''
    query GetCityShop(\$cityId: ID!) {
      cityShop(cityId: \$cityId) {
        city { id }
        equipment { quantity item { ... on EquipmentItem { ${EquipmentFragment.fields} } } }
        loot { quantity item { ... on LootItem { ${LootFragment.fields} } } }
        pets { ${PetFragment.fields} }
      }
    }
  ''';
}
```
`city { id }` is enough: the id guards the stale-response check; the name is never shown (D-02) and `hasShop`/`size` come with `cities` (D-04). `cities` gains `size` and `hasShop` after `name`. Character fragment `assetsFields` gains `pet { ${PetFragment.fields} }` and `ownedPets { ${PetFragment.fields} }`.

### Mutations (F3)
```dart
static const String equipPet = r'''
  mutation EquipPet($request: EquipPetRequest!) {
    equipPet(request: $request) { response successful }
  }''';
static const String unequipPet = r'''
  mutation UnequipPet($request: UnequipPetRequest!) {
    unequipPet(request: $request) { response successful }
  }''';
```
Service: `Future<bool> equipPet(EquipPetRequest)` / `unequipPet(UnequipPetRequest)` via `_dataOrThrow` + `successful is bool` check, same as `_spellSlotMutation` (`graphql.dart:710-728`); `Future<CityShop> getCityShop(String cityId)` via `_dataOrThrow` + `CityShop.fromJson(data['cityShop'])`, `FormatException` when malformed.

### Transaction items (F4)
```dart
class TransactionItems {
  TransactionItems({required this.equipAssets, required this.lootAssets, this.petAssets = const []});
  final List<AssetQuantityInput> equipAssets, lootAssets, petAssets;
  Map<String, dynamic> toJson() => {
    'equipAssets': equipAssets.map((a) => a.toJson()).toList(),
    'lootAssets': lootAssets.map((a) => a.toJson()).toList(),
    'petAssets': petAssets.map((a) => a.toJson()).toList(),     // quantity always 1 (BE D-17)
  };
}
```
(Today's `toJson` returns the raw `AssetQuantityInput` objects and relies on `jsonEncode` calling `toJson`; mapping explicitly makes the request testable as a plain map — Boy Scout.)

### Classifiers (F7)
```dart
const String itemNotInShopCode = 'ITEM_NOT_IN_SHOP';
const String petAlreadyOwnedCode = 'PET_ALREADY_OWNED';
const String petNotOwnedCode = 'PET_NOT_OWNED';
// TransactionFailure: + itemNotInShop, petAlreadyOwned, petNotOwned (switch arms)

// pet_equip_failure.dart
enum PetEquipFailure { notOwned, notFound, forbidden, badUserInput, unauthenticated, connection, timedOut, declined, unknown }
PetEquipFailure petEquipFailureFrom(OperationException e) { /* same shape as spellEquipFailureFrom */ }

// transaction_notice.dart — bubble copy (provisional, D-13)
String? shopkeeperRefusalLine(TransactionFailure failure) => switch (failure) {
  TransactionFailure.shopNotInCity => null,                       // banner (Phase 9 D-16)
  TransactionFailure.itemNotInShop => 'Questa merce non la tratto',
  TransactionFailure.petAlreadyOwned => 'Hai già questo compagno',
  TransactionFailure.petNotOwned => 'Questo compagno non è più tuo',
  TransactionFailure.insufficientFunds => 'Non ti bastano le monete',
  _ => 'Hmmm... Qualcosa non mi torna. Riproviamo?',               // today's line, unchanged
};
```
`Shop._showRefusal` becomes `_transactionMessage = shopkeeperRefusalLine(f) ?? ''` with `_showTransactionMessage = line != null`. `transactionNoticeFor` stays banner-only for `shopNotInCity`.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `equipmentAssetsQuantity(sellable: true)` + `lootAssetsQuantity` (global catalogue) | `cityShop(cityId)` | BE Phase 12 (deprecationReason «Phase 12: use cityShop», BE D-20) | FE drops both documents and service methods |
| `assets.pet` single field (not even selected by the FE) | `assets.pet` (equipped) + `assets.ownedPets` | BE Phase 12 D-13 | Journal slot + shop sell list |
| `CityType.cityClass` FE size map | `City.size` from the BE | BE Phase 12 D-01 | FE parses `size` but uses it nowhere in this phase (marker rendering change is deferred) |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Input types are named `EquipPetRequest { id: String!, petId: String! }` and `UnequipPetRequest { id: String! }`, return `CommonResponse` | Code Examples, 13-02 | Validation error; 13-10 aligns names (one-line change) [ASSUMED from BE D-15 «stesso stile di `equipItem`»] |
| A2 | `CitySize` SDL values are `village`, `city`, `capital` (camelCase like `CityType`) | F4 | Parse returns null (use `asNameMap()[...]`, never `byName`) [ASSUMED] |
| A3 | `cityShop` argument is `cityId: ID!` | Code Examples | Validation error, fixed in 13-10 [CITED: BE 12-CONTEXT D-18] |
| A4 | `Pet.sellable` is `Boolean` (nullable or not) on `Pet` | F3 | Selection still valid either way [CITED: BE D-07] |
| A5 | `petAssets` accepts the same `AssetQuantityInput { item: ID, quantity: Int! }` | F4 | [CITED: BE D-17] |
| A6 | `Pet.imagePath` values are relative (`pets/horse.png`) without an uploaded Cloudinary asset | F9 | None if rows stay text-only [ASSUMED from the orchestrator brief; no pet asset exists in `cloudinary_assets.dart`, verified by grep] |
| A7 | `equipPet` of the already-equipped pet and `unequipPet` with an empty slot are idempotent successes | F6 | If they error, the FE never sends them anyway (toggle decides on the displayed view) [CITED: BE D-15 «idempotenti»] |

## Open Questions (RESOLVED)

1. **Where does the city id come from?** — RESOLVED: `Shop(cities: cities)` from `MainScreen._buildPages` (like `Board`), `currentCityOf` inside the non-visual `ShopPoolLoader`; `ShopCubit.getData(String cityId)` stays Flutter-free (D-01, Claude's discretion).
2. **How to refetch on every open?** — RESOLVED: `initState` already runs on every open (C1); add only the city-change and `ITEM_NOT_IN_SHOP` triggers. No duplicate fetch: the location listener compares `status.location?.id` (not the whole character, which changes on every coin update).
3. **What happens to the buy selection after a reload / city change?** — RESOLVED: `TradeSelection.retainPurchasable(pool)` drops entries absent from the new pool; the sell selection is untouched (owned items stay valid in every city).
4. **Hide empty «Compagni» lists?** — RESOLVED: yes, the dropdown renders only when its list is non-empty (most cities sell no pets); equipment/loot dropdowns unchanged.
5. **Refusals of `equipPet`/`unequipPet`: bubble, inline or banner?** — RESOLVED (default, orchestrator to confirm, C3): Phase 8 banner via `CompanionOutcomeListener`; stale-view codes silent + `refreshCharacter()`.
6. **One pending companion operation or a queue?** — RESOLVED: one in flight per slot, taps while pending ignored (FIFO respected); queue kept as in `SpellsCubit` for structural parity but holding at most one entry.
7. **`hasShop` default when absent?** — RESOLVED: `true` (Pitfall 3); BE field is non-null.
8. **Speed format?** — RESOLVED: `companionSpeedLabel(pet)` → `'Velocità ×${_trim(speedModifier)}'` (2.0 → «×2», 2.5 → «×2,5»), null when `speedModifier == null`; no km/h computation (rule 4; BE: speed = 10 × modifier, not FE business).
9. **Pet images?** — RESOLVED: text-only rows; `imagePath` not selected (D-13, A6). `CachedSvg` only handles SVG, and no pet asset exists.
10. **Repository for the shop?** — RESOLVED: `ShopCubit` keeps calling `KlimmeckGraphQl` directly (same as today and as `TransactionCubit`); a `ShopRepository` refactor is out of scope. `CompanionCubit` gets a `CompanionRepository` (Phase 8 shape, timeout + failure mapping).
11. **Open product question left to the user (non-blocking):** the bubble copy for the other transaction refusals stays the generic line; the planner may keep the four specific lines above as provisional.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter / Dart | all plans | ✓ | 3.35.5 / 3.9.2 | — |
| Node + BE `node_modules/graphql` | `validate_documents.js` (13-10) | ✓ (ran 42/42 OK today against BE `origin/develop` `65ba3d7`) | — | — |
| BE `origin/develop` with Phase 12 | 13-10, 13-11 | ✗ (BE Phase 12 in research; `cityShop` absent from the SDL) | — | Plans 13-01..13-09 run on mocks; 13-10/11 parked |
| Android device + local BE (`adb reverse tcp:3000`) | 13-11 | user-provided | — | none (human checkpoint) |
| Innkeeper role on the device account (Locanda teleport) | 13-11 | user-provided (Phase 10 UAT setup) | — | DB `status.location` edit by the user |

**Missing with no fallback:** BE Phase 12 merge (blocks 13-10/11 only).

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` + `bloc_test` + `mocktail` (versions locked in `pubspec.lock`) |
| Config file | none (default `flutter test`); shared mocks `test/helpers/mocks.dart`, harnesses `test/helpers/journal_harness.dart`, `spells_harness.dart`, `svg_cache_seed.dart`, `landscape.dart`, `test_app.dart` |
| Quick run command | `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test <touched test paths>` |
| Full suite command | `cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide && flutter test` |
| Baseline (2026-11-02, `feat/13-city-shops` = `11dfc6a`) | `flutter test`: **2862 passed, ~67 s**; `flutter analyze`: **51 issues, 0 error, 0 warning** (info only; `avoid_print` in `shop_cubit.dart:25`, `journal_cubit.dart:23,32`); schema check **42/42 OK** vs BE `origin/develop` `65ba3d7` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SHOP-02 | `City.fromJson` parses `size` (unknown → null) and `hasShop` (absent → true) | unit | `flutter test test/models/city_test.dart` | ❌ Wave 1 |
| SHOP-02 | `CityShop.fromJson` parses city id, equipment, loot, pets | unit | `flutter test test/models/city_shop_test.dart` | ❌ Wave 1 |
| SHOP-02 | `GetCityShop` selects `city { id }`, equipment/loot via the item fragments, pets via `PetFragment`; `cities` selects `size hasShop`; no `name` sign (D-02) | unit (document) | `flutter test test/graphql/shop_documents_test.dart` | ❌ Wave 1 |
| SHOP-02 | registry lists `GetCityShop`/`EquipPet`/`UnequipPet`, not the two catalogue queries | unit | `flutter test test/tool/schema_check_documents_test.dart` | ✅ (auto-checks) |
| SHOP-02 | `ShopCubit.getData(cityId)` emits `[ShopLoading, ShopLoadData(cityId…)]`; error → `ShopError`; out-of-order responses dropped | bloc | `flutter test test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart` | ❌ Wave 3 |
| SHOP-02 | `ShopPoolLoader` loads the marker city on mount, reloads on a location change only, does nothing off-city | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_pool_loader_test.dart` | ❌ Wave 3 |
| SHOP-02 | `disabledSatchelPages`: city with `hasShop: false` → `{shop}` only; Board stays enabled (D-04) | unit | `flutter test test/screens/mainScreen/components/satchel_availability_test.dart` | ✅ extend |
| SHOP-02 | `MainScreen` disables the Shop cell on a no-shop city (wiring) | widget | `flutter test test/screens/mainScreen/main_screen_test.dart` | ✅ extend |
| SHOP-03 | codes `ITEM_NOT_IN_SHOP`/`PET_ALREADY_OWNED`/`PET_NOT_OWNED` → enum values | unit | `flutter test test/repository/transaction_failure_test.dart` | ✅ extend |
| SHOP-03 | `shopkeeperRefusalLine`: `shopNotInCity` → null (banner), `itemNotInShop`/`petAlreadyOwned` → specific lines; `transactionNoticeFor` unchanged | unit | `flutter test test/screens/mainScreen/tabs/shop/transactionCubit/transaction_notice_test.dart` | ✅ extend |
| SHOP-03 | `ShopPoolLoader` reloads after `TransactionError(itemNotInShop)` and not after other refusals | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_pool_loader_test.dart` | ❌ Wave 3 |
| SHOP-03 | sell sheet lists a legendary owned item (D-09); `TransactionModal` lets a net-positive sale be signed with an empty wallet (Pitfall 4) | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart` | ✅ / ❌ Wave 4 |
| SHOP-04 | `Pet` parses `speedModifier`, `sellable`; `CharacterAssets.ownedPets` default `[]`, props include it | unit | `flutter test test/models/pet_test.dart test/models/character/character_assets_test.dart` | ❌ Wave 1 |
| SHOP-04 | character fragment selects `pet {…}` and `ownedPets {…}` | unit (document) | `flutter test test/graphql/character_fragment_test.dart` | ✅ extend |
| SHOP-04 | `TransactionItems.toJson` carries `petAssets` with quantity 1; `EquipPetRequest`/`UnequipPetRequest.toJson` | unit | `flutter test test/models/request/transaction_request_test.dart test/models/request/equip_pet_request_test.dart` | ❌ Wave 1 |
| SHOP-04 | `TradeSelection`: totals with pets, `toTransactionItems` split, `togglePet`, `retainPurchasable`; `purchasablePets` hides owned (D-08) | unit | `flutter test test/models/shop/trade_selection_test.dart` | ❌ Wave 4 |
| SHOP-04 | `companionSpeedLabel`: null for `speedModifier == null`, «Velocità ×2,5» | unit | `flutter test test/utils/item_lines_test.dart` | ✅ extend |
| SHOP-04 | `CompanionRow`: name, price, speed line only for mounts, equipped marker | widget | `flutter test test/shared/components/companion_row_test.dart` | ❌ Wave 4 |
| SHOP-04 | `ShopModal` «Compagni»: buy shows pool pets minus owned, sell shows owned with equipped marked, hidden when empty, pencil adds once / rubber removes, filters untouched | widget | `flutter test test/screens/mainScreen/tabs/shop/components/shop_modal_test.dart` | ✅ extend |
| SHOP-04 | `TransactionModal` lists selected pets in Acquisto/Vendita and includes them in the total | widget | `flutter test test/screens/mainScreen/tabs/shop/components/transaction_modal_test.dart` | ❌ Wave 4 |
| SHOP-04 | `petEquipFailureFrom` code map; `CompanionRepository` timeout/declined/exception mapping | unit | `flutter test test/repository/pet_equip_failure_test.dart test/repository/companion_repository_test.dart` | ❌ Wave 2 |
| SHOP-04 | `CompanionCubit`: optimistic equip/unequip, settle on `sync`, rollback + outcome on failure, settledByTimeout, ignored while pending, close() cleanup | bloc | `flutter test test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart` | ❌ Wave 5 |
| SHOP-04 | `CompanionOutcomeListener`: sync on character change, banner via `companionNoticeFor`, stale re-read | widget | `flutter test test/screens/mainScreen/components/companion_outcome_listener_test.dart` | ❌ Wave 5 |
| SHOP-04 | Journal «Compagno» slot: shows equipped pet / empty copy, opens the owned list, tap equips/unequips through the cubit, overlay shown, interactive during travel (D-10) | widget | `flutter test test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart test/screens/mainScreen/tabs/journal/journal_items_test.dart` | ❌ / ✅ extend |
| SHOP-02/03/04 | Documents valid against the merged BE SDL | cross-repo gate | see «Schema gate» below | ✅ tool exists |
| SHOP-02/03/04 | Device E2E | manual | `13-HUMAN-UAT.md` | ❌ Wave 6 |

### Schema gate (plan 13-10, after the BE merge)
```bash
cd /Users/lucatabbia/Personale/Code/Klimmeck-Guide/Klimmeck-Guide
BE=/Users/lucatabbia/Personale/Code/Klimmeck-Guide-BE/Klimmeck-Guide-BE
git -C $BE fetch -q origin develop
SCRATCH=$(mktemp -d); git -C $BE show origin/develop:src/schema.gql > "$SCRATCH/schema.gql"
grep -c "cityShop" "$SCRATCH/schema.gql"                                   # ≥ 1, else STOP (parked)
awk '/^type CityShop/,/^}/' "$SCRATCH/schema.gql"                          # city equipment loot pets
awk '/^enum CitySize/,/^}/' "$SCRATCH/schema.gql"                          # village city capital (A2)
awk '/^type City /,/^}/' "$SCRATCH/schema.gql" | grep -n "size\|hasShop"
awk '/^type CharacterAssets/,/^}/' "$SCRATCH/schema.gql" | grep -n "ownedPets"
awk '/^input TransactionItems/,/^}/' "$SCRATCH/schema.gql" | grep -n "petAssets"
awk '/^type Pet /,/^}/' "$SCRATCH/schema.gql" | grep -n "sellable\|speedModifier"
grep -n "equipPet\|unequipPet" "$SCRATCH/schema.gql"; awk '/^input .*Pet.*/,/^}/' "$SCRATCH/schema.gql"   # align A1
dart run tool/schema_check/dump_documents.dart "$SCRATCH/docs"             # dumped 43 documents
NODE_PATH=$BE/node_modules node tool/schema_check/validate_documents.js "$SCRATCH/schema.gql" "$SCRATCH/docs" | grep -vc OK   # 0
```
Error codes are not in the SDL (they live in `GameRuleErrorCode`, BE `src/gameRules/game-rule-error-code.enum.ts`): read them with `git -C $BE show origin/develop:src/gameRules/game-rule-error-code.enum.ts | grep -n "ITEM_NOT_IN_SHOP\|PET_ALREADY_OWNED\|PET_NOT_OWNED"` (3 lines) and from the BE `BACKEND-NOTES.md` of Phase 12. Gates after: full `flutter test` green; `flutter analyze` 0 error / 0 warning (≤ 51 issues, the `avoid_print` in `shop_cubit.dart` should disappear: expect ≤ 50); new Dart files format-clean; `git log develop..HEAD --format=%B | grep -ciE "co-authored-by|generated with"` → 0.

### Device E2E (plan 13-11, `13-HUMAN-UAT.md`)
Setup: BE `develop` with Phase 12 merged running locally (boot seeds the pools, migrates `ownedPets`, logs the WARN report); Samsung via USB with `adb reverse tcp:3000 tcp:3000`; the device account is innkeeper (Locanda teleport); the test character has ≥ 2 oro (DB seed by the user, placeholders only, never printed).
1. Cold start → the satchel opens; on a city marker with a shop the Shop cell is enabled (SHOP-02).
2. Teleport to a **village** (Talmvere, `talmvereVillage`) → open the shop → only common/uncommon items, «Compagni» shows Cavallo da viaggio with price and «Velocità ×2»; no city name anywhere (SHOP-02, D-02, SHOP-04).
3. Buy the Cavallo da viaggio → bubble success; the Journal «Compagno» slot stays empty (buying never equips, D-08); the buy list no longer shows it (D-08).
4. Journal → tap «Compagno» → the owned list shows Cavallo da viaggio → tap → slot shows it immediately (optimistic) and stays after the subscription (SHOP-04).
5. Teleport to a **city** (e.g. a `*City` of the same region) → different pool, up to rare, no legendary (SHOP-02).
6. Teleport to a **capital** (Valantar) → different pool incl. ultrarare, no legendary; «Compagni» lists Cavallo leggero and Cammello (SHOP-02/04).
7. In Valantar sell the Cavallo da viaggio (marked equipped in the sell sheet) with a wallet below 50 ag if possible (Pitfall 4) → success; the Journal slot empties through the subscription (D-08).
8. Sell an owned legendary item, if the character has one (D-09; otherwise record «not available»).
9. Teleport to **Necrorian** → the Shop cell is disabled, the Board cell is not (D-04).
10. Optional `ITEM_NOT_IN_SHOP`: with the shop page open, the user removes a listed item from that city's pool in the DB (field name from the BE handoff), then buys it → bubble «Questa merce non la tratto», the row disappears after the reload (SHOP-03).
11. Optional: equip / unequip during a travel works (D-10).
Requirement ↔ step map: SHOP-02 (1, 2, 5, 6, 9), SHOP-03 (7, 8, 10), SHOP-04 (2, 3, 4, 6, 7). Tick a requirement only when all its mandatory steps pass.

### Sampling Rate
- **Per task commit:** the touched test files (`flutter test <paths>`, never in background) + `flutter analyze` (0 error / 0 warning).
- **Per wave merge:** `flutter test test/screens/mainScreen test/models test/repository test/graphql test/tool`.
- **Phase gate:** full `flutter test` + schema gate (43 OK) + device E2E before `/gsd-verify-work`.

### Wave 0 Gaps
- [ ] `test/models/city_test.dart`, `test/models/pet_test.dart`, `test/models/city_shop_test.dart`, `test/models/character/character_assets_test.dart`, `test/models/request/transaction_request_test.dart`, `test/models/request/equip_pet_request_test.dart` — SHOP-02/04 models
- [ ] `test/graphql/shop_documents_test.dart` — documents
- [ ] `test/screens/mainScreen/tabs/shop/shopCubit/shop_cubit_test.dart`, `components/shop_pool_loader_test.dart`, `components/transaction_modal_test.dart` — none exist today
- [ ] `test/models/shop/trade_selection_test.dart`, `test/shared/components/companion_row_test.dart`
- [ ] `test/repository/pet_equip_failure_test.dart`, `test/repository/companion_repository_test.dart`
- [ ] `test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart`, `sections/companion_section_test.dart`, `test/screens/mainScreen/components/companion_outcome_listener_test.dart`
- [ ] `test/helpers/mocks.dart`: `MockShopCubit`, `MockCompanionCubit`, `MockCompanionRepository`; `MockKlimmeckGraphQl` covers `getCityShop`/`equipPet`/`unequipPet` automatically (mocktail), register fallback values for `EquipPetRequest`/`UnequipPetRequest`
- [ ] `test/helpers/fixtures/shop_fixtures.dart` — pool JSON (equipment, loot, a mount pet, a non-mount pet), owned/equipped pets
- [ ] Provider updates in `main_screen_test.dart`, `main_screen_quest_results_test.dart`, `authenticated_shell_test.dart`, `journal_harness.dart` (they provide `SpellsCubit` today; add `CompanionCubit`)

## Security Domain

### Applicable ASVS Categories
| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no (unchanged bearer flow) | — |
| V3 Session Management | no | — |
| V4 Access Control | yes | BE owner-only `@OwnsCharacter` on `equipPet`/`unequipPet`/`doTransaction`; FE sends only the current character id and maps `FORBIDDEN`/`UNAUTHENTICATED` (no banner for unauthenticated: the session flow acts) |
| V5 Input Validation | yes | BE validates ids, quantity 1 for pets (`INVALID_QUANTITY`), pool membership (`ITEM_NOT_IN_SHOP`), duplicates (`PET_ALREADY_OWNED`), total cross-check (`TRANSACTION_TOTAL_MISMATCH`); FE never trusts its own lists for authorisation |
| V6 Cryptography | no | — |

### Known Threat Patterns
| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Buying an item outside the pool by crafting a request | Tampering | BE re-reads the pool inside the transaction (BE D-19); FE only displays |
| Double purchase of the same pet (two taps / two devices) | Tampering | BE `PET_ALREADY_OWNED` in the transaction filter; FE hides owned pets and the signature is one-shot (`_showSignature`) |
| Price tampering in `total` | Tampering | BE `TRANSACTION_TOTAL_MISMATCH` with catalogue prices |
| Equipping a pet not owned / of another character | Elevation | BE `PET_NOT_OWNED` / `FORBIDDEN`; FE rollback |
| Leaking server messages to the UI | Information disclosure | classifiers read `extensions.code` only, never `message` |
| Secrets in logs | Information disclosure | remove `print(e.toString())` from `ShopCubit` (Boy Scout); never print payloads; never read `.env` |

## Suggested wave plan

11 plans, sequential on the main tree (REPO-RULES). «Gated» = needs BE Phase 12 merged on BE `develop`.

| Wave | Plan | Content | Files (main) | BE-gated |
|------|------|---------|--------------|----------|
| 1 | **13-01 Models** | `Pet` + `speedModifier`/`sellable`; `CharacterAssets.ownedPets`; `City` + `size` (`CitySizeType?`, `asNameMap`) / `hasShop` (default true); `CityShop`; `TransactionItems.petAssets` (explicit `toJson` maps); `EquipPetRequest`/`UnequipPetRequest` | `lib/models/pet.dart`, `character/character_assets.dart`, `city.dart`, `city_shop.dart`, `request/transaction_request.dart`, `request/equip_pet_request.dart` + tests | no |
| 1 | **13-02 Documents + service** | `PetFragment`; character fragment `pet`/`ownedPets`; `cities` + `size hasShop`; `ShopQueries.getCityShop`; `EquipPet`/`UnequipPet`; registry +3; `KlimmeckGraphQl.getCityShop/equipPet/unequipPet`; document tests. SUMMARY states: the branch now needs BE 12 to run on a device | `lib/graphql/fragments/pet_fragment.dart`, `fragments.dart`, `character_fragment.dart`, `queries/city_queries.dart`, `queries/shop_queries.dart`, `mutations/character_mutations.dart`, `tool/schema_check/schema_check_documents.dart`, `lib/repository/services/graphql/graphql.dart`, `test/graphql/shop_documents_test.dart`, `test/graphql/character_fragment_test.dart` | names agreed, validation in 13-10 |
| 2 | **13-03 Classifiers** | `TransactionFailure` +3; `shopkeeperRefusalLine`; `PetEquipFailure`/`PetEquipException`; `CompanionRepository` (timeout 15 s, declined, mapping) | `lib/repository/transaction_failure.dart`, `pet_equip_failure.dart`, `companion_repository.dart`, `tabs/shop/transactionCubit/transaction_notice.dart`, tests, `test/helpers/mocks.dart` | no |
| 2 | **13-04 Satchel gate** | `disabledSatchelPages` with `hasShop` (Shop only; Board open); MainScreen wiring test | `components/satchel_availability.dart`, `test/.../satchel_availability_test.dart`, `test/screens/mainScreen/main_screen_test.dart` | no |
| 3 | **13-05 Shop call** | `ShopCubit.getData(cityId)` last-wins, `ShopLoadData(cityId, equipment, loot, pets)`, `ShopError` without raw text, no `print`; `ShopPoolLoader` (mount / location change / `itemNotInShop` reload); `Shop(cities:)` + builder reads matching pool; bubble via `shopkeeperRefusalLine`; drop the 2 catalogue documents, service methods, registry entries | `tabs/shop/shopCubit/*`, `tabs/shop/components/shop_pool_loader.dart`, `tabs/shop/shop.dart`, `main_screen.dart`, `queries/equipment_item_queries.dart`, `queries/loot_item_queries.dart`, `graphql.dart`, `tool/schema_check/schema_check_documents.dart`, tests | no (mocks) |
| 4 | **13-06 Trade selection + companion row** | `TradeSelection`, `purchasablePets`; `companionSpeedLabel`; shared `CompanionRow` | `lib/models/shop/trade_selection.dart`, `lib/utils/item_lines.dart`, `lib/shared/components/companion_row.dart`, tests | no |
| 4 | **13-07 Shop sheets with companions** | `ShopModal` «Compagni» (buy: pool minus owned; sell: owned, equipped marked; hidden when empty; heights by open count); `TransactionModal` pets + totals + `canAfford` fix (regression test first); `Shop._onConfirm` via `TradeSelection.toTransactionItems`; D-09 legendary sell test | `tabs/shop/components/shop_modal.dart`, `transaction_modal.dart`, `tabs/shop/shop.dart`, tests (`shop_modal_test.dart`, `transaction_modal_test.dart`) | no |
| 5 | **13-08 Companion cubit** | `CompanionCubit` (single slot, optimistic, token, FIFO, timeout, sync, close); `companionNoticeFor`; `CompanionOutcomeListener` in `MainScreen`; provider in `AuthenticatedShell`; harness/provider updates | `tabs/journal/companionCubit/*`, `components/companion_outcome_listener.dart`, `main_screen.dart`, `screens/auth/authenticated_shell.dart`, `test/helpers/mocks.dart`, `main_screen_test.dart`, `main_screen_quest_results_test.dart`, `authenticated_shell_test.dart`, tests | no |
| 5 | **13-09 Journal «Compagno» slot** | `CompanionSection` (displayed pet / empty copy, sheet of owned pets with `PaperSheetModal`, toggle, overlay, interactive during travel) inserted after «Armatura» | `tabs/journal/sections/companion_section.dart`, `tabs/journal/journal.dart`, `test/helpers/journal_harness.dart`, tests | no |
| 6 | **13-10 Schema gate** | fetch BE, prove names (incl. A1/A2), align documents, 43/43 OK, full suite, analyzer, format, trailers, `13-VALIDATION.md` filled | documents touched only if names differ, `.planning/phases/13-city-shops/13-VALIDATION.md` | **yes** |
| 6 | **13-11 Device E2E + handoff** | `13-HUMAN-UAT.md` (steps above), `BACKEND-NOTES.md` (FE outcome for the BE), requirements mark-complete for passed steps, ROADMAP/STATE closure | `.planning/phases/13-city-shops/13-HUMAN-UAT.md`, `BACKEND-NOTES.md`, `.planning/REQUIREMENTS.md`, `.planning/ROADMAP.md`, `.planning/STATE.md` | **yes** (human checkpoint, `autonomous: false`) |

Dependencies: 13-02 after 13-01 (service parses the models); 13-05 after 13-02/13-03; 13-07 after 13-05/13-06; 13-09 after 13-08; 13-10 after all; 13-11 after 13-10.

## Sources

### Primary (HIGH confidence, read or run in this session)
- FE code: `lib/screens/mainScreen/tabs/shop/**`, `main_screen.dart`, `components/satchel_availability.dart`, `models/quest/board_policy.dart`, `tabs/journal/**` (`journal.dart`, `cubit/journal_cubit.dart`, `spellsCubit/*`, `sections/spells_section.dart`), `repository/{transaction_failure,spell_equip_failure,spells_repository}.dart`, `services/graphql/{graphql,graphql_error_code}.dart`, `graphql/**`, `models/{pet,city,asset_item,asset_quantity,coins}.dart`, `models/character/character_assets.dart`, `models/request/transaction_request.dart`, `shared/components/{item_row,modal/paper_sheet_modal}.dart`, `config/cloudinary_assets.dart`, `tool/schema_check/*`, `screens/auth/authenticated_shell.dart`.
- Flutter SDK 3.35.5 `packages/flutter/lib/src/widgets/page_view.dart:975` (`cacheExtent`).
- Runs: `flutter test` (2862 passed, 67 s), `flutter analyze` (51 info), schema check 42/42 OK vs BE `origin/develop` `65ba3d7`.
- BE SDL `git show origin/develop:src/schema.gql`: `Pet { … speedModifier: Float … }`, `City` without `size/hasShop`, `CharacterAssets.pet: Pet`, `TransactionItems { equipAssets lootAssets }`, `AssetQuantityInput { item: ID quantity: Int! }`, `CommonResponse`.
- BE `.planning/phases/12-negozi-per-citta/12-CONTEXT.md` (D-01..D-21), BE Phase 11 `BACKEND-NOTES.md` §5 (pet prices and `speedModifier`).
- FE `.planning/phases/08-spells-section-journal-tab/08-RESEARCH.md` F3, `10-admin-panel-innkeeper/10-11-PLAN.md`, `10-RESEARCH.md` (registry rule), `13-REPO-RULES.md`.

### Secondary / Tertiary
- None: no web source was needed (no new library).

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new dependency, versions from the local toolchain.
- Architecture: HIGH — every pattern mirrors an existing, tested one (`Board(cities:)`, `SpellsCubit`, `SpellOutcomeListener`, classifiers).
- BE contract names: MEDIUM — from `12-CONTEXT.md`; input type names (A1) and `CitySize` values (A2) unverified until the merge.
- Pitfalls: HIGH — each verified in code (PageView, fragment, `canAfford`, fixtures count, registry test).

**Research date:** 2026-11-02
**Valid until:** BE Phase 12 merge (then re-check A1/A2 in 13-10); otherwise 30 days.
