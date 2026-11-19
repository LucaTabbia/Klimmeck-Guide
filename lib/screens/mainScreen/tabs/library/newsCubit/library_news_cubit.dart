import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/models/lore.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';
import 'package:klimmeck_guide/repository/storage/library_bookmarks_store.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

/// Libri che contengono almeno una lore mai vista: lo scaffale li mostra
/// aperti e la voce «Libreria» del menù porta il sigillo. Letture sempre
/// silenziose: mai caricamento né errore.
class LibraryNewsCubit extends Cubit<Set<LibraryBook>> {
  LibraryNewsCubit(
    this._graphQl, {
    required LibraryBookmarksStore bookmarks,
    required String characterId,
  }) : _bookmarks = bookmarks,
       _characterId = characterId,
       super(const {});

  final KlimmeckGraphQl _graphQl;
  final LibraryBookmarksStore _bookmarks;
  final String _characterId;

  List<Lore>? _lore;
  Set<String>? _unlocked;

  /// Rilegge le lore solo se l'insieme sbloccato è cambiato (o mai letto).
  Future<void> syncUnlockedLore(List<String> ids) async {
    final next = ids.toSet();
    if (_lore != null && setEquals(_unlocked, next)) return;
    try {
      _lore = await _graphQl.getAllLores();
    } catch (e) {
      appLog('LibraryNewsCubit lore read error: ${e.runtimeType}');
      return;
    }
    _unlocked = next;
    await recount();
  }

  /// Riconta dalle lore già lette: da chiamare quando i segnalibri cambiano.
  Future<void> recount() async {
    final lore = _lore;
    if (lore == null) return;
    final news = <LibraryBook>{};
    for (final book in LibraryBook.values) {
      if (await _holdsNews(book, lore)) news.add(book);
    }
    if (isClosed || setEquals(state, news)) return;
    emit(Set.unmodifiable(news));
  }

  Future<bool> _holdsNews(LibraryBook book, List<Lore> lore) async {
    final ids = {
      for (final entry in lore)
        if (book.holds(entry.type)) entry.id,
    };
    if (ids.isEmpty) return false;
    try {
      final seen = await _bookmarks.readSeen(_characterId, book);
      return seen == null || ids.difference(seen).isNotEmpty;
    } on Object catch (e) {
      appLog('LibraryNewsCubit bookmark read error: ${e.runtimeType}');
      return false;
    }
  }
}
