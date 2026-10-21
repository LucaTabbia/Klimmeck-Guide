import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/models/push_event.dart';

/// Notifiche di sistema costruite dal FE (D-12) e loro tap (D-15).
abstract interface class LocalNotificationsPort {
  /// Canale `PushChannel.id` + ascolto dei tap (isolate principale).
  Future<void> initialize();

  /// Mostra [event] con id `event.notificationId` e payload `event.intent.toPayload()`.
  Future<void> show(PushEvent event);

  /// Tap con l'app viva.
  Stream<NotificationIntent> get taps;

  /// Tap che ha avviato l'app da killed, letto una sola volta all'avvio (D-14).
  Future<NotificationIntent?> launchIntent();

  /// Pulisce il vassoio a fine sessione (05-RESEARCH Pitfall 13).
  Future<void> cancelAll();
}
