import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:klimmeck_guide/config/env_config.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_holder.dart';
import 'package:klimmeck_guide/repository/services/graphql/graphql_client_provider.dart';
import 'package:klimmeck_guide/repository/services/graphql/ws_reconnect_policy.dart';
import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/io.dart';

import '../../../helpers/fakes/fake_graphql_ws_server.dart';
import '../../../helpers/mocks.dart';

const _wait = Duration(seconds: 5);

final _userSubscription = gql('''
  subscription OnUserChanged { userUpdated { id } }
''');

/// Test su socket reale (loopback): `test(...)`, mai `testWidgets`.
void main() {
  late FakeGraphQlWsServer server;
  late MockAuthTokenService tokenService;
  late WebSocketLink link;
  late GraphQLClient client;

  setUp(() async {
    server = FakeGraphQlWsServer();
    await server.start();
    tokenService = MockAuthTokenService();
    when(() => tokenService.getAccessToken()).thenAnswer((_) async => 't1');
    link = buildWebSocketLink(
      url: server.url,
      policy: WsReconnectPolicy(authService: tokenService),
    );
    client = GraphQLClient(
      link: link,
      cache: GraphQLCache(store: InMemoryStore()),
    );
  });

  tearDown(() async {
    await link.dispose();
    await server.stop();
  });

  void answerWithSnapshot() {
    server.onSubscribe = (ws, subscribe) =>
        server.emit(ws, subscribe['id'] as String, {
          'userUpdated': {'id': 'u1'},
        });
  }

  Stream<QueryResult> subscribe() =>
      client.subscribe(SubscriptionOptions(document: _userSubscription));

  group('resubscribe (SYNC-03)', () {
    test(
      'resends the subscription with the same id on the same stream',
      () async {
        answerWithSnapshot();
        final events = StreamIterator<QueryResult>(subscribe());

        final first = await _next(events);
        expect(first.data?['userUpdated']['id'], 'u1');

        await server.dropWith(1001);

        final second = await _next(events);
        expect(second.data?['userUpdated']['id'], 'u1');

        final subscribes = server.framesOf('subscribe');
        expect(subscribes, hasLength(2));
        expect(subscribes[0]['id'], subscribes[1]['id']);
        expect(server.framesOf('connection_init'), hasLength(2));
        await events.cancel();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('token per connect (SYNC-06)', () {
    test(
      'second connection_init carries the rotated token on the same link',
      () async {
        answerWithSnapshot();
        final events = StreamIterator<QueryResult>(subscribe());
        await _next(events);
        final linkBefore = link;

        when(() => tokenService.getAccessToken()).thenAnswer((_) async => 't2');
        await server.dropWith(4401);
        await _next(events);

        final inits = server.framesOf('connection_init');
        expect(inits, hasLength(2));
        expect(inits[0]['payload']['Authorization'], 'Bearer t1');
        expect(inits[1]['payload']['Authorization'], 'Bearer t2');
        expect(identical(linkBefore, link), isTrue);
        await events.cancel();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('FORBIDDEN on the wire', () {
    test(
      'yields one error result, completes, and is never re-sent',
      () async {
        server.onSubscribe = (ws, subscribe) =>
            server.rejectWithCode(ws, subscribe['id'] as String, 'FORBIDDEN');
        final results = <QueryResult>[];
        final done = Completer<void>();
        subscribe().listen(results.add, onDone: done.complete);

        await done.future.timeout(_wait);
        expect(results, hasLength(1));
        expect(
          results.single.exception?.graphqlErrors.first.extensions?['code'],
          'FORBIDDEN',
        );

        await server.dropWith(1001);
        await _untilFrames(server, 'connection_init', 2);

        expect(server.framesOf('subscribe'), hasLength(1));
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('GraphQLClientHolder.reset (SYNC-04)', () {
    late GraphQLClientHolder holder;

    setUp(() {
      holder = GraphQLClientHolder(
        connect: () {
          final sessionLink = buildWebSocketLink(
            url: server.url,
            policy: WsReconnectPolicy(authService: tokenService),
          );
          return (
            client: GraphQLClient(
              link: sessionLink,
              cache: GraphQLCache(store: InMemoryStore()),
            ),
            webSocketLink: sessionLink,
          );
        },
      );
    });

    tearDown(() async => holder.reset());

    Stream<QueryResult> subscribeVia(GraphQLClient sessionClient) =>
        sessionClient.subscribe(
          SubscriptionOptions(document: _userSubscription),
        );

    test(
      'closes the old socket, silences old listeners and opens a fresh session',
      () async {
        server.onSubscribe = (ws, subscribe) =>
            server.emit(ws, subscribe['id'] as String, {
              'userUpdated': {'id': 'u1'},
            });
        final oldEvents = StreamIterator<QueryResult>(
          subscribeVia(holder.client.value),
        );
        await _next(oldEvents);
        final oldSocket = server.sockets.first;
        final oldSocketClosed = Completer<void>();
        oldSocket.done.then((_) => oldSocketClosed.complete());

        await holder.reset();

        await oldSocketClosed.future.timeout(_wait);
        expect(oldSocket.closeCode, isNotNull);

        final newEvents = StreamIterator<QueryResult>(
          subscribeVia(holder.client.value),
        );
        await _next(newEvents);

        expect(server.framesOf('connection_init'), hasLength(2));
        expect(server.framesOf('subscribe'), hasLength(2));
        expect(server.sockets, hasLength(2));
        final newSubscribe = server.framesOf('subscribe').last;
        server.emit(server.sockets.last, newSubscribe['id'] as String, {
          'userUpdated': {'id': 'u2'},
        });
        expect(await _next(newEvents), isA<QueryResult>());
        expect(await oldEvents.moveNext().timeout(_wait), isFalse);
        await newEvents.cancel();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'watchConnection observes the link created by reset',
      () async {
        await holder.watchConnection().firstWhere((c) => c).timeout(_wait);

        await holder.reset();

        await holder.watchConnection().firstWhere((c) => c).timeout(_wait);
        expect(server.framesOf('connection_init'), hasLength(2));
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });

  group('keep-alive (Pitfall 2)', () {
    test('production defaults ping every 25 s and bound connects to 10 s', () {
      expect(EnvConfig.wsPingIntervalSeconds, 25);
      expect(EnvConfig.wsConnectTimeoutSeconds, 10);
    });

    test(
      'connectWithKeepAlive opens a ready IO channel',
      () async {
        final channel = await connectWithKeepAlive(Uri.parse(server.url), [
          'graphql-transport-ws',
        ]);

        expect(channel, isA<IOWebSocketChannel>());
        await channel.sink.close();
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    test(
      'a peer that never answers pings is closed with goingAway',
      () async {
        final silentPeer = await HttpServer.bind(
          InternetAddress.loopbackIPv4,
          0,
        );
        final upgraded = <WebSocket>[];
        silentPeer.listen(
          (request) async =>
              upgraded.add(await WebSocketTransformer.upgrade(request)),
        );

        final channel = await openKeepAliveChannel(
          Uri.parse('ws://127.0.0.1:${silentPeer.port}/graphql'),
          null,
          pingInterval: const Duration(milliseconds: 100),
        );

        await channel.stream.drain<void>().timeout(
          _wait,
          onTimeout: () => fail('half-open not detected'),
        );
        expect(channel.closeCode, WebSocketStatus.goingAway);
        await silentPeer.close(force: true);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
  });
}

Future<QueryResult> _next(StreamIterator<QueryResult> events) async {
  final hasNext = await events.moveNext().timeout(_wait);
  expect(hasNext, isTrue, reason: 'stream ended before the next event');
  return events.current;
}

Future<void> _untilFrames(FakeGraphQlWsServer server, String type, int count) =>
    Stream<void>.periodic(
      const Duration(milliseconds: 20),
    ).firstWhere((_) => server.framesOf(type).length >= count).timeout(_wait);
