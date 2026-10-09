import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Risposta scriptata: status + body JSON, oppure un errore dio.
class ScriptedResponse {
  const ScriptedResponse.json(
    this.status, [
    this.body = const <String, Object?>{},
  ]) : failure = null;

  const ScriptedResponse.failure(DioExceptionType this.failure)
    : status = 0,
      body = const <String, Object?>{};

  final int status;
  final Map<String, Object?> body;
  final DioExceptionType? failure;
}

/// Adapter dio che risponde in ordine con le [ScriptedResponse] e registra
/// le richieste ricevute.
class ScriptedHttpClientAdapter implements HttpClientAdapter {
  ScriptedHttpClientAdapter(this._responses);

  final List<ScriptedResponse> _responses;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    await requestStream?.drain<void>();
    requests.add(options);
    final scripted = _responses[requests.length - 1];
    final failure = scripted.failure;
    if (failure != null) {
      throw DioException(requestOptions: options, type: failure);
    }
    return ResponseBody.fromString(
      jsonEncode(scripted.body),
      scripted.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
