part of 'character_deletion_cubit.dart';

class CharacterDeletionState extends Equatable {
  const CharacterDeletionState({
    this.isDeleting = false,
    this.failure,
    this.deletedUser,
  });

  final bool isDeleting;
  final CharacterDeletionFailure? failure;

  /// User restituito dal backend (currentCharacter null): da consegnare ad AuthCubit.adoptUser.
  final User? deletedUser;

  @override
  List<Object?> get props => [isDeleting, failure, deletedUser];
}
