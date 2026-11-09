---
phase: 12-hardening
plan: 13
subsystem: repository, map
tags: [hardening, error-codes, bad-user-input, push, map, city-size]
requires: ["12-12"]
provides:
  - "InnkeeperFailure.badUserInput (surfaces unchanged: completion form and teleport chip keep their generic lines)"
  - "PushDeviceFailure.badUserInput, not retryable (isRetryable unchanged): the register loop stops on BAD_USER_INPUT"
  - "CityMarkersLayer visibility from City.size (CitySizeType?): null size or null type = hidden"
  - "CityType without cityClass: per-type pixel size and image id kept"
affects: [12-14, 12-15, 12-16, 12-17]
tech-stack:
  added: []
  patterns:
    - "Zoom visibility driven by the BE-served City.size, never by an FE map of types"
key-files:
  created:
    - test/screens/mainScreen/tabs/map/layers/city_markers_layer_test.dart
    - .planning/phases/12-hardening/12-13-SUMMARY.md
  modified:
    - lib/repository/innkeeper_failure.dart
    - test/repository/innkeeper_failure_test.dart
    - test/screens/mainScreen/tabs/map/components/teleport_mode_chip_test.dart
    - lib/repository/push_device_failure.dart
    - test/repository/push_device_failure_test.dart
    - lib/models/enums/city_type.dart
    - lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
    - test/screens/mainScreen/tabs/map/character_marker_layer_test.dart
decisions:
  - "D-13a veto: innkeeper badUserInput falls into the existing wildcard lines (no lib change on the surfaces); push badUserInput is a silent, non-retryable value"
  - "D-13c veto: CityType keeps size + image id, only cityClass removed; visibility needs both City.size and City.type (the marker reads type for image and pixels)"
metrics:
  duration: "~15 min"
  completed: 2026-11-09
---

# Phase 12 Plan 13: BAD_USER_INPUT in innkeeper/push, markers by City.size Summary

Innkeeper and push-device classifiers map `BAD_USER_INPUT` (push as a non-retryable silent value, ending the infinite register backoff), so all eleven `*_failure.dart` classifiers now map it; `CityType.cityClass` is gone and city marker zoom visibility follows the BE-served `City.size`, with per-type pixel sizes kept.

## Commits

| Task | Commit | Message |
|------|--------|---------|
| 1 RED | 4966cb0 | test(repository): expect BAD_USER_INPUT on innkeeper and push device |
| 1 GREEN | cfe9e89 | fix(repository): classify BAD_USER_INPUT, never retry it on push |
| 2 RED | 93a5b6a | test(map): expect city markers visible by City.size |
| 2 GREEN | aefd800 | refactor(map): show city markers by City.size and drop cityClass |

## What was built

- `lib/repository/innkeeper_failure.dart`: `InnkeeperFailure.badUserInput` (right before `unauthenticated`, two-line D-13a doc), arm `badUserInputCode => InnkeeperFailure.badUserInput,` before `unauthenticatedCode`; import `spell_equip_failure.dart show badUserInputCode`.
- `lib/repository/push_device_failure.dart`: `PushDeviceFailure.badUserInput` (before `unauthenticated`, doc `/// BAD_USER_INPUT (BE Phase 10): bug del FE, mai ritentato (Phase 12 D-13a).`), arm `badUserInputCode => PushDeviceFailure.badUserInput,`; `bool get isRetryable => this == connection || this == unknown;` unchanged, so `PushRegistrationCoordinator._isTransient` (`error is! PushDeviceException || error.failure.isRetryable`) no longer retries it.
- `lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart`: `_getVisibleCities(double zoom)` = `cities.where((city) => city.type != null && _isVisibleAt(city.size, zoom))`; `static bool _isVisibleAt(CitySizeType? size, double zoom) => switch (size) {capital/city/village → MapConstants.*VisibleZoom, null => false}`.
- `lib/models/enums/city_type.dart`: `cityClass` removed from the 33 values, the field, the ctor and the `city_size_type.dart` import; `final int size;`, private `_imageId`, `imagePath` unchanged.
- Fixtures `cityA`/`cityB` in `world_map_travel_test.dart` and `character_marker_layer_test.dart` gain `'size': 'capital'`.

## RED evidence

- Task 1: compile failure, `Member not found: 'badUserInput'` (teleport_mode_chip_test.dart:44 and the two classifier tests); 3 files failed to load.
- Task 2 layer test: 3 of 5 red — «a city appears only from the city zoom (D-13)», «a village appears only from the village zoom (D-13)», «a city without a size is hidden (D-13)» (each: `Expected: no matching candidates / Actual: Found 1 widget with type "CityMarker"`, the capital-class `drusteaCapital` type made them visible). Green at the first run, as expected: «a capital is visible from the capital zoom (D-13)» (capital type and capital size agree at baseline) and «a city without a type is hidden even with a size (D-13)» (baseline `city.type?.cityClass` null → hidden already; the test pins the new `city.type != null` guard, T-12-37).
- P-M1: after the GREEN switch and before the fixture edit, `world_map_teleport_test.dart` «the layer hands the tapped city to its callback» and «the layer without a callback leaves the markers inert» failed (fixtures without `size`); the `'size': 'capital'` fixtures made them green.

## Gates

- `flutter test test/repository test/screens/innkeeper test/repository/services/push test/screens/mainScreen/tabs/map/components` → 1019 «All tests passed».
- `flutter test test/screens/mainScreen/tabs/map test/models test/graphql test/tool` → 1090 «All tests passed».
- Plan verification `flutter test test/repository test/screens/innkeeper test/screens/mainScreen/tabs/map test/models test/graphql test/tool` → 2087 «All tests passed».
- `flutter analyze`: 47 issues found (all info), 0 error, 0 warning.
- `grep -l "badUserInputCode =>" lib/repository/*_failure.dart | wc -l` = 11; `grep -rn cityClass lib test` empty; `git diff HEAD~2 --stat -- lib/graphql tool/schema_check test/tool` empty (document and registry unchanged); `bash tool/hardening_check.sh` → `hardening_check: OK`.
- `dart format` on each touched file individually. Reflows: `city_type.dart` (formatter-dirty) — the 33 entries now fit on one line each and the ctor collapsed to one line (accepted, D-13c); `city_markers_layer.dart` (formatter-dirty) — only the trailing blank line at EOF was removed besides the edited method. Both files are now formatter-clean.

## Deviations from Plan

1. **Acceptance grep `grep -c "final String imageId;" lib/models/enums/city_type.dart` = 1 prints 0** — the field has been private (`final String _imageId;`) since before this phase and the plan says to keep `imageId` unchanged; the grep literal is a plan slip. Field left as is (the image id is kept: `const CityType({required this.size, required String imageId}) : _imageId = imageId;`).
2. **Frontmatter key_link pattern `switch \(city\.size\)`** does not match: the plan's own `<interfaces>` code (and the acceptance grep `switch (size)` = 1) passes `city.size` into `_isVisibleAt(CitySizeType? size, …)`; the code follows `<interfaces>`.

No auto-fixes (Rules 1-3) were needed.

## Known Stubs

None.

## Self-Check: PASSED

- Files exist: test/screens/mainScreen/tabs/map/layers/city_markers_layer_test.dart, all modified files.
- Commits exist: 4966cb0, cfe9e89, 93a5b6a, aefd800.
