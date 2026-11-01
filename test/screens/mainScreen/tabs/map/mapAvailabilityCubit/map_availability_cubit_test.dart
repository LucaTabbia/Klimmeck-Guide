import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapAvailabilityCubit/map_availability_cubit.dart';

void main() {
  const onMap = MapAvailabilityState(isMapPage: true);

  test('starts off the map page and not free', () {
    final cubit = MapAvailabilityCubit();

    expect(cubit.state, const MapAvailabilityState());
    expect(cubit.state.isMapPage, isFalse);
    expect(cubit.state.isRouteCovered, isFalse);
    expect(cubit.state.isQuestSheetOpen, isFalse);
    expect(cubit.state.isPawnDragging, isFalse);
    expect(cubit.state.isTeleportMode, isFalse);
    expect(cubit.state.isFree, isFalse);
    cubit.close();
  });

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'the map page with nothing on top is free',
    build: MapAvailabilityCubit.new,
    act: (cubit) => cubit.pageChanged(isMapPage: true),
    expect: () => [onMap],
    verify: (cubit) => expect(cubit.state.isFree, isTrue),
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'a covering route blocks the map and its removal frees it',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) {
      cubit.routeCoveredChanged(true);
      expect(cubit.state.isFree, isFalse);
      cubit.routeCoveredChanged(false);
    },
    expect: () => [
      const MapAvailabilityState(isMapPage: true, isRouteCovered: true),
      onMap,
    ],
    verify: (cubit) => expect(cubit.state.isFree, isTrue),
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'an open quest sheet blocks the map until it closes',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) {
      cubit.questSheetChanged(true);
      expect(cubit.state.isFree, isFalse);
      cubit.questSheetChanged(false);
    },
    expect: () => [
      const MapAvailabilityState(isMapPage: true, isQuestSheetOpen: true),
      onMap,
    ],
    verify: (cubit) => expect(cubit.state.isFree, isTrue),
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'a pawn drag blocks the map until it ends',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) {
      cubit.pawnDragChanged(true);
      expect(cubit.state.isFree, isFalse);
      cubit.pawnDragChanged(false);
    },
    expect: () => [
      const MapAvailabilityState(isMapPage: true, isPawnDragging: true),
      onMap,
    ],
    verify: (cubit) => expect(cubit.state.isFree, isTrue),
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'repeating a write with the same value emits nothing',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) => cubit
      ..pageChanged(isMapPage: true)
      ..routeCoveredChanged(false)
      ..questSheetChanged(false)
      ..pawnDragChanged(false),
    expect: () => <MapAvailabilityState>[],
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'leaving the map page is never free',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) => cubit.pageChanged(isMapPage: false),
    expect: () => [const MapAvailabilityState()],
    verify: (cubit) => expect(cubit.state.isFree, isFalse),
  );

  blocTest<MapAvailabilityCubit, MapAvailabilityState>(
    'teleport mode keeps the result sheets off the map until it ends (C13)',
    build: MapAvailabilityCubit.new,
    seed: () => onMap,
    act: (cubit) {
      cubit.teleportModeChanged(true);
      expect(cubit.state.isFreeBeneathRoutes, isFalse);
      expect(cubit.state.isFree, isFalse);
      cubit.teleportModeChanged(false);
    },
    expect: () => [
      const MapAvailabilityState(isMapPage: true, isTeleportMode: true),
      onMap,
    ],
    verify: (cubit) {
      expect(cubit.state.isFreeBeneathRoutes, isTrue);
      expect(cubit.state.isFree, isTrue);
    },
  );

  test('two states differing only in teleport mode are not equal', () {
    expect(
      const MapAvailabilityState(isMapPage: true, isTeleportMode: true),
      isNot(onMap),
    );
  });
}
