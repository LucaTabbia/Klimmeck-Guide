import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/screens/innkeeper/pendingRequestsCubit/pending_requests_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../helpers/fixtures/pending_request_fixtures.dart';
import '../../../helpers/mocks.dart';

final DateTime _start = DateTime.utc(2026, 10, 29, 12);

const SubscriptionStreamException _unavailable = SubscriptionStreamException(
  operation: 'pendingRequestsUpdated',
  code: 'UNAVAILABLE',
);

const SubscriptionStreamException _forbidden = SubscriptionStreamException(
  operation: 'pendingRequestsUpdated',
  code: 'FORBIDDEN',
);

List<PendingRequest> _queue(List<Map<String, dynamic>> entries) =>
    List.unmodifiable(entries.map(PendingRequest.fromJson));

List<PendingRequest> _storyQueue() => _queue([pendingRequestJson()]);

List<PendingRequest> _travellerQueue(DateTime endTime) => _queue([
  pendingRequestJson(activeTravel: queuedTravelJson(endTime: endTime)),
]);

const InnkeeperException _connectionLost = InnkeeperException(
  InnkeeperFailure.connection,
);

const InnkeeperException _roleRevoked = InnkeeperException(
  InnkeeperFailure.forbidden,
);

List<PendingRequest> _storyAndWorldQueue() =>
    _queue([pendingRequestJson(), ...worldMissionEntriesJson()]);

/// Una subscription nuova per ogni `watchQueue()`, registrata in [streams];
/// `fetchQueue()` risponde con [fetched] e conta le chiamate.
class QueueHarness {
  QueueHarness({
    List<Duration> rereadDelays = PendingRequestsCubit.arrivalRereadDelays,
  }) {
    when(() => repository.watchQueue()).thenAnswer((_) {
      final controller = StreamController<List<PendingRequest>>.broadcast();
      streams.add(controller);
      return controller.stream;
    });
    when(() => repository.fetchQueue()).thenAnswer((_) {
      fetchCalls++;
      return fetchAnswer();
    });
    cubit = PendingRequestsCubit(
      repository: repository,
      clock: clock,
      lifecycle: lifecycle,
      rereadDelays: rereadDelays,
    );
    cubit.stream.listen(emitted.add);
  }

  final MockInnkeeperRepository repository = MockInnkeeperRepository();
  final FakeServerClockService clock = FakeServerClockService(_start);
  final AppLifecycleEventBus lifecycle = AppLifecycleEventBus();
  final List<StreamController<List<PendingRequest>>> streams = [];
  final List<PendingRequestsState> emitted = [];
  late final PendingRequestsCubit cubit;
  List<PendingRequest> fetched = const [];
  late Future<List<PendingRequest>> Function() fetchAnswer = () async =>
      fetched;
  int fetchCalls = 0;

  PendingRequestsState get state => cubit.state;

  StreamController<List<PendingRequest>> get live => streams.last;

  int get watchCalls => streams.length;

  void push(FakeAsync async, List<PendingRequest> requests) {
    live.add(requests);
    async.flushMicrotasks();
  }

  void fail(FakeAsync async, Object error) {
    live.addError(error);
    async.flushMicrotasks();
  }

  /// Ora del server e timer avanzano insieme, un secondo alla volta.
  void pass(FakeAsync async, Duration duration) {
    for (var second = 0; second < duration.inSeconds; second++) {
      clock.advance(const Duration(seconds: 1));
      async.elapse(const Duration(seconds: 1));
    }
  }

  void dispose(FakeAsync async) {
    unawaited(cubit.close());
    unawaited(lifecycle.close());
    async.flushMicrotasks();
  }
}

void _runQueue(
  void Function(QueueHarness h, FakeAsync async) body, {
  List<Duration> rereadDelays = PendingRequestsCubit.arrivalRereadDelays,
}) {
  fakeAsync((async) {
    final h = QueueHarness(rereadDelays: rereadDelays);
    body(h, async);
    h.dispose(async);
  });
}

