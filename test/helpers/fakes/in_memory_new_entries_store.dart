import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/repository/storage/new_entries_store.dart';

class InMemoryNewEntriesStore implements NewEntriesStore {
  final Map<String, Set<String>> seen = {};
  Object? readFailure;
  Object? writeFailure;

  static String keyOf(String characterId, NewEntryCategory category) =>
      '$characterId.${category.storageKey}';

  Set<String>? seenOf(String characterId, NewEntryCategory category) =>
      seen[keyOf(characterId, category)];

  @override
  Future<Set<String>?> readSeen(
    String characterId,
    NewEntryCategory category,
  ) async {
    final failure = readFailure;
    if (failure != null) throw failure;
    return seen[keyOf(characterId, category)];
  }

  @override
  Future<void> writeSeen(
    String characterId,
    NewEntryCategory category,
    Set<String> entryIds,
  ) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    seen[keyOf(characterId, category)] = Set.of(entryIds);
  }
}
