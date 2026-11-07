---
phase: 17-unlockable-lore
plan: 08
subsystem: map
tags: [map, unknown-city, cities-refresh, tdd]
requires:
  - phase: 17-02
    provides: "CharacterStatus.unlockedLore (List<String>) on every Character read and characterUpdated"
  - phase: 17-06
    provides: "BlocListener<CharacterCubit> on the unlockedLore set (Library pattern)"
provides:
  - "UnknownCityModal(cityName:) with static const line = 'Non conosci ancora questa città.'"
  - "WorldMap._openCityLore: null relatedLore -> UnknownCityModal, no lore(id) read; _showPaperSheet(Widget) shared with CityModal"
  - "MainScreenCubit.refreshCities(): silent re-read of cities, never MainScreenLoading"
  - "MainScreen BlocListener<CharacterCubit> with listenWhen _hasUnlockedLoreChanged -> refreshCities()"
affects: [17-10]
tech-stack:
  added: []
  patterns: ["silent refresh: no-op before the first load, emit only on a different list, errors swallowed with debugPrint"]
key-files:
  created:
    - lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart
    - test/screens/mainScreen/tabs/map/components/unknown_city_modal_test.dart
    - test/screens/mainScreen/cubit/main_screen_cubit_test.dart
  modified:
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - lib/screens/mainScreen/cubit/main_screen_cubit.dart
    - lib/screens/mainScreen/main_screen.dart
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
    - test/screens/mainScreen/main_screen_test.dart
key-decisions:
  - "An unknown city (relatedLore == null) opens the same paper sheet with UnknownCityModal; the bottom-sheet call lives once in _showPaperSheet(Widget)"
  - "refreshCities compares the lists with listEquals (City is Equatable) and keeps the old list on failure; MainScreen triggers it only when the SET of unlockedLore ids changes"
requirements-completed: []
duration: 6min
completed: 2026-11-07
---

# Phase 17 Plan 08: Map unknown city and silent cities refresh Summary

Tapping a city whose `relatedLore` is null opens the paper modal with only the city name and «Non conosci ancora questa città.» (no `lore(id)` read, no more `relatedLore!` crash), and `MainScreenCubit.refreshCities()` re-reads `cities` silently whenever the set of `unlockedLore` ids changes, so a city visited mid-session is known without a cold restart (D-11 revised, C1).

## Performance

- Duration: ~6 min (12:30–12:36 UTC), 2 tasks, 8 files (3 created, 5 modified), 4 code commits

## Accomplishments

- `lib/screens/mainScreen/tabs/map/components/unknown_city_modal.dart`: `const UnknownCityModal({super.key, required String cityName})`, `static const String line = 'Non conosci ancora questa città.'`; `Column[SizedBox(height / 7), AutoSizeText(cityName, 24/16, center, specialText 24), SizedBox 20, Text(line, center, bodyMedium 18), SizedBox 100]` (mirrors `CityModal`, no image, no description).
- `world_map.dart`: `_openCityLore(City city)` → `relatedLore == null` → `_showPaperSheet(UnknownCityModal(cityName: city.name ?? ''))`, else `WorldMapCubit.loadLoreData(lore.id)`; `_showCityInfoModal()` keeps its null guard and calls `_showPaperSheet(CityModal(lore: _selectedLore!))`; new `void _showPaperSheet(Widget child)` holds the unchanged `showModalBottomSheet` call (count stays 3). `relatedLore!` gone.
- `main_screen_cubit.dart`: `Future<void> refreshCities()` — returns unless `state is MainScreenLoadData`; on success emits `MainScreenLoadData(cities)` only when `!listEquals(current.cities, cities)` (and the state is still `MainScreenLoadData`); failure → `debugPrint`, list kept. `MainScreenLoading()` stays only in `loadData()`.
- `main_screen.dart`: new `BlocListener<CharacterCubit, CharacterState>(listenWhen: _hasUnlockedLoreChanged, listener: refreshCities())` in the `MultiBlocListener`; `static bool _hasUnlockedLoreChanged(previous, current)` = both `CharacterLoaded` and `!setEquals` of the `unlockedLore` sets.

## TDD

