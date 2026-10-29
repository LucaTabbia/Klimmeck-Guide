---
phase: 10-admin-panel-innkeeper
plan: 09
subsystem: map
tags: [map, teleport, admin, shell, availability, ui, tdd]
requires: [10-04, 10-05, 10-08]
provides:
  - shell-level lazy BlocProvider<TeleportModeCubit> (lib/screens/auth/authenticated_shell.dart)
  - CityMarker.onTap nullable + CityMarkersLayer.onCityTap (null = no lore)
  - WorldMap layer swap on TeleportActive, teleport drop/cancel wiring, teleportModeChanged sync
affects: [10-10]
tech-stack:
  added: []
  patterns: [BlocBuilder wraps a Stack whose first child is always the FlutterMap; only the layer list and a trailing overlay change with the mode]
key-files:
  created:
    - test/screens/mainScreen/tabs/map/world_map_teleport_test.dart
  modified:
    - lib/screens/auth/authenticated_shell.dart
    - lib/screens/mainScreen/tabs/map/components/city_marker.dart
    - lib/screens/mainScreen/tabs/map/layers/city_markers_layer.dart
    - lib/screens/mainScreen/tabs/map/world_map.dart
    - test/screens/auth/authenticated_shell_test.dart
    - test/screens/mainScreen/tabs/map/world_map_travel_test.dart
    - test/screens/mainScreen/tabs/map/world_map_availability_test.dart
key-decisions:
  - "TeleportModeCubit lives in the shell next to InnkeeperRepository (lazy): the panel (root route) starts it, the Map shows it"
  - "The teleport mode is wired only in the UI: WorldMap's BlocListener writes MapAvailabilityCubit.teleportModeChanged; no cubit calls another"
  - "The shared WorldMap harness (world_map_travel_test.dart) gains the MockTeleportModeCubit once; the teleport and availability tests import it instead of copying it"
requirements-completed: []
duration: 25min
completed: 2026-10-29
---

# Phase 10 Plan 09: Map in teleport mode Summary

The shell now provides a lazy `TeleportModeCubit`, city markers can be drop targets without opening the lore, and `WorldMap` turns into the teleport surface while the cubit is `TeleportActive`: only the map image, the cities and the chosen pawn with its name, plus the in-style «Annulla» chip. Releasing the pawn calls `teleportTo(city)`, «Annulla» calls `cancel()`, and the availability flag follows the mode (mount, transitions, dispose).

## What was built

- **Task 1:** `BlocProvider<TeleportModeCubit>(create: (context) => TeleportModeCubit(repository: context.read<InnkeeperRepository>()))` right after `RepositoryProvider<InnkeeperRepository>` in `AuthenticatedShell` (lazy, doc line added to the class comment). `CityMarker.onTap` is `VoidCallback?` (constructor still `required this.onTap`), `GestureDetector(onTap: widget.onTap)`. `CityMarkersLayer` gains `final void Function(City city)? onCityTap` (optional named), drops the `flutter_bloc`/`WorldMapCubit` imports (DIRTY file, hand-edited, never formatted). `WorldMap._openCityLore(City)` calls `WorldMapCubit.loadLoreData(city.relatedLore!.id)`.
- **Task 2:** `_buildMap()` = `BackgroundImage(BlocBuilder<TeleportModeCubit, TeleportModeState>(Stack(fit: expand, [GestureDetector(FlutterMap(children: teleport is TeleportActive ? _teleportLayers(teleport) : _gameLayers())), if (TeleportActive) _buildTeleportChip(teleport)])))`. `_gameLayers()` is the former list; `_teleportLayers(TeleportActive)` = map image + `CityMarkersLayer` without `onCityTap` + `TeleportPawnLayer(canDrag: !isTeleporting, onDragUpdate: _handleCharacterDragUpdate, onDragEnd: _handleTeleportDragEnd)`; `_buildTeleportChip` = bottom-centre `SafeArea` + `spacingLg` padding + `TeleportModeChip(onCancel: cubit.cancel)`. `_handleTeleportDragEnd(LatLng? _, City? targetCity)` ends the drag and calls `teleportTo` (C16 in the cubit). `BlocListener<TeleportModeCubit, TeleportModeState>` (listenWhen: «is TeleportActive» flips) → `_syncTeleportMode` (writes `teleportModeChanged`, on entry `_closeQuestSheet()` + `_centreOnTeleportTarget`). `initState` writes the flag from the current state, `_handleMapReady` centres on an already-active target, `dispose` adds `..teleportModeChanged(false)`.

DIRTY file, hand edit only: `city_markers_layer.dart` (+7/−5: two imports removed, the field + doc, the `onTap` ternary).

## TDD evidence

- Task 1 RED (`c615aea`): compile failure — `Error: No named parameter with the name 'onCityTap'.`, `The argument type 'void Function()?' can't be assigned to the parameter type 'void Function()'.`, `The getter 'onCityTap' isn't defined for the type 'CityMarkersLayer'.`; shell test: `Could not find the correct Provider<TeleportModeCubit>` (+ `LateInitializationError`). GREEN (`d9d5b8a`): `test/screens/mainScreen/tabs/map` + `test/screens/auth` 354/354.
- Task 2 RED (`c916396`): 11 failures, e.g. `Expected: exactly one matching candidate / Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'map.teleportPawn'>]>`; availability «holds the result sheets back» failed on `isTeleportMode`. GREEN (`6195b80`): world_map_teleport_test 16/16, world_map_availability_test 10/10, world_map_travel_test green; `test/screens/mainScreen` + `test/screens/auth` 954/954.
- Full suite: 2804 green (2785 + 19). Analyzer: 51 issues (all info), gate exit 0.

## Deviations from Plan

1. **[Rule 3] Shared harness instead of a copied one:** `world_map_availability_test.dart` already imports `world_map_travel_test.dart` (`hide main`); the `MockTeleportModeCubit` + `StreamController<TeleportModeState>` + `pumpWorldMap(teleportState:)` were added there once and the new teleport test imports it too (no duplicated harness). The availability file names `TeleportModeCubit` in a comment of its new `teleport mode (Phase 10 C13)` group, which covers the mounted-active and dispose cases (the dispose test lives there, not duplicated in the teleport file).
2. **[Rule 1] Two test-only fixes during GREEN:** the inert-marker test advances 1 s after the tap (the tap falls through to `FlutterMap`, which leaves a double-tap timer pending); the quest-sheet-on-entry test seeds `CloudinaryAssets.emptySheet` (the sheet's SVG, otherwise `pumpAndSettle` timed out). Both in the files committed with the GREEN commits.
3. **Lore-tap test calls `onCityTap` directly** on the `CityMarkersLayer` widget (as the availability test does with `onQuestSelected`): the own pawn sits on Aldheim and cityB is off-screen at zoom 2.

## Known Stubs

None. Visuals provisional (D-22). Nothing starts the mode from the panel yet: plan 10-10.

## Threat Flags

None — T-10-33 (own `CharacterMarkerLayer` absent, drop → `teleportTo` only, «preview never called» test), T-10-34 (dispose and transition tests), T-10-35 (`onCityTap` null in teleport mode, `loadLoreData` never called) mitigated.

## Self-Check: PASSED

- `test/screens/mainScreen/tabs/map/world_map_teleport_test.dart` exists; commits c615aea, d9d5b8a, c916396, 6195b80 present on `feat/10-admin-panel`.
