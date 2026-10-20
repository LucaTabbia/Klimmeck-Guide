import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';

/// Tetto di ogni chiamata locale prima di `runApp`: un canale di piattaforma bloccato
/// non deve mai trattenere l'avvio del gioco.
const Duration localNotificationsStartupTimeout = Duration(seconds: 2);

/// `false` se l'init fallisce o non risponde in tempo: il push resta disabilitato.
Future<bool> initializeLocalNotifications(
  LocalNotificationsPort notifications,
) async {
  try {
    await notifications.initialize().timeout(localNotificationsStartupTimeout);
    return true;
  } on Object catch (error) {
    debugPrint(
      'Push disabled: notifications unavailable (${error.runtimeType})',
    );
    return false;
  }
}

/// Tap che ha avviato l'app, `null` se la lettura fallisce o non risponde in tempo.
Future<NotificationIntent?> readLaunchIntent(
  LocalNotificationsPort notifications,
) async {
  try {
    return await notifications.launchIntent().timeout(
      localNotificationsStartupTimeout,
    );
  } on Object catch (error) {
    debugPrint('Push launch tap skipped (${error.runtimeType})');
    return null;
  }
}
