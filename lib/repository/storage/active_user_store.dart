import 'package:shared_preferences/shared_preferences.dart';

/// Utente attivo per l'isolate in background (D-09): scritto all'autenticazione, cancellato a
/// fine sessione. Senza utente attivo il push in background viene scartato.
abstract interface class ActiveUserStore {
  Future<String?> read();

  Future<void> write(String userId);

  Future<void> clear();
}

/// Nessuna cache: ogni lettura va allo storage di piattaforma, così l'isolate in
/// background vede subito le scritture del main isolate.
class SharedPreferencesActiveUserStore implements ActiveUserStore {
  SharedPreferencesActiveUserStore({
    SharedPreferencesAsync Function()? preferences,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync());

  static const String key = 'klimmeck.push.activeUserId';

  final SharedPreferencesAsync Function() _createPreferences;
  late final SharedPreferencesAsync _preferences = _createPreferences();

  @override
  Future<String?> read() => _preferences.getString(key);

  @override
  Future<void> write(String userId) => _preferences.setString(key, userId);

  @override
  Future<void> clear() => _preferences.remove(key);
}
