import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/account_deletion_repository.dart';
import 'package:klimmeck_guide/shared/bloc/safe_emit.dart';

part 'account_deletion_state.dart';

/// Eliminazione del proprio account dal tab Impostazioni (ACCOUNT-01).
/// Nessun pre-controllo lato app: decide il backend.
class AccountDeletionCubit extends Cubit<AccountDeletionState>
    with SafeEmit<AccountDeletionState> {
  AccountDeletionCubit(this._repository) : super(const AccountDeletionState());

  final AccountDeletionRepository _repository;

  /// Al successo lo spinner resta: la sessione si chiude e l'AuthGate
  /// sostituisce l'albero (questo cubit compreso).
  Future<void> deleteAccount() async {
    if (isClosed || state.isDeleting) return;
    emit(const AccountDeletionState(isDeleting: true));
    final failure = await _deleteOwnAccount();
    if (failure != null) emit(AccountDeletionState(failure: failure));
  }

  Future<AccountDeletionFailure?> _deleteOwnAccount() async {
    try {
      await _repository.deleteOwnAccount();
      return null;
    } on AccountDeletionException catch (error) {
      return error.failure;
    } catch (_) {
      // Garanzia anti-spinner infinito.
      return AccountDeletionFailure.unknown;
    }
  }
}
