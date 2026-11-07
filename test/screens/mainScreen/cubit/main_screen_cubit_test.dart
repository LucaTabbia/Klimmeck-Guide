import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/screens/mainScreen/cubit/main_screen_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/mocks.dart';

final City known = City.fromJson(travelCityJson());
final City unknown = City.fromJson({...travelCityJson(), 'relatedLore': null});

void main() {
  late MockKlimmeckGraphQl graphQl;

  setUp(() => graphQl = MockKlimmeckGraphQl());

  MainScreenCubit buildCubit() => MainScreenCubit(graphQl);

  group('refreshCities', () {
    blocTest<MainScreenCubit, MainScreenState>(
      'refreshCities replaces the cities silently when they differ (D-11)',
      setUp: () =>
          when(() => graphQl.getCities()).thenAnswer((_) async => [known]),
      build: buildCubit,
      seed: () => MainScreenLoadData([unknown]),
      act: (cubit) => cubit.refreshCities(),
      expect: () => [
        MainScreenLoadData([known]),
      ],
    );

    blocTest<MainScreenCubit, MainScreenState>(
      'an identical list emits nothing (D-11)',
      setUp: () =>
          when(() => graphQl.getCities()).thenAnswer((_) async => [known]),
      build: buildCubit,
      seed: () => MainScreenLoadData([known]),
      act: (cubit) => cubit.refreshCities(),
      expect: () => <MainScreenState>[],
      verify: (_) => verify(() => graphQl.getCities()).called(1),
    );

    blocTest<MainScreenCubit, MainScreenState>(
      'a failed refresh keeps the cities (D-11)',
      setUp: () =>
          when(() => graphQl.getCities()).thenThrow(Exception('offline')),
      build: buildCubit,
      seed: () => MainScreenLoadData([known]),
      act: (cubit) => cubit.refreshCities(),
      expect: () => <MainScreenState>[],
      verify: (cubit) => expect(cubit.state, MainScreenLoadData([known])),
    );

    blocTest<MainScreenCubit, MainScreenState>(
      'refreshCities before the first load does nothing (D-11)',
      build: buildCubit,
      act: (cubit) => cubit.refreshCities(),
      expect: () => <MainScreenState>[],
      verify: (_) => verifyNever(() => graphQl.getCities()),
    );
  });

  blocTest<MainScreenCubit, MainScreenState>(
    'loadData still shows the cold-start loading (D-11)',
    setUp: () =>
        when(() => graphQl.getCities()).thenAnswer((_) async => [known]),
    build: buildCubit,
    act: (cubit) => cubit.loadData(),
    expect: () => [
      MainScreenLoading(),
      MainScreenLoadData([known]),
    ],
  );
}
