import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/point_of_interest.dart';
import 'package:klimmeck_guide/models/travel/teleport_destination.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'teleport_mode_state.dart';

/// Modalità teletrasporto del GM (10-CONTEXT D-15..D-20), a livello di shell:
/// il pannello chiama `prepare`, la Mappa `teleportTo`/`cancelToPanel`, la
/// shell `cancel` (altro tab, ruolo perso), l'atterraggio del MainScreen
/// `acknowledgeExit`. Nessuna conferma (D-16); il BE resta
/// giudice (ADMIN-04/07). Un Cubit non chiama Cubit: il resto lo orchestra la UI.
class TeleportModeCubit extends Cubit<TeleportModeState>
    with SafeEmit<TeleportModeState> {
  TeleportModeCubit({required InnkeeperRepository repository})
    : _repository = repository,
      super(const TeleportIdle());

  final InnkeeperRepository _repository;

  /// Cresce a ogni cancel/prepare: una risposta arrivata dopo non tocca lo stato.
  int _generation = 0;

  /// [companionIds]: gli altri partecipanti della carta, spostati insieme al
  /// primo (UAT 2026-11-01). [resumeCardKey]: la carta il cui wizard si
  /// riapre all'atterraggio (D-28).
  Future<void> prepare({
    required String characterId,
    required String name,
    List<String> companionIds = const [],
    String? resumeCardKey,
  }) async {
    if (state is TeleportPreparing || state is TeleportActive) return;
    final generation = ++_generation;
    emit(TeleportPreparing(characterId: characterId));
    final TeleportTarget? target;
    try {
      final character = await _repository.readCharacter(characterId);
      target = TeleportTarget.fromCharacter(
        character,
        fallbackName: name,
        companionIds: companionIds,
      );
    } on InnkeeperException catch (error) {
      if (generation != _generation) return;
      emit(
        TeleportPreparationFailed(
          characterId: characterId,
          failure: error.failure,
        ),
      );
      return;
    }
    if (target == null) {
      if (generation != _generation) return;
      emit(
        TeleportPreparationFailed(
          characterId: characterId,
          failure: InnkeeperFailure.malformed,
        ),
      );
      return;
    }
    final pointsOfInterest = await _readPlaces();
    if (generation != _generation) return;
    emit(
      TeleportActive(
        target: target,
        places: innerPlacesOf(pointsOfInterest),
        resumeCardKey: resumeCardKey,
      ),
    );
  }

  /// Il luogo in cui il gruppo si trova già non fa partire nulla (C16).
  Future<void> teleportTo(TeleportDestination destination) async {
    final active = state;
    if (active is! TeleportActive || active.isTeleporting) return;
    if (destination.poiId == active.target.location.id) return;
    final generation = _generation;
    emit(active.copyWith(isTeleporting: true, failure: () => null));
    try {
      // il primo e poi i compagni, uno alla volta: il BE giudica ciascuno
      for (final characterId in [
        active.target.characterId,
        ...active.target.companionIds,
      ]) {
        await _repository.teleport(
          characterId: characterId,
          poiId: destination.poiId,
        );
      }
    } on InnkeeperException catch (error) {
      if (generation != _generation) return;
      _handleTeleportFailure(active, error.failure);
      return;
    }
    if (generation != _generation) return;
    emit(
      TeleportSucceeded(
        target: active.target,
        resumeCardKey: active.resumeCardKey,
      ),
    );
  }

  /// Ignorato mentre il teletrasporto è in volo: la mutation è già partita e
  /// il suo esito deve arrivare (anche col ruolo perso: FORBIDDEN → idle).
  void cancel() {
    if (state case TeleportActive(isTeleporting: true)) return;
    _leave();
  }

  /// «Annulla» dalla Mappa (UAT 2026-11-01): si torna al pannello, non alla
  /// propria Mappa. Ignorato in volo come `cancel`.
  void cancelToPanel() {
    if (state case TeleportActive(isTeleporting: false, :final resumeCardKey)) {
      _generation++;
      emit(TeleportCancelled(resumeCardKey: resumeCardKey));
    }
  }

  /// Il pannello è stato riaperto: la modalità torna a riposo.
  void acknowledgeExit() {
    if (state is TeleportSucceeded || state is TeleportCancelled) {
      emit(const TeleportIdle());
    }
  }

  void _handleTeleportFailure(TeleportActive active, InnkeeperFailure failure) {
    if (failure == InnkeeperFailure.forbidden) {
      _leave();
      return;
    }
    emit(active.copyWith(isTeleporting: false, failure: () => failure));
  }

  /// Senza luoghi il teletrasporto resta sulle città (D-29).
  Future<List<PointOfInterest>> _readPlaces() async {
    try {
      return await _repository.listPointsOfInterest();
    } on InnkeeperException {
      return const [];
    }
  }

  void _leave() {
    _generation++;
    emit(const TeleportIdle());
  }
}