void main() {
  group('PendingRequestsCubit subscription (D-10)', () {
    test('starts empty, not loaded, on the server clock', () {
      _runQueue((h, async) {
        expect(h.state.requests, isEmpty);
        expect(h.state.isLoaded, isFalse);
        expect(h.state.isForbidden, isFalse);
        expect(h.state.hiddenQuestIds, isEmpty);
        expect(h.state.serverNow, _start);
      });
    });

    test('start subscribes once and the first snapshot loads the list', () {
      _runQueue((h, async) {
        h.cubit.start();
        async.flushMicrotasks();
        expect(h.watchCalls, 1);
        expect(h.state.isLoaded, isFalse);

        h.push(async, _storyQueue());

        expect(h.state.isLoaded, isTrue);
        expect(h.state.requests, _storyQueue());
        expect(h.watchCalls, 1);
      });
    });

    late QueueHarness harness;
    blocTest<PendingRequestsCubit, PendingRequestsState>(
      'every snapshot replaces the list, a removed entry disappears',
      build: () => (harness = QueueHarness()).cubit,
      act: (cubit) async {
        cubit.start();
        final live = harness.live;
        live.add(_storyAndWorldQueue());
        await Future<void>.delayed(Duration.zero);
        live.add(_storyQueue());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        PendingRequestsState(
          serverNow: _start,
          requests: _storyAndWorldQueue(),
          isLoaded: true,
        ),
        PendingRequestsState(
          serverNow: _start,
          requests: _storyQueue(),
          isLoaded: true,
        ),
      ],
    );

    test('cards are the request cards of the list minus the hidden ids', () {
      final state = PendingRequestsState(
        serverNow: _start,
        requests: _storyAndWorldQueue(),
        isLoaded: true,
        hiddenQuestIds: const {worldMissionQuestId},
      );

      expect(
        state.cards,
        requestCardsOf(
          _storyAndWorldQueue(),
          hiddenQuestIds: const {worldMissionQuestId},
        ),
      );
      expect(state.cards.map((card) => card.questId), [storyQuestId]);
    });

    test('a malformed event is skipped and the stream stays open', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());

        h.fail(async, const FormatException('missing list'));
        async.elapse(const Duration(minutes: 2));

        expect(h.watchCalls, 1);
        expect(h.live.hasListener, isTrue);
        expect(h.state.requests, _storyQueue());
        expect(h.state.isLoaded, isTrue);
      });
    });
  });

  group('PendingRequestsCubit reconnection (Phase 3 policy)', () {
    test('a stream error resubscribes after the backoff, keeping the list', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());

        h.fail(async, _unavailable);
        async.elapse(const Duration(milliseconds: 999));
        expect(h.watchCalls, 1);

        async.elapse(const Duration(milliseconds: 1));
        expect(h.watchCalls, 2);
        expect(h.state.isLoaded, isTrue);
        expect(h.state.requests, _storyQueue());
      });
    });

    test('the backoff doubles until a snapshot resets it', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.fail(async, _unavailable);
        async.elapse(const Duration(seconds: 1));
        expect(h.watchCalls, 2);

        h.fail(async, _unavailable);
        async.elapse(const Duration(seconds: 1));
        expect(h.watchCalls, 2);
        async.elapse(const Duration(seconds: 1));
        expect(h.watchCalls, 3);

        h.push(async, _storyQueue());
        h.fail(async, _unavailable);
        async.elapse(const Duration(seconds: 1));
        expect(h.watchCalls, 4);
      });
    });

    test('the backoff never exceeds the reconnect cap', () {
      _runQueue((h, async) {
        h.cubit.start();
        for (var attempt = 0; attempt < 10; attempt++) {
          h.fail(async, _unavailable);
          async.elapse(const Duration(seconds: 60));
          expect(h.watchCalls, attempt + 2);
        }
      });
    });

    test('a stream completed without error resubscribes after the backoff', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());

        unawaited(h.live.close());
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1));

        expect(h.watchCalls, 2);
        expect(h.state.requests, _storyQueue());
      });
    });

    test('FORBIDDEN is terminal: flag set, stream cancelled, no retry', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());

        h.fail(async, _forbidden);
        async.elapse(const Duration(minutes: 10));

        expect(h.state.isForbidden, isTrue);
        expect(h.watchCalls, 1);
        expect(h.streams.single.hasListener, isFalse);
      });
    });

    test('close during a pending backoff stops every resubscribe', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.fail(async, _unavailable);

        h.dispose(async);
        async.elapse(const Duration(minutes: 2));

        expect(h.watchCalls, 1);
        expect(h.live.hasListener, isFalse);
      });
    });
  });

  group('PendingRequestsCubit server clock tick (D-06)', () {
    const noRereads = <Duration>[];

    test('ticks every second and rereads at endTime + 5 s and + 65 s', () {
      expect(PendingRequestsCubit.defaultTick, const Duration(seconds: 1));
      expect(PendingRequestsCubit.arrivalRereadDelays, const [
        Duration(seconds: 5),
        Duration(seconds: 65),
      ]);
    });

    test('ticks on the server clock while a participant travels', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _travellerQueue(_start.add(const Duration(minutes: 3))));

        h.pass(async, const Duration(seconds: 1));
        expect(h.state.serverNow, _start.add(const Duration(seconds: 1)));

        h.pass(async, const Duration(seconds: 2));
        expect(h.state.serverNow, _start.add(const Duration(seconds: 3)));
      }, rereadDelays: noRereads);
    });

    test('does not tick without a traveller', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());
        final emissions = h.emitted.length;

        h.pass(async, const Duration(seconds: 10));

        expect(h.emitted.length, emissions);
        expect(h.state.serverNow, _start);
      }, rereadDelays: noRereads);
    });

    test('does not tick for a travel already past its end time', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(
          async,
          _travellerQueue(_start.subtract(const Duration(minutes: 1))),
        );
        final emissions = h.emitted.length;

        h.pass(async, const Duration(seconds: 10));

        expect(h.emitted.length, emissions);
      }, rereadDelays: noRereads);
    });

    test('does not tick for a busy traveller hidden from the cards', () {
      _runQueue((h, async) {
        final travel = queuedTravelJson(
          endTime: _start.add(const Duration(minutes: 3)),
        );
        h.cubit.start();
        h.push(
          async,
          _queue(
            worldMissionEntriesJson(
              names: const ['Bea'],
              travels: {'Bea': travel},
              busyLanes: const {'Bea': 'pq-other'},
            ),
          ),
        );
        final emissions = h.emitted.length;

        h.pass(async, const Duration(seconds: 10));

        expect(h.emitted.length, emissions);
      }, rereadDelays: noRereads);
    });

    test('stops once every listed travel is past its end time', () {
      _runQueue((h, async) {
        final endTime = _start.add(const Duration(seconds: 3));
        h.cubit.start();
        h.push(async, _travellerQueue(endTime));

        h.pass(async, const Duration(seconds: 3));
        expect(h.state.serverNow, endTime);
        final emissions = h.emitted.length;

        h.pass(async, const Duration(seconds: 10));
        expect(h.emitted.length, emissions);
        expect(h.state.serverNow, endTime);
      }, rereadDelays: noRereads);
    });
  });

  group('PendingRequestsCubit arrival rereads (D-18, C5)', () {
    test('rereads once at endTime + 5 s and once at endTime + 65 s', () {
      _runQueue((h, async) {
        final queue = _travellerQueue(_start.add(const Duration(minutes: 3)));
        h.fetched = queue;
        h.cubit.start();
        h.push(async, queue);

        h.pass(async, const Duration(seconds: 184));
        expect(h.fetchCalls, 0);
        h.pass(async, const Duration(seconds: 1));
        expect(h.fetchCalls, 1);

        h.pass(async, const Duration(seconds: 59));
        expect(h.fetchCalls, 1);
        h.pass(async, const Duration(seconds: 1));
        expect(h.fetchCalls, 2);

        h.push(async, queue);
        h.pass(async, const Duration(minutes: 10));
        expect(h.fetchCalls, 2);
      });
    });

    test('a different end time schedules its own pair of rereads', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _travellerQueue(_start.add(const Duration(minutes: 3))));
        final later = _travellerQueue(_start.add(const Duration(minutes: 10)));
        h.fetched = later;
        h.push(async, later);

        h.pass(async, const Duration(minutes: 5));
        expect(h.fetchCalls, 2);

        h.pass(async, const Duration(seconds: 304));
        expect(h.fetchCalls, 2);
        h.pass(async, const Duration(seconds: 1));
        expect(h.fetchCalls, 3);
        h.pass(async, const Duration(seconds: 60));
        expect(h.fetchCalls, 4);
      });
    });
  });

  group('PendingRequestsCubit refetch (D-10)', () {
    test('a refetch replaces the list like a snapshot', () {
      _runQueue((h, async) {
        h.fetched = _storyQueue();

        unawaited(h.cubit.refetch());
        async.flushMicrotasks();

        expect(h.state.isLoaded, isTrue);
        expect(h.state.requests, _storyQueue());
      });
    });

    test('concurrent refetches share one read', () {
      _runQueue((h, async) {
        final answer = Completer<List<PendingRequest>>();
        h.fetchAnswer = () => answer.future;

        unawaited(h.cubit.refetch());
        unawaited(h.cubit.refetch());
        async.flushMicrotasks();
        expect(h.fetchCalls, 1);

        answer.complete(_storyQueue());
        async.flushMicrotasks();
        expect(h.state.requests, _storyQueue());

        h.fetchAnswer = () async => h.fetched;
        unawaited(h.cubit.refetch());
        async.flushMicrotasks();
        expect(h.fetchCalls, 2);
      });
    });

    test('a failed refetch is silent and never retried in a loop', () {
      _runQueue((h, async) {
        h.fetchAnswer = () async => throw _connectionLost;
        final before = h.state;

        unawaited(h.cubit.refetch());
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 5));

        expect(h.state, before);
        expect(h.fetchCalls, 1);
      });
    });

    test('a FORBIDDEN refetch is terminal and cancels the stream', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyQueue());
        h.fetchAnswer = () async => throw _roleRevoked;

        unawaited(h.cubit.refetch());
        async.flushMicrotasks();
        expect(h.state.isForbidden, isTrue);
        expect(h.live.hasListener, isFalse);

        h.lifecycle.notifyForegrounded();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 5));
        expect(h.fetchCalls, 1);
        expect(h.watchCalls, 1);
      });
    });

    test('a snapshot newer than a slow refetch wins over its result', () {
      _runQueue((h, async) {
        final answer = Completer<List<PendingRequest>>();
        h.fetchAnswer = () => answer.future;
        h.cubit.start();
        h.push(async, _storyAndWorldQueue());

        unawaited(h.cubit.refetch());
        async.flushMicrotasks();
        h.push(async, _storyQueue());
        answer.complete(_storyAndWorldQueue());
        async.flushMicrotasks();

        expect(h.state.requests, _storyQueue());
      });
    });

    test('an app resume rereads the queue once', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.lifecycle.notifyForegrounded();
        async.flushMicrotasks();

        expect(h.fetchCalls, 1);
      });
    });
  });

  group('PendingRequestsCubit optimistic hide (D-13)', () {
    test('a completed card stays hidden until a snapshot drops it', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyAndWorldQueue());

        h.cubit.markCompleted(worldMissionQuestId);
        expect(h.state.hiddenQuestIds, {worldMissionQuestId});
        expect(h.state.cards.map((card) => card.questId), [storyQuestId]);

        h.push(async, _storyAndWorldQueue());
        expect(h.state.hiddenQuestIds, {worldMissionQuestId});
        expect(h.state.cards.map((card) => card.questId), [storyQuestId]);

        h.push(async, _storyQueue());
        expect(h.state.hiddenQuestIds, isEmpty);
      });
    });

    test('a completion after the snapshot dropped the card hides nothing', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _storyAndWorldQueue());
        h.push(async, _storyQueue());

        h.cubit.markCompleted(worldMissionQuestId);
        expect(h.state.hiddenQuestIds, isEmpty);

        h.push(async, _storyAndWorldQueue());
        expect(h.state.cards.map((card) => card.questId), [
          storyQuestId,
          worldMissionQuestId,
        ]);
      });
    });
  });

  group('PendingRequestsCubit close (P4)', () {
    test('nothing ticks, rereads or refetches after close', () {
      _runQueue((h, async) {
        h.cubit.start();
        h.push(async, _travellerQueue(_start.add(const Duration(minutes: 1))));

        h.dispose(async);
        final emissions = h.emitted.length;
        h.pass(async, const Duration(minutes: 5));

        expect(h.fetchCalls, 0);
        expect(h.emitted.length, emissions);
        expect(h.watchCalls, 1);
      });
    });
  });
}
