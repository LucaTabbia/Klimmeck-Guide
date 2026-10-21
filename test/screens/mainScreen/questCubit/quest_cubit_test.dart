import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest/quest.dart';
import 'package:klimmeck_guide/screens/mainScreen/questCubit/quest_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fixtures/quest_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockQuestBoardRepository repository;

  setUp(() => repository = MockQuestBoardRepository());

  group('QuestCubit closed by a logout while a request is pending', () {
    test('a late response is ignored without errors', () async {
      final pendingQuests = Completer<List<Quest>>();
      when(
        () => repository.getQuests(),
      ).thenAnswer((_) => pendingQuests.future);
      final cubit = QuestCubit(repository);
      final load = cubit.loadQuest();

      await cubit.close();
      pendingQuests.complete(const <Quest>[]);

      await expectLater(load, completes);
      expect(cubit.state, isA<QuestLoading>());
    });

    test('a late failure is ignored without errors', () async {
      final pendingQuests = Completer<List<Quest>>();
      when(
        () => repository.getQuests(),
      ).thenAnswer((_) => pendingQuests.future);
      final cubit = QuestCubit(repository);
      final load = cubit.loadQuest();

      await cubit.close();
      pendingQuests.completeError(Exception('UNAUTHENTICATED'));

      await expectLater(load, completes);
      expect(cubit.state, isA<QuestLoading>());
    });
  });

  group('loadQuest', () {
    final quests = [buildQuest(id: 'a')];

    blocTest<QuestCubit, QuestState>(
      'emits loading then loaded',
      setUp: () =>
          when(() => repository.getQuests()).thenAnswer((_) async => quests),
      build: () => QuestCubit(repository),
      act: (cubit) => cubit.loadQuest(),
      expect: () => [isA<QuestLoading>(), QuestLoaded(quests)],
    );

    blocTest<QuestCubit, QuestState>(
      'emits the error on failure',
      setUp: () => when(() => repository.getQuests()).thenThrow(Exception('x')),
      build: () => QuestCubit(repository),
      act: (cubit) => cubit.loadQuest(),
      expect: () => [isA<QuestLoading>(), isA<QuestError>()],
    );

    test('keeps the city loaded by a refresh that landed in between', () async {
      final pending = Completer<List<Quest>>();
      when(() => repository.getQuests()).thenAnswer((_) => pending.future);
      when(
        () => repository.getCityPointIds('city-1'),
      ).thenAnswer((_) async => {'p-1'});
      final cubit = QuestCubit(repository);

      final load = cubit.loadQuest();
      when(() => repository.getQuests()).thenAnswer((_) async => quests);
      await cubit.refreshQuests(cityId: 'city-1');
      pending.complete(quests);
      await load;

      expect(
        cubit.state,
        QuestLoaded(quests, cityId: 'city-1', cityPointIds: const {'p-1'}),
      );
      await cubit.close();
    });
  });

  group('refreshQuests', () {
    final old = [buildQuest(id: 'old')];
    final fresh = [buildQuest(id: 'fresh')];

    blocTest<QuestCubit, QuestState>(
      'from initial emits only the loaded state, never loading',
      setUp: () {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        when(
          () => repository.getCityPointIds('city-1'),
        ).thenAnswer((_) async => {'p-1'});
      },
      build: () => QuestCubit(repository),
      act: (cubit) => cubit.refreshQuests(cityId: 'city-1'),
      expect: () => [
        QuestLoaded(fresh, cityId: 'city-1', cityPointIds: const {'p-1'}),
      ],
    );

    blocTest<QuestCubit, QuestState>(
      'a failing quests request keeps the old list and applies the city',
      setUp: () {
        when(() => repository.getQuests()).thenThrow(Exception('x'));
        when(
          () => repository.getCityPointIds('city-1'),
        ).thenAnswer((_) async => {'p-2'});
      },
      build: () => QuestCubit(repository),
      seed: () =>
          QuestLoaded(old, cityId: 'city-1', cityPointIds: const {'p-1'}),
      act: (cubit) => cubit.refreshQuests(cityId: 'city-1'),
      expect: () => [
        QuestLoaded(old, cityId: 'city-1', cityPointIds: const {'p-2'}),
      ],
    );

    blocTest<QuestCubit, QuestState>(
      'both failing emits nothing',
      setUp: () {
        when(() => repository.getQuests()).thenThrow(Exception('x'));
        when(
          () => repository.getCityPointIds('city-1'),
        ).thenThrow(Exception('y'));
      },
      build: () => QuestCubit(repository),
      seed: () =>
          QuestLoaded(old, cityId: 'city-1', cityPointIds: const {'p-1'}),
      act: (cubit) => cubit.refreshQuests(cityId: 'city-1'),
      expect: () => <QuestState>[],
    );

    blocTest<QuestCubit, QuestState>(
      'a failing city request for another city never keeps the old POIs',
      setUp: () {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        when(
          () => repository.getCityPointIds('city-2'),
        ).thenThrow(Exception('y'));
      },
      build: () => QuestCubit(repository),
      seed: () =>
          QuestLoaded(old, cityId: 'city-1', cityPointIds: const {'p-1'}),
      act: (cubit) => cubit.refreshQuests(cityId: 'city-2'),
      expect: () => [QuestLoaded(fresh, cityId: 'city-2')],
    );

    blocTest<QuestCubit, QuestState>(
      'without a city id only the quests are read and the city is kept',
      setUp: () =>
          when(() => repository.getQuests()).thenAnswer((_) async => fresh),
      build: () => QuestCubit(repository),
      seed: () =>
          QuestLoaded(old, cityId: 'city-1', cityPointIds: const {'p-1'}),
      act: (cubit) => cubit.refreshQuests(),
      expect: () => [
        QuestLoaded(fresh, cityId: 'city-1', cityPointIds: const {'p-1'}),
      ],
      verify: (_) => verifyNever(() => repository.getCityPointIds(any())),
    );

    test('the last call wins when an earlier one completes later', () async {
      final first = Completer<List<Quest>>();
      var call = 0;
      when(
        () => repository.getQuests(),
      ).thenAnswer((_) => ++call == 1 ? first.future : Future.value(fresh));
      final cubit = QuestCubit(repository);

      final firstRefresh = cubit.refreshQuests();
      await cubit.refreshQuests();
      first.complete(old);
      await firstRefresh;

      expect(cubit.state, QuestLoaded(fresh));
      await cubit.close();
    });

    test('a response after close does not throw', () async {
      final pending = Completer<List<Quest>>();
      when(() => repository.getQuests()).thenAnswer((_) => pending.future);
      final cubit = QuestCubit(repository);
      final refresh = cubit.refreshQuests();

      await cubit.close();
      pending.complete(fresh);

      await expectLater(refresh, completes);
    });
  });

  test('QuestLoaded props include the city and its POIs', () {
    expect(
      QuestLoaded(const [], cityId: 'a'),
      isNot(QuestLoaded(const [], cityId: 'b')),
    );
    expect(
      QuestLoaded(const [], cityPointIds: const {'p'}),
      isNot(QuestLoaded(const [])),
    );
  });
}
