import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Server `graphql-transport-ws` locale per i test sui socket.
///
/// Esiste perché `SocketClient` di `graphql` non è mockabile (si connette nel
/// costruttore): l'unico modo di esercitare il vero `WebSocketLink` è un peer
/// reale su loopback. Usare `test(...)`, mai `testWidgets` (HttpOverrides).
class FakeGraphQlWsServer {
  late HttpServer _http;
  final List<WebSocket> sockets = [];
  final List<Map<String, dynamic>> received = [];

  void Function(WebSocket ws, Map<String, dynamic> subscribe)? onSubscribe;

  Future<void> start() async {
    _http = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _http.listen(_accept);
  }

  String get url => 'ws://127.0.0.1:${_http.port}/graphql';

  Future<void> _accept(HttpRequest request) async {
    final ws = await WebSocketTransformer.upgrade(
      request,
      protocolSelector: (protocols) => protocols.first,
    );
    sockets.add(ws);
    ws.listen((raw) => _handle(ws, raw as String), onError: (_) {});
  }

  void _handle(WebSocket ws, String raw) {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    received.add(msg);
    switch (msg['type']) {
      case 'connection_init':
        _send(ws, {'type': 'connection_ack'});
      case 'ping':
        _send(ws, {'type': 'pong'});
      case 'subscribe':
        onSubscribe?.call(ws, msg);
    }
  }

  void _send(WebSocket ws, Map<String, dynamic> frame) =>
      ws.add(jsonEncode(frame));

  void emit(WebSocket ws, String id, Map<String, dynamic> data) => _send(ws, {
    'type': 'next',
    'id': id,
    'payload': {'data': data},
  });

  /// Forma di rifiuto del backend: `next` con errors seguito da `complete`.
  void rejectWithCode(WebSocket ws, String id, String code) {
    _send(ws, {
      'type': 'next',
      'id': id,
      'payload': {
        'errors': [
          {
            'message': code,
            'extensions': {'code': code},
          },
        ],
      },
    });
    complete(ws, id);
  }

  void complete(WebSocket ws, String id) =>
      _send(ws, {'type': 'complete', 'id': id});

  /// Chiude l'ultimo socket con [code]. Usare 4401/4403/1001, mai 1006
  /// (riservato: `close` lancia).
  Future<void> dropWith(int code) => sockets.last.close(code, 'test');

  List<Map<String, dynamic>> framesOf(String type) =>
      received.where((m) => m['type'] == type).toList();

  Future<void> stop() async {
    for (final ws in sockets) {
      await ws.close().timeout(
        const Duration(seconds: 1),
        onTimeout: () => null,
      );
    }
    await _http.close(force: true);
  }
}
