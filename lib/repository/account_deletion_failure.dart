import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_api_exception.dart'
    show unauthenticatedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String innkeeperAccountProtectedCode = 'INNKEEPER_ACCOUNT_PROTECTED';

/// Esiti di dominio dell'eliminazione dell'account; la UI li traduce in copy
/// italiana.
enum AccountDeletionFailure {
  /// L'account dell'oste non si elimina dall'App (D-16): decide il backend.
  innkeeperProtected,
  unauthenticated,
  connection,
  unknown,
}

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.failure);

  final AccountDeletionFailure failure;

  @override
  String toString() => 'AccountDeletionException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai usato.
AccountDeletionFailure accountDeletionFailureFrom(
  OperationException exception,
) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return AccountDeletionFailure.connection;
  }
  return switch (code) {
    innkeeperAccountProtectedCode => AccountDeletionFailure.innkeeperProtected,
    unauthenticatedCode => AccountDeletionFailure.unauthenticated,
    _ => AccountDeletionFailure.unknown,
  };
}
