import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/mapFocusCubit/map_focus_cubit.dart';

void main() {
  test('starts with no pending focus', () {
    final cubit = MapFocusCubit();
    addTearDown(cubit.close);

    expect(cubit.state, const MapFocusState(isCharacterFocusPending: false));
  });

  blocTest<MapFocusCubit, MapFocusState>(
    'a request latches the character focus',
    build: MapFocusCubit.new,
    act: (cubit) => cubit.requestCharacterFocus(),
    expect: () => const [MapFocusState(isCharacterFocusPending: true)],
  );

  blocTest<MapFocusCubit, MapFocusState>(
    'a second request while pending emits nothing new',
    build: MapFocusCubit.new,
    seed: () => const MapFocusState(isCharacterFocusPending: true),
    act: (cubit) => cubit.requestCharacterFocus(),
    expect: () => const <MapFocusState>[],
  );

  blocTest<MapFocusCubit, MapFocusState>(
    'consuming a pending request returns true and clears it',
    build: MapFocusCubit.new,
    seed: () => const MapFocusState(isCharacterFocusPending: true),
    act: (cubit) => expect(cubit.consumeCharacterFocus(), isTrue),
    expect: () => const [MapFocusState(isCharacterFocusPending: false)],
  );

  blocTest<MapFocusCubit, MapFocusState>(
    'consuming with nothing pending returns false and emits nothing',
    build: MapFocusCubit.new,
    act: (cubit) => expect(cubit.consumeCharacterFocus(), isFalse),
    expect: () => const <MapFocusState>[],
  );

  test('a request after close does not throw', () async {
    final cubit = MapFocusCubit();
    await cubit.close();

    expect(cubit.requestCharacterFocus, returnsNormally);
  });
}
