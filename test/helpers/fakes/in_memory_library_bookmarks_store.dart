import 'dart:async';

import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/repository/storage/library_bookmarks_store.dart';

class InMemoryLibraryBookmarksStore implements LibraryBookmarksStore {
  final Map<String, Set<String>> seen = {};
  final List<String> writtenKeys = [];
  Object? readFailure;
  Object? writeFailure;
  Completer<void>? readGate;

  static String keyOf(String characterId, LibraryBook book) =>
      '$characterId.${book.storageKey}';

  Set<String>? seenOf(String characterId, LibraryBook book) =>
      seen[keyOf(characterId, book)];

  @override
  Future<Set<String>?> readSeen(String characterId, LibraryBook book) async {
    await readGate?.future;
    final failure = readFailure;
    if (failure != null) throw failure;
    return seen[keyOf(characterId, book)];
  }

  @override
  Future<void> writeSeen(
    String characterId,
    LibraryBook book,
    Set<String> loreIds,
  ) async {
    final failure = writeFailure;
    if (failure != null) throw failure;
    writtenKeys.add(keyOf(characterId, book));
    seen[keyOf(characterId, book)] = Set.of(loreIds);
  }
}
