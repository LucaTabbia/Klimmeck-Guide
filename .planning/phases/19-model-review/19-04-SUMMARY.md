---
phase: 19-model-review
plan: 04
subsystem: models
tags: [models, pets, owned-pet, window-reader, lenient-parsing, journal, shop, tdd]
requires: ["19-03"]
provides:
  - "Pet.attack / Pet.defense (Damages?, absent or non-map → null) and Pet.rarity (RarityType?, lenient through asNameMap); xp, currentLifePoints, damages removed from the model"
  - "OwnedPet { pet, xp, currentLifePoints } with OwnedPet.tryFromJson(Object?) and the single window branch for a bare catalogue pet (xp 0, life 0)"
  - "CharacterAssets.ownedPets: List<OwnedPet> (malformed entry dropped, non-list → empty) and the getter ownedCatalogPets: List<Pet>"
  - "Fixtures: petJson(maxXp, attack, defense, rarity) written only when non-null; ownedPetJson({pet, xp, currentLifePoints})"
affects: [19-05, 19-11, 19-12]
tech-stack:
  added: []
  patterns: ["entry model with tryFromJson + one commented window branch for the wire of today", "catalogue getter on the owner so downstream consumers keep List<Pet>"]
key-files:
  created:
    - lib/models/owned_pet.dart
    - test/models/owned_pet_test.dart
  modified:
    - lib/models/pet.dart
    - lib/models/character/character_assets.dart
    - lib/screens/mainScreen/tabs/journal/sections/companion_section.dart
    - lib/screens/mainScreen/tabs/journal/components/companion_content.dart
    - lib/screens/mainScreen/tabs/shop/shop.dart
    - test/helpers/fixtures/shop_fixtures.dart
    - test/models/pet_test.dart
    - test/models/character/character_assets_test.dart
    - test/screens/mainScreen/tabs/journal/companionCubit/companion_cubit_test.dart
    - test/screens/mainScreen/tabs/journal/sections/companion_section_test.dart
    - test/screens/mainScreen/tabs/shop/shop_test.dart
    - test/screens/mainScreen/components/companion_outcome_listener_test.dart
decisions:
  - "A pet attack / defense that is present but not a map reads as null (same as absent), so Pet.fromJson cannot throw on those two fields through the shop pool or the owned list"
  - "CharacterAssets.toJson writes the owned pets as full entries (OwnedPet.toJson), no longer as a list of ids"
  - "OwnedCompanionRow keeps its Pet parameter: CompanionContent destructures the entry (for (final OwnedPet(:pet) in owned))"
metrics:
  duration: "~15 min"
  completed: 2026-11-11
  tasks: 2
  files: 14
---

# Phase 19 Plan 04: Catalogue pet with attack / defense / rarity and owned pets as entries — Summary

The catalogue `Pet` carries `attack`, `defense` and a lenient `rarity` instead of the per-character fields, and the owned pets are `OwnedPet { pet, xp, currentLifePoints }` entries read through `OwnedPet.tryFromJson`, with one window branch that still accepts the bare pet maps of the BE of today — no file under `lib/graphql` touched, nothing visible changed.

## Commits

| # | Hash | Subject |
|---|------|---------|
| 1 | `3aced7e` | test(models): expect pet attack and defense |
| 2 | `8841e5a` | feat(models): give the catalogue pet attack and defense |
| 3 | `68e4fa8` | test(models): expect owned pets as entries |
| 4 | `89c12cc` | feat(models): read owned pets as entries with their state |

Trailer check after every commit: `0`.

## RED evidence

**Task 1** — `flutter test test/models/pet_test.dart` → `+0 -1: Some tests failed.` Compile failure of the file, as the plan expected: `The getter 'attack' isn't defined for the type 'Pet'`, `The getter 'defense' …`, `The getter 'rarity' …`, and the new named parameters of the fixture are fine. The cases of the new group were not observed individually in RED (same file); the pre-existing cases of the file stayed untouched (none of them pinned `xp`, `currentLifePoints` or `damages`, so nothing had to be removed).

**Task 2** — the six files run one by one:

