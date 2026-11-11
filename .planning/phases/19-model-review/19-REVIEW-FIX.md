---
phase: 19-model-review
fixed_at: 2026-11-11
review_path: .planning/phases/19-model-review/19-REVIEW.md
iteration: 1
scope: rulings of the orchestrator on the pre-gate wave (plans 19-01..19-09)
findings_total: 14
findings_in_scope: 5
fixed: 5
skipped: 0
closed_by_ruling: 9
status: all_fixed
---

# Phase 19: Code Review Fix Report (pre-gate wave)

**Fixed at:** 2026-11-11
**Source review:** `.planning/phases/19-model-review/19-REVIEW.md`
**Iteration:** 1

**Summary:**

- Findings in the review: 14 (0 critical, 2 warning, 12 info)
- Ruled FIX by the orchestrator: 5 (WR-01, WR-02, IN-01, IN-02, IN-06) — all fixed
- Closed by ruling (no code change): 9 (IN-03, IN-04, IN-05, IN-07..IN-12)
- Skipped: 0

## Findings

| Finding | Status | Commits | Notes |
|---------|--------|---------|-------|
| WR-01 `null` equipment rarity crashes on `rarity!` | fixed | `2342266` (test), `26332e5` (fix) | `rarity?.color ?? KlimmeckGuideTheme.deepNight` at the three sites |
| WR-02 a pet that throws takes down the character / the pool | fixed | `5f5556c` (test), `29819bb` (fix) | `Pet.tryFromEntryJson` used by owned pets, shop pool and the equipped pet |
| IN-01 unused `BaseDamage.fromJson` / `EnergyDamage.fromJson` | fixed | `94f8639` | both factories deleted, no caller in `lib test tool` |
| IN-02 dead nullable `usages` and stale comments | fixed | `eb07ccf` | types tightened (4 files), see below for what stays nullable |
| IN-03 third branch of the `status` switch | closed by ruling | — | goes with the window wiring at the gate (19-11) |
| IN-04 window reader copies `recoveries` verbatim | closed by ruling | — | leniency of the temporary reader, deleted at the gate |
| IN-05 equipped spell missing from `status.spells` | closed by ruling | — | inconsistent data only, impossible after the merge |
| IN-06 dropped cities leave no trace | fixed | `bf4eb51` (test), `2a5520e` (fix) | `appLog('[Cities] skipped N malformed cities')` |
| IN-07 `CharacterAssets.toJson` asymmetric | closed by ruling | — | no reader exists; touched at the gate |
| IN-08 four labels on the companion card | closed by ruling | — | legibility of long attack lines goes to the device checklist of 19-13 |
| IN-09 near-duplicate cases in `pet_test.dart` | closed by ruling | — | titles are truthful, nothing changed |
| IN-10 `throwsA(anything)` for the strict location | closed by ruling | — | title is truthful, nothing changed |
| IN-11 test literal split for the leftover grep | closed by ruling | — | title is truthful, nothing changed |
| IN-12 stale `dynamic city` in `copyWith` | closed by ruling | — | not a test title, nothing changed |

## Fixed Issues

### WR-01: an equipment item with a `null` rarity crashes on `rarity!`

**Files modified:** `lib/shared/components/cards/equipment_item_card.dart`, `lib/shared/components/popup/equipment_info_sheet.dart`, `lib/shared/components/equipment_name.dart`
**Tests:** `test/shared/components/cards/equipment_item_card_test.dart`, `test/shared/components/popup/equipment_info_sheet_test.dart`, `test/shared/components/equipment_name_test.dart` (new) — «a null rarity falls back to the default ink (D-16)» in each, plus one case pinning the rarity colour of `EquipmentName`.
**Commits:** `2342266` (RED: three «Null check operator used on a null value»), `26332e5`
**Applied fix:** the three readers use `rarity?.color ?? KlimmeckGuideTheme.deepNight`, the same fallback as `loot_item_card.dart`. No new copy, no visual change for an item with a rarity.
**Notes:** `dart format` on the touched files reflowed two untouched members (`_cardBackgroundUrl` in the card, the constructor of `EquipmentName`). `EquipmentName` has no caller in `lib` today: fixed as ruled, the dead widget itself is left alone.

### WR-02: a pet that throws inside `Pet.fromJson` takes down the character or the shop pool

