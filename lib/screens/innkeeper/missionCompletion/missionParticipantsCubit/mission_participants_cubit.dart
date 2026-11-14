import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'mission_participants_state.dart';

/// Personaggi del gruppo e luoghi del mondo per i nomi del flusso guidato
/// (D-29): mai limiti né regole, quelli li serve la bozza (regola 4).
class MissionParticipantsCubit extends Cubit<MissionParticipantsState>
    with SafeEmit<MissionParticipantsState> {
  MissionParticipantsCubit({required InnkeeperRepository repository})
    : _repository = repository,
      super(const MissionParticipantsIdle());

  final InnkeeperRepository _repository;

  /// Una lettura alla volta; dopo un esito un nuovo `load` rilegge tutto.
  Future<void> load(List<String> characterIds) async {
    if (state is MissionParticipantsLoading) return;
    emit(const MissionParticipantsLoading());
    try {
      final characters = await Future.wait(
        characterIds.map(_repository.readCharacter),
      );
      final places = await _repository.listPointsOfInterest();
      emit(
        MissionParticipantsLoaded(
          characters: Map.unmodifiable({
            for (final (index, character) in characters.indexed)
              characterIds[index]: character,
          }),
          places: Map.unmodifiable({
            for (final place in places) place.id: place,
          }),
        ),
      );
    } on InnkeeperException catch (error) {
      emit(MissionParticipantsFailed(failure: error.failure));
    }
  }
}
