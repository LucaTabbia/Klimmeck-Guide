import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/arrival_reread_ledger.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/travelProgressCubit/travel_progress_cubit.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/travel_fixtures.dart';

final DateTime startTime = DateTime.parse('2026-10-24T10:00:00.000Z');
final DateTime endTime = DateTime.parse('2026-10-24T12:40:00.000Z');
final DateTime halfway = startTime.add(const Duration(minutes: 80));

ActiveTravel travel({
  String startTime = '2026-10-24T10:00:00.000Z',
  String endTime = '2026-10-24T12:40:00.000Z',
  double duration = 9600000,
  Map<String, dynamic>? road,
}) => ActiveTravel.fromJson(
  activeTravelJson(
    startTime: startTime,
    endTime: endTime,
    duration: duration,
    road: road,
  ),
);

TravelRoute routeOf(ActiveTravel travel) => TravelRoute.of(travel.road.points);

TravelProgressActive activeState(TravelProgressCubit cubit) =>
    cubit.state as TravelProgressActive;

void main() {
  group('TravelProgressCubit.follow', () {
    test('starts idle', () {
      final cubit = TravelProgressCubit(clock: FakeServerClockService(halfway));
      expect(cubit.state, const TravelProgressIdle());
      cubit.close();
    });

    test('derives position, route split and remaining time at halfway', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        );
        final states = <TravelProgressState>[];
        final subscription = cubit.stream.listen(states.add);
        final followed = travel();
        final route = routeOf(followed);

        cubit.follow(followed);
        async.flushMicrotasks();

        expect(states, hasLength(1));
        final state = states.single as TravelProgressActive;
        final split = route.splitAt(0.5);
        expect(state.position, route.pointAt(0.5));
        expect(state.travelled, split.travelled);
        expect(state.remaining, split.remaining);
        expect(state.remainingTime, const Duration(minutes: 80));
        expect(state.isArriving, isFalse);
        expect(state.arrivalRefetchCount, 0);
        subscription.cancel();
        cubit.close();
      });
    });

    test('before the start the pawn waits on the first point', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(
            startTime.subtract(const Duration(minutes: 10)),
          ),
        );
        final followed = travel();

        cubit.follow(followed);

        final state = activeState(cubit);
        expect(state.position, followed.road.points.first);
        expect(state.remainingTime, const Duration(minutes: 170));
        expect(state.isArriving, isFalse);
        cubit.close();
      });
    });

    test('past the end the pawn holds the last point while arriving', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(
            endTime.add(const Duration(seconds: 1)),
          ),
        );
        final followed = travel();

        cubit.follow(followed);

        final state = activeState(cubit);
        expect(state.isArriving, isTrue);
        expect(state.position, followed.road.points.last);
        expect(state.remainingTime, Duration.zero);
        cubit.close();
      });
    });

    test('a new cubit after a kill reconstructs the same state', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(halfway);
        final first = TravelProgressCubit(clock: clock)..follow(travel());
        final afterKill = TravelProgressCubit(clock: clock)..follow(travel());

        expect(afterKill.state, first.state);
        first.close();
        afterKill.close();
      });
    });

    test('an equal travel keeps the measured route and emits nothing', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        )..follow(travel());
        final route = activeState(cubit).route;
        final states = <TravelProgressState>[];
        final subscription = cubit.stream.listen(states.add);

        cubit.follow(travel());
        async.flushMicrotasks();

        expect(states, isEmpty);
        expect(identical(activeState(cubit).route, route), isTrue);
        subscription.cancel();
        cubit.close();
      });
    });

    test('a travel with another start time rebuilds the route', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        )..follow(travel());
        final previous = activeState(cubit);
        final other = travel(
          startTime: '2026-10-24T10:30:00.000Z',
          endTime: '2026-10-24T13:10:00.000Z',
          road: travelPathJson(
            coordinates: const [
              [12.0, 23.0],
              [14.0, 25.0],
            ],
          ),
        );

        cubit.follow(other);

        final state = activeState(cubit);
        expect(state, isNot(previous));
        expect(state.travel, other);
        expect(state.route.points, other.road.points);
        cubit.close();
      });
    });

    test('an empty polyline has no position and does not throw', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        );

        cubit.follow(travel(road: travelPathJson(coordinates: const [])));

        final state = activeState(cubit);
        expect(state.position, isNull);
        expect(state.travelled, isEmpty);
        expect(state.remaining, isEmpty);
        cubit.close();
      });
    });

    test('a zero duration is arriving immediately', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(startTime),
        );

        cubit.follow(travel(endTime: '2026-10-24T10:00:00.000Z', duration: 0));

        expect(activeState(cubit).isArriving, isTrue);
        cubit.close();
      });
    });

    test('follow(null) returns to idle', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        )..follow(travel());

        cubit.follow(null);

        expect(cubit.state, const TravelProgressIdle());
        cubit.close();
      });
    });

    blocTest<TravelProgressCubit, TravelProgressState>(
      'follow(null) while idle emits nothing',
      build: () => TravelProgressCubit(clock: FakeServerClockService(halfway)),
      act: (cubit) => cubit.follow(null),
      expect: () => const <TravelProgressState>[],
    );
  });

  group('TravelProgressCubit ticker', () {
    const second = Duration(seconds: 1);

    void step(FakeAsync async, FakeServerClockService clock, Duration by) {
      clock.advance(by);
      async.elapse(by);
    }

    void stepSeconds(
      FakeAsync async,
      FakeServerClockService clock,
      int seconds,
    ) {
      for (var i = 0; i < seconds; i++) {
        step(async, clock, second);
      }
    }

    test('moves the pawn along the route on every tick', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(halfway);
        final followed = travel();
        final cubit = TravelProgressCubit(clock: clock)..follow(followed);

        clock.advance(const Duration(minutes: 40));
        async.elapse(second);

        final state = activeState(cubit);
        expect(state.position, routeOf(followed).pointAt(0.75));
        expect(state.remainingTime, const Duration(minutes: 40));
        cubit.close();
      });
    });

    test('only the server time moves the pawn, never the device clock', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(halfway);
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());
        final initial = cubit.state;
        final states = <TravelProgressState>[];
        final subscription = cubit.stream.listen(states.add);

        async.elapse(const Duration(minutes: 10));

        expect(states, isEmpty);
        expect(cubit.state, initial);

        step(async, clock, second);

        expect(states, hasLength(1));
        subscription.cancel();
        cubit.close();
      });
    });

    test('after endTime the pawn holds the last point with no snap', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          endTime.subtract(const Duration(seconds: 2)),
        );
        final followed = travel();
        final cubit = TravelProgressCubit(clock: clock)..follow(followed);
        expect(activeState(cubit).isArriving, isFalse);

        stepSeconds(async, clock, 2);
        for (var i = 0; i < 30; i++) {
          final state = activeState(cubit);
          expect(state.isArriving, isTrue);
          expect(state.position, followed.road.points.last);
          step(async, clock, second);
        }
        cubit.close();
      });
    });

    test('asks for two silent rereads at most, then stops ticking', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(endTime);
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());
        expect(activeState(cubit).arrivalRefetchCount, 0);

        stepSeconds(async, clock, 5);
        expect(activeState(cubit).arrivalRefetchCount, 1);
        expect(async.pendingTimers, isNotEmpty);

        stepSeconds(async, clock, 60);
        expect(activeState(cubit).arrivalRefetchCount, 2);
        expect(async.pendingTimers, isEmpty);

        step(async, clock, const Duration(minutes: 10));
        expect(activeState(cubit).arrivalRefetchCount, 2);
        cubit.close();
      });
    });

    test('an endTime days in the past settles with no timer', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          endTime.add(const Duration(days: 3)),
        );
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());

        expect(activeState(cubit).arrivalRefetchCount, 2);
        expect(activeState(cubit).isArriving, isTrue);
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('follow(null) mid-travel cancels the timer and goes idle', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        )..follow(travel());
        expect(async.pendingTimers, isNotEmpty);

        cubit.follow(null);

        expect(cubit.state, const TravelProgressIdle());
        expect(async.pendingTimers, isEmpty);
        cubit.close();
      });
    });

    test('close() mid-travel cancels the timer', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(halfway),
        )..follow(travel());

        cubit.close();
        async.flushMicrotasks();

        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a new travel after the ticker stopped restarts it', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          endTime.add(const Duration(days: 3)),
        );
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());
        expect(async.pendingTimers, isEmpty);

        cubit.follow(
          travel(
            startTime: '2026-10-27T12:00:00.000Z',
            endTime: '2026-10-27T14:40:00.000Z',
          ),
        );

        expect(activeState(cubit).isArriving, isFalse);
        expect(async.pendingTimers, isNotEmpty);
        cubit.close();
      });
    });

    test('a resync corrects a stale unsynced offset and keeps ticking', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          halfway.add(const Duration(hours: 2)),
          isSynced: false,
        );
        final followed = travel();
        final cubit = TravelProgressCubit(clock: clock)..follow(followed);
        expect(activeState(cubit).isArriving, isFalse);
        expect(activeState(cubit).arrivalRefetchCount, 0);
        expect(async.pendingTimers, isNotEmpty);

        clock.resync(halfway);
        async.flushMicrotasks();

        final corrected = activeState(cubit);
        expect(corrected.position, routeOf(followed).pointAt(0.5));
        expect(corrected.isArriving, isFalse);
        expect(corrected.arrivalRefetchCount, 0);

        final states = <TravelProgressState>[];
        final subscription = cubit.stream.listen(states.add);
        step(async, clock, second);
        expect(states, hasLength(1));
        subscription.cancel();
        cubit.close();
      });
    });

    test('an unsynced clock decides no arrival and no reread (WR-03)', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          endTime.add(const Duration(minutes: 5)),
          isSynced: false,
        );
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());

        expect(activeState(cubit).isArriving, isFalse);
        expect(activeState(cubit).arrivalRefetchCount, 0);
        expect(cubit.claimArrivalReread(), isFalse);

        step(async, clock, second);
        expect(activeState(cubit).arrivalRefetchCount, 0);
        expect(async.pendingTimers, isNotEmpty);

        clock.resync(endTime.add(const Duration(minutes: 5)));
        async.flushMicrotasks();

        expect(activeState(cubit).isArriving, isTrue);
        expect(activeState(cubit).arrivalRefetchCount, 2);
        expect(cubit.claimArrivalReread(), isTrue);
        cubit.close();
      });
    });

    test('a resync after a settled travel recomputes and restarts', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(
          endTime.add(const Duration(minutes: 5)),
        );
        final followed = travel();
        final cubit = TravelProgressCubit(clock: clock)..follow(followed);
        expect(async.pendingTimers, isEmpty);

        clock.resync(halfway);
        async.flushMicrotasks();

        expect(activeState(cubit).position, routeOf(followed).pointAt(0.5));
        expect(activeState(cubit).isArriving, isFalse);
        expect(async.pendingTimers, isNotEmpty);
        cubit.close();
      });
    });

    test('a resync while idle emits nothing', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(halfway);
        final cubit = TravelProgressCubit(clock: clock);
        final states = <TravelProgressState>[];
        final subscription = cubit.stream.listen(states.add);

        clock.resync(endTime);
        async.flushMicrotasks();

        expect(states, isEmpty);
        expect(async.pendingTimers, isEmpty);
        subscription.cancel();
        cubit.close();
      });
    });

    test('close() cancels the offset subscription before a resync', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(halfway);
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());
        final last = cubit.state;

        cubit.close();
        async.flushMicrotasks();
        clock.resync(endTime);
        async.flushMicrotasks();

        expect(cubit.state, last);
        expect(async.pendingTimers, isEmpty);
      });
    });
  });

  group('TravelProgressCubit.claimArrivalReread (WR-02)', () {
    final afterFirst = endTime.add(const Duration(seconds: 6));

    void tick(FakeAsync async, FakeServerClockService clock, Duration by) {
      clock.advance(by);
      async.elapse(const Duration(seconds: 1));
    }

    test('claims nothing while idle or before the first threshold', () {
      fakeAsync((async) {
        final cubit = TravelProgressCubit(
          clock: FakeServerClockService(endTime),
        );
        expect(cubit.claimArrivalReread(), isFalse);

        cubit.follow(travel());

        expect(cubit.claimArrivalReread(), isFalse);
        cubit.close();
      });
    });

    test('claims one reread per threshold reached, two at most', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(afterFirst);
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());

        expect(cubit.claimArrivalReread(), isTrue);
        expect(cubit.claimArrivalReread(), isFalse);

        tick(async, clock, const Duration(seconds: 60));
        expect(cubit.claimArrivalReread(), isTrue);
        expect(cubit.claimArrivalReread(), isFalse);

        tick(async, clock, const Duration(minutes: 10));
        expect(cubit.claimArrivalReread(), isFalse);
        cubit.close();
      });
    });

    test('a remounted map sharing the ledger rereads no more', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(afterFirst);
        final ledger = ArrivalRereadLedger();
        final first = TravelProgressCubit(clock: clock, rereads: ledger)
          ..follow(travel());
        expect(first.claimArrivalReread(), isTrue);
        first.close();

        final remounted = TravelProgressCubit(clock: clock, rereads: ledger)
          ..follow(travel());

        expect(remounted.claimArrivalReread(), isFalse);
        remounted.close();
      });
    });

    test('a backward resync does not re-arm a claimed reread', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(afterFirst);
        final cubit = TravelProgressCubit(clock: clock)..follow(travel());
        expect(cubit.claimArrivalReread(), isTrue);

        clock.resync(endTime.subtract(const Duration(seconds: 10)));
        async.flushMicrotasks();
        expect(activeState(cubit).arrivalRefetchCount, 0);
        tick(async, clock, const Duration(seconds: 16));

        expect(activeState(cubit).arrivalRefetchCount, 1);
        expect(cubit.claimArrivalReread(), isFalse);
        cubit.close();
      });
    });

    test('a different travel starts with a fresh budget', () {
      fakeAsync((async) {
        final clock = FakeServerClockService(afterFirst);
        final ledger = ArrivalRereadLedger();
        final cubit = TravelProgressCubit(clock: clock, rereads: ledger)
          ..follow(travel());
        expect(cubit.claimArrivalReread(), isTrue);

        cubit.follow(
          travel(
            startTime: '2026-10-24T10:01:00.000Z',
            endTime: '2026-10-24T12:41:00.000Z',
          ),
        );
        clock.advance(const Duration(minutes: 1));
        async.elapse(const Duration(seconds: 1));

        expect(cubit.claimArrivalReread(), isTrue);
        cubit.close();
      });
    });
  });
}
