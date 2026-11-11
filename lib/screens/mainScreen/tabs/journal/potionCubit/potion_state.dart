part of 'potion_cubit.dart';

/// Stato della bevuta di una pozione dal Diario (D-11): mai stato del
/// personaggio, che arriva solo dal flusso `characterUpdated`.
sealed class PotionState extends Equatable {
  const PotionState();
}

final class PotionIdle extends PotionState {
  const PotionIdle();

  @override
  List<Object?> get props => [];
}

final class PotionDrinking extends PotionState {
  const PotionDrinking(this.itemId);

  final String itemId;

  @override
  List<Object?> get props => [itemId];
}

final class PotionDrunk extends PotionState {
  const PotionDrunk(this.itemId, this.result);

  final String itemId;
  final UseItemResult result;

  @override
  List<Object?> get props => [itemId, result];
}

final class PotionRefused extends PotionState {
  const PotionRefused(
    this.itemId,
    this.failure, {
    this.recoveryUntil,
    required this.sequence,
  });

  final String itemId;
  final ItemUseFailure failure;

  /// Fine della ricarica detta dal server (D-19); `null` se non è arrivata.
  final DateTime? recoveryUntil;

  /// Crescente: due rifiuti identici di seguito restano due esiti distinti.
  final int sequence;

  @override
  List<Object?> get props => [itemId, failure, recoveryUntil, sequence];
}
