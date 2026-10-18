import 'dart:async';

import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:klimmeck_guide/repository/storage/notification_preferences_store.dart';

class InMemoryNotificationPreferencesStore
    implements NotificationPreferencesStore {
  final Map<String, bool> values = {};
  int reads = 0;
  int writes = 0;
  bool failNextWrite = false;
  Object? readFailure;
  Completer<void>? readGate;

  static String keyOf(String userId, NotificationCategory category) =>
      '$userId.${category.storageKey}';

  bool? valueOf(String userId, NotificationCategory category) =>
      values[keyOf(userId, category)];

  @override
  Future<bool> isEnabled(String userId, NotificationCategory category) async {
    reads++;
    final failure = readFailure;
    if (failure != null) throw failure;
    return values[keyOf(userId, category)] ??
        NotificationCategory.defaultEnabled;
  }

  @override
  Future<Map<NotificationCategory, bool>> readAll(String userId) async {
    reads++;
    await readGate?.future;
    final failure = readFailure;
    if (failure != null) throw failure;
    return {
      for (final category in NotificationCategory.values)
        category:
            values[keyOf(userId, category)] ??
            NotificationCategory.defaultEnabled,
    };
  }

  @override
  Future<void> setEnabled(
    String userId,
    NotificationCategory category, {
    required bool enabled,
  }) async {
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('write failed');
    }
    writes++;
    values[keyOf(userId, category)] = enabled;
  }
}
