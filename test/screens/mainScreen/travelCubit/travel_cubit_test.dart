import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/travel_preview.dart';
import 'package:klimmeck_guide/repository/travel_failure.dart';
import 'package:klimmeck_guide/screens/mainScreen/travelCubit/travel_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../helpers/fixtures/travel_fixtures.dart';
import '../../../helpers/mocks.dart';

void main() {
  late MockTravelRepository repository;
  late FakeServerClockService clock;

  final valdoria = City.fromJson(travelCityJson());
  final preview = TravelPreview.fromJson(travelPreviewJson());
  final previewedAt = DateTime.utc(2026, 10, 24, 10);
  final eta = DateTime.utc(2026, 10, 24, 12, 40);
  final confirming = TravelConfirming(
    destination: valdoria,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );
  final starting = TravelStarting(
    destination: valdoria,
    preview: preview,
    eta: eta,
    previewedAt: previewedAt,
  );
  final started = TravelStarted(destination: valdoria, preview: preview);

  setUp(() {
    repository = MockTravelRepository();
    clock = FakeServerClockService(previewedAt);
  });

  TravelCubit build() => TravelCubit(repository, clock: clock);

  When<Future<TravelPreview>> stubPreview() => when(
    () => repository.preview(
      characterId: any(named: 'characterId'),
      poiId: any(named: 'poiId'),
    ),
  );

  When<Future<void>> stubStart() => when(
    () => repository.start(
      characterId: any(named: 'characterId'),
      poiId: any(named: 'poiId'),
    ),
  );

  void verifyNoPreview() => verifyNever(
    () => repository.preview(
      characterId: any(named: 'characterId'),
      poiId: any(named: 'poiId'),
    ),
  );

  Future<void> previewValdoria(TravelCubit cubit) =>
      cubit.preview(characterId: 'c-1', destination: valdoria);

  test('starts idle', () {
    expect(build().state, const TravelIdle());
  });

  group('preview', () {
    blocTest<TravelCubit, TravelState>(
      'shows the destination at once, then the backend numbers and the ETA',
      setUp: () => stubPreview().thenAnswer((_) async => preview),
      build: build,
      act: previewValdoria,
      expect: () => [TravelPreviewing(valdoria), confirming],
      verify: (_) => verify(
        () => repository.preview(characterId: 'c-1', poiId: 'city-marker-2'),
      ).called(1),
    );

    blocTest<TravelCubit, TravelState>(
      'emits the preview failure carried by the exception',
      setUp: () =>
          stubPreview().thenThrow(const TravelException(TravelFailure.noPath)),
      build: build,
      act: previewValdoria,
      expect: () => [
        TravelPreviewing(valdoria),
        TravelFailed(
          destination: valdoria,
          failure: TravelFailure.noPath,
          stage: TravelStage.preview,
        ),
      ],
    );

    blocTest<TravelCubit, TravelState>(
      'maps an unexpected preview error to unknown',
      setUp: () => stubPreview().thenThrow(StateError('boom')),
      build: build,
      act: previewValdoria,
      expect: () => [
        TravelPreviewing(valdoria),
        TravelFailed(
          destination: valdoria,
          failure: TravelFailure.unknown,
          stage: TravelStage.preview,
        ),
      ],
    );

    blocTest<TravelCubit, TravelState>(
      'ignores a destination without a marker',
      build: build,
      act: (cubit) => cubit.preview(
        characterId: 'c-1',
        destination: City.fromJson({
          ...travelCityJson(),
          'markerLocation': null,
        }),
      ),
      expect: () => const <TravelState>[],
      verify: (_) => verifyNoPreview(),
    );

    blocTest<TravelCubit, TravelState>(
      'ignores a preview while the flow is not idle',
      setUp: () => stubPreview().thenAnswer((_) async => preview),
      build: build,
      seed: () => confirming,
      act: previewValdoria,
      expect: () => const <TravelState>[],
      verify: (_) => verifyNoPreview(),
    );
  });

  group('cancel', () {
    test('a late successful preview after cancel is ignored', () async {
      final completer = Completer<TravelPreview>();
      stubPreview().thenAnswer((_) => completer.future);
      final cubit = build();
      final states = <TravelState>[];
      final subscription = cubit.stream.listen(states.add);

      final pending = previewValdoria(cubit);
      cubit.cancel();
      completer.complete(preview);
      await pending;
      await Future<void>.delayed(Duration.zero);

      expect(states, [TravelPreviewing(valdoria), const TravelIdle()]);
      await subscription.cancel();
      await cubit.close();
    });

    test('a late failed preview after cancel is ignored', () async {
      final completer = Completer<TravelPreview>();
      stubPreview().thenAnswer((_) => completer.future);
      final cubit = build();
      final states = <TravelState>[];
      final subscription = cubit.stream.listen(states.add);

      final pending = previewValdoria(cubit);
      cubit.cancel();
      completer.completeError(const TravelException(TravelFailure.noPath));
      await pending;
      await Future<void>.delayed(Duration.zero);

      expect(states, [TravelPreviewing(valdoria), const TravelIdle()]);
      await subscription.cancel();
      await cubit.close();
    });

    test('the token drops the answer of a replaced equal request', () async {
      final first = Completer<TravelPreview>();
      final second = Completer<TravelPreview>();
      final answers = [first, second];
      stubPreview().thenAnswer((_) => answers.removeAt(0).future);
      final cubit = build();
      final states = <TravelState>[];
      final subscription = cubit.stream.listen(states.add);

      final firstPending = previewValdoria(cubit);
      cubit.cancel();
      final secondPending = previewValdoria(cubit);
      first.completeError(const TravelException(TravelFailure.noPath));
      await firstPending;
      expect(cubit.state, TravelPreviewing(valdoria));

      second.complete(preview);
      await secondPending;
      await Future<void>.delayed(Duration.zero);

      expect(states, [
        TravelPreviewing(valdoria),
        const TravelIdle(),
        TravelPreviewing(valdoria),
        confirming,
      ]);
      await subscription.cancel();
      await cubit.close();
    });

    blocTest<TravelCubit, TravelState>(
      'returns to idle while confirming',
      build: build,
      seed: () => confirming,
      act: (cubit) => cubit.cancel(),
      expect: () => const [TravelIdle()],
    );

    blocTest<TravelCubit, TravelState>(
      'is ignored while starting',
      build: build,
      seed: () => starting,
      act: (cubit) => cubit.cancel(),
      expect: () => const <TravelState>[],
    );

    blocTest<TravelCubit, TravelState>(
      'is ignored once started',
      build: build,
      seed: () => started,
      act: (cubit) => cubit.cancel(),
      expect: () => const <TravelState>[],
    );
  });

  group('start', () {
    blocTest<TravelCubit, TravelState>(
      'starts the confirmed travel without building any travel state',
      setUp: () {
        stubPreview().thenAnswer((_) async => preview);
        stubStart().thenAnswer((_) async {});
      },
      build: build,
      act: (cubit) async {
        await previewValdoria(cubit);
        await cubit.start();
      },
      skip: 2,
      expect: () => [starting, started],
      verify: (_) => verify(
        () => repository.start(characterId: 'c-1', poiId: 'city-marker-2'),
      ).called(1),
    );

    test('a double "Parti" sends one request', () async {
      final completer = Completer<void>();
      stubPreview().thenAnswer((_) async => preview);
      stubStart().thenAnswer((_) => completer.future);
      final cubit = build();
      await previewValdoria(cubit);

      final first = cubit.start();
      await cubit.start();
      completer.complete();
      await first;

      verify(
        () => repository.start(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ).called(1);
      expect(cubit.state, started);
      await cubit.close();
    });

    blocTest<TravelCubit, TravelState>(
      'does nothing from idle',
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => const <TravelState>[],
      verify: (_) => verifyNever(
        () => repository.start(
          characterId: any(named: 'characterId'),
          poiId: any(named: 'poiId'),
        ),
      ),
    );

    blocTest<TravelCubit, TravelState>(
      'emits the start failure carried by the exception',
      setUp: () {
        stubPreview().thenAnswer((_) async => preview);
        stubStart().thenThrow(const TravelException(TravelFailure.inProgress));
      },
      build: build,
      act: (cubit) async {
        await previewValdoria(cubit);
        await cubit.start();
      },
      skip: 2,
      expect: () => [
        starting,
        TravelFailed(
          destination: valdoria,
          failure: TravelFailure.inProgress,
          stage: TravelStage.start,
        ),
      ],
    );
  });

  group('reset', () {
    blocTest<TravelCubit, TravelState>(
      'returns to idle after a failure',
      build: build,
      seed: () => TravelFailed(
        destination: valdoria,
        failure: TravelFailure.noPath,
        stage: TravelStage.preview,
      ),
      act: (cubit) => cubit.reset(),
      expect: () => const [TravelIdle()],
    );

    blocTest<TravelCubit, TravelState>(
      'returns to idle after a start',
      build: build,
      seed: () => started,
      act: (cubit) => cubit.reset(),
      expect: () => const [TravelIdle()],
    );

    blocTest<TravelCubit, TravelState>(
      'is ignored while starting',
      build: build,
      seed: () => starting,
      act: (cubit) => cubit.reset(),
      expect: () => const <TravelState>[],
    );
  });

  group('started hold', () {
    void startInFakeTime(FakeAsync async, TravelCubit cubit) {
      stubPreview().thenAnswer((_) async => preview);
      stubStart().thenAnswer((_) async {});
      previewValdoria(cubit).then((_) => cubit.start());
      async.flushMicrotasks();
    }

    test('returns to idle by itself after the default hold', () {
      fakeAsync((async) {
        final cubit = build();
        startInFakeTime(async, cubit);
        expect(cubit.state, started);

        async.elapse(
          TravelCubit.defaultStartedHold - const Duration(seconds: 1),
        );
        expect(cubit.state, started);

        async.elapse(const Duration(seconds: 1));
        expect(cubit.state, const TravelIdle());
        cubit.close();
      });
    });

    test('close cancels the hold timer', () {
      fakeAsync((async) {
        final cubit = build();
        startInFakeTime(async, cubit);
        cubit.close();
        async.flushMicrotasks();

        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  test('drops a late preview answer after close', () async {
    final completer = Completer<TravelPreview>();
    stubPreview().thenAnswer((_) => completer.future);
    final cubit = build();

    final pending = previewValdoria(cubit);
    await cubit.close();
    completer.complete(preview);
    await pending;

    expect(cubit.state, TravelPreviewing(valdoria));
  });

  test('drops a late start answer after close', () async {
    final completer = Completer<void>();
    stubPreview().thenAnswer((_) async => preview);
    stubStart().thenAnswer((_) => completer.future);
    final cubit = build();
    await previewValdoria(cubit);

    final pending = cubit.start();
    await cubit.close();
    completer.complete();
    await pending;

    expect(cubit.state, starting);
  });
}
