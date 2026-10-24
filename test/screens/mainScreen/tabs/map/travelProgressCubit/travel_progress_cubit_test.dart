import 'package:bloc_test/bloc_test.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/travel/active_travel.dart';
import 'package:klimmeck_guide/models/travel/travel_route.dart';
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
}
