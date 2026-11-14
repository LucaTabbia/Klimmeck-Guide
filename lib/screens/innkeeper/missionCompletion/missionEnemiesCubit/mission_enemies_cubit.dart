import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/mission/mission_enemy.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'mission_enemies_state.dart';

/// Lista dei nemici per gli scontri della missione (D-03, D-19): il filtro per
/// luogo e rango è del BE, qui solo «Mostra tutti» e la ricerca per nome.
class MissionEnemiesCubit extends Cubit<MissionEnemiesState>
    with SafeEmit<MissionEnemiesState> {
  MissionEnemiesCubit({
    required InnkeeperRepository repository,
    required String pendingQuestId,
  }) : _repository = repository,
       _pendingQuestId = pendingQuestId,
       super(const MissionEnemiesState());

  final InnkeeperRepository _repository;
  final String _pendingQuestId;

  /// Solo l'ultima lettura chiesta aggiorna la lista.
  int _generation = 0;

  Future<void> load() => _read(state.showAll);

  Future<void> setShowAll(bool showAll) async {
    if (showAll == state.showAll) return;
    await _read(showAll);
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  Future<void> _read(bool showAll) async {
    final generation = ++_generation;
    emit(
      state.copyWith(showAll: showAll, isLoading: true, failure: () => null),
    );
    try {
      final enemies = await _repository.listMissionEnemies(
        _pendingQuestId,
        showAll: showAll,
      );
      if (generation != _generation) return;
      emit(state.copyWith(enemies: enemies, isLoading: false));
    } on InnkeeperException catch (error) {
      if (generation != _generation) return;
      emit(state.copyWith(isLoading: false, failure: () => error.failure));
    }
  }
}
