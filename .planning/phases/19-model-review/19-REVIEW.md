---
phase: 19-model-review
reviewed: 2026-11-11T03:24:54Z
depth: standard
scope: plans 19-01..19-09 (pre-gate wave), git diff 0260b32..HEAD -- lib test tool
files_reviewed: 41
files_reviewed_list:
  - lib/models/active_spell.dart
  - lib/models/asset_quantity.dart
  - lib/models/base_damage.dart
  - lib/models/character/character.dart
  - lib/models/character/character_assets.dart
  - lib/models/character/character_status.dart
  - lib/models/character/legacy_spell_states.dart
  - lib/models/city.dart
  - lib/models/city_shop.dart
  - lib/models/damages.dart
  - lib/models/enemy.dart
  - lib/models/energy_damage.dart
  - lib/models/enums/poi_type.dart
  - lib/models/equipment.dart
  - lib/models/equipment_item.dart
  - lib/models/owned_pet.dart
  - lib/models/pet.dart
  - lib/models/point_of_interest.dart
  - lib/models/quest_result/quest_result.dart
  - lib/models/spell.dart
  - lib/models/spell/spell_state.dart
  - lib/models/spell/spellbook.dart
  - lib/models/weaknesses.dart
  - lib/repository/services/graphql/graphql.dart
  - lib/screens/mainScreen/tabs/journal/components/companion_content.dart
  - lib/screens/mainScreen/tabs/journal/components/owned_companion_row.dart
  - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
  - lib/screens/mainScreen/tabs/journal/spellsCubit/spells_cubit.dart
  - lib/screens/mainScreen/tabs/shop/shop.dart
  - lib/shared/components/cards/card_label.dart
  - lib/shared/components/cards/companion_card.dart
  - lib/shared/components/companion_row.dart
  - lib/shared/components/popup/quest_result_sheet.dart
  - lib/utils/item_lines.dart
  - lib/utils/quest_outcome_lines.dart
  - test/helpers/fixtures/spell_fixtures.dart
  - test/helpers/fixtures/shop_fixtures.dart
  - test/models/character/character_test.dart
  - test/models/character/legacy_spell_states_test.dart
  - test/models/spell/spellbook_test.dart
  - test/models (remaining changed model tests) and test/screens, test/shared, test/utils (changed widget/line tests, read as diffs)
findings:
  critical: 0
  warning: 2
  info: 12
  total: 14
status: issues_found
---

# Phase 19: Code Review Report (pre-gate wave, plans 19-01..19-09)

**Reviewed:** 2026-11-11
**Depth:** standard
**Files Reviewed:** 35 `lib` files in full, the changed tests as diffs (45 test files, the key ones in full)
**Status:** issues_found (no critical, no regression against the BE of today)

## Summary

The diff was read against the real wire of today (`lib/graphql` is untouched; the BE SDL on `origin/develop` was read to check nullability). `flutter analyze --no-fatal-infos` is at the baseline (47 info, 0 warning, 0 error); the working tree shows only ` M pubspec.lock`. No test was run (the orchestrator is running the full suite).

**Window rule (D-15): traced and holding.** Path followed: `character_fragment.dart` (`status.spells` full, `status.spellStates { usages recoveries spell { id } }`, `assets.activeSpells { usages spell {full} }`, `ownedPets { PetFragment.fields }`) -> `Character.fromJson` (`character.dart:29-36`) -> `statusJsonWithLegacySpellStates` -> `CharacterStatus._spellStatesFrom` -> `SpellState.tryFromJson` -> `Spellbook.of` / `SpellsCubit._matches`.

