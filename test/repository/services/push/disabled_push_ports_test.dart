import 'package:flutter_test/flutter_test.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/push_services.dart';

import '../../../helpers/fakes/fake_notification_permission_port.dart';
import '../../../helpers/fakes/fake_push_messaging_port.dart';
import '../../../helpers/fakes/recording_local_notifications_port.dart';

void main() {
  final event = PushEvent(
    category: NotificationCategory.travelEnd,
    title: 'Viaggio completato',
    body: 'Il tuo personaggio è arrivato a destinazione.',
    sentAt: DateTime.utc(2026, 10, 18, 12),
    id: '6712a0c4e1b2c3d4e5f60718',
  );

  group('PushServices.disabled', () {
    const services = PushServices.disabled();

    test('messaging yields no token and empty, completing streams', () async {
      expect(await services.messaging.token(), isNull);
      expect(await services.messaging.tokenRefreshes.isEmpty, isTrue);
      expect(await services.messaging.foregroundMessages.isEmpty, isTrue);
    });

    test('local notifications are inert', () async {
      final notifications = services.localNotifications;

      await expectLater(notifications.initialize(), completes);
      await expectLater(notifications.show(event), completes);
      await expectLater(notifications.cancelAll(), completes);
      expect(await notifications.taps.isEmpty, isTrue);
      expect(await notifications.launchIntent(), isNull);
    });

    test('carries no launch intent', () {
      expect(services.launchIntent, isNull);
    });

    test('permission is never determined and settings open quietly', () async {
      expect(
        await services.permission.status(),
        NotificationPermissionStatus.notDetermined,
      );
      expect(
        await services.permission.request(),
        NotificationPermissionStatus.notDetermined,
      );
      await expectLater(services.permission.openSettings(), completes);
    });

    test('keeps the given permission port', () {
      final permission = FakeNotificationPermissionPort();

      final services = PushServices.disabled(permission: permission);

      expect(services.permission, same(permission));
    });
  });

  test('PushServices exposes exactly the ports passed in', () {
    final messaging = FakePushMessagingPort();
    final notifications = RecordingLocalNotificationsPort();
    final permission = FakeNotificationPermissionPort();
    final launch = NotificationIntent(
      category: NotificationCategory.questEnd,
      sentAt: DateTime.utc(2026, 10, 18),
    );

    final services = PushServices(
      messaging: messaging,
      localNotifications: notifications,
      permission: permission,
      launchIntent: launch,
    );

    expect(services.messaging, same(messaging));
    expect(services.localNotifications, same(notifications));
    expect(services.permission, same(permission));
    expect(services.launchIntent, same(launch));
  });
}
