import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/character/character.dart';
import 'package:klimmeck_guide/models/enums/title_type.dart';
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
  Set<String> _lastReadIds = const {};

  /// Legge una volta per insieme di id (D-02): le storie servono prima della
  /// bozza e non si rileggono dopo l'inizio. Il retry resta `load`.
  Future<void> ensureLoaded(List<String> characterIds) async {
    if (_hasLoaded(characterIds)) return;
    await load(characterIds);
  }

  bool _hasLoaded(List<String> characterIds) {
    if (state is! MissionParticipantsLoaded) return false;
    final ids = characterIds.toSet();
    return ids.length == _lastReadIds.length && ids.containsAll(_lastReadIds);
  }

  /// Una lettura alla volta; dopo un esito un nuovo `load` rilegge tutto.
  Future<void> load(List<String> characterIds) async {
    if (state is MissionParticipantsLoading) return;
    _lastReadIds = characterIds.toSet();
    emit(const MissionParticipantsLoading());
    try {
      final characters = await Future.wait(
        characterIds.map(_repository.readCharacter),
      );
      final places = await _placesOrNone();
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

  /// I luoghi danno solo le etichette: senza di essi i nomi restano vuoti e
  /// il teletrasporto in città resta possibile (D-31).
  Future<List<PointOfInterest>> _placesOrNone() async {
    try {
      return await _repository.listPointsOfInterest();
    } on InnkeeperException {
      return const [];
    }
  }
}
