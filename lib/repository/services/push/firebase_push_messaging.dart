import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:klimmeck_guide/repository/services/push/push_messaging_port.dart';

/// Adapter FCM di [PushMessagingPort]: unico file app che usa `FirebaseMessaging` oltre a
/// bootstrap e handler in background.
class FirebasePushMessaging implements PushMessagingPort {
  FirebasePushMessaging(this._messaging);

  final FirebaseMessaging _messaging;

  @override
  Future<String?> token() => _messaging.getToken();

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Stream<Map<String, String>> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(
        (message) => message.data.map((key, value) => MapEntry(key, '$value')),
      );
}
