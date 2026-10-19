import 'package:flutter/foundation.dart';
import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/local_notifications_port.dart';
import 'package:klimmeck_guide/repository/storage/active_user_store.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';

/// Filtro comune a background e foreground (D-14): messaggio valido, utente noto, toggle attivo.
/// `null` = non mostrare nulla. Mai un'eccezione verso il chiamante.
Future<PushEvent?> acceptPushEvent(
  Map<String, Object?> data, {
  required String? userId,
  required NotificationPreferencesStore preferences,
}) async {
  final event = PushEvent.tryParse(data);
  if (event == null) {
    debugPrint('Push dropped: unknown or malformed message');
    return null;
  }
  if (userId == null) return null;
  try {
    return await preferences.isEnabled(userId, event.category) ? event : null;
  } on Object catch (error) {
    debugPrint('Push dropped: preferences unavailable (${error.runtimeType})');
    return null;
  }
}

/// Decisione dell'isolate in background (D-12): una notifica di sistema se [acceptPushEvent] la ammette.
Future<void> handleDataMessage(
  Map<String, Object?> data, {
  required ActiveUserStore activeUser,
  required NotificationPreferencesStore preferences,
  required LocalNotificationsPort notifier,
}) async {
  final event = await acceptPushEvent(
    data,
    userId: await _activeUserId(activeUser),
    preferences: preferences,
  );
  if (event == null) return;
  await notifier.show(event);
}

Future<String?> _activeUserId(ActiveUserStore store) async {
  try {
    return await store.read();
  } on Object catch (error) {
    debugPrint('Push dropped: active user unavailable (${error.runtimeType})');
    return null;
  }
}
