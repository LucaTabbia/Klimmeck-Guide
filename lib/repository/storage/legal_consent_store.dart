import 'package:shared_preferences/shared_preferences.dart';

/// Versione dei documenti legali accettata su questo dispositivo (D-10, D-12).
///
/// Non è lo storage della sessione: il logout non la tocca. Si cancella solo
/// quando l'account viene eliminato.
abstract interface class LegalConsentStore {
  Future<String?> readAcceptedVersion();

  Future<void> remember(String version);

  Future<void> forget();
}

/// Nessuna cache: ogni lettura va allo storage di piattaforma.
class SharedPreferencesLegalConsentStore implements LegalConsentStore {
  SharedPreferencesLegalConsentStore({
    SharedPreferencesAsync Function()? preferences,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync());

  static const String key = 'klimmeck.legal.acceptedVersion';

  final SharedPreferencesAsync Function() _createPreferences;
  late final SharedPreferencesAsync _preferences = _createPreferences();

  @override
  Future<String?> readAcceptedVersion() => _preferences.getString(key);

  @override
  Future<void> remember(String version) => _preferences.setString(key, version);

  @override
  Future<void> forget() => _preferences.remove(key);
}
