import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/city.dart';
import 'package:klimmeck_guide/models/travel/teleport_target.dart';
import 'package:klimmeck_guide/models/travel/travel_destination.dart';
import 'package:klimmeck_guide/repository/innkeeper_failure.dart';
import 'package:klimmeck_guide/repository/innkeeper_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'teleport_mode_state.dart';

/// Modalità teletrasporto del GM (10-CONTEXT D-15..D-20), a livello di shell:
/// il pannello chiama `prepare`, la Mappa `teleportTo`/`cancel`, l'atterraggio
/// del MainScreen `acknowledgeSuccess`. Nessuna conferma (D-16); il BE resta
/// giudice (ADMIN-04/07). Un Cubit non chiama Cubit: il resto lo orchestra la UI.
class TeleportModeCubit extends Cubit<TeleportModeState>
    with SafeEmit<TeleportModeState> {
  TeleportModeCubit({required InnkeeperRepository repository})
    : _repository = repository,
      super(const TeleportIdle());

  final InnkeeperRepository _repository;

  /// Cresce a ogni cancel/prepare: una risposta arrivata dopo non tocca lo stato.
  int _generation = 0;

  Future<void> prepare({
    required String characterId,
    required String name,
  }) async {
    if (state is TeleportPreparing || state is TeleportActive) return;
    final generation = ++_generation;
    emit(TeleportPreparing(characterId: characterId));
    final TeleportModeState next;
    try {
      final character = await _repository.readCharacter(characterId);
      final target = TeleportTarget.fromCharacter(
        character,
        fallbackName: name,
      );
      next = target == null
          ? TeleportPreparationFailed(
              characterId: characterId,
              failure: InnkeeperFailure.malformed,
            )
          : TeleportActive(target: target);
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
    if (generation != _generation) return;
    emit(next);
  }

  Future<void> teleportTo(City city) async {
    final active = state;
    if (active is! TeleportActive || active.isTeleporting) return;
    final destination = travelDestinationFor(
      target: city,
      location: active.target.location,
    );
    if (destination == null) return;
    final generation = _generation;
    emit(active.copyWith(isTeleporting: true, failure: () => null));
    try {
      await _repository.teleport(
        characterId: active.target.characterId,
        poiId: destination.markerLocation!.id,
      );
    } on InnkeeperException catch (error) {
      if (generation != _generation) return;
      _handleTeleportFailure(active, error.failure);
      return;
    }
    if (generation != _generation) return;
    emit(TeleportSucceeded(target: active.target));
  }

  void cancel() {
    _generation++;
    emit(const TeleportIdle());
  }

  void acknowledgeSuccess() {
    if (state is TeleportSucceeded) emit(const TeleportIdle());
  }

  void _handleTeleportFailure(TeleportActive active, InnkeeperFailure failure) {
    if (failure == InnkeeperFailure.forbidden) {
      cancel();
      return;
    }
    emit(TeleportActive(target: active.target, failure: failure));
  }
}
