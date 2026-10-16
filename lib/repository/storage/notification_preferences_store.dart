import 'package:klimmeck_guide/models/notification_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferenze notifiche per utente, solo sul device (D-10/D-11). Non è un
/// artefatto di sessione: logout e teardown non la toccano. Leggibile anche
/// fuori dall'albero widget (isolate in background di Phase 5, D-14).
abstract interface class NotificationPreferencesStore {
  Future<bool> isEnabled(String userId, NotificationCategory category);

  Future<Map<NotificationCategory, bool>> readAll(String userId);

  Future<void> setEnabled(
    String userId,
    NotificationCategory category, {
    required bool enabled,
  });
}

/// `SharedPreferencesAsync` legge sempre lo storage di piattaforma: nessuna
/// cache per isolate da invalidare. Istanza creata alla prima lettura
/// (il costruttore lancia senza plugin registrato, es. nei test).
class SharedPreferencesNotificationPreferencesStore
    implements NotificationPreferencesStore {
  SharedPreferencesNotificationPreferencesStore({
    SharedPreferencesAsync Function()? preferences,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync());

  static const String keyPrefix = 'klimmeck.notifications';
  static const bool defaultEnabled = true;

  static String keyFor(String userId, NotificationCategory category) =>
      '$keyPrefix.$userId.${category.storageKey}';

  final SharedPreferencesAsync Function() _createPreferences;
  late final SharedPreferencesAsync _preferences = _createPreferences();

  @override
  Future<bool> isEnabled(String userId, NotificationCategory category) async =>
      await _preferences.getBool(keyFor(userId, category)) ?? defaultEnabled;

  @override
  Future<Map<NotificationCategory, bool>> readAll(String userId) async => {
    for (final category in NotificationCategory.values)
      category: await isEnabled(userId, category),
  };

  @override
  Future<void> setEnabled(
    String userId,
    NotificationCategory category, {
    required bool enabled,
  }) => _preferences.setBool(keyFor(userId, category), enabled);
}
