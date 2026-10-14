import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_health.dart';
import 'package:klimmeck_guide/repository/services/sync/sync_watchdog.dart';

const _window = Duration(minutes: 3);
const _almost = Duration(minutes: 2, seconds: 59);
const _second = Duration(seconds: 1);
const _tenMinutes = Duration(minutes: 10);

void _run(
  void Function(FakeAsync async, SyncWatchdog dog, int Function() expiries)
  body,
) {
  fakeAsync((async) {
    var expiries = 0;
    final dog = SyncWatchdog(
      onExpired: () async {
        expiries++;
      },
      window: _window,
    );
    body(async, dog, () => expiries);
  });
}

void main() {
  group('degraded-time clock', () {
    test('fresh watchdog is not degraded and never expires', () {
      _run((async, dog, expiries) {
        expect(dog.isDegraded, isFalse);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('idle healthy sources never expire', () {
      _run((async, dog, expiries) {
        dog.markHealthy(SyncSource.socket);
        dog.markHealthy(SyncSource.userStream);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('expires after the window of continuous degradation', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        async.elapse(_almost);
        expect(expiries(), 0);
        async.elapse(_second);
        expect(expiries(), 1);
      });
    });

    test('recovery before the window cancels the clock', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        async.elapse(const Duration(minutes: 2));
        dog.markHealthy(SyncSource.socket);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('repeated markDegraded does not restart the window', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        async.elapse(const Duration(minutes: 1));
        dog.markDegraded(SyncSource.socket);
        async.elapse(const Duration(minutes: 1, seconds: 59));
        expect(expiries(), 0);
        async.elapse(_second);
        expect(expiries(), 1);
      });
    });

    test('touch while degraded restarts a fresh window', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.userStream);
        async.elapse(const Duration(minutes: 2));
        dog.touch();
        async.elapse(_almost);
        expect(expiries(), 0);
        async.elapse(_second);
        expect(expiries(), 1);
      });
    });

    test('touch while not degraded arms nothing', () {
      _run((async, dog, expiries) {
        dog.touch();
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });
  });

  group('terminated streams', () {
    test('terminated character stream with a healthy user stream is fine', () {
      _run((async, dog, expiries) {
        dog.markHealthy(SyncSource.userStream);
        dog.markTerminated(SyncSource.characterStream);
        expect(dog.isDegraded, isFalse);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('terminated stream with no healthy stream is degraded', () {
      _run((async, dog, expiries) {
        dog.markTerminated(SyncSource.characterStream);
        expect(dog.isDegraded, isTrue);
        async.elapse(_almost);
        expect(expiries(), 0);
        async.elapse(_second);
        expect(expiries(), 1);
      });
    });

    test('terminated then a healthy stream at 1:00 cancels the clock', () {
      _run((async, dog, expiries) {
        dog.markTerminated(SyncSource.characterStream);
        async.elapse(const Duration(minutes: 1));
        dog.markHealthy(SyncSource.userStream);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('a degraded source always counts even next to a healthy stream', () {
      _run((async, dog, expiries) {
        dog.markHealthy(SyncSource.characterStream);
        dog.markDegraded(SyncSource.userStream);
        expect(dog.isDegraded, isTrue);
        async.elapse(_window);
        expect(expiries(), 1);
      });
    });

    test('release of the only degraded source cancels the clock', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.characterStream);
        dog.release(SyncSource.characterStream);
        expect(dog.isDegraded, isFalse);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });
  });

  group('background suspension', () {
    test('suspend stops the clock and resume starts a fresh window', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        dog.suspend();
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
        dog.resume();
        async.elapse(_almost);
        expect(expiries(), 0);
        async.elapse(_second);
        expect(expiries(), 1);
      });
    });

    test('degradation while suspended arms nothing until resume', () {
      _run((async, dog, expiries) {
        dog.suspend();
        dog.markDegraded(SyncSource.socket);
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
        dog.resume();
        async.elapse(_window);
        expect(expiries(), 1);
      });
    });

    test('resume while healthy arms nothing', () {
      _run((async, dog, expiries) {
        dog.suspend();
        dog.resume();
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });
  });

  group('latch and dispose', () {
    test('fires once and leaves no pending timers', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        async.elapse(_window);
        dog.markDegraded(SyncSource.userStream);
        async.elapse(_tenMinutes);
        expect(expiries(), 1);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('dispose while degraded prevents expiry', () {
      _run((async, dog, expiries) {
        dog.markDegraded(SyncSource.socket);
        dog.dispose();
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
      });
    });

    test('every method after dispose is a no-op', () {
      _run((async, dog, expiries) {
        dog.dispose();
        dog.markDegraded(SyncSource.socket);
        dog.markTerminated(SyncSource.userStream);
        dog.markHealthy(SyncSource.characterStream);
        dog.release(SyncSource.socket);
        dog.touch();
        dog.suspend();
        dog.resume();
        dog.dispose();
        async.elapse(_tenMinutes);
        expect(expiries(), 0);
        expect(async.pendingTimers, isEmpty);
      });
    });

    test('a failing expiry callback surfaces no unhandled error', () {
      fakeAsync((async) {
        var calls = 0;
        final dog = SyncWatchdog(
          onExpired: () async {
            calls++;
            throw StateError('teardown failed');
          },
          window: _window,
        );
        dog.markDegraded(SyncSource.socket);

        async.elapse(_window);
        async.flushMicrotasks();
        async.elapse(_tenMinutes);

        expect(calls, 1);
        expect(dog.isLatched, isTrue);
      });
    });

    test('a synchronously throwing expiry callback is contained too', () {
      fakeAsync((async) {
        final dog = SyncWatchdog(
          onExpired: () => throw StateError('teardown failed'),
          window: _window,
        );
        dog.markDegraded(SyncSource.socket);

        async.elapse(_window);
        async.flushMicrotasks();

        expect(dog.isLatched, isTrue);
      });
    });
  });
}
