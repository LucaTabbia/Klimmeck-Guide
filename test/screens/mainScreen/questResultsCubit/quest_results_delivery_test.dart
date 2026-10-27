import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_sync_exceptions.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:klimmeck_guide/utils/backoff.dart';
import 'package:klimmeck_guide/utils/silent_retry.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_pending_quest_results.dart';
import '../../../helpers/fakes/recording_quest_result_acknowledger.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/mocks.dart';

QuestResult _success(String id, {int minute = 0}) => questResult(
  successResultJson(id: id, resolvedAt: '2026-10-27T12:0$minute:00.000Z'),
);

QuestResult _death(String id) => questResult(deathResultJson(id: id));

SubscriptionStreamException _streamError(String code) =>
    SubscriptionStreamException(operation: 'questResultReceived', code: code);

const QuestResultException _connectionLost = QuestResultException(
  QuestResultFailure.connection,
);

class DeliveryHarness {
  DeliveryHarness() {
    when(() => repository.watch('c-1')).thenAnswer((_) {
      final controller = StreamController<QuestResult>.broadcast();
      streams.add(controller);
      return controller.stream;
    });
    cubit = QuestResultsCubit(
      characterId: 'c-1',
      repository: repository,
      pending: pending,
      acknowledger: acknowledger,
      lifecycle: lifecycle,
      connectionRestored: connectionRestored,
      userRefresh: refreshBus,
    );
    refreshBus.requests.listen((_) => refreshRequests++);
  }

  final MockQuestResultRepository repository = MockQuestResultRepository();
  final FakePendingQuestResults pending = FakePendingQuestResults();
  final RecordingQuestResultAcknowledger acknowledger =
      RecordingQuestResultAcknowledger();
  final AppLifecycleEventBus lifecycle = AppLifecycleEventBus();
  final ConnectionRestoredBus connectionRestored = ConnectionRestoredBus();
  final UserRefreshRequestBus refreshBus = UserRefreshRequestBus();
  final List<StreamController<QuestResult>> streams = [];
  late final QuestResultsCubit cubit;
  int refreshRequests = 0;

  QuestResultsState get state => cubit.state;

  List<String> get queuedIds => [for (final result in state.queue) result.id];

  int get subscriptions => streams.length;

  StreamController<QuestResult> get latestStream => streams.last;

  void dispose() {
    cubit.close();
    lifecycle.close();
    connectionRestored.close();
    refreshBus.close();
  }
}

void withHarness(
  String description,
  void Function(DeliveryHarness h, FakeAsync async) body,
) {
  test(description, () {
    fakeAsync((async) {
      final harness = DeliveryHarness();
      body(harness, async);
      harness.dispose();
      async.flushMicrotasks();
    });
  });
}

void _start(DeliveryHarness h, FakeAsync async) {
  h.cubit.start();
  async.flushMicrotasks();
}

void _showAndClose(DeliveryHarness h, FakeAsync async, String id) {
  h.pending.results = [_success(id)];
  _start(h, async);
  h.cubit
    ..presented(id)
    ..closed(id);
  async.flushMicrotasks();
}

