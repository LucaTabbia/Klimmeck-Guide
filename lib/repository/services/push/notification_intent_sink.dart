import 'package:klimmeck_guide/models/notification_intent.dart';

/// Destinazione dei tap dei tipi personali (D-15): li trattiene finché la shell
/// di gioco li consuma.
abstract interface class NotificationIntentSink {
  void offer(NotificationIntent intent);
}
