part of 'companion_name_cubit.dart';

/// Stato dell'azione «nome del compagno» (D-18, D-19): mai il nome stesso,
/// che arriva solo con `characterUpdated`. `petId` = id a catalogo (D-23).
sealed class CompanionNameState extends Equatable {
  const CompanionNameState();
}

final class CompanionNameIdle extends CompanionNameState {
  const CompanionNameIdle();

  @override
  List<Object?> get props => [];
}

final class CompanionNameSubmitting extends CompanionNameState {
  const CompanionNameSubmitting(this.petId);

  final String petId;

  @override
  List<Object?> get props => [petId];
}

/// [sequence] distingue due salvataggi uguali di fila.
final class CompanionNameSaved extends CompanionNameState {
  const CompanionNameSaved(this.petId, {required this.sequence});

  final String petId;
  final int sequence;

  @override
  List<Object?> get props => [petId, sequence];
}

/// [sequence] distingue due rifiuti uguali di fila (D-21).
final class CompanionNameRefused extends CompanionNameState {
  const CompanionNameRefused(
    this.petId,
    this.failure, {
    required this.sequence,
  });

  final String petId;
  final PetRenameFailure failure;
  final int sequence;

  @override
  List<Object?> get props => [petId, failure, sequence];
}
