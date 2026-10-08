import 'package:flutter/foundation.dart';
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
  }) : _storage = storage ?? defaultStorage,
       _preferences = preferences ?? SharedPreferences.getInstance;

  /// `resetOnError` è esplicito: in `flutter_secure_storage` 10.3.4 il plugin
  /// Android cancella i dati solo quando la chiave AES salvata non si può più
  /// decifrare (chiave Keystore persa o invalidata, migrazione fallita) o
  /// quando un valore già cifrato non si decifra più. Gli errori transitori
  /// del Keystore all'inizializzazione arrivano come errore, senza wipe. Con
  /// `false` una chiave persa renderebbe lo storage inutilizzabile per sempre,
  /// anche in scrittura dopo un nuovo login.
  static const FlutterSecureStorage defaultStorage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    aOptions: AndroidOptions(resetOnError: true),
  );

  static const String refreshTokenKey = 'klimmeck.session.refresh_token';
  static const String firstLaunchDoneKey = 'klimmeck.session.first_launch_done';

  final FlutterSecureStorage _storage;
  final Future<SharedPreferences> Function() _preferences;
  bool _firstLaunchChecked = false;

  /// Una lettura fallita significa "nessuna sessione disponibile ora", mai
  /// "sessione da cancellare" (D-09): può essere transitoria (iOS
  /// `errSecInteractionNotAllowed` prima del primo sblocco). Il prossimo
  /// login sovrascrive comunque la chiave.
  @override
  Future<String?> readRefreshToken() async {
    await _wipeIfFirstLaunch();
    try {
      return await _storage.read(key: refreshTokenKey);
    } catch (error) {
      debugPrint('[SessionStore] session read failed: ${error.runtimeType}');
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
    if (await _markFirstLaunchDone()) await _clearQuietly();
  }

  /// `true` solo al primo avvio dopo l'installazione e a marker salvato: un
  /// marker non salvabile ripeterebbe il wipe a ogni avvio. Nel dubbio
  /// (preferenze illeggibili o non scrivibili) `false`: mai wipe.
  Future<bool> _markFirstLaunchDone() async {
    try {
      final prefs = await _preferences();
      if (prefs.getBool(firstLaunchDoneKey) ?? false) return false;
      return await prefs.setBool(firstLaunchDoneKey, true);
    } catch (error) {
      debugPrint(
        '[SessionStore] first launch check failed: ${error.runtimeType}',
      );
      return false;
    }
  }

  Future<void> _clearQuietly() async {
    try {
      await _storage.deleteAll();
    } catch (_) {
      // Wipe del primo avvio non riuscito: si prosegue comunque.
    }
  }
}
