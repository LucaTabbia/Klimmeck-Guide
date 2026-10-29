part of 'teleport_mode_cubit.dart';

sealed class TeleportModeState extends Equatable {
  const TeleportModeState();
}

final class TeleportIdle extends TeleportModeState {
  const TeleportIdle();

  @override
  List<Object?> get props => [];
}

/// Lettura di `character(id)` dalla riga del pannello (progresso inline).
final class TeleportPreparing extends TeleportModeState {
  const TeleportPreparing({required this.characterId});

  final String characterId;

  @override
  List<Object?> get props => [characterId];
}

/// Lettura fallita: nessun cambio di modalità, la riga mostra l'errore.
final class TeleportPreparationFailed extends TeleportModeState {
  const TeleportPreparationFailed({
    required this.characterId,
    required this.failure,
  });

  final String characterId;
  final InnkeeperFailure failure;

  @override
  List<Object?> get props => [characterId, failure];
}

/// La Mappa mostra solo la pedina scelta (D-15/D-20); `failure` resta sul chip
/// finché un nuovo rilascio non riparte (D-17).
final class TeleportActive extends TeleportModeState {
  const TeleportActive({
    required this.target,
    this.isTeleporting = false,
    this.failure,
  });

  final TeleportTarget target;
  final bool isTeleporting;
  final InnkeeperFailure? failure;

  TeleportActive copyWith({
    bool? isTeleporting,
    InnkeeperFailure? Function()? failure,
  }) => TeleportActive(
    target: target,
    isTeleporting: isTeleporting ?? this.isTeleporting,
    failure: failure != null ? failure() : this.failure,
  );

  @override
  List<Object?> get props => [target, isTeleporting, failure];
}

/// Teletrasporto riuscito: il MainScreen riapre il pannello e chiama
/// `acknowledgeSuccess` (D-17).
final class TeleportSucceeded extends TeleportModeState {
  const TeleportSucceeded({required this.target});

  final TeleportTarget target;

  @override
  List<Object?> get props => [target];
}
