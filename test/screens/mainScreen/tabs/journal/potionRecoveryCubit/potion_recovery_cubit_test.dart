import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/journal/potionRecoveryCubit/potion_recovery_cubit.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';
import '../../../../../helpers/fixtures/spell_fixtures.dart';

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

  test('starts ready (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      expect(cubit.state, const PotionRecoveryState(null));
      expect(cubit.state.isRecovering, isFalse);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('a future date shows the remaining time on the server clock (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 72)));

      expect(cubit.state.remaining, const Duration(minutes: 72));
      expect(cubit.state.isRecovering, isTrue);
      cubit.close();
    });
  });

  test('the remaining time is rounded up to the minute (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 71, seconds: 1)));
      expect(cubit.state.remaining, const Duration(minutes: 72));

      cubit.follow(_in(const Duration(seconds: 20)));
      expect(cubit.state.remaining, const Duration(minutes: 1));
      cubit.close();
    });
  });

  test('emits only when the shown minute changes (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);
      final states = <PotionRecoveryState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.follow(_in(const Duration(minutes: 3)));
      async.flushMicrotasks();
      states.clear();

      _tick(async, clock, times: 59);
      expect(states, isEmpty);

      _tick(async, clock);
      expect(states, const [PotionRecoveryState(Duration(minutes: 2))]);
      subscription.cancel();
      cubit.close();
    });
  });

  test('turns ready when the date passes and stops its timer (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);
      final states = <PotionRecoveryState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.follow(_in(const Duration(minutes: 2)));
      expect(async.pendingTimers, hasLength(1));

      _tick(async, clock, times: 120);

      expect(states.last, const PotionRecoveryState(null));
      expect(async.pendingTimers, isEmpty);
      subscription.cancel();
      cubit.close();
    });
  });

  test('a null or past date is ready and no timer runs (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(null);
      expect(cubit.state, const PotionRecoveryState(null));
      expect(async.pendingTimers, isEmpty);

      cubit.follow(_in(const Duration(minutes: -5)));
      expect(cubit.state, const PotionRecoveryState(null));
      expect(async.pendingTimers, isEmpty);

      cubit.follow(spellFixtureNow);
      expect(cubit.state, const PotionRecoveryState(null));
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('following a new date replaces the countdown (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 72)));
      cubit.follow(_in(const Duration(minutes: 10)));

      expect(cubit.state.remaining, const Duration(minutes: 10));
      expect(async.pendingTimers, hasLength(1));

      cubit.follow(null);
      expect(cubit.state, const PotionRecoveryState(null));
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('a clock resync recomputes the remaining time (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 72)));
      clock.resync(_in(const Duration(minutes: 10)));
      async.flushMicrotasks();

      expect(cubit.state.remaining, const Duration(minutes: 62));
      cubit.close();
    });
  });

  test('close cancels the timer (D-12)', () {
    fakeAsync((async) {
      final cubit = PotionRecoveryCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 72)));
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
    });
  });
}
