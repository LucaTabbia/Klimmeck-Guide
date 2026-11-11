import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/prisonCubit/prison_cubit.dart';

import '../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../helpers/fixtures/spell_fixtures.dart';

const _second = Duration(seconds: 1);

DateTime _in(Duration delta) => spellFixtureNow.add(delta);

void _tick(FakeAsync async, FakeServerClockService clock, {int times = 1}) {
  for (var i = 0; i < times; i++) {
    clock.advance(_second);
    async.elapse(_second);
  }
}

void main() {
  late FakeServerClockService clock;

  setUp(() {
    clock = FakeServerClockService(spellFixtureNow);
  });

  test('starts free with no timer (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      expect(cubit.state, const PrisonState(null));
      expect(cubit.state.isImprisoned, isFalse);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('a future release on the status imprisons with the remaining time '
      'rounded up to the minute (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.followStatus(_in(const Duration(hours: 9, seconds: 1)));

      expect(cubit.state.isImprisoned, isTrue);
      expect(cubit.state.remaining, const Duration(hours: 9, minutes: 1));
      cubit.close();
    });
  });

  test('frees itself when the release instant passes and stops its timer '
      '(quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);
      final states = <PrisonState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.followStatus(_in(const Duration(minutes: 2)));
      expect(async.pendingTimers, hasLength(1));

      _tick(async, clock, times: 120);

      expect(states.last, const PrisonState(null));
      expect(async.pendingTimers, isEmpty);
      subscription.cancel();
      cubit.close();
    });
  });

  test('a null or past release on the status is free (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.followStatus(null);
      expect(cubit.state.isImprisoned, isFalse);

      cubit.followStatus(_in(const Duration(minutes: -5)));
      expect(cubit.state.isImprisoned, isFalse);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('the release of a CHARACTER_IMPRISONED refusal imprisons a stale '
      'client (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);
      cubit.followStatus(null);

      cubit.learnRelease(_in(const Duration(hours: 3)));

      expect(cubit.state.remaining, const Duration(hours: 3));
      cubit.close();
    });
  });

  test('a status still without the release does not erase the refusal '
      '(quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.learnRelease(_in(const Duration(hours: 3)));
      cubit.followStatus(null);

      expect(cubit.state.remaining, const Duration(hours: 3));
      cubit.close();
    });
  });

  test('the later of the status and refusal releases wins '
      '(quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.learnRelease(_in(const Duration(hours: 3)));
      cubit.followStatus(_in(const Duration(hours: 10)));
      expect(cubit.state.remaining, const Duration(hours: 10));

      cubit.learnRelease(_in(const Duration(hours: 1)));
      expect(cubit.state.remaining, const Duration(hours: 10));

      cubit.learnRelease(null);
      expect(cubit.state.remaining, const Duration(hours: 10));
      cubit.close();
    });
  });

  test('a clock resync recomputes the remaining time (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.followStatus(_in(const Duration(hours: 10)));
      clock.resync(_in(const Duration(hours: 1)));
      async.flushMicrotasks();

      expect(cubit.state.remaining, const Duration(hours: 9));
      cubit.close();
    });
  });

  test('close cancels the timer (quick 261110-cgd)', () {
    fakeAsync((async) {
      final cubit = PrisonCubit(clock: clock);

      cubit.followStatus(_in(const Duration(hours: 10)));
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
    });
  });
}
