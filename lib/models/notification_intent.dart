import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/utils/backend_identifier.dart';

/// Tap su una notifica (sistema o banner), uniforme nei tre stati dell'app
/// (D-15). Viaggia come payload JSON della notifica locale costruita dal FE.
class NotificationIntent extends Equatable {
  const NotificationIntent({
    required this.category,
    required this.sentAt,
    this.id,
  });

  final NotificationCategory category;
  final String? id;
  final DateTime sentAt;

  String toPayload() => jsonEncode({
    'type': category.wireType,
    if (id != null) 'id': id,
    'sentAt': sentAt.toUtc().toIso8601String(),
  });

  /// `null` per payload assenti o malformati: un tap illeggibile non fa nulla.
  static NotificationIntent? tryFromPayload(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final Object? decoded;
    try {
      decoded = jsonDecode(payload);
    } on FormatException {
      return null;
    }
    if (decoded is! Map<String, dynamic>) return null;
    final category = NotificationCategory.fromWireType(decoded['type']);
    final sentAt = parseSentAt(decoded['sentAt']);
    if (category == null || sentAt == null) return null;
    return NotificationIntent(
      category: category,
      id: validBackendIdentifier(decoded['id']),
      sentAt: sentAt,
    );
  }

  @override
  List<Object?> get props => [category, id, sentAt];
}

/// Istante ISO 8601 normalizzato in UTC, `null` se assente o illeggibile.
DateTime? parseSentAt(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toUtc() : null;
