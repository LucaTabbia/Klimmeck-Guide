import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
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

  group('city retry', () {
    // WR-02: una GetCity fallita alla prima apertura lascerebbe la bacheca
    // quasi vuota senza feedback; un solo nuovo tentativo silenzioso.
    const delay = Duration(seconds: 2);
    final fresh = [buildQuest(id: 'fresh')];

    QuestCubit build() => QuestCubit(repository, cityRetryDelay: delay);

    void cityFailsTimes(int failures) {
      var calls = 0;
      when(() => repository.getCityPointIds('city-1')).thenAnswer((_) {
        if (++calls <= failures) throw Exception('GetCity down');
        return Future.value({'p-1'});
      });
    }

    test('the default delay is two seconds', () {
      expect(QuestCubit.defaultCityRetryDelay, const Duration(seconds: 2));
    });

    test('retries the city once after the delay when GetCity failed', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        cityFailsTimes(1);
        final cubit = build();

        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        expect(cubit.state, QuestLoaded(fresh, cityId: 'city-1'));
        verify(() => repository.getCityPointIds('city-1')).called(1);

        async.elapse(delay);
        expect(
          cubit.state,
          QuestLoaded(fresh, cityId: 'city-1', cityPointIds: const {'p-1'}),
        );
        verify(() => repository.getCityPointIds('city-1')).called(1);
        cubit.close();
      });
    });

    test('gives up after the single retry', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        cityFailsTimes(5);
        final cubit = build();

        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        async.elapse(delay * 3);

        verify(() => repository.getCityPointIds('city-1')).called(2);
        expect(cubit.state, QuestLoaded(fresh, cityId: 'city-1'));
        cubit.close();
      });
    });

    test('does not retry when the city POIs arrived', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        cityFailsTimes(0);
        final cubit = build();

        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        async.elapse(delay * 2);

        verify(() => repository.getCityPointIds('city-1')).called(1);
        cubit.close();
      });
    });

    test('does not retry without a city', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenThrow(Exception('x'));
        final cubit = build();

        cubit.refreshQuests();
        async.flushMicrotasks();
        async.elapse(delay * 2);

        verify(() => repository.getQuests()).called(1);
        verifyNever(() => repository.getCityPointIds(any()));
        cubit.close();
      });
    });

    test('a newer refresh supersedes the scheduled retry', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        cityFailsTimes(1);
        final cubit = build();

        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        async.elapse(delay * 2);

        verify(() => repository.getCityPointIds('city-1')).called(2);
        cubit.close();
      });
    });

    test('close cancels the scheduled retry', () {
      fakeAsync((async) {
        when(() => repository.getQuests()).thenAnswer((_) async => fresh);
        cityFailsTimes(1);
        final cubit = build();

        cubit.refreshQuests(cityId: 'city-1');
        async.flushMicrotasks();
        cubit.close();
        async.elapse(delay * 2);

        verify(() => repository.getCityPointIds('city-1')).called(1);
      });
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

  group('watchQuest', () {
    final adventurer = {'character': 'c-1', 'title': 'rookie'};
    final otherAdventurer = {'character': 'c-2', 'title': 'rookie'};
    final waiting = buildQuest(id: 'q-1', registered: [adventurer]);
    final joined = buildQuest(
      id: 'q-1',
      registered: [adventurer, otherAdventurer],
    );
    final other = buildQuest(id: 'q-2');
    late StreamController<Quest> updates;
    late int cancellations;

    QuestLoaded loaded(List<Quest> quests) =>
        QuestLoaded(quests, cityId: 'city-1', cityPointIds: const {'p-1'});

    setUp(() {
      cancellations = 0;
      updates = StreamController<Quest>.broadcast(
        onCancel: () => cancellations++,
      );
      when(
        () => repository.watchQuest(any()),
      ).thenAnswer((_) => updates.stream);
    });

    tearDown(() => updates.close());

    blocTest<QuestCubit, QuestState>(
      'replaces the watched quest and keeps the city',
      build: () => QuestCubit(repository),
      seed: () => loaded([waiting, other]),
      act: (cubit) async {
        cubit.watchQuest('q-1');
        updates.add(joined);
      },
      expect: () => [
        loaded([joined, other]),
      ],
      verify: (_) => verify(() => repository.watchQuest('q-1')).called(1),
    );

    blocTest<QuestCubit, QuestState>(
      'appends a watched quest missing from the list',
      build: () => QuestCubit(repository),
      seed: () => loaded([other]),
      act: (cubit) async {
        cubit.watchQuest('q-1');
        updates.add(joined);
      },
      expect: () => [
        loaded([other, joined]),
      ],
    );

    blocTest<QuestCubit, QuestState>(
      'ignores an update while the list is not loaded',
      build: () => QuestCubit(repository),
      act: (cubit) async {
        cubit.watchQuest('q-1');
        updates.add(joined);
      },
      expect: () => <QuestState>[],
    );

    test('watching the same quest twice subscribes once', () async {
      final cubit = QuestCubit(repository);

      cubit.watchQuest('q-1');
      cubit.watchQuest('q-1');

      verify(() => repository.watchQuest('q-1')).called(1);
      await cubit.close();
    });

    test('watching another quest cancels the previous watch', () async {
      final cubit = QuestCubit(repository);

      cubit.watchQuest('q-1');
      cubit.watchQuest('q-2');
      await pumpEventQueue();

      expect(cancellations, 1);
      verify(() => repository.watchQuest('q-2')).called(1);
      await cubit.close();
    });

    blocTest<QuestCubit, QuestState>(
      'unwatchQuest stops the updates',
      build: () => QuestCubit(repository),
      seed: () => loaded([waiting]),
      act: (cubit) async {
        cubit.watchQuest('q-1');
        cubit.unwatchQuest();
        updates.add(joined);
      },
      expect: () => <QuestState>[],
      verify: (_) => expect(cancellations, 1),
    );

    test('watching again after unwatchQuest subscribes again', () async {
      final cubit = QuestCubit(repository);

      cubit.watchQuest('q-1');
      cubit.unwatchQuest();
      cubit.watchQuest('q-1');

      verify(() => repository.watchQuest('q-1')).called(2);
      await cubit.close();
    });

    test('close cancels the watch', () async {
      final cubit = QuestCubit(repository);
      cubit.watchQuest('q-1');

      await cubit.close();

      expect(cancellations, 1);
    });

    blocTest<QuestCubit, QuestState>(
      'a stream error keeps the state and drops the watch',
      build: () => QuestCubit(repository),
      seed: () => loaded([waiting]),
      act: (cubit) async {
        cubit.watchQuest('q-1');
        updates.addError(const FormatException('quest missing'));
        await pumpEventQueue();
        cubit.watchQuest('q-1');
      },
      expect: () => <QuestState>[],
      verify: (_) => verify(() => repository.watchQuest('q-1')).called(2),
    );
  });
}
