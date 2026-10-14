import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/utils/silent_retry.dart';

class _Probe {
  _Probe({this.failures = 1 << 30, this.error = 'boom'});

  final int failures;
  final Object error;
  final List<Duration> callTimes = [];
  int calls = 0;

  Future<int> attempt(FakeAsync async) async {
    callTimes.add(async.elapsed);
    calls++;
    if (calls <= failures) throw error;
    return 42;
  }
}

void main() {
  test('default attempts is 8', () {
    expect(defaultSilentRetryAttempts, 8);
  });

  test('returns the value on first success without timers', () {
    fakeAsync((async) {
      final probe = _Probe(failures: 0);
      int? result;
      silentRetry(
        () => probe.attempt(async),
        isCancelled: () => false,
      ).then((v) => result = v);
      async.flushMicrotasks();

      expect(result, 42);
      expect(probe.calls, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('retries with exponential backoff until success', () {
    fakeAsync((async) {
      final probe = _Probe(failures: 2);
      int? result;
      silentRetry(
        () => probe.attempt(async),
        isCancelled: () => false,
      ).then((v) => result = v);
      async.elapse(const Duration(seconds: 10));

      expect(result, 42);
      expect(probe.callTimes, [
        Duration.zero,
        const Duration(seconds: 1),
        const Duration(seconds: 3),
      ]);
    });
  });

  test('gives up after maxAttempts with the last error', () {
    fakeAsync((async) {
      final probe = _Probe();
      Object? gaveUp;
      var giveUps = 0;
      Object? result = 'unset';
      silentRetry<int>(
        () => probe.attempt(async),
        isCancelled: () => false,
        maxAttempts: 3,
        onGiveUp: (e) {
          gaveUp = e;
          giveUps++;
        },
      ).then((v) => result = v);
      async.elapse(const Duration(minutes: 5));

      expect(result, isNull);
      expect(probe.calls, 3);
      expect(giveUps, 1);
      expect(gaveUp, 'boom');
    });
  });

  test('caps the delay at maxDelay', () {
    fakeAsync((async) {
      final probe = _Probe();
      silentRetry<int>(
        () => probe.attempt(async),
        isCancelled: () => false,
        maxAttempts: 6,
        maxDelay: const Duration(seconds: 4),
      );
      async.elapse(const Duration(minutes: 5));

      final waits = [
        for (var i = 1; i < probe.callTimes.length; i++)
          probe.callTimes[i] - probe.callTimes[i - 1],
      ];
      expect(waits, [
        const Duration(seconds: 1),
        const Duration(seconds: 2),
        const Duration(seconds: 4),
        const Duration(seconds: 4),
        const Duration(seconds: 4),
      ]);
    });
  });

  test('a non retryable error stops after one attempt', () {
    fakeAsync((async) {
      final probe = _Probe(error: StateError('fatal'));
      Object? gaveUp;
      Object? result = 'unset';
      silentRetry<int>(
        () => probe.attempt(async),
        isCancelled: () => false,
        shouldRetry: (e) => e is! StateError,
        onGiveUp: (e) => gaveUp = e,
      ).then((v) => result = v);
      async.flushMicrotasks();

      expect(result, isNull);
      expect(probe.calls, 1);
      expect(gaveUp, isA<StateError>());
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('cancellation during a wait stops silently', () {
    fakeAsync((async) {
      final probe = _Probe();
      var cancelled = false;
      var giveUps = 0;
      Object? result = 'unset';
      silentRetry<int>(
        () => probe.attempt(async),
        isCancelled: () => cancelled,
        onGiveUp: (_) => giveUps++,
      ).then((v) => result = v);
      async.elapse(const Duration(milliseconds: 500));
      cancelled = true;
      async.elapse(const Duration(minutes: 5));

      expect(result, isNull);
      expect(probe.calls, 1);
      expect(giveUps, 0);
    });
  });

  test('cancelled before the first attempt never calls attempt', () {
    fakeAsync((async) {
      final probe = _Probe(failures: 0);
      Object? result = 'unset';
      silentRetry<int>(
        () => probe.attempt(async),
        isCancelled: () => true,
      ).then((v) => result = v);
      async.flushMicrotasks();

      expect(result, isNull);
      expect(probe.calls, 0);
    });
  });
}
