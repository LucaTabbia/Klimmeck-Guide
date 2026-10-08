import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';

/// Client GraphQL e il suo `WebSocketLink`, che va disposto al logout.
typedef GraphQLConnection = ({
  GraphQLClient client,
  WebSocketLink webSocketLink,
});

/// Unico punto di creazione del client GraphQL autenticato
/// (docs/rules/graphql.md).
///
/// Sincrona: nessun token viene letto al boot; il socket nasce alla prima
/// subscription e a ogni (ri)connessione invia il token corrente tramite
/// [WsReconnectPolicy] (D-07). Il link non viene ricreato dopo un refresh
/// (D-37), solo al logout da `GraphQLClientHolder.reset()` (D-12).
///
/// [recovery] è `null` con lo stub dev: nessun retry, nessun refresh.
GraphQLConnection buildGraphQLConnection({
  required AuthTokenService authService,
  UnauthorizedRecovery? recovery,
}) {
  final policy = WsReconnectPolicy(
    authService: authService,
    recovery: recovery,
  );
  final webSocketLink = WebSocketLink(
    EnvConfig.graphqlWsUrl,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: const Duration(
        seconds: EnvConfig.wsInactivityTimeoutSeconds,
      ),
      initialPayload: policy.buildInitialPayload,
      onConnectionLost: policy.onConnectionLost,
    ),
    subProtocol: GraphQLProtocol.graphqlTransportWs,
  );
  final httpWithAuth = AuthAuthLink(
    authService: authService,
    recovery: recovery,
  ).concat(HttpLink(EnvConfig.graphqlHttpUrl));
  final client = GraphQLClient(
    link: Link.split(
      (request) => request.isSubscription,
      webSocketLink,
      httpWithAuth,
    ),
    cache: GraphQLCache(store: InMemoryStore()),
    queryRequestTimeout: const Duration(seconds: EnvConfig.queryTimeoutSeconds),
  );
  return (client: client, webSocketLink: webSocketLink);
}
