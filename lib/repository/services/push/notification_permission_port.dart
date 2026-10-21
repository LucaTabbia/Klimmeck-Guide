/// Stato del permesso notifiche dal sistema operativo (D-10, rivisto dopo 05-RESEARCH C1):
/// su Android solo `permission_handler` distingue "mai chiesto" da "negato".
enum NotificationPermissionStatus { notDetermined, denied, granted }

abstract interface class NotificationPermissionPort {
  Future<NotificationPermissionStatus> status();

  /// Mostra il prompt di sistema. Unico chiamante: `NotificationPermissionGate` (Phase 7).
  Future<NotificationPermissionStatus> request();

  Future<void> openSettings();
}
