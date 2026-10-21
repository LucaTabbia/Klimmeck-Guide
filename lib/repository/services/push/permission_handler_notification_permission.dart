import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';
import 'package:permission_handler/permission_handler.dart';

/// Classificazione Android: mai chiesto = denied senza rationale; negato = rationale o
/// permanentlyDenied. Limite accettato (D-10): su Android 7-12 un'app disattivata a mano
/// risulta notDetermined.
class PermissionHandlerNotificationPermission
    implements NotificationPermissionPort {
  const PermissionHandlerNotificationPermission();

  @override
  Future<NotificationPermissionStatus> status() async {
    final status = await Permission.notification.status;
    if (status.isGranted) return NotificationPermissionStatus.granted;
    if (status.isPermanentlyDenied) return NotificationPermissionStatus.denied;
    return await Permission.notification.shouldShowRequestRationale
        ? NotificationPermissionStatus.denied
        : NotificationPermissionStatus.notDetermined;
  }

  @override
  Future<NotificationPermissionStatus> request() async =>
      (await Permission.notification.request()).isGranted
      ? NotificationPermissionStatus.granted
      : NotificationPermissionStatus.denied;

  @override
  Future<void> openSettings() async {
    await openAppSettings();
  }
}
