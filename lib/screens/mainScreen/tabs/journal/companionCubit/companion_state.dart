part of 'companion_cubit.dart';

enum CompanionOperation { equip, unequip }

enum CompanionToggleIntent { equip, unequip, ignoredPending }

enum CompanionOutcomeKind {
  failed,

  /// Risposta riuscita senza `characterUpdated` entro il timeout: esito
  /// incerto, solo rilettura.
  settledByTimeout,
}

class PendingCompanion extends Equatable {
  const PendingCompanion({required this.petId, required this.operation});

  final String petId;
  final CompanionOperation operation;

  @override
  List<Object?> get props => [petId, operation];
}

/// Esito da mostrare una volta: la `sequence` crescente rende distinti due
/// esiti identici consecutivi.
class CompanionOutcome extends Equatable {
  const CompanionOutcome({
    required this.sequence,
    required this.petId,
    required this.operation,
    required this.kind,
    this.failure,
  });

  final int sequence;
  final String petId;
  final CompanionOperation operation;
  final CompanionOutcomeKind kind;
  final PetEquipFailure? failure;

  @override
  List<Object?> get props => [sequence, petId, operation, kind, failure];
}

/// Overlay ottimistico sopra `CharacterCubit` (D-10): mai stato del personaggio.
class CompanionState extends Equatable {
  const CompanionState({this.pending, this.outcome});

  final PendingCompanion? pending;
  final CompanionOutcome? outcome;

  /// Compagno da mostrare nello slot: l'operazione in attesa vince sul server.
  String? displayedPetId(Character character) => switch (pending) {
    null => character.assets?.pet?.id,
    PendingCompanion(operation: CompanionOperation.equip, :final petId) =>
      petId,
    PendingCompanion(operation: CompanionOperation.unequip) => null,
  };

  @override
  List<Object?> get props => [pending, outcome];
}
