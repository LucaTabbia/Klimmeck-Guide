---
phase: 13-city-shops
plan: 04
subsystem: satchel
tags: [satchel, availability, city-shop, has-shop, tdd]
requires:
  - 13-01 (City.hasShop, default true when absent)
provides:
  - disabledSatchelPages closes only the Shop page on a city whose hasShop is false (D-04)
  - MainScreen wiring tests for a shopless city marker
affects: [13-07, 13-10, 13-11]
tech-stack:
  added: []
  patterns:
    - "satchel gate resolves the current city once with currentCityOf and reads the backend flag City.hasShop"
key-files:
  created:
    - .planning/phases/13-city-shops/13-04-SUMMARY.md
  modified:
    - lib/screens/mainScreen/components/satchel_availability.dart
    - test/screens/mainScreen/components/satchel_availability_test.dart
    - test/screens/mainScreen/main_screen_test.dart
decisions:
  - "disabledSatchelPages uses currentCityOf instead of isOnCityMarker (the import of board_policy.dart stays); the two result sets are private top-level consts _boardAndShop and _shopOnly"
metrics:
  duration: ~4 min
  completed: 2026-11-02
  tasks: 2
  files: 3
---

# Phase 13 Plan 04: Satchel gate on City.hasShop Summary

`disabledSatchelPages` now reads the backend flag `City.hasShop`: on the marker of a shopless city (Necrorian, or a pool emptied in the DB) only the Shop page is disabled and the Board stays open; off-city, travelling and awaiting aid still close both (Phase 7 D-12, Phase 9 D-16). `MainScreen` needed no change: its consumers already take the `Set<int>`.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | d0ffff3 | test(satchel): expect the shop closed where the city has none |
| 1 GREEN | e3c3b0c | feat(satchel): close the shop on cities without one |
| 2 | e658896 | test(satchel): prove the shopless city wiring on the main screen |

## RED failures observed

- Task 1: «city shop flag a city without a shop disables only the Shop page (D-04)» failed with `Expected: Set:[5]  Actual: Set:[]` (12 passed, 1 failed).
- Task 1, green at first run (regression guards on behaviour that already held): «keeps the Board page open (D-04)» (the old rule returned `{}` on any city marker), «while travelling disables Board and Shop (Phase 7 D-12)», «while awaiting aid disables Board and Shop (Phase 9 D-16)», «a city with hasShop true keeps every page open (D-04)».
- Task 2: green at first run: wiring pre-existing. `MainScreen` already forwards `state.cities` to `disabledSatchelPages` in the builder and in `_isPageDisabled`, and `SatchelMenu` / `MenuBackground` take the resulting `Set<int>`; Task 1 made the rule. No `fix(satchel)` commit needed.

## Created names and signatures

- `lib/screens/mainScreen/components/satchel_availability.dart`:
  - `const Set<int> _boardAndShop = {SatchelLayout.boardPageIndex, SatchelLayout.shopPageIndex};`
  - `const Set<int> _shopOnly = {SatchelLayout.shopPageIndex};`
  - `Set<int> disabledSatchelPages({required PointOfInterest? location, required List<City> cities, required bool isTravelling, bool isAwaitingAid = false})` (signature unchanged): `currentCityOf(cities, location)` null / travelling / awaiting aid → `_boardAndShop`; otherwise `city.hasShop ? const {} : _shopOnly`.
- `test/screens/mainScreen/components/satchel_availability_test.dart`: top-level helper `City shoplessCity(String markerId)` (id `city-necrorian`, `hasShop: false`); group `'city shop flag'` with 5 tests (marker id `necrorian-marker`; the hasShop-true case uses `city-talmvere` / `talmvere-marker`).
- `test/screens/mainScreen/main_screen_test.dart`, group `'satchel wiring'`: second city in `cities` (`id: 'city-no-shop'`, `hasShop: false`, marker `city-marker-no-shop` at `[3.0, 4.0]`); 3 tests «on a city without a shop the Negozio item does nothing (D-04)», «… the Bacheca item still opens the board (D-04)», «… only the shop cell looks disabled (D-04)».

## Verification

- `flutter test test/screens/mainScreen/components/satchel_availability_test.dart`: 13 passed.
- `flutter test test/screens/mainScreen/main_screen_test.dart test/screens/mainScreen/components`: 149 passed.
- `flutter test test/screens/mainScreen` (plan verification): 823 passed.
- `flutter analyze`: 51 issues, all info, 0 error, 0 warning (baseline unchanged).
- `dart format` on the 3 touched files one by one (all clean before the edit; only the new test code was reflowed).
- Acceptance greps: `hasShop` 2, `currentCityOf` 1, `CityType` 0 in the lib file; `(D-04)` 3 in each test file; `city-marker-no-shop` 4 in `main_screen_test.dart`.

## Deviations from Plan

None - plan executed exactly as written. Bookkeeping uses the orchestrator's progress number 3/11 instead of the plan's 04/11.

## Known Stubs

None.

## Self-Check: PASSED

The lib file and both test files exist; commits d0ffff3, e3c3b0c, e658896 are in `git log`.
