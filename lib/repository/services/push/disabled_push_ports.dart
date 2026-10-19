import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';

/// Push disabilitato (D-02): file Firebase assente o piattaforma non supportata.
/// Specchio del `NoopPushTransport` del backend.
class NoopPushMessaging implements PushMessagingPort {
  const NoopPushMessaging();

  @override
  Future<String?> token() async => null;

  @override
  Stream<String> get tokenRefreshes => const Stream.empty();

  @override
  Stream<Map<String, String>> get foregroundMessages => const Stream.empty();
}

/// Push disabilitato (D-02): file Firebase assente o piattaforma non supportata.
/// Specchio del `NoopPushTransport` del backend.
class NoopLocalNotifications implements LocalNotificationsPort {
  const NoopLocalNotifications();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> show(PushEvent event) async {}

  @override
  Stream<NotificationIntent> get taps => const Stream.empty();

  @override
  Future<NotificationIntent?> launchIntent() async => null;

  @override
  Future<void> cancelAll() async {}
}

/// Push disabilitato (D-02): file Firebase assente o piattaforma non supportata.
/// Specchio del `NoopPushTransport` del backend.
class UnsupportedNotificationPermission implements NotificationPermissionPort {
  const UnsupportedNotificationPermission();

  @override
  Future<NotificationPermissionStatus> status() async =>
      NotificationPermissionStatus.notDetermined;

  @override
  Future<NotificationPermissionStatus> request() async =>
      NotificationPermissionStatus.notDetermined;

  @override
  Future<void> openSettings() async {}
}
