import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/services/account/account_deletion_api.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/session_terminator.dart';

/// Unico accesso dell'eliminazione del proprio account ai servizi: ogni errore
/// diventa [AccountDeletionException] (graphql.md: mai OperationException
/// alla UI).
class AccountDeletionRepository {
  AccountDeletionRepository({
    required AccountDeletionApi api,
    required SessionTerminator terminator,
  }) : _api = api,
       _terminator = terminator;

  final AccountDeletionApi _api;
  final SessionTerminator _terminator;

  /// Successo: il BE ha cancellato tutto e revocato ogni sessione; l'app chiude
  /// in locale, senza nessun'altra chiamata al backend (D-06). Un rifiuto
  /// lascia la sessione com'è.
  Future<void> deleteOwnAccount() async {
    await _guard(_api.deleteMyAccount);
    await _terminator.terminateSession(UnauthenticatedReason.accountDeleted);
  }

  Future<void> _guard(Future<void> Function() call) async {
    try {
      await call();
    } on OperationException catch (error) {
      throw AccountDeletionException(accountDeletionFailureFrom(error));
    } on FormatException {
      throw const AccountDeletionException(AccountDeletionFailure.unknown);
    }
  }
}
