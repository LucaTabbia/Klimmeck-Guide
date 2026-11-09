import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/library_book.dart';
import 'package:klimmeck_guide/repository/storage/library_bookmarks_store.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

import '../../../../../models/lore.dart';
import '../../../../../repository/services/graphql/graphql.dart';

part 'library_state.dart';

class LibraryCubit extends Cubit<LibraryState> with SafeEmit<LibraryState> {
  LibraryCubit(
    this.graphQl, {
    required LibraryBookmarksStore bookmarks,
    required String characterId,
  }) : _bookmarks = bookmarks,
       _characterId = characterId,
       super(const LibraryInitial());

  final KlimmeckGraphQl graphQl;
  final LibraryBookmarksStore _bookmarks;
  final String _characterId;

  /// Cresce a ogni apertura e ritorno ai libri: una lettura più vecchia è scartata (D-19).
  int _generation = 0;
  Set<String>? _lastUnlocked;
  Set<String> _reference = const {};
  bool _isRefreshing = false;
  bool _hasPendingRefresh = false;

  /// Tocco esplicito: il caricamento è ammesso (regola 2).
  Future<void> openBook(LibraryBook book) async {
    final generation = ++_generation;
    emit(const LibraryLoading());
    final List<Lore> lore;
    try {
      lore = _loreOf(book, await graphQl.getAllLores());
    } catch (e) {
      appLog('LibraryCubit.openBook error: ${e.runtimeType}');
      if (generation == _generation) emit(LibraryError(book, e.toString()));
      return;
    }
    final shown = _idsOf(lore);
    final baseline = await _readBaseline(book);
    if (generation != _generation) return;
    _reference = baseline ?? shown;
    emit(
      LibraryLoadData(
        book: book,
        lore: lore,
        newLoreIds: shown.difference(_reference),
      ),
    );
    await _writeBaseline(book, shown);
    if (generation != _generation) return;
    if (_hasPendingRefresh && !_isRefreshing) await _runRefreshLoop();
  }

  /// Rilettura silenziosa (D-05): solo se cambia l'insieme e un libro è aperto;
  /// mai caricamento né errore; una sola rilettura in coda durante il volo o
  /// durante l'apertura del libro.
  Future<void> syncUnlockedLore(List<String> ids) async {
    final next = ids.toSet();
    final previous = _lastUnlocked;
    _lastUnlocked = next;
    if (previous == null || setEquals(previous, next)) return;
    if (state is LibraryLoading || _isRefreshing) {
      _hasPendingRefresh = true;
      return;
    }
    if (state is! LibraryLoadData) return;
    await _runRefreshLoop();
  }

  Future<void> _runRefreshLoop() async {
    _isRefreshing = true;
    try {
      do {
        _hasPendingRefresh = false;
        await _refreshShownBook();
      } while (_hasPendingRefresh && state is LibraryLoadData);
    } finally {
      _isRefreshing = false;
    }
  }

  void goToInitial() {
    _generation++;
    emit(const LibraryInitial());
  }

  Future<void> _refreshShownBook() async {
    final shown = state;
    if (shown is! LibraryLoadData) return;
    final generation = _generation;
    final List<Lore> lore;
    try {
      lore = _loreOf(shown.book, await graphQl.getAllLores());
    } catch (e) {
      appLog('LibraryCubit refresh error: ${e.runtimeType}');
      return;
    }
    if (generation != _generation) return;
    final ids = _idsOf(lore);
    emit(
      LibraryLoadData(
        book: shown.book,
        lore: lore,
        newLoreIds: ids.difference(_reference),
      ),
    );
    await _writeBaseline(shown.book, ids);
  }

  Future<Set<String>?> _readBaseline(LibraryBook book) async {
    try {
      return await _bookmarks.readSeen(_characterId, book);
    } on Object catch (e) {
      appLog('LibraryCubit baseline read error: ${e.runtimeType}');
      return null;
    }
  }

  Future<void> _writeBaseline(LibraryBook book, Set<String> ids) async {
    try {
      await _bookmarks.writeSeen(_characterId, book, ids);
    } on Object catch (e) {
      appLog('LibraryCubit baseline write error: ${e.runtimeType}');
    }
  }

  static List<Lore> _loreOf(LibraryBook book, List<Lore> all) =>
      List.unmodifiable(all.where((lore) => book.holds(lore.type)));

  static Set<String> _idsOf(List<Lore> lore) => {
    for (final entry in lore) entry.id,
  };
}
