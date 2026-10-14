import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'fake_graphql_ws_server.dart';

class _Client {
  _Client(this.socket) {
    socket.listen((raw) {
      final frame = jsonDecode(raw as String) as Map<String, dynamic>;
      frames.add(frame);
      for (final waiter in List.of(_waiters)) {
        if (waiter.test(frame)) {
          _waiters.remove(waiter);
          waiter.completer.complete(frame);
        }
      }
    }, onDone: closed.complete);
  }

  final WebSocket socket;
  final Completer<void> closed = Completer<void>();
  final List<Map<String, dynamic>> frames = [];
  final List<({bool Function(Map<String, dynamic>) test, Completer completer})>
  _waiters = [];

  static Future<_Client> connect(String url) async => _Client(
    await WebSocket.connect(url, protocols: ['graphql-transport-ws']),
  );

  void send(Map<String, dynamic> frame) => socket.add(jsonEncode(frame));

  Future<Map<String, dynamic>> next(String type) {
    final already = frames.where((f) => f['type'] == type);
    if (already.isNotEmpty) return Future.value(already.first);
    final completer = Completer<Map<String, dynamic>>();
    _waiters.add((test: (f) => f['type'] == type, completer: completer));
    return completer.future.timeout(const Duration(seconds: 2));
  }
}

void main() {
  late FakeGraphQlWsServer server;

  setUp(() async {
    server = FakeGraphQlWsServer();
    await server.start();
  });

  tearDown(() async {
    await server.stop();
  });

  test('acks connection_init and records the payload', () async {
    final client = await _Client.connect(server.url);

    client.send({
      'type': 'connection_init',
      'payload': {'Authorization': 'Bearer t1'},
    });

    expect((await client.next('connection_ack'))['type'], 'connection_ack');
    final init = server.framesOf('connection_init').single;
    expect((init['payload'] as Map)['Authorization'], 'Bearer t1');
  });

  test('answers ping with pong', () async {
    final client = await _Client.connect(server.url);

    client.send({'type': 'ping'});

    expect((await client.next('pong'))['type'], 'pong');
  });

  test('emits a scripted next frame on subscribe', () async {
    server.onSubscribe = (ws, msg) => server.emit(ws, msg['id'], {'x': 1});
    final client = await _Client.connect(server.url);

    client.send({
      'type': 'subscribe',
      'id': '1',
      'payload': {'query': 'subscription { x }'},
    });

    expect(await client.next('next'), {
      'type': 'next',
      'id': '1',
      'payload': {
        'data': {'x': 1},
      },
    });
  });

  test('rejectWithCode sends next with errors then complete', () async {
    server.onSubscribe = (ws, msg) =>
        server.rejectWithCode(ws, msg['id'], 'FORBIDDEN');
    final client = await _Client.connect(server.url);

    client.send({'type': 'subscribe', 'id': '7'});

    expect(await client.next('next'), {
      'type': 'next',
      'id': '7',
      'payload': {
        'errors': [
          {
            'message': 'FORBIDDEN',
            'extensions': {'code': 'FORBIDDEN'},
          },
        ],
      },
    });
    expect(await client.next('complete'), {'type': 'complete', 'id': '7'});
  });

  test('dropWith closes the last socket with the given code', () async {
    final client = await _Client.connect(server.url);
    client.send({'type': 'connection_init'});
    await client.next('connection_ack');

    await server.dropWith(4401);

    await client.closed.future.timeout(const Duration(seconds: 2));
    expect(client.socket.closeCode, 4401);
  });

  test('stop completes and refuses new connections', () async {
    final url = server.url;

    await server.stop();

    expect(
      WebSocket.connect(url, protocols: ['graphql-transport-ws']),
      throwsA(anyOf(isA<SocketException>(), isA<WebSocketException>())),
    );
  });
}
