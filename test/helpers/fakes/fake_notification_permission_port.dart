import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';

/// [NotificationPermissionPort] con stato e risposta al prompt scriptati.
class FakeNotificationPermissionPort implements NotificationPermissionPort {
  FakeNotificationPermissionPort({
    this.current = NotificationPermissionStatus.notDetermined,
    this.requestResult = NotificationPermissionStatus.granted,
  });

  NotificationPermissionStatus current;
  NotificationPermissionStatus requestResult;
  int statusCalls = 0;
  int requestCalls = 0;
  int openSettingsCalls = 0;
  Object? statusFailure;

  @override
  Future<NotificationPermissionStatus> status() async {
    statusCalls++;
    final failure = statusFailure;
    if (failure != null) throw failure;
    return current;
  }

  @override
  Future<NotificationPermissionStatus> request() async {
    requestCalls++;
    current = requestResult;
    return current;
  }

  @override
  Future<void> openSettings() async => openSettingsCalls++;
}