**Files modified:** `lib/models/pet.dart`, `lib/models/owned_pet.dart`, `lib/models/city_shop.dart`, `lib/models/character/character_assets.dart`
**Tests:** `test/models/owned_pet_test.dart` (five malformed fields + the bare window pet), `test/models/character/character_assets_test.dart` («a malformed owned pet is dropped (D-16)», «a malformed equipped pet is null (D-16)»), `test/models/city_shop_test.dart` («a malformed pool pet is dropped (D-16)»)
**Commits:** `5f5556c` (RED: 9 cases), `29819bb`
**Applied fix:** one boundary reader, `Pet.tryFromEntryJson` (`tryFromJson` behind a `try … on Object`), used by `OwnedPet.tryFromJson` (both the Phase 19 shape and the window branch), by the `CityShop` pets pool and by the equipped `CharacterAssets.pet` (malformed, not a map or without a string id → `null`). `Pet.tryFromJson` and `Pet.fromJson` are unchanged, so quest prizes stay strict behind `Quest.tryFromJson`.
**Why the catch and not shape checks:** the throwing surface spans `name`, `imagePath`, `maxXp`, `maxLifePoints`, `speedModifier`, `sellable`, both prices (inside `Coins.fromJson`) and both damages; explicit checks would duplicate the whole parser. The catch follows the existing boundaries (`AssetQuantity`, `EquipmentItem`, `City`, `SpellState`).

### IN-01: `BaseDamage.fromJson` and `EnergyDamage.fromJson` have no caller

**Files modified:** `lib/models/base_damage.dart`, `lib/models/energy_damage.dart`
**Commit:** `94f8639`
**Applied fix:** both factories deleted; `grep -rnE "(BaseDamage|EnergyDamage)\.fromJson" lib test tool` prints nothing.

### IN-02: dead nullable `usages` and its fallbacks

**Files modified:** `lib/models/spell/spellbook.dart`, `lib/screens/mainScreen/tabs/journal/spellRecoveryCubit/spell_recovery_cubit.dart`, `lib/utils/spell_lines.dart`, `test/screens/mainScreen/tabs/journal/components/known_spell_row_test.dart`
**Commit:** `eb07ccf`
**Applied fix (types changed, 4 files):** `SpellbookEntry.usages` is `int`; `SpellSlot.filled` requires an `int`; `SpellRecoveryCubit.inputsOf` reads `entry.usages` without the `?? maxUsages ?? 0` chain and loses the stale «fallback D-02/D-03» comment; the «backend pre-9.1» comment of `spellUsagesLabel` now names the live reason of its fallback.
**Left as it is, on purpose:**
- `SpellSlot.usages` stays `int?` (an empty slot has none), so `participant_draft.dart:101` keeps `slot.usages ?? 0`: the type does not guarantee the value there.
- `spellUsagesLabel({required int? usages})` keeps its fallback to `maxUsages`: `spells_section.dart:192` passes `entry?.usages`, `null` for a spell that is not in the character's book.
- `spell_recovery_status.dart:51` («pre-9.1») was not named by the review and describes a live branch (no recovery instants): untouched.

### IN-06: entries dropped by `getCities` leave no trace

**Files modified:** `lib/repository/services/graphql/graphql.dart`
**Tests:** `test/repository/services/graphql/graphql_get_cities_test.dart` — «getCities logs how many cities it dropped, never their data (D-16)», «getCities logs nothing when every city parses (D-16)»
**Commits:** `bf4eb51` (RED: `Expected ['[Cities] skipped 2 malformed cities']`, actual `[]`), `2a5520e`
**Applied fix:** `appLog('[Cities] skipped $skipped malformed cities')` when at least one city is dropped, same shape as the innkeeper queue. The innkeeper log has no test; the two cases were added anyway (TDD), capturing `debugPrint` as `app_log_test.dart` does.

## Verification

- Targeted suites after each fix: green.
- `flutter analyze --no-fatal-infos`: 47 info, 0 warning, 0 error (baseline).
- `sh tool/hardening_check.sh`: `hardening_check: OK`.
- Full suite: `+4207 All tests passed!` (baseline `+4192`, 15 new cases: 4 WR-01, 9 WR-02, 2 IN-06).
- Window rule (D-15): nothing under `lib/graphql` changed.

---

_Fixed: 2026-11-11_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
