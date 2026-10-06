import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Adapter dio scriptato: risponde in ordine con gli status forniti e
/// registra le richieste ricevute.
class FakeHttpClientAdapter implements HttpClientAdapter {
  FakeHttpClientAdapter(this._statuses);

  final List<int> _statuses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    final status = _statuses[requests.length - 1];
    final code = status == 401 ? 'UNAUTHENTICATED' : 'OK';
    return ResponseBody.fromString(
      '{"code":"$code"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
