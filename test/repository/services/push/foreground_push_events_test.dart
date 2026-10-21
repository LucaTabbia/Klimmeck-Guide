import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/foreground_push_events.dart';

import '../../../helpers/fakes/fake_push_messaging_port.dart';
import '../../../helpers/fakes/in_memory_notification_preferences_store.dart';

void main() {
  const travelEndData = <String, String>{
    'type': 'travelEnd',
    'title': 'Viaggio completato',
    'body': 'Il tuo personaggio è arrivato a destinazione.',
    'sentAt': '2026-10-18T12:00:00.000Z',
    'id': '6712a0c4e1b2c3d4e5f60718',
  };
  const unknownTypeData = <String, String>{
    'type': 'combatResult',
    'title': 'Combattimento',
    'body': 'Esito del combattimento.',
    'sentAt': '2026-10-18T12:00:00.000Z',
  };
  const malformedData = <String, String>{'type': 'travelEnd'};

  late FakePushMessagingPort messaging;
  late InMemoryNotificationPreferencesStore preferences;
  late List<PushEvent> received;

  setUp(() {
    messaging = FakePushMessagingPort();
    preferences = InMemoryNotificationPreferencesStore();
    received = [];
    ForegroundPushEvents(
      messages: messaging.foregroundMessages,
      preferences: preferences,
      userId: 'u-1',
    ).events.listen(received.add);
  });

  tearDown(() => messaging.close());

  Future<void> deliver(Map<String, String> data) async {
    messaging.foreground.add(data);
    await pumpEventQueue();
  }

  void disable(String userId, NotificationCategory category) =>
      preferences.values[InMemoryNotificationPreferencesStore.keyOf(
            userId,
            category,
          )] =
          false;

  test('emits one event for a valid message', () async {
    await deliver(travelEndData);

    expect(received, [PushEvent.tryParse(travelEndData)]);
  });

  test('drops the message when the user disabled its category', () async {
    disable('u-1', NotificationCategory.travelEnd);

    await deliver(travelEndData);

    expect(received, isEmpty);
  });

  test('ignores the toggles of another user', () async {
    disable('u-2', NotificationCategory.travelEnd);

    await deliver(travelEndData);

    expect(received, hasLength(1));
  });

  test('drops malformed and unknown messages and keeps listening', () async {
    await deliver(malformedData);
    await deliver(unknownTypeData);
    await deliver(travelEndData);

    expect(received, [PushEvent.tryParse(travelEndData)]);
  });
}
