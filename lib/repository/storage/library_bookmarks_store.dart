import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lore viste all'ultimo caricamento di un libro, per personaggio, solo sul
/// device (D-07): servono al segnalibro «Nuovo», mai al BE. Un personaggio
/// ricreato ha un id nuovo e quindi nessun segnalibro.
abstract interface class LibraryBookmarksStore {
  /// `null` = libro mai aperto da questo personaggio.
  Future<Set<String>?> readSeen(String characterId, LibraryBook book);

  Future<void> writeSeen(
    String characterId,
    LibraryBook book,
    Set<String> loreIds,
  );
}

/// Istanza creata alla prima lettura (il costruttore lancia senza plugin
/// registrato, es. nei test). Gli errori della piattaforma salgono al chiamante.
class SharedPreferencesLibraryBookmarksStore implements LibraryBookmarksStore {
  SharedPreferencesLibraryBookmarksStore({
    SharedPreferencesAsync Function()? preferences,
  }) : _createPreferences = preferences ?? (() => SharedPreferencesAsync());

  static const String keyPrefix = 'klimmeck.library';

  static String keyFor(String characterId, LibraryBook book) =>
      '$keyPrefix.$characterId.${book.storageKey}';

  final SharedPreferencesAsync Function() _createPreferences;
  late final SharedPreferencesAsync _preferences = _createPreferences();

  @override
  Future<Set<String>?> readSeen(String characterId, LibraryBook book) async {
    final ids = await _preferences.getStringList(keyFor(characterId, book));
    return ids == null ? null : Set.unmodifiable(ids);
  }

  @override
  Future<void> writeSeen(
    String characterId,
    LibraryBook book,
    Set<String> loreIds,
  ) => _preferences.setStringList(
    keyFor(characterId, book),
    loreIds.toList()..sort(),
  );
}
