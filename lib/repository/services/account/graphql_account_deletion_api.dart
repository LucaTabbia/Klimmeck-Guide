import 'package:klimmeck_guide/repository/services/account/account_deletion_api.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql.dart';

/// Le due cancellazioni dell'account sul GraphQL del backend (BE Phase 26).
class GraphQlAccountDeletionApi implements AccountDeletionApi {
  const GraphQlAccountDeletionApi(this._graphQl);

  final KlimmeckGraphQl _graphQl;

  @override
  Future<void> deleteMyAccount() => _graphQl.deleteMyAccount();

  @override
  Future<void> deleteAccountByTwitchLogin(String twitchLogin) =>
      _graphQl.deleteAccountByTwitchLogin(twitchLogin);
}
