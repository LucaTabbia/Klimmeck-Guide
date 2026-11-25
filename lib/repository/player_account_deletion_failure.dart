import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/account_deletion_failure.dart'
    show innkeeperAccountProtectedCode;
import 'package:klimmeck_guide/repository/services/graphql/graphql_error_code.dart';

const String twitchUserNotFoundCode = 'TWITCH_USER_NOT_FOUND';
const String accountNotFoundCode = 'ACCOUNT_NOT_FOUND';
const String twitchUnavailableCode = 'TWITCH_UNAVAILABLE';

/// Esiti di dominio dell'eliminazione di un account da parte dell'oste (D-15);
/// la UI li traduce in copy italiana.
enum PlayerAccountDeletionFailure {
  twitchUserNotFound,
  accountNotFound,

  /// L'account di un oste non si elimina dall'App (D-16): decide il backend.
  innkeeperProtected,
  twitchUnavailable,
  connection,
  unknown,
}

/// Non porta il nome utente digitato: `toString` stampa solo l'esito.
class PlayerAccountDeletionException implements Exception {
  const PlayerAccountDeletionException(this.failure);

  final PlayerAccountDeletionFailure failure;

  @override
  String toString() => 'PlayerAccountDeletionException(${failure.name})';
}

/// Solo `extensions.code`: il testo dei messaggi del server non viene mai
/// usato. `FORBIDDEN` (chi non è oste) ricade nel generico.
PlayerAccountDeletionFailure playerAccountDeletionFailureFrom(
  OperationException exception,
) {
  final code = graphQlErrorCode(exception);
  if (code == null && exception.linkException != null) {
    return PlayerAccountDeletionFailure.connection;
  }
  return switch (code) {
    twitchUserNotFoundCode => PlayerAccountDeletionFailure.twitchUserNotFound,
    accountNotFoundCode => PlayerAccountDeletionFailure.accountNotFound,
    innkeeperAccountProtectedCode =>
      PlayerAccountDeletionFailure.innkeeperProtected,
    twitchUnavailableCode => PlayerAccountDeletionFailure.twitchUnavailable,
    _ => PlayerAccountDeletionFailure.unknown,
  };
}