- RED 1 (`7e5730f`): `unknown_city_modal_test.dart` and the teleport case failed to compile (`lib/.../unknown_city_modal.dart: No such file or directory`, `Method not found: 'UnknownCityModal'`).
- GREEN 1 (`0148631`): `flutter test test/screens/mainScreen/tabs/map` → +234 All tests passed.
- RED 2 (`c014767`): `main_screen_cubit_test.dart` failed to compile (`The method 'refreshCities' isn't defined for the type 'MainScreenCubit'`); `main_screen_test.dart` the same through the mock stub.
- GREEN 2 (`3c08d49`): `flutter test test/screens/mainScreen` → +998 All tests passed.
- «loadData still shows the cold-start loading (D-11)» is a regression pin of existing behaviour: it would have been green at the first run without the compile failure of its file.

## Tests added

- `unknown_city_modal_test.dart`: «shows the city name and the unknown line, nothing else (D-11)».
- `world_map_teleport_test.dart`: «a city without lore opens the name-only modal and never reads its lore (D-11)» (now imports `travel_fixtures.dart`, `city_modal.dart`, `unknown_city_modal.dart`).
- `main_screen_cubit_test.dart` (5 bloc_tests, top-level `known`/`unknown` cities from `travelCityJson()`): «refreshCities replaces the cities silently when they differ (D-11)», «an identical list emits nothing (D-11)», «a failed refresh keeps the cities (D-11)», «refreshCities before the first load does nothing (D-11)», «loadData still shows the cold-start loading (D-11)».
- `main_screen_test.dart`: `pumpMainScreen` gains `CharacterState? character` and `Stream<CharacterState>? characterStream` (default `Stream<CharacterState>.empty()`); new group `cities refresh` (inside `satchel wiring`) with `characterKnowing(List<String> unlockedLore, {int currentLifePoints = 900})` and `pumpKnowing(tester, ids)`; cases «a change of the unlocked set refreshes the cities silently (D-11)» (`refreshCities` once, `loadData` once from the first streamed `CharacterLoaded`) and «the same set in another order or other status changes refresh nothing (D-11)».

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `listEquals`/`setEquals` are not re-exported by `material.dart`**
- **Found during:** Task 2 GREEN
- **Issue:** the plan assumed `material.dart` re-exports `listEquals`; compile failed (`The method 'listEquals' isn't defined`).
- **Fix:** `import 'package:flutter/foundation.dart';` in `main_screen_cubit.dart` and `main_screen.dart`; in the cubit `material.dart` then became an `unnecessary_import` (info) and was removed (Boy Scout: the cubit no longer imports the widget library; `@immutable` and `debugPrint` come from `foundation.dart`). Analyzer back to 50 info.
- **Files modified:** `lib/screens/mainScreen/cubit/main_screen_cubit.dart`, `lib/screens/mainScreen/main_screen.dart`
- **Commit:** `3c08d49`

**2. [Boy Scout] doc comment of `_openCityLore` wrapped to two lines** (the plan's single line exceeded 80 columns). Commit `0148631`.

## Gates

- `flutter analyze`: 0 error, 0 warning, `50 issues found.` (baseline, all info).
- `dart format` run on each touched file, all clean (`world_map_teleport_test.dart`, `main_screen_test.dart`, the lib files: 0 changed; `main_screen_cubit_test.dart` reflowed at creation).
- Untouched: `city_modal.dart`, `world_map_cubit.dart`, `city_queries.dart` (`git diff` empty). No D-18 shared result file touched.

## Notes for the UAT and BACKEND-NOTES

- The travel confirmation sheet of an unknown destination shows no image (`travel_confirmation_sheet.dart:89` reads `widget.destination.relatedLore?.image`, already null-safe, covered by «omits the image when the lore has none»); after the silent refresh the image appears for a city just learned.
- `refreshCities` runs on every `unlockedLore` set change (arrival at a city, victories, study rolls): one `cities` read per change.

## Known Stubs

None.

## Self-Check: PASSED

- Files: `unknown_city_modal.dart`, `unknown_city_modal_test.dart`, `main_screen_cubit_test.dart` exist.
- Commits: `7e5730f`, `0148631`, `c014767`, `3c08d49` in `git log`.