- Known spells: one state per entry of `status.spells`, full catalogue spell kept. No spell is lost for a payload that respects today's SDL.
- Equipped set: `active` = membership in `assets.activeSpells` (entries with a null `spell`, allowed by `ActiveSpell.spell: Spell`, are skipped as before).
- Usages: state by id -> equipped usages -> catalogue `maxUsages` — the same chain as the removed `Spellbook._usagesOf`. Recoveries from the state by id.
- Slot count: still `maxActiveSpells` only.
- Optimistic equip/unequip: `Spellbook.of` overlays `pending` on `state.active`; `SpellsCubit._matches` (`spells_cubit.dart:228-239`) reads the same flag, so `sync`, `_succeed` and the timeout rollback behave as before. The only intended difference is the slot order (D-14: list order, not equip order).
- Subscription and query share `CharacterFragment.fullFields` and both go through `Character.fromJson` (`graphql.dart:280`, `:471`); `User.currentCharacter { id }` yields `status == null` and is unaffected. `CharacterStatus.fromJson` has no other caller.
- Companions: a bare pet falls into the window branch of `OwnedPet.tryFromJson` (xp 0 / life 0); `maxXp` is not selected so `companionXpLine` returns `null` — «Esperienza: 0 / 0» can never be printed. Slot (`_displayedPet`), `CompanionCubit` (reads `assets.pet`) and the shop «già posseduto» / sell list (`ownedCatalogPets`) keep working on the catalogue `Pet`.
- `attack` / `defense` / `rarity` / `petXpGained` are absent today -> `null` / `null` / `null` / `0` -> every new line and the rarity colour stay hidden.

**Display rules:** no arithmetic on the FE (`companionXpLine` prints the served numbers without clamping, `companionXpGainedLine` prints the served gain); the three companion lines and the result line are hidden when the data is absent; the rarity colour comes only from `RarityType.color`; the copy matches REPO-RULES («Esperienza: 40 / 300», «Attacco: tagliente 12, fuoco 5», «Difesa: contundente 4», «Il tuo compagno guadagna 12 PE»).

**Equality:** `props` / `toJson` / `copyWith` are complete for `Pet` (attack, defense, rarity), `OwnedPet`, `Weaknesses`, `Enemy`, `SpellState` (spell, active), `CharacterStatus`, `CharacterAssets`, `QuestResult.petXpGained`, `PointOfInterest`.

The two warnings are gaps of the lenient-parsing rule (D-16), neither introduced by this wave. The info items are dead code and stale comments left by the contraction, plus test-quality notes.

## Warnings

### WR-01: an equipment item with a `null` rarity is kept by the new boundaries and still crashes on `rarity!`

**File:** `lib/models/equipment_item.dart:49-51` (kept), dereferenced at `lib/shared/components/cards/equipment_item_card.dart:102`, `lib/shared/components/equipment_name.dart:30`, `lib/shared/components/popup/equipment_info_sheet.dart:79`
**Reachable:** with the BE of today (and after the merge). Pre-existing, not a regression.
**Issue:** D-16 states «never a `null` enum that a widget dereferences with `!`». The new boundaries (`AssetQuantity.tryFromJson`, `EquipmentItem.tryFromJson`) drop an entry whose rarity name is UNKNOWN (`byName` throws), but an item whose rarity is `null` or absent parses fine (`rarity: null`) and is kept. The SDL declares `EquipmentItem.rarity: String` (nullable), so one equipment document without a rarity in the bag, on the mannequin or in a shop pool throws a null-check error while building the card / row / info sheet. `LootItemCard` already handles it (`lootItem.rarity?.color ?? KlimmeckGuideTheme.deepNight`, `loot_item_card.dart:52`).
**Fix:** make the three readers null-safe like the loot card (no new copy, same colour as `RarityType.common`):
```dart
color: equipmentItem.rarity?.color ?? KlimmeckGuideTheme.deepNight,
```
with one widget test per reader («an equipment without rarity draws its name in the default ink (D-16)»). Alternative if the product prefers dropping: reject `rarity == null` inside `EquipmentItem.tryFromJson` and in `AssetQuantity.tryFromJson` for equipment items.

### WR-02: a pet that throws inside `Pet.fromJson` still takes down the whole character or the whole shop pool

