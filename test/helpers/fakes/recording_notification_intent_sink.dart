import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/repository/services/push/notification_intent_sink.dart';

/// [NotificationIntentSink] che registra gli intent offerti.
class RecordingNotificationIntentSink implements NotificationIntentSink {
  final List<NotificationIntent> offered = [];

  @override
  void offer(NotificationIntent intent) => offered.add(intent);
}
