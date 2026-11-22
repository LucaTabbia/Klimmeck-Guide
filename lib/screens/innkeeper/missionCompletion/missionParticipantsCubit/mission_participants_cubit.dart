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
  Future<void>? _reading;

  /// Legge una volta per insieme di id (D-02): le storie servono prima della
  /// bozza e una bozza ripresa non le rilegge. Il retry resta `load`.
  Future<void> ensureLoaded(List<String> characterIds) async {
    if (_hasLoaded(characterIds)) return;
    await load(characterIds);
  }

  /// Dopo «Inizia la missione»: ciò che si è letto con le storie risale a
  /// quando i partecipanti erano liberi di muoversi (D-02), le posizioni di
  /// «Luogo» valgono solo se lette a partecipanti bloccati. Una lettura in
  /// corso è partita prima del blocco: la si attende e si rilegge.
  Future<void> reread(List<String> characterIds) async {
    await _reading;
    await load(characterIds);
  }

  bool _hasLoaded(List<String> characterIds) {
    if (state is! MissionParticipantsLoaded) return false;
    final ids = characterIds.toSet();
    return ids.length == _lastReadIds.length && ids.containsAll(_lastReadIds);
  }

  /// Una lettura alla volta; dopo un esito un nuovo `load` rilegge tutto.
  Future<void> load(List<String> characterIds) =>
      _reading ??= _read(characterIds).whenComplete(() => _reading = null);

  /// Gli stessi personaggi già letti restano in mostra mentre si rileggono:
  /// le storie non spariscono, le posizioni attendono la risposta.
  Future<void> _read(List<String> characterIds) async {
    final shown = _hasLoaded(characterIds)
        ? state as MissionParticipantsLoaded
        : null;
    _lastReadIds = characterIds.toSet();
    emit(shown?.rereadingPositions() ?? const MissionParticipantsLoading());
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
      emit(
        shown?.withPositionsFailure(error.failure) ??
            MissionParticipantsFailed(failure: error.failure),
      );
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