**File:** `lib/models/pet.dart:62-65` (`Pet.tryFromJson`), reached from `lib/models/owned_pet.dart:15` and `:27`, `lib/models/city_shop.dart:25`
**Reachable:** only with malformed data (today and after the merge); the surface grows after the gate, when `maxXp` is selected (`(json["maxXp"] as num)` at `pet.dart:41`).
**Issue:** `Pet.tryFromJson` only checks «map with a string `id`» and then calls the strict `Pet.fromJson`: a non-string `name` / `imagePath`, a non-map `buyPrice` / `sellPrice`, a non-num `maxXp` / `maxLifePoints` throw. Neither `OwnedPet.tryFromJson` nor `CharacterAssets._ownedPetsFrom` nor `CityShop.fromJson` catches, so one malformed owned pet fails `Character.fromJson` (cold start and every `characterUpdated`) and one malformed pool pet fails the shop. Rows 11 and 12 of the MODEL-04 table are covered only for «not a map / no id» (the tests pin exactly those two cases); every other boundary of this wave (`AssetQuantity`, `EquipmentItem`, `City`, `SpellState`) drops the entry on any throw. 19-03-SUMMARY flagged it for 19-04, which left it open.
**Fix:** give the two list boundaries the same guard as the others, leaving `Pet.tryFromJson` (quest prize, strict behind `Quest.tryFromJson`) untouched:
```dart
// owned_pet.dart
static OwnedPet? tryFromJson(Object? json) {
  if (json is! Map<String, dynamic>) return null;
  try {
    return _fromJson(json); // today's body
  } on Object {
    return null;
  }
}
```
and in `CityShop.fromJson` map the pool through a small `_petOrNull` with the same `try`. Tests: «an owned pet with a name that is not a string is dropped and the others stay (D-16)», same for the pool.

## Info

### IN-01: `BaseDamage.fromJson` and `EnergyDamage.fromJson` have no caller left

**File:** `lib/models/base_damage.dart:10-13`, `lib/models/energy_damage.dart:11-14`
**Issue:** after 19-02 `Damages.fromJson` and `Spell.fromJson` use `tryFromJson`; `grep -rnE "(BaseDamage|EnergyDamage)\.fromJson" lib test` finds only the two definitions. They also carry the strict `byName` the phase removed.
**Fix:** delete both factories (Boy Scout), or rename `tryFromJson` as the only reader.

### IN-02: dead nullable `usages` and its fallbacks after the single state list

**File:** `lib/models/spell/spellbook.dart:32`, `:52` (`final int? usages`), `lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart:29-34`, `lib/models/request/participant_draft.dart:101`, `lib/utils/spell_lines.dart:18`
**Issue:** `Spellbook.of` now always supplies `state.usages` (an `int`), yet `SpellbookEntry.usages` / `SpellSlot.usages` (for a filled slot) stay `int?`, `SpellRecoveryCubit.inputsOf` keeps `entry.usages ?? entry.spell.maxUsages ?? 0` under the comment «Senza stato di recupero gli usi sono al massimo (fallback D-02/D-03)», `participant_draft` keeps `slot.usages ?? 0`, and `spell_lines.dart:18` still says «senza `usages` (backend pre-9.1) vale il massimo». The fallback table now lives only in the window reader.
**Fix:** make `SpellbookEntry.usages` non-null, drop the two `??` chains and the two stale comments (can ride with 19-11, when the reader goes).

### IN-03: the third branch of the `status` switch throws by passing a non-map on purpose

**File:** `lib/models/character/character.dart:35`
**Issue:** `final status => CharacterStatus.fromJson(status)` exists only to raise a `TypeError` through an implicit downcast of a `dynamic`; the intent («a non-map status stays an error») is invisible to the reader.
**Fix:** `_ => throw const FormatException('status is not a map')` (the caller `_characterFrom` already wraps every error), or let it go with the window wiring at 19-11.

### IN-04: the window reader copies `recoveries` verbatim — one unreadable instant drops a known spell

**File:** `lib/models/character/legacy_spell_states.dart:26`, `:66-69`
**Reachable:** not with the BE of today (`recoveries: [DateTime!]!`). Already ruled by the orchestrator (19-08-SUMMARY: «the reader is left as it is»).
**Issue:** before, a malformed legacy state was dropped and the spell stayed in the Journal with the fallback usages; now the built entry fails `SpellState.tryFromJson` and the spell disappears. Recorded here only so the ruling is traceable from the review.
**Fix:** none requested; if ever wanted, filter `recoveries` to parsable strings inside `_recoveriesOf`.

### IN-05: an equipped spell that is not in `status.spells` no longer fills a slot nor counts toward «slots full»

