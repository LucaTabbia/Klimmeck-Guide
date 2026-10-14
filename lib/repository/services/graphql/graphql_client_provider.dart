import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/auth/auth_token_service.dart';
import 'package:klimmeck_guide/repository/services/auth/unauthorized_recovery.dart';
import 'package:klimmeck_guide/repository/services/graphql/auth_link.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  final webSocketLink = buildWebSocketLink(
    url: EnvConfig.graphqlWsUrl,
    policy: policy,
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

/// Ping a livello WebSocket: un socket semiaperto (wifi→cellulare, tunnel)
/// non risponde al pong e viene chiuso con `goingAway`, che passa dal normale
/// `onConnectionLost` (Phase 3, Pitfall 2). Il timeout limita un connect in un
/// buco nero. `SocketClient` avvolge da sé il canale con `forGraphQL()`.
Future<WebSocketChannel> connectWithKeepAlive(
  Uri uri,
  Iterable<String>? protocols,
) => openKeepAliveChannel(uri, protocols);

/// Apre il canale con ping e timeout di connect. Gli intervalli sono
/// parametrizzati solo perché i test possano usare valori brevi.
Future<WebSocketChannel> openKeepAliveChannel(
  Uri uri,
  Iterable<String>? protocols, {
  Duration pingInterval = const Duration(
    seconds: EnvConfig.wsPingIntervalSeconds,
  ),
  Duration connectTimeout = const Duration(
    seconds: EnvConfig.wsConnectTimeoutSeconds,
  ),
}) async {
  final channel = IOWebSocketChannel.connect(
    uri,
    protocols: protocols,
    pingInterval: pingInterval,
    connectTimeout: connectTimeout,
  );
  await channel.ready;
  return channel;
}

/// Link WebSocket con riconnessione, token per connect e keep-alive. Stessa
/// factory per produzione e test di integrazione.
WebSocketLink buildWebSocketLink({
  required String url,
  required WsReconnectPolicy policy,
}) => WebSocketLink(
  url,
  config: SocketClientConfig(
    autoReconnect: true,
    inactivityTimeout: const Duration(
      seconds: EnvConfig.wsInactivityTimeoutSeconds,
    ),
    initialPayload: policy.buildInitialPayload,
    onConnectionLost: policy.onConnectionLost,
    connectFn: connectWithKeepAlive,
  ),
  subProtocol: GraphQLProtocol.graphqlTransportWs,
);
