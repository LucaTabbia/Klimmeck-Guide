import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/quest_result/quest_result.dart';
import 'package:klimmeck_guide/repository/quest_result_failure.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';
import 'package:klimmeck_guide/repository/services/sync/user_refresh_requests.dart';
import 'package:klimmeck_guide/screens/mainScreen/questResultsCubit/quest_results_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_pending_quest_results.dart';
import '../../../helpers/fakes/recording_quest_result_acknowledger.dart';
import '../../../helpers/fixtures/quest_result_fixtures.dart';
import '../../../helpers/mocks.dart';

String _at(int minute) => '2026-10-27T12:0$minute:00.000Z';

QuestResult _success(String id, {int minute = 0}) =>
    questResult(successResultJson(id: id, resolvedAt: _at(minute)));

QuestResult _death(String id, {int minute = 0}) =>
    questResult(deathResultJson(id: id, resolvedAt: _at(minute)));

const QuestResultException _connectionLost = QuestResultException(
  QuestResultFailure.connection,
);

class QueueHarness {
  QueueHarness() {
    when(
      () => repository.watch(any()),
    ).thenAnswer((_) => const Stream<QuestResult>.empty());
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
  late final QuestResultsCubit cubit;
  int refreshRequests = 0;

  QuestResultsState get state => cubit.state;

  List<String> get queuedIds => [for (final result in state.queue) result.id];

  Future<void> offer(List<QuestResult> results) async {
    pending.results = results;
    await cubit.refetchPending();
  }

  Future<void> showDeath(String id) async {
    await offer([_death(id)]);
    cubit.presented(id);
  }

  Future<void> dispose() async {
    await cubit.close();
    await Future.wait([
      lifecycle.close(),
      connectionRestored.close(),
      refreshBus.close(),
    ]);
  }
}

void main() {
  late QueueHarness h;

  setUp(() => h = QueueHarness());
  tearDown(() => h.dispose());

  group('QuestResultsCubit queue order and dedup (D-08, D-09)', () {
    test('orders by resolvedAt, ties broken by id', () async {
      await h.offer([
        _success('c', minute: 2),
        _success('b'),
        _success('x', minute: 1),
        _success('a'),
      ]);

      expect(h.queuedIds, ['a', 'b', 'x', 'c']);
    });

    test('keeps one entry per id, whichever offer comes first', () async {
      await h.offer([_success('r-1'), _success('r-1')]);
      await h.offer([_success('r-1'), _success('r-2', minute: 1)]);

      expect(h.queuedIds, ['r-1', 'r-2']);
    });

    test('ignores a result already acknowledged on the backend', () async {
      await h.offer([
        questResult(
          questResultJson(id: 'old', acknowledgedAt: '2026-10-27T13:00:00Z'),
        ),
      ]);

      expect(h.state.queue, isEmpty);
    });

    test('a death in the queue unlocks the whole queue', () async {
      await h.offer([_success('r-1')]);
      expect(h.state.isUnlockedByDeath, isFalse);

      await h.offer([_death('d-1', minute: 1)]);
      expect(h.state.isUnlockedByDeath, isTrue);
    });
  });

  group('QuestResultsCubit presentation and batch counter (D-08)', () {
    test('presenting the head moves it to showing as 1 of N', () async {
      await h.offer([_success('r-1'), _success('r-2', minute: 1)]);

      h.cubit.presented('r-1');

      expect(h.state.showing?.id, 'r-1');
      expect(h.queuedIds, ['r-2']);
      expect(h.state.position, 1);
      expect(h.state.total, 2);
    });

    test('an id that is not the head is not presented', () async {
      await h.offer([_success('r-1'), _success('r-2', minute: 1)]);

      h.cubit.presented('r-2');

      expect(h.state.showing, isNull);
      expect(h.queuedIds, ['r-1', 'r-2']);
    });

    test('the next sheet of the batch is 2 of N', () async {
      await h.offer([_success('r-1'), _success('r-2', minute: 1)]);

      h.cubit
        ..presented('r-1')
        ..closed('r-1')
        ..presented('r-2');

      expect(h.state.position, 2);
      expect(h.state.total, 2);
    });

    test('the counter restarts once the batch is over', () async {
      await h.offer([_success('r-1')]);
      h.cubit
        ..presented('r-1')
        ..closed('r-1');
      expect(h.state.position, 0);

      await h.offer([_success('r-2', minute: 1)]);
      h.cubit.presented('r-2');

      expect(h.state.position, 1);
      expect(h.state.total, 1);
    });
  });

  group('QuestResultsCubit acknowledgement at close (D-10)', () {
    test(
      'a closed sheet is acknowledged once and never offered again',
      () async {
        await h.offer([_success('r-1')]);
        h.cubit
          ..presented('r-1')
          ..closed('r-1');
        await pumpEventQueue();

        expect(h.state.showing, isNull);
        expect(h.acknowledger.acknowledged, ['r-1']);

        await h.offer([_success('r-1')]);
        expect(h.state.queue, isEmpty);
      },
    );

    test(
      'a failed acknowledgement stays silent and keeps the id out',
      () async {
        h.acknowledger.error = _connectionLost;
        await h.offer([_success('r-1')]);
        h.cubit
          ..presented('r-1')
          ..closed('r-1');
        await pumpEventQueue();

        expect(h.state, const QuestResultsState());
        await h.offer([_success('r-1')]);
        expect(h.state.queue, isEmpty);
      },
    );

    test('acknowledgements run one at a time, in close order', () async {
      final hold = Completer<void>();
      h.acknowledger.hold = hold;
      await h.offer([_success('r-1'), _success('r-2', minute: 1)]);
      h.cubit
        ..presented('r-1')
        ..closed('r-1')
        ..presented('r-2')
        ..closed('r-2');
      await pumpEventQueue();

      expect(h.acknowledger.calls, ['r-1']);

      hold.complete();
      await pumpEventQueue();
      expect(h.acknowledger.acknowledged, ['r-1', 'r-2']);
    });

    test('a non-death close never requests a user refresh', () async {
      await h.offer([_success('r-1')]);
      h.cubit
        ..presented('r-1')
        ..closed('r-1');
      await pumpEventQueue();

      expect(h.refreshRequests, 0);
    });
  });

  group('QuestResultsCubit external pop (D-10)', () {
    test(
      'requeues the sheet at its FIFO place without acknowledging',
      () async {
        await h.offer([_success('r-1'), _success('r-2', minute: 1)]);
        h.cubit.presented('r-1');

        h.cubit.dismissedExternally('r-1');
        await pumpEventQueue();

        expect(h.state.showing, isNull);
        expect(h.queuedIds, ['r-1', 'r-2']);
        expect(h.state.position, 0);
        expect(h.acknowledger.calls, isEmpty);
      },
    );

    test('ignores an id that is not showing', () async {
      await h.offer([_success('r-1')]);

      h.cubit.dismissedExternally('r-1');

      expect(h.queuedIds, ['r-1']);
      expect(h.state.position, 0);
    });
  });

  group('QuestResultsCubit death acknowledgement (D-13)', () {
    blocTest<QuestResultsCubit, QuestResultsState>(
      'awaits the acknowledgement: inFlight then done',
      build: () => h.cubit,
      setUp: () async => h.showDeath('d-1'),
      act: (cubit) => cubit.acknowledgeDeath('d-1'),
      verify: (cubit) {
        expect(cubit.state.deathAcknowledgement, DeathAcknowledgement.done);
        expect(h.acknowledger.calls, ['d-1']);
      },
      expect: () => [
        isA<QuestResultsState>().having(
          (state) => state.deathAcknowledgement,
          'deathAcknowledgement',
          DeathAcknowledgement.inFlight,
        ),
        isA<QuestResultsState>().having(
          (state) => state.deathAcknowledgement,
          'deathAcknowledgement',
          DeathAcknowledgement.done,
        ),
      ],
    );

    test('a second call while in flight is ignored', () async {
      final hold = Completer<void>();
      h.acknowledger.hold = hold;
      await h.showDeath('d-1');

      final first = h.cubit.acknowledgeDeath('d-1');
      await h.cubit.acknowledgeDeath('d-1');
      expect(h.state.deathAcknowledgement, DeathAcknowledgement.inFlight);

      hold.complete();
      await first;
      expect(h.acknowledger.calls, ['d-1']);
    });

    test('a failure keeps the sheet showing as failed', () async {
      h.acknowledger.error = _connectionLost;
      await h.showDeath('d-1');

      await h.cubit.acknowledgeDeath('d-1');

      expect(h.state.deathAcknowledgement, DeathAcknowledgement.failed);
      expect(h.state.showing?.id, 'd-1');
    });

    test('only the death showing can be acknowledged', () async {
      await h.offer([_death('d-1'), _success('r-1', minute: 1)]);

      await h.cubit.acknowledgeDeath('d-1');
      h.cubit.presented('d-1');
      await h.cubit.acknowledgeDeath('r-1');

      expect(h.acknowledger.calls, isEmpty);
      expect(h.state.deathAcknowledgement, DeathAcknowledgement.idle);
    });

    test('closing after done does not acknowledge again', () async {
      await h.showDeath('d-1');
      await h.cubit.acknowledgeDeath('d-1');

      h.cubit.closed('d-1');
      await pumpEventQueue();

      expect(h.acknowledger.calls, ['d-1']);
      expect(h.state.showing, isNull);
    });

    test('done stops offering sheets while results stay queued', () async {
      await h.offer([_death('d-1'), _success('r-1', minute: 1)]);
      h.cubit.presented('d-1');
      expect(h.state.isAcceptingSheets, isTrue);

      await h.cubit.acknowledgeDeath('d-1');
      h.cubit.closed('d-1');

      expect(h.state.isAcceptingSheets, isFalse);
      expect(h.queuedIds, ['r-1']);
    });
  });

  group('QuestResultsCubit user refresh after the death ack (checker W2)', () {
    test('done requests exactly one user refresh', () async {
      await h.showDeath('d-1');

      await h.cubit.acknowledgeDeath('d-1');
      await pumpEventQueue();

      expect(h.refreshRequests, 1);
    });

    test('failed requests none', () async {
      h.acknowledger.error = _connectionLost;
      await h.showDeath('d-1');

      await h.cubit.acknowledgeDeath('d-1');
      await pumpEventQueue();

      expect(h.refreshRequests, 0);
    });

    test('a retry that reaches done still requests one in total', () async {
      h.acknowledger.errorOnce = _connectionLost;
      await h.showDeath('d-1');

      await h.cubit.acknowledgeDeath('d-1');
      await h.cubit.acknowledgeDeath('d-1');
      await h.cubit.acknowledgeDeath('d-1');
      await pumpEventQueue();

      expect(h.state.deathAcknowledgement, DeathAcknowledgement.done);
      expect(h.acknowledger.calls, ['d-1', 'd-1']);
      expect(h.refreshRequests, 1);
    });
  });
}
