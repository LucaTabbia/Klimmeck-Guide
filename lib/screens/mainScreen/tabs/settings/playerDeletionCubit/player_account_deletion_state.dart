part of 'player_account_deletion_cubit.dart';

/// Nessun nome utente nello stato: il testo digitato vive solo nel dialog.
class PlayerAccountDeletionState extends Equatable {
  const PlayerAccountDeletionState({
    this.isDeleting = false,
    this.failure,
    this.hasDeleted = false,
  });

  final bool isDeleting;
  final PlayerAccountDeletionFailure? failure;
  final bool hasDeleted;

  @override
  List<Object?> get props => [isDeleting, failure, hasDeleted];
}
