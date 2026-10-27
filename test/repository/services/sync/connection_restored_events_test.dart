import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/repository/services/sync/connection_restored_events.dart';

void main() {
  late ConnectionRestoredBus bus;

  setUp(() => bus = ConnectionRestoredBus());
  tearDown(() => bus.close());

  test('delivers one event per restored connection', () async {
    var received = 0;
    bus.restored.listen((_) => received++);

    bus.notifyRestored();
    await Future<void>.delayed(Duration.zero);

    expect(received, 1);
  });

  test('exposes the stream through the read-only interface', () async {
    final ConnectionRestoredEvents events = bus;
    var received = 0;
    events.restored.listen((_) => received++);

    bus.notifyRestored();
    await Future<void>.delayed(Duration.zero);

    expect(received, 1);
  });

  test(
    'after close notifications are ignored and the stream is done',
    () async {
      final done = bus.restored.isEmpty;

      await bus.close();

      expect(bus.notifyRestored, returnsNormally);
      expect(await done, isTrue);
    },
  );
}
