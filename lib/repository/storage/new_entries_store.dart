import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voci di Diario e Profilo già viste, per personaggio, solo sul device:
/// servono al sigillo delle aggiunte, mai al BE. Un personaggio ricreato ha
/// un id nuovo e quindi nulla di già visto.
abstract interface class NewEntriesStore {
  /// `null` = categoria mai registrata per questo personaggio.
  Future<Set<String>?> readSeen(String characterId, NewEntryCategory category);

  Future<void> writeSeen(
    String characterId,
    NewEntryCategory category,
    Set<String> entryIds,
  );
}

/// Istanza creata alla prima lettura (il costruttore lancia senza plugin
/// registrato, es. nei test). Gli errori della piattaforma salgono al chiamante.
class SharedPreferencesNewEntriesStore implements NewEntriesStore {
  SharedPreferencesNewEntriesStore({
    SharedPreferencesAsync Function()? preferences,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync());

  static const String keyPrefix = 'klimmeck.newEntries';

  static String keyFor(String characterId, NewEntryCategory category) =>
      '$keyPrefix.$characterId.${category.storageKey}';

  final SharedPreferencesAsync Function() _createPreferences;
  late final SharedPreferencesAsync _preferences = _createPreferences();

  @override
  Future<Set<String>?> readSeen(
    String characterId,
    NewEntryCategory category,
  ) async {
    final ids = await _preferences.getStringList(keyFor(characterId, category));
    return ids == null ? null : Set.unmodifiable(ids);
  }

  @override
  Future<void> writeSeen(
    String characterId,
    NewEntryCategory category,
    Set<String> entryIds,
  ) => _preferences.setStringList(
    keyFor(characterId, category),
    entryIds.toList()..sort(),
  );
}
