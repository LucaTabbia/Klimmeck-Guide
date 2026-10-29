import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/pending_request/pending_request.dart';
import 'package:klimmeck_guide/models/pending_request/request_card.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
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

List<PendingRequest> _storyAndWorldQueue() =>
    _queue([pendingRequestJson(), ...worldMissionEntriesJson()]);

/// Una subscription nuova per ogni `watchQueue()`, registrata in [streams].
class QueueHarness {
  QueueHarness() {
    when(() => repository.watchQueue()).thenAnswer((_) {
      final controller = StreamController<List<PendingRequest>>.broadcast();
      streams.add(controller);
      return controller.stream;
    });
    cubit = PendingRequestsCubit(repository: repository, clock: clock);
  }

  final MockInnkeeperRepository repository = MockInnkeeperRepository();
  final FakeServerClockService clock = FakeServerClockService(_start);
  final List<StreamController<List<PendingRequest>>> streams = [];
  late final PendingRequestsCubit cubit;

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

  void dispose(FakeAsync async) {
    unawaited(cubit.close());
    async.flushMicrotasks();
  }
}

void _runQueue(void Function(QueueHarness h, FakeAsync async) body) {
  fakeAsync((async) {
    final h = QueueHarness();
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
}
