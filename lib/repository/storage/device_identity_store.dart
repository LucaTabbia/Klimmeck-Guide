import 'package:klimmeck_guide/models/notification_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identità push del device (D-06): UUID v4 creato una volta, mai ruotato. Sopravvive a
/// logout e cambio account; muore solo con la disinstallazione.
abstract interface class DeviceIdentityStore {
  Future<String> readOrCreate();
}

/// Un valore salvato fuori dall'alfabeto del BE (`[A-Za-z0-9._-]{1,128}`) viene
/// rigenerato; letture concorrenti condividono la stessa creazione.
class SharedPreferencesDeviceIdentityStore implements DeviceIdentityStore {
  SharedPreferencesDeviceIdentityStore({
    SharedPreferencesAsync Function()? preferences,
    String Function()? generateId,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync()),
       _generateId = generateId ?? (() => const Uuid().v4());

  /// Chiave del device, non dell'utente.
  static const String key = 'klimmeck.push.deviceId';

  final SharedPreferencesAsync Function() _createPreferences;
  final String Function() _generateId;
  late final SharedPreferencesAsync _preferences = _createPreferences();
  Future<String>? _pending;

  @override
  Future<String> readOrCreate() => _pending ??= _readOrCreateOnce();

  Future<String> _readOrCreateOnce() async {
    try {
      return await _readOrCreate();
    } catch (_) {
      _pending = null;
      rethrow;
    }
  }

  Future<String> _readOrCreate() async {
    final stored = validEventId(await _preferences.getString(key));
    if (stored != null) return stored;
    final created = _generateId();
    await _preferences.setString(key, created);
    return created;
  }
}
