import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'player_account_deletion_state.dart';

/// Eliminazione dell'account di un giocatore da parte dell'oste (ACCOUNT-03,
/// D-15). Nessun pre-controllo lato app: decide il backend.
class PlayerAccountDeletionCubit extends Cubit<PlayerAccountDeletionState>
    with SafeEmit<PlayerAccountDeletionState> {
  PlayerAccountDeletionCubit(this._repository)
    : super(const PlayerAccountDeletionState());

  final PlayerAccountDeletionRepository _repository;

  Future<void> deletePlayer(String twitchLogin) async {
    if (isClosed || state.isDeleting) return;
    emit(const PlayerAccountDeletionState(isDeleting: true));
    final failure = await _delete(twitchLogin);
    emit(
      failure == null
          ? const PlayerAccountDeletionState(hasDeleted: true)
          : PlayerAccountDeletionState(failure: failure),
    );
  }

  /// Stato pulito all'apertura del dialog.
  void reset() => emit(const PlayerAccountDeletionState());

  Future<PlayerAccountDeletionFailure?> _delete(String twitchLogin) async {
    try {
      await _repository.deletePlayerAccount(twitchLogin);
      return null;
    } on PlayerAccountDeletionException catch (error) {
      return error.failure;
    } catch (_) {
      // Garanzia anti-spinner infinito.
      return PlayerAccountDeletionFailure.unknown;
    }
  }
}
