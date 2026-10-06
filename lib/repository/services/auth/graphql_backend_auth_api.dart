import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/graphql/mutations/auth_mutations.dart';
import 'package:klimmeck_guide/graphql/queries/auth_queries.dart';
import 'package:klimmeck_guide/models/auth/auth_session.dart';
import 'package:klimmeck_guide/models/user.dart';

import 'auth_api_exception.dart';
import 'backend_auth_api.dart';

/// [BackendAuthApi] su un client GraphQL dedicato: nessun link di autenticazione né
/// retry, così le chiamate di auth non possono mai rientrare nel refresh.
class GraphQlBackendAuthApi implements BackendAuthApi {
  GraphQlBackendAuthApi({required GraphQLClient client}) : _client = client;

  factory GraphQlBackendAuthApi.forEndpoint(String httpUrl) =>
      GraphQlBackendAuthApi(
        client: GraphQLClient(
          link: HttpLink(httpUrl),
          cache: GraphQLCache(store: InMemoryStore()),
          queryRequestTimeout: const Duration(seconds: 15),
        ),
      );

  final GraphQLClient _client;

  @override
  Future<AuthSession> exchangeLoginTicket({
    required String ticket,
    required String codeVerifier,
  }) async {
    final data = await _mutate(AuthMutations.exchangeLoginTicket, {
      'ticket': ticket,
      'codeVerifier': codeVerifier,
    });
    return _parseSession(data, 'exchangeLoginTicket');
  }

  @override
  Future<AuthSession> refreshSession(String refreshToken) async {
    try {
      final data = await _mutate(AuthMutations.refreshSession, {
        'refreshToken': refreshToken,
      });
      return _parseSession(data, 'refreshSession');
    } on SessionRejected {
      rethrow;
    } on TransientAuthFailure {
      rethrow;
    } on AuthApiException catch (error) {
      throw TransientAuthFailure(_codeOf(error));
    }
  }

  @override
  Future<void> logout(String accessToken) async {
    await _mutate(
      AuthMutations.logout,
      const {},
      context: _bearer(accessToken),
    );
  }

  @override
  Future<User> fetchMe(String accessToken) async {
    final result = await _client.query(
      QueryOptions(
        document: gql(AuthQueries.getMe),
        fetchPolicy: FetchPolicy.noCache,
        context: _bearer(accessToken),
      ),
    );
    final data = _dataOrThrow(result);
    try {
      return User.fromJson(data['me'] as Map<String, dynamic>);
    } on Object catch (_) {
      throw const TransientAuthFailure('malformed_response');
    }
  }

  Future<Map<String, dynamic>> _mutate(
    String document,
    Map<String, dynamic> variables, {
    Context? context,
  }) async {
    final result = await _client.mutate(
      MutationOptions(
        document: gql(document),
        variables: variables,
        fetchPolicy: FetchPolicy.noCache,
        context: context,
      ),
    );
    return _dataOrThrow(result);
  }

  Map<String, dynamic> _dataOrThrow(QueryResult result) {
    final exception = result.exception;
    if (exception != null) throw mapAuthOperationException(exception);
    return result.data ?? const {};
  }

  AuthSession _parseSession(Map<String, dynamic> data, String field) {
    try {
      return AuthSession.fromJson(data[field] as Map<String, dynamic>);
    } on Object catch (_) {
      throw const TransientAuthFailure('malformed_response');
    }
  }

  Context _bearer(String accessToken) => Context().withEntry(
    HttpLinkHeaders(headers: {'Authorization': 'Bearer $accessToken'}),
  );

  String _codeOf(AuthApiException error) => switch (error) {
    AccessTokenRejected() => unauthenticatedCode,
    AuthRequestRejected(:final code) => code,
    LoginTicketInvalid() => loginTicketInvalidCode,
    SessionRejected(:final code) => code,
    TransientAuthFailure(:final reason) => reason,
  };
}
