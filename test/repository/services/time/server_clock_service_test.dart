import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/time/server_clock_service.dart';

import '../../../helpers/fakes/fake_server_clock_service.dart';

void main() {
  group('ServerClockService', () {
    late StreamController<void> foregrounded;
    late DateTime device;
    late int fetchCalls;

    setUp(() {
      foregrounded = StreamController<void>.broadcast();
      device = DateTime.utc(2026, 10, 24, 12);
      fetchCalls = 0;
    });

    tearDown(() => foregrounded.close());

    ServerClockService clockWith(Future<DateTime> Function() fetch) =>
        ServerClockService(
          fetchServerTime: () {
            fetchCalls++;
            return fetch();
          },
          foregrounded: foregrounded.stream,
          now: () => device,
        );

    test('before any sync the device time is used and it is not synced', () {
      final clock = clockWith(() async => DateTime.utc(2026, 10, 24, 10));

      expect(clock.now(), device);
      expect(clock.isSynced, isFalse);
    });

    test('a sync applies the server offset', () async {
      final clock = clockWith(() async => DateTime.utc(2026, 10, 24, 10));

      await clock.sync();

      expect(clock.now(), DateTime.utc(2026, 10, 24, 10));
      expect(clock.isSynced, isTrue);
    });

    test('a sync compensates half of the round trip', () async {
      final clock = clockWith(() async {
        device = DateTime.utc(2026, 10, 24, 12, 0, 2);
        return DateTime.utc(2026, 10, 24, 10, 0, 1);
      });

      await clock.sync();

      expect(clock.now(), DateTime.utc(2026, 10, 24, 10, 0, 2));
    });

    test('a failed sync keeps the previous offset', () async {
      var fail = false;
      final clock = clockWith(() async {
        if (fail) throw Exception('offline');
        return DateTime.utc(2026, 10, 24, 10);
      });
      await clock.sync();
      fail = true;

      await clock.sync();

      expect(clock.now(), DateTime.utc(2026, 10, 24, 10));
      expect(clock.isSynced, isTrue);
    });

    test('a synchronous throw of the fetch is swallowed', () async {
      final clock = ServerClockService(
        fetchServerTime: () => throw StateError('boom'),
        foregrounded: foregrounded.stream,
        now: () => device,
      );

      await clock.sync();

      expect(clock.now(), device);
      expect(clock.isSynced, isFalse);
    });

    test('a hanging fetch times out with the offset unchanged', () {
      fakeAsync((async) {
        final clock = clockWith(() => Completer<DateTime>().future);
        var completed = false;

        clock.sync().then((_) => completed = true);
        async.elapse(
          ServerClockService.defaultTimeout - const Duration(milliseconds: 1),
        );
        expect(completed, isFalse);
        async.elapse(const Duration(milliseconds: 1));

        expect(completed, isTrue);
        expect(clock.now(), device);
        expect(clock.isSynced, isFalse);
      });
    });

    test('concurrent syncs share a single fetch', () async {
      final response = Completer<DateTime>();
      final clock = clockWith(() => response.future);

      final first = clock.sync();
      final second = clock.sync();
      response.complete(DateTime.utc(2026, 10, 24, 10));
      await Future.wait([first, second]);

      expect(fetchCalls, 1);
    });

    test('a foreground event triggers a sync', () async {
      clockWith(() async => DateTime.utc(2026, 10, 24, 10));

      foregrounded.add(null);
      await pumpEventQueue();

      expect(fetchCalls, 1);
    });

    test('a device clock change is corrected at the next resume', () async {
      final clock = clockWith(() async => DateTime.utc(2026, 10, 24, 10));
      await clock.sync();

      device = device.add(const Duration(hours: 2));
      expect(clock.now(), DateTime.utc(2026, 10, 24, 12));
      foregrounded.add(null);
      await pumpEventQueue();

      expect(clock.now(), DateTime.utc(2026, 10, 24, 10));
    });

    test('offsetChanges emits after each successful sync', () async {
      final clock = clockWith(() async => DateTime.utc(2026, 10, 24, 10));
      var events = 0;
      clock.offsetChanges.listen((_) => events++);

      await clock.sync();
      await clock.sync();
      await pumpEventQueue();

      expect(events, 2);
    });

    test('offsetChanges stays silent after a failed or timed-out sync', () {
      fakeAsync((async) {
        var hang = false;
        final clock = clockWith(() {
          if (hang) return Completer<DateTime>().future;
          return Future.error(Exception('offline'));
        });
        var events = 0;
        clock.offsetChanges.listen((_) => events++);

        clock.sync();
        async.flushMicrotasks();
        hang = true;
        clock.sync();
        async.elapse(ServerClockService.defaultTimeout);

        expect(events, 0);
      });
    });

    test('after dispose no fetch runs and offsetChanges is done', () async {
      final clock = clockWith(() async => DateTime.utc(2026, 10, 24, 10));
      var done = false;
      clock.offsetChanges.listen((_) {}, onDone: () => done = true);

      await clock.dispose();
      foregrounded.add(null);
      await pumpEventQueue();

      expect(fetchCalls, 0);
      expect(done, isTrue);
    });
  });

  group('FakeServerClockService', () {
    final start = DateTime.utc(2026, 10, 24, 10);

    test('returns the scripted time and advances it', () {
      final clock = FakeServerClockService(start);

      clock.advance(const Duration(minutes: 5));

      expect(clock.now(), start.add(const Duration(minutes: 5)));
      expect(clock.isSynced, isTrue);
    });

    test('counts the sync calls', () async {
      final clock = FakeServerClockService(start);

      await clock.sync();
      await clock.sync();

      expect(clock.syncCalls, 2);
    });

    test(
      'resync sets the time, marks synced and emits offsetChanges',
      () async {
        final clock = FakeServerClockService(start, isSynced: false);
        var events = 0;
        clock.offsetChanges.listen((_) => events++);

        clock.resync(start.add(const Duration(hours: 1)));
        await pumpEventQueue();

        expect(clock.now(), start.add(const Duration(hours: 1)));
        expect(clock.isSynced, isTrue);
        expect(events, 1);
      },
    );
  });
}
