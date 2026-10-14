import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/graphql/socket_connection_monitor.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes/fake_graphql_ws_server.dart';
import '../../../helpers/mocks.dart';

const _wait = Duration(seconds: 5);
const _testTimeout = Timeout(Duration(seconds: 15));

final _userSubscription = gql('''
  subscription OnUserChanged { userUpdated { id } }
''');

/// Test su socket reale (loopback): `test(...)`, mai `testWidgets`.
void main() {
  late FakeGraphQlWsServer server;
  late WebSocketLink link;
  late SocketConnectionMonitor monitor;

  setUp(() async {
    server = FakeGraphQlWsServer();
    await server.start();
    final tokenService = MockAuthTokenService();
    when(() => tokenService.getAccessToken()).thenAnswer((_) async => 't1');
    link = buildWebSocketLink(
      url: server.url,
      policy: WsReconnectPolicy(authService: tokenService),
    );
    monitor = SocketConnectionMonitor(link);
  });

  tearDown(() async {
    await link.dispose();
    await server.stop();
  });

  test(
    'watch creates the client eagerly and emits true once connected',
    () async {
      final states = monitor.watch();

      expect(link.getSocketClient, isNotNull);
      expect(
        await states.firstWhere((connected) => connected).timeout(_wait),
        isTrue,
      );
      expect(server.framesOf('connection_init'), hasLength(1));
    },
    timeout: _testTimeout,
  );

  test(
    'a drop emits true, false, true without repeated values',
    () async {
      final states = StreamIterator<bool>(monitor.watch());
      await _nextTrue(states);

      await server.dropWith(1001);

      expect(await _next(states), isFalse);
      expect(await _next(states), isTrue);
      await states.cancel();
    },
    timeout: _testTimeout,
  );

  test(
    'watch keeps a live subscription alive and never reconnects',
    () async {
      server.onSubscribe = (ws, subscribe) =>
          server.emit(ws, subscribe['id'] as String, {
            'userUpdated': {'id': 'u1'},
          });
      final client = GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      );
      final events = StreamIterator<QueryResult>(
        client.subscribe(SubscriptionOptions(document: _userSubscription)),
      );
      await events.moveNext().timeout(_wait);
      final clientBefore = link.getSocketClient;

      final states = StreamIterator<bool>(monitor.watch());
      await _nextTrue(states);
      server.emit(
        server.sockets.single,
        server.framesOf('subscribe').single['id'] as String,
        {
          'userUpdated': {'id': 'u2'},
        },
      );

      expect(await events.moveNext().timeout(_wait), isTrue);
      expect(events.current.data?['userUpdated']['id'], 'u2');
      expect(identical(link.getSocketClient, clientBefore), isTrue);
      expect(server.framesOf('connection_init'), hasLength(1));
      await states.cancel();
      await events.cancel();
    },
    timeout: _testTimeout,
  );

  test('the stream is done after the link is disposed', () async {
    final states = monitor.watch();
    await states.firstWhere((connected) => connected).timeout(_wait);
    final done = Completer<void>();
    states.listen((_) {}, onDone: done.complete);

    await link.dispose();

    await done.future.timeout(_wait);
  }, timeout: _testTimeout);
}

Future<bool> _next(StreamIterator<bool> states) async {
  expect(await states.moveNext().timeout(_wait), isTrue);
  return states.current;
}

Future<void> _nextTrue(StreamIterator<bool> states) async {
  while (!await _next(states)) {}
}
