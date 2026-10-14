import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/sync/app_lifecycle_events.dart';

void main() {
  late AppLifecycleEventBus bus;

  setUp(() => bus = AppLifecycleEventBus());
  tearDown(() => bus.close());

  test(
    'every foregrounded listener receives one event per notification',
    () async {
      var first = 0;
      var second = 0;
      var backgrounded = 0;
      bus.foregrounded.listen((_) => first++);
      bus.foregrounded.listen((_) => second++);
      bus.backgrounded.listen((_) => backgrounded++);

      bus.notifyForegrounded();
      await Future<void>.delayed(Duration.zero);

      expect(first, 1);
      expect(second, 1);
      expect(backgrounded, 0);
    },
  );

  test('notifyBackgrounded reaches backgrounded listeners only', () async {
    var backgrounded = 0;
    var foregrounded = 0;
    bus.backgrounded.listen((_) => backgrounded++);
    bus.foregrounded.listen((_) => foregrounded++);

    bus.notifyBackgrounded();
    await Future<void>.delayed(Duration.zero);

    expect(backgrounded, 1);
    expect(foregrounded, 0);
  });

  test('notifying without listeners does not throw', () {
    expect(bus.notifyBackgrounded, returnsNormally);
    expect(bus.notifyForegrounded, returnsNormally);
  });

  test('after close notifications are ignored and streams are done', () async {
    final backgroundedDone = bus.backgrounded.isEmpty;
    final foregroundedDone = bus.foregrounded.isEmpty;

    await bus.close();

    expect(bus.notifyForegrounded, returnsNormally);
    expect(bus.notifyBackgrounded, returnsNormally);
    expect(await backgroundedDone, isTrue);
    expect(await foregroundedDone, isTrue);
  });
}
