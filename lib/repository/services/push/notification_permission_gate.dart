import 'package:klimmeck_guide/repository/services/push/notification_permission_port.dart';

/// Unico punto che può mostrare il prompt notifiche (D-10). Unico chiamante: la prima conferma
/// di viaggio di Phase 7 (call site documentato in BACKEND-NOTES.md di questa fase). Chiede solo
/// se il sistema non ha ancora deciso; nulla viene salvato dall'app: il SO è la fonte di verità.
class NotificationPermissionGate {
  NotificationPermissionGate(this._permission);

  final NotificationPermissionPort _permission;
  Future<NotificationPermissionStatus>? _inFlight;

  Future<NotificationPermissionStatus> ensureRequested() =>
      _inFlight ??= _ensureRequested().whenComplete(() => _inFlight = null);

  Future<NotificationPermissionStatus> _ensureRequested() async {
    final current = await _permission.status();
    if (current != NotificationPermissionStatus.notDetermined) return current;
    return _permission.request();
  }
}
