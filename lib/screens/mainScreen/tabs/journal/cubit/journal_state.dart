part of 'journal_cubit.dart';

sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

/// Nessun rifiuto da mostrare: lo stato dell'equipaggiamento arriva solo da
/// `characterUpdated`.
final class JournalIdle extends JournalState {
  const JournalIdle();
}

/// Cambio di equipaggiamento rifiutato (LB-1); [sequence] rende distinti due
/// rifiuti uguali consecutivi.
final class JournalEquipRefused extends JournalState {
  const JournalEquipRefused({required this.failure, required this.sequence});

  final EquipmentFailure failure;
  final int sequence;

  @override
  List<Object?> get props => [failure, sequence];
}
