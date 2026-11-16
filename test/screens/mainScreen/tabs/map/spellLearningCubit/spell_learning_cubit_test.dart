import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/screens/mainScreen/tabs/map/spellLearningCubit/spell_learning_cubit.dart';

import '../../../../../helpers/fakes/fake_server_clock_service.dart';

const _second = Duration(seconds: 1);

final DateTime _now = DateTime.utc(2026, 11, 16, 10);

DateTime _in(Duration delta) => _now.add(delta);

void _tick(FakeAsync async, FakeServerClockService clock, {int times = 1}) {
  for (var i = 0; i < times; i++) {
    clock.advance(_second);
    async.elapse(_second);
  }
}

void main() {
  late FakeServerClockService clock;

  setUp(() {
    clock = FakeServerClockService(_now);
  });

  test('starts with no learning in progress (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      expect(cubit.state, const SpellLearningState(null));
      expect(cubit.state.isLearning, isFalse);
      expect(async.pendingTimers, isEmpty);
      cubit.close();
    });
  });

  test('emits the time left to the served end, rounded up to the minute '
      '(D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 29, seconds: 30)));

      expect(cubit.state.remaining, const Duration(minutes: 30));
      expect(cubit.state.isLearning, isTrue);
      cubit.close();
    });
  });

  test('ticks down on the server clock (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 30)));
      _tick(async, clock, times: 600);

      expect(cubit.state.remaining, const Duration(minutes: 20));
      cubit.close();
    });
  });

  test('emits null at the end and stops (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);
      final states = <SpellLearningState>[];
      final subscription = cubit.stream.listen(states.add);

      cubit.follow(_in(const Duration(minutes: 2)));
      _tick(async, clock, times: 120);

      expect(states.last, const SpellLearningState(null));
      expect(async.pendingTimers, isEmpty);
      final emitted = states.length;
      _tick(async, clock, times: 5);
      expect(states, hasLength(emitted));
      subscription.cancel();
      cubit.close();
    });
  });

  test('follows a new end or none (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      cubit.follow(_in(const Duration(minutes: 30)));
      cubit.follow(null);
      expect(cubit.state, const SpellLearningState(null));

      cubit.follow(_in(const Duration(hours: 2)));
      expect(cubit.state.remaining, const Duration(hours: 2));

      cubit.follow(_in(const Duration(minutes: -5)));
      expect(cubit.state.isLearning, isFalse);
      cubit.close();
    });
  });

  test('a clock resync recomputes the time left (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      cubit.follow(_in(const Duration(hours: 2)));
      clock.resync(_in(const Duration(hours: 1)));
      async.flushMicrotasks();

      expect(cubit.state.remaining, const Duration(hours: 1));
      cubit.close();
    });
  });

  test('close cancels the timer (D-26)', () {
    fakeAsync((async) {
      final cubit = SpellLearningCubit(clock: clock);

      cubit.follow(_in(const Duration(hours: 2)));
      expect(async.pendingTimers, hasLength(1));

      cubit.close();
      async.flushMicrotasks();

      expect(async.pendingTimers, isEmpty);
    });
  });
}