void main() {
  group('QuestResultsCubit start (D-09)', () {
    withHarness('subscribes once and reads the pending results once', (h, a) {
      _start(h, a);

      verify(() => h.repository.watch('c-1')).called(1);
      expect(h.pending.calls, 1);
    });

    withHarness('a live result is queued as an arrival', (h, a) {
      _start(h, a);

      h.latestStream.add(_success('r-1'));
      a.flushMicrotasks();

      expect(h.queuedIds, ['r-1']);
      expect(h.state.arrival?.id, 'r-1');
      expect(h.state.arrivalSerial, 1);
    });

    withHarness('a result from the port is queued without an arrival', (h, a) {
      h.pending.results = [_success('r-1')];

      _start(h, a);

      expect(h.queuedIds, ['r-1']);
      expect(h.state.arrival, isNull);
      expect(h.state.arrivalSerial, 0);
    });
  });

  group('QuestResultsCubit refetch triggers (D-09 c, D-10)', () {
    withHarness('a foreground reads the pending results again', (h, a) {
      _start(h, a);

      h.lifecycle.notifyForegrounded();
      a.flushMicrotasks();

      expect(h.pending.calls, 2);
    });

    withHarness('a reconnection reads the pending results again', (h, a) {
      _start(h, a);

      h.connectionRestored.notifyRestored();
      a.flushMicrotasks();

      expect(h.pending.calls, 2);
    });

    withHarness('triggers during a read join the read in flight', (h, a) {
      final hold = Completer<void>();
      h.pending.hold = hold;
      _start(h, a);

      h.lifecycle.notifyForegrounded();
      h.connectionRestored.notifyRestored();
      a.flushMicrotasks();
      expect(h.pending.calls, 1);

      hold.complete();
      a.flushMicrotasks();
      h.lifecycle.notifyForegrounded();
      a.flushMicrotasks();
      expect(h.pending.calls, 2);
    });

    withHarness('a failed acknowledgement is retried before the read', (h, a) {
      h.acknowledger.errorOnce = _connectionLost;
      _showAndClose(h, a, 'r-1');
      expect(h.acknowledger.acknowledged, isEmpty);
      final hold = Completer<void>();
      h.acknowledger.hold = hold;

      h.lifecycle.notifyForegrounded();
      a.flushMicrotasks();
      expect(h.acknowledger.calls, ['r-1', 'r-1']);
      expect(h.pending.calls, 1);

      hold.complete();
      a.flushMicrotasks();
      expect(h.acknowledger.acknowledged, ['r-1']);
      expect(h.pending.calls, 2);

      h.lifecycle.notifyForegrounded();
      a.flushMicrotasks();
      expect(h.acknowledger.calls, ['r-1', 'r-1']);
    });

    withHarness('a foreground retries a failed death acknowledgement', (h, a) {
      h.acknowledger.errorOnce = _connectionLost;
      h.pending.results = [_death('d-1')];
      _start(h, a);
      h.cubit.presented('d-1');
      h.cubit.acknowledgeDeath('d-1');
      a.flushMicrotasks();
      expect(h.state.deathAcknowledgement, DeathAcknowledgement.failed);

      h.lifecycle.notifyForegrounded();
      a.flushMicrotasks();

      expect(h.state.deathAcknowledgement, DeathAcknowledgement.done);
      expect(h.acknowledger.acknowledged, ['d-1']);
    });

    withHarness('a network failure of the read is retried in silence', (h, a) {
      h.pending.error = _connectionLost;
      _start(h, a);

      a.elapse(const Duration(minutes: 10));

      expect(h.pending.calls, defaultSilentRetryAttempts);
      expect(h.state, const QuestResultsState());
    });

    for (final failure in [
      QuestResultFailure.forbidden,
      QuestResultFailure.unauthenticated,
      QuestResultFailure.notFound,
    ]) {
      withHarness('a ${failure.name} read is not retried', (h, a) {
        h.pending.error = QuestResultException(failure);
        _start(h, a);

        a.elapse(const Duration(minutes: 10));

        expect(h.pending.calls, 1);
        expect(h.state, const QuestResultsState());
      });
    }
  });

  group('QuestResultsCubit subscription (D-09 a, checker I2)', () {
    for (final code in ['NOT_FOUND', 'FORBIDDEN']) {
      withHarness('$code stops for good and reads the pending results', (h, a) {
        _start(h, a);

        h.latestStream.addError(_streamError(code));
        a.elapse(const Duration(minutes: 5));

        expect(h.subscriptions, 1);
        expect(h.pending.calls, 2);
        expect(h.refreshRequests, 0);
      });
    }

    withHarness('a transport error resubscribes after the backoff', (h, a) {
      _start(h, a);
      final delay = exponentialBackoff(
        0,
        max: WsReconnectPolicy.maxReconnectDelay,
      );

      h.latestStream.addError(Exception('ws'));
      a.elapse(delay - const Duration(milliseconds: 1));
      expect(h.subscriptions, 1);

      a.elapse(const Duration(milliseconds: 1));
      expect(h.subscriptions, 2);
      verify(() => h.repository.watch('c-1')).called(2);
    });

    withHarness('a completed stream resubscribes', (h, a) {
      _start(h, a);

      h.latestStream.close();
      a.elapse(const Duration(minutes: 1));

      expect(h.subscriptions, 2);
    });

    withHarness('a malformed event is skipped without resubscribing', (h, a) {
      _start(h, a);

      h.latestStream.addError(const FormatException('bad payload'));
      a.elapse(const Duration(minutes: 1));
      h.latestStream.add(_success('r-1'));
      a.flushMicrotasks();

      expect(h.subscriptions, 1);
      expect(h.queuedIds, ['r-1']);
    });
  });

  group('QuestResultsCubit push tap (D-11, T-9-26)', () {
    for (final id in [null, 'bad id!']) {
      withHarness('ignores the id $id', (h, a) {
        _start(h, a);

        h.cubit.requestFromTap(id);
        a.flushMicrotasks();

        verifyNever(() => h.repository.fetch(any()));
      });
    }

    withHarness('a queued id is not read again', (h, a) {
      h.pending.results = [_success('r-1')];
      _start(h, a);

      h.cubit.requestFromTap('r-1');
      a.flushMicrotasks();

      verifyNever(() => h.repository.fetch(any()));
    });

    withHarness('a showing id is not read again', (h, a) {
      h.pending.results = [_success('r-1')];
      _start(h, a);
      h.cubit.presented('r-1');

      h.cubit.requestFromTap('r-1');
      a.flushMicrotasks();

      verifyNever(() => h.repository.fetch(any()));
    });

    withHarness('a closed id is not read again', (h, a) {
      _showAndClose(h, a, 'r-1');

      h.cubit.requestFromTap('r-1');
      a.flushMicrotasks();

      verifyNever(() => h.repository.fetch(any()));
    });

    withHarness('a pending-ack id is not read again', (h, a) {
      h.acknowledger.error = _connectionLost;
      _showAndClose(h, a, 'r-1');

      h.cubit.requestFromTap('r-1');
      a.flushMicrotasks();

      verifyNever(() => h.repository.fetch(any()));
    });

    withHarness('an unknown id is read once and queued quietly', (h, a) {
      when(
        () => h.repository.fetch('r-9'),
      ).thenAnswer((_) async => _success('r-9'));
      _start(h, a);

      h.cubit.requestFromTap('r-9');
      a.flushMicrotasks();

      verify(() => h.repository.fetch('r-9')).called(1);
      expect(h.queuedIds, ['r-9']);
      expect(h.state.arrivalSerial, 0);
    });

    for (final failure in [
      QuestResultFailure.notFound,
      QuestResultFailure.forbidden,
    ]) {
      withHarness('${failure.name} produces a notice', (h, a) {
        when(
          () => h.repository.fetch('r-9'),
        ).thenThrow(QuestResultException(failure));
        _start(h, a);

        h.cubit.requestFromTap('r-9');
        a.flushMicrotasks();
        expect(h.state.notice?.resultId, 'r-9');
        expect(h.state.notice?.failure, failure);
        expect(h.state.notice?.serial, 1);

        h.cubit.requestFromTap('r-9');
        a.flushMicrotasks();
        expect(h.state.notice?.serial, 2);
      });
    }

    for (final failure in [
      QuestResultFailure.connection,
      QuestResultFailure.timedOut,
      QuestResultFailure.malformed,
      QuestResultFailure.unknown,
      QuestResultFailure.unauthenticated,
    ]) {
      withHarness('${failure.name} stays silent', (h, a) {
        when(
          () => h.repository.fetch('r-9'),
        ).thenThrow(QuestResultException(failure));
        _start(h, a);

        h.cubit.requestFromTap('r-9');
        a.flushMicrotasks();

        expect(h.state.notice, isNull);
        expect(h.state.queue, isEmpty);
      });
    }
  });

  group('QuestResultsCubit close', () {
    withHarness('stops the stream and every trigger', (h, a) {
      _start(h, a);
      final stream = h.latestStream;

      h.cubit.close();
      a.flushMicrotasks();
      h.lifecycle.notifyForegrounded();
      h.connectionRestored.notifyRestored();
      a.elapse(const Duration(minutes: 1));

      expect(stream.hasListener, isFalse);
      expect(h.pending.calls, 1);
      expect(h.subscriptions, 1);
    });

    withHarness('cancels a pending resubscription', (h, a) {
      _start(h, a);

      h.latestStream.addError(Exception('ws'));
      a.flushMicrotasks();
      h.cubit.close();
      a.elapse(const Duration(minutes: 5));

      expect(h.subscriptions, 1);
    });
  });
}