- `owned_pet_test.dart`: compile failure — `Error when reading 'lib/models/owned_pet.dart': No such file or directory`, `Undefined name 'OwnedPet'`.
- `character_assets_test.dart`: compile failure — `The getter 'pet' isn't defined for the type 'Pet'`, `The getter 'xp' isn't defined for the type 'Pet'`, `The getter 'ownedCatalogPets' isn't defined for the type 'CharacterAssets'`.
- `companion_section_test.dart`: `+0 -1` in `setUpAll` — the entries are read as broken bare pets: `type 'Null' is not a subtype of type 'String'` (the entry has no top-level `id`).
- `companion_cubit_test.dart`: `+2 -11`, same `type 'Null' is not a subtype of type 'String'` while building the character.
- `companion_outcome_listener_test.dart`: `+0 -1` (loading: the top-level character fixture throws the same cast error).
- `shop_test.dart`: `+2 -3` — «a pet owned as an entry is not purchasable (D-03)», «a pet bought meanwhile leaves the purchase selection (D-08)», «a pet that left the inventory leaves the sale selection (D-07)», same cast error.

No case of the two tasks was green at the first run except the pre-existing ones.

## Readers of the removed pet fields

`grep -rnE "\.damages|\.xp\b|\.currentLifePoints|\.maxXp" lib | grep -i pet` printed only lines of `lib/models/pet.dart` itself (ctor and `copyWith`): no reader outside the model, as expected. `Pet(` is constructed only inside the model (lib and test).

## The window branch (D-15, deleted RED-first in 19-11)

```dart
    // Finestra (BE prima della Phase 19): un compagno a catalogo nudo.
    // Ramo cancellato al gate (piano 19-11).
    final bare = Pet.tryFromJson(json);
    return bare == null
        ? null
        : OwnedPet(pet: bare, xp: 0, currentLifePoints: 0);
```

It is the only legacy reader of the pets (`grep -c "Pet.tryFromJson(json)" lib/models/owned_pet.dart` = 1). The recorded old-shape payload of `test/graphql/character_fragment_test.dart` (untouched) passes through it.

## Orchestrator addition (not a deviation)

On the note of the 19-03 executor, relayed by the orchestrator: `Pet.fromJson` reads `attack` / `defense` through `_damagesFrom(Object?)`, which returns `null` for anything that is not a map, so a present-but-malformed value can no longer throw through the shop pool (`Pet.tryFromJson`) or the owned list. Two pinned tests in the group `'attack and defense (Phase 19)'`: «a non-map attack is null (D-16)» and «a non-map defense is null (D-16)» (an int / a string, and a list — the pet still parses). They sit beside the plan's «an attack that is not a map is null (D-12)». `Pet.tryFromJson` itself is unchanged (map with a string `id`).

## Tests and gates

| Command | Result |
|---------|--------|
| `flutter test test/models test/screens/mainScreen/tabs/shop test/shared/components` (Task 1 verify) | `+1221: All tests passed!` |
| `flutter test test/models test/screens/mainScreen/tabs/journal test/screens/mainScreen/tabs/shop test/screens/mainScreen/components test/shared/components test/graphql/character_fragment_test.dart` (Task 2 verify + plan `<verification>`, plus `test/shared/components`) | `+1632: All tests passed!` |
| `flutter analyze --no-fatal-infos` (after each GREEN) | `47 issues found.` — info only, `ANALYZE_GATE_OK` (baseline 47 info / 0 warning / 0 error) |
| `sh tool/hardening_check.sh` | exit 0 |

The full `flutter test` was not run (orchestrator instruction).

## Acceptance results

Task 1: `final Damages? attack` 1 · `final Damages? defense` 1 · removed-field grep (`currentLifePoints|\bdamages\b|final int\? xp`, imports excluded) 0 · `final int? maxXp` 1 · `final RarityType? rarity` 1 · `RarityType.values.asNameMap()` 1 · `RarityType.values.byName` 0 · in `pet_test.dart`: `D-20)` 4, «unknown rarity is null (D-20)» 1, `D-12` 6, `D-03` 2 · `git diff HEAD~2 --stat -- lib/graphql` empty.

