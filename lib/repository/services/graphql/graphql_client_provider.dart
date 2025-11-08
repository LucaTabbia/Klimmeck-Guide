import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

ValueNotifier<GraphQLClient> initGraphQLClient() {
  final String httpUrl = 'http://192.168.0.11:3000/api/graphql';
  final String wsUrl = 'ws://192.168.0.11:3000/api/graphql';

  final HttpLink httpLink = HttpLink(httpUrl);

  final WebSocketLink wsLink = WebSocketLink(
    wsUrl,
    config: SocketClientConfig(
      autoReconnect: true,
      inactivityTimeout: const Duration(seconds: 30),
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
      queryRequestTimeout: const Duration(seconds: 30),
    ),
  );
}
