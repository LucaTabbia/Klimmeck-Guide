import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/disabled_push_ports.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';
import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';

/// Porte push composte una volta in `main()` (D-02): abilitate con Firebase pronto,
/// no-op altrimenti. Il resto dell'app non sa quale delle due riceve.
class PushServices {
  const PushServices({
    required this.messaging,
    required this.localNotifications,
    required this.permission,
    this.launchIntent,
  });

  const PushServices.disabled({
    this.permission = const UnsupportedNotificationPermission(),
  }) : messaging = const NoopPushMessaging(),
       localNotifications = const NoopLocalNotifications(),
       launchIntent = null;

  final PushMessagingPort messaging;
  final LocalNotificationsPort localNotifications;
  final NotificationPermissionPort permission;

  /// Tap che ha avviato l'app (killed), se c'è.
  final NotificationIntent? launchIntent;
}
