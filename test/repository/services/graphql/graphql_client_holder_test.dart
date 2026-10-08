import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/mocks.dart';

class _SpyWebSocketLink extends WebSocketLink {
  _SpyWebSocketLink({this.failOnDispose = false, this.disposal})
    : super('ws://test.invalid/graphql');

  final bool failOnDispose;
  final Future<void>? disposal;
  int disposeCalls = 0;

  @override
  Future<void> dispose() async {
    disposeCalls++;
    await disposal;
    if (failOnDispose) throw StateError('socket already closed');
  }
}

void main() {
  late List<GraphQLConnection> connections;
  late bool failNextDispose;
  Future<void>? nextDisposal;

  setUp(() {
    connections = [];
    failNextDispose = false;
    nextDisposal = null;
  });

  GraphQLConnection connect() {
    final link = _SpyWebSocketLink(
      failOnDispose: failNextDispose,
      disposal: nextDisposal,
    );
    final connection = (
      client: GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
      webSocketLink: link as WebSocketLink,
    );
    connections.add(connection);
    return connection;
  }

  int disposeCallsOf(int index) =>
      (connections[index].webSocketLink as _SpyWebSocketLink).disposeCalls;

  group('GraphQLClientHolder', () {
    test('connects once and exposes the first client', () {
      final holder = GraphQLClientHolder(connect: connect);

      expect(connections, hasLength(1));
      expect(holder.client.value, same(connections.first.client));
    });

    test('reset disposes the websocket and installs a new client', () async {
      final holder = GraphQLClientHolder(connect: connect);
      var notifications = 0;
      holder.client.addListener(() => notifications++);

      await holder.reset();

      expect(disposeCallsOf(0), 1);
      expect(connections, hasLength(2));
      expect(holder.client.value, same(connections[1].client));
      expect(notifications, 1);
    });

    test('two consecutive resets dispose each link once', () async {
      final holder = GraphQLClientHolder(connect: connect);

      await holder.reset();
      await holder.reset();

      expect(connections, hasLength(3));
      expect(disposeCallsOf(0), 1);
      expect(disposeCallsOf(1), 1);
      expect(disposeCallsOf(2), 0);
      expect(holder.client.value, same(connections[2].client));
    });

    test(
      'overlapping resets share one recreation: no undisposed link',
      () async {
        final slowDisposal = Completer<void>();
        nextDisposal = slowDisposal.future;
        final holder = GraphQLClientHolder(connect: connect);
        nextDisposal = null;

        final first = holder.reset();
        final second = holder.reset();
        slowDisposal.complete();
        await Future.wait([first, second]);

        expect(connections, hasLength(2));
        expect(disposeCallsOf(0), 1);
        expect(holder.client.value, same(connections[1].client));
      },
    );

    test('a reset after an overlapping pair recreates again', () async {
      final holder = GraphQLClientHolder(connect: connect);

      await Future.wait([holder.reset(), holder.reset()]);
      await holder.reset();

      expect(connections, hasLength(3));
      expect(disposeCallsOf(1), 1);
      expect(holder.client.value, same(connections[2].client));
    });

    test('installs the new client even when dispose fails', () async {
      failNextDispose = true;
      final holder = GraphQLClientHolder(connect: connect);

      await holder.reset();

      expect(disposeCallsOf(0), 1);
      expect(holder.client.value, same(connections[1].client));
    });
  });

  group('buildGraphQLConnection', () {
    test('builds client and websocket link without reading a token', () {
      final mockService = MockAuthTokenService();

      final connection = buildGraphQLConnection(authService: mockService);

      expect(connection.client, isA<GraphQLClient>());
      expect(connection.webSocketLink, isA<WebSocketLink>());
      expect(connection.webSocketLink.getSocketClient, isNull);
      verifyZeroInteractions(mockService);
    });

    test('accepts the unauthorized recovery for the real session', () {
      final mockService = MockAuthTokenService();

      final connection = buildGraphQLConnection(
        authService: mockService,
        recovery: MockUnauthorizedRecovery(),
      );

      expect(connection.client, isA<GraphQLClient>());
      verifyZeroInteractions(mockService);
    });
  });
}
