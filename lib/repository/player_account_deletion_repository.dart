import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/player_account_deletion_failure.dart';
import 'package:klimmeck_guide/repository/services/account/account_deletion_api.dart';

/// Unico accesso dell'eliminazione di un account da parte dell'oste ai servizi
/// (D-15): ogni errore diventa [PlayerAccountDeletionException] (graphql.md:
/// mai OperationException alla UI). Il nome utente non viene mai registrato.
class PlayerAccountDeletionRepository {
  PlayerAccountDeletionRepository({required AccountDeletionApi api})
    : _api = api;

  final AccountDeletionApi _api;

  /// Passa il testo così com'è (lo spazio lo toglie il widget): il BE valida,
  /// risolve il nome nell'ID Twitch e decide chi si può eliminare (regola 4).
  Future<void> deletePlayerAccount(String twitchLogin) async {
    try {
      await _api.deleteAccountByTwitchLogin(twitchLogin);
    } on OperationException catch (error) {
      throw PlayerAccountDeletionException(
        playerAccountDeletionFailureFrom(error),
      );
    } on FormatException {
      throw const PlayerAccountDeletionException(
        PlayerAccountDeletionFailure.unknown,
      );
    }
  }
}
