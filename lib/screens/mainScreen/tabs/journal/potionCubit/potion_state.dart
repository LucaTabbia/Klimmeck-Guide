part of 'potion_cubit.dart';

/// Stato della bevuta di una pozione dal Diario (D-11): mai stato del
/// personaggio, che arriva solo dal flusso `characterUpdated`.
/// `targetPetId` / `targetName` = compagno bersaglio e suo nome mostrato
/// (D-07, D-20); `null` quando beve il personaggio.
sealed class PotionState extends Equatable {
  const PotionState();
}

final class PotionIdle extends PotionState {
  const PotionIdle();

  @override
  List<Object?> get props => [];
}

final class PotionDrinking extends PotionState {
  const PotionDrinking(this.itemId, {this.targetPetId, this.targetName});

  final String itemId;
  final String? targetPetId;
  final String? targetName;

  @override
  List<Object?> get props => [itemId, targetPetId, targetName];
}

final class PotionDrunk extends PotionState {
  const PotionDrunk(
    this.itemId,
    this.result, {
    this.targetPetId,
    this.targetName,
  });

  final String itemId;
  final UseItemResult result;
  final String? targetPetId;
  final String? targetName;

  @override
  List<Object?> get props => [itemId, result, targetPetId, targetName];
}

final class PotionRefused extends PotionState {
  const PotionRefused(
    this.itemId,
    this.failure, {
    this.recoveryUntil,
    required this.sequence,
    this.targetPetId,
    this.targetName,
  });

  final String itemId;
  final ItemUseFailure failure;

  /// Fine della ricarica detta dal server (D-19, D-05); `null` se non è
  /// arrivata.
  final DateTime? recoveryUntil;

  /// Crescente: due rifiuti identici di seguito restano due esiti distinti.
  final int sequence;
  final String? targetPetId;
  final String? targetName;

  @override
  List<Object?> get props => [
    itemId,
    failure,
    recoveryUntil,
    sequence,
    targetPetId,
    targetName,
  ];
}
