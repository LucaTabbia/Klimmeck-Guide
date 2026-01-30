import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

import '../../../config/env_config.dart';

ValueNotifier<GraphQLClient> initGraphQLClient() {
  final HttpLink httpLink = HttpLink(EnvConfig.graphqlHttpUrl);

  final WebSocketLink wsLink = WebSocketLink(
    EnvConfig.graphqlWsUrl,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: Duration(seconds: EnvConfig.wsInactivityTimeoutSeconds),
      initialPayload: () => <String, dynamic>{},
    ),
    subProtocol: GraphQLProtocol.graphqlTransportWs,
  );

  final Link link = Link.split(
    (request) => request.isSubscription,
    wsLink,
    httpLink,
  );

  return ValueNotifier(
    GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
      queryRequestTimeout: Duration(seconds: EnvConfig.queryTimeoutSeconds),
    ),
  );
}
