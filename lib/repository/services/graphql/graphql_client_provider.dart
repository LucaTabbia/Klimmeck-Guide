import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';

/// Costruisce e restituisce il `GraphQLClient` auth-aware.
///
/// La signature è `Future<ValueNotifier<GraphQLClient>>` perché il
/// `bootstrapToken` per il `WebSocketLink.initialPayload` deve essere
/// recuperato in modo asincrono prima di creare il link.
///
/// Limitazione Phase 1 (D-07 auth-session-bootstrap/11-CONTEXT.md):
/// `initialPayload` legge il token una volta al setup. Phase 11 ricrea
/// il `WebSocketLink` on-demand dopo ogni token refresh.
Future<ValueNotifier<GraphQLClient>> initGraphQLClient(
  AuthTokenService authTokenService,
) async {
  final httpLink = HttpLink(EnvConfig.graphqlHttpUrl);
  final authLink = AuthAuthLink(authService: authTokenService);

  // Phase 1: token letto una volta al boot per il payload WS iniziale.
  // Phase 11: ricreare il link su refresh (punto di estensione D-07).
  final bootstrapToken = await authTokenService.getAccessToken();
  final wsLink = WebSocketLink(
    EnvConfig.graphqlWsUrl,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: Duration(seconds: EnvConfig.wsInactivityTimeoutSeconds),
      initialPayload: () => <String, dynamic>{
        if (bootstrapToken != null && bootstrapToken.isNotEmpty)
          'Authorization': 'Bearer $bootstrapToken',
      },
    ),
    subProtocol: GraphQLProtocol.graphqlTransportWs,
  );

  final httpWithAuth = authLink.concat(httpLink);
  final link = Link.split((r) => r.isSubscription, wsLink, httpWithAuth);

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      queryRequestTimeout: Duration(seconds: EnvConfig.queryTimeoutSeconds),
    ),
  );
}
