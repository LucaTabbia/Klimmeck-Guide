import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/mission/mission_prize_options.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'mission_prize_options_state.dart';

/// Catalogo dei premi per personaggio, letto una volta e mai filtrato qui
/// (D-07, D-22, regola 4): il BE lo serve già nei limiti del rango.
class MissionPrizeOptionsCubit extends Cubit<MissionPrizeOptionsState>
    with SafeEmit<MissionPrizeOptionsState> {
  MissionPrizeOptionsCubit({
    required InnkeeperRepository repository,
    required String pendingQuestId,
  }) : _repository = repository,
       _pendingQuestId = pendingQuestId,
       super(const MissionPrizeOptionsState());

  final InnkeeperRepository _repository;
  final String _pendingQuestId;

  /// Nessuna chiamata per opzioni già lette o in volo; un fallimento si riprova.
  Future<void> loadFor(String characterId) async {
    if (state.options.containsKey(characterId) ||
        state.loading.contains(characterId)) {
      return;
    }
    emit(
      state.copyWith(
        loading: {...state.loading, characterId},
        failures: {...state.failures}..remove(characterId),
      ),
    );
    try {
      final options = await _repository.readMissionPrizeOptions(
        pendingQuestId: _pendingQuestId,
        characterId: characterId,
      );
      emit(
        state.copyWith(
          options: {...state.options, characterId: options},
          loading: {...state.loading}..remove(characterId),
        ),
      );
    } on InnkeeperException catch (error) {
      emit(
        state.copyWith(
          loading: {...state.loading}..remove(characterId),
          failures: {...state.failures, characterId: error.failure},
        ),
      );
    }
  }

  Future<void> loadAll(List<String> characterIds) =>
      Future.wait(characterIds.map(loadFor));
}