Task 2: `static OwnedPet? tryFromJson` 1 · `Pet.tryFromJson(json)` 1 · in `character_assets.dart`: `OwnedPet.tryFromJson` 1, `final List<OwnedPet> ownedPets` 1 · `ownedCatalogPets` in `shop.dart` 1 · `currentLifePoints` under `lib/screens lib/shared lib/utils` on an «owned» line 0 (D-18) · `ownedPetJson` in the fixtures 1 · `D-03` in `owned_pet_test.dart` 5, `D-15)` 1 · `D-03` in `character_assets_test.dart` 6 · `git diff HEAD~2 --stat -- lib/graphql lib/screens/mainScreen/tabs/journal/companionCubit lib/models/shop` empty.

All single-line greps matched without `grep -A3`. Over the whole plan `git diff HEAD~4 --stat -- lib/graphql` is empty; `git status --short` → ` M pubspec.lock` only.

## Files formatted

`dart format` one by one on every touched file. Reflowed: `lib/models/owned_pet.dart` (the two `OwnedPet(...)` returns of the skeleton break over 80 columns — content identical to the plan's `<interfaces>`), `companion_cubit_test.dart` and `companion_outcome_listener_test.dart` (only the edited `ownedPets` literal). Every other file was already clean after the edit.

## Deviations from Plan

None that needed a rule — plan executed as written. Notes:

- `companion_content.dart`: the loop is `for (final OwnedPet(:pet) in owned)` so the body of the row (key, `pet`, comparisons, `onTap`) is byte-identical to before; it reads `owned.pet.id` as the plan asks, through the pattern.
- `pet_test.dart`: no existing assertion pinned the three removed fields, so nothing was deleted there; `character_assets_test.dart`: the three old `ownedPets` cases (D-10, D-11, D-08 titles) are replaced by the six `(D-03)` cases — the «absent → empty» and «a sale re-renders» expectations live on inside «an owned list that is not a list is empty (D-03)» and «the owned entries are part of the props (D-03)».
- The new shop case asserts on the `pets` handed to `ShopModal` (buy sheet empty, sell sheet = the catalogue horse) for a character owning the horse as an entry with `xp` 40.
- Two long test titles are split by the formatter over two adjacent string literals; the title text is intact.

## Notes for the next plans

- **19-05** (`companionXpLine`, attack / «Difesa» lines, rarity on card and rows): `OwnedCompanionRow` still takes `Pet pet`; `CompanionContent.owned` is already `List<OwnedPet>`, so handing the row the entry is a change of the loop at `companion_content.dart` (today `for (final OwnedPet(:pet) in owned)`) and of the row's parameter only. `owned.xp` + `owned.pet.maxXp` feed the xp line; before the gate `maxXp` is never selected → `null` → the line must stay hidden (T-19-14: the window zeros must never be printed).
- `Pet.attack` / `Pet.defense` are `Damages?` whose lists hold only entries with a known type (19-02 boundary): `petAttackLine` / `petDefenseLine` can index `type!` safely and must hide on `null` as on empty. `Pet.rarity` is `null` against the BE of today (not selected until 19-11).
- `CharacterAssets.toJson()['ownedPets']` is now a list of entry maps (`{pet, xp, currentLifePoints}`), not of ids; no reader of that key exists in `lib` or `test` today.
- `CharacterAssets.ownedPets` is unmodifiable; `ownedCatalogPets` builds a fresh list at every call (shop only) — fine for the `setEquals` on ids, do not use it as an Equatable prop.
- **19-11** (gate): delete the window branch RED-first (flip «a bare catalogue pet is read as an entry … (D-15)» to «… is null»), move the recorded payload of `character_fragment_test.dart` to entries, select `ownedPets { pet { … } xp currentLifePoints }` and `attack defense maxXp rarity` in `PetFragment`.
- Still strict in `Pet.fromJson` (outside this plan's scope): a non-string `name` / `imagePath`, a non-map `buyPrice` / `sellPrice`, a non-num `maxXp` / `speedModifier` throw; `CharacterAssets.pet` (equipped) is still read with `Pet.fromJson` behind a `!= null` check only.

## Known Stubs

None. (`OwnedPet.currentLifePoints` is parsed and displayed nowhere by decision D-18.)

## Threat Flags

None — no new surface; T-19-13..16 and T-19-55 are covered by the tests above.

## Self-Check: PASSED

- Created files exist: `lib/models/owned_pet.dart`, `test/models/owned_pet_test.dart`.
- Commits `3aced7e`, `8841e5a`, `68e4fa8`, `89c12cc` are in `git log`.
