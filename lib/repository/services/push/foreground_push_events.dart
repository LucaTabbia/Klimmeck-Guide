import 'package:klimmeck_guide/models/push_event.dart';
import 'package:klimmeck_guide/repository/services/push/data_message_handler.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';

/// Messaggi ricevuti in foreground per l'utente della shell (D-13): stesso filtro
/// del background, ma senza alcuna notifica di sistema — l'unica superficie in
/// foreground è il banner in-app.
class ForegroundPushEvents {
  ForegroundPushEvents({
    required Stream<Map<String, String>> messages,
    required NotificationPreferencesStore preferences,
    required String userId,
  }) : _messages = messages,
       _preferences = preferences,
       _userId = userId;

  final Stream<Map<String, String>> _messages;
  final NotificationPreferencesStore _preferences;
  final String _userId;

  Stream<PushEvent> get events => _messages.asyncExpand(_accepted);

  Stream<PushEvent> _accepted(Map<String, String> data) async* {
    final event = await acceptPushEvent(
      data,
      userId: _userId,
      preferences: _preferences,
    );
    if (event != null) yield event;
  }
}
