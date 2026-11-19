import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/enums/new_entry_category.dart';
import 'package:klimmeck_guide/repository/storage/new_entries_store.dart';
import 'package:klimmeck_guide/utils/app_log.dart';

part 'new_entries_state.dart';

/// Aggiunte a Diario e Profilo non ancora viste. Il confronto è con ciò che
/// il device ha già visto: letture e scritture sempre silenziose.
class NewEntriesCubit extends Cubit<NewEntriesState> {
  NewEntriesCubit({required NewEntriesStore store, required String characterId})
    : _store = store,
      _characterId = characterId,
      super(const NewEntriesState());

  final NewEntriesStore _store;
  final String _characterId;

  Map<NewEntryCategory, Set<String>> _owned = const {};
  final Map<NewEntryCategory, Set<String>> _seen = {};

  /// Allineamenti e visite si eseguono uno alla volta, nell'ordine d'arrivo.
  Future<void> _queue = Future.value();

  /// [owned]: le voci che il personaggio ha ora, per categoria. Alla prima
  /// registrazione di una categoria nulla è nuovo; una voce persa torna nuova
  /// se ricompare.
  Future<void> sync(Map<NewEntryCategory, Set<String>> owned) =>
      _enqueue(() async {
        _owned = owned;
        final unseen = <NewEntryCategory, Set<String>>{};
        for (final MapEntry(key: category, value: ids) in owned.entries) {
          final seen = await _seenOf(category, firstSight: ids);
          if (seen == null) continue;
          final stillOwned = seen.intersection(ids);
          if (stillOwned.length != seen.length) {
            await _remember(category, stillOwned);
          }
          final fresh = ids.difference(stillOwned);
          if (fresh.isNotEmpty) unseen[category] = fresh;
        }
        _publish(unseen: unseen, highlighted: state.highlighted);
      });

  /// Ingresso in una pagina: le sue aggiunte restano segnate fino alla
  /// prossima visita e da ora valgono come viste.
  Future<void> visit(Set<NewEntryCategory> categories) => _enqueue(() async {
    final unseen = {...state.unseen};
    final highlighted = {...state.highlighted};
    for (final category in categories) {
      final fresh = unseen.remove(category);
      if (fresh == null) {
        highlighted.remove(category);
        continue;
      }
      highlighted[category] = fresh;
      await _remember(category, _owned[category] ?? const {});
    }
    _publish(unseen: unseen, highlighted: highlighted);
  });

  Future<void> _enqueue(Future<void> Function() step) =>
      _queue = _queue.then((_) => step());

  void _publish({
    required Map<NewEntryCategory, Set<String>> unseen,
    required Map<NewEntryCategory, Set<String>> highlighted,
  }) {
    if (isClosed) return;
    emit(NewEntriesState(unseen: unseen, highlighted: highlighted));
  }

  /// `null` = store illeggibile: non si segna nulla.
  Future<Set<String>?> _seenOf(
    NewEntryCategory category, {
    required Set<String> firstSight,
  }) async {
    final cached = _seen[category];
    if (cached != null) return cached;
    final Set<String>? stored;
    try {
      stored = await _store.readSeen(_characterId, category);
    } on Object catch (e) {
      appLog('NewEntriesCubit read error: ${e.runtimeType}');
      return null;
    }
    if (stored != null) return _seen[category] = stored;
    await _remember(category, firstSight);
    return firstSight;
  }

  Future<void> _remember(NewEntryCategory category, Set<String> ids) async {
    _seen[category] = ids;
    try {
      await _store.writeSeen(_characterId, category, ids);
    } on Object catch (e) {
      appLog('NewEntriesCubit write error: ${e.runtimeType}');
    }
  }
}
