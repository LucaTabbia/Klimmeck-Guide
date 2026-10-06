import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistenza degli artefatti di sessione. Solo il refresh token è persistito
/// (AUTH-02): l'access JWT vive in memoria.
abstract interface class SessionStore {
  Future<String?> readRefreshToken();
  Future<void> writeRefreshToken(String refreshToken);
  Future<void> clear();
}

/// [SessionStore] su storage cifrato di piattaforma (Keychain / Keystore).
///
/// Il Keychain iOS sopravvive alla disinstallazione dell'app: un marker non
/// segreto in `shared_preferences` (che invece viene cancellato) segnala il
/// primo avvio dopo l'installazione e fa svuotare lo storage cifrato prima
/// della prima lettura.
///
/// `first_unlock_this_device` permette l'avvio in background da push con
/// device bloccato e impedisce la migrazione della sessione su un nuovo device.
class SecureSessionStore implements SessionStore {
  SecureSessionStore({
    FlutterSecureStorage? storage,
    Future<SharedPreferences> Function()? preferences,
  }) : _storage =
           storage ??
           const FlutterSecureStorage(
             iOptions: IOSOptions(
               accessibility: KeychainAccessibility.first_unlock_this_device,
             ),
           ),
       _preferences = preferences ?? SharedPreferences.getInstance;

  static const String refreshTokenKey = 'klimmeck.session.refresh_token';
  static const String firstLaunchDoneKey = 'klimmeck.session.first_launch_done';

  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _preferences;
  bool _firstLaunchChecked = false;

  @override
  Future<String?> readRefreshToken() async {
    await _wipeIfFirstLaunch();
    try {
      return await _storage.read(key: refreshTokenKey);
    } catch (_) {
      await _clearQuietly();
      return null;
    }
  }

  @override
  Future<void> writeRefreshToken(String refreshToken) =>
      _storage.write(key: refreshTokenKey, value: refreshToken);

  @override
  Future<void> clear() => _storage.delete(key: refreshTokenKey);

  Future<void> _wipeIfFirstLaunch() async {
    if (_firstLaunchChecked) return;
    _firstLaunchChecked = true;
    final prefs = await _preferences();
    if (prefs.getBool(firstLaunchDoneKey) ?? false) return;
    await _clearQuietly();
    await prefs.setBool(firstLaunchDoneKey, true);
  }

  Future<void> _clearQuietly() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Storage irrecuperabile: si prosegue comunque senza sessione.
    }
  }
}
