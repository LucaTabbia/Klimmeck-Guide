import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

ValueNotifier<GraphQLClient> initGraphQLClient() {
  final String url = 'http://192.168.11.173:3000/api/graphql';

  final HttpLink httpLink = HttpLink(url);

  return ValueNotifier(
    GraphQLClient(
      link: httpLink,
      cache: GraphQLCache(store: null),
      queryRequestTimeout: const Duration(seconds: 30),
    ),
  );
}
