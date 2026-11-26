import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/account/account_deletion_api.dart';

/// [AccountDeletionApi] in memoria: conta le richieste e, se [error] è
/// impostato, lo lancia da entrambe le cancellazioni.
class FakeAccountDeletionApi implements AccountDeletionApi {
  int deleteMyAccountCalls = 0;
  final List<String> deletedTwitchLogins = [];
  Object? error;

  /// Eseguito dentro `deleteMyAccount` prima che risponda: la revoca che
  /// arriva mentre la cancellazione è in volo.
  Future<void> Function()? beforeDeleteMyAccountReturns;

  @override
  Future<void> deleteMyAccount() async {
    deleteMyAccountCalls++;
    await beforeDeleteMyAccountReturns?.call();
    final failure = error;
    if (failure != null) throw failure;
  }

  @override
  Future<void> deleteAccountByTwitchLogin(String twitchLogin) async {
    deletedTwitchLogins.add(twitchLogin);
    final failure = error;
    if (failure != null) throw failure;
  }
}

/// Errore GraphQL con [code] in `extensions.code` e un testo del server
/// che l'app non deve mai leggere.
OperationException operationExceptionWithCode(
  String code, {
  String message = 'server text',
}) => OperationException(
  graphqlErrors: [
    GraphQLError(message: message, extensions: {'code': code}),
  ],
);
