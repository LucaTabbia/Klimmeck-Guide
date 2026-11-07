import 'dart:async';

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

    test(
      'overlapping refreshes read once more after the first and never emit out of order (D-11)',
      () async {
        final first = Completer<List<City>>();
        final second = Completer<List<City>>();
        final reads = [
          Future.value([unknown]),
          first.future,
          second.future,
        ];
        when(() => graphQl.getCities()).thenAnswer((_) => reads.removeAt(0));
        final cubit = buildCubit();
        await cubit.loadData();
        verify(() => graphQl.getCities()).called(1);
        final states = <MainScreenState>[];
        final subscription = cubit.stream.listen(states.add);

        final refresh = cubit.refreshCities();
        final overlapping = cubit.refreshCities();
        verify(() => graphQl.getCities()).called(1);

        first.complete([unknown]);
        await pumpEventQueue();
        verify(() => graphQl.getCities()).called(1);

        second.complete([known]);
        await Future.wait([refresh, overlapping]);
        await pumpEventQueue();

        verifyNever(() => graphQl.getCities());
        expect(states, [
          MainScreenLoadData([known]),
        ]);
        await subscription.cancel();
        await cubit.close();
      },
    );

    test(
      'a refresh requested during the cold start runs once the cities are loaded (D-11)',
      () async {
        final coldStart = Completer<List<City>>();
        final reads = [
          coldStart.future,
          Future.value([known]),
        ];
        when(() => graphQl.getCities()).thenAnswer((_) => reads.removeAt(0));
        final cubit = buildCubit();

        final load = cubit.loadData();
        await cubit.refreshCities();
        coldStart.complete([unknown]);
        await load;
        await pumpEventQueue();

        verify(() => graphQl.getCities()).called(2);
        expect(cubit.state, MainScreenLoadData([known]));
        await cubit.close();
      },
    );

    test(
      'a refresh requested before a failed cold start never runs (D-11)',
      () async {
        when(() => graphQl.getCities()).thenThrow(Exception('offline'));
        final cubit = buildCubit();

        final load = cubit.loadData();
        await cubit.refreshCities();
        await load;
        await pumpEventQueue();

        verify(() => graphQl.getCities()).called(1);
        expect(cubit.state, isA<MainScreenError>());
        await cubit.close();
      },
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
