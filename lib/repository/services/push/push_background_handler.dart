import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:klimmeck_guide/repository/services/push/data_message_handler.dart';
import 'package:klimmeck_guide/repository/services/push/flutter_local_notifications_adapter.dart';
import 'package:klimmeck_guide/repository/storage/active_user_store.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';

/// Ingresso dell'isolate in background/killed (D-12). Top-level e non anonimo, come richiede
/// `onBackgroundMessage`. Usa solo store, modelli e l'adapter notifiche: niente Firebase,
/// dotenv, tema o BuildContext.
@pragma('vm:entry-point')
Future<void> firebaseBackgroundMessageHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();
  final notifications = FlutterLocalNotificationsAdapter();
  await notifications.initializeWithoutTaps();
  await handleDataMessage(
    message.data,
    activeUser: SharedPreferencesActiveUserStore(),
    preferences: SharedPreferencesNotificationPreferencesStore(),
    notifier: notifications,
  );
}
