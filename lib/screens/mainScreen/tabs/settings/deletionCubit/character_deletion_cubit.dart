import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/models/user.dart';
import 'package:klimmeck_guide/repository/character_deletion_failure.dart';
import 'package:klimmeck_guide/repository/character_deletion_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'character_deletion_state.dart';

/// Eliminazione del personaggio corrente dal tab Impostazioni (SET-05).
/// Nessun pre-controllo lato app: decide il backend (D-21).
class CharacterDeletionCubit extends Cubit<CharacterDeletionState>
    with SafeEmit<CharacterDeletionState> {
  CharacterDeletionCubit(this._repository)
    : super(const CharacterDeletionState());

  final CharacterDeletionRepository _repository;

  Future<void> deleteCharacter() async {
    if (isClosed || state.isDeleting) return;
    emit(const CharacterDeletionState(isDeleting: true));
    final failure = await _deleteCurrentCharacter();
    if (failure != null) await _handleFailure(failure);
  }

  /// La sessione non ha adottato lo User (stesso id richiesto): si sblocca e lo dice.
  void handoverRejected() => emit(
    const CharacterDeletionState(
      failure: CharacterDeletionFailure.handoverRejected,
    ),
  );

  Future<CharacterDeletionFailure?> _deleteCurrentCharacter() async {
    try {
      _handOver(await _repository.deleteCurrentCharacter());
      return null;
    } on CharacterDeletionException catch (error) {
      return error.failure;
    } catch (_) {
      // Garanzia anti-spinner infinito.
      return CharacterDeletionFailure.unknown;
    }
  }

  /// CHARACTER_NOT_FOUND = stato stantio (D-18): ci si riallinea con `me`.
  Future<void> _handleFailure(CharacterDeletionFailure failure) async {
    if (failure != CharacterDeletionFailure.notFound) return _fail(failure);
    final unlinked = await _userWithoutCharacter();
    if (unlinked == null) return _fail(CharacterDeletionFailure.unknown);
    _handOver(unlinked);
  }

  Future<User?> _userWithoutCharacter() async {
    try {
      final user = await _repository.fetchCurrentUser();
      return user.currentCharacter == null ? user : null;
    } catch (_) {
      return null;
    }
  }

  /// Ultima emissione: dopo l'adozione la shell (e questo cubit) si smonta.
  void _handOver(User user) =>
      emit(CharacterDeletionState(isDeleting: true, deletedUser: user));

  void _fail(CharacterDeletionFailure failure) =>
      emit(CharacterDeletionState(failure: failure));
}
