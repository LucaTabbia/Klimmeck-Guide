import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/notification.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:klimmeck_guide/utils/backend_identifier.dart';
import 'package:klimmeck_guide/utils/stable_notification_id.dart';

/// Messaggio data-only del backend già validato (BE Phase 5 §2). Il payload non
/// porta stato di gioco: il FE ri-interroga il backend (regola 4).
class PushEvent extends Equatable {
  const PushEvent({
    required this.category,
    required this.title,
    required this.body,
    required this.sentAt,
    this.id,
  });

  final NotificationCategory category;
  final String title;
  final String body;
  final DateTime sentAt;
  final String? id;

  /// `null` per tipi sconosciuti o campi mancanti (D-04): mai un'eccezione.
  static PushEvent? tryParse(Map<String, Object?> data) {
    final category = NotificationCategory.fromWireType(data['type']);
    final title = data['title'];
    final body = data['body'];
    final sentAt = parseSentAt(data['sentAt']);
    if (category == null || sentAt == null) return null;
    if (title is! String || title.isEmpty) return null;
    if (body is! String || body.isEmpty) return null;
    return PushEvent(
      category: category,
      title: title,
      body: body,
      sentAt: sentAt,
      id: category.isPersonal ? validBackendIdentifier(data['id']) : null,
    );
  }

  /// Chiave di dedup (D-18) e base dell'id Android: `(tipo, id)` oppure, senza
  /// id, `(tipo, minuto di sentAt)`.
  String get dedupKey => '${category.wireType}|${id ?? _sentAtMinute}';

  int get notificationId => stableNotificationId(dedupKey);

  NotificationIntent get intent =>
      NotificationIntent(category: category, id: id, sentAt: sentAt);

  KGNotification get notification =>
      KGNotification(title: title, description: body);

  String get _sentAtMinute {
    final utc = sentAt.toUtc();
    return DateTime.utc(
      utc.year,
      utc.month,
      utc.day,
      utc.hour,
      utc.minute,
    ).toIso8601String();
  }

  @override
  List<Object?> get props => [category, title, body, sentAt, id];
}