**File:** `lib/models/character/legacy_spell_states.dart:21-29`, `lib/models/spell/spellbook.dart:84-87`
**Reachable:** only with inconsistent data today (the BE equip filter requires a known spell; `addedSpell` of equipment never enters `activeSpells`); impossible by construction after the merge.
**Issue:** the old `Spellbook` built the slots from `assets.activeSpells` regardless of the known list; the single list is built from `status.spells`, so such an entry vanishes and `intentFor` could answer `equip` where the BE answers «slots full» (the cubit then rolls back with the BE error — no stuck state).
**Fix:** none needed; noted as the one behavioural difference of the window besides the D-14 order.

### IN-06: entries dropped by the new boundaries leave no trace

**File:** `lib/repository/services/graphql/graphql.dart:318` (cities), `lib/models/asset_quantity.dart:18-25`, `lib/models/equipment_item.dart:58-65`, `lib/models/city.dart:60-67`
**Issue:** the `on Object` catches follow the existing project pattern (`SpellState.tryFromJson`, `PendingRequest.tryFromJson`) and hide no programming error that a test would not catch, but a city missing from the Map or an item missing from the bag is now silent. The same file already logs the analogous case (`appLog('[Innkeeper] skipped $skipped malformed queue entries')`, `graphql.dart:262`). Also, `getCities` now returns an empty list when every city is dropped, where a `null` payload throws «No cities found».
**Fix:** in `getCities`, log the count of dropped cities with `appLog` (no data in the message); optional for the item boundaries.

### IN-07: `CharacterAssets.toJson` is asymmetric

**File:** `lib/models/character/character_assets.dart:50-51`
**Issue:** `"pet": pet?.id` (an id) next to `"ownedPets": [... owned.toJson()]` (full entries): the output cannot be read back by `fromJson` (`Pet.fromJson` on a string throws). No reader exists today; the `pet` half is pre-existing.
**Fix:** write `pet?.toJson()` when the file is touched at the gate, or leave both as ids.

### IN-08: four labels on the companion card — legibility is not what the test pins

**File:** `lib/shared/components/cards/companion_card.dart:46-53`, `test/shared/components/cards/companion_card_test.dart:150`
**Reachable:** only after the merge (attack / defense served).
**Issue:** each `CardLabel` is `cardSize / 6` high with `AutoSizeText(minFontSize: 4, maxLines: 1)`; «Attacco: tagliente 12, perforante 8, fuoco 5» on a square parchment shrinks toward 4 px instead of overflowing, so «four labels fit the parchment without overflow (D-13)» can never fail on text length — it pins the count of labels, not that they can be read.
**Fix:** add the card with a long attack line to the device E2E checklist of 19-13; rename the test to what it asserts («four labels are laid out without a layout exception»).

### IN-09: two near-duplicate cases in `pet_test.dart`

**File:** `test/models/pet_test.dart:99` and `:106`
**Issue:** «an attack that is not a map is null (D-12)» and «a non-map attack is null (D-16)» assert the same rule on the same parser.
**Fix:** keep one (the `(D-16)` one also covers the list value).

### IN-10: `throwsA(anything)` for the strict location

**File:** `test/models/point_of_interest_test.dart:94`
**Issue:** «a malformed location still throws (D-17)» accepts any throw, including one from an unrelated line of `fromJson`.
**Fix:** `throwsA(anyOf(isA<TypeError>(), isA<RangeError>()))`, or split the five inputs by the error they raise.

### IN-11: a test literal split in two to stay out of a leftover grep

**File:** `test/models/character/character_assets_test.dart:9-11`
**Issue:** `const _equippedListKey = 'active' 'Spells';` exists to keep the gate grep (`activeSpells` absent from `lib test tool`) clean. It works, but the next reader will not find the key by searching for it.
**Fix:** keep it, with the existing doc comment saying explicitly that the split is for the 19-11 leftover grep; or delete the two cases with the window reader.

### IN-12: stale `dynamic city` in `PointOfInterest.copyWith`

**File:** `lib/models/point_of_interest.dart:52`
**Issue:** the phase removed `dynamic quest` from the same signature and left `dynamic city` (noted in 19-01-SUMMARY as out of scope); the file was touched, so the Boy Scout rule applies.
**Fix:** `City? city`.

---

_Reviewed: 2026-11-11_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
