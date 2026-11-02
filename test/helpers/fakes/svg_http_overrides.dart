import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _svg = '<svg xmlns="http://www.w3.org/2000/svg" width="1" height="1"/>';

/// Risponde a ogni richiesta HTTP con un SVG minimo: i widget con
/// `SvgPicture.network` (pennello e gomma del negozio) non falliscono sul
/// 400 vuoto del binding di test.
void useSvgHttpOverrides() {
  final previous = HttpOverrides.current;
  HttpOverrides.global = _SvgHttpOverrides();
  addTearDown(() => HttpOverrides.global = previous);
}

class _SvgHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _SvgHttpClient();
}

class _SvgHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _SvgHttpRequest();

  @override
  void close({bool force = false}) {}
}

class _SvgHttpRequest extends Fake implements HttpClientRequest {
  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  int contentLength = -1;

  @override
  bool persistentConnection = true;

  @override
  final HttpHeaders headers = _NoHeaders();

  @override
  Future<void> addStream(Stream<List<int>> stream) => stream.drain<void>();

  @override
  Future<HttpClientResponse> close() async => _SvgHttpResponse();
}

class _NoHeaders extends Fake implements HttpHeaders {
  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {}

  @override
  void forEach(void Function(String name, List<String> values) action) {}
}

class _SvgHttpResponse extends Stream<List<int>> implements HttpClientResponse {
  final List<int> _bytes = utf8.encode(_svg);

  @override
  int get statusCode => HttpStatus.ok;

  @override
  String get reasonPhrase => 'OK';

  @override
  int get contentLength => _bytes.length;

  @override
  bool get isRedirect => false;

  @override
  bool get persistentConnection => false;

  @override
  HttpHeaders get headers => _NoHeaders();

  @override
  List<RedirectInfo> get redirects => const [];

  @override
  HttpClientResponseCompressionState get compressionState =>
      HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) => Stream<List<int>>.value(_bytes).listen(
    onData,
    onError: onError,
    onDone: onDone,
    cancelOnError: cancelOnError,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
